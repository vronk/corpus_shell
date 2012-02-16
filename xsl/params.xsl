<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:sru="http://www.loc.gov/zing/srw/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:fcs="http://clarin.eu/fcs/1.0" exclude-result-prefixes="xs" version="1.0">
    <xsl:param name="user"/>

    <!-- baseUrl for constructing
        //sru:baseUrl
    -->
    <xsl:param name="base_url" select="''"/>
    <!--<xsl:param name="base_url">http://clarin.aac.ac.at/exist7/rest/db/content_repository</xsl:param>
        <xsl:param name="base_dir">http://corpus3.aac.ac.at/cs/</xsl:param>-->
    <xsl:param name="scripts_url" select="''"/>
    <!-- http://clarin.aac.ac.at/exist7/rest/db/content_repository/scripts</xsl:param> -->
    <xsl:param name="site_logo">corpus_shell</xsl:param>
    <xsl:param name="site_name">Content Repository</xsl:param>
    <xsl:param name="format" select="'htmlpagelist'"/> <!-- table|list|detail -->
    <xsl:param name="q" select="/sru:searchRetrieveResponse/sru:echoedSearchRetrieveRequest/sru:query"/>
    <xsl:param name="x-context" select="/sru:searchRetrieveResponse/sru:echoedSearchRetrieveRequest/fcs:x-context"/>
    <xsl:param name="startRecord" select="/sru:searchRetrieveResponse/sru:echoedSearchRetrieveRequest/sru:startRecord"/>
    <xsl:param name="maximumRecords" select="/sru:searchRetrieveResponse/sru:echoedSearchRetrieveRequest/sru:maximumRecords"/>
    <xsl:param name="numberOfRecords" select="/sru:searchRetrieveResponse/sru:numberOfRecords"/>
    <xsl:param name="contexts_url" select="concat($base_url,'?operation=scan&amp;scanClause=fcs.resource&amp;sort=text')"/>
</xsl:transform>