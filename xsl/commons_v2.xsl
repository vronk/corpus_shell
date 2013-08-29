<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:utils="http://aac.ac.at/content_repository/utils"
    xmlns:exsl="http://exslt.org/common"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    version="2.0">
    <xsl:import href="commons_v1.xsl"/>
    <xd:doc scope="stylesheet">
        <xd:desc>Generic functions for SRU-result handling
            <xd:p>History:
                <xd:ul>
                    <xd:li>2012-02-04: created by:"vr": Convenience wrapper to commons_v1.xsl in XSLT 2.0</xd:li>
                    <xd:li>2011-12-04: created by:"vr": Based on cmd_functions.xsl but retrofitted back to 1.0</xd:li>
                </xd:ul>
            </xd:p>       
        </xd:desc>
    </xd:doc>
    
    <xd:doc>
        <xd:desc>???</xd:desc>
    </xd:doc>
    <xsl:template name="contexts-doc">
        <xsl:if test="not(doc-available(resolve-uri($contexts_url,$base_url)))">
            <xsl:message>ERROR: context not available: <xsl:value-of select="resolve-uri($contexts_url,$base_url)"/>
                base-uri:  <xsl:value-of select="base-uri()"/>
            </xsl:message>
        </xsl:if>
        <xsl:copy-of select="if (doc-available(resolve-uri($contexts_url,$base_url))) then doc(resolve-uri($contexts_url,$base_url)) else ()"/>
    </xsl:template>
 
    <xd:doc>
        <xd:desc>Convenience-wrapper to formURL-template
            shall be usable to form consistently all urls within xsl </xd:desc>
        <xd:param name="action">See <xd:ref name="formURL" type="template">formURL template</xd:ref>.</xd:param>
        <xd:param name="format">See <xd:ref name="formURL" type="template">formURL template</xd:ref>.</xd:param>
        <xd:param name="q">See <xd:ref name="formURL" type="template">formURL template</xd:ref>.</xd:param>
    </xd:doc>     
    <xsl:function name="utils:formURL">
        <xsl:param name="action"/>
        <xsl:param name="format"/>
        <xsl:param name="q"/>
        <xsl:call-template name="formURL">
            <xsl:with-param name="action" select="$action"/>
            <xsl:with-param name="format" select="$format"/>
            <xsl:with-param name="q" select="$q"/>
            <!-- CHECK: possibly necessary   <xsl:with-param name="repository" select="$repository" /> -->
        </xsl:call-template>
        <!-- XSL 2.0 implementation: 
     <xsl:function name="util:formURL">
        <xsl:param name="action"/>
        <xsl:param name="format"/>
        <xsl:param name="q"/>
        <xsl:variable name="param_q">
            <xsl:if test="$q != ''">
                <xsl:value-of select="concat('&query=',$q)"/>
            </xsl:if>
        </xsl:variable>
        <xsl:variable name="param_repository">
            <xsl:if test="$x-context != ''">
                <xsl:value-of select="concat('&repository=',$x-context)"/>
            </xsl:if>
        </xsl:variable>
        <xsl:variable name="param_startRecord">
            <xsl:if test="$startRecord != ''">
                <xsl:value-of select="concat('&startRecord=',$startRecord)"/>
            </xsl:if>
        </xsl:variable>
        <xsl:variable name="param_maximumRecords">
            <xsl:if test="$maximumRecords != ''">
                <xsl:value-of select="concat('&maximumRecords=',$maximumRecords)"/>
            </xsl:if>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$action=''">
                <xsl:value-of select="concat($base_url, '/?q=', $q, '&x-context=', $x-context)"/>
            </xsl:when>
            <xsl:when test="$q=''">
                <xsl:value-of select="concat($base_url, '/',$action, '/', $format)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="$action='record'">
                        <xsl:value-of select="concat($base_url, '/',$action, '/', $format, '?query=', $q, $param_repository)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="concat($base_url, '/',$action, '/', $format, '?query=', $q, $param_repository, $param_startRecord, $param_maximumRecords)"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>-->
    </xsl:function>        
  
   <!--
    convenience wrapper function to xml-context-template;
    delivers the ancestor path
    -->
    <xsl:function name="utils:xmlContext">
        <xsl:param name="child"/>
        <xsl:call-template name="xml-context">
            <xsl:with-param name="child" select="$child"/>
        </xsl:call-template>
    </xsl:function>
  
<!--
   convenience wrapper function to dict-template;
-->
    <xsl:function name="utils:dict">
        <xsl:param name="key"/>
        <xsl:value-of select="utils:dict($key, $key)"/>
    </xsl:function>
    <xsl:function name="utils:dict">
        <xsl:param name="key"/>
        <xsl:param name="fallback"/>
        <xsl:call-template name="dict">
            <xsl:with-param name="key" select="$key"/>
            <xsl:with-param name="fallback" select="$fallback"/>
        </xsl:call-template>
    </xsl:function>
    
    <xd:doc>
        <xd:desc>Dummy that returns it's parameter as this is not needed in XSL 2.0</xd:desc>
        <xd:param name="node-set">This node-set is returned as is</xd:param>
    </xd:doc>
    <xsl:function name="exsl:node-set">
        <xsl:param name="node-set"/>
        <xsl:value-of select="$node-set"/>
    </xsl:function>
</xsl:stylesheet>