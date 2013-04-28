WIDTH = 16
HEIGHT = 12

UNIT = 48

initialMap = ->
  map = []
  for y in [1..HEIGHT]
    map.push ('*' for x in [1..WIDTH])
  map

$ ->
  ReadFile('castle-text.txt').assign $('#castle-text'), 'text'
  ReadFile('castle-name.txt').assign $('#castle-name'), 'text'
  ReadFile('death-message.txt').assign $('#death-text'), 'text'
  $('#restart').click ->
    GameState.reset()
  GameState.stream
           .map((x) -> if x.combatState? then 'show' else 'hide')
           .skipDuplicates()
           .assign $('#combat'), 'modal'
  run = $('#cmbt-run').asEventStream 'click'
  GameState.inCombat
           .sampledBy(run)
           .filter((x) -> x)
           .onValue ->
    console.log "Leaving combat..."
    GameState.mutate (state) ->
      delete state.combatState
      state
  attack = $('#cmbt-attack').asEventStream 'click'
  GameState.inCombat
           .sampledBy(attack)
           .filter((x) -> x)
           .onValue ->
    GameState.mutate (state) ->
      soundEffects = []
      # Player attacks first
      crit = false
      hitCreature = CombatUpdate state.stats, state.combatState, ->
        crit = true
      if crit
        soundEffects.push 'crit'
      else
        soundEffects.push (if hitCreature > 0 then 'hit' else 'miss')
      state.combatState.hp -= hitCreature
      if state.combatState.hp <= 0
        state.milestones.push state.combatState.milestone if state.combatState.milestone?
        delete state.combatState
      # If creature is alive, it hits back
      else
        hitPlayer = CombatUpdate state.combatState, state.stats
        soundEffects.push 'hurt' if hitPlayer > 0
        state.hp -= hitPlayer
      delay = 0
      for effect in soundEffects
        do (effect) ->
          setTimeout(-> PlaySound effect, delay)
        delay += 150
      state
  damage = GameState.stream
                    .map((x) -> x.hp)
                    .skipDuplicates()
                    .slidingWindow(2)
                    .filter((x) -> x.length is 2)
                    .filter((x) -> x[1] < x[0])
  damage.onValue ->
    PlaySound 'hurt'
  damage.onValue (x) ->
    newHealth = x[1]
    if newHealth <= 0
      GameState.mutate (state) ->
        state.hp = 0
        delete state.combatState
        state
  dead = GameState.stream.map((x) -> x.hp)
                         .map((x) -> x <= 0)
  dead.map((x) -> if x then 'show' else 'hide')
      .assign $('#death'), 'modal'


  Bacon.onValues GameState.stream, CreatureDB, (state, creatures) ->
    return unless state.combatState?
    type = state.combatState.type
    entry = creatures[type]
    $('#combat-enemy').attr('src', "img/sprites/#{entry.sprite}.png")
    $('#combat-enemy-name').text(entry.name)
  combState = GameState.stream
                       .filter((x) -> x.combatState?)
                       .map((x) -> x.combatState)
  combState.map((x) -> x.hp)
           .assign $('.enemy-hp'), 'text'
  combState.map((x) -> x.con)
           .map(XPToLevel)
           .map((x) -> MaxHP(x, false))
           .assign $('.enemy-mhp'), 'text'
  stats = GameState.stream.map((x) -> x.stats)
  hp = GameState.stream.map((x) -> x.hp)
  stats.map((x) -> x.con)
       .map(XPToLevel)
       .map((x) -> MaxHP(x, true))
       .assign $('.player-mhp'), 'text'
  hp.assign $('.player-hp'), 'text'

GameState.stream
         .map((x) -> x.combatState?)
         .skipDuplicates()
         .filter((x) -> x)
         .onValue ->
  PlaySound 'combat'

window.Step = GameState.heroPos
                       .slidingWindow(2)
                       .filter((x) -> x.length is 2)
                       .filter((x) -> x[0][0] isnt x[1][0] or
                                      x[0][1] isnt x[1][1])

window.ChangeMap = GameState.location.changes().skipDuplicates().debounce(5)

Step.onValue ->
  PlaySound 'step'

entitySource = Bacon.combineTemplate
  heroPosition: GameState.heroPos
  creatures: GameState.creatures
  creatureDB: CreatureDB

entities = entitySource.map (data) ->
  elements = []
  elements.push
    sprite: 'hero'
    x: data.heroPosition[0]
    y: data.heroPosition[1]
  for creature in data.creatures
    elements.push
      sprite: data.creatureDB[creature.type].sprite
      x: creature.x
      y: creature.y
  elements

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

