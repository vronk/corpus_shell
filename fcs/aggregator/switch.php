<?php

  //definition of constants
  $configUrl = "switch.config";
  $localhost = "corpus3.aac.ac.at";
  $scriptsUrl = "http://corpus3.aac.ac.at/cs2/corpus_shell/scripts";
  $fcsConfig = "fcs.resource.config.php";
  $fcsConfigFound = false;

  //array containing default xsl style sheets
  $globalStyles = array ("searchRetrieve" => "", "scan" => "", "explain" => "", "default" => "");

  //import fcs configuration cache
  if (file_exists($fcsConfig))
  {
    include $fcsConfig;
    $fcsConfigFound = true;
  }

  //returns the node value of the first fitting tag with $tagName
  //processes the descendants of $node only
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

  //returns the node value of the first fitting tag with $tagName
  //that has an attribute $attr with the value $attrValue
  //processes the descendants of $node only
  function GetNodeValueWithAttribute($node, $tagName, $attr, $attrValue)
  {
     $list = $node->getElementsByTagName($tagName);
     $idx = 0;

     if ($list->length != 0)
     {
       while ($idx < $list->length)
       {
         $value = $list->item($idx);

         if ($value->hasAttributes())
         {
           $attribute = $value->attributes->getNamedItem($attr)->nodeValue;
           if ($attribute == $attrValue)
             return $value->nodeValue;
         }
         $idx++;
       }
     }
     return "";
  }

  //get default xsl style sheets
  function GetDefaultStyles()
  {
    global $configUrl;
    global $globalStyles;

    $doc = new DOMDocument;
    $doc->Load($configUrl);

    $xpath = new DOMXPath($doc);
    $query = '//styles';
    $entries = $xpath->query($query);

    foreach ($entries as $entry)
    {
      $keys = array_keys($globalStyles);
      foreach ($keys as $key)
      {
        $hstr = GetNodeValueWithAttribute($entry, "style", "operation", $key);
        if ($hstr != "")
          $globalStyles[$key] = $hstr;
      }
    }
  }

  //opens $configUrl and searches for a <item> with a <name> value that
  //equals $context - returns configuration infos for the found node in
  //an array
  function GetConfig($context)
  {
    global $configUrl;
    $doc = new DOMDocument;
    $doc->Load($configUrl);

    $xpath = new DOMXPath($doc);
    $query = '//item';
    $entries = $xpath->query($query);

    foreach ($entries as $entry)
    {
       $name = GetNodeValue($entry, "name");
       if ($name == $context)
       {
         $type = GetNodeValue($entry, "type");
         $uri = GetNodeValue($entry, "uri");
         $style = GetNodeValue($entry, "style");
         return array("name" => $name, "type" => $type, "uri" => $uri, "style" => $style);
       }
    }

    //context not found in switch.config
    //have a look in fcsConfig - if it does exist!
    global $fcsConfigFound;

    if ($fcsConfigFound)
    {
      global $configName;

      if (array_key_exists($context, $configName))
      {
        $conf = $configName[$context];
        return array("name" => $conf["name"], "type" => $conf["type"], "uri" => $conf["endPoint"], "style" => $conf["style"]);
      }
    }

    return false;
  }

  //like file_exists() but working with urls
  function url_exists($url)
  {
      $handle = @fopen($url,'r');
      return ($handle !== false);
  }

  //header("Content-Type: text/plain");

  // FIXME: all this parameter handling has to be reworked
		// dont just pass the request string, but check the parameters and recreate the url for the endpoint


  // params SRU
  if (isset($_GET['operation'])) $operation = $_GET["operation"]; else $operation = "explain";
  if (isset($_GET['query'])) $query = trim($_GET['query']); else $query = "";
  if (isset($_GET['scanClause'])) $scanClause = trim($_GET['scanClause']); else $scanClause = "";
  if (isset($_GET['responsePosition'])) $responsePosition = trim($_GET['responsePosition']); else $responsePosition = "";

  if (isset($_GET['maximumTerms'])) $maximumTerms = trim($_GET['maximumTerms']); else $maximumTerms = "10";
  if (isset($_GET['version'])) $version = trim($_GET['version']); else $version = "1.2";

  if (isset($_GET['maximumRecords'])) $maximumRecords = trim($_GET['maximumRecords']); else $maximumRecords = "10";
  if (isset($_GET['startRecord'])) $startRecord = trim($_GET['startRecord']); else $startRecord = "1";
  if (isset($_GET['recordPacking'])) $recordPacking = trim($_GET['recordPacking']); else $recordPacking = "xml";
  if (isset($_GET['recordSchema'])) $recordSchema = trim($_GET['recordSchema']); else $recordSchema = "";

  //TODO: add request param "stylesheet"
  //if (isset($_GET['stylesheet'])) $stylesheet = trim($_GET['stylesheet']); else $stylesheet = "1.2";

  //additional params - non SRU
  if (isset($_GET['x-context'])) $xcontext = $_GET["x-context"]; else $xcontext = "";
  if (isset($_GET['x-format'])) $xformat = trim($_GET['x-format']); else $xformat = "";

  /* ********************************************************************** */
  /**/ // TODO: has to be removed [START]
  /**/ $params = $_SERVER["REQUEST_URI"];
  /**/ $params = strstr($params, "?");
  /**/ // carving out some parameters! not nice!
  /**/ $params = str_replace("x-context=" . $xcontext, "", $params);
  /**/ $params = str_replace("x-format=" . $xformat, "", $params);
  /**/ $sAry = array("?&", "&&");
  /**/ $rAry = array("?", "&");
	 /**/ // add default params
	 /**/ $params = $params."&version=1.2&maximumRecords=10";
  /**/ $params = str_replace($sAry, $rAry, $params);
  /**/ //TODO: has to be removed [END]
  /* ********************************************************************** */



  $context = explode(",", $xcontext);

  //load default xsl style sheets from $configUrl
  GetDefaultStyles();

