<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    version="1.0">
    <xsl:import href="../commons_v1.xsl"/>
    <xd:doc scope="stylesheet">
        <xd:desc> generate a generic html-view for xml
            <xd:p>History:
                <xd:ul>
                    <xd:li>2012-02-05: created by:"vr": from scan2view.xsl, from model2view.xsl</xd:li>
                </xd:ul>
            </xd:p>
        </xd:desc>
    </xd:doc>
    
    <xsl:output method="html"/>
    <xsl:variable name="title" select="''"/>
    <xsl:template name="continue-root">
        <xsl:apply-templates select="." mode="format-xmlelem">
            <xsl:with-param name="strict" select="true()"/>
        </xsl:apply-templates>
    </xsl:template>
    <xsl:template match="@ComponentId" mode="format-attr"/>
</xsl:stylesheet>