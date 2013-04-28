window.XPToLevel = (xp) ->
  Math.floor(2.708 * Math.log(0.606*(xp + 22))) - 6

window.MaxHP = (level) ->
  Math.floor(0.5*level*level + 0.9*level + 9)

window.Roll =
  die: (dieMax) ->
    Math.floor(1 + dieMax*Math.random())
  single: (dies, dieMax, critFactor, baseLevel) ->
    crit = 0
    for i in [1..dies]
      roll = die(dieMax)
      if roll is dieMax
        crit += 1
      baseLevel += roll
    baseLevel * Math.pow(critFactor, crit)
  versus: (proposition, opposition) ->
    proRoll = die proposition
    if proRoll is proposition
      return true # critical hit
    oppRoll = die opposition
    if oppRoll is opposition
      return false # critical dodge
    return proRoll > oppRole

window.Distance = (x1, y1, x2, y2) ->
  Math.abs(x1 - x2) + Math.abs(y1 - y2)

window.CreatureDB = ReadFile("creatures.json").map(JSON.parse)

$ ->
  #alert "Hello, world!"

