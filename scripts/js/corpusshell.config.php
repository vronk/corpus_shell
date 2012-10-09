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

  if (file_exists($ddcConfig))
  {
    include $ddcConfig;
    $ddcConfigFound = true;    
  }  

  header("Content-Type: application/x-javascript");
  print "var SearchConfig = new Array();\n";

  $doc = new DOMDocument;
  $doc->Load($configUrl);

  $xpath = new DOMXPath($doc);
  $query = '//item';
  $entries = $xpath->query($query);

  $idx = 0;

  foreach ($entries as $entry)
  {
     $type = GetNodeValue($entry, "type");
     print "SearchConfig[$idx] = new Array();\n";
     $name = GetNodeValue($entry, "name");
     print "SearchConfig[$idx]['x-context'] = '$name';\n";
     $label = GetNodeValue($entry, "label");
     print "SearchConfig[$idx]['DisplayText'] = '$label';\n\n";     
     $idx++;

     if (($type == "fcs.resource") && ($ddcConfigFound === true))
     {
       $keys = array_keys($configName);
       $parentName = $name;
       
       foreach ($keys as $key)
       {         
         $pos = strpos($key, $parentName);
         if (($pos !== false) && ($pos == 0))
         {
           print "SearchConfig[$idx] = new Array();\n";
           $conf = $configName[$key];
           
           $name = $conf["name"];
           print "SearchConfig[$idx]['x-context'] = '$name';\n";
           $label = $conf["displayText"];
           print "SearchConfig[$idx]['DisplayText'] = ' -> $label';\n\n";     
           $idx++;
         }
       }       
     }

  }
?>