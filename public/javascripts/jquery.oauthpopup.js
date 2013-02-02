/*!
 *  * jQuery OAuth via popup window plugin
 *  *
 *  * @author  Nobu Funaki @zuzara
 *  *
 *  * Dual licensed under the MIT and GPL licenses:
 *  *   http://www.opensource.org/licenses/mit-license.php
 *  *   http://www.gnu.org/licenses/gpl.html
 *  *
 *  * @modified_by Geoffrey Bilder (center window)
 *  *
 *  */
var currentOAuthModel = null;
var currentOAuthCallback = null;

function oauthIframeCallback() {
  currentOAuthModel.modal('hide');
}

(function($){
    //  inspired by DISQUS
    $.oauthpopup = function(options)
    {
        if (!options || !options.path) {
            throw new Error("options.path must not be empty");
        }
      var width = 500;
      var height = 560;
      var left = (screen.width  - width)/2;
      var top = (screen.height - height)/2;
        options = $.extend({
            windowName: 'ConnectWithOAuth' // should not include space for IE
          , windowOptions: 'location=0,status=0,width=' + width + ',height=' + height + ',left=' + left + ',top=' + top 
          , callback: function(){ window.location.reload(); }
        }, options);

        var oauthWindow   = window.open(options.path, options.windowName, options.windowOptions);
        var oauthInterval = window.setInterval(function(){
            if (oauthWindow.closed) {
                window.clearInterval(oauthInterval);
                options.callback();
            }
        }, 1000);
    };

  $.oauthmodel = function(options) {
    var $model = $('<div>').addClass('model').addClass('hide').addClass('fade').appendTo($('body'));
    var $iframe = $('<iframe>').attr('src', options['path']).appendTo($model);

    $model.model('show');

    currentOAuthModel = $model;
    currentOAuthCallback = options['callback'];
  };
})(jQuery);