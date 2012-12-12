<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:msxsl="urn:schemas-microsoft-com:xslt" exclude-result-prefixes="msxsl"
    xmlns:sru="http://www.loc.gov/zing/srw/">
    <xsl:param name="uri"/>
    <xsl:param name="type"/>
    <xsl:param name="style"/>
  <xsl:output method="text" indent="no"/>
  <xsl:template match="/">
    <xsl:for-each select="sru:scanResponse/sru:terms/sru:term/sru:extraTermData/sru:terms/sru:term">
      <xsl:text>$configName["</xsl:text>
      <xsl:value-of select="sru:value"/>
      <xsl:text>"] = array(</xsl:text>
      <xsl:text>"endPoint" =&gt; "</xsl:text>
      <xsl:value-of select="$uri"/>
      <xsl:text>", </xsl:text>
      <xsl:text>"name" =&gt; "</xsl:text>
      <xsl:value-of select="sru:value"/>
      <xsl:text>", </xsl:text>
      <xsl:text>"displayText" =&gt; "</xsl:text>
      <xsl:value-of select="sru:displayTerm"/>
      <xsl:text>", </xsl:text>
      <xsl:text>"type" =&gt; "</xsl:text>
      <xsl:value-of select="$type"/>
      <xsl:text>", </xsl:text>
      <xsl:text>"style" =&gt; "</xsl:text>
      <xsl:value-of select="$style"/>
      <xsl:text>", </xsl:text>
      <xsl:text>"context" =&gt; "</xsl:text>
      <xsl:value-of select="substring-after(sru:value, concat(../../../sru:value,':'))"/>
      <xsl:text>");
    </xsl:text>
    </xsl:for-each>
  </xsl:template>
</xsl:stylesheet>
