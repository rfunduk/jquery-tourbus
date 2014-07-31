describe 'Bus core', ->
  validId = '#tourbus-test-1'
  afterEach -> $.tourbus('destroyAll')

  describe 'autoDepart', ->
    describe 'true', ->
      beforeEach -> @tour = $.tourbus( validId, autoDepart: true )

      it 'should be running', ->
        assert.ok @tour.running
      it 'should build the first 2 legs', ->
        assert.lengthOf @tour.legs, 2 # first leg + preload second
      it 'should show the first leg', ->
        assert.equal @tour.currentLegIndex, 0
        assert.equal @tour.legs[0].$el.css('visibility'), 'visible'

    describe 'false', ->
      before -> @tour = $.tourbus( validId, autoDepart: false )

      it 'should not be running', ->
        assert.ok !@tour.running
      it 'should not build legs', ->
        assert.lengthOf @tour.legs, 0

  describe 'departing', ->
    testNewTour = ->
      it 'should create a container', ->
        assert.lengthOf $(".tourbus-container##{@tour.elId}"), 1

      it 'should show the first leg', ->
        assert.equal @tour.currentLegIndex, @tour.options.startAt
        assert.equal @tour.legs[0].$el.css('visibility'), 'visible'

      it 'should trigger onDepart callback', ->
        assert.ok @onDepart

    describe 'fresh', ->
      beforeEach ->
        @tour = $.tourbus( validId, onDepart: => @onDepart = true )
        @tour.depart()
      testNewTour()

    describe 'reinitialization', ->
      beforeEach ->
        $.tourbus( validId, autoDepart: true ).destroy()
        @tour = $.tourbus( validId, onDepart: => @onDepart = true )
        @tour.depart()
      testNewTour()

  describe 'stopping', ->
    beforeEach ->
      @tour = $.tourbus( validId )
      @tour.depart()
      @currentLegIndex = @tour.currentLegIndex
      @tour.stop()

    it 'should reset the current leg', ->
      assert.equal @tour.currentLegIndex, null

    it 'should hide the current leg', ->
      assert.equal @tour.legs[@currentLegIndex].$el.css('visibility'), 'hidden'

    it 'should start again', ->
      @tour.depart()
      assert.equal @tour.legs[@currentLegIndex].$el.css('visibility'), 'visible'

  describe 'navigating', ->
    beforeEach ->
      @el = $(validId).tourbus()
      @bus = @el.data('tourbus')
      @bus.depart()

    describe 'next', ->
      nextFuncs = [
        { name: '$#trigger', fn: -> @el.trigger('next.tourbus') }
        { name: 'Bus#next', fn: -> @bus.next() }
        { name: '.tourbus-next#click', fn: -> @bus.legs[0].$el.find('.tourbus-next').trigger('click') }
      ]

      nextFuncs.forEach ( next ) ->
        describe "triggered via #{next.name}", ->
          it 'should navigate to next leg', ->
            next.fn.call( this )
            assert.equal @bus.legs[0].$el.css('visibility'), 'hidden'
            assert.equal @bus.legs[1].$el.css('visibility'), 'visible'

    describe 'prev', ->
      beforeEach -> @bus.next()

      prevFuncs = [
        { name: '$#trigger', fn: -> @el.trigger('prev.tourbus') }
        { name: 'Bus#prev', fn: -> @bus.prev() }
        { name: '.tourbus-prev#click', fn: -> @bus.legs[1].$el.find('.tourbus-prev').trigger('click') }
      ]

      prevFuncs.forEach ( prev ) ->
        describe "triggered via #{prev.name}", ->
          it 'should navigate to previous leg', ->
            prev.fn.call( this )
            assert.equal @bus.legs[0].$el.css('visibility'), 'visible'
            assert.equal @bus.legs[1].$el.css('visibility'), 'hidden'
