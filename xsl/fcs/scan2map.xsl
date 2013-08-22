<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:utils="http://aac.ac.at/content_repository/utils" xmlns:sru="http://www.loc.gov/zing/srw/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:fcs="http://clarin.eu/fcs/1.0" 
     exclude-result-prefixes="#all" version="2.0">
    <!-- 
<purpose> generate a simplified xml-version of scanResponse </purpose>
<params>
<param name=""></param>
</params>
<history>
<change on="2012-05-02" type="created" by="vr">based on scan2view.xsl </change>
		
</history>

<sample >
<sru:scanResponse xmlns:sru="http://www.loc.gov/zing/srw/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:fcs="http://clarin.eu/fcs/1.0/">
<sru:version>1.2</sru:version>
   <sru:terms path="//div[@type='diary-day']/p/date/substring(xs:string(@value),1,7)">
        <sru:term>
        <sru:value>1903-01</sru:value>
        <sru:numberOfRecords>30</sru:numberOfRecords>
        </sru:term>
        <sru:term>
        <sru:value>1903-02</sru:value>
        <sru:numberOfRecords>28</sru:numberOfRecords>
        </sru:term>
        <sru:term>
        <sru:value>1903-03</sru:value>
        <sru:numberOfRecords>31</sru:numberOfRecords>
        </sru:term>
   </sru:terms>
   <sru:extraResponseData>
        <fcs:countTerms>619</fcs:countTerms>
    </sru:extraResponseData>
    <sru:echoedScanRequest>
        <sru:scanClause>diary-month</sru:scanClause>
        <sru:maximumTerms>100</sru:maximumTerms>
    </sru:echoedScanRequest>        
 <sru:scanResponse>
 
</sample>
-->

<xsl:output indent="yes"></xsl:output>
    
    <xsl:param name="sort">x</xsl:param>
    <!-- s=size|n=name|t=time|x=default -->
    
    <xsl:param name="title" select="concat('scan: ', $scanClause )"/>

    <xsl:decimal-format name="european" decimal-separator="," grouping-separator="."/>
    <xsl:param name="scanClause" select="/sru:scanResponse/sru:echoedScanRequest/sru:scanClause"/>
    <xsl:param name="index" select="$scanClause"/>

    <xsl:template match="/">
        <xsl:variable name="countTerms" select="/sru:scanResponse/sru:extraResponseData/fcs:countTerms"/>
        
        <map index="{$scanClause}" count="{$countTerms}">
            <xsl:apply-templates select="/sru:scanResponse/sru:terms"/>            
        </map>
    </xsl:template>
    
    <!-- 
sample data:        
        <sru:term>
        <sru:value>cartesian</sru:value>
        <sru:numberOfRecords>35645</sru:numberOfRecords>
        <sru:displayTerm>Carthesian</sru:displayTerm>
        <sru:extraTermData></sru:extraTermData>
        </sru:term>
    -->
    <xsl:template match="sru:terms">
            <xsl:apply-templates select="sru:term"/>
    </xsl:template>
    <xsl:template match="sru:term">
        <item count="{sru:numberOfRecords}" norm="{(sru:displayTerm, sru:value)[1]}" ><xsl:value-of select="(sru:displayTerm, sru:value)[1]"/></item>
        
        <xsl:apply-templates select="sru:extraTermData/sru:terms/sru:term"/>
    </xsl:template>
    
</xsl:stylesheet>