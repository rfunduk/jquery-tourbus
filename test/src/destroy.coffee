describe 'Bus#destroy', ->
  beforeEach ->
    @tour = $.tourbus '#tourbus-test-1'
    @tour.depart()

  describe 'when destroyed', ->
    beforeEach ->
      @totalLegs = @tour.totalLegs
      @id = @tour.id
      @tour.destroy()

    it 'should not have any legs', ->
      assert.isNull @tour.legs
    it 'should not leave elements in the DOM', ->
      for index in Array(@totalLegs)
        legId = "#tourbus-leg-id-#{@id}-#{index}"
        assert.lengthOf $("#tourbus-leg-id-#{@id}-#{index}"), 0, "#{legId} still in DOM!"
