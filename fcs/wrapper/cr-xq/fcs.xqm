xquery version '3.0';

(:
: Module Name: FCS
: Date: 2012-03-01
: 
: XQuery 
: Specification : XQuery v1.0
: Module Overview: Federated Content Search
:)

(:~ This module provides methods to serve XML-data via the FCS/SRU-interface  
: @see http://clarin.eu/fcs 
: @author Matej Durco
: @since 2011-11-01 
: @version 1.1 
:)
module namespace fcs = "http://clarin.eu/fcs/1.0";
 
declare namespace err = "http://www.w3.org/2005/xqt-errors";
declare namespace sru = "http://www.loc.gov/zing/srw/";
declare namespace zr = "http://explain.z3950.org/dtd/2.0/";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace cmd = "http://www.clarin.eu/cmd/"; 
import module namespace request="http://exist-db.org/xquery/request";
import module namespace diag =  "http://www.loc.gov/zing/srw/diagnostic/" at  "modules/diagnostics/diagnostics.xqm";

import module namespace repo-utils = "http://aac.ac.at/content_repository/utils" at  "repo-utils.xqm";
import module namespace kwic = "http://exist-db.org/xquery/kwic";
import module namespace cmdcoll = "http://clarin.eu/cmd/collections" at  "/db/cr/modules/cmd/cmd-collections.xqm";
import module namespace cmdcheck = "http://clarin.eu/cmd/check" at  "/db/cr/modules/cmd/cmd-check.xqm";
import module namespace cql = "http://exist-db.org/xquery/cql" at "/db/cr/modules/cqlparser/cqlparser.xqm";

declare variable $fcs:explain as xs:string := "explain";
declare variable $fcs:scan  as xs:string := "scan";
declare variable $fcs:searchRetrieve as xs:string := "searchRetrieve";

declare variable $fcs:scanSortText as xs:string := "text";
declare variable $fcs:scanSortSize as xs:string := "size";
declare variable $fcs:indexXsl := doc('index.xsl');
declare variable $fcs:kwicWidth := 30;

(:~ The main entry-point. Processes request-parameters
regards config given as parameter + the predefined sys-config
@returns the result document (in xml, html or json)
:)
declare function fcs:repo($config-file as xs:string) as item()* {
  let    
    $config := repo-utils:config($config-file),   
     
    $key := request:get-parameter("key", "index"),        
        (: accept "q" as synonym to query-param; "query" overrides:)    
    $q := request:get-parameter("q", ""),
    $query := request:get-parameter("query", $q),    
        (: if query-parameter not present, 'explain' as DEFAULT operation, otherwise 'searchRetrieve' :)
(:    $operation :=  if ($query eq "") then request:get-parameter("operation", $fcs:explain):)
    (: trying without explain as default operation, to get to the static-content by default :)
    $operation :=  if ($query eq "") then request:get-parameter("operation", "static")
                    else request:get-parameter("operation", $fcs:searchRetrieve),
      
    (: take only first format-argument (otherwise gives problems down the line) 
        TODO: diagnostics :)
    $x-format := (request:get-parameter("x-format", $repo-utils:responseFormatHTMLpage))[1],
    $x-context := request:get-parameter("x-context", ""),
    (:
    $query-collections := 
    if (matches($collection-params, "^root$") or $collection-params eq "") then 
      $cr:collectionRoot
    else
		tokenize($collection-params,','),
        :)
(:      $collection-params, :)
  $max-depth as xs:integer := xs:integer(request:get-parameter("maxdepth", 1))

  let $result :=
      (: if ($operation eq $cr:getCollections) then
		cr:get-collections($query-collections, $format, $max-depth)
      else :)
      if ($operation eq $fcs:explain) then
          fcs:explain($x-context, $config)		
      else if ($operation eq $fcs:scan) then
        (: allow optional $index-parameter to be prefixed to the scanClause 
            this is just to simplify input on the client-side :) 
        let $index := request:get-parameter("index", ""),
            $scanClause-param := request:get-parameter("scanClause", ""),
		$scanClause := if ($index ne '' and  not(starts-with($scanClause-param, $index)) ) then 
		                     concat( $index, '=', $scanClause-param)
		                  else
		                     $scanClause-param,
		
		$start-term := request:get-parameter("startTerm", 1),
		$response-position := request:get-parameter("responsePosition", 1),
		$max-terms := request:get-parameter("maximumTerms", 50),
	    $max-depth := request:get-parameter("x-maximumDepth", 1),
		$sort := request:get-parameter("sort", 'text')
		 return fcs:scan($scanClause, $x-context, $start-term, $max-terms, $response-position, $max-depth, $sort, $config) 
        (: return fcs:scan($scanClause, $x-context) :)
	  else if ($operation eq $fcs:searchRetrieve) then
        if ($query eq "") then diag:diagnostics("param-missing", "query")
        else 
      	 let $cql-query := $query,
			$start-item := request:get-parameter("startRecord", 1),
			$max-items := request:get-parameter("maximumRecords", 50),	
			$x-dataview := request:get-parameter("x-dataview", repo-utils:config-value($config, 'default.dataview'))
            (: return cr:search-retrieve($cql-query, $query-collections, $format, xs:integer($start-item), xs:integer($max-items)) :)
            return fcs:search-retrieve($cql-query, $x-context, xs:integer($start-item), xs:integer($max-items), $x-dataview, $config)
    else 
      fcs:static($key, $x-context, $config)
    
   return  repo-utils:serialise-as($result, $x-format, $operation, $config)
   
};


