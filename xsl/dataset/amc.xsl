<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:exsl="http://exslt.org/common"  xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" 
    extension-element-prefixes="exsl xd">
    
   <xsl:import href="solr2dataset.xsl"/>
    <!--<xsl:import href="dataset2table.xsl"/>
    <xsl:import href="dataset2google-json.xsl"/>-->
    <xsl:import href="dataset2view.xsl"/>
    <xsl:import href="solr-hits2html.xsl"/>
    
    
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b>  2012-09-28</xd:p>
            <xd:p><xd:b>Author:</xd:b> matej</xd:p>
            <xd:p>main stylesheet of the amc views, provides the html-boilerplate and calls the templates for actual processing of the data</xd:p>            
            <xd:p>(originally called <xd:ref>apa.xsl</xd:ref>)</xd:p>
            <xd:p>It processes the faceted results of any normal solr-request, but additionally it is able to treat specially two extra parameters:
                <xd:i>qx</xd:i> and <xd:i>baseq</xd:i>.</xd:p>
            <xd:p>If the result contains facets (<code>lst[@name='facet_fields']/lst</code>),
            they are displayed as separate table and chart.</xd:p>
            <xd:p>If the result contains pivot-facets (solr 4.x feature, <code>lst[@name = 'facet_pivot']</code>), 
            it is displayed as one table and one chart, with the values from the two (first) fields being spread out as rows and columns.</xd:p>
            <xd:p>If the request contained <xd:b>qx</xd:b> parameter, this parameter is used to call subrequests 
                from within xsl (with the <code>doc()</code> function), with the same parameters as the original request, 
                but with the value of the <xd:i>q</xd:i> parameter replaced by the value in the <xd:i>qx</xd:i> parameter.
                If multiple <xd:i>qx</xd:i> parameters are present, one subrequest for each value is called.
                All the results from the subrequests and the original result are combined into a <xd:b>multiresult</xd:b>, 
                which is transformed into a dataset for further unified processing</xd:p> 
            <xd:p>If the request contained <xd:b>baseq</xd:b> parameter, again a separate subrequest is made
                with the value of <xd:i>baseq</xd:i> parameter as <xd:i>q</xd:i> parameter and the result is used 
                as a base for computing relative frequencies for the <xd:ref name="chart-data">chart-data</xd:ref>.
                This is a separate subsequent step, applied already on the preprocessed internal representation, 
                i.e. it can be applied both on a simple result, pivot result or qx result.
                The post-processed result, contains both the absolute and relative frequencies (+ formatted versions) as attributes, 
                but the relative number is used as value of the <code>&lt;value/></code> element. Example:                
                <xd:pre><![CDATA[
 <dataseries name="haus">
   <value label="all" 
          formatted="1.153.332" 
          abs="1153332" 
          rel="0.04224215720642085"
          rel_formatted="42.242,16">
      42242.16
   </value>
  </dataseries>]]></xd:pre>
            </xd:p>
        </xd:desc>
    </xd:doc>
    
<!--<xsl:output method="xml" indent="yes" omit-xml-declaration="no"
        media-type="text/html; charset=UTF-8" encoding="utf-8" />
        doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN"
media-type="text/xhtml"
    <xsl:output method="xml" media-type="text/html" indent="yes" encoding="UTF-8"  />
