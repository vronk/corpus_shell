/*
 *  eXist Open Source Native XML Database
 *  Copyright (C) 2001-09 The eXist Project
 *  http://exist-db.org
 *  
 *  This program is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public License
 *  as published by the Free Software Foundation; either version 2
 *  of the License, or (at your option) any later version.
 *  
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Lesser General Public License for more details.
 *  
 *  You should have received a copy of the GNU Lesser General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 *  
 *  $Id: ParseSimpleQL.java 10610 2009-11-26 09:12:00Z shabanovd $
 */
package org.exist.xquery.modules.cqlparser;

import java.io.IOException;
import java.io.StringReader;

import org.apache.log4j.Logger;
import org.exist.dom.QName;
import org.exist.xquery.BasicFunction;
import org.exist.xquery.Cardinality;
import org.exist.xquery.FunctionSignature;
import org.exist.xquery.XPathException;
import org.exist.xquery.XQueryContext;
import org.exist.xquery.value.FunctionParameterSequenceType;
import org.exist.xquery.value.FunctionReturnSequenceType;
import org.exist.xquery.value.Sequence;
import org.exist.xquery.value.SequenceType;
import org.exist.xquery.value.StringValue;
import org.exist.xquery.value.Type;

import org.z3950.zing.cql.CQLNode;
import org.z3950.zing.cql.CQLParseException;
import org.z3950.zing.cql.CQLParser;

public class ParseCQL extends BasicFunction {

	private static final String OutputTypeString = "string";
	private static final String OutputTypeCQL = "CQL";
	private static final String OutputTypeXCQL = "XCQL";
	
	@SuppressWarnings("unused")
	private static final Logger logger = Logger.getLogger(ParseCQL.class);
	
    public final static FunctionSignature signature =
        new FunctionSignature(
            new QName("parse-cql", CQLParserModule.NAMESPACE_URI, CQLParserModule.PREFIX),
            "Parses expressions in the Context Query Language (SRU/CQL), returning it back as CQL or XCQL, based on the second parameter . " +
            "basic searchClauses (index relation term) can be combined with boolean operatorer ",
            new SequenceType[] { 
            		new FunctionParameterSequenceType("expression", Type.STRING, Cardinality.ZERO_OR_ONE, "The expression to parse"),
            		new FunctionParameterSequenceType("output-as", Type.STRING, Cardinality.ZERO_OR_ONE, "Output as 'CQL' or 'XCQL'")
            },
            new FunctionReturnSequenceType( Type.ANY_TYPE, Cardinality.ZERO_OR_ONE, "the result"));
    
    public ParseCQL(XQueryContext context) {
        super(context, signature);
    }

    public Sequence eval(Sequence[] args, Sequence contextSequence)
            throws XPathException {
    
    	Sequence ret = Sequence.EMPTY_SEQUENCE;
        if (args[0].isEmpty())
            return Sequence.EMPTY_SEQUENCE;
        String query = args[0].getStringValue();
        
        String output = "CQL";
        if (!args[1].isEmpty())
            output = args[1].getStringValue();
        
      	  try {
      		CQLParser parser = new CQLParser();
//      		String local_full_query_string = query;
//      		local_full_query_string = local_full_query_string.replace("-", "%2D");
      		CQLNode  query_cql = parser.parse(query);
      		if (output.equals(OutputTypeXCQL)) {
      			// .toXCQL() still returns the xml only as a string, which has to be parsed to xml
      			// currently this is done in the xquery-function using the parse-cql function
      			ret = new StringValue(query_cql.toXCQL(0));
      		} else if (output.equals(OutputTypeString)) {
      			ret = new StringValue(query_cql.toString());
      		} else {
      			ret = new StringValue(query_cql.toCQL());
      		}
      		return ret;
      	  }
      		catch (CQLParseException e) {
      			throw new XPathException(this, "An error occurred while parsing the query expression (CQLParseException): " + e.getMessage(), e);      		
            } catch (IOException e) {
            	throw new XPathException(this, "An error occurred while parsing the query expression (IOException): " + e.getMessage(), e);
    		}
    }

}
