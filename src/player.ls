
{ id, log, limit, floor, v2, pi } = require \std

{ RadialCollider } = require \./collider
{ Physics } = require \./physics
{ Timer } = require \./timer
{ PlayerBullet, Laser } = require \./bullet

Palette = require \./player-palettes

{ palette-sprite } = require \./sprite


#
# Player
#
# Contains things common to Players and Enemies
#

export class Player

  { board-size } = require \config

  laser-rate    = 2
  bullet-rate   = 0.05

  sprite-size   = [ 30, 30 ]
  sprite-offset = sprite-size `v2.scale` 0.5

  palette-index-assignment = <[ red blue green magenta cyan yellow ]>

  color-map = \/assets/ship-colormap.svg
  lumin-map = \/assets/ship-luminosity.svg

  (@index) ->
    @bullets   = []
    @lasers    = []
    @physics   = new Physics [0 20 - board-size.1]
    @collider  = new RadialCollider 0, 0, 10
    @auto-move = yes
    @score     = 0

    @damage =
      health: 200
      max-hp: 200

    @forcefield-phase = 0
    @forcefield-active = no

    @laser-timer  = new Timer laser-rate
    @bullet-timer = new Timer bullet-rate

    @palette = Palette[palette-index-assignment[@index]]
    @sprite = palette-sprite color-map, lumin-map, @palette.paintjob, 200

  kill: ->
    @dead = true
    @bullets = []

  unkill: ->
    @dead = false
    @damage.health = @damage.max-hp

  derive-bullet-color: (p) ->
    @palette.bullet-color p

  auto-pilot: (time) ->
    m = Math.sin time + @index * pi / 3
    g = Math.cos time + @index * pi / 6
    @physics.pos.0 = board-size.0 * 0.98 * m # * Math.abs(m)
    @physics.pos.1 = -board-size.1 + board-size.1/3 + g * board-size.1/5

  update: (Δt, time) ->
    if @dead then return
    if @auto-move then @auto-pilot time

    pos = @physics.pos

    @forcefield-phase += Δt * 40
    @bullets = @bullets.filter (.update Δt)
    @lasers  = @lasers.filter (.update Δt, pos)

    @laser-timer.update Δt
    @bullet-timer.update Δt

    if @bullet-timer.expired
      @shoot!
      @bullet-timer.reset!

    @collider.move-to @physics.pos

  move-to: (pos) ->
    @physics.move-to pos
    @collider.move-to pos

  draw-projectiles: (ctx) ->
    @bullets.map (.draw ctx)

  draw-lasers: (ctx) ->
    @lasers.map (.draw ctx)

  draw-ship: (ctx) ->
    if @dead then return
    @draw-forcefield ctx if @forcefield-active
    ctx.sprite @sprite, @physics.pos, sprite-size, offset: sprite-offset

  draw: (ctx) ->
    if @dead then return
    @draw-projectiles ctx
    @draw-lasers ctx
    @draw-ship ctx

  draw-forcefield: (ctx) ->
    shells = 4
    shell-gap = 20
    max-diam = 10 + shells * shell-gap
    ctx.set-line-color \white
    for shell from 0 til shells
      diam = 10 + shell * shell-gap + @forcefield-phase % shell-gap
      ctx.ctx.global-alpha = 1 - diam/max-diam
      ctx.stroke-circle @physics.pos, diam
    ctx.ctx.global-alpha = 1

  shoot: ->
    if @dead then return
    if @laser-timer.active then return
    if not @bullet-timer.active
      @bullets.push new PlayerBullet [ @physics.pos.0 - 3, @physics.pos.1 + 5 ], this
      @bullets.push new PlayerBullet [ @physics.pos.0 + 3, @physics.pos.1 + 5 ], this
      @bullet-timer.active = yes

  laser: (shaker) ->
    if @dead then return
    if @laser-timer.active is no
      @lasers.push new Laser [ @physics.pos.0, @physics.pos.1 ], this
      @laser-timer.active = yes
      if shaker?
        shaker.trigger-after 0.5, 10, 2.5
      return true
    return false

  dont-auto-move: ->
    @auto-move = no

  collect: (item) ->
    item.collected = yes
    #log @index, @score += 1


