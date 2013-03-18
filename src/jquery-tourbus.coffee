( ($) ->

  $.fn.tourbus = ( options={} ) ->
    options = $.extend( true, {}, $.fn.tourbus.defaults, options )
    this.each( -> new TourBus( this, options ) )

  $.fn.tourbus.defaults =
    debug: false
    autoDepart: false
    target: 'body'
    startAt: 0
    onDepart: -> null
    onStop: -> null
    onLegStart: -> null
    onLegEnd: -> null
    leg:
      scrollTo: null
      scrollSpeed: 150
      scrollContext: 100
      orientation: 'bottom'
      align: 'left'
      width: 'auto'
      margin: 10
      top: null
      left: null
      arrow: "50%"

  ### Internal ###

  class TourBus
    constructor: ( el, options ) ->
      @id = uniqueId()
      @$target = $(options.target)
      @$el = $(el)
      @$el.data( tourbus: @ )

      @options = options
      @currentLegIndex = null
      @totalLegs = @$el.find('li').length
      @_setupEvents()

      @$el.trigger('depart.tourbus') if @options.autoDepart
      @_log 'built tourbus with options', @options

    # start and end the entire tour, resetting to the beginning
    depart: ->
      @running = true
      @options.onDepart( @ )
      @_log 'departing'
      @legs = @_buildLegs()
      @currentLegIndex = @options.startAt
      @showLeg(@currentLegIndex)
    stop: ->
      return unless @running
      @hideAllLegs()
      @currentLegIndex = @options.startAt
      @options.onStop( @ )
      @running = false

    on: ( event, selector, fn ) ->
      @$target.on event, selector, fn

    currentLeg: ->
      return null if @currentLegIndex == null
      @legs[@currentLegIndex]

    # show/hide the current leg
    # hide cleans up the dom
    showLeg: ( index ) ->
      index ?= @currentLegIndex
      leg = @legs[index]
      preventDefault = @options.onLegStart( leg, @ )
      leg.show() if preventDefault != false
    hideLeg: ( index ) ->
      leg = @legs[index]
      preventDefault = @options.onLegEnd( leg, @ )
      leg.hide() if preventDefault != false
    hideAllLegs: ->
      $.each( @legs, $.proxy(@hideLeg, @) )

    # convenience to proceed to next/previous leg or end tour
    # when we're out of legs
    next: ->
      @hideAllLegs()
      @currentLegIndex++
      if @currentLegIndex > @totalLegs - 1 then @stop() else @showLeg(@currentLegIndex)
    prev: ->
      @hideAllLegs()
      @currentLegIndex--
      if @currentLegIndex < 0 then @stop() else @showLeg(@currentLegIndex)

    destroy: ->
      $.each( @legs, -> this.destroy() )
      @_teardownEvents()

    _buildLegs: ->
      # remove all previous legs
      $.each( @legs, ( _, leg ) -> leg.destroy() ) if @legs && @legs.length

      # build all legs
      $.map(
        @$el.find('li')
        ( legEl, i ) =>
          $legEl = $(legEl)
          data = $legEl.data()

          leg = new Leg(
            content: $legEl.html()
            target: data.el || 'body'
            tourbus: @
            index: i
            rawData: data
          )

          leg.render()
          @$target.append leg.$el
          leg.position()
          leg.hide()
          leg
      )

    _log: ->
      return unless @options.debug
      args = new Array(arguments)
      args.unshift "TOURBUS #{@id}:"
      console.log args...

    # provide even handling for external start/stop/next/prev
    _setupEvents: ->
      @$el.on 'depart.tourbus', $.proxy( @depart, @ )
      @$el.on 'stop.tourbus', $.proxy( @stop, @ )
      @$el.on 'next.tourbus', $.proxy( @next, @ )
      @$el.on 'prev.tourbus', $.proxy( @prev, @ )
    _teardownEvents: ->
      @$el.off '.tourbus'


  class Leg
    constructor: ( options ) ->
      @tourbus = options.tourbus
      @rawData = options.rawData
      @content = options.content
      @index = options.index
      @options = options
      @$target = $(options.target)

      if @$target.length == 0
        throw "#{@$target.selector} is not an element!"

      @_setupOptions()

      @_configureElement()
      @_configureTarget()
      @_configureScroll()

      @_setupEvents()

      @tourbus._log "leg #{@index} made with options", @options

    render: ->
      arrowClass = if @options.orientation == 'centered' then '' else 'tourbus-arrow'
      @$el.addClass( " #{arrowClass} tourbus-arrow-#{@options.orientation} " )
      html = """
        <div class='tourbus-leg-inner'>
          #{@content}
        </div>
      """
      @$el.css( width: @options.width ).html( html )
      return @

    destroy: ->
      @$el.remove()
      @_teardownEvents()

    position: ->
      # position arrow
      if @options.orientation != 'centered'
        rule = {}
        keys = top: 'left', bottom: 'left', left: 'top', right: 'top'
        @options.arrow += 'px' if typeof(@options.arrow) == 'number'
        rule[keys[@options.orientation]] = @options.arrow
        selector = "##{@id}.tourbus-arrow"
        @tourbus._log "adding rule for #{@id}", rule
        _addRule( "#{selector}:before, #{selector}:after", rule )

      css = @_offsets()
      @tourbus._log 'setting offsets on leg', css
      @$el.css css

    show: ->
      @$el.css visibility: 'visible', opacity: 1.0, zIndex: 9999
      @scrollIntoView()
    hide: ->
      if @tourbus.options.debug
        @$el.css visibility: 'visible', opacity: 0.4, zIndex: 0
      else
        @$el.css visibility: 'hidden'

    scrollIntoView: ->
      return unless $.fn.scrollTo && !isNaN(@options.scrollSpeed)
      return if @options.scrollTo == false
      scrollTarget = _dataProp( @options.scrollTo, @$el )
      @tourbus._log 'scrolling to', scrollTarget, @scrollSettings
      $.scrollTo( scrollTarget, @scrollSettings )

    _setupOptions: ->
      globalOptions = @tourbus.options.leg
      @options.top = _dataProp( @rawData.top, globalOptions.top )
      @options.left = _dataProp( @rawData.left, globalOptions.left )
      @options.scrollTo = _dataProp( @rawData.scrollTo, globalOptions.scrollTo )
      @options.scrollSpeed = _dataProp( @rawData.scrollSpeed, globalOptions.scrollSpeed )
      @options.scrollContext = _dataProp( @rawData.scrollContext, globalOptions.scrollContext )
      @options.margin = _dataProp( @rawData.margin, globalOptions.margin )
      @options.arrow = @rawData.arrow || globalOptions.arrow
      @options.align = @rawData.align || globalOptions.align
      @options.width = @rawData.width || globalOptions.width
      @options.orientation = @rawData.orientation || globalOptions.orientation

    _configureElement: ->
      @id = "tourbus-leg-id-#{@tourbus.id}-#{@options.index}"
      @$el = $("<div class='tourbus-leg'></div>")
      @el = @$el[0]
      @$el.attr( id: @id )
      @$el.css( zIndex: 9999 )

    _setupEvents: ->
      @$el.on 'click', '.tourbus-next', $.proxy( @tourbus.next, @tourbus )
      @$el.on 'click', '.tourbus-prev', $.proxy( @tourbus.prev, @tourbus )
      @$el.on 'click', '.tourbus-stop', $.proxy( @tourbus.stop, @tourbus )
    _teardownEvents: ->
      @$el.off 'click'

    _configureTarget: ->
      @targetOffset = @$target.offset()
      @targetOffset.top = @options.top if _dataProp( @options.top, false )
      @targetOffset.left = @options.left if _dataProp( @options.left, false )

      @targetWidth = @$target.outerWidth()
      @targetHeight = @$target.outerHeight()

    _configureScroll: ->
      @scrollSettings =
        offset: -@options.scrollContext
        easing: 'linear'
        axis: 'y'
        duration: @options.scrollSpeed

    _offsets: ->
      elHeight = @$el.height()
      elWidth = @$el.width()

      offsets = {}

      switch @options.orientation
        when 'centered'
          targetHeightOverride = $(window).height()
          offsets.top = @options.top
          unless _dataProp( offsets.top, false )
            offsets.top = (targetHeightOverride / 2) - (elHeight / 2)
          offsets.left = (@targetWidth / 2) - (elWidth / 2)
        when 'left'
          offsets.top = @targetOffset.top
          offsets.left = @targetOffset.left - elWidth - @options.margin
        when 'right'
          offsets.top = @targetOffset.top
          offsets.left = @targetOffset.left + @targetWidth + @options.margin
        when 'top'
          offsets.top = @targetOffset.top - elHeight - @options.margin
          offsets.left = @targetOffset.left
        when 'bottom'
          offsets.top = @targetOffset.top + @targetHeight + @options.margin
          offsets.left = @targetOffset.left

      validOrientations =
        top: [ 'left', 'right' ]
        bottom: [ 'left', 'right' ]
        left: [ 'top', 'bottom' ]
        right: [ 'top', 'bottom' ]

      if _include( @options.orientation, validOrientations[@options.align] )
        switch @options.align
          # when 'left' then offsets.left += 0 # aligned left by default
          # when 'top' then offsets.top += 0 # aligned top by default
          when 'right' then offsets.left += @targetWidth - elWidth
          when 'bottom' then offsets.top += @targetHeight - elHeight

      else if @options.align == 'center'
        if _include( @options.orientation, validOrientations.left )
          # centering horizontally
          targetHalf = @targetWidth / 2
          elHalf = elWidth / 2
          dimension = 'left'
        else
          # centering vertically
          targetHalf = @targetHeight / 2
          elHalf = elHeight / 2
          dimension = 'top'

        if targetHalf > elHalf
          offsets[dimension] += (targetHalf - elHalf)
        else
          offsets[dimension] -= (elHalf - targetHalf)

      return offsets

    _debugHtml: ->
      debuggableOptions = $.extend( true, {}, @options )
      delete debuggableOptions.tourbus
      delete debuggableOptions.content
      delete debuggableOptions.target
      """
        <small>
          This leg built with:
          <pre>#{JSON.stringify(debuggableOptions, undefined, 2)}</pre>
        </small>
      """

  _tours = 0; uniqueId = -> return _tours++

  _dataProp = ( possiblyFalsy, alternative ) ->
    if possiblyFalsy == null || typeof(possiblyFalsy) == 'undefined'
      return alternative
    return possiblyFalsy

  _include = ( value, array ) ->
    (array||[]).indexOf( value ) != -1

  _addRule = (( styleTag ) ->
    sheet = document.head.appendChild(styleTag).sheet
    return ( selector, css ) ->
      propText = $.map( Object.keys(css), ( p ) -> "#{p}:#{css[p]}" ).join(';')
      sheet.insertRule( "#{selector} { #{propText} }", sheet.cssRules.length )
  )( document.createElement('style') )

)( jQuery )
