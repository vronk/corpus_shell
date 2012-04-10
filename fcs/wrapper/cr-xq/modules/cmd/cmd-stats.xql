let $doc-name := xmldb:store("/db/mdrepo-data", "stats_cmd.xml", <result></result>),
    $doc := doc($doc-name),
    (:    $ns-uri := namespace-uri($context[1]/*), :)         	           
            (: dynamically declare a namespace for the next step, if one is defined in current context :)
    (: $dummy := if (exists($ns-uri)) then util:declare-namespace("",$ns-uri) else () :)
    $dummy := util:declare-namespace("",xs:anyURI("http://www.clarin.eu/cmd/")),
    $collection := collection("/db/mdrepo-data"),
$items := (<item key="C" label="CMD" >count($collection//CMD)</item> ,
<item key="C.0" label="CMD without " >count($collection//CMD[not(.//ResourceType='Resource')][not(.//ResourceType='Metadata')])</item>,
<item key="C.R+M" label="CMD with MD and Res" >count(($collection//CMD[.//ResourceType='Resource'][.//ResourceType='Metadata']))</item>,
<item key="C.R" label="CMD with Resource" >count($collection//CMD[.//ResourceType='Resource'])</item>,
<item key="C.R.0" label="CMD - with Resource empty">count($collection//CMD[.//ResourceType='Resource'][.//ResourceRef[. = ""]])</item>,
<item key="C.R.1" label="CMD with relative Resource (starts-with('.'))" >count($collection//CMD[.//ResourceType='Resource'][starts-with(.//ResourceRef,'.')])</item>,
<item key="C.R.2" label="CMD with http-uri Resource" >count($collection//CMD[.//ResourceType='Resource'][starts-with(.//ResourceRef,'http')])</item>,
<item key="C.R.1+2" label="CMD - with relative and http Resource">count($collection//CMD[.//ResourceType='Resource'][starts-with(.//ResourceRef,'.')][starts-with(.//ResourceRef,'http')])</item>,
<item key="C.R.3" label="CMD - Resource only filename (not empty, no '/')" >count($collection//CMD[.//ResourceProxy[ResourceType='Resource'][ResourceRef[not(. = "")][not(contains(.,'/'))]]])</item>,
<item key="RP.R" label="ResourceProxy - Resource" >count(//ResourceProxy[ResourceType='Resource'])</item>,

<item key="C.cc.self" label="CMD with IsPartOf=MdSelfLink" >count($collection//CMD[.//MdSelfLink=.//IsPartOf])</item>,

<item key="C.M" label="CMD with Metadata = Collections" >count($collection//CMD[.//ResourceType='Metadata'])</item>,
<item key="C.M.1" label="CMD with relative MD" >count($collection//CMD[.//ResourceType='Metadata'][starts-with(.//ResourceRef,'.')])</item>,
<item key="C.M.2" label="CMD with http-uri MD" >count($collection//CMD[.//ResourceType='Metadata'][starts-with(.//ResourceRef,'http')])</item>
)
return
 for $item in $items 
 let $answer := util:eval($item/text())
return update insert <item key="{$item/@key}" label="{$item/@label}">{$answer}</item> into $doc/result

(: <item key="C.R.3" label="CMD - Resource not empty, not relative, not http">5100</item>	   
  <item label="CMD - Resource not relative, not http" >count(//CMD[.//ResourceType='Resource'][not(starts-with(.//ResourceRef,'.'))][not(starts-with(.//ResourceRef,'http'))])</item>,
 
 
 ,
<item key="C.0" label="CMD without " >count(//CMD[not(.//ResourceType='Resource')][not(.//ResourceType='Metadata')])</item>,
<item key="C.R+M" label="CMD with MD and Res" >count((//CMD[.//ResourceType='Resource'][.//ResourceType='Metadata']))</item>,
<item key="C.R" label="CMD with Resource" >count(//CMD[.//ResourceType='Resource'])</item>,
<item key="C.R.0" label="CMD - with Resource empty">count(//CMD[.//ResourceType='Resource'][.//ResourceRef[. = ""]])</item>,
<item key="C.R.1" label="CMD with relative Resource (starts-with('.'))" >count(//CMD[.//ResourceType='Resource'][starts-with(.//ResourceRef,'.')])</item>,
<item key="C.R.2" label="CMD with http-uri Resource" >count(//CMD[.//ResourceType='Resource'][starts-with(.//ResourceRef,'http')])</item>,
<item key="C.R.1+2" label="CMD - with relative and http Resource">count(//CMD[.//ResourceType='Resource'][starts-with(.//ResourceRef,'.')][starts-with(.//ResourceRef,'http')])</item>,
<item key="C.R.3" label="CMD - Resource only filename (not empty, no '/')" >count(//CMD[.//ResourceProxy[ResourceType='Resource'][ResourceRef[not(. = "")][not(contains(.,'/'))]]])</item>,
<item key="RP.R" label="ResourceProxy - Resource" >count(//ResourceProxy[ResourceType='Resource'])</item>,

<item key="C.M" label="CMD with Metadata = Collections" >count(//CMD[.//ResourceType='Metadata'])</item>,
<item key="C.M.1" label="CMD with relative MD" >count(//CMD[.//ResourceType='Metadata'][starts-with(.//ResourceRef,'.')])</item>,
<item key="C.M.2" label="CMD with http-uri MD" >count(//CMD[.//ResourceType='Metadata'][starts-with(.//ResourceRef,'http')])</item>,

<item key="RP.M" label="ResourceProxy - Metadata" >count(//ResourceProxy[ResourceType='Metadata'])</item>,

<item key="C..3" label="CMD - only filename (not empty, no '/')" >count(//CMD[.//ResourceRef[not(. = "")][not(contains(.,'/'))]])</item>,
<item key="RR.3" label="ResourceRef only filename (not empty, no '/')" >count(//ResourceRef[not(. = "")][not(contains(.,'/'))])</item>,
<item key="C..RR.0" label="CMD - empty ResourceRef">count(//CMD[.//ResourceRef[. = ""]])</item>,
<item key="RR.0 label="ResourceRef empty">count(//ResourceRef[. = ""])</item>,
<item key="C..RR.0+1" label="CMD - empty and non-empty ResourceRef">count((//CMD[.//ResourceRef[. = ""]][.//ResourceRef[not(. = "")]]))</item>
 :)
 
 