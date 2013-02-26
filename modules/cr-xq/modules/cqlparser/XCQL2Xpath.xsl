<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="2.0">

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
    <xsl:param name="x-context" select="''"/>
    <xsl:param name="debug" select="true()"/>
    <xsl:param name="mappings-file" select="'xmldb:///db/cr/etc/mappings.xml'"/>
    <xsl:variable name="context-param" select="'x-context'"/>
    <xsl:variable name="mappings" select="if (doc-available($mappings-file)) then doc($mappings-file)/map else ()"/>
    <xsl:variable name="context-mapping" select="$mappings//map[@key][xs:string(@key) eq $x-context]"/>
    <xsl:variable name="default-mapping" select="$mappings//map[@key][xs:string(@key) eq 'default']"/>
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
                <xsl:value-of select="'.'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="boolean-query" select="exists(/triple)"/>
    <xsl:template match="/">
        <xsl:call-template name="message">
            <xsl:with-param name="msg">XCQL: <xsl:copy-of select="."/>
            </xsl:with-param>
        </xsl:call-template>
        <!-- <xsl:call-template name="message">
            <xsl:with-param name="msg"><xsl:copy-of select="doc($mappings-file)"/>
            </xsl:with-param>
        </xsl:call-template>-->
        <xsl:variable name="xpath-query">
            <xsl:apply-templates/>
        </xsl:variable>
