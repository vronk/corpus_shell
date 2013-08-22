<?php
  /**
   * This script generates a php configuation cache file
   * 
   * It gets included by switch.php as configuration information
   *
   * First the config file ($switchConfig - set in config.php) is parsed and all items having the type
   * $type (eg. "fcs.resource") are collected. afterwards their endpoints are
   * queried with the params "?operation=scan&scanClause=".$type
   *
   * The results are transformed into data of a php array using the xsl file
   * $xslfile.
   *
   * At last the results of all queries/transformations are merged and written
   * to the php file $fcsConfig (set in config.php)
   *
   * To speed things up every occurance of the local hostname (supplied by the
   * config.php variable $localhost) is replaced with
   * "localhost" when querying upstream endpoints. If resources aren't hosted
   * on the same server the query for resources uses the usual network connection.
   * 
   * @uses $switchConfig
   * @uses $fcsConfig
   * @uses $localhost
   * @copyright 2012-feb
   * @author Andy Basch
   * @package fcs-aggregator
   */


  /**
   * Load the common config file
   */
  include "../utils-php/config.php";

  /**
   * Get the node value of the first occurrence of $tagName
   * in the children of $node
   * FIXME: This is a duplicat of a similar function in switch.php.
   * @param DOMNode $node The Node at which the search is started.
   * @param string $tagName The tag to search for.
   * @return string The value of the tag if found else the empty string "" is returned.
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

  /**
   * Analog to file_exists() this function tests if a given $url does exist
   * FIXME: This is a dublicate of a similar function in switch.php
   * @param string $url A URL to be testes.
   * @return bool If $url is reachable or not.
   */
  function url_exists($url)
  {
      $handle = @fopen($url,'r');
      return ($handle !== false);
  }

  /**
   * Generate success message and display the generated script
   * with links to all queried endpoints
   * 
   * The message is a simple HTML page.
   * @param string $fcsConfig Path to the generated config file.
   */
  function success($fcsConfig, $urls, $content)
  {
    echo "<html><head><title>Success!</title></head><body>";
    echo "Success - file was generated successfully<br>$fcsConfig<br><br>";
    echo "<br>$urls<br>";
    echo '<pre>' . str_replace("<", "&lt;", $content) . '</pre></body></html>';
  }

  /**
   * Only process config-items of this type (currently fcs.resource)
   * @global string $type
   */
  $type ="fcs.resource";

  /**
   * xsl file used to transform the query result into php code
   * 
   * $xslfile = "http://corpus3.aac.ac.at/cs2/corpus_shell/fcs/utils/php/fcs.resource.to.php.xsl";
   * $xslfile = $webRoot."fcs/utils/php/fcs.resource.to.php.xsl";
   * @global string $xslfile
   */
  $xslfile = "fcs.resource.to.php.xsl";

  //$xslfile = str_replace($localhost, "localhost",  $xslfile);

  /**
   * At the end of this script this contains the new fcs.resource.config.php
   * @global string $content
   */
  $content = "";
  $urls = "";


  /**
   * The config file $switchConfig as XML DOM tree
   * @uses $switchConfig
   * @global DOMDocument $doc
   */
  $doc = new DOMDocument;
  $doc->Load($switchConfig);
  /**
   * Objects offers XPath 1.0 query functionality for the $switchConfig file.
   * @uses $doc
   * @global DOMXPath $xpath
   */
  $xpath = new DOMXPath($doc);

  /**
   * XQuery needed to find all items with type==$type (defined above)
   * @global string $query
   */
  $query = "//item[type='$type']";
  
  /**
   * A list of DOM Nodes matching the criteria given by $query
   * @uses $query
   * @uses $xpath
   * @global DOMNodeList $entries
   */
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

  //write xslt results to the above defined file $fcsConfig
  $handle = fopen($fcsConfig, "w");
  $content = '<?php' . "\n    " .
"    /**\n" .
"	 * This file contains an array of arrays (a map of maps) for finding endpoints by their identifier\n" .
"	 * \n" .
"	 * This file is generated by initconfigcache.php. Load initconfigcache.php at least once from your web server with your browser. \n" .
"	 * @package fcs-aggregator\n" .
"	 */\n" .
"	 \n" .
"	/**\n" .
"	 * An array of arrays (a map of maps) for finding endpoints by their identifier\n" .
"	 * \n" .
"	 * Using the identifier for a resource the endPoint, name (back reference, the identifier),\n" .
"	 * displayText (human intelligable name),\n" .
"	 * type (\"fcs.resource\"), style (the stylesheet associated with the resource) and context \n" .
"	 * (for the x-context parameter can be determined). \n" .
"	 * @global array \$configName\n" .
"	 */\n" .
'    $configName = array();'.
/* "\n    " . '$configContext = array();' .
*/ "\n\n    " .
$content . "\n?>";
  fwrite($handle, $content);
  fclose($handle);

  //after everything is done, display a success message ...
  //... and the generated php code
  success($fcsConfig, $urls, $content);
?>