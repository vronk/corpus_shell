<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:my="myFunctions" version="2.0">
<!-- 
<purpose> generate all the views for terms-matrix</purpose>
<params>
<param name=""></param>
</params>
<history>
	<change on="2010-10-11" type="created" by="vr">from model2view.xsl</change>		
</history>
-->
<!-- <xsl:import href="cmd_commons.xsl"/> -->
    <xsl:import href="../commons_v1.xsl"/>
<!--    <xsl:import href="cmd_functions.xsl"/>-->

<!--  <xsl:output method="xml" />  -->  

<!-- <xsl:param name="size_lowerbound">0</xsl:param>
<xsl:param name="max_depth">0</xsl:param>
<xsl:param name="freq_limit">20</xsl:param>
<xsl:param name="show">file</xsl:param> 
<xsl:param name="detail_uri_prefix"  select="'?q='"/> 
<xsl:param name="mode" select="'htmldiv'" /> -->
    <xsl:param name="x_maximumDepth" select="0"/>
    <xsl:param name="sort">x</xsl:param> <!-- s=size|n=name|t=time|x=default -->
    <xsl:param name="name_col_width">50%</xsl:param>
    <xsl:param name="title" select="'Terms'"/>
    <xsl:decimal-format name="european" decimal-separator="," grouping-separator="."/>
    <xsl:template name="continue-root">
        <div>
            <xsl:choose>
                <xsl:when test="$format='htmltable'">
                    <xsl:call-template name="header"/>
                    <xsl:call-template name="table"/>
                </xsl:when>
                <xsl:when test="$format='htmlpage' or $format='terms2htmldetail' ">
                    <xsl:call-template name="header"/>
                    <div id="terms-matrix">
                        <xsl:apply-templates mode="terms-tree">
                            <xsl:sort select="if (@type='model') then 1 else if (@type='dcr') then 2  else 3" data-type="number"/>
                        </xsl:apply-templates>
                    </div>
                </xsl:when>
                <xsl:when test="$format='terms2htmllist'">
                    <xsl:apply-templates select=".//Termset" mode="list">
                        <xsl:sort select="if (@type='model') then 1 else if (@type='dcr') then 2  else 3" data-type="number"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:when test="$format='terms2flat'">
                    <xsl:call-template name="terms-flat"/>
                </xsl:when>
                <xsl:when test="$format='terms2autocomplete'">
                    <xsl:variable name="terms_flat">
                        <xsl:call-template name="terms-flat"/>
                    </xsl:variable>
                    <xsl:apply-templates select="$terms_flat" mode="autocomplete"/>
                </xsl:when>
                <xsl:when test="$format='terms2htmlselect'">
                    <select id="terms-select">
                        <xsl:apply-templates select=".//Termset" mode="select"/>
                    </select>
