initialGameState =
  location: 'first'
  x: 4
  y: 4
  stats:
    str: 0 # strength, used in rolls for hit damage
    dex: 0 # dexterity, used in rolls for will hit and dodge
    con: 0 # constitution, used in calculation of hp
    hea: 0 # healing magic, used in calculation of effectiveness
    des: 0 # destruction magic, used in calculation of effectiveness
    alt: 0 # alteration magic, used in calculation of effectiveness
  hp: 10
  creatures: [{type: "badger", state: "roam", x: 9, y: 9}]

# Maximum HP is calculated as:
#   9 + ceil(0.3 * 2.2 ^ level)

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
  creatures: stateProp.map((x) -> x.creatures)

