<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:my="myFunctions" version="2.0">
<!-- 
<purpose> generate a view for a values-list (index scan) </purpose>
<params>
<param name=""></param>
</params>
<history>
	<change on="2011-01-08" type="created" by="vr">from model2view.xsl</change>
		
</history>
-->
    <xsl:import href="cmd_commons.xsl"/>


<!-- <xsl:param name="size_lowerbound">0</xsl:param>
<xsl:param name="max_depth">0</xsl:param>
<xsl:param name="freq_limit">20</xsl:param>
<xsl:param name="show">file</xsl:param> -->
    <xsl:param name="sort">x</xsl:param> <!-- s=size|n=name|t=time|x=default -->
    <xsl:param name="name_col_width">50%</xsl:param>

<!-- <xsl:param name="mode" select="'htmldiv'" /> -->
    <xsl:param name="title" select="concat('MDRepo.scan: ', my:xpath2index(/Terms/@scanClause))"/>

<!--
<xsl:param name="detail_uri_prefix"  select="'?q='"/> 
-->
    <xsl:output method="html"/>
    <xsl:decimal-format name="european" decimal-separator="," grouping-separator="."/>
    <xsl:template name="continue-root">
        <div class="cmds-ui-block  init-show">
            <xsl:call-template name="header"/>
            <div class="content">
                <xsl:apply-templates/>
            </div>

		<!-- 
		<xsl:choose>   	 	
    	 	 
    	 	<xsl:when test="$format='values2htmlpage'" >
    	 		<xsl:call-template name="header"/>
			    <div class="values">
			    	
				</div>	    	 
								    		
	  	 	</xsl:when>
    	 	<xsl:otherwise>
    	 		<xsl:call-template name="list"/>    
    	 	</xsl:otherwise>
    	 </xsl:choose>
    	  -->
        </div>
    </xsl:template>
    <xsl:template name="header">
	<!--  <h2>MDRepository Statistics - index values</h2>  -->
        <div class="header">
            <xsl:attribute name="max-value">
                <xsl:value-of select="/Terms/@count_items"/>
            </xsl:attribute>
            <xsl:attribute name="start-item">
                <xsl:value-of select="/Terms/@start-item"/>
            </xsl:attribute>
            <xsl:attribute name="maximum-items">
                <xsl:value-of select="/Terms/@max-items"/>
            </xsl:attribute>
            <xsl:value-of select="$title"/>
            <span class="cmd cmd_detail"/>
            <div class="ui-context-dialog">
                <table class="show">
                    <tbody>
                        <xsl:for-each select="(/Terms|/Terms/Term)/@*">
                            <tr>
                                <td class="key">
                                    <xsl:value-of select="name()"/>
                                </td>
                                <td>
                                    <xsl:call-template name="format-value"/>
                                </td>
                            </tr>
                        </xsl:for-each>
                    </tbody>
                </table>
            </div>
        </div>
    </xsl:template>
    <xsl:template match="Term">
        <xsl:variable name="index" select="my:xpath2index(@path)"/>
        <table>
            <xsl:for-each select="v">
                <tr>
                    <td align="right">
                        <xsl:value-of select="@count"/>
                    </td>
                    <td>
                        <span class="cmd cmd_columns"/>
                        <a class="value-caller" href="{my:formURL('','', concat($index, '%3D%22', @key, '%22'))}" target="_blank">
                            <xsl:value-of select="@key"/>
                        </a>
                    </td>
                </tr>
            </xsl:for-each>
        </table>
    </xsl:template>
    <xsl:template name="callback-header">
        <style type="text/css">
		#modeltree { margin-left: 10px; border: 1px solid #9999aa; border-collapse: collapse;}
		.number { text-align: right; }
		td { border-bottom: 1px solid #9999aa; padding: 1px 4px;}
		.treecol {padding-left: 1.5em;}
		table thead {background: #ccccff; font-size:0.9em; }
		table thead tr th { border:1px solid #9999aa; font-weight:normal; text-align:left; padding: 1px 4px;}

	</style>
        <script type="text/javascript">
		$(function(){
			$("#modeltree").treeTable({initialState:"expanded"});
			addPaging($('.cmds-ui-block'));
			
			
		});
	</script>
    </xsl:template>
</xsl:stylesheet>