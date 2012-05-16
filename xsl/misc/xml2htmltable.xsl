<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<!-- 
<purpose>generic conversion of data-sets in xml to a basic-view[HTML]</purpose>
<params>
<param name=""></param>
</params>
<history>
	<change on="2006?" type="created" by="vr"></change>	
	<change on="2007-04-23" type="add" by="vr">added read from /*/header/* to genHeader</change>	
	<change on="2012-05-14" by="vr">incorporated into cr-xq-xsl suite</change>
</history>
-->
    <xsl:output method="html" encoding="UTF-8"/>
    <xsl:include href="commons_v1.xsl"/>
    <xsl:variable name="title" select="''"/>
    <xsl:template name="continue-root">
        <div>
            <xsl:call-template name="genHeader"/>
            <xsl:call-template name="body"/>
        </div>
    </xsl:template>
    <xsl:template name="genHeader">
        <div class="note">
            <xsl:for-each select="/*/@*[name()!='title']">
                <span class="label">
                    <xsl:value-of select="name()"/>: </span>
                <em>
                    <xsl:value-of select="."/>
                </em>;
					</xsl:for-each>
            <xsl:for-each select="/*/header/*[.!='']">
                <span class="label">
                    <xsl:value-of select="name()"/>: </span>
                <em>
                    <xsl:value-of select="."/>
                </em>;
					</xsl:for-each>
            <xsl:for-each select="/*/header/*[count(@*)=1][.!='']">
                <span class="label">
                    <xsl:value-of select="@*[1]"/>: </span>
                <em>
                    <xsl:value-of select="."/>
                </em>;
					</xsl:for-each>
            <xsl:for-each select="/*/header/*[count(@*)=2]">
                <span class="label">
                    <xsl:value-of select="@*[1]"/>: </span>
                <em>
                    <xsl:value-of select="@*[2]"/>
                </em>;
					</xsl:for-each>
        </div>
    </xsl:template>
    <xsl:template name="title">
        <xsl:value-of select="name(/*)"/>
        <xsl:if test="/*/@title">: <xsl:value-of select="/*/@title"/>
        </xsl:if>
    </xsl:template>
    <xsl:template name="body">
    <!-- <document> -->
        <xsl:choose>
            <xsl:when test="/*/header">
                <xsl:apply-templates select="/*/*[position()&gt;1]"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>      

     <!-- </document> -->
    </xsl:template>
    <xsl:template match="*">
        <hr/>
        <div>
            <xsl:if test="parent::*">
                <xsl:value-of select="name()"/>
                <br/>
                <xsl:call-template name="node-attrs"/>
            </xsl:if>
            <xsl:if test="*">
                <xsl:call-template name="children2table"/>
            </xsl:if>
        </div>
    </xsl:template>
    <xsl:template name="node-attrs">
        <xsl:for-each select="@*">
            <xsl:value-of select="name()"/>: <xsl:value-of select="."/>
            <xsl:if test="not(position()=last())">; </xsl:if>
        </xsl:for-each>
    </xsl:template>
    <xsl:template name="children2table">
        <table><!-- <caption><xsl:value-of select="name()" /> (<xsl:call-template name="node-attrs" />)</caption> -->
            <thead>
                <tr>
                    <xsl:for-each select="*[1]/@*">
                        <th>
                            <xsl:value-of select="name()"/>
                        </th>
                    </xsl:for-each>
                    <xsl:for-each select="*[1]/*">
                        <th>
                            <xsl:value-of select="concat(position(),name())"/>
                        </th>
                    </xsl:for-each>
			<!-- <xsl:if test="$copy_cols" > 
				<th><xsl:value-of select="name(*[1])" /></th> -->
                </tr>
            </thead>
            <tbody>
                <xsl:for-each select="*">
                    <xsl:sort select="@key"/>
                    <tr>
                        <xsl:for-each select="@*">
                            <td>
                                <xsl:value-of select="."/>
                            </td>
                        </xsl:for-each>
                        <xsl:for-each select="(*|text())">
                            <td>
                                <xsl:value-of select="."/>
                            </td>
                        </xsl:for-each>
									<!--	<td><xsl:value-of select="." /></td>  -->
                    </tr>
                </xsl:for-each>
            </tbody>
        </table>
    </xsl:template>
    <xsl:template match="link">
        <a href="{.}">
            <xsl:value-of select="."/>
        </a>
    </xsl:template>
</xsl:stylesheet>