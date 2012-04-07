module namespace cmd = "http://clarin.eu/cmd/collections";
import module namespace fcs  = "http://clarin.eu/fcs/1.0" at "xmldb:exist:///db/cr/fcs.xqm";
import module namespace repo-utils = "http://aac.ac.at/content_repository/utils" at  "xmldb:exist:///db/cr/repo-utils.xqm";

declare namespace sru = "http://www.loc.gov/zing/srw/";


(: this also needs to be set dynamically via config 
declare variable $cmd:dataPath := "/db/mdrepo-data"; (\:repo-utils:config-value('metadata.path'):\)
declare variable $cmd:base-dbcoll := collection($cmd:dataPath);
:)

declare variable $cmd:collectionRoot := "root";
declare variable $cmd:scan-collection := "cmd.collection";


declare function cmd:base-dbcoll($config) as item()* {
    collection(repo-utils:config-value($config, 'data.path'))
};

(:~
  API function getCollections. 
:)
declare function cmd:get-collections($collections as xs:string+, $format as xs:string, $max-depth as xs:integer, $config as element()) as item() {
  let $name := repo-utils:gen-cache-id("collection", $collections, xs:string($max-depth)),
    $doc := 
    if (repo-utils:is-in-cache($name, $config)) then
       repo-utils:get-from-cache($name, $config)
    else
      let $base-dbcoll := cmd:base-dbcoll($config)
      let $data := cmd:colls($collections, $max-depth, $base-dbcoll)
 	return repo-utils:store-in-cache($name, $data, $config)
  return $doc 
(:    repo-utils:serialise-as($doc, $format, 'scan'):)
        
};

