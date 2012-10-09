<?php
  
  include "../../fcs/utils/php/config.php";

  print_r($_POST);
  if (isset($_POST['uid']) && trim($_POST['uid']) != "" && isset($_POST['data']) && trim($_POST['data']) != "")
  {
    print "<msg>ok</msg>";

    $path = $csRoot + "main/utils/userdata/";

    $uid = trim($_POST['uid']);
    $data = trim($_POST['data']);

    print "uid: $uid";

    $filename = $path . $uid . ".json";

    $handle = fopen($filename, "w");
    fwrite($handle, $data);
    fclose($handle);
  }
  else
    print "<msg>not ok</msg>";
?>