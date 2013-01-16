var user_input;

function UserInput(obj)
{
    this.input_obj= obj;
    this.input_string = "";
    this.default_op = "groupand";
    this.err_string = "";

    this.nodes = new Array();
    this.tokens = new Array();
this.offsets = new Array();

    this.cql = function () { return this.rootNode() ? this.rootNode().cql : ""; };
    this.verbose = function (curpos) { return this.translateNode(this.rootNode(), 'verbose',curpos); };
    // this.lastTokenIx = function () { return ((this.tokens.length > this.pos.length) ? this.tokens.length : this.pos.length ) - 1; };
    this.rootNode = function () {return (this.nodes.length==0 ? null : this.nodes[this.nodes.length - 1]);};
    this.parseInput = parseInput;
    this.verboseParse =verboseParse;
    this.tokenAt = tokenAt;
    this.userValueAt = userValueAt;
    this.tokenTypesAt = tokenTypesAt;
    this.hasTokenTypeAt = hasTokenTypeAt;
    this.replaceTokenAt = replaceTokenAt;
    this.setGroupAt = setGroupAt;
    this.translateNode = translateNode;


}

function parseInput(str) {
    if (str) {
        this.input_string = str;
    } else if (this.input_obj) {
        this.input_string = this.input_obj.value;
    } else {
        this.input_string = "";
        this.err_string = "Nothing to parse";
        return false;
    }

    this.err_string = "";
    this.nodes = [];
    this.tokens = [];

    user_input = this;

    var error_offsets = new Array();
    var error_lookaheads = new Array();
    var error_count = 0;
    if( ( error_count = __parse( this.input_string, error_offsets, error_lookaheads ) ) > 0 ) {
                for( var i = 0; i < error_count; i++ )
                        this.err_string += "bei " + this.input_string.substr( error_offsets[i] ) + " (pos: " + error_offsets[i] + ")" + " wird " +
                        error_lookaheads[i].join(' oder ') + " erwartet" ;
    }
}

/* *************************** */
/* functions called from parse */

function offset (info) {
    return info.offset;
}

//Structs
function NODE()
{
    var type;
    var userval;
    var userx;
    var cql;
    var start;
    var len;
    var end;
    var children;
    var parent;
}

/* builds a (simplified, opportunistic) parsing-tree, collecting the cql on the fly,
thus the root node has the whole cql-query.
paste %1["children"] as children param to flatten the siblings
*/
function createNode( type, user_value, user_string, cql, start, children ) {
    var n = new NODE();
    n.type = type;
    n.userval = user_value;
    n.userx= user_string;
    n.cql = cql;

    n.len = n.userx.length;
    // special handling (or hacking?) for the right-end-nodes, otherwise shift one, for 0-based indexing
    // (the offset seems somehow not to increment at the end of the string anymore)

    /*
    if (offset==user_input.input_string.length) {
        offset = (user_string == user_input.input_string.substring(offset-n.len)) ? offset : offset -1;
    } else {
        offset = offset -1;
    }
    */
    /*
    //(offset==n.len)
    //offset = (offset==user_input.input_string.length) ? offset : offset - 1;
    //if offset = (offset==n.len) ? offset : offset - 1;
    //offset = (offset==n.len) ? offset : offset - 1;
    */
    n.start = start;
    n.end = start + n.len;
    n.children = [];

    if (n.userval!="") user_input.tokens.push(n);

    for( var i = 5; i < arguments.length; i++ )
    {
            n.children = n.children.concat(arguments[i])
    }

    // every child has the right to know its parent.
    for( var i = 0; i < n.children.length; i++ ) {
            n.children[i].parent = n;
    }
    //output(n.type + n.children.length );
    output("DEBUG:cN(): " + n.type + ":" + n.userval + ": " + n.children.length);
    user_input.nodes.push(n);
    return n;
}

// from terminal part, one gets the right offset = beginning of the token
// i am sure this can be done better
function createLeafNode ( type, user_value, user_string, cql, start) {
    var n = new NODE();
    n.type = type;
    n.userval = user_value;
    n.userx= user_string;
    n.cql = cql;


    n.len = n.userx.length;
    // special handling (or hacking?) for the right-end-nodes, otherwise shift one, for 0-based indexing
    // (the offset seems somehow not to increment at the end of the string anymore)

    n.start = start;
    n.end = start + n.len;
    n.children = [];


    if (n.userval!="") user_input.tokens.push(n);

    user_input.nodes.push(n);
    return n;
}

function tokenAt(ix) {
    //output ("ix: " + ix);
    //output ("tokens.length:" + this.tokens.length);
    for( var i = 0; i < this.tokens.length; i++ )    {
        if (this.tokens[i].start <= ix && this.tokens[i].end >= ix) return i;
    }
    return -1;
}

