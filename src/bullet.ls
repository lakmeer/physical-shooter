
{ id, log, min, floor, v2 } = require \std

{ CollisionRadius } = require \./collision-box


#
# Bullet
#
# Blam
#

export class Bullet

  { board-size } = require \config

  ship-colors = [
    -> "rgb(#{ 255 - floor it * 255 }, 0, 0)"
    -> "rgb(0, 0, #{ 255 - floor it * 255 })"
    -> "rgb(#{ 255 - floor it * 255 }, 0, #{ 255 - floor it * 255 })"
    -> "rgb(#{ 255 - floor it * 255 }, #{ 128 - floor it * 128 }, 0)"
    -> "rgb(0, #{ 230 - floor it * 230 }, 0)"
    -> p = 240 - floor it * 240; "rgb(#p,#p,#p)"
  ]

  (@pos, @owner) ->
    @vel = [0 0]
    @acc = [(100 * Math.random! - 50), 1000]
    @w     = 2
    @box   = new CollisionRadius ...@pos, @w/2
    @state =
      alive: yes
      hit: no
      spent: 0
      quota: 1
      power: 20

  impact: (target, Δt) ->  # Assume target has compatible component
    damage-this-tick = @state.power * Δt
    target.damage.health -= damage-this-tick
    if target.type? is \small
      target.vel.1 += 10  # knockback
    else
      target.vel.1 += 1  # knockback

    @state.spent += damage-this-tick
    @state.hit = true

  derive-color: ->
    p = @state.spent/@state.quota
    ship-colors[@owner.index] p

  update: (Δt) ->
    @vel = (@acc `v2.scale` Δt) `v2.add` @vel
    @pos = (@vel `v2.scale` Δt) `v2.add` @pos `v2.add` (@acc `v2.scale` (0.5 * Δt * Δt))
    @box.move-to @pos
    @state.alive = @pos.1 <= board-size.1 * 1.5
    return @state.alive and @state.spent <= @state.quota

  draw: ->
    it.set-color @derive-color!
    it.rect [@pos.0 - @w/2, @pos.1 + @w/2], [ @w, @w * (3 + @vel.1/100) ]
    #@box.draw it


#
# Enemy Variant
#

export class EnemyBullet

  range = 10
  collection-ramp-up = 25

  { board-size } = require \config

  (@pos) ->
    @vel = [0 0]
    @acc = [(100 * Math.random! - 50), -1000]

    @w     = 5
    @box   = new CollisionRadius ...@pos, @w/2

    @stray = no
    @friction = 1
    @color = \white
    @collection-speed = 0

    @state =
      alive: yes
      hit: no
      spent: 0
      quota: 1
      power: 25

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

  update: (Δt) ->
    @vel = (@acc `v2.scale` Δt) `v2.add` @vel `v2.scale` @friction
    @pos = (@vel `v2.scale` Δt) `v2.add` @pos `v2.add` (@acc `v2.scale` (0.5 * Δt * Δt))
    @box.move-to @pos
    @state.alive = @pos.1 <= board-size.1 * 1.5 and @pos.1 >= -board-size.1 * 1.5
    return @state.alive and @state.spent <= @state.quota

  update-stray: (Δt, owner) ->
    diff = owner.pos `v2.sub` @pos
    dist = v2.hyp diff

    if dist < range
      owner.collect this
      return false

    @collection-speed = min dist, @collection-speed + collection-ramp-up * Δt
    dir  = v2.norm diff
    jump = dir `v2.scale` @collection-speed
    @pos = @pos `v2.add` jump
    return true

  draw: ->
    it.set-color @derive-color!
    if @stray then it.ctx.global-alpha = 0.5
    it.circle @pos, @w
    if @stray then it.ctx.global-alpha = 1
    #@box.draw it


#
# Laser Beam Weapon
#

export class Laser

  { board-size } = require \config

  ship-colors = [
    -> "rgb(#{ 255 - floor it * 255 }, 0, 0)"
    -> "rgb(0, 0, #{ 255 - floor it * 255 })"
    -> "rgb(#{ 255 - floor it * 255 }, 0, #{ 255 - floor it * 255 })"
  ]

  class LaserCollider
    (@x, @y, @w) ->
      @colliding = no
    move-to: ([ @x, @y ]) ->
    intersects: ({ x, y, rad }:target) ->
      inside-left  = x > @x - @w/2 - rad
      inside-right = x < @x + @w/2 + rad
      above-player = y >= @y - rad
      @colliding = target.colliding =
        inside-left and inside-right and above-player
    draw: (ctx) ->
      ctx.set-line-color if @colliding then \red else \white
      ctx.stroke-rect [ @x - @w/2, board-size.1 ], [ @w, board-size.1 - @y ]

  (@pos, @owner) ->
    @w     = 50
    @box   = new LaserCollider @pos.0, @pos.1, @w
    @state =
      alive: yes
      age: 0
      life: 1
      power: 200

  impact: (target, Δt) ->  # Assume target has compatible component
    damage-this-tick = @state.power * Δt
    target.damage.health -= damage-this-tick
    target.vel.1 += 10  # knockback
    @state.spent += damage-this-tick
    @state.hit = true

  derive-color: (p) ->
    ship-colors[@owner.index] p

  update: (Δt, pos) ->
    @pos.0 = pos.0
    @pos.1 = pos.1
    @box.move-to @pos
    @state.age += Δt
    return @state.alive and @state.age < @state.life

  draw: ->
    p = @state.age / @state.life
    it.set-color @derive-color p
    it.ctx.global-alpha = 1 - p
    it.rect [@pos.0 - @w/2, board-size.1 ], [ @w, board-size.1 - @pos.1 ]
    it.ctx.global-alpha = 1
    #@box.draw it