-->    
    <xsl:output method="xhtml"  
        doctype-public="-//W3C//DTD XHTML 1.0 Transitional//
        EN" indent="yes"/>
    <xsl:preserve-space elements="script"/>
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>invokes appropriate template (<xd:ref name="pivot2data" type="template"></xd:ref> or <xd:ref name="qx2data" type="template"></xd:ref>) to generate a unified internal representation of the data 
                 (<xd:ref>dataset</xd:ref> nodeset in the <xd:ref>chart-data</xd:ref> variable), creates the html-boilerplate
                and calls the templates to produce the table and chart representation of the data.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="/">
        
        <xsl:variable name="chart-data">            
            <xsl:variable name="query-data">
                <xsl:choose>
                    <!-- pivot mode (take first two facets) -->
                    <xsl:when test="//str[@name = 'facet.pivot']">                
                        <xsl:call-template name="pivot2data" >
                            <!--<xsl:with-param name="facet1" >year</xsl:with-param>
                                <xsl:with-param name="facet2" >docsrc</xsl:with-param>-->
                        </xsl:call-template>  
                    </xsl:when>
                    <!-- multi query mode (n queries and one (first) facet -->
                    <!--<xsl:when test="//*[contains(@name,'qx')]">
                        <!-\-QX:<xsl:value-of select="//*[contains(@name,'qx')]"/>-\->  
                        <xsl:call-template name="qx2data" />
                    </xsl:when>-->
                    <xsl:otherwise>
                        <xsl:call-template name="qx2data" />                    
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <!-- if base query  add relative freqs --> 
            <xsl:choose>
                <!-- if incoming preprocessed data --> 
                <xsl:when test="/dataset or /result/dataset or /multiresult/dataset">
                    <xsl:copy-of select="/"/>
                </xsl:when>
                <xsl:when test="//*[contains(@name,'baseq')]">
                    <xsl:call-template name="data2reldata">
                        <xsl:with-param name="query-data" select="$query-data"></xsl:with-param>
                        <xsl:with-param name="base-query" select="//*[contains(@name,'baseq')]" />
                    </xsl:call-template>
                </xsl:when>
                
                <xsl:otherwise>
                    <xsl:copy-of select="$query-data"/>
                </xsl:otherwise>
            </xsl:choose>           
            
        </xsl:variable>
        
        <html xmlns="http://www.w3.org/1999/xhtml">
            <head>
                <link rel="stylesheet" type="text/css" href="{concat($scripts-dir, 'style/jquery.ui.resizable.css')}" />
                <link rel="stylesheet" type="text/css" href="{concat($scripts-dir, 'style/jquery.ui.all.css')}" />
                <link rel="stylesheet" type="text/css" href="{concat($scripts-dir, 'style/jquery/clarindotblue/jquery-ui-1.8.5.custom.css')}" />
                <link rel="stylesheet" type="text/css" href="{concat($scripts-dir, 'style/cmds-ui.css')}" />
                
                <!--table { border-collapse:collapse;  border:1px solid grey }
        td {padding: 3px; border:1px solid grey}-->
                <style type="text/css">
        
        div.infovis-wrapper {border: 1px solid grey; margin: 20px; padding: 5px; height:350px; width:800px;}
        .infovis {height: 90%; width: 100%;}
        .value { text-align: right; }
        </style> 
                <!--DEBUG: <xsl:apply-templates select="$chart-data" mode="invert" />
                DEBUG: <xsl:copy-of select="$chart-data" />-->
           
                <script type="text/javascript" src="{concat($scripts-dir, 'js/jquery/jquery.min.js')}"></script>
                <script type="text/javascript" src="{concat($scripts-dir, 'js/jquery/jquery-ui.min.js')}"></script>
             
                <!--currently not used
                    <xsl:if test="contains($parts,'table')">
                    <script type="text/javascript" src="{concat($scripts-dir, 'js/jquery/jquery.tablesorter.js')}"/>
                    <script type="text/javascript" src="{concat($scripts-dir, 'js/jquery/jquery.uitablefilter.js')}"/>
                </xsl:if>-->
                
                <xsl:if test="contains($parts,'chart')" >
                    <xsl:call-template name="callback-header-chart" />
                </xsl:if>
                
<!--                <script type="text/javascript" src="{concat($scripts-dir, 'js/amc.js')}"></script>-->
                
            </head>
            <body >
                <h1>amc search interface</h1>
                
                <xsl:call-template name="response-header"/>

<!--      DEBUG:               <xsl:copy-of select="$chart-data" />-->
    
<!--    DEBUG: parts:<xsl:value-of select="$parts" />-->
            <!-- displaying chart-data passed to dataset2view -->
                <xsl:for-each select="$chart-data">
                                <xsl:call-template name="continue-root"></xsl:call-template>
                </xsl:for-each>
                
                <xsl:if test="contains($parts,'hits') and exists(/response/result/doc)" >
                    <xsl:call-template name="hits"></xsl:call-template>
                </xsl:if>                    

            </body>
        </html>
    </xsl:template>
    
    
</xsl:stylesheet>

