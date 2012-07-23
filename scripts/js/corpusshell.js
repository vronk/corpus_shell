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

$(function()
{
    $('.scroll-container .data-view.full a').live("click", function (event) {
         event.preventDefault();
         OpenSubPanel(this, $(this).attr('href'), true, "text");
      });
    $('.scroll-container .data-view.image a').live("click", function (event) {
         event.preventDefault();
         OpenSubPanel(this, $(this).attr('href'), true, "image");
      });
    $('.scroll-container .navigation a').live("click", function (event) {
         event.preventDefault();
         OpenSubPanel(this, $(this).attr('href'), true, "text");
      });

    userId = $.storage.get("userId");

    if (userId == null)
    {
      GetUserId();
    }

    updating = true;
    GetUserData(userId);

    updating = false;

    PanelController.onUpdated = function (changeText)
    {
       if (!updating)
       {
         //alert("onChanged triggered!, changed: " + changeText);
         RefreshPanelList();
         ProfileController.SetProfile(PanelController.ProfileName, PanelController.Panels);
         SaveUserData(userId);
       }
    }
});

var PanelCount = 0;

function GetUserId()
{
  $.getJSON('http://corpus3.aac.ac.at/cs2/corpus_shell/main/utils/getUserId.php', function(data)
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
      url: "http://corpus3.aac.ac.at/cs2/corpus_shell/main/utils/getUserData.php",
      dataType: 'json',
      data : {uid: userId},
      complete: function(data, textStatus)
      {
        var result = JSON.parse(data.responseText, null);
        if (result == undefined || result == null || result == false)
          result = new Array();

        ProfileController.Profiles = result;
        var currentProfile = PanelController.ProfileName;
        RefreshProfileCombo(currentProfile);
        LoadProfile(currentProfile);
      }
  }
  );
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
      url: "http://corpus3.aac.ac.at/cs2/corpus_shell/main/utils/saveUserData.php",
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

function GetPanelPosition(panel)
{
  var position = new Object();
  position["Left"] = $(panel).css("left");
  position["Top"] = $(panel).css("top");
  position["Width"] = $(panel).css("width");
  position["Height"] = $(panel).css("height");

  return position;
}

function SavePanelPositon(panel)
{
  var panelId = $(panel).attr("id");

  var position = GetPanelPosition(panel);
  PanelController.SetPanelPosition(panelId, position);
}

function LoadPanelPosition(panel)
{
  var panelId = $(panel).attr("id");

  return PanelController.GetPanelPosition(panelId);
}

function GetMinZIndex()
{
  var minZidx = Math.pow(2, 32) - 1;
  $( ".draggable" ).each(function(index)
  {
     var zIdx = parseInt($(this).css("z-index"));
     if (zIdx < minZidx)
       minZidx = zIdx;
  });
  return minZidx;
}

function GetMaxZIndex()
{
  LowerZIndex();
  var maxZidx = 0;
  $( ".draggable" ).each(function(index)
  {
     var zIdx = parseInt($(this).css("z-index"));
     if (zIdx > maxZidx)
       maxZidx = zIdx;
  });
  return maxZidx;
}

function LowerZIndex()
{
  var minZidx = GetMinZIndex();
  if (minZidx > 1)
  {
    var diff = minZidx - 1;
    $( ".draggable" ).each(function(index)
    {
       var zIdx = parseInt($(this).css("z-index"));
       var newZIdx = zIdx - diff;
       $(this).css("z-index", newZIdx);
       var panelId = $(this).attr('id');
       PanelController.SetPanelZIndex(panelId, newZIdx);
    });
  }
}

function BringToFront(panel)
{
  var maxZidx = GetMaxZIndex();
  $(panel).css("z-index",maxZidx + 1);
}

