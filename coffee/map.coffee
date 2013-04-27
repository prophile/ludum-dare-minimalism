WIDTH = 16
HEIGHT = 12

UNIT = 48

initialMap = ->
  map = []
  for y in [1..HEIGHT]
    map.push ('*' for x in [1..WIDTH])
  map

GameState.heroPos.slidingWindow(2)
                 .filter((x) -> x.length is 2)
                 .filter((x) -> x[0][0] isnt x[1][0] or
                                x[0][1] isnt x[1][1])
                 .onValue (x) -> PlaySound 'step'

entitySource = Bacon.combineTemplate
  heroPosition: GameState.heroPos

entities = entitySource.map (data) ->
  elements = []
  elements.push
    sprite: 'hero'
    x: data.heroPosition[0]
    y: data.heroPosition[1]
  elements

entities.onValue (x) ->
  console.log "ents"
  console.log x

tiles =
  '*': 'stone'
  ' ': 'ground'

tileEvents =
  '*':
    type: 'block'
  ' ':
    type: 'walk'

baseMapData = GameState.location.flatMapLatest (x) ->
  ReadFile "#{x}.level"
baseMapSource = baseMapData.map (data) ->
  lines = data.split /\n/
  for line in [0..(HEIGHT-1)]
    x for x in lines[line]

baseMapMetadata = baseMapData.map (data) ->
  lines = data.split /\n/
  elements = (line.split /\s*=\s*/ for line in lines[HEIGHT..])
  _.object ([item[0], JSON.parse(item[1])] for item in elements when item.length is 2)

baseMap = baseMapSource.toProperty initialMap()

handleService = (options) ->
  switch options.service
    when "castle"
      PlaySound 'fanfare'
      $('#castle').modal 'show'
      # things

setMap = (map) ->
  GameState.mutate (state) ->
    state.location = map
    state

plugKey = (stream, oX, oY) ->
  sources = Bacon.combineTemplate
    oldPos: GameState.heroPos
    map: baseMap
    md: baseMapMetadata
  newPosition = sources.sampledBy(stream).map (params) ->
    {oldPos, map, md} = params
    newPos = [oldPos[0] + oX, oldPos[1] + oY]
    tile = map[newPos[1]][newPos[0]]
    if md[tile]?
      event = md[tile][1]
    else
      event = tileEvents[tile]
    switch event.type
      when "walk"
        newPos
      when "block"
        oldPos
      when "border_y"
        setMap event.dest
        [newPos[0], (HEIGHT - 1) - newPos[1]]
      when "border_x"
        setMap event.dest
        [(WIDTH - 1) - newPos[0], newPos[1]]
      when "gateway"
        setMap event.dest
        event.pos
      when "service"
        handleService event
        oldPos
    # work out the event
  newPosition.onValues (x, y) ->
    GameState.mutate (state) ->
      state.x = x
      state.y = y
      state

$ ->
  plugKey Keys.Left, -1, 0
  plugKey Keys.Up, 0, -1
  plugKey Keys.Down, 0, 1
  plugKey Keys.Right, 1, 0
  paper = Raphael(50, 50, WIDTH * UNIT, HEIGHT * UNIT)
  for y in [0..(HEIGHT-1)]
    for x in [0..(WIDTH-1)]
      do (x, y) ->
        im = paper.image 'about:blank', UNIT*x, UNIT*y, UNIT, UNIT
        component = baseMap.map((tiles) -> tiles[y][x])
        tileSelection = Bacon.combineAsArray(component, baseMapMetadata)
                             .map (elements) ->
                                [tile, md] = elements
                                if md[tile]?
                                  md[tile][0]
                                else
                                  tiles[tile]
        tileSelection.skipDuplicates()
                     .map((tile) -> "img/tiles/#{tile}.png")
                     .assign im, 'attr', 'src'
  entitySprites = []
  entities.onValue (ents) ->
    sprite.remove() for sprite in entitySprites
    for entity in ents
      newEnt = paper.image("img/sprites/#{entity.sprite}.png",
                           entity.x*UNIT, entity.y*UNIT, UNIT, UNIT)
      entitySprites.push newEnt

