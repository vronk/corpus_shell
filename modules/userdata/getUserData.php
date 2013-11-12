<?php
/**
 * This file script is used to provide the data stored for some user
 * in a server side storage.
 * 
 * Expects an uid as a POST parameter, returns a file with that name from 
 * $userdatapath which has a json ending. The mime type is set accordingly.
 * @uses $userdataPath
 * @see getUserId.php
 * @package user-data
 */
 
  header('Content-type: application/json');

/**
 * Uses the common modules config file.
 */
  include "../utils-php/config.php";

  header('Content-type: application/json');
// use POST
  if (isset($_POST['uid']) && trim($_POST['uid']) != "")
// use GET
//  if (isset($_GET['uid']) && trim($_GET['uid']) != "")
  {
    $uid = trim($_POST['uid']);
    $filename = $userdataPath . $uid . ".json";
    if (file_exists($filename))
    {
      readfile($filename);
    }
  }
  else
    print "null";