<!-- moving the base-elem out into xquery        
<xsl:value-of select="concat($xpath-query,'/', $base-elem)"/>-->
        <xsl:value-of select="$xpath-query"/>
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
        <xsl:if test="not(ancestor::triple)">/descendant-or-self::*[</xsl:if>
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
        <xsl:variable name="resolved_index">
            <xsl:call-template name="resolve-index">
                <xsl:with-param name="ix" select="index"/>
            </xsl:call-template>
        </xsl:variable>
<!--        <xsl:value-of select="$resolved_index" />-->
        <xsl:for-each select="$resolved_index">
            <xsl:apply-templates select="index"/>
        </xsl:for-each>
        <xsl:apply-templates select="relation">
            <xsl:with-param name="index" select="$resolved_index"/>
            <xsl:with-param name="term" select="term"/>
        </xsl:apply-templates>
    </xsl:template>


<!--   aim is: special handling of collection-filter (as separate parameter) -->
    <!--<xsl:template match="searchClause" mode="collection">
        <xsl:text>&<xsl:value-of select="$context-param" />=</xsl:text>
        <xsl:value-of select="term"/>
        </xsl:template>-->
    <xsl:template match="index">
        
	<!-- <xsl:variable name="ix_xpathed" select="translate($ix_resolved, '.', '/')" ></xsl:variable> -->
<!--        <xsl:variable name="ix_xpathed" select="my:index2xpath(.)"/>-->
        <xsl:variable name="ix_xpathed">
            <xsl:call-template name="index2xpath">
                <xsl:with-param name="ix" select="."/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="($ix_xpathed='cql.serverChoice' or $ix_xpathed='*') and not(ancestor::triple)">.//*</xsl:when> <!-- descendant-or-self::*-->
            <xsl:when test="$ix_xpathed='cql.serverChoice' or $ix_xpathed='*'">.</xsl:when>
            <xsl:when test="$boolean-query">
                <xsl:value-of select="concat('.//',$ix_xpathed)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="concat('//',$ix_xpathed)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="relation">
        <xsl:param name="term"/>
        <xsl:param name="index"/>
        <xsl:param name="match-on" select="if (exists($index/index/@use)) then xs:string($index/index/@use) else  '.' "/>
        <!--        <xsl:message>relation index:<xsl:value-of select="$index/index/@use"/></xsl:message>-->
        <xsl:variable name="sanitized_term">
            <!-- select="replace($term,' ','+')"/ -->
            <xsl:choose> <!-- remove quotes -->
                <xsl:when test="starts-with($term, '''') ">
                    <xsl:value-of select="translate($term,'''','')"/>
                </xsl:when>
                <xsl:when test="starts-with($term, '%22') ">
                    <xsl:value-of select="translate($term,'%22','')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$term"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:text>[</xsl:text>
        <xsl:choose>
            <xsl:when test="$term='*' or $term='_'">
                <xsl:text>true()</xsl:text>
            </xsl:when>
            <xsl:when test="value='contains'">
                <xsl:value-of select="concat('contains(', $match-on, ', ''')"/>
                <xsl:value-of select="$sanitized_term"/>
                <xsl:text>')</xsl:text>
            </xsl:when>
            <xsl:when test="(value='any' or preceding-sibling::index='*' or preceding-sibling::index='cql.serverChoice')">
				<!--  use full-text querying: [ft:query(., "language")] -->
                <xsl:choose>
<!--                    <xsl:when test="starts-with($term,'%22') or starts-with($term,'"') ">-->
                    <xsl:when test="contains($sanitized_term, ' ')">
                        <xsl:value-of select="concat('ft:query(', $match-on, ', ')"/>
<!--                        <xsl:text>ft:query(.,<phrase></xsl:text>-->
                        <!-- <xsl:text><phrase></xsl:text>
                        <xsl:value-of select="replace($sanitized_term,'"','')"/>
                        <xsl:text></phrase>)</xsl:text> -->
                        <xsl:text>'"</xsl:text>
                        <xsl:value-of select="replace($sanitized_term,'&#34;','')"/>
                        <xsl:text>"')</xsl:text>
                    </xsl:when>
                    <xsl:when test="contains($term,'%7C')"> <!-- contains: |  - but why simply remove? -->
                        <xsl:value-of select="concat('ft:query(', $match-on, ', ')"/>
                        <xsl:text>'</xsl:text>
                        <xsl:value-of select="replace($sanitized_term,'%7C','')"/>
                        <xsl:text>')</xsl:text>
                    </xsl:when>
                    <xsl:when test="contains($term,$ws) or contains($sanitized_term,'+')"> <!--  AND-combined full-text search-->
                        <xsl:for-each select="tokenize(replace($sanitized_term,'\+',$ws),$ws)">
                            <xsl:if test=".!=''">
                                <xsl:value-of select="concat('ft:query(', $match-on, ', ')"/>
                                <xsl:text>'</xsl:text>
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
                    <!--<xsl:otherwise>
                        <xsl:value-of select="concat('ft:query(', $match-on, ', ')"/>
                        <xsl:text><term></xsl:text>
                        <xsl:value-of select="$sanitized_term"/>
                        <xsl:text></term>)</xsl:text>
                    </xsl:otherwise>-->
                    <xsl:otherwise>
                        <xsl:value-of select="concat('ft:query(', $match-on, ', ')"/>
                        <xsl:text>'</xsl:text>
                        <xsl:value-of select="$sanitized_term"/>
                        <xsl:text>')</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="value='='">
                <xsl:value-of select="concat($match-on, $ws, 'eq', $ws)"/>
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
    
  <!-- based on $as-param - return either the resolve xpath-string or the matching index-element -->
    <xsl:template name="resolve-index">
        <xsl:param name="ix" select="."/>        
        
        
        <!-- reverting the "escaping" of whitespaces in indices with datcat-name -->
        <xsl:variable name="ix_string" select="replace($ix/text(),'_',' ')"/>
        <!--<xsl:call-template name="message">
            <xsl:with-param name="msg">resolve index:<xsl:value-of select="$ix"/>
            </xsl:with-param>
        </xsl:call-template>-->

        <!--$resolved-index := if (exists($index-map)) then $index-map/text()
            else if (exists($repo-utils:mappings//index[xs:string(@key) eq $index])) then
            $repo-utils:mappings//index[xs:string(@key) eq $index]
            else $index-->
<!--        <xsl:variable name="resolved_ix">-->
            <!--        <xsl:copy-of select="$ix"></xsl:copy-of>-->
        <xsl:choose>
            <xsl:when test="exists($context-mapping/index[xs:string(@key) eq  $ix_string])">
<!--                <xsl:copy-of select="$context-mapping/index[xs:string(@key) eq  $ix_string]"></xsl:copy-of>-->
                <xsl:apply-templates select="$context-mapping/index[$ix_string eq xs:string(@key)]" mode="copy"/>
            </xsl:when>
            <!-- if no contextual mapping, try in default, than whole map -->
            <xsl:when test="exists($default-mapping/index[xs:string(@key) eq  $ix_string])">
                <xsl:apply-templates select="$default-mapping/index[$ix_string eq xs:string(@key)]" mode="copy"/>
            </xsl:when>
            <xsl:when test="exists($mappings//index[$ix_string eq xs:string(@key)])">
<!--               <xsl:copy-of select="$mappings//index[$ix_string eq xs:string(@key)]" />
                    work-around a bug in transform:transform with copy-of on doc($data)
                    http://exist.2174344.n4.nabble.com/transform-transform-error-with-doc-when-document-contains-attributes-td4186440.html                -->
                <xsl:variable name="matching_indexes">
                    <xsl:apply-templates select="$mappings//index[$ix_string eq xs:string(@key)]" mode="copy"/>
                </xsl:variable>
                <index key="{$ix_string}">
                    <xsl:copy-of select="$matching_indexes//path"/>
                </index>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="$ix"/>
            </xsl:otherwise>
        </xsl:choose>
<!--        </xsl:variable>-->
        
      <!--<xsl:copy-of select="$resolved_ix"></xsl:copy-of>
        <xsl:message>resolved index:<xsl:copy-of select="$resolved_ix"/>
        </xsl:message>-->
    </xsl:template>
    <xsl:template name="index2xpath">
        <xsl:param name="ix" select="."/>
        <xsl:variable name="paths">
            <xsl:choose>
                <xsl:when test="count($ix/path) &gt; 1">
                    <xsl:value-of select="concat('(', string-join(distinct-values($ix/path/text()),'|'),')')"/>
                </xsl:when>
                <xsl:when test="exists($ix/path)">
                    <xsl:value-of select="$ix/path/text()"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$ix/text()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="translate($paths, '.', '/')"/>
    </xsl:template>
                
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
    <xsl:template match="@*|node()" mode="copy">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()" mode="copy"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template name="message">
        <xsl:param name="msg "/>
        <xsl:if test="$debug">
            <xsl:message>
                <xsl:copy-of select="$msg"/>
            </xsl:message>
        </xsl:if>
<!--        <xsl:apply-templates/>-->
    </xsl:template>
</xsl:stylesheet>