function InitDraggable(divid)
{
  $(divid)
  .resizable({ containment: "parent", aspectRatio: false,
             resize: function(event, ui)
             {
               BringToFront(this);
               var hgt = parseInt($(this).css("height").replace(/px/g, ""));
               if ($(this).find(".searchstring").length != 0)
                 $(this).find(".scroll-pane").css("height", hgt - 105 + "px");
               else
                 $(this).find(".scroll-pane").css("height", hgt - 35 + "px");


               RefreshScrollPane(this);

               var wid = parseInt($(this).css("width").replace(/px/g, ""));
               $(this).find(".scroll-content").css("width", wid - 16 + "px");

               SavePanelPositon(this);
             }
             })
  .draggable({ handle: "p", containment: "parent",  snap: true,
             start: function(event, ui)
             {
               BringToFront(this);
             } ,
             stop: function(event, ui)
             {
               SavePanelPositon(this);
             }
             });
}

function InitScrollPane(parElem)
{
  //$(".jspScrollable").removeClass("jspScrollable");
  //$('.scroll-pane').jScrollPane({autoReinitialise: true});
  var srdiv = $(parElem).find(".searchresults");
  $(srdiv).sbscroller({ mousewheel: true});
}

function RefreshScrollPane(parElem)
{
  $(parElem).find(".searchresults").sbscroller('refresh');
}

