#!/usr/bin/perl
#
# Extract the text given by two byte positions
#
use strict;
use Fcntl qw(:seek);

my ($filename, $start, $end) = @ARGV;

open(my $ifh,$filename)  or die "Unable to open $filename";
my $buffer;
seek($ifh,$start,SEEK_SET);
my $bytes = $end - $start;
my $rb    = read($ifh,$buffer,$bytes);
printf "%s\n", $buffer;
close($ifh);
