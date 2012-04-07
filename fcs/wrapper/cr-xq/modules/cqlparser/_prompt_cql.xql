xquery version "1.0";

    	import module namespace cql = "http://exist-db.org/xquery/cql" at "/db/cr/modules/cqlparser/cqlparser.xqm";
        import module namespace repo-utils = "http://aac.ac.at/content_repository/utils" at  "xmldb:exist:///db/cr/repo-utils.xqm";
        import module namespace fcs  = "http://clarin.eu/fcs/1.0" at "xmldb:exist:///db/cr/fcs.xqm";
        
		let $cql := "dce:title contains Wien"
     (:   let $xcql := cql:cql-to-xcql("personName any haus and (birth-place=Wien or death-place=Wien)") :)
        let $xcql := cql:cql-to-xcql($cql)
        let $x-context := 'clarin.eu:mdrepo' (: 'clarin.at:icltt:cr:aac-names' :)        
        let $config := doc("/db/cr/etc/config_mdrepo.xml")
        let $mappings-file := repo-utils:config-value($config, 'mappings') (: 'xmldb:///db/cr/etc/mappings_mdrepo.xml' :)
        let $context := repo-utils:context-to-collection($x-context, $config)
        (:let $context :=  collection('/db/mdrepo-data') :)
        let $xpath1 := cql:cql2xpath ($cql, $x-context, $mappings-file)
        let $fcs-q := fcs:transform-query-old($cql, $x-context, 'search', $config )
        let $xpath :=  transform:transform ($xcql, $cql:transform-doc, 
            <parameters><param name="x-context" value="{$x-context}" />
                <param name="mappings-file" value="{$mappings-file}" />
            </parameters> )
(:  cql:cql2xpath or person = Adler :)
let $result := util:eval("$context//(teiHeader/fileDesc/titleStmt/title|teiHeader/fileDesc/sourceDesc/biblStruct/monogr/title)[. eq 'Kochschule']")

return (concat("$context",$xpath1),util:eval(concat("$context",$xpath1))) 
(: $context//(titleStmt)[contains(.,'Wien')]
$context//(Components)[ft:query(.,'Wien')]:)