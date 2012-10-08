<?php

error_reporting(E_ALL);

 //load configuration
 include "config.php";

 //load database and user data
 include $dbConfigFile;

 if (isset($_GET['x-type']) && trim($_GET['x-type']) == "fcs")
   $responseTemplate = $responseTemplateFcs;

 //required values for the templates
 $recordSchema = "http://clarin.eu/fcs/1.0/resource.xsd";
 $version = "1.2";

 function diagnostics($dgId, $dgDetails)
 {
    global $diagnosticsTemplate;
    global $version;
    global $vlibPath;

    //TODO: this needs to be based on diagnostics-list:
    //http://www.loc.gov/standards/sru/resources/diagnostics-list.html
    $diagnosticMessage = "Error";
    $diagnosticId = $dgId;
    $diagnosticDetails = $dgDetails;

    require_once $vlibPath;

   	$tmpl = new vlibTemplate($diagnosticsTemplate);

   	$tmpl->setvar('version', $version);
   	$tmpl->setvar('diagnosticId', $diagnosticId);
   	$tmpl->setvar('diagnosticMessage', $diagnosticMessage);
   	$tmpl->setvar('diagnosticDetails', $diagnosticDetails);

   	$tmpl->pparse();
 }

 function explain()
 {
    global $explainTemplate;
    global $vlibPath;

    require_once $vlibPath;

   	$tmpl = new vlibTemplate($explainTemplate);
   	$tmpl->pparse();
 }

 function decodecharrefs($str)
 {
   //str_replace("alt","neu","Zeichenkette")
   $str = str_replace("#9#", ";", $str);
   $str = str_replace("#8#", "&#", $str);
   return $str;
 }

 function search($query)
 {
    global $responseTemplate;
    global $version;
    global $recordSchema;
    global $recordPacking;

    global $server;
    global $user;
    global $password;
    global $database;

   global $vlibPath;

   require_once $vlibPath;

    $db = mysql_connect($server, $user, $password);
    if (!$db)
      diagnostics('MySQl Connection Error', 'Failed to connect to database: ' . mysql_error());
    mysql_select_db($database, $db);

    $sqlstr = "SELECT DISTINCT id, entry FROM vicav_profiles_001 ";
    $sqlstr.= "WHERE lemma = '$query'";

    //print "sqlstr: '$sqlstr'";

    $result = mysql_query($sqlstr);

    $numberOfRecords = mysql_num_rows($result);

   	$tmpl = new vlibTemplate($responseTemplate);

   	$tmpl->setvar('version', $version);
   	$tmpl->setvar('numberOfRecords', $numberOfRecords);
   	$tmpl->setvar('query', $query);
   	$tmpl->setvar('baseURL', $baseURL);
   	$tmpl->setvar('nextRecordPosition', $nextRecordPosition);
   	$tmpl->setvar('res', '1');

   	$hits = array();
   	$hitsMetaData = array();
   	array_push($hitsMetaData, array('key' => 'copyright', 'value' => 'ICLTT'));
   	$hstr = "Arabic dialect profile for the region of $query";
   	array_push($hitsMetaData, array('key' => 'content', 'value' => $hstr));

    if ($line = mysql_fetch_row($result))
    {
        $id = $line[0];
        $content = $line[1];

        array_push($hits, array(
               'recordSchema' => $recordSchema,
               'recordPacking' => $recordPacking,
               'queryUrl' => $baseURL,
               'content' => decodecharrefs($content),
               'hitsMetaData' => $hitsMetaData
               ));
    }

    $tmpl->setloop('hits', $hits);
   	$tmpl->pparse();
 }

  //sru params
  if (isset($_GET['operation']) && trim($_GET['operation']) != "")
    $operation = trim($_GET['operation']);
  else
    $operation = "";

  if (isset($_GET['version']) && trim($_GET['version']) != "")
    $version = trim($_GET['version']);

  if (isset($_GET['startRecord']) && trim($_GET['startRecord']) != "")
    $startRecord = trim($_GET['startRecord']);
  else
    $startRecord = "";

  if (isset($_GET['maximumRecords']) && trim($_GET['maximumRecords']) != "")
    $maximumRecords = trim($_GET['maximumRecords']);
  else
    $maximumRecords = "";

  if (isset($_GET['query']) && trim($_GET['query']) != "")
  {
    $query = trim($_GET['query']);
    $query = str_replace("|", "#", $query);
  }
  else
    $query = "";

  if (isset($_GET['scanClause']) && trim($_GET['scanClause']) != "")
    $scanClause = trim($_GET['scanClause']);
  else
    $scanClause = "";

  if (isset($_GET['recordPacking']) && trim($_GET['recordPacking']) == "xml")
    $recordPacking = trim($_GET['recordPacking']);
  else
    $recordPacking = "raw";

  header ("content-type: text/xml");
  //print "test";

  if ($operation == "explain" || $operation == "")
    explain();
  else if ($operation == "scan")
  {

  }
  else if ($operation == "searchRetrieve")
  {
    //print "query: $query";
    search($query);
  }


    //diagnostics('test1', 'test message');

?>

