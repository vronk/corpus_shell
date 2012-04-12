xquery version "1.0";
module namespace cmdcheck = "http://clarin.eu/cmd/check";
(: checking (trying to ensure) consistency of the IDs in CMD-records (MdSelfLink vs. ResourceProxies vs. IsPartOf)

TODO: check (and/or generate) the inverse links in IsPartOf (vs. ResourceProxies)
:)
   
(:import module namespace cmd  = "http://clarin.eu/cmd/collections" at "cmd-collections.xqm";:)
import module namespace repo-utils = "http://aac.ac.at/content_repository/utils" at  "/db/cr/repo-utils.xqm";

declare namespace sru = "http://www.loc.gov/zing/srw/";
declare namespace cmd = "http://www.clarin.eu/cmd/";

(:~ default namespace: cmd - declared statically, because dynamic ns-declaration did not work 
cmd is the default namespace in (not) all the CMD records  
:)
(:declare default element namespace "http://www.clarin.eu/cmd/";:)
(:~ default namespace - not declared explicitely, it is declared dynamically where necessary (function: addIsPartOf() :) 
declare variable $cmdcheck:default-ns := "http://www.clarin.eu/cmd/";

(:~ init-function meant to call individual functions actually doing something.
at least it resolves x-context to a nodeset
:)
declare function cmdcheck:checks($x-context as xs:string+, $config as node() ) as item()* {
    
    let $log-file-name := concat('log_checks_', repo-utils:sanitize-name($x-context), '.xml')
    let $log-path := repo-utils:config-value($config, 'log.path')
    
    let $start-time := util:system-dateTime()
	
    let $data-collection := repo-utils:context-to-collection($x-context, $config),        
        $stat-profiles := cmdcheck:stat-profiles($data-collection), 
        $check-linking := cmdcheck:check-linking($data-collection),
        $duration := util:system-dateTime() - $start-time    
    
    let $result-data := <checks context="{$x-context}" on="{$start-time}" duration="{$duration}" >
                    <profiles>{$stat-profiles}</profiles>
                    <check-linking>{$check-linking}</check-linking>
                  </checks>
     let $store := xmldb:store($log-path ,  $log-file-name, $result-data)                  
    return $store     
};

(:~ extracts CMD-Profiles from given nodeset

TODO: profile-name deduction not reliable  - needs match with cmd-terms and diagnostics
:)
declare function cmdcheck:stat-profiles($context as node()*) as item()* {
      (: try- to handle namespace problem - primitively :)  
    let $ns-uri := namespace-uri($context[1]/*),         	           
            (: dynamically declare a namespace for the next step, if one is defined in current context 
       $dummy := if (exists($ns-uri)) then util:declare-namespace("",$ns-uri) else () :)
       (: this is now trying to overcome the default-ns issue, by accepting with and without ns :)

        $dummy := util:declare-namespace("",xs:anyURI(""))       
    let $profiles := util:eval("$context//(MdProfile|cmd:MdProfile)/text()")
    let $distinct-profiles := distinct-values($profiles)
    let $profiles-summary := for $profile in $distinct-profiles            
                                let $profile-name := util:eval("$context[.//(MdProfile|cmd:MdProfile)/text() = $profile][1]//(Components|cmd:Components)/*/name()")
                                let $cnt := count($profiles[. eq $profile])
                                return <sru:term>
                                           <sru:value>{$profile}</sru:value>
                                           <sru:numberOfRecords>{$cnt }</sru:numberOfRecords>
                                           <sru:displayTerm>{$profile-name}</sru:displayTerm>                                      
                                         </sru:term>
    let $count-all := count($context)                                        
    return
        <sru:scanResponse xmlns:sru="http://www.loc.gov/zing/srw/" xmlns:fcs="http://clarin.eu/fcs/1.0">
              <sru:version>1.2</sru:version>              
              <sru:terms>              
                {$profiles-summary }
               </sru:terms>
               <sru:extraResponseData>
                     <fcs:countTerms>{$count-all}</fcs:countTerms>
                 </sru:extraResponseData>
                 <sru:echoedScanRequest>                      
                      <sru:scanClause>cmd.profile</sru:scanClause>
                  </sru:echoedScanRequest>
           </sru:scanResponse>    
};

(:~ checking consistency of the IDs in CMD-records (MdSelfLink vs. ResourceProxies)

this is now solved better (faster) with xpaths in the cmd-testset, 
so this is probably obsolete.
it has very bad performance!

TODO: check (and/or generate) the inverse links in IsPartOf (vs. ResourceProxies) :)
declare function cmdcheck:check-linking($context as node()*) as item()* {

let $mdselflinks := $context//MdSelfLink
let $resourceproxies := $context//ResourceProxy
let $resourceproxies-md := $resourceproxies[ResourceType eq 'Metadata']/ResourceRef
(: )let $diff :=  $resourceproxies-md[not(index-of($mdselflinks, self::*))] 
let $diff2 :=  $mdselflinks[not($resourceproxies-md = text())]:)
let $diff := for $resource-proxy in $resourceproxies-md
                    let $id := xs:string($resource-proxy/text())
                return if ($mdselflinks[ft:query(.,<term>{$id}</term>)]) then () (: $mdselflinks[ft:query(.,<term>{$id}</term>)] :)
                 else <doc n="{util:document-name($resource-proxy)}" >{$resource-proxy}</doc>

let $diff2 := for $mdselflink in $mdselflinks
                    let $id := xs:string($mdselflink/text())
                return if ($resourceproxies-md[ft:query(.,<term>{$id}</term>)]) then () (: $mdselflinks[ft:query(.,<term>{$id}</term>)] :)
                 else <doc n="{util:document-name($mdselflink)}" >{$mdselflink}</doc>
return ($diff,$diff2)
};



declare function cmdcheck:query-internal($queries, $context as node()+, $result-path as xs:string, $result-filename as xs:string ) as item()* {
    
    (: collect the xpaths from the before fiddling with the namespace :)
    let $xpaths := $queries//xpath
    (:    let $context := repo-utils:context-to-collection($x-context, $config)       
	   $context:= collection("/db/mdrepo-data/cmdi-providers"),	   :)

    let $result-store := xmldb:store($result-path ,  $result-filename, <result test="{$queries//test/xs:string(@id)}" ></result>),
        $result-doc:= doc($result-store)

    let $ns-uri := namespace-uri($context[1]/*)        	           
      (: dynamically declare a default namespace for the xpath-evaluation, if one is defined in current context 
      WATCHME: this is not very reliable, mainly meant to handle default-ns: cmd :)
(:      $dummy := if (exists($ns-uri)) then util:declare-namespace("",$ns-uri) else () :)
    let $dummy := util:declare-namespace("",xs:anyURI($ns-uri))    


    let $start-time := util:system-dateTime()	
    let $upd-dummy :=  
        for $xpath in $xpaths            
            let $start-time := util:system-dateTime()
            let $answer := util:eval($xpath/text())
            let $duration := util:system-dateTime() - $start-time
           return update insert <xpath key="{$xpath/@key}" label="{$xpath/@label}" dur="{$duration}">{$answer}</xpath> into $result-doc/result

    return $result-doc

};


(:~	WARNING - CHANGES DATA! adds IsPartOf to the CMDrecords (contained in the db-coll)
- expects CMD-records for collections in specific db-coll (with name of the db-coll matching the name of the collectionfile):
    ./_corpusstructure/collection_{db-coll-name}.cmdi
- logs the progress of the processing in a separate file
- can be applied repeatedly - deletes(!) old IsPartOfList, before inserting new

@param $x-context an identifier of a collection (as defined in mappings)

TODO: could also generate the CMD-records for collections (assuming db-colls as collections) 
      (now done by the python script: dir2cmdicollection.py)
TODO: currently a hack: the collection-records also are marked as root elements - this has to be optional at least, 
      and may even be dangerous (count(IsPartOf[@level=1])>1)!
TODO: not recursive yet!
:)
declare function cmdcheck:addIsPartOf($x-context as xs:string, $config as node()*) as item()* {

let $log-file-name := concat('log_addIsPartOf_', $x-context, '.xml')
    let $log-path := repo-utils:config-value($config, 'log.path')
    let $log-doc-path := xmldb:store($log-path ,  $log-file-name, <result></result>)
    let $log-doc := doc($log-doc-path)
    
    (:let $root-dbcoll := repo-utils:context-to-collection($x-context, $config),:)
    let $root-dbcoll-path := repo-utils:context-to-collection-path($x-context, $config)
    
    let $coll-dbcoll := '_corpusstructure'
     
    (: beware empty path!! would return first-level collections and run over whole database :) 
    let $colls := if ($root-dbcoll-path ne "") then xmldb:get-child-collections($root-dbcoll-path) else ()
    let $start_time := fn:current-dateTime()
    
    (: dynamic ns-declaration does not work for xpath 
    let $declare-dummy := util:declare-namespace("",xs:anyURI($cmdcheck:default-ns))
    :)
    let $log-dummy := update insert <edit x-context="{$x-context}" root-dbcoll="{$root-dbcoll-path}" 
                        coll-dbcoll="{$coll-dbcoll}" count-colls="{count($colls)}" time="{$start_time}" /> into $log-doc/result
    (:if (exists($colls)) then:)
    for $coll_name in $colls[not(.=$coll-dbcoll)]
    (: let $coll_name := 'HomeFamilyManagement' :)
    let $files := collection(concat($root-dbcoll-path,$coll_name))
    (: let $files := xmldb:xcollection($root_coll) :)	
	let $coll_file := concat($root-dbcoll-path, $coll-dbcoll, '/collection_', $coll_name, '.cmdi')
	let $coll_doc := doc($coll_file)
	let $coll_id := $coll_doc//MdSelfLink/text()

(:	let $cmdi_files := $files[ends-with(util:document-name(.),".cmdi")]:)

    let $pre_time := util:system-dateTime()
	let $duration := $pre_time - $start_time
 return	( update insert <edit coll="{$coll_name}" collid="{$coll_id}" coll_file="{$coll_file}" count="{count($files)}" time="{$pre_time}" /> into $log-doc/result, 
			update delete $files//IsPartOfList,
			update delete $coll_doc//IsPartOfList,
			update insert <IsPartOfList>
								<IsPartOf level="1">{$x-context}</IsPartOf>
								<IsPartOf level="1">root</IsPartOf>
						  </IsPartOfList>
			  	into $coll_doc//Resources,
			update insert <IsPartOfList>
							<IsPartOf level="2">{$x-context}</IsPartOf>
							<IsPartOf level="1">{$coll_id}</IsPartOf>
						  </IsPartOfList> 
				into $files//Resources,
		update value $log-doc/result/edit[last()] with (util:system-dateTime() - $pre_time)
        )
    (:
    return	($coll_name, count($cmdi_files), $coll_file,  update insert <IsPartOfList>
							<IsPartOf level="1">{$coll_id}</IsPartOf>
						  </IsPartOfList> into $cmdi_files//Resources ):)
};

