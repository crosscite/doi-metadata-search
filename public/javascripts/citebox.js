function showCiteBox(doi, title) {
  citationInfo['doi'] = doi;
  citationInfo['title'] = title;

  updateCiteBox();
  $('#citation-modal').modal();
};

function updateCiteBox() {
  // make sure style is set
  citationInfo['style'] = citationInfo['style'] || 'apa';

  $('#citation-description').text(citationInfo['doi']);
  $('#citation-modal-title').html(citationInfo['title']);

  $('#cite-nav li').removeClass('active');
  $('#' + citationInfo['style']).addClass('active');

  var url = $('#site-title').attr('data-conneg');

  if (citationInfo['style'] == 'bibtex') {
    url += '/dois/application/x-bibtex/' + citationInfo['doi'];
  } else if (citationInfo['style'] == 'ris') {
    url += '/dois/application/x-research-info-systems/' + citationInfo['doi'];
  } else {
    url += '/dois/text/x-bibliography/' + citationInfo['doi'] + '?style=' + citationInfo['style'];
  }

  $.ajax({
    url: url,
    success: function(body) {
      $('#citation-text').css("color", "black");

      if (citationInfo['style'] === "bibtex" || citationInfo['style'] === "ris") {
        body = "<pre>" + body + "</pre>";
      }

      $('#citation-text').html(body);
      $('#clipboard-btn').css("display", "inline");
      new Clipboard('#clipboard-btn');
    },
    error: function (error) {
      console.log(error.responseJSON);
      $('#citation-text').css("color", "#e67e22");
      $('#citation-text').text(error.responseJSON);
      $('#clipboard-btn').css("display", "none");
    }
  });
};

function setCiteBoxStyle(style) {
  citationInfo['style'] = style;
  $('#citation-text').html('');
  updateCiteBox();
};

$(document).ready(function(e) {
  citationInfo = {style: 'apa'};
  $('#citation-modal-close').click(function(e) {
    $('#citation-modal').modal('hide');
  });

  $('.cite-link').click(function(e) {
    setCiteBoxStyle($(this).parent().attr('id'));
  });
});
