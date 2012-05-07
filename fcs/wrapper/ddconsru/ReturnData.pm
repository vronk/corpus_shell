package ReturnData;

our $xmlCache = "/srv/www/htdocs/cstest/xmlCache.pl";
our $imgCache = "/srv/www/htdocs/cstest/imgCache.pl";

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

sub getXmlByPid($@)
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

sub returnText($@)
{
  my ($txt) = @_;

  print "Content-Type: text/xml\n\n";
 	open(IN,'<'.$txt) || die "Can not open file $txt: $!";

		while(<IN>)
		{
  		print "$_\n";
		}

		close IN;
}

1;