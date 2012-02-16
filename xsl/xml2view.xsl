<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    version="2.0">
    <!-- 
        <purpose> generate a generic html-view for xml </purpose>
        <params>
        <param name=""></param>
        </params>
        <history>
        <change on="2012-02-05" type="created" by="vr">from scan2view.xsl, from model2view.xsl</change>
        
        </history>
        
    -->
    <xsl:import href="commons.xsl"/>
    <xsl:output method="html"/>
    <xsl:decimal-format name="european" decimal-separator="," grouping-separator="."/>
    <xsl:variable name="title" select="concat('explain: ', $site_name)"/>
    <xsl:template name="continue-root">
        <div class="explain-view">
            <xsl:apply-templates select="." mode="format-xmlelem"/>
        </div>
    </xsl:template>
</xsl:stylesheet>