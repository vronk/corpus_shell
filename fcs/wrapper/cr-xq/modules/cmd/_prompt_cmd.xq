xquery version "1.0";

let $config := doc("/db/cr/etc/config_mdrepo.xml"), 
    $x-context := "olac-root", (: "http://clarin.eu/lrt-inventory", clarin-at:aac-test-corpus :)
(:    $data-collection := repo-utils:context-to-collection($x-context, $config),:)
    $data-collection := collection("/db/mdrepo-data/cmdi-providers"),
    $testset-name := 'testset_cmd2',
    $query-doc := doc(concat("/db/cr/modules/cmd/", $testset-name, ".xml"))

let $result-filename := concat('queries_', repo-utils:sanitize-name(concat($x-context, '-', $testset-name)), '.xml'),
    $result-path := repo-utils:config-value($config, 'log.path')

return cmdcheck:query-internal($query-doc, $data-collection, $result-path, $result-filename )

