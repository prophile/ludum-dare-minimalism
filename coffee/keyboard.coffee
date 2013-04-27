window.Keys = {}
window.Keys.Left = new Bacon.Bus
window.Keys.Right = new Bacon.Bus
window.Keys.Up = new Bacon.Bus
window.Keys.Down = new Bacon.Bus

$ ->
  keyEvents = $(document.body).asEventStream "keydown"

  Keys.Down.plug keyEvents.filter((x) -> x.keyCode is 40)
  Keys.Up.plug keyEvents.filter((x) -> x.keyCode is 38)
  Keys.Left.plug keyEvents.filter((x) -> x.keyCode is 37)
  Keys.Right.plug keyEvents.filter((x) -> x.keyCode is 39)

