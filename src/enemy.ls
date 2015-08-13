
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
  fire-rate = 0.6
  bullet-speed = 200
  sprite-size = [ 20, 20 ]
  sprite-offset = sprite-size `v2.scale` 0.5
  move-acc = 5
  idle-rotate-speed = 1
  big-idle-rotate-speed = 2

  (pos = [0 0]) ->
    @physics = new Physics p:pos, a:[0 -50 - rnd 50], f:0.95
    @collider = new RadialCollider pos.0, pos.1, 10
    @type = \small
    @bullets = []
    @box = @collider
    @palette = Palette.enemy
    @pod = null

    # Damage component
    @damage =
      health: 30
      max-hp: 30
      alive: yes

    @fire-timer  = new Timer fire-rate
    #@fire-timer.current = Math.random! * fire-rate
    @fire-target = null
    @wreckage-sprite = sprite \/assets/chunk-enemy.svg, 100
    @fire-timer.reset!
    @fire-timer.current = random-range 0, fire-rate

    @phase = 0
    @rotate-dir = Math.sign Math.random!

    @stray-limit = 50

  claim-for-player: -> # Not used

  update: (Δt, time) ->
    @bullets := @bullets.filter (.update Δt)

    phase-change = if @type is \large then big-idle-rotate-speed else idle-rotate-speed
    @phase += Δt * phase-change * @rotate-dir

    while @bullets.length > @stray-limit
      @bullets.shift!

    @fire-timer.update Δt
    #@point-at-target @fire-target

    @rotation = @phase

    if @fire-timer.elapsed and @fire-target
      @shoot-at @fire-target
      @fire-timer.reset!

    @physics.update Δt
    @collider.move-to @physics.pos

    # Check if target died and we're just remembering it's dead object
    if not @fire-target?.alive
      @fire-target = null

    # Move toward pod center
    if @pod
      @physics.set-acc (@pod.center `v2.sub` @physics.pos) `v2.scale` move-acc

  assign-target: (target) ->
    @fire-target = target

  assign-pod: (pod) ->
    @pod = pod

  set-move-target: (pos) ~>
    @move-target = pos

  point-at-target: (target = @fire-target) ->
    if target
      @rotation = @physics.get-bearing-to target.physics.pos

  move-to: (pos) ->
    @physics.pos <<< pos
    @collider.move-to pos

  draw: (ctx) ->
    return if not @damage.alive
    @bullets.map (.draw ctx)
    ctx.sprite small, @physics.pos, sprite-size, offset: sprite-offset, rotation: @rotation
    #@collider.draw ctx

  shoot-at: (target) ->
    bearing = v2.norm target.physics.pos `v2.sub` @physics.pos
    bullet = new EnemyBullet this, @physics.pos
    bullet.physics.set-vel bearing `v2.scale` bullet-speed
    @bullets.push bullet

  # Deprecated
  confine-to-bounds: ->
    bord-z = board-size.1 * 0.5
    if @physics.pos.0 >  board-size.0 - border then @physics.pos.0 =  board-size.0 - border
    if @physics.pos.0 < -board-size.0 + border then @physics.pos.0 = -board-size.0 + border
    if @physics.pos.1 >  board-size.1 - border then @physics.pos.1 =  board-size.1 - border
    if @physics.pos.1 < -board-size.1 + bord-z then @physics.pos.1 = -board-size.1 + bord-z


#
# Big Version
#

export class BigEnemy extends Enemy

  { board-size } = require \config

  border = 10
  aspect = 71 / 100
  fire-rate = 0.05
  sprite-size = [ 50, 50 ]
  bullet-speed = 200
  sprite-offset = sprite-size `v2.scale` 0.5

  (pos = [0 0]) ->
    @w = 40
    super ...
    @type = \large
    @physics.fri = 0.95
    @collider = new RadialCollider pos.0, pos.1, 25

    # Damage component
    @damage =
      health: 50
      max-hp: 50
      alive: yes

    @fire-timer  = new Timer fire-rate
    @wreckage-sprite = sprite \/assets/chunk-enemy.svg, 100
    @stray-limit = 500

  move-to: (pos) ->
    @physics.move-to pos
    @box.move-to pos

  draw: (ctx) ->
    return if not @damage.alive
    @bullets.map (.draw ctx)
    ctx.sprite medium, @physics.pos, sprite-size, offset: sprite-offset, rotation: @rotation
    #@collider.draw ctx

  shoot-at: (target) ->
    jiggle    = [ (random-range -10, 10), (random-range -10, 10) ]
    left-pos  = [ @physics.pos.0 + @w/3, @physics.pos.1 ]
    right-pos = [ @physics.pos.0 - @w/3, @physics.pos.1 ]

    left-bearing  = v2.norm (jiggle `v2.add` target.physics.pos) `v2.sub` left-pos
    right-bearing = v2.norm (jiggle `v2.add` target.physics.pos) `v2.sub` right-pos

    bullet = new EnemyBullet this, left-pos
    bullet.physics.vel = left-bearing `v2.scale` bullet-speed
    bullet.alt = true
    @bullets.push bullet

    bullet = new EnemyBullet this, right-pos
    bullet.physics.vel = right-bearing `v2.scale` bullet-speed
    bullet.alt = true
    @bullets.push bullet

