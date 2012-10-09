<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<!-- ********************************************************* -->
<!-- This stylesheet is used to display the output of comments -->
<!-- adapted from aac:stand.xsl ( removed root template)   -->
<!-- ********************************************************* -->



<!--    <xsl:variable name="marginLeft" select="'margin-left:100px;'"/>-->
    <xsl:variable name="marginLeft" select="''"/>
    <xsl:template match="bibl">
        <span style="color:rgb(128,0,255);">
            <b>[</b>
            <xsl:apply-templates/>
            <b>]<sup>b</sup>
            </b>
        </span>
    </xsl:template>
    <xsl:template match="byline">
        <span style="color:rgb(82,155,51);font-size:14pt;">
            <p style="margin-left:100px;">
                <xsl:apply-templates/>
            </p>
        </span>
    </xsl:template>
    <xsl:template match="cit">
        <span style="color:rgb(7,124,43);">
            <b>[</b>
        </span>
        <xsl:apply-templates/>
        <span style="color:rgb(7,124,43);">
            <b>]<sup>cit</sup>
            </b>
        </span>
    </xsl:template>
    <xsl:template match="corr">
        <xsl:if test="@cert[.='high']">
            <span style="color:rgb(255,0,0);">
                <sup>
                    <i>
                        <xsl:apply-templates/>
                    </i>
                </sup>
            </span>
        </xsl:if>
        <xsl:if test="@cert[.='low']">
            <span style="color:rgb(128,0,255);">
                <sup>
                    <i>
                        <xsl:apply-templates/>
                    </i>
                </sup>
            </span>
        </xsl:if>
    </xsl:template>
    <xsl:template match="sic">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="reg">
        <span style="color:rgb(236,118,0);">
            <sup>
                <i>
                    <xsl:apply-templates/>
                </i>
            </sup>
        </span>
    </xsl:template>
    <xsl:template match="orig">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="date">
        <span style="color:rgb(0,89,0);">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <xsl:template match="div">
        <xsl:choose>
            <xsl:when test="@type[.='compTitle']">
                <span style="color:rgb(204,0,0);font-size:14pt;">
                    <xsl:apply-templates/>
                </span>
            </xsl:when>
            <xsl:otherwise>
                <table style="margin-left:100px;">
                    <tr>
                        <td style="border: 1px solid black;">
                            <xsl:value-of select="@ana"/>&#160;<xsl:value-of select="@type"/>
                        </td>
                        <td>
                            <hr style="color:blue;width:300px;"/>
                        </td>
                    </tr>
                </table>
                <xsl:apply-templates/>
                <table style="margin-left:100px;">
                    <tr>
                        <td>
                            <hr style="color:red;width:100px;"/>
                        </td>
                    </tr>
                </table>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template name="emptyLine">
        <xsl:param name="line"/>
        <xsl:param name="mid"/>
        <xsl:variable name="brID">
            <xsl:value-of select="$mid"/>_<xsl:value-of select="$line"/>
        </xsl:variable>
        <xsl:if test="$line &gt; 0">
            <br>
                <xsl:attribute name="style">font-family:'Arial Unicode MS';font-size:13pt;</xsl:attribute>
                <xsl:attribute name="id">
                    <xsl:value-of select="$brID"/>
                </xsl:attribute>
            </br>
            <xsl:call-template name="emptyLine">
                <xsl:with-param name="line" select="$line - 1"/>
                <xsl:with-param name="mid" select="$mid"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    <xsl:template match="epigraph">
        <table style="margin-left:100px;">
            <tr>
                <td style="border: 1px solid black;">epigraph</td>
                <td>
                    <hr style="color:blue;width:300px;"/>
                </td>
            </tr>
        </table>
        <xsl:apply-templates/>
        <table style="margin-left:100px;">
            <tr>
                <td>
                    <hr style="color:red;width:100px;"/>
                </td>
            </tr>
        </table>
    </xsl:template>
    <xsl:template match="figure">
        <xsl:choose>
            <xsl:when test="child::p">
                <br/>
                <table style="border: 3px solid olivedrab;font-size:10pt;padding:3px 3px 3px 3px;margin-left:100px;">
                    <tr>
                        <td style="border: 1px solid black;">
                            <xsl:apply-templates/>
                        </td>
                    </tr>
                </table>
                <br/>
            </xsl:when>
            <xsl:when test="child::lg">
                <br/>
                <table style="border: 3px solid olivedrab;font-size:10pt;padding:3px 3px 3px 3px;margin-left:100px;">
                    <tr>
                        <td style="border: 1px solid black;">
                            <xsl:apply-templates/>
                        </td>
                    </tr>
                </table>
                <br/>
            </xsl:when>
            <xsl:otherwise>
                <br/>
                <table style="border: 3px solid olivedrab;margin-left:100px;">
                    <tr>
                        <td style="border: 1px solid black;width:150px;height:100px;">
                            <xsl:apply-templates/>
                        </td>
                    </tr>
                </table>
                <br/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="foreign">
        <xsl:apply-templates/>
        <xsl:if test="@xml:lang">
            <sup>
                <xsl:value-of select="@xml:lang"/>
            </sup>
        </xsl:if>
    </xsl:template>
    <xsl:template match="fw">
        <xsl:choose>
            <xsl:when test="@place[.='top_right']">
                <span style="text-align:right">
                    <xsl:apply-templates/>
                </span>
            </xsl:when>
            <xsl:when test="@place[.='top_left']">
                <span style="text-align:left">
                    <xsl:apply-templates/>
                </span>
            </xsl:when>
            <xsl:when test="@place[.='top_center']">
                <span style="width:330px;text-align:center">
                    <xsl:apply-templates/>
                </span>
            </xsl:when>
            <xsl:when test="@place[.='bot_right']">
                <span style="width:300px;text-align:right">
                    <xsl:apply-templates/>
                </span>
            </xsl:when>
            <xsl:when test="@place[.='bot_left']">
                <span style="width:380px;text-align:left">
                    <xsl:apply-templates/>
                </span>
            </xsl:when>
            <xsl:when test="@place[.='bot_center']">
                <span style="width:330px;text-align:center">
                    <xsl:apply-templates/>
                </span>
            </xsl:when>
            <xsl:when test="@type[.='marginalNote']">
                <div>
                    <xsl:choose>
                        <xsl:when test="@place[.='right']">
                            <xsl:attribute name="style">position:absolute;left:650px;font-family:'Arial Unicode MS';font-size:10pt;</xsl:attribute>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="style">position:absolute;left:20px;font-family:'Arial Unicode MS';font-size:10pt;</xsl:attribute>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:variable name="mID">m<xsl:value-of select="count(preceding::p) + count(preceding::lg)"/>
                    </xsl:variable>
                    <xsl:choose>
                        <xsl:when test="@aac_ord">
                            <xsl:attribute name="id">
                                <xsl:value-of select="$mID"/>_<xsl:value-of select="@aac_ord"/>
                            </xsl:attribute>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="id">
                                <xsl:value-of select="$mID"/>
                            </xsl:attribute>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:if test="@aac_line">
                        <xsl:choose>
                            <xsl:when test="@aac_ord">
                                <xsl:call-template name="emptyLine">
                                    <xsl:with-param name="line" select="@aac_line - 1"/>
                                    <xsl:with-param name="mid">
                                        <xsl:value-of select="$mID"/>_<xsl:value-of select="@aac_ord"/>
                                    </xsl:with-param>
                                </xsl:call-template>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:call-template name="emptyLine">
                                    <xsl:with-param name="line" select="@aac_line - 1"/>
                                    <xsl:with-param name="mid" select="$mID"/>
                                </xsl:call-template>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:if>
                    <xsl:apply-templates/>
                </div>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="gap">
        <xsl:apply-templates/>
        <xsl:if test="@unit">
            <span style="font-family:arial Unicode MS;color:darkmagenta;background:lemonchiffon">
                <sup>
                    <xsl:value-of select="@unit"/>&#160;</sup>
            </span>
        </xsl:if>
    </xsl:template>
    <xsl:template match="head">
        <xsl:choose>
            <xsl:when test="@type[.='desc']">
                <span style="color:rgb(73,84,182);font-size:14pt;">
                    <p style="margin-left:100px;">
                        <xsl:apply-templates/>
                    </p>
                </span>
            </xsl:when>
            <xsl:when test="@type[.='imprint']">
                <span style="color:rgb(128,128,128);font-size:14pt;">
                    <p style="margin-left:100px;">
                        <xsl:apply-templates/>
                    </p>
                </span>
            </xsl:when>
            <xsl:when test="@type[.='main']">
                <span style="color:rgb(204,0,0);font-size:14pt;">
                    <p style="margin-left:100px;">
                        <xsl:apply-templates/>
                    </p>
                </span>
            </xsl:when>
            <xsl:when test="@type[.='sub']">
                <span style="color:rgb(215,107,0);font-size:14pt;">
                    <p style="margin-left:100px;">
                        <xsl:apply-templates/>
                    </p>
                </span>
            </xsl:when>
            <xsl:otherwise>
                <p style="margin-left:100px;">
                    <xsl:apply-templates/>
                </p>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="imprint">
        <table style="margin-left:100px;">
            <tr>
                <td style="border: 1px solid black;">imprint</td>
                <td>
                    <hr style="color:blue;width:300px;"/>
                </td>
            </tr>
        </table>
        <xsl:apply-templates/>
        <table style="margin-left:100px;">
            <tr>
                <td style="width:50px;">&#160;</td>
                <td>
                    <hr style="color:red;width:300px;"/>
                </td>
            </tr>
        </table>
    </xsl:template>
    <xsl:template match="l">
        <span style="color:rgb(0,128,0)">
            <xsl:apply-templates/>
        </span>
        <br/>
    </xsl:template>
    <xsl:template match="lb">
        <xsl:apply-templates/>
        <br/>
    </xsl:template>

