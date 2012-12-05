function ResourceManager()
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
      var resource = this.Resources[resname];
      for (key in resource.Indexes)
      {
        var index = resource.Indexes[key];
        var ary = new Array();
        ary['label'] = index.Title;
        ary['value'] = index.Name;
        list.push(ary);
      }
    }
    else
    {
      for (reskey in this.Resources)
      {
        var resource = this.Resources[reskey];
        for (key in resource.Indexes)
        {
          var index = resource.Indexes[key];

          //distinct -> add only unique values
          var found = false;

          //check if list contains indexName
          for (var idx=0; idx<list.length; idx++)
          {
            var item = list[idx];
            if (item.value == index.Name)
             found = true;
          }

          //add if list doesn't contain indexName
          if (found == false)
          {
            var ary = new Array();
            ary['label'] = index.Title;
            ary['value'] = index.Name;
            list.push(ary);
          }
        }
      }
    }

    return list;
  }

  this.ClearResources = function ()
  {
    for (reskey in this.Resources)
    {
      var resource = this.Resources[reskey];
      for (key in resource.Indexes)
      {
        delete resource.Indexes[key];
      }

      delete resource;
    }
  }

  this.GetIndexCache = function ()
  {
    var hStr = '<div id="openIndexList" style="height: 250px; overflow: auto;"><table id="indexList">';

    for (reskey in this.Resources)
    {
      var resource = this.Resources[reskey];

      hStr += '<tr><td colspan="4" class="dotted b">' + resource.Title + '</td></tr>';

      var cnt = 0;
      for (key in resource.Indexes)
      {
        hStr += '<tr><td rowspan="2" style="width: 15px;"></td>';
        var idx = resource.Indexes[key];
        hStr += '<td class="dotted" colspan="3">' + idx.Title + ' (' + idx.Name + ')</td></tr>';

        hStr += '<tr><td class="dottedr is' + idx.Searchable + '"';
        if (idx.Searchable == true)
          hStr += ' style="cursor: pointer;" onclick="PanelController.OpenNewSearchPanel(\'' + resource.Name + '\', \'' +  idx.Name + '=\');"';
        hStr += '>search</td>';
        hStr += '<td class="dottedr is' + idx.Scanable + '"'

        if (idx.Scanable == true)
          hStr += ' style="cursor: pointer;" onclick="PanelController.OpenNewScanPanel(\'' + resource.Name + '\', \'' +  idx.Name + '\');"';

        hStr += '>scan</td>';
        hStr += '<td class="dottedr is' + idx.Sortable + '">sort</td></tr>';
        hStr += '<tr><td colspan="3" style="height: 10px;"></td></tr>'
        cnt++;
      }
      if (cnt == 0)
      {
        hStr += '<tr><td style="width: 15px;"></td>';
        hStr += '<td colspan="3">no indexes found</td></tr>';
      }
    }

    return hStr + '</table></div>';
  }
}

var ResourceController = new ResourceManager();