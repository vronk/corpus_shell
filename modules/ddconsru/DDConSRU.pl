#!/usr/bin/perl -w

# adding the directory of this script
# (is not the same as cwd, when running on server)
# only necessary when running as cgi-script

use lib "/srv/www/perl-lib";
use DDC;
use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use CGI qw(param);
use Encode;
use Template;
use Diagnostics;
use lib "/srv/www/htdocs/cs2/corpus_shell/modules/get-data";
use getData;
#use XML::Simple qw(:strict);

use XML::LibXML;

my $configFile = '/srv/www/htdocs/cs2/corpus_shell/modules/ddconsru/ddc.config';

our $xmlCache = "/srv/www/htdocs/cstest/xmlCache.pl";

##------------------------------------------------------------------------------
## Constants & Globals
##------------------------------------------------------------------------------
$hts = 0;

# TODO: investigate
#$query_suffix = " #within file"; # funnily changes the result, so that individual tokens don't get parsed correctly

$query_suffix = " #has_field[availability,/^._s_/]"; # vienna version #has_field[site,Wien]
#$query_suffix = " :barock";

my $localhost = "corpus3.aac.ac.at";

my $cgi = new CGI;
my $url = $cgi->url(-query => 1);

$url =~ s/&amp;/&/g;
$url =~ s/;/&/g;
$url = URLDecode($url);
$url =~ s/&&/&/g;
$url =~ s/&/&amp;/g;
$recordIdBase = $url;
$url =~ s/query=.*&amp;/&amp;/g;
$url =~ s/query=.*//g;
$url =~ s/x-format=.*&amp;/&amp;/g;
$url =~ s/x-format=.*//g;
$url =~ s/(&amp;)+/&amp;/g;

$url =~ s/localhost/$localhost/g;
$url =~ s/127\.0\.0\.1/$localhost/g;


#$recordIdBase = "http://corpus3.aac.ac.at/ddconsru?operation=searchRetrieve&x-context=clarin.at:icltt:ddc:barock&query=__query__";

# basel server
#$query_suffix = " #has_field[availability,/^._s_/] #within file #greater_by[random]"  # basler version
#$recordIdBase = "http://chtk.unibas.ch/korpus-c4/search?query=";

our $corpora = '';
our $queryTypeIsRaw = 0;

our $templatePath = "tmpl";

our $response_template = "sru_response_template.xml";

our $explain_file = $templatePath . "/explain.xml";
our $scan_collections_file = $templatePath . "/sru_scan_fcs.resource.xml";

our $recordSchema = "http://clarin.eu/fcs/1.0";

our $context = "";

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

our $wIdx = "0";
our $sIdx = "-1";
our $fIdx = "-1";
our $showIndexes = "";
our $extLink = "";
our $fullLink = "";


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

$sh = param("responsePosition");
  if ($sh) {$responsePosition = $sh}

$sh = param("maximumTerms");
  if ($sh) {$maximumTerms = $sh}

if ($context eq "" && $operation eq "searchRetrieve")
{
  #param "x-context" is missing
  Diagnostics::diagnostics(7, "x-context");
  return;
}

my $oldContext = $context;

