#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use SeedUtils;
use Time::HiRes 'gettimeofday';
use Parse::RecDescent;
    
use Bio::KBase::GenomeAnnotation::Client;
use JSON::XS;

use IDclient;
use GenomeTypeObject;
eval {
    require  Bio::KBase::IDServer::Client;
};

use Getopt::Long::Descriptive;

my($opt, $usage) = describe_options("%c %o [< input] [> output]",
				    ["input|i=s", "Input genome typed object"],
				    ["output|o=s", "Output genome typed object"],
				    ["id-prefix=s", "Generated feature id prefix"],
				    ["id-server=s", "URL to ID server"],
				    ["id-type", "Feature ID type to generate", { default => "gap" }],
				    ["help|h", "Show this help message"]);

print($usage->text), exit(0) if $opt->help;
die($usage->text) if @ARGV > 0;

my $genome_in;

if ($opt->input)
{
    $genome_in = GenomeTypeObject->create_from_file($opt->input);
}
else
{
    $genome_in = GenomeTypeObject->create_from_file(\*STDIN);
}

my $id_client;
if ($opt->id_server)
{
    $id_client = Bio::KBase::IDServer::Client->new($opt->id_server);
}
else
{	
    $id_client = IDclient->new($genome_in);
}

my $hostname = `hostname`;
chomp $hostname;
my $event = {
    tool_name => 'rast_call_assembly_gaps',
    execute_time => scalar gettimeofday,
    parameters => [],
    hostname => $hostname,
};
my $event_id = $genome_in->add_analysis_event($event);

my $id_prefix = $opt->id_prefix // $genome_in->{id};
my $id_type = $opt->id_type;

my $parser = init_parser();

my @features;

for my $contig ($genome_in->contigs)
{
    my $gl = $contig->{genbank_locus};
    next unless $gl;
    my $c = $gl->{contig};
    next unless $c;
    # print "$c\n";

    my $tree = $parser->parse($c);

    my $cur = 1;
    if ($tree->[0] ne 'join')
    {
	warn "Cannot parse novel form of CONTIGS: $c\n";
    }
    else
    {
	my $len = length($contig->{dna});
	my @recs;
	# print "Process contig of length $len\n";
	for my $ent (@{$tree->[1]})
	{
	    if ($ent->[0] eq 'contig_base')
	    {
		my($ctg, $start, $stop) = @$ent[1..3];
		# print "$ctg: $start - $stop\n";
		my $cstart = $cur;
		my $clen = $stop - $start + 1;
		my $cend = $cur + $clen - 1;
		push(@recs, { ctg => $ent, cstart => $cstart, cend => $cend, clen => $clen });
		$cur = $cend + 1;
	    }
	    elsif ($ent->[0] eq 'gap')
	    {
		my $len = $ent->[1];
		# print "gap: $len\n";
		my $cstart = $cur;
		my $cend = $cur + $len - 1;
		push(@recs, { ctg => $ent, cstart => $cstart, cend => $cend, clen => $len });
		$cur = $cend + 1;
		my $gapchars = substr($contig->{dna}, $cstart - 1, $len);
		if ($gapchars !~ /^n+$/)
		{
		    warn "Bad gap @$ent $gapchars\n";
		}
	    }
	    else
	    {
		warn "Unknown chunk type @$ent\n";
		last;
	    }
	}
	#
	# Postprocess list to create gap features.
	#
	for my $i (0..$#recs)
	{
	    my $ent = $recs[$i];
	    if ($ent->{ctg}->[0] eq 'gap')
	    {
		my $pent = $recs[$i-1];
		my $nent = $recs[$i+1];
		if (!$pent)
		{
		    warn "Gap at $i doesn't have a preceding entry\n";
		    last;
		}
		if (!$nent)
		{
		    warn "Gap at $i doesn't have a next entry\n";
		    last;
		}
		if ($pent->{ctg}->[0] ne 'contig_base')
		{
		    warn "Gap at $i has unknown entry type $pent->{ctg}->[0] in preceding entry\n";
		    last;
		}
		if ($nent->{ctg}->[0] ne 'contig_base')
		{
		    warn "Gap at $i has unknown entry type $pent->{ctg}->[0] in next entry\n";
		    last;
		}
		my $pname = $pent->{ctg}->[1];
		my $nname = $nent->{ctg}->[1];
		# print "Gap $i $ent->{cstart} $ent->{cend} $pname $nname\n";

		push(@features, [$contig->{id}, $ent->{cstart}, $ent->{clen}, '+', $pname, $nname]);
	    }
	}
    }
}

my $count = @features;
my $typed_prefix = join(".", $id_prefix, $id_type);
my $cur_id_suffix = $id_client->allocate_id_range($typed_prefix, $count);

for my $f (@features)
{
    my($contig, $start, $len, $strand, $pname, $nname) = @$f;
    my $desc = ($len == 100) ? "unknown length" : "$len characters";
    my $func = "Assembly gap of $desc between contigs $pname and $nname";
    my $id = join(".", $typed_prefix, $cur_id_suffix);
    $cur_id_suffix++;
    $genome_in->add_feature({
	-id         => $id,
	-type       => $id_type,
	-location   => [[ $contig, $start, $strand, $len ]],
	-annotator  => 'rast_call_assembly_gaps',
	-analysis_event_id   => $event_id,
	-function => $func,
    });
}

if ($opt->output)
{
    $genome_in->destroy_to_file($opt->output);
}
else
{
    $genome_in->destroy_to_file();
}

sub init_parser
{
    my $grammar = <<'END';
parse: location
location: single_base '..' single_base { ['range', $item[1], $item[3] ] }
location: lower_bound '..' single_base { ['lb_range', $item[1], $item[3] ] }
location: single_base '..' upper_bound { ['ub_range', $item[1], $item[3] ] }
location: single_base '.' single_base { ['unknown_between', $item[1], $item[3] ] }
location: single_base '^' single_base { ['between', $item[1], $item[3] ] }
location: single_base { [ $item[1] ] }
location: 'complement(' location ')' { ['complement', $item[2] ] }
location: 'join(' location_list ')' { ['join', $item[2] ] }
location: 'gap(' /\d+/ ')' { ['gap', $item[2]] }
location: /[A-Za-z][A-Za-z0-9]*(\.\d+)?/ ':' single_base '..' single_base { ['contig_base', $item[1], $item[3], $item[5] ] }

location_list: location ',' location_list { [ $item[1], @{$item[3]} ] }
location_list: location { [ $item[1] ] }

single_base: /\d+/
lower_bound: /<\d+/
upper_bound: />\d+/
END
    # print "---\n$grammar\n---\n";
    my $parser = Parse::RecDescent->new($grammar);
    return $parser;
}
