#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use utf8;
use open qw(:std :utf8);
use JSON::XS qw(decode_json);
use Encode qw(encode_utf8);

if (@ARGV != 1) {
    die "Usage: $0 file.sub.js";
}

my ($fn) = @ARGV;

my $json = do { local (@ARGV, $/) = $fn; <> };
$json =~ s/^[^{]+//s;
$json =~ s/[^}]+$//s;

undef $@;
my $subs = eval { decode_json(encode_utf8($json)) };
if (not $subs) {
    die "JSON parse failed for $fn: $@";
}

my @sils;
my $sub;
my $max_sub = $#{$subs->{data}};

SUB:
for my $i (0 .. $max_sub) {
    $sub = $subs->{data}[$i];
    my $len = $sub->{slen} || 0; # silence length
    my $start = $sub->{sstart}; # silence start
    next SUB if not defined $start;
    my $mid = $start + $len / 2;
    if ($len > 30) {
        if ($i == $max_sub) {
            warn "trailing long silence (stem: $subs->{filestem}, start: $start)";
        }
        else {
            warn "long silence (stem: $subs->{filestem}, start: $start, length: $len)";
        }
    }
    push @sils, {
        len => $len,
        mid => $mid,
    };
}
my $file_end = $subs->{data}[-1]{sstart} + $subs->{data}[-1]{slen};

my $maxi = $#sils;
for my $i (1 .. $maxi) {
    $sils[$i]{l} = $sils[$i - 1];
}
for my $i (0 .. $maxi - 1) {
    $sils[$i]{r} = $sils[$i + 1];
}
$sils[ 0]{l} = { mid => 0 };
$sils[-1]{r} = { mid => $file_end };

my @to_filter = sort {$a->{len} <=> $b->{len}} @sils;

my @filtered;
for my $sil (@to_filter) {
    if ($sil->{r}{mid} - $sil->{l}{mid} > 60) {
        push @filtered, $sil;
    }
    else {
        $sil->{l}{r} = $sil->{r};
        $sil->{r}{l} = $sil->{l};
    }
}

@to_filter = @filtered;
@filtered = ();
for my $sil (@to_filter) {
    if ($sil->{mid} - $sil->{l}{mid} < 30 or
        $sil->{r}{mid} - $sil->{mid} < 30
    ) {
        $sil->{l}{r} = $sil->{r};
        $sil->{r}{l} = $sil->{l};
    }
    else {
        push @filtered, $sil;
    }
}

for my $point (sort {$a <=> $b} map $_->{mid}, @filtered) {
    printf "%.2f\n", $point + 0.0001;
}
