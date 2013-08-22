<?php
/**
 * Saves corpus_shell user data for the provided uid
 * 
 * The data is saved in $userdataPath using the uid as filename and .json as
 * extension.
 * If a uid and data is provided as a POST request the function is assumed
 * to have succeeded.
 * TODO: Should be: If the file is actually saved the function has succeeded.
 * On success <msg>ok</msg> is returned on error <msg>not ok<msg>.
 * @uses $userdataPath
 * @see getUserId.php
 * @package user-data
 */
  
  include "../utils-php/config.php";

  // TODO: where is this printed to? who checks this?
  print_r($_POST);
  if (isset($_POST['uid']) && trim($_POST['uid']) != "" && isset($_POST['data']) && trim($_POST['data']) != "")
  {
    print "<msg>ok</msg>";

    $uid = trim($_POST['uid']);
    $data = trim($_POST['data']);

    print "uid: $uid";

    $filename = $userdataPath . $uid . ".json";

    $handle = fopen($filename, "w");
    fwrite($handle, $data);
    fclose($handle);
  }
  else
    print "<msg>not ok</msg>";
?>