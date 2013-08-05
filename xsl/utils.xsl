<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:exsl="http://exslt.org/common"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:utils="http://aac.ac.at/corpus_shell/utils"
    xmlns:ds="http://aac.ac.at/corpus_shell/dataset"
    xmlns="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="exsl xs xd utils ds" 
    version="2.0">
    
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> 2013-02-17</xd:p>
            <xd:p><xd:b>Author:</xd:b> m</xd:p>
            <xd:p>some generic helper functions </xd:p>
            <xd:p>(from amc-helpers.xsl)</xd:p>
        </xd:desc>
    </xd:doc>
    
    
    <xsl:decimal-format decimal-separator="," grouping-separator="."/>
    <xd:doc>
        <xd:desc>
            <xd:p></xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:variable name="number-format-dec" >#.##0,##</xsl:variable>    
    <xd:doc>
        <xd:desc>
            <xd:p></xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:variable name="number-format-default" >#.###</xsl:variable>
    <xd:doc>
        <xd:desc>
            <xd:p></xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:variable name="number-format-plain" >0,##</xsl:variable>
    
    <xd:doc>
        <xd:desc>
            <xd:p>convenience format-number function, 
                if empty -> 0, else if not a number return the string</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:function name="utils:format-number">
        <xsl:param name="number"></xsl:param>
        <xsl:param name="pattern"></xsl:param>
        <xsl:value-of select="
            if (xs:string($number)='' or number($number) =0) then 0 else
            if(number($number)=number($number)) then format-number($number,$pattern) 
            else $number"></xsl:value-of>
    </xsl:function>
    
    
    <!-- taken from cmd2graph.xsl -> smc_functions.xsl -->
    <xsl:function name="utils:normalize">
        <xsl:param name="value" />		
        <xsl:value-of select="translate($value,'*/-.'',$@={}:[]()#>&lt; ','XZ__')" />		
    </xsl:function>
    
    
    <xd:doc>
        <xd:desc>
            <xd:p>inverts the dataset, i.e. labels will get dataseries and vice versa</xd:p>
            <xd:p>needed mainly for AreaChart display.</xd:p>
            <xd:p>tries to cater for inconsistent structure (@key, @name, @label ...)
            once all data is harmonized (according to dataset.xsd), we can get rid of it</xd:p>
        </xd:desc>
        <xd:param name="dataset"></xd:param>
    </xd:doc>
    <!-- -->
    <xsl:template match="ds:dataset" mode="invert">
        <xsl:param name="dataset" select="."/>
        <!-- for now, make dataset without explicit namespace, for that need to override the current xhtml default ns -->
        <ds:dataset xmlns="">
            <xsl:copy-of select="@*"/>
            <ds:labels>
                <xsl:for-each select="ds:dataseries">
                    <ds:label>
                        <xsl:if test="@type">
                            <xsl:attribute name="type" select="@type"/>
                        </xsl:if>
                        <xsl:if test="@key">
                            <xsl:attribute name="key" select="@key"/>
                        </xsl:if>
                        <xsl:value-of select="(@name, @label ,@key)[1]"/>
                    </ds:label>
                </xsl:for-each>
            </ds:labels>
            <xsl:for-each select="ds:labels/ds:label">
                <xsl:variable name="curr_label_old" select="(@key, text())[1]"/>
                <ds:dataseries key="{$curr_label_old}" label="{text()}">
                    <xsl:for-each select="$dataset//ds:value[$curr_label_old=@key or $curr_label_old=@label]">
                        <ds:value key="{(../@name, ../@label,../@key)[not(.='')][1]}">
                            <!-- copy other (value) attributes, but not the key or label --> 
                            <xsl:copy-of select="@*[not(.='')][not(name()=('key','label'))]"/>
                            <!-- formatted="{@formatted}"
                <xsl:if test="../@type"><xsl:attribute name="type" select="../@type"></xsl:attribute></xsl:if>-->
                            <xsl:value-of select="."/>
                        </ds:value>
                    </xsl:for-each>
                </ds:dataseries>
            </xsl:for-each>
        </ds:dataset>
    </xsl:template>
    
</xsl:stylesheet>

