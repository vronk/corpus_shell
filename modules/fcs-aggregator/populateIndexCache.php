<?php
/**
 * Generates a js-array out of switch.config containing the available targets
 *
 * Includes items of type == "fcs.resource". This js-array is loaded by the HTML app.
 * @uses $switchConfig
 * @uses $configName
 * @uses $switchUrl
 * @package fcs-aggregator
 */

  /**
   * Common configuration file
   */
  include "../utils-php/config.php";

  $ddcConfigFound = false;

  /**
   * FIXME: Duplicated again
   */
  function GetNodeValue($node, $tagName)
  {
     $list = $node->getElementsByTagName($tagName);
     if ($list->length != 0)
     {
       $value = $list->item(0);
       return $value->nodeValue;
     }
     return "";
  }

  function ReadDataSet($dataSet, $indexes, $entry)
  {
    $dataSet["idxTitle"] = $indexes->item(0)->nodeValue;

    $dataSet["searchable"] = $entry->attributes->getNamedItem("search")->nodeValue;
    $dataSet["scanable"] = $entry->attributes->getNamedItem("scan")->nodeValue;
    $dataSet["sortable"] = $entry->attributes->getNamedItem("sort")->nodeValue;

    return $dataSet;
  }


  function GetScanResult($resName)
  {
  	global $switchUrl; 
  	
    print "ResName --- >  $resName\n";
    $url = $switchUrl."?operation=explain&x-context=".$resName."&version=1.2";
    print $url;
    $doc = new DOMDocument();
    $doc->load($url);

    $xpath = new DOMXPath($doc);
    $xpath->registerNamespace("zr","http://explain.z3950.org/dtd/2.0/");
    $idxArray = array();

    $entries = $xpath->query("//zr:index");
    //print "count: " . $entries->length . "\n";

    if ($entries->length != 0)
    {
      foreach ($entries as $entry)
      {
        $dataSet = array();
        $names = $xpath->query("zr:map/zr:name", $entry);
        if ($names->length != 0)
        {
          $dataSet["idxName"] = $names->item(0)->nodeValue;

          $indexes = $xpath->query("zr:title[@lang='en']", $entry);
          if ($indexes->length != 0)
          {
            $idxArray[$dataSet["idxName"]] = ReadDataSet($dataSet, $indexes, $entry);
          }
        }
        //print_r($dataSet);
      }
      print "\n";
    }
    else
    {
      $xpath->registerNamespace("","http://explain.z3950.org/dtd/2.1/");
      $idxArray = array();

      $entries = $xpath->query("//index");
      //print "count: " . $entries->length . "\n";

      foreach ($entries as $entry)
      {
        $dataSet = array();
        $names = $xpath->query("map/name", $entry);
        if ($names->length != 0)
        {
          $dataSet["idxName"] = $names->item(0)->nodeValue;

          $indexes = $xpath->query("title[@lang='en']", $entry);
          if ($indexes->length != 0)
          {
            $idxArray[$dataSet["idxName"]] = ReadDataSet($dataSet, $indexes, $entry);
          }
        }
        //print_r($dataSet);
      }
      print "\n";
    }
    return $idxArray;
  }

  if (file_exists($fcsConfig))
  {
    include $fcsConfig;
    $ddcConfigFound = true;
  }

  header("Content-Type: text/plain");
  print "Starting queries ...\n";

  $doc = new DOMDocument;
  $doc->Load($switchConfig);

  $xpath = new DOMXPath($doc);
  $query = '//item';
  $entries = $xpath->query($query);

  $indexes = array();

  foreach ($entries as $entry)
  {
     $type = GetNodeValue($entry, "type");
     $name = GetNodeValue($entry, "name");
     $indexes[$name] = GetScanResult($name);

     if (($type == "fcs.resource") && ($ddcConfigFound === true))
     {
     	// $configName is defined in the fcs.resrouce.config.php, that has to be generated in a separate step (initconfigcache.php)
       $keys = array_keys($configName);
       $parentName = $name;

       foreach ($keys as $key)
       {
       	//FIXME: this cannot be based on substring!! http://corpus3.aac.ac.at/trac/ticket/75
         $pos = strpos($key, $parentName);
         if (($pos !== false) && ($pos == 0))
         {
           $conf = $configName[$key];

           $name = $conf["name"];
           $indexes[$name] = GetScanResult($name);
         }
       }
     }
  }

  //print_r($indexes);
  $content = json_encode($indexes);
  //print $content;

  //open/create file
  if (!$handle = fopen($indexCacheFileName, "w"))
  {
    print  "\nCannot open/create file ($indexCacheFileName)";
    exit;
  }

  //write json string to cache file
  if (fwrite($handle, $content) === FALSE)
  {
      print "\nCannot write to file ($indexCacheFileName)";
      exit;
  }

  //close file and save it
  fclose($handle);

  print "\nIndexCache written to file (" . realpath($indexCacheFileName) . ")";

?>