
{ id, log, box, limit, floor, sfx, v2, pi } = require \std

{ CollisionRadius } = require \./collision-box
{ Bullet, Laser } = require \./bullet


{ sprite, palette-sprite } = require \./sprite


# Generate graphic

lumin = sprite \/assets/ship-luminosity.svg, 200

color-schemes = [
  <[ darkred lightblue darkred ]>
  <[ darkblue lightblue royalblue ]>
  <[ purple lightblue magenta ]>
  <[ orangered lightblue orange ]>
  <[ darkgreen lightblue forestgreen ]>
  <[ white lightblue white ]>
]

color-map = \/assets/ship-colormap.svg
lumin-map = \/assets/ship-luminosity.svg

ship-sprites = color-schemes.map (palette) ->
  palette-sprite color-map, lumin-map, palette, 200


#
# Player
#
# Contains things common to Players and Enemies
#

export class Player

  { board-size } = require \config

  sprite-size   = [ 30, 30 ]
  sprite-offset = sprite-size `v2.scale` 0.5

  bullet-rate = 0.05
  laser-rate = 2

  ship-colors = [
    -> "rgb(#{ 255 - floor it * 255 }, 0, 0)"
    -> "rgb(0, 0, #{ 255 - floor it * 255 })"
    -> "rgb(#{ 255 - floor it * 255 }, 0, #{ 255 - floor it * 255 })"
    -> "rgb(#{ 255 - floor it * 255 }, #{ 128 - floor it * 128 }, 0)"
    -> "rgb(0, #{ 230 - floor it * 230 }, 0)"
    -> p = 230 - floor it * 230; "rgb(#p,#p,#p)"
  ]

  (@index) ->
    @bullets = []
    @lasers = []
    @pos = [0 20 - board-size.1]
    @box = new CollisionRadius ...@pos, 10
    @auto-move = yes
    @score = 0

    @damage =
      health: 200
      max-hp: 200

    @forcefield-phase = 0
    @forcefield-active = no

    @stray-color = ship-colors[@index]
    @explosion-tint-color = ship-colors[@index] 0

    @bullet-timer =
      active: no
      target-time: bullet-rate
      current-time: 0

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
      g = Math.cos time + @index * pi / 6
      @pos.0 = board-size.0 * 0.98 * m # * Math.abs(m)
      @pos.1 = -board-size.1 + 100 + g * 70

    @forcefield-phase += Δt * 40
    @bullets = @bullets.filter (.update Δt)
    pos = @pos
    @lasers  = @lasers.filter (.update Δt, pos)

    if @laser-timer.active
      @laser-timer.current-time += Δt

    if @laser-timer.current-time > @laser-timer.target-time
      @laser-timer.current-time = 0
      @laser-timer.active = no

    if @bullet-timer.active
      @bullet-timer.current-time += Δt

    if @bullet-timer.current-time > @bullet-timer.target-time
      @bullet-timer.current-time = 0
      @bullet-timer.active = no

    @box.move-to @pos

  move-to: (@pos) ->
    @box.move-to @pos

  draw: (ctx) ->
    if @dead then return
    @draw-forcefield ctx if @forcefield-active
    @bullets.map (.draw ctx)
    @lasers.map (.draw ctx)
    ctx.sprite ship-sprites[@index], @pos, sprite-size, sprite-offset
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
    if @bullet-timer.active is no
      @bullets.push new Bullet [ @pos.0 - 3, @pos.1 + 5 ], this
      @bullets.push new Bullet [ @pos.0 + 3, @pos.1 + 5 ], this
      @bullet-timer.active = yes

  laser: ->
    if @dead then return
    if @laser-timer.active is no
      @lasers.push new Laser [ @pos.0, @pos.1 ], this
      @laser-timer.active = yes

  dont-auto-move: ->
    @auto-move = no

  collect: (item) ->
    item.collected = yes
    #log @index, @score += 1


