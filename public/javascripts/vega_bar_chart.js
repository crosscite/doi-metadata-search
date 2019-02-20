
var spec = {
  "$schema": "https://vega.github.io/schema/vega/v4.json",
  "width": 500,
  "height": 200,
  "padding": 5,

  "data": [],

  "signals": [
    {
      "name": "tooltip",
      "value": {},
      "on": [
        {"events": "rect:mouseover", "update": "datum"},
        {"events": "rect:mouseout",  "update": "{}"}
      ]
    }
  ],

  "scales": [
    {
      "name": "xscale",
      "type": "band",
      "domain": {"data": "iris", "field": "id"},
      "range": "width",
      "padding": 0.05,
      "round": true
    },
    {
      "name": "yscale",
      "domain": {"data": "iris", "field": "sum"},
      "nice": true,
      "range": "height"
    }
  ],

  "axes": [
    { "orient": "bottom", "scale": "xscale", "tickCount": 5},
    { "orient": "left", "scale": "yscale", "tickCount": 5, "labelFont":"'Raleway', 'Helvetica', Arial, sans-serif"}
  ],

  "marks": [
    {
      "type": "rect",
      "from": {"data":"iris"},
      "encode": {
        "enter": {
          "x": {"scale": "xscale", "field": "id"},
          "width": {"scale": "xscale", "band": 1},
          "y": {"scale": "yscale", "field": "sum"},
          "y2": {"scale": "yscale", "value": 0}
        },
        "update": {
          "fill": {"value": "#68B3C8"}
        },
        "hover": {
          "fill": {"value": "gray"}
        }
      }
    },
    {
      "type": "text",
      "encode": {
        "enter": {
          "align": {"value": "center"},
          "baseline": {"value": "bottom"},
          "fill": {"value": "#333"}
        },
        "update": {
          "x": {"scale": "xscale", "signal": "tooltip.id", "band": 0.5},
          "y": {"scale": "yscale", "signal": "tooltip.sum", "offset": -2},
          "text": {"signal": "tooltip.sum"},
          "fillOpacity": [
            {"test": "datum === tooltip", "value": 0},
            {"value": 1}
          ]
        }
      }
    }
  ]
};


var specLite = {
  "$schema": "https://vega.github.io/schema/vega-lite/v2.6.0.json",
  "description": "A simple bar chart with embedded data.",
  "selection": {
    "grid": {
      "type": "interval", "bind": "scales"
    }
  },
  "data": {
  },
  "axes": [
    { "orient": "bottom", "scale": "xscale", "tickCount": 5},
    { "orient": "left", "scale": "yscale", "tickCount": 5, "labelFont":"'Raleway', 'Helvetica', Arial, sans-serif"}
  ],  
  "mark": 
    {
      "type": "bar",
      "color":"#68B3C8"
    }
  ,
  "width": 500,
  "encoding": {
    "x": {"field": "id","type": "temporal", "timeUnit":"yearmonth","title": "", "scale": {"domain": ["2017-12", "2019-05"]}, "axis":{"grid":false}},
    "y": {"field": "sum", "type": "quantitative", "title": "","scale": {"domain": [0, 500]}},
    "tooltip": {"field": "sum", "type": "quantitative"}
  }
}


// // uncooment to activate
// $(document).ready(function(e) {
//   var data = [
//     {
//       "name": "iris",
//       "values": []
//     }
//   ];
//   var data = 
//     {
//       "values": []
//     };
  

//   data.values= gon.chart_views
//   specLite.data = data;
//   var spec_views = specLite;
//   vegaEmbed(
//     '#views-chart',
//     spec_views, {actions: false}
//   );
// });

// $(document).ready(function(e) {
//   var data = [
//     {
//       "name": "iris",
//       "values": []
//     }
//   ];

//   data[0].values= gon.chart_downloads
//   spec.data = data;
//   var spec_downloads = spec;
//   vegaEmbed(
//     '#downloads-chart',
//     spec_downloads, {actions: false}
//   );
// });
