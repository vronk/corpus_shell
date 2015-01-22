!function($){
    
    var module = {};
    
    var onFetched = function(tag, containerToResize, newContainerSize, reservedSize, jqXHR) {
        var searchResponse = $(jqXHR.responseText).find('.wrapper.full');
        tag.html(searchResponse);
        if (containerToResize !== undefined && containerToResize.length !== 0) {
            containerToResize.width(newContainerSize);
            if (reservedSize !== undefined) {
                tag.css('width', 'calc(' + newContainerSize + ' - ' + reservedSize + ')');
            }
        }
    };
    
    var debug = function() {        
    };
    
    module.fetchUrlIntoTag = function(url, tag, containerToResize, newContainerSize, reservedSize) {
        tag.html('loading...')
        $.ajax(url, {
            async: true,
            dataType: 'html',
            success: function(unused, unused2, jqXHR){
                onFetched(tag, containerToResize, newContainerSize, reservedSize, jqXHR);
            },
            error: debug            
        });
    };
    
    this.HTMLOnDemandLoader = module;
}(jQuery);