<!--                    <a href="{my:formURL('terms','htmlpage','all')}">overview</a>-->
                    <a href="TODO:terms">overview</a>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select=".//Termset" mode="list"/>
                </xsl:otherwise>
            </xsl:choose>
        </div>
    </xsl:template>
    <xsl:template name="header">
        <h2>MDService Terms</h2>
        <table>
            <tbody>
                <tr>
                    <td>count Termsets</td>
                    <td align="right">
                        <xsl:value-of select="count(//Termset)"/>
                    </td>
                </tr>
            </tbody>
        </table>
    </xsl:template>
    <xsl:template name="table">
        <table>
            <caption>Terms Usage</caption>
            <thead>
                <tr>
                    <th>name/path</th>
                    <th>count elems</th>
                    <th>count text</th>
                    <th>count distinct text</th>
                    <th>context</th>
                    <th>corresp comp</th>
                    <th>datcat</th>
                </tr>
            </thead>
            <tbody>
                <xsl:apply-templates select="*" mode="table"/>
            </tbody>
        </table>
    </xsl:template>
    <xsl:template match="Term" mode="table">
        <tr>
            <td>
				<!-- <a href="?q={@path}" > -->
                <span class="cmd cmd_add"/>
                <span class="column-elem">
                    <xsl:value-of select="translate(@path,'/','.')"/>
                </span>
					<!-- </a> -->
            </td>
            <td align="right">
                <xsl:value-of select="@count"/>
            </td>
            <td align="right">
                <xsl:value-of select="@count_text"/>
            </td>
            <td align="right">
                <xsl:value-of select="@count_distinct_text"/>
            </td>
            <td>
                <xsl:value-of select="@context"/>
            </td>
            <td>
                <xsl:value-of select="@corresponding_component"/>
            </td>
            <td>
                <xsl:value-of select="@datcat"/>
            </td>
        </tr>
        <xsl:apply-templates select="*" mode="table"/>
    </xsl:template>
    <xsl:template match="Termset" mode="list">
        <div class="terms">
            <span class="detail-caller">
                <xsl:value-of select="@name"/>
            </span>
		<!-- <xsl:call-template name="attr-detail-div" /> -->
		<!--  format:<xsl:value-of select="$format" /> -->
		<!--<xsl:variable name="translated_term" select="translate(replace(/*/Term[1]/@path,'//',''),'/','.')" />
		 <input id="query_terms" value="{$translated_term}" /> -->
            <ul class="treeview">
                <xsl:apply-templates select="Term[@path]" mode="list"/>
            </ul>
        </div>
    </xsl:template>
    <xsl:template match="Term" mode="list">
        <xsl:param name="options" select="''"/>
		<!--  <xsl:variable name="translated_path" select="translate(replace(@path,'//',''),'/','.')" /> -->
		<!--  filter out empty datcats  -->
        <xsl:if test="@elem or descendant::*[@elem] or $options='all'">
            <li>
                <div class="cmds-elem-plus">
                    <span class="detail-caller"><!-- <a href="{concat($detail_model_prefix,@context)}" >  -->
                        <xsl:value-of select="@path"/>
                    </span>
                    <span class="note">|<xsl:value-of select="@count"/>|</span>
					<!--  /<xsl:value-of select="@count_text"/>/<xsl:value-of select="@count_distinct_text"/> -->
                    <span class="data comppath">
                        <xsl:value-of select="@path"/>
                    </span>
                    <span class="cmd cmd_filter">
                        <xsl:text> </xsl:text>
                    </span>
                    <span class="cmd cmd_detail">
                        <xsl:text> </xsl:text>
                    </span>
                    <span class="cmd cmd_columns">
                        <xsl:text> </xsl:text>
                    </span>
					<!-- <xsl:call-template name="attr-detail-div" /> -->
						<!--  <div class="detail">
							<xsl:for-each select="@*" >
								<div class="cmds-elem-prop"><span class="label"><xsl:value-of select="name()" />: </span>
									<span class="value"><xsl:value-of select="." /></span></div>
							</xsl:for-each>
						</div> -->
                </div>
                <ul>
                    <xsl:apply-templates select="Term" mode="list">
                        <xsl:with-param name="options" select="$options"/>
                    </xsl:apply-templates>
                </ul>
            </li>
        </xsl:if>
    </xsl:template>


