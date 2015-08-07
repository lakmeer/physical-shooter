
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
    -> "rgb(#{ 255 - floor it * 255 }, #{ 128 - floor it * 128 }, 0)"
    -> "rgb(0, #{ 230 - floor it * 230 }, 0)"
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
      power: 40

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
    #@box.draw it


#
# Enemy Variant
#

export class EnemyBullet

  max-speed = 100
  range = 10
  collection-ramp-up = 5

  { board-size } = require \config

  (@pos) ->
    @vel = [0 0]
    @acc = [(100 * Math.random! - 50), -1000]

    @w     = 5
    @box   = new CollisionBox ...@pos, @w, @w

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

    speed = min dist, @collection-speed + collection-ramp-up * Δt
    @collection-speed = min max-speed, speed
    dir  = v2.norm diff
    jump = dir `v2.scale` @collection-speed
    @pos = @pos `v2.add` jump
    return true

  draw: ->
    it.set-color @derive-color!
    if @stray then it.ctx.global-alpha = 0.5
    it.circle @pos, @w
    if @stray then it.ctx.global-alpha = 1


export class Laser

  { board-size } = require \config

  ship-colors = [
    -> "rgb(#{ 255 - floor it * 255 }, 0, 0)"
    -> "rgb(0, 0, #{ 255 - floor it * 255 })"
    -> "rgb(#{ 255 - floor it * 255 }, 0, #{ 255 - floor it * 255 })"
  ]

  (@pos, @index) ->
    @w     = 10
    @box   = new CollisionBox @pos.0, 0, @w, board-size.1 * 2
    @state =
      alive: yes
      age: 0
      life: 1
      power: 100

  impact: (target, Δt) ->  # Assume target has compatible component
    damage-this-tick = @state.power * Δt
    target.damage.health -= damage-this-tick
    target.vel.1 += 10  # knockback
    @state.spent += damage-this-tick
    @state.hit = true

  derive-color: (p) ->
    ship-colors[@index] p

  update: (Δt, pos) ->
    @pos.0 = pos.0
    @pos.1 = pos.1
    @box.move-x @pos.0
    @state.age += Δt
    return @state.alive and @state.age < @state.life

  draw: ->
    p = @state.age / @state.life
    it.set-color @derive-color p
    it.ctx.global-alpha = 1 - p
    it.rect [@pos.0 - @w/2, board-size.0 ], [ @w, board-size.0 * 2 ]
    it.ctx.global-alpha = 1
    #@box.draw it

