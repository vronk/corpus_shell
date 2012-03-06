<?php
  //configuration script for the SRU scripts

  $docRoot =                 '/srv/www/htdocs/';
  $fcsRoot =                 $docRoot . 'cs2/corpus_shell/fcs/';
  //db connection data
  $dbConfigFile =            $docRoot . 'sru/dbconfig.php';

  //template files
  $diagnosticsTemplate =     $fcsRoot . 'utils/php/templates/sru_diagnostics_template.xml';
  $responseTemplateFcs =     $fcsRoot . 'utils/php/templates/sru_response_template_fcs.xml';
  $responseTemplate =        $fcsRoot . 'utils/php/templates/sru_response_template.xml';
  $explainTemplate =         $fcsRoot . 'utils/php/templates/explain.xml';
  $explainSwitchTemplate =   $fcsRoot . 'utils/php/templates/switch_explain.xml';
//  $scanCollectionsTemplate = $fcsRoot . 'utils/php/templates/scan_collections.xml';
  $scanCollectionsTemplate = $fcsRoot . 'utils/php/templates/sru_scan_collections_template.xml';
                             
  //path to template engine   
  $vlibPath =                $fcsRoot . 'utils/php/vlib/vlibTemplate.php';
?>