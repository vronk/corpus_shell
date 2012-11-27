// param
var query_input_field_id = 'querystring';

// global vars
var opt_divs = new Object();
var query_input_field;
var user_query = new Object();
var user_input;
var ixCurrentToken;
var debug=true;


$(function()
{
	query_input_field = $('#' + query_input_field_id );
	
	query_input_field.on("keyup",interpret_query);

	 if (user_input==null) {
 		user_input = new UserInput(query_input_field); 		
 	 }

});


function interpret_query(e) {

	if (!e) var e = window.event;

		//the idea to jump to the option_block on arrow-up
//	if (e.keyCode==38) { 
	 	//$('queryform').word_type.focus();
	
//			$('word_type_only_this_wf').focus();
//	 	return false;
	//} else 
	if (e.keyCode==13) { 
	 			query_input_field.focus();	 	
	 	return false;
	 } else {
	 	return interpret();
	}
}

function interpret(force) {

	//enhance (ie-safe) the input-element (textarea) with cursor-related properties	
	//cursor(query_input_field);
	
	var curpos = query_input_field.caret();
	
	// only parse if content changed
	if ((user_input.input_string != query_input_field.val()) || force)		{						
		//user_input.changed = true;
		user_input.parseInput(query_input_field.val())		
	} else {
		//user_input.changed = false;		
	}
	
	//output( "current user_input.input_string:" +  user_input.input_string );
	//output( "current cursor:" +  curpos );
	//output("currentTokenIx:" + currentTokenIx(user_input));

  var atEnd = (curpos == query_input_field.textLen);
  //user_query.onWord = (user_input.input_string[curpos ]!=" ") && !atEnd;
  query_input_field.onIndex = user_input.hasTokenTypeAt(curpos ,'index');
  query_input_field.onTerm = user_input.hasTokenTypeAt(curpos ,'searchTerm')
 
	// if (user_query.onWord) {
			
 // $('query_cql').value =  user_input.cql();
 $('#errordiv').html("curpos:" + curpos + "; " + user_input.verbose(curpos)  + "<br/>" + user_input.err_string + "<br/>" + 
 									 "tokenTypesAt:" + user_input.tokenTypesAt(curpos ) + "<br/>" + 
									"query_input_field.onIndex" + query_input_field.onIndex + "<br/>" + 
									"query_input_field.onTerm" + query_input_field.onTerm);
 
 			
/*	if (mode=="verbose" && debug) {
		tx += "<br/>t.len: " + user_input.tokens.length + "; curpos : " + curpos;
		tx += "; currTokenIx:" + user_input.tokenAt(curpos);
 */
 
}


// precondition: interpret {cursor, parse} = current user_input
function apply_opt (type, key) {	
		
	if (!user_query.cursorPosition) cursor(user_query);
		
	//var snippet = dict[type][key]['user'];	
	//snippet = sprintf(dict[type]['user'], snippet); //wrap type-prefix/sufix, especially for POS	
	var snippet = resolveKey (key, 'user');
	var curPos = user_query.cursorPosition;
	var new_qstr=user_query.value;
	
	if (type=='conn') {		
		if (user_query.selectedText) {
			if (user_query.selectedText.length>0) {
				output(user_query.selectedText + user_query.s, user_query.e );			
				//new_qstr= user_input.setGroupAt(user_query.s, user_query.e);		
	  	} else {
	  		user_input.default_op = key;
	  		selectOption('conn' , key); 
	  	}
	  } else {
	  	user_input.default_op = key;
	  	selectOption('conn' , key); 
	  }
	} else {		
		if (user_query.selectedText) {
			if (user_query.selectedText.length>0) {
				new_qstr= user_query.beforeCursor + sprintf(snippet,user_query.selectedText) + user_query.afterCursor ;
		  } else {	  		
		  	new_qstr= user_input.replaceTokenAt(curPos , sprintf(snippet,user_input.userValueAt(curPos)));	
	  	}
	  } else {
	  	new_qstr= user_input.replaceTokenAt(curPos , sprintf(snippet,user_input.userValueAt(curPos)));	
	  }
	}
	user_query.value = new_qstr;	
	setCursorAt(user_query, curPos);	
	interpret(true);
				
}

