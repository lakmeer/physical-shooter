
#
# Require
#

{ id, log, delay, random-range } = require \std

Palette = require \./player-palettes

{ FrameDriver } = require \./frame-driver

IO = require \socket.io-client



#
# Setup
#

frame-driver    = new FrameDriver

selected = no
my-index = void
my-color = \black
x        = 0.5
y        = 0.9
command  = null


server = IO window.location.hostname + \:9999


#
# Interface
#

set-bg = -> document.body.style.background-color = it

is-in-steering-region = -> true



#
# Socket Callbacks
#

server.on \connect, ->
  log "I'm the client!"

server.on \available, (players) ->

  selected := yes
  my-index := players.0.index
  my-color := Palette[ players.0.color ].bullet-color!

  set-bg my-color

  server.emit \join, my-index
  frame-driver.start!

  $steering = document.get-element-by-id \steering

  $steering.add-event-listener \touchmove, (event) ->
    for touch in event.touches
      x := 2 * (touch.pageX / window.inner-width) - 1
      y := touch.pageY / window.inner-height
    event.prevent-default!
    return false

server.on \disconnect, ->
  frame-driver.stop!
  set-bg \black

#
# Frame Loop
#

frame-driver.on-tick ->
  if selected
    if command
      server.emit \p, x, y, command
      command := null
    else
      server.emit \p, x, y

#
# Init
#

# Debug - delay start so master can load first

delay (random-range 1000, 2000), -> server.emit \is-client

