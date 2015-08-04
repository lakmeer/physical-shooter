
{ id, log, floor } = require \std

#
# Backdrop Class
#
# Renders the background moving underneath
#

export class Backdrop

  speed = 100

  ->
    @offset = 0
    @gap    = 1

  draw: (ctx) ->
    for i from -100 to 100 by @gap
      ctx.set-line-color "rgb(0,#{ floor 100 - (100+i)/2 },30)"
      y = i - @offset
      ctx.line -100, y, 100, y
      ctx.line 100 + i, -100, 100 + i, 100
      ctx.line -100 - i, -100, -100 - i, 100


  update: (Δt, time) ->
    @offset += speed * Δt
    if @offset >= 20
      @offset %= 20

    @gap = 12 + 2 * Math.sin time/2
