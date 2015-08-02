
{ id, log, box, sfx, v2 } = require \std

{ CollisionBox } = require \./collision-box
{ Bullet } = require \./bullet

#
# Player
#
# Contains things common to Players and Enemies
#

export class Player

  ->
    @bullets = []
    @pos = [0 -80]
    @box = new CollisionBox ...@pos, 10, 10
    @auto-move = yes

  update: (Δt, time) ->
    if @auto-move
      @pos.0 = 90 * Math.sin time
    @bullets = @bullets.filter (.update Δt)
    @box.move-to @pos

  move-to: (@pos) ->
    @box.move-to @pos

  draw: (ctx) ->
    @bullets.map (.draw ctx)
    ctx.set-color \#35d
    ctx.rect @pos `v2.add` [-5,5], box 10
    @box.draw ctx

  shoot: ->
    #sfx "PEW!"
    @bullets.push new Bullet [ @pos.0 - 3, @pos.1 + 5 ]
    @bullets.push new Bullet [ @pos.0 + 3, @pos.1 + 5 ]

  dont-auto-move: ->
    @auto-move = no