// would loop over every context, but only concat results (even with headers!) so this is not really "aggregating"
  foreach($context as $item)
  {
    $config_item = GetConfig($item);

    if ($config_item !== false)
    {
      $uri = $config_item["uri"];

      if (($config_item['type'] == "fcs")||($config_item['type'] == "fcs.resource"))
      {
        if ($params == "")
        	$params = "?x-context=" . $item;
          // temporarily deactivated, because produced double param x-context
          // (for exist, maybe it will make problems with other targets
          elseif (stripos($params, "x-context") !== FALSE)
          	$params  = $params;
          else
          	$params .= "&x-context=" . $item;

      }
      $fileName = $uri . $params;

      $pos = stripos($xformat, "html");
      //print "StriPos: $pos";

  	   //depending on x-format parameter decide if to transform the result (into html), or leave it as raw xml
      if ($pos !== FALSE)
      {
        $style = str_replace($localhost, "localhost",  $config_item["style"]);
        //print $fileName;

        if (url_exists($style))
        {
          $xslDoc = new DOMDocument();
          $xslDoc->load($style);

          if (url_exists($fileName))
          {
            $xmlDoc = new DOMDocument();
            $xmlDoc->load($fileName);
							    // DEBUG
							    // $outXML = $xmlDoc->saveXML();
							    // print $outXML;

            $proc = new XSLTProcessor();
            $proc->importStylesheet($xslDoc);
           	$proc->setParameter('', 'format', $xformat);
           	$proc->setParameter('', 'scripts_url', $scriptsUrl);
            header("content-type: text/html; charset=UTF-8");
            echo $proc->transformToXML($xmlDoc);
          }
          else
          {
            print "$fileName not found!";
          }
        }
        else
        {
          print "$style not found!";
        }
      }
      else if (stripos($xformat, "xsltproc") !== FALSE)
      {
      	 print "XSLTPROC-testing";
      	 print "hasExsltSupport:".$proc->hasExsltSupport;
        //print $xslDoc->saveXML();
      }
      else if (stripos($xformat, "xsl") !== FALSE)
      {
      	 // this option is more or less only for debugging (to see the xsl used)
      	 $style = str_replace($localhost, "localhost",  $config_item["style"]);

      	 header ("content-type: text/xml; charset=UTF-8");
      	 readfile($style);

      	 //$xslDoc = new DOMDocument();
        //$xslDoc->load($style);
        //print $xslDoc->saveXML();
      }
      else
      {
        header ("content-type: text/xml; charset=UTF-8");
        $fileName = $uri . $params;
        $fileName = str_replace($localhost, "localhost", $fileName);

        if (url_exists($fileName))
        {
          readfile($fileName);
        }
        else
        {
          $fileName = str_replace("&", "&amp;", $fileName);
          print "<message>uri or script not found! $fileName</message>";
        }
      }
    }
    else
    {
      //return error message: x-context not found in $configUri
    }
  }
?>