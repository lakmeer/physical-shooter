
{ id, log, box, limit, floor, sfx, v2, pi } = require \std

{ CollisionBox } = require \./collision-box
{ Bullet } = require \./bullet


# Generate graphic

ship-src= '/assets/ship.svg'
ship-size = 200

ship-blitter = document.create-element \canvas
ship-blitter.width = ship-blitter.height = ship-size
ship-ctx = ship-blitter.get-context \2d

ship-i = new Image
ship-i.src = ship-src
ship-i.onload = ->
  ship-ctx.draw-image ship-i, 0, 0, ship-size, ship-size



#
# Player
#
# Contains things common to Players and Enemies
#

export class Player

  { board-size } = require \config

  sprite-size   = [ 30, 30 ]
  sprite-offset = sprite-size `v2.scale` 0.5

  (@index) ->
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
      m = Math.sin time + @index * pi
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
    ctx.sprite ship-blitter, @pos, sprite-size, sprite-offset
    #ctx.set-color @derive-color! # \#35d
    #ctx.rect @pos `v2.add` [-5,5], box 10
    #@box.draw ctx

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

