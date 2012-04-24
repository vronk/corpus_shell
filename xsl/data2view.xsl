<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:sru="http://www.loc.gov/zing/srw/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:fcs="http://clarin.eu/fcs/1.0" xmlns:exist="http://exist.sourceforge.net/NS/exist" version="1.0" exclude-result-prefixes="xs sru exist tei fcs">

    <!-- 
        <purpose> provide more specific handling of sru-result-set recordData</purpose>
        <params>
        <param name=""></param>
        </params>
        <history>	
        <change on="2011-11-14" type="created" by="vr">based on cmdi/scripts/xml2view.xsl</change>	
        </history>
    -->
    <xsl:include href="data2view_tei.xsl"/>
    <xsl:include href="stand_weiss.xsl"/>
   
<!-- default starting-point -->
    <xsl:template match="sru:recordData" mode="record-data">
        <xsl:apply-templates select="*" mode="record-data"/>
    </xsl:template>
    
<!-- default fallback: display the xml-structure-->
    <xsl:template match="*" mode="record-data">
        <xsl:apply-templates select="." mode="format-xmlelem"/>
    </xsl:template>

 <!-- hide meta-information about the record from output-->
    <xsl:template match="sru:recordSchema|sru:recordPacking" mode="record-data"/>
    <xsl:template match="sru:recordIdentifier | sru:recordPosition" mode="record-data"/>
    
<!-- kwic match -->
    <xsl:template match="exist:match" mode="record-data">
        <span class="hilight match">
            <xsl:value-of select="."/>
        </span>
    </xsl:template>

    

<!-- FCS-wrap -->
    <xsl:template match="fcs:Resource" mode="record-data">
        <!-- currently reduced to processing only DataView-kwic 
        but we should make this generic (don't restrict by type, just continue processing the record-data) -->
        <xsl:apply-templates select=".//fcs:DataView" mode="record-data"/>
    </xsl:template>
    <xsl:template match="fcs:DataView" mode="record-data">
           <!-- don't show full view if, there is kwic, title-view is called separately, and  -->
        <xsl:if test="not((@type='full' and parent::*/fcs:DataView[@type='kwic']) or @type='title')">
            <div class="data-view {@type}">
                <xsl:apply-templates mode="record-data"/>
            </div>
        </xsl:if>
    </xsl:template>
    <xsl:template match="fcs:DataView[@ref]" mode="record-data">
        <div class="data-view {@type}">
            <a href="{@ref}">
                <xsl:value-of select="@type"/>
            </a>
        </div>
    </xsl:template>
    
 <!-- better hide the fullview (the default view is too much)
        TODO: some more condensed view -->
<!--    <xsl:template match="fcs:DataView[@type='full']" mode="record-data"/>-->
<!--  this would be to use, if including a stylesheet without mode=record-data (like aac:stand.xsl)       
    <xsl:template match="fcs:DataView[@type='full']/*" mode="record-data">
        <xsl:apply-templates></xsl:apply-templates>
    </xsl:template>
-->    
        
 <!-- handle generic metadata-fields -->
    <xsl:template match="fcs:f" mode="record-data">
        <span class="label">
            <xsl:value-of select="@key"/>: </span>
        <span class="value">
            <xsl:value-of select="."/>
        </span>; 
    </xsl:template>
    
 <!--
     handle KWIC-DataView:
     <c type="left"></c><kw></kw><c type="right"></c>
 -->
    <xsl:template match="fcs:c" mode="record-data">
    <!-- FIXME:  accepting both attributes is temporary, until all providers agree on one -->
        <span class="context {@c | @type}">
            <xsl:apply-templates mode="record-data"/>
        </span>
        <xsl:if test="following-sibling::*[1][local-name()='c']">
            <br/>
        </xsl:if>
    </xsl:template>
    <xsl:template match="fcs:kw" mode="record-data">
        <xsl:text> </xsl:text>
        <span class="kw hilight">
            <xsl:apply-templates mode="record-data"/>
        </span>
        <xsl:text> </xsl:text>
    </xsl:template>
    <xsl:template name="getTitle">
        <xsl:choose>
            <xsl:when test=".//fcs:DataView[@type='title']">
                <xsl:value-of select=".//fcs:DataView[@type='title']"/>
            </xsl:when>
            <xsl:when test=".//date/@value">
                <xsl:value-of select=".//date/@value"/>
            </xsl:when>
            <xsl:when test=".//tei:persName">
                <xsl:value-of select=".//tei:persName"/>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>