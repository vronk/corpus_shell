xquery version "1.0";

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

declare namespace sru = "http://www.loc.gov/zing/srw/";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
import module namespace request="http://exist-db.org/xquery/request";
import module namespace diag =  "http://www.loc.gov/zing/srw/diagnostic/" at  "modules/diagnostics/diagnostics.xqm";
import module namespace repo-utils = "http://aac.ac.at/content_repository/utils" at  "repo-utils.xqm";
import module namespace kwic = "http://exist-db.org/xquery/kwic";
import module namespace cmd = "http://clarin.eu/cmd/collections" at  "/db/cr/modules/cmd/cmd-collections.xqm";
import module namespace cql = "http://exist-db.org/xquery/cql" at "/db/cr/modules/cqlparser/cqlparser.xqm";


declare variable $fcs:explain as xs:string := "explain";
declare variable $fcs:scan  as xs:string := "scan";
declare variable $fcs:searchRetrieve as xs:string := "searchRetrieve";

declare variable $fcs:scanSortText as xs:string := "text";
declare variable $fcs:scanSortSize as xs:string := "size";
declare variable $fcs:indexXsl := doc('index.xsl');
declare variable $fcs:kwicWidth := 80;

(:~ The main entry-point. Processes request-parameters 
@returns the result document (in xml, html or json)
:)
declare function fcs:repo($config-file as xs:string) as item()* {
  let
    $config := if (doc-available($config-file)) then doc($config-file) 
                        else diag:diagnostics("general-error", concat("config not available: ", $config-file)) ,
        
        (: accept "q" as synonym to query-param; "query" overrides:)
    $q := request:get-parameter("q", ""),
    $query := request:get-parameter("query", $q),    
        (: if query-parameter not present, 'explain' as DEFAULT operation, otherwise 'searchRetrieve' :)
    $operation :=  if ($query eq "") then request:get-parameter("operation", $fcs:explain)
                    else request:get-parameter("operation", $fcs:searchRetrieve),
    $x-format := request:get-parameter("x-format", $repo-utils:responseFormatXml),
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
		let $scanClause := request:get-parameter("scanClause", ""),
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
			$x-dataview := request:get-parameter("x-dataview", 'kwic')
            (: return cr:search-retrieve($cql-query, $query-collections, $format, xs:integer($start-item), xs:integer($max-items)) :)
            return fcs:search-retrieve($cql-query, $x-context, xs:integer($start-item), xs:integer($max-items), $x-dataview, $config)
    else 
      diag:diagnostics("unsupported-operation", $operation)
       
   return  repo-utils:serialise-as($result, $x-format, $operation, $config)
   
};