// process default connector
function resolveBag(n) {

    n.type=user_input.default_op;

    var pattern = resolveKey(user_input.default_op, 'cql');
    var fix = pattern.split("\%s");
    var prefix="", infix="", sufix="";
    if (fix.length==1) {
        infix = fix[0];
    } else if (fix.length==2) {
        prefix=fix[0];
        sufix=fix[1];
    } else if (fix.length==3) {
        prefix=fix[0];
        infix = fix[1];
        sufix=fix[2];
    }
    var cql = prefix;
    for( var i = 0; i < n.children.length; i++ ) {
         cql = cql +    n.children[i].cql;
         if (i != (n.children.length-1)) cql = cql + infix;
    }
    cql = cql + sufix;

    return cql;
}

/* ************************** */
/* functions used after parse */

function verboseParse () {
        x = "input_string:" + this.input_string + "\n";
        x = x + "err: " + this.err_string + "\n";
        x = x + "token-len:" + this.tokens.length + "\n";
        x = x + "cql:" + this.cql() + "\n";
     x = x + "nodes:\n";
     x = x + formatNode(this.nodes[this.nodes.length -1]);
     return x;
}

function userValueAt(ix) {
    var n = this.tokens[this.tokenAt(ix)]
    if (typeof n== "undefined") {
        return "";
    } else {
        return n.userval;
    }
}

// boolean if the n.type of token or one of its parents = @type
function hasTokenTypeAt(ix,type) {

    var tts = this.tokenTypesAt(ix);
    for(var i = 0; i < tts.length; i++) if(tts[i] == type) return true;
return false;
}

// return array of types (also of parents) for token at position @ix
function tokenTypesAt(ix) {
     var n = this.tokens[this.tokenAt(ix)]

    if (typeof n== "undefined") {
        return [];
    } else {
        return tokenTypes(n);
    }
}

// return array of types (also of parents)
function tokenTypes(n) {
    if (n.parent) {
        var tt = [n.type];
        return tt.concat(tokenTypes(n.parent));
} else {
    return n.type;
    }
}

function replaceTokenAt(ix,new_token) {

    var new_q= this.input_string;

    var old_node = this.tokens[this.tokenAt(ix)];
//        output(ix + ": " + this.tokenAt(ix) + "-" + this.tokens[this.tokenAt(ix)]);

    if (old_node) {
    //    output(formatNode(old_node));
        var new_q= this.input_string.substring(0, old_node.start) + new_token + this.input_string.substring(old_node.end);
    }    else {
        var new_q= this.input_string.substring(0, ix ) + new_token + this.input_string.substring(ix);
    }

    return new_q;

}

// not working yet
function setGroupAt(startPos, endPos, conn_type) {
    var new_q= this.input_string;

// replace only full tokens
var startIx = this.tokenAt(startPos);
var endIx = this.tokenAt(endPos);


// ! dict_entry.user - changed!
var pattern = resolveKey(conn_type, 'user');

    var fix = pattern.split("\%s");
    var prefix="", infix="", sufix="";
    if (fix.length==1) {
        infix = fix[0];
    } else if (fix.length==2) {
        prefix=fix[0];
        sufix=fix[1];
    } else if (fix.length==3) {
        prefix=fix[0];
        infix = fix[1];
        sufix=fix[2];
    }

    var new_q= this.input_string.substring(0, this.tokens[startIx].start);
    new_q = new_q + prefix;

for (var i = startIx; i < endIx; i++) {
    var old_node = this.tokens[i];
    new_q = new_q + old_node.userx;
    if (i != (endIx - 1)) new_q = new_q + infix;
}
new_q = new_q + sufix + this.input_string.substring(this.tokens[endIx].end);

return new_q;
}

function formatNode(n,prefix) {
    if (!prefix) prefix="";
    x = prefix + n.type + ": " + n.userval + ", " + n.userx + ", " + n.cql + " at " + n.start + "-" + n.end + ", len: " + n.len /* + n.cql + n.children */ + "\n";
        if (n.children) {
            if (n.children.length>0) {
             x = x + prefix + "{\n";
                for( var i = 0; i < n.children.length; i++ )
                    x = x + prefix + formatNode(n.children[i],prefix + " " );
              x = x + prefix + "}\n";
             }
         }
    return x;
}

function translateNode(n, mode, curpos) {
     // output("n:" + formatNode(n," "));
    if (n == null) return "";

    var key = "", pattern="", userval="";

    if (n.type=='pos') {
        userval = resolveUserToken('pos',n.userval,mode);
        pattern = dict['pos'][mode];
    } else {
        key = n.type;
        pattern = resolveKey(key, mode);
        userval = n.userval;
    }

    if (!pattern) pattern = "%s"; // default: fill uservalx

    //output("pattern:" + pattern);
    var fix = pattern.split("\%s");

    var prefix=fix[0] ? fix[0] : "" ;
    var infix=fix[1] ? fix[1] : "" ;
    var sufix=fix[2] ? fix[2] : "" ;


    var x ="";

    if (userval) {            // should be only on leaves;
        var uservalx;
        if (mode=="verbose") {
            uservalx = "" + userval + "";
        } else {
            uservalx = userval ;
     }
     // highlight curent Token
     if (mode=="verbose" && n == this.tokens[this.tokenAt(curpos)]) {
         x = x + "" + sprintf(pattern, uservalx) + "";
        } else {
            x = x + sprintf(pattern, uservalx);
     }
    }
    // this should be xor (userval or children)
    if (n.children) {
        if (curpos >= n.start && curpos <= n.end) {
            prefix = "" + prefix + "";
            infix = "" + infix + "";
            sufix = "" + sufix + "";
        }
        //output (n.children.length);
        if (n.children.length>0) {
            x = x + prefix;
            for( var i = 0; i < n.children.length; i++ ) {
                var child = this.translateNode(n.children[i],mode,curpos);
                if (child.length>0) {
                    x = x + child;
                    if (i != (n.children.length-1)) x = x + infix;
                }
            }
            x = x + sufix;
        }

    }

    return x;
}

