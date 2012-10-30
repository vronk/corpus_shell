xquery version "1.0";
module namespace fcs-tests  = "http://clarin.eu/fcs/1.0/tests";

import module namespace httpclient = "http://exist-db.org/xquery/httpclient";
import module namespace t="http://exist-db.org/xquery/testing";
import module namespace repo-utils = "http://aac.ac.at/content_repository/utils" at  "/db/cr/repo-utils.xqm";

declare namespace zr="http://explain.z3950.org/dtd/2.1/";
declare namespace sru = "http://www.loc.gov/zing/srw/";
declare namespace fcs = "http://clarin.eu/fcs/1.0";
declare namespace diag = "http://www.loc.gov/zing/srw/diagnostic/";
declare namespace xhtml="http://www.w3.org/1999/xhtml"; 

(: sample input:
    
 :)
declare variable $fcs-tests:config := doc("config.xml");
declare variable $fcs-tests:cr-config := repo-utils:config("/db/cr/conf/cr/config.xml");
declare variable $fcs-tests:run-config := "run-config.xml";
declare variable $fcs-tests:testsets-coll := "/db/cr/modules/testing/testsets/";
declare variable $fcs-tests:results-coll := "/db/cr/modules/testing/results/";
declare variable $fcs-tests:href-prefix := "tests.xql";

