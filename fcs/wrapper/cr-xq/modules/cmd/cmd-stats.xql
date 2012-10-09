xquery version "1.0";
import module namespace request="http://exist-db.org/xquery/request";
(:import module namespace cradmin  = "http://aac.ac.at/content_repository/admin" at "/db/cr/admin.xqm";:)
import module namespace cmdcheck = "http://clarin.eu/cmd/check" at "/db/cr/modules/cmd/cmd-check.xqm";

let $config-path := request:get-parameter("config", "/db/cr/etc/config_mdrepo.xml"),
    $op := request:get-parameter("operation", ""),
    $config := doc($config-path), 
    $x-context := request:get-parameter("x-context", "") (: "univie.at:cpas"  "clarin.at:icltt:cr:stb" :),

    $result := if ($op eq '') then cmdcheck:display-overview($config-path)
                    else cmdcheck:run-stats($config-path)

return $result

