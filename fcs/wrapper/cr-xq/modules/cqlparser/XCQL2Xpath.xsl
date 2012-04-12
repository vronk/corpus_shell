<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:my="myFunctions" version="2.0">

<!-- 
<purpose>transform XCQL to xpath
</purpose>
<history>			
	<change on="2012-02-13" type="recreated" by="vr">based on XCQL2Xpath.xsl from the CLARIN/MDService project
	for now, stripped down of the mapping functionality (mapping index-names to some xml-elements/or xml-paths)	
	</change>
</history>
<sample>
<triple>
  <boolean>
    <value>and</value>
  </boolean>
  <leftOperand>
    <searchClause>
      <index>bath.author</index>
      <relation>
        <value>any</value>
      </relation>
      <term>fish</term>
    </searchClause>
  </leftOperand>
  <rightOperand>
    <searchClause>
      <index>dc.title</index>
      <relation>
        <value>all</value>
      </relation>
      <term>cat dog</term>
    </searchClause>
  </rightOperand>
</triple>
</sample>
-->
    <xsl:output method="text"/>
    <xsl:param name="mode" select="'xpath'"/> <!-- xpath |  url -->
    <xsl:param name="x-context" select="''"/> <!-- xpath |  url -->
    <xsl:param name="debug" select="false()"/>
    <xsl:param name="mappings-file" select="'xmldb:///db/cr/etc/mappings.xml'"/>
    <xsl:variable name="context-param" select="'x-context'"/>
    <xsl:variable name="mappings" select="doc($mappings-file)"/>
    <xsl:variable name="context-mapping" select="$mappings//map[@key][xs:string(@key) eq $x-context]"/>
    <xsl:variable name="ws">
        <xsl:choose>
            <xsl:when test="$mode='url'">%20</xsl:when>
            <xsl:otherwise>
                <xsl:text> </xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="base-elem">
        <xsl:choose>
            <xsl:when test="$context-mapping[@base_elem]">
                <xsl:value-of select="concat('ancestor-or-self::', $context-mapping/@base_elem)"/>
            </xsl:when>
            <xsl:when test="$mappings//map[@key='default'][@base_elem]">
                <xsl:value-of select="concat('ancestor-or-self::', $mappings//map[@key='default']/@base_elem)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="'self::*'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:template match="/">
    <!--    <xsl:call-template name="message">
            <xsl:with-param name="msg">XCQL: <xsl:copy-of select="."/>
            </xsl:with-param>
        </xsl:call-template>
        <xsl:call-template name="message">
            <xsl:with-param name="msg"><xsl:copy-of select="doc($mappings-file)"/>
            </xsl:with-param>
        </xsl:call-template>-->
        <xsl:variable name="xpath-query">
            <xsl:apply-templates/>
        </xsl:variable>
        <xsl:value-of select="concat($xpath-query,'/', $base-elem)"/>
    </xsl:template>
    <xsl:template match="triple">
        <!--special handling for collection (=context) index, disabled for now,
            as it has a separate parameter in the fcs-interface ($x-context)
          <xsl:choose>	
            <xsl:when test="rightOperand/searchClause/index='collection'">
                <xsl:apply-templates select="leftOperand/*"/>
                <xsl:apply-templates select="rightOperand/*" mode="collection"/>
            </xsl:when>
            <xsl:otherwise>-->
        <xsl:if test="not(ancestor::triple)">descendant-or-self::*[</xsl:if>
        <xsl:call-template name="boolean">
            <xsl:with-param name="op" select="boolean/value"/>
            <xsl:with-param name="left">
                <xsl:apply-templates select="leftOperand/*"/>
            </xsl:with-param>
            <xsl:with-param name="right">
                <xsl:apply-templates select="rightOperand/*"/>
            </xsl:with-param>
        </xsl:call-template>
        <xsl:if test="not(ancestor::triple)">]</xsl:if>
    </xsl:template>
    <xsl:template name="boolean">
        <xsl:param name="op"/>
        <xsl:param name="left"/>
        <xsl:param name="right"/>
        <xsl:message>XCQL2XPath.template-boolean.$op:<xsl:value-of select="$op"/>
        </xsl:message>
        <xsl:choose>
            <xsl:when test="$op='and'">
                <xsl:text/>
                <xsl:value-of select="$left"/>
                <xsl:text>][</xsl:text>
                <xsl:value-of select="$right"/>
                <xsl:text/>
            </xsl:when>
            <xsl:when test="$op='or'">
                <xsl:value-of select="$left"/>
                <xsl:value-of select="$ws"/>
                <xsl:text>or</xsl:text>
                <xsl:value-of select="$ws"/>
                <xsl:value-of select="$right"/>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="searchClause">
        <xsl:apply-templates select="index"/>
        <xsl:apply-templates select="relation">
            <xsl:with-param name="term" select="term"/>
        </xsl:apply-templates>
    </xsl:template>


<!--   aim is: special handling of collection-filter (as separate parameter) -->
    <!--<xsl:template match="searchClause" mode="collection">
        <xsl:text>&<xsl:value-of select="$context-param" />=</xsl:text>
        <xsl:value-of select="term"/>
        </xsl:template>-->
    <xsl:template match="index">
        <xsl:message>index:<xsl:value-of select="."/>
        </xsl:message>
	<!-- reverting the "escaping" of whitespaces in indices with datcat-name -->
        <xsl:variable name="ix_string" select="replace(text(),'_',' ')"/>
        <xsl:variable name="ix_resolved">
            
            
            <!--$resolved-index := if (exists($index-map)) then $index-map/text()
            else if (exists($repo-utils:mappings//index[xs:string(@key) eq $index])) then
            $repo-utils:mappings//index[xs:string(@key) eq $index]
            else $index-->
            <xsl:choose>
                <xsl:when test="exists($context-mapping/index[@key eq  $ix_string])">
                    <xsl:value-of select="concat('(', string-join($context-mapping/index[@key eq  $ix_string]/path/text(),'|'),')')"/>
                </xsl:when>
                <!-- if no contextual mapping, try in whole map -->
                <xsl:when test="exists($mappings//index[@key eq  $ix_string])">
                    <xsl:value-of select="concat('(', string-join($mappings//index[@key eq  $ix_string]/path/text(),'|'),')')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$ix_string"/>
                </xsl:otherwise>
            </xsl:choose>
            
            
            <!-- index-resolution/mapping disabled    
            <xsl:choose>
                <xsl:when test="contains(.,':')">
                    <xsl:variable name="prefix" select="substring-before(.,':')"/>
                    <xsl:variable name="termset" select="$terms_setup/Termsets/Termset[@id=$prefix]"/>
                    <xsl:message>XCQL2XPath.index:<xsl:copy-of select="$termset"/>
								ix_string:<xsl:value-of select="$ix_string"/>
                    </xsl:message>
                    <xsl:choose>
				<!-\- magic happening here  -\->
                        <xsl:when test="$termset[@type='dcr' or @type='rr']">
                            <xsl:variable name="expanded_context" select="$terms_flat//context[@path=$ix_string]"/>
                            <xsl:variable name="expanded_query">
                                <xsl:text>(</xsl:text>
                                <xsl:for-each select="distinct-values($expanded_context//context[@elem]/@path)">
                                    <xsl:variable name="prefix" select="substring-before(.,':')"/>
                                    <xsl:variable name="termset" select="$terms_setup/Termsets/Termset[@id=$prefix]"/>
                                    <xsl:value-of select="concat($termset/@name,'//',substring-after(.,':'))"/>
                                    <xsl:if test="position()!=last()">
                                        <xsl:text>|</xsl:text>
                                    </xsl:if>
                                </xsl:for-each>
                                <xsl:text>)</xsl:text>
                            </xsl:variable>
                            <xsl:message>expanded-context:<xsl:value-of select="$expanded_query"/>
                            </xsl:message>
                            <xsl:value-of select="$expanded_query"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="concat($termset/@name,'//',substring-after(.,':'))"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
            </xsl:choose>-->
        </xsl:variable>
	<!-- <xsl:variable name="ix_xpathed" select="translate($ix_resolved, '.', '/')" ></xsl:variable> -->
<!--        <xsl:variable name="ix_xpathed" select="my:index2xpath(.)"/>-->
        <xsl:variable name="ix_xpathed" select="translate($ix_resolved, '.', '/')"/>
        <xsl:choose>
            <xsl:when test="($ix_xpathed='cql.serverChoice' or $ix_xpathed='*') and not(ancestor::triple)">.//*</xsl:when> <!-- descendant-or-self::*-->
            <xsl:when test="$ix_xpathed='cql.serverChoice' or $ix_xpathed='*'">.</xsl:when>
            <xsl:when test="ancestor::triple">
                <xsl:value-of select="concat('.//',$ix_xpathed)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="concat('//',$ix_xpathed)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="relation">
        <xsl:param name="term"/>
        <xsl:param name="sanitized_term" select="replace($term,' ','+')"/>
        <xsl:text>[</xsl:text>
        <xsl:choose>
            <xsl:when test="$term='*' or $term='_'">
                <xsl:text>true()</xsl:text>
            </xsl:when>
            <xsl:when test="value='contains'">
                <xsl:text>contains(.,'</xsl:text>
                <xsl:value-of select="$sanitized_term"/>
                <xsl:text>')</xsl:text>
            </xsl:when>
            <xsl:when test="(value='any' or preceding-sibling::index='*' or preceding-sibling::index='cql.serverChoice')">
				<!--  use full-text querying: [ft:query(., "language")] -->
                <xsl:choose>
                    <xsl:when test="starts-with($term,'%22')">
                        <xsl:text>ft:query(.,&lt;phrase&gt;</xsl:text>
                        <xsl:value-of select="replace($sanitized_term,'%22','')"/>
                        <xsl:text>&lt;/phrase&gt;)</xsl:text>
                    </xsl:when>
                    <xsl:when test="contains($term,'%7C')">
                        <xsl:text>ft:query(.,'</xsl:text>
                        <xsl:value-of select="replace($sanitized_term,'%7C','')"/>
                        <xsl:text>')</xsl:text>
                    </xsl:when>
                    <xsl:when test="contains($term,$ws) or contains($sanitized_term,'+')"> <!--  AND-combined full-text search-->
                        <xsl:for-each select="tokenize(replace($sanitized_term,'\+',$ws),$ws)">
                            <xsl:if test=".!=''">
                                <xsl:text>ft:query(.,'</xsl:text>
                                <xsl:value-of select="."/>
                                <xsl:text>')</xsl:text>
                                <xsl:message>
                                    <xsl:value-of select="concat(position(),':', .)"/>
                                </xsl:message>
                                <xsl:if test="position()!=last()">
                                    <xsl:text>][</xsl:text>
                                </xsl:if>
                            </xsl:if>
                        </xsl:for-each>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>ft:query(.,'</xsl:text>
                        <xsl:value-of select="$sanitized_term"/>
                        <xsl:text>')</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="value='='">
                <xsl:value-of select="concat('.', $ws, 'eq', $ws)"/>
                <xsl:text>'</xsl:text>
                <xsl:value-of select="$sanitized_term"/>
                <xsl:text>'</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>.</xsl:text>
                <xsl:value-of select="value"/>
                <xsl:text>'</xsl:text>
                <xsl:value-of select="$sanitized_term"/>
                <xsl:text>'</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text>]</xsl:text>
    </xsl:template>
    <xsl:template name="message">
        <xsl:param name="msg "/>
        <xsl:if test="$debug">
            <xsl:message>
                <xsl:copy-of select="$msg"/>
            </xsl:message>
        </xsl:if>
        <xsl:apply-templates/>
    </xsl:template>
</xsl:stylesheet>