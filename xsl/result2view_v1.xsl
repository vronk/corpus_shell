<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:saxon="http://saxon.sf.net/" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:exsl="http://exslt.org/common"
    xmlns:sru="http://www.loc.gov/zing/srw/"
    xmlns:ccs="http://clarin.eu/ContentSearch"
    xmlns:diag="http://www.loc.gov/zing/srw/diagnostic/"    
    version="1.0" exclude-result-prefixes="saxon xs exsl diag">
<!--   
    <purpose> generate html view of a sru-result-set  (eventually in various formats).</purpose>
<history> 
<change on="2011-12-06" type="created" by="vr">based on cmdi/scripts/mdset2view.xsl retrofitted for XSLT 1.0</change>	
</history>
-->
    <!--  method="xhtml" is saxon-specific! prevents  collapsing empty <script> tags, that makes browsers choke -->
    <xsl:output method="xml" media-type="text/xhtml" indent="yes" encoding="UTF-8" doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN"/> 

    <xsl:include href="commons.xsl"/>
    <xsl:include href="data2view.xsl"/>
    
    
    <xsl:param name="mode" select="'html'"/>
    <xsl:param name="title">
        <xsl:text>Result Set</xsl:text>
    </xsl:param>

    <xsl:variable name="cols" >
    <col>all</col>    
    </xsl:variable>        
    
    <xsl:template name="continue-root">
       
        <xsl:for-each select="sru:searchRetrieveResponse">
            <xsl:apply-templates select="sru:diagnostics" />
            <div>
                <xsl:if test="contains($format, 'htmlpage')">
                    <xsl:call-template name="header"/>
                </xsl:if>
                 <!--<xsl:if test="contains($format, 'page')">
                    <xsl:call-template name="query-input"/>
                    </xsl:if> -->
  
           <xsl:apply-templates select="sru:records" mode="list"/>
    <!-- switch mode depending on the $format-parameter -->        
                <!--<xsl:choose> 
                    <xsl:when test="contains($format,'htmltable')">
                        <xsl:apply-templates select="records" mode="table"/>
                    </xsl:when>
                    <xsl:when test="contains($format,'htmllist')">
                        <xsl:apply-templates select="records" mode="list"/>
                    </xsl:when>
                    <xsl:when test="contains($format, 'htmlpagelist')">
                        <xsl:apply-templates select="records" mode="list"/>
                    </xsl:when>
                    <xsl:otherwise>mdset2view: unrecognized format: <xsl:value-of select="$format"/>
                    </xsl:otherwise>
                </xsl:choose>-->
            </div>
        </xsl:for-each>
    </xsl:template>
    
	<!-- sample header:	
<numberOfRecords>524</numberOfRecords>
    <echoedSearchRetrieveRequest>//Title[contains(.,'an')] /db/cmdi-mirror/silang_data 1 50</echoedSearchRetrieveRequest>
    <diagnostics>50</diagnostics>     -->

