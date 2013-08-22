<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
  xmlns:exsl="http://exslt.org/common"
  xmlns:ds="http://aac.ac.at/corpus_shell/dataset"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns:utils="http://aac.ac.at/corpus_shell/utils"
  extension-element-prefixes="exsl xs xd utils">
  
  <xsl:import href="solr-utils.xsl"/>
  
  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p><xd:b>Created on:</xd:b> 2012-09-26</xd:p>      
      <xd:p><xd:b>Author:</xd:b> m</xd:p>
      <xd:p>sub-stylesheet (of <xd:ref name="amc.xsl"></xd:ref>) transforming solr facet data to the internal representation (&lt;dataset>) </xd:p>
      <xd:p><xd:b>modified on:</xd:b> 2012-11-23</xd:p>
      <xd:p>added processing for stats-result </xd:p>
    </xd:desc>
  </xd:doc>
  
  <xsl:output method="xml" indent="yes" omit-xml-declaration="no"
    media-type="text/xml; charset=UTF-8" encoding="utf-8" />

  
  <xsl:template match="/" >
    <xsl:call-template name="preprocess" />
  </xsl:template>
  
  
  <xd:doc>
    <xd:desc>
      <xd:p>check if already preprocessed</xd:p>
    </xd:desc>
  </xd:doc>
  <xsl:template name="preprocess">
    <xsl:choose>
      <xsl:when test="/response">
        <xsl:call-template name="preprocess-solr-response" />
      </xsl:when>
      <xsl:otherwise>
         <xsl:copy-of select="/"></xsl:copy-of>
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template>
  
  <xsl:template name="preprocess-solr-response">
    <!--<result>
    reldata:<xsl:value-of select="$reldata" />-->
    
    
    <xsl:variable name="resolved-result">
      <xsl:call-template name="resolve-qx"></xsl:call-template>
    </xsl:variable>
    
    
    <xsl:variable name="datasets">
      <xsl:choose>
        <xsl:when test="//*[contains(@name,'baseq')] or $reldata=1">
          <xsl:call-template name="data2reldata">
            <xsl:with-param name="query-data" select="$resolved-result//ds:dataset"></xsl:with-param>
          </xsl:call-template>                
        </xsl:when>
        <xsl:when test="//str[@name = 'facet.pivot']">                
          <xsl:call-template name="pivot2data" >
          </xsl:call-template>  
        </xsl:when>
        <xsl:otherwise>
          <!--<xsl:call-template name="qx2data"></xsl:call-template>-->
          <xsl:copy-of select="$resolved-result//ds:dataset" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:variable name="numberOfRecords" select="//result/@numFound" />
    
    <xsl:variable name="numberOfHits " >
        <xsl:call-template name="compute-hits">
          <xsl:with-param name="response" select="//response"></xsl:with-param>
        </xsl:call-template>  
    </xsl:variable>
    
    <xsl:variable  name="count_datasets" select="count($datasets/*)" />
<!--    DEBUG-ns: <xsl:value-of select="namespace-uri($datasets/ds:dataset[1])"></xsl:value-of>-->
    <result dataset_count="{$count_datasets}" type="{if ($count_datasets &gt; 1) then 'multiresult' else ''}"
      numFound="{$numberOfRecords}" numHits="{$numberOfHits}">
      <xsl:copy-of select="$params"></xsl:copy-of>
        <xsl:copy-of select="$datasets"></xsl:copy-of>
      <!-- copy in the hits -->
      <xsl:copy-of select="$resolved-result//result[@name='response']" />
      </result>
  
  </xsl:template>

