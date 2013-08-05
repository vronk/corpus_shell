<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
    <!-- 
        <purpose> generate a generic html-view for xml </purpose>
        <params>
        <param name=""></param>
        </params>
        <history>
        <change on="2012-02-05" type="created" by="vr">from scan2view.xsl, from model2view.xsl</change>
        
        </history>
        
    -->
    <xsl:import href="../commons_v2.xsl"/>
    <xsl:output method="html"/>
    <xsl:variable name="title" select="''"/>
    <xsl:template name="continue-root">
        <xsl:apply-templates select="." mode="format-xmlelem">
            <xsl:with-param name="strict" select="true()"/>
        </xsl:apply-templates>
    </xsl:template>
    <xsl:template match="@ComponentId" mode="format-attr"/>
</xsl:stylesheet>