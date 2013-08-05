xquery version "1.0";

import module namespace smc  = "http://clarin.eu/smc" at "smc.xqm";
import module namespace crday  = "http://aac.ac.at/content_repository/data-ay" at "/db/cr/crday.xqm";
import module namespace repo-utils = "http://aac.ac.at/content_repository/utils" at  "xmldb:exist:///db/cr/repo-utils.xqm";
import module namespace cmdcheck  = "http://clarin.eu/cmd/check" at "/db/cr/modules/cmd/cmd-check.xqm";

declare namespace cmd = "http://www.clarin.eu/cmd/";

let $dcr-cmd-map := doc("/db/cr/modules/smc/data/dcr-cmd-map.xml")
let $cmd-terms := doc("/db/cr/modules/smc/data/cmd-terms.xml")
let $xsl-smc-op := doc("/db/cr/modules/smc/xsl/smc_op.xsl")

let $config := doc("/db/cr/etc/config_mdrepo.xml"), 
    $x-context := "olac-root" (: "http://clarin.eu/lrt-inventory", :)
(:    $context-collection := "/db/cr-data/barock",
    $data-collection := repo-utils:context-to-collection($x-context, $config)
    $context := collection($context-collection), :)

(: let $cmd-terms := doc("/db/cr/modules/smc/data/cmd-terms.xml") 
let $ay-data := doc("/db/mdrepo-data/_indexes/ay-teiHeader.xml") 
let $mapping := smc:create-mappings($ay-data)
return xmldb:store("/db/cr/etc", "mappings_mdrepo_auto.xml", $mapping)

let $ay-data := crday:ay-xml($data-collection, "Components", 4 ) 
return xmldb:store("/db/mdrepo-data/_indexes", "ay-olac-Components.xml", $ay-data)
:)

let $cache_path := repo-utils:config-value($config, 'cache.path')
(:let $mapping := smc:get-mappings($x-context, $config, true(),'raw'):)
(:let $mappings := collection($cache_path)/map[*]:)

let $profile_comps := distinct-values($cmd-terms//Term[@type='CMD_Component'][@parent='']/xs:string(@id)),
    $components := distinct-values($cmd-terms//Term[@type='CMD_Component'][not(@parent='')]/xs:string(@id))

(:return <comp>{for $comp in $components return :)

(:let $ambigue_names := distinct-values($cmd-terms//Term[lower-case(xs:string(@name))='name']/xs:string(@datcat)):)

(:let  $distinct-cmd-names := distinct-values($cmd-terms//Term/lower-case(xs:string(@name)))
let $ambiguity := for $n in  $distinct-cmd-names
                        let $distinct-datcats := distinct-values($cmd-terms//Term[lower-case(xs:string(@name))=$n]/xs:string(@datcat))
                    return <Term name="{$n}" count-datcats="{$distinct-datcats}"  ></Term>

return  for $term in $ambiguity
            order by $term/@count-datcats descending
            return $term :)
return ()            
(:
let $data-collection := repo-utils:context-to-collection($x-context, $config),
$ay-profiles := cmdcheck:stat-profiles($data-collection),
$child-elements := util:eval("$data-collection//collection")/child::element(),
$child-ns-qnames := if (exists($child-elements)) then distinct-values($child-elements/concat(namespace-uri(), '|', name())) else ()
:)
(:     $ns-uri := namespace-uri($data-collection[1]),    
    (namespace-uri($data-collection[1]/*), $data-collection[1]/*, $ay-profiles)  :)
(:return $mappings:)
(: crday:ay-xml($data-collection, "collection", 8)
let $path-nodes :=  $data-collection//cmd:Components,:)
(:    $child-elements := $path-nodes/child::element(),:)
(:    $ns := distinct-values($child-elements/namespace-uri()),:)
(:    (:  $subs := distinct-values($child-elements/concat(namespace-uri(), ":", name())),:):)
(:    $subs := distinct-values($child-elements/name()),    :)
(:    (: $dummy := util:declare-namespace ("", $ns), :):)
(:     $eval-subs := util:eval(concat("$path-nodes/", $subs)),:)



(:~ test shorten-uri
let $url := 'http://purl.org/dc/elements/1.1/title'
let $termset := $smc:termsets//Termset[url_prefix][starts-with($url, url_prefix)][$url ne '']
    let $url-suffix := substring-after ($url, $termset/url_prefix)    
return if (exists($termset)) then concat($termset/key, ':', $url-suffix) else $url
:)


(: let $list-cmd := transform:transform ($dcr-cmd-map, $xsl-smc-op,
<parameters><param name="operation" value="list"/>
    <param name="set" value="isocat-en"/>
    <param name="context" value="isocat-en"/>
</parameters>)

return (count($list-cmd//Term),$list-cmd)
:)
(:)
return transform:transform ($dcr-cmd-map, $xsl-smc-op, 
<parameters><param name="operation" value="map"/>    
    <param name="term" value="nome do projecto"/>        
</parameters>)
:)
