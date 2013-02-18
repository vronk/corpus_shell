<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
        xmlns:saxon="http://saxon.sf.net/"    
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:utils="http://aac.ac.at/corpus_shell/utils"
    exclude-result-prefixes="xs saxon utils"
    version="2.0">

    
    
    <xsl:template name="hits">
    <xsl:param name="data" select="/"></xsl:param>
        <xsl:apply-templates select="$data//result" mode="hits"></xsl:apply-templates>    
    </xsl:template>
    
    <xsl:template match="result" mode="hits">
        
        <div class="result">
            <h3>Result list: <xsl:value-of select="(.//*[@name='params']/*[@name='q'], utils:params('q','')) [1]" ></xsl:value-of></h3>
            <span class="label">hits: </span><span class="value hilight"><xsl:value-of select="utils:format-number(@numFound, '#.###')" /></span>
            <span class="label">start, count: </span><span class="value"><xsl:value-of select="@start" />, <xsl:value-of select="utils:params('rows','')" /></span>
        <table class="show-lines">
            <xsl:apply-templates select="doc" mode="hits"></xsl:apply-templates>
        </table>
        </div>
    </xsl:template>
    
    <xsl:template match="doc"  mode="hits">
        <tr >
            <td valign="top" ><xsl:value-of select="position()"></xsl:value-of></td>
            <td><xsl:call-template name="get-kwic">
                <xsl:with-param name="id" select="*[@name='id']/text()"></xsl:with-param>
            </xsl:call-template>
            </td>
            <td>
                <xsl:apply-templates mode="hits" select="*[@name=('titel','docsrc','region', 'ressort2', 'year', 'date', 'tokens')]"></xsl:apply-templates>    
            </td>
        </tr>
    </xsl:template>
    
    <xsl:template match="doc/arr" mode="hits">
        <span class="field">
            <span class="label"><xsl:value-of select="@name"></xsl:value-of>: </span>
            <span class="value"><xsl:value-of select="string-join(*,', ')"/></span>, 
        </span>
    </xsl:template>
    
    <xsl:template match="doc/*[not(name()='arr')]" mode="hits">
        <span class="field">
            <span class="label"><xsl:value-of select="@name"></xsl:value-of>: </span>
            <span class="value"><xsl:value-of select="."/></span>, 
        </span>
    </xsl:template>
    
    <xsl:template name="get-kwic" >
    <xsl:param name="id"></xsl:param>
    
        <!-- 
        <xsl:variable name="highlights" select="//lst[@name='highlighting']/lst"></xsl:variable>
        stay contextual for the case of a multiresult -->
        <xsl:variable name="highlights" select="ancestor::result[@name='response']/lst[@name='highlighting']/lst"></xsl:variable>
        <xsl:choose>
            <xsl:when test="$highlights">
                <xsl:variable name="match" select="$highlights[@name=$id]" />
                <xsl:for-each select="$match/arr/*">
                    <xsl:variable name="parsed_match" select="saxon:parse(concat('&lt;span>', ., '&lt;/span>'))"></xsl:variable>
                    <div class="kwic"><xsl:copy-of select="$parsed_match" /></div>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <!-- how to get a context otherwise? 
                it seems unnecessary to get into some complicated fall-backs -->
            </xsl:otherwise>
        </xsl:choose>
            
    </xsl:template>
    
    <!--
        generic table view
    <xsl:template match="result" mode="hits">
        <table>
            <xsl:apply-templates mode="hits"></xsl:apply-templates>
        </table>
    </xsl:template>
    
    <xsl:template match="doc"  mode="hits">
        <tr>
            <td valign="top"><xsl:value-of select="position()"></xsl:value-of></td>
            <td><table><xsl:apply-templates mode="hits"/></table></td>
        </tr>
    </xsl:template>
    
    <xsl:template match="doc/*" mode="hits">
        <tr>
            <td><xsl:value-of select="@name"></xsl:value-of></td>
            <td><xsl:value-of select="."/></td>
        </tr>
    </xsl:template>
    --></xsl:stylesheet>