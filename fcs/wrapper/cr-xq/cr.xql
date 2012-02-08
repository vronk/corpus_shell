xquery version "1.0";

(: 
 $Id: cmd-model.xql 727 2010-09-28 11:44:03Z vronk $
:)
import module namespace request="http://exist-db.org/xquery/request";
(: import module namespace json="http://www.json.org"; :)

(:import module namespace cr  = "http://aac.ac.at/content_repository" at "cr.xqm";:)
import module namespace fcs  = "http://clarin.eu/fcs/1.0" at "fcs.xqm";
import module namespace diag =  "http://www.loc.gov/zing/srw/diagnostic/" at  "modules/diagnostics/diagnostics.xqm";
import module namespace repo-utils =  "http://aac.ac.at/content_repository/utils" at  "repo-utils.xqm";

declare function local:repo() as item()* {
  let 
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
          fcs:explain($x-context)		
      else if ($operation eq $fcs:scan) then
		let $scanClause := request:get-parameter("scanClause", ""),
		$start-term := request:get-parameter("startTerm", 1),
		$max-terms := request:get-parameter("maximumTerms", 50),
		$sort := request:get-parameter("sort", 'text')
		 return fcs:scan($scanClause, $x-context, $start-term, $max-terms, $sort) 
        (: return fcs:scan($scanClause, $x-context) :)
	  else if ($operation eq $fcs:searchRetrieve) then
        if ($query eq "") then diag:diagnostics("param-missing", "query")
        else 
      	 let $cql-query := $query,
			$start-item := request:get-parameter("startRecord", 1),
			$max-items := request:get-parameter("maximumRecords", 50)	
            (: return cr:search-retrieve($cql-query, $query-collections, $format, xs:integer($start-item), xs:integer($max-items)) :)
            return fcs:search-retrieve($cql-query, $x-context, xs:integer($start-item), xs:integer($max-items))
    else 
      diag:diagnostics("unsupported-operation", $operation)
       
    return repo-utils:serialise-as($result,$x-format, $operation)

};


local:repo() 

(: 
let $context := 'clarin.at:icltt:cr:aac-naes'
fcs:explain("") 
return fcs:search-retrieve('Adler',$context,1,10)
:)
