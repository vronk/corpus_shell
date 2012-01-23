xquery version "1.0";

(: 
 $Id: cmd-model.xql 727 2010-09-28 11:44:03Z vronk $
:)
import module namespace request="http://exist-db.org/xquery/request";
(: import module namespace json="http://www.json.org"; :)

import module namespace cr  = "http://aac.ac.at/content_repository"
at "xmldb:exist:///db/content_repository/scripts/cr.xqm";
import module namespace diag =  "http://www.loc.gov/zing/srw/diagnostic/" at  "modules/diagnostics/diagnostics.xqm";
import module namespace repo-utils =  "http://aac.ac.at/content_repository/utils" at  "repo-utils.xqm";

declare function local:repo() as item()* {
  let $operation :=  request:get-parameter("operation", $cr:searchRetrieve),
    $q := request:get-parameter("q", ""),
    $query := request:get-parameter("query", $q),    
    $format := request:get-parameter("format", $repo-utils:responseFormatXml),
    $collection-params := request:get-parameter("collection", $cr:collectionRoot),
    $query-collections := 
    if (matches($collection-params, "^root$") or $collection-params eq "") then 
      $cr:collectionRoot
    else
		tokenize($collection-params,','),
(:      $collection-params, :)
    $max-depth as xs:integer := xs:integer(request:get-parameter("maxdepth", 1))
    return
      (: if ($operation eq $cr:getCollections) then
		cr:get-collections($query-collections, $format, $max-depth)
      else :) 
      if ($operation eq $cr:queryModel) then
		cr:query-model($query, $query-collections, $format, $max-depth)
      else if ($operation eq $cr:scanIndex) then
		let $filter := request:get-parameter("filter", ""),
		$start-item := request:get-parameter("startItem", 1),
		$max-items := request:get-parameter("maxItems", 50),
		$sort := request:get-parameter("sort", 'text')
		return cr:scan-index($query, $query-collections, $format, $start-item, $max-items, $sort)
	  else if ($operation eq $cr:searchRetrieve) then
        if ($query eq "") then diag:diagnostics("param-missing", "query")
        else 
      	 let $cql-query := $query,
			$start-item := request:get-parameter("startItem", 1),
			$max-items := request:get-parameter("maxItems", 50)	
            return cr:search-retrieve($cql-query, $query-collections, $format, xs:integer($start-item), xs:integer($max-items))
    else 
      diag:diagnostics("unsupported-operation", $operation)

};

local:repo()
