var PanelCount = 0;
var PanelPostions = new Array();

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

function SavePanelPositon(panel)
{
  var panelid = $(panel).attr("id");
  PanelPostions[panelid] = new Array();
  PanelPostions[panelid]["left"] = $(panel).css("left");
  PanelPostions[panelid]["top"] = $(panel).css("top");
  PanelPostions[panelid]["width"] = $(panel).css("width");
  PanelPostions[panelid]["height"] = $(panel).css("height");
}

function LoadPanelPosition(panel)
{
  var panelid = $(panel).attr("id");
  return PanelPostions[panelid];
}

function BringToFront(panel)
{
  $( ".draggable" ).each(function(index)
  {
     if ($(this).css("z-index") != "10")
       $(this).css("z-index","10");
  });
  $(panel).css("z-index","11");
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
                 $(this).find(".scroll-pane").css("height", hgt - 120 + "px");
               else
                 $(this).find(".scroll-pane").css("height", hgt - 25 + "px");

               RefreshScrollPane(this);
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
	 OpenNewSearchPanel(-1);
	 var scombo = GenerateSearchCombo(0);
	 $(scombo).css("margin-top", "5px");
	 $("#searchbuttons").append(scombo);
});

function StartSearch(elem)
{
  var parElem = $(elem).parents(".draggable");
  var sstr = $(parElem).find(".searchstring").val();
  var sele = parseInt($(parElem).find(".searchcombo").val());

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
      // FIX: x-context gehört nicht in den query string
      //data : {operation: 'searchRetrieve', query: SearchConfig[sele]['x-context'] + '=' + sstr, 'x-context': SearchConfig[sele]['x-context'], 'x-format': 'html'},
      data : {operation: 'searchRetrieve', query: sstr, 'x-context': SearchConfig[sele]['x-context'], 'x-format': 'html', version: '1.2'},
      complete: function(xml, textStatus)
      {
        /*
        var api = $(parElem).find('.scroll-pane').data('jsp');

     			api.getContentPane().html(xml.responseText);
     			api.reinitialise();
     			*/

				var resultPane = $(parElem).find(".searchresults")

				resultPane.removeClass("cmd loading");

				// What does this do??
     			if ($(parElem).find(".searchresults .scroll-content").length > 0)
     			{
          $(parElem).find(".searchresults .scroll-content").html(xml.responseText);
          RefreshScrollPane(parElem);
     			}
     	  else
     		 {
          $(resultPane).html(xml.responseText);
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
     			if ($(parElem).find(".searchresults .scroll-content").length > 0)
     			{
          $(parElem).find(".searchresults .scroll-content").html(xml.responseText);
          RefreshScrollPane(parElem);
     			}
     	  else
     		 {
          $(parElem).find(".searchresults").html(xml.responseText);
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
      url: "http://corpus3.aac.ac.at/cs/gethtml.php",
//          url: "/ddconsru",
      dataType: 'xml',
      data : {txt: filename},
      complete: function(xml, textStatus)
      {
/*
        //var resText = xml.responseText;
        //alert(resText);
        var srdiv =  $(elem).find(".searchresults");
        //var str = $(srdiv).html();
        //alert(str);
        $(srdiv).html(xml.responseText);
        RefreshScrollPane(elem);
*/

     			if ($(parElem).find(".searchresults .scroll-content").length > 0)
     			{
          $(elem).find(".searchresults .scroll-content").html(xml.responseText);
          RefreshScrollPane(elem);
     			}
     	  else
     		 {
          $(elem).find(".searchresults").html(xml.responseText);
          InitScrollPane(elem);
        }
        $(elem).find(".hitcount").text($(".recordcount").val());

      }
  }
  );
}

function GetFacsimile(elem, filename)
{
  if ($(parElem).find(".searchresults .scroll-content").length > 0)
		{
    $(elem).find(".searchresults .scroll-content").html('<img src="getimage.php?img=' + filename + '" />');
    RefreshScrollPane(elem);
		}
  else
	 {
    $(elem).find(".searchresults").html('<img src="getimage.php?img=' + filename + '" />');
    InitScrollPane(elem);
  }
}

function GeneratePanelTitle(titlestring, pin)
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
    	$(pina).attr("onclick", "PinPanel(this, 2);");
    	$(pina).addClass("noborder");

    	var pinimg = document.createElement('img');
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

function GenerateSearchInputs(config)
{
 	var searchdiv = document.createElement('div');
 	$(searchdiv).addClass("searchdiv");
 	$(searchdiv).text("Search for ");

 	var searchstring = document.createElement('input');
 	$(searchstring).addClass("searchstring");
 	$(searchstring).attr("type", "text");

 	var searchbutton = document.createElement('input');
 	$(searchbutton).addClass("searchbutton");
 	$(searchbutton).attr("type", "button");
 	$(searchbutton).attr("value", "Go");
 	$(searchbutton).attr("onclick", "StartSearch(this);");

 	var searchcombo = GenerateSearchCombo(config);

 	$(searchdiv).append(searchstring);
 	//var searchbr = document.createElement('br');
 	//$(searchdiv).append(searchbr);

 	$(searchdiv).append(" in ");
 	$(searchdiv).append(searchcombo);
 	$(searchdiv).append(" ");
 	$(searchdiv).append(searchbutton);

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
 	var searchpanel = document.createElement('div');
 	PanelCount++;
 	$(searchpanel).addClass("draggable ui-widget-content");
 	$(searchpanel).attr("id", "Panel" + PanelCount);
 	$(searchpanel).attr("onclick", "BringToFront(this);");
 	$(searchpanel).css("position", "absolute");
 	$(searchpanel).css("left", 200 + 20*PanelCount + "px");
 	$(searchpanel).css("top", 10 + 20*PanelCount +  "px");
 	$(searchpanel).css("width", "510px");
 	$(searchpanel).css("height", "300px");
 	$(searchpanel).css("z-index", "12");

 	var titlep = GeneratePanelTitle("Search " + PanelCount, 0);
 	$(searchpanel).append(titlep);
 	$(searchpanel).append(GenerateSearchInputs(config));
 	$(searchpanel).append(GenerateSearchNavigation());
 	$(searchpanel).append(GenerateSearchResultsDiv());

 	$("#snaptarget").append(searchpanel);
 	InitDraggable(searchpanel);
 	//InitScrollPane(searchpanel);
}

function OpenTextPanel(elem, filename)
{
  var paneldiv = $(elem).parents(".draggable");

 	var textpanel = document.createElement('div');
 	PanelCount++;
 	$(textpanel).addClass("draggable ui-widget-content");
 	$(textpanel).attr("id", "Panel" + PanelCount);
 	$(textpanel).attr("onclick", "BringToFront(this);");
 	$(textpanel).css("position", "absolute");

 	var wid = parseInt($(paneldiv).css("width").replace(/px/g, ""));
 	var lef = parseInt($(paneldiv).css("left").replace(/px/g, ""));

 	$(textpanel).css("left", lef + wid + 15 + "px");
 	$(textpanel).css("top", $(paneldiv).css("top"));
 	$(textpanel).css("width", "350px");
 	$(textpanel).css("height", $(paneldiv).css("height"));
 	$(textpanel).css("z-index", "12");

 	var titlep = GeneratePanelTitle("Full text '" + filename + "'", 1);
 	$(textpanel).append(titlep);
 	$(textpanel).append(GenerateSearchResultsDiv());

 	$("#snaptarget").append(textpanel);
 	CorrectSearchResultHeight(textpanel);

 	GetFullText(textpanel, filename);
 	InitDraggable(textpanel);
 	//InitScrollPane(textpanel);
}

function OpenImagePanel(elem, filename)
{
  var paneldiv = $(elem).parents(".draggable");
  filename = filename.replace(/xml/g, "jpg");

 	var textpanel = document.createElement('div');
 	PanelCount++;
 	$(textpanel).addClass("draggable ui-widget-content");
 	$(textpanel).attr("id", "Panel" + PanelCount);
 	$(textpanel).attr("onclick", "BringToFront(this);");
 	$(textpanel).css("position", "absolute");

 	var wid = parseInt($(paneldiv).css("width").replace(/px/g, ""));
 	var lef = parseInt($(paneldiv).css("left").replace(/px/g, ""));

 	$(textpanel).css("left", lef + wid + 15 + "px");
 	$(textpanel).css("top", $(paneldiv).css("top"));
 	$(textpanel).css("width", "350px");
 	$(textpanel).css("height", $(paneldiv).css("height"));
 	$(textpanel).css("z-index", "12");

 	var titlep = GeneratePanelTitle("Facsimile '" + filename + "'", 1);
 	$(textpanel).append(titlep);
 	$(textpanel).append(GenerateSearchResultsDiv());

 	$("#snaptarget").append(textpanel);
  CorrectSearchResultHeight(textpanel);

 	GetFacsimile(textpanel, filename);

 	InitDraggable(textpanel);
 	//InitScrollPane(textpanel);
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
 	$(paneldiv).css("z-index", "25");

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
   	$(paneldiv).css("left", pos["left"]);
   	$(paneldiv).css("top", pos["top"]);
   	$(paneldiv).css("width", pos["width"]);
   	$(paneldiv).css("height", pos["height"]);
   	$(paneldiv).css("z-index", "25");
 	}

  //var hgt = parseInt($(paneldiv).css("height").replace(/px/g, ""));
  //$(paneldiv).find(".scroll-pane").css("height", hgt - 150 + "px");

  CorrectSearchResultHeight(paneldiv);

  $(titlep).find(".titletopiconmax").attr("src", "scripts/style/img/n.win_max.png");
  $(titlep).find(".titletopiconmax").parent().attr("onclick", "MaximizePanel(this);");
}

function ClosePanel(titlep)
{
 	$(titlep).parents(".draggable").remove();
}

function PinPanel(elem, col)
{
 	var paneldiv = $(elem).parents(".draggable");

  if (col == 1)
  {
    $(paneldiv).find(".titletopiconpin").attr("src", "scripts/style/img/pin.gray.png");
    $(paneldiv).find(".titletopiconpin").removeClass("pinned");
    $(paneldiv).find(".titletopiconpin").parent().attr("onclick", "PinPanel(this, 2);");
  }
  else
  {
    $(paneldiv).find(".titletopiconpin").attr("src", "scripts/style/img/pin.color.png");
    $(paneldiv).find(".titletopiconpin").addClass("pinned");
    $(paneldiv).find(".titletopiconpin").parent().attr("onclick", "PinPanel(this, 1);");
  }

}

function CorrectSearchResultHeight(paneldiv)
{
  var hgt = parseInt($(paneldiv).css("height").replace(/px/g, ""));
  if ($(paneldiv).find(".searchstring").length != 0)
    $(paneldiv).find(".scroll-pane").css("height", hgt - 150 + "px");
  else
    $(paneldiv).find(".scroll-pane").css("height", hgt - 25 + "px");
}



