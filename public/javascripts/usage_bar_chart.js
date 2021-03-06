/*global d3, startDate, endDate, startTime, endTime, formatWeek, formatHour, numberToHumanSize, formatFixed, formatDate, formatTime, numberWithDelimiter */

// function barWidth(width,length){
//   let calc_width = (width/(length)) - 2;
//   let bar_width = calc_width;
//   if (calc_width > 17){
//     bar_width = 17;
//   }else if(calc_width < 6){
//     bar_width = 6;
//   }
//   return bar_width
// }

function setupUsage(data, yop, chartWidth) {
  if (Number.isInteger("full") == false) {
    var startDate = new Date(data[0].id);
    var today = new Date();
    var endDate = new Date(today.setMonth(today.getMonth())); // creates a bit of space at the end
  } else {
    var endDate = new Date(
      lastDataPoint.setMonth(lastDataPoint.getMonth() + 2)
    );
    var startDate = new Date(
      lastDataPoint.setMonth(lastDataPoint.getMonth() - displayMode)
    );
  }

  if (yop) {
    var startDate = new Date(yop + "-01-01");
  }

  let formatMonthYear = d3.time.format.utc("%b %Y");

  var domain = [startDate, endDate];
  var length = bins(yop, 120); //d3.time.months(startDate, endDate).length;
  var firstLabel = formatMonthYear(startDate);
  var lastLabel = formatMonthYear(endDate);

  return {
    width: chartWidth,
    barWidth: chartWidth / length,
    firstLabel: firstLabel,
    lastLabel: lastLabel,
    length: length,
    domain: domain
  };
}

function setupCitations(data, yop, chartWidth) {
  var today = new Date();
  var endDate = new Date(today.setMonth(today.getMonth())); // c
  var firstDataPoint = new Date(data[0].id + "-01-01");
  var yopDate = new Date(yop + "-01-01");
  var startDate = firstDataPoint > yopDate ? yopDate : firstDataPoint;
  var maxStart = new Date(today.getFullYear() - 20 + "-01-01");
  var diff = today.getFullYear() - yopDate.getFullYear();
  var startDate = diff <= 20 ? yopDate : maxStart;

  var startTime = startDate;
  var endTime =  new Date(today.getFullYear(), 12, 0);
  var domain = [startTime, endTime];
  var length = (diff > 20 ? 20 : diff) + 0.5;
  var firstLabel = formatYear(startDate);
  var lastLabel = formatYear(endDate);
  var barWidth = 21;

  return {
    width: (barWidth + 2) * length,
    barWidth: barWidth,
    firstLabel: firstLabel,
    lastLabel: lastLabel,
    length: length,
    domain: domain
  };
}

// function monthDiff(d1, d2) {
//   var months;
//   months = (d2.getFullYear() - d1.getFullYear()) * 12;
//   months -= d1.getMonth() + 1;
//   months += d2.getMonth();
//   return months <= 0 ? 0 : months;
// }

function monthDiff(dateFrom, dateTo) {
  return dateTo.getMonth() - dateFrom.getMonth() + 
    (12 * (dateTo.getFullYear() - dateFrom.getFullYear()))
 }

function bins(yop, maxBin) {
  var today = new Date();
  var yopDate = new Date(yop + "-01-01");

  if (monthDiff(yopDate, today) > 0) {
    if (monthDiff(yopDate, today) < maxBin) {
      return monthDiff(yopDate, today);
    }
  } else {
    return maxBin * 0.9;
  }
  return maxBin;
}