<!--
<xsl:template match="lg">
<xsl:choose>
<xsl:when test="@aac_part[.='I'] and @rend[.='indent']"><span style="background:rgb(255,211,168);"><p>     <xsl:apply-templates/></p></span></xsl:when>
<xsl:when test="@rend[.='indent']"><p>     <xsl:apply-templates/></p></xsl:when>
<xsl:when test="@aac_part[.='I']"><span style="background:rgb(255,211,168);"><p><xsl:apply-templates/></p></span></xsl:when>
<xsl:when test="@aac_part[.='M']"><span style="background:rgb(244,255,196);"><p><xsl:apply-templates/></p></span></xsl:when>
<xsl:when test="@aac_part[.='F']"><span style="background:rgb(205,223,254)"><p><xsl:apply-templates/></p></span></xsl:when>
<xsl:otherwise>
<p><xsl:apply-templates/></p>
</xsl:otherwise>
</xsl:choose>
</xsl:template>
-->
    <xsl:template match="lg">
        <p>
            <xsl:attribute name="id">p<xsl:value-of select="count(preceding::p) + count(preceding::lg)"/>
            </xsl:attribute>
            <xsl:choose>
                <xsl:when test="@part[.='I'] and @rend[.='indent']">
                    <xsl:attribute name="style">background:rgb(255,211,168);margin-left:100px;font-family:'Arial Unicode MS';font-size:12pt;</xsl:attribute>&#160;&#160;&#160;&#160;&#160;</xsl:when>
                <xsl:when test="@rend[.='indent']">
                    <xsl:attribute name="style">margin-left:100px;font-family:'Arial Unicode MS';font-size:12pt;</xsl:attribute>&#160;&#160;&#160;&#160;&#160;</xsl:when>
                <xsl:when test="@aac_part[.='I']">
                    <xsl:attribute name="style">background:rgb(255,211,168);font-family:'Arial Unicode MS';font-size:12pt;<xsl:value-of select="$marginLeft"/>
                    </xsl:attribute>
                </xsl:when>
                <xsl:when test="@aac_part[.='M']">
                    <xsl:attribute name="style">background:rgb(244,255,196);font-family:'Arial Unicode MS';font-size:12pt;<xsl:value-of select="$marginLeft"/>
                    </xsl:attribute>
                </xsl:when>
                <xsl:when test="@aac_part[.='F']">
                    <xsl:attribute name="style">background:rgb(205,223,254);font-family:'Arial Unicode MS';font-size:12pt;<xsl:value-of select="$marginLeft"/>
                    </xsl:attribute>
                </xsl:when>
                <xsl:when test="ancestor::figure">
                    <xsl:attribute name="style">font-family:'Arial Unicode MS';font-size:12pt;</xsl:attribute>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="style">font-family:'Arial Unicode MS';font-size:12pt;<xsl:value-of select="$marginLeft"/>
                    </xsl:attribute>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates/>
        </p>
    </xsl:template>
    <xsl:template match="milestone">
        <xsl:choose>
            <xsl:when test="@type[.='hr'] and @rend[.='line']">
                <hr style="text-align:left;margin-left:100px;width:350px;"/>
            </xsl:when>
            <xsl:when test="@type[.='hr'] and @rend[.='high']">
                <table style="border: 3px solid Darkgrey;padding:3px 3px 3px 3px;margin-left:100px;">
                    <tr>
                        <td style="border: 1px solid black;width:340px;height:50px;">
                            <xsl:apply-templates/>
                        </td>
                    </tr>
                </table>
                <br/>
            </xsl:when>
            <xsl:when test="@type[.='hr'] and @rend[.='dotted']">................................<br/>
            </xsl:when>
            <xsl:when test="@type[.='separator'] and @rend[.='asterisk']">
                <p style="text-align:center">*</p>
            </xsl:when>
            <xsl:when test="@type[.='separator'] and @rend[.='asterism']">
                <p style="text-align:center">*&#160;&#160;*&#160;&#160;*</p>
            </xsl:when>
            <xsl:when test="@type[.='separator'] and @rend[.='asterismUp']">
                <p style="text-align:center">*&#160;&#160;<sup>*</sup>&#160;&#160;*</p>
            </xsl:when>
            <xsl:when test="@type[.='separator'] and @rend[.='asterismDown']">
                <p style="text-align:center">*&#160;&#160;<sub>*</sub>&#160;&#160;*</p>
            </xsl:when>
            <xsl:when test="@type[.='separator'] and @rend[.='hr']">
                <hr style="width:100px;text-align:center"/>
            </xsl:when>
            <xsl:when test="@type[.='separator'] and @rend[.='undefined']">
                <p style="margin-left:100px;width:330px;text-align:center">⌫⌦</p>
            </xsl:when>
            <xsl:when test="@type[.='symbol'] and @rend[.='blEtc']">રc.</xsl:when>
            <xsl:when test="@type[.='symbol'] and @rend[.='brackets']">
                <span style="font-size:18pt;">)(</span>
            </xsl:when>
            <xsl:when test="@type[.='symbol'] and @rend[.='flower']">✾</xsl:when>
            <xsl:when test="@type[.='symbol'] and @rend[.='undefined']">
                <b>☉</b>
            </xsl:when>
            <xsl:otherwise>
                <b>?S?</b>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="name">
        <xsl:choose>
            <xsl:when test="@type[.='auctor']">
                <span style="color:rgb(0,128,255);">
                    <xsl:apply-templates/>
                </span>
            </xsl:when>
            <xsl:when test="@type[.='translator']">
                <span style="color:rgb(0,128,255);">
                    <xsl:apply-templates/>
                </span>
            </xsl:when>
            <xsl:when test="@type[.='editor']">
                <span style="color:rgb(0,128,255);">
                    <xsl:apply-templates/>
                </span>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

<!--
<xsl:template match="p">
<xsl:choose>
<xsl:when test="@aac_part[.='I'] and @rend[.='indent']"><span style="background:rgb(255,211,168);"><p>     <xsl:apply-templates/></p></span></xsl:when>
<xsl:when test="@rend[.='indent']"><p>     <xsl:apply-templates/></p></xsl:when>
<xsl:when test="@aac_part[.='I']"><span style="background:rgb(255,211,168);"><p><xsl:apply-templates/></p></span></xsl:when>
<xsl:when test="@aac_part[.='M']"><span style="background:rgb(244,255,196);"><p><xsl:apply-templates/></p></span></xsl:when>
<xsl:when test="@aac_part[.='F']"><span style="background:rgb(205,223,254)"><p><xsl:apply-templates/></p></span></xsl:when>
<xsl:otherwise><p><xsl:apply-templates/></p></xsl:otherwise>
</xsl:choose>
</xsl:template>
-->
    <xsl:template match="p">
        <p>
            <xsl:attribute name="id">p<xsl:value-of select="count(preceding::p) + count(preceding::lg)"/>
            </xsl:attribute>
            <xsl:choose>
                <xsl:when test="@part[.='I'] and @rend[.='indent']">
                    <xsl:attribute name="style">background:rgb(255,211,168);margin-left:100px;font-family:'Arial Unicode MS';font-size:12pt;</xsl:attribute>&#160;&#160;&#160;&#160;&#160;</xsl:when>
                <xsl:when test="@rend[.='indent']">
                    <xsl:attribute name="style">margin-left:100px;font-family:'Arial Unicode MS';font-size:12pt;</xsl:attribute>&#160;&#160;&#160;&#160;&#160;</xsl:when>
                <xsl:when test="@aac_part[.='I']">
                    <xsl:attribute name="style">background:rgb(255,211,168);font-family:'Arial Unicode MS';font-size:12pt;<xsl:value-of select="$marginLeft"/>
                    </xsl:attribute>
                </xsl:when>
                <xsl:when test="@aac_part[.='M']">
                    <xsl:attribute name="style">background:rgb(244,255,196);font-family:'Arial Unicode MS';font-size:12pt;<xsl:value-of select="$marginLeft"/>
                    </xsl:attribute>
                </xsl:when>
                <xsl:when test="@aac_part[.='F']">
                    <xsl:attribute name="style">background:rgb(205,223,254);font-family:'Arial Unicode MS';font-size:12pt;<xsl:value-of select="$marginLeft"/>
                    </xsl:attribute>
                </xsl:when>
                <xsl:when test="ancestor::figure">
                    <xsl:attribute name="style">font-family:'Arial Unicode MS';font-size:12pt;</xsl:attribute>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="style">font-family:'Arial Unicode MS';font-size:12pt;<xsl:value-of select="$marginLeft"/>
                    </xsl:attribute>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates/>
        </p>
    </xsl:template>
    <xsl:template match="pb">
        <p style="color:rgb(196,196,196);">.......................................................................................</p>
    </xsl:template>
    <xsl:template match="persName">
        <span style="color:rgb(0,108,0);text-decoration:none;">
            <xsl:apply-templates/>
        </span>
        <span style="border:2px solid black;font-weight:bold;color:rgb(0,108,0);">
            <xsl:if test="@type">
                <sup>
                    <i>
                        <xsl:value-of select="@type"/>&#160;</i>
                </sup>
            </xsl:if>
            <xsl:if test="@subtype">
                <sup>
                    <i>
                        <xsl:value-of select="@subtype"/>&#160;</i>
                </sup>
            </xsl:if>
            <xsl:if test="@key">
                <sup>
                    <xsl:value-of select="@key"/>
                </sup>
            </xsl:if>
        </span>
    </xsl:template>
    <xsl:template match="placeName">
        <span style="color:rgb(196,0,0);text-decoration:none;">
            <b>[</b>
            <xsl:apply-templates/>
            <b>]</b>
        </span>
        <span style="border:2px solid black;font-weight:bold;color:rgb(186,0,0);">
            <xsl:if test="@type">
                <sup>
                    <i>
                        <xsl:value-of select="@type"/>&#160;</i>
                </sup>
            </xsl:if>
            <xsl:if test="@subtype">
                <sup>
                    <i>
                        <xsl:value-of select="@subtype"/>&#160;</i>
                </sup>
            </xsl:if>
            <xsl:if test="@key">
                <sup>
                    <xsl:value-of select="@key"/>
                </sup>
            </xsl:if>
        </span>
    </xsl:template>
    <xsl:template match="quote">
        <span style="background:rgb(255,255,128);">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <xsl:template match="rs">
        <xsl:choose>
            <xsl:when test="@type[.='game']">
                <span style="color:rgb(159,80,0);text-decoration:none;">
                    <b>[</b>
                    <xsl:apply-templates/>
                    <b>]</b>
                </span>
                <span style="border:2px solid black;font-weight:bold;color:rgb(196,98,0);">
                    <xsl:if test="@type">
                        <sup>
                            <i>
                                <xsl:value-of select="@type"/>&#160;</i>
                        </sup>
                    </xsl:if>
                    <xsl:if test="@subtype[.='fraud']">
                        <sup>
                            <i>
                                <span style="color:rgb(0,128,128);">fraud</span>&#160;</i>
                        </sup>
                    </xsl:if>
                    <xsl:if test="@subtype[.='fraud_']">
                        <sup>
                            <i>
                                <span style="color:rgb(0,128,128);">fraud_</span>&#160;</i>
                        </sup>
                    </xsl:if>
                    <xsl:if test="@subtype[.='jargon']">
                        <sup>
                            <i>
                                <span style="color:rgb(0,0,255);">jargon</span>&#160;</i>
                        </sup>
                    </xsl:if>
                    <xsl:if test="@subtype[.='jargon_']">
                        <sup>
                            <i>
                                <span style="color:rgb(0,0,255);">jargon_</span>&#160;</i>
                        </sup>
                    </xsl:if>
                    <xsl:if test="@subtype[.='name']">
                        <sup>
                            <i>
                                <span style="color:rgb(0,183,46);">name</span>&#160;</i>
                        </sup>
                    </xsl:if>
                    <xsl:if test="@subtype[.='player']">
                        <sup>
                            <i>
                                <span style="color:rgb(202,0,0);">player</span>&#160;</i>
                        </sup>
                    </xsl:if>
                    <xsl:if test="@subtype[.='requisite']">
                        <sup>
                            <i>
                                <span style="color:rgb(102,102,102);">requisite</span>&#160;</i>
                        </sup>
                    </xsl:if>
                    <xsl:if test="@subtype[.='term']">
                        <sup>
                            <i>
                                <span style="color:rgb(102,0,204);">term</span>&#160;</i>
                        </sup>
                    </xsl:if>
                    <xsl:if test="@subtype[.='term_']">
                        <sup>
                            <i>
                                <span style="color:rgb(102,0,204);">term_</span>&#160;</i>
                        </sup>
                    </xsl:if>
                    <xsl:if test="@subtype[.='term_c']">
                        <sup>
                            <i>
                                <span style="color:rgb(102,0,204);">term_c</span>&#160;</i>
                        </sup>
                    </xsl:if>
                </span>
            </xsl:when>
            <xsl:when test="@type[.='profession']">
                <span style="color:rgb(91,91,91);text-decoration:none;">
                    <b>[</b>
                    <xsl:apply-templates/>
                    <b>]</b>
                </span>
                <span style="border:2px solid black;font-weight:bold;color:rgb(91,91,91);">
                    <xsl:if test="@type">
                        <sup>
                            <i>
                                <xsl:value-of select="@type"/>&#160;</i>
                        </sup>
                    </xsl:if>
                    <xsl:if test="@subtype[.='scientist']">
                        <sup>
                            <i>
                                <span style="color:rgb(0,0,255);">scientist</span>&#160;</i>
                        </sup>
                    </xsl:if>
                    <xsl:if test="@subtype[.='science']">
                        <sup>
                            <i>
                                <span style="color:rgb(0,183,46);">science</span>&#160;</i>
                        </sup>
                    </xsl:if>
                    <xsl:if test="@subtype[.='cleric']">
                        <sup>
                            <i>
                                <span style="color:rgb(202,0,0);">cleric</span>&#160;</i>
                        </sup>
                    </xsl:if>
                    <xsl:if test="@subtype[.='foolery']">
                        <sup>
                            <i>
                                <span style="color:rgb(0,128,192);">foolery</span>&#160;</i>
                        </sup>
                    </xsl:if>
                    <xsl:if test="@key">
                        <sup>
                            <xsl:value-of select="@key"/>
                        </sup>
                    </xsl:if>
                    <xsl:if test="@key2[.='attr']">
                        <sup>
                            <i>
                                <span style="color:rgb(0,128,128);">attr</span>&#160;</i>
                        </sup>
                    </xsl:if>
                    <xsl:if test="@key2[.='attr_s']">
                        <sup>
                            <i>
                                <span style="color:rgb(255,0,0);">attr_s</span>&#160;</i>
                        </sup>
                    </xsl:if>
                    <xsl:if test="@key2[.='habi']">
                        <sup>
                            <i>
                                <span style="color:rgb(175,29,54);">habi</span>&#160;</i>
                        </sup>
                    </xsl:if>
                    <xsl:if test="@key2[.='habi_']">
                        <sup>
                            <i>
                                <span style="color:rgb(175,29,54);">habi_</span>&#160;</i>
                        </sup>
                    </xsl:if>
                    <xsl:if test="@key2[.='imag']">
                        <sup>
                            <i>
                                <span style="color:rgb(102,0,204);">imag</span>&#160;</i>
                        </sup>
                    </xsl:if>
                    <xsl:if test="@key2[.='inst']">
                        <sup>
                            <i>
                                <span style="color:rgb(255,83,0);">inst</span>&#160;</i>
                        </sup>
                    </xsl:if>
                    <xsl:if test="@key2[.='parl']">
                        <sup>
                            <i>
                                <span style="color:rgb(174,0,174);">parl</span>&#160;</i>
                        </sup>
                    </xsl:if>
                    <xsl:if test="@key2[.='parl_']">
                        <sup>
                            <i>
                                <span style="color:rgb(174,0,174);">parl_</span>&#160;</i>
                        </sup>
                    </xsl:if>
                    <xsl:if test="@key2[.='pers']">
                        <sup>
                            <i>
                                <span style="color:rgb(0,0,0);">PERS</span>&#160;</i>
                        </sup>
                    </xsl:if>
                    <xsl:if test="@key2[.='pers_']">
                        <sup>
                            <i>
                                <span style="color:rgb(0,0,0);">PERS_</span>&#160;</i>
                        </sup>
                    </xsl:if>
                    <xsl:if test="@key2[.='sour']">
                        <sup>
                            <i>
                                <span style="color:rgb(0,0,0);">SOUR</span>&#160;</i>
                        </sup>
                    </xsl:if>
                </span>
            </xsl:when>
            <xsl:otherwise>
                <span style="color:rgb(0,0,187);text-decoration:none;">
                    <b>[</b>
                    <xsl:apply-templates/>
                    <b>]</b>
                </span>
                <span style="border:2px solid black;font-weight:bold;color:rgb(0,0,187);">
                    <xsl:if test="@type">
                        <sup>
                            <i>
                                <xsl:value-of select="@type"/>&#160;</i>
                        </sup>
                    </xsl:if>
                    <xsl:if test="@subtype">
                        <sup>
                            <i>
                                <xsl:value-of select="@subtype"/>&#160;</i>
                        </sup>
                    </xsl:if>
                    <xsl:if test="@key">
                        <sup>
                            <xsl:value-of select="@key"/>
                        </sup>
                    </xsl:if>
                </span>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="seg">
        <xsl:if test="@rend[.='initialCapital']">
            <xsl:choose>
                <xsl:when test="*">
                    <span style="font-size:25px;">
                        <xsl:apply-templates/>
                    </span>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="hstr">
                        <xsl:value-of select="."/>
                    </xsl:variable>
                    <xsl:choose>
                        <xsl:when test="ancestor::p and substring($hstr, 1,1) != '„'">
                            <span style="font-size:20px;">
                                <xsl:value-of select="substring($hstr, 1, 1)"/>
                            </span>
                            <xsl:value-of select="substring($hstr, 2)"/>
                        </xsl:when>
                        <xsl:when test="ancestor::lg and substring($hstr, 1,1) != '„'">
                            <span style="font-size:20px;">
                                <xsl:value-of select="substring($hstr, 1, 1)"/>
                            </span>
                            <xsl:value-of select="substring($hstr, 2)"/>
                        </xsl:when>
                        <xsl:when test="substring($hstr, 1,1) != '„'">
                            <span style="font-size:25px;">
                                <xsl:value-of select="substring($hstr, 1, 1)"/>
                            </span>
                            <xsl:value-of select="substring($hstr, 2)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="substring($hstr, 1, 1)"/>
                            <span style="font-size:25px;">
                                <xsl:value-of select="substring($hstr, 2, 1)"/>
                            </span>
                            <xsl:value-of select="substring($hstr, 3)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="@rend[.='antiqua'] and ancestor::fw">
                <span style="background:rgb(224,224,224);font-family:'Times New Roman';font-size:10pt;">
                    <xsl:apply-templates/>
                </span>
            </xsl:when>
            <xsl:when test="@rend[.='antiqua'] and ancestor::head">
                <span style="background:rgb(224,224,224);font-family:'Times New Roman';font-size:14pt;">
                    <xsl:apply-templates/>
                </span>
            </xsl:when>
            <xsl:when test="@rend[.='antiqua'] and ancestor::byline">
                <span style="background:rgb(224,224,224);font-family:'Times New Roman';font-size:14pt;">
                    <xsl:apply-templates/>
                </span>
            </xsl:when>
            <xsl:when test="@rend[.='antiqua']">
                <span style="background:rgb(224,224,224);font-family:'Times New Roman';font-size:13pt;">
                    <xsl:apply-templates/>
                </span>
            </xsl:when>
            <xsl:when test="@rend[.='bold']">
                <b>
                    <xsl:apply-templates/>
                </b>
            </xsl:when>
            <xsl:when test="@rend[.='gothic']">
                <xsl:apply-templates/>
            </xsl:when>
            <xsl:when test="@rend[.='italicised']">
                <i>
                    <xsl:apply-templates/>
                </i>
            </xsl:when>
            <xsl:when test="@rend[.='spaced']">
                <span style="color:rgb(0,0,255);letter-spacing:0.2em">
                    <xsl:apply-templates/>
                </span>
            </xsl:when>
            <xsl:when test="@rend[.='smallCaps']">
                <span style="font-variant:small-caps;font-size:12pt;">
                    <xsl:apply-templates/>
                </span>
            </xsl:when>
            <xsl:when test="@rend[.='sub']">
                <sub>
                    <span style="font-size:smaller;">
                        <xsl:apply-templates/>
                    </span>
                </sub>
            </xsl:when>
            <xsl:when test="@rend[.='sup']">
                <sup>
                    <span style="font-size:smaller;">
                        <xsl:apply-templates/>
                    </span>
                </sup>
            </xsl:when>
            <xsl:when test="@rend[.='underlined']">
                <u>
                    <xsl:apply-templates/>
                </u>
            </xsl:when>
            <xsl:when test="@type[.='enum']">
                <span style="color:rgb(221,111,0);">
                    <xsl:apply-templates/>
                </span>
            </xsl:when>
            <xsl:when test="@type[.='footer']">
                <span style="margin-left:100px;">
                    <xsl:apply-templates/>
                </span>
            </xsl:when>
            <xsl:when test="@type[.='header']">
                <xsl:choose>
                    <xsl:when test="descendant::fw[@place='top_center'] and fw[@place='top_right']">
                        <span style="margin-left:100px;">
                            <xsl:apply-templates/>
                        </span>
                    </xsl:when>
                    <xsl:when test="descendant::fw[@place='top_right'][not(@place='top_center')]">
                        <span style="margin-left:380px;">
                            <xsl:apply-templates/>
                        </span>
                    </xsl:when>
                    <xsl:otherwise>
                        <span style="margin-left:100px;">
                            <xsl:apply-templates/>
                        </span>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="@type[.='signature']">
                <span style="background:chocolate">
                    <xsl:apply-templates/>
                </span>
            </xsl:when>
            <xsl:when test="@rend[.='blackletter']">
                <span style="background:rgb(170,255,191);font-family:'Arial Unicode MS';font-size:12pt;">
                    <xsl:apply-templates/>
                </span>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="text">
        <span style="font-family:'Arial Unicode MS'">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <xsl:template match="table">
        <xsl:choose>
            <xsl:when test="ancestor::table">
                <table style="border: 1px solid black;">
                    <xsl:apply-templates/>
                </table>
            </xsl:when>
            <xsl:otherwise>
                <table style="border: 1px solid black;margin-left:100px;">
                    <xsl:apply-templates/>
                </table>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="row">
        <tr>
            <xsl:apply-templates/>
        </tr>
    </xsl:template>
    <xsl:template match="cell">
        <td>
            <xsl:attribute name="style">border: 1px solid black;vertical-align:top;</xsl:attribute>
            <xsl:if test="@cols">
                <xsl:attribute name="colspan">
                    <xsl:value-of select="@cols"/>
                </xsl:attribute>
            </xsl:if>
            <xsl:if test="@rows">
                <xsl:attribute name="rowspan">
                    <xsl:value-of select="@rows"/>
                </xsl:attribute>
            </xsl:if>
            <xsl:apply-templates/>
        </td>
    </xsl:template>
    <!--<xsl:template match="aac_HYPH1">
        <xsl:choose>
            <xsl:when test="@aac_cont">
                <xsl:attribute name="aac_cont">
                    <xsl:value-of select="@aac_cont"/>
                </xsl:attribute>
            </xsl:when>
        </xsl:choose>
        <xsl:apply-templates/>  <span style="color:red;">(<xsl:value-of select="@aac_cont"/>)</span>
    </xsl:template>
    -->
    <xsl:template match="aac_HYPH2">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="aac_HYPH3">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="aac_PREV"/>
    <xsl:template match="aac_NEXT"/>
    <xsl:template match="aac_IMAGE"/>
    <xsl:template match="aac_PAGE">
        <span style="font-family:'Arial Unicode MS'">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <xsl:template match="aac_DIV_END">
        <table style="border: 0px solid black;margin-left:100px;">
            <tr>
                <td style="width:50px;">&#160;</td>
                <td>
                    <hr style="color:red;width:300px;"/>
                </td>
            </tr>
        </table>
    </xsl:template>
    <xsl:template match="aac_DIV_START">
        <table style="border: 0px solid black;margin-left:100px;">
            <tr>
                <td style=" border: 1px solid black;">
                    <xsl:value-of select="@ana"/>&#160;<xsl:value-of select="@type"/>&#160;</td>
                <td>
                    <hr style="color:blue;width:300px;"/>
                </td>
            </tr>
        </table>
    </xsl:template>
</xsl:stylesheet>