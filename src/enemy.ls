
{ id, log, box, floor, v2 } = require \std

{ CollisionBox } = require \./collision-box

#
# Enemy
#
# Autonomous, computer-controlled version of Ship
# Idea: injected controller class - cpu vs human
#

export class Enemy
  (@pos = [0 0]) ->
    @box = new CollisionBox ...@pos, 10, 10
    @bullets = []
    @state =
      alive: yes
      health: 10
      max-hp: 10

  update: (Δt, time) ->
    @bullets := @bullets.filter (.update Δt)
    @box.move-to @pos

  move-to: (@pos) ->
    @box.move-to @pos

  draw: (ctx) ->
    @bullets.map (.draw ctx)
    ctx.set-color "hsl(#{floor 120*@state.health/@state.max-hp},100%,50%)"
    ctx.rect @pos `v2.add` [-5,5], box 10
    @box.draw ctx

  shoot: ->
    @bullets.push new Bullet [ @pos.0 - 0.04, @pos.1 ]
    @bullets.push new Bullet [ @pos.0 + 0.04, @pos.1 ]

