
{ id, log, floor } = require \std


#
# Backdrop Class
#
# Renders the background moving underneath
#

export class Backdrop

  speed = 600

  { board-size, screen-size } = require \config

  { sprite }  = require \./sprite

  color-a = [ 165 27 25 ]
  color-b = [ 189 42 28 ]

  lerp = (a, t, b) -> a + t * (b - a)

  bg = sprite \/assets/bg.jpg, 3860

  ->
    @offset = 0
    @gap    = 50

  derive-color: (p) ->
    h = floor lerp color-b.0, p, color-a.0
    s = floor lerp color-b.1, p, color-a.1
    l = floor lerp color-b.2, p, color-a.2
    "hsl(#h,#s%,#l%)"

  draw: (ctx) ->

    ctx.sprite bg, [ -board-size.0, board-size.1 + @offset + board-size.1 * 8 ], [ board-size.0 * 2, board-size.1 * 10 ]

    return

    ctx.set-line-color @derive-color 0.4
    for i from -board-size.1 to board-size.1 + @gap by @gap
      y = i - @offset
      ctx.line -board-size.0, y, board-size.0, y

    x = board-size.0/2

    for i from -x to x by @gap
      ctx.line  x + i, -board-size.1,  x + i, board-size.1
      ctx.line -x - i, -board-size.1, -x - i, board-size.1


  update: (Δt, time, canvas) ->

    @offset = time * -40

    return

    @offset += speed * Δt
    if @offset >= @gap
      @offset %= @gap

    @gap = 50 + 15 * Math.sin time/2



