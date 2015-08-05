
{ id, log, box, limit, floor, sfx, v2 } = require \std

{ CollisionBox } = require \./collision-box
{ Bullet } = require \./bullet

#
# Player
#
# Contains things common to Players and Enemies
#

export class Player

  { board-size } = require \config

  ->
    @bullets = []
    @pos = [0 10 - board-size.1]
    @box = new CollisionBox ...@pos, 10, 10
    @auto-move = yes

    @damage =
      health: 200
      max-hp: 200

    @forcefield-phase = 0
    @forcefield-active = no

  kill: ->
    @dead = true
    @bullets = []

  unkill: ->
    @dead = false
    @damage.health = @damage.max-hp

  derive-color: ->
    p = limit 0, 1, @damage.health / @damage.max-hp
    g = floor 200 * p
    r = 200 - g
    "rgb(#r,#g,#g)"

  update: (Δt, time) ->
    if @dead then return
    if @auto-move
      m = Math.sin time
      n = Math.sin time * 3
      @pos.0 = 90 * m * Math.abs(m)
    @forcefield-phase += Δt * 40
    @bullets = @bullets.filter (.update Δt)
    @box.move-to @pos

  move-to: (@pos) ->
    @box.move-to @pos

  draw: (ctx) ->
    if @dead then return
    @draw-forcefield ctx if @forcefield-active
    @bullets.map (.draw ctx)
    ctx.set-color @derive-color! # \#35d
    ctx.rect @pos `v2.add` [-5,5], box 10
    @box.draw ctx

  draw-forcefield: (ctx) ->
    shells = 4
    shell-gap = 20
    max-diam = 10 + shells * shell-gap
    ctx.set-line-color \white
    for shell from 0 til shells
      diam = 10 + shell * shell-gap + @forcefield-phase % shell-gap
      ctx.ctx.global-alpha = 1 - diam/max-diam
      ctx.stroke-circle @pos, diam
    ctx.ctx.global-alpha = 1

  shoot: ->
    if @dead then return
    #sfx "PEW!"
    @bullets.push new Bullet [ @pos.0 - 3, @pos.1 + 5 ]
    @bullets.push new Bullet [ @pos.0 + 3, @pos.1 + 5 ]

  dont-auto-move: ->
    @auto-move = no

