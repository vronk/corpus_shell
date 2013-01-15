<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
  xmlns:exsl="http://exslt.org/common"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" 
  extension-element-prefixes="exsl xd">
  <!--<xsl:import href="amc-params.xsl"  />
  <xsl:import href="amc-helpers.xsl"  />-->
  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p><xd:b>Created on:</xd:b> 2012-09-26</xd:p>
      <xd:p><xd:b>Author:</xd:b> m</xd:p>
      <xd:p>sub-stylesheet to produce google-chart out of the internal dataset-representation</xd:p>
    </xd:desc>
  </xd:doc>
  
  <!--<xsl:output method="text" indent="yes" omit-xml-declaration="no"
    media-type="application/json; charset=UTF-8" encoding="utf-8" />-->

  
  <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
    <xd:desc>
      <xd:p>generate a json-object out of the facet-list provided as parameter and add all scripts (js, css) necessary for the visualization</xd:p>
      <xd:p>the chart will be generated inside a div#infovis </xd:p>
      <xd:p>expects div#infovis and still need to invoke init()-function (onload or onclick somewhere) </xd:p>
    </xd:desc>
  </xd:doc>
  

  
  
  <xsl:template name="chart-google" >
    <xsl:param name="data" ></xsl:param>
    
    <xsl:variable name="json-data">
      <xsl:apply-templates select="exsl:node-set($data)" mode="data2chart-google" >
<!--        <xsl:with-param name="data" select="$data" ></xsl:with-param>-->
      </xsl:apply-templates>
    </xsl:variable>
    
    <script type="text/javascript" src="{concat($scripts-dir, 'google-jsapi.js')}"></script>
    <script type="text/javascript">
      // allow for multiple datasets (for every facet)
        var data_arr = [<xsl:copy-of select="$json-data"/>];
      
      var curr_stacked =true;
      var curr_layout ='pie';
      var chart = null;
      var curr_chart_ix = 0;
      
        
      google.load("visualization", "1", {packages:["corechart"]});
      //google.setOnLoadCallback(drawChart(0));
      function drawChart(data_ix = curr_chart_ix, options = getOptions(curr_stacked)) {        
        
        curr_chart_ix=data_ix;        
        
        var data = google.visualization.arrayToDataTable(data_arr[data_ix]);
        if (options["layout"]=='pie') {
          chart = new google.visualization.PieChart(document.getElementById('infovis'));
          chart.draw(data, options);
        } else {
          chart = new google.visualization.AreaChart(document.getElementById('infovis'));
          chart.draw(data, options);
        }
      }
      
      function toggleStacked () {
        curr_stacked = !curr_stacked;
        drawChart(curr_chart_ix, getOptions(curr_stacked));
     }
     
     function toggleLayout() {
        if (curr_layout=='pie'){ curr_layout = 'area' } else { curr_layout='pie'};
        drawChart(curr_chart_ix, getOptions());
     }
     
      function getOptions(stacked) { 
        var options = {
            layout: curr_layout,
            title: '<xsl:value-of select="exsl:node-set($data)/dataset/@name" />',               
            isStacked: curr_stacked
          };
        return options; 
      }      
      
    </script>
    
  </xsl:template>
  
  
  <xsl:template match="dataset" mode="data2chart-google">
    <xsl:param name="data" select="."></xsl:param>
    
    <xsl:text>[</xsl:text>    
      <xsl:apply-templates select="exsl:node-set($data)" mode="chart-google"></xsl:apply-templates>
    <xsl:text>]</xsl:text>
    <xsl:if test="not(position()=last())">, 
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="dataset" mode="chart-google">
    <xsl:apply-templates mode="chart-google"></xsl:apply-templates>
  </xsl:template>
  
  <xsl:template match="labels" mode="chart-google">
    <xsl:text>['count', </xsl:text>
      <xsl:apply-templates mode="chart-google"></xsl:apply-templates>    
    <xsl:text>], </xsl:text>    
  </xsl:template>
  
  <xsl:template match="dataseries[not(@name='all' or @key='all')][value]" mode="chart-google">
    <xsl:text>['</xsl:text><xsl:value-of select="(@name,@label,@key)[1]" /><xsl:text>', </xsl:text>
    <xsl:apply-templates mode="chart-google"
        select="value[not(@key=current()/../labels/label[@type='base'])]"></xsl:apply-templates>    
    <xsl:text>]</xsl:text>
    <xsl:if test="not(position()=last())">, 
    </xsl:if>    
  </xsl:template>
  
  <xsl:template match="label[not(.='all')][not(@type='base')]" mode="chart-google">      
    <xsl:text>'</xsl:text><xsl:value-of select="." /><xsl:text>' </xsl:text>
    <xsl:if test="not(position()=last())">, </xsl:if>    
  </xsl:template>
  
  <xsl:template match="value[not(@label='all')][not(@type='base')]" mode="chart-google">      
    <xsl:value-of select="(@rel,@abs,.)[1]" />
    <xsl:if test="not(position()=last())">, </xsl:if>    
  </xsl:template>

<!-- default: discard -->
  <xsl:template match="*" mode="chart-google" />
 
</xsl:stylesheet>

