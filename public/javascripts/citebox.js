function showCiteBox(doi, title) {
  citationInfo['doi'] = doi;
  citationInfo['title'] = title;
  citationInfo['format'] = 'apa';

  $('#citation-text').html('');
  updateCiteBox();
  $('#citation-modal').modal();
  spinner.spin(document.getElementById('spinner'));
};

function updateCiteBox() {
  $('#citation-description').text(citationInfo['doi']);
  $('#citation-modal-title').html(citationInfo['title']);

  $('#cite-nav li').removeClass('active');
  $('#' + citationInfo['format']).addClass('active');

  var path = '/citation?format=' + citationInfo['format'];
  path += '&doi=' + encodeURIComponent(citationInfo['doi']);

  $.ajax({
    url: path,
    success: function(body) {
      $('#citation-text').css("color", "black");

      if (citationInfo['format'] === "bibtex" || citationInfo['format'] === "ris") { body = "<pre>" + body + "</pre>" };

      $('#citation-text').html(body);
      spinner.stop();
    },
    error: function (error) {
      console.log(error.responseJSON);
      if (error.responseJSON.message !== "Format missing or not supported." && error.responseJSON.message !== "DOI missing or wrong format.") {
        $('#citation-text').css("color", "#e67e22");
        $('#citation-text').text(error.responseJSON.message);
      }
      spinner.stop();
    }
  });
};

function setCiteBoxFormat(format) {
  citationInfo['format'] = format;
  $('#citation-text').html('');
  spinner.spin(document.getElementById('spinner'));
  updateCiteBox();
};

$(document).ready(function(e) {
  citationInfo = {format: 'apa'};
  spinnerOpts = {shadow: true, width: 2, speed: 2};
  spinner = new Spinner(spinnerOpts);
  new Clipboard('.btn');
  $('#citation-modal-close').click(function(e) {
    $('#citation-modal').modal('hide');
  });


  $('.cite-link').click(function(e) {
    setCiteBoxFormat($(this).parent().attr('id'));
    $('#cite-nav li').removeClass('active');
    $(this).parent().addClass('active');
  });


});
