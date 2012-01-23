xquery version "1.0";
module namespace fcs = "http://clarin.eu/fcs/1.0";

declare namespace sru = "http://www.loc.gov/zing/srw/";
import module namespace diag =  "http://www.loc.gov/zing/srw/diagnostic/" at  "modules/diagnostics/diagnostics.xqm";
import module namespace repo-utils = "http://aac.ac.at/content_repository/utils" at  "repo-utils.xqm";

declare namespace tei = "http://www.tei-c.org/ns/1.0";

declare variable $fcs:explain as xs:string := "explain";
declare variable $fcs:scan  as xs:string := "scan";
declare variable $fcs:searchRetrieve as xs:string := "searchRetrieve";


declare function fcs:explain($x-context as xs:string*) as item()* {
    let $context := if ($x-context) then $x-context
                    else repo-utils:config-value('explain')
   let $explain := $repo-utils:md-collection//CMD[Header/MdSelfLink/text() eq $context]//explain (: //ResourceRef/text() :)
    
    return $explain
};

(:
TODO?: only read explicit indexes + create index on demand.
:)
declare function fcs:scan($scanClause as xs:string, $x-context as xs:string*) {
    
    let $clause-tokens := tokenize($scanClause,'='),
        $index := $clause-tokens[1],
        $term := $clause-tokens[2],
        (:$map-index := $repo-utils:mappings/map/index[@key=$index], :)
        $index-file := concat(repo-utils:config-value('index.prefix'),$index,'.xml'),
        $result := doc($index-file)
    
    return $result  
    
    
};


declare function fcs:search-retrieve($query as xs:string, $x-context as xs:string*, $startRecord as xs:integer, $maximumRecords as xs:integer) as item()* {
    let $data-collection := if ($x-context) then collection($repo-utils:mappings//map[xs:string(@key) eq $x-context]/@path)
                            else $repo-utils:data-collection
    let $xpath-query := concat("$data-collection", fcs:transform-query ($query, $x-context))
    let $result := util:eval($xpath-query)
    return <result>{$result}</result>
                    
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
    let $context-map := if (exists($repo-utils:mappings//map[xs:string(@key) eq $x-context])) then 
                                $repo-utils:mappings//map[xs:string(@key) eq $x-context]
                            else $repo-utils:mappings//map[xs:string(@key) eq 'default'],
        
            (: try to get a mapping for given index, or else take the index itself :)
        $index-map := $context-map/index[xs:string(@key) eq $index],
        $resolved-index := if (exists($index-map)) then $index-map/text()
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
        $indexed := (xs:string($index-map/@status) eq 'indexed') 
        
	let $res := concat("//", $resolved-index, "[", if ($indexed) then "ft:query" else "contains", "(.,'", $searchTerm, "')]",
								"/ancestor-or-self::", $base-elem)					

	return $res

};
