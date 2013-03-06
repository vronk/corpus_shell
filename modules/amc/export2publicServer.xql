xquery version "3.0";

import module namespace httpclient="http://exist-db.org/xquery/httpclient";
import module namespace util="http://exist-db.org/xquery/util"; 

(: credentials :)
declare variable $username := 'admin';
declare variable $password := 'p';
 
(: document to retrieve, and document to upload :)
declare variable $in  := '/db/apps/sade-projects/amc/config.xml';
declare variable $out := '/db/cr-data/test.xml';
 
(: URI of the REST interface of eXist instance :)
declare variable $rest := 'http://clarin.aac.ac.at/exist9/rest';
let $auth := concat("Basic ", util:base64-encode(concat($username, ':', $password)))
let $headers := <headers><header name="Authorization" value="{$auth}"/>
                        </headers>

let $doc         := doc($in)
  return 
      httpclient:put(xs:anyURI(concat($rest, $out)),
                 $doc,
                 true(),
                 $headers)