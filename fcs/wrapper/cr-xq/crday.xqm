module namespace crday  = "http://aac.ac.at/content_repository/data-ay";

import module namespace repo-utils =  "http://aac.ac.at/content_repository/utils" at  "repo-utils.xqm";

import module namespace xdb="http://exist-db.org/xquery/xmldb";
(:import module namespace diag =  "http://www.loc.gov/zing/srw/diagnostic/" at  "modules/diagnostics/diagnostics.xqm";
import module namespace util="http://exist-db.org/xquery/util";
import module namespace kwic="http://exist-db.org/xquery/kwic";
:)
declare namespace sru = "http://www.loc.gov/zing/srw/";
declare namespace fcs = "http://clarin.eu/fcs/1.0";
declare namespace cmd = "http://www.clarin.eu/cmd/";
(:declare namespace tei = "http://www.tei-c.org/ns/1.0";:)

declare variable $crday:docTypeTerms := "Terms";

(:~ analyzes the xml-structure - sub-elements and text-nodes
in the context of given collection, starting from given xpath

@param $context nodeset to analyze
@param $path if starts-with '/' or = '' start directly at the $context, else eval on f 'descendants-or-self'-axis 
calls elem-r for recursive processing

@returns xml-with paths and numbers 
:)
declare function crday:ay-xml($context as item()*, $path as xs:string, $depth as xs:integer ) as element() {
  
  (:let $collection := collection($cr:dataPath),
  if ($collections[1] eq $cr:collectionRoot) then
  util:eval(fn:concat("$collection/descendant::IsPartOf[ft:query(., <query><term>", xdb:decode($coll), "</term></query>)]/ancestor-or-self::CMD/descendant-or-self::", $path))
  :)
   let $ns-uri := namespace-uri($context[1]/*),
       $qname := $context[1]/*/name(),
       $prefix := if (exists(prefix-from-QName($qname))) then prefix-from-QName($qname) else "",
       $dummy := if (exists($ns-uri)) then util:declare-namespace($prefix,$ns-uri) else ()
   
   let $full-path := if (starts-with($path,'/') or $path = '' ) then
                        fn:concat("$context", $path)
                       else     fn:concat("$context/descendant-or-self::", $path)
                            
  let $path-nodes := util:eval($full-path )
  
  let $entries := crday:elem-r($path-nodes, $path, $ns-uri, $depth, $depth),
(:      $coll-names-value := if (fn:empty($collections)) then () else attribute colls {fn:string-join($collections, ",")},:)
        $dummy-undeclare-ns := util:declare-namespace("",xs:anyURI("")), 
	  $result := element {$crday:docTypeTerms} {
(:      		  $coll-names-value,:)
      		  attribute depth {$depth},
      		  attribute created {fn:current-dateTime()},
      		  $entries  
		}
    return $result      	
};

(:~ goes down the xml-structure recursively and creates a summary about it along the way

namespace aware (handles namespace: none, default, explicit)

:)
declare function crday:elem-r($path-nodes as node()*, $path as xs:string, $ns as xs:anyURI?, $max-depth as xs:integer, $depth as xs:integer) as element() {
      let $path-count := count($path-nodes),
	$child-elements := $path-nodes/child::element(),
	$child-ns-qnames := if (exists($child-elements)) then distinct-values($child-elements/concat(namespace-uri(), '|', name())) else (),	
	$nodes-child-terminal := if (empty($child-elements)) then $path-nodes else () (: Maybe some selected elements $child-elements[not(element())] later on :),
	$text-nodes := $nodes-child-terminal/text(),
	$text-count := count($text-nodes),
	$text-count-distinct := count(distinct-values($text-nodes)),
	$dummy-undeclare-ns := util:declare-namespace("",xs:anyURI(""))
	return 
(:	<Term path="{fn:concat("//", $path)}" name="{text:groups($path, "/([^/]+)$")[last()]}" count="{$path-count}" count_text="{$text-count}"  count_distinct_text="{$text-count-distinct}">{ :)
	<Term path="{fn:concat("", translate($path,'/','.'))}" name="{(text:groups($path, "/([^/]+)$")[last()],$path)[1] }" count="{$path-count}" count_text="{$text-count}"  count_distinct_text="{$text-count-distinct}">{
	   (attribute ns {$ns},
	  if ($depth > 0) then
	    for $ns-qname in $child-ns-qnames[. != '']
	       let $ns-uri := substring-before($ns-qname, '|'),
	           $qname := substring-after($ns-qname, '|'),
	           $prefix := if (exists(prefix-from-QName($qname))) then prefix-from-QName($qname) else "",
	           (: dynamically declare a namespace for the next step, if one is defined in current context :)
	           $dummy := if (exists($ns-uri)) then util:declare-namespace($prefix,$ns-uri) else ()
	           return  
	           crday:elem-r(util:eval(concat("$path-nodes/", $qname)), concat($path, '/', $qname), $ns-uri, $max-depth, $depth - 1)			
	  else 'maxdepth'
	)}</Term>
};


(:~ analyze xml-structure
  API function queryModel. 
:)
(:declare function crday:ay-xml-wrap($init-xpath as xs:string, $collection as xs:string+, $max-depth as xs:integer) as item()? {
	
  let $name := repo-utils:gen-cache-id("model", ($collection, $cmd-index-path), xs:string($max-depth)),
    $doc := 
    if (repo-utils:is-in-cache($name)) then
      repo-utils:get-from-cache($name)
    else
      let $data := cr:elem($collection, $cmd-index-path, $max-depth)
        return repo-utils:store-in-cache($name, $data)
        
  return $doc	
};
:)