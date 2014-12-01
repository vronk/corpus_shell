!function($, jasmine, URI, ResourceController) {
    jasmine.getFixtures().fixturesPath = 'spec/fixtures';
    var module = {};
    module.matchers = {
        toBeTypeOf: function(util, customEqualityTesters) {
            return {
                compare: function(actual, expected) {
                    if (expected === undefined) {
                        expected = 'object';
                    }                    
                    var result = {};
                    result.pass = false;
	            var objType = actual ? Object.prototype.toString.call(actual) : '';
                    result.pass = objType.toLowerCase() === '[object ' + expected.toLowerCase() + ']';
                    var notText = result.pass ? ' not' : '';
                    result.message = 'Expected ' + actual + notText + ' to be [object ' + expected + ']';
                    return result;
                }
            };
        }
    };
    
    module.generateUUID = function(){
    var d = new Date().getTime();
    var uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
        var r = (d + Math.random()*16)%16 | 0;
        d = Math.floor(d/16);
        return (c==='x' ? r : (r&0x7|0x8)).toString(16);
    });
    return uuid;
    };
    
    module.fakeResponses = {}; //map
    
//    $.ajax('spec/fixtures/mecmua.json', {
//            async: false,
//            dataType: 'json',
//            success: function(unused, unused2, jqXHR) {
//                module.fakeResponses['mecmua'] = jqXHR.responseText;
//            }
//        });        
    
    var fakeXHR;
    
    module.setUpFakeXHR = function() {
        if (jasmine.Ajax !== undefined) {
            jasmine.Ajax.install();
            jasmine.Ajax.stubRequest('http://localhost/corpus_shell/modules/fcs-aggregator/switch.php?version=1.2&operation=explain&x-context=arz_eng_006&x-format=json&x-dataview=metadata')
                    .andReturn({
                        "status": 200,
                        "contentType": 'text/json',
                        "responseText": module.fakeResponses['arz_eng_006']
                    });
            jasmine.Ajax.stubRequest('http://localhost/corpus_shell/modules/fcs-aggregator/switch.php?version=1.2&operation=explain&x-context=mecmua&x-format=json&x-dataview=metadata')
                    .andReturn({
                        "status": 200,
                        "contentType": 'text/json',
                        "responseText": module.fakeResponses['mecmua']
                    });
        }
        if (window.sinon !== undefined) {
            fakeXHR = sinon.useFakeXMLHttpRequest();
            fakeXHR.onCreate = function(xhr) {
                // need to give control back so the request can be actually made
                setTimeout(function() {
                    var uri = URI(xhr.url);
                    uri.normalize();
                    var query = URI.parseQuery(uri.query());
                    uri.query('');
                    if (uri.href() === 'http://localhost/corpus_shell/modules/fcs-aggregator/switch.php') {
                        if (module.fakeResponses.hasOwnProperty(query['x-context'])) {
                                xhr.respond(200,
                                        {"Content-Type": "application/json"},
                                module.fakeResponses[query['x-context']]);
                                return;
                            }
                    }
                xhr.respond(404,
                               { "Content-Type": "application/json" },
                               uri.toString() + ' not found!');
                }, 100);
            };
        }
        // else do not fake
    };
    
    module.restoreRealXHR  = function() {
        if (jasmine.Ajax !== undefined) {
            jasmine.Ajax.uninstall;
        }
        if (window.sinon !== undefined) {
            fakeXHR.restore();
        }
    };
    
    module.loadIndexCache = function (onComplete, onError) {
        ResourceController.ClearResources();

        for (var i = 0; i < SearchConfig.length; i++) {
            var resName = SearchConfig[i]["x-context"];
            ResourceController.AddResource(resName, SearchConfig[i]["DisplayText"]);
        }

        $.ajax({
            dataType: "json",
            url: 'spec/fixtures/indexCache.json',
            async: false,
            success: function (data) {
                $.each(data, function (key, val) {
                    for (var index in val) {
                        var item = val[index];
                        ResourceController.AddIndex(key, item.idxName, item.idxTitle, item.searchable, item.scanable, item.sortable, item.native);
                    }
                });
            },
            complete: function (jqXHR, textStatus) {
                if (onComplete !== undefined && typeof (onComplete) === 'function')
                    onComplete(jqXHR, textStatus);
            },
            error: function (jqXHR, textStatus) {
                if (onError !== undefined && typeof (onError) === 'function')
                    onError(jqXHR, textStatus, textThrown);
            }
        });
    };
        
    //publish
    this.SpecHelper = module;
}(window.jQuery, jasmine, URI, ResourceController);