xquery version "1.0";   
            
   (: declare option exist:serialize "method=text media-type=text/xml encoding=UTF-8";:)
     
    let $rel-label := ' ppm'
    let $lb := "&#xD;&#xA;"
    let $percentile-base :=1000000
    let $decimal-base := 100
    let $all-label := '_all_'
    let $store := true()
    let $output-dir := "/db/apps/testing/" 
    let $output-file := "VWB-lemmas_onAMC_all.dataset.xml"
      (: let $data := subsequence(collection("/db/apps/cr/modules/testing/results/corpus207-solr4-8985"),1,20)   :)
    let $data := collection("/db/apps/cr/modules/testing/results/corpus207-solr4-8985") 
      
    (: let $data := collection("/db/cr/modules/testing/results/local-solr4")      :)
    
   let  $base-data := doc("/db/apps/cr/modules/testing/results/corpus207-solr4-8985/stats-overall-sum-base.xml")
    (: let  $base-data := doc("/db/cr/modules/testing/results/local-solr4/stats-overall-sum-base.xml") :)
    
    (: contains - to eliminate erroneously doubly assigned:  "amitte aost" "asuedost asuedost" :)
    let $ordered-base-data := for $val in $base-data//dataseries/value[not(@label=$all-label)][not(contains(@label,' '))] 
                                  order by $val/ancestor::dataset/@name descending, xs:string($val/@label)
                                  return $val
    
    (: let $facet-labels := for $val in $base-data//dataseries/value[not(@label=$all-label)]  :)
    let $facet-labels := for $val in $ordered-base-data
                                (: order by $val/ancestor::dataset/@name descending, xs:string($val/@label) :)
                              (:  return (concat($val/ancestor::dataset/@name, ':', xs:string($val/@label)), concat( xs:string($val/@label), $rel-label)) :)
                              return concat($val/ancestor::dataset/@name, ':', xs:string($val/@label))
    
    let $all-records  := $base-data//result/xs:string(@numFound)
    let $all-value := ($base-data//dataseries/value[@label=$all-label])[1]
    
    
    let $base-values := for $val in $ordered-base-data
                                let $rel := round($val div $all-value * $percentile-base * $decimal-base) div $decimal-base
                            return ( xs:string($val/@formatted), translate(format-number($rel,'#,###.##'),',.','.,'))
    
 
  (:  let $labels := for $l in ('lemma', 'records', 'hits', 'freq', $facet-labels)   :)
        let $labels := <labels><label>{$all-label}</label>{for $l in  $facet-labels
                        return <label>{$l}</label>
                        }</labels>
      
      (:
    let $base-q = '*.*'                        
    let $base := <dataseries name="{$base-q}"> 
                        { for $v in ('*.*', $all-records, translate($all-value,'.',','), $percentile-base,  $base-values  )
                                return <value label="{" formatted="4.399.311.452">4.399311452E9</value>
         <value label="awest" formatted="407.400.374">4.07400374E8</value>
         ...
      </dataseries>
    :)
    let $dataseries := for $result in $data//result[@type="multiresult"]
                    let $q := $result//lst[@name='params']/str[@name='qkey']/text(),
                        $numberOfRecords := $result//@numFound,
                        $numberOfHits-x := $result//@numHits,
                        $numberOfHits := if (number($numberOfHits-x)=number($numberOfHits-x)) then
                                         if ($numberOfHits-x > $numberOfRecords * 10) then '' else
                                                round($numberOfHits-x) else   $numberOfHits-x,
                        (: $freq :=round((if(number($numberOfHits)=number($numberOfHits)) then $numberOfHits else $numberOfRecords)
                                    div $all-value * $percentile-base * $decimal-base) div $decimal-base, :)
                        $freq := ($result//dataseries[not(@type='base')]/value[@label=$all-label]/xs:string(@rel_formatted))[1],
                        $all-value := ($result//dataseries[not(@type='base')]/value[@label=$all-label])[1],
                        $hits-value := <value label="hits" >{$numberOfHits}</value>,
                        $values := for $val in $result//dataseries[not(@type='base')]/
                                        value[not(@label=$all-label)][not(contains(@label,' '))]  
                                        order by $val/ancestor::dataset/@name descending, xs:string($val/@label)
                                        return <value label="{concat($val/ancestor::dataset/@name, ':', xs:string($val/@label))}" >{$val/@*[not(name()='label')]}</value>
                (: ,$numberOfRecords, translate($numberOfHits,'.',','), translate($freq,'.',','),  $values),';') :)
        return <dataseries name="{$q}" hits="{number($numberOfHits)}">{($all-value, $values)}</dataseries>
    
        
    (:  for processing directly the solr-response
    let $csv := for $response in $data//response
        let $q := $response//lst[@name='params']/str[@name='q']/text(),
            $numberOfRecords := $response//result/xs:string(@numFound),
            $facets := $response//lst[@name='facet_fields']/lst/int,
            $region := for $m in $map return sum($facets[xs:string(@name)=$m/l/text()])
        return string-join(($q,$numberOfRecords, $region),';')

    let $csv := string-join(($csv-header, $csv-baseline, $csv-data), $lb)
:)    
    
    let $result := <dataset>{($labels,$dataseries)}</dataset>

    return  if ($store) then 
                    xmldb:store($output-dir,$output-file,$result)
                else
                    $result
        