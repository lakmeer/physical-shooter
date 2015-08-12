
{ id, log, pi, tau, floor } = require \std
{ test } = require \test

#
# Blitter
#
# A drawing surface that can in turn draw itself to other drawing surfaces
#

export class Blitter

  { screen-size, board-size, scale-factor } = require \config

  (@size = screen-size, @bs = board-size, @scale = scale-factor) ->
    @canvas = document.create-element \canvas
    @ctx    = @canvas.get-context \2d

    @canvas.width  = @size.0
    @canvas.height = @size.1
    @canvas.style.display = \block
    @canvas.style.transform = "scale(#{@scale})"
    @canvas.style.transform-origin = "0% 0%"

    @offset = [0 0]

    @rotation = 0

    @ctx.font = "20px monospace"
    @ctx.text-align = \center

  clear: ->
    @ctx.fill-style = \white
    @ctx.stroke-style = \white
    @ctx.clear-rect 0, 0, @size.0, @size.1
    @rotation += 0.2

  set-color: (col) ->
    @ctx.fill-style = col

  set-line-color: (col) ->
    @ctx.stroke-style = col

  sprite: (img, pos, size, { offset = [0 0], rotation = 0 }={}) ->
    [ x, y ] = @game-space-to-screen-space pos
    [ w, h ] = @game-size-to-screen-size size
    [ u, v ] = @game-size-to-screen-size offset
    @ctx.save!
    @ctx.translate x - u + w/2, y - v + h/2
    @ctx.rotate rotation
    @ctx.draw-image img, -w/2, -h/2, w, h
    @ctx.restore!

  rect: (pos, size) ->
    [ x, y ] = @game-space-to-screen-space pos
    [ w, h ] = @game-size-to-screen-size size
    @ctx.fill-rect x, y, w, h

  stroke-rect: (pos, size) ->
    [ x1, y1 ] = @game-space-to-screen-space pos
    [  w, h  ] = @game-size-to-screen-size size
    [ x2, y2 ] = [ x1 + w, y1 + h ]
    @ctx.begin-path!
    @ctx.move-to x1 + 0.5, y1 + 0.5
    @ctx.line-to x2 - 0.5, y1 + 0.5
    @ctx.line-to x2 - 0.5, y2 - 0.5
    @ctx.line-to x1 + 0.5, y2 - 0.5
    @ctx.line-to x1 + 0.5, y1 + 0.5
    @ctx.close-path!
    @ctx.stroke!

  line: (x1, y1, x2, y2) ->
    [ x1, y1 ] = @game-space-to-screen-space [ x1, y1 ]
    [ x2, y2 ] = @game-space-to-screen-space [ x2, y2 ]
    @ctx.begin-path!
    @ctx.move-to x1 + 0.5, y1 + 0.5
    @ctx.line-to x2 + 0.5, y2 + 0.5
    @ctx.close-path!
    @ctx.stroke!

  circle: (pos, diam) ->
    [ x, y ] = @game-space-to-screen-space pos
    [ rad ] = @game-size-to-screen-size [ diam/2, 0 ]
    @ctx.begin-path!
    @ctx.arc x, y, rad, 0, tau
    @ctx.close-path!
    @ctx.fill!

  semi-circle: (pos, diam) ->
    [ x, y ] = @game-space-to-screen-space pos
    [ rad ] = @game-size-to-screen-size [ diam/2, 0 ]
    @ctx.begin-path!
    @ctx.arc x, y, rad, 0, pi
    @ctx.close-path!
    @ctx.fill!

  stroke-circle: (pos, diam) ->
    [ x, y ] = @game-space-to-screen-space pos
    [ rad ] = @game-size-to-screen-size [ diam/2, 0 ]
    @ctx.begin-path!
    @ctx.arc x, y, rad, 0, tau
    @ctx.close-path!
    @ctx.stroke!

  text: (pos, text, offset) ->
    [ x, y ] = @game-space-to-screen-space pos
    [ u, v ] = @game-size-to-screen-size offset
    @ctx.fill-text text, x - u, y - v

  show-grid: ->
    @set-line-color \grey
    @line 0, @bs.1, 0, -@bs.1
    @line @bs.0, 0, -@bs.0, 0

  alpha: ->
    @ctx.global-alpha = it

  install: (host) ->
    host.append-child @canvas

  game-size-to-screen-size: ([ w, h ]) ->
    [ w * 0.5 * @size.0/@bs.0, h * 0.5 * @size.1/@bs.1 ]

  screen-size-to-game-size: ([ w, h ]) ->
    [ w * 2 * @bs.0/@size.0 / @scale, h * 2 * @bs.1/@size.1 * @scale ]

  game-space-to-screen-space: ([ x, y ]) ->
    [ @size.0/2 + @size.0/2 * x/@bs.0 + @offset.0,
      @size.1/2 - @size.1/2 * y/@bs.1 + @offset.1 ]

  screen-space-to-game-space: ([ x, y ]) ->
    [ x * @bs.0 * 2/@size.0 / @scale - @bs.0, @bs.1 - y * @bs.1 * 2/@size.1 / @scale ]

  set-offset: ([ x, y ]) ->
    @offset.0 = x
    @offset.1 = y


#
# Tests
#

test "Blitter - Game space to screen space", ->
  blitter = new Blitter [ 100, 100 ], [ 100, 100 ], 1

  @equal-v2 'Origin is in the center'
    .expect blitter.game-space-to-screen-space [ 0, 0 ]
    .to-be  [ 50, 50 ]

  @equal-v2 'min X min Y is bottom left'
    .expect blitter.game-space-to-screen-space [ -100, -100 ]
    .to-be  [ 0, 100 ]

  @equal-v2 'min X max Y is top left'
    .expect blitter.game-space-to-screen-space [ -100, 100 ]
    .to-be  [ 0, 0 ]

  @equal-v2 'max X min Y is bottom right'
    .expect blitter.game-space-to-screen-space [ 100, -100 ]
    .to-be  [ 100, 100 ]

  @equal-v2 'max X max Y is top right'
    .expect blitter.game-space-to-screen-space [ 100, 100 ]
    .to-be  [ 100, 0 ]


test "Blitter - Screen space to game space", ->
  blitter = new Blitter [ 100, 100 ], [ 100, 100 ], 1

  @equal-v2 'Origin is in the center'
    .expect blitter.screen-space-to-game-space [ 50, 50 ]
    .to-be [ 0, 0 ]

  @equal-v2 'min X min Y is bottom left'
    .expect blitter.screen-space-to-game-space [ 0, 100 ]
    .to-be [ -100, -100 ]

  @equal-v2 'max X min Y is bottom right'
    .expect blitter.screen-space-to-game-space [ 100, 100 ]
    .to-be [ 100, -100 ]

  @equal-v2 'min X max Y is top left'
    .expect blitter.screen-space-to-game-space [ 0, 0 ]
    .to-be [ -100, 100 ]

  @equal-v2 'max X max Y is top right'
    .expect blitter.screen-space-to-game-space [ 100, 0 ]
    .to-be [ 100, 100 ]

