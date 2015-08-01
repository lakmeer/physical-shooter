
{ id, log, box, v2 } = require \std

{ CollisionBox } = require \./collision-box

#
# Enemy
#
# Autonomous, computer-controlled version of Ship
# Idea: injected controller class - cpu vs human
#

export class Enemy
  ->
    @pos = [0 0]
    @bullets = []
    @box = new CollisionBox ...@pos, 10, 10
    @state = alive: yes

  update: (Δt, time) ->
    @pos.0 = 50 * Math.sin time/1000
    @bullets := @bullets.filter (.update Δt)
    @box.move-to @pos

  move-to: (@pos) ->
    @box.move-to @pos

  draw: (ctx) ->
    @bullets.map (.draw ctx)
    ctx.set-color \red
    ctx.rect (@pos), box 80
    @box.draw ctx

  shoot: ->
    @bullets.push new Bullet [ @pos.0 - 0.04, @pos.1 ]
    @bullets.push new Bullet [ @pos.0 + 0.04, @pos.1 ]


