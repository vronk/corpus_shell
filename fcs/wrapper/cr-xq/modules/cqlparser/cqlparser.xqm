xquery version "1.0";
(:~ This module provides methods to transform CQL query to XPath   
: @see http://clarin.eu/fcs 
: @author Matej Durco
: @since 2012-03-01
: @version 1.1 
:)
module namespace cql = "http://exist-db.org/xquery/cql";

import module namespace cqlparser = "http://exist-db.org/xquery/cqlparser";
import module namespace repo-utils = "http://aac.ac.at/content_repository/utils" at  "/db/cr/repo-utils.xqm";

declare variable $cql:transform-doc := doc("XCQL2Xpath.xsl");

(:~ use the extension module CQLParser (using cql-java library)
to parse the expression and return the xml version  of the parse-tree
:)
declare function cql:cql-to-xcql($cql-expression as xs:string) {
  util:parse(cqlparser:parse-cql($cql-expression, "XCQL"))
};

(:~ translate a query in CQL-syntax to a corresponding XPath 
: <ol>
: <li>1. parsing into XCQL (XML-representation of the parsed query</li>
: <li>2. and transform via XCQL2Xpath.xsl-stylesheet</li>
: </ol>
: @return xpath-string 
:)
declare function cql:cql2xpath($cql-expression as xs:string, $x-context as xs:string)  as xs:string {
    let $xcql := cql:cql-to-xcql($cql-expression)
(:    return transform:transform ($xcql, $cql:transform-doc, <parameters><param name="mappings-file" value="{repo-utils:config-value('mappings')}" /></parameters>):)
    return transform:transform ($xcql, $cql:transform-doc, <parameters><param name="x-context" value="{$x-context}" /></parameters> )
  
};

(:~ a version that accepts mappings-file as param
:)
declare function cql:cql2xpath($cql-expression as xs:string, $x-context as xs:string, $mappings as xs:string)  as xs:string {
    let $xcql := cql:cql-to-xcql($cql-expression)
    return transform:transform ($xcql, $cql:transform-doc, 
        <parameters><param name="x-context" value="{$x-context}" />
                <param name="mappings-file" value="{$mappings}" /></parameters> )  
};

declare function cql:xcql2xpath ($xcql as node(), $x-context as xs:string)  as xs:string {
    
(:    return transform:transform ($xcql, $cql:transform-doc, <parameters><param name="mappings-file" value="{repo-utils:config-value('mappings')}" /></parameters>):)    
transform:transform ($xcql, $cql:transform-doc, <parameters><param name="x-context" value="{$x-context}" /></parameters> )
    
};

