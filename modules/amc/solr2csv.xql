    xquery version "1.0";   
            
    declare option exist:serialize "method=text media-type=text/csv";
    
    let $rel-label := ' ppm'
    let $percentile-base := 1000000
    let $decimal-base := 100
    let $all-label := '_all_'
    let $data := collection("/db/cr/modules/testing/results/local-solr4")        
    
    let  $base-data := doc("/db/cr/modules/testing/results/local-solr4/stats-overall-sum-base.xml")
    
    let $facet-labels := for $val in $base-data//dataseries/value[not(@label=$all-label)] 
                                order by $val/ancestor::dataset/@name descending, xs:string($val/@label)
                                return (concat($val/ancestor::dataset/@name, ':', xs:string($val/@label)), concat( xs:string($val/@label), $rel-label))
    
    let $all-records  := $base-data//result/xs:string(@numFound)
    let $all-value := ($base-data//dataseries/value[@label=$all-label])[1]
    
    let $base-values := for $val in $base-data//dataseries/value[not(@label=$all-label)] 
                                let $rel := round($val div $all-value * $percentile-base * $decimal-base) div $decimal-base
                            order by $val/ancestor::dataset/@name descending, xs:string($val/@label)
                            return ( xs:string($val/@formatted), translate(format-number($rel,'#,###.##'),',.','.,'))
    
    let $csv-header := string-join(('lemma', 'records', 'hits',  $facet-labels)  ,';')
    let $csv-baseline := string-join(('*.*', $all-records, $all-value,   $base-values  ),';')
    
    let $csv := for $result in $data//result[@type="multiresult"]
                    let $q := $result//lst[@name='params']/str[@name='qkey']/text(),
                        $numberOfRecords := $result//xs:string(@numFound),
                        $numberOfHits := $result//xs:string(@numHits),
                        $values := for $val in $result//dataseries[not(@type='base')]/
                        value[not(@label=$all-label)] 
                        order by $val/ancestor::dataset/@name descending, xs:string($val/@label)
                        return ( xs:string($val/@formatted), xs:string($val/@rel_formatted))
        return (string-join(($q,$numberOfRecords, $numberOfHits, $values),';'),"&#xD;&#xA;")
    
        
    (:  for processing directly the solr-response
    let $csv := for $response in $data//response
        let $q := $response//lst[@name='params']/str[@name='q']/text(),
            $numberOfRecords := $response//result/xs:string(@numFound),
            $facets := $response//lst[@name='facet_fields']/lst/int,
            $region := for $m in $map return sum($facets[xs:string(@name)=$m/l/text()])
        return string-join(($q,$numberOfRecords, $region),';')
    :)
    
    
    return ($csv-header, "&#xD;&#xA;", $csv-baseline, "&#xD;&#xA;", $csv)