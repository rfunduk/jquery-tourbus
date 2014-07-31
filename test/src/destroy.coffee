describe 'Bus#destroy', ->
  beforeEach ->
    @bus = $.tourbus '#tourbus-test-1'
    @bus.depart()

  describe 'when destroyed', ->
    beforeEach ->
      @totalLegs = @bus.totalLegs
      @busId = @bus.id
      @bus.destroy()

    it 'should not have any legs', ->
      assert.lengthOf @bus.legs, 0

    it 'should not leave elements in the DOM', ->
      # bus and legs are destroyed, so build ids by hand here
      assert.lengthOf $("#tourbus-#{@busId}"), 0, "Bus container still in DOM!"
      for index in Array(@totalLegs)
        assert.lengthOf $("#tourbus-leg-#{@busId}-#{index}"), 0, "#{@busId}/#{index} still in DOM!"

    it 'should cleanup event handlers', ->
      called = false
      @bus.options.onDepart -> called = true
      assert.throws -> @bus.depart()
      assert !called

    it 'should cleanup data', ->
      # weirdly, can't use assert.equal here because
      # of a phantomjs serialization error
      assert !@bus.$original.data('tourbus')

    describe 'reinitialization', ->
      it 'should not error', ->
        assert.doesNotThrow =>
          @reinit = $.tourbus '#tourbus-test-1'
          @reinit.depart()
        assert.lengthOf $("#tourbus-#{@reinit.id}"), 1
