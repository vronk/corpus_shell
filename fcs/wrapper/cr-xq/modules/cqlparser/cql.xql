xquery version "1.0";

import module namespace cql = "http://exist-db.org/xquery/cql" at "/db/cr/modules/cqlparser/cqlparser.xqm";
import module namespace request="http://exist-db.org/xquery/request";

let $cql := request:get-parameter("cql", "title any Wien and date < 1950")
return (cql:cql-to-xcql($cql))