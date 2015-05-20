/**
 * @fileOverview Provides tha PanelManager class and the global PanelController object. <br/>
 * Entry point from index.html is {@link module:corpus_shell~PanelManager#OpenNewSearchPanel} <br/>
 * Entry point from corpusshell.js is {@link module:corpus_shell~PanelManager#OpenSubPanel} which
 * is automatically attached to a set of links to replace their default behaviour. See {@link module:corpus_shell~doOnDocumentReady}<br/>
 * Currently the target of all operations is the id selector of "#snaptarget" -> {@link module:corpus_shell~PanelController}</br>
 * last change:  2012.10.02
 * @author      Andy Basch
 * 
 */

/**
 * @module corpus_shell 
 */

/**
 * The controller object managing all the panels. Currently the target for
 * its operation is an id selector of #snaptarget
 */ 
var PanelController;
// Everything here assumes $ === jQuery so ensure this
!function ($, SearchConfig, params) {

/**
 * Creates a PanelManager.
 * @constructor
 * @param container {string} A jQuery selector which selects the part of the page
 *                           the panels appear in.
 * @param searchConfig {array.<SearchConfigItem>} An array of x-context, DisplayText maps -> {@link module:corpus_shell~SearchConfig}
 * @classdesc purpose:      handles the panel management in corpus_shell
 *
 * @requires corpus_shell~Panel
 * @requires jQuery
 *
 */
var PanelManager = function (container, searchConfig)
{
  /**  
   * @public
   * @type {string}
   * @desc A jQuery selector which selects the part of the page the panels appear in 
   */
  this.Container = container;
  /** 
   * @public
   * @type {array.<SearchConfigItem>}
   */
  this.SearchConfig = searchConfig;

  /**
   * @protected
   * @type {map.<MainPanelObject>} 
   * @desc A "map" (that is an object with ever extending dynamic properties) of parent/main panels created accessible by their unique id.
   */
  this.Panels = [];
  /** @protected */
  this.ProfileName = "default";
  /** 
   * @protected
   * @type {array.<string>}
   * @desc Array of all panel ids currently in use.
   */
  this.UsedPanels = [];
  /**
   * @protected
   * @type {array.<string>}
   * @desc array of all search panel titles currently in use. 
   */
  this.UsedSearchPanelTitles = [];
  /** 
   * @protected
   * @type {map.<module:corpus_shell~Panel>}
   * @desc A "map" (that is an object with ever extending dynamic properties) of panels accessible by their unique id.
   */
  this.PanelObjects = [];

  /** @event */
  this.onUpdated = null;

  /**
   * Calls onUpdate if set. 
   * @protected
   */
  this.TriggerChangedEvent = function (change)
  {
    if (typeof this.onUpdated === "function")
      this.onUpdated(change);
  };

  /* methods */


  //adders

  /**
   * @param {string} panelId A unique panel identifier.
   * @param {string} type The type of pannel for which a main panel should be added.
   * @param {Position} position The postion of the panel.
   * @param {url} url A URL, may be undefined.
   * @param {string} title The intelligable title of the main panel.
   * @param {number} zIndex The height of the main panel object to be added.
   * @desc
   * <ol>
   * <li>Creates a new {@link MainPanelObject} using the given parameters. -> {@link module:corpus_shell~PanelManager#GetNewMainPanelObject}</li>
   * <li>Add this panel to the "map" of main panels. -> {@link module:corpus_shell~PanelManager#Panels}</li>
   * <li>Add the panel id to the list of currently used panels (panel ids). -> {@link module:corpus_shell~PanelManager#AddPanelId}</li>
   * <li>Add the panel title to the list of currently used search panel titles. -> {@link module:corpus_shell~PanelManager#AddSearchPanelTitle}</li>
   * </ol>
   * @summary purpose:    adds a parent/main panel to the list of panels.
   * @fires module:corpus_shell~PanelManager#event:onUpdated
   * @return    -
   */
  this.AddMainPanel = function(panelId, type, position, url, title, zIndex)
  {
    this.Panels[panelId] = this.GetNewMainPanelObject(panelId, type, position, url, title, zIndex);
    this.AddPanelId(panelId);
    this.AddSearchPanelTitle(title);
    this.TriggerChangedEvent("Mainpanel added: " + panelId);
  };

  /**
   * purpose:    adds an image panel to the list of panels (this.Panels[parentId].Panels)
   * @see Panel.Panels
   * @param parentId
   * @param panelId unique panel identifier
   * @param pinned
   * @param position
   * @param url
   * @param title
   * @param zIndex
   * @return    -
   */
  this.AddImagePanel = function(parentId, panelId, pinned, position, url, title, zIndex)
  {
    this.AddSubPanel(parentId, panelId, pinned, position, url, title, zIndex, "image");
  };

  /**
   * purpose:    adds a text panel to the list of panels (this.Panels[parentId].Panels)
   * @see Panel.Panels
   * @param parentId
   * @param panelId unique panel identifier
   * @param pinned
   * @param position
   * @param url
   * @param title
   * @param zIndex
   * @return    -
   */
  this.AddTextPanel = function(parentId, panelId, pinned, position, url, title, zIndex)
  {
    this.AddSubPanel(parentId, panelId, pinned, position, url, title, zIndex, "text");
  };

  /**
   * purpose:    adds a subpanel to the list of panels (this.Panels[parentId].Panels)
   * @see Panel.Panels
   * @param parentId
   * @param panelId unique panel identifier
   * @param pinned
   * @param position
   * @param url
   * @param title
   * @param zIndex
   * @param type
   * @return    -
   * @protected
   */
  this.AddSubPanel = function(parentId, panelId, pinned, position, url, title, zIndex, type)
  {
    var parent = null;

    if (this.IsSubPanel(parentId))
      parent = this.GetMainFromSubPanel(parentId);
    else
      parent = this.GetMainPanel(parentId);

    if (parent !== undefined && parent !== null)
    {
      parent.Panels[panelId] = this.GetNewPanelObject(panelId, type, pinned, position, url, title, zIndex);
      this.AddPanelId(panelId);

      var ucFirst =  type.charAt(0).toUpperCase() + type.substr(1);
      var message = ucFirst + "Panel added: " + panelId;

      this.TriggerChangedEvent(message);
    }
  };

  //getters

  /**
   * purpose:    gets or adds main panel
   * @param panelId - unique panel identifier
   * @return - 
   */
  this.GetMainPanel = function(panelId)
  {
    var main = this.Panels[panelId];

    if (main === undefined)
    {
      this.AddMainPanel(panelId);
      main = this.Panels[panelId];
    }

    return main;
  };

  /**
   * gets subpanel, if it doesn't exist, returns null
   * purpose:    searches for subpanel by panelId
   * @param parentId
   * @param panelId - unique panel identifier
   * @return    if found, returns the panel else null 
   */
  this.GetSubPanel = function(parentId, panelId)
  {
    if (parentId !== "")
    {
      var subPanel = this.Panels[parentId].Panels[panelId];
      return subPanel === undefined ? null : subPanel;
    }
    else
    {
      for (var key in this.Panels)
      {
        var subPanel = this.Panels[key].Panels[panelId];
        if (subPanel !== undefined)
          return subPanel;
      }

      return null;
    }
  };

  /**
   * purpose:    searches for the corresponding parent panel to a given
   *             panelId of a subpanel
   * @param panelId - unique panel identifier
   * @return    if found, returns the panel else null
   */
  this.GetMainFromSubPanel = function(panelId)
  {
     for (var key in this.Panels)
     {
       var subPanel = this.Panels[key].Panels[panelId];
       if (subPanel !== undefined)
         return this.Panels[key];
     }

     return null;
  };

  /**
   * purpose:    searches for the corresponding parent panelId to a given
   *             panelId of a subpanel
   * @param panelId - unique panel identifier
   * @return    if found, returns the parent panelId else null
   */
  this.GetMainIdFromSubPanel = function(panelId)
  {
     for (var key in this.Panels)
     {
       var subPanel = this.Panels[key].Panels[panelId];
       if (subPanel != undefined)
         return key;
     }

     return null;
  };

  /**
   * purpose:    searches for a panel without knowing wether it is a main or a
   *             sub panel
   * @param panelId - unique panel identifier
   * @return    if found, returns the panel else null
   */
  this.GetPanel = function(panelId)
  {
    var panel = null;

    if (this.ExistsMainPanel(panelId) == true)
      panel = this.Panels[panelId];

    if (panel == null)
      panel = this.GetSubPanel("", panelId);

    return panel;
  };

  /**
   * purpose:
   * @param panelId - unique panel identifier
   * @return    sth. if found or else null
   */
  this.GetPinnedImagePanel = function(parentId)
  {
    return this.GetPinnedPanel(parentId, "image");
  };

  /**
   * purpose:
   * @param panelId - unique panel identifier
   * @return    sth. if found or else null
   */
  this.GetPinnedImagePanelId = function(parentId)
  {
    return this.GetPinnedPanelId(parentId, "image");
  };

  /**
   * purpose:
   * @param panelId - unique panel identifier
   * @return    sth. or else null
   */
  this.GetPinnedTextPanel = function(parentId)
  {
    return this.GetPinnedPanel(parentId, "text");
  };

  /**
   * purpose:
   * @param panelId - unique panel identifier
   * @return    sth. if found or else null
   */
  this.GetPinnedTextPanelId = function(parentId)
  {
    return this.GetPinnedPanelId(parentId, "text");
  };

  /**
   * purpose:
   * @protected
   * @param panelId - unique panel identifier
   * @return  sth. if found or else null
   */
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
  };

  /**
   * purpose:
   * @protected
   * @param panelId - unique panel identifier
   * @return    sth. if found or else null
   */
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
  };

  /**
   * purpose:
   * @param panelId - unique panel identifier
   * @return    sth. if found or else null
   */
  this.GetPanelPosition = function(panelId)
  {
    var panel = this.GetPanel(panelId);

    if (panel != null)
      return panel.Position;
    else
      return null;
  };

  /**
   * purpose:
   * @param panelId - unique panel identifier
   * @return    sth. if found or else null
   */
  this.GetPanelUrl = function(panelId)
  {
    var panel = this.GetPanel(panelId);

    if (panel != null)
      return panel.Url;
    else
      return null;
  };

  /**
   * purpose:
   * @param elem
   * @return    sth.
   */
  this.GetPanelDivFromElement = function(elem)
  {
    return $(titlep).parents(".draggable");
  };

  /**
   * purpose:
   * @param panelId - unique panel identifier
   * @return    -
   */
  this.InitScrollPane = function(panelId)
  {
    var panelObj = this.GetPanelObj(panelId);
    if (panelObj)
      panelObj.InitScrollPane();
  };

  /**
   * purpose:
   * @param panelId - unique panel identifier
   * @return    -
   */
  this.RefreshScrollPane = function(panelId)
  {
    var panelObj = this.GetPanelObj(panelId);
    if (panelObj)
      panelObj.RefreshScrollPane();
  }

  //setters

  /**
   * purpose:
   * @param panelId - unique panel identifier
   * @param col
   * @return    -
   */
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

  /**
   * purpose: Sets the pinned state of the specified panel.
   * @param panelId - unique panel identifier
   * @return    -
   */
  this.SetPanelPinned = function(panelId)
  {
    this.SetPanelPinnedState(panelId, true);
  }

  /**
  * purpose: Clears the pinned state of the specified panel.
  * @param panelId - unique panel identifier
  * @return    -
  */
  this.SetPanelNotPinned = function(panelId)
  {
    this.SetPanelPinnedState(panelId, false);
  }

  /**
  * purpose: Sets the pinned state of the specified panel according to pinned.
  * @param panelId - unique panel identifier
  * @param pinned {boolean} State to be set.
  * @return    -
  */
  this.SetPanelPinnedState = function(panelId, pinned)
  {
    var panel = this.GetSubPanel("", panelId);

    if (panel != null && panel.Pinned != pinned)
    {
      panel.Pinned = pinned;
      this.TriggerChangedEvent("Panel pinned state changed: " + panelId);
    }
  }

  /**
  * @param panelId - unique panel identifier
  * purpose:
  * @return    -
  */
  this.SetPanelPosition = function(panelId, position)
  {
    var panel = this.GetPanel(panelId);
    
    if (panel.Maximized) {return;}
    
    if (panel !== null && 
        (panel.Position.Top !== position.Top ||
        panel.Position.Left !== position.Left ||
        panel.Position.Width !== position.Width ||
        panel.Position.Height !== position.Height))
    {
      panel.Position = position;
      this.TriggerChangedEvent("Panel position changed: " + panelId);
    }
  }

  /**
  * @param {string} panelId Unique panel identifier
  * @param {url} url A URL to store.
  * @desc purpose: Updates a panel's url.
  * @fires module:corpus_shell~PanelManager#event:onUpdated
  * @return    -
  */
  this.SetPanelUrl = function(panelId, url)
  {
    var panel = this.GetPanel(panelId);

    if (panel != null && panel.Url != url)
    {
      panel.Url = url;
      this.TriggerChangedEvent("Panel url changed: " + panelId);
    }
  }

  /**
  * @param panelId - unique panel identifier
  * purpose:
  * @return    -
  */
  this.SetPanelZIndex = function(panelId, zIndex)
  {
    var panel = this.GetPanel(panelId);

    if (panel !== null && panel.ZIndex !== zIndex)
    {
      panel.ZIndex = zIndex;

      var panelObj = this.GetPanelObj(panelId);
      if (panelObj)
        panelObj.SetZIndex(panel.ZIndex);

      this.TriggerChangedEvent("Panel zIndex changed: " + panelId);
    }
  }

  //removers
  /**
  * @param panelId - unique panel identifier
  * purpose:
  * @return    -
  */
  this.ClosePanel = function(panelId)
  {
    this.RemovePanel(panelId);
  }

  /**
  * @param panelId - unique panel identifier
  * purpose:
  * @return    -
  */
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

  /**
  * @param panelId - unique panel identifier
  * purpose:
  * @return    -
  */
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

  /**
  * @param -
  * purpose:
  * @return    -
  */
  this.RemoveSubPanel = function(parentId, panelId, triggerEvent)
  {
    delete this.Panels[parentId].Panels[panelId];

    this.RemovePanelId(panelId);

    this.RemovePanelObj(panelId);

    this.TriggerChangedEvent("");
  }

  /**
  * @param -
  * purpose:
  * @return    -
  */
  this.RemoveAllPanels = function()
  {
    for (var panelId in this.Panels)
      this.RemoveMainPanel(panelId);
  }

  //helpers
  
  /**
   * @typedef {Object} MainPanelObject
   * @property {string} Id The unique panel id of this panel. Used as an id for an HTML element and
   * as a JavaScript objects property name.
   * @property {string} Title The title of the panel.
   * @property {string} Type The type of this panel.
   * @property {Position} Position The position of this panel
   * @property {array.<SubPanelObject>} Panels  All the sub panels within this panel.
   * @property {url} Url A URL describing ???
   * @property {number} ZIndex At which "heigh" this panel is on screen.
   */
  
  /** 
   * @private
   * @param panelId - unique panel identifier
   * @desc purpose: Constructong a {@link MainPanelObject}
   * @return {MainPanelObject}
   */
  this.GetNewMainPanelObject = function(panelId, type, position, url, title, zIndex)
  {
    var obj = new Object();
    obj["Id"] = panelId;
    obj["Title"] = title;
    obj["Type"] = type;
    obj["Position"] = position;
    obj["Panels"] = new Array();
    obj["Url"] = url;
    obj["ZIndex"] = zIndex;

    return obj;
  }

  /**
   * @typedef {Object} SubPanelObject
   * @property {string} Id The unique panel id of this panel. Used as an id for an HTML element and
   * as a JavaScript objects property name.
   * @property {string} Title The title of the panel.
   * @property {string} Type The type of this panel.
   * @property {boolean} Pinned If this panel is pinned down at the moment.
   * @property {Position} Position The position of this panel
   * @property {url} Url A URL describing ???
   * @property {number} ZIndex At which "heigh" this panel is on screen.
   */

  /**
   * @private
   * @param panelId - unique panel identifier
   * @desc purpose:	Constructing function of a {@link SubPanelObject}
   * @return    {SubPanelObject}
   */
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

  /**
  * @private
  * @desc purpose: Generate unique panel ids. <br/>
  * <em>Note: These have to be valid ids for an HTML element and JavaScript objects property names!</em>
  * @return {string} A dynamically generated unique panel id (that is panel + the next unused number = eg. panel815).
  */
  this.GetNewPanelId = function()
  {
    var i = 1;

    while (this.UsedPanels.indexOf('panel' + i) != -1)
    {
      i++;
    }

    return 'panel' + i;
  }

  /**
   * @private
   * @param titlePart {string} The first part of the title.
   * @desc purpose: Generate a title for a panel.
   * @return {string}
   */
  this.GetNewPanelTitle = function(titlePart)
  {
    var i = 1;

    while (this.UsedSearchPanelTitles.indexOf(titlePart + ' ' + i) != -1)
    {
      i++;
    }

    return titlePart + ' ' + i;
  }

  /**
  * @param {string} panelId A unique panel identifier.
  * purpose: Add a panel id to the array of used panels. -> {@link module:corpus_shell~PanelManager#UsedPanels}
  * @return    -
  */
  this.AddPanelId = function(panelId)
  {
    this.UsedPanels.push(panelId);
  }

  /**
  * @param {string} title Title to be added.
  * @desc purpose: add title to the array of currently used titles. -> {@link module:corpus_shell~PanelManager#UsedSearchPanelTitles}
  * @return    -
  */
  this.AddSearchPanelTitle = function(title)
  {
    this.UsedSearchPanelTitles.push(title);
  }

  /**
  * @param panelId - unique panel identifier
  * purpose:
  * @return    -
  */
  this.RemovePanelId = function(panelId)
  {
    var idx = this.UsedPanels.indexOf(panelId);
    if (idx == -1) return;

    delete this.UsedPanels[idx];
  }

  /**
  * @param -
  * purpose:
  * @return    -
  */
  this.RemoveSearchPanelTitle = function(title)
  {
    var idx = this.UsedSearchPanelTitles.indexOf(title);
    if (idx == -1) return;

    delete this.UsedSearchPanelTitles[idx];
  }

  /**
  * purpose: Updates the array of pannel ids.
  * @return    -
  */
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
  };

  /**
  * purpose: Updated the array of panel titles.
  * @return    -
  */
  this.RefreshUsedSearchPanelTitles = function()
  {
    this.UsedSearchPanelTitles.length = 0;

    for (var key in this.Panels)
    {
      var panel = this.Panels[key];
      this.AddSearchPanelTitle(panel.Title);
    }
  };
  
  /**
   * @typedef {Object} PanelDescription
   * @property {string} config Name of the x-context/config this should be from. URI encoded.
   * @property {string} panelType A panel type as in {@link module:corpus_shell~Panel#type}
   * @property {string] searchStr A query or a search clause (for scans). URI encoded.
   */
  
  /**
   * Datastructure holding the panels registerd by {@link module:corpus_shell~PanelManager#EnsureSearchPanelOpened}.
   * @type {array.<PanelDescription>}
   */
  this.EnsuredPanels = [];
  /**
   * Ensures that a search panel for this resource will be visible when the initialization is finished.
   * @public
   * @param {number|string} config The index of the {@link module:corpus_shell~SearchConfig} to use or <br/>
   *                        may be an internal resource name.
   * @param {string} [searchstr] The search string to execute in the new panel.
   */
  this.EnsureSearchPanelOpened = function(config, panelType, searchStr)
  {
  	 this.EnsuredPanels.push({config: decodeURIComponent(config), panelType: panelType, searchStr: decodeURIComponent(searchStr)});
  };
  
  /**
  * @param panelId - unique panel identifier
  * purpose:
  * @return    -
  */
  this.ExistsMainPanel = function(panelId)
  {
    var main = this.Panels[panelId];

    return (main != undefined);
  };

  /**
  * @param panelId - unique panel identifier
  * purpose:
  * @return    -
  */
  this.IsSubPanel = function(panelId)
  {
    var panel = this.GetSubPanel("", panelId);

    return panel != null;
  }

  /**
  * @param panelId - unique panel identifier
  * purpose:
  * @return    -
  */
  this.IsPinned = function(panelId)
  {
    var panel = this.GetSubPanel("", panelId);

    if (panel == null) return false;
    return panel.Pinned;
  }

  /**
  * @param panelId - unique panel identifier
  * purpose:
  * @return    -
  */
  this.NormalizePanel = function(panelId)
  {
    if (panelId === undefined) {return;}
    
    var panel = this.GetPanel(panelId);
    
    if (!panel.Maximized) {return;}
    
    var position = this.GetPanelPosition(panelId);
    
    panel.Maximized = false;

    var panelObj = this.GetPanelObj(panelId);
    if (panelObj)
    {
      var maxZidx = this.GetMaxZIndex() + 1;
      panelObj.Normalize(position, maxZidx);
      this.maximizedPanel = undefined;
      this.TriggerChangedEvent("Panel normal size: " + panelId);     
    }
  };

  this.maximizedPanel = undefined;
  
  /**
  * @param panelId - unique panel identifier
  * purpose:
  * @return    -
  */
  this.MaximizePanel = function(panelId)
  {
    var wid = $("#mainpanel").width();
    var hgt = $("#mainpanel").height();
    var panel = this.GetPanel(panelId);
    
    if (this.maximizedPanel !== undefined) {
        this.NormalizePanel(this.maximizedPanel);
    }
    
    panel.Maximized = true;

    var position = new Object();
    position["Left"] = "5px";
    position["Top"] = "0px";
    position["Width"] = wid - 30 + "px";
    position["Height"] = hgt - 25 + "px";

    var panelObj = this.GetPanelObj(panelId);
    if (panelObj)
    {
      var maxZidx = this.GetMaxZIndex();
      var curZidx = panelObj.ZIndex;
      var newZidx = curZidx < maxZidx ? maxZidx + 2 : curZidx;
      panelObj.Maximize(position, newZidx);
      panel.ZIndex = newZidx;
      this.maximizedPanel = panelObj.Id;
      this.TriggerChangedEvent("Panel maximized: " + panelId);
    }
  };

  /**
  * @param -
  * purpose:
  * @return    -
  */
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

  /**
  * purpose: Get the z index of the currently top most panel(s). Looks for main and sub panels.
  * @return {number}
  */
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
  };

  /**
  * @param -
  * purpose:
  * @return    -
  */
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

  /**
  * @param panelId - unique panel identifier
  * purpose:
  * @return    -
  */
  this.BringToFront = function(panelId)
  {
    var curMaxZidx = this.GetMaxZIndex();
    var panelObj = this.GetPanelObj(panelId);

    if (panelObj !== undefined && panelObj.ZIndex < curMaxZidx) {    
        var maxZidx = curMaxZidx + 2;
        this.SetPanelZIndex(panelId, maxZidx);
        panelObj.SetZIndex(maxZidx);
    }
  };

  /**
   * Get the positon for a newly created panel.
   * @returns {Position} The postion for a newly created panel usind a cascading
   * effect.
   */
  this.GetInitialPosition = function () {
    var panelCount = this.GetPanelCount();
    var position = new Object();
    position["Left"] = defaultLeftOffset + 20*panelCount + "px";
    position["Top"] = defaultTopOffset + 20*panelCount +  "px";
    position["Width"] = defaultWidth;
    position["Height"] = defaultHeight;
    return position;
  };
  
  /**
   * @public
   * @param {number|string} config The index of the {@link module:corpus_shell~SearchConfig} to use or <br/>
   *                        may be an internal resource name.
   * @param {string} [searchstr] The search string to execute in the new panel. <br/>
   *                             This may be an incomplete statement e.g. if this is called from
   *                             HTML generated by {@link module:corpus_shell~ResourceManager#GetIndexCache}
   * @param {string} [dataview] A comma separated list of dataviews to request from the switch. Most useful: "full".
   * @desc
   * <ol> 
   * <li>Fetches the next unique panel id -> {@link module:corpus_shell~PanelManager#GetNewPanelId}. </li>
   * <li>Calculates an initial position as a {@link Position} object. <br/>
   *     It uses a cascading effect {@link module:corpus_shell~PanelManager#GetPanelCount} and by default an initial size of 525px x 600px. </li>
   * <li>Places the new window above all currently visible. -> {@link module:corpus_shell~PanelManager#GetMaxZIndex}</li>
   * <li>Creates a new title for the panel using "Search" as a part of that title. -> {@link module:corpus_shell~PanelManager#GetNewPanelTitle}</li>
   * <li>Converts the internal name to an index if necessary -> {@link module:corpus_shell~PanelManager#GetSearchIdx}.</li>
   * <li>Creates a new {@link module:corpus_shell~Panel} object.</li>
   * <li>Within this new panel create a new search panel and display it using {@link module:corpus_shell~Panel#CreatePanel}
   * <li>Add the new panel to this object's "map" of all panels by its unique id. -> {@link module:corpus_shell~PanelManager#PanelObjects}</li>
   * <li>Create a new main panel object for this panel in the map of main panel objects which is one above the created panel -> {@link module:corpus_shell~PanelManager#AddMainPanel}</li>
   * </ol>
   * Note: Do not call this from an arbitrary jQuery ready handler! The initialization is most probably not finished and the newly created panel will just vanish.<br/>
   * @summary purpose: Creates a new search panel and registers it with this object.
   * @fires module:corpus_shell~PanelManager#event:onUpdated
   * @return {string} The ID of the newly created Search Panel
   */
  this.OpenNewSearchPanel = function(config, searchstr, dataview)
  {
    var panelName = this.GetNewPanelId();

    var position = this.GetInitialPosition();

    var maxZidx = this.GetMaxZIndex() + 1;
    var panelTitle = this.GetNewPanelTitle("Search");

    if (isNaN(config))
      config = this.GetSearchIdx(config);
    
    var newPanel = new Panel(panelName, "search", panelTitle, "", position, false, maxZidx, this.Container, this, config);
    if (dataview !== undefined)
       newPanel.UrlParams['x-dataview'] = dataview;
    this.NormalizePanel(this.maximizedPanel);
    newPanel.CreatePanel(searchstr);

    this.PanelObjects[panelName] = newPanel;
    this.AddMainPanel(panelName, "search", position, undefined, panelTitle, maxZidx + 1);
    return newPanel.Id;
  };


  /**
   * @public
   * @param {string} An internal resource name.
   * @param {string} [scanIdx] The index string for which the possible terms should be fetched. <br/>
   * @desc
   * <ol>
   *    <li>Create a URL that fetches a scan view of the specified index
   *        for the specified resource from {@link module:corpus_shell~switchURL}.</li>
   *    <li>Open a new content panel with to show this URL.</li>
   * </ol>
   * @return    -
   */
  this.OpenNewScanPanel = function(config, scanIdx)
  {
    var urlStr = switchURL + "?operation=scan&x-format=html&x-context=" + config +
                 "&version=1.2&scanClause=" + scanIdx;
    if (scanIdx === 'geo') {
        this.OpenNewContentPanel(urlStr, "Map " + config + ": " + scanIdx);
    } else {
        this.OpenNewContentPanel(urlStr, "Scan " + config + ": " + scanIdx);
    }
  };

  /**
  * @param -
  * purpose:
  * @return    -
  */
  this.OpenNewContentPanel = function(url, titlePart)
  {
    if (url === '#')
        return;
    var panelName = this.GetNewPanelId();

    var position = this.GetInitialPosition();

    var maxZidx = this.GetMaxZIndex() + 1;
    if (titlePart == undefined)
      titlePart = "Content";

    var panelTitle = this.GetNewPanelTitle(titlePart);
    
    
    var newPanel;
    if (titlePart.indexOf("Map ") === 0) {
        var posWidthParts = position.Width.split(/(\d*)((px)|(em))?/i);
        position.Width = '' + (posWidthParts[1] * 1.8) + posWidthParts[2];
        newPanel = new MapPanel(panelName, "content", panelTitle, url, position, false, maxZidx, this.Container, this, undefined);
    }
    else if (titlePart.indexOf("Book ") === 0)
        newPanel = new BookReaderPanel(panelName, "content", panelTitle, url, position, false, maxZidx, this.Container, this, undefined);
    else if ((titlePart.indexOf("XML ") === 0) || (titlePart.indexOf("TEI ") === 0)) {
        var posWidthParts = position.Width.split(/(\d*)((px)|(em))?/i);
        position.Width = '' + (posWidthParts[1] * 2) + posWidthParts[2];
        newPanel = new XmlPanel(panelName, "content", panelTitle, url, position, false, maxZidx, this.Container, this, undefined);
    }
    else
        newPanel = new Panel(panelName, "content", panelTitle, url, position, false, maxZidx, this.Container, this, undefined);
    this.NormalizePanel(this.maximizedPanel);
    newPanel.CreatePanel();

    this.PanelObjects[panelName] = newPanel;
    this.AddMainPanel(panelName, "content", position, url, panelTitle, maxZidx + 1);
  }

  /**
  * @param {MainPanelObject} panelObj A object describing the panel to be created
  * Called when restoring the hibernated layout to create a search panel.
  * @return    -
  */
  this.CreateNewSearchPanelObj = function(panelObj)
  {
    if (panelObj === undefined) return;

    var maxZidx = this.GetMaxZIndex() + 1;
    var zIndex = parseInt(panelObj.ZIndex);
    if (isNaN(zIndex))
      zIndex = maxZidx;
    var newPanel = new Panel(panelObj.Id, panelObj.Type, panelObj.Title, panelObj.Url, panelObj.Position, false, zIndex ,this.Container, this, 0, panelObj.Maximized);
    this.NormalizePanel(this.maximizedPanel);
    newPanel.CreatePanel();
        
    this.PanelObjects[panelObj.Id] = newPanel;
    
    if (panelObj.Maximized) {
       if (this.maximizedPanel === undefined) {
            this.MaximizePanel(panelObj.Id);
       } 
    }
  };

  /**
  * @param {MainPanelObject} panelObj A object describing the panel to be created
  * Called when restoring the hibernated layout to create other panels.
  * @return    -
  */
  this.CreateNewContentPanelObj = function(panelObj)
  {
        if (panelObj === undefined)
            return;

        var maxZidx = this.GetMaxZIndex() + 1;
        var newPanel;
        if (panelObj.Title.indexOf("Map ") === 0)
            newPanel = new MapPanel(panelObj.Id, panelObj.Type, panelObj.Title, panelObj.Url, panelObj.Position, false, maxZidx, this.Container, this, 0, panelObj.Maximized);
        else if (panelObj.Title.indexOf("Book ") === 0)
            newPanel = new BookReaderPanel(panelObj.Id, panelObj.Type, panelObj.Title, panelObj.Url, panelObj.Position, false, maxZidx, this.Container, this, 0, panelObj.Maximized);
        else if ((panelObj.Title.indexOf("XML ") === 0) || (panelObj.Title.indexOf("TEI ") === 0))
            newPanel = new XmlPanel(panelObj.Id, panelObj.Type, panelObj.Title, panelObj.Url, panelObj.Position, false, maxZidx, this.Container, this, 0, panelObj.Maximized);
        else
            newPanel = new Panel(panelObj.Id, panelObj.Type, panelObj.Title, panelObj.Url, panelObj.Position, false, maxZidx, this.Container, this, 0, panelObj.Maximized);
        this.NormalizePanel(this.maximizedPanel);
        newPanel.CreatePanel();

        this.PanelObjects[panelObj.Id] = newPanel;
  };

  /**
  * @param elem {node} The link/anchor node where this call originated.
  * @param url {url} A URL which is used as a container for all parameters needed by the sub panels. 
  * @param pinned {boolean} If a created sub panel is pinned.
  * @param type {string} "image" or "text"
  * @summary purpose: Create a new sub panel that displays the results of a full text search or a facsimile image.
  * @desc First tries to get the image or text panel associated with the panel to which the link elem belongs to.
  * If that doesn't succeed a new sub panel is created else the content of the already existing sub panel is changed. 
  * @return    -
  */
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
      this.NormalizePanel(this.maximizedPanel);
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
  };

  /**
  * @param -
  * purpose:
  * @return    -
  */
  this.CreateNewSubPanelObj = function(panelObj)
  {
    if (panelObj == undefined) return;

    var newPanel = new Panel(panelObj.Id, panelObj.Type, panelObj.Title, panelObj.Url, panelObj.Position, panelObj.Pinned, panelObj.ZIndex ,this.Container, this, 0, panelObj.Maximized);
    this.NormalizePanel(this.maximizedPanel);
    newPanel.CreatePanel();
    this.PanelObjects[panelObj.Id] = newPanel;
  }

  //panelobject methods
  
  /**
  * @param panelId - unique panel identifier
  * purpose:
  * @return    -
  */
  this.GetPanelObj = function(panelId)
  {
    return this.PanelObjects[panelId];
  }

  /**
  * @param panelId - unique panel identifier
  * purpose:
  * @return    -
  */
  this.RemovePanelObj = function(panelId)
  {
    var panelObj = this.GetPanelObj(panelId);
    if (panelObj != undefined)
    {
      panelObj.Close();
      delete this.PanelObjects[panelId];
    }
  }

  /**
  * @param panelId - unique panel identifier
  * purpose:
  * @return    -
  */
  this.UpdatePanelPosition = function(panelId)
  {
    var panelObj = this.GetPanelObj(panelId);

    if (panelObj)
     {
       panelObj.UpdatePosition();
       var position = panelObj.Position;
       this.SetPanelPosition(panelId, position);
     }
  };

  /**
  * @param {string} panelId - unique panel identifier
  * @param {boolean} [resetPaging] Wheter to set the start record for the result set to 1.
  * @desc purpose: Store the search urls for all the searches started using the panels <br/>
  * after executing them there. -> {@link module:corpus_shell~Panel#StartSearch}
  * @fires module:corpus_shell~PanelManager#event:onUpdated
  * @return    -
  */
  this.StartSearch = function(panelId, resetPaging)
  {
    var panel = this.GetPanelObj(panelId);

    if (panel != undefined)
    {
      var startInput = $('#' + panelId).find('.startrecord');
      var start = parseInt(startInput.val(), 10);
      var maxInput = $('#' + panelId).find('.maxrecord');
      var max = parseInt(maxInput.val());
      if (resetPaging === true) {
          start = panel.DefaultStartRecord;
          startInput.val(start);
          max = panel.DefaultMaxRecords;
          maxInput.val(max);
      }
      var url = panel.StartSearch(start, max);
      this.SetPanelUrl(panelId, url);
    }
  };

  /**
  * @param panelId - unique panel identifier
  * purpose:
  * @return    -
  */
  this.StartSearchPrev = function(panelId)
  {
    var panel = this.GetPanelObj(panelId);

    if (panel != undefined)
    {
      var start = parseInt($('#' + panelId).find('.startrecord').val());
      var max = parseInt($('#' + panelId).find('.maxrecord').val());

      if (!max || max <= 0) max = panel.DefaultMaxRecords;
      if (!start || start < 1) start = panel.DefaultStartRecord;

      if (start - max > 0)
        start = start - max;

      var url = panel.StartSearch(start, max);
      this.SetPanelUrl(panelId, url);
    }
  };

  /**
  * @param panelId - unique panel identifier
  * purpose:
  * @return    -
  */
  this.StartSearchNext = function(panelId)
  {
    var panel = this.GetPanelObj(panelId);

    if (panel !== undefined)
    {
      var start = parseInt($('#' + panelId).find('.startrecord').val());
      var max = parseInt($('#' + panelId).find('.maxrecord').val());

      if (!max || max <= 0) max = panel.DefaultMaxRecords;
      if (!start || start < 1) start = panel.DefaultStartRecord;

      var hitCount = parseInt($('#' + panelId).find('.hitcount').html());

      if (hitCount && start + max <= hitCount)
        start = start + max;

      var url = panel.StartSearch(start, max);
      this.SetPanelUrl(panelId, url);
    }
  };

  //SearchConfig methods

  /**
  * @param {string} xContext A context identifier that is not a number but an internal name.
  * @desc purpose: finds the current index in {@link moduls:corpus_shell~SearchConfig} for a particular
  * internal (resource) name.
  * @return {number} The index matching the parameter or else 0
  */
  this.GetSearchIdx = function(xContext)
  {
    for (var idx = 0; idx < this.SearchConfig.length; idx++)
    {
      if (this.SearchConfig[idx]['x-context'] === xContext)
        return idx;
    }
    return 0;
  };

  /**
  * @param {number} idx The index to get the internal resource name for.
  * purpose: get an internal resource name for an index in {@link moduls:corpus_shell~SearchConfig}.
  * @return {string} The internal resource name.
  */
  this.GetResourceName = function(idx)
  {
    if (this.SearchConfig[idx] !== undefined) 
        return this.SearchConfig[idx]["x-context"];
  };

  // other helpers (place them elsewhere?)
  
  /**
   * Returns the current number of (main) panels.
   * @return {number} 
   */
  this.GetPanelCount = function()
  {
    var cnt = 0;

    for (var key in this.Panels)
    {
      cnt++;
    }

    return cnt;
  };
  
  /**
   * Query if panel fitting the description is already open
   * @param {PanelDescription} panelDescription
   * @returns {Boolean} Whether such a panel is already open.
   */
  this.isPanelOpen = function (panelDescription) {
        var found = false;
        var configIdx = this.GetSearchIdx(panelDescription.config);
        for (var pkey in this.PanelObjects) {
            found = this.PanelObjects[pkey].Config === configIdx &&
                    this.PanelObjects[pkey].Type === panelDescription.panelType;
            if (!found)
                continue;
            if (panelDescription.panelType === "search")
                found = this.PanelObjects[pkey].UrlParams.query === panelDescription.searchStr;
            else
                found = this.PanelObjects[pkey].UrlParams.scanClause === panelDescription.searchStr;
            if (found)
                break;
        }
        return found;
    };
    
  /**
  * @param {string] name ???
  * @param {Object} panels ???
  * purpose:
  * @return    -
  */
  this.LoadProfile = function(name, panels)
  {
    this.RemoveAllPanels();
    this.Panels = panels;
    this.ProfileName = name;

    for (var key in this.Panels)
    {
      var panel = this.Panels[key];
      if ((panel.Type === undefined) || (panel.Type === "search"))
      {
        panel['Type'] = "search";
        this.CreateNewSearchPanelObj(panel);
        if (panel.Url !== undefined && panel.Url !== "")
        {
          var panelObj = this.GetPanelObj(panel.Id);
          if (panelObj !== undefined)
            panelObj.StartSearch();
        }
      }
      else if (panel.Type === "content")
      {
        this.CreateNewContentPanelObj(panel);
      }

      for (var subKey in panel.Panels)
      {
        var subPanel = panel.Panels[subKey];
        this.CreateNewSubPanelObj(subPanel);
      }
    }
    this.RefreshUsedPanels();
    this.RefreshUsedSearchPanelTitles();
        for (var key in this.EnsuredPanels) {
            if (this.isPanelOpen(this.EnsuredPanels[key])) continue;
            if (this.EnsuredPanels[key].panelType === "search") {
                var ID = this.OpenNewSearchPanel(this.EnsuredPanels[key].config, this.EnsuredPanels[key].searchStr);
                this.StartSearch(ID);
            } else if (this.EnsuredPanels[key].panelType === "explain") {
                this.OpenNewContentPanel(params.switchURL + '?x-format=html&version=1.2&x-context=' + this.EnsuredPanels[key].config +
                   '&operation=explain');
            } else {
                if (this.EnsuredPanels[key].searchStr !== 'geo') {
                this.OpenNewContentPanel(params.switchURL + '?x-format=html&version=1.2&x-context=' + this.EnsuredPanels[key].config +
                   '&operation=scan&scanClause=' + this.EnsuredPanels[key].searchStr);
                }
                else {
                    this.OpenNewContentPanel(params.switchURL + '?x-format=html&version=1.2&x-context=' + this.EnsuredPanels[key].config +
                   '&operation=scan&scanClause=' + this.EnsuredPanels[key].searchStr,
                   "Map " + this.EnsuredPanels[key].config + ": " + this.EnsuredPanels[key].searchStr);
                }
            }
        }
  };
}
this.PanelController = new PanelManager("#snaptarget", SearchConfig);
}(jQuery, SearchConfig, params);