if ($context ne "")
{
  my $parser = XML::LibXML->new();
  if (!(-e $configFile))
  {
    print STDERR "---- File NOT found: $configFile ---- \n";
  }
  my $doc = $parser->parse_file($configFile);

  my $serverFound = 0;
  foreach my $serverNode ($doc->findnodes('//server'))
  {
    my($key) = $serverNode->findnodes('./key');
    if ($key->to_literal eq $context)
    {
      my $str = $key->to_literal;
      print STDERR "---- Server found: $str ---- \n";

      $serverFound = 1;
      $context = "";

      my($par) = $serverNode->findnodes('./ip');
      $server = $par->to_literal;
      print STDERR "---- Server found: $server ---- \n";

      my($par1) = $serverNode->findnodes('./port');
      $port = $par1->to_literal;
      print STDERR "---- Server found: $port ---- \n";
    }
  }

  if ($serverFound == 0)
  {
    print STDERR "---- Server NOT found: $context ---- \n";

    foreach my $item ($doc->findnodes('//item'))
    {
      my($key) = $item->findnodes('./key');
      if ($key->to_literal eq $context)
      {
        # get the internal name of the corpus (to be given to ddc as context)
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

        if ($item->exists('./dataview[@type=\'external\']/@ref'))
        {
          my($eLink) = $item->findnodes('./dataview[@type=\'external\']/@ref');
          $extLink = $eLink->to_literal;
        }

        if ($item->exists('./dataview[@type=\'full\']/@ref'))
        {
          my($fLink) = $item->findnodes('./dataview[@type=\'full\']/@ref');
          $fullLink = $fLink->to_literal;
        }

        if ($item->exists('./index[@key=\'w\']'))
        {
          my($wordIndex) = $item->findnodes('./index[@key=\'w\']');
          $wIdx = $wordIndex->to_literal;
        }

        if ($item->exists('./index[@key=\'s\']'))
        {
          my($sentIndex) = $item->findnodes('./index[@key=\'s\']');
          $sIdx = $sentIndex->to_literal;
        }

        if ($item->exists('./index[@key=\'f\']'))
        {
          my($fileIndex) = $item->findnodes('./index[@key=\'f\']');
          $fIdx = $fileIndex->to_literal;
        }

			if ($item->exists('./showIndexes'))
        {
          my($showIdnexes_node) = $item->findnodes('./showIndexes');
          $showIndexes = $showIdnexes_node->to_literal;
        }

				# prepending "$" to (known) indices (if not already present)
        foreach my $indexItem ($item->findnodes('./index[@key]'))
        {
          my $key = $indexItem->findvalue('./@key');

          ##print STDERR "---- key: $key ---- query: $query ---- \n";
          if (($query =~ m/$key=/) && ($query !~ m/\$$key=/))
          {
            $query =~ s/$key=/\$$key=/g;
          }
        }

        my($txt) = $item->findnodes('./displayText');
        $displayText = $txt->to_literal;
      }
    }
  }

  print STDERR "---- Error: $oldContext -- $context ---- \n";

  if ($oldContext eq $context)
  {
    ##search index was not found
    Diagnostics::diagnostics(6, $context);
    return;
  }
}

$url =~ s/http:\/\/$localhost\/ddconsru/$fullLink/g;

### Diagnostics
# http://www.loc.gov/standards/sru/resources/diagnostics-list.html
#if (! $operation eq 'explain' || operation eq 'searchRetrieve')
# $d = new Diagnostics(4);

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
    fcsToc($oldContext, $fileMask, $displayText);
  }
  elsif (($responsePosition ne "") and ($maximumTerms ne "") and (index($scanClause, "=") ne -1))
  {

  }
  else
  {
    Diagnostics::diagnostics(6, $scanClause) ; # unsupported parameter value
  }

  return;
}

if (($operation eq "searchRetrieve") and ($pageToken ne ""))
{
  if ($xformat eq "img")
  {
    GetData::getImageByPid($fileMask, $pageToken);
  }
  else
  {
    GetData::getXmlByPid($fileMask, $pageToken, $oldContext);
  }
  return;
}

our $dclient = DDC::Client::Distributed->new(connect=>{PeerAddr=>$server,PeerPort=>$port},
          start=>$startRecord,
          limit=>$maximumRecords,
          timeout=>$timeout,
         );

print STDERR "---- ddc config PeerAddr: $server, PeerPort: $port ---- \n";

##print STDERR "---- ddc reality PeerAddr: $serverAddr, PeerPort: $port ---- \n";


$res = 1;
$resNum = 0;
$DDC::Format::Text::resultLineNumber = 0;

# apply restricting to free texts (for anonymous users)  - to be inline with deployed webapps
if (($context) && ($context ne ""))
{
  $query_suffix = ':'.$context;
}
else
{
  $query_suffix = "";
}
$query_= $query.$query_suffix;

$dclient->open() or $res = 0;
if ($res == 1)
{
   print "Content-Type: text/xml\n\n";
   ($hits_count, $hits) = $dclient->query02($query_) ;
   #$hits = $dclient->query_01($query) or $res = 2;
   $resNum = $#hits;
}
else
{
   ## 2 - System temporarily unavailable
   Diagnostics::diagnostics(2, $oldContext);
   return;
}

