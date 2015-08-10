
{ id, log, limit, floor, random-range, v2, pi } = require \std

{ RadialCollider } = require \./collider
{ Physics } = require \./physics
{ Timer, RecurringTimer } = require \./timer
{ PlayerBullet, Laser } = require \./bullet

{ palette-sprite } = require \./sprite

Palette = require \./player-palettes

weapon-specs =
  * num: 1
    dps: 100
  * num: 2
    dps: 200
  * num: 3
    dps: 400
  * num: 4
    dps: 800
  * num: 5
    dps: 1600
  * num: 5
    dps: 3200


#
# Player
#
# Contains things common to Players and Enemies
#

export class Player

  { board-size } = require \config

  laser-rate    = 2
  bullet-rate   = 0.2
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
      health: 1000
      max-hp: 1000

    @forcefield-phase = 0
    @forcefield-active = no
    @laser-timer  = new Timer laser-rate
    @bullet-timer = new RecurringTimer bullet-rate
    @palette = Palette[palette-index-assignment[@index]]
    @sprite = palette-sprite color-map, lumin-map, @palette.paintjob, 200

    @set-weapon-level 0

  level-up-weapon: ->
    @set-weapon-level @weapon-level + 1

  set-weapon-level: (n) ->
    @weapon-level = n
    spec = weapon-specs[@weapon-level]
    @weapon-multi = spec.num
    @bullet-timer.target = 1/spec.dps * 10 * spec.num

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

  laser: (shaker) ->
    if @dead then return
    if @laser-timer.active is no
      @lasers.push new Laser this, [ @physics.pos.0, @physics.pos.1 ]
      @laser-timer.active = yes
      if shaker?
        shaker.trigger-after 0.5, 10, 2.5
      return true
    return false

  dont-auto-move: ->
    @auto-move = no

  collect: (item) ->
    item.collected = yes
    @score += 1

  update: (Δt, time) ->
    if @dead then return
    if @auto-move then @auto-pilot time

    pos = @physics.pos

    @forcefield-phase += Δt * 40
    @bullets = @bullets.filter (.update Δt)
    @lasers  = @lasers.filter  (.update Δt, pos)

    @laser-timer.update Δt
    @bullet-timer.update Δt
    @collider.move-to @physics.pos

    if @bullet-timer.elapsed => @shoot!

  shoot: ->
    if @dead then return
    if @laser-is-active then return

    jiggle = [ (random-range -1, 1), (random-range -1, 1) ]
    source = @physics.pos `v2.add` jiggle

    multi2-left = [-4 0]
    multi2-right = [4 0]

    multi3-mid  =  [0 2]
    multi3-left = [-7 0]
    multi3-right = [7 0]

    switch @weapon-multi
    | 1 =>
      @bullets.push new PlayerBullet this, source
    | 2 =>
      @bullets.push new PlayerBullet this, (multi2-left  `v2.add` source), (multi2-left `v2.scale` 3)
      @bullets.push new PlayerBullet this, (multi2-right `v2.add` source), (multi2-right `v2.scale` 3)
    | 3 =>
      @bullets.push new PlayerBullet this, (multi3-left  `v2.add` source), (multi3-left `v2.scale` 3)
      @bullets.push new PlayerBullet this, (multi3-mid   `v2.add` source)
      @bullets.push new PlayerBullet this, (multi3-right `v2.add` source), (multi3-right `v2.scale` 3)
    | 4 =>
      @bullets.push new PlayerBullet this, (multi2-left  `v2.add` source), (multi2-left `v2.scale` 5)
      @bullets.push new PlayerBullet this, (multi2-left  `v2.add` source), (multi2-left `v2.scale` 2)
      @bullets.push new PlayerBullet this, (multi2-right `v2.add` source), (multi2-right `v2.scale` 2)
      @bullets.push new PlayerBullet this, (multi2-right `v2.add` source), (multi2-right `v2.scale` 5)
    | 5 =>
      @bullets.push new PlayerBullet this, (multi3-left  `v2.add` source), (multi3-left `v2.scale` 5)
      @bullets.push new PlayerBullet this, (multi3-left  `v2.add` source), (multi3-left `v2.scale` 2)
      @bullets.push new PlayerBullet this, (multi3-mid   `v2.add` source)
      @bullets.push new PlayerBullet this, (multi3-right `v2.add` source), (multi3-right `v2.scale` 2)
      @bullets.push new PlayerBullet this, (multi3-right `v2.add` source), (multi3-right `v2.scale` 5)

