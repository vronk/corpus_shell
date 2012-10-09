<?php
  /*
    this script generates a php cache file 
    (that gets included by switch.php as configuration information)
    
    first the config file ($configUrl) is parsed and all items having the type 
    $type (eg. "fcs.resource") are collected. afterwards their endpoints are 
    queried with the params "?operation=scan&scanClause=".$type
    
    the results are transformed into data of a php array using the xsl file 
    $xslfile.
    
    at last the results of all queries/transformations are merged and written 
    to the php file $filename. 
    
    2012-feb by Andy Basch
    */
  

  //get the node value of the first occurrence of $tagName
  //in the children of $node
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

  //analog to file_exists() this function tests if a given $url does exist
  function url_exists($url)
  {
      $handle = @fopen($url,'r');
      return ($handle !== false);
  }
  
  //generate success message and display the generated script 
  //with links to all queried endpoints
  function success($filename, $urls, $content)
  {
    echo "<html><head><title>Success!</title></head><body>";
    echo "Success - file was generated successfully<br>$filename<br><br>";
    echo "<br>$urls<br>";
    echo '<pre>' . str_replace("<", "&lt;", $content) . '</pre></body></html>';
  }

  //to speed up xslt the servername ist replaced by "localhost"
  $localhost = "corpus3.aac.ac.at";
  //target file name
  $filename = "/srv/www/htdocs/cs2/corpus_shell/fcs/aggregator/fcs.resource.config.php";
  //config file that is parsed below
  $configUrl = "/srv/www/htdocs/cs2/corpus_shell/fcs/aggregator/switch.config";
  
  //only process config-items of this type
  $type ="fcs.resource";

  //xsl file used to transform the query result into php code
  $xslfile = "http://corpus3.aac.ac.at/cs2/corpus_shell/fcs/utils/php/fcs.resource.to.php.xsl";
  $xslfile = str_replace($localhost, "localhost",  $xslfile);
  
  $content = "";
  $urls = "";

  
  //load the config file $configUrl
  $doc = new DOMDocument;
  $doc->Load($configUrl);

  $xpath = new DOMXPath($doc);
  
  //find all items with type==$type (defined above)
  $query = "//item[type='$type']";
  $entries = $xpath->query($query);
  
  foreach ($entries as $entry)
  {
     //parse the config file 
     $name = GetNodeValue($entry, "name");
     $uri = GetNodeValue($entry, "uri");
     $style = GetNodeValue($entry, "style");     
     
     $uriparam = $uri . "?operation=scan&scanClause=" . $type;
     $url = str_replace($localhost, "localhost",  $uriparam);
     
     //used for the success message
     $urls .= '<a href="' . $uriparam . '" target="_blank">' . $uri . '</a><br>';

     if (url_exists($url) && url_exists($xslfile))
     {
       //load xsl file
       $xslDoc = new DOMDocument();
       $xslDoc->load($xslfile);
   
       //query endpoint
       $xmlDoc = new DOMDocument();
       $xmlDoc->load($url);
   
       $proc = new XSLTProcessor();
       $proc->importStylesheet($xslDoc);
       //xsl params
       $proc->setParameter("", "uri", $uri);
       $proc->setParameter("", "type", $type);
       $proc->setParameter("", "style", $style);

       //xsl transform the query result ...
       //... and append it to the existing results
       $content .= $proc->transformToXML($xmlDoc);
     }
  }
  
  //write xslt results to the above defined file $filename
  $handle = fopen($filename, "w"); 
  $content = '<?php' . "\n    " . '$configName = array();'. /* "\n    " . '$configContext = array();' . */ "\n\n    " . $content . "\n?>";
  fwrite($handle, $content);    
  fclose($handle);
  
  //after everything is done, display a success message ...
  //... and the generated php code
  success($filename, $urls, $content); 
?>