(:~ collect subcollection for every collection identified by its id in the $collections-param 
:)
declare function cmd:colls($collections as xs:string+, $max-depth as xs:integer, $base-dbcoll) as element() {
		let $children := 
	  	(: loop over the list of collection-ids provided as parameter 
	  	    and run colls-r on each to recursively get all subcollections :)
	  	for $collection-item in $collections
	   		return
	   		  (: loop over sequence only for the case of root-records :) 
	   			for $collection-record in cmd:get-resource-by-handle($collection-item, $base-dbcoll) 
	     			return cmd:colls-r($collection-record, $collection-record//MdSelfLink, $max-depth, $base-dbcoll)
		let $res-count := sum($children/@cnt)
		let $coll-count := sum($children/@cnt_subcolls) + count($children) 
		let $data :=
		  <sru:scanResponse xmlns:sru="http://www.loc.gov/zing/srw/" xmlns:fcs="http://clarin.eu/fcs/1.0">
              <sru:version>1.2</sru:version>
              <sru:echoedScanRequest>                      
                      <sru:scanClause>{$cmd:scan-collection}</sru:scanClause>
                      <sru:responsePosition/>
                      <sru:maximumTerms>?</sru:maximumTerms>
                  </sru:echoedScanRequest>
              <sru:terms>
                {$children}
               </sru:terms>
           </sru:scanResponse>
(:
		      <Collections cnt="{$res-count}" cnt_subcolls="{$coll-count}" cnt_children="{count($children)}" root="{$collections}">
		          {$children}
		      </Collections>:)			
		return $data
};

(:~  Recurse down in collections-tree
:)
declare function cmd:colls-r($cmd-collection-record as node(), $cmd-collection-handle as xs:string, $depth as xs:integer, $base-dbcoll) as item()* {
  let  $children :=  if ($depth eq 1) then () else cmd:get-children-colls($cmd-collection-handle, $base-dbcoll)

  let $sub-colls :=
      if (fn:exists($children)) then
           for $child in $children
   	        return
   	            cmd:colls-r($child, $child//Header/MdSelfLink, $depth - 1, $base-dbcoll)
          else
            ()
         
   let $count-sub-records := cmd:get-sub-records-count($cmd-collection-handle, $base-dbcoll)	   
   let $count-sub-colls := cmd:get-collection-count($cmd-collection-handle, $base-dbcoll)
   let $cmd-collection-name := cmd:get-md-collection-name($cmd-collection-record)
   
   return
	      <sru:term>
            <sru:value>{$cmd-collection-handle}</sru:value>
            <sru:numberOfRecords>{$count-sub-records}</sru:numberOfRecords>
            <sru:displayTerm>{$cmd-collection-name}</sru:displayTerm>
            <sru:extraTermData>
                <fcs:numberOfChildren>{count($children)}</fcs:numberOfChildren>
                <fcs:numberOfCollections>{$count-sub-colls}</fcs:numberOfCollections>
                <sru:terms>
                    {$sub-colls}
	            </sru:terms>
	         </sru:extraTermData>
	      </sru:term>
	      (:
	           c n="{$name}" handle="{$handle}" cnt="{sum($child-results/@cnt)}" cnt_subcolls="{if ($handle eq '') then '-1' else cmd:get-collection-count($handle)}" cnt_children="{count($child-results)}" >{$child-results}</c>
     else
       <c n="{$name}" handle="{$handle}" cnt_subcolls="{if ($handle eq '') then '-1' else cmd:get-collection-count($handle)}" cnt="{if ($handle eq '') then '-1' else cmd:get-resource-count($handle)}"></c>:)
};

(:~ 
  Get the MD resource by handle (matching on MdSelfLink)
  if param empty return the root records (IsPartOf=root)
  IMPORTANT to have just the basic lucene:WhitespaceAnalyzer on MdSelfLink, so that the handles 
  are considered one token (don't get tokenized on the punctuation) 
:)
declare function cmd:get-resource-by-handle($id as xs:string, $base-dbcoll) as node()* {  
    if ($id eq "" or $id eq $cmd:collectionRoot) then
        $base-dbcoll//IsPartOf[. = $cmd:collectionRoot]/ancestor::CMD
  else     
    util:eval(concat("$base-dbcoll/ft:query(descendant::MdSelfLink, <term>", xmldb:decode($id), "</term>)/ancestor::CMD"))
 (: $collection/descendant::MdSelfLink[. = xdb:decode($id)]/ancestor::CMD :)
};

(:~
  Get the next level collection-records (ResourceType='Metadata')
  The children are actually defined in the ResourceProxyList of the parent record,
  but we rely here on the inverse IsPartOf-element (that are generated from the ResourceProxies during import/initialization)
  because it allows faster access (via lucene-index)
  :)
declare function cmd:get-children-colls($handle as xs:string, $base-dbcoll) as node()* {
        
    util:eval(concat("$base-dbcoll/ft:query(descendant::IsPartOf[@level=1], <term>", $handle, "</term>)/ancestor::CMD[descendant::ResourceType[. = 'Metadata']]"))
    
    (: collection($cmd:dataPath)/descendant::IsPartOf[. eq $handle]/ancestor::CMD[descendant::ResourceType[. = "Metadata"]] :)
};

(:~
count ALL (independent of maxDepth) records (descendants of given record)
both collection and resource records
:)
declare function cmd:get-sub-records-count($handle as xs:string, $base-dbcoll) as xs:integer {
 (: 	xs:string(count(collection($cmd:dataPath)//IsPartOf[. eq $handle]/ancestor::CMD[descendant::ResourceType[. = "Resource"] or not(exists(descendant::ResourceType)) ])):)    
	count($base-dbcoll//IsPartOf[ft:query(.,<term>{$handle}</term>)]/ancestor::CMD)
}; 

(:~ 
  count ALL (independent of maxDepth) resource-records (ie actually ResourceType=Resource, but
  there are records without ResourceProxy[ResourceType=Resource] - 
  so care for that (not(exists((ResourceType))))
:)
declare function cmd:get-resource-count($handle as xs:string, $base-dbcoll) as xs:integer {
 (: 	xs:string(count(collection($cmd:dataPath)//IsPartOf[. eq $handle]/ancestor::CMD[descendant::ResourceType[. = "Resource"] or not(exists(descendant::ResourceType)) ])):)
(:	count($cmd:base-dbcoll//IsPartOf[. eq $handle]/ancestor::CMD[not(descendant::ResourceType eq 'Metadata') ]):)
    count($base-dbcoll//IsPartOf[ft:query(.,<term>{$handle}</term>)]/ancestor::CMD[not(descendant::ResourceType eq 'Metadata') ])

}; 

(:~
  This is complement to cmd:get-resource-count()
  count ALL (independent of maxDepth) collection-records 
  (ie ResourceType=Metadata)			
:)
declare function cmd:get-collection-count($handle as xs:string, $base-dbcoll) as xs:integer {
(:	count($cmd:base-dbcoll//IsPartOf[. eq $handle]/ancestor::CMD[descendant::ResourceType[. = "Metadata"]]):)
		count($base-dbcoll//IsPartOf[ft:query(.,<term>{$handle}</term>)]/ancestor::CMD[descendant::ResourceType[. = "Metadata"]])	
};

(:~ 
  Try to derive a name from the collection-record, it tries to find one of the common fields for a name and takes first.
:)
declare function cmd:get-md-collection-name($collection-doc as node()) as xs:string {
($collection-doc//Corpus/Name, $collection-doc//Session/Name, $collection-doc//Collection/GeneralInfo/Name, $collection-doc//Collection/GeneralInfo/Title, 
    $collection-doc//Name, $collection-doc//name, $collection-doc//Title, $collection-doc//title, 
    $collection-doc//Header/MdCollectionDisplayName, "UNKNOWN")[1]
};