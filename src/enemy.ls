
{ id, log, box, floor, physics, rnd, random-range, v2 } = require \std

{ RadialCollider } = require \./collider
{ EnemyBullet }    = require \./bullet
{ Physics }        = require \./physics
{ Timer }          = require \./timer

{ sprite }  = require \./sprite

Palette = require \./player-palettes

small  = sprite \/assets/enemy-small.svg, 200
medium = sprite \/assets/enemy-med.svg,   200


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

  (pos = [0 0]) ->
    @physics = new Physics p:pos, a:[0 -50 - rnd 50], f:0.95
    @collider = new RadialCollider pos.0, pos.1, 10
    @type = \small
    @bullets = []
    @box = @collider
    @palette = Palette.enemy

    # Damage component
    @damage =
      health: 10
      max-hp: 10
      alive: yes

    @fire-timer  = new Timer fire-rate
    @fire-target = null
    @wreckage-sprite = sprite \/assets/chunk-enemy.svg, 100

  update: (Δt, time) ->
    @bullets := @bullets.filter (.update Δt)
    @fire-timer.update Δt
    @point-at-target @fire-target

    if @fire-timer.elapsed and @fire-target
      @shoot-at @fire-target
      @fire-timer.reset!

    @physics.update Δt
    @confine-to-bounds!
    @collider.move-to @physics.pos

  point-at-target: (target = @fire-target) ->
    if target
      @rotation = @physics.get-bearing-to target.physics.pos

  confine-to-bounds: ->
    bord-z = board-size.1 * 0.5
    if @physics.pos.0 >  board-size.0 - border then @physics.pos.0 =  board-size.0 - border
    if @physics.pos.0 < -board-size.0 + border then @physics.pos.0 = -board-size.0 + border
    if @physics.pos.1 >  board-size.1 - border then @physics.pos.1 =  board-size.1 - border
    if @physics.pos.1 < -board-size.1 + bord-z then @physics.pos.1 = -board-size.1 + bord-z

  move-to: (pos) ->
    @physics.pos <<< pos
    @collider.move-to pos

  draw: (ctx) ->
    return if not @damage.alive
    @bullets.map (.draw ctx)
    ctx.sprite small, @physics.pos, sprite-size, offset: sprite-offset, rotation: @rotation

  shoot-at: (target) ->
    bearing = v2.norm target.physics.pos `v2.sub` @physics.pos
    bullet = new EnemyBullet this, @physics.pos
    bullet.physics.set-vel bearing `v2.scale` bullet-speed
    @bullets.push bullet


#
# Big Version
#

export class BigEnemy extends Enemy

  { board-size } = require \config

  border = 10
  aspect = 71 / 100
  fire-rate = 0.05
  sprite-size = [ 50, 50 * aspect ]
  bullet-speed = 400
  sprite-offset = sprite-size `v2.scale` 0.5

  (pos = [0 0]) ->
    @w = 40
    super ...
    @type = \large
    @physics.fri = 0.95

    # Damage component
    @damage =
      health: 100
      max-hp: 100
      alive: yes

    @fire-timer  = new Timer fire-rate
    @wreckage-sprite = sprite \/assets/chunk-enemy.svg, 100

  move-to: (pos) ->
    @physics.move-to pos
    @box.move-to pos

  draw: (ctx) ->
    return if not @damage.alive
    @bullets.map (.draw ctx)
    ctx.sprite medium, @physics.pos, sprite-size, offset: sprite-offset, rotation: @rotation

  shoot-at: (target) ->
    jiggle    = [ (random-range -10, 10), (random-range -10, 10) ]
    left-pos  = [ @physics.pos.0 + @w/3, @physics.pos.1 ]
    right-pos = [ @physics.pos.0 - @w/3, @physics.pos.1 ]

    left-bearing  = v2.norm (jiggle `v2.add` target.physics.pos) `v2.sub` left-pos
    right-bearing = v2.norm (jiggle `v2.add` target.physics.pos) `v2.sub` right-pos

    bullet = new EnemyBullet this, left-pos
    bullet.physics.vel = left-bearing `v2.scale` bullet-speed
    @bullets.push bullet

    bullet = new EnemyBullet this, right-pos
    bullet.physics.vel = right-bearing `v2.scale` bullet-speed
    @bullets.push bullet

