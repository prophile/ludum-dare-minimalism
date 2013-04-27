fileBus = new Bacon.Bus

files = fileBus.toProperty {}

receiveFile = new Bacon.Bus

# map updates
files.sampledBy(receiveFile.map(JSON.parse), (a, b) -> [a, b])
     .onValues (oldMap, newItem) ->
        oldMap[newItem.item] = newItem.contents
        fileBus.push oldMap

# set up event source
$ ->
  source = new EventSource 'levels.php'
  source.onopen = ->
    console.log "Connection opened"
  source.onerror = ->
    console.log "Connection error"
  source.addEventListener 'file', (event) ->
    receiveFile.push event.data

window.ReadFile = (name) ->
  files.map((x) -> x[name])
       .filter((x) -> x?)

