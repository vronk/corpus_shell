#!/usr/bin/perl -w

use lib qw(.);
use DDC;
use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use CGI qw(param);
use Encode;

print "Content-Type: text/xml\n\n";

##------------------------------------------------------------------------------
## Constants & Globals
##------------------------------------------------------------------------------
$hts = 0;
$server  = "192.168.0.5";

our $port    = 50000;
our $corpora = '';
our $queryTypeIsRaw = 0;

our $start   = 0;
my $opts = "";
##our $limit   = 200;
our $limit   = 4;
our $timeout = 60;
my $timeString = "";
my $sortOrder = "";

our $columns = 80;
our $query = 'der';

my $shts = "";
my $sTable = "";

##------------------------------------------------------------------------------
##  param evaluation
##------------------------------------------------------------------------------
$sh = param("server");
  if ($sh) {$server = $sh}

$sh = param("start");
  if ($sh) {$start = $sh}

$sh = param("limit");
  if ($sh) {$limit = $sh}

$sh = param("ts");
  if ($sh) {$timeString = $sh}

$sh = param("q");
  if ($sh) {$query = $sh}

$sh = param("textField");
  if ($sh) {$DDC::Format::Text::textField = $sh}

$sh = param("lr");
  if ($sh) {$DDC::Format::Text::lr = $sh}

$sh = param("flds");
  if ($sh) {$DDC::Format::Text::flds = $sh}

$sh = param("corpora");
  if ($sh) {$corpora = $sh}

$opts = param("opts");
  if (index($opts, "deypsil") > -1) {
    $DDC::Format::Text::deypsilonify = 1;
  }
  if (index($opts, "lessByDate") > -1) {
    $sortOrder = " #less_by[dt] ";
  }
  if (index($opts, "lessByAuth") > -1) {
    $sortOrder = " #less_by[author] ";
  }

$sh = param("res");
  if ($sh eq "raw") {$queryTypeIsRaw = 1}
  if ($sh eq "xml") {$queryTypeIsRaw = 2}

$sh = param("type");
  if ($sh eq "w") {
    $query = '$w='.$query;
  }
  if ($sh eq "l")   {
    $query = '$l='.$query;
  }

 $query =~ s/_s_/;/g;
 $query =~ s/_q_/"/g;
 $query =~ s/_a_/&/g;
 $query =~ s/_r_/#/g;
 $query =~ s/_pl_/+/g;

my $q2 = "";
@arr = split(/_/, $query);
$arrlen = @arr;
for ($i=1; $i<@arr; ++$i) {
   $q2 = $q2.chr(int(@arr[$i]));
}
$q2 = encode("utf8", $q2);
$query = $q2.$sortOrder." :".$corpora;

$res = 1;
$resNum = 0;
our $dclient = DDC::Client::Distributed->new(connect=>{PeerAddr=>$server,PeerPort=>$port},
					     start=>$start,
					     limit=>$limit,
					     timeout=>$timeout,
					    );

$DDC::Format::Text::resultLineNumber = 0;

$dclient->open() or $res = 0;
if ($res == 1) {
	$hts = $dclient->query_01($query) or $res = 2;
	$resNum = $#hts;
}

$fmt = DDC::Format::Text->new(columns=>$columns,start=>$start);
$sRes = "<kwic>".$fmt->toXML_01($hts)."</kwic>";

print '<?xml version="1.0" encoding="utf-8"?>'."\n\n";
print "<root><query>$query</query>\n";
print "<q2>$q2</q2>\n";
print "<q4>$q4</q4>\n";
print "<ts>$timeString</ts>\n";
print "<res>$res $#hts</res>\n";
print "<opts>$opts</opts>\n";
print "<start>$start</start>\n";
print "<server>$myip</server>\n";
print "<limit>$limit</limit>\n";
print "<tout>$timeout</tout>\n";
print "<port>$port</port>\n";
##print "<resNum>".$DDC::Format::Text::shts."</resNum>\n";
##print "<resultLineNumber>".$DDC::Format::Text::resultLineNumber."</resultLineNumber>\n";
print "<corpora>$corpora</corpora>\n";
print "$sRes\n\n";
print "</root>\n";
