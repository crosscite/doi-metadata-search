 
function onMetricsHover(item) {
  console.log(item);
  gtag("event", 'metric',{
    eventCategory: 'metrics',
    eventAction: item.class,
    eventLabel: item.id
  }); 
};

