
{ id, log } = require \std
{ test } = require \test


#
# Blitter
#
# A drawing surface that can in turn draw itself to other drawing surfaces
#

export class Blitter

  screen-size  = 600

  (@size = [ screen-size, screen-size ]) ->
    @canvas = document.create-element \canvas
    @ctx    = @canvas.get-context \2d

    @canvas.width  = @size.0
    @canvas.height = @size.1

  clear: ->
    @ctx.fill-style = \white
    @ctx.clear-rect 0, 0, @size.0, @size.1

  set-color: (col) ->
    @ctx.fill-style = col

  rect: (pos, size) ->
    [ x, y ] = @game-space-to-screen-space pos
    [ w, h ] = @game-space-to-screen-space size
    @ctx.fill-rect @size.0/2 + x * @size.0/2, @size.1 - y * @size.1, w * @size.0, h * @size.1

  stroke-rect: ([ x, y ], [ w, h ]) ->
    x1 = @size.0/2 + x * @size.0/2
    y1 = @size.1 - y * @size.1
    x2 = x1 + w * @size.0
    y2 = y1 + h * @size.1
    @ctx.stroke-style = \white
    @ctx.begin-path!
    @ctx.move-to x1 + 0.5, y1 + 0.5
    @ctx.line-to x2 - 0.5, y1 + 0.5
    @ctx.line-to x2 - 0.5, y2 - 0.5
    @ctx.line-to x1 + 0.5, y2 - 0.5
    @ctx.line-to x1 + 0.5, y1 + 0.5
    @ctx.stroke!
    @ctx.close-path!

  line: (x1, y1, x2, y2) ->
    @ctx.stroke-style = \white
    @ctx.move-to @size.0/2 + x1 * @size.0/2, @size.1 - y1 * @size.1
    @ctx.line-to @size.0/2 + x2 * @size.0/2, @size.1 - y2 * @size.1
    @ctx.stroke!

  install: (host) ->
    host.append-child @canvas

  screen-space-to-game-space: ([ screen-x, screen-y ]) ->
    game-x = screen-x/(@size.0/2) - 1
    game-y = 1 - screen-y/@size.0
    return [ game-x, game-y ]

  game-space-to-screen-space: ([ x, y ]) ->
    [ @size.0/2 + x * @size.0/2, @size.1 - y * @size.1 ]


#
# Tests
#

test "Blitter - Screen space to game space", ->
  blitter = new Blitter [ 100, 100 ]

  @equal-v2 'Origin is at bottom center'
    .expect blitter.game-space-to-screen-space [ 0, 0 ]
    .to-be  [ 50, 100 ]

  @equal-v2 'Y=1 is at top center'
    .expect blitter.game-space-to-screen-space [ 0, 1 ]
    .to-be  [ 50, 0 ]

  @equal-v2 'min X min Y is bottom left'
    .expect blitter.game-space-to-screen-space [ -1, 0 ]
    .to-be  [ 0, 100 ]

  @equal-v2 'max X min Y is bottom right'
    .expect blitter.game-space-to-screen-space [ 1, 0 ]
    .to-be  [ 100, 100 ]

  @equal-v2 'min X max Y is top left'
    .expect blitter.game-space-to-screen-space [ -1, 1 ]
    .to-be  [ 0, 0 ]

  @equal-v2 'max X max Y is top right'
    .expect blitter.game-space-to-screen-space [ 1, 1 ]
    .to-be  [ 100, 0 ]


test "Blitter - Game space to screen space", ->
  blitter = new Blitter [ 100, 100 ]

  @equal-v2 'Origin is at bottom center'
    .expect blitter.screen-space-to-game-space [ 50, 100 ]
    .to-be [ 0, 0 ]

  @equal-v2 'Y=1 is at top center'
    .expect blitter.screen-space-to-game-space [ 50, 0 ]
    .to-be [ 0, 1 ]

  @equal-v2 'min X min Y is bottom left'
    .expect blitter.screen-space-to-game-space [ 0, 100 ]
    .to-be [ -1, 0 ]

  @equal-v2 'max X min Y is bottom right'
    .expect blitter.screen-space-to-game-space [ 100, 100 ]
    .to-be [ 1, 0 ]

  @equal-v2 'min X max Y is top left'
    .expect blitter.screen-space-to-game-space [ 0, 0 ]
    .to-be [ -1, 1 ]

  @equal-v2 'max X max Y is top right'
    .expect blitter.screen-space-to-game-space [ 100, 0 ]
    .to-be [ 1, 1 ]

