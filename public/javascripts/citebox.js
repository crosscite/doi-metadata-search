function showCiteBox(doi, title) {
  citationInfo['doi'] = doi;
  citationInfo['title'] = title;
  citationInfo['format'] = 'bibtex';

  $('#citation-text').html('');
  updateCiteBox();
  $('#citation-modal').modal();
  spinner.spin(document.getElementById('citation-text'));
}

function updateCiteBox() {
  $('#citation-description').text(citationInfo['doi']);
  $('#citation-modal-title').html('Citing &lsquo;' + citationInfo['title'] + '&rsquo;');

  $('#cite-nav li').removeClass('active');
  $('#' + citationInfo['format']).addClass('active');
  
  var path = '/citation?format=' + citationInfo['format'];
  path += '&doi=' + encodeURIComponent(citationInfo['doi']);
  
  $.ajax({
    url: path,
    success: function(body) {
      $('#citation-text').text(body);
      spinner.stop();
    }  
  });
}

function setCiteBoxFormat(format) {
  citationInfo['format'] = format;
  $('#citation-text').html('');
  spinner.spin(document.getElementById('citation-text'));
  updateCiteBox();
}

$(document).ready(function(e) {
  citationInfo = {format: 'bibtex'};
  spinnerOpts = {shadow: true, width: 2, speed: 2};
  spinner = new Spinner(spinnerOpts);
  
  $('#citation-modal-close').click(function(e) {
    $('#citation-modal').modal('hide');
  });

  $('.cite-link').click(function(e) {
    setCiteBoxFormat($(this).parent().attr('id'));
    $('#cite-nav li').removeClass('active');
    $(this).parent().addClass('active');
  });
});