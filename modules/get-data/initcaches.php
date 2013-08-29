<?php
  /**
   * this script generates php cache files that are used to speed up xml or
   * image delivery.
   *
   * an additionial advantage of these caches is the fact that the array items
   * are sorted before they are saved to disc. hence its very easy to get the
   * previous/next entry/file.
   *
   * @package get-data-caching
   * @copyright 2012-feb
   * @author Andy Basch
   */

  /**
   * paths and files
   */
  include "cacheconfig.php";

  //recursive file search
  function GetFiles($dir, $fileArray)
  {
    if (is_dir($dir))
    {
      if ($handle = opendir($dir))
      {
        while (($file = readdir($handle)) !== false)
        {
          //concat search dir $dir an search result $file
          $fullPath = $dir . "/" . $file;

          //start recursion if the search entry is a directory
          if (is_dir($fullPath) && ($file != ".") && ($file != ".."))
          {
            $fileArray = GetFiles($fullPath, $fileArray);
          }
          //found a file
          else if (is_file($fullPath))
          {
            //add it to the search result
            $fileArray[] = $fullPath;
          }
        }
        closedir($handle);
      }
    }
    return $fileArray;
  }

  //write array $fileArray to file $cacheFile
  function WriteCacheToFile($cacheFile, $fileArray, $arrayName)
  {
    //open for writing (creating it if it doesn't exist yet)
    $fileHandle = fopen($cacheFile, 'w');

    fwrite($fileHandle, "  #generated by initcaches.php\n  #do not edit this file - changes will be lost\n\n");
    //add array definition
    fwrite($fileHandle, "  our @$arrayName = ();\n\n");

    //iterate through the given $fileArray and write it
    //to the above defined $fileHandle
    foreach ($fileArray as $file)
    {
      fwrite($fileHandle, '  push(@' . $arrayName . ', "' . $file . "\");\n");
    }
    fwrite($fileHandle, '  1;');

    //close $fileHandle
    fclose($fileHandle);
    chmod($cacheFile, 0755);
  }

  //generate xml $fileArray ...
  $fileArray = GetFiles($xmlRoot, array());
  //... sort it ...
  asort($fileArray);
  //... and finally save it to the file $xmlCache
  WriteCacheToFile($xmlCache, $fileArray, 'xmlArray');
  print "Xml cache was successfully written to $xmlCache! [".count($fileArray)." files found]<br>";

  unset($fileArray);

  //generate img $fileArray ...
  $fileArray = GetFiles($imgRoot, array());
  //... sort it ...
  asort($fileArray);
  //... and finally save it to the file $imgCache
  WriteCacheToFile($imgCache, $fileArray, 'imgArray');
  print "Image cache was successfully written to $xmlCache! [".count($fileArray)." files found]";
?>