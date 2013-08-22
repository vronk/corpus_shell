xquery version "1.0";

declare option exist:serialize "method=text media-type=text/csv encoding=UTF-8";

    let $dataset := doc("/db/apps/testing/AGkorpus_onAMC_all.dataset.xml" )
    (: let $dataset := doc("/db/apps/testing/VWB-lemmas_onAMC_all.dataset_2012-12-10.xml")  :)
    (: let $dataset := doc("/db/apps/testing/VWB-lemmas_onAMC_c20.dataset.xml") :)
   let $csv := transform:transform($dataset, doc("/db/apps/cr-xq/modules/dataset/dataset2csv.xsl"), ()) 
    
  return xmldb:store("/db/apps/testing/","AGkorpus_onAMC_all.dataset.csv", $csv, 'text/css')  
 (: return $csv :)