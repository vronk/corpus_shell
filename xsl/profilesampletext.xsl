<?xml version="1.0" encoding="iso-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:html="http://www.w3.org/1999/xhtml" xmlns="http://www.w3.org/1999/xhtml" exclude-result-prefixes="html">

    <xsl:output method="html"/>

    <xsl:template match="/">
      <html>
      <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
      <style>
        td
        {
          height: 20px;
        }
      </style>
      <script language="Javascript">
            function mi(t_) {
               t_.style.background = 'rgb(136,136,255)';
               t_.style.color = 'white';
               t_.style.cursor ="pointer";
            }

            function mo(t_) {
               t_.style.background = 'white';
               t_.style.color = 'black';
               t_.style.cursor ="default";
            }

            function showWC(t_) {
               ob4 = document.getElementById('dvWC');
               if (ob4) {
                  ob4.innerHTML = t_;
               }
            }

            function showTrans(t_) {
               ob4 = document.getElementById('dvTrans');
               if (ob4) {
                  ob4.innerHTML = t_;
               }
            }

            function showUsage(t_) {
               ob4 = document.getElementById('dvUsage');
               if (ob4) {
                  ob4.innerHTML = t_;
               }
            }

            function addUsage(t_) {
               ob4 = document.getElementById('dvUsage');
               if (ob4) {
                  ob4.innerHTML = ob4.innerHTML + t_;
               }
            }
            function showLemma(t_) {
               ob4 = document.getElementById('dvLemma');
               if (ob4) {
                  ob4.innerHTML = t_;
               }
            }
      </script>

      <table style="position: absolute; left: 10px; top: 10px; border-collapse: collapse; background:rgb(211,211,211); &#xA;      border:1px solid rgb(95,95,95)">
         <tr><td style="width:100px"><b>Word class: </b></td><td style="width:200px"><i id="dvWC" style="color:rgb(154,5,69)"></i></td></tr>
         <tr><td><b>Lemma: </b></td><td><i id="dvLemma" style="color:rgb(2,37,157)"></i></td></tr>
         <tr><td><b>Translation: </b></td><td><i id="dvTrans" style="color:rgb(60,124,1)"></i></td></tr>
         <tr><td><b>Usage: </b></td><td><i id="dvUsage" style="color:rgb(60,124,1)"></i></td></tr>
      </table>

      <table style="position: absolute; left: 10px; top: 110px; ">
         <tr>
            <td colspan="2">
              <h3>Sample Text</h3>

              <xsl:for-each select="//s">
                  <div class="profiletext">
                     <xsl:value-of select="position()"/>.

                     <xsl:for-each select=".//w | .//c"><span onMouseMove="mi(this)" onMouseout="mo(this)">
                           <xsl:choose>
                              <xsl:when test="name()='w'">
                                 <xsl:attribute name="onMouseMove">
                                    mi(this);
                                    showWC('<xsl:value-of select="./fs/f[@name='pos']"/>');
                                    showLemma('<xsl:value-of select="./fs/f[@name='lemma']"/>');
                                    showTrans('<xsl:value-of select="./fs/f[@name='translation']"/>');
                                    showUsage('<xsl:value-of select="./fs/f[@name='usage']"/>');
                                    <xsl:if test="./fs/f[@name='tense']">addUsage('<xsl:value-of select="./fs/f[@name='tense']"/> tense');</xsl:if>
                                    <xsl:if test="./fs/f[@name='person']">addUsage(', <xsl:value-of select="./fs/f[@name='person']"/>-');</xsl:if>
                                    <xsl:if test="./fs/f[@name='number']">addUsage('<xsl:value-of select="./fs/f[@name='number']"/>');</xsl:if>
                                 </xsl:attribute>
                                 <xsl:value-of select="./fs/f[@name='wordform']"/>
                              </xsl:when>

                              <xsl:when test="name()='c'">
                                 <xsl:attribute name="onMouseMove">
                                    mi(this);showWC('');showLemma('');showTrans('');showUsage('');
                                 </xsl:attribute>
                                 <xsl:value-of select="."/>
                              </xsl:when>
                           </xsl:choose></span></xsl:for-each>
                </div>
              </xsl:for-each>
      </td></tr></table>
      </html>
    </xsl:template>

</xsl:stylesheet>
