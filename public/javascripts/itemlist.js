MAX_EXPAND_CHARS = 240;

$(document).ready(function() {
  $('.oa-tooltip').tooltip({
    title: 'Article is published in a journal present in the Directory of Open Access Journals.'
  });

  $('.expand').each(function() {
    if ($(this).text().length > MAX_EXPAND_CHARS) {
      $(this).data('full-text', $(this).text());
      $(this).text($(this).text().substring(0, MAX_EXPAND_CHARS));
      $(this).append($('<a>').addClass('expander').text('...').attr('href', '#'));
    }
  });

  $('.expander').click(function(e) {
    var parent = $(this).parent();
    parent.text(parent.data('full-text'));
    e.preventDefault();
    return false;
  });

  var replacePopoverWithLogin = function($popover) {
    var $p = $('<p>').text('Your sign in to ORCID has expired. Please sign back in.')
    var $btnClose = $('<button>').addClass('btn').addClass('close-btn').addClass('btn-sm').text('Close');
    var $btnLogin = $('<button>').addClass('btn').addClass('btn-info').addClass('btn-sm').addClass('login-btn').text('Sign in to ORCID');
    var $btnsClose = $('<div>').addClass('btn-group').addClass('btn-group-sm').append($btnClose);
    var $btnsLogin = $('<div>').addClass('btn-group').addClass('btn-group-sm').append($btnLogin);
    var $btnToolbar = $('<div>').addClass('btn-toolbar').addClass('pull-right').append($btnsClose).append($btnsLogin);
    var $content = $('<div>').append($p).append($btnToolbar);

    var $newPopoverContent = $('<div>').addClass('popover-content').append($content);

    $('.popover-content').replaceWith($newPopoverContent);

    $('.login-btn').click(function(e) {
      $.oauthpopup({path: '/auth/orcid',
                    callback: function() {
                      location.reload();
                    }
      });
      e.preventDefault();
      return false;
    });

    $('.close-btn').click(function(e) {
      $popover.popover('destroy');
      e.preventDefault();
      return false;
    });
  };

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

  var performSync = function($popover) {
    $.ajax({
      url: '/orcid/sync',
      success: function(data) {
        if (data.status === 'ok') {
          location.reload();
        } else if (data.status === 'oauth_timeout') {
          replacePopoverWithLogin($popover);
        } else {
          location.reload();
        }
      },
      error: function() {
        location.reload();
      }
    });
  };

  var claimOkClickFn = function(e) {
    $('.claim-none').popover('destroy');
    $('.claim-warn').popover('destroy');
    $('.claim-ok').popover('destroy');

    var $p = $('<p>').text('Last time we checked, this work was in your ORCID record. Refresh to retrieve changes to your works from ORCID.');
    var $btnClose = $('<button>').addClass('btn').addClass('btn-sm').addClass('claim-close-btn').text('Cancel');
    var $btnRefresh = $('<button>').addClass('btn').addClass('btn-default').addClass('btn-sm').addClass('claim-refresh-btn').text('Refresh');
    var $btnsClose = $('<div>').addClass('btn-group').addClass('btn-group-sm').append($btnClose);
    var $btnsRefresh = $('<div>').addClass('btn-group').addClass('btn-group-sm').append($btnRefresh);
    var $btnToolbar = $('<div>').addClass('btn-toolbar').addClass('pull-right').append($btnsClose).append($btnsRefresh);
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

    $('.claim-refresh-btn').click(function(e) {
      if (!$(this).hasClass('disabled')) {
        $(this).parent().find('.btn').addClass('disabled');
        $(this).prepend($('<i>').addClass('fa').addClass('fa-refresh').addClass('fa-spin'));
        performSync($popover);
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
        data: { "doi": $popover.attr('id') },
        success: function(data) {
          if (data.status === 'ok' || data.status === 'ok_visible') {
            $popover.popover('destroy');
            $popover.removeClass('claim-none');
            $popover.unbind('click');
            $popover.find('i').removeClass('fa-circle-o');
            $popover.find('i').addClass('fa-check-circle-o');
            if (data.status === 'ok') {
              $popover.addClass('claim-warn');
              $popover.click(claimWarnClickFn);
              $popover.find('span').text('Not visible');
            } else {
              $popover.addClass('claim-ok');
              $popover.click(claimOkClickFn);
              $popover.find('span').text('In your record');
            }
          } else if (data.status === 'error') {
            replacePopoverWithErrorMessage($popover, data.message);
          } else if (data.status === 'oauth_timeout') {
            replacePopoverWithLogin($popover);
          } else {
            $popover.popover('destroy');
          }
        },
        error: function() {
          $popover.popover('destroy');
        }
    });
  };

  var claimNoneClickFn = function(e) {
    $('.claim-none').popover('destroy');
    $('.claim-warn').popover('destroy');
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

  var claimWarnClickFn = function(e) {
    $('.claim-none').popover('destroy');
    $('.claim-warn').popover('destroy');
    $('.claim-ok').popover('destroy');

    var $text = $('<div>').html('<span>Work has been added to your ORCID record but is marked as private. Visit your <a href="https://orcid.org/my-orcid" target="_blank"><i class="fa fa-external-link"></i>ORCID record</a> to set this work\'s visibility to public or limited.<br/><br/>If you have removed this private work from your ORCID record you can click the button below to remove it here.</span>');
    var $btnClose = $('<button>').addClass('btn').addClass('claim-close-btn').addClass('btn-sm').text('Close');
    var $btnRefresh = $('<button>').addClass('btn').addClass('btn-warning').addClass('btn-sm').addClass('claim-refresh-btn').text('Refresh');
    var $btnRemove = $('<button>').addClass('btn').addClass('btn-danger').addClass('btn-sm').addClass('claim-remove-btn').text('Remove');
    var $btnsClose = $('<div>').addClass('btn-group').addClass('btn-group-sm').append($btnClose);
    var $btnsRefresh = $('<div>').addClass('btn-group').addClass('btn-group-sm').append($btnRefresh);
    var $btnsRemove = $('<div>').addClass('btn-group').addClass('btn-group-sm').append($btnRemove);
    var $btnToolbar = $('<div>').addClass('btn-toolbar').addClass('pull-right').append($btnsClose).append($btnsRefresh).append($btnsRemove);
    var $content = $('<div>').append($p).append($btnToolbar);
    var $popover = $(this);

    $(this).popover({
      placement: 'bottom',
      html: true,
      title: 'Work is private in your ORCID record',
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

    $('.claim-refresh-btn').click(function(e) {
      if (!$(this).hasClass('disabled')) {
        $(this).parent().find('.btn').addClass('disabled');
        $(this).prepend($('<i>').addClass('fa').addClass('fa-refresh').addClass('fa-spin'));
        performSync($popover);
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
          $popover.removeClass('claim-warn');
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
  $('.claim-warn').click(claimWarnClickFn);
  $('.claim-none').click(claimNoneClickFn);
});
