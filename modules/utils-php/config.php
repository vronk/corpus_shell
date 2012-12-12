<?php
  //configuration script for the SRU scripts

  $serverRoot =              '/srv/www/';
  $docRoot =                 $serverRoot . 'htdocs/';
  $csRoot =                  'cs2/corpus_shell/';
  $fcsRoot =                 $docRoot . $csRoot . 'modules/';
  //db connection data
  $dbConfigFile =            $docRoot . 'sru/dbconfig.php';

  //template files
  $diagnosticsTemplate =     $fcsRoot . 'utils-php/templates/sru_diagnostics_template.xml';
  $responseTemplateFcs =     $fcsRoot . 'utils-php/templates/sru_response_template_fcs.xml';
  $responseTemplate =        $fcsRoot . 'utils-php/templates/sru_response_template.xml';
  $explainTemplate =         $fcsRoot . 'utils-php/templates/explain.xml';
  $explainSwitchTemplate =   $fcsRoot . 'utils-php/templates/switch_explain.xml';
//$scanCollectionsTemplate = $fcsRoot . 'utils-php/templates/scan_collections.xml';
  $scanCollectionsTemplate = $fcsRoot . 'utils-php/templates/sru_scan_collections_template.xml';

  //path to template engine
  $vlibPath =                $fcsRoot . 'utils-php/vlib/vlibTemplate.php';

  //required values for the templates
  $recordSchema =            "http://clarin.eu/fcs/1.0/Resource.xsd";
  $version =                 "1.2";

	// to speed up xslt the servername ist replaced by "localhost"
  $localhost =               "corpus3.aac.ac.at";
  $webRoot =                 "http://" . $localhost . "/" . $csRoot;
  $switchUrl =							        "http://" . $localhost . "/switch";
  $scriptsUrl =              $webRoot . "scripts";
  $fcsConfig =               $fcsRoot . "fcs-aggregator/fcs.resource.config.php";
  $switchConfig =            $fcsRoot . "fcs-aggregator/switch.config";
  $indexCacheFileName =      $docRoot . $csRoot . "scripts/js/indexCache.json";

	$userdataPath = 					 $fcsRoot . "userdata/data/";
  $ddcConfig =               $fcsRoot . "ddconsru/ddc.config";
  $ddcConfigXml =            $fcsRoot . "ddconsru/tmpl/sru_scan_fcs.resource.xml";
  $ddcConfigXsl =            $fcsRoot . "ddconsru/tmpl/sru_scan_fcs.resource.xsl";

?>