(:~ Strictly speaking not part of the FCS-protocol, 
this function delivers static content, to be returned as HTML.
: @param $content-id required, identifies the content to be returned. The id is matched against id-attribute in the {config:static.path}-collection
: @param $x-context not used right now! probably not needed 
: @returns found static data or nothing 
:)
declare function fcs:static($content-id as xs:string+, $x-context as xs:string*, $config) as item()* {
    let $context := if ($x-context) then $x-context
                    else repo-utils:config-value($config, 'explain')
    let $static-dbcoll := collection(repo-utils:config-value($config,'static.path'))     
   let $data := $static-dbcoll//*[@id=$content-id]
    
    return $data
};

(:~ handles the explain-operation requests.
: @param $x-context optional, identifies a resource to return the explain-record for. (Accepts both MD-PID or Res-PID (MdSelfLink or ResourceRef/text))
: @returns either the default root explain-record, or - when provided with the $x-context parameter - the explain-record of given resource
:)
declare function fcs:explain($x-context as xs:string*, $config) as item()* {
    let $context := if ($x-context) then $x-context
                    else repo-utils:config-value($config, 'explain')
    let $md-dbcoll := collection(repo-utils:config-value($config,'metadata.path'))     
   let $explain := $md-dbcoll//CMD[Header/MdSelfLink/text() eq $context or .//ResourceRef/text() eq $context]//(explain|zr:explain) (: //ResourceRef/text() :)
    
    return $explain
};

(:
TODO?: only read explicit indexes + create index on demand.
:)
(:
declare function fcs:scan($scanClause as xs:string, $x-context as xs:string*) {
    
    let $clause-tokens := tokenize($scanClause,'='),
        $index := $clause-tokens[1],
        $term := $clause-tokens[2],
        (\:$map-index := $repo-utils:mappings/map/index[@key=$index], :\)
        $index-file := concat(repo-utils:config-value('index.prefix'),$index,'.xml'),
        h$result := doc($index-file)
    
    return $result     
};
:)


(:~ This function handles the scan-operation requests
:  (derived from cmd:scanIndex function)
: two phases: 
:   1. one create full index for given path/element within given collection (for now the collection is stored in the name - not perfect) (and cache)
:	2. select wished subsequence (on second call, only the second step is performed)
	
: actually wrapping function handling caching of the actual scan result (coming from do-scan-default())
: or fetching the cached result (if available)
: also dispatching to cmd-collections for the scan-clause=cmd.collections
:   there either scanClause-filter or x-context is used as constraint (scanClause-filter is prefered))

:)
declare function fcs:scan($scan-clause  as xs:string, $x-context as xs:string+, $start-item as xs:integer, $max-items as xs:integer, $response-position as xs:integer, $max-depth as xs:integer, $p-sort as xs:string?, $config) as item()? {

  let $scx := tokenize($scan-clause,'='),
	 $index-name := $scx[1],  
	 (:$index := fcs:get-mapping($index-name, $x-context, $config ), :)
	 (: if no index-mapping found, dare to use the index-name as xpath :) 
(:	 $index-xpath := if ($index/text()) then $index/text() else $index-name, :)
     $index-xpath :=  fcs:index-as-xpath($index-name,$x-context, $config ),
 	 $filter := ($scx[2],'')[1],	 
	 $sort := if ($p-sort eq $fcs:scanSortText or $p-sort eq $fcs:scanSortSize) then $p-sort else $fcs:scanSortText	
	 
	 (: WATCHME: this is quite unreliable, it relies on manual (urn-like) creation of the ids for the resources)  
	   it won't work once the id become PIDs 
	   this is only used for generating the cache-id to store the resultset :)
