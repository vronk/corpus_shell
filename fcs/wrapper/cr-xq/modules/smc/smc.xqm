xquery version "1.0";
module namespace smc = "http://clarin.eu/smc";

import module namespace repo-utils = "http://aac.ac.at/content_repository/utils" at  "xmldb:exist:///db/cr/repo-utils.xqm";
import module namespace crday  = "http://aac.ac.at/content_repository/data-ay" at "/db/cr/crday.xqm";
import module namespace fcs = "http://clarin.eu/fcs/1.0" at "/db/cr/fcs.xqm";

declare namespace sru = "http://www.loc.gov/zing/srw/";

declare variable $smc:termsets := doc("data/termsets.xml");
declare variable $smc:cmd-terms := doc("data/cmd-terms.xml");

(:~ create and store mapping for every profile in given nodeset 
expects the CMD-structure
:)
declare function smc:get-mappings($x-context as xs:string, $config) as item()* {

let $scan-profiles :=  fcs:scan('cmd.profile', $x-context, 1, 50, 1, 1, "text", $config),
    $target_path := repo-utils:config-value($config, 'cache.path')

(: for every profile in the data-set :)
for $profile in $scan-profiles//sru:term
    let $profile-name := xs:string($profile/sru:displayTerm)    
    let $map-doc-name := repo-utils:gen-cache-id("map", ($x-context, $profile-name), '')
    
    let $result := 
        if (repo-utils:is-in-cache($map-doc-name, $config)) then  (:and not($run-flag):)
            repo-utils:get-from-cache($map-doc-name, $config)
        else
            let $ay-data := crday:get-ay-xml($config, $x-context, $profile-name, $crday:defaultMaxDepth, '')    
            let $mappings := smc:match-paths($ay-data)
            return repo-utils:store-in-cache($map-doc-name, $mappings, $config)
   return $result
(:  TODO?: add html-serialization
    return repo-utils:serialise-as($result, 'htmlpage', 'terms', $config, ()):)
    
};

(:~ expects a summary of data, matches the resulting paths with paths in cmd-terms
and returns dcr-indexes, that have a path in the input-data

:)
declare function smc:match-paths($ay-data as item()) as item()* {

let $data-paths := $ay-data//Term/replace(replace(xs:string(@path),'//',''),'/','.')
let $match := $smc:cmd-terms//Term[xs:string(@path) = $data-paths ]

let $mapping := for $datcat in distinct-values($match//xs:string(@datcat))
                    let $key := smc:shorten-uri($datcat) 
                    return <index key="{$key}" >
                                { for $path in $match[xs:string(@datcat) = $datcat]/xs:string(@path)
                                    return <path>{$path}</path>
                                }
                            </index>
return <map>{$mapping}</map>
};

(:~ replace url_prefix in the url by the short key
based on definitions in $smc:termsets
:)
declare function smc:shorten-uri($url as xs:string) as xs:string {    
    let $termset := $smc:termsets//Termset[url_prefix][starts-with($url, url_prefix)][$url ne '']
    let $url-suffix := substring-after ($url, $termset/url_prefix)    
    return if (exists($termset)) then concat($termset/key, ':', $url-suffix) else $url
};