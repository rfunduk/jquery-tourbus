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
