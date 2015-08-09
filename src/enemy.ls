
{ id, log, box, floor, physics, rnd, v2 } = require \std

{ CollisionRadius } = require \./collision-box

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
  fire-rate = 0.5
  bullet-speed = 200
  sprite-size = [ 20, 20 ]
  sprite-offset = sprite-size `v2.scale` 0.5

  (@pos = [0 0]) ->
    @box = new CollisionRadius @pos.0, @pos.1, 10
    @vel = [0 0]
    @acc = [0 -50 - rnd 50]
    @type = \small
    @bullets = []
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
    @point-at-target @fire-target

    if @fire-timer.current-time >= @fire-timer.target-time
      @fire-timer.current-time %= @fire-timer.target-time
      if @fire-target
        @shoot-at @fire-target.pos

    physics this, Δt
    @confine-to-bounds!
    @box.move-to @pos

  point-at-target: (target = @fire-target) ->
    if target
      xx = target.pos.0 - @pos.0
      yy = target.pos.1 - @pos.1
      @rotation = Math.asin -xx/v2.hyp [ xx, yy ]

  confine-to-bounds: ->
    bord-z = board-size.1 * 0.5
    if @pos.0 >  board-size.0 - border then @pos.0 =  board-size.0 - border
    if @pos.0 < -board-size.0 + border then @pos.0 = -board-size.0 + border
    if @pos.1 >  board-size.1 - border then @pos.1 =  board-size.1 - border
    if @pos.1 < -board-size.1 + bord-z then @pos.1 = -board-size.1 + bord-z

  move-to: (@pos) ->
    @box.move-to @pos

  draw: (ctx) ->
    return if not @damage.alive
    @bullets.map (.draw ctx)
    ctx.sprite small, @pos, sprite-size, offset: sprite-offset, rotation: @rotation
    #@box.draw ctx

  shoot-at: (pos) ->
    xx = pos.0 - @pos.0
    yy = pos.1 - @pos.1
    bearing = v2.norm pos `v2.sub` @pos

    bullet = new EnemyBullet [ @pos.0 + 0.04, @pos.1 ]
    bullet.vel = bearing `v2.scale` bullet-speed
    bullet.acc = [ 0 0 ]

    @bullets.push bullet



export class BigEnemy

  { board-size } = require \config

  border = 10
  aspect = 71 / 100
  fire-rate = 0.05
  sprite-size = [ 50, 50 * aspect ]
  bullet-speed = 200
  sprite-offset = sprite-size `v2.scale` 0.5

  (@pos = [0 0]) ->
    @w = 40
    @box = new CollisionRadius @pos.0, @pos.1, @w
    @bullets = []
    @type = \large
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
    @rotation = 0

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
    bord-z = board-size.1 * 0.5
    if @pos.0 >  board-size.0 - border then @pos.0 =  board-size.0 - border
    if @pos.0 < -board-size.0 + border then @pos.0 = -board-size.0 + border
    if @pos.1 >  board-size.1 - border then @pos.1 =  board-size.1 - border
    if @pos.1 < -board-size.1 + bord-z then @pos.1 = -board-size.1 + bord-z

  move-to: (@pos) ->
    @box.move-to @pos

  draw: (ctx) ->
    return if not @damage.alive
    @bullets.map (.draw ctx)
    ctx.sprite medium, @pos, sprite-size, offset: sprite-offset, rotation: @rotation
    #@box.draw ctx

  shoot-at: (pos) ->
    xx = pos.0 - @pos.0
    yy = pos.1 - @pos.1
    bearing = v2.norm pos `v2.sub` @pos
    @rotation = Math.asin -xx/v2.hyp [ xx, yy ]

    bullet = new EnemyBullet [ @pos.0 + @w/2, @pos.1 ]
    bullet.vel = bearing `v2.scale` bullet-speed
    bullet.acc = [ 0 0 ]
    @bullets.push bullet

    bullet = new EnemyBullet [ @pos.0 - @w/2, @pos.1 ]
    bullet.vel = bearing `v2.scale` bullet-speed
    bullet.acc = [ 0 0 ]
    @bullets.push bullet

