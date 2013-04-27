WIDTH = 16
HEIGHT = 12

UNIT = 48

initialMap = ->
  map = []
  for y in [1..HEIGHT]
    map.push ('ground' for x in [1..WIDTH])
  map

baseMapBus = new Bacon.Bus
baseMap = baseMapBus.toProperty initialMap()

mapMutator = new Bacon.Bus

mutateMap = (handler) ->
  mapMutator.push handler

Bacon.onValues baseMap, mapMutator, (oldMap, mutate) ->
  baseMapBus.push mutate(oldMap)

$ ->
  paper = Raphael(50, 50, WIDTH * UNIT, HEIGHT * UNIT)
  #rectangle = paper.rect(0, 0, WIDTH*UNIT, HEIGHT*UNIT)
  #rectangle.attr "fill", "#ffa500"
  for y in [0..(HEIGHT-1)]
    for x in [0..(WIDTH-1)]
      do (x, y) ->
        im = paper.image 'about:blank', UNIT*x, UNIT*y, UNIT, UNIT
        baseMap.map((tiles) -> tiles[y][x])
               .skipDuplicates()
               .map((tile) -> "img/tiles/#{tile}.png")
               .assign im, 'attr', 'src'

setTimeout (->
  mutateMap (map) ->
    map[2][2] = 'grass'
    map), 2000

