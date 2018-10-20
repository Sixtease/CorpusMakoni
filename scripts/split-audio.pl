#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use File::Basename qw(basename fileparse);
use Getopt::Long;
use File::Temp qw(:seekable);

my $output_format = 'wav';
my $splitdir = $ENV{SPLITDIR};
my $chunkdir = $ENV{CHUNKDIR};
my $output_file_naming = $ENV{OUTPUT_FILE_NAMING};
my $sox_q = -t STDERR ? '' : ' --no-show-progress';
my $lame_q = $sox_q ? ' --quiet' : '';
my $overlap = $ENV{SPLIT_OVERLAP} || 0.5;

GetOptions(
    'splitdir=s' => \$splitdir,
    'chunkdir=s' => \$chunkdir,
    'output-format=s' => \$output_format,
    'output-file-naming=s' => \$output_file_naming,
    'split-overlap=f' => \$overlap,
);

my $output_template = "%1\$s/chunk%6\$d.%5\$s";
if ($output_file_naming eq 'chunks') {
    # OK
}
elsif ($output_file_naming eq 'intervals') {
    $output_template = "%s/%s--from-%07.2f--to-%07.2f.%s";
}
elsif (defined $output_file_naming) {
    die "Unexpected file naming: $output_file_naming";
}

for my $fn (@ARGV) {
    my $orig_fn = $fn;
    my $basefn = basename $fn;
    print STDERR "\n>>> $basefn \n";
    my ($stem) = fileparse($fn, qw(.mp3 .wav .flac));
    my $split_fn = "$splitdir/$stem.txt";
    my $is_generated = 0;

    my $split_fh;
    if (-e $split_fn) {
        say STDERR "found splits for $stem";
        open $split_fh, '<', $split_fn or die "Couldn't open $split_fn: $!";
    }
    else {
        say STDERR "generating splits for $stem";
        my $split_filecontents = join "", map "$_\n", map 60*$_, 1 .. `soxi -D "$fn"`/60;
        open $split_fh, '<', \$split_filecontents or die "Couldn't open generated splits for $stem: $!";
        $is_generated = 1;
    }

    if ($fn =~ /\.mp3$/) {
        my $tmp = File::Temp->new(SUFFIX => '.wav');
        open my $lame_fh, '-|', qq{lame $lame_q --decode "$fn" -} or die "couldn't start lame: $!";
        {
            local $/;
            print {$tmp} <$lame_fh>;
        }
        $tmp->seek(0, SEEK_SET);
        $fn = $tmp;
    }

    my $flen = `soxi -D "$orig_fn"`;
    my $prev = 0;
    my $i = '000';
    my $chunk_fn;

    for (my $next = <$split_fh>; $next <= $flen; $next = <$split_fh> || $flen) {
        chomp $next;
        my $curr = $next;

        my $should_redo = 0;

        if (($curr - $prev) > 120) {
            $curr = $prev + 90;
            $should_redo = 1;
        }
        ;;; print STDERR "$prev => $curr\n";

        last if $curr >= $flen;
        last if $is_generated and $flen - $curr < 30;

        $chunk_fn = sprintf $output_template, $chunkdir, $stem, $prev, $curr, $output_format, $i;

        print STDERR "($i) $basefn => $chunk_fn $prev .. $curr\n";
        my $end = $curr + $overlap;
        system qq{sox $sox_q "$fn" --channels 1 "$chunk_fn" trim "$prev" "=$end" remix -};

        $prev = $curr;
        $i++;

        redo if $should_redo;
    }
    $chunk_fn = sprintf $output_template, $chunkdir, $stem, $prev, $flen, $output_format, $i;
    print STDERR "($i) $basefn => $chunk_fn $prev .. END\n";
    system qq{sox $sox_q "$fn" --channels 1 "$chunk_fn" "trim" "$prev" remix -};
}
