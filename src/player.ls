
{ id, log, limit, floor, random-range, v2, pi } = require \std

{ RadialCollider } = require \./collider
{ Physics } = require \./physics
{ Timer, RecurringTimer } = require \./timer
{ PlayerBullet, Laser } = require \./bullet

{ palette-sprite } = require \./sprite

Palette = require \./player-palettes

weapon-specs =
  * num: 2
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

  max-speed     = 2000
  laser-rate    = 2
  bullet-rate   = 0.2
  sprite-size   = [ 30, 30 ]
  sprite-offset = sprite-size `v2.scale` 0.5

  palette-index-assignment = <[ red blue green magenta cyan yellow ]>

  shells = 5
  shell-gap = 30

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
    @alive = yes

    @laser-timer  = new Timer laser-rate
    @bullet-timer = new RecurringTimer bullet-rate
    @palette = Palette[palette-index-assignment[@index]]
    @sprite = palette-sprite color-map, lumin-map, @palette.paintjob, 200
    @destination-pos = [ @physics.pos.0, @physics.pos.1 ]

    @state =
      laser-active: no
      vortex-active: no
      forcefield-active: no

    @forcefield-phase = 0
    @set-weapon-level 0

  level-up-weapon: ->
    @set-weapon-level @weapon-level + 1

  set-weapon-level: (n) ->
    @weapon-level = n
    spec = weapon-specs[@weapon-level]
    @weapon-multi = spec.num
    @bullet-timer.target = 1/spec.dps * 10 * spec.num

  kill: ->
    @alive = false
    @bullets = []

  unkill: ->
    @alive = true
    @damage.health = @damage.max-hp

  derive-bullet-color: (p) ->
    @palette.bullet-color p

  move-towards: (pos) ->
    @destination-pos = pos

  draw-projectiles: (ctx) ->
    @bullets.map (.draw ctx)

  draw-lasers: (ctx) ->
    @lasers.map (.draw ctx)

  draw-ship: (ctx) ->
    if not @alive then return
    if @state.forcefield-active
      @draw-forcefield ctx
    ctx.sprite @sprite, @physics.pos, sprite-size, offset: sprite-offset

  draw: (ctx) ->
    if not @alive then return
    @draw-projectiles ctx
    @draw-lasers ctx
    @draw-ship ctx

  draw-forcefield: (ctx) ->
    max-diam = 10 + shells * shell-gap
    ctx.set-line-color \white

    diam = 50
    ctx.ctx.global-alpha = 1 - (@forcefield-phase % shell-gap) / shell-gap
    ctx.circle @physics.pos, diam

    for shell from 0 til shells
      diam = 50 + shell * shell-gap + @forcefield-phase % shell-gap
      ctx.ctx.global-alpha = 1 - diam/max-diam
      ctx.stroke-circle @physics.pos, diam
    ctx.ctx.global-alpha = 1

  laser: (shaker) ->
    if not @alive then return
    @lasers.push new Laser this, [ @physics.pos.0, @physics.pos.1 ]
    @laser-timer.active = yes
    if shaker?
      shaker.trigger-after 0.5, 10, 2.5
    return true

  collect: (item) ->
    item.collected = yes
    @score += 1

  update: (Δt, time) ->
    if not @alive then return

    pos = @physics.pos

    # Update projectiles
    @bullets = @bullets.filter (.update Δt)
    @bullet-timer.update Δt

    # Update special weapons
    @lasers  = @lasers.filter  (.update Δt, pos)
    if @lasers.length is 0
      @deactivate-laser!
    @laser-timer.update Δt
    @forcefield-phase += Δt * 200

    if @bullet-timer.elapsed => @shoot!

    # Move towards dest
    diff = @destination-pos `v2.sub` @physics.pos
    dist = v2.hyp diff
    dest =
      if dist < max-speed * Δt
        @destination-pos
      else
        @physics.pos `v2.add` ((v2.norm diff) `v2.scale` (max-speed * Δt))

    @physics.move-to dest
    @collider.move-to dest

  shoot: ->
    if not @alive then return
    if @state.laser-active or @state.forcefield-active or @state.vortex-active then return

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

  activate-laser: ->
    if not @state.laser-active
      @state.laser-active = yes
      @laser!
      @deactivate-vortex!
      @deactivate-forcefield!

  activate-forcefield: ->
    if not @state.laser-active
      @state.forcefield-active = yes
      @deactivate-vortex!

  activate-vortex: ->
    if not @state.laser-active
      @state.vortex-active = yes
      @deactivate-forcefield!

  deactivate-laser: ->
    @state.laser-active = no

  deactivate-forcefield: ->
    @state.forcefield-active = no

  deactivate-vortex: ->
    @state.vortex-active = no

  cleanup: ->
    # TODO: Cleanup projectiles if I die

