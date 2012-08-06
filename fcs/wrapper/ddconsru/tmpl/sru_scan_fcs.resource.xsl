<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:msxsl="urn:schemas-microsoft-com:xslt" exclude-result-prefixes="msxsl"
                xmlns:sru="http://www.loc.gov/zing/srw/"
>
  <xsl:output method="xml" indent="yes"/>

  <xsl:template match="/">
    <sru:scanResponse >
      <sru:version>1.2</sru:version>
      <sru:terms>
        <xsl:for-each select="config/server">
          <sru:term>
            <sru:value>
              <xsl:value-of select="key"/>
            </sru:value>
            <sru:numberOfRecords>
              <xsl:value-of select="count(corpora/item)"/>
            </sru:numberOfRecords>
            <sru:displayTerm>
              <xsl:value-of select="displayText"/>
            </sru:displayTerm>
            <sru:extraTermData>
              <sru:terms>
                <xsl:for-each select="corpora/item">
                  <sru:term>
                    <sru:value>
                      <xsl:value-of select="key"/>
                    </sru:value>
                    <sru:numberOfRecords>1</sru:numberOfRecords>
                    <sru:displayTerm>
                      <xsl:value-of select="displayText"/>
                    </sru:displayTerm>
                  </sru:term>
                </xsl:for-each>
              </sru:terms>
            </sru:extraTermData>
          </sru:term>
        </xsl:for-each>
      </sru:terms>
      <sru:echoedScanRequest>
        <sru:version>1.2</sru:version>
        <sru:scanClause>fcs.resource</sru:scanClause>
        <sru:responsePosition/>
        <sru:maximumTerms>42</sru:maximumTerms>
      </sru:echoedScanRequest>
    </sru:scanResponse>
  </xsl:template>
</xsl:stylesheet>
