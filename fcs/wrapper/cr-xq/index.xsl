<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:sru="http://www.loc.gov/standards/sru/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:fcs="http://clarin.eu/fcs/1.0/" version="2.0">


<!--
two tasks (in separate calls, managed by $mode-param):
1. produces an index by grouping content	
2. selects a subsequence of the produced content
-->
    <xsl:param name="scan-clause"/>
    <xsl:param name="mode" select="'aggregate'"/>
    <xsl:param name="sort" select="'text'"/>
    <xsl:param name="filter" select="''"/>
    <xsl:param name="filter-mode" select="if (ends-with($filter,'*')) then 'starts-with' else 'contains'"/> <!-- contains, starts-with -->
    <xsl:param name="start-item" select="100"/>
    <xsl:param name="max-items" select="100"/> <!-- if max-items=0 := return all -->
    <xsl:template match="/">
<!--		
<params mode="{$mode}" sort="{$sort}"  /> -->
        <sru:scanResponse>
            <sru:version>1.2</sru:version>
            <xsl:choose>
                <xsl:when test="$mode='subsequence'">
                    <xsl:apply-templates mode="subsequence" select=".//sru:terms"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="terms">
                        <xsl:apply-templates/>
                    </xsl:variable>
                    <xsl:copy-of select="$terms"/>
                    <sru:extraResponseData>
                        <fcs:countTerms>
                            <xsl:value-of select="count($terms//sru:term)"/>
                        </fcs:countTerms>
                    </sru:extraResponseData>
                </xsl:otherwise>
            </xsl:choose>
            <sru:echoedScanRequest>
                <sru:scanClause>
                    <xsl:value-of select="$scan-clause"/>
                </sru:scanClause>
                <sru:maximumTerms>
                    <xsl:value-of select="$max-items"/>
                </sru:maximumTerms>
            </sru:echoedScanRequest>
        </sru:scanResponse>
    </xsl:template>
    <xsl:template match="nodes[*]">
        <xsl:variable name="nodes" select="*"/>
        <xsl:variable name="count-text" select="count($nodes/text()[.!=''])"/>
        <xsl:variable name="distinct-text-count" select="count(distinct-values($nodes/text()))"/>
        <sru:terms>
            <xsl:copy-of select="@*"/>
            <xsl:for-each-group select="$nodes" group-by="text()">
                <sru:term>
                    <sru:value>
                        <xsl:value-of select="text()"/>
                    </sru:value>
                    <sru:numberOfRecords>
                        <xsl:value-of select="count(current-group())"/>
                    </sru:numberOfRecords>
                </sru:term>
            </xsl:for-each-group>
        </sru:terms>
    </xsl:template>
    <xsl:template match="sru:terms" mode="subsequence">
        <xsl:variable name="filtered" select="*[if ($filter!='') then                             if ($filter-mode='starts-with') then starts-with(sru:value,substring-before($filter,'*'))                                else contains(sru:value, $filter)                            else true()]"/>
        
        <!-- this may be potentially expensive and we may need to store the index already sorted (which is the normal/sane way to do!) -->
        <xsl:variable name="ordered">
            <xsl:choose>
                <xsl:when test="$sort='size'">
                    <xsl:for-each select="$filtered">
                        <xsl:sort select="sru:numberOfRecords" data-type="number" order="descending"/>
                        <xsl:copy-of select="."/>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:for-each select="$filtered">
                        <xsl:sort select="sru:value" data-type="text" order="ascending"/>
                        <xsl:copy-of select="."/>
                    </xsl:for-each>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

<!-- 		<xsl:variable name="count-items" select="count($filtered)" />-->
        <xsl:copy>
<!--            <xsl:copy-of select="@*" />-->
<!--			<xsl:value-of select="count($ordered/*)" /> -->
<!--			<xsl:attribute name="count_items" select="if (xs:integer($count-items) > xs:integer($max-items)) then $max-items else $count-items" /> -->
            <xsl:apply-templates select="$ordered/*[xs:integer(position()) &gt;= xs:integer($start-item) and                  ((xs:integer(position()) &lt; (xs:integer($start-item) + xs:integer($max-items))) or xs:integer($max-items)=0)]"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="sru:term">
        <xsl:copy>
            <xsl:copy-of select="*"/>
            <!-- <xsl:attribute name="pos" select="position()"/> -->
            <extraTermData>
                <fcs:position>
                    <xsl:value-of select="position()"/>
                </fcs:position>
            </extraTermData>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>