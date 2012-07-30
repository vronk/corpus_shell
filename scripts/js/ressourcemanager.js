function ResourceManager ()
{
  this.Resources = new Array();

  this.AddResource = function (resname, restitle)
  {
    this.Resources[resname] = this.GetNewResourceObject(resname, restitle);
  }

  this.AddIndex = function (resname, idxname, idxtitle, searchable, scanable, sortable)
  {
    if (this.Resources[resname] != undefined)
      this.Resources[resname].Indexes[idxname] = this.GetNewIndexObject(idxname, idxtitle, searchable, scanable, sortable);
  }

  this.GetNewResourceObject = function (name, title)
  {
    var newObj = new Object();
    newObj["Name"] = name;
    newObj["Title"] = title;
    newObj["Indexes"] = new Array();

    return newObj;
  }

  this.GetNewIndexObject = function (name, title, searchable, scanable, sortable)
  {
    var newObj = new Object();
    newObj["Name"] = name;
    newObj["Title"] = title;
    newObj["Searchable"] = searchable;
    newObj["Scanable"] = scanable;
    newObj["Sortable"] = sortable;

    return newObj;
  }

  this.GetLabelValueArray = function (resname)
  {
    var list = new Array();

    if (this.Resources[resname] != undefined)
    {
      resource = this.Resources[resname];
      for (key in resource.Indexes)
      {
        var index = resource.Indexes[key];
        var ary = new Array();
        ary['label'] = index.Title;
        ary['value'] = index.Name;
        list.push(ary);
      }
    }

    return list;
  }

}

var ResourceController = new ResourceManager();