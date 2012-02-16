<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:utils="http://aac.ac.at/content_repository/utils" 
    xmlns:sru="http://www.loc.gov/zing/srw/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:fcs="http://clarin.eu/fcs/1.0" 
    version="2.0">
    <!-- 
        <purpose> generate a view for the explain-record (http://www.loc.gov/standards/sru/specs/explain.html) </purpose>
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
        <xsl:apply-templates select=".//indexInfo"/>
        <!--<div class="explain-view">
            <xsl:apply-templates select="." mode="format-xmlelem"/>
        </div>-->
    </xsl:template>
    <xsl:template match="indexInfo">
        <ul class="indexInfo">
            <xsl:apply-templates select="index"/>
        </ul>
    </xsl:template>
    <xsl:template match="index">
        <xsl:variable name="scan-index" select="concat('?operation=scan&amp;scanClause=', map/name , '&amp;x-context=', $x-context, '&amp;x-format=', $format )"/>
        <li>
            <a href="{$scan-index}">
                <xsl:value-of select="title"/>
            </a>
        </li>
    </xsl:template>
</xsl:stylesheet>