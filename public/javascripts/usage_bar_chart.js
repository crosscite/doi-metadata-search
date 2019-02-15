 

    /*global d3, startDate, endDate, startTime, endTime, formatWeek, formatHour, numberToHumanSize, formatFixed, formatDate, formatTime, numberWithDelimiter */

    // var width = 340,
    //     height = 100
    //     margin = { top: 7, right: 10, bottom: 5, left: 5 },
    //     colors = ["#1abc9c","#2ecc71","#3498db","#9b59b6","#34495e","#95a6a6"],
    //     l = 250, // left margin
    //     r = 150, // right margin
    //     w = 400, // width of drawing area
    //     h = 24,  // bar height
    //     s = 2;   // spacing between bars






    // let data = (this.data) ? this.data : [];

    // let height = 100;

    // let startDate = new Date("2010-01-01");
    // let endDate = new Date("2020-01-01");
    // let domain = [startDate, endDate];
    // let length = d3.time.years(startDate, endDate).length;
    // let width = length * 22;



    function bar2Viz(data, div, count, format) {

      var startDate = new Date(data[0].id);
      var endDate = new Date(data[data.length - 1].id);

      var timeStamp = null;
      let formatYear = d3.time.format.utc("%Y");
      let formatHour = d3.time.format.utc("%h");
      let formatMonthYear = d3.time.format.utc("%Y-%B");
      let formatFixed = d3.format(",.0f");
      let formatTime = d3.time.format.utc("%H:%M:%S");

      let margin = { top: 10, right: 5, bottom: 20, left: 5 };



      if (format === "days") {
        var domain = [startDate, endDate];
        var length = 30;
      } else if (format === "months") {
        var domain = [startDate, endDate];
        var length = d3.time.months(startDate, endDate).length;
        width = length * 22;
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
        // .attr("width", margin.left + width + margin.right)
        // .attr("height", margin.top + height + margin.bottom)
        .attr("preserveAspectRatio","meet")
        .attr("viewBox","-30 0 350 200")
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
        .attr("width", width/length - 1)
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
        .text(formatYear(startDate));
  
      chart.append("text")
        .attr("class", "label")
        .attr("text-anchor", "middle")
        .attr("transform", "translate(" + (width - 11) + "," + (height + 18) + ")")
        .text(formatYear(endDate));


      chart.selectAll("rect").each(
        function(d) {
          var title = null,
              dateStamp = null,
              dateString = null;

          if (count === "sfum") {
            title = numberToHumanSize(d.sum);
          } else if (count === "sum") {
            title = formatFixed(d.sum) + " counts";
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
        }
      );

      d3.select(div + "-loading").remove();

      // return chart object
      return chart;
    }

    // horizontal bar chart
    function hBarViz(data, name) {
      // make sure we have data for the chart
      if (typeof data === "undefined") {
        d3.select("#" + name + "-loading").remove();
        return;
      }

      // Works tab
      var chart = d3.select("div#" + name + "-body").append("svg")
        .attr("width", w + l + r)
        .attr("height", data.length * (h + 2 * s) + 30)
        .attr("class", "chart")
        .append("g")
        .attr("transform", "translate(" + l + "," + h + ")");

      var x = null;

      if (name === "work") {
        x = d3.scale.linear()
          .domain([0, d3.max(data, function(d) { return d[name + "_count"]; })])
          .range([0, w]);
      } else {
        x = d3.scale.log()
          .domain([0.1, d3.max(data, function(d) { return d[name + "_count"]; })])
          .range([1, w]);
      }
      var y = d3.scale.ordinal()
        .domain(data.map(function(d) { return d.title; }))
        .rangeBands([0, (h + 2 * s) * data.length]);
      var z = d3.scale.ordinal()
        .domain(data.map(function(d) { return d.group_id; }))
        .range(colors);

      chart.selectAll("text.labels")
        .data(data)
        .enter().append("a").attr("xlink:href", function(d) { return "/sources/" + d.id; }).append("text")
        .attr("x", 0)
        .attr("y", function(d) { return y(d.title) + y.rangeBand() / 2; })
        .attr("dx", 0 - l) // padding-right
        .attr("dy", ".18em") // vertical-align: middle
        .text(function(d) { return d.title; });

      chart.selectAll("rect")
        .data(data)
        .enter().append("rect")
        .attr("fill", function(d) { return z(d.group_id); })
        .attr("y", function(d) { return y(d.title); })
        .attr("height", h)
        .attr("width", function(d) { return x(d[name + "_count"]); });

      chart.selectAll("text.values")
        .data(data)
        .enter().append("text")
        .attr("x", function(d) { return x(d[name + "_count"]); })
        .attr("y", function(d) { return y(d.title) + y.rangeBand() / 2; })
        .attr("dx", 5) // padding-right
        .attr("dy", ".18em") // vertical-align: middle
        .text(function(d) { return numberWithDelimiter(d[name + "_count"]); });

      d3.select("#" + name + "-loading").remove();
    }

    
$(document).ready(function(e) {
    var views = gon.chart_views;
    var downloads = gon.chart_downloads;
  
    bar2Viz(views,"#views-chart","sum","months");
    bar2Viz(downloads,"#downloads-chart","sum","months");
});