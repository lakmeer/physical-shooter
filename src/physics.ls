

{ id, log, asin, v2 } = require \std


#
# Physics Component
#
# Knows about physics properties and how to simulate them
#

export class Physics

  ({ p, v, a, f }) ->
    @pos = p or [0 0]
    @vel = v or [0 0]
    @acc = a or [0 0]
    @fri = f or 1

  update: (Δt) ->
    @vel = (@vel `v2.add` (@acc `v2.scale` Δt)) `v2.scale` @fri
    @pos = @pos `v2.add` (@vel `v2.scale` Δt) `v2.add` (@acc `v2.scale` (0.5*Δt*Δt))

  move-to: ->
    @set-pos ...

  set-pos: ([ x, y ]) ->
    @pos.0 = x
    @pos.1 = y

  set-vel: ([ x, y ]) ->
    @vel.0 = x
    @vel.1 = y

  set-acc: ([ x, y ]) ->
    @acc.0 = x
    @acc.1 = y

  get-bearing-to: ([ x, y ]) ->
    xx = x - @pos.0
    yy = y - @pos.1
    asin -xx/v2.hyp [ xx, yy ]

