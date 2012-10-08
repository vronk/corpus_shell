/*
 * subject:      PanelManager class
 * purpose:      handles the panel management in corpus_shell
 *
 * dependencies: Panel - panel.js
 *               jQuery
 *
 * creator:      Andy Basch
 * last change:  2012.10.02
 */

function PanelManager (container, searchConfig)
{
  /* public properties */
  this.Container = container;
  this.SearchConfig = searchConfig

  this.Panels = new Array();
  this.ProfileName = "default";
  this.UsedPanels = new Array();
  this.UsedSearchPanelTitles = new Array();
  this.PanelObjects = new Array();

  /* events */
  this.onUpdated = null;

  /* event triggers */
  this.TriggerChangedEvent = function (change)
  {
    if (typeof this.onUpdated == "function")
      this.onUpdated(change);
  }

  /* methods */


  //adders

  //function:   this.AddMainPanel(panelId, position, url, title, zIndex)
  //parameters: panelId - unique panel identifier
  //purpose:
  //returns:    -
  this.AddMainPanel = function(panelId, position, url, title, zIndex)
  {
    this.Panels[panelId] = this.GetNewMainPanelObject(panelId, position, url, title, zIndex);
    this.AddPanelId(panelId);
    this.AddSearchPanelTitle(title);
    this.TriggerChangedEvent("Mainpanel added: " + panelId);
  }

  //function:   this.AddImagePanel(parentId, panelId, pinned, position, url, title, zIndex)
  //parameters: panelId - unique panel identifier
  //purpose:
  //returns:    -
  this.AddImagePanel = function(parentId, panelId, pinned, position, url, title, zIndex)
  {
    this.AddSubPanel(parentId, panelId, pinned, position, url, title, zIndex, "image");
  }

  //function:   this.AddTextPanel(parentId, panelId, pinned, position, url, title, zIndex)
  //parameters: panelId - unique panel identifier
  //purpose:
  //returns:    -
  this.AddTextPanel = function(parentId, panelId, pinned, position, url, title, zIndex)
  {
    this.AddSubPanel(parentId, panelId, pinned, position, url, title, zIndex, "text");
  }

  //function:   this.AddSubPanel(parentId, panelId, pinned, position, url, title, zIndex, type)
  //parameters: panelId - unique panel identifier
  //purpose:
  //returns:    -
  this.AddSubPanel = function(parentId, panelId, pinned, position, url, title, zIndex, type)
  {
    var parent = null;

    if (this.IsSubPanel(parentId))
      parent = this.GetMainFromSubPanel(parentId);
    else
      parent = this.GetMainPanel(parentId);

    if (parent != undefined && parent != null)
    {
      parent.Panels[panelId] = this.GetNewPanelObject(panelId, type, pinned, position, url, title, zIndex);
      this.AddPanelId(panelId);

      var ucFirst =  type.charAt(0).toUpperCase() + type.substr(1);
      var message = ucFirst + "Panel added: " + panelId;

      this.TriggerChangedEvent(message);
    }
  }

  //getters

  //function:   this.GetMainPanel(parentId)
  //parameters: panelId - unique panel identifier
  //purpose:    gets or adds main panel
  //returns:    -
  this.GetMainPanel = function(panelId)
  {
    var main = this.Panels[panelId];

    if (main == undefined)
    {
      this.AddMainPanel(panelId);
      main = this.Panels[panelId];
    }

    return main;
  }

  //gets subpanel, if it doesn't exist, returns null
  //function:   this.GetSubPanel(parentId, panelId)
  //parameters: panelId - unique panel identifier
  //purpose:
  //returns:    -
  this.GetSubPanel = function(parentId, panelId)
  {
    if (parentId != "")
    {
      var subPanel = this.Panels[parentId].Panels[panelId];
      return subPanel == undefined ? null : subPanel;
    }
    else
    {
      for (var key in this.Panels)
      {
        var subPanel = this.Panels[key].Panels[panelId];
        if (subPanel != undefined)
          return subPanel;
      }

      return null;
    }
  }

  //function:   this.GetMainFromSubPanel(panelId)
  //parameters: panelId - unique panel identifier
  //purpose:
  //returns:    -
  this.GetMainFromSubPanel = function(panelId)
  {
     for (var key in this.Panels)
     {
       var subPanel = this.Panels[key].Panels[panelId];
       if (subPanel != undefined)
         return this.Panels[key];
     }

     return null;
  }

  //function:   this.GetMainIdFromSubPanel(panelId)
  //parameters: panelId - unique panel identifier
  //purpose:
  //returns:    -
  this.GetMainIdFromSubPanel = function(panelId)
  {
     for (var key in this.Panels)
     {
       var subPanel = this.Panels[key].Panels[panelId];
       if (subPanel != undefined)
         return key;
     }

     return null;
  }

  //function:   this.GetPanel(panelId)
  //parameters: panelId - unique panel identifier
  //purpose:
  //returns:    -
  this.GetPanel = function(panelId)
  {
    var panel = null;

    if (this.ExistsMainPanel(panelId) == true)
      panel = this.Panels[panelId];

    if (panel == null)
      panel = this.GetSubPanel("", panelId);

    return panel;
  }

  //function:   this.GetPinnedImagePanel(parentId)
  //parameters: panelId - unique panel identifier
  //purpose:
  //returns:    -
  this.GetPinnedImagePanel = function(parentId)
  {
    return this.GetPinnedPanel(parentId, "image");
  }

  //function:   this.GetPinnedImagePanelId(parentId)
  //parameters: panelId - unique panel identifier
  //purpose:
  //returns:    -
  this.GetPinnedImagePanelId = function(parentId)
  {
    return this.GetPinnedPanelId(parentId, "image");
  }

  //function:   this.GetPinnedTextPanel(parentId)
  //parameters: panelId - unique panel identifier
  //purpose:
  //returns:    -
  this.GetPinnedTextPanel = function(parentId)
  {
    return this.GetPinnedPanel(parentId, "text");
  }

  //function:   this.GetPinnedTextPanelId(parentId)
  //parameters: panelId - unique panel identifier
  //purpose:
  //returns:    -
  this.GetPinnedTextPanelId = function(parentId)
  {
    return this.GetPinnedPanelId(parentId, "text");
  }

  //function:   this.GetPinnedPanel(parentId, type)
  //parameters: panelId - unique panel identifier
  //purpose:
  //returns:    -
  this.GetPinnedPanel = function(parentId, type)
  {
    if (this.ExistsMainPanel(parentId) == false)
      if (this.IsSubPanel(parentId))
        parentId = this.GetMainIdBFromSubPanel(parentId);

    if (parentId == null)
      return null;

    var main = this.GetMainPanel(parentId);

    for (var key in main.Panels)
    {
      if (main.Panels[key] != undefined && main.Panels[key].Type == type && main.Panels[key].Pinned == true)
        return main.Panels[key];
    }

    return null;
  }

  //function:   this.GetPinnedPanelId(parentId, type)
  //parameters: panelId - unique panel identifier
  //purpose:
  //returns:    -
  this.GetPinnedPanelId = function(parentId, type)
  {
    if (this.ExistsMainPanel(parentId) == false)
      if (this.IsSubPanel(parentId))
        parentId = this.GetMainIdFromSubPanel(parentId);

    if (parentId == null)
      return null;

    var main = this.GetMainPanel(parentId);

    for (var key in main.Panels)
    {
      if (main.Panels[key] != undefined && main.Panels[key].Type == type && main.Panels[key].Pinned == true)
        return key;
    }

    return null;
  }

  //function:   this.GetPanelPosition(panelId)
  //parameters: panelId - unique panel identifier
  //purpose:
  //returns:    -
  this.GetPanelPosition = function(panelId)
  {
    var panel = this.GetPanel(panelId);

    if (panel != null)
      return panel.Position;
    else
      return null;
  }

  //function:   this.GetPanelUrl(panelId)
  //parameters: panelId - unique panel identifier
  //purpose:
  //returns:    -
  this.GetPanelUrl = function(panelId)
  {
    var panel = this.GetPanel(panelId);

    if (panel != null)
      return panel.Url;
    else
      return null;
  }

  //function:   this.GetPanelDivFromElement(elem)
  //parameters: -
  //purpose:
  //returns:    -
  this.GetPanelDivFromElement = function(elem)
  {
    return $(titlep).parents(".draggable");
  }

  //function:   this.InitScrollPane(panelId)
  //parameters: panelId - unique panel identifier
  //purpose:
  //returns:    -
  this.InitScrollPane = function(panelId)
  {
    var panelObj = this.GetPanelObj(panelId);
    if (panelObj)
      panelObj.InitScrollPane();
  }

  //function:   this.RefreshScrollPane(panelId)
  //parameters: panelId - unique panel identifier
  //purpose:
  //returns:    -
  this.RefreshScrollPane = function(panelId)
  {
    var panelObj = this.GetPanelObj(panelId);
    if (panelObj)
      panelObj.RefreshScrollPane();
  }

  //setters

  //function:   this.PinPanel(panelId, col)
  //parameters: panelId - unique panel identifier
  //purpose:
  //returns:    -
  this.PinPanel = function(panelId, col)
  {
    var panelObj = this.GetPanelObj(panelId);
    if (panelObj != undefined)
      panelObj.Pin(col);

    if (col == 1)
      this.SetPanelNotPinned(panelId);
    else
      this.SetPanelPinned(panelId);
  }

  //function:   this.SetPanelPinned(panelId)
  //parameters: panelId - unique panel identifier
  //purpose:
  //returns:    -
  this.SetPanelPinned = function(panelId)
  {
    this.SetPanelPinnedState(panelId, true);
  }

  //function:   this.SetPanelNotPinned(panelId)
  //parameters: panelId - unique panel identifier
  //purpose:
  //returns:    -
  this.SetPanelNotPinned = function(panelId)
  {
    this.SetPanelPinnedState(panelId, false);
  }

  //function:   this.SetPanelPinnedState(panelId, pinned)
  //parameters: panelId - unique panel identifier
  //purpose:
  //returns:    -
  this.SetPanelPinnedState = function(panelId, pinned)
  {
    var panel = this.GetSubPanel("", panelId);

    if (panel != null && panel.Pinned != pinned)
    {
      panel.Pinned = pinned;
      this.TriggerChangedEvent("Panel pinned state changed: " + panelId);
    }
  }

  //function:   this.SetPanelPosition(panelId, position)
  //parameters: panelId - unique panel identifier
  //purpose:
  //returns:    -
  this.SetPanelPosition = function(panelId, position)
  {
    var panel = this.GetPanel(panelId);

    if (panel != null && panel.Position != position)
    {
      panel.Position = position;
      this.TriggerChangedEvent("Panel position changed: " + panelId);
    }
  }

  //function:   this.SetPanelUrl(panelId, url)
  //parameters: panelId - unique panel identifier
  //purpose:
  //returns:    -
  this.SetPanelUrl = function(panelId, url)
  {
    var panel = this.GetPanel(panelId);

    if (panel != null && panel.Url != url)
    {
      panel.Url = url;
      this.TriggerChangedEvent("Panel url changed: " + panelId);
    }
  }

  //function:   this.SetPanelZIndex(panelId, zIndex)
  //parameters: panelId - unique panel identifier
  //purpose:
  //returns:    -
  this.SetPanelZIndex = function(panelId, zIndex)
  {
    var panel = this.GetPanel(panelId);

    if (panel != null && panel.ZIndex != zIndex)
    {
      panel.ZIndex = zIndex;

      var panelObj = this.GetPanelObj(panelId);
      if (panelObj)
        panelObj.SetZIndex(panel.ZIndex);

      this.TriggerChangedEvent("Panel zIndex changed: " + panelId);
    }
  }

  //removers
  //function:   this.ClosePanel(panelId)
  //parameters: panelId - unique panel identifier
  //purpose:
  //returns:    -
  this.ClosePanel = function(panelId)
  {
    this.RemovePanel(panelId);
  }

  //function:   this.RemovePanel(panelId)
  //parameters: panelId - unique panel identifier
  //purpose:
  //returns:    -
  this.RemovePanel = function(panelId)
  {
    if (this.Panels[panelId] != undefined)
    {
      this.RemoveMainPanel(panelId);
    }
    else
    {
      for (var key in this.Panels)
      {
        if (this.Panels[key] != undefined && this.Panels[key].Panels[panelId] != undefined)
        {
          delete this.RemoveSubPanel(key, panelId);
          break;
        }
      }
    }
  }

  //function:   this.RemoveMainPanel(panelId)
  //parameters: panelId - unique panel identifier
  //purpose:
  //returns:    -
  this.RemoveMainPanel = function(panelId)
  {
    var panel = this.Panels[panelId];

    for (var subPanelId in panel.Panels)
    {
      this.RemoveSubPanel(panelId, subPanelId);
    }

    delete this.Panels[panelId];

    this.RemovePanelId(panelId);
    this.RemoveSearchPanelTitle(panel.Title);

    this.RemovePanelObj(panelId);

    this.TriggerChangedEvent("");
  }

  //function:   this.RemoveSubPanel(parentId, panelId, triggerEvent)
  //parameters: -
  //purpose:
  //returns:    -
  this.RemoveSubPanel = function(parentId, panelId, triggerEvent)
  {
    delete this.Panels[parentId].Panels[panelId];

    this.RemovePanelId(panelId);

    this.RemovePanelObj(panelId);

    this.TriggerChangedEvent("");
  }

  //function:   this.RemoveAllPanels()
  //parameters: -
  //purpose:
  //returns:    -
  this.RemoveAllPanels = function()
  {
    for (var panelId in this.Panels)
      this.RemoveMainPanel(panelId);
  }

  //helpers
  //function:   this.GetNewMainPanelObject(panelId, position, url, title, zIndex)
  //parameters: panelId - unique panel identifier
  //purpose:
  //returns:    -
  this.GetNewMainPanelObject = function(panelId, position, url, title, zIndex)
  {
    var obj = new Object();
    obj["Id"] = panelId;
    obj["Title"] = title;
    obj["Position"] = position;
    obj["Panels"] = new Array();
    obj["Url"] = url;
    obj["ZIndex"] = zIndex;

    return obj;
  }

  //function:   this.GetNewPanelObject(panelId, type, pinned, position, url, title, zIndex)
  //parameters: panelId - unique panel identifier
  //purpose:
  //returns:    -
  this.GetNewPanelObject = function(panelId, type, pinned, position, url, title, zIndex)
  {
    var obj = new Object();
    obj["Id"] = panelId;
    obj["Title"] = title;
    obj["Type"] = type;

    if (!pinned)
      pinned = false;

    obj["Pinned"] = pinned;
    obj["Position"] = position;
    obj["Url"] = url;
    obj["ZIndex"] = zIndex;

    return obj;
  }

  //function:   this.GetNewPanelId()
  //parameters: -
  //purpose:
  //returns:    -
  this.GetNewPanelId = function()
  {
    var i = 1;

    while (this.UsedPanels.indexOf('panel' + i) != -1)
    {
      i++;
    }

    return 'panel' + i;
  }

  //function:   this.GetNewSearchPanelTitle()
  //parameters: -
  //purpose:
  //returns:    -
  this.GetNewSearchPanelTitle = function()
  {
    var i = 1;

    while (this.UsedSearchPanelTitles.indexOf('Search ' + i) != -1)
    {
      i++;
    }

    return 'Search ' + i;
  }

  //function:   this.AddPanelId(panelId)
  //parameters: panelId - unique panel identifier
  //purpose:
  //returns:    -
  this.AddPanelId = function(panelId)
  {
    this.UsedPanels.push(panelId);
  }

  //function:   this.AddSearchPanelTitle(title)
  //parameters: -
  //purpose:
  //returns:    -
  this.AddSearchPanelTitle = function(title)
  {
    this.UsedSearchPanelTitles.push(title);
  }

  //function:   this.RemovePanelId(panelId)
  //parameters: panelId - unique panel identifier
  //purpose:
  //returns:    -
  this.RemovePanelId = function(panelId)
  {
    var idx = this.UsedPanels.indexOf(panelId);
    if (idx == -1) return;

    delete this.UsedPanels[idx];
  }

  //function:   this.RemoveSearchPanelTitle(title)
  //parameters: -
  //purpose:
  //returns:    -
  this.RemoveSearchPanelTitle = function(title)
  {
    var idx = this.UsedSearchPanelTitles.indexOf(title);
    if (idx == -1) return;

    delete this.UsedSearchPanelTitles[idx];
  }

  //function:   this.RefreshUsedPanels()
  //parameters: -
  //purpose:
  //returns:    -
  this.RefreshUsedPanels = function()
  {
    this.UsedPanels.length = 0;

    for (var key in this.Panels)
    {
      var panel = this.Panels[key];
      this.AddPanelId(key);

      for (var subKey in panel.Panels)
      {
        this.AddPanelId(subKey);
      }
    }
  }

  //function:   this.RefreshUsedSearchPanelTitles()
  //parameters: -
  //purpose:
  //returns:    -
  this.RefreshUsedSearchPanelTitles = function()
  {
    this.UsedSearchPanelTitles.length = 0;

    for (var key in this.Panels)
    {
      var panel = this.Panels[key];
      this.AddSearchPanelTitle(panel.Title);
    }
  }

  //function:   this.ExistsMainPanel(panelId)
  //parameters: panelId - unique panel identifier
  //purpose:
  //returns:    -
  this.ExistsMainPanel = function(panelId)
  {
    var main = this.Panels[panelId];

    return (main != undefined);
  }

  //function:   this.IsSubPanel(panelId)
  //parameters: panelId - unique panel identifier
  //purpose:
  //returns:    -
  this.IsSubPanel = function(panelId)
  {
    var panel = this.GetSubPanel("", panelId);

    return panel != null;
  }

  //function:   this.IsPinned(panelId)
  //parameters: panelId - unique panel identifier
  //purpose:
  //returns:    -
  this.IsPinned = function(panelId)
  {
    var panel = this.GetSubPanel("", panelId);

    if (panel == null) return false;
    return panel.Pinned;
  }

  //function:   this.NormalizePanel(panelId)
  //parameters: panelId - unique panel identifier
  //purpose:
  //returns:    -
  this.NormalizePanel = function(panelId)
  {
    var position = this.GetPanelPosition(panelId);

    var panelObj = this.GetPanelObj(panelId);
    if (panelObj)
    {
      var maxZidx = this.GetMaxZIndex() + 1;
      panelObj.Normalize(position, maxZidx);
    }
  }

  //function:   this.MaximizePanel(panelId)
  //parameters: panelId - unique panel identifier
  //purpose:
  //returns:    -
  this.MaximizePanel = function(panelId)
  {
    var wid = $("#mainpanel").width();
    var hgt = $("#mainpanel").height();

    var position = new Object();
    position["Left"] = "5px";
    position["Top"] = "0px";
    position["Width"] = wid - 30 + "px";
    position["Height"] = hgt - 25 + "px";

    var panelObj = this.GetPanelObj(panelId);
    if (panelObj)
    {
      var maxZidx = this.GetMaxZIndex() + 1;
      panelObj.Maximize(position, maxZidx);
    }
  }

  //function:   this.GetMinZIndex()
  //parameters: -
  //purpose:
  //returns:    -
  this.GetMinZIndex = function()
  {
    var minZidx = Math.pow(2, 32) - 1;

    for (var key in this.Panels)
    {
      var panel = this.Panels[key];

      var zIdx1 = parseInt(panel.ZIndex);
      if (zIdx1 < minZidx)
        minZidx = zIdx1;

      for (var subKey in panel.Panels)
      {
        var subPanel = panel.Panels[subKey];
        var zIdx2 = parseInt(subPanel.ZIndex);
        if (zIdx2 < minZidx)
          minZidx = zIdx2;
      }
    }

    return minZidx;
  }

  //function:   this.GetMaxZIndex()
  //parameters: -
  //purpose:
  //returns:    -
  this.GetMaxZIndex = function()
  {
    this.LowerZIndex();

    var maxZidx = 0;

    for (var key in this.Panels)
    {
      var panel = this.Panels[key];

      var zIdx1 = parseInt(panel.ZIndex);
      if (zIdx1 > maxZidx)
        maxZidx = zIdx1;

      for (var subKey in panel.Panels)
      {
        var subPanel = panel.Panels[subKey];
        var zIdx2 = parseInt(subPanel.ZIndex);
        if (zIdx2 > maxZidx)
          maxZidx = zIdx2;
      }
    }

    return maxZidx;
  }

  //function:   this.LowerZIndex()
  //parameters: -
  //purpose:
  //returns:    -
  this.LowerZIndex = function()
  {
    var minZidx = this.GetMinZIndex();
    if (minZidx > 1)
    {
      var diff = minZidx - 1;

      for (var key in this.Panels)
      {
        var panel = this.Panels[key];

        var zIdx1 = parseInt(panel.ZIndex);
        var newZIdx1 = zIdx1 - diff;

        this.SetPanelZIndex(key, newZIdx1);

        for (var subKey in panel.Panels)
        {
          var subPanel = panel.Panels[subKey];

          var zIdx2 = parseInt(subPanel.ZIndex);
          var newZIdx2 = zIdx2 - diff;

          this.SetPanelZIndex(subKey, newZIdx2);
        }
      }
    }
  }

  //function:   this.BringToFront(panelId)
  //parameters: panelId - unique panel identifier
  //purpose:
  //returns:    -
  this.BringToFront = function(panelId)
  {
    var maxZidx = this.GetMaxZIndex() + 1;
    this.SetPanelZIndex(panelId, maxZidx);

    var panelObj = this.GetPanelObj(panelId);

    if (panelObj)
      panelObj.SetZIndex(maxZidx);
  }

  //function:   this.OpenNewSearchPanel(config)
  //parameters: -
  //purpose:
  //returns:    -
  this.OpenNewSearchPanel = function(config)
  {
    var panelName = this.GetNewPanelId();
    var panelCount = this.Panels.length;

    var position = new Object();
    position["Left"] = 200 + 20*panelCount + "px";
    position["Top"] = 10 + 20*panelCount +  "px";
    position["Width"] = "525px";
    position["Height"] = "600px";

    var maxZidx = this.GetMaxZIndex() + 1;
    var panelTitle = this.GetNewSearchPanelTitle();

    if (isNaN(config))
      config = this.GetSearchIdx(config);

    var newPanel = new Panel(panelName, "search", panelTitle, "", position, false, maxZidx, this.Container, this, config);
    newPanel.CreatePanel();

    this.PanelObjects[panelName] = newPanel;
    this.AddMainPanel(panelName, position, undefined, panelTitle, maxZidx + 1);
  }

  //function:   this.CreateNewSearchPanelObj(panelObj)
  //parameters: -
  //purpose:
  //returns:    -
  this.CreateNewSearchPanelObj = function(panelObj)
  {
    if (panelObj == undefined) return;

    var maxZidx = this.GetMaxZIndex() + 1;
    var newPanel = new Panel(panelObj.Id, "search", panelObj.Title, panelObj.Url, panelObj.Position, false, maxZidx ,this.Container, this, 0);
    newPanel.CreatePanel();

    this.PanelObjects[panelObj.Id] = newPanel;
  }

  //function:   this.OpenSubPanel(elem, url, pinned, type)
  //parameters: -
  //purpose:
  //returns:    -
  this.OpenSubPanel = function(elem, url, pinned, type)
  {
    var paneldiv = $(elem).parents(".draggable");
    var parentId = $(paneldiv).attr('id');

    var panel;

    if (type == "image")
    {
      panel = this.GetPinnedImagePanelId(parentId);
      url = url.replace(/xml/g, "jpg");
    }
    else if (type == "text")
      panel = this.GetPinnedTextPanelId(parentId);

    if (panel == null)
    {
      var panelId = this.GetNewPanelId();

      var wid = $(paneldiv).width();
      var lef = parseInt($(paneldiv).css("left").replace(/px/g, ""));

      var position = new Object();
      position["Left"] = lef + wid + 15 + "px";
      position["Top"] = $(paneldiv).css("top");
      position["Width"] = "350px";
      position["Height"] = $(paneldiv).css("height");

      var panelTitle = "";

      if (type == "image")
        panelTitle = "Facsimile";
      else if (type == "text")
        panelTitle = "Full text";

      var maxZidx = this.GetMaxZIndex() + 1;

      //function Panel(id, type, title, url, position, pinned, zIndex, container, panelController, config)

      var newPanel = new Panel(panelId, type, panelTitle, url, position, pinned, maxZidx, this.Container, this, undefined);
      newPanel.CreatePanel();

      if (type == "image")
        this.AddImagePanel(parentId, panelId, pinned, position, url, panelTitle, maxZidx);
      else if (type == "text")
        this.AddTextPanel(parentId, panelId, pinned, position, url, panelTitle, maxZidx);

      this.PanelObjects[panelId] = newPanel;
    }
    else
    {
      var newPanel = $('#' + panel);
      this.SetPanelUrl(panel, url);

      var panelObj = this.GetPanelObj(panel);
      if (panelObj != undefined)
      {
        panelObj.SetUrl(url);

        if (type == "image")
          panelObj.GetFacsimile();
        else if (type == "text")
          panelObj.GetFullText();

        panelObj.InitDraggable(newPanel);
      }
    }
  }

  //function:   this.CreateNewSubPanelObj(panelObj)
  //parameters: -
  //purpose:
  //returns:    -
  this.CreateNewSubPanelObj = function(panelObj)
  {
    if (panelObj == undefined) return;

    var newPanel = new Panel(panelObj.Id, panelObj.Type, panelObj.Title, panelObj.Url, panelObj.Position, panelObj.Pinned, panelObj.ZIndex ,this.Container, this, 0);
    newPanel.CreatePanel();
    this.PanelObjects[panelObj.Id] = newPanel;
  }

  //panelobject methods
  //function:   this.GetPanelObj(panelId)
  //parameters: panelId - unique panel identifier
  //purpose:
  //returns:    -
  this.GetPanelObj = function(panelId)
  {
    return this.PanelObjects[panelId];
  }

  //function:   this.RemovePanelObj(panelId)
  //parameters: panelId - unique panel identifier
  //purpose:
  //returns:    -
  this.RemovePanelObj = function(panelId)
  {
    var panelObj = this.GetPanelObj(panelId);
    if (panelObj != undefined)
    {
      panelObj.Close();
      delete this.PanelObjects[panelId];
    }
  }

  //function:   this.UpdatePanelPosition(panelId)
  //parameters: panelId - unique panel identifier
  //purpose:
  //returns:    -
  this.UpdatePanelPosition = function(panelId)
  {
    var panelObj = this.GetPanelObj(panelId);

    if (panelObj)
     {
       panelObj.UpdatePosition();
       var position = panelObj.Position;
       this.SetPanelPosition(panelId, position);
     }
  }

  //function:   this.StartSearch(panelId)
  //parameters: panelId - unique panel identifier
  //purpose:
  //returns:    -
  this.StartSearch = function(panelId)
  {
    var panel = this.GetPanelObj(panelId);

    if (panel != undefined)
    {
      var url = panel.StartSearch();
      this.SetPanelUrl(panelId, url);
    }
  }

  //SearchConfig methods

  //function:   this.GetSearchIdx(xContext)
  //parameters: -
  //purpose:
  //returns:    -
  this.GetSearchIdx = function(xContext)
  {
    for (var idx = 0; idx < this.SearchConfig.length; idx++)
    {
      if (this.SearchConfig[idx]['x-context'] == xContext)
        return idx;
    }
    return 0;
  }

  //function:   this.GetResourceName(idx)
  //parameters: -
  //purpose:
  //returns:    -
  this.GetResourceName = function(idx)
  {
    return this.SearchConfig[idx]["x-context"];
  }

  //function:   this.LoadProfile(name, panels)
  //parameters: -
  //purpose:
  //returns:    -
  this.LoadProfile = function(name, panels)
  {
    this.RemoveAllPanels();
    this.Panels = panels;
    this.ProfileName = name;

    for (var key in this.Panels)
    {
      var panel = this.Panels[key];
      this.CreateNewSearchPanelObj(panel);
      if (panel.Url != undefined && panel.Url != "")
      {
        var panelObj = this.GetPanelObj(panel.Id);
        if (panelObj != undefined)
          panelObj.StartSearch();
      }

      for (var subKey in panel.Panels)
      {
        var subPanel = panel.Panels[subKey];
        this.CreateNewSubPanelObj(subPanel);
      }
    }
    this.RefreshUsedPanels();
    this.RefreshUsedSearchPanelTitles();
  }
}

var PanelController = new PanelManager("#snaptarget", SearchConfig);