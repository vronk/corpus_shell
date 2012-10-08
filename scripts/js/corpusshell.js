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

var updating = false;
var userId = null;
var searchPanelCount = 1;
$.storage = new $.store();
var Indexes = null;
var baseURL = "/cs2/corpus_shell";


$(function()
{
    $('.scroll-container .data-view.full a').live("click", function (event) {
         event.preventDefault();
         PanelController.OpenSubPanel(this, $(this).attr('href'), true, "text");
      });
    $('.scroll-container .data-view.image a').live("click", function (event) {
         event.preventDefault();
         PanelController.OpenSubPanel(this, $(this).attr('href'), true, "image");
      });
    $('.scroll-container .navigation a').live("click", function (event) {
         event.preventDefault();
         PanelController.OpenSubPanel(this, $(this).attr('href'), true, "text");
      });

    userId = $.storage.get("userId");

    if (userId == null)
    {
      GetUserId();
    }

    updating = true;
    GetUserData(userId);

    updating = false;
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
});

var PanelCount = 0;

function GetUserId()
{
  $.getJSON(baseURL + '/main/utils/getUserId.php', function(data)
  {
     userId = data.id;
     $.storage.set("userId", userId);
  });
}

function GetUserData(userId)
{
  $.ajax(
  {
      type: 'POST',
      url: baseURL + "/main/utils/getUserData.php",
      dataType: 'json',
      data : {uid: userId},
      complete: function(data, textStatus)
      {
        var result = JSON.parse(data.responseText, null);
        if (result == undefined || result == null || result == false || result == "" )
          result = new Array();

        ProfileController.Profiles = result;
        var currentProfile = PanelController.ProfileName;
        RefreshProfileCombo(currentProfile);
        LoadProfile(currentProfile);
      }
  }
  );
}

function LoadIndexCache()
{
  ResourceController.ClearResources();

  for (var i = 0; i < SearchConfig.length; i++)
  {
    var resName = SearchConfig[i]["x-context"];
    ResourceController.AddResource(resName, SearchConfig[i]["DisplayText"]);
  }

  $.getJSON('http://corpus3.aac.ac.at/cs2/corpus_shell/scripts/js/indexCache.json', function(data)
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

function SaveUserData(userid)
{
  var dataStr = json_encode(ProfileController.Profiles);

  $.ajax(
  {
      type: 'POST',
//      CHANGE THIS FOR RELEASE
//      url: "http://corpus3.aac.ac.at/sru/switch.php",
      url: baseURL + "/main/utils/saveUserData.php",

      dataType: 'xml',
      data : {uid: userid, data: dataStr},
      complete: function(xml, textStatus)
      {
        //alert("user data saved: userid: " + userid);
      }
  }
  );
}

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

function ToggleSideBarHiLight(hi)
{
  if (hi == 1)
    $(".sidebartoggle").css("background-color", "#E0EEF8");
  else
    $(".sidebartoggle").css("background-color", "#214F75");
}

$(function()
{
  var scombo = GenerateSearchCombo(0);
  $(scombo).css("margin-top", "5px");
  $("#searchbuttons").append(scombo);

  var pcombo = GenerateProfileCombo(0);
  $("#profiledel").after(pcombo);
});

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

function RefreshProfileCombo(selEntry)
{
  var pcombo = GenerateProfileCombo(0, selEntry);

  var htmlstr = $(pcombo).html();
  $('#profilecombo').html(htmlstr);
}

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

function LoadProfile(name)
{
  updating = true;
  PanelController.LoadProfile(name, ProfileController.GetProfile(name));
  updating = false;
  RefreshPanelList();
}

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