describe 'Bus callbacks', ->
  validId = '#tourbus-test-1'
  afterEach -> $.tourbus('destroyAll')

  describe 'with callbacks', ->
    beforeEach ->
      @onDepart = false
      @onStop = false
      @onLegStart = 0
      @onLegEnd = 0

      @tour = $.tourbus(
        validId,
        onDepart: => @onDepart = true
        onStop: => @onStop = true
        onLegStart: => @onLegStart++
        onLegEnd: => @onLegEnd++
      )

    it 'should trigger onDepart', ->
      @tour.depart()
      assert.ok @onDepart

    it 'should trigger onStop', ->
      @tour.depart()
      @tour.stop()
      assert.ok @onStop

    it 'should trigger onLegStart', ->
      @tour.depart()
      assert.equal @onLegStart, 1
      @tour.next()
      assert.equal @onLegStart, 2

    it 'should trigger onLegEnd', ->
      @tour.depart()
      assert.equal @onLegEnd, 0
      @tour.next()
      assert.equal @onLegEnd, 1, "#{@tour.elId} had too many leg ends"
