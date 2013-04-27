postStats = (stats) ->
  $.ajax
    type: 'POST'
    url: 'stats.php'
    data: JSON.stringify(stats)
    contentType: "application/json"

GameState.stream.sampledBy(GameState.heroPos.changes().skipDuplicates())
                .onValue (state) ->
  postStats
    event: 'move'
    state: state