function bar2Viz(data, div, count, format, displayMode, yop) {
  console.log(data)
  var lastDataPoint = new Date(data[data.length - 1].id);
  var today = new Date();
  let setup;

  var timeStamp = null;
  let formatYear = d3.time.format.utc("%Y");
  let formatHour = d3.time.format.utc("%h");
  let formatMonthYear = d3.time.format.utc("%b %Y");
  let formatFixed = d3.format(",.0f");
  let formatTime = d3.time.format.utc("%H:%M:%S");
  let height = 200;
  var margin = { top: 10, right: 20, bottom: 30, left: 20 };

  let chartWidth = document.getElementById("myTabContent").offsetWidth * 0.95;
  if (displayMode == "citations") {
    setup = setupCitations(data, yop, 0);
    chartWidth = setup.width;
  } else {
    setup = setupUsage(data, yop, chartWidth);
  }
  var x = d3.time.scale
    .utc()
    .domain(setup.domain)
    .nice(d3.time.month)
    .rangeRound([0, setup.width + 10], 0.5);

  var y = d3.scale
    .linear()
    .domain([
      0,
      d3.max(data, function(d) {
        return d.sum;
      })
    ])
    .rangeRound([height, 0]);

  var xAxis = d3.svg
    .axis()
    .scale(x)
    .tickSize(0)
    .ticks(0);

  var chart = d3
    .select(div)
    .append("svg")
    .data([data])
    .attr("width", margin.left + setup.width + margin.right)
    .attr("height", margin.top + height + margin.bottom)
    .attr("style", "position:relative;")
    .attr("class", "chart barchart")
    .append("svg:g")
    .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

  chart
    .selectAll(".bar")
    .data(data)
    .enter()
    .append("rect")
    .attr("class", function(d) {
      if (format === "days") {
        timeStamp = Date.parse(d.key + "T12:00:00Z");
        var weekNumber = formatWeek(new Date(timeStamp));
        return weekNumber % 2 === 0 ? "bar relations" : "bar relations-alt";
      } else if (format === "months") {
        timeStamp = Date.parse(d.key + "-01T12:00:00Z");
        var year = formatYear(new Date(timeStamp));
        return year % 2 === 0 ? "bar relations" : "bar relations-alt";
      } else if (format === "years") {
        timeStamp = Date.parse(d.key + "-01-01T12:00:00Z");
        var year = formatYear(new Date(timeStamp));
        return year % 2 === 0 ? "bar relations" : "bar relations-alt";
      } else {
        timeStamp = Date.parse(d.key + ":00:01Z");
        var hour = formatHour(new Date(timeStamp));
        return hour >= 11 && hour <= 22 ? "bar relations-alt" : "bar relations";
      }
    })
    .attr("x", function(d) {
      if (format === "days") {
        return x(new Date(Date.parse(d.id + "T12:00:00Z")));
      } else if (format === "months") {
        return x(new Date(Date.parse(d.id + "-01T12:00:00Z")));
      } else if (format === "years") {
        return x(new Date(Date.parse(d.id + "-01-01T12:00:00Z")));
      } else {
        return x(new Date(Date.parse(d.id + ":00:00Z")));
      }
    })
    .attr("width", setup.barWidth - 2)
    .attr("y", function(d) {
      return y(d.sum);
    })
    .attr("height", function(d) {
      return height - y(d.sum);
    });

  chart
    .append("g")
    .attr("class", "x axis")
    .attr("transform", "translate(0," + height + ")")
    .call(xAxis);

  var last_tick = chartWidth;
  if (monthDiff(lastDataPoint, today) < 1) {
    last_tick = chart
      .selectAll("rect")
      .pop()
      .pop().x.animVal.value;
  }

  var rotate = "0";
  if (setup.length < 3 && setup.length > 1) {
    rotate = "-65";
  }

  chart
    .append("text")
    .attr("class", "label")
    .attr("text-anchor", "middle")
    .attr(
      "transform",
      "translate(11," + (height + 18) + "), rotate(" + rotate + ")"
    )
    .text(setup.firstLabel)
    .style("font-size", "13px");

  if (setup.length > 1) {
    chart
      .append("text")
      .attr("class", "label")
      .attr("text-anchor", "middle")
      .attr(
        "transform",
        "translate(" +
          (last_tick - 11) +
          "," +
          (height + 18) +
          "), rotate(" +
          rotate +
          ")"
      )
      .text(setup.lastLabel)
      .style("font-size", "13px");
  }

  chart.selectAll("rect").each(function(d) {
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
      dateStamp = Date.parse(d.id + "T12:00:00Z");
      dateString = " on " + formatDate(new Date(dateStamp));
    } else if (format === "months") {
      dateStamp = Date.parse(d.id + "-01T12:00:00Z");
      dateString = " in " + formatMonthYear(new Date(dateStamp));
    } else if (format === "years") {
      dateStamp = Date.parse(d.id + "-01-01T12:00:00Z");
      dateString = " in " + formatYear(new Date(dateStamp));
    } else {
      dateStamp = Date.parse(d.id + ":00:00Z");
      dateString = " at " + formatTime(new Date(dateStamp));
    }

    $(this).tooltip({ title: title + dateString, container: "body" });

    $(this)
      .on("mouseover", function() {
        d3.select(this).attr("class", "bar relations-high");
      })
      .on("mouseout", function() {
        d3.select(this).attr("class", "bar relations-alt");
      });
  });

  d3.select(div + "-loading").remove();

  // return chart object
  return chart;
}

