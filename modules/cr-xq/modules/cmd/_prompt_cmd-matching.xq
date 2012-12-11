xquery version "1.0";

declare default element namespace "http://www.clarin.eu/cmd/";
let $start-time := util:system-dateTime()
let $context := collection("/db/mdrepo-data/cmdi-providers")
let $mdselflinks := $context//MdSelfLink
let $resourceproxies := $context//ResourceProxy
let $resourceproxies-md := $resourceproxies
(:let $resourceproxies-md := $context//ResourceRef[../ResourceType = 'Metadata']:)
let $seq-limit := 1000
let  $rp-md-sub := $resourceproxies-md/xs:string(text())
(:let  $rp-md-sub := fn:subsequence($resourceproxies-md/xs:string(text()), 1, $seq-limit):)
(: )let $diff := for $rp in $rp-md-sub                    
                return if ($mdselflinks[ft:query(.,<term>{$rp}</term>)]) then () 
                 else <doc n="" >{$rp}</doc>
:)
(: let $match-for := for $mdlink in $mdselflinks, $rp in $rp-md-sub
                where $mdlink/text() = $rp
                return $mdlink :)
(:let  $match := $mdselflinks[text() = $rp-md-sub]:)
let  $id := $rp-md-sub[1]
(: does not use index ! :)
let $mdselflinks := $context//MdSelfLink
(:let  $mdsl-match  := $mdselflinks[. = $resourceproxies-md] :)
(: uses index!:)
(:let  $mdsl-match  := $context//MdSelfLink[. = $resourceproxies-md] :)
(:let  $mdsl-diff  := $context//MdSelfLink[not(. = $resourceproxies-md)] :)
(:let $rp-diff := $context//ResourceRef[not(. = $mdselflinks)] intersect $context//ResourceProxy[ResourceType eq 'Metadata']/ResourceRef:)
let $rp-diff-xpath := "count(c$ontext//ResourceRef[not(. =  $context//MdSelfLink)][../ResourceType eq 'Metadata'])"
let $rp-diff := util:eval($rp-diff-xpath)
(:let  $rp-match := $resourceproxies-md[. = $mdselflinks]:)

(:let $match-ft := $mdselflinks[ft:query(.,<term>{$id}</term>)]:)

(:($id, $mdselflinks[ft:query(.,<term>{$id}</term>)])
count( $mdsl-diff), :)
return (count($context), $rp-diff, (util:system-dateTime() - $start-time) )