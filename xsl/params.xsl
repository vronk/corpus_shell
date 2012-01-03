<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:my="myFunctions"
    exclude-result-prefixes="xs"
    version="1.0">
    
    <xsl:param name="user"></xsl:param>
<!--    <xsl:param name="base_dir">http://corpus3.aac.ac.at/cs/</xsl:param>-->
    <xsl:param name="base_dir">http://clarin.aac.ac.at/exist7/rest/db/content_repository/scripts</xsl:param>
    <xsl:param name="site_logo">CR LOGO</xsl:param>
    <xsl:param name="site_name">Content Repository</xsl:param>
    <xsl:param name="format" select="'htmlpagelist'" /> <!-- table|list|detail -->
    
    <xsl:param name="q" select="''"/>
    <xsl:param name="repository" select="''"/>
    <xsl:param name="startRecord">1</xsl:param>
    <xsl:param name="maximumRecords">10</xsl:param>
    
            
</xsl:transform>