<xsl:template name="compute-hits">
  <xsl:param name="response" select="//response"></xsl:param>
  <xsl:variable name="maxScore" select="$response//result/@maxScore" />
  <xsl:variable name="countRecords" select="$response//@numFound" />
  
  <!-- only process if maxScore present - this is still not very reliable! --> 
  <xsl:if test="exists($maxScore)" >
    <xsl:variable name="countRows" select="count($response//result/doc/*[@name='score'])" />
    <xsl:variable name="minScore" select="$response//result/doc[position()=last()]/*[@name='score']" />
    
    <xsl:variable name="sumScore" select="sum($response//result/doc/*[@name='score'])" />
    
    <xsl:variable name="scoreRatio" select="$minScore div $maxScore" />
    <xsl:variable name="minScoreRatioed" select="$minScore * $scoreRatio" />
    
    <xsl:variable name="estimatedRestScoreSum" select="
      if ($minScoreRatioed &lt; 1) then ($countRecords - $countRows) 
      else    $minScoreRatioed * ($countRecords  - $countRows)" />
    <xsl:message>
      minScore:<xsl:value-of select="$minScore"></xsl:value-of>
      minScoreRatioed:<xsl:value-of select="$minScoreRatioed"></xsl:value-of>
      estimatedRestScoreSum:<xsl:value-of select="$estimatedRestScoreSum"></xsl:value-of>
    </xsl:message>
    <xsl:value-of select="$sumScore + $estimatedRestScoreSum"></xsl:value-of>
  </xsl:if>
  
</xsl:template>
  
  
  <xd:doc>
    <xd:desc>
      <xd:p>resolves multiple queries (based on the <xd:b>qx</xd:b> parameter) with  subrequests </xd:p> 
      <xd:p>it creates a multiresult out of the original result and the results of the subrequests.</xd:p>
    </xd:desc>
    <xd:param name="qx">additional queries</xd:param>
    <xd:param name="params">all the parameters of the original result, to be reused in the subrequest</xd:param>
  </xd:doc>
  <xsl:template name="resolve-qx" >
    <!--<xsl:param name="qx" select="//*[@name='qx']" />
    <xsl:param name="qxkey" select="//*[@name='qxkey']" />-->
    <xsl:param name="qx" select="//*[@name='qx']" />
    <xsl:param name="qxkey" select="//*[@name='qxkey']" />
<!--    <xsl:param name="qxkey" select="utils:params('qxkey',())" />-->
    <xsl:param name="params" select="$params" />
    
    <xsl:variable name="q-list" >
      <xsl:apply-templates select="$qx" mode="arrayize" />
    </xsl:variable>
    
    <xsl:variable name="qkey-list" >
      <xsl:apply-templates select="$qxkey" mode="arrayize" />
    </xsl:variable>
    
    
    <xsl:variable name="multiresult">
      <result type="multi">
        <!-- put the original (got via param q) result itself into the multiresult -->
        <xsl:copy-of select="/"/>
        
        <!-- run the other queries (qx) as separate requests and collect the sub-results -->
        <!--        <xsl:message><xsl:copy-of select="$q-list" /> </xsl:message>-->
        <!--        <xsl:for-each select="exsl:node-set($q-list)/*" >-->
        <xsl:for-each select="$q-list/*" >
        
        <!-- try to match qkeys based on their position - hoping for parallel ordering of qx and qxkey -->
           <xsl:variable name="curr_pos" select="position()" />
          <xsl:variable name="qkey" select="$qkey-list/*[not(.='')][position()=$curr_pos]"></xsl:variable>