function TestCql (inputStr)
{
if (inputStr)
{
var testUserInput = new UserInput();
testUserInput.parseInput(inputStr);
return testUserInput;
}

return null;
}



/*
    Default template driver for JS/CC generated parsers running as
    browser-based JavaScript/ECMAScript applications.

    WARNING:     This parser template will not run as console and has lesser
                features for debugging than the console derivates for the
                various JavaScript platforms.

    Features:
    - Parser trace messages
    - Integrated panic-mode error recovery

    Written 2007, 2008 by Jan Max Meyer, J.M.K S.F. Software Technologies

    This is in the public domain.
*/

var _dbg_withtrace        = false;
var _dbg_string            = new String();

function __dbg_print( text )
{
    _dbg_string += text + "\n";
}

function __lex( info )
{
    var state        = 0;
    var match        = -1;
    var match_pos    = 0;
    var start        = 0;
    var pos            = info.offset + 1;

    do
    {
        pos--;
        state = 0;
        match = -2;
        start = pos;

        if( info.src.length <= start )
            return 21;

        do
        {

switch( state )
{
    case 0:
        if( ( info.src.charCodeAt( pos ) >= 9 && info.src.charCodeAt( pos ) <= 10 ) || info.src.charCodeAt( pos ) == 13 || info.src.charCodeAt( pos ) == 32 ) state = 1;
        else if( info.src.charCodeAt( pos ) == 34 ) state = 2;
        else if( info.src.charCodeAt( pos ) == 40 ) state = 3;
        else if( info.src.charCodeAt( pos ) == 41 ) state = 4;
        else if( ( info.src.charCodeAt( pos ) >= 48 && info.src.charCodeAt( pos ) <= 57 ) ) state = 5;
        else if( info.src.charCodeAt( pos ) == 61 ) state = 6;
        else if( info.src.charCodeAt( pos ) == 65 ) state = 7;
        else if( info.src.charCodeAt( pos ) == 79 ) state = 10;
        else if( info.src.charCodeAt( pos ) == 111 ) state = 11;
        else if( ( info.src.charCodeAt( pos ) >= 66 && info.src.charCodeAt( pos ) <= 78 ) || ( info.src.charCodeAt( pos ) >= 80 && info.src.charCodeAt( pos ) <= 90 ) || info.src.charCodeAt( pos ) == 95 || ( info.src.charCodeAt( pos ) >= 98 && info.src.charCodeAt( pos ) <= 110 ) || ( info.src.charCodeAt( pos ) >= 112 && info.src.charCodeAt( pos ) <= 122 ) || info.src.charCodeAt( pos ) == 196 || info.src.charCodeAt( pos ) == 214 || info.src.charCodeAt( pos ) == 220 || info.src.charCodeAt( pos ) == 223 || info.src.charCodeAt( pos ) == 228 || info.src.charCodeAt( pos ) == 246 || info.src.charCodeAt( pos ) == 252 ) state = 14;
        else if( info.src.charCodeAt( pos ) == 97 ) state = 15;
        else state = -1;
        break;

    case 1:
        state = -1;
        match = 1;
        match_pos = pos;
        break;

    case 2:
        state = -1;
        match = 9;
        match_pos = pos;
        break;

    case 3:
        state = -1;
        match = 5;
        match_pos = pos;
        break;

    case 4:
        state = -1;
        match = 6;
        match_pos = pos;
        break;

    case 5:
        if( ( info.src.charCodeAt( pos ) >= 48 && info.src.charCodeAt( pos ) <= 57 ) ) state = 5;
        else state = -1;
        match = 8;
        match_pos = pos;
        break;

    case 6:
        state = -1;
        match = 4;
        match_pos = pos;
        break;

    case 7:
        if( info.src.charCodeAt( pos ) == 78 ) state = 12;
        else if( ( info.src.charCodeAt( pos ) >= 65 && info.src.charCodeAt( pos ) <= 77 ) || ( info.src.charCodeAt( pos ) >= 79 && info.src.charCodeAt( pos ) <= 90 ) || info.src.charCodeAt( pos ) == 95 || ( info.src.charCodeAt( pos ) >= 97 && info.src.charCodeAt( pos ) <= 122 ) || info.src.charCodeAt( pos ) == 196 || info.src.charCodeAt( pos ) == 214 || info.src.charCodeAt( pos ) == 220 || info.src.charCodeAt( pos ) == 223 || info.src.charCodeAt( pos ) == 228 || info.src.charCodeAt( pos ) == 246 || info.src.charCodeAt( pos ) == 252 ) state = 14;
        else state = -1;
        match = 7;
        match_pos = pos;
        break;

    case 8:
        if( ( info.src.charCodeAt( pos ) >= 65 && info.src.charCodeAt( pos ) <= 90 ) || info.src.charCodeAt( pos ) == 95 || ( info.src.charCodeAt( pos ) >= 97 && info.src.charCodeAt( pos ) <= 122 ) || info.src.charCodeAt( pos ) == 196 || info.src.charCodeAt( pos ) == 214 || info.src.charCodeAt( pos ) == 220 || info.src.charCodeAt( pos ) == 223 || info.src.charCodeAt( pos ) == 228 || info.src.charCodeAt( pos ) == 246 || info.src.charCodeAt( pos ) == 252 ) state = 14;
        else state = -1;
        match = 3;
        match_pos = pos;
        break;

    case 9:
        if( ( info.src.charCodeAt( pos ) >= 65 && info.src.charCodeAt( pos ) <= 90 ) || info.src.charCodeAt( pos ) == 95 || ( info.src.charCodeAt( pos ) >= 97 && info.src.charCodeAt( pos ) <= 122 ) || info.src.charCodeAt( pos ) == 196 || info.src.charCodeAt( pos ) == 214 || info.src.charCodeAt( pos ) == 220 || info.src.charCodeAt( pos ) == 223 || info.src.charCodeAt( pos ) == 228 || info.src.charCodeAt( pos ) == 246 || info.src.charCodeAt( pos ) == 252 ) state = 14;
        else state = -1;
        match = 2;
        match_pos = pos;
        break;

    case 10:
        if( info.src.charCodeAt( pos ) == 82 ) state = 8;
        else if( ( info.src.charCodeAt( pos ) >= 65 && info.src.charCodeAt( pos ) <= 81 ) || ( info.src.charCodeAt( pos ) >= 83 && info.src.charCodeAt( pos ) <= 90 ) || info.src.charCodeAt( pos ) == 95 || ( info.src.charCodeAt( pos ) >= 97 && info.src.charCodeAt( pos ) <= 122 ) || info.src.charCodeAt( pos ) == 196 || info.src.charCodeAt( pos ) == 214 || info.src.charCodeAt( pos ) == 220 || info.src.charCodeAt( pos ) == 223 || info.src.charCodeAt( pos ) == 228 || info.src.charCodeAt( pos ) == 246 || info.src.charCodeAt( pos ) == 252 ) state = 14;
        else state = -1;
        match = 7;
        match_pos = pos;
        break;

    case 11:
        if( info.src.charCodeAt( pos ) == 114 ) state = 8;
        else if( ( info.src.charCodeAt( pos ) >= 65 && info.src.charCodeAt( pos ) <= 90 ) || info.src.charCodeAt( pos ) == 95 || ( info.src.charCodeAt( pos ) >= 97 && info.src.charCodeAt( pos ) <= 113 ) || ( info.src.charCodeAt( pos ) >= 115 && info.src.charCodeAt( pos ) <= 122 ) || info.src.charCodeAt( pos ) == 196 || info.src.charCodeAt( pos ) == 214 || info.src.charCodeAt( pos ) == 220 || info.src.charCodeAt( pos ) == 223 || info.src.charCodeAt( pos ) == 228 || info.src.charCodeAt( pos ) == 246 || info.src.charCodeAt( pos ) == 252 ) state = 14;
        else state = -1;
        match = 7;
        match_pos = pos;
        break;

    case 12:
        if( info.src.charCodeAt( pos ) == 68 ) state = 9;
        else if( ( info.src.charCodeAt( pos ) >= 65 && info.src.charCodeAt( pos ) <= 67 ) || ( info.src.charCodeAt( pos ) >= 69 && info.src.charCodeAt( pos ) <= 90 ) || info.src.charCodeAt( pos ) == 95 || ( info.src.charCodeAt( pos ) >= 97 && info.src.charCodeAt( pos ) <= 122 ) || info.src.charCodeAt( pos ) == 196 || info.src.charCodeAt( pos ) == 214 || info.src.charCodeAt( pos ) == 220 || info.src.charCodeAt( pos ) == 223 || info.src.charCodeAt( pos ) == 228 || info.src.charCodeAt( pos ) == 246 || info.src.charCodeAt( pos ) == 252 ) state = 14;
        else state = -1;
        match = 7;
        match_pos = pos;
        break;

    case 13:
        if( info.src.charCodeAt( pos ) == 100 ) state = 9;
        else if( ( info.src.charCodeAt( pos ) >= 65 && info.src.charCodeAt( pos ) <= 90 ) || info.src.charCodeAt( pos ) == 95 || ( info.src.charCodeAt( pos ) >= 97 && info.src.charCodeAt( pos ) <= 99 ) || ( info.src.charCodeAt( pos ) >= 101 && info.src.charCodeAt( pos ) <= 122 ) || info.src.charCodeAt( pos ) == 196 || info.src.charCodeAt( pos ) == 214 || info.src.charCodeAt( pos ) == 220 || info.src.charCodeAt( pos ) == 223 || info.src.charCodeAt( pos ) == 228 || info.src.charCodeAt( pos ) == 246 || info.src.charCodeAt( pos ) == 252 ) state = 14;
        else state = -1;
        match = 7;
        match_pos = pos;
        break;

    case 14:
        if( ( info.src.charCodeAt( pos ) >= 65 && info.src.charCodeAt( pos ) <= 90 ) || info.src.charCodeAt( pos ) == 95 || ( info.src.charCodeAt( pos ) >= 97 && info.src.charCodeAt( pos ) <= 122 ) || info.src.charCodeAt( pos ) == 196 || info.src.charCodeAt( pos ) == 214 || info.src.charCodeAt( pos ) == 220 || info.src.charCodeAt( pos ) == 223 || info.src.charCodeAt( pos ) == 228 || info.src.charCodeAt( pos ) == 246 || info.src.charCodeAt( pos ) == 252 ) state = 14;
        else state = -1;
        match = 7;
        match_pos = pos;
        break;

    case 15:
        if( info.src.charCodeAt( pos ) == 110 ) state = 13;
        else if( ( info.src.charCodeAt( pos ) >= 65 && info.src.charCodeAt( pos ) <= 90 ) || info.src.charCodeAt( pos ) == 95 || ( info.src.charCodeAt( pos ) >= 97 && info.src.charCodeAt( pos ) <= 109 ) || ( info.src.charCodeAt( pos ) >= 111 && info.src.charCodeAt( pos ) <= 122 ) || info.src.charCodeAt( pos ) == 196 || info.src.charCodeAt( pos ) == 214 || info.src.charCodeAt( pos ) == 220 || info.src.charCodeAt( pos ) == 223 || info.src.charCodeAt( pos ) == 228 || info.src.charCodeAt( pos ) == 246 || info.src.charCodeAt( pos ) == 252 ) state = 14;
        else state = -1;
        match = 7;
        match_pos = pos;
        break;

}


            pos++;

        }
        while( state > -1 );

    }
    while( 1 > -1 && match == 1 );

    if( match > -1 )
    {
        info.att = info.src.substr( start, match_pos - start );
        info.offset = match_pos;

switch( match )
{
    case 2:
        {
         info.att = createLeafNode("logopand", '', info.att, ' and ', ( info.offset - info.att.length ));
        }
        break;

    case 3:
        {
         info.att = createLeafNode("logopor", '', info.att, ' or ', ( info.offset - info.att.length ));
        }
        break;

    case 4:
        {
         info.att = createLeafNode("equals", '=', info.att, ' = ', ( info.offset - info.att.length ));
        }
        break;

    case 7:
        {
         info.att = createLeafNode("alpha", info.att, info.att, info.att, ( info.offset - info.att.length ));
        }
        break;

    case 8:
        {
         info.att = parseInt( info.att );
        }
        break;

    case 9:
        {
         info.att = createLeafNode("quote", info.att, info.att, info.att, ( info.offset - info.att.length ));
        }
        break;

}


    }
    else
    {
        info.att = new String();
        match = -1;
    }

    return match;
}