(:	 let $short-xcontext := substring-after($x-context, concat(repo-utils:config-value($config, 'explain'),':'))
	 let $sanitized-xcontext := if ($short-xcontext='') then repo-utils:sanitize-name($x-context) else $short-xcontext :)
	 let $sanitized-xcontext := repo-utils:sanitize-name($x-context) 
    let $index-doc-name := repo-utils:gen-cache-id("index", ($sanitized-xcontext, $index-name, $sort, $max-depth)),
  
  (: get the base-index from cache, or create and cache :)
  $index-scan := if (repo-utils:is-in-cache($index-doc-name, $config)) then
          repo-utils:get-from-cache($index-doc-name, $config) 
        else
            let $data :=
                if ($index-name eq $cmdcoll:scan-collection) then
                    let $starting-handle := if ($filter ne '') then $filter else $x-context
                    return cmdcoll:colls($starting-handle, $max-depth, cmdcoll:base-dbcoll($config))
                  (: just a hack for now, handling of special indexes should be put solved in some more easily extensible way :)  
                else if ($index-name eq 'cmd.profile') then
                    let $context := repo-utils:context-to-collection($x-context, $config)
                    return  cmdcheck:scan-profiles($context, $config)
                else
                    fcs:do-scan-default($scan-clause, $index-xpath, $x-context, $sort, $config)         

          (: if empty result, return the empty result, but don't store
            to not fill cache with garbage:)
        return         repo-utils:store-in-cache($index-doc-name , $data, $config)
        (:if (number($data//sru:scanResponse/sru:extraResponseData/fcs:countTerms) > 0) then
        
                else $data:)

	(: extract the required subsequence (according to given sort) :)
	let $res-nodeset := transform:transform($index-scan,$fcs:indexXsl, 
			<parameters><param name="scan-clause" value="{$scan-clause}"/>
			            <param name="mode" value="subsequence"/>
						<param name="sort" value="{$sort}"/>
						<param name="filter" value="{$filter}"/>
						<param name="start-item" value="{$start-item}"/>
					    <param name="response-position" value="{$response-position}"/>
						<param name="max-items" value="{$max-items}"/>
			</parameters>),
		$count-items := count($res-nodeset/sru:term),
		(: $colls := if (fn:empty($collection)) then '' else fn:string-join($collection, ","), :)
        $colls := string-join( $x-context, ', ') ,
		$created := fn:current-dateTime()
		(: $scan-clause := concat($xpath, '=', $filter) :)
		(: $res := <Terms colls="{$colls}" created="{$created}" count_items="{$count-items}" 
					start-item="{$start-item}" max-items="{$max-items}" sort="{$sort}" scanClause="{$scan-clause}"  >{$res-term}</Terms> 
					  count_text="{$count-text}" count_distinct_text="{$distinct-text-count}" :)
        (: $res := <sru:scanResponse>
                    <sru:version>1.2</sru:version>
                    {$res-nodeset}        			    
                    <sru:echoedScanRequest>                        
                        <sru:scanClause>{$scan-clause}</sru:scanClause>
                        <sru:maximumTerms>{ $count-items }</sru:maximumTerms>    

                    </sru:echoedScanRequest>
    			</sru:scanResponse>
           :)         
(:	let	$result-count := $doc/Term/@count,
    $result-seq := fn:subsequence($doc/Term/v, $start-item, $end-item),
	$result-frag := ($doc/Term, $result-seq),
    $seq-count := fn:count($result-seq) :)

  return $res-nodeset   
};


declare function fcs:do-scan-default($scan-clause as xs:string, $index-xpath as xs:string, $x-context as xs:string, $sort as xs:string, $config) as item()* {
  (:        let $getnodes := util:eval(fn:concat("$data-collection/descendant-or-self::", $index-xpath)),:)
    let $data-collection := repo-utils:context-to-collection($x-context, $config)
        let $getnodes := util:eval(fn:concat("$data-collection//", $index-xpath)),
            (: if we collected strings, we have to wrap them in elements 
                    to be able to work with them in xsl :) 
            $prenodes := if ($getnodes[1] instance of xs:string) then
                                    for $t in $getnodes return <v>{$t}</v>
                            else if ($getnodes[1] instance of attribute()) then
                                    for $t in $getnodes return <v>{xs:string($t)}</v>
                            else for $t in $getnodes return <v>{string-join($t//text()," ")}</v>
        let $nodes := <nodes path="{fn:concat('//', $index-xpath)}"  >{$prenodes}</nodes>,
        	(: use XSLT-2.0 for-each-group functionality to aggregate the values of a node - much, much faster, than XQuery :)
   	    $data := transform:transform($nodes,$fcs:indexXsl, 
   	                <parameters><param name="scan-clause" value="{$scan-clause}"/>
   	                <param name="sort" value="{$sort}"/></parameters>)
   	    
   	  return $data
};

(:~ main search function (handles the searchRetrieve-operation request) 
:)
declare function fcs:search-retrieve($query as xs:string, $x-context as xs:string*, $startRecord as xs:integer, $maximumRecords as xs:integer, $x-dataview as xs:string*, $config) as item()* {
                                 

        let $start-time := util:system-dateTime()
        let $data-collection := repo-utils:context-to-collection($x-context, $config) 
        (:if ($x-context) then collection($repo-utils:mappings//map[xs:string(@key) eq $x-context]/@path)
                                else $repo-utils:data-collection:)
        
        let $xpath-query := fcs:transform-query ($query, $x-context, $config, true())
         
            (: if there was a problem with the parsing the query  don't evaluate :)
        let $results := if ($xpath-query instance of text() or $xpath-query instance of xs:string) then
                                util:eval(concat("$data-collection",$xpath-query))
                           else ()
    
        let	$result-count := fn:count($results),         
(: deactivated ordering -> TODO: optional
        $ordered-result := fcs:sort-result($results, $query, $x-context, $config),                              :)
        $ordered-result := $results,
        $result-seq := fn:subsequence($ordered-result, $startRecord, $maximumRecords),
        
        $seq-count := fn:count($result-seq),        
        $end-time := util:system-dateTime(),
    
        $xpath-query-no-base-elem := fcs:transform-query ($query, $x-context, $config, false()),
(:      startdd trying to invert the base-elem handling
        $xpath-query-with-base-elem := fcs:transform-query ($query, $x-context, $config, true()),
        $xpath-query-base-elem := substring-after($xpath-query-with-base-elem , $xpath-query
        :)
        (: temporarily deactivated match-seq 
        $match := util:eval (concat("$results", $xpath-query-no-base-elem)),
        $match-seq := util:eval (concat("$result-seq", $xpath-query-no-base-elem)),:)
        $match-seq := (),
        $result-seq-match := fcs:highlight-result($result-seq, $match-seq, $x-context, $config),
        (:$match := (),
        $result-seq-match := $result-seq,:)
        $records :=
          <sru:records>
    	       {for $rec at $pos in $result-seq-match	           
    	           let $rec-data := fcs:format-record-data($rec,$x-dataview, $x-context, $config)	           
    	           return 
    	               <sru:record>
    	                   <sru:recordSchema>http://clarin.eu/fcs/1.0/Resource.xsd</sru:recordSchema>
    	                   <sru:recordPacking>xml</sru:recordPacking>
    	                   <sru:recordData>
    	                     {$rec-data}
                            </sru:recordData>
    	                   <sru:recordPosition>{$pos}</sru:recordPosition>
    	                   <sru:recordIdentifier>{xs:string($rec-data/fcs:ResourceFragment[1]/@ref) }</sru:recordIdentifier>
    	                </sru:record>
    	       }
          </sru:records>,
        $end-time2 := util:system-dateTime(),
        $result :=
        <sru:searchRetrieveResponse>
          <sru:numberOfRecords>{$result-count}</sru:numberOfRecords>
          <sru:echoedSearchRetrieveRequest>
              <sru:version>1.2</sru:version>
              <sru:query>{$query}</sru:query>
              <fcs:x-context>{$x-context}</fcs:x-context>
              <fcs:x-dataview>{$x-dataview}</fcs:x-dataview>
              <sru:startRecord>{$startRecord}</sru:startRecord>
              <sru:maximumRecords>{$maximumRecords}</sru:maximumRecords>
              <sru:query>{$query}</sru:query>          
              <sru:baseUrl>{repo-utils:config-value($config, "base.url")}</sru:baseUrl> 
          </sru:echoedSearchRetrieveRequest>
          <sru:extraResponseData>
          	<fcs:returnedRecords>{$seq-count}</fcs:returnedRecords>
            <fcs:numberOfMatches>{ () (: count($match) :)}</fcs:numberOfMatches>
    		<fcs:duration>{($end-time - $start-time, $end-time2 - $end-time) }</fcs:duration>
    		<fcs:transformedQuery>{ $xpath-query }</fcs:transformedQuery>
          </sru:extraResponseData>
          { ($records,
            if ($xpath-query instance of element(diagnostics)) then  <sru:diagnostics>{$xpath-query/*}</sru:diagnostics> else ()
           ) }
        </sru:searchRetrieveResponse>
    
        return $result
    
};

declare function fcs:format-record-data($record-data as node(), $data-view as xs:string*, $x-context as xs:string*, $config as node()) as item()*  {
(:    let $record-data := util:expand($record, ""):)
                        (:	      cmdcoll:get-md-collection-name($raw-record-data):)
	let $title := fcs:apply-index ($record-data, "title",$x-context, $config)	   
	let $resource-pid := fcs:apply-index ($record-data, "resource-pid",$x-context, $config)	
	let $resourcefragment-pid := fcs:apply-index ($record-data, "resourcefragment-pid",$x-context, $config)	
	(: to repeat current $x-format param-value in the constructed requested :)
	let $x-format := request:get-parameter("x-format", $repo-utils:responseFormatXml)
	let $resourcefragment-ref := if (exists($resourcefragment-pid)) then concat('?operation=searchRetrieve&amp;query=resourcefragment-pid="', xmldb:encode-uri($resourcefragment-pid), '"&amp;x-dataview=full&amp;x-context=', $x-context)
	                                      else ""
	
    let $kwic := if ('kwic' = $data-view) then
                   let $kwic-config := <config width="{$fcs:kwicWidth}"/>
                   let $kwic-html := kwic:summarize($record-data, $kwic-config)
                       
                    return if (exists($kwic-html)) then  
                                           <fcs:DataView type="kwic">{
                                               for $match in $kwic-html 
                                               return (<fcs:c type="left">{$match/span[1]/text()}</fcs:c>, 
                                       (: <c type="left">{kwic:truncate-previous($exp-rec, $matches[1], (), 10, (), ())}</c> :)
                                                      <fcs:kw>{$match/span[2]/text()}</fcs:kw>,
                                                      <fcs:c type="right">{$match/span[3]/text()}</fcs:c>)            	                       
                                       (: let $summary  := kwic:get-summary($exp-rec, $matches[1], $config) :)
                        (:	                               <fcs:DataView type="kwic-html">{$kwic-html}</fcs:DataView>:)
                                            }</fcs:DataView>
(: DEBUG:                                            <fcs:DataView>{$kwic-html}</fcs:DataView>) :)
                                     else (: if no kwic-match let's take first 100 characters 
                                        There c/should be some more sophisticated way to extract most significant info 
                                        e.g. match on the query-field :)
                                       <fcs:DataView type="kwic">{substring($record-data,1,(2 * $fcs:kwicWidth))}</fcs:DataView>                                         
                     else ()
    (: prev-next :)                     
    let $dv-navigation:= if ('navigation' = $data-view) then
                            let $context-map := fcs:get-mapping("",$x-context, $config)
                          let $sort-index := if (exists($context-map/@sort)) then $context-map/@sort
                                                 else "title"
                           (: WATCHME: this only works if default-sort and title index are the same :)
                           (:important is the $responsePosition=2 :)
                          let $prev-next-scan := fcs:scan(concat($sort-index, '=', $title),$x-context, 1,3,2,1,'text',$config)  
                          let $rf-prev := $prev-next-scan//sru:terms/sru:term[1]/sru:value
                          let $rf-next := $prev-next-scan//sru:terms/sru:term[3]/sru:value                                
                          let $rf-prev-ref := concat('?operation=searchRetrieve&amp;query=resourcefragment-pid="', xmldb:encode-uri($rf-prev), '"&amp;x-dataview=full&amp;x-dataview=navigation&amp;x-context=', $x-context)                                                 
                          let $rf-next-ref:= concat('?operation=searchRetrieve&amp;query=resourcefragment-pid="', xmldb:encode-uri($rf-next), '"&amp;x-dataview=full&amp;x-dataview=navigation&amp;x-context=', $x-context)
                           return
                             (<fcs:ResourceFragment type="prev" pid="{$rf-prev}" ref="{$rf-prev-ref}"  />,
                             <fcs:ResourceFragment type="next" pid="{$rf-next}" ref="{$rf-next-ref}"  />)
                        else ()
                     
    let $dv-title := <fcs:DataView type="title">{$title[1]}</fcs:DataView>                      

    return if ($data-view = 'raw') then $record-data 
            else <fcs:Resource pid="{$resource-pid}" >
                       <fcs:ResourceFragment pid="{$resourcefragment-pid}" ref="{$resourcefragment-ref}" >                       
                         {($dv-title, $kwic, 
                         if ('full' = $data-view or not(exists($kwic))) then <fcs:DataView type="full">{$record-data}</fcs:DataView>
                             else ()
                           )}
                           </fcs:ResourceFragment>
                           {$dv-navigation}
                       </fcs:Resource>


};

(:~ This expects a CQL-query that it translates to XPath

It relies on the external cqlparser-module, that delivers the query in XCQL-format (parse-tree of the query as XML)
and then applies a stylesheet

@params $x-context identifier of a resource/collection
@returns XPath version of the CQL-query, or diagnostics bubbling up the call-chain if parse-error! 
:)
declare function fcs:transform-query($cql-query as xs:string, $x-context as xs:string, $config, $base-elem-flag as xs:boolean) as item() {
    
    let $mappings := repo-utils:config-value($config, 'mappings'),    
        $xpath-query := cql:cql2xpath ($cql-query, $x-context, $mappings),
    
    (: if there was a problem with the parsing the query  don't evaluate :)
    $final-xpath := if ($base-elem-flag and ($xpath-query instance of text() or $xpath-query instance of xs:string)) then
                let $context-map := fcs:get-mapping("",$x-context, $config),
                    $default-mappings := fcs:get-mapping("", 'default', $config ),
(:                    $index-map := $context-map/index[xs:string(@key) eq $index],
                (\: get either a) the specific base-element for the index, 
                      b) the default for given map,
                      c) the index itself :\)
                    $base-elem := if (exists($index-map/@base_elem)) then xs:string($index-map/@base_elem) 
                        else if (exists($context-map/@base_elem)) then xs:string($context-map/@base_elem)
                        else $index:)                        
                    $base-elem := if (exists($context-map[@base_elem])) then
                                        if (not($context-map/@base_elem='')) then
                                            concat('ancestor-or-self::', $context-map/@base_elem)
                                         else '.'
                                    else if (exists($default-mappings[@base_elem])) then
                                        concat('ancestor-or-self::', $default-mappings/@base_elem)
                                    else '.'
                                    
                return concat($xpath-query,'/', $base-elem)
            else
                $xpath-query
                
      return $final-xpath
 };

(: old version, "manually" parsing the cql-string
it accepted/understood: 
term
index=term
index relation term
:)
declare function fcs:transform-query-old($cql-query as xs:string, $x-context as xs:string, $type as xs:string, $config ) as xs:string {

    let $query-constituents := if (contains($cql-query,'=')) then 
                                        tokenize($cql-query, "=") 
                                   else tokenize($cql-query, " ")    
	let $index := if ($type eq 'scan' or count($query-constituents)>1 )  then $query-constituents[1]
	                else "cql.serverChoice"				 				
	let $searchTerm := if (count($query-constituents)=1) then
							$cql-query
						else if (count($query-constituents)=2) then (: tokenized with '=' :)
						    normalize-space($query-constituents[2])
						else
							$query-constituents[3]

(: try to get a mapping specific to given context, else take the default :)
    let $context-map := fcs:get-mapping("",$x-context, $config),

(: TODO: for every index in $xcql :)
            (: try  to get a) a mapping for given index within the context-map,
                    b) in any of the mapping (if not found in the context-map) , - potentially dangerous!!
                    c) or else take the index itself :)
        $mappings := doc(repo-utils:config-value($config, 'mappings')),   
        $index-map := $context-map/index[xs:string(@key) eq $index],
        $resolved-index := if (exists($index-map)) then $index-map/text()
                           else if (exists($mappings//index[xs:string(@key) eq $index])) then
                                $mappings//index[xs:string(@key) eq $index]
                            else $index       
            ,    
            (: get either a) the specific base-element for the index, 
                  b) the default for given map,
                  c) the index itself :)
        $base-elem := if (exists($index-map/@base_elem)) then xs:string($index-map/@base_elem) 
                        else if (exists($context-map/@base_elem)) then xs:string($context-map/@base_elem)
                        else $index,
            (: <index status="indexed"> - flag to know if ft-indexes can be used.
            TODO?: should be checked against the actual index-configuration :)
        $indexed := (xs:string($index-map/@status) eq 'indexed'),
        $match-on := if (exists($index-map/@use) ) then xs:string($index-map/@use) else '.'  
        
	let $res := if ($type eq 'scan') then
	                   concat("//", $resolved-index, if ($match-on ne '.') then concat("/", $match-on) else '') 
	               else
	                   concat("//", $resolved-index, "[", 
	                                       if ($indexed) then 
	                                               concat("ft:query(", $match-on, ",<term>",translate($searchTerm,'"',''), "</term>)")
	                                           else 
	                                               concat("contains(", $match-on, ",'", translate($searchTerm,'"',''), "')")
	                                        , "]",
								"/ancestor-or-self::", $base-elem)		
				    

	return $res

};

(:~ gets the mapping-entry for the index

first tries a mapping within given context, then tries defaults.

if $index-param = "" return the map-element, 
    else - if found - return the index-element 
:)
declare function fcs:get-mapping($index as xs:string, $x-context as xs:string+, $config) as node()* {
    let $mappings := doc(repo-utils:config-value($config, 'mappings')),
    
    $context-map := if (exists($mappings//map[xs:string(@key) = $x-context])) then 
                                $mappings//map[xs:string(@key) = $x-context]
                            else $mappings//map[xs:string(@key) = 'default'],    
    $context-index := $context-map/index[xs:string(@key) eq $index]
    
    
    return  if ($index eq '') then 
                $context-map
             else if (exists($context-index)) then 
                        $context-index
                else (: if no contextual index, dare to take any index - may be dangerous!  :)
                    let $any-index := $mappings//index[xs:string(@key) eq $index]
                    return $any-index
};


declare function fcs:indexes-in-query($cql as xs:string, $x-context as xs:string+, $config) as node()* {
    
    let $xcql := cql:cql-to-xcql($cql)
    let $indexes := for $ix in $xcql//index[not(ancestor::sortKeys)]
                        return fcs:get-mapping($ix, $x-context, $config)
                        
    return $indexes                       
    

};

(:~ evaluate given index on given piece of data
used when formatting record-data, to put selected pieces of data (indexes) into the results record 

@returns result of evaluating given index's path on given data. or empty node if no mapping index was found
:)
declare function fcs:apply-index($data, $index as xs:string, $x-context as xs:string+, $config) as item()* {

  let $index-map := fcs:get-mapping($index,$x-context, $config),
    $index-xpath := fcs:index-as-xpath($index,$x-context, $config)
(:    $match-on := if (exists($index-map/@use) ) then concat('/', xs:string($index-map[1]/@use)) else ''
, $match-on:)  
  return if (exists($index-map/path/text())) then util:eval(concat("$data//", $index-xpath ))
            else ()  
};

(:~ gets the mapping for the index and creates an xpath (UNION)

FIXME: takes just first @use-param - this prevents from creating invalid xpath, but is very unreliable wrt to the returned data
       also tried to make a union but problems with values like: 'xs:string(@value)' (union operand is not a node sequence [source: String])

@param $index index-key as known to mappings 

@returns xpath-equivalent of given index as defined in mappings; multiple xpaths are translated to a UNION, 
           value of @use-attribute is also attached;  
         if no mapping found, returns the input-index unchanged 
:)
declare function fcs:index-as-xpath($index as xs:string, $x-context as xs:string+, $config) as xs:string {    
    let $index-map := fcs:get-mapping($index, $x-context, $config )        
     return if (exists($index-map)) then
       (:                 let $match-on := if (exists($index-map/@use) ) then 
                                            if (count($index-map/@use) > 1) then  
                                               concat('/(', string-join($index-map/@use,'|'),')')
                                            else concat('/', xs:string($index-map/@use)) 
                                         else '' :)
                                  let $match-on := if (exists($index-map/@use) ) then concat('/', xs:string($index-map[1]/@use)) else ''
                                  
                        let $indexes := if (count($index-map/path) > 1) then  
                                            translate(concat('(', string-join($index-map/path,'|'),')', $match-on),'.','/')
                                            else translate(concat($index-map/path, $match-on),'.','/')
                           return $indexes
                  else $index
    
};

(:~ this is to mark matched-element, even if usual index-matching-mechanism fails (which is when matching on attributes) 
:)

declare function fcs:highlight-result($result as node()*, $match as node()*, $x-context as xs:string+, $config) as item()* {
    
    let $default-expand := util:expand($result)
    
(:    let $indexes := fcs:indexes-in-query($query, $x-context, $config):)
    
    (: if the kwic-module already did its work, just give that back, 
            else use the custom highlighting:) 
     
    (:temporarily deactivated for performance
    let $processed-result := if (exists($default-expand//exist:match)) then $default-expand
                               else fcs:process-result($result, $match):)
      let $processed-result := $default-expand                               
(:                    else  :)
                     (: "highlight-matches=elements"):)
    
    return $processed-result                               
};

(:~ this is to mark matched element, even if usual index-matching-mechanism fails (which is when matching on attributes)
it recursively processes the result 
and sets a <exist:match> element (-a-r-o-u-n-d) INSIDE the matching elements
(because it is important for the further processing to keep the matching element)
it still strips the inner elements (descendants) and only leaves the .//text() . 

@param $result the result containing the matched elements, but somewhere inside the ancestors (base-elem)
@param $matching the list of directly matched elements, that are contained in the $result somewhere

:)
declare function fcs:process-result($result as node()*, $matching as node()*) as item()* {
  for $node in $result
    return  typeswitch ($node)
        case text() return $node
        case comment() return $node
        (:case element() return  if ($node = $matching) then <exist:match>{fcs:process-result-default($node, $matching )}</exist:match>:)
                            
        case element() return  if ($node = $matching) then 
                                element {node-name($node)} {$node/@*, 
                                            <exist:match>{string-join($node//text(), ' ')}</exist:match>}
                    else  fcs:process-result-default($node, $matching )
        default return fcs:process-result-default($node, $matching )
(:namespace prefix-from-QName($node/name()) {$node/namespace-uri()} ,:)
    };

declare function fcs:process-result-default($node as node(), $matching as node()*) as item()* {
  element {node-name($node)} {($node/@*, fcs:process-result($node/node(), $matching))}
(:  namespace {$node/namespace-uri()}, :)
  (: <div class="default">{$node/name()} </div> :)  
 };

(:~ dynamically sort result based on query (CQL: sortBy clause) or default sorting defined in mappings
if unable to find any sorting index, return the result as is.
<sortKeys>
<key>
<index>dc.date</index>
<modifiers>
<modifier>
<type>sort.descending</type>
</modifier>
</modifiers>
</key>
<key>
<index>dc.title</index>
<modifiers>
<modifier>
<type>sort.ascending</type>
</modifier>
</modifiers>
</key>
</sortKeys>
:)
declare function fcs:sort-result($result as node()*, $cql as xs:string, $x-context as xs:string+, $config) as item()* {

  let $xcql := cql:cql-to-xcql($cql)
  let $indexes := if (exists($xcql//sortKeys/key/index)) then
                        $xcql//sortKeys/key/index
                      else 
                          let $context-map := fcs:get-mapping("",$x-context, $config)
                          return if (exists($context-map/@sort)) then $context-map/@sort
                                    else ()
                        
    let $xpaths := for $ix in $indexes                         
                        return fcs:index-as-xpath($ix,$x-context, $config )
                                 
   let $sorting-expression := string-join(("for $rec in $result order by ",
                                    for $index at $pos in $xpaths
                                        let $modifier := substring-after ($indexes[position()=$pos]/following-sibling::modifiers/modifier/type, 'sort.')
                                    return 
                                        ("$rec//", $index, " ", $modifier, if ($pos = count($xpaths)) then '' else ', '),
                                    " return $rec"                                      
                                    ), '')                                   
   return if (count($indexes) = 0) then $result
                else util:eval($sorting-expression)

};