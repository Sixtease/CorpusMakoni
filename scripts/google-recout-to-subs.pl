#!/usr/bin/env perl

use utf8;
use 5.010;
use strict;
use warnings;
use open qw(:std :utf8);
use File::Basename qw(dirname);

my $PATH;
BEGIN { $PATH = (sub { dirname( (caller)[1] ) })->(); }
use lib $PATH;

use MakonFM::Util::Vyslov qw(vyslov);

use JSON ();

my $filestem = $ARGV[0];
$filestem =~ s/\.json$//;
$filestem =~ s/^.*\///;

my $file_content = join '', <ARGV>;
my $recout_data = JSON->new->decode($file_content);

my @subdata;

for my $result (@{ $recout_data->{results} }) {
  my $alt1 = $result->{alternatives}[0];

  next if not $alt1;

  for (my $i = 0; $i < @{ $alt1->{words} }; $i++) {
    my $word = $alt1->{words}[$i];
    my $occurrence = $word->{word};
    my $next_word = $alt1->{words}[$i + 1] // {};
    my $next_start = $next_word->{startTime} // $next_word->{startOffset} // $result->{resultEndTime} // $result->{resultEndOffset};
    my $form = lc $occurrence;
    $form =~ s/\W//g;
    my $ucword = uc($form);
    my $fonet = vyslov($ucword);
    my $start_ts = $word->{startTime} // $word->{startOffset};
    my $end_ts = $word->{endTime} // $word->{endOffset};
    s/s$//, $_ = $_ - 0 for $start_ts, $end_ts, $next_start;
    my $silence_length = $next_start - $end_ts;
    my @silence_parts = $silence_length > 0 ? (sstart => $end_ts, slen => $silence_length) : ();
    push @subdata, {
      occurrence => $occurrence,
      wordform => $form,
      fonet => $fonet->[0],
      timestamp => $start_ts,
      confidence => $word->{confidence},
      @silence_parts,
    };
  }
}

my %subs = (
  filestem => $filestem,
  data => \@subdata,
);

print qq[jsonp_subtitles(];
print JSON->new->pretty->encode(\%subs);
print qq[);\n];
