module namespace repo-utils = "http://aac.ac.at/content_repository/utils";

import module namespace xdb="http://exist-db.org/xquery/xmldb";
import module namespace diag =  "http://www.loc.gov/zing/srw/diagnostic/" at  "modules/diagnostics/diagnostics.xqm";

(: 
  ***********************
  HELPER function - dealing with caching the results
:)

declare variable $repo-utils:xmlExt as xs:string := ".xml";
declare variable $repo-utils:cachePath as xs:string := "/db/cache";

declare variable $repo-utils:responseFormatXml as xs:string := "xml";
declare variable $repo-utils:responseFormatJSon as xs:string := "json";
declare variable $repo-utils:responseFormatText as xs:string := "text";
declare variable $repo-utils:responseFormatHTML as xs:string := "html";

declare variable $repo-utils:resultXsl := doc('/db/content_repository/scripts/xsl/result2view.xsl');


(: 
  Function for telling wether the document is available or not.
  generic, currently not used
:)
declare function repo-utils:is-doc-available($collection as xs:string, $doc-name as xs:string) as xs:boolean {
  fn:doc-available(fn:concat($collection, "/", $doc-name))
};

declare function repo-utils:is-in-cache($doc-name as xs:string) as xs:boolean {
  fn:doc-available(fn:concat($repo-utils:cachePath, "/", $doc-name))
};

declare function repo-utils:get-from-cache($doc-name as xs:string) as item()* {
      fn:doc(fn:concat($repo-utils:cachePath, "/", $doc-name))
};

(:  
  Store the collection listing for given collection.
:)
declare function repo-utils:store-in-cache($doc-name as xs:string, $data as node()) as item()* {
  let $clarin-writer := fn:doc("/db/clarin/writer.xml"),
  $dummy := xdb:login($repo-utils:cachePath, $clarin-writer//write-user/text(), $clarin-writer//write-user-cred/text())
  let $store := (: util:catch("org.exist.xquery.XPathException", :) xdb:store($repo-utils:cachePath, $doc-name, $data), (: , ()) :)
  $stored-doc := fn:doc(concat($repo-utils:cachePath, "/", $doc-name))
  return $stored-doc
};

(:
  Create document name with md5-hash for selected collections (or types) 
  for reuse.
:)
declare function repo-utils:gen-cache-id($type-name as xs:string, $keys as xs:string+, $depth as xs:string) as xs:string {
  let $name-prefix := fn:concat($type-name, $depth),
    $sorted-names := for $key in $keys order by $key ascending return $key
    return
    fn:concat($name-prefix, "-", util:hash(string-join($sorted-names, ""), "MD5"), $repo-utils:xmlExt)
};

(:
  Seraliseringsformat. 
:)
declare function repo-utils:serialise-as($item as node()?, $format as xs:string) as item()? {
      if ($format eq $repo-utils:responseFormatJSon) then
	       let $option := util:declare-option("exist:serialize", "method=text media-type=application/json")
	       return $item
	       (: json:xml-to-json($item) :)
	    else if (contains($format, $repo-utils:responseFormatHTML)) then
	           let $res := transform:transform($item,$repo-utils:resultXsl, 
              			<parameters><param name="format" value="{$format}"/>
              			</parameters>)          
               let $option := util:declare-option("exist:serialize", "method=xml media-type=text/html")
	           return $res
	   else
	       let $option := util:declare-option("exist:serialize", "method=xml media-type=application/xml")
	    return $item

(: $repo-utils:responseFormatXml, $repo-utils:responseFormatText:)	     
       
	    (:let $option := 
	              if (contains($format, $repo-utils:responseFormatHTML)) then
	                  util:declare-option("exist:serialize", "method=xml media-type=text/xhtml")
	              else 
    	              util:declare-option("exist:serialize", "method=xml media-type=application/xml")
:)
          
	          	(: $item :)
};

(:
declare function diag:diagnostics($key as xs:string, $param as xs:string) as item()? {
    
	let $diag := 
	       if (exists($diag:diagnostics//diag:diagnostic[@key=$key])) then
	               $diag:diagnostics//diag:diagnostic[@key=$key]
	           else $diag:diagnostics//diag:diagnostic[@key='general-error']
	   return
	       <diagnostics>
	           {$diag}
	       </diagnostics>	   
};
:)