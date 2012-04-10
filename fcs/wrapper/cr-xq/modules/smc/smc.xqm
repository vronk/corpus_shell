xquery version "1.0";
module namespace smc = "http://clarin.eu/smc";

import module namespace repo-utils = "http://aac.ac.at/content_repository/utils" at  "xmldb:exist:///db/cr/repo-utils.xqm";
import module namespace crday  = "http://aac.ac.at/content_repository/data-ay" at "/db/cr/crday.xqm";
import module namespace cmdcheck  = "http://clarin.eu/cmd/check" at "/db/cr/modules/cmd/cmd-check.xqm";

declare variable $smc:termsets := doc("data/termsets.xml");
declare variable $smc:cmd-terms := doc("data/cmd-terms.xml");
declare variable $smc:ay-data-depth := 8;

(:~ create and store mapping for every profile in given nodeset 
expects the CMD-structure
:)
declare function smc:create-mappings($x-context as xs:string, $config) as item()* {

let $data-collection := repo-utils:context-to-collection($x-context, $config),
    $ay-profiles := cmdcheck:stat-profiles($data-collection),
    $target_path := repo-utils:config-value($config, 'cache.path')

(: for every profile in the data-set :)
for $profile in $ay-profiles
    let $profile-name := xs:string($profile/@name)
    let $ay-data := crday:ay-xml($data-collection, $profile-name, $smc:ay-data-depth )
    let $mappings := smc:match-paths($ay-data)
    let $ay-doc-name := concat('ay-', repo-utils:sanitize-name($x-context), '-', $profile-name, '.xml')
    let $map-doc-name := concat('map-', repo-utils:sanitize-name($x-context), '-', $profile-name, '.xml')
    return (xmldb:store($target_path, $ay-doc-name, $ay-data),
            xmldb:store($target_path, $map-doc-name, $mappings))
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