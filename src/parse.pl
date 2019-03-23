#!/usr/bin/perl
#
# Parsing tokens
#
use strict;
use FSM::Simple;


my @regexp;
$regexp[0]  = '\{';
$regexp[1]  = '\}';
$regexp[2]  = '\]';
$regexp[3]  = ',';
$regexp[4]  = '\".+List\"\:\s*\[';
$regexp[5]  = '\".*\":((\".*\")|\-*\d+)';



my $TEOF    = 6;
my $testfile= "../json/testfile.json";
my $outfile = "output.json";
open(my $ifh,"$testfile")  or die "Unable to open $testfile";
open(my $ofh, ">$outfile") or die "Unable to create $outfile";
my @tokenstack;
my $lineno = 0;
my $startposition = 0;
my $endposition = 0;

my $nextline;

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
sub init{
   my $rh_args = shift;
   $rh_args->{echo}   = 1;
   $rh_args->{token}  = 0;
   $rh_args->{returned_value} = &gettoken($rh_args->{echo});
   printf "(init,%s)\n",$rh_args->{returned_value};
   return $rh_args
}
sub s1 {
  my $rh_args = shift;
  $rh_args->{returned_value} = &gettoken($rh_args->{echo});
  printf "(s1,%s)\n",$rh_args->{returned_value};
  printf "Beginlist %s, (%d)\n", $nextline, $startposition;
  return $rh_args
}
sub s2 {
  my $rh_args = shift;
  $rh_args->{returned_value} = &gettoken($rh_args->{echo});
  printf "(s2,%s)\n",$rh_args->{returned_value};
  printf "Beginobject, (%d)\n", $startposition;
  return $rh_args
}
sub s3 {
  my $rh_args = shift;
  $rh_args->{returned_value} = &gettoken($rh_args->{echo});
  printf "(s3,%s)\n",$rh_args->{returned_value};

  return $rh_args
}
sub s3 {
  my $rh_args = shift;
  $rh_args->{returned_value} = &gettoken($rh_args->{echo});
  printf "(s3,%s)\n",$rh_args->{returned_value};
  return $rh_args
}
sub s4 {
  my $rh_args = shift;
  $rh_args->{returned_value} = &gettoken($rh_args->{echo});
  printf "(s4,%s)\n",$rh_args->{returned_value};

  return $rh_args
}
sub s5 {
  my $rh_args = shift;
  $rh_args->{returned_value} = &gettoken($rh_args->{echo});
  printf "(s5,%s)\n",$rh_args->{returned_value};
  printf "Endobject, (%d)\n", $endposition-2;
  return $rh_args
}
sub s6 {
  my $rh_args = shift;
  $rh_args->{returned_value} = &gettoken($rh_args->{echo});
  printf "(stop,%s)\n",$rh_args->{returned_value};
  printf "Endlist, (%d)\n", $endposition-2;
  return $rh_args
}
sub stop {
  my $rh_args = shift;
  $rh_args->{returned_value} = undef;
  printf "Last Line\n";
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
