xquery version "1.0";

import module namespace fcs-tests = "http://clarin.eu/fcs/1.0/tests" at  "tests.xqm"; 
(:import module namespace httpclient = "http://exist-db.org/xquery/httpclient";:)

declare namespace sru = "http://www.loc.gov/zing/srw/";
declare namespace fcs = "http://clarin.eu/fcs/1.0";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

(:let $target := "http://localhost:8681/exist/cr/"
let $testset-name := "test_connect"

let $tests := doc(concat("testsets/", $testset-name, ".xml"))//TestSet
:)
(:let $data := httpclient:get(xs:anyURI("http://localhost:8680/exist/rest/db/content_repository/scripts/cr.xql"), false(), () ) :)
(:let $store := xmldb:store("results", concat($testset-name, '.xml'), t:run-testSet($tests)) :)

 
(: t:run-testSet($tests)
t:format-testResult($store):)

let $target := request:get-parameter("target", ())
let $testset := request:get-parameter("testset", ())
let $operation := request:get-parameter("operation", ())
let $messages := ""
return
    if ($operation eq "run") then        
        let $run := fcs-tests:run-testset($target, $testset)
        return fcs-tests:display-page($target, $testset, $operation)
    else
        fcs-tests:display-page($target, $testset,$operation)