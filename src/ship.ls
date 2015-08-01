
{ id, log, box, v2 } = require \std

{ Bullet } = require \./bullet


#
# Ship
#
# Contains things common to Players and Enemies
#

export class Ship

  ->
    @bullets = []

  update: (Δt, time) ->
    @pos.0 = 0.5 * Math.sin time/1000
    @bullets := @bullets.filter (.update Δt)
    @box.move-to @pos

  draw: (ctx) ->
    @bullets.map (.draw ctx)
    ctx.set-color \red
    ctx.rect (@pos `v2.add` [-0.08 0.04]), box 0.08
    @box.draw ctx

  shoot: ->
    @bullets.push new Bullet [ @pos.0 - 0.04, @pos.1 ]
    @bullets.push new Bullet [ @pos.0 + 0.04, @pos.1 ]

