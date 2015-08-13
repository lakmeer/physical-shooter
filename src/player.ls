
{ id, log, limit, floor, random-range, v2, pi } = require \std

{ RadialCollider } = require \./collider
{ Physics } = require \./physics
{ Timer, RecurringTimer } = require \./timer
{ PlayerBullet, Laser } = require \./bullet

{ palette-sprite } = require \./sprite

Palette = require \./player-palettes

{ bullet-damage } = require \config

weapon-specs =
  * num: 1
    dps: 100
  * num: 1
    dps: 150
  * num: 2
    dps: 200
  * num: 2
    dps: 300
  * num: 3
    dps: 370
  * num: 3
    dps: 450
  * num: 4
    dps: 500
  * num: 4
    dps: 600
  * num: 5
    dps: 700
  * num: 5
    dps: 1000

max-weapon-level = weapon-specs.length - 1



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

  respawn-time = 2

  palette-index-assignment = <[ red blue green magenta cyan yellow ]>

  vortex-particle-width = 5
  vortex-particle-count = 10

  shells = 5
  shell-gap = 30

  color-map = \/assets/ship-colormap.svg
  lumin-map = \/assets/ship-luminosity.svg

  laser-charge-cost   = 3000
  repulsor-charge-cost = 1
  vortex-charge-cost   = 2

  charge-increase-per-collection = 3

  (@index) ->
    @bullets   = []
    @lasers    = []

    @w = 20

    @physics   = new Physics [0 20 - board-size.1]
    @collider  = new RadialCollider 0, 0, 10

    @score  = 0
    @grand-score = 0
    @charge = laser-charge-cost

    @damage =
      health: 2000
      max-hp: 2000

    @alive = yes

    @respawn-timer = new Timer respawn-time
    @laser-timer  = new Timer laser-rate
    @bullet-timer = new RecurringTimer bullet-rate

    @palette = Palette[palette-index-assignment[@index]]
    @sprite = palette-sprite color-map, lumin-map, @palette.paintjob, 200

    @state =
      laser-active: no
      vortex-active: no
      forcefield-active: no

    @forcefield-phase = 0
    @destination-pos = [ @physics.pos.0, @physics.pos.1 ]
    @set-weapon-level 0

    # Respawning and death
    @death-callback = id
    @death-callback-pending = yes

  process-wave-increase: (wave) ->
    @score = 0
    @level-up-weapon!

  superpowers: ->
    @charge = 1000000000

  level-up-weapon: ->
    if @weapon-level < max-weapon-level
      @set-weapon-level @weapon-level + 1

  set-weapon-level: (n) ->
    @weapon-level = n
    spec = weapon-specs[@weapon-level]
    @weapon-multi = spec.num
    @bullet-timer.target = 1/spec.dps * 10 * spec.num

  kill: ->
    @alive = false
    @bullets = []
    @death-callback? this

  derive-bullet-color: (p) ->
    @palette.bullet-color p

  move-towards: (pos) ->
    if not (@state.vortex-active or @state.laser-active)
      @destination-pos = pos

  draw-projectiles: (ctx) ->
    @bullets.map (.draw ctx)

  draw-lasers: (ctx) ->
    @lasers.map (.draw ctx)

  draw-ship: (ctx) ->
    ctx.sprite @sprite, @physics.pos, sprite-size, offset: sprite-offset

  draw-vortex: (ctx) ->
    ctx.ctx.global-composite-operation = \overlay
    ctx.set-color @palette.vortex-particle-color
    for i from 0 to vortex-particle-count
      left = @physics.pos.0 + random-range -@w/2 - vortex-particle-width, @w/2
      top  = @physics.pos.1 + board-size.1 * 2 - random-range 0, @w/2
      ctx.rect [ left, top ], [ vortex-particle-width, board-size.1 * 2 ]
    ctx.ctx.global-composite-operation = \source-over

  draw-special-effects: (ctx) ->
    if @state.forcefield-active then @draw-forcefield ctx
    if @state.vortex-active then @draw-vortex ctx

  draw-forcefield: (ctx) ->
    max-diam = 10 + shells * shell-gap
    ctx.set-color \white
    ctx.set-line-color \white

    diam = 50
    ctx.ctx.global-alpha = 1 - (@forcefield-phase % shell-gap) / shell-gap
    ctx.circle @physics.pos, diam

    for shell from 0 til shells
      diam = 50 + shell * shell-gap + @forcefield-phase % shell-gap
      ctx.ctx.global-alpha = 1 - diam/max-diam
      ctx.stroke-circle @physics.pos, diam
    ctx.ctx.global-alpha = 1

  draw-hud: (ctx) ->
    #return
    charge-offset = [ 0 50 ]
    score-offset =  [ 0 100 ]
    ctx.set-color @palette.bullet-color 0
    ctx.text @physics.pos, @charge, charge-offset
    ctx.text @physics.pos, @score,  score-offset

  laser: ->
    if not @alive then return
    @charge -= laser-charge-cost
    @lasers.push new Laser this, [ @physics.pos.0, @physics.pos.1 ]
    @laser-timer.active = yes
    return true

  collect: (item) ->
    item.collected = yes
    @score += 1
    @grand-score += 1
    @charge += charge-increase-per-collection
    log @charge

  update: (Δt, time) ->
    if not @alive then return

    # Update projectiles
    @bullets = @bullets.filter (.update Δt)
    @bullet-timer.update Δt
    if @bullet-timer.elapsed then @shoot!

    # Update special weapons
    @forcefield-phase += Δt * 200

    # Update laser
    pos = @physics.pos
    @lasers = @lasers.filter (.update Δt, pos)
    if @lasers.length is 0 then @deactivate-laser!

    for laser in @lasers  # there's only one actually
      if laser.done-charging!
        @state.laser-active = yes
        @state.laser-charging = no

    # Move towards dest
    @update-position Δt
    @spend-charge-on-active-weapons Δt

    # Autotpilot
    if @auto-pilot?
      @auto-pilot.update Δt, time
      @damage.health = @damage.max-health

    # Detect dealth
    if @damage.health <= 0
      @alive = no


  update-position: (Δt) ->
    diff = @destination-pos `v2.sub` @physics.pos
    dist = v2.hyp diff
    dest =
      if dist < max-speed * Δt then @destination-pos
      else @physics.pos `v2.add` ((v2.norm diff) `v2.scale` (max-speed * Δt))
    @physics.move-to dest
    @collider.move-to dest

  spend-charge-on-active-weapons: (Δt) ->
    if @state.forcefield-active
      @charge -= repulsor-charge-cost

    if @state.vortex-active
      @charge -= vortex-charge-cost

    if @charge <= 0
      @charge = 0
      @deactivate-vortex!
      @deactivate-forcefield!

  on-killed: (λ) ->
    @death-callback = λ
    @death-callback-pending = yes

  is-laser-busy: ->
    @state.laser-active or @state.laser-charging

  is-super-active: ->
    @state.laser-active or @state.forcefield-active or @state.vortex-active

  suppress-fire-if: (state) ->
    @fire-suppress = state

  shoot: ->
    if not @alive then return
    if @fire-suppress then return
    if @is-super-active! then return

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
    if not @is-laser-busy! and @charge >= laser-charge-cost
      @state.laser-charging = yes
      @laser!
      @deactivate-vortex!
      @deactivate-forcefield!

  activate-forcefield: ->
    if not @state.forcefield-active and not @is-laser-busy! and @charge >= repulsor-charge-cost
      @state.forcefield-active = yes
      @deactivate-vortex!

  activate-vortex: ->
    if not @state.vortex-active and not @is-laser-busy! and @charge >- vortex-charge-cost
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

