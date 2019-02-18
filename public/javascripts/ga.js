 
function onMetricsHover(item) {
  console.log(item);
  gtag("event", 'metric',{
    eventCategory: 'metrics',
    eventAction: item.class,
    eventLabel: item.id
  }); 
};




$(document).ready(function(e) {
  $('span.usage-counts').on("onmouseover", function(e) {
    console.log(e);
    onMetricsHover(this);
  });
});