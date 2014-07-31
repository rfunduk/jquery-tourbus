$ = jQuery
utils = require './utils'

module.exports = class Leg
  constructor: ( @options ) ->
    @$original = @options.original
    @bus = @options.bus
    @rawData = @options.rawData
    @index = @options.index
    @$target = $(@options.target)
    @id = "#{@bus.id}-#{@options.index}"
    @elId = "tourbus-leg-#{@id}"
    @visible = false

    if @$target.length == 0
      throw "#{@$target.selector} is not an element!"

    @content = @$original.html()

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
      selector = "##{@elId}.tourbus-arrow"
      @bus._log "adding rule for #{@elId}", rule
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
    scrollTarget = utils.dataProp( @options.scrollTo, @$el )
    @bus._log 'scrolling to', scrollTarget, @scrollSettings
    $.scrollTo( scrollTarget, @scrollSettings )

  _setupOptions: ->
    globalOptions = @bus.options.leg

    dataProps = [
      'class', 'top', 'left', 'scrollTo', 'scrollSpeed',
      'scrollContext', 'margin', 'arrow', 'align', 'width',
      'zindex', 'orientation'
    ]
    for prop in dataProps
      @options[prop] = utils.dataProp( @rawData[prop], globalOptions[prop] )

  _configureElement: ->
    @$el = $("<div class='tourbus-leg'></div>")
    @el = @$el[0]
    @$el.attr id: @elId
    @$el.addClass @options.class
    @$el.css zIndex: @options.zindex

  _setupEvents: ->
    @$el.on 'click', '.tourbus-next', $.proxy( @bus.next, @bus )
    @$el.on 'click', '.tourbus-prev', $.proxy( @bus.prev, @bus )
    @$el.on 'click', '.tourbus-stop', $.proxy( @bus.stop, @bus )
  _teardownEvents: ->
    @$el.off 'click'

  _configureTarget: ->
    @targetOffset = @$target.offset()
    @targetOffset.top = @options.top if utils.dataProp( @options.top, false )
    @targetOffset.left = @options.left if utils.dataProp( @options.left, false )

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
        unless utils.dataProp( offsets.top, false )
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

    if utils.include( @options.orientation, validOrientations[@options.align] )
      switch @options.align
        # when 'left' then offsets.left += 0 # aligned left by default
        # when 'top' then offsets.top += 0 # aligned top by default
        when 'right' then offsets.left += @targetWidth - elWidth
        when 'bottom' then offsets.top += @targetHeight - elHeight

    else if @options.align == 'center'
      if utils.include( @options.orientation, validOrientations.left )
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

# internal convenience functions

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
