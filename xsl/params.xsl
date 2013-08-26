<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:sru="http://www.loc.gov/zing/srw/"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:fcs="http://clarin.eu/fcs/1.0"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    exclude-result-prefixes="xs"
    version="1.0">
    
    <xd:doc scope="stylesheet">
        <xd:desc>Central definition of all parameters the style sheets take
            <xd:p>
                The following are needed in commons_v1.xsl (formURL) and in html_snippets.xsl, therefore they need to be defined here
                (but only as default, so we could move them, because actually they pertain only to result2view.xsl:
                <xd:ul>
                    <xd:li><xd:ref name="operation" type="parameter">operation</xd:ref></xd:li>
                    <xd:li><xd:ref name="format" type="parameter">format</xd:ref></xd:li>
                    <xd:li><xd:ref name="q" type="parameter">q</xd:ref></xd:li>
                    <xd:li><xd:ref name="x-context" type="parameter">x-context</xd:ref></xd:li>
                    <xd:li><xd:ref name="startRecord" type="parameter">startRecord</xd:ref></xd:li>
                    <xd:li><xd:ref name="maximumRecords" type="parameter">maximumRecords</xd:ref></xd:li>
                    <xd:li><xd:ref name="numberOfRecords" type="parameter">numberOfRecords</xd:ref></xd:li>
                    <xd:li><xd:ref name="numberOfMatches" type="parameter">numberOfMatches</xd:ref></xd:li>
                    <xd:li><xd:ref name="mode" type="parameter">mode</xd:ref></xd:li>
                </xd:ul>
            </xd:p>
        </xd:desc>
    </xd:doc>
    
    <xd:doc>
        <xd:desc></xd:desc>
    </xd:doc>
    <xsl:param name="user"/>
    
    <xd:doc>
        <xd:desc>
            <xd:p>
                Defaults to an empty xs:string.
            </xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:param name="title" select="''"/>
    <xd:doc>
        <xd:desc>The URL the result originated from
            <xd:p>
                Note: can be found in //sru:baseUrl. Example: http://clarin.aac.ac.at/exist7/rest/db/content_repository
            </xd:p>
            <xd:p>
                Defaults to an empty xs:string.
            </xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:param name="base_url" select="''"/>
    
    <!-- <xsl:param name="base_dir">http://corpus3.aac.ac.at/cs/</xsl:param>-->
    
    <xd:doc>
        <xd:desc>A URL for scripts ???
        <xd:p>
            Example: http://clarin.aac.ac.at/exist7/rest/db/content_repository/scripts
        </xd:p>
        <xd:p>
            Defaults to an empty xs:string.
        </xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:param name="scripts_url" select="''"/>
    <xd:doc>
        <xd:desc>A URL where a logo for the site can be found
            <xd:p>
                Defaults to <xd:ref name="scripts_url" type="parameter">$scripts_url</xd:ref> . 'style/logo_c_s.png'
            </xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:param name="site_logo" select="concat($scripts_url, 'style/logo_c_s.png')"/>
    <xd:doc>
        <xd:desc>Name of the site
            <xd:p>
                Defaults to 'Repository'
            </xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:param name="site_name">Repository</xsl:param>
    
    
    <!-- following are needed in in commons_v1.xsl (formURL) and in html_snippets.xsl, therefore they need to be defined here
        (but only as default, so we could move them, because actually they pertain only to result2view.xsl -->
    
    <xd:doc>
        <xd:desc>Operation for which this template should do the transformation 
            <xd:p>One of
                <xd:ul>
                    <xd:li>explain</xd:li>
                    <xd:li>scan</xd:li>
                    <xd:li>searchRetrieve</xd:li>
                </xd:ul>
            </xd:p>
            <xd:p>
                Defaults to nothing.
            </xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:param name="operation"/>
    <xd:doc>
        <xd:desc>Requested format of the result
            <xd:p>One a combination of
                <xd:ul>
                    <xd:li>html + one of
                        <xd:ul>
                            <xd:li>page</xd:li>
                            <xd:li>js</xd:li>
                            <xd:li>simple</xd:li>                    
                        </xd:ul>
                    </xd:li>
                    <xd:li>list</xd:li>
                    <xd:li>detail</xd:li>
                </xd:ul>
            </xd:p>
            <xd:p>
                Examples: htmlsimpledetail or htmljslist
            </xd:p>
            <xd:p>
                Defaults to 'htmlpagelist'.
            </xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:param name="format" select="'htmlpagelist'"/>
    <xd:doc>
        <xd:desc>The query sent by the client
            <xd:p>
                Defaults to /sru:searchRetrieveResponse/sru:echoedSearchRetrieveRequest/sru:query
            </xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:param name="q" select="/sru:searchRetrieveResponse/sru:echoedSearchRetrieveRequest/sru:query"/>
    <xd:doc>
        <xd:desc>The x-context (x-cmd-context) the client specified
            <xd:p>
                Defaults to /sru:searchRetrieveResponse/sru:echoedSearchRetrieveRequest/sru:query
            </xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:param name="x-context" select="/sru:searchRetrieveResponse/sru:echoedSearchRetrieveRequest/fcs:x-context"/>
    <xd:doc>
        <xd:desc>The start record the client requested or the one the upstream endpoint chose
            <xd:p>
                Defaults to /sru:searchRetrieveResponse/sru:echoedSearchRetrieveRequest/sru:startRecord
            </xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:param name="startRecord" select="/sru:searchRetrieveResponse/sru:echoedSearchRetrieveRequest/sru:startRecord"/>
    <xd:doc>
        <xd:desc>The maximum number of records the client requested or the one the upstream endpoint chose
            <xd:p>
                Defaults to /sru:searchRetrieveResponse/sru:echoedSearchRetrieveRequest/sru:maximumRecords
            </xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:param name="maximumRecords" select="/sru:searchRetrieveResponse/sru:echoedSearchRetrieveRequest/sru:maximumRecords"/>
    <xd:doc>
        <xd:desc>The actual number of records in the response
            <xd:p>
                Defaults to /sru:searchRetrieveResponse/sru:numberOfRecords
            </xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:param name="numberOfRecords" select="/sru:searchRetrieveResponse/sru:numberOfRecords"/>
    <xd:doc>
        <xd:desc>The number of matches records in the response
            <xd:p>
                Defaults to /sru:searchRetrieveResponse/sru:extraResponseData/fcs:numberOfMatches
            </xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:param name="numberOfMatches" select="/sru:searchRetrieveResponse/sru:extraResponseData/fcs:numberOfMatches"/>
    <xd:doc>
        <xd:desc>???
            <xd:p>
                Defaults to 'html'
            </xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:param name="mode" select="'html'"/>
 
    <xd:doc>
        <xd:desc>The scanClause specified by the client
            <xd:p>
                Defaults to an empty xs:string.
            </xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:param name="scanClause" select="''"/>
    <xd:doc>
        <xd:desc>???</xd:desc>
    </xd:doc> 
    <xsl:param name="contexts_url" select="concat($base_url,'fcs?operation=scan&amp;scanClause=fcs.resource&amp;sort=text&amp;version=1.2&amp;x-format=xml')"/>
    
    <xd:doc>
        <xd:desc>A URL to a file where additional parameters can be specified</xd:desc>
    </xd:doc>
    <xsl:param name="mappings-file" select="''"/>
    
    <xd:doc>
        <xd:desc>URL parameter that contained the context for the operation</xd:desc>
    </xd:doc>
    <xsl:variable name="context-param" select="'x-context'"/>
    <xd:doc>
        <xd:desc>A map with additional settings</xd:desc>
    </xd:doc>
    <xsl:variable name="mappings" select="document($mappings-file)/map"/>
    <xd:doc>
        <xd:desc>The settings for <xd:ref name="x-context" type="parameter">$x-context</xd:ref> contained in 
        <xd:ref name="mappings" type="variable">mappings</xd:ref></xd:desc>
        <xd:p>
            The XML atrribute key is taken from the XSL context where this variable is evaluated so the context
            should be an XML element that has a key attribute.
        </xd:p>
    </xd:doc>
    <xsl:variable name="context-mapping" select="$mappings//map[@key][xs:string(@key) = $x-context]"/>
    <xd:doc>
        <xd:desc>The settings for default contained in <xd:ref name="mappings" type="variable">mappings</xd:ref>
            <xd:p>
                The XML atrribute key is taken from the XSL context where this variable is evaluated so the context
                should be an XML element that has a key attribute.
            </xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:variable name="default-mapping" select="$mappings//map[@key][xs:string(@key) = 'default']"/>
</xsl:stylesheet>