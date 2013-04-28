initialGameState =
  location: 'first'
  x: 4
  y: 4
  stats:
    str: 0 # strength, used in rolls for hit damage, add half damage done
    dex: 0 # dexterity, used in rolls for will hit and dodge, add one for hit and three for dodge
    con: 0 # constitution, used in calculation of hp, add damage taken
    hea: 0 # healing magic, used in calculation of effectiveness
    des: 0 # destruction magic, used in calculation of effectiveness
    alt: 0 # alteration magic, used in calculation of effectiveness
  hp: 26
  creatures: []

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
  inCombat: stateProp.map((x) -> x.combatState?)

