/**
 * @fileOverview Contains all the helper methods that are called from index.html which do
 * some preliminary checks and then delegate the work to the specialized classes. It also provides the ui logic for the sidebar.<br/>
 * This file has some sections which are just instructions and are not wraped into a function block.
 * Main entry points here are {@link module:corpus_shell~doOnDocumentReady} which is passed to jQuery as the $(document).ready() handler,
 * {@link module:corpus_shell~SaveProfileAs}, {@link module:corpus_shell~CreateNewProfile}, {@link module:corpus_shell~LoadProfile} and {@link module:corpus_shell~DeleteProfile}
 * which are activated by correponding buttons in the side bar, {@link module:corpus_shell~GetUserData} which is used by the Refresh user profiles button and
 * {@link module:corpus_shell~ShowIndexCache} which provides the Show/Hide indexes functionality.
 */

/**
 * @module corpus_shell 
 */

// Adds an indexOf to every Array object if there isn't one at the moment.
if (!Array.prototype.indexOf)
{
  Array.prototype.indexOf = function(elt /*, from*/)
  {
    var len = this.length;

    var from = Number(arguments[1]) || 0;
    from = (from < 0)
         ? Math.ceil(from)
         : Math.floor(from);
    if (from < 0)
      from += len;

    for (; from < len; from++)
    {
      if (from in this &&
          this[from] === elt)
        return from;
    }
    return -1;
  };
}

/**
 * A protection variable to disable updates initiated by {@link module:corpus_shell~PanelManager#onUpdated} while
 * data is still retrieved from the server.
 * @type {boolean} 
 */
var updating = false;

/**
 * The current user ID.
 * @type {string}  
 */
var userId = null;
/**
 * Current count of search panels.
 * @type {number} 
 */
var searchPanelCount = 1;
$.storage = new $.store();
var Indexes = null;

/**
 * @desc Get parameters from the supplied uri/url as a "map" (a JavaScript object which properties correspond to the parameters).
 * @param {url} url Some url witch contains parameters to be converted to a "map".
 * @return {map} Parameters in the url as a "map".  
 */
function GetUrlParams(url)
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


/**
 * <ol>
 * <li>Bind events to DOM elements that may or may not exist in the current DOM tree using jQuery</li>
 * <li>Tries to get a user id.</li>
 * <li>Initiates asynchrounous loading of the profiles and the index data.</li>
 * <li>Installs a handler for the {@link module:corpus_shell~PanelManager#event:onUpdated} event of {@link module:corpus_shell~PanelController}.</li>
 * <li>Displays a URL which contains the current user ID in a DOM element designated by #userid</li>
 * <li>Generates a drop down list with search targets using {@link module:corpus_shell~GenerateSearchCombo} into the DOM element designated by #searchbuttons and preselects the first item</li>
 * <li>Generates a drop down list with profiles using {@link module:corpus_shell~GenerateProfileCombo} right after the DOM element designated by #profiledel and preselects the first item</li>
 * </ol>
 */
function doOnDocumentReady ()
{
    $('.scroll-container .data-view.full a').live("click", function (event) {
         event.preventDefault();
         PanelController.OpenSubPanel(this, $(this).attr('href'), true, "text");
      });
    $('.scroll-container .data-view.image a').live("click", function (event) {
         event.preventDefault();
         PanelController.OpenSubPanel(this, $(this).attr('href'), true, "image");
      });
    $('.scroll-container a.value-caller').live("click", function (event) {
         event.preventDefault();
         PanelController.OpenSubPanel(this, '/switch' + $(this).attr('href') + '&version=1.2&x-context=clarin.at:icltt:cr:stb', true, "text");
      });
    $('.scroll-container .navigation a').live("click", function (event) {
         event.preventDefault();
         PanelController.OpenSubPanel(this, $(this).attr('href'), true, "text");
      });

    var urlParams = GetUrlParams(location.search);
    if (urlParams['userId'] && urlParams['userId'] != "")
    {
      userId = urlParams['userId'];
    }

    if (userId == null)
    {
      userId = $.storage.get("userId");
    }

    if (userId == null)
    {
      GetUserId();
    }

    updating = true;
    GetUserData(userId);

    // updating = false; doesn't make sense here. Belongs to the GetUserData AJAX callback?
    LoadIndexCache();

    PanelController.onUpdated = function (changeText)
    {
       if (!updating)
       {
         RefreshPanelList();
         ProfileController.SetProfile(PanelController.ProfileName, PanelController.Panels);
         SaveUserData(userId);
       }
    }

    $("#userid").val(GenerateUseridLink(userId));
    
    var scombo = GenerateSearchCombo(0);
    $(scombo).css("margin-top", "5px");
    $("#searchbuttons").append(scombo);

    var pcombo = GenerateProfileCombo(0);
    $("#profiledel").after(pcombo);
}
$(doOnDocumentReady);

