MapPanel.prototype = new Panel();

function MapPanel(id, type, title, url, position, pinned, zIndex, container, panelController, config) {
    Panel.call(this, id, type, title, url, position, pinned, zIndex, container, panelController, config);
    this.Url = this.Url.replace("x-format=html", "x-format=json");

    this.scanResult;
    this.map;
    this.markers = new OpenLayers.Layer.Markers(this.Id + "_markers");
    this.icon_size = new OpenLayers.Size(20, 20);
    this.icon = new OpenLayers.Icon('scripts/style/img/dot.png',
            this.icon_size,
            new OpenLayers.Pixel(-(this.icon_size.w / 2),
                    -(this.icon_size.h / 2))
            );

    /**
     * @param -
     * purpose:    loads this.Url via AJAX and places the content of the remote file
     *             inside the searchresult div; afterwards initializes/refreshes the
     *             scrollbar
     * @return    -
     */
    this.GetFullText = function()
    {
        var elem = this.GetCssId();
        var panel = this;

        $.ajax(
                {
                    type: 'GET',
                    url: this.Url,
                    dataType: 'json',
                    complete: function(xml, textStatus)
                    {
                        panel.scanResult = $.parseJSON(xml.responseText);
                        var responseText = "<div id='" + panel.Id + "_map' class='content' style='width: 100%; height:100%;'/>"

//          responseText = $(responseText).find(".title, .data-view, .navigation, .content");

                        $(elem).find(".searchresults").html(responseText);
                        panel.initalizeLayers();
                    }
                }
        );
    };

    this.initalizeLayers = function() {
        this.map = new OpenLayers.Map(this.Id + "_map", {
            projection: 'EPSG:3857',
            layers: [
                new OpenLayers.Layer.Google(
                        "Google Physical",
                        {type: "terrain"}
                ),
//           new OpenLayers.Layer.OSM("OSM"),
                /*            new OpenLayers.Layer.Google(
                 "Google Streets", // the default
                 {numZoomLevels: 20}
                 ),
                 new OpenLayers.Layer.Google(
                 "Google Hybrid",
                 {type: google.maps.MapTypeId.HYBRID, numZoomLevels: 20}
                 ),
                 new OpenLayers.Layer.Google(
                 "Google Satellite",
                 {type: google.maps.MapTypeId.SATELLITE, numZoomLevels: 22}
                 ),*/
                this.markers,
            ],
            controls: [
                new OpenLayers.Control.Attribution(),
                new OpenLayers.Control.DragPan({'autoActivate': true}),
            ],
            center: new OpenLayers.LonLat(16.04, 24.397)
                    // Google.v3 uses web mercator as projection, so we have to
                    // transform our coordinates
                    .transform('EPSG:4326', 'EPSG:3857'),
            zoom: 4,
        });
        this.scanResult.terms.forEach(function(term)
        {
            LatLon = term.value.split(", ");
            marker = new OpenLayers.Marker(new OpenLayers.LonLat(LatLon[1], LatLon[0]).transform(
                    'EPSG:4326', // transform from WGS 1984
                    this.map.getProjectionObject() // to whatever map needs, most of the time Spherical Mercator Projection
                    ), this.icon.clone());
            marker.URL = term.nextHref;
            marker.events.register('click', marker, markerCallback);
            this.markers.addMarker(marker);
        }, this);
    };

    markerCallback = function(evt) {
        target = this.URL;
        var urlParams = GetUrlParams(target);
        var ID = PanelController.OpenNewSearchPanel(urlParams['x-context'], urlParams.query);
        PanelController.StartSearch(ID);
    };

    /**
     * This method is not needed by this type of panel.
     * @returns -
     */
    this.InitScrollPane = function() {
    };
    /**
     * This method needs to pass the call to map's updateSize.
     * @returns -
     */
    this.RefreshScrollPane = function() {
        this.map.updateSize();
    };

}
