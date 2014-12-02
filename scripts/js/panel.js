/**
 * @fileOverview Provides the Panel class. Main entry points here are {@link module:corpus_shell~Panel#CreatePanel}.
 * @author      Andy Basch,
 * last change:  2012.10.02
 */

/**
 * @module corpus_shell
 */

/**
 * @typedef {Object} Position
 * @property {number} Left
 * @property {number} Top
 * @property {number} Width
 * @property {number} Height
 */

// Everything here assumes $ === jQuery so ensure this
!function ($, params, PanelController, ResourceController, VirtualKeyboard, document) {
// fetchKeys? wait? when? where?
    VirtualKeyboard.keys = {
        "arz_eng_006": ["ʔ", "ā", "ḅ", "ʕ", "ḍ", "ḏ", "ē", "ġ", "ǧ", "ḥ", "ī", "ᴵ", "ḷ", "ṃ", "ō", "ṛ", "ṣ", "š", "ṭ", "ṯ", "ū", "ẓ", "ž"],
        "apc_eng_002": ["ʔ", "ā", "ḅ", "ʕ", "ḍ", "ḏ", "ē", "ǝ", "ᵊ", "ġ", "ǧ", "ḥ", "ī", "ᴵ", "ḷ", "ṃ", "ō", "ṛ", "ṣ", "š", "ṭ", "ṯ", "ū", "ẓ", "ž"],
        "aeb_eng_001__v001":["ʔ", "ā", "ḅ", "ʕ", "ḏ̣", "ḏ", "ē", "ġ", "ǧ", "ḥ", "ī", "ᴵ", "ḷ", "ṃ", "ō", "ṛ", "ṣ", "š", "ṭ", "ṯ", "ū", "ẓ", "ž"], 
        "mecmua": ["ʾ", "ʿ", "ā", "č", "ç", "ė", "ḍ", "ḏ", "ġ", "ḥ", "ḫ", "ī", "ı", "ñ", "s̱", "ş", "ṣ", "š", "ṭ", "ū", "ü", "ẕ", "ż", "ẓ"]
    };
    VirtualKeyboard.keys['tunico_conc'] = VirtualKeyboard.keys['aeb_eng_001__v001'];
    VirtualKeyboard.keys['tunico'] = VirtualKeyboard.keys['aeb_eng_001__v001'];
/**
 * Creates a panel in corpus_shell.
 * @constructor
 * @param {string} id The unique id of this panel. Is a valid JavaScript objects property name.
 * @param {string} type The type of this panel (currently known: search, image, )
 * @param {string} title The intelligable title presented to the user. 
 * @param {url} url A URL, may be an empty string.
 * @param {Position} position The initial position of the panel.
 * @param {boolean} pinned
 * @param {number} zIndex The initial "height" at which this panel shall be displayed.
 * @param {string} container A jQuery selector which selects the part of the page
 *                           the pannels appear in
 * @param {module:corpus_shell~PanelManager} panelController The object this panel belongs to.
 * @param {number} config An index in {@link module:corpus_shell~SearchConfig}.
 * @classdesc
 * purpose:      represents a panel in corpus_shell
 *
 * @requires     corpus_shell~PanelManager
 * @requires     corpus_shell~PanelController
 * @requires     jQuery
 */
var module = function (id, type, title, url, position, pinned, zIndex, container, panelController, config)
{
  /**
  * @param url - string containing an URL
  * purpose:    parses the given url and fills an array fill with the key/value pairs
  *             of all url parameters
  * @return    array with key/value pairs of the url params
  */
  // This has to be on top as it's used below in initializing some other member variable
  this.GetUrlParams = function(url)
  {
    var urlParams = {};
    if (url !== undefined)
    {
      var match;
      var pl     = /\+/g;  //  Regex for replacing addition symbol with a space
      var search = /([^&=]+)=?([^&]*)/g;
      var decode = function (s) { return decodeURIComponent(s.replace(pl, " ")); };

      var query  = "";
      var qmPos = url.indexOf('?');
      if (qmPos !== -1)
        query = url.substr(qmPos + 1);
      else
        query = url;

      while (match = search.exec(query))
         urlParams[decode(match[1])] = decode(match[2]);
    }

    return urlParams;
  };

  /**
   * @public
   * @type {string}
   * @desc Used as an id for an HTML element. 
   */
  this.Id = id;
  /** 
   * @public
   * @type {string}
   * @desc One of search, image, content, 
   */
  this.Type = type;
  /**
   * @public
   * @type {string}
   * @desc An intelligable title for this panel.
   */
  this.Title = title;
  /**
   * @public
   * @type {url}
   * @desc A URL used for creating this panel.
   */
  this.Url = url;
  /**
   * @public
   * @type {Object}
   * @desc An Object which members correspond to the params of the URL used for creating this panel.
   */  
  this.UrlParams = this.GetUrlParams(url);
  /**
   * @public
   * @type {Position}
   * @desc Position of the panel.
   */
  this.Position = position;
  /**
   * @public
   * @type {boolean}
   * @desc If the panel is pinned or not. 
   */
  this.Pinned = pinned;
  /** 
   * @public
   * @type {number}
   * @desc At which "height" in the stack of panels is this panel.
   */
  this.ZIndex = zIndex;
  /**
   * @public
   * @type {string}
   * @desc A jQuery selector string which identifies the place where the panels are drawn. 
   */
  this.Container = container;
  /**
   * The {@link module:corpus_shell~PanelManager} object this panel belongs to.
   * @public 
   */
  this.PanelController = PanelController;
  /**
   * @public
   * @type {number}
   * @desc The index in {@link module:corpus_shell~SearchConfig} for the config to use in search operations.
   */
  this.Config = config;
  if (panelController !== undefined && config === undefined && this.Type !== "search") {
      this.Config = panelController.GetSearchIdx(this.UrlParams['x-context']);
  }
  /**
   * @public
   * @type {number}
   * @desc The default start record when the returned record set is displayed. 
   */
  this.DefaultStartRecord = 1;
  
  /**
   * @public
   * @type {number}
   * @desc The default maximum number of record when the returned record set is displayed. 
   */
  this.DefaultMaxRecords = 10;

  /* methods */

  /**
   * @param {string} [searchstr] A search string for a new search panel if one is actually created.
   * @desc purpose: switch to create the actual DOM-object and to append it to {@link module:corpus_shell~Panel#Container}
   *            depending on the value of {@link module:corpus_shell~Panel#Type} being search either {@link module:corpus_shell~Panel#CreateNewSearchPanel}
   *            or {@link module:corpus_shell~Panel#CreateNewSubPanel} is called
   * @return    -
   */
  this.CreatePanel = function(searchstr)
  {
    if (this.Type === "search")
      this.CreateNewSearchPanel(this.Config, searchstr);
    else
      this.CreateNewSubPanel();
  };

  /**
  * @param url - string containing an URL
  * purpose:    sets the property this.Url and additionally sets the url in
  *             this.PanelController
  * @return    -
  */
  this.SetUrl = function(url)
  {
    this.Url = encodeURI(url);
    this.UrlParams = this.GetUrlParams(url);
    this.PanelController.SetPanelUrl(this.Id, url);
    var thisPanel = $(this.GetCssId());
    thisPanel.find("a.c_s_fcs_xml_link").attr("href", url.replace("x-format=html", "x-format=xml").replace("x-format=json", "x-format=xml"));
    if (this.UrlParams['operation'] === 'searchRetrieve')
        thisPanel.find("a.c_s_tei_xml_link").removeClass("c_s-hidden").attr("href", this.Url.replace("x-format=html", "x-format=xmltei"));
  };

  /**
  * @param -
  * purpose:    closes the panel - ie remove it completelly from the DOM-tree
  * @return    -
  */
  this.Close = function()
  {
    $(this.GetCssId()).remove();
  };

  // postion handling

  /**
  * @param -
  * purpose:    gets the current position and size of the panel DOM object and sets
  *             the property this.Position
  * @return    -
  */
  this.UpdatePosition = function()
  {
    var newPosition = this.GetPanelPosition();
    this.Position = newPosition;
  }

  /**
  * @param position - object that contains values for top and left position as
  *             well as width and height
  * purpose:    set postion and size of panel div, sets this.Position property, too
  * @return    -
  */
  this.SetPosition = function(position)
  {
    this.Position = position;

    if (this.Position)
    {
      $(this.GetCssId()).css("left", this.Position.Left);
      $(this.GetCssId()).css("top", this.Position.Top);
      $(this.GetCssId()).css("width", this.Position.Width);
      $(this.GetCssId()).css("height", this.Position.Height);
    }
  }

  /**
  * @param -
  * purpose:    gets the current position and size of the panel DOM object
  * @return    postion object containing the values for left, top, width, and height
  */
  this.GetPanelPosition = function()
  {
    var position = new Object();
    position["Left"] = $(this.GetCssId()).css("left");
    position["Top"] = $(this.GetCssId()).css("top");
    position["Width"] = $(this.GetCssId()).css("width");
    position["Height"] = $(this.GetCssId()).css("height");

    return position;
  }

  /**
  * @param zIdx - Z-Index value
  * purpose:    sets the Z-Index of the panel DOM object and the this.ZIndex property
  * @return    -
  */
  this.SetZIndex = function(zIdx)
  {
    this.ZIndex = zIdx;

    $(this.GetCssId()).css("z-index", zIdx);
  }

  /**
  * @param position - object that contains values for top and left position as
  *             well as width and height
  *             zIdx - Z-Index value
  * purpose:    sets all position/dimension values of the panel, used to return panel
  *             from maximized to normal mode (= dimension and position prior to
  *             maximization), changes the title bar icon and link to allow for the
  *             panel to be maximized again.
  * @return    -
  */
  this.Normalize = function(position, zIdx)
  {
    this.SetPosition(position);
    this.SetZIndex(zIdx);

    this.CorrectSearchResultHeight();
    
    var iconMax = $(this.GetCssId()).find(".titletopiconmax");
    var iconNorm = $(this.GetCssId()).find(".titletopiconnorm");
    
    if (iconNorm.length === 0) {
        iconMax.attr("src", "scripts/style/img/n.win_max.png");
        iconMax.parent().attr("onclick", "PanelController.MaximizePanel('" + this.Id + "');");
    } else {
        iconNorm.addClass("c_s-hidden");
        iconMax.removeClass("c_s-hidden");       
    }
  }

  /**
  * @param position - object that contains values for top and left position as
  *             well as width and height
  *             zIdx - Z-Index value
  * purpose:    sets all position/dimension values of the panel, used to maximize the
  *             panel, changes the title bar icon and link
  * @return    -
  */
  this.Maximize = function(position, zIdx)
  {
    this.SetPosition(position);
    this.SetZIndex(zIdx);

    this.CorrectSearchResultHeight();

    var iconMax = $(this.GetCssId()).find(".titletopiconmax");
    var iconNorm = $(this.GetCssId()).find(".titletopiconnorm");
    
    if (iconNorm.length === 0) {
        iconMax.attr("src", "scripts/style/img/n.win_norm.png");
        iconMax.parent().attr("onclick", "PanelController.NormalizePanel('" + this.Id + "');");
    } else {
        iconMax.addClass("c_s-hidden");
        iconNorm.removeClass("c_s-hidden");
    }
  };

  /**
  * @param pinnedState - a value of 1 means that the panel is pinned
  * purpose:    sets the property this.Pinned and changes the icon in the panel title bar
  * @return    -
  */
  this.Pin = function(pinnedState)
  {
    var paneldiv = this.GetCssId();

    if (pinnedState == 1)
    {
      this.Pinned = true;
      $(paneldiv).find(".titletopiconpin:not(.c_s-grayed)").removeClass("c_s-hidden");
      $(paneldiv).find(".titletopiconpin.c_s-grayed").addClass("c_s-hidden");
    }
    else
    {
      this.Pinned = false;
      $(paneldiv).find(".titletopiconpin:not(.c_s-grayed)").addClass("c_s-hidden");
      $(paneldiv).find(".titletopiconpin.c_s-grayed").removeClass("c_s-hidden");      
    }
  }

  var titleBarPlusBottomSpacing = 21 + 11;
  var searchUIHeight = 20 + 23 + 10;
  /**
  * @param -
  * purpose:    corrects the height of the searchresult div dependent on the panel type
  * @return    -
  */
  this.CorrectSearchResultHeight = function()
  {
    this.MozillaWorkaroundScrollAreaHeight();
    var hgt = $(this.GetCssId()).height();

    if (this.Type == "search")
      $(this.GetCssId()).find(".searchresults").height(hgt - titleBarPlusBottomSpacing - searchUIHeight);
    else
      $(this.GetCssId()).find(".searchresults").height(hgt - titleBarPlusBottomSpacing);
  };

  this.MozillaWorkaroundScrollAreaHeight = function()
  {
            var self = $(this.GetCssId());
            var scrollarea = self.find(".c_s-scroll-area");;
            if ($.browser.mozilla) {
                if (scrollarea !== undefined) {
                    scrollarea.css("position", "relative");
                    var height = self.find(".c_s-searchresults-container").height();
                    if (height !== scrollarea.height())
                        scrollarea.height(height);
                }
                this.UpdateContentView();
            }
  };
  
  /**
  * @param {number} configIdx Preselected index of SearchCombo
  * @param {string} searchStr Search string to inserted in search input
  * @desc <ol>
  * <li>Creates a new div and styles it as needed by the ui. Its id is set to the unique panel id.</li>
  * <li>Creates the "window title bar" using {@link module:corpus_shell~Panel#GeneratePanelTitle}</li>
  * <li>Builds a query to be executed if some search string is given.</li>
  * <li>Creates the ui elements for searching.<br/>
  * -> {@link module:corpus_shell~Panel#GenerateSearchInputs} <br/>
  * -> {@link module:corpus_shell~Panel#GenerateSearchNavigation}</li>
  * <li>Adds a div for search results. -> {@link module:corpus_shell~Panel#GenerateSearchResultsDiv}</li>
  * <li>Makes the panel draggable. -> {@link module:corpus_shell~Panel#InitDraggable} </li>
  * </ol>
  * @summary purpose:    creates a new search panel and displays it.
  * @return    -
  */
  this.CreateNewSearchPanel = function(unused, searchStr)
  {
    var query = "";

    if (this.Url !== undefined && this.Url !== "")
    {
      var urlObj = this.GetUrlParams(this.Url);
      var xContext = urlObj['x-context'];
      this.Config = this.PanelController.GetSearchIdx(xContext);
      query = urlObj['query'];
    }
    else
    {
      if (searchStr !== undefined)
        query = searchStr;
    }

    var searchPanel = module.panelProto.clone();
    var searchUI = module.searchUIProto.clone();
 
    this.FillInPanelTitle(searchPanel, this.Title, 0, false);
            this.searchbutton = searchUI.find(".c_s-ui-searchbutton input");
            this.searchbutton.attr("onclick", "PanelController.StartSearch('" + this.Id + "', true);");
            var startrecordInput = searchUI.find(".startrecord");
            var maxrecordInput = searchUI.find(".maxrecord");
            var loadButton = searchUI.find(".navigationmain .load");
            this.DefaultStartRecord = parseInt(startrecordInput.val(), 10);
            this.DefaultMaxRecords = parseInt(maxrecordInput.val(), 10);
            startrecordInput.keyup(function(event)
                {
                    if (event.keyCode === 13)
                        loadButton.click();
                });
            maxrecordInput.keyup(function(event)
                {
                    if (event.keyCode === 13)
                        loadButton.click();
                });
            loadButton.attr("onclick", "PanelController.StartSearch('" + this.Id + "');");
            searchUI.find(".navigationmain .prev").attr("onclick", "PanelController.StartSearchPrev('" + this.Id + "');");
            searchUI.find(".navigationmain .next").attr("onclick", "PanelController.StartSearchNext('" + this.Id + "');");
            this.ConfigureSearchTextInput(searchUI.find(".searchstring"), decodeURIComponent(query));
            this.ConfigureSearchContextCombo(searchUI.find(".searchcombo"), this.Config);
            
            searchPanel.find(".c_s-ui-widget-header").after(searchUI);
            
            this.nativequery = searchPanel.find(".c_s-native-ui");
            if (this.canUseNative()) {
                this.nativequery.css("display", "table-row");
                this.nativequery.find("input.c_s-queryType-native").attr('checked', this.UrlParams.queryType === "native");
            }

        $(searchPanel).attr("id", this.Id);
        $(searchPanel).attr("onclick", "PanelController.BringToFront('" + this.Id + "');");
        $(searchPanel).css("position", "absolute");

        $(searchPanel).css("left", this.Position.Left);
        $(searchPanel).css("top", this.Position.Top);
        $(searchPanel).css("width", this.Position.Width);
        $(searchPanel).css("height", this.Position.Height);
        $(searchPanel).css("z-index", this.ZIndex);

    $(this.Container).append(searchPanel);
    this.InitDraggable();
    VirtualKeyboard.attachKeyboards();
  };
  
  this.canUseNative = function(){
    var context = this.PanelController.GetResourceName(this.Config); 
    var availableTags = ResourceController.Resources[context];
    if (availableTags !== undefined) {
        for (var key in availableTags["Indexes"]) {
            var native = availableTags["Indexes"][key]["Native"];
            if (native === true)
                 return true;
        }
    }
    return false;
  };

  /**
  * @param -
  * purpose:    creates a new sub panel, ie. a panel without search inputs
  * @return    -
  */
  this.CreateNewSubPanel = function()
  {
    var newPanel = module.panelProto.clone();
    var usePin = 1;
    if (this.Type === "content")
        usePin = 0;    
    this.FillInPanelTitle($(newPanel), this.Title, usePin, this.Pinned);

    $(newPanel).attr("id", this.Id);
    $(newPanel).attr("onclick", "PanelController.BringToFront('" + this.Id + "');");
    $(newPanel).css("position", "absolute");

    $(newPanel).css("left", this.Position.Left);
    $(newPanel).css("top", this.Position.Top);
    $(newPanel).css("width", this.Position.Width);
    $(newPanel).css("height", this.Position.Height);
    $(newPanel).css("z-index", this.ZIndex);

    $(this.Container).append(newPanel);

    if (this.Type === "image")
      this.GetFacsimile();
    else if ((this.Type === "text") || (this.Type === "content"))
      this.GetFullText();

    this.InitDraggable();
  };

  /**
   * A method called if the content might need a refresh, e.g. the map.
   * @returns -
   */
  this.UpdateContentView = function() {
    // for th panels handled by this class there is no need to do anything.
  };
  
  /**
  * Configures the jQuery UI resiza and drag functions.
  */
  this.InitDraggable = function()
  {
    var self = this;
    var panelId = this.Id;
    var scrollarea;

    $(this.GetCssId())
                    .resizable({containment: "parent", aspectRatio: false,
                        resize: function(event, ui)
                        {
                            PanelController.BringToFront(panelId);
                            var needsCalculation = !$(this).hasClass("c_s-ui-widget");
                            if (needsCalculation) {
                                var hgt = $(this).height();
                                if ($(this).find(".searchstring").length !== 0)
                                    $(this).find(".searchresults").css("height", hgt - titleBarPlusBottomSpacing - searchUIHeight + "px");
                                else
                                    $(this).find(".searchresults").css("height", hgt - titleBarPlusBottomSpacing + "px");
                                var wid = $(this).width();
                                $(this).find(".searchresults").css("width", wid + "px");
                                PanelController.RefreshScrollPane(panelId);
                            }
                            self.UpdateContentView(event, ui);
                            /* Part of the Firefox doesn't interpret overflow together with
                             * a heigth to be calculated workaround.
                             */
                            if (scrollarea !== undefined) {
                                var height = $(this).find(".c_s-searchresults-container").height();
                                if (height !== scrollarea.height())
                                    scrollarea.height(height);
                            }
                            /* End workaround */
                            PanelController.UpdatePanelPosition(panelId);
                        },
                        /* Part of the Firefox doesn't interpret overflow together with
                         * a heigth to be calculated workaround.
                         */
                        start: function(event, ui) {
                            if ($.browser.mozilla) {
                                if (scrollarea === undefined) {
                                    scrollarea = $(this).find(".c_s-scroll-area");
                                }
                                scrollarea.css("position", "absolute");
                            }
                        },
                        /* Part of the Firefox doesn't interpret overflow together with
                         * a heigth to be calculated workaround.
                         */
                        stop: function(event, ui) {
                            self.MozillaWorkaroundScrollAreaHeight();
                        }
                    })
                    .draggable({handle: ".c_s-ui-widget-header", containment: "parent", snap: true,
                        start: function(event, ui)
                        {
                            PanelController.BringToFront(panelId);
                        },
                        stop: function(event, ui)
                        {
                            PanelController.UpdatePanelPosition(panelId);
                        }
                    });
        };

  /**
  * @param -
  * purpose:    initializes the scrollbar adjacent to the searchresult div
  * @return    -
  */
  this.InitScrollPane = function()
  {
        if (!$(this.GetCssId()).hasClass("c_s-ui-widget")) {
   var srdiv = $(this.GetCssId()).find(".searchresults");
   $(srdiv).jScrollPane({ mouseWheelSpeed: 10});
        }
  };
  
  /**
  * @param -
  * purpose:    refreshes the scrollbar adjacent to the searchresult div. If the div isn't a jScrollPane yet
  * it is initialised.
  * @return    -
  */
  this.RefreshScrollPane = function()
  {
       var api = $(this.GetCssId()).find(".searchresults").data('jsp');
       if (api != undefined)
          api.reinitialise();
       else this.InitScrollPane();
  };

  /**
  * @param -
  * purpose:    adds a # char in front of this.Id to make it easier to address the
  *             panel with jQuery
  * @return    -
  */
  this.GetCssId = function()
  {
    return '#' + this.Id;
  };
          
  /**
  * @param -
  * purpose:    loads this.Url via AJAX and places the content of the remote file
  *             inside the searchresult div; afterwards initializes/refreshes the
  *             scrollbar
  * @return    -
  */
  this.GetFullText = function()
  {
    var elem = this.GetCssId();
    var panel = this;
    if (this.initialSearchResultClasses === undefined) {
        this.initialSearchResultClasses = $(elem).find(".searchresults").attr('class');
    } else {
        $(elem).find(".searchresults").attr('class', this.initialSearchResultClasses);
    }

    $.ajax(
    {
        type: 'GET',
        url: this.Url,
        dataType: 'xml',
        complete: function(xml, textStatus)
        {
          var responseText = $(xml.responseText);

          //The "type" of resource, the x-context, is passed as a class of the
          //returned div. This div is skipped over in this kind of panel so
          //try to get the classes and then add them to the .searchresults div
          var snippetClasses;
          responseText.each(function() {
              snippetClasses = $(this).attr('class');
              if (snippetClasses !== undefined)
                 return false;
          });
          
          var responseTable = responseText.find("table.show");
          if (responseTable.length === 0)
            responseText = responseText.find(".title, .data-view, .navigation, .content");
          else
            responseText = responseTable;

          if ($(elem).find(".searchresults").data('jsp') != undefined)
          {
            $(elem).find(".searchresults").data('jsp').getContentPane().html(responseText);
            panel.RefreshScrollPane();
          }
          else
          {
            var height;
            if ($.browser !== undefined && $.browser.mozilla) {
            /* Part of a crude hack to get around missing support for overflow and
             * percentage height in table cells in firefox (only fixed px overflows
             * are used).
             */
             height = $(elem).find(".c_s-scroll-area").height();
            }
            var searchResults = $(elem).find(".searchresults");
            searchResults.attr('class', searchResults.attr('class') + ' ' + snippetClasses);
            searchResults.html(responseText);
            if ($.browser !== undefined && $.browser.mozilla) {
                $(elem).find(".c_s-scroll-area").height(height);
            }
            panel.InitScrollPane();
          }
        },
        success: function(xhr) {
            panel.SetUrl(panel.Url);
        }
    }
    );
  };

  /**
  * @param -
  * purpose:    places an img tag (with src=this.Url) inside the searchresult div
  *             and afterwards initializes/refreshes the scrollbar
  * @return    -
  */
  this.GetFacsimile = function()
  {
    var elem = this.GetCssId();

    var resultPane = $(elem).find(".searchresults");
    if (resultPane.data('jsp') != undefined)
    {
      resultPane = resultPane.data('jsp').getContentPane();
    }
    resultPane.html('<img src="' + this.Url + '" class="facsimile-img"/>');
    var caller = this;
    $(".facsimile-img").load(function(){
    	caller.RefreshScrollPane();
    });
  };

  /**
  * purpose:    invokes a AJAX call to the switch script that handles search orders
  *             to every search ressource; displays the search result in the
  *             searchresult div
  * @param {number} [start] Optionally use this as the start record when retrieving the data.
  * @param {number} [max] Optionally use this as the maximum number of records the server should return. 
  * @return {url} The url string that was used to get the displayed search result
  */
  this.StartSearch = function(start, max)
  {
    if (start === undefined)
        start = this.DefaultStartRecord;
    if (max === undefined)
        max = this.DefaultMaxRecords;
    var parElem = this.GetCssId();
    var sstr = $(parElem).find(".searchstring").val();
    var sele = parseInt($(parElem).find(".searchcombo").val());

    //  empty result-pane and indicate loading
    var resultPane = $(parElem).find(".searchresults").addClass("cmd loading");
    var oldHits = parseInt($(resultPane).find(".result-header").attr("data-numberOfRecords"), 10);
    oldHits = isNaN(oldHits) ? 2: oldHits;
    if (resultPane.data('jsp') !== undefined)
    {
       resultPane = resultPane.data('jsp').getContentPane();
    }
    resultPane.text("");
    PanelController.RefreshScrollPane(panelId);

    // get batch start and size
    var startInput = $(parElem).find(".startrecord");
    var maxInput = $(parElem).find(".maxrecord");

    var xcontext = this.PanelController.GetResourceName(sele);

        /* url +  */
    var urlStr = params.switchURL + "?operation=searchRetrieve&query=" + sstr + "&x-context=" + xcontext +
                 "&x-format=html&version=1.2";
    if (this.UrlParams['x-dataview'] !== undefined) {
        urlStr += "&x-dataview=" +this.UrlParams['x-dataview'];
    } else {
        urlStr += "&x-dataview=kwic,title"
    }

    if (!max || max <= 0) max = this.DefaultMaxRecords;
    if (!start || start < 1) start = this.DefaultStartRecord;

    urlStr += '&maximumRecords=' + max + '&startRecord=' + start;
    
    var useQueryTypeNative = $(parElem).find(".c_s-queryType-native:checked");
    if (useQueryTypeNative.length === 1) {
        urlStr += "&queryType=native";
    }

    this.SetUrl(urlStr);

    var panelId = this.Id;
    var panel = this;
    
    $(parElem).find(".hitcount").text("-");
    startInput.val(start);
    maxInput.val(max);
    
    $.ajax(
    {
        type: 'GET',
        url: params.switchURL,
        dataType: 'xml',
        data : this.UrlParams,
        complete: function(xml, textStatus)
        {
          resultPane = $(parElem).find(".searchresults").removeClass("cmd loading");;

          var hstr;
          if (xml.responseText != undefined)
             hstr = xml.responseText;
          else
             hstr = xml.statusText;
          hstr = hstr.replace(/&amp;/g, "&");

          var hits;
          // init or refresh scrollbars
          if ($(parElem).find(".searchresults").data('jsp') != undefined)
          {
            $(parElem).find(".searchresults").data('jsp').getContentPane().html(hstr);
            PanelController.RefreshScrollPane(panelId);
          }
          else
          {
            var height;
            var navigationHeight;
            if ($.browser.mozilla) {
            /* Part of a crude hack to get around missing support for overflow and
             * percentage height in table cells in firefox (only fixed px overflows
             * are used).
             */
             height = $(parElem).find(".c_s-scroll-area").height();
             navigationHeight = $(parElem).find(".c_s-navigation-ui").height();
            }
            $(resultPane).html(hstr);
            hits = parseInt($(resultPane).find(".result-header").attr("data-numberOfRecords"), 10);
            if ($.browser.mozilla) {
                height = (oldHits <= 1) && (hits > 1) ? height - navigationHeight : height;
                height = (hits <= 1) && (oldHits > 1) ? height + navigationHeight : height;
                $(parElem).find(".c_s-scroll-area").height(height);
            }
            PanelController.InitScrollPane(panelId);
          }
          $(parElem).find(".c_s-navigation-ui").css("display", "");
          if (hits === 1) {
              $(parElem).find(".c_s-navigation-ui").css("display", "none");
          } else {
          $(parElem).find(".hitcount").text(hits);
              if (start > hits) {
                 start = hits;
                 startInput.val(start);
              }
              if ((start + max) > hits)
                 maxInput.val(hits - start + 1);
          }
          $(resultPane).find(".result-header").hide();
        },
        success: function(xhr) {
            panel.SetUrl(decodeURI(panel.Url));
        }
    }
    );

    return urlStr;
  };

  /**
   * A jQuery object representing a clickabel UI item which knows how to perform
   * a search
   */
  this.searchbutton;
  
  /**
   * A jQuery object that is used for submitting the search "phrases". A virtual
   * keyboard might need to be appended to this. 
   */
  this.searchinput;
  
  /**
   * A jQuery object that is used to switch to a native query format, e.g. CorpusQL
   * instead of ContextQL. Needs to be switched on and off if the selected context
   * changes.
   */
  this.nativequery;

  /**
   * 
   * @param {jQuery} searchstring A jQuery object representing text input
  * @param {string} searchStr Search string
  */
        this.ConfigureSearchTextInput = function(searchstring, searchStr) {
            var availableTags = ResourceController.GetLabelValueArray();

            searchstring
                    .bind("keydown", function(event) {
                        if (event.keyCode === $.ui.keyCode.TAB &&
                                $(this).data("autocomplete").menu.active) {
                            event.preventDefault();
                        }
                    })
                    .autocomplete({
                        minLength: 0,
                        source: // availableTags
                                function(request, response) {
                                    //  delegate back to autocomplete, but extract the last term
                                    response($.ui.autocomplete.filter(
                                            availableTags, extractLast(request.term)));
                                }
                        ,
                        focus: function() {
                            //  prevent value inserted on focus
                            return false;
                        },
                        select: function(event, ui) {
                            var terms = split(this.value);
                            //  remove the current input
                            terms.pop();
                            //  add the selected item
                            terms.push(ui.item.value);
                            //  add placeholder to get the comma-and-space at the end
                            terms.push("");
                            this.value = terms.join("=");
                            return false;
                        }
                    });
            searchstring.attr('data-context', this.PanelController.GetResourceName(this.Config));
            searchstring.attr('id', this.Id + '-searchstring');
            // fetchKeys? wait? when? where?

            if (searchStr !== undefined)
                searchstring.val(searchStr);

            var searchbutton = this.searchbutton;
            
            searchstring.keyup(function(event)
            {
                if (event.keyCode === 13)
                    searchbutton.click();
            });
            this.searchinput = searchstring;
        };
  
  /**
   * 
   * @param {jQuery} searchcombo A jQuery object representing an option element
   *                             that should be used to present possible search
   *                             contexts.
   * @param {number} configIdx A number that denotes the preselected option.
   */
  this.ConfigureSearchContextCombo = function(searchcombo, configIdx) {
    for (var i = 0; i < this.PanelController.SearchConfig.length; i++)
    {
       var searchoption = $(document.createElement('option'));
       searchoption.attr("value", i);

       if (i === configIdx)
         searchoption.attr("selected", "selected");

       searchoption.text(this.PanelController.SearchConfig[i]["DisplayText"]);
       searchcombo.append(searchoption);
    }
    
    var obj = this;
    searchcombo.on("change", function(){
        obj.Config = this.selectedIndex;
        var newContext = obj.PanelController.GetResourceName(obj.Config);
        obj.searchinput.data('context', newContext);
        /* debugging only, will not be read again by data() */
        obj.searchinput.attr('data-context', newContext);        
        VirtualKeyboard.attachKeyboards();
        if (obj.canUseNative()) {
            obj.nativequery.css("display", "table-row");
            obj.nativequery.find("input.c_s-queryType-native").attr('checked', obj.UrlParams.queryType === "native");
        } else {
            obj.nativequery.css("display", "none");
            obj.nativequery.find("input.c_s-queryType-native").attr('checked', false);
        }
    });
    
    var searchbutton = this.searchbutton;
        
    searchcombo.keyup(function(event)
    {
      if(event.keyCode === 13)
         searchbutton.click();
    });  
  };

  /**
   * @param {jQuery} context The jQuery object that should be manipulated.
   *        This object is expected to have some space of class
   *        c_s-ui-widget-header-title for the title and two hidden
   *        markers of class titletopiconpin for the pinned state one
   *        of which has also class c_s-greyed and both have class c_s-hidden
   *        initially. The class c_s-hidden will be removed to denote the
   *        current state. Elements with class titletopiconclose and
   *        titletopiconmax will have onclick handlers attached.
  * @param {string} titlestring The panel's title.
  * @param {number} pin With a value of 1 the panel gets a pin icon.
  * @param {boolean} pinned Boolean value that tells wether the panel is pinned.
  * purpose:    creates a paragraph containing the panel title and the icons to pin
  *             (optional), maximize, and close.
  * @return    the complete panel title paragraph as a DOM object
  */
 
  this.FillInPanelTitle = function(context, titlestring, pin, pinned) {
        context.find(".c_s-ui-widget-header-title").text(titlestring);
        if (pin === 1)
        {
            if (pinned === true) {
                context.find(".titletopiconpin.c_s-grayed").removeClass("c_s-hidden");
            } else {
                context.find(".titletopiconpin:not(.c_s-grayed)").removeClass("c_s-hidden");
            }
        }
        context.find(".titletopiconclose").attr("onclick", "PanelController.ClosePanel('" + this.Id + "');");
        context.find(".titletopiconmax").attr("onclick", "PanelController.MaximizePanel('" + this.Id + "');");
        context.find(".titletopiconnorm").attr("onclick", "PanelController.NormalizePanel('" + this.Id + "');");
        // TODO Check this!
        context.find(".titletopiconpin").attr("onclick", "PanelController.PinPanel('" + this.Id + "', 2);");
        context.find(".titletopiconpin.c_s-grayed").attr("onclick", "PanelController.PinPanel('" + this.Id + "', 1);");
        if (this.Url in this) {
            this.SetUrl(this.Url);
        }
  };
};
    
    module.panelProto;
    module.searchUIProto;
    module.failed = PanelController === undefined ||
        ResourceController === undefined ||
        VirtualKeyboard === undefined ||
        VirtualKeyboard.failed ||
        URI === undefined;

    if (!module.failed) {
        $.ajax(params.templateLocation + "panel.tpl.html", {
            async: false,
            dataType: 'html',
            error: function() {
                module.failed = true;
            },
            success: function(unused, unused2, jqXHR) {
                module.panelProto = $(jqXHR.responseText).find('#template');
                module.failed = (module.panelProto.length === undefined ||
                        module.panelProto.length !== 1);
                module.panelProto.find('.remove-for-production').remove();
                module.panelProto.removeAttr('id');
                $.ajax(params.templateLocation + "searchui.tpl.html", {
                async: false,
                        dataType: 'html',
                        error: function () {
                            module.failed = true;
                        },
                        success: function (unused, unused2, jqXHR) {
                            module.searchUIProto = $(jqXHR.responseText).find('#template');
                            module.failed = (module.searchUIProto.length === undefined ||
                                    module.searchUIProto.length !== 1);
                            module.searchUIProto.find('.remove-for-production').remove();
                            module.searchUIProto.removeAttr('id');
                        }
                    });
            }
        });
    }
    
    // publish
    this.Panel = module;
}(jQuery, params, PanelController, ResourceController, VirtualKeyboard, document);
