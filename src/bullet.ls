
{ id, log, min, rnd, wrap, floor, v2 } = require \std

{ RadialCollider, LaserCollider } = require \./collider

{ board-size } = require \config

ship-colors = [
  -> "rgb(#{ 255 - floor it * 255 }, 0, 0)"
  -> "rgb(0, 0, #{ 255 - floor it * 255 })"
  -> "rgb(0, #{ 230 - floor it * 230 }, 0)"
  -> "rgb(#{ 255 - floor it * 255 }, 0, #{ 255 - floor it * 255 })"
  -> "rgb(#{ 255 - floor it * 255 }, #{ 128 - floor it * 128 }, 0)"
  -> p = 240 - floor it * 240; "rgb(#p,#p,#p)"
]

{ Physics } = require \./physics


#
# Bullet
#
# Blam
#

random-range = (a, b) -> a + (rnd b - a)

class Bullet

  (pos, @owner) ->
    @w ||= 1
    @physics  = new Physics p:pos
    @collider = new RadialCollider ...pos, @w/2
    @state =
      alive: yes
      spent: 0
      quota: 1
      power: 1

  derive-color: ->
    \white

  update: (Δt) ->
    @physics.update Δt
    @collider.move-to @physics.pos
    @state.alive = @is-in-bounds! and @state.spent <= @state.quota

  is-in-bounds: ->
    @state.alive =
      @physics.pos.0 <=  board-size.0 * 1.5 and
      @physics.pos.0 >= -board-size.0 - 1.5 and
      @physics.pos.1 <=  board-size.1 * 1.5 and
      @physics.pos.1 >= -board-size.1 - 1.5

  knock-back: (target) ->

  draw: ->
    it.set-color \magenta
    it.rect [ @physics.pos.0 - @w/2, @physics.pos.1 + @w/2], [ @w, @w ]


#
# Player's Bullet
#
# Custom launch parameters and drawing
#

export class PlayerBullet extends Bullet

  ->
    @w = 2
    super ...
    @state.quota = 1
    @state.power = 20
    @physics.set-vel [0 100]
    @physics.set-acc [(random-range -5, 5), 1000]

  derive-color: ->
    @owner.derive-bullet-color @state.spent / @state.quota

  impact: (target, Δt) ->  # Assume target has compatible component
    damage-this-tick = @state.power * Δt
    target.damage.health -= damage-this-tick

    if target.type? and target.type is \small
      target.physics.vel.1 += 10  # knockback
    else
      target.physics.vel.1 += 1  # knockback

    @state.spent += damage-this-tick
    @state.hit = true

  draw: ->
    it.circle @physics.pos, @w
    it.set-color @derive-color!
    it.rect [@physics.pos.0 - @w/2, @physics.pos.1 + @w/2],
      [ @w, @w * (3 + @physics.vel.1/100) ]


#
# Enemy Variant
#

export class EnemyBullet extends Bullet

  range = 10
  collection-ramp-up = 25

  { board-size } = require \config

  (pos, vel) ->
    @w        = 5
    super ...
    @physics  = new Physics p:pos, v:vel, f:1
    @stray    = no
    @color    = \white

    @collection-speed = 0

    @state.quota = 1
    @state.power = 25

  impact: (target, Δt) ->  # Assume target has compatible component
    damage-this-tick = @state.power * Δt
    target.damage.health -= damage-this-tick
    @state.spent += damage-this-tick
    @state.hit = true

  derive-color: ->
    if @stray
      @color
    else
      "rgb(#{ 255 - floor 255 * @state.spent/@state.quota },255,255)"

  update-stray: (Δt, owner) ->
    diff = owner.physics.pos `v2.sub` @physics.pos
    dist = v2.hyp diff

    if dist < range
      owner.collect this
      return false

    @collection-speed = min dist, @collection-speed + collection-ramp-up * Δt
    dir  = v2.norm diff
    jump = dir `v2.scale` @collection-speed
    @physics.pos = @physics.pos `v2.add` jump
    return true

  draw: ->
    if @stray
      it.ctx.global-alpha = 0.7
      it.set-color @derive-color!
      it.circle @physics.pos, @w * 2
      it.ctx.global-alpha = 0.5
      it.set-color \white
      it.circle @physics.pos, @w * 2 * 0.7
      it.ctx.global-alpha = 1
    else
      it.set-color @derive-color!
      it.circle @physics.pos, @w


#
# Laser Beam Weapon
#

export class Laser

  { board-size } = require \config

  (@pos, @owner) ->
    @w = 100
    @collider = new LaserCollider @pos.0, @pos.1, @w
    @state =
      alive: yes
      age: 0
      life: 2
      power: 200

    @charge-time = 0.5
    @phase = 1

  impact: (target, Δt) ->  # Assume target has compatible component
    damage-this-tick = @state.power * Δt
    target.damage.health -= damage-this-tick
    @state.spent += damage-this-tick
    @state.hit = true

  derive-color: (p, i) ->
    ship-colors[@owner.index] p, i

  update: (Δt, pos = @pos) ->
    @pos.0 = pos.0
    @pos.1 = pos.1
    @collider.move-to @pos
    @state.age += Δt

    if @phase is 1 and @state.age >= @charge-time
      @phase = 2
      @collider.disabled = no
      @state.age %= @charge-time

    if @phase is 2
      p = @state.age / @state.life
      @collider.set-width @w * (1 - p*p*p)

      if @state.age >= @state.life
        @state.age %= @state.life
        @phase += 1

    return @state.alive and @state.age < @state.life and @phase < 3

  draw: ->
    if @phase is 1
      @draw-phase-a it
    else
      @draw-phase-b it

  draw-phase-a: ->
    p = @state.age / @charge-time
    it.ctx.global-alpha = p*p
    it.ctx.global-composite-operation = \lighter
    it.set-color @derive-color 1 - p
    it.circle @pos, @w * 20 * (1 - p*p*p)
    it.ctx.global-alpha = 1
    it.ctx.global-composite-operation = \source-over

  draw-beam: (ctx, w, color) ->
    ctx.set-color color
    ctx.semi-circle @pos, w
    ctx.rect [@pos.0 - w/2, board-size.1 + 20 ], [ w, board-size.1 - @pos.1 + 20 ]

  draw-phase-b: ->
    p = @state.age / @state.life
    it.ctx.global-composite-operation = \lighter
    @draw-beam it, @w * (1 - p*p*p), @derive-color p
    @draw-beam it, @w * (1 -  p*p ), \grey
    @draw-beam it, @w * (1 -   p  ), \white
    it.ctx.global-composite-operation = \source-over

