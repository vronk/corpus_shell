<?php
  $configUrl = "../sru/switch.config";
  $localhost = "corpus3.aac.ac.at";

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
     print "SearchConfig[$idx] = new Array();\n";

     $name = GetNodeValue($entry, "name");
     print "SearchConfig[$idx]['x-context'] = '$name';\n";
     $label = GetNodeValue($entry, "label");
     print "SearchConfig[$idx]['DisplayText'] = '$label';\n\n";
     $idx++;
  }
?>