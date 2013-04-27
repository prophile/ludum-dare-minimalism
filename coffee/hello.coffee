window.XPToLevel = (xp) ->
  Math.floor(2.708 * Math.log(0.606*(xp + 22))) - 6

$ ->
  #alert "Hello, world!"

