module namespace cr  = "http://aac.ac.at/content_repository";

import module namespace repo-utils =  "http://aac.ac.at/content_repository/utils" at  "repo-utils.xqm";

(:
 $Id: cmd-model.xqm 1045 2011-01-09 20:28:15Z vronk $
:)

import module namespace diag =  "http://www.loc.gov/zing/srw/diagnostic/" at  "modules/diagnostics/diagnostics.xqm";
import module namespace xdb="http://exist-db.org/xquery/xmldb";
import module namespace util="http://exist-db.org/xquery/util";
import module namespace kwic="http://exist-db.org/xquery/kwic";

declare namespace sru = "http://www.loc.gov/zing/srw/";
declare namespace fcs = "http://clarin.eu/fcs/1.0";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

declare variable $cr:cmdiDatabaseURI as xs:string := "xmldb:exist:///db";

declare variable $cr:dataPath as xs:string := "/db/content_repository";

declare variable $cr:mappings := doc('/db/content_repository/scripts/mappings.xml');

declare variable $cr:groupXsl := doc('/db/clarin/group.xsl');
(: declare variable $cr:resultXsl := doc('/db/content_repository/scripts/xsl/values2view.xsl'); :)
(: declare variable $cr:resultXsl := doc('/db/content_repository/scripts/xsl/result2view.xsl'); :)

declare variable $cr:getCollections as xs:string := "getCollections";
declare variable $cr:queryModel as xs:string := "queryModel";
declare variable $cr:scanIndex as xs:string := "scanIndex";
declare variable $cr:searchRetrieve as xs:string := "searchRetrieve";

declare variable $cr:docTypeTerms as xs:string := "Terms";
declare variable $cr:docTypeSuffix as xs:string := "Values";

declare variable $cr:scanSortText as xs:string := "text";
declare variable $cr:scanSortSize as xs:string := "size";

declare variable $cr:collectionDocName as xs:string := "collection.xml";

declare variable $cr:collectionRoot as xs:string := "root";

declare variable $cr:maxDepth as xs:integer := 8;
declare variable $cr:valuesLimit as xs:integer := 100;


(:~
  API function searchRetrieve. 
:)
declare function cr:search-retrieve($query as xs:string, $collections as xs:string+, $format as xs:string, $start-item as xs:integer, $end-item as xs:integer) as item()* {
  let $start-time := util:system-dateTime(),
    $collection := collection($cr:dataPath),
    $decoded-query := xdb:decode($query),
    $xpath-query := cr:transform-query($decoded-query),
    $sanitized-query := fn:concat("$collection", $xpath-query),    
    $results := util:eval($sanitized-query)
(:    if ($collections[1] eq $cr:collectionRoot) then
    else
      for $coll in $collections return util:eval(fn:concat("$collection/ft:query(descendant::IsPartOf, <term>", xdb:decode($coll) ,"</term>)/ancestor-or-self::CMD", $sanitized-query))
:)
	let	$result-count := fn:count($results),
    $result-seq := fn:subsequence($results, $start-item, $end-item),
    $seq-count := fn:count($result-seq),
	$end-time := util:system-dateTime()

    
    let $result-fragment :=
    <sru:searchRetrieveResponse>
      <sru:numberOfRecords>{$result-count}</sru:numberOfRecords>
      <sru:echoedSearchRetrieveRequest>{if ($decoded-query ne $sanitized-query) then concat("Rewritten to '", $sanitized-query, "'") else $query, $collections, $start-item, $end-item}</sru:echoedSearchRetrieveRequest>
      <sru:extraResponseData>
      	<sru:returnedRecords>{$seq-count}</sru:returnedRecords>
		<sru:duration>{$end-time - $start-time}</sru:duration>
      </sru:extraResponseData>
      <sru:records>
	       {for $rec at $pos in $result-seq
	           let $exp-rec := util:expand($rec, "expand-xincludes=no") (: kwic:summarize($rec,<config width="40"/>) :)
	           return 
	               <sru:record>
	                   <sru:recordSchema>http://clarin.eu/fcs/1.0/Resource.xsd</sru:recordSchema>
	                   <sru:recordPacking>xml</sru:recordPacking>
	                   <sru:recordData>	                       
	                       <fcs:Resource>
	                           <fcs:ResourceFragment>
    	                         <fcs:DataView type="kwic">{$exp-rec}</fcs:DataView>
    	                       </fcs:ResourceFragment>
	                       </fcs:Resource>
	                   </sru:recordData>
	                   <sru:recordPosition>{$pos}</sru:recordPosition>
	                   <sru:recordIdentifier>{$rec/@xml:id}</sru:recordIdentifier>
	                </sru:record>
	       }
      </sru:records>
    </sru:searchRetrieveResponse>

    return
	repo-utils:serialise-as($result-fragment, $format)

};