<xsl:template name="header">
        <div class="result-header">
            <xsl:attribute name="max_value">
                <xsl:value-of select="sru:numberOfRecords"/>
            </xsl:attribute>
            <xsl:variable name="cnt_hits" select="number(diagnostics)"/>
            <xsl:variable name="form_action" >
                <xsl:call-template name="formURL">                    
                </xsl:call-template>
             </xsl:variable>
            
            <form action="{$form_action}" method="get">
                <span class="label">hits: </span>
                <span class="value hilight">
                    <xsl:value-of select="sru:numberOfRecords"/>
                </span>;
		<span class="label">from:</span>
                <span>
                    <input type="text" name="startRecord" class="value start_record paging-input">
                        <xsl:attribute name="value">
                            <xsl:value-of select="$startRecord"/>
                        </xsl:attribute>
                    </input>
                </span>
                <span class="label">max:</span>
                <span>
                    <input type="text" name="maximumRecords" class="value maximum_records paging-input">
                        <xsl:attribute name="value">
                            <xsl:choose>
                                <xsl:when test="number($cnt_hits) &lt; number($maximumRecords)">
                                        <xsl:value-of select="$cnt_hits"/>        
                                </xsl:when>
                                <xsl:otherwise>
                                        <xsl:value-of select="$maximumRecords"/>
                                </xsl:otherwise>
                            </xsl:choose>                            
                        </xsl:attribute>
                    </input>
                </span>
                <xsl:if test="$repository != ''">
                    <input type="hidden" name="repository">
                        <xsl:attribute name="value">
                            <xsl:value-of select="$repository"/>
                        </xsl:attribute>
                    </input>
                </xsl:if>
                <input type="hidden" name="query">
                    <xsl:attribute name="value">
                        <xsl:value-of select="$q"/>
                    </xsl:attribute>
                </input>
                <input type="submit" value="" class="cmd cmd_reload"/>
                <xsl:variable name="prev_startRecord">
                    <xsl:choose>
                        <xsl:when test="number($startRecord) - number($maximumRecords) &gt; 0">
                            <xsl:value-of select="format-number(number($startRecord) - number($maximumRecords),'#')"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="1"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="next_startRecord">
                    <xsl:choose>
                        <xsl:when test="number($startRecord) + number($maximumRecords) &gt; number(numberOfRecords)">
                            <xsl:value-of select="$startRecord"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="format-number(number($startRecord) + number($maximumRecords),'#')"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="link_prev" >
                    <xsl:call-template name="formURL">
                        <xsl:with-param name="startRecord" select="$prev_startRecord" />
                        <xsl:with-param name="maximumRecords" select="$maximumRecords" />                        
                    </xsl:call-template>
                </xsl:variable>                
                <a class="internal prev" href="{$link_prev}">
                    <span>
                        <xsl:choose>
                            <xsl:when test="$startRecord = '1'">
                                <xsl:attribute name="class">
                                    <xsl:value-of select="'cmd cmd_prev disabled'"/>
                                </xsl:attribute>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:attribute name="class">
                                    <xsl:value-of select="'cmd cmd_prev '"/>
                                </xsl:attribute>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:text>prev</xsl:text>
                    </span>
                </a>
                <xsl:variable name="link_next" >
                    <xsl:call-template name="formURL">
                        <xsl:with-param name="startRecord" select="$next_startRecord" />
                        <xsl:with-param name="maximumRecords" select="$maximumRecords" />                        
                    </xsl:call-template>
                </xsl:variable>
                <a class="internal next" href="{$link_next}">
                    <span class="cmd cmd_next">
                        <xsl:choose>
                            <xsl:when test="number($startRecord) + number($maximumRecords) &gt;= number(numberOfRecords)">
                                <xsl:attribute name="class">
                                    <xsl:value-of select="'cmd cmd_next disabled'"/>
                                </xsl:attribute>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:attribute name="class">
                                    <xsl:value-of select="'cmd cmd_next '"/>
                                </xsl:attribute>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:text>next</xsl:text>
                    </span>
                </a>
                <span class="cmd cmd_detail"/>              
            </form>
        </div>
        <div class="note">
            <span class="label">echo: </span>
            <span class="value">
                <xsl:value-of select="sru:echoedSearchRetrieveRequest"/>
            </span>;<span class="label">duration: </span>
            <span class="value">
                <xsl:value-of select="sru:extraResponseData/duration"/>
            </span>;</div>
    </xsl:template>
    
    <xsl:template match="sru:records" mode="list">
        <table class="show">
            <thead>
                <tr>
                    <th>pos</th>
                    <th>record</th>
                </tr>
            </thead>
            <tbody>
                <xsl:apply-templates select="sru:record" mode="list"/>
            </tbody>
        </table>
    </xsl:template>
    
    <xsl:template match="sru:record" mode="list">
        <xsl:variable name="curr_record" select="."/>
   
        <xsl:variable name="fields">
            <div>
                <xsl:apply-templates select="*" mode="record-data"/>
            </div>
        </xsl:variable>
        <xsl:call-template name="record-table-row">
            <xsl:with-param name="fields" select="$fields"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template name="record-table-row">
        <xsl:param name="fields"/>
<!-- @field absolute_position compute records position over whole recordset, ie add `startRecord` (important when paging)
 -->
        <xsl:variable name="absolute_position" >
            <xsl:choose>
        <!--      CHECK: Does this check if $startRecord is a number, or is it an error?          -->
                <xsl:when test="number($startRecord)=number($startRecord)">
                        <xsl:value-of select="number($startRecord) + position() - 1"/>                    
                </xsl:when>
                <xsl:otherwise>
                        <xsl:value-of select="position()"/>
                </xsl:otherwise>
            </xsl:choose>                        
        </xsl:variable>
        
        <xsl:variable name="rec_uri" >
            <xsl:choose>
                <xsl:when test=".//sru:recordIdentifier">
                    <xsl:value-of select=".//sru:recordIdentifier"/>
                </xsl:when>
                <xsl:when test=".//ccs:Resource/@ref">
                    <xsl:value-of select=".//ccs:Resource/@ref"/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- TODO: this won't work yet, the idea is to deliver only the one record as a fall-back
                        (i.e. when there is no other view, no further link) supplied for the Resource) --> 
                    <xsl:call-template name="formURL">
                        <xsl:with-param name="action" select="'record'"></xsl:with-param>
                        <xsl:with-param name="q" select="$absolute_position"></xsl:with-param>
                    </xsl:call-template>    
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>    
        <tr>
            <td rowspan="2" valign="top">
                <xsl:choose>
                    <xsl:when test="$rec_uri">
                           <!-- it was: htmlsimple, htmltable -link-to-> htmldetail; otherwise -> htmlpage -->
<!--                        <a class="internal" href="{my:formURL('record', $format, my:encodePID(.//recordIdentifier))}">-->
                        
                        <a class="internal" href="{$rec_uri}">
                            <xsl:value-of select="$absolute_position"/>
                        </a>                        
<!--                        <span class="cmd cmd_save"/>-->
                    </xsl:when>
                    <xsl:otherwise>
<!-- FIXME: generic link somewhere anyhow! -->
                        <xsl:value-of select="$absolute_position"/>
                    </xsl:otherwise>
                </xsl:choose>
            </td>
            <td>
                <!--
                    TODO: handle context
                    <xsl:call-template name="getContext"/>-->
                <div class="title">
                    <xsl:call-template name="getTitle"/>
                </div>
            </td>
        </tr>
        <tr>
            <td>
                <xsl:copy-of select="$fields"/>
            </td>
        </tr>
    </xsl:template>
    
    <xsl:template match="sru:diagnostics">
        <div class="error">
            <xsl:apply-templates></xsl:apply-templates>
        </div>
    </xsl:template>
    
    <xsl:template match="diag:diagnostic">        
            <xsl:value-of select="diag:message" /> (<xsl:value-of select="diag:uri" />)
    </xsl:template>
    
</xsl:stylesheet>