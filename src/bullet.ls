
{ id, log, min, floor, v2 } = require \std

{ CollisionBox } = require \./collision-box


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
  ]

  (@pos, @index) ->
    @vel = [0 0]
    @acc = [(100 * Math.random! - 50), 1000]
    @w     = 2
    @box   = new CollisionBox ...@pos, @w, @w
    @state =
      alive: yes
      hit: no
      spent: 0
      quota: 8
      power: 200

  impact: (target, Δt) ->  # Assume target has compatible component
    damage-this-tick = @state.power * Δt
    target.damage.health -= damage-this-tick
    target.vel.1 += 10  # knockback
    @state.spent += damage-this-tick
    @state.hit = true

  derive-color: ->
    p = @state.spent/@state.quota
    ship-colors[@index] p

  update: (Δt) ->
    @vel = (@acc `v2.scale` Δt) `v2.add` @vel
    @pos = (@vel `v2.scale` Δt) `v2.add` @pos `v2.add` (@acc `v2.scale` (0.5 * Δt * Δt))
    @box.move-to @pos
    @state.alive = @pos.1 <= board-size.1 * 1.5
    return @state.alive and @state.spent <= @state.quota

  draw: ->
    it.set-color @derive-color!
    it.rect [@pos.0 - @w/2, @pos.1 + @w/2], [ @w, @w * (3 + @vel.1/100) ]
    @box.draw it


#
# Enemy Variant
#

export class EnemyBullet

  max-speed = 5
  range = 10
  collection-ramp-up = 10

  { board-size } = require \config

  (@pos) ->
    @vel = [0 0]
    @acc = [(100 * Math.random! - 50), -1000]
    @w     = 5
    @box   = new CollisionBox ...@pos, @w, @w
    @state =
      alive: yes
      hit: no
      spent: 0
      quota: 1
      power: 25
    @stray = no
    @friction = 1
    @color = \white
    @collection-speed = 0

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

    @collection-speed += collection-ramp-up * Δt

    if dist < range
      owner.collect this
      return false

    dir  = v2.norm diff
    @pos = @pos `v2.add` (dir `v2.scale` (@collection-speed `min` max-speed))

    return true

  draw: ->
    it.set-color @derive-color!
    if @stray then it.ctx.global-alpha = 0.5
    it.circle @pos, @w
    if @stray then it.ctx.global-alpha = 1

