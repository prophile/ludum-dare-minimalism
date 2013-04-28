window.XPToLevel = (xp) ->
  Math.floor(2.708 * Math.log(0.606*(xp + 22))) - 6

window.MaxHP = (level) ->
  Math.floor(2.5 * (0.5*level*level + 0.9*level + 9))

window.Roll =
  die: (dieMax) ->
    Math.floor(1 + dieMax*Math.random())
  single: (dies, dieMax, critAction, baseLevel) ->
    crit = 0
    for i in [1..dies]
      roll = Roll.die(dieMax)
      if roll is dieMax
        crit += 1
      baseLevel += roll
    for i in [1..crit]
      baseLevel = critAction(baseLevel)
    baseLevel
  versus: (proposition, opposition) ->
    proRoll = Roll.die proposition
    if proRoll is proposition
      return true # critical hit
    oppRoll = Roll.die opposition
    if oppRoll is opposition
      return false # critical dodge
    return proRoll > oppRole

window.CombatUpdate = (attackerStats, defenderStats, didCrit = ->) ->
  # Roll versus for hit
  didHit = Roll.versus(XPToLevel(attackerStats.dex),
                       XPToLevel(defenderStats.dex))
  if didHit
    # increment attacker dex
    attackerStats.dex += 1
  else
    # increment defender dex
    defenderStats.dex += 1
  return 0 unless didHit
  # Roll for hit damage
  crit = (damage) ->
    do didCrit
    damage * 2
  hitDamage = Roll.single(1, 4, crit, XPToLevel(attackerStats.str))
  # Increment attacker strength stats by half hit damage
  attackerStats.str += Math.floor(hitDamage * 0.5)
  # Increment defender con stats by damage taken
  defenderStats.con += hitDamage
  return hitDamage

window.Distance = (x1, y1, x2, y2) ->
  Math.abs(x1 - x2) + Math.abs(y1 - y2)

window.CreatureDB = ReadFile("creatures.json").map(JSON.parse)

$ ->
  #alert "Hello, world!"

