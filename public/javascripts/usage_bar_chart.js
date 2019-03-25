 

    /*global d3, startDate, endDate, startTime, endTime, formatWeek, formatHour, numberToHumanSize, formatFixed, formatDate, formatTime, numberWithDelimiter */

    function barWidth(width,length){
      let calc_width = Math.floor(width/length - 1);
      let bar_width = calc_width;
      if (calc_width > 50){
        bar_width = 25;
      }else if(calc_width < 6){
        bar_width = 6;
      }
      return bar_width
    }


    function bar2Viz(data, div, count, format, displayMode, yop) {

      if(Number.isInteger(displayMode) == false){
        var startDate = new Date(data[0].id);
        var today = new Date();
        var endDate = new Date(today.setMonth( today.getMonth())); // creates a bit of space at the end
      }
      else {
        var lastDataPoint = new Date(data[data.length - 1].id);
        var endDate = new Date(lastDataPoint.setMonth( lastDataPoint.getMonth() + 2 ));
        var startDate = new Date(lastDataPoint.setMonth( lastDataPoint.getMonth() - displayMode ));
      }

      if(yop){
        var startDate = new Date(yop+"-01-01");
      }

      var timeStamp = null;
      let formatYear = d3.time.format.utc("%Y");
      let formatHour = d3.time.format.utc("%h");
      let formatMonthYear = d3.time.format.utc("%b %Y");
      let formatFixed = d3.format(",.0f");
      let formatTime = d3.time.format.utc("%H:%M:%S");
      let height = 200
      var margin = { top: 10, right: 20, bottom: 20, left: 20 };

      if (format === "days") {
        var domain = [startDate, endDate];
        var length = 30;
      } else if (format === "months") {
        var domain = [startDate, endDate];
        var length = d3.time.months(startDate, endDate).length;
        width = 840;
      } else {
        var domain = [startTime, endTime];
        var length = 24;
      }
      
      var x = d3.time.scale.utc()
        .domain(domain)
        .rangeRound([0, width]);

      var y = d3.scale.linear()
        .domain([0, d3.max(data, function(d) { return d.sum; })])
        .rangeRound([height, 0]);

      var xAxis = d3.svg.axis()
        .scale(x)
        .tickSize(0)
        .ticks(0);

      var chart = d3.select(div).append("svg")
        .data([data])
        .attr("width", margin.left + width + margin.right)
        .attr("height", margin.top + height + margin.bottom)
        .attr("style","position:relative")
        .attr("class", "chart barchart")
        .append("svg:g")
        .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

      chart.selectAll(".bar")
        .data(data)
        .enter().append("rect")
        .attr("class", function(d) {
          if (format === "days") {
            timeStamp = Date.parse(d.key + 'T12:00:00Z');
            var weekNumber = formatWeek(new Date(timeStamp));
            return (weekNumber % 2 === 0) ? "bar relations" : "bar relations-alt";
          } else if (format === "months") {
            timeStamp = Date.parse(d.key + '-01T12:00:00Z');
            var year = formatYear(new Date(timeStamp));
            return (year % 2 === 0) ? "bar relations" : "bar relations-alt";
          } else {
            timeStamp = Date.parse(d.key + ':00:01Z');
            var hour = formatHour(new Date(timeStamp));
            return (hour >= 11 && hour <= 22) ? "bar relations-alt" : "bar relations";
          }})
        .attr("x", function(d) {
          if (format === "days") {
            return x(new Date(Date.parse(d.id + 'T12:00:00Z')));
          } else if (format === "months") {
            return x(new Date(Date.parse(d.id + '-01T12:00:00Z')));
          } else {
            return x(new Date(Date.parse(d.id + ':00:00Z')));
          }})
        .attr("width", barWidth(width,length))
        .attr("y", function(d) { return y(d.sum); })
        .attr("height", function(d) { return height - y(d.sum); });


      chart.append("g")
        .attr("class", "x axis")
        .attr("transform", "translate(0," + height + ")")
        .call(xAxis);

      chart.append("text")
        .attr("class", "label")
        .attr("text-anchor", "middle")
        .attr("transform", "translate(11," + (height + 18) + ")")
        .text(formatMonthYear(startDate))
        .style("font-size", "13px");
  
      chart.append("text")
        .attr("class", "label")
        .attr("text-anchor", "middle")
        .attr("transform", "translate(" + (width - 11) + "," + (height + 18) + ")")
        .text(formatMonthYear(endDate))
        .style("font-size", "13px");

      chart.selectAll("rect").each(
        function(d) {
          var title = null,
              dateStamp = null,
              dateString = null;

          if (count === "sfum") {
            title = numberToHumanSize(d.sum);
          } else if (count === "sum") {
            title = formatFixed(d.sum);
          } else {
            title = formatFixed(d.sum);
          }

          if (format === "days") {
            dateStamp = Date.parse(d.id + 'T12:00:00Z');
            dateString = " on " + formatDate(new Date(dateStamp));
          } else if (format === "months") {
            dateStamp = Date.parse(d.id + '-01T12:00:00Z');
            dateString = " in " + formatMonthYear(new Date(dateStamp));
          } else {
            dateStamp = Date.parse(d.id + ':00:00Z');
            dateString = " at " + formatTime(new Date(dateStamp));
          }

          $(this).tooltip({ title: title + dateString, container: "body"});

          $(this).on("mouseover", function() {
            d3.select(this).attr("class", "bar relations-high");
          })
          .on("mouseout", function() {
            d3.select(this).attr("class", "bar relations-alt");
          });
        }
      );

      d3.select(div + "-loading").remove();

      // return chart object
      return chart;
    }

    function tabs_interaction(){
      var tab = window.location.hash.substring(1)


      if(tab){
        $('#'+tab).tab("show")
      }else{
        $('#views-tab').tab("show")
      }
  
      $('.usage-counts.usage-views').on('click', function (e) {
        e.preventDefault()
        $("#views-tab").tab('show')
      })
      
      $('.usage-counts.usage-downloads').on('click', function (e) {
        e.preventDefault()
        $("#downloads-tab").tab('show')
      })
    }


$(document).ready(function(e) {
  if (typeof gon !== 'undefined'){
    var views = gon.chart_views;
    var downloads = gon.chart_downloads;
    // var citations = gon.chart_citations;
    var yop = gon.yop;

    console.log(views)
    
    tabs_interaction()

    bar2Viz(views,"#views-chart","sum","months","full",yop);
    bar2Viz(downloads,"#downloads-chart","sum","months","full",yop);
    // bar2Viz(citations,"#citations-chart","sum","months","full",yop);
  }
});

$(document).ready(function(e) {
  $('.usage-info').tooltip({show: {effect:"none", delay:0}});
});