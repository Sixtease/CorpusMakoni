#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use utf8;

my ($audio_dir) = shift;

# meta json
while (<>) {
    my ($from) = /\bfrom\b\D*(\d+\.\d+)/ or next;
    my ($to)   = /\bto\b\D*(\d+\.\d+)/;
    my ($alleged_dur) = /\bduration\b\D*(\d+\.\d+)/;
    my ($format) = /(mp3|ogg)/;
    my ($basename) = /"basename": "([^"]+)"/;
    my ($stem) = $basename =~ /(.*?)--/;
    my $is_final_chunk = not /,$/;
    my $computed_dur = $to - $from;
    my $sox_dur = `soxi -D "$audio_dir/$stem/$format/$basename"`;
    my $dif = $sox_dur - $alleged_dur;
    chomp $sox_dur;
    chomp;
    if ($is_final_chunk) {
        say "$dif $alleged_dur:$computed_dur:$sox_dur:$_"
            if $alleged_dur < 30 or $alleged_dur > 120 or abs($computed_dur - $alleged_dur) > 0.01 or abs($dif > 1.2);
    }
    else {
        say "$dif $alleged_dur:$computed_dur:$sox_dur:$_"
            if $alleged_dur < 30 or $alleged_dur > 120 or abs($computed_dur - $alleged_dur) > 0.01 or $dif > 1.2 or $dif < 0;
    }
}
