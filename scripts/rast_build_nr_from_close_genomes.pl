#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use File::Path 'rmtree';

use FIG;
use FIG_Config;
my $fig = FIG->new();

my ($rast_dir, @additional_files) = @ARGV;

my @genome_fastas = map {
    (m/^(\d+\.\d+)/ && $fig->is_genome($1))
	? join(q(/), ($FIG_Config::organisms, $1, q(Features/peg/fasta)))
	: ()
} &FIG::file_read($rast_dir.q(/closest.genomes));



my $nr_dir = $rast_dir.q(/NR);
if (-d $nr_dir) {
    rmtree($nr_dir) or die "Could not remove '$nr_dir'";
}
mkdir($nr_dir) or die "Could not create directory '$nr_dir'";
if (@genome_fastas < 5) {
    foreach my $file (qw(nr nr.phr nr.pin nr.psq)) {
	symlink($FIG_Config::global.q(/).$file, $nr_dir.q(/).$file)
	    or die "Could not symlink to global NR-file '$file'";
    }
}
else {
    my $source_files_fh;
    my $source_files = $nr_dir.q(/nr.sources_files);
    open($source_files_fh, '>', $source_files) or die "Could not write-open '$source_files'";
    print $source_files_fh map { (-s $_) ? ($_, qq(\n)) : () } (@genome_fastas, @additional_files);
    close($source_files_fh);
    &FIG::run_gathering_output('build_nr_md5',
			       $source_files,
			       $nr_dir.q(/nr),
			       $nr_dir.q(/peg.synonyms),
			       $nr_dir.q(/nr.len_btree),
			       $nr_dir.q(/nr.fig_ids)
	);
    &FIG::run_gathering_output(qw(formatdb -p T -i), $nr_dir.q(/nr))
}
