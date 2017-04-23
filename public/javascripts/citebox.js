function showCiteBox(doi, title) {
  citationInfo['doi'] = doi;
  citationInfo['title'] = title;

  $('#citation-text').html('');
  updateCiteBox();
  $('#citation-modal').modal();
  spinner.spin(document.getElementById('spinner'));
};

function updateCiteBox() {
  // make sure style is set
  citationInfo['style'] = citationInfo['style'] || 'apa';

  $('#citation-description').text(citationInfo['doi']);
  $('#citation-modal-title').html(citationInfo['title']);
  $('#clipboard-btn').css("display", "none");

  $('#cite-nav li').removeClass('active');
  $('#' + citationInfo['style']).addClass('active');

  var url;
  if (citationInfo['style'] == 'bibtex') {
    url = 'https://data.datacite.org/application/x-bibtex/' + citationInfo['doi'];
  } else if (citationInfo['style'] == 'citeproc') {
    url = 'https://data.datacite.org/application/vnd.citationstyles.csl+json/' + citationInfo['doi'];
  } else {
    url = 'https://citation.datacite.org/format?style=' + citationInfo['style'];
    url += '&doi=' + citationInfo['doi'] + '&locale=en-US';
  }

  $.ajax({
    url: url,
    success: function(body) {
      $('#citation-text').css("color", "black");

      if (citationInfo['style'] === "bibtex") {
        body = "<pre>" + body + "</pre>";
      } else if (citationInfo['style'] === "citeproc") {
        body = "<pre>" + JSON.stringify(body, null, 2) + "</pre>";
      }

      $('#citation-text').html(body);
      spinner.stop();
      $('#clipboard-btn').css("display", "inline");
      new Clipboard('#clipboard-btn');
    },
    error: function (error) {
      console.log(error.responseJSON);
      $('#citation-text').css("color", "#e67e22");
      $('#citation-text').text(error.responseJSON);
      spinner.stop();
    }
  });
};

function setCiteBoxStyle(style) {
  citationInfo['style'] = style;
  $('#citation-text').html('');
  spinner.spin(document.getElementById('spinner'));
  updateCiteBox();
};

$(document).ready(function(e) {

  citationInfo = {style: 'apa'};
  spinnerOpts = {shadow: true, width: 2, speed: 2};
  spinner = new Spinner(spinnerOpts);
  $('#citation-modal-close').click(function(e) {
    $('#citation-modal').modal('hide');
  });


  $('.cite-link').click(function(e) {
    setCiteBoxStyle($(this).parent().attr('id'));
    $('#cite-nav li').removeClass('active');
    $(this).parent().addClass('active');
  });
});
