
{ id, log, floor, v2 } = require \std

{ CollisionBox } = require \./collision-box


#
# Bullet
#
# Blam
#

export class Bullet

  { board-size } = require \config

  (@pos) ->
    @vel = [0 0]
    @acc = [(100 * Math.random! - 50), 1000]
    @w     = 2
    @box   = new CollisionBox ...@pos, @w, @w
    @state =
      alive: yes
      hit: no
      spent: 0
      quota: 4
      power: 50

  impact: (target, Δt) ->  # Assume target has compatible component
    damage-this-tick = @state.power * Δt
    target.damage.health -= damage-this-tick
    target.vel.1 += 10  # knockback
    @state.spent += damage-this-tick
    @state.hit = true

  derive-color: ->
    "rgb(255,#{ 255 - floor 255 * @state.spent/@state.quota },0)"

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

  impact: (target, Δt) ->  # Assume target has compatible component
    damage-this-tick = @state.power * Δt
    target.damage.health -= damage-this-tick
    @state.spent += damage-this-tick
    @state.hit = true

  derive-color: ->
    if @stray
      \green
    else
      "rgb(#{ 255 - floor 255 * @state.spent/@state.quota },255,255)"

  update: (Δt) ->
    @vel = (@acc `v2.scale` Δt) `v2.add` @vel `v2.scale` @friction
    @pos = (@vel `v2.scale` Δt) `v2.add` @pos `v2.add` (@acc `v2.scale` (0.5 * Δt * Δt))
    @box.move-to @pos
    @state.alive = @pos.1 <= board-size.1 * 1.5 and @pos.1 >= -board-size.1 * 1.5
    return @state.alive and @state.spent <= @state.quota

  draw: ->
    it.set-color @derive-color!
    it.circle @pos, @w