<!--                  <xsl:message><xsl:copy-of select="." /> DEBUGqxkey1:<xsl:copy-of select="$qkey-list/*" /></xsl:message>-->
          <xsl:call-template name="subrequest">
            <xsl:with-param name="q" select="."></xsl:with-param>
            <xsl:with-param name="qkey" select="$qkey"></xsl:with-param>
          </xsl:call-template>  		      
        </xsl:for-each>
      </result>
    </xsl:variable>

    <result type="multi">
     <xsl:call-template name="result2dataset-wrapper">
       <xsl:with-param name="result" select="$multiresult"></xsl:with-param>
     </xsl:call-template>
      
      <!-- copy-in the hit-results  --> 
      <xsl:for-each select="$multiresult//result[@name='response']"  >
          <xsl:copy>
            <xsl:copy-of select="@*"></xsl:copy-of>
            <!-- copy-in the params from response -->
            <xsl:copy-of select="../lst[@name='responseHeader']" />
            <xsl:copy-of select="*"></xsl:copy-of>
            <!-- copy-in the highlighting sectino -->
            <xsl:copy-of select="../lst[@name='highlighting']" />
          </xsl:copy>
      </xsl:for-each>
    </result>

  </xsl:template>
  
  
  <xd:doc>
    <xd:desc>
      <xd:p>should be OBSOLETED by resolve-qx now </xd:p> 
        <xd:p>Generates a dataset with multiple queries (based on the <xd:b>qx</xd:b> parameter).</xd:p> 
      <xd:p>First it creates a multiresult out of the original result and the results of the subrequests 
        then lets convert the multiresult into a dataset representation.</xd:p>
    </xd:desc>
    <xd:param name="qx">additional queries</xd:param>
    <xd:param name="params">all the parameters of the original result, to be reused in the subrequest</xd:param>
  </xd:doc>
  <xsl:template name="qx2data" >
    <xsl:param name="qx" select="//*[contains(@name,'qx')]" />
    <xsl:param name="params" select="//lst[@name='params']" />

    <xsl:variable name="multiresult">
      <xsl:call-template name="resolve-qx">
        <xsl:with-param name="qx" select="$qx" />
        <xsl:with-param name="params" select="$params" />
      </xsl:call-template>
    </xsl:variable>
    
    <xsl:call-template name="result2dataset-wrapper">
      <xsl:with-param name="result" select="$multiresult"></xsl:with-param>
    </xsl:call-template>
    
  </xsl:template>
  
    
  <xd:doc >
    <xd:desc>
      <xd:p>preprocess the data from pivot-facets into a table-structure</xd:p>
      <xd:p>facet1 is mapped to dataseries</xd:p>
      <xd:p>Although solr's <xd:i>pivot.facet</xd:i> allows pivoting more than two facets, 
        this template works only for two facets. However they can be explicitely set (<xd:ref name="facet1" type="parameter" />, <xd:ref name="facet2" type="parameter" />).</xd:p>
      <xd:p>all the parameters are optional, by default the template works with the original input document (<xd:ref name="source-data" type="parameter" />)
      and derives all parameters from there.</xd:p>
    </xd:desc>
    
  </xd:doc>
  <xsl:template name="pivot2data">
    <xsl:param name="source-data" select="/"></xsl:param>    
    <xsl:param name="invert" select="false()"></xsl:param>    
