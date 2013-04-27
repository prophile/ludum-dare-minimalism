elements = {}

window.PlaySound = (sound) ->
  if elements[sound]?
    do elements[sound].play

$ ->
  console.log "Loading SM"
  soundManager.setup
    url: 'sm2/'
    preferFlash: false
    onready: ->
      console.log "SM ready, loading data"
      ReadFile('sounds.json').onValue (sounds) ->
        console.log "Loaded sound database"
        soundDB = JSON.parse sounds
        for element of elements
          elements[element].unload()
        for sound of soundDB
          do (sound) ->
            console.log "Loading sound '#{sound}'..."
            elements[sound] = soundManager.createSound
              id: sound
              url: "sound/#{soundDB[sound]}"
              onload: ->
                console.log "Loaded sound '#{sound}'"

