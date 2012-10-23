xquery version "1.0";
import module namespace request="http://exist-db.org/xquery/request";
import module namespace crday  = "http://aac.ac.at/content_repository/data-ay" at "/db/cr/crday.xqm";
import module namespace diag =  "http://www.loc.gov/zing/srw/diagnostic/" at  "modules/diagnostics/diagnostics.xqm";
import module namespace repo-utils = "http://aac.ac.at/content_repository/utils" at  "/db/cr/repo-utils.xqm";

let $config-path := request:get-parameter("config", "/db/cr/conf/cr/config.xml"),
    $op := request:get-parameter("operation", ""),
(:    $config := doc($config-path),:)
    $config := repo-utils:config($config-path),
    $format := request:get-parameter("x-format",'htmlpage'),
    $x-context := request:get-parameter("x-context", "") (: "univie.at:cpas"  "clarin.at:icltt:cr:stb" :),

    $result := if ($op eq '') then 
                        crday:display-overview($config-path)
               else if (contains ($op, 'query')) then
                    crday:get-query-internal($config, $x-context, (contains($op, 'run')), $format)                    
               else if (contains ($op, 'scan-fcs-resource')) then
                    crday:get-fcs-resource-scan($config-path, (contains($op, 'run')), $format)                    
               else if (contains ($op, 'struct')) then
                    let $init-path := request:get-parameter("init-path", ""),              
                        $max-depth := request:get-parameter("x-maximumDepth", $crday:defaultMaxDepth)
                     return crday:get-ay-xml($config, $x-context, $init-path, $max-depth, (contains($op, 'run')), $format)                    
                else 
                    diag:diagnostics("unsupported-operation", $op)
return $result

