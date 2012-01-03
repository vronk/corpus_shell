<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" >

<!-- 
<purpose>pieces of html wrapped in templates, to be reused by other stylesheets</purpose>
<history>
	<change on="2011-12-05" type="created" by="vr">copied from  cr/html_snippets reworked back to xslt 1.0</change>
</history>

-->
    <xsl:import href="params.xsl"/>
    
    <xsl:template name="html-head">
        <title>
            <xsl:value-of select="$title"/>
        </title> 
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
        <link href="{$base_dir}/style/jquery/clarindotblue/jquery-ui-1.8.5.custom.css" type="text/css" rel="stylesheet"/>
        <link href="{$base_dir}/style/cmds-ui.css" type="text/css" rel="stylesheet"/>
        <link href="{$base_dir}/style/cr.css" type="text/css" rel="stylesheet"/>
        <!--        <xsl:if test="contains($format,'htmljspage')">
            <link href="{$base_dir}/style/jquery/jquery-treeview/jquery.treeview.css" rel="stylesheet"/>        
            </xsl:if>-->
    </xsl:template>
    <xsl:template name="page-header">
        <div class="cmds-ui-block" id="titlelogin">
            <div id="logo">
                <a href="http://www.clarin.eu">
                    <img src="{$site_logo}" alt="{$site_name}"/>
                </a>
                <div id="site-name">
                    <xsl:value-of select="$site_name"/>
                </div>
            </div>
            <div id="top-menu">
                <div id="user">
                    <xsl:variable name="link_toggle_js">                           
                     <xsl:call-template name="formURL">
                            <xsl:with-param name="format" >
                                <xsl:choose>
                                    <xsl:when test="contains($format,'htmljspage')">htmlpage</xsl:when>
                                    <xsl:otherwise>htmljspage</xsl:otherwise>
                                </xsl:choose>                                
                            </xsl:with-param>
                     </xsl:call-template>
                    </xsl:variable>
                    
                    <xsl:choose>
                        <xsl:when test="contains($format,'htmljspage')">
                            <a href="{$link_toggle_js}"> none js </a>
                        </xsl:when>
                        <xsl:otherwise>
                            <a href="{$link_toggle_js}"> js </a>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:choose>
                        <xsl:when test="$user = ''">
                            <a href="workspace.jsp">    login</a>
                        </xsl:when>
                        <xsl:otherwise>
							User: <b>
                                <xsl:value-of select="$user"/>
                            </b>
                            <a href="logout.jsp">    logout</a>
                        </xsl:otherwise>
                    </xsl:choose>
                    <a target="_blank" href="static/info"> docs</a>
                </div>
                <div id="notify" class="cmds-elem-plus note">
                    <div id="notifylist" class="note"/>
                </div>
            </div>
        </div>
    </xsl:template>
    <xsl:template name="query-input">
	
	<!-- QUERYSEARCH - BLOCK -->
        <div class="cmds-ui-block init-show" id="querysearch">
            <div class="header ui-widget-header ui-state-default ui-corner-top">
                <span>Search</span>
            </div>
            <div class="content" id="query-input">
                <xsl:variable name="form_action" >
                    <xsl:call-template name="formURL">                    
                    </xsl:call-template>
                </xsl:variable>
                
                <form id="searchretrieve" action="{$form_action}" method="get">
                    <table class="cmds-ui-elem-stretch">
                        <tr>
                            <td>
                                <input type="text" id="input-simplequery" name="query" value="{$q}" class="queryinput active"/>
                                <div id="searchclauselist" class="queryinput inactive"/>
                            </td>
                            <td>
                                <input type="submit" value="submit" id="submit-query"/>
                            </td>
                        </tr>
                    </table>
                    <div>
                        <table class="cmds-ui-elem-stretch ui-advanced">
                            <tr>
                                <td valign="top">
                                    <div id="repositories">
                                        <label>Repository</label>
                                        <select id="repositories_select" name="repository">
                                            <option value="">TODO - not implemented yet</option>
                                            <!--
                                                TODO: 
                                            <xsl:for-each select="exsl:node-set($repositories)">
                                                <option>
                                                    <xsl:attribute name="value">
                                                        <xsl:value-of select="name"/>
                                                    </xsl:attribute>
                                                    <xsl:value-of select="name"/>
                                                </option>
                                            </xsl:for-each>
                                            -->
                                        </select>
                                    </div>
							<!--  selected collections  -->
							<!-- <label>Collections</label><br/>-->
                                    <div id="collections-widget" class="c-widget"/>
                                </td>
                                <td valign="top">
                                    <label>Complex query</label>
                                    <span id="switch-input" class="cmd"/>
                                    <br/>
						<!--  <div id="searchclauselist"></div>-->							
						<!--<input type="checkbox" checked="false" id="input-withsummary" name="WS"/><label>with Summary</label> 
						 -->
                                </td>
                            </tr>
                        </table>
                    </div>
                </form>
            </div>
        </div>
    </xsl:template>
    <xsl:template name="query-list">

<!-- QUERYLIST BLOCK -->
        <div id="querylistblock" class="cmds-ui-block">
            <div class="header ui-widget-header ui-state-default ui-corner-top">
                <span>QUERYLIST</span>
            </div>
            <div class="content" id="querylist"/>
        </div>
    </xsl:template>
    <xsl:template name="detail-space">
        <div id="detailblock" class="cmds-ui-block">
            <div class="header ui-widget-header ui-state-default ui-corner-top">
                <span>DETAIL</span>
            </div>
            <div class="content" id="details"/>
        </div>
    </xsl:template>
    <xsl:template name="public-space">
        <div id="public-space" class="cmds-ui-block">
            <div class="header">
                <span>Public Space</span>
            </div>
            <div id="serverqs" class="content"/>
        </div>
    </xsl:template>
    <xsl:template name="user-space">
        <div class="cmds-ui-block init-show" id="user-space">
            <div class="header">
                <span>Personal Workspace</span>
            </div>
            <div id="userqs" class="content">
                <div id="userquerysets">
                    <label>Querysets</label>
                    <select id="qts_select"/>
				<!--  <button id="qts_add" class="cmd cmd_add" >Add</button> -->
                    <span id="qts_add" class="cmd cmd_add"/>
                    <span id="qts_delete" class="cmd cmd_del"/>
                </div>
                <label>name</label>
                <input type="text" id="qts_input"/>
                <span id="qts_save" class="cmd cmd_save"/>
                <div id="userqueries"/>
            </div>
            <div id="userbs" class="content">
                <div id="bookmarksets">
                    <label>Bookmarksets</label>
                    <select id="bts_select"/>
                    <span id="bts_add" class="cmd cmd_add"/>
                    <span id="bts_delete" class="cmd cmd_del"/>
                    <span id="bts_publish" class="cmd cmd_publish"/>
                </div>
                <label>name</label>
                <input type="text" id="bts_input"/>
                <span id="bts_save" class="cmd cmd_save"/>
                <div id="bookmarks"/>
            </div>
        </div>
    </xsl:template>
</xsl:stylesheet>