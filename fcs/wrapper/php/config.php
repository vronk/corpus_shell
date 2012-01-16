<?php
  //configuration script for the SRU scripts

  //db connection data
  $dbConfigFile =            '../../../../../sru/dbconfig.php';

  //template files
  $diagnosticsTemplate =     '../../utils/php/templates/sru_diagnostics_template.xml';
  $responseTemplateFcs =     '../../utils/php/templates/sru_response_template_fcs.xml';
  $responseTemplate =        '../../utils/php/templates/sru_response_template.xml';
  $explainTemplate =         '../../utils/php/templates/explain.xml';
  $scanCollectionsTemplate = '../../utils/php/templates/scan_collections.xml';

  //path to template engine
  $vlibPath =                '../../utils/php/vlib/vlibTemplate.php';
?>