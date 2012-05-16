xquery version "1.0";
import module namespace request="http://exist-db.org/xquery/request";
import module namespace crday  = "http://aac.ac.at/content_repository/data-ay" at "/db/cr/crday.xqm";
import module namespace diag =  "http://www.loc.gov/zing/srw/diagnostic/" at  "modules/diagnostics/diagnostics.xqm";

let $config-path := request:get-parameter("config", "/db/cr/etc/config.xml"),
    $op := request:get-parameter("operation", ""),
    $config := doc($config-path), 
    $x-context := request:get-parameter("x-context", "") (: "univie.at:cpas"  "clarin.at:icltt:cr:stb" :),

    $result := if ($op eq '') then 
                        crday:display-overview($config-path)
               else if (contains ($op, 'query')) then
                    crday:get-query-internal($config, $x-context, (contains($op, 'run')), 'htmlpage')                    
               else if (contains ($op, 'struct')) then
                    let $init-path := request:get-parameter("init-path", ""),              
                        $max-depth := request:get-parameter("x-maximumDepth", $crday:defaultMaxDepth)
                     return crday:get-ay-xml($config, $x-context, $init-path, $max-depth, (contains($op, 'run')), 'htmlpage')                    
                else 
                    diag:diagnostics("unsupported-operation", $op)
return $result

