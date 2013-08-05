xquery version "3.0";

declare namespace sru = "http://www.loc.gov/zing/srw/";
declare namespace fcs = "http://clarin.eu/fcs/1.0";

(:  count(collection("/db/cr/modules/testing/results/corpus207-solr4-8985/")) :)

    let $store := true()
    let $output-dir := "/db/apps/sade-projects/amc/data/_indexes/"
    let $output-file := "index--dataset-size-1.xml"
    
let $docs := collection("/db/cr/modules/testing/results/corpus207-solr4-8985-core/")

(: subsequence($docs,1,20) 
 : unnecessarily inefficient: [lst[@name='params']/str[@name='qkey']]:)
let $terms  := for $doc in $docs/result
                let $qkey := $doc/lst[@name='params']/str[@name='qx']/text() (: qkey :)
                (: let $count := xs:string($doc/@numFound) :)
                let $count := string-join($doc/result[@name="response"]/xs:string(@numFound), '/')
            return <sru:term><sru:value>{$qkey}</sru:value><sru:numberOfRecords>{$count}</sru:numberOfRecords></sru:term>
            
let $result := <sru:scanResponse><sru:version>1.2</sru:version>
            <sru:terms>{$terms}</sru:terms>
            <sru:extraResponseData><fcs:countTerms>{count($terms)}</fcs:countTerms></sru:extraResponseData>
       </sru:scanResponse>
       
      
    return  if ($store) then 
                    xmldb:store($output-dir,$output-file,$result)
                else
                    $result