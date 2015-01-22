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
var Indexes = null;

/**
 * 
 * @type {string} A title that is to be displayed on the Tab of the browser.
 */

var sitesTitle;

function split( val )
{
  return val.split( /=\s*/ );
}

function extractLast( term )
{
  return split( term ).pop();
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
            out.push(inVal.replace(/(["\\])/g, '\\$1').replace(/\r/g, '').replace(/\n/g, '\n'));
            out.push('"');
            return out;

        default:
            out.push(String(inVal));
            return out;
    }
}

// Everything here assumes $ === jQuery so ensure this
(function ($, PanelController, ResourceController, ProfileController, params, URI, HTMLOnDemandLoader) {

/**
 * @summary Get parameters from the supplied uri/url
 * @desc Returns them as a "map" (a JavaScript object which properties correspond to the parameters).
 *       Does not depend on $ as jQuery and is used by other modules (panel.js) too.
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
 * @summary Initialization for the corpus_shell app. Run on $(document).ready().
 * @desc
 * <ol>
 * <li>Bind events to DOM elements that do exist when the document is loaded, that is everything belonging to the side bar.</li>
 * <li>Bind events to DOM elements that may not exist in the current DOM tree using jQuery.
 *     These DOM elements are generated by some search request results so further functionality can be provided.
 *   <ul>
 *     <li>For every link in a .data-view .full class container in a .searchresults the default behavior is replaced by the 
 *         {@link module:corpus_shell~PanelManager#OpenSubPanel} method. This method is used to open a full text sub panel.</li>
 *     <li>For every link in a .data-view .full class container in a .searchresults the default behavior is replaced by the 
 *         {@link module:corpus_shell~PanelManager#OpenSubPanel} method. This method is used to open an image sub panel which shows the facsimile.</li>
 *     <li>For every link of class .value-caller in a .searchresults for a kwic search result the default behavior is replaced by the 
 *         {@link module:corpus_shell~PanelManager#OpenSubPanel} method.
 *     </li>
 *     <li>For every link of class .search-caller in a .searchresults for a scan result the default behavior is replaced by the 
 *         {@link module:corpus_shell~PanelManager#OpenNewSearchPanel} method.
 *     </li>
 *     <li>For every link in a .navigation class container in a .searchresults the default behavior is replaced by the 
 *         {@link module:corpus_shell~PanelManager#OpenSubPanel} method. This method is used to enable page navigation in full text views.</li>
 *      </ul>
 * </li>
 * <li>Tries to get a user id.</li>
 * <li>Initiates asynchrounous loading of the profiles and the index data.</li>
 * <li>Installs a handler for the {@link module:corpus_shell~PanelManager#event:onUpdated} event of {@link module:corpus_shell~PanelController}.</li>
 * <li>Displays a URL which contains the current user ID in a DOM element designated by #userid</li>
 * <li>Generates a drop down list with search targets using {@link module:corpus_shell~GenerateSearchCombo} into the DOM element designated by #searchbuttons and preselects the first item</li>
 * <li>Generates a drop down list with profiles using {@link module:corpus_shell~GenerateProfileCombo} right after the DOM element designated by #profiledel and preselects the first item</li>
 * </ol>
 * Note: The function is written in a style that enables the user/developer to see the program flow until the initialization is finished. This is achieved
 * by deliberately using anonymous functions as callbacks. Please keep in mind that there is a variable delay between the call to Get...() and the execution
 * of the following code block.
 */
function doOnDocumentReady ()
{
    $(".sidebartoggle").bind("click", function() {
        ToggleSideBar();
    });
    $(".sidebartoggle").bind("mouseover", function() {
        ToggleSideBarHiLight(1);
    });
    $(".sidebartoggle").bind("mouseout", function() {
        ToggleSideBarHiLight(0);
    });
    
    $('#searchbuttons .sidebar').bind("click", function () {
        PanelController.OpenNewSearchPanel(parseInt($('#searchbuttons .searchcombo').val(), 10));
    });
    
    $('#TogglePanelListButton').bind("click", function () {
        TogglePanelList();
    });
    
    $('#profileload').bind("click", function () {
       LoadProfile($('#profilebuttons .searchcombo').val());
    });
    
    $('#profiledel').bind("click", function () {
       DeleteProfile($('#profilebuttons .searchcombo').val());
    });

    $('#profilesave').bind("click", function () {
       SaveProfileAs($('#profilebuttons #newprofilename').val());
    });
    
    $('#profilenew').bind("click", function () {
       CreateNewProfile($('#profilebuttons #newprofilename').val());
    });

    $('#profilerefresh').bind("click", function () {
       GetUserData(userId);
    });
    
    $('#ShowIndexesButton').bind("click", function () {
       ShowIndexCache();
    });

    var clickHandled = false;
    var ordinaryLinkHandler = function (event) {
            var target = $(this).attr('target');
            var href = $(this).attr('href');
            var targetURI = URI(href).protocol(URI().protocol());
            var internal = URI(params.switchURL).equals(targetURI.search("").normalize()) &&
                    !$(this).hasClass("search-caller");
            if ((target === undefined || target === "") && ((href.indexOf('#') > 0) || internal)) {
                event.preventDefault();
                PanelController.OpenSubPanel(this, href, true, "text");
                clickHandled = true;
            } else if (href.indexOf('archive.org') >= 0) {
                event.preventDefault();
                PanelController.OpenNewContentPanel(href, "Book ");
                clickHandled = true;
            }
      };
    $(document).on("click", '.tei-fs a.search-caller', function(){       
        var href = $(this).attr('href');
        var targetURI = URI(href).protocol(URI().protocol());
        HTMLOnDemandLoader.fetchUrlIntoTag(targetURI.normalize().href(), $(this).parent(), $(this).parent().parent(), '15em', '4em');
        clickHandled = true;
    })
    $(document).on("click", '.searchresults .data-view.full a', ordinaryLinkHandler);
    $(document).on("click", '.searchresults .data-view.application_x-clarin-fcs-kwic_xml a', ordinaryLinkHandler);
    $(document).on("click", '.searchresults .data-view.image a', function (event) {
            var target = $(this).attr('target');
            if (target === undefined || target === "") {
                event.preventDefault();
                PanelController.OpenSubPanel(this, $(this).attr('href'), true, "image");
                clickHandled = true;
            }
      });
    $(document).on("click", '.searchresults a.value-caller', function (event) {
        event.preventDefault();
        if (clickHandled === true) {
            clickHandled = false;
            return;
        }
        clickHandled = false;
        var target = $(this).attr('href');
        if (target.indexOf('http://') === -1) {
            target = params.switchURL + target;
        }
        PanelController.OpenSubPanel(this, target, true, "text");
      });
    $(document).on("click", '.searchresults a.search-caller', function (event) {
        event.preventDefault();
            if (clickHandled === true) {
            clickHandled = false;
            return;
        }
        clickHandled = false;
        var target = $(this).attr('href');
        var urlParams = GetUrlParams(target);
        var ID = PanelController.OpenNewSearchPanel(urlParams['x-context'], urlParams.query, urlParams['x-dataview']);
        PanelController.StartSearch(ID);
      });
    $(document).on("click", '.searchresults .navigation a', function (event) {
         event.preventDefault();
         PanelController.OpenSubPanel(this, $(this).attr('href'), true, "text");
         clickHandled = true;
      });
    $(document).on("click", 'a.c_s_fcs_xml_link', function (event) {
        event.preventDefault();
        PanelController.OpenNewContentPanel($(this).attr('href'), 'XML ');
    });
    $(document).on("click", 'a.c_s_tei_xml_link', function (event) {
        event.preventDefault();
        PanelController.OpenNewContentPanel($(this).attr('href'), 'TEI ');
    });
    if (sitesTitle === undefined)
        sitesTitle = document.title;
    var urlParams = GetUrlParams(location.search);
    GetUserId(urlParams, function() {
    // the $(document).ready callback returns here. The following code is executed after a delay that depends on how userId is fetched and
    // if that is successful. A debugger will most probably not step into this block using its single step function.
        updating = true;
        GetUserData(userId, function(result) {
            // The following code is executed after a delay that depends on how the users previous panel setup is fetched and
            // if that is successful. A debugger will most probably not step into this block using its single step function.
            // If there is no such profile on the server yet or it is unreadable
            // or whatever else bad happened a new Array is returned.
            if (result.length === 0)
               ProfileController.SetProfile(PanelController.ProfileName, PanelController.Panels);
            else
               ProfileController.Profiles = result;
            var currentProfile = PanelController.ProfileName;
            PanelController.ProfileName = "";
            RefreshProfileCombo(currentProfile);
            if (ProfileController.Profiles._sideBarOpen === false) {
                ToggleSideBar();
            }
            updating = false;
            LoadIndexCache(function() {
            // The following code is executed after a delay that depends on how the data about available resources is fetched and
            // if that is successful. A debugger will most probably not step into this block using its single step function.
                PanelController.onUpdated = function(changeText) {
                    if (!updating) {
                        RefreshPanelList();
                        ProfileController.SetProfile(PanelController.ProfileName, PanelController.Panels);
                        SaveUserData(userId);
                    }
                };

                $("#userid").val(GenerateUseridLink(userId));

                var scombo = GenerateSearchCombo(0);
                $(scombo).css("margin-top", "5px");
                $("#searchbuttons").append(scombo);

                var pcombo = GenerateProfileCombo(0);
                $("#profiledel").after(pcombo);

                LoadProfile(currentProfile);
            });
        });
    });

};

$(document).ready(doOnDocumentReady);

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

  if (pos !== -1)
    url = url.substr(0, pos);

  return url + "?userId=" + encodeURIComponent(userId);
}

/**
 * @summary Tries to get a new user ID (a GUID) from the {@link ../phpdocs/user-data/_userdata---getUserId.php.html modules/userdata/getUserId.php} script.
 * @desc Retrieval is done asynchronously so this function returns immediately and the actual result may be valid only later.</br>
 * If userId retrieved by this function is used then put the code that uses it into an onComplete handler.
 * @param {map} urlParams A map (associative array) with a key value pair of userId = username. Eg. the return value of {@link module:corpus_shell~PanelManager#GetUrlParams}.
 * @param {function} [onComplete] Code to execute on completion of the request. Note that the two usual parameters my be undefined if the userId was retrieved from the URL.
 * @param {function} [onError] Code to execute on failure.
 * @return -
 */
function GetUserId(urlParams, onComplete, onError) {
    if (urlParams['userId'] && urlParams['userId'] != "") {
        userId = urlParams['userId'];
        onComplete();
    } else {
        $.ajax({
            dataType : "json",
            url : baseURL + userData + "getUserId.php",
            success : function(data) {
                userId = data.id;
                try {
                    localStorage.setItem("userId", userId);
                } catch (e) {
                    // most probably IE on localhost
                    if(!window.console){ window.console = {log: function(){} }; }
                    window.console.log("Error using localStorage. Is this an IE trying to use localStorage for localhost? If yes then consider this a security feature.")
                }
            },
            error : function() {
                try {
                    userId = localStorage.getItem("userId");
                } catch (e) {
                    // most probably IE on localhost
                    if(!window.console){ window.console = {log: function(){} }; }
                    window.console.log("Error using localStorage. Is this an IE trying to use localStorage for localhost? If yes then consider this a security feature.")
                }
                if (onError !== undefined && typeof (onError) === 'function')
                    onError(jqXHR, textStatus, textThrown);
            },
            complete : function(result, jqXHR, textStatus) {
                if (onComplete !== undefined && typeof (onComplete) === 'function')
                    onComplete(result, jqXHR, textStatus);
            },
        });
    }
}


/**
 * @summary Tries to retrieve profile settings saved on the server.<br/>
 * @desc Retrieval is done asynchronously so this function returns immediately and the actual result may be valid only later.</br>
 * If the data retrieved by this function is used then put the code that uses it into an onComplete handler.</br>
 * If contacting the the script fails the browsers localstore is used.
 * <ol>
 * <li>Interprets the server's answer as JSON and if this fails uses data from local store instead.</li>
 * <li>Passes the data to {@link module:corpus_shell~ProfileController} as {@link module:corpus_shell~ProfileManager#Profiles}</li>
 * </ol>
 * @param {string} userId The user id for which the data should be retrieved. May be an GUID for example.
 * @param {function} [onComplete] Code to execute on completion of the request.
 * @param {function} [onError] Code to execute on failure.
 * @return -
 */
function GetUserData(userId, onComplete, onError)
{
  $.ajax(
  {
      type: 'POST',
      url: baseURL + userData + "getUserData.php",
      dataType: 'json',
      data : {uid: userId},
      complete: function(jqXHR, textStatus)
      {
        var result = null;
        try {
            result = JSON.parse(jqXHR.responseText, null);
        }
        catch (e) {
            // make-it-work hack: if this is unintelligable go to the localstore and fetch data from there
            try {
              var dataStr = localStorage.getItem(userId + "_Profiles");
              result = JSON.parse(dataStr);
            } catch (e) {}
        }
        if (result === undefined || result === null || result === false || result === "" )
          result = new Array();
        if (onComplete !== undefined && typeof(onComplete) === 'function')
           onComplete(result, jqXHR, textStatus);
      },
      error: function(jqXHR, textStatus, errorThrown) {
          if (onError !== undefined && typeof(onError) === 'function')
             onError(jqXHR, textStatus, textThrown);
      },
  });
}

/**
 * @summary Loads the {@link module:corpus_shell~ResourceController}, a {@link module:corpus_shell~ResourceManager}, with data stored in indexCache.json.
 * @desc Retrieval is done asynchronously so this function returns immediately and the actual result may be valid only later.</br>
 * If the data retrieved by this function is used then put the code that uses it into an onComplete handler.
 * Does not work when run from another web server/local disk. Maybe fixed maybe not ...
 * @param {function} [onComplete] Code to execute on completion of the request.
 * @param {function} [onError] Code to execute on failure.
 * @return -
 */
function LoadIndexCache(onComplete, onError) {
    ResourceController.ClearResources();

    for (var i = 0; i < SearchConfig.length; i++) {
        var resName = SearchConfig[i]["x-context"];
        ResourceController.AddResource(resName, SearchConfig[i]["DisplayText"]);
    }

    $.ajax({
        dataType : "json",
        url : baseURL + 'scripts/js/indexCache.json',
        success : function(data) {
            $.each(data, function(key, val) {
                for (var index in val) {
                    var item = val[index];
                    ResourceController.AddIndex(key, item.idxName, item.idxTitle, item.searchable, item.scanable, item.sortable, item.native);
                }
            });
        },
        complete : function(jqXHR, textStatus) {
            if (onComplete !== undefined && typeof (onComplete) === 'function')
                onComplete(jqXHR, textStatus);
        },
        error : function(jqXHR, textStatus, errorThrown) {
            if (onError !== undefined && typeof (onError) === 'function')
                onError(jqXHR, textStatus, textThrown);
        },
    });
}

/**
 * @type {link} A manipulates a special link that could be used to save the url with
 * the userid for later use.
 */
var originalShareLink;

/**
 * Lock for not retrying user data saving unless last attempt succeeded or failed.
 * @type Boolean
 */
var saveUserDataLock = false;
/**
 * Remember to try to save again after the last attempt completet.
 * @type Boolean
 */
var changedWhileSaving = false;

/**
 * @desc Tries to save the users profile data to the server. As a backup saves the profile data to the local store.
 * Manipulates the browsers history so the link in the address bar changes using the updated userid.
 * @param {string} userid  The user id for which the data should be saved. May be an GUID for example.
 */
function SaveUserData(userid)
{
  var dataStr = json_encode(ProfileController.Profiles);

  // Now save things locally, may be something goes wrong on transmission ...
  // make-things-work hack: This only makes sense if we at least compare the local and the
  // remote profile at load time and then use the newer one.
  try {
    localStorage.setItem(userId + "_Profiles", dataStr);
  } catch (e) {
      // this fails on IE if this is running on localhost -> debugging :-(
  }
  if (saveUserDataLock === false) {
  saveUserDataLock = true;
  $.ajax(
  {
      type: 'POST',
      url: baseURL + userData + "saveUserData.php",
      dataType: 'xml',
      data : {uid: userid, data: dataStr},
      complete: function(jqXHR, textStatus)
      {
        // li.share a is for drupal/gratis. How to do this without drupal?
        function errorHandler() {
            History.replaceState(null, sitesTitle,"?userId=");
            if (originalShareLink !== undefined) {
                $("li.share a").attr("href", originalShareLink);
            }
        }
        // complete (!= success) is even called if the php is only a locally downloaded copy with no php
        // interpreter to run it, so it surely is no valid XML
        var shareLink = $("li.share a");
        saveUserDataLock = false;
        if (changedWhileSaving === true) {
            changedWhileSaving = false;
            SaveUserData(userId);
            return;
        }
        if (jqXHR.status === 200 && textStatus === "success") {
            var msg = $(jqXHR.responseXML).find("msg").text();
            if (msg === "ok") {
                History.replaceState(null, sitesTitle, "?userId=" + encodeURIComponent(userid));
                if (originalShareLink === undefined)
                    originalShareLink = shareLink.attr("href");
                $("li.share a").attr("href", "?userId=" + encodeURIComponent(userid));
            }
            else errorHandler();
            // TODO: display the message somewhere.
        } else errorHandler();
      }
  }
  );
  } else {
      changedWhileSaving = true;
  }
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
    ProfileController.Profiles._sideBarOpen = false;
    $("#sidebaricon").attr("src", "scripts/style/img/sidebargrip.right.png");
  }
  else
  {
    left = 0;
    ProfileController.Profiles._sideBarOpen = true;
    $("#sidebaricon").attr("src", "scripts/style/img/sidebargrip.left.png");
  }

  $("#sidebar").css("left", left+"px");
  SaveUserData(userId);
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
    if (profiles[pos] === "_sideBarOpen")
        continue;
    var profileoption = document.createElement('option');
    $(profileoption).prop("value", profiles[pos]);

    if (selEntry !== undefined)
    {
      if (profiles[pos] === selEntry)
        $(profileoption).prop("selected", true);
    }
    else
    {
      if (i === idx)
        $(profileoption).prop("selected", true);
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

     if (i === config)
       $(searchoption).prop("selected", true);

     $(searchoption).text(SearchConfig[i]["DisplayText"]);
     $(searchcombo).append(searchoption);
  }

  return searchcombo;
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
  if (name === PanelController.ProfileName)
      // nothing todo, might be desastrous to continue.
      return;
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
    PanelController.RemoveAllPanels();
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
  if (profileName == 'default')
  {
    alert('Cannot delete the default profile!');
    return;
  }

  if (confirm('Delete profile "' + profileName + '"?'))
  {
    if (PanelController.ProfileName === profileName)
    {
      LoadProfile('default');
    }
    ProfileController.DeleteProfile(profileName);
    SaveUserData(userId);
    RefreshProfileCombo();
  }
}

// unused as of now
function RefreshIndexes()
{
  for (var i = 0; i < SearchConfig.length; i++)
  {
    var resName = SearchConfig[i]["x-context"];
    ResourceController.AddResource(resName, SearchConfig[i]["DisplayText"]);
    GetIndexes(resName);
  }
}

// unused as of now
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

/**
 * 
 * TODO: How does this function work if GetResourceName seems to be undefined.
 * @return {array.<LabelValueObject>} 
 */
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

})(jQuery, PanelController, ResourceController, ProfileController, params, URI, HTMLOnDemandLoader);
