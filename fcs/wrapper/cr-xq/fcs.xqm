xquery version "1.0";
module namespace fcs = "http://clarin.eu/fcs/1.0";

declare namespace sru = "http://www.loc.gov/zing/srw/";
import module namespace diag =  "http://www.loc.gov/zing/srw/diagnostic/" at  "modules/diagnostics/diagnostics.xqm";
import module namespace repo-utils = "http://aac.ac.at/content_repository/utils" at  "repo-utils.xqm";

declare namespace tei = "http://www.tei-c.org/ns/1.0";

declare variable $fcs:explain as xs:string := "explain";
declare variable $fcs:scan  as xs:string := "scan";
declare variable $fcs:searchRetrieve as xs:string := "searchRetrieve";

declare variable $fcs:scanSortText as xs:string := "text";
declare variable $fcs:scanSortSize as xs:string := "size";
declare variable $fcs:indexXsl := doc('index.xsl');


declare function fcs:explain($x-context as xs:string*) as item()* {
    let $context := if ($x-context) then $x-context
                    else repo-utils:config-value('explain')
   let $explain := $repo-utils:md-collection//CMD[Header/MdSelfLink/text() eq $context]//explain (: //ResourceRef/text() :)
    
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

(:
  (derived from cmd:scanIndex function)
two phases: 
    1. one create full index for given path/element (and cache)
	2. select wished subsequence (on second call, only the second step is performed)
:)
declare function fcs:scan($scan-clause  as xs:string, $x-context as xs:string+, $start-item as xs:integer, $max-items as xs:integer, $p-sort as xs:string?) as item()? {

  let $scx := tokenize($scan-clause,'='),
	 $index-name := $scx[1],  
	 $index := fcs:get-mapping($index-name, $x-context ),
	 (: if no index-mapping found, dare to use the index-name as xpath :) 
	 $index-xpath := if ($index/text()) then $index/text() else $index-name, 
 	 $filter := ($scx[2],'')[1],
	 $sort := if ($p-sort eq $fcs:scanSortText or $p-sort eq $fcs:scanSortSize) then $p-sort else $fcs:scanSortText,
	 $data-collection := repo-utils:context-to-collection($x-context)
	 
    let $index-doc-name := repo-utils:gen-cache-id("index", ($index-name, $sort),""),
  
  (: get the base-index from cache, or create and cache :)
    $index-scan := if (repo-utils:is-in-cache($index-doc-name )) then
      repo-utils:get-from-cache($index-doc-name ) 
    else        
        let $getnodes := util:eval(fn:concat("$data-collection/descendant-or-self::", $index-xpath)),
            (: to overcome problems with attributes
            this is not really reliable, but the self::text() test produced bad error, 
            so it is reversed, hoping that we will select only elements or text :) 
            $prenodes := if ($getnodes[1][self::element()]) then $getnodes
                            else for $t in $getnodes return <v>{$t}</v>
        let $nodes := <nodes path="{fn:concat('//', $index-xpath)}"  >{$prenodes}</nodes>,
        	(: use XSLT-2.0 for-each-group functionality to aggregate the values of a node - much, much faster, than XQuery :)
   	    $data := transform:transform($nodes,$fcs:indexXsl, <parameters><param name="scan-clause" value="{$scan-clause}"/></parameters>)      
        return repo-utils:store-in-cache($index-doc-name , $data)

	(: extract the required subsequence (according to given sort) :)
	let $res-nodeset := transform:transform($index-scan,$fcs:indexXsl, 
			<parameters><param name="scan-clause" value="{$scan-clause}"/>
			            <param name="mode" value="subsequence"/>
						<param name="sort" value="{$sort}"/>
						<param name="filter" value="{$filter}"/>
						<param name="start-item" value="{$start-item}"/>
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
   (:  repo-utils:serialise-as($res, $format)	 :)
};



declare function fcs:search-retrieve($query as xs:string, $x-context as xs:string*, $startRecord as xs:integer, $maximumRecords as xs:integer) as item()* {
    let $start-time := util:system-dateTime()
    let $data-collection := repo-utils:context-to-collection($x-context) 
    (:if ($x-context) then collection($repo-utils:mappings//map[xs:string(@key) eq $x-context]/@path)
                            else $repo-utils:data-collection:)
    let $xpath-query := concat("$data-collection", fcs:transform-query ($query, $x-context))
        
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
          <sru:startRecord>{$startRecord}</sru:startRecord>
          <sru:maximumRecords>{$maximumRecords}</sru:maximumRecords>
          <sru:query>{$query}</sru:query>          
          <sru:baseUrl>{repo-utils:config-value("base.url")}</sru:baseUrl> 
      </sru:echoedSearchRetrieveRequest>
      <sru:extraResponseData>
      	<fcs:returnedRecords>{$seq-count}</fcs:returnedRecords>
		<fcs:duration>{$end-time - $start-time}</fcs:duration>
		<fcs:transformedQuery>{ $xpath-query }</fcs:transformedQuery>
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
    	                         <fcs:DataView type="full">{$exp-rec}</fcs:DataView>
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



(: This expects a CQL-query that it (will be able to) translates to XPath 
returns: XPath version of the CQL-query :)
declare function fcs:transform-query($cql-query as xs:string, $x-context as xs:string) as xs:string {
    let $query-constituents := tokenize($cql-query, " ")    
	let $index := if (count($query-constituents)=1) then
				  "cql.serverChoice"
				 else 
					$query-constituents[1]				
	let $searchTerm := if (count($query-constituents)=1) then
							$cql-query
						else
							$query-constituents[3]
            (: try to get a mapping specific to given context, else take the default :)
    let $context-map := fcs:get-mapping("",$x-context),
        
            (: try  to get a) a mapping for given index within the context-map,
                    b) in any of the mapping (if not found in the context-map) , - potentially dangerous!!
                    c) or else take the index itself :)
            
        $index-map := $context-map/index[xs:string(@key) eq $index],
        $resolved-index := if (exists($index-map)) then $index-map/text()
                           else if (exists($repo-utils:mappings//index[xs:string(@key) eq $index])) then
                                $repo-utils:mappings//index[xs:string(@key) eq $index]
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
        $match-on := if (exists($index-map/@use) ) then xs:string($index-map/@use) else "."  
        
	let $res := concat("//", $resolved-index, "[", if ($indexed) then "ft:query" else "contains", "(", $match-on, ",'", $searchTerm, "')]",
								"/ancestor-or-self::", $base-elem)					

	return $res

};

(: if $index-param = "" return the map-element, 
else - if found return the index-element 
:)
declare function fcs:get-mapping($index as xs:string, $x-context as xs:string+) as node()* {
    let $context-map := if (exists($repo-utils:mappings//map[xs:string(@key) eq $x-context])) then 
                                $repo-utils:mappings//map[xs:string(@key) eq $x-context]
                            else $repo-utils:mappings//map[xs:string(@key) eq 'default']
    
    return  if ($index eq '') then 
                $context-map
             else $context-map/index[xs:string(@key) eq $index]
             
};