# Do mappy things
baseMapMetadata.toProperty().sampledBy(ChangeMap).onValue (meta) ->
  _.delay ->
    GameState.mutate (state) ->
      console.log "Map load"
      state.creatures = []
      if meta.parked?
        for park in meta.parked
          continue if park.milestone? and park.milestone in state.milestones
          creature =
            type: park.type
            state: "parked"
            x: park.x
            y: park.y
          creature.milestone = park.milestone if park.milestone?
          state.creatures.push creature
      state

# Creature updates and encounters on step
Bacon.combineAsArray(GameState.heroPos, CreatureDB, baseMapSource, baseMapMetadata)
     .sampledBy(Step)
     .onValues (hero, cdb, map, meta) ->
  GameState.mutate (state) ->
    # Create the PF map
    hasRoamer = false
    grid = new PF.Grid WIDTH, HEIGHT
    # Populate the walkability information
    for y in [0..(HEIGHT-1)]
      for x in [0..(WIDTH-1)]
        tile = map[y][x]
        walkable = (tile is ' ' or tile in (meta.aiPath ? ""))
        grid.setWalkableAt(x, y, walkable)
    # Fill in any parked creatures in the walkability grid
    for creature in state.creatures
      if creature.state is "parked"
        grid.setWalkableAt(creature.x, creature.y, false)
      else
        hasRoamer = true
    finder = new PF.BiAStarFinder
      allowDiagonal: true
      heuristic: PF.Heuristic.manhattan
    # Stage 1: creature movement
    state.creatures = _.flatten (for creature in state.creatures
      moveDir = [0, 0]
      switch creature.state
        when "roam"
          moveDir = [[-1, 0], [1, 0], [0, -1], [0, 1]][Math.floor(Math.random()*4)]
        when "enraged"
          liveGrid = grid.clone()
          path = finder.findPath(creature.x, creature.y, hero[0], hero[1], liveGrid)
          if not path? or path.length <= 1
            creature.state = "roam" # return to roaming
          else
            firstStep = path[1]
            moveDir = [firstStep[0] - creature.x, firstStep[1] - creature.y]
      newPos = [creature.x + moveDir[0], creature.y + moveDir[1]]
      walkable = grid.isWalkableAt(newPos[0], newPos[1])
      if walkable
        creature.x = newPos[0]
        creature.y = newPos[1]
    # Stage 2: creature enragement
      if creature.state is "roam"
        creature.state = "enraged" if Distance(creature.x, creature.y, hero[0], hero[1])<=5
    # Stage 3: creature engagement
      engageDistance = if creature.state is "parked" then 1 else 1
      if Distance(creature.x, creature.y, hero[0], hero[1]) <= engageDistance
        {con, str, dex} = cdb[creature.type].stats
        state.combatState =
          hp: MaxHP(XPToLevel(con), false)
          con: con
          dex: dex
          str: str
          type: creature.type
        state.combatState.milestone = creature.milestone if creature.milestone?
        []
      else
        [creature])
    # Stage 4: creature creation (possibly)
    if not hasRoamer and meta.fauna?
      if Math.random() < 0.1
        # create a roamer
        type = meta.fauna[Math.floor(Math.random() * meta.fauna.length)]
        location = null
        for i in [1..10]
          possLocation = [Math.floor(Math.random() * WIDTH),
                          Math.floor(Math.random() * HEIGHT)]
          # condition 1: walkable
          continue unless grid.isWalkableAt(possLocation[0], possLocation[1])
          # condition 2: not too close
          continue unless Distance(possLocation[0], possLocation[1],
                                   hero[0], hero[1]) > 4
          location = possLocation
        if location?
          state.creatures.push
            type: "badger"
            state: "roam"
            x: location[0]
            y: location[1]
    state

handleService = (options) ->
  switch options.service
    when "castle"
      PlaySound 'fanfare'
      $('#castle').modal 'show'
      # things
    when "heal"
      PlaySound 'heal'
      GameState.mutate (state) ->
        state.hp = MaxHP(XPToLevel(state.stats.con), true)
        state
    when "sign"
      $('#sign-text').text options.message
      $('#sign').modal 'show'

setMap = (map) ->
  GameState.mutate (state) ->
    state.location = map
    state

plugKey = (stream, oX, oY) ->
  sources = Bacon.combineTemplate
    oldPos: GameState.heroPos
    map: baseMap
    md: baseMapMetadata
    comb: GameState.inCombat
  newPosition = sources.sampledBy(stream).map (params) ->
    {oldPos, map, md, comb} = params
    return oldPos if comb
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

