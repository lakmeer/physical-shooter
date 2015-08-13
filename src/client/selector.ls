
# Require

{ id, log, tau } = require \std

{ sprite, palette-sprite } = require \../sprite

Palette  = require \../player-palettes


#
# Selector
#

export class Selector

  color-map = \/assets/ship-colormap.svg
  lumin-map = \/assets/ship-luminosity.svg
  colors    = <[ red blue green magenta cyan yellow grey ]>

  #ship-sprite = (palette) -> palette-sprite color-map, lumin-map, palette.paintjob, 512

  ship-sprite = (palette) -> sprite palette.selector-image, 512


  (@dom) ->
    @available-colors = []

    @ships = colors.map (color, index) ->
      index: index
      color: color
      sprite: ship-sprite Palette[color]
      #greyed: ship-sprite Palette.grey
      palette: Palette[color]
      free: no

    @state =
      selection: null
      phase: 0

  show: ->
    @prepare!
    @dom.style.display = \block

  hide: ->
    @dom.style.display = \none

  save-selection: (index) -> ~>
    selection = @ships[index]
    if selection.free
      @state.selection = index

  prepare: ->
    for let child, i in @dom.children
      child.append-child @ships[i].sprite
      #child.append-child @ships[i].greyed
      child.add-event-listener \touchstart, @save-selection i

  get-selection: ->
    if @state.selection? then @ships[that] else false

  set-available-colors: (options) ->
    log options
    for option in options
      @ships[option.index].free = option.free

  update: (Δt) ->
    @state.phase += Δt / 3

    for let child, i in @dom.children
      @set-availability-state child, @ships[i]
      θ = @state.phase + (0.5 + i/@dom.children.length) * -tau
      x = -12.5 + 30 * Math.sin θ
      y = -12.5 + 30 * Math.cos θ
      child.style.margin-left = x + \vh
      child.style.margin-top  = y + \vh

  set-availability-state: (child, ship) ->
    if ship.free
      #ship.sprite.style.display = \block
      #ship.greyed.style.display = \none
      ship.sprite.style.opacity = 1.0
    else
      #ship.sprite.style.display = \none
      #ship.greyed.style.display = \block
      #ship.greyed.style.opacity = 0.3
      ship.sprite.style.opacity = 0.3

  disconnected: ->
    # TODO: something when the client is disconnected