var PanelCount = 0;

/**
 * @param {string} userId A user ID corpus_shell understands, maybe a GUID.
 * @desc Adds the user ID as paramter userId to the URL of this document.
 * @return {url} A URL which can be used to access corpus_shell directely with everything
 * set up the same as when the user left. Can be used for eg. bookmarking.
 */
function GenerateUseridLink(userId)
{
  var url = document.URL;
  var pos = url.indexOf("?");

  if (pos != -1)
    url = url.substr(0, pos);

  return url + "?userId=" + userId;
}

/**
 * Tries to get a new user ID from the modules/userdata/getUserId.php script.
 * @return {string} A user ID, maybe a GUID.
 */
function GetUserId()
{
  $.getJSON(baseURL + userData + "getUserId.php", function(data)
  {
     userId = data.id;
     $.storage.set("userId", userId);
  });
}

/**
 * @summary Tries to retrieve profile settings saved on the server.<br/>
 * If contacting the the script fails the browsers localstore is used.
 * @desc Retrieval is done asynchronously so this function returns immediately and the actual result may be be valid later.
 * <ol>
 * <li>Interprets the server's answer as JSON and if this fails uses data from local store instead.</li>
 * <li>Passes the data to {@link module:corpus_shell~ProfileController} as {@link module:corpus_shell~ProfileManager#Profiles}</li>
 * </ol>
 * @param {string} userId The user id for which the data should be retrieved. May be an GUID for example.
 * @return -
 */
function GetUserData(userId)
{
  $.ajax(
  {
      type: 'POST',
      url: baseURL + userData + "getUserData.php",
      dataType: 'json',
      data : {uid: userId},
      complete: function(data, textStatus)
      {
        var result = null;
        try {
        	result = JSON.parse(data.responseText, null);
        }
        catch (e) {
        	// make-it-work hack: if this is unintelligable go to the localstore and fetch data from there
        	try {
        	  var dataStr = $.storage.get(userId + "_Profiles");
        	  result = JSON.parse(dataStr);
        	} catch (e) {}
        }
        if (result == undefined || result == null || result == false || result == "" )
          result = new Array();

        ProfileController.Profiles = result;
        updating = false; // moved here from the doOnDocumentReady callback.
        var currentProfile = PanelController.ProfileName;
        RefreshProfileCombo(currentProfile);
        LoadProfile(currentProfile);
      }
  }
  );
}

/**
 * Loads the {@link module:corpus_shell~ResourceController}, a {@link module:corpus_shell~ResourceManager}, with data stored in indexCache.json.
 */
function LoadIndexCache()
{
  ResourceController.ClearResources();

  for (var i = 0; i < SearchConfig.length; i++)
  {
    var resName = SearchConfig[i]["x-context"];
    ResourceController.AddResource(resName, SearchConfig[i]["DisplayText"]);
  }

  $.getJSON(baseURL + '/scripts/js/indexCache.json', function(data)
  {
    $.each(data, function(key, val)
    {
      for(var index in val)
      {
        var item = val[index];

        if (item.searchable == "true") item.searchable = true; else item.searchable = false;
        if (item.scanable == "true") item.scanable = true; else item.scanable = false;
        if (item.sortable == "true") item.sortable = true; else item.sortable = false;

        ResourceController.AddIndex(key, item.idxName, item.idxTitle, item.searchable, item.scanable, item.sortable);
      }
    });

  });
}

