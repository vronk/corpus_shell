xquery version "1.0";
import module namespace request="http://exist-db.org/xquery/request";
import module namespace crday  = "http://aac.ac.at/content_repository/data-ay" at "/db/cr/crday.xqm";

let $config-path := request:get-parameter("config", "/db/cr/etc/config.xml"),
    $op := request:get-parameter("operation", ""),
    $config := doc($config-path), 
    $x-context := request:get-parameter("x-context", "") (: "univie.at:cpas"  "clarin.at:icltt:cr:stb" :),

    $result := if ($op eq '') then 
                        crday:display-overview($config-path)                   
                    else crday:run-check-queries($config, $x-context, ($op = 'run'))

return $result

