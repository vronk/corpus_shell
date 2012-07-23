function PanelManager ()
{
  this.Panels = new Array();
  this.ProfileName = "default";
  this.UsedPanels = new Array();

  //events
  this.onUpdated = null;

  this.TriggerChangedEvent = function (change)
  {
    if (typeof this.onUpdated == "function")
      this.onUpdated(change);
  }

  //adders

  this.AddMainPanel = function(panelId, position, url, title, zIndex)
  {
    this.Panels[panelId] = this.GetNewMainPanelObject(panelId, position, url, title, zIndex);
    this.AddPanelId(panelId);
    this.TriggerChangedEvent("Mainpanel added: " + panelId);
  }

  this.AddImagePanel = function(parentId, panelId, pinned, position, url, title, zIndex)
  {
    this.AddSubPanel(parentId, panelId, pinned, position, url, title, zIndex, "image");
  }

  this.AddTextPanel = function(parentId, panelId, pinned, position, url, title, zIndex)
  {
    this.AddSubPanel(parentId, panelId, pinned, position, url, title, zIndex, "text");
  }

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


  //gets or adds main panel
  this.GetMainPanel = function(parentId)
  {
    var main = this.Panels[parentId];

    if (main == undefined)
    {
      this.AddMainPanel(parentId);
      main = this.Panels[parentId];
    }

    return main;
  }

  //gets subpanel, if it doesn't exist, returns null
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

  this.GetPanel = function(panelId)
  {
    var panel = null;

    if (this.ExistsMainPanel(panelId) == true)
      panel = this.Panels[panelId];

    if (panel == null)
      panel = this.GetSubPanel("", panelId);

    return panel;
  }

  this.GetPinnedImagePanel = function(parentId)
  {
    return this.GetPinnedPanel(parentId, "image");
  }

  this.GetPinnedImagePanelId = function(parentId)
  {
    return this.GetPinnedPanelId(parentId, "image");
  }

  this.GetPinnedTextPanel = function(parentId)
  {
    return this.GetPinnedPanel(parentId, "text");
  }

  this.GetPinnedTextPanelId = function(parentId)
  {
    return this.GetPinnedPanelId(parentId, "text");
  }

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

  this.GetPanelPosition = function(panelId)
  {
    var panel = this.GetPanel(panelId);

    if (panel != null)
      return panel.Position;
    else
      return null;
  }

  this.GetPanelUrl = function(panelId)
  {
    var panel = this.GetPanel(panelId);

    if (panel != null)
      return panel.Url;
    else
      return null;
  }

  //setters

  this.SetPanelPinned = function(panelId)
  {
    this.SetPanelPinnedState(panelId, true);
  }

  this.SetPanelNotPinned = function(panelId)
  {
    this.SetPanelPinnedState(panelId, false);
  }

  this.SetPanelPinnedState = function(panelId, pinned)
  {
    var panel = this.GetSubPanel("", panelId);

    if (panel != null && panel.Pinned != pinned)
    {
      panel.Pinned = pinned;
      this.TriggerChangedEvent("Panel pinned state changed: " + panelId);
    }
  }

  this.SetPanelPosition = function(panelId, position)
  {
    var panel = this.GetPanel(panelId);

    if (panel != null && panel.Position != position)
    {
      panel.Position = position;
      this.TriggerChangedEvent("Panel position changed: " + panelId);
    }
  }

  this.SetPanelUrl = function(panelId, url)
  {
    var panel = this.GetPanel(panelId);

    if (panel != null && panel.Url != url)
    {
      panel.Url = url;
      this.TriggerChangedEvent("Panel url changed: " + panelId);
    }
  }

  this.SetPanelZIndex = function(panelId, zIndex)
  {
    var panel = this.GetPanel(panelId);

    if (panel != null && panel.ZIndex != zIndex)
    {
      panel.ZIndex = zIndex;
      this.TriggerChangedEvent("Panel zIndex changed: " + panelId);
    }
  }

  //removers

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

  this.RemoveMainPanel = function(panelId)
  {
    delete this.Panels[panelId];
    this.RemovePanelId(panelId);
    this.TriggerChangedEvent("");
  }

  this.RemoveSubPanel = function(parentId, panelId, triggerEvent)
  {
    delete this.Panels[parentId].Panels[panelId];
    this.RemovePanelId(panelId);
    this.TriggerChangedEvent("");
  }

  this.RemoveAllPanels = function()
  {
    for (var panelId in this.Panels)
      this.RemoveMainPanel(panelId);
  }

  //helpers
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

  this.GetNewPanelId = function()
  {
    var i = 1;

    while (this.UsedPanels.indexOf('panel' + i) != -1)
    {
      i++;
    }

    return 'panel' + i;
  }

  this.AddPanelId = function(panelId)
  {
    this.UsedPanels.push(panelId);
  }

  this.RemovePanelId = function(panelId)
  {
    var idx = this.UsedPanels.indexOf(panelId);
    if (idx == -1) return;

    delete this.UsedPanels[idx];
  }

  this.RefreshUsedPanels = function()
  {
    this.UsedPanels.length = 0;

    for (var key in this.Panels)
    {
      var panel = PanelController.Panels[key];
      this.AddPanelId(key);

      for (var subKey in panel.Panels)
      {
        this.AddPanelId(subKey);
      }
    }
  }

  this.ExistsMainPanel = function(panelId)
  {
    var main = this.Panels[panelId];

    return (main != undefined);
  }

  this.IsSubPanel = function(panelId)
  {
    var panel = this.GetSubPanel("", panelId);

    return panel != null;
  }


  this.IsPinned = function(panelId)
  {
    var panel = this.GetSubPanel("", panelId);

    if (panel == null) return false;
    return panel.Pinned;
  }
}

var PanelController = new PanelManager();