$(document).ready(function() {
  var doi = $("meta[name='DC.identifier']").attr("content")
  if (doi === undefined) {
    return;
  }
  doi = doi.substr(16);
  var url = $('#site-title').attr('data-conneg');
  url += '/application/vnd.schemaorg.ld+json/' + doi;
  console.log(url)

  $.ajax({
    url: url,
    dataType: 'text', // don't convert JSON to Javascript object
    success: function(data) {
      $('<script>')
         .attr('type', 'application/ld+json')
         .text(data)
         .appendTo('head');
    },
    error: function (error) {
      console.log(error.responseJSON);
    }
  });
});