function __parse( src, err_off, err_la )
{
    var        sstack            = new Array();
    var        vstack            = new Array();
    var     err_cnt            = 0;
    var        act;
    var        go;
    var        la;
    var        rval;
    var     parseinfo        = new Function( "", "var offset; var src; var att;" );
    var        info            = new parseinfo();

/* Pop-Table */
var pop_tab = new Array(
    new Array( 0/* cqlQuery' */, 1 ),
    new Array( 11/* cqlQuery */, 1 ),
    new Array( 10/* searchClause */, 3 ),
    new Array( 10/* searchClause */, 1 ),
    new Array( 12/* index */, 1 ),
    new Array( 14/* searchTerm */, 1 ),
    new Array( 13/* relation */, 1 ),
    new Array( 16/* comparitor */, 1 ),
    new Array( 15/* term */, 1 ),
    new Array( 17/* identifier */, 1 ),
    new Array( 17/* identifier */, 1 ),
    new Array( 18/* charString1 */, 1 ),
    new Array( 19/* charString2 */, 3 ),
    new Array( 20/* alphaNum */, 1 ),
    new Array( 20/* alphaNum */, 1 )
);

/* Action-Table */
var act_tab = new Array(
    /* State 0 */ new Array( 9/* "QUOTE" */,10 , 7/* "ALPHA" */,11 , 8/* "INT" */,12 ),
    /* State 1 */ new Array( 21/* "$" */,0 ),
    /* State 2 */ new Array( 21/* "$" */,-1 ),
    /* State 3 */ new Array( 4/* "EQ" */,15 ),
    /* State 4 */ new Array( 21/* "$" */,-3 ),
    /* State 5 */ new Array( 4/* "EQ" */,-4 , 21/* "$" */,-5 ),
    /* State 6 */ new Array( 4/* "EQ" */,-8 , 21/* "$" */,-8 ),
    /* State 7 */ new Array( 4/* "EQ" */,-9 , 21/* "$" */,-9 ),
    /* State 8 */ new Array( 4/* "EQ" */,-10 , 21/* "$" */,-10 ),
    /* State 9 */ new Array( 4/* "EQ" */,-11 , 21/* "$" */,-11 ),
    /* State 10 */ new Array( 7/* "ALPHA" */,11 , 8/* "INT" */,12 ),
    /* State 11 */ new Array( 4/* "EQ" */,-13 , 21/* "$" */,-13 , 9/* "QUOTE" */,-13 ),
    /* State 12 */ new Array( 4/* "EQ" */,-14 , 21/* "$" */,-14 , 9/* "QUOTE" */,-14 ),
    /* State 13 */ new Array( 9/* "QUOTE" */,10 , 7/* "ALPHA" */,11 , 8/* "INT" */,12 ),
    /* State 14 */ new Array( 9/* "QUOTE" */,-6 , 7/* "ALPHA" */,-6 , 8/* "INT" */,-6 ),
    /* State 15 */ new Array( 9/* "QUOTE" */,-7 , 7/* "ALPHA" */,-7 , 8/* "INT" */,-7 ),
    /* State 16 */ new Array( 9/* "QUOTE" */,19 ),
    /* State 17 */ new Array( 21/* "$" */,-2 ),
    /* State 18 */ new Array( 21/* "$" */,-5 ),
    /* State 19 */ new Array( 4/* "EQ" */,-12 , 21/* "$" */,-12 )
);

/* Goto-Table */
var goto_tab = new Array(
    /* State 0 */ new Array( 11/* cqlQuery */,1 , 10/* searchClause */,2 , 12/* index */,3 , 14/* searchTerm */,4 , 15/* term */,5 , 17/* identifier */,6 , 18/* charString1 */,7 , 19/* charString2 */,8 , 20/* alphaNum */,9 ),
    /* State 1 */ new Array( ),
    /* State 2 */ new Array( ),
    /* State 3 */ new Array( 13/* relation */,13 , 16/* comparitor */,14 ),
    /* State 4 */ new Array( ),
    /* State 5 */ new Array( ),
    /* State 6 */ new Array( ),
    /* State 7 */ new Array( ),
    /* State 8 */ new Array( ),
    /* State 9 */ new Array( ),
    /* State 10 */ new Array( 20/* alphaNum */,16 ),
    /* State 11 */ new Array( ),
    /* State 12 */ new Array( ),
    /* State 13 */ new Array( 14/* searchTerm */,17 , 15/* term */,18 , 17/* identifier */,6 , 18/* charString1 */,7 , 19/* charString2 */,8 , 20/* alphaNum */,9 ),
    /* State 14 */ new Array( ),
    /* State 15 */ new Array( ),
    /* State 16 */ new Array( ),
    /* State 17 */ new Array( ),
    /* State 18 */ new Array( ),
    /* State 19 */ new Array( )
);



/* Symbol labels */
var labels = new Array(
    "cqlQuery'" /* Non-terminal symbol */,
    "WHITESPACE" /* Terminal symbol */,
    "AND" /* Terminal symbol */,
    "OR" /* Terminal symbol */,
    "EQ" /* Terminal symbol */,
    "BRACKETOPEN" /* Terminal symbol */,
    "BRACKETCLOSE" /* Terminal symbol */,
    "ALPHA" /* Terminal symbol */,
    "INT" /* Terminal symbol */,
    "QUOTE" /* Terminal symbol */,
    "searchClause" /* Non-terminal symbol */,
    "cqlQuery" /* Non-terminal symbol */,
    "index" /* Non-terminal symbol */,
    "relation" /* Non-terminal symbol */,
    "searchTerm" /* Non-terminal symbol */,
    "term" /* Non-terminal symbol */,
    "comparitor" /* Non-terminal symbol */,
    "identifier" /* Non-terminal symbol */,
    "charString1" /* Non-terminal symbol */,
    "charString2" /* Non-terminal symbol */,
    "alphaNum" /* Non-terminal symbol */,
    "$" /* Terminal symbol */
);



    info.offset = 0;
    info.src = src;
    info.att = new String();

    if( !err_off )
        err_off    = new Array();
    if( !err_la )
    err_la = new Array();

    sstack.push( 0 );
    vstack.push( 0 );

    la = __lex( info );

    while( true )
    {
        act = 21;
        for( var i = 0; i < act_tab[sstack[sstack.length-1]].length; i+=2 )
        {
            if( act_tab[sstack[sstack.length-1]][i] == la )
            {
                act = act_tab[sstack[sstack.length-1]][i+1];
                break;
            }
        }

        if( _dbg_withtrace && sstack.length > 0 )
        {
            __dbg_print( "\nState " + sstack[sstack.length-1] + "\n" +
                            "\tLookahead: " + labels[la] + " (\"" + info.att + "\")\n" +
                            "\tAction: " + act + "\n" +
                            "\tSource: \"" + info.src.substr( info.offset, 30 ) + ( ( info.offset + 30 < info.src.length ) ?
                                    "..." : "" ) + "\"\n" +
                            "\tStack: " + sstack.join() + "\n" +
                            "\tValue stack: " + vstack.join() + "\n" );
        }


        //Panic-mode: Try recovery when parse-error occurs!
        if( act == 21 )
        {
            if( _dbg_withtrace )
                __dbg_print( "Error detected: There is no reduce or shift on the symbol " + labels[la] );

            err_cnt++;
            err_off.push( info.offset - info.att.length );
            err_la.push( new Array() );
            for( var i = 0; i < act_tab[sstack[sstack.length-1]].length; i+=2 )
                err_la[err_la.length-1].push( labels[act_tab[sstack[sstack.length-1]][i]] );

            //Remember the original stack!
            var rsstack = new Array();
            var rvstack = new Array();
            for( var i = 0; i < sstack.length; i++ )
            {
                rsstack[i] = sstack[i];
                rvstack[i] = vstack[i];
            }

            while( act == 21 && la != 21 )
            {
                if( _dbg_withtrace )
                    __dbg_print( "\tError recovery\n" +
                                    "Current lookahead: " + labels[la] + " (" + info.att + ")\n" +
                                    "Action: " + act + "\n\n" );
                if( la == -1 )
                    info.offset++;

                while( act == 21 && sstack.length > 0 )
                {
                    sstack.pop();
                    vstack.pop();

                    if( sstack.length == 0 )
                        break;

                    act = 21;
                    for( var i = 0; i < act_tab[sstack[sstack.length-1]].length; i+=2 )
                    {
                        if( act_tab[sstack[sstack.length-1]][i] == la )
                        {
                            act = act_tab[sstack[sstack.length-1]][i+1];
                            break;
                        }
                    }
                }

                if( act != 21 )
                    break;

                for( var i = 0; i < rsstack.length; i++ )
                {
                    sstack.push( rsstack[i] );
                    vstack.push( rvstack[i] );
                }

                la = __lex( info );
            }

            if( act == 21 )
            {
                if( _dbg_withtrace )
                    __dbg_print( "\tError recovery failed, terminating parse process..." );
                break;
            }


            if( _dbg_withtrace )
                __dbg_print( "\tError recovery succeeded, continuing" );
        }

        /*
        if( act == 21 )
            break;
        */


        //Shift
        if( act > 0 )
        {
            if( _dbg_withtrace )
                __dbg_print( "Shifting symbol: " + labels[la] + " (" + info.att + ")" );

            sstack.push( act );
            vstack.push( info.att );

            la = __lex( info );

            if( _dbg_withtrace )
                __dbg_print( "\tNew lookahead symbol: " + labels[la] + " (" + info.att + ")" );
        }
        //Reduce
        else
        {
            act *= -1;

            if( _dbg_withtrace )
                __dbg_print( "Reducing by producution: " + act );

            rval = void(0);

            if( _dbg_withtrace )
                __dbg_print( "\tPerforming semantic action..." );

switch( act )
{
    case 0:
    {
        rval = vstack[ vstack.length - 1 ];
    }
    break;
    case 1:
    {
         rval= createNode("cqlQuery", "", vstack[ vstack.length - 1 ]['userx'], vstack[ vstack.length - 1 ]['cql'], vstack[ vstack.length - 1 ]['start'], vstack[ vstack.length - 1 ]);
    }
    break;
    case 2:
    {
         rval= createNode("searchClause", "", vstack[ vstack.length - 3 ]['userx'] + vstack[ vstack.length - 2 ]['userx'] + vstack[ vstack.length - 1 ]['userx'], vstack[ vstack.length - 3 ]['cql'] + vstack[ vstack.length - 2 ]['cql'] + vstack[ vstack.length - 1 ]['cql'], vstack[ vstack.length - 3 ]['start'], vstack[ vstack.length - 3 ], vstack[ vstack.length - 2 ], vstack[ vstack.length - 1 ]);
    }
    break;
    case 3:
    {
         rval= createNode("searchClause", "", vstack[ vstack.length - 1 ]['userx'], vstack[ vstack.length - 1 ]['cql'], vstack[ vstack.length - 1 ]['start'], vstack[ vstack.length - 1 ]);
    }
    break;
    case 4:
    {
         rval= createNode("index", "", vstack[ vstack.length - 1 ]['userx'], vstack[ vstack.length - 1 ]['cql'], vstack[ vstack.length - 1 ]['start'], vstack[ vstack.length - 1 ]);
    }
    break;
    case 5:
    {
         rval= createNode("searchTerm", "", vstack[ vstack.length - 1 ]['userx'], vstack[ vstack.length - 1 ]['cql'], vstack[ vstack.length - 1 ]['start'], vstack[ vstack.length - 1 ]);
    }
    break;
    case 6:
    {
         rval= createNode("relation", "", vstack[ vstack.length - 1 ]['userx'], vstack[ vstack.length - 1 ]['cql'], vstack[ vstack.length - 1 ]['start'], vstack[ vstack.length - 1 ]);
    }
    break;
    case 7:
    {
         rval= createNode("comparitor", "", vstack[ vstack.length - 1 ]['userx'], vstack[ vstack.length - 1 ]['cql'], vstack[ vstack.length - 1 ]['start'], vstack[ vstack.length - 1 ]);
    }
    break;
    case 8:
    {
         rval= createNode("term", "", vstack[ vstack.length - 1 ]['userx'], vstack[ vstack.length - 1 ]['cql'], vstack[ vstack.length - 1 ]['start'], vstack[ vstack.length - 1 ]['children']);
    }
    break;
    case 9:
    {
         rval= createNode("identifier", "", vstack[ vstack.length - 1 ]['userx'], vstack[ vstack.length - 1 ]['cql'], vstack[ vstack.length - 1 ]['start'], vstack[ vstack.length - 1 ]['children']);
    }
    break;
    case 10:
    {
         rval= createNode("identifier", "", vstack[ vstack.length - 1 ]['userx'], vstack[ vstack.length - 1 ]['cql'], vstack[ vstack.length - 1 ]['start'], vstack[ vstack.length - 1 ]['children']);
    }
    break;
    case 11:
    {
         rval= createNode("charString", "", vstack[ vstack.length - 1 ]['userx'], vstack[ vstack.length - 1 ]['cql'], vstack[ vstack.length - 1 ]['start'], vstack[ vstack.length - 1 ]);
    }
    break;
    case 12:
    {
         rval= createNode("charString", "", vstack[ vstack.length - 3 ] + vstack[ vstack.length - 2 ]['userx'] + vstack[ vstack.length - 1 ], '"' + vstack[ vstack.length - 2 ]['cql'] + '"', vstack[ vstack.length - 3 ]['start']);
    }
    break;
    case 13:
    {
         rval= createNode("alphanum", "", vstack[ vstack.length - 1 ]['userx'], vstack[ vstack.length - 1 ]['cql'], vstack[ vstack.length - 1 ]['start'], vstack[ vstack.length - 1 ]);
    }
    break;
    case 14:
    {
        rval = vstack[ vstack.length - 1 ];
    }
    break;
}



            if( _dbg_withtrace )
                __dbg_print( "\tPopping " + pop_tab[act][1] + " off the stack..." );

            for( var i = 0; i < pop_tab[act][1]; i++ )
            {
                sstack.pop();
                vstack.pop();
            }

            go = -1;
            for( var i = 0; i < goto_tab[sstack[sstack.length-1]].length; i+=2 )
            {
                if( goto_tab[sstack[sstack.length-1]][i] == pop_tab[act][0] )
                {
                    go = goto_tab[sstack[sstack.length-1]][i+1];
                    break;
                }
            }

            if( act == 0 )
                break;

            if( _dbg_withtrace )
                __dbg_print( "\tPushing non-terminal " + labels[ pop_tab[act][0] ] );

            sstack.push( go );
            vstack.push( rval );
        }

        if( _dbg_withtrace )
        {
            alert( _dbg_string );
            _dbg_string = new String();
        }
    }

    if( _dbg_withtrace )
    {
        __dbg_print( "\nParse complete." );
        alert( _dbg_string );
    }

    return err_cnt;
}




// invocation for testing (webenv with prompt or commandline with arguments)

var input_str="";
var test_user_input;

if (typeof inProduction =="undefined") {

if (typeof arguments != "undefined") {
        if (arguments[0]) input_str = arguments[0];
}
if (input_str=="" && typeof prompt== 'function' ) {
     input_str= prompt( "Please enter a string to be parsed:", "" );
}

if (input_str) {
         test_user_input = new UserInput();
         test_user_input.parseInput(input_str);
        //output ("test: " + test_user_input.test);
        output (test_user_input.verboseParse());
}
}

function test(ix) {
    var ui = new UserInput();
    if (ix) {
        if (dict.test[ix]) {
            ui.parseInput(dict.test[ix]);
            output (ui.verboseParse());
        }
        return;
    }
    for( var i = 0; i < dict.test.length; i++ )    {
            ui.parseInput(dict.test[i]);
            output (ui.verboseParse());
    }
}

function output (x) {
    if (typeof console != 'undefined') {
        console.log(x);
    } else if (typeof print == 'function') {
        print (x);
    } else if (typeof alert == 'function') {
        alert(x);
    }

}
