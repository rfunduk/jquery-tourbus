$(document).ready( function() {

  $('img').imagesLoaded( function() {
    var info = $('#tour-info');

    $('#tourbus-demo-1').imagesLoaded( function() {
      $(this).tourbus( {
        // debug: true,
        // autoDepart: true,
        onLegStart: function( leg, tourbus ) {
          info.html("Intro tour is on leg: " + (leg.index+1));

          // auto-progress where required
          if( leg.rawData.autoProgress ) {
            var currentIndex = leg.index;
            setTimeout(
              function() {
                if( tourbus.currentLegIndex != currentIndex ) { return; }
                tourbus.next();
              },
              leg.rawData.autoProgress
            );
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
        onDepart: function() {
          info.html("Intro tour started!");
        },
        onStop: function() {
          info.html("Intro tour is inactive...");
        }
      } );
    } );

    var docsTour = $('#tourbus-demo-2').tourbus( {
      onLegStart: function( leg, tourbus ) {
        if( leg.rawData.andNext ) {
          tourbus.currentLegIndex++;
          tourbus.showLeg();
        }
      }
    } );

    $(document).on( 'click', '.docs-tour, .go-to-docs', function() {
      $('#tourbus-demo-1').trigger('stop.tourbus');
      docsTour.data('tourbus').depart();
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
