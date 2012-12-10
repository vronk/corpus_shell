<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
  xmlns:exsl="http://exslt.org/common"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  extension-element-prefixes="exsl xd">
  
  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p><xd:b>Created on:</xd:b> 2012-09-26</xd:p>
      <xd:p><xd:b>Author:</xd:b> m</xd:p>
      <xd:p>sub-stylesheet to produce a html table out of the internal dataset-representation</xd:p>
    </xd:desc>
  </xd:doc>


  <xsl:template match="dataset" mode="data2table">
    <xsl:param name="data" select="."></xsl:param>

        <table >
          <caption><xsl:value-of select="exsl:node-set($data)/@name"/></caption>
          <xsl:apply-templates select="exsl:node-set($data)" mode="table"></xsl:apply-templates>
        </table>
        
  </xsl:template>
  
  <xsl:template match="labels" mode="table">
   <thead>
     <tr><th>key</th>
      <xsl:apply-templates mode="table"></xsl:apply-templates></tr>
   </thead>
  </xsl:template>
  
  <xsl:template match="dataseries" mode="table">
    <tr><td><xsl:value-of select="@name" />
          <xsl:if test="@type='reldata'">
            <br/><xsl:value-of select="ancestor::dataset/@percentile-unit" />
          </xsl:if>
      </td>
      <xsl:apply-templates mode="table"></xsl:apply-templates>
    </tr>
  </xsl:template>
  
  <xsl:template match="label" mode="table">      
      <th> <xsl:value-of select="." /></th>    
  </xsl:template>
  
  <xsl:template match="value" mode="table">      
    <td class="value"> <xsl:value-of select="@abs" />
<!--      <xsl:value-of select="@formatted" />-->
<!--      <xsl:if test="@rel_formatted">
        <br/><xsl:value-of select="@rel_formatted" />
      </xsl:if>-->
    </td>    
  </xsl:template>
  
  
</xsl:stylesheet>