/**
 * @param {Object} inVal Some arbitarily deep nested Object.
 * @desc Provides a recursive algorithm to construct the json code needed to represent a hierarchical object structure.<br/>
 * The actual recursive function is called _json_encode.
 * @return {string} JSON string representing the object hierarchy.
 */
function json_encode(inVal)
{
  return _json_encode(inVal).join('');
}

function _json_encode(inVal, out)
{
	out = out || new Array();
	var undef; // undefined
	switch (typeof inVal)
	{
 		case 'object':
			if (!inVal)
			{
				out.push('null');
			}
			else
			{
				if (inVal.constructor == Array)
				{
					// Need to make a decision... if theres any associative elements of the array
					// then I will block the whole thing as an object {} otherwise, I'll block it
					// as a  normal array []
					var testVal = inVal.length;
					var compVal = 0;
					for (var key in inVal) compVal++;
					if (testVal != compVal)
					{
						// Associative
						out.push('{');
						i = 0;
						for (var key in inVal)
						{
							if (i++ > 0) out.push(',\n');
							out.push('"');
							out.push(key);
							out.push('":');
							_json_encode(inVal[key], out);
						}
						out.push('}');
					}
					else
					{
						// Standard array...
						out.push('[');
						for (var i = 0; i < inVal.length; ++i)
						{
							if (i > 0) out.push(',\n');
							_json_encode(inVal[i], out);
						}
						out.push(']');
					}

				}
				else if (typeof inVal.toString != 'undefined')
				{
					out.push('{');
					var first = true;
					for (var i in inVal)
					{
						var curr = out.length; // Record position to allow undo when arg[i] is undefined.
						if (!first) out.push(',\n');
						_json_encode(i, out);
						out.push(':');
						_json_encode(inVal[i], out);
						if (out[out.length - 1] == undef)
						{
							out.splice(curr, out.length - curr);
						}
						else
						{
							first = false;
						}
					}
					out.push('}');
				}
			}
			return out;

		case 'unknown':
		case 'undefined':
		case 'function':
			out.push(undef);
			return out;

		case 'string':
	        out.push('"');
	        out.push(inVal.replace(/(["\\])/g, '\$1').replace(/\r/g, '').replace(/\n/g, '\n'));
	        out.push('"');
	        return out;

		default:
			out.push(String(inVal));
			return out;
	}
}

/**
 * @desc Tries to save the users profile data to the server. As a backup saves the profile data to the local store.
 * @param {string} userId  The user id for which the data should be saved. May be an GUID for example.
 */
function SaveUserData(userid)
{
  var dataStr = json_encode(ProfileController.Profiles);

  // Now save things locally, may be something goes wrong on transmission ...
  // make-things-work hack: This only makes sense if we at least compare the local and the
  // remote profile at load time and then use the newer one.
  
  $.storage.set(userId + "_Profiles", dataStr);
  
  $.ajax(
  {
      type: 'POST',
      url: baseURL + userData + "saveUserData.php",
      dataType: 'xml',
      data : {uid: userid, data: dataStr},
      complete: function(xml, textStatus)
      {
        // this almost ever succedes. Even if the php is only a locally downloaded copy with no php
        // interpreter to run it, so it surely is no valid XML :-(
      }
  }
  );
}

/**
 * Provides the functionality for openning and closing the side bar.Changes the arrow shown. 
 */
function ToggleSideBar()
{
  var left = $("#sidebar").css("left").replace(/px/g, "");
  var width = $("#sidebar").css("width").replace(/px/g, "");

  if (left == "0" || left == "0px")
  {
    left = left - width + 7;
    $("#sidebaricon").attr("src", "scripts/style/img/sidebargrip.right.png");
  }
  else
  {
    left = 0;
    $("#sidebaricon").attr("src", "scripts/style/img/sidebargrip.left.png");
  }

  $("#sidebar").css("left", left+"px");
}

/**
 * @param {number} hi If 1 the color will change to the highlighted state else to normal.
 * @desc Provides the color change if the mouse is over the edge of the side bar. 
 */
function ToggleSideBarHiLight(hi)
{
  if (hi == 1)
    $(".sidebartoggle").css("background-color", "#E0EEF8");
  else
    $(".sidebartoggle").css("background-color", "#214F75");
}

/**
 * @param {number} [idx] Index of an entry to be preselected.
 * @param {string} [selEntry] Name of an entry to be preselected. If supplied idx is ignored.
 * @desc Creates a drop down list containing all profiles known to {@link module:corpus_shell~ProfileController}.
 * @return {Element} A select DOM Element which is usually realized as a drop down list. Its id is #profilecombo. This element is also of class .searchcombo.
 */
function GenerateProfileCombo(idx, selEntry)
{
  var profilecombo = document.createElement('select');
  $(profilecombo).addClass("searchcombo");

  var i = 0;

  var profiles = ProfileController.GetProfileNames();

  for (var pos = 0; pos < profiles.length; pos++)
  {
    var profileoption = document.createElement('option');
    $(profileoption).attr("value", profiles[pos]);

    if (selEntry != undefined)
    {
      if (profiles[pos] == selEntry)
        $(profileoption).attr("selected", "selected");
    }
    else
    {
      if (i == idx)
        $(profileoption).attr("selected", "selected");
    }

    $(profileoption).text(profiles[pos]);
    $(profilecombo).append(profileoption);
    i++;
  }

  $(profilecombo).css("margin", "5px 0px");
  $(profilecombo).attr("id", "profilecombo");

  return profilecombo;
}

/**
 * @param {string} [selEntry] Name of the profile to be selected.
 * @desc Replaces the DOM element with the id of #profilecombo with a newly generated one.
 * @return -  
 */
function RefreshProfileCombo(selEntry)
{
  var pcombo = GenerateProfileCombo(0, selEntry);

  var htmlstr = $(pcombo).html();
  $('#profilecombo').html(htmlstr);
}

/**
 * @public
 * @param config {number} Item that should be preselected.
 * @desc Creates a drop down list using all the items in {@link module:corpus_shell~SearchConfig}
 * @return {Element} A select DOM element which is usually realized as a drop down list. These select nodes are of class .searchcombo.
 */
function GenerateSearchCombo(config)
{
  var searchcombo = document.createElement('select');
  $(searchcombo).addClass("searchcombo");

  for (var i = 0; i < SearchConfig.length; i++)
  {
     var searchoption = document.createElement('option');
     $(searchoption).attr("value", i);

     if (i == config)
       $(searchoption).attr("selected", "selected");

     $(searchoption).text(SearchConfig[i]["DisplayText"]);
     $(searchcombo).append(searchoption);
  }

  return searchcombo;
}

function split( val )
{
  return val.split( /=\s*/ );
}

function extractLast( term )
{
		return split( term ).pop();
}

function RefreshPanelList()
{
  if ($('#panelList').length != 0)
  {
    $('#openpanelslist').html('');
    TogglePanelList();
  }
}

/**
 * Provides the functionality for showing a list of all currently shown panels and subpanels.
 * With this list the panels can be brought to front by name.
 */
function TogglePanelList()
{
  if ($('#panelList').length != 0)
  {
     $('#openpanelslist').remove();
     $('#TogglePanelListButton').text('Show panel list');
     return true;
  }

  $('#openpanelslist').remove();
  $('#TogglePanelListButton').text('Hide panel list');

  var openpanelslist = document.createElement('div');
  $(openpanelslist).attr('id', 'openpanelslist');
  $(openpanelslist).css('padding', '10px 0px');
  $(openpanelslist).css('border-left', '1px dotted #666666');
  $(openpanelslist).css('border-right', '1px dotted #666666');
  $(openpanelslist).css('border-bottom', '1px dotted #666666');

  var listContainer = document.createElement('table');
  $(listContainer).attr('id', 'panelList');
  $(listContainer).css('margin-left', '15px');
  $(listContainer).css('width', '165px');
  $(listContainer).css('border-collapse', 'collapse');

  var sortedKeys = new Array();
  for (panelName in PanelController.Panels)
  {
    sortedKeys.push(panelName);
  }

  sortedKeys.sort(function(idA, idB)
  {
    var objA = PanelController.Panels[idA];
    var objB = PanelController.Panels[idB];

    var a = objA.Title;
    var b = objB.Title;

    return a < b ? -1 : (a > b ? 1 : 0);
  });

  for (var i = 0; i < sortedKeys.length; i++)
  {
    var panelName = sortedKeys[i];
    var tr = document.createElement('tr');
    var td = document.createElement('td');
    var a = document.createElement('a');

    $(td).attr('colspan','2');

    $(a).addClass('sidebar');
    $(a).attr('href','#');
    $(a).attr('onclick','PanelController.BringToFront("' + panelName + '");');
    $(a).css('display', 'block');
    $(a).css('padding-top', '2px');
    $(a).css('padding-bottom', '2px');

    var panel = PanelController.Panels[panelName];
    $(a).text(panel.Title); // + ' [zIdx: ' + $('#' + panelName).css('z-index') + ']');

    $(td).append(a);
    $(tr).append(td);
    $(listContainer).append(tr);

    if (panel != undefined)
    {
      for (subPanelName in panel.Panels)
      {
        var trSub = document.createElement('tr');
        var tdSub = document.createElement('td');
        var tdSubSpacer = document.createElement('td');
        var aSub = document.createElement('a');

        $(aSub).addClass('sidebar');
        $(aSub).attr('href','#');
        $(aSub).attr('onclick','PanelController.BringToFront("' + subPanelName + '");');
        $(aSub).css('display', 'block');
        $(aSub).css('padding-top', '2px');
        $(aSub).css('padding-bottom', '2px');

        var subPanel = panel.Panels[subPanelName];
        $(aSub).text(subPanel.Title);

        $(tdSubSpacer).css('width', '20px');
        $(tdSub).append(aSub);
        $(trSub).append(tdSubSpacer);
        $(trSub).append(tdSub);
        $(listContainer).append(trSub);
      }
    }
  }

  $(openpanelslist).append(listContainer);
  $('#TogglePanelListButton').after(openpanelslist);
}

/**
 * @desc loads the profile with the given name.
 * @param {string} name Name of an existing profile.
 */
function LoadProfile(name)
{
  updating = true;
  PanelController.LoadProfile(name, ProfileController.GetProfile(name));
  updating = false;
  RefreshPanelList();
}

/**
 * @desc Saves the current set of panels with a new name as a profile. Shows an error message box if no name is given.
 * @param {string} newName A new name for the current set of panels.
 */
function SaveProfileAs(newName)
{
  if (newName == "")
    alert('New name is empty!');
  else
  {
    var currentName = PanelController.ProfileName;
    ProfileController.SetProfileAsNew(newName, PanelController.Panels);
    PanelController.ProfileName = newName;
    alert('Current name is "' + currentName + '", new name is "' + newName + '"');
    SaveUserData(userId);
    RefreshProfileCombo(newName);
  }
}

/**
 * @param {string} newName Name of the profile to be createed.
 * @desc Creates a new profile with the given name and saves that profile.
 * @return -
 */
function CreateNewProfile(newName)
{
  if (newName == "")
    alert('New name is empty!');
  else
  {
    var currentName = PanelController.ProfileName;
    ProfileController.SetProfileAsNew(newName, PanelController.Panels);
    PanelController.ProfileName = newName;
    alert('New profile "' + newName + '" was created');
    LoadProfile(newName);
    RemoveAllPanels();
    SaveUserData(userId);
    RefreshProfileCombo(newName);
  }
}

/**
 * @param {string} profileName Name of the profile to be deleted.
 * @desc Deletes the given profile if it's not loaded and not the default profile.
 * Asks the user to confirm before actually deleting. This also saves the new list of profiles.
 * @return -
 */
function DeleteProfile(profileName)
{
  if (PanelController.ProfileName == profileName)
  {
    alert('Cannot delete profile "' + profileName + '", because it is currently loaded!');
    return;
  }

  if (profileName == 'default')
  {
    alert('Cannot delete the default profile!');
    return;
  }

  if (confirm('Delete profile "' + profileName + '"?'))
  {
    ProfileController.DeleteProfile(profileName);
    SaveUserData(userId);
    RefreshProfileCombo();
  }
}

function RefreshIndexes()
{
  for (var i = 0; i < SearchConfig.length; i++)
  {
    var resName = SearchConfig[i]["x-context"];
    ResourceController.AddResource(resName, SearchConfig[i]["DisplayText"]);
    GetIndexes(resName);
  }
}

function GetIndexes(resName)
{
  $.ajax(
  {
    type: 'GET',
    url: "fcs/aggregator/switch.php",
    dataType: 'xml',
    data : {operation: 'explain', 'x-context': resName, version: '1.2'},
    complete: function(xml)
    {
      $(xml.responseXML).find("index").each(function ()
      {
         var idxName = $(this).find("map name").text();
         var idxTitle = $(this).find("title[lang='en']").text();
         var searchable = $(this).attr("search");
         var scanable = $(this).attr("scan");
         var sortable = $(this).attr("sort");

         ResourceController.AddIndex(resName, idxName, idxTitle, searchable, scanable, sortable);
      }
      );
    }
  }
  );
}

function GetIndexesFromSearchCombo()
{
  var sele = parseInt($(parElem).find(".searchcombo").val());
  var resource = GetResourceName(sele);

  return ResourceController.GetLabelValueArray(resource);
}

/**
 * Provides the Show/Hide indexes functionality. The actual list is provided
 * as an HTML snippet by {@link corpus_shell~ResourceManager#GetIndexCache}. 
 */
function ShowIndexCache()
{
  if ($('#indexList').length != 0)
  {
     $('#openIndexList').remove();
     $('#ShowIndexesButton').text('Show indexes');
     return true;
  }

  $('#openIndexList').remove();
  $('#ShowIndexesButton').text('Hide indexes');

  var hStr = ResourceController.GetIndexCache();

   $('#ShowIndexesButton').after(hStr);

  $('#openIndexList').css('padding', '10px 0px');
  $('#openIndexList').css('border-left', '1px dotted #666666');
  $('#openIndexList').css('border-right', '1px dotted #666666');
  $('#openIndexList').css('border-bottom', '1px dotted #666666');


  //$('#indexList').css('margin-left', '15px');
  $('#indexList').css('width', '162px');
  $('#indexList').css('border-collapse', 'collapse');

  $('#openIndexList td.dotted.b').css('font-weight', 'bold');
  $('#openIndexList td.dotted').css('color', '#000000');
  $('#openIndexList td.dotted').css('vertical-align', 'top');
  $('#openIndexList td.dotted').css('border-top', '1px dotted #666666');

  $('#openIndexList td.dottedr.isfalse').css('color', '#999999');
  $('#openIndexList td.dottedr.isfalse').css('text-decoration', 'line-through');
  $('#openIndexList td.dottedr.istrue').css('color', '#000000');


  $('#openIndexList td.dottedr').css('vertical-align', 'top');
  $('#openIndexList td.dottedr').css('text-align', 'right');
}