$(function()
{
  //OpenNewSearchPanel(-1);
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

    /*
    var currentTime = new Date();
    var hours = currentTime.getHours();
    var minutes = currentTime.getMinutes();
    var seconds = currentTime.getSeconds();

    if (minutes < 10)
      minutes = "0" + minutes;

    if (seconds < 10)
      seconds = "0" + seconds;

    $(profileoption).text(profiles[pos] + ' - ' + hours + ':' + minutes + ':' + seconds);
    */
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

function StartSearch(elem)
{
  var parElem = $(elem).parents(".draggable");
  var sstr = $(parElem).find(".searchstring").val();
  var sele = parseInt($(parElem).find(".searchcombo").val());

  // empty result-pane and indicate loading
  $(parElem).find(".searchresults").addClass("cmd loading").text("");
  $(parElem).find(".hitcount").text("-");

  var url = "http://corpus3.aac.ac.at/switch";
  var xcontext = SearchConfig[sele]['x-context'];

  var urlStr = url + "?operation=searchRetrieve&query=" + sstr + "&x-context=" + xcontext +
               "&x-format=html&version=1.2";

  PanelController.SetPanelUrl($(parElem).attr("id"), urlStr);

  $.ajax(
  {
      type: 'GET',
//      CHANGE THIS FOR RELEASE
//      url: "http://corpus3.aac.ac.at/sru/switch.php",
      url: url,
      dataType: 'xml',
      data : {operation: 'searchRetrieve', query: sstr, 'x-context': xcontext, 'x-format': 'html', version: '1.2'},
      complete: function(xml, textStatus)
      {
        var resultPane = $(parElem).find(".searchresults");
        resultPane.removeClass("cmd loading");

        var hstr = xml.responseText;
        hstr = hstr.replace(/&amp;/g, "&");

        //What does this do??
        if ($(parElem).find(".searchresults .scroll-content").length > 0)
        {
          $(parElem).find(".searchresults .scroll-content").html(hstr);
          RefreshScrollPane(parElem);
        }
        else
        {
          $(resultPane).html(hstr);
          InitScrollPane(parElem);
        }
        var hits = $(resultPane).find(".result-header").attr("data-numberOfRecords")
        $(parElem).find(".hitcount").text(hits);
        $(resultPane).find(".result-header").hide();
      }
  }
  );
}

function LoadBatch(elem)
{
  var parElem = $(elem).parents(".draggable");
  var recordcount = parseInt($(parElem).find(".recordcount").val());
  var startrecord = parseInt($(parElem).find(".startrecord").val());
  var maxrecord = parseInt($(parElem).find(".maxrecord").val());

  if (recordcount > 0 && startrecord > 0 && startrecord < recordcount)
  {
     Search(elem, startrecord, maxrecord);
  }
}

function Search(elem, startrecord, maxrecord)
{
  var parElem = $(elem).parents(".draggable");
  var sstr = $(parElem).find(".searchstring").val();

  // empty result-pane and indicate loading
  $(parElem).find(".searchresults").addClass("cmd loading").text("");
  $(parElem).find(".hitcount").text("-");

  $.ajax(
  {
      type: 'GET',
//      CHANGE THIS FOR RELEASE
//      url: "http://corpus3.aac.ac.at/sru/switch.php",
      url: "fcs/aggregator/switch.php",
//          url: "/ddconsru",
      dataType: 'xml',
      data : {operation: 'searchRetrieve', query: SearchConfig[sele]['x-context'] + '=' + sstr, startRecord: startrecord, maximumRecords: maxrecord, 'x-context': SearchConfig[sele]['x-context'], 'x-format': 'html', version: '1.2'},
      complete: function(xml, textStatus)
      {
        var resultPane = $(parElem).find(".searchresults")
        resultPane.removeClass("cmd loading");

        var hstr = xml.responseText;
        hstr = hstr.replace(/&amp;/g, "&");

        if ($(parElem).find(".searchresults .scroll-content").length > 0)
        {
          $(parElem).find(".searchresults .scroll-content").html(hstr);
          RefreshScrollPane(parElem);
        }
        else
        {
          $(parElem).find(".searchresults").html(hstr);
          InitScrollPane(parElem);
        }
        $(parElem).find(".hitcount").text($(".recordcount").val());
      }
  }
  );
}

function LoadPreviousBatch(elem)
{
  var parElem = $(elem).parents(".draggable");
  var recordcount = parseInt($(parElem).find(".recordcount").val());
  var startrecord = parseInt($(parElem).find(".startrecord").val());
  var maxrecord = parseInt($(parElem).find(".maxrecord").val());

  if (recordcount > 0)
  {
    if (startrecord - maxrecord > 0)
    {
      $(parElem).find(".startrecord").val(startrecord - maxrecord);
      Search(elem, startrecord - maxrecord, maxrecord);
    }
    else if (startrecord - maxrecord <= 0)
    {
      $(parElem).find(".startrecord").val(1);
      Search(1, maxrecord);
    }
  }
}

function LoadNextBatch(elem)
{
  var parElem = $(elem).parents(".draggable");
  var recordcount = parseInt($(parElem).find(".recordcount").val());
  var startrecord = parseInt($(parElem).find(".startrecord").val());
  var maxrecord = parseInt($(parElem).find(".maxrecord").val());

  if (startrecord + maxrecord < recordcount)
  {
    $(parElem).find(".startrecord").val(startrecord + maxrecord);
    Search(elem, startrecord + maxrecord, maxrecord);
  }
}

function GetFullText(elem, filename)
{
  $.ajax(
  {
      type: 'GET',
      url: filename,
      dataType: 'xml',
      complete: function(xml, textStatus)
      {
        var responseText = xml.responseText;

        //strip unnecessary header
        //responseText = $(responseText).find("div.data-view.full");
        responseText = $(responseText).find(".title, .data-view, .navigation");

        if ($(elem).find(".scroll-content").length > 0)
        {
          $(elem).find(".scroll-content").html(responseText);
          RefreshScrollPane(elem);
        }
        else
        {
          $(elem).find(".searchresults").html(responseText);
          InitScrollPane(elem);
        }
      }
  }
  );
}

function GetFacsimile(elem, filename)
{
  if ($(elem).find(".searchresults .scroll-content").length > 0)
  {
    $(elem).find(".searchresults .scroll-content").html('<img src="' + filename + '" />');
    RefreshScrollPane(elem);
  }
  else
  {
    $(elem).find(".searchresults").html('<img src="' + filename + '" />');
    InitScrollPane(elem);
  }
}

function GeneratePanelTitle(titlestring, pin, pinned)
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
  $(maxa).attr("onclick", "MaximizePanel(this);");
  $(maxa).addClass("noborder");

  var maximg = document.createElement('img');
  $(maximg).attr("src", "scripts/style/img/n.win_max.png");
  $(maximg).addClass("titletopiconmax");
  $(maximg).addClass("noborder");

  var righttd2 = document.createElement('td');
  $(righttd2).css("width", "17px");

  var closea = document.createElement('a');
  $(closea).attr("href", "#");
  $(closea).attr("onclick", "ClosePanel(this);");
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

function GenerateSearchNavigation()
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

  var loadimg = document.createElement('img');
  $(loadimg).addClass("navigationicon");
  $(loadimg).attr("src", "scripts/style/img/n.arrow_right_b.png");

  $(loada).append(loadimg);

  var preva = document.createElement('a');
  $(preva).addClass("noborder");

  var previmg = document.createElement('img');
  $(previmg).addClass("navigationicon");
  $(previmg).attr("src", "scripts/style/img/n.arrow_left.png");

  $(preva).append(previmg);

  var nexta = document.createElement('a');
  $(nexta).addClass("noborder");

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

function GetSearchIdx(xContext)
{
  for (var idx = 0; idx < SearchConfig.length; idx++)
  {
    if (SearchConfig[idx]['x-context'] == xContext)
      return idx;
  }
  return 0;
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

function GenerateSearchInputs(configIdx, searchStr)
{
  var searchdiv = document.createElement('div');
  $(searchdiv).addClass("searchdiv");
  $(searchdiv).text("Search for ");

  var searchstring = document.createElement('input');
  $(searchstring).addClass("searchstring");
  $(searchstring).attr("type", "text");

  if (searchStr != undefined)
    $(searchstring).val(searchStr);

  var buttondiv = document.createElement('div');
  $(buttondiv).css('float', 'right');

  var searchbutton = document.createElement('input');
  $(searchbutton).addClass("searchbutton");
  $(searchbutton).attr("type", "button");
  $(searchbutton).attr("value", "Go");
  $(searchbutton).attr("onclick", "StartSearch(this);");

  var searchcombo = GenerateSearchCombo(configIdx);

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

function GenerateSearchResultsDiv()
{
  var resultdiv = document.createElement('div');
  //$(resultdiv).addClass("scroll-pane");
  $(resultdiv).addClass("searchresults");
  return resultdiv;
}

function OpenNewSearchPanel(config)
{
  var panelName = PanelController.GetNewPanelId();
  var left = 200 + 20*PanelCount + "px";
  var top = 10 + 20*PanelCount +  "px";
  var wid = "525px";
  var hgt = "600px";
  var maxZidx = GetMaxZIndex();
  var panelTitle = "Search " + searchPanelCount;

  CreateNewSearchPanel(panelName, left, top, wid, hgt, maxZidx + 1, panelTitle, "", config)
  var position = GetPanelPosition('#' + panelName);

  PanelController.AddMainPanel(panelName, position, undefined, panelTitle, maxZidx + 1);
  searchPanelCount++;
}

function CreateNewSearchPanelObj(panelObj)
{
  if (panelObj != undefined)
  {
    CreateNewSearchPanel(panelObj.Id, panelObj.Position.Left, panelObj.Position.Top, panelObj.Position.Width,
                         panelObj.Position.Height, panelObj.ZIndex, panelObj.Title, panelObj.Url, 0);
  }
}

function CreateNewSearchPanel(id, left, top, wid, hgt, zIdx, title, url, config)
{
  var searchpanel = document.createElement('div');

  $(searchpanel).addClass("draggable ui-widget-content whiteback");
  $(searchpanel).attr("id", id);
  $(searchpanel).attr("onclick", "BringToFront(this);");
  $(searchpanel).css("position", "absolute");
  $(searchpanel).css("left", left);
  $(searchpanel).css("top", top);
  $(searchpanel).css("width", wid);
  $(searchpanel).css("height", hgt);
  $(searchpanel).css("z-index", zIdx);

  var titlep = GeneratePanelTitle(title, 0, false);
  $(searchpanel).append(titlep);

  var query = "";
  if (url != undefined && url != "")
  {
    var urlObj = GetUrlParams(url);
    var xContext = urlObj['x-context'];
    config = GetSearchIdx(xContext);
    query = urlObj['query'];
  }

  $(searchpanel).append(GenerateSearchInputs(config, query));
  $(searchpanel).append(GenerateSearchNavigation());

  var searchResultDiv = GenerateSearchResultsDiv();
  var newHeight = parseInt(hgt.replace(/px/g, "")) - 105;
  $(searchResultDiv).css("height", newHeight + "px");
  $(searchpanel).append(searchResultDiv);

  $("#snaptarget").append(searchpanel);
  InitDraggable(searchpanel);
}

function CreateNewSubPanelObj(panelObj)
{
  if (panelObj == undefined) return;

  return CreateNewSubPanel(panelObj.Id, panelObj.Position.Left, panelObj.Position.Top,
                             panelObj.Position.Width, panelObj.Position.Height, panelObj.ZIndex,
                             panelObj.Title, panelObj.Url, panelObj.Pinned, panelObj.Type);
}

function CreateNewSubPanel(panelId, left, top, wid, hgt, zIdx, title, url, pinned, type)
{
  var newPanel = document.createElement('div');
  $(newPanel).addClass("draggable ui-widget-content whiteback");

  $(newPanel).attr("id", panelId);
  $(newPanel).attr("onclick", "BringToFront(this);");
  $(newPanel).css("position", "absolute");

  $(newPanel).css("left", left);
  $(newPanel).css("top", top);
  $(newPanel).css("width", wid);
  $(newPanel).css("height", hgt);
  $(newPanel).css("z-index", zIdx);

  var titlep = GeneratePanelTitle(title, 1, pinned);
  $(newPanel).append(titlep);
  var searchResultDiv = GenerateSearchResultsDiv();
  $(searchResultDiv).css('height', $(newPanel).height() - 35);
  $(newPanel).append(searchResultDiv);

  $("#snaptarget").append(newPanel);
  CorrectSearchResultHeight(newPanel);

  if (type == "image")
    GetFacsimile(newPanel, url);
  else if (type == "text")
    GetFullText(newPanel, url);

  InitDraggable(newPanel);

  return newPanel;
}

function OpenSubPanel(elem, filename, pinned, type)
{
  var paneldiv = $(elem).parents(".draggable");
  var parentId = $(paneldiv).attr('id');

  var panel;

  if (type == "image")
  {
    panel = PanelController.GetPinnedImagePanelId(parentId);
    filename = filename.replace(/xml/g, "jpg");
  }
  else if (type == "text")
    panel = PanelController.GetPinnedTextPanelId(parentId);

  if (panel == null)
  {
    var panelId = PanelController.GetNewPanelId();

    var parentId = $(paneldiv).attr('id');

    var wid = parseInt($(paneldiv).css("width").replace(/px/g, ""));
    var lef = parseInt($(paneldiv).css("left").replace(/px/g, ""));

    var left = lef + wid + 15 + "px";
    var top = $(paneldiv).css("top");
    var width = "350px";
    var height = $(paneldiv).css("height");

    var zIdx = GetMaxZIndex() + 1;
    var panelTitle = "";

    if (type == "image")
      panelTitle = "Facsimile";
    else if (type == "text")
      panelTitle = "Full text";

    var newPanel = CreateNewSubPanel(panelId, left, top, width, height, zIdx, panelTitle, filename, pinned, type)

    var position = GetPanelPosition(newPanel);
    if (type == "image")
      PanelController.AddImagePanel(parentId, panelId, pinned, position, filename, panelTitle, zIdx);
    else if (type == "text")
      PanelController.AddTextPanel(parentId, panelId, pinned, position, filename, panelTitle, zIdx);
  }
  else
  {
    var newPanel = $('#' + panel);
    PanelController.SetPanelUrl(panel, filename);

    if (type == "image")
      GetFacsimile(newPanel, filename);
    else if (type == "text")
      GetFullText(newPanel, filename);

    InitDraggable(newPanel);
  }
}

function MaximizePanel(titlep)
{
  var paneldiv = $(titlep).parents(".draggable");
  $(paneldiv).css("left", "5px");
  $(paneldiv).css("top", "0px");
  var wid = $("#mainpanel").width();
  var hgt = $("#mainpanel").height();
  $(paneldiv).css("width", wid-30);
  $(paneldiv).css("height", hgt-25);

  var maxZidx = GetMaxZIndex();
  $(paneldiv).css("z-index",maxZidx + 1);

  //var hgt = parseInt($(paneldiv).css("height").replace(/px/g, ""));
  //$(paneldiv).find(".scroll-pane").css("height", hgt - 150 + "px");

  CorrectSearchResultHeight(paneldiv);

  $(titlep).find(".titletopiconmax").attr("src", "scripts/style/img/n.win_norm.png");
  $(titlep).find(".titletopiconmax").parent().attr("onclick", "NormalizePanel(this);");
}

function NormalizePanel(titlep)
{
  var paneldiv = $(titlep).parents(".draggable");
  var pos = LoadPanelPosition(paneldiv);

  if (pos)
  {
    $(paneldiv).css("left", pos.Left);
    $(paneldiv).css("top", pos.Top);
    $(paneldiv).css("width", pos.Width);
    $(paneldiv).css("height", pos.Height);

    var maxZidx = GetMaxZIndex();
    $(paneldiv).css("z-index",maxZidx + 1);
  }

  //var hgt = parseInt($(paneldiv).css("height").replace(/px/g, ""));
  //$(paneldiv).find(".scroll-pane").css("height", hgt - 150 + "px");

  CorrectSearchResultHeight(paneldiv);

  $(titlep).find(".titletopiconmax").attr("src", "scripts/style/img/n.win_max.png");
  $(titlep).find(".titletopiconmax").parent().attr("onclick", "MaximizePanel(this);");
}
function ClosePanel(titlep)
{
  var paneldiv = $(titlep).parents(".draggable");
  var panelId = $(paneldiv).attr('id');

  $(paneldiv).remove();
  PanelController.RemovePanel(panelId);
}

function PinPanel(elem, col)
{
  var paneldiv = $(elem).parents(".draggable");
  var panelId = $(paneldiv).attr('id');

  if (col == 1)
  {
    $(paneldiv).find(".titletopiconpin").attr("src", "scripts/style/img/pin.gray.png");
    $(paneldiv).find(".titletopiconpin").removeClass("pinned");
    $(paneldiv).find(".titletopiconpin").parent().attr("onclick", "PinPanel(this, 2);");
    PanelController.SetPanelNotPinned(panelId);
  }
  else
  {
    $(paneldiv).find(".titletopiconpin").attr("src", "scripts/style/img/pin.color.png");
    $(paneldiv).find(".titletopiconpin").addClass("pinned");
    $(paneldiv).find(".titletopiconpin").parent().attr("onclick", "PinPanel(this, 1);");
    PanelController.SetPanelPinned(panelId);
  }

}

function CorrectSearchResultHeight(paneldiv)
{
  var hgt = parseInt($(paneldiv).css("height").replace(/px/g, ""));
  if ($(paneldiv).find(".searchstring").length != 0)
    $(paneldiv).find(".scroll-pane").css("height", hgt - 105 + "px");
  else
    $(paneldiv).find(".scroll-pane").css("height", hgt - 25 + "px");
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

  for (panelName in PanelController.Panels)
  {
    var tr = document.createElement('tr');
    var td = document.createElement('td');
    var a = document.createElement('a');

    $(td).attr('colspan','2');

    $(a).addClass('sidebar');
    $(a).attr('href','#');
    $(a).attr('onclick','BringToFront("#' + panelName + '");');
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
        $(aSub).attr('onclick','BringToFront("#' + subPanelName + '");');
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
  ClearPanels();
  PanelController.Panels = ProfileController.GetProfile(name);
  PanelController.ProfileName = name;

  searchPanelCount = 0;
  PanelCount = 0;

  for (var key in PanelController.Panels)
  {
    searchPanelCount++;
    PanelCount++;
    var panel = PanelController.Panels[key];
    CreateNewSearchPanelObj(panel);
    if (panel.Url != undefined && panel.Url != "")
      StartSearch("#" + panel.Id + " .searchbutton");

    for (var subKey in panel.Panels)
    {
      PanelCount++;
      var subPanel = panel.Panels[subKey];
      CreateNewSubPanelObj(subPanel);
    }
  }
  updating = false;
  PanelController.RefreshUsedPanels();
}

function ClearPanels()
{
   $("div.draggable").each(function()
   {
     $(this).remove();
   });
   PanelCount = 0;
   searchPanelCount = 1;
}

function RemoveAllPanels()
{
  ClearPanels();
  PanelController.RemoveAllPanels();
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