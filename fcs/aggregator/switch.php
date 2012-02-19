<?php
//  ini_set('display_errors', 1);

  $configUrl = "switch.config";
  $localhost = "corpus3.aac.ac.at";
  $scriptsUrl = "http://corpus3.aac.ac.at/cs2/corpus_shell/scripts";
  $fcsConfig = "fcs.resource.config.php";
  $fcsConfigFound = false;
  
  if (file_exists($fcsConfig))
  {
    include $fcsConfig;
    $fcsConfigFound = true;    
  }  

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
         //echo "Name: $name - ";

         $type = GetNodeValue($entry, "type");
         //echo "Type: $type - ";

         $uri = GetNodeValue($entry, "uri");
         //echo "Uri: $uri\n";

         $style = GetNodeValue($entry, "style");
         //echo "Style: $style\n";

         return array("name" => $name, "type" => $type, "uri" => $uri, "style" => $style);
       }
    }
    
    //context not found in switch.config
    //have a look in fcsConfig
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
  
  function url_exists($url)
  {
      $handle = @fopen($url,'r');
      return ($handle !== false);
  }
  

  //header("Content-Type: text/plain");

// FIXME: all this parameter handling has to be reworked
		// dont just pass the request string, but check the parameters and recreate the url for the endpoint
	
  $hstr = $_GET["x-context"];

  if (isset($_GET['x-format']))
    $format = trim($_GET['x-format']);
  else
    $format = "";

  $params = $_SERVER["REQUEST_URI"];
  $params = strstr($params, "?");
  // carving out some parameters! not nice!
  $params = str_replace("x-context=" . $hstr, "", $params);
  $params = str_replace("x-format=" . $format, "", $params);

  $sAry = array("?&", "&&");
  $rAry = array("?", "&");

	 // add default params
	 $params = $params."&version=1.2";
	 
  $params = str_replace($sAry, $rAry, $params);
  //print "Params: $params\n";

  $context = explode(",", $hstr);
  //print_r($context);

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
          //      else          $params .= "&x-context=" . $item;
          else 
          $params = $params;
      }
      $fileName = $uri . $params;
  
      $pos = stripos($format, "html");
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
           	$proc->setParameter('', 'format', $format);
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
      else if (stripos($format, "xsltproc") !== FALSE)
      {
      	 print "XSLTPROC-testing";
      	 print "hasExsltSupport:".$proc->hasExsltSupport;
        //print $xslDoc->saveXML();
      }
      else if (stripos($format, "xsl") !== FALSE)
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
  }
?>