// possible values for from, to : key|user|cql|verbose|example
//example arguments: Adjektiv, user, cql
// OBSOLETED by resolveKey()
function translate_token(token, from, to) {
	
	//user_input.tokens		
	var dict_part = dict['pos'];
	for (entry in dict_part) {				
		var key = entry.toString();
		if (dict_part[key][from]==token) {			
		 return dict_part[key][to];			
		}
	}
	return token;
}

function code_optionlist(type) {

	var wrapper_div = $('opt_' + type);	
	var dict_part = dict[type];
	
	if (wrapper_div && dict_part) {  	
		var xli="<table border='0' class='forpos'";
		
	  //for (var i=0; i<dict_part.length; i++) {	  		
	  for (entry in dict_part) {	
	  		//<option>" + dict_part[i] + "</option>";	
	  		var key = entry.toString();
	  		//hacking
	  		if ((type=='pos' && dict_part[key].user) || dict_part[key].label) {
	 				xli += "<tr id='wraper_" + type + "_type_" + key + "' class='select' ><td onclick=\"apply_opt('" + type + "','" + key + "')\" >" ;
	 				if (type=='pos') {
	 					xli += dict_part[key].user + "</td><td>" + dict_part[key].verbose + "</td></tr>"; 	 				 				 			
	 				} else {	 					
	 					xli	+= "<input type='radio' name='" + type + "_type' onchange=\"apply_opt('" + type + "','" + key + "')\" value='" + key + "' >" ;	 					
	 					xli += dict_part[key].label + "</input></td></tr>"; 	 				 				 			
	 				}
	 			}
		}
		
		xli += "</table>";		
		return xli;
	}
}

function selectOption (type, curval) {
	  
    var fs = $$('input[name="' + type + '_type"]')		
    var wraper_key, wraper;
    output(fs.length);
		for(var i=0; i<fs.length; i++) {
			wraper_key = 'wraper_' + type + '_type_' + fs[i].value ;
			
			output("fsivalue:" + fs[i].value);
			wraper = $(wraper_key);		
			if (fs[i].value==curval) {
				fs[i].checked = true;
				if (wraper) wraper.className = "selected";
			} else {
				fs[i].checked = false;
				if (wraper) wraper.className = "select";
			}
	  }
}


// value of selected radio-option
// NOT USED (?)!
function selectedOption (ctrl) {
	    for (var i=0; i < ctrl.length; i++) if (ctrl[i].checked) return ctrl[i].value;
    return false;
        
}


//enhance (ie-safe) the input-element (textarea) with cursor-related properties	
var os = 0
var oe = 0
function cursor(o) {
	var t = o.val(), s = getSelectionStart(o), e = getSelectionEnd(o)
	if (s == os && e == oe) return
	o.cursorPosition = s
	// maxLength.firstChild.nodeValue = o.getAttribute('maxLength')
	o.textLen = t.length
	o.s = s;
	o.e = e;
	//	availLength.firstChild.nodeValue = o.getAttribute('maxLength') - t.length
	//output (s + ":" +  e + "-" + t.substring(s, e).replace(/ /g, '\xa0') + "-");	
	o.beforeCursor = t.substring(0, s).replace(/ /g, '\xa0') //|| '\xa0'
	o.selectedText = t.substring(s, e).replace(/ /g, '\xa0')  //|| '\xa0'	
	o.afterCursor = t.substring(e).replace(/ /g, '\xa0') //|| '\xa0'	
//	o.markedText = o.beforeCursor '<cs>' + o.selectedText + '<ce>' + o.afterCursor;
	os = s
	oe = e
	return s;
}

function getSelectionStart(o) {
	if (o.createTextRange) {
		var r = document.selection.createRange().duplicate()
		r.moveEnd('character', o.val().length)
		if (r.text == '') return o.val().length
		return o.value.lastIndexOf(r.text)
	} else return o.selectionStart
}

function getSelectionEnd(o) {
	if (o.createTextRange) {
		var r = document.selection.createRange().duplicate()
		r.moveStart('character', -o.val().length)
		return r.text.length
	} else return o.selectionEnd
}

function setCursorAt(obj, pos) { 
    if(obj.createTextRange) { 
        /* Create a TextRange, set the internal pointer to
           a specified position and show the cursor at this
           position
        */ 
        var range = obj.createTextRange(); 
        range.move("character", pos); 
        range.select(); 
    } else if(obj.selectionStart) { 
        /* Gecko is a little bit shorter on that. Simply
           focus the element and set the selection to a
           specified position
        */ 
        obj.focus(); 
        obj.setSelectionRange(pos, pos); 
		} 
} 
