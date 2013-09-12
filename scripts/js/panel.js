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
function Panel(id, type, title, url, position, pinned, zIndex, container, panelController, config)
{
  /**
   * @public
   * @type {string}
   * @desc Used as an id for an HTML element. 
   */
  this.Id = id;
  /** 
   * @public
   * @type {string}
   * @desc One of search, image, 
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
   * @desc A URL used for searching.
   */
  this.Url = url;
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
  this.PanelController = panelController;
  /**
   * @public
   * @type {number}
   * @desc The index in {@link module:corpus_shell~SearchConfig} for the config to use in search operations.
   */
  this.Config = config;

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
    if (this.Type == "search")
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
    this.Url = url;
    this.PanelController.SetPanelUrl(this.Id, url);
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

    $(this.GetCssId()).find(".titletopiconmax").attr("src", "scripts/style/img/n.win_max.png");
    $(this.GetCssId()).find(".titletopiconmax").parent().attr("onclick", "PanelController.MaximizePanel('" + this.Id + "');");
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

    $(this.GetCssId()).find(".titletopiconmax").attr("src", "scripts/style/img/n.win_norm.png");
    $(this.GetCssId()).find(".titletopiconmax").parent().attr("onclick", "PanelController.NormalizePanel('" + this.Id + "');");
  }

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
      $(paneldiv).find(".titletopiconpin").attr("src", "scripts/style/img/pin.gray.png");
      $(paneldiv).find(".titletopiconpin").removeClass("pinned");
      $(paneldiv).find(".titletopiconpin").parent().attr("onclick", "PanelController.PinPanel('" + this.Id + "', 2);");
    }
    else
    {
      this.Pinned = false;
      $(paneldiv).find(".titletopiconpin").attr("src", "scripts/style/img/pin.color.png");
      $(paneldiv).find(".titletopiconpin").addClass("pinned");
      $(paneldiv).find(".titletopiconpin").parent().attr("onclick", "PanelController.PinPanel('" + this.Id + "', 1);");
    }
  }

  /**
  * @param -
  * purpose:    corrects the height of the searchresult div dependent on the panel type
  * @return    -
  */
  this.CorrectSearchResultHeight = function()
  {
    var hgt = $(this.GetCssId()).height();

    if (this.Type == "search")
      $(this.GetCssId()).find(".searchresults").height(hgt - 105);
    else
      $(this.GetCssId()).find(".searchresults").height(hgt - 35);
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
  this.CreateNewSearchPanel = function(configIdx, searchStr)
  {
    var searchPanel = document.createElement('div');

    $(searchPanel).addClass("draggable ui-widget-content whiteback");
    $(searchPanel).attr("id", this.Id);
    $(searchPanel).attr("onclick", "PanelController.BringToFront('" + this.Id + "');");
    $(searchPanel).css("position", "absolute");

    $(searchPanel).css("left", this.Position.Left);
    $(searchPanel).css("top", this.Position.Top);
    $(searchPanel).css("width", this.Position.Width);
    $(searchPanel).css("height", this.Position.Height);
    $(searchPanel).css("z-index", this.ZIndex);

    var titlep = this.GeneratePanelTitle(this.Title, 0, false);
    $(searchPanel).append(titlep);

    var query = "";

    if (this.Url != undefined && this.Url != "")
    {
      var urlObj = this.GetUrlParams(this.Url);
      var xContext = urlObj['x-context'];
      this.Config = this.PanelController.GetSearchIdx(xContext);
      query = urlObj['query'];
    }
    else
    {
      if (searchStr != undefined)
        query = searchStr;
    }

    $(searchPanel).append(this.GenerateSearchInputs(this.Config, query));
    $(searchPanel).append(this.GenerateSearchNavigation());

    var searchResultDiv = this.GenerateSearchResultsDiv();
    var newHeight = parseInt(this.Position.Height.replace(/px/g, "")) - 105;

    $(searchResultDiv).css("height", newHeight + "px");
    $(searchPanel).append(searchResultDiv);

    $(this.Container).append(searchPanel);
    this.InitDraggable();
  };

  /**
  * @param -
  * purpose:    creates a new sub panel, ie. a panel without search inputs
  * @return    -
  */
  this.CreateNewSubPanel = function()
  {
    var newPanel = document.createElement('div');
    $(newPanel).addClass("draggable ui-widget-content whiteback");

    $(newPanel).attr("id", this.Id);
    $(newPanel).attr("onclick", "PanelController.BringToFront('" + this.Id + "');");
    $(newPanel).css("position", "absolute");

    $(newPanel).css("left", this.Position.Left);
    $(newPanel).css("top", this.Position.Top);
    $(newPanel).css("width", this.Position.Width);
    $(newPanel).css("height", this.Position.Height);
    $(newPanel).css("z-index", this.ZIndex);

    var usePin = 1;

    if (this.Type == "content")
      usePin = 0;

    var titlep = this.GeneratePanelTitle(this.Title, usePin, this.Pinned);
    $(newPanel).append(titlep);
    var searchResultDiv = this.GenerateSearchResultsDiv();
    $(searchResultDiv).css('height', $(newPanel).height() - 35);
    $(newPanel).append(searchResultDiv);

    $(this.Container).append(newPanel);
    this.CorrectSearchResultHeight(newPanel);

    if (this.Type == "image")
      this.GetFacsimile();
    else if ((this.Type == "text") || (this.Type == "content"))
      this.GetFullText();

    this.InitDraggable();
  };

  /**
  * @param url - string containing an URL
  * purpose:    parses the given url and fills an array fill with the key/value pairs
  *             of all url parameters
  * @return    array with key/value pairs of the url params
  */
  this.GetUrlParams = function(url)
  {
    var urlParams = {};
    if (url != undefined)
    {
      var match;
      var pl     = /\+/g;  //  Regex for replacing addition symbol with a space
      var search = /([^&=]+)=?([^&]*)/g;
      var decode = function (s) { return decodeURIComponent(s.replace(pl, " ")); };

      var query  = "";
      var qmPos = url.indexOf('?');
      if (qmPos != -1)
        query = url.substr(qmPos + 1);
      else
        query = url;

      while (match = search.exec(query))
         urlParams[decode(match[1])] = decode(match[2]);
    }

    return urlParams;
  };

  /**
  * @param -
  * purpose:    makes the panel DOM object resizeable and draggable.
  * @return    -
  */
  this.InitDraggable = function()
  {
    var panelId = this.Id;

    $(this.GetCssId())
    .resizable({ containment: "parent", aspectRatio: false,
               resize: function(event, ui)
               {
                 PanelController.BringToFront(panelId);
                 var hgt = $(this).height();
                 if ($(this).find(".searchstring").length != 0)
                   $(this).find(".searchresults").css("height", hgt - 105 + "px");
                 else
                   $(this).find(".searchresults").css("height", hgt - 35 + "px");

                 PanelController.RefreshScrollPane(panelId);

                 var wid = $(this).width();
                 $(this).find(".searchresults").css("width", wid + "px");

                 PanelController.UpdatePanelPosition(panelId);
               }
               })
    .draggable({ handle: "p", containment: "parent",  snap: true,
               start: function(event, ui)
               {
                 PanelController.BringToFront(panelId);
               } ,
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
   var srdiv = $(this.GetCssId()).find(".searchresults");
   $(srdiv).jScrollPane({ mouseWheelSpeed: 10});
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

    $.ajax(
    {
        type: 'GET',
        url: this.Url,
        dataType: 'xml',
        complete: function(xml, textStatus)
        {
          var responseText = xml.responseText;

          responseText = $(responseText).find(".title, .data-view, .navigation, .content");

          if ($(elem).find(".searchresults").data('jsp') != undefined)
          {
            $(elem).find(".searchresults").data('jsp').getContentPane().html(responseText);
            panel.RefreshScrollPane();
          }
          else
          {
            $(elem).find(".searchresults").html(responseText);
            panel.InitScrollPane();
          }
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
  * @return {url} the url string that was used to get the displayed search result
  */
  this.StartSearch = function()
  {
    var parElem = this.GetCssId();
    var sstr = $(parElem).find(".searchstring").val();
    var sele = parseInt($(parElem).find(".searchcombo").val());

    //  empty result-pane and indicate loading
    var resultPane = $(parElem).find(".searchresults").addClass("cmd loading");
    if (resultPane.data('jsp') != undefined)
    {
       resultPane = resultPane.data('jsp').getContentPane();
    }
    resultPane.text("");
    PanelController.RefreshScrollPane(panelId);
    $(parElem).find(".hitcount").text("-");

    // get batch start and size
    var start = parseInt($(parElem).find(".startrecord").val());
    var max = parseInt($(parElem).find(".maxrecord").val());

    var xcontext = this.PanelController.GetResourceName(sele);

        /* url +  */
    var urlStr = switchURL + "?operation=searchRetrieve&query=" + sstr + "&x-context=" + xcontext +
                 "&x-format=html&version=1.2";

    if (!max || max <= 0) max = 10;
    if (!start || start < 1) start = 1;

    urlStr += '&maximumRecords=' + max + '&startRecord=' + start;

    this.SetUrl(urlStr);

    var panelId = this.Id;

    $.ajax(
    {
        type: 'GET',
        url: switchURL,
        dataType: 'xml',
        data : {operation: 'searchRetrieve', query: sstr, 'x-context': xcontext, 'x-format': 'html', version: '1.2', maximumRecords: max, startRecord: start},
        complete: function(xml, textStatus)
        {
          $(parElem).find(".searchresults").removeClass("cmd loading");;

          var hstr;
          if (xml.responseText != undefined)
             hstr = xml.responseText;
          else
             hstr = xml.statusText;
          hstr = hstr.replace(/&amp;/g, "&");

          // init or refresh scrollbars
          if ($(parElem).find(".searchresults").data('jsp') != undefined)
          {
            $(parElem).find(".searchresults").data('jsp').getContentPane().html(hstr);
            PanelController.RefreshScrollPane(panelId);
          }
          else
          {
            $(resultPane).html(hstr);
            PanelController.InitScrollPane(panelId);
          }
          var hits = $(resultPane).find(".result-header").attr("data-numberOfRecords");
          $(parElem).find(".hitcount").text(hits);
          $(resultPane).find(".result-header").hide();
        }
    }
    );

    return urlStr;
  };

  // generate dom objects

  /**
  * @param {number} configIdx  Selected index of SearchCombo
  * @param {string} searchStr Search string
  * purpose:    creates a div with the searchsting text input, the endpoint combobox,
  *             and the start search button.<br/>
  * If the Go button is clicked PanelController's {@link module:corpus_shell~PanelManager#StartSearch} is invoked
  * with this panels unique id.
  * @return    the complete div as a DOM object
  */
  this.GenerateSearchInputs = function(configIdx, searchStr)
  {
    var searchdiv = document.createElement('div');
    $(searchdiv).addClass("searchdiv");
    $(searchdiv).text("Search for ");

    var searchstring = document.createElement('input');
    $(searchstring).addClass("searchstring");
    $(searchstring).attr("type", "text");

    var availableTags = ResourceController.GetLabelValueArray();

    $(searchstring)
      .bind( "keydown", function( event ) {
       if ( event.keyCode === $.ui.keyCode.TAB &&
         $( this ).data( "autocomplete" ).menu.active ) {
        event.preventDefault();
       }
      })
     .autocomplete({
      minLength: 0,
      source: // availableTags
      function( request, response ) {
       //  delegate back to autocomplete, but extract the last term
       response( $.ui.autocomplete.filter(
        availableTags, extractLast( request.term ) ) );
      }
      ,
      focus: function() {
       //  prevent value inserted on focus
       return false;
      },
      select: function( event, ui ) {
       var terms = split( this.value );
       //  remove the current input
       terms.pop();
       //  add the selected item
       terms.push( ui.item.value );
       //  add placeholder to get the comma-and-space at the end
       terms.push( "" );
       this.value = terms.join("=");
       return false;
      }
     });

    if (searchStr != undefined)
      $(searchstring).val(searchStr);

    var buttondiv = document.createElement('div');
    $(buttondiv).css('float', 'right');

    var searchbutton = document.createElement('input');
    $(searchbutton).addClass("searchbutton");
    $(searchbutton).attr("type", "button");
    $(searchbutton).attr("value", "Go");
    $(searchbutton).attr("onclick", "PanelController.StartSearch('" + this.Id + "');");

    var searchcombo = this.GenerateSearchCombo(configIdx);

    $(searchdiv).append(searchstring);
    $(searchdiv).append(" in ");
    $(searchdiv).append(searchcombo);
    $(searchdiv).append(" ");
    $(buttondiv).append(searchbutton);
    $(searchdiv).append(buttondiv);

    $(searchstring).keyup(function(event)
    {
      if(event.keyCode == 13)
        $(searchbutton).click();
    });

    $(searchcombo).keyup(function(event)
    {
      if(event.keyCode == 13)
        $(searchbutton).click();
    });

    return searchdiv;
  };

  /**
  * @param configIdx - selected index of SearchCombo
  * purpose:    creates the endpoint combobox, selects the entry with the index given
  *             in configIdx
  * @return    the combobox as a DOM object
  */
  this.GenerateSearchCombo = function(configIdx)
  {
    var searchcombo = document.createElement('select');
    $(searchcombo).addClass("searchcombo");

    for (var i = 0; i < this.PanelController.SearchConfig.length; i++)
    {
       var searchoption = document.createElement('option');
       $(searchoption).attr("value", i);

       if (i == configIdx)
         $(searchoption).attr("selected", "selected");

       $(searchoption).text(this.PanelController.SearchConfig[i]["DisplayText"]);
       $(searchcombo).append(searchoption);
    }

    return searchcombo;
  };

  /**
  * @param {string} titlestring The panel's title.
  * @param {number} pin With a value of 1 the panel gehts a pin icon.
  * @param {boolean} pinned Boolean value that tells wether the panel is pinned.
  * purpose:    creates a paragraph containing the panel title and the icons to pin
  *             (optional), maximize, and close.
  * @return    the complete panel title paragraph as a DOM object
  */
  this.GeneratePanelTitle = function(titlestring, pin, pinned)
  {
    var titlep = document.createElement('p');
    $(titlep).addClass("ui-widget-header");

    var titletable = document.createElement('table');
    $(titletable).css("width", "100%");

    var titletr = document.createElement('tr');
    var lefttd = document.createElement('td');
    $(lefttd).text(titlestring);

    if (pin == 1)
    {
       var pintd = document.createElement('td');
       $(pintd).css("width", "17px");

       var pina = document.createElement('a');
       $(pina).attr("href", "#");

       if (pinned == true)
         $(pina).attr("onclick", "PinPanel(this, 1);");
       else
         $(pina).attr("onclick", "PinPanel(this, 2);");
       $(pina).addClass("noborder");

       var pinimg = document.createElement('img');

       if (pinned == true)
         $(pinimg).attr("src", "scripts/style/img/pin.color.png");
       else
         $(pinimg).attr("src", "scripts/style/img/pin.gray.png");

       $(pinimg).addClass("titletopiconpin");
       $(pinimg).addClass("noborder");
    }

    var righttd1 = document.createElement('td');
    $(righttd1).css("width", "17px");

    var maxa = document.createElement('a');
    $(maxa).attr("href", "#");
    $(maxa).attr("onclick", "PanelController.MaximizePanel('" + this.Id + "');");
    $(maxa).addClass("noborder");

    var maximg = document.createElement('img');
    $(maximg).attr("src", "scripts/style/img/n.win_max.png");
    $(maximg).addClass("titletopiconmax");
    $(maximg).addClass("noborder");

    var righttd2 = document.createElement('td');
    $(righttd2).css("width", "17px");

    var closea = document.createElement('a');
    $(closea).attr("href", "#");
    $(closea).attr("onclick", "PanelController.ClosePanel('" + this.Id + "');");
    $(closea).addClass("noborder");

    var closeimg = document.createElement('img');
    $(closeimg).attr("src", "scripts/style/img/n.win_close.png");
    $(closeimg).attr("alt", "X");
    $(closeimg).addClass("titletopiconclose");
    $(closeimg).addClass("noborder");

    $(maxa).append(maximg);
    $(closea).append(closeimg);

    $(righttd1).append(maxa);
    $(righttd2).append(closea);

    $(titletr).append(lefttd);

    if (pin == 1)
    {
      $(pina).append(pinimg);
      $(pintd).append(pina);

      $(titletr).append(pintd);
    }

    $(titletr).append(righttd1);
    $(titletr).append(righttd2);

    $(titletable).append(titletr);
    $(titlep).append(titletable);

    return titlep;
  };

  /**
  * purpose:    creates a table with icons to navigate through the search result
  * @return    returns the complete table as a DOM object
  */
  this.GenerateSearchNavigation = function()
  {
    var navtable = document.createElement('table');
    $(navtable).addClass("navigation");

    var navtr = document.createElement('tr');
    var navigationtitle = document.createElement('td');
    $(navigationtitle).text("Search results");
    $(navigationtitle).addClass("navigationtitle");

    var navigationmain = document.createElement('td');
    $(navigationmain).addClass("navigationmain");
    $(navigationmain).append("<i>hits:</i>&nbsp;");

    var hitcount = document.createElement('span');
    $(hitcount).addClass("hitcount");
    $(hitcount).text("0");

    $(navigationmain).append(hitcount);
    $(navigationmain).append(";&nbsp;<i>from:</i>&nbsp;");

    var startrecord = document.createElement('input');
    $(startrecord).addClass("startrecord");
    $(startrecord).attr("type","text");
    $(startrecord).val("1");

    $(navigationmain).append(startrecord);
    $(navigationmain).append("&nbsp;<i>max:</i>&nbsp;");

    var maxrecord = document.createElement('input');
    $(maxrecord).addClass("maxrecord");
    $(maxrecord).attr("type","text");
    $(maxrecord).val("10");

    $(navigationmain).append(maxrecord);

    var loada = document.createElement('a');
    $(loada).addClass("noborder");
    $(loada).attr("href", "#");
    $(loada).attr("onclick", "PanelController.StartSearch('" + this.Id + "');");

    var loadimg = document.createElement('img');
    $(loadimg).addClass("navigationicon");
    $(loadimg).attr("src", "scripts/style/img/n.arrow_right_b.png");

    $(loada).append(loadimg);

    var preva = document.createElement('a');
    $(preva).addClass("noborder");
    $(preva).attr("href", "#");
    $(preva).attr("onclick", "PanelController.StartSearchPrev('" + this.Id + "');}");

    var previmg = document.createElement('img');
    $(previmg).addClass("navigationicon");
    $(previmg).attr("src", "scripts/style/img/n.arrow_left.png");

    $(preva).append(previmg);

    var nexta = document.createElement('a');
    $(nexta).addClass("noborder");
    $(nexta).attr("href", "#");
    $(nexta).attr("onclick", "PanelController.StartSearchNext('" + this.Id + "');");

    var nextimg = document.createElement('img');
    $(nextimg).addClass("navigationicon");
    $(nextimg).attr("src", "scripts/style/img/n.arrow_right.png");

    $(nexta).append(nextimg);

    $(navigationmain).append(loada);
    $(navigationmain).append(preva);
    $(navigationmain).append(nexta);

    $(navtr).append(navigationtitle);
    $(navtr).append(navigationmain);

    $(navtable).append(navtr);

    return navtable;
  };

  /**
  * purpose:    creats a div that is filled with the search result returned from the
  *             search script (switch.php)
  * @return    -
  */
  this.GenerateSearchResultsDiv = function()
  {
    var resultdiv = document.createElement('div');
    $(resultdiv).addClass("searchresults");
    return resultdiv;
  };
}