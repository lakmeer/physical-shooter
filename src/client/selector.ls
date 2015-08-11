
# Require

{ id, log, tau } = require \std

{ palette-sprite } = require \../sprite

Palette  = require \../player-palettes


#
# Selector
#

export class Selector

  color-map = \/assets/ship-colormap.svg
  lumin-map = \/assets/ship-luminosity.svg
  colors    = <[ red blue green magenta cyan yellow grey ]>

  ship-sprite = (palette) ->
    palette-sprite color-map, lumin-map, palette.paintjob, 512

  (@dom) ->
    @available-colors = []

    @ships = colors.map (color, index) ->
      index: index
      color: color
      sprite: ship-sprite Palette[color]
      greyed: ship-sprite Palette.grey
      palette: Palette[color]
      available: no

    @state =
      selection: null
      phase: 0

    # Prepare DOM
    for let child, i in @dom.children
      child.append-child @ships[i].sprite
      child.append-child @ships[i].greyed
      child.add-event-listener \touchstart, @save-selection i

  hide: -> @dom.style.display = \none
  show: -> @dom.style.display = \block

  save-selection: (index) -> ~>
    selection = @ships[index]
    if selection.available
      @state.selection = index

  get-selection: ->
    if @state.selection? then @ships[that] else false

  set-available-colors: (options) ->
    for let child, i in @dom.children
      slot = options.filter (.index is i)
      available = slot.length > 0
      @ships[i].available = available
      if available
        @ships[i].sprite.style.display = \block
        @ships[i].greyed.style.display = \none
      else
        @ships[i].sprite.style.display = \none
        @ships[i].greyed.style.display = \block

  update: (Δt) ->
    @state.phase += Δt / 3

    for let child, i in @dom.children
      θ = @state.phase + (0.5 + i/@dom.children.length) * -tau
      x = -12.5 + 30 * Math.sin θ
      y = -12.5 + 30 * Math.cos θ
      child.style.margin-left = x + \vh
      child.style.margin-top  = y + \vh

  disconnected: ->
    # TODO: something when the client is disconnected

