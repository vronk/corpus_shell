#!/usr/bin/perl -w

use lib qw(.);
use DDC;
use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use CGI qw(param);
use Encode;
use Template;
#use XML::Simple qw(:strict);

use XML::LibXML;

my $configFile = 'ddc.config';

##------------------------------------------------------------------------------
## Constants & Globals
##------------------------------------------------------------------------------
$hts = 0;

# TODO: investigate
#$query_suffix = " #within file"; # funnily changes the result, so that individual tokens don't get parsed correctly

$query_suffix = " #has_field[availability,/^._s_/] #has_field[site,Wien]"; # vienna version
#$query_suffix = " :barock";
$recordIdBase = "http://corpus4.aac.ac.at/search/searchx?query=__query__&amp;paging=1&amp;query_cql=__query__";

# basel server
#$query_suffix = " #has_field[availability,/^._s_/] #within file #greater_by[random]"  # basler version
#$recordIdBase = "http://chtk.unibas.ch/korpus-c4/search?query=";

our $corpora = '';
our $queryTypeIsRaw = 0;

our $templatePath = "tmpl";

our $response_template = "sru_response_template.xml";
our $diagnostics_template = "sru_diagnostics_template.xml";

our $explain_file = $templatePath . "/explain.xml";
our $scan_collections_file = $templatePath . "/sru_scan_fcs.resource.xml";

our $recordSchema = "http://clarin.eu/fcs/1.0";

our $xmlCache = "/srv/www/htdocs/cstest/xmlCache.pl";
our $imgCache = "/srv/www/htdocs/cstest/imgCache.pl";

our $operation = "";
our $version = "1.2";
our $query = "";
our $startRecord = 1;
our $maximumRecords = 10;
our $recordPacking = "xml";
our $scanClause = "";

our $start   = 0;
my $opts = "";
##our $limit   = 200;
our $limit   = 4;
our $timeout = 60;
my $timeString = "";
my $sortOrder = "";

our $columns = 80;
our $fileMask = "";
our $displayText = "";
my $pageToken = "";
my $xformat = "";

my $shts = "";
my $sTable = "";


##------------------------------------------------------------------------------
##  param evaluation
##------------------------------------------------------------------------------

$sh = param("operation");
  if ($sh) {$operation = $sh}

$sh = param("version");
  if ($sh) {$version= $sh}

$sh = param("startRecord");
  if ($sh) {$startRecord = $sh}

$sh = param("maximumRecords");
  if ($sh) {$maximumRecords = $sh}

$sh = param("query");
  if ($sh)
  {
    $query = $sh;

    my $idx = index($query, "toc=");

    if ($idx >= 0)
    {
      $pageToken = substr($query, $idx + 4);
    }
  }

$sh = param("x-format");
  if ($sh) {$xformat = $sh}

$sh = param("x-ccs-fields");
  if ($sh) {$DDC::Format::Text::flds = $sh}

$sh = param("x-context");
  if ($sh) {$context = $sh;}

$sh = param("scanClause");
  if ($sh) {$scanClause = $sh}

$sh = param("recordPacking");

  if ($sh && $sh eq "raw") {$queryTypeIsRaw = 1}
  if ($sh && $sh eq "xml") {$queryTypeIsRaw = 2}

if ($context eq "" && $operation eq "searchRetrieve")
{
 	#param "x-context" is missing
 	diagnostics(7, "x-context");
 	return;
}

if ($context ne "")
{
  my $parser = XML::LibXML->new();
  my $doc    = $parser->parse_file($configFile);
  my $oldContext = $context;

  foreach my $item ($doc->findnodes('//item'))
  {
#    my $key = $item->findnodes('./key');
#    if ($key->to_literal eq $context)
#    {
#      my($name) = $item->findnodes('./name');
#      $context =  $name->to_literal;
#      my($par) = $key->findnodes('../../../ip');
#      $server = $par->to_literal;
#      my($par1) = $key->findnodes('../../../port');
#      $port = $par1->to_literal;
#      my($mask) = $item->findnodes('./fileMask');
#      $fileMask = $mask->to_literal;
#      my($txt) = $item->findnodes('./displayText');
#      $displayText = $txt->to_literal;
#    }
    my($key) = $item->findnodes('./key');
    if ($key->to_literal eq $context)
    {
      my($name) = $item->findnodes('./name');
      $context =  $name->to_literal;
      my($par) = $key->findnodes('../../../ip');
      $server = $par->to_literal;
      my($par1) = $key->findnodes('../../../port');
      $port = $par1->to_literal;

      if ($item->exists('./fileMask'))
      {
        my($mask) = $item->findnodes('./fileMask');
        $fileMask = $mask->to_literal;
      }

      my($txt) = $item->findnodes('./displayText');
      $displayText = $txt->to_literal;
    }
  }
  if ($oldContext eq $context)
  {
    ##search index was not found
    diagnostics(6, $context);
    return;
  }
}

