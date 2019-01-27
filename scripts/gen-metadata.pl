#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use utf8;
use File::Basename qw(basename);

my $output_dir = shift @ARGV;
my @dirs = @ARGV; # ../splits/*

my %stems;

say STDERR "analyzing";
for my $dir (@dirs) {
    FILE:
    for my $fn (glob("$dir/*")) {
        say STDERR $fn;
        my $bn = basename($fn);
        my ($stem, $start, $end, $format) = $bn =~ /^([^\/]+)--from-([0-9.]+)--to-([0-9.]+)\.(.+)/;
        next FILE if not $stem;
        my $duration = $end - $start;
        if (not $duration > 0) {
            warn "bad duration for $fn";
            next FILE;
        }
        my $size = (stat $fn)[7];
        push @{ $stems{$stem}{$format} }, {
            duration => $duration,
            size => $size,
            stem => $stem,
            basename => $bn,
            from => $start,
            to => $end,
        };
    }
}

say STDERR "\ngenerating";
for my $stem (sort keys %stems) {
    # say STDERR $stem;
    open my $fh, '>:utf8', "$output_dir/$stem.jsonp" or do {
        warn "Cannot open '$output_dir/$stem.jsonp' for writing: $!";
        next;
    };
    print {$fh} (qq[jsonp_splits(\n{\n  "$stem": {\n    "formats": {\n]);
    my @formats = sort keys %{ $stems{$stem} };
    my $last_format = $formats[-1];
    for my $format (@formats) {
        print {$fh} qq(      "$format": [\n);
        my @chunks = sort {$a->{to} <=> $b->{to}} @{ $stems{$stem}{$format} };
        my $last_chunk = $chunks[-1];
        for my $chunk_data (@chunks) {
            print {$fh} qq(        { );
            print {$fh} qq("duration": );
            printf {$fh} '%.2f', $chunk_data->{duration};
            print {$fh} qq(, "size": );
            print {$fh} $chunk_data->{size};
            print {$fh} qq(, "basename": ");
            print {$fh} $chunk_data->{basename};
            print {$fh} qq(", "from": );
            printf {$fh} '%.2f', $chunk_data->{from};
            print {$fh} qq(, "to": );
            printf {$fh} '%.2f', $chunk_data->{to};
            print {$fh} qq( });
            print {$fh} qq(,) unless $chunk_data == $last_chunk;
            print {$fh} qq(\n);
        }
        print {$fh} qq(      ]);
        print {$fh} qq(,) unless $format eq $last_format;
        print {$fh} qq(\n);
    }
    print {$fh} "    }\n  }\n}\n)\n";
}
