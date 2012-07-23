function ProfileManager()
{
  this.Profiles = new Array();

  this.SetProfile = function(name, profile)
  {
    this.Profiles[name] = profile;
  }

  this.SetProfileAsNew = function(name, profile)
  {
    this.Profiles[name] = this.CloneProfile(profile);
  }

  this.GetProfile = function(name)
  {
    var profile = this.Profiles[name];
    if (profile == undefined)
      profile = new Array();

    return profile;
  }

  this.RenameProfile = function(name, newName)
  {
    var profile = this.Profiles[name];
    this.Profiles[newName] = profile;
    delete this.Profiles[name];
  }

  this.DeleteProfile = function(name)
  {
    var profile = this.Profiles[name];
    if (profile != undefined)
      delete this.Profiles[name];
  }

  this.GetProfileNames = function()
  {
    var list = new Array();
    for (var key in ProfileController.Profiles)
    {
      list.push(key);
    }

    return list;
  }

  this.CloneProfile = function(profile)
  {
    var newProfile = jQuery.extend(true, {}, profile);
    return newProfile;
  }
}

var ProfileController = new ProfileManager();