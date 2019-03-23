#!/usr/bin/perl
#
# Parsing tokens find the lists and the start and end of the objects
#
#
#   position.pl --jsonfile=<filename>  --position=<filename> --listname=<filename> --nolines=bytes --debug
#
# where
#   jsonfile        - the main file download file
#   jsonobject      - intput with the positions
#   listname        - listname
#   maxlines        - number of lines in the input file
#   debug           - enable debug
#
#
use strict;
use FSM::Simple;
use Term::ProgressBar 2.00;
use Getopt::Long;

my @regexp;
$regexp[0]  = '\{';
$regexp[1]  = '\}';
$regexp[2]  = '\]';
$regexp[3]  = ',';
$regexp[4]  = '\".+List\"\:\s*\[';
$regexp[5]  = '\".*\":((\".*\")|\-*\d+)';
my $TEOF    = 6;

my $jsonfile   = "../json/BBR-AKT-TOT-JSON-101_20181204091515.json";
my $position   = "../csv/position.csv";
my $listname   = "../csv/listnames.csv";
my $maxlines   = 28075948;
my $debug      = 0;

GetOptions( "jsonfile=s"        => \$jsonfile,
            "position=s"        => \$position,
            "listname=s"        => \$listname,
            "maxlines=i"        => \$maxlines,
            "debug"             => \$debug);

open(my $ifh, $jsonfile)            or die "Unable to open $jsonfile";
open(my $ofh, ">$position")         or die "Unable to create $position";
open(my $listfh,">$listname")       or die "Unable to create $listname";

my $progress       = Term::ProgressBar->new($maxlines) if !$debug;
my $next_update    = 0;

my @tokenstack;
my $lineno         = 0;
my $startposition  = 0;
my $endposition    = 0;


my $nextline;

#
# Get the next token
#
#
# Get the next token
#
sub gettoken{
  my $println = shift;
  my $tokenstackisempty = (scalar @tokenstack == 0);
  if ($tokenstackisempty) {
     $startposition = tell($ifh);
     $nextline      = <$ifh>;
     $endposition   = tell($ifh);
     chomp($nextline);
     if (!$nextline) {
       return $TEOF
     }
     $lineno++;
     $next_update = $progress->update($lineno) if $lineno >= $next_update && !$debug;
     printf "%3d:%s\n", $lineno, $nextline if $println;
     #
     # parse the $line
     #
     my $regid = 0;
     #
     # We need to assure that the order of the found strings are in the correct order
     #
     my  %res;
     #
     # Test for T4 and T5 - and note the position
     #
     my $reg5on = 0;
     my $reg4on = 0;
     my $searchpos = 0;
     if ($nextline =~ /$regexp[5]/) {
       $reg5on  = 1;
       my $startpos    = $-[0];
       my $endpos      = $+[0];

       if (length($nextline) > $endpos) {
         $searchpos = $endpos
       }
     }
     if ($nextline =~ /$regexp[4]/) {
       $reg4on  = 1;
       my $startpos    = $-[0];
       my $endpos      = $+[0];

       if (length($nextline) > $endpos) {
         $searchpos = $endpos
       }
     }
     my $string = substr($nextline,$searchpos);
     for my $i (0..3){
        my $re = $regexp[$i];
        if ($string =~ /$re/) {
           my $startpos    = $-[0];
           my $endpos      = $+[0];
           $res{$startpos} = $regid;
        }
        $regid++;
     }
     for my $key (sort {$b <=> $a} keys %res) {
       push(@tokenstack,$res{$key})
     }
     if ($reg4on) {
       push(@tokenstack,4)
     }
     if ($reg5on) {
       push(@tokenstack,5)
     }
  }
  return pop(@tokenstack)
}
my %objects;
my $currentlist;
my $objectstartposition;
my $objectendposition;
my @objectlist;
sub init{
   my $rh_args = shift;
   $rh_args->{echo}   = $debug;
   $rh_args->{token}  = 0;
   $rh_args->{returned_value} = &gettoken($rh_args->{echo});
   printf "(init,%s)\n",$rh_args->{returned_value} if $debug;
   return $rh_args
}
sub s1 {
  my $rh_args = shift;
  $rh_args->{returned_value} = &gettoken($rh_args->{echo});
  printf "(s1,%s)\n",$rh_args->{returned_value} if $debug;
  printf "Beginlist %s, (%d)\n", $nextline, $startposition if $debug;;
  if ($nextline =~ /\"(.+List)\"/) {
    $currentlist = $1;
    $objects{$currentlist}=0;
    push(@objectlist,$currentlist);
    $progress->message("New list ".$currentlist) if !$debug;
  }
  return $rh_args
}
sub s2 {
use Getopt::Long;  my $rh_args = shift;
  $rh_args->{returned_value} = &gettoken($rh_args->{echo});
  printf "(s2,%s)\n",$rh_args->{returned_value} if $debug;
  printf "Beginobject, (%d)\n", $startposition if $debug;
  $objects{$currentlist}++;
  $objectstartposition = $startposition;
  return $rh_args
}
sub s3 {
  my $rh_args = shift;
  $rh_args->{returned_value} = &gettoken($rh_args->{echo});
  printf "(s3,%s)\n",$rh_args->{returned_value} if $debug;

  return $rh_args
}
sub s3 {
  my $rh_args = shift;
  $rh_args->{returned_value} = &gettoken($rh_args->{echo});
  printf "(s3,%s)\n",$rh_args->{returned_value} if $debug;
  return $rh_args
}
sub s4 {
  my $rh_args = shift;
  $rh_args->{returned_value} = &gettoken($rh_args->{echo});
  printf "(s4,%s)\n",$rh_args->{returned_value} if $debug;

  return $rh_args
}
sub s5 {
  my $rh_args = shift;
  $rh_args->{returned_value} = &gettoken($rh_args->{echo});
  printf "(s5,%s)\n",$rh_args->{returned_value} if $debug;
  printf "Endobject, (%d)\n", $endposition-2 if $debug;
  $objectendposition = $endposition-2;
  printf $ofh "%s,%d,%d\n", $currentlist,$objectstartposition,$objectendposition;
  return $rh_args
}
sub s6 {
  my $rh_args = shift;
  $rh_args->{returned_value} = &gettoken($rh_args->{echo});
  printf "(stop,%s)\n",$rh_args->{returned_value} if $debug;
  printf "Endlist, (%d)\n", $endposition-2 if $debug;
  return $rh_args
}
sub stop {
  my $rh_args = shift;
  $rh_args->{returned_value} = undef;
  printf "Last Line\n" if $debug;
  return $rh_args
}