<!--
both Termsets and Termset can be root level
sample
  <Termsets xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:my="myFunctions">
   <Termset name="TextCorpusProfile" colls="root" depth="8" created="2011-01-03T19:59:21.366+01:00" type="model" id="tcp" url="" format="terms|cmdrepo">
 -->
    <xsl:template match="Termsets|Termset|Terms" mode="terms-tree">
        <xsl:param name="parentid" select="'x'"/>
        <xsl:param name="lv" select="0"/>
        <xsl:variable name="xid" select="concat($parentid,position())"/>
	
	<!--  special handling for datcat and relcat termsets -->
        <xsl:variable name="self">
            <xsl:if test="@type='dcr' or @type='rr'">
                <tr id="{$xid}">
                    <td class="treecol">
                        <span class="cmd cmd_columns"/>
                        <xsl:value-of select="@name"/>
                    </td>
                    <td colspan="3"/>
                </tr>
            </xsl:if>
        </xsl:variable>
        <xsl:variable name="children">
            <xsl:apply-templates select="*" mode="terms-tree">
                <xsl:sort order="ascending" select="@name"/>
                <xsl:with-param name="parentid" select="$xid"/>
                <xsl:with-param name="lv" select="$lv+1"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$lv=0">
                <table class="terms-tree show">
                    <thead class="ui-widget-header ui-state-default">
                        <tr>
                            <th class="treecol" rowspan="2">Name
                                <span class="cmd cmd_detail"/>
                            </th>
                            <th colspan="3">Count</th>
                            <th rowspan="2">Ratio</th>
                        </tr>
                        <tr>
                            <th>Elems</th>
                            <th>Text</th>
                            <th>Distinct</th>
                        </tr>
                    </thead>
                    <tbody>
                        <xsl:copy-of select="$self"/>
                        <xsl:copy-of select="$children"/>
                    </tbody>
                </table>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="$self"/>
                <xsl:copy-of select="$children"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="Term" mode="terms-tree">
        <xsl:param name="parentid" select="'x'"/>
        <xsl:param name="lv" select="0"/>
        <xsl:variable name="xid">
            <xsl:choose>
                <xsl:when test="$lv=0">
                    <xsl:value-of select="concat($parentid,position())"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat($parentid,'-', position())"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
	
	<!--  this is especially for empty data-categories -->
        <xsl:variable name="is_empty" select="if(Term or @count) then '' else 'empty-term'"/>
        <tr id="{$xid}" class="{$is_empty}">
            <xsl:if test="not(parent::Termset or parent::Terms) or parent::Termset[@type='dcr' or @type='rr']">
                <xsl:attribute name="class" select="concat('child-of-',$parentid)"/>
            </xsl:if>
            <xsl:variable name="path_anchored">
                <xsl:choose>
                    <xsl:when test="@corresponding_component">
			  		<!-- <a target="_blank" href="{concat($components_viewer_uri, @corresponding_component)}" ><xsl:value-of select="@path" /></a> -->
                        <a target="_blank" href="{concat('', @corresponding_component)}">
                            <xsl:value-of select="@path"/>
                        </a>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="@path"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <td class="treecol"><!--<span class="cmd cmd_query" ></span><span class="cmd cmd_columns" ></span>-->
                <span class="column-elem">
                    <xsl:copy-of select="$path_anchored"/>
                </span><!--<span class="cmd cmd_info" ></span>-->
                <xsl:if test="@datcat!=''">[<a target="_blank" href="{@datcat}">
			<!-- <xsl:value-of select="my:shortURL(@datcat)" /> -->
                        <xsl:value-of select="''"/>
                    </a>]</xsl:if>
            </td>
		<!-- <td><xsl:value-of select="@path" />,<xsl:value-of select="@context" /></td>-->
            <td class="number">
                <xsl:value-of select="@count"/>
            </td>
		<!--  has children don't show the text-count - they are empty on non-terminals
			or better/experimental: show sum of the descendants
		 -->
            <td class="number"><!--   <xsl:if test="not(Term)"><xsl:value-of select="@count_text" /></xsl:if>-->
                <xsl:variable name="count_text_sanitized" select="if (not(Term)) then @count_text else sum(descendant::Term/@count_text)"/>
                <xsl:value-of select="if (number($count_text_sanitized)=number($count_text_sanitized)) then           format-number(number($count_text_sanitized),'#.##0','european' ) else ''"/>
            </td>
            <td class="number">	
			<!-- <xsl:if test="not(Term)"><a class="value-caller" href="{my:formURL('values', 'htmllist', concat(@path,'&sort=size'))}" ><xsl:value-of select="format-number(@count_distinct_text,'#.##0','european')" /></a>
			  <xsl:message><xsl:value-of select="concat('formURL: ',my:formURL('values', 'htmllist', concat(@path,'&sort=size')))"></xsl:value-of></xsl:message>
			</xsl:if>-->
                <xsl:if test="Term">
                    <xsl:value-of select="format-number(sum(descendant::Term/@count_distinct_text),'#.##0','european')"/>
                </xsl:if>
                <xsl:if test="not(Term)">
                    <xsl:value-of select="format-number(@count_distinct_text,'#.##0','european')"/>
                </xsl:if>
            </td>
            <td class="number">
                <xsl:if test="not(Term)">
                    <xsl:variable name="count_elems" select="parent::Term/@count"/>
                    <xsl:variable name="inf_content_ratio" select="if (@count_distinct_text!=0) then (@count_text div $count_elems) * (@count_text div @count_distinct_text) else ''"/>
                    <xsl:value-of select="if (number($inf_content_ratio)=number($inf_content_ratio)) then format-number(number($inf_content_ratio),'#.##0,00','european' ) else ''"/>
                </xsl:if>
            </td>
        </tr>
        <xsl:if test="Term and ($lv&lt;$x_maximumDepth or $x_maximumDepth=0)">
            <xsl:choose>
                <xsl:when test="$sort='s'">
                    <xsl:apply-templates select="Term" mode="terms-tree">
                        <xsl:with-param name="parentid" select="$xid"/>
                        <xsl:with-param name="lv" select="$lv+1"/>
                        <xsl:sort order="descending" select="@count_distinct_text" data-type="number"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:when test="$sort='n'">
                    <xsl:apply-templates select="Term" mode="terms-tree">
                        <xsl:with-param name="parentid" select="$xid"/>
                        <xsl:with-param name="lv" select="$lv+1"/>
                        <xsl:sort order="ascending" select="@name"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
					<!--  testwise: show only non empty Terms-->
                    <xsl:variable name="count_elems" select="@count"/>
                    <xsl:apply-templates select="Term" mode="terms-tree">
                        <xsl:sort select="if (@count_distinct_text!=0) then @count_text div $count_elems * (@count_text div @count_distinct_text) else 0" order="descending" data-type="number"/>
                        <xsl:with-param name="parentid" select="$xid"/>
                        <xsl:with-param name="lv" select="$lv+1"/>
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>
    <xsl:template match="Termset" mode="select">
        <xsl:variable name="count" select="if (Term/@count) then concat(' |',Term/@count,'|') else '' "/>
        <xsl:variable name="call-value" select="if (@type='model' or not(@id)) then @name else @id"/>
        <option value="{$call-value}">
            <xsl:value-of select="@name"/>
            <xsl:value-of select="$count"/>
        </option>
    </xsl:template>
    <xsl:template match="Term" mode="autocomplete">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <div class="term-contexts">
                <ul>
                    <xsl:apply-templates mode="autocomplete"/>
                </ul>
            </div>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="context" mode="autocomplete">
        <li class="context cmds-elem-plus">
            <span class="autocomplete-select-caller">
		<!-- 
		<a href="{concat($detail_model_prefix,@path)}" >
				<xsl:value-of select="@path"/></a>
		 -->
                <xsl:value-of select="@path"/>
            </span>
					
		<!-- <xsl:call-template name="attr-detail-div" /> -->
            <ul>
                <xsl:apply-templates select="context" mode="autocomplete"/>
            </ul>
        </li>
    </xsl:template>
    <xsl:template name="terms-flat">
	
		<!--  group union of model, dcr and rr Terms -->
        <xsl:for-each-group select=".//Termset[@type='model']//Term | .//Termset[@type='dcr']/Term | .//Termset[@type='rr']//Term[@type='rel']" group-by="lower-case(@name)">
