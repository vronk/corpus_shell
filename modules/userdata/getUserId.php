<?php
/**
 * Generates a GUID for identifying a particular corpus_shell user's 
 * persistence file on this web server
 * 
 * A utility service which is otherwise unrelated to the storage and retrieval of
 * the data even though the identifier will be used as a part of the filename
 * on the server. The data is presented to the client as a JSON object with a
 * property of "id". The browser is advised to refetch such GUIDs every time.
 * @see getUserData.php
 * @see saveUserData.php
 * @package user-data
 */
 
 /**
  * Creates a GUID based on the time and origin of the request.
  */
 function create_guid($namespace = '')
 {
    $guid = '';
    $uid = uniqid("", true);
    $data = $namespace;
    $data .= $_SERVER['REQUEST_TIME'];
    $data .= $_SERVER['HTTP_USER_AGENT'];
    $data .= $_SERVER['LOCAL_ADDR'];
    $data .= $_SERVER['LOCAL_PORT'];
    $data .= $_SERVER['REMOTE_ADDR'];
    $data .= $_SERVER['REMOTE_PORT'];
    $hash = strtoupper(hash('ripemd128', $uid . $guid . md5($data)));
    $guid = '{' .
            substr($hash,  0,  8) .
            '-' .
            substr($hash,  8,  4) .
            '-' .
            substr($hash, 12,  4) .
            '-' .
            substr($hash, 16,  4) .
            '-' .
            substr($hash, 20, 12) .
            '}';
    return $guid;
 }

 header('cache-control: no-cache, must-revalidate');
 header('expires: Mon, 26 Jul 1997 05:00:00 GMT');
 header('content-type: application/json; charset=utf-8');

 $uid = create_guid();
 $data = array('id' => $uid);

 echo json_encode($data);

?>