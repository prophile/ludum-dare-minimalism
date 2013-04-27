postStats = (stats) ->
  $.ajax
    type: 'POST'
    url: 'stats.php'
    data: JSON.stringify(stats)
    contentType: "application/json"

Bacon.onValues Map.Hero, Map.Map, (hero, map) ->
  postStats
    event: 'move'
    x: hero[0]
    y: hero[1]
    map: map

