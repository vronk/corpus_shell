var XmlPanel;

// Everything here assumes $ === jQuery so ensure this
(function ($) {

/**
 * A class for displaying XML data in a panel
 * Inherits from Panel using prototype inheritance (see below)
 */
XmlPanel = function (id, type, title, url, position, pinned, zIndex, container, panelController, config) {
    Panel.call(this, id, type, title, url, position, pinned, zIndex, container, panelController, config);
    this.Url = encodeURI(this.Url.replace("x-format=html", "x-format=xml"));

    this.xmlResult;
    this.editor;

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
                    dataType: 'xml',
                    complete: function(xml, textStatus)
                    {
                        panel.xmlResult = xml.responseText;
                        var responseText = "<div id='" + panel.Id + "_editor' class='content' style='width: 100%; height:100%;'>"
                        responseText += "</div>";
                        $(elem).find(".searchresults").html(responseText);
                        panel.editor = ace.edit(panel.Id + "_editor");
                        panel.editor.setValue(panel.xmlResult);
                        panel.editor.setTheme("ace/theme/tomorrow");
                        panel.editor.getSession().setMode("ace/mode/xml"); 
                        panel.editor.setReadOnly(true);
                        panel.editor.clearSelection();
                    }
                }
        );
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
    this.UpdateContentView = function() {
        this.editor.resize();
    };

}

XmlPanel.prototype = new Panel();

})(jQuery);

