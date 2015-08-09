
{ id, log, min, rnd, wrap, floor, random-range, v2 } = require \std

{ RadialCollider, LaserCollider } = require \./collider
{ board-size } = require \config
{ Physics } = require \./physics


#
# Bullet
#
# Blam
#

class Bullet

  (@owner, pos, vel = [0 0]) ->
    @w ||= 1
    @physics  = new Physics p:pos, v:vel
    @collider = new RadialCollider ...pos, @w/2
    @color = @owner.palette.bullet-color
    @state =
      alive: yes
      spent: 0
      quota: 1
      power: 1

  derive-color: ->
    @color @state.spent / @state.quota

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

  knock-back: (target, n) ->
    target.physics.vel.1 += n

  draw: ->
    it.set-color \magenta
    it.rect [ @physics.pos.0 - @w/2, @physics.pos.1 + @w/2], [ @w, @w ]


#
# Player's Bullet
#
# Custom launch parameters and drawing
#

export class PlayerBullet extends Bullet

  knock-back-amount =
    small: 10
    large: 1

  ->
    @w = 2
    super ...
    @state.quota = 1
    @state.power = 20
    @physics.add-vel [0 100]
    @physics.set-acc [(random-range -5, 5), 1000]

  impact: (target, Δt) ->  # Assume target has compatible component
    damage-this-tick = @state.power * Δt
    target.damage.health -= damage-this-tick
    @knock-back target, knock-back-amount[target.type]
    @state.spent += damage-this-tick
    @state.hit = true

  draw: ->
    length = @w * (3 + @physics.vel.1/100)
    it.set-color @derive-color!
    it.rect [ @physics.pos.0 - @w/2, @physics.pos.1 + @w/2 ], [ @w, length ]
    it.set-color \white
    it.circle @physics.pos, @w


#
# Enemy Variant
#

export class EnemyBullet extends Bullet

  range = 10
  collection-ramp-up = 25

  { board-size } = require \config

  (@owner, pos) ->
    @w        = 5
    super ...
    @physics  = new Physics p:pos, f:1
    @stray    = no
    @color    = -> \white

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

  (@owner, pos) ->
    @w = 100
    @pos = [ pos.0, pos.1 ]
    @collider = new LaserCollider pos.0, pos.1, @w
    @charge-time = 0.5
    @phase = 1
    @state =
      alive: yes
      age: 0
      life: 2
      power: 200

  impact: (target, Δt) ->  # Assume target has compatible component
    damage-this-tick = @state.power * Δt
    target.damage.health -= damage-this-tick
    @state.spent += damage-this-tick
    @state.hit = true

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
    it.set-color @owner.palette.laser-color p
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
    @draw-beam it, @w * (1 - p*p*p), @owner.palette.laser-color 1 - p
    @draw-beam it, @w * (1 -  p*p ), \grey
    @draw-beam it, @w * (1 -   p  ), \white
    it.ctx.global-composite-operation = \source-over

