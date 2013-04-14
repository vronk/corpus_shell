<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:zr="http://explain.z3950.org/dtd/2.0/" xmlns:utils="http://aac.ac.at/content_repository/utils" xmlns:sru="http://www.loc.gov/zing/srw/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:fcs="http://clarin.eu/fcs/1.0" exclude-result-prefixes="#all" version="2.0">
    <!-- 
<purpose> generate a json object of the explain </purpose>
<params>
<param name=""></param>
</params>
<result>
     {explain:"$scanClause", count:"$countIndexes",
      indexes: [{label:"label1", value:"value1", count:"#number"}, ...]            
     }
</result>
<history>
<change on="2012-05-02" type="created" by="vr">based on scan2view.xsl </change>
<change on="2013-01-20" type="created" by="vr">based on scan2map.xsl </change>
		
</history>

<sample >
<explain xsi:schemaLocation="http://explain.z3950.org/dtd/2.0/ file:/C:/Users/m/3lingua/corpus_shell/_repo2/corpus_shell/fcs/schemas/zeerex-2.0.xsd" authoritative="false" id="id1"><serverInfo protocol="SRU" version="1.2" transport="http"><host>TODO: config:param-value($config, "base-url")</host><port>80</port><database>cr</database></serverInfo><databaseInfo><title lang="en" primary="true">ICLTT Content Repository</title><description lang="en" primary="true"/><author/><contact/></databaseInfo><metaInfo><dateModified>TODO</dateModified></metaInfo><indexInfo><set identifier="isocat.org/datcat" name="isocat"><title>ISOcat data categories</title></set><set identifier="clarin.eu/fcs" name="fcs"><title>CLARIN - Federated Content Search</title></set>
<!-/- <index search="true" scan="true" sort="false">
            <title lang="en">Resource</title>
            <map>
                <name set="fcs">resource</name>
            </map>
        </index> -/->
        <index search="true" scan="true" sort="false"><title lang="en">ana</title><map><name set="fcs">ana</name></map></index><index search="true" scan="true" sort="false"><title lang="en">birth-date</title><map><name set="fcs">birth-date</name></map></index> 
</sample>
-->
    <xsl:output indent="yes" method="text" media-type="application/json" encoding="UTF-8"/>
    <xsl:param name="sort">x</xsl:param>
    <!-- s=size|n=name|t=time|x=default -->
    <xsl:param name="title" select="concat('scan: ', $scanClause )"/>
    <xsl:decimal-format name="european" decimal-separator="," grouping-separator="."/>
    <xsl:param name="scanClause" select="/sru:scanResponse/sru:echoedScanRequest/sru:scanClause"/>
    <xsl:param name="index" select="$scanClause"/>
    <xsl:template match="/">
        <xsl:variable name="countIndexes" select="count(//zr:indexInfo/zr:index)"/>
        <xsl:text>{"explain":"explain",</xsl:text>
<!--        <xsl:value-of select="$x-context"/>-->
        <xsl:text> "countIndexes":"</xsl:text>
        <xsl:value-of select="$countIndexes"/>
        <xsl:text>", </xsl:text><!--"countReturned":"</xsl:text>
        <xsl:value-of select="$countReturned"/>
        <xsl:text>", </xsl:text>-->
        <xsl:apply-templates select="//zr:indexInfo"/>
        <xsl:text>}</xsl:text>
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
    <xsl:template match="zr:indexInfo">
        <xsl:text>
"context_sets": {
</xsl:text>
        <xsl:apply-templates select="zr:set"/>
        <xsl:text>},</xsl:text>
        <xsl:text>
"indexes": {
</xsl:text>
        <xsl:apply-templates select="zr:index"/>
        <xsl:text>}</xsl:text>
    </xsl:template>
    <xsl:template match="zr:set">
        <xsl:text>"</xsl:text>
        <xsl:value-of select="@name"/>
        <xsl:text>": "</xsl:text>
        <xsl:value-of select="zr:title"/>
        <xsl:text>"</xsl:text>
        <xsl:if test="not(position()=last())">, </xsl:if>
    </xsl:template>
    <xsl:template match="zr:index">
        <xsl:text>"</xsl:text>
        <xsl:value-of select="zr:title"/>
        <xsl:text>": {"search": "</xsl:text>
        <xsl:value-of select="@search"/>
        <xsl:text>", </xsl:text>
        <xsl:text>"scan": "</xsl:text>
        <xsl:value-of select="@scan"/>
        <xsl:text>", </xsl:text>
        <xsl:text>"sort": "</xsl:text>
        <xsl:value-of select="@sort"/>
        <xsl:text>"}</xsl:text>
        <xsl:if test="not(position()=last())">, </xsl:if>
        
        <!--<xsl:text>{"title": "</xsl:text>
        <xsl:value-of select="translate(sru:value,'"','')"/>
        <xsl:text>", </xsl:text>
        <xsl:text>"label": "</xsl:text>
        <xsl:value-of select="translate((sru:displayTerm, sru:value)[1],'"','')"/> |<xsl:value-of select="sru:numberOfRecords"/>
        <xsl:text>|", </xsl:text>
        <xsl:text>"count": "</xsl:text>
        <xsl:value-of select="sru:numberOfRecords"/>
        <xsl:text>"}</xsl:text>
        <xsl:if test="not(position()=last())">, </xsl:if>
        <xsl:apply-templates select="sru:extraTermData/sru:terms/sru:term"/>-->
    </xsl:template>
</xsl:stylesheet>