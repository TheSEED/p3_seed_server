#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;

use SeedUtils;

my $jobs_dir = '/vol/rast-prod/jobs';

my @jobs = @ARGV;
if ($jobs[0] eq q(-)) {
    @jobs = map { m/^(\d+)/ ? ($1) : () } <STDIN>;
    chomp @jobs;
}

foreach my $job (@jobs) {
    print STDERR "Job: $job\n";
    my $verify_rpt = "$jobs_dir/$job/rp.errors/verify_genome_directory.report";
    if (-s $verify_rpt) {
	my $bad_pegs_fh;
	my $bad_pegs_file = qq(/scratch/tmp_bad_pegs.$$);
	print STDERR "File: $bad_pegs_file\n";
	open($bad_pegs_fh, q(>), $bad_pegs_file)
	    or die "Could not write-open '$bad_pegs_file'";
	print $bad_pegs_fh map { m/^ERROR: PEG (fig\|\d+\.\d+\.peg\.\d+) appears to be DNA, not protein/
				     ? ($1, qq(\n))
				     : ()
	} &SeedUtils::file_read( $verify_rpt );
	close($bad_pegs_fh);
	print STDERR ("File: $bad_pegs_file -- size=", (-s $bad_pegs_file), "\n");
	
	if (-s $bad_pegs_file) {
	    
	    my $genomeID = &SeedUtils::file_head( "$jobs_dir/$job/GENOME_ID", 1);
	    chomp $genomeID;

	    &run_safe('/homes/gdpusch/FIGdisk/FIG/bin/delete_fids_from_orgdir',
		      "$jobs_dir/$job/rp/$genomeID",
		      $bad_pegs_file,
		);
	    
	    &run_safe('reset_stage', $job,   'export');
	    &run_safe('rast_sync',   '-job', $job);
	    
	    print STDERR "Job '$job' reset\n";
	}
	else {
	    print STDERR "No bad PEGs in '$job'\n";
	}
    }
    
    print STDERR "\n\n";
}

sub run_safe {
    my @cmd = @_;
    print STDERR ("Executing: ", join(', ', @cmd), "\n");
    
    system(@cmd);
    if ($? == -1) {
	print "failed to execute: $!\n";
    }
    elsif ($? & 127) {
	printf "child died with signal %d, %s coredump\n",
	($? & 127),  ($? & 128) ? 'with' : 'without';
    }
    else {
	# printf "child exited with value %d\n", $? >> 8;
	return 0;
    }
    die "aborting";
}

