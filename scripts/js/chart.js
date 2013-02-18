

    var data= {};
    var options = {}; 
    var chart = {};
      
      // copied locally instead as: google-corechart.js
      //google.load("visualization", "1", {packages:["corechart"]});

/** function to invoke the chart rendering 
expects the data to render in the chart-object under given dataset-key*/
            function drawChart(dataset) {        
            var target_container_id = "chart-" +  dataset;
               if (options[dataset]["layout"]=='area') {
                 chart[dataset] = new google.visualization.AreaChart(document.getElementById(target_container_id));
               } else if (options[dataset]["layout"]=='bar') {
                 chart[dataset] = new google.visualization.BarChart(document.getElementById(target_container_id));               
               } else if (options[dataset]["layout"]=='column') {
                 chart[dataset] = new google.visualization.ColumnChart(document.getElementById(target_container_id));               
               } else if (options[dataset]["layout"]=='line') {
                 chart[dataset] = new google.visualization.LineChart(document.getElementById(target_container_id));               
               } else if (options[dataset]["layout"]=='pie') {
                 chart[dataset] = new google.visualization.PieChart(document.getElementById(target_container_id));               
               }
           
               chart[dataset].draw(data[dataset], options[dataset]);
           
            // set a reference to the displayed dataset, so that the target_conatiner "knows" what it is displaying
            var target_container = $("#" + target_container_id);
             //console.log(target_container);
                 target_container.data("dataset",dataset);
               // console.log(dataset + '-' + target_container.data("dataset"));
            }
     
     function toggleLayout(dataset) {
        if (options[dataset]["layout"]=='pie') { options[dataset]["layout"] = 'area' } else { options[dataset]["layout"]='pie'};
        drawChart(dataset);
     }
     
     function changeLayout(dataset,layout) {
        if (options[dataset]["layout"]!=layout) { 
                options[dataset]["layout"] = layout 
                drawChart(dataset);
            };
     }
     

  $(function()
  {
        $('.infovis-wrapper').resizable( { 
           start: function(event, ui) {
                  $(this).children('.infovis').hide();
                },
           stop:  function(event, ui) {
                  $(this).children('.infovis').show();
                   var dataset = $(this).children('.infovis').data('dataset');
                 //  console.log(dataset);
                  drawChart(dataset);                              
                }                           
           }          
        );
  });     
     