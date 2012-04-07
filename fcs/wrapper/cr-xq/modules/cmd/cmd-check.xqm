xquery version "1.0";

(: checking consistency of the IDs in CMD-records (MdSelfLink vs. ResourceProxies)

TODO: check (and/or generate) the inverse links in IsPartOf (vs. ResourceProxies)
    :)
import module namespace cmd  = "http://clarin.eu/cmd/collections" at "/db/cr/cmd-collections.xqm";

let $collection-id := "clarin-at:aac-test-corpus"
let $base-dbcoll := collection($cmd:dataPath)

let $profiles := $base-dbcoll//MdProfile/text()
let $distinct-profiles := distinct-values($profiles)
let $profiles-summary := for $profile in $distinct-profiles
                            return <profile id="{$profile}" cnt="{count($profiles[. eq $profile])}" />

let $mdselflinks := $base-dbcoll//MdSelfLink
let $resourceproxies := $base-dbcoll//ResourceProxy
let $resourceproxies-md := $resourceproxies[ResourceType eq 'Metadata']/ResourceRef
(: )let $diff :=  $resourceproxies-md[not(index-of($mdselflinks, self::*))] 
let $diff2 :=  $mdselflinks[not($resourceproxies-md = text())]:)
let $diff := for $resource-proxy in $resourceproxies-md
                    let $id := xs:string($resource-proxy/text())
                return if ($mdselflinks[ft:query(.,<term>{$id}</term>)]) then () (: $mdselflinks[ft:query(.,<term>{$id}</term>)] :)
                 else $resource-proxy

let $diff2 := for $mdselflink in $mdselflinks
                    let $id := xs:string($mdselflink/text())
                return if ($resourceproxies-md[ft:query(.,<term>{$id}</term>)]) then () (: $mdselflinks[ft:query(.,<term>{$id}</term>)] :)
                 else $mdselflink

return ($diff,$diff2)
(:
return ($mdselflinks[ft:query(.,<term>{$id}</term>)])
 (index-of($resourceproxies-md,$mdselflinks[1]))
 let $a := (<a>a</a>,<a>b</a>,<a>c</a>)
let $b := (<b>b</b>,<a>d</a>,<a>e</a>)
let $diff := $a[$b = .] 
:)
(:    (count($mdselflinks), count($resourceproxies), count($resourceproxies-md), count($distinct-profiles), 
$diff,
$profiles-summary
)
:)