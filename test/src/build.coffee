describe '$.tourbus build', ->
  afterEach -> $.tourbus('destroyAll')

  ctors = [
    { name: 'build', type: tourbus.Bus, fn: ( el, opts={} ) -> $.tourbus('build', el, opts) }
    { name: 'bare', type: tourbus.Bus, fn: ( el, opts={} ) -> $.tourbus(el, opts) }
    { name: '$.fn', type: window.$, fn: ( el, opts={} ) -> $(el).tourbus(opts) }
  ]

  describe 'with a valid element', ->
    validId = '#tourbus-test-1'

    ctors.forEach ( ctor ) ->
      describe "built with '#{ctor.name}'", ->
        it 'should not error', ->
          assert.doesNotThrow -> ctor.fn( validId )
          assert.doesNotThrow -> ctor.fn( $(validId) )

        it 'should not be null', ->
          assert.isNotNull ctor.fn( validId )

        it 'should return a Bus', ->
          assert.instanceOf ctor.fn( validId ), ctor.type

        it 'should override Bus defaults', ->
          defaultStartAt = $.tourbus.defaults.startAt
          tour = ctor.fn( validId, startAt: defaultStartAt+1 )
          tour = tour.data('tourbus') unless tour instanceof tourbus.Bus
          assert.notEqual tour.options.startAt, defaultStartAt

        it 'should override Leg defaults', ->
          defaultMargin = $.tourbus.defaults.leg.margin
          tour = ctor.fn( validId, leg: { margin: defaultMargin+1 } )
          tour = tour.data('tourbus') unless tour instanceof tourbus.Bus
          tour.depart() # so the legs get built
          assert.notEqual tour.legs[0].options.margin, defaultMargin

        it 'should depart', ->
          assert.doesNotThrow ->
            tour = ctor.fn( validId )
            tour = tour.data('tourbus') unless tour instanceof tourbus.Bus
            tour.depart()


  describe 'with multiple valid elements', ->
    validSelector = '.tour-test-multiple'

    ctors.forEach ( ctor ) ->
      return if ctor.name == '$.fn' # $(sel).each returns $(sel) again
      describe "built with #{ctor.name}", ->
        it 'should return a [Bus,...]', ->
          tours = ctor.fn( validSelector )
          assert.isArray tours
          tours.forEach ( bus ) ->
            assert.instanceOf bus, tourbus.Bus

        it 'should set the same options', ->
          defaultStartAt = $.tourbus.defaults.startAt
          tours = ctor.fn( validSelector, startAt: defaultStartAt+1 )
          tours.forEach ( bus ) ->
            assert.notEqual bus.options.startAt, defaultStartAt


  describe 'with an invalid element', ->
    invalidId = '#tourbus-test-0'

    ctors.forEach ( ctor ) ->
      return if ctor.name == '$.fn' # $(sel).each doesn't throw
      describe "built with #{ctor.name}", ->
        it 'should error', ->
          assert.throws ->
            ctor.fn( invalidId )
