
{ id, log, box, v2 } = require \std

{ CollisionBox } = require \./collision-box

#
# Player
#
# Contains things common to Players and Enemies
#

export class Player

  ->
    @bullets = []
    @pos = [0 0]
    @box = new CollisionBox ...@pos, 10, 10

  update: (Δt, time) ->
    @pos.0 = 50 * Math.sin time/1000
    @bullets := @bullets.filter (.update Δt)
    @box.move-to @pos

  move-to: (@pos) ->
    @box.move-to @pos

  draw: ->
    @bullets.map (.draw ctx)
    it.set-color \red
    it.rect @pos `v2.add` [-5,5], box 10
    @box.draw it

  shoot: ->
    @bullets.push new Bullet [ @pos.0 - 0.04, @pos.1 ]
    @bullets.push new Bullet [ @pos.0 + 0.04, @pos.1 ]


