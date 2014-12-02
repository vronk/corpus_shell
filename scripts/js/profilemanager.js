/**
 * @fileOverview Provides the ProfileManager class and the ProfileController object.
 * @author Andy Basch
 */

/**
 * @module corpus_shell 
 */

// Everything here assumes $ === jQuery so ensure this
!function ($) {
    
    //publish
    this.ProfileController = new ProfileManager();

/**
 * @classdesc A class for managing the profiles that contain queries, windows and their layout.
 * @constructor 
 */
function ProfileManager()
{
  /**
   * A "map" (that is an object with ever extending dynamic properties) of maps for
   * {@link MainPanelObject}s.
   * @type {map<map<MainPanelObject>>} 
   */
  this.Profiles = new Array();

  /**
   * @param {string} name Name of the profile.
   * @param {map<MainPanelObject>} profile A Profile to set.
   * @desc Set a particular profile by name
   * @return -
   */
  this.SetProfile = function(name, profile)
  {
    this.Profiles[name] = profile;
  };

  /**
   * @param {string} name New name of the profile.
   * @param {map<MainPanelObject>} profile A Profile to clone.
   * @desc Set a clone of a particular profile by name
   * @return -
   */
  this.SetProfileAsNew = function(name, profile)
  {
    this.Profiles[name] = this.CloneProfile(profile);
  };

  /**
   * @param {string} name Name of the profile.
   * @desc Retrieve a profile by name.
   * @return {map<MainPanelObject>} The profile stored by this name. If there is now profile stored a new empty object is returned.
   */
  this.GetProfile = function(name)
  {
    var profile = this.Profiles[name];
    if (profile === undefined)
      profile = new Array();

    return profile;
  };

  /**
   * @param {string} name Name of the profile.
   * @param {string} newName New name of the profile.
   * @desc Rename a profile.
   * @return -
   */
  this.RenameProfile = function(name, newName)
  {
    var profile = this.Profiles[name];
    this.Profiles[newName] = profile;
    delete this.Profiles[name];
  };

  /**
   * @param {string} name Name of the profile.
   * @desc Delete the profile stored by this name.
   * @return -
   */
  this.DeleteProfile = function(name)
  {
    var profile = this.Profiles[name];
    if (profile !== undefined)
      delete this.Profiles[name];
  };

  /**
   * @desc Retrieves the name of all profiles stored in {@link module:corpus_shell~ProfileController}.
   * That is not necessaryly the list of all profiles in this ProfileManager.
   * @return array.<string> The profile names 
   */
  this.GetProfileNames = function()
  {
    var list = new Array();
    for (var key in this.Profiles)
    {
      list.push(key);
    }

    return list;
  };

  /**
   * @param {map.<MainPanelObject>} profile A profile to clone.
   * @desc Creates an independent clone, a deep copy, of the given profile.
   * @return {map.<MainPanelObject>} The cloned profile.
   */
  this.CloneProfile = function(profile)
  {
    var newProfile = $.extend(true, {}, profile);
    return newProfile;
  };
}
this.ProfileController = new ProfileManager();
}(jQuery);