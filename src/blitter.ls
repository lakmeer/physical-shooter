
{ id, log, floor } = require \std
{ test } = require \test


#
# Blitter
#
# A drawing surface that can in turn draw itself to other drawing surfaces
#

export class Blitter

  { screen-size, board-size } = require \config

  bs = board-size

  (@size = [ screen-size, screen-size ]) ->
    @canvas = document.create-element \canvas
    @ctx    = @canvas.get-context \2d

    @canvas.width  = @size.0
    @canvas.height = @size.1

  clear: ->
    @ctx.fill-style = \white
    @ctx.stroke-style = \white
    @ctx.clear-rect 0, 0, @size.0, @size.1

  set-color: (col) ->
    @ctx.fill-style = col

  set-line-color: (col) ->
    @ctx.stroke-style = col

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

  show-grid: ->
    @set-line-color \grey
    @line 0, 100, 0, -100
    @line 100, 0, -100, 0

  install: (host) ->
    host.append-child @canvas

  game-size-to-screen-size: ([ w, h ]) ->
    [ w * 0.5 * @size.0/bs, h * 0.5 * @size.1/bs ]

  screen-size-to-game-size: ([ w, h ]) ->
    [ w * 2 * bs/@size.0, h * 2 * bs/@size.1 ]

  game-space-to-screen-space: ([ x, y ]) ->
    [ @size.0/2 + @size.0/2 * x/bs, @size.1/2 - @size.1/2 * y/bs ]

  screen-space-to-game-space: ([ x, y ]) ->
    [ x * bs * 2/@size.0 - bs, bs - y * bs * 2/@size.1 ]

#
# Tests
#

test "Blitter - Game space to screen space", ->
  blitter = new Blitter [ 100, 100 ]

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
  blitter = new Blitter [ 100, 100 ]

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

