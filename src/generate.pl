#!/usr/bin/perl
#
# generate.pl - generate the json file based on the main json input file and the position file
#
# SYNOPSIS
# ========
#
#   generate.pl --jsonfile=<filename>  --position=<filename> --listnames=<filename> --filesize=<filesize(MB)> --prefix=<prefix> --directory=<directory name>
#
# where
#   jsonfile        - the main file download file
#   position        - intput with the positions
#   listname        - listnames
#   filesize        - max size of outputfile in MByte
#   directory       - name of the directory for the outputfiles
#   prefix          - prefix for the outputfile
#
# The syntax of the output file name
#   <prefix><seqno - 4 digits>.json
#
use strict;
use warnings;
use Getopt::Long;
use Term::ProgressBar 2.00;
use Fcntl qw(:seek);
use File::Basename;
#
# Default values for input parameters
#
my $jsonfile   = "../json/BBR-AKT-TOT-JSON-101_20181204091515.json";
my $position   = "../csv/position.csv";
my $listnames  = "../csv/listnames.csv";
$|=1;
my $filesizeMB = 40;

my $directory  = "../work";
my $prefix     = "file";

GetOptions( "jsonfile=s"        => \$jsonfile,
            "position=s"        => \$position,
            "listnames=s"       => \$listnames,
            "filesize=i"        => \$filesizeMB,
            "directory=s"       => \$directory,
            "prefix=s"          => \$prefix);
my $filesize   = $filesizeMB*1024*1024;
my $basename   = basename($jsonfile,'.json');

open(my $fh, $jsonfile)          or die "Unable to open $jsonfile";
open(my $posfh, $position)       or die "Unable to open $position";
open(my $listfh,$listnames)      or die "Unable to open $listnames";
#
# Create the output directory - if it does not excists
#
if (!-d $directory) {
  mkdir $directory
}
#
# Process the list name file
#
my @listnames;
while (my $line=<$listfh>) {
  chomp($line);
  my ($list,$no) = split(/,/,$line);
  push(@listnames,$list);
  printf "%s\n", $list;
}
close($listfh);
#
# Process the positions
#

my %jsonstruct;

my $bytesize     = 0;
my $objectno     = 0;
my $currentlist  = '';
my $startposition= 0;
my $endposition  = 0;
my $previouslist = '';
my $sequenceno   = 1;
my @objects;
my $total        = 0;
my %items;
while (my $line=<$posfh>) {
  chomp($line);
  # printf "%s\n", $line;
  $objectno++;
  ($currentlist,$startposition,$endposition) = split(/,/,$line);
  $items{$currentlist}++;
  $bytesize += ($endposition - $startposition + 3);
  # printf "%s %d %d %d %d\n", $currentlist,$objectno,$startposition, $endposition,int($bytesize/1024/1024);

  #
  # Track if we have a new list - except first time
  #
  if ($currentlist ne $previouslist) {
    if ($previouslist eq '') {
      # First time we get a new list
      $previouslist = $currentlist;
    }
    else {
      # Next time we get a new list - generate the file
      # printf "Number of objects %d\n", scalar @objects;
      # printf "%s %d %d %d %d\n", $currentlist,$objectno,$startposition, $endposition,int($bytesize/1024/1024);


      generatejson($previouslist,'N');
      $bytesize     = 0;
      for my $i (0..$#objects-1) {
        pop(@objects)
      }
      $previouslist = $currentlist
    }
  }
  #
  # Track if hit the size limit
  #
  elsif ($bytesize > $filesize) {
    # break - generate a new file
    generatejson($previouslist,'S');
    $bytesize = 0;

    for my $i (0..$#objects-1) {
      pop(@objects)
    }

  }
  push(@objects,$line);
}
#
# The remaining objects
#
# printf "The rest %d\n", $#objects;
if ($#objects > 0) {
  generatejson($previouslist,'E')
}
printf "Total %d\n", $total;
my $subtotal = 0;
for my $item (sort keys %items) {
  printf "%s, %d\n", $item, $items{$item}
}
#
# Generate the complete json file based on the lists and the json objects
#
sub generatejson {
  my $activelist = shift;
  my $action     = shift;
  #
  # C$currentlistreate the output file path
  #
  my $outputfilename = sprintf "%sP%04d.json", $basename,$sequenceno;
  $sequenceno++;
  my $fullpath = $directory.'/'.$outputfilename;
  printf "%s, %8d, %8d, %s, %s\n",$action,  $bytesize, $#objects, $fullpath, $previouslist;
  open(my $ofh, ">$fullpath") or die "Unable to create $fullpath";
  printf $ofh "{\n";
  #
  # loop through the lists
  #
  my $items    = scalar @listnames;
  my $lastlist = $listnames[$items-1];
  # printf "Number of Lists: %d\n", $items;

  for my $l (@listnames) {
    # printf "List %s <%s>\n", $l, $activelist;
    printf $ofh "\"%s\" : [\n", $l;
    if ($l eq $activelist) {
      my $numberofobjects = $#objects;
      for my $i (0..$numberofobjects-2) {
        # printf "%3d,%s\n", $i, $objects[$i];
        my ($list,$startposition,$endposition) = split(/,/,$objects[$i]);
        my $json = getjson($fh,$startposition,$endposition);
        # printf "%s\n  ", $json;
        printf $ofh "%s,\n", $json
      }
      my ($list,$startposition,$endposition) = split(/,/,$objects[$numberofobjects-1]);
      my $json = getjson($fh,$startposition,$endposition);
      printf $ofh "%s\n", $json
    }

    if ($l eq $lastlist) {
       printf $ofh "]\n"
    }
    else {
      printf $ofh "],\n"
    }
  }
  printf $ofh  "}\n";
  close($ofh);

}
#
# finduuid - locate the uuid in the input
#
sub finduuid{
  my $input = shift;
  my @lines = split(/\n/,$input);
  for my $line (@lines) {
    if ($line =~ /([a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12})/) {
      printf $fh "%s\n",$1
    }
  }
}
#
# getjson
#
sub getjson{
  my $fh    = shift;
  my $start = shift;
  my $end   = shift;
  # printf "getjson(%d,%d)\n", $start,$end;
  if ( $start <= 0 or $end <= 0) {
    printf "getjson(%d,%d)\n", $start,$end;
    die
  }
  my $buffer;
  seek($fh,$start,SEEK_SET);
  my $bytes = $end - $start;
  my $rb    = read($fh,$buffer,$bytes);
  #
  # Remove the trailing comma
  #
  $buffer =~ s/,$//;
  # printf "getjson: %s",$buffer;
  $total++;
  return $buffer;
}
