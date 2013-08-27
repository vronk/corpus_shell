<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns="http://www.w3.org/1999/xhtml" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:cmd="http://www.clarin.eu/cmd/"
    xmlns:sru="http://www.loc.gov/zing/srw/"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:exist="http://exist.sourceforge.net/NS/exist"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    version="1.1" exclude-result-prefixes="exist xd">

<xd:doc scope="stylesheet">
    <xd:desc>Stylesheet for custom formatting of CMD-records (inside a FCS/SRU-result).</xd:desc>
</xd:doc>
    
    <xsl:variable name="resourceref_limit" select="10"/>
    <xsl:template match="cmd:ResourceProxyList" mode="record-data">
        <xsl:choose>
            <xsl:when test="count(cmd:ResourceProxy) &gt; 1">
                <div class="resource-links">
                    <label>references </label>
                    <xsl:value-of select="count(cmd:ResourceProxy[cmd:ResourceType='Metadata'])"/>
                    <label> MDRecords, </label>
                    <xsl:value-of select="count(cmd:ResourceProxy[cmd:ResourceType='Resource'])"/>
                    <label> Resources</label>
                    <xsl:if test="count(cmd:ResourceProxy) &gt; $resourceref_limit">
                        <br/>
                        <label>showing first </label>
                        <xsl:value-of select="$resourceref_limit"/>
                        <label> references. </label> 
                            <!--   <s><a href="{concat($default_prefix, my:encodePID(./ancestor::CMD/Header/MdSelfLink))}">see more</a></s> -->
<!--                            <s><a href="{my:formURL('record', 'htmlpage', my:encodePID(./ancestor::cmd:CMD/cmd:Header/MdSelfLink))}">see more</a></s>-->
                    </xsl:if>
                    <ul class="detail">
                        <xsl:apply-templates select="cmd:ResourceProxy[position() &lt; $resourceref_limit]" mode="record-data"/>
                    </ul>
                </div>
            </xsl:when>
            <xsl:otherwise>
                <ul>
                    <xsl:apply-templates mode="record-data"/>
                </ul>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="cmd:ResourceProxy" mode="record-data">
        <xsl:variable name="href">
            <xsl:choose>
                <xsl:when test="cmd:ResourceType='Resource'">
                    <xsl:value-of select="cmd:ResourceRef"/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- XSL 2.0:
                    *******************
                            <xsl:function name="util:encodePID">
                                    <xsl:param name="pid"/>
                                    <xsl:value-of select="encode-for-uri(replace(replace($pid,'/','%2F'),'\.','%2E'))"/>
                            </xsl:function>
                    *******************
                    <xsl:value-of select="util:formURL('record', 'htmlpage', util:encodePID(ResourceRef))"/>
                    -->
                    <xsl:call-template name="formURL">
                        <xsl:with-param name="action">record</xsl:with-param>
                        <xsl:with-param name="format">htmlpage</xsl:with-param>
                        <xsl:with-param name="q"><xsl:value-of select="encode-for-uri(replace(replace(ResourceRef,'/','%2F'),'\.','%2E'))"/></xsl:with-param>
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- XPath 1.0 if trick: from http://stackoverflow.com/questions/971067/is-there-an-if-then-else-statement-in-xpath and
        http://www.tkachenko.com/blog/archives/000156.html Becker's method, relies on substring start argument bigger than string lenght
        returns empty string and number(false) = 0, number(true) = 1. -->
        <!-- XPath 2.0:  if (cmd:ResourceType='Resource') then 'external' else 'internal' -->
        <xsl:variable name="class" select="concat(
            substring('external', number(not(cmd:ResourceType='Resource')) * string-length('external') + 1),
            substring('internal', number(cmd:ResourceType='Resource') * string-length('internal') + 1)
            )"/>
        <li>
            <span class="label">
                <xsl:value-of select="cmd:ResourceType"/>: </span>
            <a class="{$class}" href="{$href}" target="_blank">
                <xsl:value-of select="cmd:ResourceRef"/>
            </a>
        </li>
    </xsl:template>
    <xsl:template match="@ComponentId" mode="format-attr"/>
</xsl:stylesheet>