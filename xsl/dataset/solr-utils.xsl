<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:exsl="http://exslt.org/common"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:utils="http://aac.ac.at/corpus_shell/utils"
    xmlns="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="exsl xs xd utils" 
    version="2.0">
    
    <xsl:import href="../utils.xsl"/>
    <xsl:import href="amc-params.xsl"/> 
    
    <xsl:output method="xhtml"  
        doctype-public="-//W3C//DTD XHTML 1.0 Transitional//
        EN" indent="yes"/>
    
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> 2012-09-28</xd:p>
            <xd:p><xd:b>Author:</xd:b> m</xd:p>
            <xd:p>some helper functions for processing the solr-result (amc-viewer)</xd:p>
            <xd:p>params moved to amc-params.xsl [2012-12-10]</xd:p>
        </xd:desc>
    </xd:doc>
    
    <xd:doc>
        <xd:desc>
            <xd:p>the base-link parameters encoded as url</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:variable name="base-link">
        <xsl:call-template name="base-link"></xsl:call-template>
    </xsl:variable>
    

    <xd:doc>
        <xd:desc>
            <xd:p>store in a variable the params list as delivered by solr in the header of a response</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:variable name="params" select="(//lst[@name='params'])[1]" />
    
    <xd:doc>
        <xd:desc>
            <xd:p>access function to the params-list </xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:function name="utils:params">
        <xsl:param name="param-name"></xsl:param>
        <xsl:param name="default-value"></xsl:param>
        <xsl:value-of select="if(exists($params/*[@name=$param-name])) then $params/*[@name=$param-name] else $default-value "></xsl:value-of>
    </xsl:function>

    <xsl:function name="utils:uri-encode">
        <xsl:param name="value"></xsl:param>
        <xsl:value-of select="encode-for-uri($value)" />
<!--        perhaps whitespaces is enough - seems not (umlaute!)-->
<!--        <xsl:value-of select="replace($value,' ','%20')" />-->
    </xsl:function>
    


    <xd:doc >
        <xd:desc>
            <xd:p>does the sub-calls </xd:p>
            <xd:p>uses XSLT-2.0 function: <xd:ref name="doc-available()" type="function"/></xd:p>
        </xd:desc>
        <xd:param name="q">the query string; default is the query of the original result </xd:param>
        <xd:param name="link">url to retrieve; overrides the q-param</xd:param>
    </xd:doc>
    <xsl:template name="subrequest" >
        <xsl:param name="q" select="utils:params('q','*:*')" />
        <xsl:param name="qkey" select="utils:params('qkey','all')" />
        
        <xsl:param name="link" select="concat($baseurl, $base-link, 'q=', utils:uri-encode($q[1]), '&amp;qkey=', utils:uri-encode(($qkey,$q)[1]))" />
        <xsl:message>DEBUG qkey: <xsl:value-of select="exists($qkey)" /></xsl:message>
        <xsl:message>DEBUG1: subrequest: <xsl:value-of select="$link" /></xsl:message>        
        
        <xsl:choose>
            <xsl:when test="doc-available($link)" >
                <xsl:copy-of select="doc($link)" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>WARNING: subrequest failed! <xsl:value-of select="$link"></xsl:value-of></xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>  
    
    <xd:doc>
        <xd:desc>
            <xd:p>generates a link out of the param-list, but leaves out special parameters (q, qx, baseq, wt)</xd:p>
            <xd:p>used as base for subrequests</xd:p>
        </xd:desc>
        <xd:param name="params"></xd:param>
    </xd:doc>    
    <xsl:template name="base-link">
        <xsl:param name="params" select="$params" />
<!--        <xsl:apply-templates select="$params/*[not(@name='q')][not(@name='qx')][not(@name='qxkey')][not(@name='baseq')][not(@name='wt')]" mode="link"></xsl:apply-templates>        -->
                <xsl:apply-templates select="$params/*[not(@name=('q', 'qx', 'qkey', 'qxkey', 'baseq', 'wt'))]" mode="link"></xsl:apply-templates>        
    </xsl:template>        
    
    
    <xd:doc>
        <xd:desc>
            <xd:p>(re)generates a link out of the param-list in the result</xd:p>
        </xd:desc>
    </xd:doc>    
    <xsl:template name="link" >        
        <xsl:variable name="link" ><xsl:text>?</xsl:text><xsl:apply-templates select="$params" mode="link" /></xsl:variable>
        <a href="{$link}"><xsl:value-of select="$link" /></a>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p></xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="lst[@name='params']/str"  mode="link">
        <xsl:value-of select="concat(@name,'=',utils:uri-encode(.),'&amp;')" />
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p></xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="lst[@name='params']/arr" mode="link">        
        <xsl:apply-templates  mode="link"/>        
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p></xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="lst[@name='params']/arr/str" mode="link">        
        <xsl:value-of select="concat(../@name,'=', utils:uri-encode(.),'&amp;')" />
        
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p>in link-mode discard any text-nodes not handled explicitely</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="text()" mode="link"/>
    
    <xd:doc >
        <xd:desc>
            <xd:p>generate a header for the response (params, result-info)</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template name="response-header" >
        <!--<xsl:for-each select="result">-->
        <div class="response-header">
            <xsl:apply-templates select="$params"  mode="query-input"/>
<!--            <span class="label">hits: </span><span class="value hilight"><xsl:value-of select="utils:format-number(//result/@numFound, '#.###')" /></span>-->
        </div>
    </xsl:template>
    
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>generate a tabled form out of the params</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template name="query-input" match="lst[@name='params']" mode="query-input">
        <form>        
            <table border="0">                
                <xsl:apply-templates mode="form" />
            </table>
            <input type="submit" value="search" />
            <xsl:call-template name="link" />
        </form>
    </xsl:template>
    
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p></xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="lst[@name='params']/str" mode="form" >
        <tr><td border="0" ><xsl:value-of select="@name" />:</td>
            <td><input type="text" name="{@name}"  value="{.}" /></td></tr>
    </xsl:template>
    
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p></xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="lst[@name='params']/arr" mode="form" >
        <tr><td border="0" valign="top"><xsl:value-of select="@name" />:</td>
            <td><xsl:apply-templates  mode="form" />
            </td></tr>
    </xsl:template>
    
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p></xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="lst[@name='params']/arr/str" mode="form"  >        
        <input type="text" name="{../@name}"  value="{.}" /><br/>        
    </xsl:template>
    
    <xsl:template match="text()" mode="query-input"/>
    <xsl:template match="text()" mode="form"/>
    
    
    <xd:doc>
        <xd:desc>
            <xd:p>flatten array to node-sequence</xd:p>
            <xd:p>solr delivers parameters differently depending on 
                if they are one (&lt;str name="param">value&lt;/str>)
                or many (&lt;arr name="param">&lt;str>value1&lt;/str>&lt;str>value2&lt;/str>&lt;/arr>)
            </xd:p>
            <xd:p>this is to generate a flat node-sequence out of both structures, 
                so that it can be traversed in the same way
            </xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="*" mode="arrayize">
        
        <xsl:choose>
            <xsl:when test="name(.)='arr'">
                <xsl:copy-of select="*" />                    
            </xsl:when>
            <xsl:otherwise>
<!--                <xsl:copy-of select="exsl:node-set(.)" />-->
                <xsl:copy-of select="." />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
</xsl:stylesheet>

