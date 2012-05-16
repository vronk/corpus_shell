<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
    <!-- 
        <purpose> just provide a html-wrapper for given html-snippet</purpose>
        <params>
        <param name=""></param>
        </params>
        <history>
        <change on="2012-05-14" type="created" by="vr">from xml2view.xsl</change>
        
        </history>
        
    -->
    <xsl:import href="commons.xsl"/>
    <xsl:output method="html"/>
    <xsl:variable name="title" select="''"/>
    <xsl:template name="continue-root">
        <xsl:copy-of select="."/>
    </xsl:template>
</xsl:stylesheet>