(: this function is accessed by the testing-code to get configuration-options from the run-config :)
declare function fcs-tests:config-value($key as xs:string) as xs:string* {
            let $config := doc(concat($fcs-tests:testsets-coll, $fcs-tests:run-config))/config
                return if ($key eq "testset") then  xs:string($config//testset/@key)
                        else $config//target/text()
};

declare function fcs-tests:config-key($key as xs:string) as xs:string* {
            let $config := doc(concat($fcs-tests:testsets-coll, $fcs-tests:run-config))/config
                return if ($key eq "testset") then  xs:string($config//testset/@key)
                        else xs:string($config//target/@key)
};

declare function fcs-tests:get-result-paths($target  as xs:string, $testset as xs:string) as xs:string* {
        (concat($fcs-tests:results-coll, $target, "/"), concat($testset, ".xml"))
};

declare function fcs-tests:get-result-path($target  as xs:string, $testset as xs:string) as xs:string* {
        string-join(fcs-tests:get-result-paths($target , $testset ), "" )
};

declare function fcs-tests:get-result($target  as xs:string, $testset as xs:string) as item() {
  let $result-path := fcs-tests:get-result-path($target, $testset)
   let $result := if ($target = '' or $testset = '') then () 
                            else if (doc-available($result-path)) then
                            doc($result-path)                            
                        else <diagnostics><diagnostic key="result-unavailable">result unavailable: {$result-path}</diagnostic>
                                <diagnostic>{fcs-tests:get-testset($testset)}</diagnostic>
                              </diagnostics>
 return $result
};

(:~ try to get the testset-file based on the testset-key
@returns testset-file if available, otherwise empty result
:)
declare function fcs-tests:get-testset($testset as xs:string) as item()* {
    let $testset-path := concat($fcs-tests:testsets-coll, $testset, ".xml")
    return if (doc-available($testset-path)) then                        
                    doc($testset-path)
                  else 
                  <diagnostic>unknown testset: {$testset}</diagnostic>
};


(:~ main function governing the execution of the tests

Generates a run-config out of the full config based on the parameters.
@param $target identifying key of the target  as set in the config
@param $testset-key identifying key of the testset as set in the config (that also has to be the name of the testset-file)
:)
declare function fcs-tests:run-testset($target  as xs:string, $testset-key as xs:string) as item()* {
    
    (: preparing a configuration for given run, based on the parameters :)
    let $run-config := <config>{($fcs-tests:config//target[xs:string(@key) = $target],
                                $fcs-tests:config//testset[xs:string(@key) = $testset-key])}</config>
    let $store := repo-utils:store($fcs-tests:testsets-coll, $fcs-tests:run-config, $run-config, true())
    let $testset := fcs-tests:get-testset($testset-key)
    let $start-time := util:system-dateTime()
    let $result := if (exists($testset)) then                        
                            let $tests := $testset//TestSet
                            (: distinguish the testset, that the testing-module can process
                               and the home-made test-doc, that tests URLs :)
                            return if (exists($tests)) then
                                        t:run-testSet($tests, ())
                                     else
                                        fcs-tests:test-rest($testset)
                       else
                           $testset 
    let $end-time := util:system-dateTime()
    let $test-wrap := <testrun duration="{$end-time - $start-time}" on="{fn:current-dateTime()}" >{$result}</testrun>
    let $store-result := fcs-tests:store-result($target, $testset-key, $test-wrap)
    (:for $test in $tests/tests/test return fcs-tests:run-test($test):)
    return $store-result
};

(:~ process a test-doc (target is expected to be set in the config)
:)
declare function fcs-tests:test-rest($test-doc as node()) as item()* {

    let $result := local:dispatch($test-doc)
    
(:
let $targets := if (exists($test/target)) then $test/target else $test/preceding-sibling::target
let $requests := for $target in $targets return concat($target, $test/request/text())
let $data := for $request in $requests return
                <request href="{$request}" id
                httpclient:get(xs:anyURI($request), false(), () )

let $check := for $condition in $test/condition 
                        let $expr :=concat("($data/", $condition/text(), " eq ", xs:string($condition/@result), ")")
                         return <check expr="{$expr}" >{util:eval($expr)} </check>
return <test><id>{$test/id}</id><label>{$test/label}</label>
            <requests>{$requests}</requests>
            <results>{$check}</results>
        </test>
:)
return $result

};

(:~ This function takes the children of the node and passes them
   back into the typeswitch function. :)
declare function local:passthru($x as node()) as node()*
{
for $z in $x/node() return local:dispatch($z)
};

(:~ This is the recursive typeswitch function, to traverse the testset-document :)
declare function local:dispatch($x as node()) as node()*
{
typeswitch ($x)
  case text() return $x
  case element (test) return element div {$x/@*, attribute class {"test"}, fcs-tests:process-request($x)}  
  case element() return element {$x/name()} {$x/@*, local:passthru($x)}  
  default return local:passthru($x)
};

(:~ executes one URL-test. 

Issues one http-call to the target-url in the a@href-attribute, stores the incoming result and evaluates the associated xpaths  

expects:
   <div class="test" id="search-haus">
      <a class="request" href="?operation=searchRetrieve&amp;query=Haus">search: Haus</a>
      <span class="check xpath">//sru:numberOfRecords</span>
   </div>
   
@returns the requested-url, results of the xpath-evaluations as a div-list and any diagnostics
:)     
declare function fcs-tests:process-request($test as node()) as item()* {
    
    let $a := $test/a,
        $test-id := xs:string($test/@id),
        $target := fcs-tests:config-value("target"), 
        $target-key := fcs-tests:config-key("target"),
        $request := concat($target, xs:string($a/@href))    
    let $a-processed := <a href="{$request}">{$a/text()}</a>
    let $result-data := httpclient:get(xs:anyURI($request), false(), () )
                            
    let $store := fcs-tests:store-result($target-key, $test-id, $result-data)
    
    (: evaluate all xpaths defined for given request :) 
    let $check := for $xpath in $test/xpath 
                    let $evald := util:eval($xpath/text())
                    
                    return 
                    <div><span class="key">{if (exists($xpath/@key)) then xs:string($xpath/@key) else $xpath/text()}:</span> 
                          <span class="value {if ($evald instance of xs:boolean) then xs:string($evald) else '' }">{$evald}</span>
                    </div>
                    
     (: checking extra for diagnostics :)
     let $http-status := $result-data/httpclient:response/@statusCode     
     let $diag := ($result-data//diag:diagnostic, $result-data//exception, 
                if ($http-status ne '200') then <http-status>{$http-status}</http-status> else ())      
      let $wrapped-diag := if (exists($diag)) then 
                <diagnostics type="{string-join($diag/name(),',')}" >{$diag}</diagnostics> else ()                     
return ($a-processed, $check, $wrapped-diag) 
};

declare function fcs-tests:store-result($target as xs:string, $testset as xs:string, $result as node()) as item()* { 
    fcs-tests:store-result ($target, $testset, "", $result)
};


declare function fcs-tests:store-result($target as xs:string, $testset as xs:string, $test as xs:string, $result as node()) as item()* {
(: create collection for results for one target :)
   let $create-coll := if (not(xmldb:collection-available(concat($fcs-tests:results-coll, $target)))) then 
                           xmldb:create-collection($fcs-tests:results-coll, $target) else ()
  
  let $result-path := fcs-tests:get-result-paths($target, concat($testset, $test))
   
  let $store-result := repo-utils:store($result-path[1], $result-path[2], $result, true())

return $store-result
};


declare function fcs-tests:format-result($result as node()) as item()* {
    
    if ($result[self::element(diagnostics)]) then
            <div class="message">{$result/text()}</div>
       else if (exists($result/testrun)) then
          repo-utils:serialise-as ($result, "html", "test", $fcs-tests:cr-config)
       else repo-utils:serialise-as ($result, "html", "test", $fcs-tests:cr-config)
              (: return quite empty html ?? 
                t:format-testResult($result) :)
};

declare function fcs-tests:display-page($target  as xs:string, $testset as xs:string, $operation) as item()* {

    let $result := fcs-tests:get-result($target, $testset)        
     
    let $formatted-result := fcs-tests:format-result($result)  
    let $opt := util:declare-option("exist:serialize", "media-type=text/html method=xhtml") 
    return     
    <html>
        <head>
            <title>FCS - test suite</title>
            <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
             <link rel="stylesheet" type="text/css" href="tests.css" />            
             <link rel="stylesheet" type="text/css" href="../../scripts/style/cmds-ui.css" />
        </head>
        <body>            
            <div id="header">
             <!--  <ul id="menu">                    
                    <li><a href="collectresults.xql">Results</a></li>
                </ul>--> 
                <h1>FCS - test suite</h1>
            </div>
            
            <div id="content">
            {if ($operation = 'overview') then fcs-tests:display-overview() else () }
            <form>
                <label>targets</label><select name="target">
                    {
                    for $target-elem  in $fcs-tests:config//target
                        let $target-key := xs:string($target-elem/@key)
                        let $option :=  if ($target = $target-key) then
                                            <option selected="selected" value="{$target-key}" >{$target-key}</option>
                                         else
                                            <option value="{$target-key}" >{$target-key } </option>
                        return $option
                    }
                </select>
                <label>test-set</label><select name="testset">
                    {
                    for $testset-elem in $fcs-tests:config//testset
                        let $testset-key := xs:string($testset-elem/@key)
                        let $option :=  if ($testset= $testset-key) then
                                            <option selected="selected" value="{$testset-key}" >{$testset-key}</option>
                                         else
                                            <option value="{$testset-key}" >{$testset-key}</option>
                        return $option
                    }
                </select>
                <label>test-set</label>
                    <select name="operation">
                       <option value="run" >{if ($operation = 'run') then attribute selected { "selected" } else ()} run</option>
                       <option value="view" > {if ($operation = 'view') then attribute selected { "selected" } else ()} view</option>                    
                       <option value="overview" > {if ($operation = 'overview') then attribute selected { "selected" } else ()} overview</option>
                    </select>                
                <input type="submit" value="View/Run" />
                </form>
                
                <div id="result">{$formatted-result}</div>
                
            </div>            
        </body>
    </html>

};

declare function fcs-tests:display-overview() as item()* {

    <table><tr><th></th>{for $target in $fcs-tests:config//target return <th>{xs:string($target/@key)}</th>}</tr>
            {for $testset in $fcs-tests:config//testset
                    let $testset-key := $testset/xs:string(@key)
                    return <tr>
                        <th>{$testset-key}</th>
                        {for $target in $fcs-tests:config//target
                           let $target-key := $target/xs:string(@key)
                           let $test-result := fcs-tests:get-result($target-key , $testset-key )                           
                           let $root-elem := $test-result/*/name()
                           let $op := if ($test-result//diagnostic["result-unavailable" = xs:string(@key)]) then 'run' else 'view'
                           (: display number of all and failed tests in the testset, operates on the HTML produced during the test-run :)
                           let $view:= if ($test-result//diagnostic["result-unavailable" = xs:string(@key)]) then ()
                                       else  
                                            let $show := if ($root-elem[1] eq 'testrun') then 
                                                            <span><span class="test-passed">{count($test-result//div[@class='test'][.//span[@class='value true']])}</span>{"/"}
                                                                   <span class="test-failed">{count($test-result//div[@class='test'][.//span[@class='value false']])}</span>{"/"}                                                                   
                                                                {count($test-result//div[@class='test'])}
                                                                {if (exists($test-result//diagnostics)) then <span class="test-failed">!!</span> else () }
                                                              </span>
                                                            else $root-elem 
                                            return <a href="?target={$target-key}&amp;testset={$testset-key}&amp;operation=view" >{$show}</a> 
                                    
                        return <td align="center">{$view} [<a href="?target={$target-key}&amp;testset={$testset-key}&amp;operation=run" >run</a>]</td>
                        }
                    </tr>
            }</table>
};