<!--		<xsl:for-each-group select="//Term[exists(@name)][parent::Termset]" group-by="lower-case(@name)" >-->
            <xsl:sort select="lower-case(@name)"/>
			<!--  <xsl:if test="exists(current-group()[not(@type='datcat')])" >  -->
            <Term name="{@name}">
                <xsl:for-each select="current-group()[not(@type='datcat' or @type='rel')]">
                    <context><!-- <xsl:value-of select="ancestor::Termset[1]/@id" />:  -->
                        <xsl:copy-of select="@*"/>
                        <xsl:value-of select="@path"/>
                    </context>
                </xsl:for-each>
                <xsl:for-each select="current-group()[@type='datcat'][parent::Termset]">
                    <xsl:variable name="datcat" select="."/>
                    <context>
                        <xsl:copy-of select="@*"/>
                        <xsl:value-of select="ancestor::Termset[1]/@id"/>:<xsl:value-of select="@name"/>
                        <xsl:for-each-group select="$datcat/Term" group-by="@path">
                            <context>
                                <xsl:copy-of select="@*"/>
                                <xsl:copy-of select="@*"/>
                                <xsl:value-of select="@path"/>
                            </context>
                        </xsl:for-each-group>
                    </context>
                </xsl:for-each>
                <xsl:for-each select="current-group()[@type='rel']">
                    <xsl:variable name="datcat" select="if(parent::Term[@type='rel']) then parent::Term[@type='rel'] else . "/>
                    <context>
                        <xsl:copy-of select="@*"/><!-- <xsl:value-of select="ancestor::Termset[1]/@id" />: -->
                        <xsl:value-of select="@path"/>
<!--						<xsl:for-each-group select="$datcat//Term[@type!='datcat']" group-by="@path" >-->
                        <xsl:for-each select="$datcat//Term[@type='datcat']"> <!-- [Term/@path] -->
                            <context>
                                <xsl:copy-of select="@*"/>
                                <xsl:value-of select="@path"/>
                                <xsl:for-each-group select="Term[@path]" group-by="@path">
                                    <context>
                                        <xsl:copy-of select="@*"/>
                                        <xsl:value-of select="@path"/>
                                    </context>
                                </xsl:for-each-group>
                            </context>
                        </xsl:for-each>
                    </context>
                </xsl:for-each>
            </Term>
