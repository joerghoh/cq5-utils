package requestlog;

=head1 SYNOPSIS

This module tries to ease the parsing of the request.log files of Day Communique; it allows one to extract the relevant information without fiddling around with the file format.

=cut

use strict;
use warnings;
use Carp;

require Exporter;
our @ISA= qw(Exporter);
our @EXPORT_OK = qw(parseRequestLog);


=head2 parseRequestLog

parseRequestLog($logfile, $record_started, $record_finished)

A wrapper function for the doParse function, which reads from a file.


=cut

sub parseRequestLog($$$) {

  my $logfilename = shift;
  if (! -f $logfilename) { croak "File $logfilename doesn't exist\n";};

  if ($logfilename =~ /.+\.gz$/) {
    open(FILE,"gunzip -c $logfilename |") or croak "Cannot open logfile $logfilename\n";
  } else {
    open(FILE,$logfilename) or croak "Cannot open logfile $logfilename\n";
  }

  return doParse(*FILE,$_[0],$_[1]);
}


=head2 doParse

doParse (filehandle,record_started,record_finished)

Tries to data from filehandle and calls some callbacks

Parameters:
  $filehandle - an open filehandle from which the data is read
  $record_started - reference to a sub to handle started requests
  $record_finished - reference to a sub to handle finished requests

  Each reference may be undef; each sub takes a hash containing the keys "id","timestamp","handle","mimetype", "duration",
  and "statuscode", containing the elements of the record in the file.

parseRequestLog returns a hash with all not finished requests.

=cut

sub doParse($$$) {

  my $FH=shift;
  my $record_started_request_callback = shift;
  my $record_finished_request_callback = shift;

  my %requests=();
  while (my $line = <$FH>) {

    my %record=();

    # 07/Aug/2013:23:02:22 +0200 [0] -> REPORT /crx/server/ HTTP/1.1
    if ((my $timestamp,my $id,my $method, my $handle) = ($line =~ /([0-3][0-9]\/[A-Z][a-z]+\/[0-9]{4}:[0-9]{2}:[0-9]{2}:[0-9]{2} (?:\-|\+)\d+) \[(\d+)\] -> (\S+) (\S+).*/o)) {
	  $requests{"$id"}->{"handle"} = $handle;
	  $requests{"$id"}->{"method"} = $method;
	  $requests{"$id"}->{"id"} = $id;
	  $requests{"$id"}->{"timestamp"} = $timestamp;
	  if (defined($record_started_request_callback)) {
	    $record{"id"}=$id;
	    $record{"handle"}=$handle;
	    $record{"method"}=$method;
	    $record{"timestamp"}=$timestamp;
        &$record_started_request_callback(%record);
		}
	  next;
    }
    
    # 07/Aug/2013:23:02:22 +0200 [0] <- 200 text/xml; charset=UTF-8 91ms
    if ((my $timestamp, my $id,my $statuscode, my $mimetype,my $duration) = ($line =~ /([0-3][0-9]\/[A-Z][a-z]+\/[0-9]{4}:[0-9]{2}:[0-9]{2}:[0-9]{2} (?:\-|\+)\d+) \[(\d+)\] <- (\d+?) (\S+).* (\d+?)ms.*$/o)) {

	if (defined($record_finished_request_callback)) {
	  $record{"id"}=$id;
	  $record{"handle"}=$requests{"$id"}->{"handle"};
	  $record{"timestamp"}=$requests{"$id"}->{"timestamp"};
	  $record{"method"} = $requests{"$id"}->{"method"};
	  $record{"duration"}=$duration;
	  $record{"mimetype"}=$mimetype;
	  $record{"statuscode"}=$statuscode;
	  &$record_finished_request_callback(%record);
	}
	delete $requests{"$id"};
	next;
    }
    # neither "<-" nor "->" lines, so printing a warning
    warn "Cannot handle: $line";
  }
  close($FH);
  return %requests;

}

=head1 AUTHOR

This module was created by Joerg Hoh (joerg@joerghoh.de)

=head1 LICENSE

This code is licensed under GPL version 2.
There's no warranty.

=cut

1;
