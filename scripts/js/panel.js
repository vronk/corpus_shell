/*
 * subject:      Panel class
 * purpose:      represents a panel in corpus_shell
 *
 * dependencies: PanelManager/PanelController - panelmanager.js
 *               jQuery
 *
 * creator:      Andy Basch
 * last change:  2012.10.02
 */

function Panel(id, type, title, url, position, pinned, zIndex, container, panelController, config)
{
  /* public properties */
  this.Id = id;
  this.Type = type;
  this.Title = title;
  this.Url = url;
  this.Position = position;
  this.Pinned = pinned;
  this.ZIndex = zIndex;
  this.Container = container;
  this.PanelController = panelController;
  this.Config = config;

  /* methods */

  //function:   this.CreatePanel()
  //parameters: -
  //purpose:    creates the actual DOM-object and appends it to this.Container
  //            depending on the value of this.Type either this.CreateNewSearchPanel()
  //            or this.CreateNewSubPanel() is called
  //returns:    -
  this.CreatePanel = function(searchstr)
  {
    if (this.Type == "search")
      this.CreateNewSearchPanel(this.Config, searchstr);
    else
      this.CreateNewSubPanel();
  }

  //function:   this.SetUrl(url)
  //parameters: url - string containing an URL
  //purpose:    sets the property this.Url and additionally sets the url in
  //            this.PanelController
  //returns:    -
  this.SetUrl = function(url)
  {
    this.Url = url;
    this.PanelController.SetPanelUrl(this.Id, url);
  }

  //function:   this.Close()
  //parameters: -
  //purpose:    closes the panel - ie remove it completelly from the DOM-tree
  //returns:    -
  this.Close = function()
  {
    $(this.GetCssId()).remove();
  }

  //postion handling

  //function:   this.UpdatePosition()
  //parameters: -
  //purpose:    gets the current position and size of the panel DOM object and sets
  //            the property this.Position
  //returns:    -
  this.UpdatePosition = function()
  {
    var newPosition = this.GetPanelPosition();
    this.Position = newPosition;
  }

  //function:   this.SetPosition(position)
  //parameters: position - object that contains values for top and left position as
  //            well as width and height
  //purpose:    set postion and size of panel div, sets this.Position property, too
  //returns:    -
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

  //function:   this.GetPanelPosition()
  //parameters: -
  //purpose:    gets the current position and size of the panel DOM object
  //returns:    postion object containing the values for left, top, width, and height
  this.GetPanelPosition = function()
  {
    var position = new Object();
    position["Left"] = $(this.GetCssId()).css("left");
    position["Top"] = $(this.GetCssId()).css("top");
    position["Width"] = $(this.GetCssId()).css("width");
    position["Height"] = $(this.GetCssId()).css("height");

    return position;
  }

  //function:   this.SetZIndex(zIdx)
  //parameters: zIdx - Z-Index value
  //purpose:    sets the Z-Index of the panel DOM object and the this.ZIndex property
  //returns:    -
  this.SetZIndex = function(zIdx)
  {
    this.ZIndex = zIdx;

    $(this.GetCssId()).css("z-index", zIdx);
  }

  //function:   this.Normalize(position, zIdx)
  //parameters: position - object that contains values for top and left position as
  //            well as width and height
  //            zIdx - Z-Index value
  //purpose:    sets all position/dimension values of the panel, used to return panel
  //            from maximized to normal mode (= dimension and position prior to
  //            maximization), changes the title bar icon and link to allow for the
  //            panel to be maximized again.
  //returns:    -
  this.Normalize = function(position, zIdx)
  {
    this.SetPosition(position);
    this.SetZIndex(zIdx);

    this.CorrectSearchResultHeight();

    $(this.GetCssId()).find(".titletopiconmax").attr("src", "scripts/style/img/n.win_max.png");
    $(this.GetCssId()).find(".titletopiconmax").parent().attr("onclick", "PanelController.MaximizePanel('" + this.Id + "');");
  }

  //function:   this.Maximize(position, zIdx)
  //parameters: position - object that contains values for top and left position as
  //            well as width and height
  //            zIdx - Z-Index value
  //purpose:    sets all position/dimension values of the panel, used to maximize the
  //            panel, changes the title bar icon and link
  //returns:    -
  this.Maximize = function(position, zIdx)
  {
    this.SetPosition(position);
    this.SetZIndex(zIdx);

    this.CorrectSearchResultHeight();

    $(this.GetCssId()).find(".titletopiconmax").attr("src", "scripts/style/img/n.win_norm.png");
    $(this.GetCssId()).find(".titletopiconmax").parent().attr("onclick", "PanelController.NormalizePanel('" + this.Id + "');");
  }

  //function:   this.Pin(pinnedState)
  //parameters: pinnedState - a value of 1 means that the panel is pinned
  //purpose:    sets the property this.Pinned and changes the icon in the panel title bar
  //returns:    -
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

  //function:   this.CorrectSearchResultHeight()
  //parameters: -
  //purpose:    corrects the height of the searchresult div dependent on the panel type
  //returns:    -
  this.CorrectSearchResultHeight = function()
  {
    var hgt = $(this.GetCssId()).height();

    if (this.Type == "search")
      $(this.GetCssId()).find(".scroll-pane").height(hgt - 105);
    else
      $(this.GetCssId()).find(".scroll-pane").height(hgt - 25);
  }

  //function:   this.CreateNewSearchPanel(configIdx, searchStr)
  //parameters: configIdx - selected index of SearchCombo
  //            searchStr - search string to inserted in search input
  //purpose:    creates a new search panel
  //returns:    -
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
      configIdx = this.PanelController.GetSearchIdx(xContext);
      query = urlObj['query'];
    }
    else
    {
      if (searchStr != undefined)
        query = searchStr;
    }

    $(searchPanel).append(this.GenerateSearchInputs(configIdx, query));
    $(searchPanel).append(this.GenerateSearchNavigation());

    var searchResultDiv = this.GenerateSearchResultsDiv();
    var newHeight = parseInt(this.Position.Height.replace(/px/g, "")) - 105;

    $(searchResultDiv).css("height", newHeight + "px");
    $(searchPanel).append(searchResultDiv);

    $(this.Container).append(searchPanel);
    this.InitDraggable();
  }

  //function:   this.CreateNewSubPanel()
  //parameters: -
  //purpose:    creates a new sub panel, ie. a panel without search inputs
  //returns:    -
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
  }

  //function:   this.GetUrlParams(url)
  //parameters: url - string containing an URL
  //purpose:    parses the given url and fills an array fill with the key/value pairs
  //            of all url parameters
  //returns:    array with key/value pairs of the url params
  this.GetUrlParams = function(url)
  {
    var urlParams = {};
    if (url != undefined)
    {
      var match;
      var pl     = /\+/g;  // Regex for replacing addition symbol with a space
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
  }

  //function:   this.InitDraggable()
  //parameters: -
  //purpose:    makes the panel DOM object resizeable and draggable.
  //returns:    -
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
                   $(this).find(".scroll-pane").css("height", hgt - 105 + "px");
                 else
                   $(this).find(".scroll-pane").css("height", hgt - 35 + "px");

                 PanelController.RefreshScrollPane(panelId);

                 var wid = $(this).width();
                 $(this).find(".scroll-content").css("width", wid - 16 + "px");

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
  }

  //function:   this.InitScrollPane()
  //parameters: -
  //purpose:    initializes the scrollbar adjacent to the searchresult div
  //returns:    -
  this.InitScrollPane = function()
  {
   var srdiv = $(this.GetCssId()).find(".searchresults");
   $(srdiv).sbscroller({ mousewheel: true});
  }

  //function:   this.RefreshScrollPane()
  //parameters: -
  //purpose:    refreshes the scrollbar adjacent to the searchresult div
  //returns:    -
  this.RefreshScrollPane = function()
  {
    $(this.GetCssId()).find(".searchresults").sbscroller('refresh');
  }

  //function:   this.GetCssId()
  //parameters: -
  //purpose:    adds a # char in front of this.Id to make it easier to address the
  //            panel with jQuery
  //returns:    -
  this.GetCssId = function()
  {
    return '#' + this.Id;
  }

  //function:   this.GetFullText()
  //parameters: -
  //purpose:    loads this.Url via AJAX and places the content of the remote file
  //            inside the searchresult div; afterwards initializes/refreshes the
  //            scrollbar
  //returns:    -
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

          if ($(elem).find(".scroll-content").length > 0)
          {
            $(elem).find(".scroll-content").html(responseText);
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
  }

  //function:   this.GetFacsimile()
  //parameters: -
  //purpose:    places an img tag (with src=this.Url) inside the searchresult div
  //            and afterwards initializes/refreshes the scrollbar
  //returns:    -
  this.GetFacsimile = function()
  {
    var elem = this.GetCssId();

    if ($(elem).find(".searchresults .scroll-content").length > 0)
    {
      $(elem).find(".searchresults .scroll-content").html('<img src="' + this.Url + '" />');
      this.RefreshScrollPane(elem);
    }
    else
    {
      $(elem).find(".searchresults").html('<img src="' + this.Url + '" />');
      this.InitScrollPane(elem);
    }
  }

  //function:   this.StartSearch()
  //parameters: -
  //purpose:    invokes a AJAX call to the switch script that handles search orders
  //            to every search ressource; displays the search result in the
  //            searchresult div
  //returns:    the url string that was used to get the displayed search result
  this.StartSearch = function()
  {
    var parElem = this.GetCssId();
    var sstr = $(parElem).find(".searchstring").val();
    var sele = parseInt($(parElem).find(".searchcombo").val());

    // empty result-pane and indicate loading
    $(parElem).find(".searchresults").addClass("cmd loading").text("");
    $(parElem).find(".hitcount").text("-");

    //get batch start and size
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
          var resultPane = $(parElem).find(".searchresults");
          resultPane.removeClass("cmd loading");

          var hstr = xml.responseText;
          hstr = hstr.replace(/&amp;/g, "&");

          //init or refresh scrollbars
          if ($(parElem).find(".searchresults .scroll-content").length > 0)
          {
            $(parElem).find(".searchresults .scroll-content").html(hstr);
            PanelController.RefreshScrollPane(panelId);
          }
          else
          {
            $(resultPane).html(hstr);
            PanelController.InitScrollPane(panelId);
          }
          var hits = $(resultPane).find(".result-header").attr("data-numberOfRecords")
          $(parElem).find(".hitcount").text(hits);
          $(resultPane).find(".result-header").hide();
        }
    }
    );

    return urlStr;
  }

  //generate dom objects

  //function:   this.GenerateSearchInputs(configIdx, searchStr)
  //parameters: configIdx - selected index of SearchCombo
  //            searchStr - search string
  //purpose:    creates a div with the searchsting text input, the endpoint combobox,
  //            and the search button
  //returns:    the complete div as a DOM object
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
      source: //availableTags
      function( request, response ) {
       // delegate back to autocomplete, but extract the last term
       response( $.ui.autocomplete.filter(
        availableTags, extractLast( request.term ) ) );
      }
      ,
      focus: function() {
       // prevent value inserted on focus
       return false;
      },
      select: function( event, ui ) {
       var terms = split( this.value );
       // remove the current input
       terms.pop();
       // add the selected item
       terms.push( ui.item.value );
       // add placeholder to get the comma-and-space at the end
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
  }

  //function:   this.GenerateSearchCombo(configIdx)
  //parameters: configIdx - selected index of SearchCombo
  //purpose:    creates the endpoint combobox, selects the entry with the index given
  //            in configIdx
  //returns:    the combobox as a DOM object
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
  }

  //function:   this.GeneratePanelTitle(titlestring, pin, pinned)
  //parameters: titlestring - panel title
  //            pin - with a value of 1 the panel gehts a pin icon
  //            pinned - boolean value that tells wether the panel is pinned
  //purpose:    creates a paragraph containing the panel title and the icons to pin
  //            (optional), maximize, and close.
  //returns:    the complete panel title paragraph as a DOM object
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
  }

  //function:   this.GenerateSearchNavigation()
  //parameters: -
  //purpose:    creates a table with icons to navigate through the search result
  //returns:    returns the complete table as a DOM object
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
  }

  //function:   this.GenerateSearchResultsDiv()
  //parameters: -
  //purpose:    creats a div that is filled with the search result returned from the
  //            search script (switch.php)
  //returns:    -
  this.GenerateSearchResultsDiv = function()
  {
    var resultdiv = document.createElement('div');
    $(resultdiv).addClass("searchresults");
    return resultdiv;
  }
}