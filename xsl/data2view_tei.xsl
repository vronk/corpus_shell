<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:sru="http://www.loc.gov/zing/srw/" xmlns:html="http://www.w3.org/1999/xhtml" version="1.0" exclude-result-prefixes="html">

<!-- 
 stylesheet for formatting TEI-elements  inside a FCS/SRU-result.
the TEI-elements are expected without namespace (!) (just local names)
This is not nice, but is currently in results like that.

The templates are sorted by TEI-elements they match.
if the same transformation applies to multiple elements,
it is extracted into own named-template and called from the matching templates.
the named templates are at the bottom.
-->
    
    <!-- some special elements retained in data, due to missing correspondencies in tei 
        if it will get more, we should move to separate file -->
    <xsl:template match="aac_HYPH1" mode="record-data">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="aac_HYPH2" mode="record-data">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="aac_HYPH3" mode="record-data">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="bibl" mode="record-data">
        <xsl:call-template name="inline"/>
    </xsl:template>
    <xsl:template match="date" mode="record-data">
        <div class="date">
            <xsl:value-of select="."/>[<xsl:value-of select="@value"/>]
      </div>
    </xsl:template>
    <xsl:template match="div|p" mode="record-data">
        <xsl:copy>
            <xsl:apply-templates mode="record-data"/>
        </xsl:copy>
    </xsl:template>
   
  <!-- 
     TODO: this has to be broken down to individual children-elements.
     the styles should be moved to CSS and referenced by classes 
   -->
    <xsl:template match="entry" mode="record-data">
        <div class="profiletext">
            <div style="margin-top: 15px; background:rgb(242,242,242); border: 1px solid grey">
                <b>
                    <xsl:value-of select="form[@type='lemma']/orth[contains(@xml:lang,'Trans')]"/>
                    <xsl:if test="form[@type='lemma']/orth[contains(@xml:lang,'arabic')]">
                        <xsl:text> </xsl:text>(<xsl:value-of select="form[@type='lemma']/orth[contains(@xml:lang,'arabic')]"/>)</xsl:if>
                </b>
                <xsl:if test="gramGrp/gram[@type='pos']">
                    <span style="color:rgb(0,64,0)">
                        <xsl:text>           </xsl:text>[<xsl:value-of select="gramGrp/gram[@type='pos']"/>
                        <xsl:if test="gramGrp/gram[@type='subc']">; <xsl:value-of select="gramGrp/gram[@type='subc']"/>
                        </xsl:if>]</span>
                </xsl:if>
                <xsl:for-each select="form[@type='inflected']">
                    <div style="margin-left:30px">
                        <xsl:choose>
                            <xsl:when test="@ana='#adj_f'">
                                <b style="color:blue">
                                    <i>(f) </i>
                                </b>
                            </xsl:when>
                            <xsl:when test="@ana='#adj_pl'">
                                <b style="color:blue">
                                    <i>(pl) </i>
                                </b>
                            </xsl:when>
                            <xsl:when test="@ana='#n_pl'">
                                <b style="color:blue">
                                    <i>(pl) </i>
                                </b>
                            </xsl:when>
                            <xsl:when test="@ana='#v_pres_sg_p3'">
                                <b style="color:blue">
                                    <i>(pres) </i>
                                </b>
                            </xsl:when>
                        </xsl:choose>
                        <xsl:value-of select="orth[contains(@xml:lang,'Trans')]"/>
                        <xsl:if test="orth[contains(@xml:lang,'arabic')]">
                            <xsl:text> </xsl:text>(<xsl:value-of select="orth[contains(@xml:lang,'arabic')]"/>)</xsl:if>
                    </div>
                </xsl:for-each>
                <xsl:for-each select="sense">
                    <xsl:if test="def">
                        <div style="margin-top: 5px; border-top:0.5px dotted grey;">
                            <xsl:if test="def[@xml:lang='en']">
                                <xsl:value-of select="def[@xml:lang='en']"/>
                            </xsl:if>
                            <xsl:if test="def[@xml:lang='de']">
                                <xsl:text> </xsl:text>
                                <span style="color:rgb(126,126,126); font-style: italic">(<xsl:value-of select="def[@xml:lang='de']"/>)</span>
                            </xsl:if>
                        </div>
                    </xsl:if>
                    <xsl:if test="cit[@type='translation']">
                        <div style="margin-top: 5px; border-top:0.5px dotted grey;">
                            <xsl:if test="cit[(@type='translation')and(@xml:lang='en')]">
                                <xsl:value-of select="cit[(@type='translation')and(@xml:lang='en')]"/>
                            </xsl:if>
                            <xsl:if test="cit[(@type='translation')and(@xml:lang='de')]">
                                <xsl:text> </xsl:text>
                                <span style="color:rgb(126,126,126); font-style: italic">(<xsl:value-of select="cit[(@type='translation')and(@xml:lang='de')]"/>)</span>
                            </xsl:if>
                        </div>
                    </xsl:if>
                    <xsl:for-each select="cit[@type='example']">
                        <div style="margin-left:30px">
                            <xsl:value-of select="quote[contains(@xml:lang,'Trans')]"/>
                            <i>
                                <xsl:value-of select="cit[(@type='translation')and(@xml:lang='en')]"/>
                            </i>
                            <xsl:if test="cit[(@type='translation')and(@xml:lang='de')]">
                                <xsl:text> </xsl:text>
                                <span style="color:rgb(126,126,126); font-style: italic">(<xsl:value-of select="cit[(@type='translation')and(@xml:lang='de')]"/>)</span>
                            </xsl:if>
                        </div>
                    </xsl:for-each>
                </xsl:for-each>
            </div>
        </div>
    </xsl:template>
    <xsl:template match="lb" mode="record-data">
        <br/>
    </xsl:template>
    <xsl:template match="milestone" mode="record-data">
        <xsl:text>...</xsl:text>
    </xsl:template>
    <xsl:template match="pb" mode="record-data">
        <div class="pb">p. <xsl:value-of select="@n"/>
        </div>
    </xsl:template>
    <xsl:template match="persName | placeName" mode="record-data">
        <xsl:call-template name="inline"/>
    </xsl:template>
    <xsl:template match="rs" mode="record-data">
        <xsl:call-template name="inline"/>
    </xsl:template>
    <!-- handing over to aac:stand.xsl -->
    <xsl:template match="seg" mode="record-data">
        <xsl:apply-templates select="."/>
    </xsl:template>
    <!--
    <xsl:template match="seg[@type='header']" mode="record-data"/>
    <xsl:template match="seg[@rend='italicised']" mode="record-data">
        <em>
            <xsl:apply-templates mode="record-data"/>
        </em>
    </xsl:template>
    -->
        
    <!-- a rather sloppy section optimized for result from aacnames listPerson/tei:person -->
    <!-- this should occur only in lists, not in text-->
    <xsl:template match="tei:person" mode="record-data">
        <div class="person">
            <xsl:apply-templates select="tei:birth|tei:death|tei:occupation" mode="record-data"/>
            <div class="links">
                <ul>
                    <xsl:apply-templates select="tei:link" mode="record-data"/>
                </ul>
            </div>
        </div>
    </xsl:template>
    
    <!-- already used as title -->
    <xsl:template match="tei:person/tei:persName" mode="record-data"/>
    
    <!-- not really nice for output -->
    <xsl:template match="tei:sex" mode="record-data"/>
    <xsl:template match="tei:birth" mode="record-data">
        <div>
            <span class="label">geboren: </span>
            <span class="{local-name()}" data-when="{@when}">
                <xsl:value-of select="concat(@when, ', ', tei:placeName)"/>
            </span>
        </div>
    </xsl:template>
    <xsl:template match="tei:death" mode="record-data">
        <div>
            <span class="label">gestorben: </span>
            <span class="{local-name()}" data-when="{@when}">
                <xsl:value-of select="concat(@when, ', ', tei:placeName)"/>
            </span>
        </div>
    </xsl:template>
    <xsl:template match="tei:occupation" mode="record-data">
        <div class="{local-name()}">
            <xsl:value-of select="."/>
        </div>
    </xsl:template>
    <xsl:template match="tei:link" mode="record-data">
        <li>
            <a href="{@target}">
                <xsl:value-of select="@target"/>
            </a>
        </li>
    </xsl:template>
    
    
<!-- ************************ -->
<!-- named templates starting -->
    <xsl:template name="inline">
        <span class="{name()}">
            <xsl:value-of select="."/>
        </span>
    </xsl:template>
</xsl:stylesheet>