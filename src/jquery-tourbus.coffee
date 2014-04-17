( ($) ->

  tourbus = $.tourbus = ( args... ) ->
    method = args[0]
    if methods.hasOwnProperty( method )
      args = args[1..]
    else if method instanceof $
      method = 'build'
    else if typeof method == 'string'
      method = 'build'
      args[0] = $(args[0])
    else
      $.error( "Unknown method of $.tourbus --", args )

    methods[method].apply( this, args )

  $.fn.tourbus = ( args... ) ->
    this.each ->
      args.unshift( $(this) )
      tourbus( 'build', args... )
      return this

  methods =
    build: ( el, options={} ) ->
      options = $.extend( true, {}, tourbus.defaults, options )
      built = []
      el = $(el) unless el instanceof $
      el.each -> built.push( _assemble( this, options ) )
      $.error( "#{el.selector} was not found!" ) if built.length == 0
      return built[0] if built.length == 1
      return built

    destroyAll: ->
      bus.destroy() for index, bus of _busses

    expose: ( global ) ->
      global.tourbus = Bus: Bus, Leg: Leg

  tourbus.defaults =
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
      zindex: 9999
      arrow: "50%"

  ### Internal ###

  class Bus
    constructor: ( el, options ) ->
      @id = uniqueId()
      @$target = $(options.target)
      @$el = $(el)
      @$el.data( tourbus: @ )

      @options = options
      @currentLegIndex = null
      @legs = null
      @legEls = @$el.children('li')
      @totalLegs = @legEls.length
      @_setupEvents()

      @$el.trigger('depart.tourbus') if @options.autoDepart
      @_log 'built tourbus with el', el.toString(), 'and options', @options

    # start and end the entire tour, resetting to the beginning
    depart: ->
      @running = true
      @options.onDepart( @ )
      @_log 'departing', @
      @legs = @_buildLegs()
      @currentLegIndex = @options.startAt
      @showLeg()
    stop: ->
      return unless @running
      $.each( @legs, $.proxy(@hideLeg, @) ) if @legs
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
      @_log 'showLeg:', leg
      preventDefault = @options.onLegStart( leg, @ )
      leg.show() if preventDefault != false
    hideLeg: ( index ) ->
      index ?= @currentLegIndex
      leg = @legs[index]
      if leg.visible
        @_log 'hideLeg:', leg
        preventDefault = @options.onLegEnd( leg, @ )
        leg.hide() if preventDefault != false

    # refresh on-screen positions of all legs (can be used after window resize)
    repositionLegs: ->
      $.each( @legs, -> this.reposition() ) if @legs

    # convenience to proceed to next/previous leg or end tour
    # when we're out of legs
    next: ->
      @hideLeg()
      @currentLegIndex++
      return @stop() if @currentLegIndex > @totalLegs - 1
      @showLeg()
    prev: ( cb ) ->
      @hideLeg()
      @currentLegIndex--
      return @stop() if @currentLegIndex < 0
      @showLeg()

    destroy: ->
      $.each( @legs, -> this.destroy() ) if @legs
      @legs = null
      delete _busses[@id]
      @_teardownEvents()

    _buildLegs: ->
      # remove all previous legs
      $.each( @legs, ( _, leg ) -> leg.destroy() ) if @legs

      # build all legs
      $.map(
        @legEls,
        ( legEl, i ) =>
          $legEl = $(legEl)
          data = $legEl.data()

          leg = new Leg(
            $orig: $legEl
            content: $legEl.html()
            target: data.el || 'body'
            bus: @
            index: i
            rawData: data
          )

          leg.render()
          @$target.append leg.$el
          leg._position()
          leg.hide()
          leg
      )

    _log: ->
      return unless @options.debug
      console.log "TOURBUS #{@id}:", arguments...

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
      @bus = options.bus
      @rawData = options.rawData
      @$orig = options.$orig
      @content = options.content
      @index = options.index
      @options = options
      @$target = $(options.target)
      @visible = false

      if @$target.length == 0
        throw "#{@$target.selector} is not an element!"

      @_setupOptions()

      @_configureElement()
      @_configureTarget()
      @_configureScroll()

      @_setupEvents()

      @bus._log "leg #{@index} made with options", @options

    render: ->
      arrowClass = if @options.orientation == 'centered' then '' else 'tourbus-arrow'
      @$el.addClass( " #{arrowClass} tourbus-arrow-#{@options.orientation} " )
      html = """
        <div class='tourbus-leg-inner'>
          #{@content}
        </div>
      """
      @$el.css( width: @options.width, zIndex: @options.zindex ).html( html )
      return @

    destroy: ->
      @$el.remove()
      @_teardownEvents()

    reposition: ->
      @_configureTarget()
      @_position()

    _position: ->
      # position arrow
      if @options.orientation != 'centered'
        rule = {}
        keys = top: 'left', bottom: 'left', left: 'top', right: 'top'
        @options.arrow += 'px' if typeof(@options.arrow) == 'number'
        rule[keys[@options.orientation]] = @options.arrow
        selector = "##{@id}.tourbus-arrow"
        @bus._log "adding rule for #{@id}", rule
        _addRule( "#{selector}:before, #{selector}:after", rule )

      css = @_offsets()
      @bus._log 'setting offsets on leg', css
      @$el.css css

    show: ->
      @visible = true
      @$el.css visibility: 'visible', opacity: 1.0, zIndex: @options.zindex
      @scrollIntoView()
    hide: ->
      @visible = false
      if @bus.options.debug
        @$el.css visibility: 'visible', opacity: 0.4, zIndex: 0
      else
        @$el.css visibility: 'hidden'

    scrollIntoView: ->
      return unless @willScroll
      scrollTarget = _dataProp( @options.scrollTo, @$el )
      @bus._log 'scrolling to', scrollTarget, @scrollSettings
      $.scrollTo( scrollTarget, @scrollSettings )

    _setupOptions: ->
      globalOptions = @bus.options.leg
      @options.top = _dataProp( @rawData.top, globalOptions.top )
      @options.left = _dataProp( @rawData.left, globalOptions.left )
      @options.scrollTo = _dataProp( @rawData.scrollTo, globalOptions.scrollTo )
      @options.scrollSpeed = _dataProp( @rawData.scrollSpeed, globalOptions.scrollSpeed )
      @options.scrollContext = _dataProp( @rawData.scrollContext, globalOptions.scrollContext )
      @options.margin = _dataProp( @rawData.margin, globalOptions.margin )
      @options.arrow = @rawData.arrow || globalOptions.arrow
      @options.align = @rawData.align || globalOptions.align
      @options.width = @rawData.width || globalOptions.width
      @options.zindex = @rawData.zindex || globalOptions.zindex
      @options.orientation = @rawData.orientation || globalOptions.orientation

    _configureElement: ->
      busClasses = ( @bus.$el.attr('class') || '' ).replace('tourbus-legs', '')
      @id = "tourbus-leg-id-#{@bus.id}-#{@options.index}"
      @$el = $("<div class='tourbus-leg'></div>").addClass(busClasses).addClass(@$orig.attr('class'))
      @el = @$el[0]
      @$el.attr( id: @id )
      @$el.css( zIndex: @options.zindex )

    _setupEvents: ->
      @$el.on 'click', '.tourbus-next', $.proxy( @bus.next, @bus )
      @$el.on 'click', '.tourbus-prev', $.proxy( @bus.prev, @bus )
      @$el.on 'click', '.tourbus-stop', $.proxy( @bus.stop, @bus )
    _teardownEvents: ->
      @$el.off 'click'

    _configureTarget: ->
      @targetOffset = @$target.offset()
      @targetOffset.top = @options.top if _dataProp( @options.top, false )
      @targetOffset.left = @options.left if _dataProp( @options.left, false )

      @targetWidth = @$target.outerWidth()
      @targetHeight = @$target.outerHeight()

    _configureScroll: ->
      @willScroll = $.fn.scrollTo && @options.scrollTo != false
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

  _tours = 0; uniqueId = -> return _tours++

  _busses = {}
  _assemble = ->
    bus = new Bus( arguments... )
    _busses[bus.id] = bus
    bus

  _dataProp = ( possiblyFalsy, alternative ) ->
    if possiblyFalsy == null || typeof(possiblyFalsy) == 'undefined'
      return alternative
    return possiblyFalsy

  _include = ( value, array ) ->
    $.inArray( value, array || [] ) != -1

  _addRule = (( styleTag ) ->
    styleTag.type = 'text/css'
    document.getElementsByTagName('head')[0].appendChild( styleTag )
    sheet = document.styleSheets[document.styleSheets.length - 1]

    return ( selector, css ) ->
      propText = $.map( (key for key of css),
                        ( p ) -> "#{p}:#{css[p]}" ).join(';')
      try
        if sheet.insertRule
          sheet.insertRule( "#{selector} { #{propText} }",
                            (sheet.cssRules || sheet.rules).length )
        else
          sheet.addRule( selector, propText )

      return
  )( document.createElement('style') )

)( jQuery )
