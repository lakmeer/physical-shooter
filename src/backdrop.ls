
{ id, log, floor } = require \std

#
# Backdrop Class
#
# Renders the background moving underneath
#

export class Backdrop

  speed = 100

  { board-size } = require \config

  ->
    @offset = 0
    @gap    = 1

  draw: (ctx) ->
    for i from -board-size.1 to board-size.1 by @gap
      y = i - @offset
      ctx.set-line-color "rgb(0,#{ floor 100 + 100 - (100+i)/2 },30)"
      ctx.line -board-size.0, y, board-size.0, y

    x = board-size.0/2

    for i from -x to x by @gap
      ctx.line  x + i, -board-size.1,  x + i, board-size.1
      ctx.line -x - i, -board-size.1, -x - i, board-size.1


  update: (Δt, time) ->
    @offset += speed * Δt
    if @offset >= 20
      @offset %= 20

    @gap = 12 + 2 * Math.sin time/2