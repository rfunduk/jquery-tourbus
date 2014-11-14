$ = jQuery
Leg = require './leg'
utils = require './utils'

module.exports = class Bus
  @_busses: {}
  @_tours: 0
  @uniqueId: -> return @_tours++
  constructor: ( el, @options ) ->
    @id = @constructor.uniqueId()
    @elId = "tourbus-#{@id}"
    @constructor._busses[@id] = @
    @$original = $(el)
    @rawData = @$original.data()
    @$container = $(utils.dataProp( @rawData.container, @options.container ))
    @$original.data( tourbus: @ )

    @currentLegIndex = null
    @legs = []
    @legEls = @$original.children('li')
    @totalLegs = @legEls.length

    @_configureElement()
    @_setupEvents()

    if utils.dataProp( @rawData.autoDepart, @options.autoDepart )
      @$original.trigger('depart.tourbus')

    @_log 'built tourbus with el', el.toString(), 'and options', @options

  # start and end the entire tour, resetting to the beginning
  depart: ->
    @running = true
    @options.onDepart( @ )
    @_log 'departing', @
    @currentLegIndex = utils.dataProp( @rawData.startAt, @options.startAt )
    @showLeg()
  stop: ->
    return unless @running
    $.each @legs, $.proxy(@hideLeg, @)
    @currentLegIndex = null
    @options.onStop( @ )
    @running = false

  on: ( event, selector, fn ) ->
    @$container.on event, selector, fn

  currentLeg: ->
    return null if @currentLegIndex == null
    @legs[@currentLegIndex]

  buildLeg: ( i ) ->
    $legEl = $(@legEls[i])
    data = $legEl.data()

    @legs[i] = leg = new Leg
      bus: @
      original: $legEl,
      target: data.el || 'body'
      index: i
      rawData: data

    leg.render()
    @$el.append leg.$el
    leg._position()
    leg.hide()
    leg

  # show/hide the current leg
  # hide cleans up the dom
  showLeg: ( index ) ->
    index ?= @currentLegIndex
    leg = @legs[index] || @buildLeg( index )
    @_log 'showLeg:', leg
    preventDefault = @options.onLegStart( leg, @ )
    leg.show() if preventDefault != false

    # ensure the next leg is available
    @buildLeg( index ) if ++index < @totalLegs && !@legs[index]

  hideLeg: ( index ) ->
    index ?= @currentLegIndex
    leg = @legs[index]
    if leg && leg.visible
      @_log 'hideLeg:', leg
      preventDefault = @options.onLegEnd( leg, @ )
      leg.hide() if preventDefault != false

    # ensure the previous leg is available
    @buildLeg( index ) if --index > 0 && !@legs[index]

  # refresh on-screen positions of all legs (can be used after window resize)
  repositionLegs: -> $.each @legs, -> @reposition()

  # convenience to proceed to next/previous leg or end tour
  # when we're out of legs
  next: ->
    @hideLeg()
    @currentLegIndex++
    if @currentLegIndex > @totalLegs - 1
      @$original.trigger('stop.tourbus')
    else
      @showLeg()

  prev: ( cb ) ->
    @hideLeg()
    @currentLegIndex--
    if @currentLegIndex < 0
      @$original.trigger('stop.tourbus')
    else
      @showLeg()

  destroy: ->
    $.each @legs, -> @destroy()
    @legs = []
    delete @constructor._busses[@id]
    @_teardownEvents()
    @$original.removeData('tourbus')
    @$el.remove()

  _configureElement: ->
    @$el = $("<div class='tourbus-container'></div>")
    @el = @$el[0]
    @$el.attr id: @elId
    @$el.addClass utils.dataProp( @rawData.class, @options.class )
    @$container.append @$el

  _log: ->
    return unless utils.dataProp( @rawData.debug, @options.debug )
    console.log "TOURBUS #{@id}:", arguments...

  # provide even handling for external start/stop/next/prev
  _setupEvents: ->
    @$original.on 'depart.tourbus', $.proxy( @depart, @ )
    @$original.on 'stop.tourbus', $.proxy( @stop, @ )
    @$original.on 'next.tourbus', $.proxy( @next, @ )
    @$original.on 'prev.tourbus', $.proxy( @prev, @ )
  _teardownEvents: ->
    @$original.off '.tourbus'
