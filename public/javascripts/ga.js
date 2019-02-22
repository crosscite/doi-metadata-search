 
function onMetricsHover(item) {
  views = $('.usage-views')['0'] !== undefined ? $('.usage-views')['0'].innerText.replace(/[|a-z,A-Z]/g, "") : "0"
  downloads = $('.usage-downloads')['0'] !== undefined ? $('.usage-downloads')['0'].innerText.replace(/[|a-z,A-Z]/g, "") : "0"
  gtag("event", 'metric',{
    event_category: item.className,
    event_label: parseInt(item.innerText.replace(/[|a-z,A-Z]/g, "")),
    value: 1,
    views: views,
    downloads: downloads,
    // resolutions: ($('.resolutions')['0'].innerText.replace(/[|a-z,A-Z]/g, "")),
    // citations: ($('.citations')['0'].innerText.replace(/[|a-z,A-Z]/g, ""))
  }); 
};

function onDoiClick(item) {
  views = $('.usage-views')['0'] !== undefined ? $('.usage-views')['0'].innerText.replace(/[|a-z,A-Z]/g, "") : "0"
  downloads = $('.usage-downloads')['0'] !== undefined ? $('.usage-downloads')['0'].innerText.replace(/[|a-z,A-Z]/g, "") : "0"
  gtag("event", 'links',{
    event_category: item.className,
    event_label: item.className,
    value: 1,
    views: views,
    downloads: downloads,
  }); 
};


function setGaPage(e){
  gtag('set', {
    'page': window.location,
    'views': $('span.usage-counts.usage-views').innerText,
    'downloads': $('span.usage-counts.usage-downloads').innerText,
    'position': '1',
  });
};


$(document).ready(function(e) {
  setGaPage(e);

  $('.usage-counts').on("mouseover", function(e) {
    onMetricsHover(this);
  });
  $('#doi-link').on("click", function(e) {
    onDoiClick(this);
  });
  $('#title-link').on("click", function(e) {
    onDoiClick(this);
  });
  $('row.tab-pane').on("mouseover", function(e) {
    onMetricsHover(this);
  });

});