print STDERR "---- ddc $hits_count ---- \n";

$fmt = DDC::Format::Text->new(columns=>$columns,start=>$startRecord);

# mainly for debugging, you could pass the formatted string into the template

#$res = $fmt->toString($hits);
# hack to escape ampersand;
$res =~ s/&/&amp;/g;
#$sRes = "<records>".$res."</records>";
#$sRes = @hits;

#print "query_raw:".$query_;
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
    wIdx => $wIdx,
    sIdx => $sIdx,
    showIndexes => $showIndexes,
    fIdx => $fIdx,
    url => $url,
    fileMask => $fileMask,
    extLink => $extLink,
    recordIdBase => $recordIdBase."&amp;startRecord=",
    resourceFragmentIdColumn => "4",
 #   res => $res,
    parse_context => sub { my ($context, $kws, $wIdx, $sIdx, $extLink, $fIdx, $fileMask, $url) = @_;
     return parse_context($context, $kws, $wIdx, $sIdx, $extLink, $fIdx, $fileMask, $url)},
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
  my ($context, $kws, $wIdx, $sIdx, $extLink, $fIdx, $fileMask, $url) = @_;
  # print "DEBUG: context:".$context;
  # important to use @{$kws} later in code, otherwise it won't be handled correctly as an array.
  # ( man, it took time to find out.)
  # eg like this:
  # for $i (@{$kws}) {  print $i; }

  # the simple split would be just on whitespaces:
  # my @tokens = split (/ /, $context);
  # but we need a special handling for punctuation - due to ddc glueing punctuation together with the previous token.
  my @tokens = split (/(?:         # therefore the parenthesis for alternative  |
                     #  (?: - non capturing parenthesis
              \s|           # this is the default for the whitespace
              (?=[\,\.\!\/\(\:;\?][\#\^]\$))   # this captures the starting of a punct-token:  `.#$` or `,#$`
            /x   #  /x modifier allows for comments and ignoring most whitespaces in the pattern
                # (?= ...  = lookahead assertion (splits before a pattern, but includes the pattern in the return
               # simple parenthesis, would split the punct-token once too often.
      , $context);

  my $wordrange = 5;
  my $kwIdx = -1;

  my @tiered_tokens;
  my $i =0;
  my $j =0;

  foreach (@tokens) {
#   print $_;
   @token_fields = split(/\#|\^/, $_);
   next if (@token_fields <= $wIdx);
   $w = $token_fields[$wIdx];

   if (($sIdx ne "-1") && ($extLink ne ""))
   {
     $token_fields[$sIdx] = $extLink . $token_fields[$sIdx];
   }

   if (($fIdx ne "-1") && ($fileMask ne ""))
   {
     my $hstr = $token_fields[$fIdx];
     $hstr =~ s/$fileMask//g;
     $hstr =~ s/\..*//g;

     $hstr = $url . "&amp;query=toc=" . $hstr;
     $hstr =~ s/(&amp;)+/&amp;/g;
     $token_fields[$fIdx] = $hstr;
   }

   # check if keyword is marked with &&,
   if ($w =~ /^&&/) {
     $is_kw = 1;
     # $w =~ s/^&&//;
     $kwIdx = $i;
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

  if ($kwIdx != -1)
  {
    if ($tiered_tokens < $kwIdx + $wordrange + 1)
    {
     splice(@tiered_tokens, $kwIdx + $wordrange + 1);
    }

    if ($kwIdx - $wordrange > 0)
    {
      splice(@tiered_tokens,0,$kwIdx-$wordrange);
    }
  }

  return @tiered_tokens;
}

sub fcsToc()
{
  my ($context, $mask, $text) = @_;

  if ($mask eq "")
  {
    Diagnostics::diagnostics(27, "x-context");  #Empty term unsupported
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

sub URLDecode
{
  my $theURL = $_[0];
  $theURL =~ tr/+/ /;
  $theURL =~ s/%([a-fA-F0-9]{2,2})/chr(hex($1))/eg;
  $theURL =~ s/<!--(.|\n)*-->//g;
  return $theURL;
}
