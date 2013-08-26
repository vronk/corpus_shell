<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:kwic="http://clarin.eu/fcs/1.0/kwic"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:sru="http://www.loc.gov/zing/srw/"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:fcs="http://clarin.eu/fcs/1.0"
    xmlns:exist="http://exist.sourceforge.net/NS/exist"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    version="1.0" exclude-result-prefixes="kwic xsl tei sru xs fcs exist xd">
    <xd:doc scope="stylesheet">
        <xd:desc>Provides more specific handling of sru-result-set recordData
            <xd:p>History:
                <xd:ul>
                    <xd:li>2013-04-17: created by: "m": </xd:li>
                    <xd:li>2011-11-14: created by: "vr": based on cmdi/scripts/xml2view.xsl</xd:li>
                </xd:ul>
            </xd:p>
            <xd:p/>
        </xd:desc>
    </xd:doc>

    <xsl:include href="data2view_cmd.xsl"/>
<!--    <xsl:import href="../amc/dataset2view.xsl"/>-->
    <xsl:include href="data2view_tei.xsl"/>
<!--    <xsl:include href="../stand_weiss.xsl"/>-->
   
   
    <xd:doc>
        <xd:desc>Default starting-point
            <xd:p>In mode record-data this this and all included style sheets define the transformation.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="sru:recordData" mode="record-data">
        <xsl:apply-templates select="*" mode="record-data"/>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>default fallback: display the xml-structure
            <xd:p/>
        </xd:desc>
    </xd:doc>
    <xsl:template match="*" mode="record-data">
        <!--<xsl:variable name="overrides">
            <xsl:apply-imports/>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$overrides">
                <xsl:copy-of select="$overrides"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="format-xmlelem"/>
            </xsl:otherwise>
        </xsl:choose>-->
        <xsl:apply-templates select="." mode="format-xmlelem"/>
    </xsl:template>

 <!-- hide meta-information about the record from output-->
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p/>
        </xd:desc>
    </xd:doc>
    <xsl:template match="sru:recordSchema|sru:recordPacking" mode="record-data"/>
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p/>
        </xd:desc>
    </xd:doc>
    <xsl:template match="sru:recordIdentifier | sru:recordPosition" mode="record-data"/>
    
<!-- kwic match -->
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p/>
        </xd:desc>
    </xd:doc>
    <xsl:template match="exist:match" mode="record-data">
        <span class="hilight match">
  <!--            <xsl:apply-templates select="*" mode="record-data"/>-->
            <xsl:value-of select="."/>
        </span>
    </xsl:template>

    

<!-- FCS-wrap -->
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p/>
        </xd:desc>
    </xd:doc>
    <xsl:template match="fcs:Resource" mode="record-data">
        
        <!-- this is quite specialized only for the navigation-ResourceFragments! -->
        <div class="navigation">
            <xsl:apply-templates select=".//fcs:ResourceFragment[@type][not(fcs:DataView)]" mode="record-data"/>
        </div>
        
        <!-- currently reduced to processing only DataView-kwic 
        but we should make this generic (don't restrict by type, just continue processing the record-data) -->
        <xsl:apply-templates select=".//fcs:DataView" mode="record-data"/>
    </xsl:template>
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p/>
        </xd:desc>
    </xd:doc>
    <xsl:template match="fcs:DataView" mode="record-data">
           <!-- don't show full view if, there is kwic, title-view is called separately, and  -->
        <xsl:if test="not((@type='full' and parent::*/fcs:DataView[@type='kwic']) or @type='title')">
            <div class="data-view {@type}">
                <xsl:apply-templates mode="record-data"/>
            </div>
        </xsl:if>
    </xsl:template>
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p/>
        </xd:desc>
    </xd:doc>
    <xsl:template match="fcs:DataView[@ref][not(@ref='')]" mode="record-data">
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
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p/>
        </xd:desc>
    </xd:doc>
    <xsl:template match="fcs:ResourceFragment[@type]" mode="record-data">
        <a href="{@ref}&amp;x-format={$format}" rel="{@type}" class="{@type}">
            <xsl:value-of select="@pid"/>
        </a>
    </xsl:template>
    

 <!-- handle generic metadata-fields -->
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p/>
        </xd:desc>
    </xd:doc>
    <xsl:template match="fcs:f" mode="record-data">
        <span class="label">
            <xsl:value-of select="@key"/>: </span>
        <span class="value">
            <xsl:value-of select="."/>
        </span>; 
    </xsl:template>
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p/>
        </xd:desc>
    </xd:doc>
    <xsl:template match="kwic:kwic" mode="record-data">
        <div class="kwic-line">
            <xsl:apply-templates mode="record-data"/>
        </div>
    </xsl:template>        
    
 <!--
     handle KWIC-DataView:
     <c type="left"></c><kw></kw><c type="right"></c>
     WATCHME: temporarily accepting both version (fcs and kwic namespacEe)
 -->
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p/>
        </xd:desc>
    </xd:doc>
    <xsl:template match="kwic:c|fcs:c" mode="record-data">
        <span class="context {@type}">
            <xsl:apply-templates mode="record-data"/>
        </span>
        <xsl:if test="following-sibling::*[1][local-name()='c']">
            <br/>
        </xsl:if>
    </xsl:template>
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p/>
        </xd:desc>
    </xd:doc>
    <xsl:template match="kwic:kw|fcs:kw" mode="record-data">
        <xsl:text> </xsl:text>
        <span class="kw hilight">
            <xsl:apply-templates mode="record-data"/>
        </span>
        <xsl:text> </xsl:text>
    </xsl:template>
    
    
    <!-- ************************ -->
    <!-- named templates starting -->
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p/>
        </xd:desc>
    </xd:doc>
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
    
    <xd:doc>
        <xd:desc>
            <xd:p>Empty template. Only available with XSL 2.0 using features. See data2view_v2.xsl</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template name="inline"/>
</xsl:stylesheet>