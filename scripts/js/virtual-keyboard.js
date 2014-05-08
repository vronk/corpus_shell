!function($, params, URI, jquery_selection) {
    var module = {};
    module.virtualKeyboardProto;
    module.failed = false;
    module.keys = {}; // map
    
    if (jquery_selection === undefined || URI === undefined) {
        module.failed = true;
    } else {
        $.ajax(params.templateLocation + "virtual-keyboard.tpl.html", {
            async: false,
            dataType: 'html',
            error: function() {
                module.failed = true;
            },
            success: function(unused, unused2, jqXHR) {
                module.virtualKeyboardProto = $(jqXHR.responseText).find('#template');
                module.failed = (module.virtualKeyboardProto.length === undefined ||
                        module.virtualKeyboardProto.length !== 1);
                module.virtualKeyboardProto.find('.remove-for-production').remove();
                module.virtualKeyboardProto.removeAttr('id');
            }
        });
    }
    
    /**
     * Asynchroinously fetches an explain object to derive the keys for the context
     * encoded in the uri given.
     * 
     * @param {uri} url A uri where a JSON object can be found that conforms to our explain objects interface.
     * @param {type} whenDone A function to be called when the request finishes.
     * @returns {undefined}
     */
    module.fetchKeys = function (url, whenDone) {
        if (module.failed) return;
        $.ajax(url, {
            dataType: 'json',
            error: function() {
                module.keys = {};
            },
            success: function(unused, unused2, jqXHR) {
                //does not work in jQuery 1.8.3, there was no reponseJSON
                //var explain = jqXHR.responseJSON;
                var explain = $.parseJSON(jqXHR.responseText);
                if (explain.explain !== 'explain' ||
                    explain.description === undefined ||
                    explain.description.encoding === undefined ||
                    explain.description.encoding.chars === undefined)
                    return;
                var query = URI.parseQuery(URI(url).query());
                var keys = [];
                for (var i in explain.description.encoding.chars) {
                    keys.push(explain.description.encoding.chars[i]['Unicode']);
                }
                module.keys[query["x-context"]] = keys;
            },
            complete: function() {
                whenDone();
            }
        });
    };
    
    keyClicked = function(event) {
        var key = $(event.currentTarget);
        var container = key.parent();
        var input = $('#' + container.data('linked_input'));
        // corner case input empty (weird selection semantics (!?)
        if (input.val() === '') {
            var text = key.text();
            input.val(text);
            //FF and IE _do not_ position the caret at the end of the text set!
            input.selection('setPos', {start: text.length, end: text.length});
        } else {
            input.selection('replace', {text: key.text(), caret: 'end'});
        }
    };
    
    /**
     * 
     * @param {string} context a default context used if no data-context is present.
     * @returns {undefined}
     */
    module.attachKeyboards = function(defaultContext) {
        if (module.failed) return;
        var inputs = $(".virtual-keyboard-input");
        var defaultContext = defaultContext;
        inputs.each(function(unused, element) {
            var myInput = $(element);
            //sanity checks
            var localContext = myInput.data("context");
            if ((localContext === undefined || localContext === '') && defaultContext !== undefined) {
                localContext = defaultContext;
                myInput.data('context', defaultContext);
            }
            var existingKeyboard = $(".virtual-keyboard-input#"+myInput.attr('id')+"+.virtual-keyboard");
            if (existingKeyboard.size() > 0) {
                if (existingKeyboard.data('context') !== localContext)
                    existingKeyboard.remove();
                else
                    return;
            }
            if (localContext === undefined || module.keys[localContext] === undefined)
                return;
            //create keyboard
            var virtualKeyboard = module.virtualKeyboardProto.clone();
            // data() stores in javascript not in DOM
            virtualKeyboard.attr('data-context', localContext);
            var virtualKeyboardKeyProto = virtualKeyboard.find(".key-prototype");
            virtualKeyboardKeyProto.removeClass("key-prototype");
            virtualKeyboardKeyProto.on("click", keyClicked);
            virtualKeyboard.insertAfter(myInput);
            for (var i in module.keys[localContext]) {
                var key = virtualKeyboardKeyProto.clone(true);
                key.text(module.keys[localContext][i]);
                virtualKeyboard.append(key);
            }
            virtualKeyboardKeyProto.remove();
            virtualKeyboard.data('linked_input', myInput.attr('id'));
        });
    };
    
    // publish
    this.VirtualKeyboard = module;
}(window.jQuery, params, URI, window.jQuery.fn.selection);