<!--    <xsl:param name="pivot-fields" select="$source-data//str[@name = 'facet.pivot']/text()" ></xsl:param>-->
    <xsl:param name="pivot-fields" select="$source-data/response/lst[@name = 'facet_counts']/lst[@name = 'facet_pivot']/arr/@name" ></xsl:param>    
    <!-- use qkey as -->
    <xsl:param name="query" select="($source-data//lst[@name='params']/*[@name='qkey'],$source-data//lst[@name='params']/*[@name='q'])[1]" ></xsl:param>    
    <xsl:param name="facet1" >
      <xsl:choose>
        <xsl:when test="$invert">
          <xsl:value-of select="substring-after($pivot-fields,',')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="substring-before($pivot-fields,',')"/>
        </xsl:otherwise>        
      </xsl:choose>       
    </xsl:param>
    <xsl:param name="facet2" >
        <xsl:choose>
          <xsl:when test="$invert">
            <xsl:value-of select="substring-before($pivot-fields,',')"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="substring-after($pivot-fields,',')"/>
          </xsl:otherwise>        
        </xsl:choose> </xsl:param>      
    <xsl:param name="facet1-list" >
      <xsl:for-each select="$source-data/response/lst[@name = 'facet_counts']/lst[@name = 'facet_fields']/lst[@name=$facet1]/int">
        <xsl:sort select="@name" />
        <xsl:copy-of select="."/>
      </xsl:for-each>
    </xsl:param>    
    <xsl:param name="facet2-list" >
      <xsl:for-each select="$source-data/response/lst[@name = 'facet_counts']/lst[@name = 'facet_fields']/lst[@name=$facet2]/int">
        <xsl:sort select="@name" />
        <xsl:copy-of select="."/>
      </xsl:for-each>
    </xsl:param>    
    <xsl:param name="pivot-data" select="$source-data/response/lst[@name = 'facet_counts']/lst[@name = 'facet_pivot']/arr" />

    <ds:dataset name="{$pivot-fields}-{utils:normalize($query)}" label="{$pivot-fields} {$query}">
      <xsl:call-template name="facets2labels">
        <xsl:with-param name="facet-list" select="$facet2-list"></xsl:with-param>
      </xsl:call-template>
      <xsl:call-template name="facets2dataseries">
        <xsl:with-param name="facet-list" select="$facet2-list"></xsl:with-param>
        <xsl:with-param name="all-value" select="$source-data//result/@numFound"></xsl:with-param>
      </xsl:call-template>      
      <xsl:apply-templates select="$pivot-data" mode="pivot">
        <xsl:with-param name="dataseries" select="$facet1"></xsl:with-param>
        <xsl:with-param name="labels" select="$facet2"></xsl:with-param>
         <xsl:with-param name="dataseries-list" select="$facet1-list"></xsl:with-param>
        <xsl:with-param name="labels-list" select="$facet2-list"></xsl:with-param>
        <xsl:with-param name="pivot-fields" select="$pivot-fields"></xsl:with-param>
      </xsl:apply-templates>
    </ds:dataset>
    
  </xsl:template>    
  
  <xd:doc>
    <xd:desc>
      <xd:p>generates labels for the dataset out of a facet-list</xd:p>
    </xd:desc>
    <xd:param name="facet-list"></xd:param>
  </xd:doc>
  <xsl:template name="facets2labels">
    <xsl:param name="facet-list"></xsl:param>    
    <ds:labels>  
      <ds:label><xsl:value-of select="$all-label" /></ds:label>
      <xsl:for-each select="exsl:node-set($facet-list)/*" >
        <ds:label><xsl:value-of select="if(xs:string(@name)='') then '_EMPTY_' else translate(xs:string(@name),'~ ','__')" /></ds:label>        
      </xsl:for-each>      
    </ds:labels>
  </xsl:template>
  
  
  <xd:doc>
    <xd:desc>
      <xd:p>generates a dataseries out of a facet-list</xd:p>
    </xd:desc>
    <xd:param name="dataseries-title"></xd:param>
    <xd:param name="facet-list"></xd:param>
    <xd:param name="all-value">value for the first column (all), normally result/@numFound</xd:param>
  </xd:doc>
  <xsl:template name="facets2dataseries" >
    <xsl:param name="dataseries-title" >all</xsl:param>
    <xsl:param name="facet-list"></xsl:param>
    <xsl:param name="all-value" select=".//result/@numFound"></xsl:param>
    
    <ds:dataseries name="{$dataseries-title}">
        <ds:value label="{$all-label}" formatted="{utils:format-number($all-value,$number-format-default)}" >
          <xsl:value-of select="$all-value"/>
        </ds:value>
      <xsl:for-each select="$facet-list/*" >
        <ds:value label="{if(xs:string(@name)='') then '_EMPTY_' else translate(xs:string(@name),'~ ','__')}" formatted="{utils:format-number(.,$number-format-default)}" >
          <xsl:value-of select="." />
        </ds:value>
      </xsl:for-each>    
      </ds:dataseries>
    
  </xsl:template>
    
  <xd:doc >
    <xd:desc>
      <xd:p>default pivot, normal facet-ordering starting on first level </xd:p>
    </xd:desc>
    <xd:param name="facet1-list"></xd:param>
    <xd:param name="facet2-list"></xd:param>
  </xd:doc>
  <xsl:template match="arr/lst" mode="pivot">
    <xsl:param name="facet2-list"></xsl:param>
    
    <ds:dataseries name="{*[@name = 'value']}" >        
      <ds:value label="{$all-label}" formatted="{utils:format-number(*[@name = 'count'],$number-format-default)}" >
        <xsl:value-of select="*[@name = 'count']"/>
      </ds:value>        
      
      <xsl:variable name="curr_facet" select="." />
      <xsl:for-each select="exsl:node-set($facet2-list)/*">
        <xsl:variable name="curr_label" select="@name"></xsl:variable>
        <xsl:variable name="count" select="$curr_facet/arr[@name='pivot']/lst[*[@name='value'][.=$curr_label]]/*[@name='count']" />
        <ds:value label="{$curr_label}" >
          <xsl:choose>
          <xsl:when test="number($count)=number($count)" > <!-- test if number -->             
            <xsl:attribute name="formatted" ><xsl:value-of select="utils:format-number($count,$number-format-default)" /></xsl:attribute>
            <xsl:value-of select="$count" />
          </xsl:when>
            <xsl:otherwise>               
              <xsl:attribute name="formatted" ><xsl:value-of select="'-'" /></xsl:attribute>
              <xsl:value-of select="0" />
            </xsl:otherwise>
          </xsl:choose>
        </ds:value>
      </xsl:for-each>      
    </ds:dataseries>
  
  </xsl:template>



  <xd:doc >
    <xd:desc>
      <xd:p>custom pivot, plot any two facets</xd:p>
    </xd:desc>
    <xd:param name="facet1"></xd:param>
    <xd:param name="facet2"></xd:param>
    <xd:param name="facet1-list"></xd:param>
    <xd:param name="facet2-list"></xd:param>
    <xd:param name="pivot-fields"></xd:param>
  </xd:doc>
  <xsl:template match="arr" mode="pivot">
    <xsl:param name="dataseries"  />
    <xsl:param name="labels" />
    <xsl:param name="dataseries-list"></xsl:param>
    <xsl:param name="labels-list"></xsl:param>
    <xsl:param name="pivot-fields" select="../@name"></xsl:param>    
    <xsl:param name="pivot-data" select="."></xsl:param>
    
    <xsl:for-each select="exsl:node-set($dataseries-list)/*" >      
        
      <xsl:variable name="curr_dataseries" select="string(@name)" />
      
      <ds:dataseries name="{@name}" >        
      <ds:value label="{$all-label}" formatted="{utils:format-number(.,$number-format-default)}" >
        <xsl:value-of select="."/>
      </ds:value>        
      
        <xsl:for-each select="exsl:node-set($labels-list)/*">
          <xsl:variable name="curr_label" select="string(@name)"></xsl:variable>
          <xsl:variable name="count" select="$pivot-data//lst[ancestor-or-self::lst[str[@name='field']=$dataseries and str[@name='value']= $curr_dataseries]]
                        [ancestor-or-self::lst[str[@name='field']=$labels and str[@name='value']= $curr_label]]/int[@name='count']" />
