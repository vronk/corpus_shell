<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:sru="http://www.loc.gov/zing/srw/" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:fcs="http://clarin.eu/fcs/1.0" version="1.0" exclude-result-prefixes="msxsl">
    <xsl:output method="xml" indent="yes"/>
    <xsl:template match="/">
        <sru:scanResponse>
<!--            <xsl:copy-of select="."/>-->
            <sru:version>1.2</sru:version>
            <sru:terms>
<!--                <xsl:apply-templates select="(.//map[@key])[1]" />-->
                <xsl:variable name="root-key" select="(.//map[@key])[1]/@key"/>
                <sru:term>
                    <sru:value>
                        <xsl:value-of select="$root-key"/>
                    </sru:value>
                    <sru:numberOfRecords>
                        <xsl:value-of select="count(.//map[parent::map][not(@key=$root-key)])"/>
                    </sru:numberOfRecords>
                    <sru:displayTerm>
                        <xsl:value-of select=".//map[@key=$root-key]/@title"/>
                    </sru:displayTerm>
                    <sru:extraTermData>
                        <sru:terms>
                            <xsl:apply-templates select=".//map[parent::map][not(@key=$root-key)]"/>
                        </sru:terms>
                    </sru:extraTermData>
                </sru:term>
            </sru:terms>
            <sru:extraResponseData>
                <fcs:countTerms>
                    <xsl:value-of select="count(.//map[parent::map])"/>
                </fcs:countTerms>
            </sru:extraResponseData>
            <sru:echoedScanRequest>
                <sru:version>1.2</sru:version>
                <sru:scanClause>fcs.resource</sru:scanClause>
                <sru:responsePosition/>
                <sru:maximumTerms>42</sru:maximumTerms>
            </sru:echoedScanRequest>
        </sru:scanResponse>
    </xsl:template>
    <xsl:template match="map">
        <sru:term>
            <sru:value>
                <xsl:value-of select="@key"/>
            </sru:value>
<!--                <sru:numberOfRecords><xsl:value-of select="count(map)" /></sru:numberOfRecords>-->
            <sru:displayTerm>
                <xsl:value-of select="@title"/>
            </sru:displayTerm>
            <sru:extraTermData>
                <sru:terms>
                    <xsl:apply-templates select="map"/>
                </sru:terms>
            </sru:extraTermData>
        </sru:term>
    </xsl:template>
</xsl:stylesheet>