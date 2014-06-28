$ = jQuery
Bus = require './modules/bus'
Leg = require './modules/leg'

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
    el.each -> built.push( new Bus( this, options ) )
    $.error( "#{el.selector} was not found!" ) if built.length == 0
    return built[0] if built.length == 1
    return built

  destroyAll: ->
    bus.destroy() for index, bus of Bus._busses

  expose: ( global ) ->
    global.tourbus = Bus: Bus, Leg: Leg

tourbus.defaults =
  debug: false
  autoDepart: false
  container: 'body'
  class: null
  startAt: 0
  onDepart: -> null
  onStop: -> null
  onLegStart: -> null
  onLegEnd: -> null
  leg:
    class: null
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
