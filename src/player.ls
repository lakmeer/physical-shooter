
{ id, log, box, limit, floor, sfx, v2, pi } = require \std

{ CollisionBox } = require \./collision-box
{ Bullet, Laser } = require \./bullet


{ sprite, palette-sprite } = require \./sprite


# Generate graphic

lumin = sprite \/assets/ship-luminosity.svg, 200

color-map-ix = 3

color-schemes = [
  [ \darkred, \lightblue, \pink ]
  [ \darkblue, \lightblue, \royalblue ]
  [ \purple, \lightblue, \magenta ]
  [ \orangered, \lightblue, \orange ]
  [ \darkgreen, \lightblue, \forestgreen ]
]

red    = palette-sprite \/assets/ship-colormap.svg, \/assets/ship-luminosity.svg, color-schemes.0, 200
blue   = palette-sprite \/assets/ship-colormap.svg, \/assets/ship-luminosity.svg, color-schemes.1, 200
pink   = palette-sprite \/assets/ship-colormap.svg, \/assets/ship-luminosity.svg, color-schemes.2, 200
orange = palette-sprite \/assets/ship-colormap.svg, \/assets/ship-luminosity.svg, color-schemes.3, 200
green  = palette-sprite \/assets/ship-colormap.svg, \/assets/ship-luminosity.svg, color-schemes.4, 200


color-map-src = \/assets/ship-colormap.svg
lumin-map-src = \/assets/ship-luminosity.svg

ship-sprites = [ red, blue, pink, orange, green ]


#
# Player
#
# Contains things common to Players and Enemies
#

export class Player

  { board-size } = require \config

  sprite-size   = [ 30, 30 ]
  sprite-offset = sprite-size `v2.scale` 0.5

  laser-rate = 2

  ship-colors = [
    -> "rgb(#{ 255 - floor it * 255 }, 0, 0)"
    -> "rgb(0, 0, #{ 255 - floor it * 255 })"
    -> "rgb(#{ 255 - floor it * 255 }, 0, #{ 255 - floor it * 255 })"
    -> "rgb(#{ 255 - floor it * 255 }, #{ 128 - floor it * 128 }, 0)"
    -> "rgb(0, #{ 230 - floor it * 230 }, 0)"
  ]

  (@index) ->
    @bullets = []
    @lasers = []
    @pos = [0 20 - board-size.1]
    @box = new CollisionBox ...@pos, 10, 10
    @auto-move = yes
    @score = 0

    @damage =
      health: 200
      max-hp: 200

    @forcefield-phase = 0
    @forcefield-active = no

    @stray-color = ship-colors[@index]

    @laser-timer =
      active: no
      target-time: laser-rate
      current-time: 0

  kill: ->
    @dead = true
    @bullets = []

  unkill: ->
    @dead = false
    @damage.health = @damage.max-hp

  derive-color: ->
    p = limit 0, 1, @damage.health / @damage.max-hp
    ship-colors[@index] p

  update: (Δt, time) ->
    if @dead then return
    if @auto-move
      m = Math.sin time + @index * pi / 3
      n = Math.sin time * 3
      @pos.0 = board-size.0*0.99 * m * Math.abs(m)

    @forcefield-phase += Δt * 40
    @bullets = @bullets.filter (.update Δt)
    pos = @pos
    @lasers  = @lasers.filter (.update Δt, pos)

    if @laser-timer.active
      @laser-timer.current-time += Δt

    if @laser-timer.current-time > @laser-timer.target-time
      @laser-timer.current-time = 0
      @laser-timer.active = no

    @box.move-to @pos

  move-to: (@pos) ->
    @box.move-to @pos

  draw: (ctx) ->
    if @dead then return
    @draw-forcefield ctx if @forcefield-active
    @bullets.map (.draw ctx)
    @lasers.map (.draw ctx)
    ctx.sprite ship-sprites[@index], @pos, sprite-size, sprite-offset

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
    @bullets.push new Bullet [ @pos.0 - 3, @pos.1 + 5 ], @index
    @bullets.push new Bullet [ @pos.0 + 3, @pos.1 + 5 ], @index

  laser: ->
    if @laser-timer.active is no
      @lasers.push new Laser [ @pos.0, @pos.1 ], @index
      @laser-timer.active = yes

  dont-auto-move: ->
    @auto-move = no

  collect: (item) ->
    item.collected = yes
    #log @index, @score += 1