(:~ handles the explain-operation requests.
: @param $x-context optional, identifies a resource to return the explain-record for. (Accepts both MD-PID or Res-PID (MdSelfLink or ResourceRef/text))
: @returns either the default root explain-record, or - when provided with the $x-context parameter - the explain-record of given resource
:)
declare function fcs:explain($x-context as xs:string*, $config) as item()* {
    let $context := if ($x-context) then $x-context
                    else repo-utils:config-value($config, 'explain')
    let $md-dbcoll := collection(repo-utils:config-value($config,'metadata.path'))
   let $explain := $md-dbcoll//CMD[Header/MdSelfLink/text() eq $context or .//ResourceRef/text() eq $context]//explain (: //ResourceRef/text() :)
    
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
	 let $short-xcontext := substring-after($x-context, concat(repo-utils:config-value($config, 'explain'),':')) 
    let $index-doc-name := repo-utils:gen-cache-id("index", ($short-xcontext, $index-name, $sort, $max-depth),""),
  
  (: get the base-index from cache, or create and cache :)
  $index-scan := if (repo-utils:is-in-cache($index-doc-name, $config)) then
          repo-utils:get-from-cache($index-doc-name, $config) 
        else
            let $data :=
                if ($index-name eq $cmd:scan-collection) then                        
                    cmd:colls($filter, $max-depth, cmd:base-dbcoll($config)) 
                else
                    fcs:do-scan-default($scan-clause, $index-xpath, $x-context, $config)         

        return repo-utils:store-in-cache($index-doc-name , $data, $config)

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


declare function fcs:do-scan-default($scan-clause as xs:string, $index-xpath as xs:string, $x-context as xs:string, $config) as item()* {
  (:        let $getnodes := util:eval(fn:concat("$data-collection/descendant-or-self::", $index-xpath)),:)
    let $data-collection := repo-utils:context-to-collection($x-context, $config)
        let $getnodes := util:eval(fn:concat("$data-collection//", $index-xpath)),
            (: if we collected strings, we have to wrap them in elements 
                    to be able to work with them in xsl :) 
            $prenodes := if ($getnodes[1] instance of xs:string) then
                                    for $t in $getnodes return <v>{$t}</v>
                            else for $t in $getnodes return <v>{string-join($t//text()," ")}</v>
        let $nodes := <nodes path="{fn:concat('//', $index-xpath)}"  >{$prenodes}</nodes>,
        	(: use XSLT-2.0 for-each-group functionality to aggregate the values of a node - much, much faster, than XQuery :)
   	    $data := transform:transform($nodes,$fcs:indexXsl, <parameters><param name="scan-clause" value="{$scan-clause}"/></parameters>)
   	    
   	  return $data
};

(:~ main search function (handles the searchRetrieve-operation request) 
:)
declare function fcs:search-retrieve($query as xs:string, $x-context as xs:string*, $startRecord as xs:integer, $maximumRecords as xs:integer, $x-dataview as xs:string*, $config) as item()* {
    let $start-time := util:system-dateTime()
    let $data-collection := repo-utils:context-to-collection($x-context, $config) 
    (:if ($x-context) then collection($repo-utils:mappings//map[xs:string(@key) eq $x-context]/@path)
                            else $repo-utils:data-collection:)
    let $xpath-query := concat("$data-collection", fcs:transform-query ($query, $x-context, $config))
        
    let $results := util:eval($xpath-query)

    let	$result-count := fn:count($results),
    $result-seq := fn:subsequence($results, $startRecord, $maximumRecords),
    $seq-count := fn:count($result-seq),
    $end-time := util:system-dateTime(),
    
    (:<sru:recordSchema>mods</sru:recordSchema>:)          
          (:<xQuery><searchClause xmlns="http://www.loc.gov/zing/cql/xcql/">
          <index>dc.title</index>
          <relation>
          <value>=</value>
          </relation>
          <term>dinosaur</term>
          </searchClause> 
          </xQuery>:)
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
		<fcs:duration>{$end-time - $start-time}</fcs:duration>
		<fcs:transformedQuery>{ $xpath-query }</fcs:transformedQuery>
      </sru:extraResponseData>
      <sru:records>
	       {for $rec at $pos in $result-seq
	           let $exp-rec := util:expand($rec, "expand-xincludes=no") (: kwic:summarize($rec,<config width="40"/>) :)
	           let $kwic-config := <config width="{$fcs:kwicWidth}"/>
	           let $kwic-html := kwic:summarize($exp-rec, $kwic-config)
	           
	           (: a basic diry solution to the data-view parameterization 
	           now it only checks if kwic and/or full, but 
	               TODO: the configuration of data-view should be outsourced to configuration:)	           
	           let $kwic := if ('kwic' = $x-dataview) then
	                               <fcs:DataView type="kwic">{
	                                       for $match in $kwic-html 
	                                       return (<fcs:c type="left">{$match/span[1]/text()}</fcs:c>, 
            	           (: <c type="left">{kwic:truncate-previous($exp-rec, $matches[1], (), 10, (), ())}</c> :)
            	                          <fcs:kw>{$match/span[2]/text()}</fcs:kw>,
            	                          <fcs:c type="right">{$match/span[3]/text()}</fcs:c>)            	                       
                           (: let $summary  := kwic:get-summary($exp-rec, $matches[1], $config) :)
            (:	                               <fcs:DataView type="kwic-html">{$kwic-html}</fcs:DataView>:)
                                }</fcs:DataView>
                              else ()
                
	           return 
	               <sru:record>
	                   <sru:recordSchema>http://clarin.eu/fcs/1.0/Resource.xsd</sru:recordSchema>
	                   <sru:recordPacking>xml</sru:recordPacking>
	                   <sru:recordData>	                       
	                       <fcs:Resource>
	                           <fcs:ResourceFragment>
	                             {($kwic,
    	                         if ('full' = $x-dataview) then <fcs:DataView type="full">{$exp-rec}</fcs:DataView>
        	                         else ()
        	                         )}
    	                       </fcs:ResourceFragment>
	                       </fcs:Resource>
	                   </sru:recordData>
	                   <sru:recordPosition>{$pos}</sru:recordPosition>
	                   <sru:recordIdentifier>{$rec/@xml:id}</sru:recordIdentifier>
	                </sru:record>
	       }
      </sru:records>
    </sru:searchRetrieveResponse>

    return $result
                    
};


(:~ This expects a CQL-query that it translates to XPath

It relies on the external cqlparser-module, that delivers the query in XCQL-format (parse-tree of the query as XML)
and then applies a stylesheet

@params $x-context identifier of a resource/collection
@returns XPath version of the CQL-query 
:)
declare function fcs:transform-query($cql-query as xs:string, $x-context as xs:string, $config) as xs:string {
    let $mappings := repo-utils:config-value($config, 'mappings')
    return cql:cql2xpath ($cql-query, $x-context, $mappings)
    
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
    
    $context-map := if (exists($mappings//map[xs:string(@key) eq $x-context])) then 
                                $mappings//map[xs:string(@key) eq $x-context]
                            else $mappings//map[xs:string(@key) eq 'default']
    
    return  if ($index eq '') then 
                $context-map
             else $context-map/index[xs:string(@key) eq $index]
             
};

(:~ gets the mapping for the index and creates an xpath (UNION)

@param $index index-key as known to mappings 

@returns xpath-equivalent of given index as defined in mappings; multiple xpaths are translated to a UNION; 
         if no mapping found, returns the input-index unchanged 
:)
declare function fcs:index-as-xpath($index as xs:string, $x-context as xs:string+, $config) as xs:string {    
    let $index-map := fcs:get-mapping($index, $x-context, $config )      
     return if (exists($index-map)) then translate(concat('(', string-join($index-map/path,'|'),')'),'.','/')
                    else $index
};
