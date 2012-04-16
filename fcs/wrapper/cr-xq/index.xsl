<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:sru="http://www.loc.gov/zing/srw/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:fcs="http://clarin.eu/fcs/1.0" version="2.0">


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
    <xsl:param name="start-item" select="1"/>
    <xsl:param name="response-position" select="1"/>
    <xsl:param name="max-items" select="100"/> <!-- if max-items=0 := return all -->
    <xsl:template match="/">
<!--		
<params mode="{$mode}" sort="{$sort}"  /> -->
        <sru:scanResponse>
            <sru:version>1.2</sru:version>
            <xsl:choose>
                <xsl:when test="$mode='subsequence'">
<!--                    don't go descendants-axis, because of nested terms
<xsl:apply-templates mode="subsequence" select=".//sru:terms"/>-->
                    <xsl:apply-templates mode="subsequence" select="sru:scanResponse/sru:terms"/>
                    <xsl:copy-of select="sru:scanResponse/sru:extraResponseData"/>
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
        <!-- FIXME: this is not correct, because it counts individual text-nodes.
            if there are nodes with subnodes, text in every child is counted extra-->
        <xsl:variable name="distinct-text-count" select="count(distinct-values($nodes/text()))"/>
        <sru:terms>
            <xsl:copy-of select="@*"/>
            <xsl:choose>
                <xsl:when test="$sort='text'">
                    <xsl:for-each-group select="$nodes" group-by=".//text()">
                        <xsl:sort select=".//text()" data-type="text" order="ascending"/>
<!--                        <xsl:sort select="count(current-group())" data-type="number" order="descending"/>-->
                        <sru:term>
                            <sru:value>
                                <xsl:value-of select=".//text()"/>
                            </sru:value>
                            <sru:numberOfRecords>
                                <xsl:value-of select="count(current-group())"/>
                            </sru:numberOfRecords>
                        </sru:term>
                    </xsl:for-each-group>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:for-each-group select="$nodes" group-by=".//text()">
                        <xsl:sort select="count(current-group())" data-type="number" order="descending"/>
                        <sru:term>
                            <sru:value>
                                <xsl:value-of select=".//text()"/>
                            </sru:value>
                            <sru:numberOfRecords>
                                <xsl:value-of select="count(current-group())"/>
                            </sru:numberOfRecords>
                        </sru:term>
                    </xsl:for-each-group>
                </xsl:otherwise>
            </xsl:choose>
        </sru:terms>
    </xsl:template>

    <!-- if filter by default use only filtered data, except when sort=text and either filter mode = starts-with (only sensible result )
        or the response-position is other than 1 (needed for navigation scan)
        than use the subsequence of the data-set, starting from first filter-matching term +/- response-position  -->
    <xsl:template match="sru:terms" mode="subsequence">
        <xsl:variable name="only-filtered" select="not($sort='text' and ($filter-mode='starts-with' or not(xs:integer($response-position) = 1)))"/>
        <!-- position of the matching term within the index, if there is a filter -->
        <xsl:variable name="filtered" select="*[if ($filter!='') then if ($filter-mode='starts-with') then starts-with(sru:value,substring-before($filter,'*')) else contains(sru:value, $filter) else true()]"/>
        <xsl:variable name="match-position" select="count(sru:term[.=$filtered[1]]/preceding-sibling::sru:term)"/>

<!--        <xsl:message><xsl:value-of select="$match-position" /></xsl:message>-->
        
        <!-- expect ordered data -->
        <xsl:variable name="ordered">
            <xsl:choose>
                <xsl:when test="$only-filtered">
                    <xsl:copy-of select="$filtered"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="*"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

<!-- 		<xsl:variable name="count-items" select="count($filtered)" />-->
        <xsl:copy>
<!--            <xsl:copy-of select="@*" />-->
<!--			<xsl:value-of select="count($ordered/*)" /> -->
<!--			<xsl:attribute name="count_items" select="if (xs:integer($count-items) > xs:integer($max-items)) then $max-items else $count-items" /> -->
<!--            <xsl:message>cnt:<xsl:value-of select="count($ordered/*)"/>-match:<xsl:value-of select="$match-position"/>-start:<xsl:value-of select="$effective-start-item"/>-end:<xsl:value-of select="$effective-end-item"/>
</xsl:message>-->
            <xsl:variable name="start-pos" select="if ($only-filtered) then 0 else xs:integer($match-position)"/>
            <xsl:variable name="effective-start-item" select="xs:integer($start-item) + $start-pos - xs:integer($response-position) + 1"/>
            <xsl:variable name="effective-end-item" select="xs:integer($effective-start-item) + xs:integer($max-items)"/>
            <xsl:apply-templates select="$ordered/*[xs:integer(position()) &gt;= xs:integer($effective-start-item) and ((xs:integer(position()) &lt; (xs:integer($effective-end-item))) or xs:integer($max-items)=0)]"/>
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