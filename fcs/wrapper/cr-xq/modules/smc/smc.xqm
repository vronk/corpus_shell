xquery version "1.0";
module namespace smc = "http://clarin.eu/smc";

import module namespace repo-utils = "http://aac.ac.at/content_repository/utils" at  "xmldb:exist:///db/cr/repo-utils.xqm";
import module namespace crday  = "http://aac.ac.at/content_repository/data-ay" at "/db/cr/crday.xqm";
import module namespace fcs = "http://clarin.eu/fcs/1.0" at "/db/cr/fcs.xqm";

declare namespace sru = "http://www.loc.gov/zing/srw/";

declare variable $smc:termsets := doc("data/termsets.xml");
declare variable $smc:dcr-terms := doc("data/dcr-terms.xml");
declare variable $smc:cmd-terms := doc("data/cmd-terms.xml");

(:~ mappings overview
only process already created maps (i.e. (for now) don't run mappings on demand, 
because that would induce ay-xml - which takes very long time and is not safe 
:)
declare function smc:mappings-overview($config, $format as xs:string) as item()* {

let $cache_path := repo-utils:config-value($config, 'cache.path'),
    $mappings := collection($cache_path)/map[*]
    


let $overview := if (contains($format, "table")) then
                       <table class="show"><tr><th>index</th>
                         {for $map in $mappings return <th>{concat($map/@profile-name, ' ', $map/@context)}</th> } 
                         </tr>                    
                        { for $ix in distinct-values($mappings//index/xs:string(@key))
                             let $datcat := $smc:dcr-terms//Concept[Term[@type='id']/concat(@set,':',text()) = $ix],
                                  $datcat-label := $datcat/Term[@type='mnemonic'],
                                 $datcat-type := $datcat/@datcat-type
                             return <tr><td valign="top">{(<b>{$datcat-label}</b>, <br/>, concat($ix, ' ', $datcat-type))}</td>
                                        {for $map in $mappings
                                                 let $paths := $map/index[xs:string(@key)=$ix]/path
                                        return <td valign="top"><ul>{for $path in $paths
                                                            return <li>{$path/text()}</li>
                                                         }</ul></td> 
                                         }
                                      </tr>
                           }
                        </table>
                    else 
                       <ul>                  
                        { for $ix in distinct-values($mappings//index/xs:string(@key))
                             let $datcat := $smc:dcr-terms//Concept[Term[@type='id']/concat(@set,':',text()) = $ix],
                                  $datcat-label := $datcat/Term[@type='mnemonic'],
                                 $datcat-type := $datcat/@datcat-type
                             return <li><span>{(<b>{$datcat-label}</b>, <br/>, concat($ix, ' ', $datcat-type))}</span>
                                        {for $map in $mappings
                                                 let $paths := $map/index[xs:string(@key)=$ix]/path
                                        return <td valign="top"><ul>{for $path in $paths
                                                            return <li>{$path/text()}</li>
                                                         }</ul></td> 
                                         }
                                      </li>
                           }
                        </ul> 
                    
       return if ($format eq 'raw') then
                   $overview
                else            
                   repo-utils:serialise-as($overview, $format, 'html', $config, ())                   
};

(:~ create and store mapping for every profile in given nodeset 
expects the CMD-format

@param format [raw, htmlpage, html] - raw: return only the produced table, html* : serialize as html
:)
declare function smc:get-mappings($config, $x-context as xs:string+, $run-flag as xs:boolean, $format as xs:string) as item()* {

let $scan-profiles :=  fcs:scan('cmd.profile', $x-context, 1, 50, 1, 1, "text", $config),
    $target_path := repo-utils:config-value($config, 'cache.path')

(: for every profile in the data-set :)
let $result := for $profile in $scan-profiles//sru:term
                    let $profile-name := xs:string($profile/sru:displayTerm)    
                    let $map-doc-name := repo-utils:gen-cache-id("map", ($x-context, $profile-name), '')
                    
                    return 
                        if (repo-utils:is-in-cache($map-doc-name, $config) and not($run-flag)) then 
                            repo-utils:get-from-cache($map-doc-name, $config)
                        else
                            let $ay-data := crday:get-ay-xml($config, $x-context, $profile-name, $crday:defaultMaxDepth, false(), 'raw')    
                            let $mappings := <map profile-id="{$profile/sru:value}" profile-name="{$profile-name}" context="{$x-context}"> 
                                                {smc:match-paths($ay-data, $profile)}
                                               </map>
                            return repo-utils:store-in-cache($map-doc-name, $mappings, $config)
    
   return if ($format eq 'raw') then
                   <map context="{$x-context}" >{$result}</map>
                else            
                   repo-utils:serialise-as(<map context="{$x-context}" >{$result}</map>, $format, 'default', $config, ())  
};

(:~ expects a summary of data, matches the resulting paths with paths in cmd-terms
and returns dcr-indexes, that have a path in the input-data

be kind and try to map on profile-name if profile-id not available (or did not match) 
:)
declare function smc:match-paths($ay-data as item(), $profile as node()) as item()* {

let $data-paths := $ay-data//Term/replace(replace(xs:string(@path),'//',''),'/','.')

let $profile-id := xs:string($profile/sru:value)
let $profile-name := xs:string($profile/sru:displayTerm)    
  
let $match-by-id := if ($profile-id ne '') then $smc:cmd-terms//Termset[@id=$profile-id and @type="CMD_Profile"]/Term[xs:string(@path) = $data-paths ] else ()
let $match := if (exists($match-by-id)) then $match-by-id
                    else $smc:cmd-terms//Termset[xs:string(@name)=$profile-name and @type="CMD_Profile"]/Term[xs:string(@path) = $data-paths ] 

let $mapping := for $datcat in distinct-values($match//xs:string(@datcat))
                    let $key := smc:shorten-uri($datcat) 
                    return <index key="{$key}" >
                                { for $path in $match[xs:string(@datcat) = $datcat]/xs:string(@path)                                    
                                    return <path count="">{$path}</path>
                                }
                            </index>
return $mapping
};

(:~ replace url_prefix in the url by the short key
based on definitions in $smc:termsets
:)
declare function smc:shorten-uri($url as xs:string) as xs:string {    
    let $termset := $smc:termsets//Termset[url_prefix][starts-with($url, url_prefix)][$url ne '']
    let $url-suffix := substring-after ($url, $termset/url_prefix)    
    return if (exists($termset)) then concat($termset/key, ':', $url-suffix) else $url
};