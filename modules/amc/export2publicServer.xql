xquery version "3.0";

import module namespace httpclient="http://exist-db.org/xquery/httpclient";
import module namespace util="http://exist-db.org/xquery/util"; 

(: credentials :)
declare variable $username := 'admin';
declare variable $password := 'sen71blE8dba';
 
(: document to retrieve, and document to upload :)
declare variable $in  := '/db/cr/modules/testing/results/corpus207-solr4-8985-core/';
declare variable $out := '/db/cr-data/amc-vwb/';
 
(: URI of the REST interface of eXist instance :)
declare variable $rest := 'http://clarin.aac.ac.at/exist/rest';
let $auth := concat("Basic ", util:base64-encode(concat($username, ':', $password)))
let $headers := <headers><header name="Authorization" value="{$auth}"/>
                        </headers>
let $start-time := util:system-time()
let $result := for $inf in xmldb:get-child-resources($in)
    
    let $doc         := doc(concat($in,$inf))
    let $outf := concat($rest, $out, $inf)
    let $put := 
      httpclient:put(xs:anyURI($outf),
                 $doc,
                 true(),
                 $headers) 
   return $inf

let $end-time := util:system-time()

return concat($start-time, ' - ', $end-time, '=', ($end-time - $start-time), ': ', count($result) )