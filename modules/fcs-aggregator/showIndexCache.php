<?php
/**
 * Loads indexCache.json and returns a html representation of the imported array
 * 
 * The webpage is created as nested unordered lists and styled to look like a table.
 * @uses GenerateConfigDictionary()
 * @package fcs-aggregator
 */

  /**
   * Common configuration file
   */
  include "../utils-php/config.php";

  $ddcConfigFound = false;

  /**
   * FIXME: Duplicate function
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

  if (file_exists($fcsConfig))
  {
    include $fcsConfig;
    $ddcConfigFound = true;
  }

  /**
   * Create a dictionary (a map) that maps internal names to their labels
   * 
   * Uses $configName if the cache file was generated.
   * @uses $switchConfig
   * @uses $configName
   */
  function GenerateConfigDictionary()
  {
    global $switchConfig;
    global $configName;
    global $ddcConfigFound;

    $doc = new DOMDocument;
    $doc->Load($switchConfig);

    $retArray = array();

    $xpath = new DOMXPath($doc);
    $query = '//item';
    $entries = $xpath->query($query);

    $idx = 0;

    foreach ($entries as $entry)
    {
      $type = GetNodeValue($entry, "type");
      $name = GetNodeValue($entry, "name");
      $label = GetNodeValue($entry, "label");
      $retArray[$name] = $label;

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
            $label = $conf["displayText"];

            $retArray[$name] = $label;
          }
        }
      }
    }
    return $retArray;
  }

  //load file content into $indexes variable
  $indexes = file_get_contents($indexCacheFileName, true);
  //transform into a multi dimensional array
  $content = json_decode($indexes);

  //load config file for resources' labels
  $configDict = GenerateConfigDictionary();

  //generate html code
  header('Content-Type: text/html; charset=utf-8');

  print '<html>';
  print '<style>';
  print 'body {font-size: 12px; background-color: #EEEEEE; margin: 0px; padding: 25px; font-family: tahoma, sans serif;}';
  print 'h1 {font-size: 18px; text-align: center;}';
  print 'b {font-weight: normal; color: #000000;}';
  print 's {font-weight: normal; color: #999999;}';
  print 'li {border: 1px dotted #333333; margin: 10px 10px; padding: 2px;}';
  print 'body ul li {font-size: 14px; padding-left: 15px;}';
  print 'li ul li {background-color: #EEEEEE; border: none;}';
  print 'ul {background-color: #AAAAAA; list-style-type: none; padding: 10px;}';
  print 'body ul {width: 460px; margin-left: auto; margin-right: auto;}';
  print 'li ul {width: 400px;}';
  print '</style>';
  print '<body>';
  print '<h1>ICLTT corpus_shell search indexes</h1>';
  print '<ul>';

  //iterate through all resources
  foreach ($content as $key => $value)
  {
    print '<li>' . $configDict[$key] . " (" . $key . ")<br><ul>";
    $cnt = 0;
    //iterate through serach indexes of the current resource
    foreach ($value as $item)
    {
      print "<li>" . $item->idxTitle . " (" . $item->idxName. ")<br>";

      $hstr = "";
      if ($item->searchable == "true")
        $hstr .= "<b>search</b> ";
      else
        $hstr .= "<s>search</s> ";

      if ($item->scanable == "true")
        $hstr .= "<b>scan</b> ";
      else
        $hstr .= "<s>scan</s> ";

      if ($item->sortable == "true")
        $hstr .= "<b>sort</b> ";
      else
        $hstr .= "<s>sort</s> ";

      print "  $hstr</li>";
      $cnt++;
    }
    if ($cnt == 0)
      print "<li>no indexes found</li>";
    print '</ul></li>';
  }
  print '</ul>';
  print '</body>';
  print '</html>';

?>