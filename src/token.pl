#!/usr/bin/perl
#
# Parsing tokens
#
use strict;


my @regexp;
$regexp[0]  = '\{';
$regexp[1]  = '\"\w+List\"\:\s*\[';
$regexp[4]  = '\}';
$regexp[3]  = ',';
$regexp[2]  = '\]';
$regexp[5]  = '\".*\":((\".*\")|\d+)';

my $TEOF    = 6;
my $testfile= "testfile.json";
open(my $fh,"$testfile") or die "Unable to open $testfile";
my @tokenstack;
my $lineno = 0;
#
# Get the next token
#
sub gettoken{
  my $println = shift;
  my $tokenstackisempty = (scalar @tokenstack == 0);
  if ($tokenstackisempty) {
     my $nextline = <$fh>;
     chomp($nextline);
     if (!$nextline) {
       return $TEOF
     }
     $lineno++;
     printf "\n%3d:%s\n", $lineno, $nextline if $println;
     #
     # parse the $line
     #
     my $regid = 0;
     #
     # We need to assure that the order of the found strings are in the correct order
     #
     my  %res;
     for my $regexp (@regexp) {
        if ($nextline =~ /$regexp/) {
           my $pos    = $-[0];
           $res{$pos} = $regid;
        }
        $regid++;
     }
     for my $key (sort {$b <=> $a} keys %res) {
       push(@tokenstack,$res{$key})
     }
  }
  return pop(@tokenstack)
}
my $token = -1;
while ($token != $TEOF) {
  $token = gettoken(1);
  printf "%d ", $token;
}