#
# Main
#
my $token = -1;
my $state = 0;

my $machine = FSM::Simple->new();

$machine->add_state(name => 'init',      sub => \&init);
$machine->add_state(name => 'S1',        sub => \&s1);
$machine->add_state(name => 'S2',        sub => \&s2);
$machine->add_state(name => 'S3',        sub => \&s3);
$machine->add_state(name => 'S4',        sub => \&s4);
$machine->add_state(name => 'S5',        sub => \&s5);
$machine->add_state(name => 'S6',        sub => \&s6);
$machine->add_state(name => 'stop',      sub => \&stop);

$machine->add_trans(from => 'init',      to => 'S1', exp_val => 0);
$machine->add_trans(from => 'S1',        to => 'S2', exp_val => 4);
$machine->add_trans(from => 'S2',        to => 'S3', exp_val => 0);
$machine->add_trans(from => 'S2',        to => 'S6', exp_val => 2);
$machine->add_trans(from => 'S3',        to => 'S4', exp_val => 5);
$machine->add_trans(from => 'S4',        to => 'S5', exp_val => 1);
$machine->add_trans(from => 'S4',        to => 'S4', exp_val => 2);
$machine->add_trans(from => 'S4',        to => 'S3', exp_val => 3);
$machine->add_trans(from => 'S5',        to => 'S2', exp_val => 3);
$machine->add_trans(from => 'S5',        to => 'S6', exp_val => 2);
$machine->add_trans(from => 'S6',        to => 'S1', exp_val => 3);
$machine->add_trans(from => 'S6',        to => 'stop', exp_val => 1);
$machine->add_trans(from => 'S6',        to => 'stop', exp_val =>  $TEOF);

$machine->run();

my $total = 0;
for my $l (@objectlist) {

  if ($objects{$l} > 1 ) {
    printf  $listfh "%s,%d\n",$l,$objects{$l};
    $total += $objects{$l};
  }
  else {
    printf  $listfh "%s,%d\n",$l,0;
  }
}
printf "Total %d\n", $total
