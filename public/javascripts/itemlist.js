MAX_EXPAND_CHARS = 240;

$(document).ready(function() {
  var replacePopoverWithErrorMessage = function($popover, message) {
    var $p = $('<p>').text('An error has occured: ' + message)
    var $btnClose = $('<button>').addClass('btn').addClass('btn-info').addClass('close-btn').text('Ok');
    var $btns = $('<div>').addClass('btn-container').append($btnClose);
    var $content = $('<div>').append($p).append($btns);
    var $newPopoverContent = $('<div>').addClass('popover-content').append($content);

    $('.popover-content').replaceWith($newPopoverContent);

    $('.close-btn').click(function(e) {
      $popover.popover('destroy');
      e.preventDefault();
      return false;
    });
  };

  var claimOkClickFn = function(e) {
    $('.claim-none').popover('destroy');
    $('.claim-waiting').popover('destroy');
    $('.claim-ok').popover('destroy');

    var $p = $('<p>').text('Last time we checked, this work was in your ORCID record.');
    var $btnClose = $('<button>').addClass('btn').addClass('btn-default').addClass('btn-sm').addClass('claim-close-btn').text('Close');
    var $btnsClose = $('<div>').addClass('btn-group').addClass('btn-group-sm').append($btnClose);
    var $btnToolbar = $('<div>').addClass('btn-toolbar').addClass('pull-right').append($btnsClose);
    var $content = $('<div>').append($p).append($btnToolbar);
    var $popover = $(this);

    $(this).popover({
      placement: 'bottom',
      html: true,
      title: 'Work is in your ORCID record',
      content: $('<div>').append($content).html(),
      trigger: 'manual'
    });

    $(this).popover('show');

    $('.claim-close-btn').click(function(e) {
      if (!$(this).hasClass('disabled')) {
        $popover.popover('destroy');
      }
      e.preventDefault();
      return false;
    });

    e.preventDefault();
    return false;
  };

  var performClaim = function($popover) {
    $.ajax({
        url: '/orcid/claim',
        data: { "doi": $popover.attr('data-doi'),
                "orcid": $popover.attr('data-orcid'),
                "api_key": $popover.attr('data-api-key') },
        success: function(data) {
          if (data.status === 'waiting') {
            $popover.popover('destroy');
            $popover.removeClass('claim-none');
            $popover.addClass('claim-waiting');
            $popover.find('span').text('Work is queued for your ORCID record');
            // $("#" + $popover.attr('data-doi')).html('Share');
          } else if (data.status === 'failed') {
            replacePopoverWithErrorMessage($popover, data);
          }
        },
        error: function() {
          $popover.popover('destroy');
        }
    });
  };

  var claimNoneClickFn = function(e) {
    $('.claim-none').popover('destroy');
    $('.claim-waiting').popover('destroy');
    $('.claim-ok').popover('destroy');

    var $p = $('<p>').text('Are you sure you want to add this work to your ORCID record?');
    var $btnNo = $('<button>').addClass('btn').addClass('btn-sm').addClass('claim-no-btn').text('Cancel');
    var $btnOk = $('<button>').addClass('btn').addClass('btn-default').addClass('btn-sm').addClass('claim-ok-btn').text('Ok');
    var $btnsNo = $('<div>').addClass('btn-group').addClass('btn-group-sm').append($btnNo);
    var $btnsOk = $('<div>').addClass('btn-group').addClass('btn-group-sm').append($btnOk);
    var $btnToolbar = $('<div>').addClass('btn-toolbar').addClass('pull-right').append($btnsNo).append($btnsOk);
    var $content = $('<div>').append($p).append($btnToolbar);
    var $popover = $(this);

    $(this).popover({
      placement: 'bottom',
      html: true,
      title: 'Add work to ORCID',
      content: $('<div>').append($content).html(),
      trigger: 'manual'
    });

    $(this).popover('show');

    $('.claim-no-btn').click(function(e) {
      if (!$(this).hasClass('disabled')) {
        $popover.popover('destroy');
      }
      e.preventDefault();
      return false;
    });

    $('.claim-ok-btn').click(function(e) {
      if ($(this).hasClass('disabled')) {
        return;
      }

      $(this).prepend($('<i>').addClass('fa').addClass('fa-refresh').addClass('fa-spin'));
      $(this).addClass('disabled');
      $(this).parent().find('.btn').addClass('disabled');

      performClaim($popover);

      e.preventDefault();
      return false;
    });

    e.preventDefault();
    return false;
  };

  var claimWaitingClickFn = function(e) {
    $('.claim-none').popover('destroy');
    $('.claim-waiting').popover('destroy');
    $('.claim-ok').popover('destroy');

    var $text = $('<div>').html('<span>Work has been queued to be added to your ORCID record. Please check back later.');
    var $btnClose = $('<button>').addClass('btn').addClass('btn-default').addClass('btn-sm').addClass('claim-close-btn').text('Close');
    var $btnsClose = $('<div>').addClass('btn-group').addClass('btn-group-sm').append($btnClose);
    var $btnToolbar = $('<div>').addClass('btn-toolbar').addClass('pull-right').append($btnsClose);
    var $content = $('<div>').append($text).append($btnToolbar);
    var $popover = $(this);

    $(this).popover({
      placement: 'bottom',
      html: true,
      title: 'Work is queued for your ORCID record',
      content: $('<div>').append($content).html(),
      trigger: 'manual'
    });

    $(this).popover('show');

    $('.claim-close-btn').click(function(e) {
      if (!$(this).hasClass('disabled')) {
        $popover.popover('destroy');
      }
      e.preventDefault();
      return false;
    });

    $('.claim-remove-btn').click(function(e) {
      if ($(this).hasClass('disabled')) {
        return;
      }

      $(this).prepend($('<i>').addClass('fa').addClass('fa-refresh').addClass('fa-spin'));
      $(this).parent().find('.btn').addClass('disabled');

      $.ajax({
        url: '/orcid/unclaim',
        data: {doi: $popover.attr('id')},
        success: function() {
          $popover.popover('destroy');
          $popover.removeClass('claim-waiting');
          $popover.addClass('claim-none');
          $popover.unbind('click');
          $popover.click(claimNoneClickFn);
          $popover.find('span').text('Add to ORCID');
          $popover.find('i').removeClass('fa-check-circle-o');
          $popover.find('i').addClass('fa-circle-o');
        },
        error: function() {
          $popover.popover('destroy');
        }
      });
      e.preventDefault();
      return false;
    });

    e.preventDefault();
    return false;
  };

  $('.claim-ok').click(claimOkClickFn);
  $('.claim-waiting').click(claimWaitingClickFn);
  $('.claim-none').click(claimNoneClickFn);
});
