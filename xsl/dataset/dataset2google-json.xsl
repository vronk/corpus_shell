<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:exsl="http://exslt.org/common" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    version="2.0" extension-element-prefixes="exsl xd xs">
  <!--<xsl:import href="amc-params.xsl"  />
  <xsl:import href="amc-helpers.xsl"  />-->
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p>
                <xd:b>Created on:</xd:b> 2012-09-26</xd:p>
            <xd:p>
                <xd:b>Author:</xd:b> m</xd:p>
            <xd:p>sub-stylesheet to produce google-chart out of the internal dataset-representation</xd:p>
        </xd:desc>
    </xd:doc>
  
  <!--<xsl:output method="text" indent="yes" omit-xml-declaration="no"
    media-type="application/json; charset=UTF-8" encoding="utf-8" />-->
    <xd:doc>
        <xd:desc>
            <xd:p>generate a json-object out of the facet-list provided as parameter and add all scripts (js, css) necessary for the visualization</xd:p>
            <xd:p>the chart will be generated inside a div#infovis </xd:p>
            <xd:p>expects div#infovis and still need to invoke init()-function (onload or onclick somewhere) </xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template name="chart-google">
        <xsl:param name="data"/>
        <xsl:variable name="json-data">
            <xsl:apply-templates select="$data" mode="data2chart-google">
<!--        <xsl:with-param name="data" select="$data" ></xsl:with-param>-->
            </xsl:apply-templates>
        </xsl:variable>
        <!-- try to guess appropriate layout, simply area-chart if two dimensional = more than one dataseries -->
        <xsl:variable name="layout" select="if (count($data//dataseries[not(@type='base')]) &gt; 1) then 'area' else 'pie' "/>
<!--        DEBUG:<xsl:value-of select="count($data//dataseries)" />-->
        <xsl:variable name="dataset-name" select="concat(@name,position())"/>
        <script type="text/javascript">
      
      // allow for multiple datasets (for every facet)
      data["<xsl:value-of select="$dataset-name"/>"] = google.visualization.arrayToDataTable(<xsl:copy-of select="$json-data"/>)
      options["<xsl:value-of select="$dataset-name"/>"] = {
                          layout: "<xsl:value-of select="$layout"/>",
                          title: '<xsl:value-of select="$dataset-name"/>'
                    }  
      
      google.setOnLoadCallback(drawChart('<xsl:value-of select="$dataset-name"/>'));
     
      <!--
      function toggleStacked () {
        curr_stacked = !curr_stacked;
        drawChart(curr_chart_ix, getOptions(curr_stacked));
     }-->
        </script>
    </xsl:template>
    
   
    <xd:doc>
        <xd:desc>
            <xd:p>to be called explicitely from dataset2view</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template name="callback-header-chart">
        <script type="text/javascript" src="{concat($scripts-dir, 'js/google-jsapi.js')}"/>
        <script type="text/javascript" src="{concat($scripts-dir, 'js/google-corechart.js')}"/>
        <script type="text/javascript">
                var data= {};
                var options = {}; 
                var chart = {};
      
      // copied locally instead as: google-corechart.js
      //google.load("visualization", "1", {packages:["corechart"]});
      
            function drawChart(dataset) {        
            var target_container_selector = "chart-" +  dataset;
            
               if (options[dataset]["layout"]=='pie') {
               chart[dataset] = new google.visualization.PieChart(document.getElementById(target_container_selector));
               chart[dataset].draw(data[dataset], options[dataset]);
               } else {
               chart[dataset] = new google.visualization.AreaChart(document.getElementById(target_container_selector));
               chart[dataset].draw(data[dataset], options[dataset]);
               }
            }
     
     function toggleLayout(dataset) {
        if (options[dataset]["layout"]=='pie') { options[dataset]["layout"] = 'area' } else { options[dataset]["layout"]='pie'};
        drawChart(dataset);
     }
      
    </script>
    </xsl:template>
    <xsl:template match="dataset" mode="data2chart-google">
        <xsl:param name="data" select="."/>
        <xsl:variable name="inverted-data">
            <xsl:apply-templates select="$data" mode="invert"/>
        </xsl:variable>
        <xsl:text>[</xsl:text>
        <xsl:apply-templates select="$inverted-data" mode="chart-google"/>
        <xsl:text>]</xsl:text>
        <xsl:if test="not(position()=last())">, 
    </xsl:if>
    </xsl:template>
    <xsl:template match="dataset" mode="chart-google">
        <xsl:apply-templates mode="chart-google"/>
    </xsl:template>
    <xsl:template match="labels" mode="chart-google">
        <xsl:text>['count', </xsl:text>
        <xsl:apply-templates mode="chart-google"/>
        <xsl:text>], </xsl:text>
    </xsl:template>
    <xsl:template match="dataseries[value]" mode="chart-google">
        <xsl:if test="not(xs:string(@name)=$all-label or @key=$all-label)" >
           <xsl:text>['</xsl:text>
           <xsl:value-of select="(@name,@label,@key)[1]"/>
           <xsl:text>', </xsl:text>
           <xsl:apply-templates mode="chart-google" select="value[not(@key=current()/../labels/label[@type='base'])]"/>
           <xsl:text>]</xsl:text>
           <xsl:if test="not(position()=last())">, 
    </xsl:if>
        </xsl:if>
    </xsl:template>
    <xsl:template match="label[not(.=$all-label)][not(@type='base')]" mode="chart-google">
        <xsl:text>'</xsl:text>
        <xsl:value-of select="."/>
        <xsl:text>' </xsl:text>
        <xsl:if test="not(position()=last())">, </xsl:if>
    </xsl:template>
    <xsl:template match="value[not(xs:string(@key)=$all-label)][not(@type='base')]" mode="chart-google">
        <xsl:value-of select="(@rel,@abs,.)[1]"/>
        <!--DEBUG:<xsl:value-of select="@key"/>-->
        <xsl:if test="not(position()=last())">, </xsl:if>
    </xsl:template>

<!-- default: discard -->
    <xsl:template match="*" mode="chart-google"/>
</xsl:stylesheet>