### Diagnostics
# http://www.loc.gov/standards/sru/resources/diagnostics-list.html
#if (! $operation eq 'explain' || operation eq 'searchRetrieve')
#	$d = new Diagnostics(4);


 $query =~ s/_s_/;/g;
 $query =~ s/_q_/"/g; #"
 $query =~ s/_a_/&/g;
 $query =~ s/_r_/#/g;
 $query =~ s/_pl_/+/g;

  #$query = $query.$sortOrder." :".$corpora;

#  $query = $query.' #less_by[dt]'." :".$corpora;
#$query = '$p=NN:frs_03';
#$query = 'Mythus'; # :freud_td_01';
#$query = '$w=der:freud_td_01';
	#$query = 'NEAR($l=gehen;$l=mit;3)';
	#$query = 'NEAR($p=ADJA;$p=NN && $l=Katze;1)';

#print $query;

### Handle default explain-operation
if ($operation eq "explain" || !$operation)
{
  print "Content-Type: text/xml\n\n";

 	open(IN,'<'.$explain_file) || die "Can not open file $explain_file: $!";

		while(<IN>)
		{
  		next if ($_=~ /^#/);
  		print "$_\n";
		}

		close IN;
	 return;
}

### Handle scan cmd-collections
if ($operation eq "scan" )
{
 	if ($scanClause eq "fcs.resource" )
 	{
 		 print "Content-Type: text/xml\n\n";

    open(IN,'<'.$scan_collections_file) || die "Can not open file $scan_collections_file: $!";
 			while(<IN>)
 			{
 			  print "$_\n";
 			}
 			close IN;
 	}
 	elsif ($scanClause eq "fcs.toc" )
 	{
 		 fcsToc($contextOriginal, $fileMask, $displayText);
 	}
 	else
 	{
 		 diagnostics(6, $scanClause) ; # unsupported parameter value
 	}

		return;
}

if (($operation eq "searchRetrieve") and ($pageToken ne ""))
{
  if ($xformat eq "img")
  {
    getImageByPid($fileMask, $pageToken);
  }
  else
  {
    getXmlByPid($fileMask, $pageToken);
  }
  return;
}

print "Content-Type: text/xml\n\n";

our $dclient = DDC::Client::Distributed->new(connect=>{PeerAddr=>$server,PeerPort=>$port},
					     start=>$startRecord,
					     limit=>$maximumRecords,
					     timeout=>$timeout,
					    );

$res = 1;
$resNum = 0;
$DDC::Format::Text::resultLineNumber = 0;

# apply restricting to free texts (for anonymous users)  - to be inline with deployed webapps
if ($context)
{
 	$query_suffix = ':'.$context;
}
$query_= $query.$query_suffix;

$dclient->open() or $res = 0;
if ($res == 1) {
	($hits_count, $hits) = $dclient->query02($query_) ;
	#$hits = $dclient->query_01($query) or $res = 2;
	$resNum = $#hits;
 }

$fmt = DDC::Format::Text->new(columns=>$columns,start=>$startRecord);

# mainly for debugging, you could pass the formatted string into the template

#$res = $fmt->toString($hits);
# hack to escape ampersand;
$res =~ s/&/&amp;/g;
#$sRes = "<records>".$res."</records>";
#$sRes = @hits;

#print $query_;
#$sRes = "<kwic>".$fmt->toString($hits)."</kwic>";
#print $sRes;

$recordIdBase =~ s/__query__/$query/g;

my $vars = {
    version => $version,
    startRecord => $startRecord,
    numberOfRecords  => $hits_count,
    recordSchema => $recordSchema,
    recordPacking => $recordPacking,
    query => $query,
    hits => $hits,
    recordIdBase => $recordIdBase."&amp;start=",
    resourceFragmentIdColumn => "4",
 #   res => $res,
    parse_context => sub { my ($context,$kws) = @_; return parse_context($context, $kws)},
  };


my $tt = Template->new({
    INCLUDE_PATH => $templatePath,
    INTERPOLATE  => 1,
}) || die "$Template::ERROR\n";

$tt->process($response_template, $vars)
    || die $tt->error(), "\n";


### this is called from the sru_response_template.xml
# to parse the context of individual hit.
# sample:
# Und#KON#und#74 du#PPER#du#75 kamest#VVFIN#kamest#76 in#APPR#in#77 mein#PPOSAT#mein#78 Haus#NN#Haus#79,#$,#,#80

sub parse_context($@)
{
	my ($context, $kws) = @_;
	# print "DEBUG: context:".$context;
	# important to use @{$kws} later in code, otherwise it won't be handled correctly as an array.
	# ( man, it took time to find out.)
	# eg like this:
	#	for $i (@{$kws}) {		print $i;	}

	# the simple split would be just on whitespaces:
	#	my @tokens = split (/ /, $context);
	# but we need a special handling for punctuation - due to ddc glueing punctuation together with the previous token.
	my @tokens = split (/(?:   						# therefore the parenthesis for alternative  |
																				#  (?: - non capturing parenthesis
													\s|           # this is the default for the whitespace
													(?=[\,\.\!\/\(\:;\?][\#\^]\$))   # this captures the starting of a punct-token:  `.#$` or `,#$`
											/x   #  /x modifier allows for comments and ignoring most whitespaces in the pattern
	 												 # (?= ...  = lookahead assertion (splits before a pattern, but includes the pattern in the return
													 # simple parenthesis, would split the punct-token once too often.
					, $context);


	my @tiered_tokens;
	my $i =0;
	my $j =0;
		foreach (@tokens) {
#		 print $_;
		 @token_fields = split(/\#|\^/, $_);
		 next if (@token_fields < 2);
		 $w = $token_fields[0];

		 # check if keyword is marked with &&,
		 if ($w =~ /^&&/) {
		 		$is_kw = 1;
		 		# $w =~ s/^&&//;
		 } else {
		 		$is_kw = 0;
		 	}

		 $w =~ s/&/&amp;/g;
		 #$w = $token_field;
		 # print $w;

		 		# this is fall-back for marking the keyword (if it was not marked with &&),
		 		# to match it based on the matched keywords as (alternatively) returned by ddc
		 $is_kw = $is_kw || grep { $_ eq $w } @{$kws};
			my %token = ();
			$token{"kw"} = $is_kw;
		  # print "is_kw:".$is_kw;

		 # this should go easier, but had problems assigning the split-fields-array as one item in the tokens-array.
		 $j=0;
		 	foreach $f (@token_fields) {
		 		#$tiered_tokens[$i][$j] = $f;
		 		# remove if keyword is marked with &&
		 		$f =~ s/&&//g;
		 		$f =~ s/&/&amp;/g;
		 		$token{$j} = $f;
		 		$j++;
		 	}
		 	$tiered_tokens[$i] = \%token;
		 	#print $tiered_tokens[$i];
		$i++;
	}
		return @tiered_tokens;
}

sub fcsToc()
{
  my ($context, $mask, $text) = @_;

  if ($mask eq "")
  {
    diagnostics(27, "x-context");  #Empty term unsupported
    return;
  }

  require $xmlCache;

  my @subArray = grep(/$mask/,@xmlArray);

  print "Content-Type: text/xml\n\n";
  print '<?xml version="1.0" encoding="utf-8"?>';
  print "\n";
  print '<sru:scanResponse xmlns:sru="http://www.loc.gov/zing/srw/">';
  print "\n  <sru:version>1.2</sru:version>\n";
  print "  <sru:terms>\n";

  my $maskLen = length($mask);

  foreach(@subArray)
  {
    my $i = index($_, $mask);
    if ($i >= 0)
    {
      $i += $maskLen;
      my $hstr = substr($_, $i, 5);
      my $pageType = substr($hstr, 0, 1);
      my $pageTypeText;

      if ($pageType eq 'a')
      {
        $pageTypeText = "A-Page";
      }
      elsif ($pageType eq 'i')
      {
        $pageTypeText = "I-Page";
      }
      elsif ($pageType eq 'u')
      {
        $pageTypeText = "U-Page";
      }
      else
      {
        $pageTypeText = "Page";
      }

      my $pageNo = substr($hstr, 1, 4);
      while (substr($pageNo, 0, 1) eq '0')
      {
        $pageNo = substr($pageNo, 1);
      }

      print "    <sru:term>\n";
      print "      <sru:value>$context|$hstr</sru:value>\n";
      print "      <sru:numberOfRecords>1</sru:numberOfRecords>\n";
      print "      <sru:displayTerm>$text, $pageTypeText $pageNo</sru:displayTerm>\n";
      print "    </sru:term>\n";
    }
  }
  print "  </sru:terms>\n";
  print "</sru:scanResponse>\n";

  return;
}

sub getImageByPid()
{
  my ($mask, $pageNo) = @_;

  require $imgCache;

  my $hstr = $mask.$pageNo;
  my @subArray = grep(/$hstr/, @imgArray);
  my $count = @subArray;

  if ($count != 0)
  {
    returnImage($subArray[0]);
  }
}

sub returnImage()
{
  my ($img) = @_;

  open IMAGE, $img;

  #assume is a jpeg...
  my ($image, $buff);
  while(read IMAGE, $buff, 1024)
  {
    $image .= $buff;
  }

  close IMAGE;
  print "Content-type: image/jpeg\n\n";
  print $image;
}

sub getXmlByPid()
{
  my ($mask, $pageNo) = @_;

  require $xmlCache;

  my $hstr = $mask.$pageNo;
  my @subArray = grep(/$hstr/, @xmlArray);
  my $count = @subArray;

  if ($count != 0)
  {
    returnText($subArray[0]);
  }
}

sub returnText()
{
  my ($txt) = @_;

  print "Content-Type: text/xml\n\n";
 	open(IN,'<'.$txt) || die "Can not open file $explain_file: $!";

		while(<IN>)
		{
  		print "$_\n";
		}

		close IN;
}

sub diagnostics () {

	my ($dgId, $dgDetails) = @_;

# TODO: this needs to be based on diagnostics-list:
# http://www.loc.gov/standards/sru/resources/diagnostics-list.html

my %errorMessages = (
1   => "General system error",
2   => "System temporarily unavailable",
3   => "Authentication error",
4   => "Unsupported operation",
5   => "Unsupported version",
6   => "Unsupported parameter value",
7   => "Mandatory parameter not supplied",
8   => "Unsupported Parameter",
10  => "Query syntax error",
12  => "Too many characters in query",
13  => "Invalid or unsupported use of parentheses",
14  => "Invalid or unsupported use of quotes",
15  => "Unsupported context set",
16  => "Unsupported index",
18  => "Unsupported combination of indexes",
19  => "Unsupported relation",
20  => "Unsupported relation modifier",
21  => "Unsupported combination of relation modifers",
22  => "Unsupported combination of relation and index",
23  => "Too many characters in term",
24  => "Unsupported combination of relation and term",
26  => "Non special character escaped in term",
27  => "Empty term unsupported",
28  => "Masking character not supported",
29  => "Masked words too short",
30  => "Too many masking characters in term",
31  => "Anchoring character not supported",
32  => "Anchoring character in unsupported position",
33  => "Combination of proximity/adjacency and masking characters not supported",
34  => "Combination of proximity/adjacency and anchoring characters not supported",
35  => "Term contains only stopwords",
36  => "Term in invalid format for index or relation",
37  => "Unsupported boolean operator",
38  => "Too many boolean operators in query",
39  => "Proximity not supported",
40  => "Unsupported proximity relation",
41  => "Unsupported proximity distance",
42  => "Unsupported proximity unit",
43  => "Unsupported proximity ordering",
44  => "Unsupported combination of proximity modifiers",
46  => "Unsupported boolean modifier",
47  => "Cannot process query; reason unknown",
48  => "Query feature unsupported",
49  => "Masking character in unsupported position",
50  => "Result sets not supported",
51  => "Result set does not exist",
52  => "Result set temporarily unavailable",
53  => "Result sets only supported for retrieval",
55  => "Combination of result sets with search terms not supported",
58  => "Result set created with unpredictable partial results available",
59  => "Result set created with valid partial results available",
60  => "Result set not created: too many matching records",
61  => "First record position out of range",
64  => "Record temporarily unavailable",
65  => "Record does not exist",
66  => "Unknown schema for retrieval",
67  => "Record not available in this schema",
68  => "Not authorised to send record",
69  => "Not authorised to send record in this schema",
70  => "Record too large to send",
71  => "Unsupported record packing",
72  => "XPath retrieval unsupported",
73  => "XPath expression contains unsupported feature",
74  => "Unable to evaluate XPath expression",
80  => "Sort not supported",
82  => "Unsupported sort sequence",
83  => "Too many records to sort",
84  => "Too many sort keys to sort",
86  => "Cannot sort: incompatible record formats",
87  => "Unsupported schema for sort",
88  => "Unsupported path for sort",
89  => "Path unsupported for schema",
90  => "Unsupported direction",
91  => "Unsupported case",
92  => "Unsupported missing value action",
93  => "Sort ended due to missing value",
110 => "Stylesheets not supported",
111 => "Unsupported stylesheet",
120 => "Response position out of range",
121 => "Too many terms requested");

my $diagnosticMessage = $errorMessages{$dgId};

my $vars = {
    version => $version,
    diagnosticId => $dgId,
    diagnosticMessage =>  $diagnosticMessage,
    diagnosticDetails => $dgDetails
  };

print "Content-Type: text/xml\n\n";

my $tt = Template->new({
    INCLUDE_PATH => $templatePath,
    INTERPOLATE  => 1,
}) || die "$Template::ERROR\n";

$tt->process($diagnostics_template, $vars)
    || die $tt->error(), "\n";
}

