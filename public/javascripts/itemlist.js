MAX_EXPAND_CHARS = 240;

$(document).ready(function() {
  var replacePopoverWithErrorMessage = function($popover, message) {
    var $p = $('<p>').text('Claim failed with message "' + message + '".').addClass('error');
    var $btnClose = $('<button>').addClass('btn').addClass('btn-default').addClass('btn-sm').addClass('claim-close-btn').text('Close');
    var $btnsClose = $('<div>').addClass('btn-group').addClass('btn-group-sm').append($btnClose);
    var $btnToolbar = $('<div>').addClass('btn-toolbar').addClass('pull-right').append($btnsClose);
    var $content = $('<div>').append($p).append($btnToolbar);
    var $newPopoverContent = $('<div>').addClass('popover-content').append($content);

    $('.popover-content').replaceWith($newPopoverContent);

    $('.claim-close-btn').click(function(e) {
      $popover.popover('destroy');
      e.preventDefault();
      return false;
    });
  };

  var claimOkClickFn = function(e) {
    $('.claim-none').popover('destroy');
    $('.claim-waiting').popover('destroy');
    $('.claim-warn').popover('destroy');
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

  var claimDeleteClickFn = function(e) {
    $('.claim-none').popover('destroy');
    $('.claim-waiting').popover('destroy');
    $('.claim-warn').popover('destroy');
    $('.claim-ok').popover('destroy');

    var $p = $('<p>').text('Are you sure you want to remove this work from your ORCID record?').addClass('icon-warning');
    var $btnNo = $('<button>').addClass('btn').addClass('btn-warning').addClass('btn-sm').addClass('claim-no-btn').text('Cancel');
    var $btnOk = $('<button>').addClass('btn').addClass('btn-warning').addClass('btn-fill').addClass('btn-sm').addClass('claim-ok-btn').text('Ok');
    var $btnsNo = $('<div>').addClass('btn-group').addClass('btn-group-sm').append($btnNo);
    var $btnsOk = $('<div>').addClass('btn-group').addClass('btn-group-sm').append($btnOk);
    var $btnToolbar = $('<div>').addClass('btn-toolbar').addClass('pull-right').append($btnsNo).append($btnsOk);
    var $content = $('<div>').append($p).append($btnToolbar);
    var $popover = $(this);

    $(this).popover({
      placement: 'bottom',
      html: true,
      title: 'Remove work from ORCID',
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

  var claimWarnClickFn = function(e) {
    $('.claim-none').popover('destroy');
    $('.claim-waiting').popover('destroy');
    $('.claim-warn').popover('destroy');
    $('.claim-ok').popover('destroy');

    var $p = $('<p>').html('Please check <strong>DataCite Profiles</strong> for more information.');
    var $btnClose = $('<button>').addClass('btn').addClass('btn-primary').addClass('btn-fill').addClass('btn-sm').addClass('claim-close-btn').text('Close');
    var $btnsClose = $('<div>').addClass('btn-group').addClass('btn-group-sm').append($btnClose);
    var $btnToolbar = $('<div>').addClass('btn-toolbar').addClass('pull-right').append($btnsClose);
    var $content = $('<div>').append($p).append($btnToolbar);
    var $popover = $(this);

    $(this).popover({
      placement: 'bottom',
      html: true,
      title: 'An error occured while adding to ORCID record',
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
        url: $popover.attr('data-url'),
        method: "POST",
        data: JSON.stringify({ "doi": $popover.attr('data-doi'),
                               "orcid": $popover.attr('data-orcid'),
                               "claim_action": "create",
                               "source_id": "orcid_search" }),
        beforeSend: function (xhr) {
            xhr.setRequestHeader("Content-Type","application/json");
            xhr.setRequestHeader("Authorization", "Token token=" + $popover.attr('data-api-key'));
        },
        success: function(response) {
          if (typeof response.data !== "undefined" && response.data.attributes.state === 'waiting') {
            $popover.popover('destroy');
            $popover.removeClass('claim-none');
            $popover.addClass('claim-waiting');
            $popover.find('span').text('Work queued for ORCID record');
          }
        },
        error: function(response) {
          console.log(response)
          var message = "An error occured."
          if (typeof response.responseText !== "undefined") {
            var responseText = JSON.parse(response.responseText);
            message = (typeof responseText.errors !== "undefined") ? responseText.errors[0].title : message;
          } else if (typeof response.statusText !== "undefined") {
            message = response.statusText;
          }
          replacePopoverWithErrorMessage($popover, message);
        }
    });
  };

  var claimNoneClickFn = function(e) {
    $('.claim-none').popover('destroy');
    $('.claim-waiting').popover('destroy');
    $('.claim-warn').popover('destroy');
    $('.claim-ok').popover('destroy');

    var $p = $('<p>').text('Are you sure you want to add this work to your ORCID record?');
    var $btnNo = $('<button>').addClass('btn').addClass('btn-primary').addClass('btn-sm').addClass('claim-no-btn').text('Cancel');
    var $btnOk = $('<button>').addClass('btn').addClass('btn-primary').addClass('btn-fill').addClass('btn-sm').addClass('claim-ok-btn').text('Ok');
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
    $('.claim-warn').popover('destroy');
    $('.claim-ok').popover('destroy');

    var $text = $('<div>').html('<span>Work has been queued to be added to your ORCID record. Please check back later.');
    var $btnClose = $('<button>').addClass('btn').addClass('btn-primary').addClass('btn-fill').addClass('btn-sm').addClass('claim-close-btn').text('Close');
    var $btnsClose = $('<div>').addClass('btn-group').addClass('btn-group-sm').append($btnClose);
    var $btnToolbar = $('<div>').addClass('btn-toolbar').addClass('pull-right').append($btnsClose);
    var $content = $('<div>').append($text).append($btnToolbar);
    var $popover = $(this);

    $(this).popover({
      placement: 'bottom',
      html: true,
      title: 'Work queued for ORCID record',
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
  $('.claim-warn').click(claimWarnClickFn);
});
