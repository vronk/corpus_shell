describe("panel tests:", function() {
    beforeEach(function(){
        
    });
    
    afterEach(function(){});
    
    describe("Prerequisites:", function() {
//        xit("should not run ;-)", function() {
//           expect(true).toBeFalsy(); 
//        });
        it("should have access to its URI dependency", function() {
            expect(URI).toBeDefined();
        });
        it("should have access to its VirtualKeyboard dependency", function() {
            expect(VirtualKeyboard).toBeDefined();
        });
        describe("Virtual Keyboard needs to be working:", function () {
            it("should have access to the jquery.selection dependency", function () {
                expect($.fn.selection).toBeDefined();
            });
            it("should fetch the virtual keyboard template", function () {
                expect(VirtualKeyboard.failed).toBeFalsy();
            });
        });
        it("should have access to its param dependency", function() {
            expect(params).toBeDefined();
        });
        it("should have access to its PanelController dependency", function() {
            expect(PanelController).toBeDefined();
        });
        describe("PanelController dependencies:", function() {
            it("should have access to its SearchConfig dependency", function () {
                expect(SearchConfig).toBeDefined();
            });            
        });
        it("should have access to its ResourceController dependency", function() {
            expect(ResourceController).toBeDefined();
        });
        describe("Check that the prototypes are as expected:", function () {
            it("should have a valid panel prototype", function () {
                expect(Panel.panelProto).toExist();
//                expect(Panel.virtualKeyboardProto.length).toEqual(1);
                //Tests for the effective class which is undefined for the prototype (FF, IE) (element not in use/XML not HTML):
                //expect(VirtualKeyboard.virtualKeyboardProto).toHaveClass('class', 'virtual-keyboard');
//                expect(Panel.virtualKeyboardProto).toHaveAttr('class', 'virtual-keyboard');
//                expect(Panel.virtualKeyboardProto).not.toHaveAttr('id');
            });
            it("should have a valid search UI prototype", function () {
                expect(Panel.searchUIProto).toExist();
            });
        });
    });
    
    xdescribe("Getting data:", function() {
        beforeEach(function(done) {
            jasmine.addMatchers(SpecHelper.matchers);
            SpecHelper.setUpFakeXHR();
// fails to cleanly uninstall.
//        jasmine.Ajax.withMock(function() {
            VirtualKeyboard.fetchKeys("http://localhost/corpus_shell/modules/fcs-aggregator/switch.php?version=1.2&operation=explain&x-context=arz_eng_006&x-format=json&x-dataview=metadata",
                    function() {
                        VirtualKeyboard.fetchKeys("http://localhost/corpus_shell/modules/fcs-aggregator/switch.php?version=1.2&operation=explain&x-context=mecmua&x-format=json&x-dataview=metadata",
                                function() {
                                    SpecHelper.restoreRealXHR();
                                    done();
                                });
                    });
//        });
        });
        it("should have some keys in the TEI header fetched", function() {
            var i = 0;
            for (i in VirtualKeyboard.keys) {
                expect(VirtualKeyboard.keys[i].length).toBeGreaterThan(0);
                for (var j in VirtualKeyboard.keys[i])
                    expect(VirtualKeyboard.keys[i][j]).toBeTypeOf('String');
            }
            // check there was any iteration!
            expect(i).not.toEqual(0);
// Get the JSON for the outermost beforeEach with this.
//            console.log(JSON.stringify(VirtualKeyboard.keys));
        });
    });

    simpleFixtureSetup = function() {
        loadFixtures("snaptarget.html");
    };

    randomizeFirstInputId = function() {
        var randomId = SpecHelper.generateUUID();
        $(".virtual-keyboard-input#sth-unique").attr('id', randomId);
        return $(".virtual-keyboard-input#"+randomId);
    };

    addAnotherTestInput = function() {
        appendLoadFixtures("virtual-keyboard-input.html");
        var randomId = SpecHelper.generateUUID();
        $(".virtual-keyboard-input#sth-unique").attr('id', randomId);
        return $(".virtual-keyboard-input#"+randomId);
    };

    xdescribe("Attaching to inputs of class .virtual-keyboard-input:", function() {
        beforeEach(simpleFixtureSetup);
        describe("one input:", function() {
            it("should add a keyboard to inputs of class virtual keyboard input", function() {
                expect($(".virtual-keyboard-input")).toBeInDOM();
                expect($(".virtual-keyboard-input")).toHaveData('context', 'arz_eng_006');
                expect($(".virtual-keyboard-input")).toHaveId('sth-unique');
                var randomId = SpecHelper.generateUUID();
                $(".virtual-keyboard-input").attr('id', randomId);
                VirtualKeyboard.attachKeyboards();
                expect($(".virtual-keyboard")).toBeInDOM();
                expect($(".virtual-keyboard")).toHaveData('linked_input', randomId)
            });
            it("should not add keyboards to inputs that don't provide context data", function() {
                $(".virtual-keyboard-input#sth-unique").data('context', '');
                VirtualKeyboard.attachKeyboards();
                expect($(".virtual-keyboard")).not.toExist();
            });
            it("should not add keyboards to inputs that provide unknown context data", function() {
                $(".virtual-keyboard-input#sth-unique").data('context', 'fasel');
                VirtualKeyboard.attachKeyboards();
                expect($(".virtual-keyboard")).not.toExist();
            });
            it("should add keyboards to inputs that don't provide context data if a default is given", function() {
                $(".virtual-keyboard-input#sth-unique").data('context', '');
                VirtualKeyboard.attachKeyboards('arz_eng_006');
                expect($(".virtual-keyboard")).toExist();
            });
            it("should add those keys to the template", function() {
                VirtualKeyboard.attachKeyboards();
                // Currently may fail because of unsupported CORS for JSON on IE up to 9. Keyboard unuseabel (no keys)
                expect($(".virtual-keyboard *").length).toEqual(VirtualKeyboard.keys["arz_eng_006"].length);
                $(".virtual-keyboard *").each(function(i, element) {
                    expect($(element).text()).toEqual(VirtualKeyboard.keys["arz_eng_006"][i]);
                });
            });
            it("should change the keyboard if the context changes", function() {
                VirtualKeyboard.attachKeyboards();
                expect($('.virtual-keyboard')).toExist();
                $('#sth-unique').data('context', '');
                VirtualKeyboard.attachKeyboards();
                expect($('.virtual-keyboard')).not.toExist();
            });
        });

        describe("many inputs", function() {
            beforeEach(function(){
                this.firstInput = randomizeFirstInputId();
            });
            it("should work with any number of inputs on the same page", function() {
                for (var i = 0; i < 9; i++) {
                    addAnotherTestInput();
                }
                VirtualKeyboard.attachKeyboards();
                expect($(".virtual-keyboard").length).toEqual(10);
                $(".virtual-keyboard").each(function(unused, element) {
                    var element = $(element);
                    expect(element).toHaveData('linked_input');
                    expect($("#" + element.data('linked_input'))).toBeInDOM();
                });
            });
            it("should be able to only attach keyboards to new inputs", function() {
                VirtualKeyboard.attachKeyboards();
                for (var i = 0; i < 3; i++) {
                    addAnotherTestInput();
                    VirtualKeyboard.attachKeyboards();
                }
                expect($(".virtual-keyboard").length).toEqual(4);
                $(".virtual-keyboard-input").each(function(unused, element) {
                    var id = $(element).attr("id");
                    expect($(".virtual-keyboard-input#" + id + "+.virtual-keyboard")).toHaveData('linked_input', id);
                });
            });
            it("should attach the keyboard according to the context context attribute", function(){
                for (var i = 0; i < 3; i++) {
                    var currentInput = addAnotherTestInput();
                    // data() only pulls the data-* attribute on first access, never changes it.
                    currentInput.attr('data-context', 'mecmua');
                }
                expect($('.virtual-keyboard-input[data-context="mecmua"]')).toBeInDOM();
                expect($('.virtual-keyboard-input[data-context="arz_eng_006"]')).toBeInDOM();
                VirtualKeyboard.attachKeyboards();
                expect($('.virtual-keyboard[data-context="mecmua"]')).toBeInDOM();
                expect($('.virtual-keyboard[data-context="arz_eng_006"]')).toBeInDOM();            });
        });
    });

    xdescribe("Manipulating inputs:", function() {
        beforeEach(simpleFixtureSetup);
        describe("many inputs", function() {
            beforeEach(randomizeFirstInputId);
            it("should insert a character into the text control it's attached to", function() {
                for (var i = 0; i < 2; i++) {
                    addAnotherTestInput();
                    VirtualKeyboard.attachKeyboards();
                }
                $(".virtual-keyboard").each(function(unused, element) {
                    var linked_input = $('#' + $(element).data('linked_input'));
                    $(element).children().each(function(unused, element) {
                        var text_before = linked_input.val();
                        $(element).trigger("click");
                        var text_after = linked_input.val();
                        expect(text_after.length > text_before.length).toBeTruthy();
                        expect(linked_input.val()).toEqual(text_before + $(element).text());
                    });
                });
            });
        });
        describe("one input", function() {
            describe("insertion tests", function() {
                beforeEach(function() {
                    this.testVal = 'test';
                    this.insertPoint = Math.round(this.testVal.length / 2);
                    this.testStart = this.testVal.slice(0, this.insertPoint);
                    this.testEnd = this.testVal.slice(this.insertPoint);
                    VirtualKeyboard.attachKeyboards();
                    $('#sth-unique').val(this.testVal);
                });
                it("should insert the character at the current position", function() {
                    // caret is not at the end in FF or IE!
                    // for e.g. chrome:
                    if (navigator.userAgent.indexOf("Chrome") > 0) {
                        expect($('#sth-unique').selection('getPos').start).toEqual(this.testVal.length);
                        expect($('#sth-unique').selection('getPos').end).toEqual(this.testVal.length);
                    } else {
                    // for FF, IE, ??
                        expect($('#sth-unique').selection('getPos').start).toEqual(0);                        
                        expect($('#sth-unique').selection('getPos').end).toEqual(0);
                    }
                    $('#sth-unique').selection('setPos', {start: this.insertPoint, end: this.insertPoint});
                    var keyboard = $('#sth-unique + .virtual-keyboard');
                    var testData = this;
                    $(keyboard).children().each(function(unused, element) {
                        var key = $(element);
                        key.trigger("click");
                        testData.testStart += key.text();
                    });
                    this.testVal = this.testStart + this.testEnd;
                    expect($('#sth-unique').val()).toEqual(this.testVal);
                });
                it("should replace the selection with the clicked character", function() {
                    $('#sth-unique').selection('setPos', {start: this.insertPoint - 1, end: this.insertPoint + 1});
                    var keyboard = $('#sth-unique + .virtual-keyboard');
                    this.testStart = this.testStart.slice(0, -1);
                    var testData = this;
                    $(keyboard).children().each(function(unused, element) {
                        var key = $(element);
                        key.trigger("click");
                        testData.testStart += key.text();
                    });
                    this.testVal = this.testStart + this.testEnd.slice(1);
                    expect($('#sth-unique').val()).toEqual(this.testVal);
                });
            });
        });
    });
//    xdescribe("End (deacitvated)", function() {
//        xit("the end", function(){});
//    });
});

