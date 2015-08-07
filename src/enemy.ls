
{ id, log, box, floor, physics, rnd, v2 } = require \std

{ CollisionBox } = require \./collision-box

{ EnemyBullet } = require \./bullet

{ sprite } = require \./sprite


small  = sprite \/assets/enemy-small.svg, 200
medium = sprite \/assets/enemy-med.svg, 200


#
# Enemy
#
# Autonomous, computer-controlled version of Ship
# Idea: injected controller class - cpu vs human
#

export class Enemy

  { board-size } = require \config

  border = 10
  fire-rate = 0.4

  sprite-size = [ 20, 20 ]
  sprite-offset = sprite-size `v2.scale` 0.5

  (@pos = [0 0]) ->
    @box = new CollisionBox @pos.0, @pos.1, 10, 10
    @bullets = []

    @vel = [0 0]
    @acc = [0 -50 - rnd 50]

    @friction = 0.95

    # Damage component
    @damage =
      health: 10
      max-hp: 10
      alive: yes

    @fire-timer =
      target-time: fire-rate
      current-time: 0

    @fire-target = null

    @wreckage-sprite = sprite \/assets/chunk-enemy.svg, 100

  update: (Δt, time) ->
    @bullets := @bullets.filter (.update Δt)
    @fire-timer.current-time += Δt

    if @fire-timer.current-time >= @fire-timer.target-time
      @fire-timer.current-time %= @fire-timer.target-time
      if @fire-target
        @shoot-at @fire-target.pos

    physics this, Δt
    @confine-to-bounds!
    @box.move-to @pos

  confine-to-bounds: ->
    if @pos.0 >  board-size.0 - border then @pos.0 =  board-size.0 - border
    if @pos.0 < -board-size.0 + border then @pos.0 = -board-size.0 + border
    if @pos.1 >  board-size.1 - border then @pos.1 =  board-size.1 - border
    if @pos.1 < -board-size.1 + border + 50 then @pos.1 = -board-size.1 + border + 50

  move-to: (@pos) ->
    @box.move-to @pos

  draw: (ctx) ->
    return if not @damage.alive
    @bullets.map (.draw ctx)
    ctx.sprite small, @pos, sprite-size, sprite-offset

  shoot-at: (pos) ->
    xx = pos.0 - @pos.0
    yy = pos.1 - @pos.1
    bearing = v2.norm pos `v2.sub` @pos

    bullet = new EnemyBullet [ @pos.0 + 0.04, @pos.1 ]
    bullet.vel = bearing `v2.scale` 100
    bullet.acc = [ 0 0 ]

    @bullets.push bullet



export class BigEnemy

  { board-size } = require \config

  border = 10
  fire-rate = 0.1

  aspect =  71 / 100

  sprite-size = [ 50, 50 * aspect ]
  sprite-offset = sprite-size `v2.scale` 0.5

  (@pos = [0 0]) ->
    log \new \BigEnemy
    @box = new CollisionBox @pos.0, @pos.1, 50, 30
    @bullets = []

    @vel = [0 0]
    @acc = [0 -50 - rnd 50]

    @friction = 0.95

    # Damage component
    @damage =
      health: 100
      max-hp: 100
      alive: yes

    @fire-timer =
      target-time: fire-rate
      current-time: 0

    @fire-target = null

    @wreckage-sprite = sprite \/assets/chunk-enemy.svg, 100

  update: (Δt, time) ->
    @bullets := @bullets.filter (.update Δt)
    @fire-timer.current-time += Δt

    if @fire-timer.current-time >= @fire-timer.target-time
      @fire-timer.current-time %= @fire-timer.target-time
      if @fire-target
        @shoot-at @fire-target.pos

    physics this, Δt
    @confine-to-bounds!
    @box.move-to @pos

  confine-to-bounds: ->
    if @pos.0 >  board-size.0 - border then @pos.0 =  board-size.0 - border
    if @pos.0 < -board-size.0 + border then @pos.0 = -board-size.0 + border
    if @pos.1 >  board-size.1 - border then @pos.1 =  board-size.1 - border
    if @pos.1 < -board-size.1 + border + 50 then @pos.1 = -board-size.1 + border + 50

  move-to: (@pos) ->
    @box.move-to @pos

  draw: (ctx) ->
    return if not @damage.alive
    @bullets.map (.draw ctx)
    ctx.sprite medium, @pos, sprite-size, sprite-offset

  shoot-at: (pos) ->
    xx = pos.0 - @pos.0
    yy = pos.1 - @pos.1
    bearing = v2.norm pos `v2.sub` @pos

    bullet = new EnemyBullet [ @pos.0 + 0.04, @pos.1 ]
    bullet.vel = bearing `v2.scale` 100
    bullet.acc = [ 0 0 ]
    @bullets.push bullet

    bullet = new EnemyBullet [ @pos.0 - 0.04, @pos.1 ]
    bullet.vel = bearing `v2.scale` 100
    bullet.acc = [ 0 0 ]
    @bullets.push bullet



