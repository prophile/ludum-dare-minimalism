WIDTH = 16
HEIGHT = 12

UNIT = 48

initialMap = ->
  map = []
  for y in [1..HEIGHT]
    map.push ('*' for x in [1..WIDTH])
  map

setEntities = new Bacon.Bus
entities = setEntities.toProperty []

setTimeout((->
  setEntities.push [{sprite: 'hero', x: 4, y: 4}]
), 2800)

setCurrentMap = new Bacon.Bus
currentMap = setCurrentMap.toProperty "first"

tiles =
  '*': 'stone'
  ' ': 'ground'

baseMapData = currentMap.flatMapLatest (x) ->
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

$ ->
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