<!--            $curr_facet/arr[@name='pivot']/lst[*[@name='value'][.=$curr_label]]/*[@name='count']" />-->
          <ds:value label="{$curr_label}" >
            <xsl:choose>
              <xsl:when test="number($count)=number($count)" > <!-- test if number -->             
                <xsl:attribute name="formatted" ><xsl:value-of select="utils:format-number($count,$number-format-default)" /></xsl:attribute>
                <xsl:value-of select="$count" />
              </xsl:when>
              <xsl:otherwise>               
                <xsl:attribute name="formatted" ><xsl:value-of select="'-'" /></xsl:attribute>
                <xsl:value-of select="0" />
              </xsl:otherwise>
            </xsl:choose>
          </ds:value>
        </xsl:for-each>      
      </ds:dataseries>
    </xsl:for-each>
    
  </xsl:template>
  
  
  <xd:doc>
    <xd:desc>
      <xd:p>checks if the result isn't already dataset and if not invokes actual transformation result2dataset, result-stats2dataset</xd:p>
      <xd:p>also strips any wrapping xml from around multiresult/dataset</xd:p>
    </xd:desc>
    <xd:param name="result">result, multiresult or dataset</xd:param>
    <xd:param name="params"></xd:param>
  </xd:doc>
  <xsl:template name="result2dataset-wrapper">
    <xsl:param name="result"></xsl:param>
    <xsl:param name="params" select="($result//lst[@name='params'])[1]" />
  
    <xsl:choose>
      <!--  should be obsolete     
      <xsl:when test="exists($result//result/dataset)">
        <xsl:copy-of select="$result//result"></xsl:copy-of>
      </xsl:when>
        -->
      <xsl:when test="exists($result//ds:dataset)">
        <xsl:copy-of select="$result//ds:dataset"></xsl:copy-of>
      </xsl:when>
      <xsl:otherwise>
        
        <xsl:variable name="datasets">
          <xsl:call-template name="result2dataset">
            <xsl:with-param name="result" select="$result"></xsl:with-param>
          </xsl:call-template>
          <xsl:call-template name="result-stats2dataset">
            <xsl:with-param name="result" select="$result"></xsl:with-param>
          </xsl:call-template>
        </xsl:variable>
        
        <xsl:copy-of select="$datasets"></xsl:copy-of>
        
        <!-- if more then one dataset wrap with <multiresult> 
        moved to calling template -->
        <!--<xsl:choose>
          <xsl:when test="count($datasets/*) &gt; 1">
            <multiresult>
              <xsl:copy-of select="$datasets"></xsl:copy-of>
            </multiresult>
          </xsl:when>
          <xsl:otherwise>
            <xsl:copy-of select="$datasets"></xsl:copy-of>
          </xsl:otherwise>
        </xsl:choose>
        -->
      </xsl:otherwise>    
    </xsl:choose>
 
  </xsl:template>


  <xd:doc>
    <xd:desc>
      <xd:p>transforms solr result to internal dataset format</xd:p>
    </xd:desc>
    <xd:param name="result">full result, can be multiresult</xd:param>
    <xd:param name="params"></xd:param>
  </xd:doc>
  <xsl:template name="result2dataset">
    <xsl:param name="result"></xsl:param>
    <xsl:param name="params" select="($result//lst[@name='params'])[1]" />
    
    <xsl:variable name="facet-list" >
      <xsl:apply-templates select="exsl:node-set($params)/*[@name='facet.field']" mode="arrayize" />
    </xsl:variable>
    
    <!-- DEBUG: <xsl:copy-of select="$facet-list" />-->
    
    <!-- inverting results and facets -->
    <!-- create a dataset for every facet -->
    
    <xsl:for-each select="exsl:node-set($facet-list)/*">
      <xsl:variable name="curr_facet" select="." />            
      <ds:dataset name="{$curr_facet}">
        <xsl:call-template name="facets2labels">
          <xsl:with-param name="facet-list" >
            <!-- take first (the original) result as base for the labels -->
            <xsl:for-each select="exsl:node-set($result)//response[1]/lst[@name = 'facet_counts']/lst[@name = 'facet_fields']/lst[@name=$curr_facet]/int">
              <xsl:sort select="lower-case(@name)" />
              <xsl:copy-of select="."/>
            </xsl:for-each>
          </xsl:with-param>
        </xsl:call-template>
        
        <!-- and a dataseries for every response -->               
        <xsl:for-each select="exsl:node-set($result)//response">
          <!-- TODO: facets not aligned! -->                   
          <xsl:variable name="curr_facet_list" >                       
            <xsl:for-each select="lst[@name = 'facet_counts']/lst[@name = 'facet_fields']/lst[@name=$curr_facet]/int">
              <xsl:sort select="@name" />
              <xsl:copy-of select="."/>
            </xsl:for-each>
          </xsl:variable>
          <xsl:call-template name="facets2dataseries">        		        
            <!-- prefer qkey as name of the dataseries -->
            <xsl:with-param name="dataseries-title" select="(.//lst[@name='params']/*[@name='qkey'], .//lst[@name='params']/*[@name='q'])[1]"></xsl:with-param>
            <xsl:with-param name="facet-list" select="$curr_facet_list"></xsl:with-param>    
            <xsl:with-param name="all-value" select=".//result/@numFound"></xsl:with-param>
          </xsl:call-template>
        </xsl:for-each>
      </ds:dataset>		    
    </xsl:for-each>
    
  </xsl:template>  
  

  <xd:doc>
    <xd:desc>
      <xd:p>transforms solr stats-result to internal dataset format</xd:p>
      <xd:p>- processes only stats-data (if stats.facet-field and lst@stats is present)</xd:p>
    </xd:desc>
    <xd:param name="result">full result, can be multiresult</xd:param>
    <xd:param name="params"></xd:param>
  </xd:doc>
  <xsl:template name="result-stats2dataset">
    <xsl:param name="result"></xsl:param>
    <xsl:param name="params" select="($result//lst[@name='params'])[1]" />
    
    <xsl:variable name="facet-field-list" >
      <xsl:apply-templates select="exsl:node-set($params)/*[@name='stats.facet']" mode="arrayize" />
    </xsl:variable>
    
<!--     DEBUG: <xsl:copy-of select="$facet-list" />-->
    
    
    <!-- create a dataset for every facet -->
    
        <xsl:for-each select="exsl:node-set($facet-field-list)/*">
          <xsl:variable name="curr_facet" select="." />
          
          <!-- take first result (of first stat.field) as base for the labels -->
          <xsl:variable name="facet-value-list">
            <xsl:for-each select="exsl:node-set($result)//response[1]/lst[@name = 'stats']/*/lst[1]/lst[@name = 'facets']/lst[@name=$curr_facet]/lst">
              <xsl:sort select="@name" />
              <xsl:copy-of select="."/>
            </xsl:for-each>
          </xsl:variable>
          
          <ds:dataset name="{$curr_facet}">
            <xsl:call-template name="facets2labels">
              <xsl:with-param name="facet-list" select="$facet-value-list" >        
              </xsl:with-param>
            </xsl:call-template>
            
            <!-- and a dataseries for every response -->               
            <xsl:for-each select="exsl:node-set($result)//response">
              <!-- TODO: facets not aligned! -->
              <!-- and a dataseries for every metrics in the response (min, max, sum...) -->
              <xsl:variable name="metrics" select="distinct-values(lst[@name = 'stats']/*/lst[1]/lst[@name = 'facets']/lst[@name=$curr_facet]/lst/(double|long)/@name)[.=$statsx_metrics or $statsx_metrics='all'] " ></xsl:variable>
              
              <!-- where the stat-fields data starts -->
              <xsl:variable name="stats-data" select="lst[@name = 'stats']/*/lst" />
              
              <!-- iterate over stat-fields -->
              <xsl:for-each select="lst[@name = 'stats']/*/lst">
                <xsl:variable name="curr_field" select="@name" />
