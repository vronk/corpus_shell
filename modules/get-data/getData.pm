package GetData;

use Template;
use List::Util qw(first);
use File::Basename;

our $xmlCache = "/srv/www/htdocs/cstest/xmlCache.pl";
our $imgCache = "/srv/www/htdocs/cstest/imgCache.pl";

our $templatePath = "tmpl";

our $contentTemplate = "sru_response_content_template.xml";

######################################################################

sub getImageByPid($@)
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

sub returnImage($@)
{
  my ($img) = @_;

  open IMAGE, $img;

  #assume it is a jpeg...
  my ($image, $buff);
  while(read IMAGE, $buff, 1024)
  {
    $image .= $buff;
  }

  close IMAGE;
  print "Content-type: image/jpeg\n\n";
  print $image;
}

sub getXmlByPid($@)
{
  my ($mask, $pageNo, $xcontext) = @_;

  require $xmlCache;

  my $hstr = $mask.$pageNo;
  my @subArray = grep(/$hstr/, @xmlArray);
  my $count = @subArray;

  if ($count != 0)
  {
    my $idx = first { $xmlArray[$_] =~ /$hstr/ } 0 .. $#xmlArray;
    my $prevPid = ($idx > 0) ? $xmlArray[$idx - 1] : "";

    my @dummy = fileparse($prevPid, qr/\.[^.]*/);
    $prevPid = $dummy[0];
    $prevPid =~ s/$mask//g;

    my $cnt = @xmlArray;
    my $nextPid = ($idx + 1 < $cnt) ? $xmlArray[$idx + 1] : "";

    @dummy = fileparse($nextPid, qr/\.[^.]*/);
    $nextPid = $dummy[0];
    $nextPid =~ s/$mask//g;

    returnText($subArray[0], $pageNo, $prevPid, $nextPid, $xcontext);
  }
}

sub returnText($@)
{
  my ($txt, $pageNo, $prevPid, $nextPid, $xcontext) = @_;

  print "Content-Type: text/xml\n\n";
 	open(IN,'<'.$txt) || die "Can not open file $txt: $!";

  my $lines = "";

		while(<IN>)
		{
    my $hstr = "$_\n";
    if (!($hstr =~ m/^<\?/))
    {
      $lines .= $hstr;
    }
		}

		close IN;

		addSruWrapper($lines, $pageNo, $prevPid, $nextPid, $xcontext);
}

sub addSruWrapper($@)
{
   my ($content, $pageNo, $prevPid, $nextPid, $xcontext) = @_;

   my $prevRef = "http://corpus3.aac.ac.at/switch?x-context=" . $xcontext . "&operation=searchRetrieve&version=1.2&recordPacking=xml&x-format=html&version=1.2&query=toc=" . $prevPid;
   my $nextRef = "http://corpus3.aac.ac.at/switch?x-context=" . $xcontext . "&operation=searchRetrieve&version=1.2&recordPacking=xml&x-format=html&version=1.2&query=toc=" . $nextPid;
   $prevRef =~ s/&/&amp;/g;
   $nextRef =~ s/&/&amp;/g;

   my $vars = {
       version => "1.2",
       startRecord => "1",
       numberOfRecords  => "1",
       recordSchema => "http://clarin.eu/fcs/1.0",
       recordPacking => "xml",
       content => $content,
       query => "toc=" . $pageNo,
       prevPid => $prevPid,
       nextPid => $nextPid,
       prevRef => $prevRef,
       nextRef => $nextRef,
     };

   my $tt = Template->new({
       INCLUDE_PATH => $templatePath,
       INTERPOLATE  => 1,
   }) || die "$Template::ERROR\n";

   $tt->process($contentTemplate, $vars)
       || die $tt->error(), "\n";
}

1;