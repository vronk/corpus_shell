<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:diag="http://www.loc.gov/zing/srw/diagnostic/" xmlns:utils="http://aac.ac.at/corpus_shell/utils"  xmlns:sru="http://www.loc.gov/zing/srw/" xmlns:saxon="http://saxon.sf.net/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:fcs="http://clarin.eu/fcs/1.0" xmlns:exsl="http://exslt.org/common" version="2.0" 
    xmlns:ds="http://aac.ac.at/corpus_shell/dataset" exclude-result-prefixes="saxon xs exsl diag sru fcs utils ds">
    
<!--   
    <purpose> generate html view of a dataset, basically use dataset2table but also use commons to wrap it in html.</purpose>
<history>  
<change on="2013-01-24" type="created" by="vr"></change>	
</history>   
 -->   
    <xsl:import href="dataset2table.xsl"/>
    <xsl:import href="../utils.xsl"/>
    <!--  method="xhtml" is saxon-specific! prevents  collapsing empty <script> tags, that makes browsers choke -->
    <!-- doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN" -->
    <xsl:output method="html" media-type="text/xhtml" indent="yes" encoding="UTF-8" />
    
    <xsl:include href="../commons_v2.xsl"/>

    <xsl:param name="site_logo" select="'scripts/style/imgs/clarin-logo.png'"/>
    <xsl:param name="site_name">SMC statistics</xsl:param>
    
    <xsl:param name="title" />
    <xsl:variable name="cols">
        <col>all</col>
    </xsl:variable>
    
    <xsl:template name="continue-root">
        
        <div>
            <xsl:apply-templates select="*" mode="data2table"/>
        </div>
    </xsl:template>
    
    <xsl:template name="top-menu">
        <xsl:for-each select="//ds:dataset" >
            <!-- this has to be in sync with  <xsl:template match="ds:dataset" mode="data2table"> in dataset2table.xsl -->    
                <xsl:variable name="dataset-name" select="concat(utils:normalize(@name),position())"/>
<!--                <a href="#dataset-{@key}" ><xsl:value-of select="(@label,@key)[1]"></xsl:value-of></a> | -->
            <a href="#table-{$dataset-name}" ><xsl:value-of select="(@label,@key)[1]"></xsl:value-of></a> |
            
            </xsl:for-each>
    </xsl:template>
    
    
    <xsl:template name="callback-header">
        <script type="text/javascript">
            $(function()
            {
         /*   $(".detail-caller").live("mouseover", function(event) {
                //console.log(this);
                $(this).parent().find('.detail').show();
              });
            
            $(".detail-caller").live("mouseout", function(event) {
                //console.log(this);
                $(this).parent().find('.detail').hide();
              });
           */ 
           
            $(".detail-caller").live("click", function(event) {
                //console.log(this);
                event.preventDefault();
                $(this).parent().find('.detail').toggle();
              });
              
            });
        </script>
    </xsl:template>
</xsl:stylesheet>