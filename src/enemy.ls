
{ id, log, box, floor, physics, rnd, v2 } = require \std

{ CollisionBox } = require \./collision-box

#
# Enemy
#
# Autonomous, computer-controlled version of Ship
# Idea: injected controller class - cpu vs human
#

export class Enemy

  { board-size } = require \config

  border = 10

  (@pos = [0 0]) ->
    @box = new CollisionBox ...@pos, 10, 10
    @bullets = []

    @vel = [0 0]
    @acc = [0 -50 - rnd 50]

    @friction = 0.95

    # Damage component
    @damage =
      health: 10
      max-hp: 10
      alive: yes

  update: (Δt, time) ->
    @bullets := @bullets.filter (.update Δt)
    physics this, Δt
    if @pos.0 >  board-size.0 - border then @pos.0 =  board-size.0 - border
    if @pos.0 < -board-size.0 + border then @pos.0 = -board-size.0 + border
    if @pos.1 >  board-size.1 - border then @pos.1 =  board-size.1 - border
    if @pos.1 < -board-size.1 + border + 50 then @pos.1 = -board-size.1 + border + 50
    @box.move-to @pos

  move-to: (@pos) ->
    @box.move-to @pos

  draw: (ctx) ->
    return if not @damage.alive
    @bullets.map (.draw ctx)
    ctx.set-color "hsl(#{floor 120*@damage.health/@damage.max-hp},100%,50%)"
    ctx.rect @pos `v2.add` [-5,5], box 10
    @box.draw ctx

  shoot-at: (pos) ->

    @bullets.push new Bullet [ @pos.0 + 0.04, @pos.1 ]