<!--			</xsl:if>-->
        </xsl:for-each-group>
    </xsl:template>
    <xsl:template name="list-datcats">
        <xsl:param name="matrix" select="."/>
        <table>
            <caption>DatCats |<xsl:value-of select="count(distinct-values($matrix//Term/@datcat))"/>| <span class="note">* Click on numbers to see detail </span>
            </caption>
            <thead>
                <tr>
                    <th rowspan="2">id</th>
                    <th rowspan="2">name</th>
                    <th colspan="3">count </th>
                    <th rowspan="2">elems</th>
                </tr>
                <tr>
                    <th>profile*</th>
                    <th>all*</th>
                    <th>elems</th>
                </tr>
            </thead>
            <tbody>
                <xsl:for-each-group select="$matrix//Term" group-by="@datcat">
                    <xsl:sort select="lower-case(@datcat)" order="ascending"/>
                    <tr>
						<!--
						<td valign="top"><xsl:value-of select="my:shortURL(@datcat)"/></td>
						<td valign="top"><xsl:value-of select="my:rewriteURL(@datcat)"/></td>
						
						<td valign="top" align="right">
							<span class="detail-caller" ><xsl:value-of select="count(distinct-values(current-group()/@name))"/></span>
							<div class="detail" >
									<div class="box_heading"><xsl:value-of select="my:rewriteURL(@datcat)"/></div>
									<ul>
										<xsl:for-each select="distinct-values(current-group()/@name)" >
											<li><xsl:value-of select="." /></li>
										</xsl:for-each>
									</ul>
								</div>							
						</td>
						<td valign="top" align="right">
							<span class="term_detail_caller" ><xsl:value-of select="count(current-group())"/></span>
							<div class="term_detail" >
									<div class="box_heading"><xsl:value-of select="my:rewriteURL(@datcat)"/></div>
									<ul>
										<xsl:for-each-group select="current-group()" group-by="@name" >
											<li><xsl:value-of select="@name" />
													<ul>
														<xsl:for-each select="current-group()/@context" >
																<li><xsl:value-of select="." /></li>
														</xsl:for-each>
													</ul>
											</li>
										</xsl:for-each-group>
									</ul>
								</div>							
						</td>
						<td valign="top" align="right"><xsl:value-of select="count(distinct-values(current-group()/@elem))"/></td>						
							
						<td width="40%">						
								<xsl:for-each select="distinct-values(current-group()/@elem)">
									<xsl:sort select="." />
									<xsl:value-of select="."/>,
								</xsl:for-each>
						</td>
						-->
                    </tr>
                </xsl:for-each-group>
            </tbody>
        </table>
    </xsl:template>
    <xsl:template name="callback-header">
<!--        <link href="{$scripts_url}/style/jquery/jquery-treeview/jquery.treeview.css" rel="stylesheet"/>-->
        <link href="{$scripts_url}/style/jquery/treetable/jquery.treeTable.css" rel="stylesheet"/>
<!--        <link href="{$scripts_url}/style/jquery/jquery-autocomplete/jquery-ui.css" rel="stylesheet" type="text/css"/>-->
        <script src="{$scripts_url}/js/jquery.min.js" type="text/javascript"/>
        <script src="{$scripts_url}/js/jquery-ui.min.js" type="text/javascript"/>
        <script src="{$scripts_url}/js/jquery-treeTable/jquery.treeTable.js" type="text/javascript"/>
        <style type="text/css">
		.cmd_add {display:none}
	</style>
        <script type="text/javascript"><![CDATA[

    $(function(){
			$(".terms-tree").treeTable({initialState:"collapsed"});
			
			// trying to add a collapse/expand button... - now added directly in the xsl-template 
			// var header = $(".terms-tree").find("th")[0];
			//$(header).html( $(header).html() );
			
			$(".terms-tree .cmd_detail").click(function(event) {					
			        $(".terms-tree").expandAll();
			/* 	if(this.id != $(ui.draggable.parents("tr")[0]).id && !$(this).is(".expanded")) {
        $(this).expand();
      }  */
				});
				
			/* $("a.value-caller").click(function(event) {
					event.preventDefault();
					handleValueCaller($(this));
				});		
			$(".terms-tree").find('.treecol').find(".cmd_columns").click(function(event) {
					event.preventDefault();
					handleIndexSelection($(this));
			}); */	
    });
    
    /* from:
http://stackoverflow.com/questions/5864109/how-to-add-and-expand-all-collapse-all-to-a-jquery-treetable-in-an-apache-wick 
*/
$.fn.expandAll = function() {
    $(this).find("tr").removeClass("collapsed").addClass("expanded").each(function(){
        $(this).expand();
        });
    };


	

		]]></script>
    </xsl:template>
</xsl:stylesheet>