<!--                DEBUG:<xsl:value-of select="concat($curr_facet, '-', $curr_field, '-', $metrics)"></xsl:value-of>-->
                
                <xsl:for-each select="$metrics">
                  <xsl:variable name="curr_metric" select="." />
                 
                 <xsl:call-template name="facets2dataseries">        		        
                   <xsl:with-param name="dataseries-title" select="concat($curr_field,'-',$curr_metric)"></xsl:with-param>
                   <!-- unifying to the usual structure (element with facet-key in @name-attribute and facet-value as element value --> 
                   <xsl:with-param name="facet-list" >
                     <xsl:for-each select="$stats-data[@name=$curr_field]/lst[@name = 'facets']
                                          /lst[@name=$curr_facet]/lst/(double|long)[@name=$curr_metric]">
                       <ds:value name="{../@name}"><xsl:value-of select="." /></ds:value>
                     </xsl:for-each> 
                   </xsl:with-param>    
                   <xsl:with-param name="all-value" select="$stats-data[@name=$curr_field]/*[@name=$curr_metric]"></xsl:with-param>
                 </xsl:call-template>
                </xsl:for-each>
              </xsl:for-each>
            </xsl:for-each>
          </ds:dataset>		    
        </xsl:for-each>
     
  </xsl:template>  
  
  
  <xd:doc >
    <xd:desc>
      <xd:p>if a base-query (<xd:ref name="baseq" type="parameter" />) is provided, enrich the query-data with relative frequencies</xd:p>            
    </xd:desc>
    <xd:param name="query-data">expects the result already preprocessed in the internal <xd:ref>dataset</xd:ref>-representation </xd:param>
    <xd:param name="base-query">the base-query (will be resolved in a separate subrequest call)</xd:param>
  </xd:doc>
  <xsl:template name="data2reldata">
    <xsl:param name="query-data" >
      <xsl:call-template name="result2dataset-wrapper">
        <xsl:with-param name="result" select="/" />             
      </xsl:call-template>
    </xsl:param>
    <xsl:param name="base-query" select="//*[contains(@name,'baseq')]" />
    
    <xsl:variable name="base-call1">            
      <xsl:choose>
        <xsl:when test="exists($base-query)" >
          <xsl:call-template name="subrequest">
            <xsl:with-param name="q" select="$base-query" />
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:copy-of select="()"></xsl:copy-of>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <!--  retrieve base-result via subrequest -->
<!--    <xsl:variable name="base-result" >
      <xsl:call-template name="subrequest">
        <xsl:with-param name="link" select="$default-base-data-path" />
      </xsl:call-template>
    </xsl:variable>-->
    <xsl:variable name="base-result" >
      <!-- allow for fall-back on the cached default-base-data  -->
      <xsl:choose>
        <xsl:when test="$base-call1/*">
<!--        <xsl:when test="$reldata=1"> <!-\- not reliable!! testing-\-> -->
          <xsl:copy-of select="$base-call1" />

        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="subrequest">
            <xsl:with-param name="link" select="$default-base-data-path" />
          </xsl:call-template>          
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:variable name="base-dataset" >           
      <xsl:call-template name="result2dataset-wrapper">
        <xsl:with-param name="result" select="$base-result" />
      </xsl:call-template>
    </xsl:variable>
    
    <xsl:variable name="datasets">
     <xsl:apply-templates select="exsl:node-set($query-data)" mode="reldata">
       <xsl:with-param name="base-data" select="exsl:node-set($base-dataset)"></xsl:with-param>
     </xsl:apply-templates>
    </xsl:variable>
   
   <xsl:copy-of select="$datasets"></xsl:copy-of>
 
  </xsl:template>
  
  
  <xsl:template match="ds:dataset" mode="reldata">        
    <xsl:param name="data" select="."></xsl:param>
    <xsl:param name="base-data" ></xsl:param>
    
    <xsl:variable name="dataset-name" select="xs:string(exsl:node-set($data)/@name)" />
    <ds:dataset name="{$dataset-name}" type="reldata" percentile-unit="{$percentile-unit}">            
      <!-- copy the labels of the original dataset -->
      <xsl:copy-of select="exsl:node-set($data)/ds:labels"/>
      <!-- at the dataseries from the base dataset -->
      <xsl:variable name="base-dataseries" >
        <xsl:variable name="orig-base-dataseries" select="$base-data//ds:dataset[@name=$dataset-name]/ds:dataseries"/>
        <ds:dataseries name="{$orig-base-dataseries/@name}" type="base" >
          <xsl:for-each select="$orig-base-dataseries/*" >
            <xsl:sort select="@label" />
            <xsl:copy-of select="." />
          </xsl:for-each>
        </ds:dataseries>                
      </xsl:variable>            
      <xsl:copy-of select="$base-dataseries" >                
      </xsl:copy-of>
      
      <!-- run through the datasets dataseries adding the relative values -->
      <xsl:apply-templates select="exsl:node-set($data)/ds:dataseries" mode="reldata">
        <xsl:with-param name="base-data" select="$base-dataseries"></xsl:with-param>     
      </xsl:apply-templates>
    </ds:dataset>
    
  </xsl:template>
  
  <xsl:template match="ds:dataseries" mode="reldata">
    <xsl:param name="base-data" ></xsl:param>
    <ds:dataseries name="{@name}" type="reldata">
      <xsl:apply-templates mode="reldata">
        <xsl:with-param name="base-data"  select="$base-data"></xsl:with-param>
      </xsl:apply-templates>
    </ds:dataseries>        
  </xsl:template>
  
  <xsl:template match="ds:value" mode="reldata">
    <xsl:param name="base-data" ></xsl:param>
    
    <xsl:variable name="base-value" select="exsl:node-set($base-data)//ds:value[@label=current()/@label]"/>
    <xsl:variable name="relfreq" select=". div $base-value"/>        
    <ds:value label="{@label}"  formatted="{@formatted}" abs="{.}" rel="{$relfreq}" 
      rel_formatted="{utils:format-number($relfreq * $percentile-base, $number-format-dec)}">
      <xsl:value-of select="round($relfreq * $percentile-base * $decimal-base) div $decimal-base"/>
      </ds:value>
    
  </xsl:template>
  
 

</xsl:stylesheet>

