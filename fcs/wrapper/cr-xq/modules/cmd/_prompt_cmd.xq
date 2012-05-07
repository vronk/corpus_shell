xquery version "1.0";

import module namespace repo-utils =  "http://aac.ac.at/content_repository/utils" at  "/db/cr/repo-utils.xqm";
import module namespace cmdcheck  = "http://clarin.eu/cmd/check" at "/db/cr/modules/cmd/cmd-check.xqm";
import module namespace cmdcoll = "http://clarin.eu/cmd/collections" at "/db/cr/modules/cmd/cmd-collections.xqm";
declare namespace cmd = "http://www.clarin.eu/cmd/";

let $config := doc("/db/cr/etc/config_mdrepo.xml"), 
    $x-context := "test_cmd", (: "http://clarin.eu/lrt-inventory", clarin-at:aac-test-corpus :)
    $data-collection := repo-utils:context-to-collection($x-context, $config),
(:    $data-collection := collection("/db/mdrepo-data/cmdi-providers"),:)
    $testset-name := 'testset_cmd',
    $query-doc := doc(concat("/db/cr/modules/cmd/", $testset-naem, ".xml"))

let $result-filename := concat('queries_', repo-utils:sanitize-name(concat($x-context, '-', $testset-name)), '.xml'),
    $result-path := repo-utils:config-value($config, 'log.path')

let $base-dbcoll := cmdcoll:base-dbcoll($config)
      let $data := cmdcoll:colls($collections, $max-depth, $base-dbcoll)

let $orphaned := $data-collection//cmd:CMD[not(cmd:Header/cmd:MdSelfLink = $data-collection//cmd:ResourceProxy[cmd:ResourceType eq 'Metadata']/cmd:ResourceRef)]

let $first-level := $data-collection//cmd:MdSelfLink[. = $orphaned//cmd:ResourceRef]

return $data
(: cmdcheck:addIsPartOf($x-context, $config)
$first-level:)
(:    cmdcheck:query-internal($query-doc, $data-collection, $result-path, $result-filename ):)
