<?php
/*
	generates an js-array out of switch.config
	containing the available targets

	new feature: add items of type == "fcs.resource"
*/

//  CHANGE THIS FOR RELEASE
//  $configUrl = "../../sru/switch.config";
  $configUrl = "../../fcs/aggregator/switch.config";
  $localhost = "corpus3.aac.ac.at";

  $ddcConfig = "../../fcs/aggregator/fcs.resource.config.php";
  $ddcConfigFound = false;

  $cacheFileName = "../../scripts/js/indexCache.json";

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
    print "ResName --- >  $resName\n";
    $url = "http://localhost/switch?operation=explain&x-context=$resName&version=1.2";
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

  if (file_exists($ddcConfig))
  {
    include $ddcConfig;
    $ddcConfigFound = true;
  }

  header("Content-Type: text/plain");
  print "Starting queries ...\n";

  $doc = new DOMDocument;
  $doc->Load($configUrl);

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
       $keys = array_keys($configName);
       $parentName = $name;

       foreach ($keys as $key)
       {
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
  if (!$handle = fopen($cacheFileName, "w"))
  {
    print  "\nCannot open/create file ($cacheFileName)";
    exit;
  }

  //write json string to cache file
  if (fwrite($handle, $content) === FALSE)
  {
      print "\nCannot write to file ($cacheFileName)";
      exit;
  }

  //close file and save it
  fclose($handle);

  print "\nIndexCache written to file (" . realpath($cacheFileName) . ")";

?>