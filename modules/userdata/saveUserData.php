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

  if (function_exists('xdebug_disable')) {
    xdebug_disable();
  }
//  xdebug_start_error_collection();
  header("content-type: text/xml");
  // print_r's output is directed to the browser!
  print "<userdata>";
  print "<debug>"
  . "<var name='\$_POST'>";
  print(str_replace(array("<", "&", ">"), array("&lt;", "&amp;", "&gt;"), print_r($_POST, true)));
  print "</var></debug>";
  if (isset($_POST['uid']) && trim($_POST['uid']) != "" && isset($_POST['data']) && trim($_POST['data']) != "") {
    $uid = trim($_POST['uid']);
    $data = trim($_POST['data']);

    print "uid: $uid";

    $filename = $userdataPath . $uid . ".json";

    // disable warning
    $handle = @fopen($filename, "w");
    if ($handle === false) {
        print "<msg>open error</msg>";
    } else {
        if (fwrite($handle, $data) === false) {
            "<msg>write error</msg>";
        } else {
            print "<msg>ok</msg>";
        }
        fclose($handle);
    }
} else {
    print "<msg>not ok</msg>";
}
//xdebug_stop_error_collection();
//$xdebug_errors = xdebug_get_collected_errors();
//print "<debug>";
//print "<xdebug>";
//print(str_replace(array("<", "&", ">"), array("&lt;", "&amp;", "&gt;"), print_r($xdebug_errors, true)));
//print "</xdebug>";
//print "</debug>";
print "</userdata>";