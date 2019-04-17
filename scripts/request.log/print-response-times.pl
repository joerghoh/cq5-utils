#!/usr/bin/perl -w


BEGIN {
  ## add the directory in which the script is located to the searchpath to find the requestlog module
  if ($0 =~ /\//) {
  	(my $searchpath) = ($0 =~ /(.+)\/[^\/]+/);
  	push @INC, $searchpath;
  }
  
}

use strict;
use Getopt::Long;
use requestlog qw(parseRequestLog);

my $path;


sub printEntry (%) {
  
  my %record=@_;
  
  print "[" . $record{"timestamp"}  . "]" .  $record{"handle"} . " => " . $record{"duration"} . " ms\n" ;

}

foreach my $logfile (@ARGV) {
  parseRequestLog($logfile,undef, \&printEntry);
}
