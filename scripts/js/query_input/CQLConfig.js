
/**
 * @class CQLConfig
 * "business" class, fetching and holding the information about available indexes and their values in SRU/CQL
 * based on exactly one explain! 
 * options: multiple params/fields, 
 * indexes, different widgets
 *
 * dependencies: jQuery
 
 * @author vronk
 * @version 2013-04-11
 *
 * @param options explain_url, context_identifier
*/

function CQLConfig(options) {
    var defaults = {"base_url": "fcs",  /* the _url will get this as first replace-pattern */
                    "explain_url": "%s?operation=explain&x-format=json",
                    "scan_base_url": "%s?x-context=&x-format=json&operation=scan&scanClause=%s&sort=size&maximumTerms=%d", /* call without pattern restriction (for initial call) */
                    "scan_pattern_url": "%s?x-context=&x-format=json&operation=scan&scanClause=%s=%s", /* placeholders will be replaced with index and (optional) pattern */
                   "x_context": "",
                   "values_limit": 200,
                   "onLoaded": function(index) { console.log("loaded index: " + index) }
                  };
   
       /** main variable holding all the settings for qi, especially also all params and their allowed values, and their current value
      * it is constructed here by merging the default and the user options passed as parameter to .QueryInput()
      */
   var settings = $.extend(true, {}, defaults, options);

    this.settings = settings;
    this.onLoaded = this.settings.onLoaded;
    this.loaded = 0; 
    
    this.context = "";
    this.explain = {};
    /** stores the list of indexes (this.explain.indexes) as an array */
    this.indexes = [];
    /** stores the values from scan for individual indexes */
    this.values = {};
    
    
    this.init = function() {
        // console.log("cqlconfig.init");
        if (!this.settings.hasOwnProperty("explain_url")) {
            this.loaded = -1;
            return null;
        } else {
            var me = this;
            var explain_url = sprintf(this.settings.explain_url,this.settings.base_url).replace(/&amp;/g,'&');
            $.getJSON(explain_url, function(data) {
                    // console.log(data);
                    me.explain = data;
                    
                    if (me.explain.hasOwnProperty("indexes")) {
                        for (ix in me.explain.indexes) {
           //                 console.log(ix);
                            me.indexes.push(ix);
                        }
                    }
                    me.loaded=1;
                    me.onLoaded.call(me, "explain");
              });
        }
      };
     
     /** return context sets */
    this.getContextsets = function () {
        if (this.explain.hasOwnProperty("context_sets")) {       
            return this.explain.context_sets;
         } else {
            return null;
         }
    }
    
    this.getIndexes = function () {
        if (this.indexes == []) {
            return ["loading..."];
        } else {
            return this.indexes; 
        }
    };

    /*: read (and cache) the scan on demand
        TODO: how to handle large indexes? 
    */
    this.getValues = function (index, pattern) {
    
        if (this.values[index]) {
           
           if (this.values[index].hasOwnProperty("terms")) {
                // if full index loaded just work with that
              if (this.values[index].indexSize == this.values[index].countReturned) {
                    return  filter(this.values[index].terms,pattern);
              } 
           }
           // if index but not terms i.e. => loading  - go load pattern
           // but as it is obviously a big index (because still loading), only go for next call with at least two characters   
           if (!this.values[index][pattern] && pattern.length >= 2 )
             { 
             // else try to get a subset with pattern
               var scan_url = sprintf(this.settings.scan_pattern_url,this.settings.base_url,index,pattern).replace(/&amp;/g,'&');
                console.log("scan_pattern_url:" + scan_url);
                this.values[index][pattern] = {"status":"loading"};
                   var me = this;
                 $.getJSON(scan_url, function(data) {
                         // console.log(data);
                         me.values[index][pattern] = data;
                         
                         me.onLoaded.call(me, index);
                   });
             }
             
             // return filtered result if available
           if (this.values[index][pattern].hasOwnProperty("terms")) {
                   return  this.values[index][pattern].terms;
              } else { 
                    return this.values[index][pattern]; 
              }
             
             
        } else {
          // only start loading if not called until now
          this.values[index] = {"status":"loading"};
          var me = this;
          var scan_url = sprintf(this.settings.scan_base_url,this.settings.base_url,index,this.settings.values_limit).replace(/&amp;/g,'&');
           console.log("scan_base_url:" + scan_url);
            $.getJSON(scan_url, function(data) {
                    console.log("DATA LOADED");
                    me.values[index] = data;
                    me.onLoaded.call(me, index);
              });
              // return status:loading
          return {"status":"loading"};
        } 
       
    };

    function filter(array, term) {
    //var matcher = new RegExp("^" + $.ui.autocomplete.escapeRegex(term), "i");
    // console.log(array);
    var matcher = new RegExp("^" + term, "i");
    return $.grep(array, function (value) {
        return matcher.test(value.label || value.value || value);
    });
};


   this.init();
    
    
};