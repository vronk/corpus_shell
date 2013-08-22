/** special query-input widgets for CQL-input
  * searchclause-set and cql-parsing input

/** generate cql-search clause */ 
function genCQLInput(key, param_settings) {
    
    // main input for the string-version of the search-clause (probably hidden)
        var new_input = $("<input />");
            new_input.attr("id",key);
            new_input.attr("name",key);
        
        
        var query_object = new Query(key, param_settings);
        var new_cql_widget = $("<div id='" + key + "-widget' ></div>");
        
        // link the widget and the query object 
        //new_cql_widget.data("query_object") = query_object;
        new_cql_widget.query_object = query_object;
        console.log("new_cql_widget.query_object:");
        console.log(new_cql_widget.query_object);
        query_object.widget = new_cql_widget;
        
        // add first SC 
        query_object.addSearchClause(null,"");
        
        return [new_input, new_cql_widget];
}


/** constructor for a Qurey-object - bascally a set of search clauses (previously: Searchclauseset */
function Query(key, param_settings) {
    this.key = key;
    this.cql_config = param_settings.cql_config;
    
    // the parent widget holding the search-clauses;
    this.widget ={};
    
    this.searchclauses = [];
    this.and_divs = [];

    /** add SC relative to an existing one */    
    this.addSearchClause = function(source_clause, rel) {
    
        var add_and = 0;
        // compute the position-index in the search-clauses (and/or-matrix)
        if (source_clause == null || rel=='and') {
        // if no related clause, put at the end
            and_pos = this.searchclauses.length;
            or_pos = 0;
            add_and = 1;
         } else {
            and_pos = source_clause.and_pos;
            or_pos = this.searchclauses[and_pos].length;
         }
        
        console.log (and_pos + '-' + or_pos);
        
        if (add_and==1) {
            this.searchclauses[and_pos] = [];
            var and_div = $("<div class='and_level'>");
            this.widget.append(and_div);
            this.and_divs[and_pos] = and_div; 
        } 
        
        sc = new SearchClause(this, and_pos, or_pos);
        this.searchclauses[and_pos][or_pos] = sc;
        
        if (this.widget) {
            this.and_divs[and_pos].append(sc.widget);
        } 
    }
    
    /** add SC relative to an existing one */    
    this.removeSearchClause = function(source_clause) {
    
        and_pos = source_clause.and_pos;
        or_pos = source_clause.or_pos;
            
        // don't remove the first SC            
        if (!(and_pos==0 && or_pos==0)) {            
            this.searchclauses[and_pos][or_pos] = null;
            source_clause.widget.remove();
         }
    }
}


/** constructor for a SearchClause object */
function SearchClause(query_object, and_pos, or_pos) {
      this.and_pos = and_pos;
      this.or_pos = or_pos;
      this.query_object = query_object;
      this.index = ""
      this.relation = "";
      this.value = "";

    //make cql_config static to make it accessible from getValues()
    //cql_config = query_object.cql_config;

    /** generate a widget for this SC */
      this.genCQLSearchClauseWidget = function () {
        
         //console.log("genCQLSearchClauseWidget(query_object)");
         //console.log(this.query_object);
         
        var key= query_object.key; 
        var input_index = $("<input />");
            input_index.attr("id","cql-" + key + "-index");
            input_index.attr("name","cql-" + key + "-index")
            input_index.data("sc", this);            
            // update the value in data-object;
            input_index.change(function(){ $(this).data("sc").index = $(this).val();  
                //console.log($(this).data("sc").index + '-' + $(this).val()); 
                });
            
        var select_relation = $("<select class=' rel_input'><option value='='>=</option><option value='>'>></option><option value='<'><</option><option value='any'>any</option><option value='contains'>contains</option><option value='all'>all</option></select>");
        var input_value = $("<input />");
            input_value.attr("id","cql-" + key + "-value");
            input_value.attr("name","cql-" + key + "-value");
    
           input_value.data("sc", this);            
            // update the value in data-object;
           input_value.change(function(){ $(this).data("sc").value = $(this).val(); });
            

        var new_widget = $("<div id='widget-" + key + "' class='widget-cql'></div>");
            new_widget.append(input_index)
                      .append(select_relation)
                      .append(input_value);
    
    // setup autocompletes 
        if (this.query_object.cql_config) {
            
            // let the autocomplete-select refresh upon loaded index
            this.query_object.cql_config.onLoaded = function(index) {     input_value.autocomplete( "search");
                   console.log("onloaded-index:" + index)};
          
            var indexes =  this.query_object.cql_config.getIndexes();
          //  console.log(indexes);
            
            // setting source on init did not work ??
             //input_index.autocomplete({source: indexes});
             input_index.autocomplete();
             input_index.autocomplete( "option", "source", indexes );
        //      console.log(input_index.autocomplete( "option", "source" ));
        
             input_value.data("input_index", input_index);
             input_value.autocomplete();
             input_value.autocomplete( "option", "source", getValues );
        }
        
       new_widget.append(this.genControls()); 
       return new_widget;
    };


    getValues = function(request, response) {
            
            console.log("request_term:" + request.term);
            //console.log(this.element.data("sc"));
            var sc = this.element.data("sc")
            values = sc.query_object.cql_config.getValues(sc.index,request.term);
            //console.log(values);
            if (values.status == 'loading') { response( ["loading..."]) }
                else  { response(values) };
    };
    

    this.genControls = function () {
    
        var div_controls = $("<span class='controls' />");
        var cmd_del = $("<span class='cmd cmd_sc_delete' />");
        var cmd_and = $("<span class='cmd cmd_add_and' />");
        var cmd_or = $("<span class='cmd cmd_add_or' />");
        
        div_controls.append(cmd_del).append(cmd_and).append(cmd_or);
        
        var me = this;
        cmd_del.bind("click", function(event) { me.query_object.removeSearchClause(me);  });
        cmd_and.bind("click", function(event) { me.query_object.addSearchClause(me,"and"); });
        cmd_or.bind("click", function(event) { me.query_object.addSearchClause(me,"or"); });
                      
      return div_controls;
    
	}


this.widget = this.genCQLSearchClauseWidget();


} // end SearchClause