(:
extracted from search-retrieve for a separate summary-function
	let $summary-fragment :=
		if (contains($format,'withSummary')) then
			let $used-profiles := for $profile in distinct-values($results//Components/concat(child::element()/name(),'##',../Header/MdProfile))
	 						let $profile-id := substring-after($profile,'##'), $profile-name := substring-before($profile,'##')
							return <profile id="{$profile-id}" name="{$profile-name}" count="{count($results//Components[concat(child::element()/name(),'##',../Header/MdProfile) eq $profile])}" />,
				$end-time2 := util:system-dateTime(),
				$result-summary := cr:elem-r($result-seq//Components, "Components", $cr:maxDepth, $cr:maxDepth),
		    	$end-time3 := util:system-dateTime(),
				$duration :=  concat(($end-time - $start-time),", ", ($end-time2 - $start-time),", ", ($end-time3 - $start-time))
			return (<duration>{$duration}</duration>, <usedProfiles>{$used-profiles}</usedProfiles>,<resultSummary>{$result-summary}</resultSummary>)
		else <duration>{$end-time - $start-time}</duration>


:)

(:~
  API function queryModel. 
:)
declare function cr:query-model($cmd-index-path as xs:string, $collection as xs:string+, $format as xs:string, $max-depth as xs:integer) as item()? {
	
  let $name := repo-utils:gen-cache-id("model", ($collection, $cmd-index-path), xs:string($max-depth)),
    $doc := 
    if (repo-utils:is-in-cache($name)) then
      repo-utils:get-from-cache($name)
    else
      let $data := cr:elem($collection, $cmd-index-path, $max-depth)
        return repo-utils:store-in-cache($name, $data)
  return 
    repo-utils:serialise-as($doc, $format)	
};

(:~
  API function scanIndex. 
two phases: 
	1.one create full index for given path/element (and cache)
	2. select wished subsequence (on second call, only the second step is performed)
:)
declare function cr:scan-index($q as xs:string, $collection as xs:string+, $format as xs:string, $start-item as xs:integer, $max-items as xs:integer, $p-sort as xs:string?) as item()? {

  let $qa := tokenize($q,'='),
	 $cmd-index-path := $qa[1],
 	 $filter := ($qa[2],'')[1],
	 $sort := if ($p-sort eq $cr:scanSortText or $p-sort eq $cr:scanSortSize) then $p-sort else $cr:scanSortText,
  	  $name := repo-utils:gen-cache-id("index", ($collection, $cmd-index-path),"1"),
    (: skip cache $doc := cr:values($cmd-index-path, $collection) :)
    $doc := if (repo-utils:is-in-cache($name)) then
      repo-utils:get-from-cache($name) 
    else  
      let  $data := cr:values($cmd-index-path, $collection)
        return repo-utils:store-in-cache($name, $data)

	(: extract the required subsequence (according to given sort) :)
	let $res-term := transform:transform($doc,$cr:groupXsl, 
			<parameters><param name="mode" value="subsequence"/>
						<param name="sort" value="{$sort}"/>
						<param name="filter" value="{$filter}"/>
						<param name="start-item" value="{$start-item}"/>
						<param name="max-items" value="{$max-items}"/>
			</parameters>),
		$count-items := count($res-term/v),
		$colls := if (fn:empty($collection)) then '' else fn:string-join($collection, ","),
		$ created := fn:current-dateTime(),
		$scan-clause := concat($cmd-index-path, '=', $filter),
		$res := <Terms colls="{$colls}" created="{$created}" count_items="{$count-items}" 
					start-item="{$start-item}" max-items="{$max-items}" sort="{$sort}" scanClause="{$scan-clause}"  >{$res-term}</Terms>

(:	let	$result-count := $doc/Term/@count,
    $result-seq := fn:subsequence($doc/Term/v, $start-item, $end-item),
	$result-frag := ($doc/Term, $result-seq),
    $seq-count := fn:count($result-seq) :)

  return 
    repo-utils:serialise-as($res, $format)	
};



(: 
  **********************
  queryModel, scanIndex - subfunctions
:)

(: This expects a CQL-query that it (will be able to) translates to XPath 
returns: XPath version of the CQL-query :)
declare function cr:transform-query($cql-query as xs:string) as xs:string {
	let $query-constituents := tokenize($cql-query, " ")
	let $index := if (count($query-constituents)=1) then
				  "cql.serverChoice"
				 else 
					$query-constituents[1]				
	let $searchTerm := if (count($query-constituents)=1) then
							$cql-query
						else
							$query-constituents[3]
	let $res := if (exists($cr:mappings/map/index[@key=$index])) then
					  concat("//", $cr:mappings/map/index[@key=$index], "[ft:query(.,'", $searchTerm, "')]",
								"/ancestor-or-self::", $cr:mappings/map/index[@key=$index]/@base_elem)
					else 
 					  concat("//",$index, "[contains(.,'", $searchTerm, "')]")

	return $res

};

declare function cr:sanitize-query($query as xs:string) as xs:string {

let $last-segment := text:groups($query, "/([^/]+)$")[last()]
return 
  if ($query = ("//*", "descendant::element()")) then 
    "" 
  else if ($last-segment = ("Title", "Name", "Role", "Genre", "Country", "Continent", "MdSelfLink", "IsPartOf")) then
    (: concat("ft:query(",:) if ($query eq concat("//", $last-segment)) then concat("[descendant::", $last-segment, "]") else concat("[", $query, "]") (:, ", <regex>.*</regex>)") :)
  else $query
};

declare function cr:elem($collections as xs:string+, $path as xs:string, $depth as xs:integer) as element() {
  let $collection := collection($cr:dataPath),
    $path-nodes :=
    if ($collections[1] eq $cr:collectionRoot) then
      util:eval(fn:concat("$collection/descendant-or-self::", $path))
    else
      for $coll in $collections 
      return
	util:eval(fn:concat("$collection/ft:query(descendant::IsPartOf, <query><term>", xdb:decode($coll), "</term></query>)/ancestor-or-self::CMD/descendant-or-self::", $path))
   
	 	let $entries := cr:elem-r($path-nodes, $path, $depth, $depth),
 			$coll-names-value := if (fn:empty($collections)) then () else attribute colls {fn:string-join($collections, ",")},
	      	$result := element {$cr:docTypeTerms} {
      		  $coll-names-value,
		  attribute depth {$depth}, 
		  attribute created {fn:current-dateTime()},
		  $entries  
		}
    return $result      	
};

declare function cr:elem-r($path-nodes as node()*, $path as xs:string, $max-depth as xs:integer, $depth as xs:integer) as element() {
      let $path-count := count($path-nodes),
	$child-elements := $path-nodes/child::element(),
	$subs := distinct-values($child-elements/name()),
	$nodes-child-terminal := if (empty($child-elements)) then $path-nodes else () (: Maybe some selected elements $child-elements[not(element())] later on :),
	$text-nodes := $nodes-child-terminal/text(),
	$text-count := count($text-nodes),
	$text-count-distinct := count(distinct-values($text-nodes))
	return 
(:	<Term path="{fn:concat("//", $path)}" name="{text:groups($path, "/([^/]+)$")[last()]}" count="{$path-count}" count_text="{$text-count}"  count_distinct_text="{$text-count-distinct}">{ :)
	<Term path="{fn:concat("//", $path)}" name="{(text:groups($path, "/([^/]+)$")[last()],$path)[1] }" count="{$path-count}" count_text="{$text-count}"  count_distinct_text="{$text-count-distinct}">{
	  if ($depth > 0) then
	    (for $elname in $subs[. != '']
	    return
	      cr:elem-r(util:eval(concat("$path-nodes/", $elname)), concat($path, '/', $elname), $max-depth, $depth - 1)
			(: values moved to own function: scanIndex 
		      if ($max-depth eq 1 and $text-count gt 0) then cr:values($path-nodes) else ()) :)
						)
	  else 'maxdepth'
	}</Term>
};

declare function cr:paths($n) {
	for $el in $n
	return <Term name="{$el/name()}"> {
	for $anc in $el/parent::element()
	return util:node-xpath($anc)
	}</Term>
};

declare function cr:collect-nodes($collections as xs:string+, $path as xs:string) as element()* {
  let $collection := collection($cr:dataPath),
    $path-nodes :=
    if ($collections[1] eq $cr:collectionRoot) then
      util:eval(fn:concat("$collection/descendant-or-self::", $path))
    else
      for $coll in $collections 
      return
	util:eval(fn:concat("$collection/ft:query(descendant::IsPartOf, <query><term>", xdb:decode($coll), "</term></query>)/ancestor-or-self::CMD/descendant-or-self::", $path))
   
	return $path-nodes
};

declare function cr:values($path as xs:string,$collections as xs:string+) as element() {

 	let $nodes := cr:collect-nodes($collections, $path),
(:		$term := <Term path="{fn:concat("//", $path)}" name="{(text:groups($path, "/([^/]+)$")[last()],$path)[1] }" >{$nodes}</Term> 
		@name is added in xslt:)
		$term := <Term path="{fn:concat("//", $path)}"  >{$nodes}</Term>

	(: use XSLT-2.0 for-each-group functionality to aggregate the values of a node - much, much faster, than XQuery :)
	return transform:transform($term,$cr:groupXsl, ())

};

