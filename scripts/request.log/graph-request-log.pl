#!/usr/bin/perl -w
#
# Written by Joerg Hoh (joerg@joerghoh.de)
#   released under Apache License 2
#
# Purpose: 
#  * parses CQ request.log files and creates output which is suitable for gnuplot
#
# a common pattern to call is:
# ./graph-request-log.pl --title "request log" --output=today.png /path/to/crx-quickstart/logs/request.log | gnuplot

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

####### The tunables ##########
my $graph_title="gimme a title!!";

my $mime_opt=".*";          # match all -- no filter
my $path_opt=".*";          # match all -- no filter

my $slow_requests=2; # in percent

my $auto_tune=0;


######## Values for gnuplot ###############
my $output_width=770;
my $time_axis_label="%H:%M";


######## SUBS ###############

my $mime_match;
my $path_match;
my $output="output.png";

my %timetable;

my $statuscode=0;


##########################################
#
# checks a found valid request record if it matches the given criteria
#
##########################################
sub evalID(%) {
  my %record=@_;

  # timestamps are something like this: 07/Aug/2013:23:02:22 +0200

  return if (!defined $record{"timestamp"});
  return if (!defined $record{"duration"});
  #printf "timestamp=%s, duration=%s id=%s\n",$record{"timestamp"},$record{"duration"},$record{"id"};

  (my $ts) = ($record{"timestamp"} =~ /^(\d+\/[a-zA-Z]{3}\/\d+:\d+:\d+):\d+/);
  if (! exists $timetable{"$ts"}){
    $timetable{"$ts"}->{"count"} = 0;
    $timetable{"$ts"}->{"time_sum"} = 1;
  }

  if ($statuscode != 0) {
    return if ($record{"statuscode"} != $statuscode);
  }

  # match the filters
  return if (!defined $record{"mimetype"});
  return if ($record{"mimetype"} !~ /$mime_match/); 
  

  return if (!defined $record{"handle"});
  return if ($record{"handle"} !~ /$path_match/o);

  $timetable{"$ts"}->{"count"} = $timetable{"$ts"}->{"count"} +1;
  $timetable{"$ts"}->{"time_sum"} = $timetable{"$ts"}->{"time_sum"} + $record{"duration"};

  push @{$timetable{"$ts"}->{"stamps"}}, $record{"duration"};

}



sub printUsage() {
  print <<EOF

  Print a graphical version of a CQ5 request.log file
 
  $0 [options] file ...
  --title TITLE         - the title of the output graph
  --mime MATCH          - only analyze requests which have the MATCHing mime type set (regexp allowed)
  --statuscode STATUS   - the numerical HTTP statuscode, which must match (default: all match)
  --path-match MATCH    - only analyze requests which URL does match the regular expression MATCH
  --width=WIDTH         - the width of the generated image in pixels, default is 770
  --auto                - enable auto tuning to set various settings to reasonable values
  --output FILENAME     - the name of the file where to put the resulting graph
  --help                - print this and exit 
 
  Filtering:
  --mime, --path-match and --statuscode are additive.
 

  all files are evaluated and integrated in this output
  
  result will be displayed on STDOUT, which you can pipe directly into gnuplot
  without any further parameters (the final image filename can be given to the --output parameter)

EOF
}


######### Start ##########


#print STDERR join (" ", @ARGV,"\n");

my $result = GetOptions("title=s" => \$graph_title,
                        "mime=s" => \$mime_opt,
                        "statuscode=s" => \$statuscode,
                        "path-match=s" => \$path_opt,
                        "width=s" => \$output_width,
                        "output=s" => \$output,
                        "auto" => sub {$auto_tune = 1;},
                        "help" => sub { printUsage(); exit 1;}
                        );

# strip quotes
$mime_opt=~s/['"]//g;
$path_opt=~s/['"]//g;

$mime_match=qr/$mime_opt/; 
$path_match=qr/$path_opt/; 

my $noinputfiles = $#ARGV +1; 


# enable auto tuning of parameters
if ( $auto_tune) {
  if ($noinputfiles > 3) {
    $output_width = 1000;
    $time_axis_label="%d.%m"; 
  }
}


foreach my $logfilename (@ARGV) {
  parseRequestLog($logfilename,undef,\&evalID);
}


##### construct the title string ############
my $add_title="";
if ($path_opt !~ /\.\*/) {
  $add_title .= "URL-match = $path_opt ";
}
if ($mime_opt !~ /\.\*/) {
  $add_title .= "Mime-type = $mime_opt";
}

if ($add_title ne "" ) {
  $add_title = "(" . $add_title . ")";
}

# 07/Aug/2013:23:02:22 +0200
######## create gnuplot output  ############

print <<EOF;
#!/usr/bin/gnuplot -persist

set timefmt "%d/%b/%Y:%H:%M"
set format x "$time_axis_label"
set xdata time
set title "$graph_title $add_title"
set xlabel "Time"
set ylabel "answered requests per minute"
set y2label "response time per request [ms]"
set term png small size $output_width,400 
set y2tics 
set logscale y2
set grid
set output "$output"

#set logscale y2 2
#set y2range [:5000]

plot "-" using 1:4 axes x1y2  title "delivery time per request (98% percentile)" , \\
     "-" using 1:5 axes x1y2  title "delivery time per request (median)", \\
     "-" using 1:2  title "number of requests (per minute)" 
EOF
 

my $average = 0;
my $percentile98 = 0;
my $median=0;
my $count;

# because we want to keep all gnuplot commands and data inline, we 
# need to print all data for each plot command. See gnuplot docs for more information.
# the "e" character followed by a newline describes the end of one dataset.

foreach (1..3) {
  my @keys = sort (keys %timetable);
  foreach my $k (@keys) {
    if ($k) {
	  $count = $timetable{"$k"}->{"count"};
      $average = 1; $percentile98=1; $median=1;
      if ($count != 0) { 
        $average = int($timetable{"$k"}->{"time_sum"}/$count); 
      }
         
      # calculate the 98% percentile
      if ($timetable{"$k"}->{"stamps"}) {
	    my @stamps = sort {$a <=> $b} @{$timetable{"$k"}->{"stamps"}};
	    my $nr = int ($#stamps/100*98);
	    
	    $percentile98 = $stamps[$nr];
	    #printf "stamps = %s, nr = %s, 98%%=%d\n",join (",",@stamps), $nr, $percentile98;
	    
	    $nr = int ( $#stamps/2);
	    $median = $stamps[$nr];
		  
      }
      
      # output
	  printf "%s %s %d %d %d\n",$k,$count,$average,$percentile98, $median;
    }

  }
  print "e\n";
}

# that's it
