module namespace cmd = "http://clarin.eu/cmd/collections";
import module namespace fcs  = "http://clarin.eu/fcs/1.0" at "xmldb:exist:///db/cr/fcs.xqm";
import module namespace repo-utils = "http://aac.ac.at/content_repository/utils" at  "xmldb:exist:///db/cr/repo-utils.xqm";

(:~
  API function getCollections. 
:)
declare function cmd:get-collections($collections as xs:string+, $format as xs:string, $max-depth as xs:integer) as item() {
  let $name := repo-utils:gen-cache-id("collection", $collections, xs:string($max-depth)),
    $doc := 
    if (repo-utils:is-in-cache($name)) then
       repo-utils:get-from-cache($name)
    else
      let $data := cmd:colls($collections, $max-depth)
 	return repo-utils:store-in-cache($name, $data)
  return 
    repo-utils:serialise-as($doc, $format,"scan")
};

(: 
  **********************
  getCollections - subfunctions
:)
declare function cmd:colls($collections as xs:string+, $max-depth as xs:integer) as element() {
		let $children := 
	  	for $collection-item in $collections
	   		return
	   			for $collection-doc in cmd:get-resource-by-handle($collection-item) 
	     			return cmd:colls-r($collection-doc, cmd:get-md-collection-name($collection-doc), $collection-doc//MdSelfLink, "", $max-depth)
		let $res-count := sum($children/@cnt)
		let $coll-count := sum($children/@cnt_subcolls) + count($children) 
		let $data := <Collections cnt="{$res-count}" cnt_subcolls="{$coll-count}" cnt_children="{count($children)}" root="{$collections}">{$children}</Collections>			
		return $data
};

(:
  Recurse down in collections.
:)
declare function cmd:colls-r($collection as node(), $name as xs:string, $handle as xs:string, $proxy-id as xs:string, $depth as xs:integer) as item()* {
  let $children :=  if ($depth eq 1) then () else cmd:get-children-colls($collection)
  (: let $dummy := util:log('debug', fn:concat(cmd:get-md-collection-name($collection), " ", $collection//MdSelfLink, " ", xs:string($depth), " CHILDREN = ", string-join(for $child in $children return $child//MdSelfLink, "#"))) :)
    return
      if (fn:exists($children)) then
	let $child-results :=
	  for $child in $children
	    (: let $child-doc := if (empty($child/unresolvable-uri)) then
		cmd:get-resource-by-handle($child/ResourceRef) else (), :)
            let $child-name := cmd:get-md-collection-name($child)
	    let $proxyid := ($collection//ResourceProxy[ResourceRef = $child//MdSelfLink]/@id, concat("UNKNOWN proxy id:", $child//MdSelfLink))[1] 
	    return
	      cmd:colls-r($child, $child-name, $child//Header/MdSelfLink, $proxyid, $depth - 1)

	  return
	  <c n="{$name}" handle="{$handle}" proxy-id="{$proxy-id}" cnt="{sum($child-results/@cnt)}" cnt_subcolls="{if ($handle eq '') then '-1' else cmd:get-collection-count($handle)}" cnt_children="{count($child-results)}" >{$child-results}</c>
      else
      	<c n="{$name}" handle="{$handle}" proxy-id="{$proxy-id}" cnt_subcolls="{if ($handle eq '') then '-1' else cmd:get-collection-count($handle)}" cnt="{if ($handle eq '') then '-1' else cmd:get-resource-count($handle)}"></c>
};

(:
  Get the MD resource by handle.
:)
declare function cmd:get-resource-by-handle($id as xs:string) as node()* {
  let $collection := collection($cmd:dataPath)
  return 
    if ($id eq "" or $id eq $cmd:collectionRoot) then
    $collection//IsPartOf[. = $cmd:collectionRoot]/ancestor::CMD
  else
    util:eval(concat("$collection/ft:query(descendant::MdSelfLink, <term>", xmldb:decode($id), "</term>)/ancestor::CMD"))
 (: $collection/descendant::MdSelfLink[. = xdb:decode($id)]/ancestor::CMD :)
};

(:
  Get the next level collection-records (ResourceType='Metadata')
  rely on the ResourceProxy of the parent (param)
:)
declare function cmd:get-children-colls($collection as node()) as node()* {
  let $handle := $collection//MdSelfLink/text(),
    $cmdi-collection := collection($cmd:dataPath)
  return util:eval(concat("$cmdi-collection/ft:query(descendant::IsPartOf, <term>", $handle, "</term>)/ancestor::CMD[descendant::ResourceType[. = 'Metadata']]"))
    (: collection($cmd:dataPath)/descendant::IsPartOf[. eq $handle]/ancestor::CMD[descendant::ResourceType[. = "Metadata"]] :)
};

(: 
  count ALL (independent of maxDepth) resource-records (ie actually ResourceType=Resource, but
  there are records without ResourceProxy[ResourceType=Resource] - 
  so care for that (not(exists((ResourceType))))
:)
declare function cmd:get-resource-count($handle as xs:string) as xs:string {
 (: 	xs:string(count(collection($cmd:dataPath)//IsPartOf[. eq $handle]/ancestor::CMD[descendant::ResourceType[. = "Resource"] or not(exists(descendant::ResourceType)) ])):)
	xs:string(count(collection($cmd:dataPath)//IsPartOf[. eq $handle]/ancestor::CMD[not(descendant::ResourceType eq 'Metadata') ]))
}; 

(:
  This is complement to cmd:get-resource-count()
  count ALL (independent of maxDepth) collection-records 
  (ie ResourceType=Metadata)			
:)
declare function cmd:get-collection-count($handle as xs:string) as xs:string {
	xs:string(count(collection($cmd:dataPath)//IsPartOf[. eq $handle]/ancestor::CMD[descendant::ResourceType[. = "Metadata"]]))
};

(: 
  Try to derive a name from the collection-record (more-or-less agnostic about 
  the actual schema.
:)
declare function cmd:get-md-collection-name($collection-doc as node()) as xs:string {
($collection-doc//Corpus/Name, $collection-doc//Session/Name, $collection-doc//Collection/GeneralInfo/Name, $collection-doc//Collection/GeneralInfo/Title, $collection-doc//Name, $collection-doc//name, $collection-doc//Title, $collection-doc//title, "UNKNOWN")[1]
};