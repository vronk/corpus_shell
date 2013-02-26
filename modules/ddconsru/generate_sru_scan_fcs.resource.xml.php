<?php
  /*
  This script transformes the given ddc.config file into sru_scan_fcs.resource.xml
  using the xsl style sheet sru_scan_fcs.resource.xsl

  $ddcConfig =               $fcsRoot . "ddconsru/ddc.config";
  $ddcConfigXml =            $fcsRoot . "ddconsru/tmpl/sru_scan_fcs.resource.xml";
  $ddcConfigXsl =            $fcsRoot . "ddconsru/tmpl/sru_scan_fcs.resource.xsl";

  2013-02 A. Basch
  */

  //load config file
  include "../utils-php/config.php";

  $xslDoc = new DOMDocument();
  $xslDoc->load($ddcConfigXsl);

  $xmlDoc = new DOMDocument();
  $xmlDoc->load($ddcConfig);

  $proc = new XSLTProcessor();
  $proc->importStylesheet($xslDoc);
  $content = $proc->transformToXML($xmlDoc);

  header("content-type: text/plain; charset=UTF-8");
  //open/create file
  if (!$handle = fopen($ddcConfigXml, "w"))
  {
    print  "\nCannot open/create file ($ddcConfigXml)";
    exit;
  }

  //write json string to cache file
  if (fwrite($handle, $content) === FALSE)
  {
      print "\nCannot write to file ($ddcConfigXml)";
      exit;
  }

  //close file and save it
  fclose($handle);

  print "\nDDConSRU scan template written to file (" . realpath($ddcConfigXml) . ")";

?>