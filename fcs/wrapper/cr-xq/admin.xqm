xquery version "1.0";
(:~ overview/admin module for cr-xq
:)
module namespace cr-admin = "http://aac.ac.at/content_repository/admin";

import module namespace repo-utils = "http://aac.ac.at/content_repository/utils" at  "/db/cr/repo-utils.xqm";
import module namespace crday = "http://aac.ac.at/content_repository/data-ay" at  "/db/cr/crday.xqm";
import module namespace fcs = "http://clarin.eu/fcs/1.0" at "/db/cr/fcs.xqm";

declare function cr-admin:display-overview($config-path as xs:string) as item()* {

       let $config := doc($config-path), 
           $mappings := doc(repo-utils:config-value($config, 'mappings'))
        
        let $opt := util:declare-option("exist:serialize", "media-type=text/html method=xhtml")
        
(:    {for $target in $config//target return <th>{xs:string($target/@key)}</th>}</tr>:)
let $overview :=  <table><tr><th>collection</th><th>path</th><th>size</th><th>ns</th><th>root-elem</th><th>base-elem</th><th>indexes</th><th>tests</th></tr>
           { for $map in $mappings//map[@key]
                    let $map-key := $map/xs:string(@key),
                        $map-dbcoll-path := $map/xs:string(@path),
(:                        $map-dbcoll:= if ($map-dbcoll-path ne '' and xmldb:collection-available (($map-dbcoll-path,"")[1])) then collection($map-dbcoll-path) else (),                      :)
                          $map-dbcoll:= repo-utils:context-to-collection($map-key, $config),
                        $root-elems := for $elem in distinct-values($map-dbcoll/*/name()) return $elem,
                        $ns-uris := for $ns in distinct-values($map-dbcoll/namespace-uri(*)) return $ns,
                        $queries-doc-name := cr-admin:check-queries-doc-name($config, $map-key),
                        $invoke-check-queries-href := concat('?x-context=', repo-utils:sanitize-name($map-key) ,'&amp;config=', $config-path, '&amp;operation=' ),
                        $queries := if (repo-utils:is-in-cache($queries-doc-name, $config)) then 
                                                <a href="{concat($invoke-check-queries-href,'view')}" >view</a>                                             
                                              else ()  
                    return <tr>
                        <td>{$map-key}</td>
                        <td>{$map-dbcoll-path}</td>
                        <td>{count($map-dbcoll)}</td>
                        <td>{$ns-uris}</td>
                        <td>{$root-elems}</td>
                        <td>{$map/xs:string(@base_elem)}</td>
                        <td>{count($map/index)}</td>                        
                        <td>{$queries} [<a href="{concat($invoke-check-queries-href,'run')}" >run</a>]</td>
                        </tr>
                        }
        </table>
                        (:{for $target in $fcs-tests:config//target
                           let $target-key := $target/xs:string(@key)
                           let $test-result := fcs-tests:get-result($target-key , $testset-key )                           
                           let $root-elem := $test-result/*/name()
                           let $op := if ($test-result//diagnostic["result-unavailable" = xs:string(@key)]) then 'run' else 'view'
                           (\: display number of all and failed tests in the testset, operates on the HTML produced during the test-run :\)
                           let $view:= if ($test-result//diagnostic["result-unavailable" = xs:string(@key)]) then ()
                                       else  
                                            let $show := if ($root-elem[1] eq 'testrun') then 
                                                            <span><span class="test-passed">{count($test-result//div[@class='test'][.//span[@class='value true']])}</span>{"/"}
                                                                   <span class="test-failed">{count($test-result//div[@class='test'][.//span[@class='value false']])}</span>{"/"}                                                                   
                                                                {count($test-result//div[@class='test'])}
                                                                {if (exists($test-result//diagnostics)) then <span class="test-failed">!!</span> else () }
                                                              </span>
                                                            else $root-elem 
                                            return <a href="?target={$target-key}&amp;testset={$testset-key}&amp;operation=view" >{$show}</a> 
                                    
                        return <td align="center">{$view} [<a href="?target={$target-key}&amp;testset={$testset-key}&amp;operation=run" >run</a>]</td>
                        }:)                    
          
       return repo-utils:serialise-as($overview, 'htmlpage', 'html', $config, ())
};


(: actually: run or view (if available) 
calls: 
crday:query-internal($queries, $context as node()+, $result-path as xs:string, $result-filename as xs:string ) as item()* {
:)
declare function cr-admin:run-check-queries($config as node(), $x-context as xs:string, $run-flag as xs:boolean) as item()* {

    let $testset := doc(repo-utils:config-value($config, 'tests.path')),
    
        $cache-path := repo-utils:config-value($config, 'cache.path'),             
        $queries-doc-name := cr-admin:check-queries-doc-name($config, $x-context), 
  
  (: get the the results from cache, or create :)
  $result := if (exists($testset)) then 
                if (repo-utils:is-in-cache($queries-doc-name, $config) and not($run-flag)) then
                    repo-utils:get-from-cache($queries-doc-name, $config) 
                  else                    
                    let $context := repo-utils:context-to-collection($x-context, $config)
                    return crday:query-internal($testset, $context, $x-context, $cache-path, $queries-doc-name)
                    (: no need to store, because already continuously stored during querying  
                    return repo-utils:store-in-cache($index-doc-name , $data, $config) :)
               else
                <diagnostics>no testset available</diagnostics>
                
    
  return repo-utils:serialise-as($result, 'htmlpage', 'table', $config, ())
(:  return $result:)
  
    
};

(:~ return doc-name out of context and testset (from config) or empty string if testset does not exist :)
declare function cr-admin:check-queries-doc-name($config as node(), $x-context as xs:string) as xs:string {
let $testset := doc(repo-utils:config-value($config, 'tests.path')),
    $testset-name := if (exists($testset)) then util:document-name($testset) else (),
    $sanitized-xcontext := repo-utils:sanitize-name($x-context)  
 return if (exists($testset)) then repo-utils:gen-cache-id("queries", ($sanitized-xcontext, $testset-name),"") else ""
 
};