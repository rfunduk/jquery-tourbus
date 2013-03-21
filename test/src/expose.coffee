describe '$.tourbus expose', ->
  afterEach -> $.tourbus('destroyAll')

  before ->
    @obj = {}
    $.tourbus( 'expose', @obj )

  it 'should define global', ->
    assert.deepProperty @obj, 'tourbus.Bus'
    assert.deepProperty @obj, 'tourbus.Leg'
