xquery version "1.0";
module namespace cmdcheck = "http://clarin.eu/cmd/check";
(: checking (trying to ensure) consistency of the IDs in CMD-records (MdSelfLink vs. ResourceProxies vs. IsPartOf)

TODO: check (and/or generate) the inverse links in IsPartOf (vs. ResourceProxies)
:)
   
(:import module namespace cmd  = "http://clarin.eu/cmd/collections" at "cmd-collections.xqm";:)
import module namespace repo-utils = "http://aac.ac.at/content_repository/utils" at  "/db/cr/repo-utils.xqm";
import module namespace fcs = "http://clarin.eu/fcs/1.0" at "/db/cr/fcs.xqm";
import module namespace crday  = "http://aac.ac.at/content_repository/data-ay" at "/db/cr/crday.xqm";
import module namespace diag =  "http://www.loc.gov/zing/srw/diagnostic/" at  "modules/diagnostics/diagnostics.xqm";

declare namespace sru = "http://www.loc.gov/zing/srw/";
declare namespace cmd = "http://www.clarin.eu/cmd/";

(:~ default namespace: cmd - declared statically, because dynamic ns-declaration did not work 
cmd is the default namespace in (not) all the CMD records  
:)
declare default element namespace "http://www.clarin.eu/cmd/";
(:~ default namespace - not declared explicitely, it is declared dynamically where necessary (function: addIsPartOf() :) 
declare variable $cmdcheck:default-ns := "http://www.clarin.eu/cmd/";
declare variable $cmdcheck:root-coll := "root";


(:~ runs cmd.profile-scan for all contexts defined in the mappings :)

declare function cmdcheck:run-stats($config-path as xs:string) as item()* {

       let $config := doc($config-path), 
           $mappings := doc(repo-utils:config-value($config, 'mappings'))
        
        let $opt := util:declare-option("exist:serialize", "media-type=text/html method=xhtml")

      for $map in $mappings//map[@key]
                let $map-key := $map/xs:string(@key),
                    $map-dbcoll-path := $map/xs:string(@path),
                    $scan-cmd-profile := fcs:scan('cmd.profile', $map-key, 1, 50, 1, 1, "text", $config)                                        
                return $scan-cmd-profile
};

(:~ currently not used -> DEPRECATE? 
init-function meant to call individual functions actually doing something.
at least it resolves x-context to a nodeset
:)
declare function cmdcheck:check($x-context as xs:string+, $config as node() ) as item()* {
    
    let $log-file-name := concat('log_checks_', repo-utils:sanitize-name($x-context), '.xml')
    let $log-path := repo-utils:config-value($config, 'log.path')
    
    let $start-time := util:system-dateTime()
	
    let $data-collection := repo-utils:context-to-collection($x-context, $config),        
        $stat-profiles := cmdcheck:scan-profiles($data-collection), 
(:        $check-linking := cmdcheck:check-linking($data-collection),:)
        $duration := util:system-dateTime() - $start-time    
    
    let $result-data := <checks context="{$x-context}" on="{$start-time}" duration="{$duration}" >
                    <profiles>{$stat-profiles}</profiles>
                    <check-linking>{$check-linking}</check-linking>
                  </checks>
     let $store := xmldb:store($log-path ,  $log-file-name, $result-data)                  
    return $store     
};

(:~ extracts CMD-Profiles from given nodeset

TODO: match with cmd-terms and diagnostics
:)
declare function cmdcheck:scan-profiles($context as node()*) as item()* {
      (: try- to handle namespace problem - primitively :)  
    let $ns-uri := namespace-uri($context[1]/*)  
            (: dynamically declare a namespace for the next step, if one is defined in current context 
       $dummy := if (exists($ns-uri)) then util:declare-namespace("",$ns-uri) else () :)
       (: this is now trying to overcome the default-ns issue, by accepting with and without ns :)

(:        $dummy := util:declare-namespace("",xs:anyURI(""))       :)
(:    let $profiles := util:eval("$context//(MdProfile|cmd:MdProfile)/text()"):)
(: taking :)
    let $profiles := $context//cmd:CMD/concat(cmd:Header/cmd:MdProfile/text(), '#', cmd:Components/*[1]/local-name())
    let $distinct-profiles := distinct-values($profiles)
    let $profiles-summary := for $profile in $distinct-profiles            
(:                                let $profile-name := util:eval("$context[.//(MdProfile|cmd:MdProfile)/text() = $profile][1]//(Components|cmd:Components)/*/name()"):)
                                let $profile-name := substring-after($profile, '#') 
                                let $profile-id := substring-before($profile, '#')
                                let $cnt := count($profiles[. eq $profile])
                                return <sru:term>
                                           <sru:value>{if ($profile-id ne '') then $profile-id else $profile-name}</sru:value>
                                           <sru:numberOfRecords>{$cnt }</sru:numberOfRecords>
                                           <sru:displayTerm>{$profile-name}</sru:displayTerm>
                                           { if ($profile-id eq '') then
                                                    <sru:extraTermData>
                                                        { diag:diagnostics("profile-missing", $profile-name) }
                                                    </sru:extraTermData>
                                                  else ()
                                                  }
                                         </sru:term>
    let $count-all := count($distinct-profiles)                                        
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


declare function cmdcheck:display-overview($config-path as xs:string) as item()* {

   let $config := doc($config-path),
       $dummy := util:declare-namespace("",xs:anyURI("")),
       $mappings := doc(repo-utils:config-value($config, 'mappings'))
(:       $baseurl := repo-utils:config-value($config, 'base.url'),:)
        
   let $opt := util:declare-option("exist:serialize", "media-type=text/html method=xhtml")                       

   let $overview :=  crday:display-overview($config-path, 'raw')
    
   let $profiles-overview :=  <table class="show"><tr><th>collection</th><th>profiles</th></tr>
           { for $map in util:eval("$mappings//map[@key]")
                    let $map-key := $map/xs:string(@key),
                        $map-dbcoll-path := $map/xs:string(@path),
                        $scan-cmd-profile := fcs:scan('cmd.profile', $map-key, 1, 50, 1, 1, "text", $config),   
                        $scan-formatted := repo-utils:serialise-as( $scan-cmd-profile, 'htmldetail', 'scan', $config, ())
                    return <tr>
                        <td>{$map-key}</td>
                        <td>{ $scan-formatted }</td>
                        </tr>
                        }
        </table>
            (: { for $profile in $scan-cmd-profile//sru:term 
                            return ($profile/sru:value, $profile/sru:displayTerm, $profile/sru:numberOfRecords)
                        }:)

        return repo-utils:serialise-as( <div>{($overview, $profiles-overview)}</div>, 'htmlpage', 'html', $config, ())
        
};




(:~	WARNING - CHANGES DATA! adds IsPartOf to the CMDrecords (contained in the db-coll)
- expects CMD-records for collections in specific db-coll (with name of the db-coll matching the name of the collectionfile):
    ./_corpusstructure/collection_{db-coll-name}.cmdi
- logs the progress of the processing in a separate file
- can be applied repeatedly - deletes(!) old IsPartOfList, before inserting new

@param $x-context an identifier of a collection (as defined in mappings)
@param $config config-node - used to get log.path and collection-path

TODO: could also generate the CMD-records for collections (assuming db-colls as collections) 
      (now done by the python script: dir2cmdicollection.py)
TODO: currently a hack: the collection-records also are marked as root elements - this has to be optional at least, 
      and may even be dangerous (count(IsPartOf[@level=1])>1)!
TODO: not recursive yet!
:)
declare function cmdcheck:addIsPartOf-colls($x-context as xs:string, $config as node()*) as item()* {

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
								<IsPartOf level="1">{$cmdcheck:root-coll}</IsPartOf>
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

(:~ recursive addIsPartOf 
starts by finding "orphaned" mdrecords = expecting that to be the root records.
and continues  ?
:)
declare function cmdcheck:addIsPartOf($x-context as xs:string, $config as node()*) as item()* {

let $log-file-name := concat('log_addIsPartOf_', $x-context, '.xml')
    let $log-path := repo-utils:config-value($config, 'log.path')
    let $log-doc-path := xmldb:store($log-path ,  $log-file-name, <result></result>)
    let $log-doc := doc($log-doc-path)
    
    let $root-dbcoll := repo-utils:context-to-collection($x-context, $config),
        $root-dbcoll-path := repo-utils:context-to-collection-path($x-context, $config)
    
(:    let $coll-dbcoll := '_corpusstructure':)
     
    (: beware empty path!! would return first-level collections and run over whole database :) 
    let $colls := if ($root-dbcoll-path ne "") then xmldb:get-child-collections($root-dbcoll-path) else ()
    let $start_time := fn:current-dateTime()
   
    
    let $log-dummy := update insert <edit x-context="{$x-context}" root-dbcoll="{$root-dbcoll-path}" 
                         count-colls="{count($colls)}" time="{$start_time}" /> into $log-doc/result
                        
    let $root := cmdcheck:addIsPartOf-root($root-dbcoll, $log-doc)                        
    let $updated := cmdcheck:addIsPartOf-r($root-dbcoll, $root, 1, $log-doc)
    
    return $log-doc
 };
 
 (:~ consider those, whose MdSelfLink isn't referenced anywhere (orphans) as the root-cmd-collections 
 @returns the edited records :) 
 declare function cmdcheck:addIsPartOf-root($context as node()*, $log-doc as node()*) as item()* {
 
    let $pre_time := util:system-dateTime()
 
    let $orphaned := $context//CMD[not(Header/MdSelfLink = $context//ResourceProxy[ResourceType eq 'Metadata']/ResourceRef)]

    let $update := ( update insert <edit collid="root" count="{count($orphaned)}" time="{$pre_time}" /> into $log-doc/result, 
			update delete $orphaned//IsPartOfList,
			update insert <IsPartOfList>
			                 <IsPartOf>{$cmdcheck:root-coll}</IsPartOf>					
						  </IsPartOfList>  
				into $orphaned//Resources,		
		  update value $log-doc/result/edit[last()] with (util:system-dateTime() - $pre_time)
        )
 
    return $orphaned
 
 };
 
 declare function cmdcheck:addIsPartOf-r($context as node()*, $parents as node()*, $level as xs:integer, $log-doc as node()*) as item()* {
    
    let $start_time := util:system-dateTime()
    let $log-dummy := update insert <edit level="{$level}"  
                        count-colls="{count($parents)}" time="{$start_time}" /> into $log-doc/result
    
  let $update := for $cmd-record in $parents  
                    let $parent-id := $cmd-record//MdSelfLink/text()
                    let $children := $context//CMD[Header/MdSelfLink = $cmd-record//ResourceRef]    
                	let $ispartoflist := <IsPartOfList>{($cmd-record//IsPartOfList/IsPartOf[not(text()=$cmdcheck:root-coll)],
                								<IsPartOf >{$parent-id}</IsPartOf>) }					
                						  </IsPartOfList>  
                
                    let $pre_time := util:system-dateTime()
                	let $duration := $pre_time - $start_time
                    return	( update insert <edit collid="{$parent-id}" count="{count($children)}" time="{$pre_time}" /> into $log-doc/result, 
                			update delete $children//IsPartOfList,
                			update insert $ispartoflist 
                				into $children//Resources,		
                		  update value $log-doc/result/edit[last()] with (util:system-dateTime() - $pre_time)
                        )
    
    (: go next level - we dont have to recurse in the update-loop, 
     but we can do whole next level in one call :)
    let $next-level := $context//CMD[Header/MdSelfLink = $parents//ResourceRef]
    let $updated := if (exists($next-level)) then  cmdcheck:addIsPartOf-r($context, $next-level ,($level+1),$log-doc)
                        else ()
    return $update                     
};

