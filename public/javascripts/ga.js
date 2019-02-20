 
function onMetricsHover(item) {
  gtag("event", 'metric',{
    eventCategory: 'metrics',
    eventAction: item.className,
    eventLabel: item.innerText,
    dimension1: window.location,
    dimension2: $('a#doi-link').innerText
  }); 
};

function onDoiClick(item) {
  gtag("event", 'links',{
    eventCategory: 'dois',
    eventAction: item.className,
    eventLabel: item.innerText,
    dimension1: window.location,
    dimension2: $('a#doi-link').innerText
  }); 
};




$(document).ready(function(e) {
  $('span.usage-counts').on("mouseover", function(e) {
    onMetricsHover(this);
  });
  $('a#doi-link').on("click", function(e) {
    onDoiClick(this);
  });
  $('a#title-link').on("click", function(e) {
    onDoiClick(this);
  });
  $('row.tab-pane').on("mouseover", function(e) {
    onMetricsHover(this);
  });

});