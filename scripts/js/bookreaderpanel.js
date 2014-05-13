!function ($, Panel) {
/**
 * A class for displaying XML data in a panel
 * Inherits from Panel using prototype inheritance (see below)
 */
var BookReaderPanel = function (id, type, title, url, position, pinned, zIndex, container, panelController, config) {
    Panel.call(this, id, type, title, url, position, pinned, zIndex, container, panelController, config);

    /**
     * @param -
     * purpose:    loads this.Url via AJAX and places the content of the remote file
     *             inside the searchresult div; afterwards initializes/refreshes the
     *             scrollbar
     * @return    -
     */
    this.GetFullText = function()
        {
            var uri = URI(this.Url);
            var bookId = uri.filename();
            var navFragment = uri.fragment();
            if (navFragment === '') {
                 navFragment = 'page/n11/mode/1up';
            }
            //?ui=embed
            uri = URI('https://archive.org/stream/' + bookId + '#' + navFragment);
            var elem = this.GetCssId();
            $(this.GetCssId()).find(".c_s_fcs_xml_link").addClass("c_s-hidden");
            var responseText = "<iframe id='" + this.Id + "_book' class='content' style='width: 100%; height:100%;' src=" + uri.toString() + ">";
            responseText += "</iframe>";
            $(elem).find(".searchresults").html(responseText);
            // hack FIXME
            $(elem).find(".c_s-scroll-area").css('overflow', 'hidden');
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
        
    };

};

// inherit Panel
BookReaderPanel.prototype = new Panel();

// publish
this.BookReaderPanel = BookReaderPanel;

}(jQuery, Panel);

