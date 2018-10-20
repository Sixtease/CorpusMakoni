#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use utf8;

my ($source_audio_dir) = shift;

my $err;
my $isbad;
my $prev = 0;
my $prevstem = '';
my $source_audio_fn;

while (<>) {
    $isbad = 0;
    $err = '';
    my (
        $stem, $fnfrom, $fnto, $jsfrom, $jsto
    ) = m{([^"/]+)--from-(.*)--to-(\d+\.\d+).*\bfrom\b\D+(\d+\.\d+).*\bto\b\D+(\d+\.\d+)};
    if (not defined $jsto) {
        if ($prevstem) {
            check_coverage($prevstem, $prev);
        }
        $prev = 0;
        undef $prevstem;
        next;
    }
    mbex($fnfrom == $jsfrom);
    mbex($fnto eq $fnto);
    mbex($jsfrom == $prev);
    mbex($jsto - $jsfrom >=  30);
    mbex($jsto - $jsfrom <= 120);
    print $err . $_ if $isbad;
    $prev = $jsto;
    $prevstem = $stem;
}

sub mbex {
    $err .= $_[0] ? ' ' : '!';
    $isbad = 1 if not $_[0];
}

sub check_coverage {
    my ($stem, $final_chunk_end) = @_;
    my ($source_audio_fn) = (glob(qq("$source_audio_dir/flac/$stem.flac*")), glob(qq("$source_audio_dir/mp3/$stem.mp3*")));
    if (not $source_audio_fn) {
        die "Couldn't find source audio file for stem '$stem'";
    }
    my $source_length = `soxi -D "$source_audio_fn"`;
    chomp $source_length;
    warn "$source_audio_fn (stem $stem) uncovered ($final_chunk_end of $source_length)"
        if $source_length - $final_chunk_end > 0.5;
}
