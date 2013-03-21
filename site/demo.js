$(document).ready( function() {

  $('img').imagesLoaded( function() {
    var info = $('#tour-info');

    $('#tourbus-demo-1').tourbus( {
      // debug: true,
      // autoDepart: true,
      onLegStart: function( leg, bus ) {
        info.html("Intro tour is on leg: " + (leg.index+1));

        // auto-progress where required
        if( leg.rawData.autoProgress ) {
          var currentIndex = leg.index;
          setTimeout(
            function() {
              if( bus.currentLegIndex != currentIndex ) { return; }
              bus.next();
            },
            leg.rawData.autoProgress
          );
        }

        // highlight where required
        if( leg.rawData.highlight ) {
          leg.$target.addClass('intro-tour-highlight');
          $('.intro-tour-overlay').show();
        }

        // fade/slide in first leg
        if( leg.index == 0 ) {
          leg.$el
            .css( { visibility: 'visible', opacity: 0, top: leg.options.top / 2 } )
            .animate( { top: leg.options.top, opacity: 1.0 }, 500,
                      function() { leg.show(); } );
          return false;
        }
      },
      onLegEnd: function( leg ) {
        // remove highlight when leaving this leg
        if( leg.rawData.highlight ) {
          leg.$target.removeClass('intro-tour-highlight');
          $('.intro-tour-overlay').hide();
        }
      },
      onDepart: function() {
        info.html("Intro tour started!");
      },
      onStop: function() {
        info.html("Intro tour is inactive...");
      }
    } );

    var docsBus = $.tourbus( '#tourbus-demo-2' );
    $.tourbus( 'build', '#tourbus-demo-3', { autoDepart: true } );

    $(document).on( 'click', '.docs-tour, .go-to-docs', function() {
      $('#tourbus-demo-1').trigger('stop.tourbus');
      docsBus.depart();
    } );
    $(document).on( 'click', '.start-intro-tour', function() {
      $('#tourbus-demo-1').trigger('depart.tourbus');
    } );
  } );

  $('script.highlight').each( function() {
    var block = $(this);
    var code = $.trim( block.html() ).escape();
    var language = block.data('language');
    block = $("<pre class='language-" + language + "'><code>" + code + "</code></pre>").insertAfter(block);
    hljs.highlightBlock( block[0] );
  } );

} );

String.prototype.escape = function() {
  var tagsToReplace = {
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;'
  };
  return this.replace( /[&<>]/g, function( tag ) {
    return tagsToReplace[tag] || tag;
  } );
};