function tabs_interaction() {
  var tab = window.location.hash.substring(1);

  if (tab) {
    $("#" + tab).tab("show");
  } else if (gon.chart_citations) {
    $("#citations-tab").tab("show");
  } else if (gon.chart_views) {
    $("#views-tab").tab("show");
  } else if (gon.chart_downloads) {
    $("#downloads-tab").tab("show");
  }

  $(".usage-counts.citations").on("click", function(e) {
    e.preventDefault();
    $("#citations-tab").tab("show");
  });

  $(".usage-counts.usage-views").on("click", function(e) {
    e.preventDefault();
    $("#views-tab").tab("show");
  });

  $(".usage-counts.usage-downloads").on("click", function(e) {
    e.preventDefault();
    $("#downloads-tab").tab("show");
  });
}


$(document).ready(function(e) {
  if (typeof gon !== "undefined") {
    var views = gon.chart_views;
    var downloads = gon.chart_downloads;
    var citations = gon.chart_citations;
    var yop = gon.yop;

    tabs_interaction();

    //   views = [
    //     {id: "2017-01", title: "April 2018", sum: 337},
    //     {id: "2017-02", title: "April 2018", sum: 337},
    //     {id: "2017-03", title: "April 2018", sum: 337},
    //     {id: "2017-05", title: "April 2018", sum: 337},
    //     {id: "2017-06", title: "April 2018", sum: 337},
    //     {id: "2017-07", title: "April 2018", sum: 337},
    //     {id: "2017-08", title: "April 2018", sum: 337},
    //     {id: "2017-09", title: "April 2018", sum: 337},
    //     {id: "2017-10", title: "April 2018", sum: 337},
    //     {id: "2017-11", title: "April 2018", sum: 337},
    //     {id: "2017-12", title: "April 2018", sum: 337},
    //     {id: "2018-01", title: "April 2018", sum: 337},
    //     {id: "2018-04", title: "April 2018", sum: 337},
    //     {id: "2018-05", title: "April 2018", sum: 34},
    //     {id: "2018-06", title: "April 2018", sum: 337},
    //     {id: "2018-07", title: "April 2018", sum: 5},
    //     {id: "2018-08", title: "April 2018", sum: 337},
    //     {id: "2018-09", title: "April 2018", sum: 337},
    //     {id: "2018-10", title: "April 2018", sum: 337},
    //     {id: "2018-11", title: "April 2018", sum: 4},
    //     {id: "2018-12", title: "April 2018", sum: 337},
    //     {id: "2019-01", title: "April 2018", sum: 337},
    //     {id: "2019-02", title: "April 2018", sum: 337},
    //     {id: "2019-03", title: "April 2018", sum: 337},
    //     {id: "2019-05", title: "April 2018", sum: 337},
    //     {id: "2019-06", title: "April 2018", sum: 337},
    //     {id: "2019-07", title: "April 2018", sum: 337},
    //     {id: "2019-08", title: "April 2018", sum: 337},
    // ]

    // yop="2019"

    //     citations = [
    //     //   {id: "2009", title: "April 2018", sum: 337},
    //     //   {id: "2010", title: "April 2018", sum: 337},
    //     //   {id: "2011", title: "April 2018", sum: 337},
    //     //   {id: "2012", title: "April 2018", sum: 12},
    //     //   {id: "2013", title: "April 2018", sum: 337},
    //     //   {id: "2014", title: "April 2018", sum: 337},
    //     //   {id: "2015", title: "April 2018", sum: 1000},
    //     // {id: "2016", title: "April 2018", sum: 337},
    //     // {id: "2017", title: "April 2018", sum: 23},
    //     // {id: "2018", title: "April 2018", sum: 337},
    //     {id: "2019", title: "April 2018", sum: 337}
    //   ]

    if (views) {
      bar2Viz(views, "#views-chart", "sum", "months", "full", yop);
    }
    if (downloads) {
      bar2Viz(downloads, "#downloads-chart", "sum", "months", "full", yop);
    }
    if (citations) {
      bar2Viz(citations, "#citations-chart", "sum", "years", "citations", yop);
    }
  }
});

$(document).ready(function(e) {
  $(".usage-info").tooltip({ show: { effect: "none", delay: 0 } });
});
