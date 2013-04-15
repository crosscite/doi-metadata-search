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
    var $btnLogin = $('<button>').addClass('btn').addClass('btn-info').addClass('login-btn').text('Sign in to ORCID');
    var $btnClose = $('<button>').addClass('btn').addClass('close-btn').text('Close');
    var $btns = $('<div>').addClass('btn-container').append($btnClose).append($btnLogin);
    var $content = $('<div>').append($p).append($btns);
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
  }
  
  var performSync = function($popover) {
    $.ajax({
      url: '/orcid/sync',
      success: function(data) {
        if (data['status'] == 'ok') {
          location.reload();
        } else if (data['status'] == 'oauth_timeout') {
          replacePopoverWithLogin($popover);
        } else {
          location.reload();
        }  
      },
      error: function() {
        location.reload();
      }
    });
  }

  var claimOkClickFn = function(e) {
    $('.claim-none').popover('destroy');
    $('.claim-warn').popover('destroy');
    $('.claim-ok').popover('destroy');

    var $p = $('<p>').text('Last time we checked, this work was in your ORCID profile. Refresh to retrieve changes to your works from ORCID.');
    var $btnClose = $('<button>').addClass('btn').addClass('claim-close-btn').text('Close');
    var $btnRefresh = $('<button>').addClass('btn').addClass('btn-warning').addClass('claim-refresh-btn').text('Refresh');
    var $btns = $('<div>').addClass('btn-container').append($btnClose).append($btnRefresh);
    var $content = $('<div>').append($p).append($btns);
    var $popover = $(this);

    $(this).popover({
      placement: 'bottom',
      html: true,
      title: 'Work is in your ORCID profile',
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
        $(this).prepend($('<i>').addClass('icon-refresh').addClass('icon-spin'));
        performSync($popover);
      }
      e.preventDefault();
      return false;
    });

    e.preventDefault();
    return false;
  }

  var performClaim = function($popover) {
    $.ajax({
        url: '/orcid/claim',
        data: {doi: $popover.attr('id')},
        success: function(data) {
          if (data['status'] == 'ok' || data['status'] == 'ok_visible') {
            $popover.popover('destroy');
            $popover.removeClass('claim-none');
            $popover.unbind('click');
            $popover.find('i').removeClass('icon-circle-blank');
            $popover.find('i').addClass('icon-circle');

            if (data['status'] == 'ok') {
              $popover.addClass('claim-warn');
              $popover.click(claimWarnClickFn);
              $popover.find('span').text('Not visible');
            } else {
              $popover.addClass('claim-ok');
              $popover.click(claimOkClickFn);
              $popover.find('span').text('In your profile');
            }
          } else if (data['status'] == 'oauth_timeout') {
            replacePopoverWithLogin($popover);
          } else if (data['status'] == 'no_such_doi') {
            $popover.find('span').text('No such DOI');
            $popover.popover('destroy');
          } else {
            $popover.find('span').text('ERROR: ' + data['status']);
            $popover.popover('destroy');
          }
        },
        error: function() {
          $popover.popover('destroy');
        }
    });
  }
        
  var claimNoneClickFn = function(e) {
    $('.claim-none').popover('destroy');
    $('.claim-warn').popover('destroy');
    $('.claim-ok').popover('destroy');
    
    var $p = $('<p>').text('Are you sure you want to add this work to your ORCID profile?');
    var $btnNo = $('<button>').addClass('btn').addClass('claim-no-btn').text('No');
    var $btnOk = $('<button>').addClass('btn').addClass('btn-success').addClass('claim-ok-btn').text('Yes');
    var $btns = $('<div>').addClass('btn-container').append($btnNo).append($btnOk);
    var $content = $('<div>').append($p).append($btns);
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
      
      $(this).prepend($('<i>').addClass('icon-refresh').addClass('icon-spin'));
      $(this).addClass('disabled');
      $(this).parent().find('.btn').addClass('disabled');

      performClaim($popover);
      
      e.preventDefault();
      return false;
    });

    e.preventDefault();
    return false;
  }

  var claimWarnClickFn = function(e) {
    $('.claim-none').popover('destroy');
    $('.claim-warn').popover('destroy');
    $('.claim-ok').popover('destroy');

    var $text = $('<div>').html('<span>Work has been added to your ORCID profile but is marked as private. Visit your <a href="https://orcid.org/my-orcid" target="_blank"><i class="icon-external-link"></i>ORCID profile</a> to set this work\'s visibility to public or limited.<br/><br/>If you have removed this private work from your ORCID profile you can click the button below to remove it from CrossRef Metadata Search.</span>');
    var $btnClose = $('<button>').addClass('btn').addClass('claim-close-btn').text('Close');
    var $btnRefresh = $('<button>').addClass('btn').addClass('btn-warning').addClass('claim-refresh-btn').text('Refresh');
    var $btnRemove = $('<button>').addClass('btn').addClass('btn-danger').addClass('claim-remove-btn').text('Remove');
    var $btns = $('<div>').addClass('btn-container').append($btnClose).append($btnRefresh).append($btnRemove);
    var $content = $('<div>').append($text).append($btns);
    var $popover = $(this);
    
    $(this).popover({
      placement: 'bottom',
      html: true,
      title: 'Work is private in your ORCID profile',
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
        $(this).prepend($('<i>').addClass('icon-refresh').addClass('icon-spin'));
        performSync($popover);
      }
      e.preventDefault();
      return false;
    });
    
    $('.claim-remove-btn').click(function(e) {
      if ($(this).hasClass('disabled')) {
        return;
      }
      
      $(this).prepend($('<i>').addClass('icon-refresh').addClass('icon-spin'));
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
          $popover.find('i').removeClass('icon-circle');
          $popover.find('i').addClass('icon-circle-blank');
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
  }

  $('.claim-ok').click(claimOkClickFn);
  $('.claim-warn').click(claimWarnClickFn);
  $('.claim-none').click(claimNoneClickFn);
});