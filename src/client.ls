
#
# Require
#

{ id, log, tau, delay, random-range } = require \std

Palette = require \./player-palettes

{ FrameDriver } = require \./frame-driver

IO = require \socket.io-client

{ palette-sprite } = require \./sprite

colors = <[ red blue green magenta cyan yellow grey ]>

color-map = \/assets/ship-colormap.svg
lumin-map = \/assets/ship-luminosity.svg

ship-sprite = (palette) -> palette-sprite color-map, lumin-map, palette.paintjob, 512

sprites = { [ color, ship-sprite Palette[color] ] for color in colors }


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

LASER_ON   = 1
FORCE_ON   = 2
VORTEX_ON  = 3

LASER_OFF  = 4  # Not actually used
FORCE_OFF  = 5
VORTEX_OFF = 6

MODE_SELECT_PLAYER = 1
MODE_CAPTURE_INPUT = 2

# State
interface-mode = MODE_SELECT_PLAYER
$controls = document.get-element-by-id \controls
$selector = document.get-element-by-id \selector

# Functions
set-bg = -> document.body.style.background-color = it

is-in-steering-region = ({ pageX }) -> pageX > window.inner-width / 2

get-command = (is-release-event, { pageY }) ->
  h = window.inner-height
  command =
    if      pageY < h * 1/3 then LASER_ON
    else if pageY < h * 2/3 then FORCE_ON
    else                         VORTEX_ON
  return if is-release-event then command += 3 else command

submit-selection = (index) ->
  selected := yes
  my-index := index
  my-color := Palette[colors[index]].bullet-color!
  set-bg my-color
  server.emit \join, my-index
  interface-mode := MODE_CAPTURE_INPUT


render-options = (available-colors, λ) ->
  for let child, i in $selector.children
    θ = (0.5 + i/$selector.children.length) * -tau
    x = -12.5 + 30 * Math.sin θ
    y = -12.5 + 30 * Math.cos θ

    slot = available-colors.filter (.index is i)

    child.style.margin-left = x + \vh
    child.style.margin-top  = y + \vh
    child.append-child sprites[colors[i]]

    if slot.length
      child.add-event-listener \touchstart, -> λ? i
    else
      sprites[colors[i]].greyscale!


#
# Socket Callbacks
#

server.on \connect, ->

server.on \available, (players) ->
  frame-driver.start!

  render-options players, (index) ->

    submit-selection index

    document.add-event-listener 'touchstart', (event) ->
      for touch in event.touches
        if is-in-steering-region touch
          x := 2 * (touch.pageX / window.inner-width) - 1
          y := touch.pageY / window.inner-height
        else
          command := get-command no, touch
      event.prevent-default!
      return false

    document.add-event-listener 'touchend', (event) ->
      for touch in event.changed-touches
        if not is-in-steering-region touch
          command := get-command yes, touch
      event.prevent-default!
      return false

    document.add-event-listener 'touchmove', (event) ->
      for touch in event.touches
        if is-in-steering-region touch
          x := 2 * (touch.pageX / window.inner-width) - 1
          y := touch.pageY / window.inner-height
          event.prevent-default!
          return false


server.on \disconnect, ->
  frame-driver.stop!
  interface-mode = MODE_SELECT_PLAYER
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

frame-driver.on-frame ->
  switch interface-mode
  | MODE_SELECT_PLAYER =>
    $controls.style.display = \none
    $selector.style.display = \block
  | MODE_CAPTURE_INPUT
    $controls.style.display = \block
    $selector.style.display = \none
  | otherwise =>
    void # No such interface mode


#
# Init
#

# Debug - delay start so master can load first

delay (random-range 1000, 2000), -> server.emit \is-client

