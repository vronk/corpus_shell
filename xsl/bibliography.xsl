<?xml version="1.0" encoding="iso-8859-1"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns="http://www.w3.org/1999/xhtml"
  exclude-result-prefixes="html xd">

    <xsl:output method="html"/>
    <xd:doc>
      <xd:desc></xd:desc>
    </xd:doc>
  <xsl:template match="/">
      <div class="profiletext">
        <xsl:for-each select="//biblStruct">
          <xsl:choose>
            <xsl:when test="analytic/author">
               <b><xsl:value-of select="analytic/author"/>:</b><i> <xsl:value-of select="analytic/title"/></i> in
               <i><xsl:value-of select="monogr/title"/></i>
            </xsl:when>
            
            <xsl:otherwise>
               <b><xsl:value-of select="monogr/author"/>:</b><i> <xsl:value-of select="monogr/title"/></i>
               <xsl:if test="monogr/imprint/pubPlace">. <xsl:value-of select="monogr/imprint/pubPlace"/></xsl:if>
               <xsl:if test="monogr/imprint/date"> <xsl:value-of select="monogr/imprint/date"/></xsl:if>
            </xsl:otherwise>
          </xsl:choose>
          <br/>
        </xsl:for-each>
      </div>
    </xsl:template>
</xsl:stylesheet>
