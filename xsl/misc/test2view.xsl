<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="2.0">
    <!-- 
        <purpose> generate a html-view for the tests by the testing-module</purpose>
        <params>
        <param name=""></param>
        </params>
        <history>
        <change on="2012-02-12" type="created" by="vr">from explain2view.xsl</change>
        
        </history>
        
        <sample>
        <TestSet>
<testName>Example test</testName>
    <description>
        <p>Testing the number of paragraphs</p>
        <author>James Fuller</author>
    </description>
    <test n="1" pass="true"/>
</TestSet>
 </sample>
        
    -->
    <xsl:import href="commons_v1.xsl"/>
    <xsl:output method="html"/>
    <xsl:decimal-format name="european" decimal-separator="," grouping-separator="."/>
    <xsl:variable name="title" select="concat('explain: ', $site_name)"/>
    <xsl:template name="continue-root">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="TestSet">
        <div class="testset">
            <h2>
                <xsl:value-of select="testName"/>
            </h2>
            <p>
                <xsl:copy-of select="description"/>
            </p>
            <table>
                <xsl:apply-templates select="test"/>
            </table>
        </div>
    </xsl:template>
    <xsl:template match="test">
        <tr>
            <td>
                <xsl:value-of select="@n"/>
            </td>
            <td>
                <xsl:value-of select="task"/>
                <span>[<xsl:value-of select="if (xs:string(@pass)='true') then 'passed' else 'failed' "/>]</span>
            </td>
        </tr>
        <xsl:if test="result">
            <tr>
                <td/>
                <td>
                    <xsl:apply-templates select="result" mode="format-xmlelem"/>
                </td>
            </tr>
        </xsl:if>
    </xsl:template>
    <xsl:template match="testrun">
        <div>
            <xsl:copy-of select="info/h2"/>
            <div class="note">duration: <xsl:value-of select="@duration"/>; on: <xsl:value-of select="substring(@on,1,10)"/>; </div>
            <xsl:apply-templates select="(info/*|TestSet)"/>
        </div>
    </xsl:template>
    <xsl:template match="diagnostics">
        <div>
            <div class="test-failed">
                <xsl:value-of select="@type"/>
            </div>
            <xsl:copy-of select="."/>
        </div>
    </xsl:template>
    <xsl:template match="h2"/>
    <xsl:template match="*|@*">
        <xsl:copy>
            <xsl:apply-templates select="*|@*|text()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="text()">
        <xsl:value-of select="."/>
    </xsl:template>
</xsl:stylesheet>