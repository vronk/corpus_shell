<?php
  header('Content-type: application/json');
  
  include "../../fcs/utils/php/config.php";

  if (isset($_POST['uid']) && trim($_POST['uid']) != "")
//  if (isset($_GET['uid']) && trim($_GET['uid']) != "")
  {
    $path = $csRoot + "main/utils/userdata/";
    $uid = trim($_POST['uid']);
    //$uid = trim($_GET['uid']);
    $filename = $path . $uid . ".json";

    if (file_exists($filename))
    {
      readfile($filename);
    }
  }
  else
    print "null";
?>