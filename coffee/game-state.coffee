initialGameState =
  location: 'first'
  x: 4
  y: 4
  stats:
    str: 0
    dex: 0
    int: 0
    hea: 0
    des: 0
    alt: 0
  hp: 10
  mhp: 10

stateBus = new Bacon.Bus
stateProp = stateBus.toProperty initialGameState

stateModify = new Bacon.Bus

stateProp.sampledBy(stateModify, (a, b) -> [a, b])
         .onValues (prop, mod) ->
  # clone the property here
  # ew ew ew
  prop = JSON.parse(JSON.stringify(prop))
  stateBus.push (mod prop)

window.GameState =
  reset: -> stateBus.push initialGameState
  stream: stateProp
  mutate: (callback) -> stateModify.push callback
  location: stateProp.map((x) -> x.location)
  heroPos: stateProp.map((x) -> [x.x, x.y])

