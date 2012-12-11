xquery version "1.0";
import module namespace request="http://exist-db.org/xquery/request";
(:import module namespace cradmin  = "http://aac.ac.at/content_repository/admin" at "/db/cr/admin.xqm";:)
import module namespace cmdcheck = "http://clarin.eu/cmd/check" at "/db/cr/modules/cmd/cmd-check.xqm";
import module namespace diag =  "http://www.loc.gov/zing/srw/diagnostic/" at  "modules/diagnostics/diagnostics.xqm";
import module namespace smc = "http://clarin.eu/smc" at "/db/cr/modules/smc/smc.xqm";

let $config-path := request:get-parameter("config", "/db/cr/conf/mdrepo/config.xml"),
    $op := request:get-parameter("operation", ""),
    $config := doc($config-path), 
    $format := request:get-parameter("x-format",'htmlpage'),
    $x-context := request:get-parameter("x-context", "") (: "univie.at:cpas"  "clarin.at:icltt:cr:stb" :),

    $result := if ($op eq '') then 
                    cmdcheck:display-overview($config-path)                    
                else if (contains ($op, 'mappings-overview')) then                    
                    smc:mappings-overview($config, $format)
                else if ($op = 'gen-mappings') then                
                    cmdcheck:collection-to-mapping($config, $x-context)
                else if (contains ($op, 'mappings')) then                    
                    smc:get-mappings($config, $x-context, (contains($op, 'run')), $format)                    
                
                else 
                    diag:diagnostics("unsupported-operation", $op)
(:                    else cmdcheck:run-stats($config-path):)

return $result


