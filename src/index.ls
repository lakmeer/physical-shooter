
# Require

{ id, log, min, v2, rnd, floor, delay, wrap, limit } = require \std

{ FrameDriver } = require \./frame-driver
{ Blitter }     = require \./blitter
{ BinSpace }    = require \./bin-space
{ Timer, OneShotTimer }       = require \./timer

{ Player }            = require \./player
{ Backdrop }          = require \./backdrop
{ Enemy, BigEnemy }   = require \./enemy
{ CollectableStream } = require \./collectable-stream

{ EffectsDriver } = require \./effects-driver
{ ScreenShake }   = require \./screen-shake
{ Explosion }     = require \./explosion
{ Wreckage }      = require \./wreckage


# Config

{ board-size, time-factor } = require \config


# Init

blast-force        = 50000
blast-force-large  = 500000
beam-attract-force = -100000
repulse-force      = 5000
start-wave-size    = 10
effects-limit      = 50
player-count       = 6

shaker           = new ScreenShake
effects          = new EffectsDriver effects-limit
backdrop         = new Backdrop
main-canvas      = new Blitter
enemy-bin-space  = new BinSpace 40, 20, \white
player-bin-space = new BinSpace 40, 20, \black
crowd-bin-space  = new BinSpace 40, 20, \red

players = [ new Player i + 0 for i from 0 til player-count ]
enemies = []
pickups = []

main-canvas.install document.body

wave-size = do (n = start-wave-size, x = 1) ->*
  while true
    yield [ n += 1, floor x += 0.2 ]

wave-complete-timer = new OneShotTimer 3


# Homeless functions

ids = -> if it is 0 then 0 else 1 / (it*it)

emit-force-blast = (force, self, others, Δt) ->

  [ x, y ] = self.physics.pos

  blast = (target) ->
    xx  = x - target.physics.pos.0
    yy  = y - target.physics.pos.1
    d   = v2.dist target.physics.pos, self.physics.pos
    push = [ force * -xx * ids(d) * Δt, force * -yy * ids(d) * Δt]
    target.physics.vel = target.physics.vel `v2.add` push

  for other in others when other isnt self
    blast other
    if other.bullets
      for bullet in other.bullets
        blast bullet


emit-beam-blast = (force, self, others, Δt) ->

  [ x ] = self.physics.pos

  effective-distance = 250
  min-dist = 10

  draw = (target, push) ->
    xx  = x - target.physics.pos.0
    if Math.abs(xx) < min-dist
      target.physics.vel.0 += xx
      if push then target.physics.vel.1 *= 0.5
    else
      target.physics.vel.0 += -xx * force * Δt * ids xx


  for other in others when other isnt self
    draw other
    if other.bullets
      for bullet in other.bullets
        draw bullet, true


new-wave = (n) ->
  [ small, big ] = wave-size.next!value

  x = -board-size.0 + 10 + (rnd board-size.0 * 2 - 10)
  y = board-size.1 - rnd (board-size.1/2 - 10)

  for i from 0 til small
    enemy = new Enemy [ x, y ]
    enemy.fire-target = players.0
    enemies.push enemy

  for i from 0 til big
    enemy = new BigEnemy [ x,y ]
    enemy.fire-target = players.0
    enemies.push enemy

find-target = (enemy) ->
  if player-count is 0
    enemy.fire-target = null
  else if not players.0.dead
    enemy.fire-target = players.0

check-destroyed = (enemy, owner, Δt) ->
  if enemy.damage.health <= 0 and enemy.damage.alive
    enemy.damage.alive = no
    shaker.trigger 5, 0.2
    pickups.push new CollectableStream enemy.bullets, owner
    effects.push new Explosion enemy.physics.pos, if enemy.type is \large then 2 else 1
    effects.push new Wreckage enemy.physics.pos, enemy.wreckage-sprite
    force = if enemy.type is \large then blast-force-large else blast-force
    emit-force-blast force, enemy, enemies, Δt

de-crowd = (self, others) ->
  max-speed = 5
  effective-distance = if self.type is \large then 100 else 25
  for other in others
    diff = v2.sub other.physics.pos, self.physics.pos
    dist = v2.hyp diff
    dir  = v2.norm diff
    if dist < effective-distance
      x = dir.0 * max-speed * ( dist/effective-distance)
      y = dir.1 * max-speed * (dist/effective-distance)
      #self.vel.0 -= x - 0.5 + rnd 1
      #self.vel.1 -= y - 0.5 + rnd 1
      other.physics.vel.0 += x * 1.5 - 0.5 + rnd 1
      other.physics.vel.1 += y * 1.0 - 0.5 + rnd 1


# Tick functions

play-test-frame = (Δt, time) ->

  # Scale time if needed
  Δt   *= time-factor
  time *= time-factor

  # Update scene features
  backdrop.update Δt, time
  shaker.update Δt
  effects.update Δt, time

  # Update autonomous moving things
  pickups := pickups.filter (.update Δt, time)

  # Prepare for simulation
  enemy-bin-space.clear!
  crowd-bin-space.clear!
  player-bin-space.clear!

  # Spawn new enemies if we've run out
  if enemies.length < 1
    wave-complete-timer.begin!
    wave-complete-timer.update Δt

    #log wave-complete-timer.get-progress!
    if wave-complete-timer.elapsed
      new-wave wave-size

  # Update players and their bullets
  for player in players
    #player.dont-auto-move!
    player.update Δt, time
    for bullet in player.bullets
      enemy-bin-space.assign-bin bullet

  # Update enemies and their bullets
  for enemy in enemies
    crowd-bin-space.assign-bin enemy
    if enemy.damage.alive
      enemy.update Δt, time
      find-target enemy

      for bullet in enemy.bullets
        player-bin-space.assign-bin bullet

  # De-crowd enemies
  for enemy in enemies
    de-crowd enemy, crowd-bin-space.get-bin-collisions enemy

  # Check for collision on the white plane
  for enemy in enemies
    for other in enemy-bin-space.get-bin-collisions enemy
      if other.collider.intersects enemy.collider
        if other.impact?
          other.impact enemy, Δt
          check-destroyed enemy, other.owner, Δt

  # Check for collisions on the black plane
  for player in players
    for other in player-bin-space.get-bin-collisions player
      if player.damage.health > 0 and other.collider.intersects player.collider
        other.impact? player, Δt

    if player.forcefield-active and not player.dead
      emit-force-blast repulse-force, player, enemies, Δt
      shaker.trigger 1/player-count, 0.1

    if player.beam-vortex-active
      emit-beam-blast beam-attract-force, player, enemies, Δt
      #shaker.trigger 2/player-count, 0.1

    if player.damage.health <= 0 and not player.dead
      effects.push new Explosion player.physics.pos, 3, player.explosion-tint-color
      player.kill!
      for enemy in enemies
        enemy.fire-target = null

    for laser in player.lasers
      for enemy in enemies
        if laser.collider.intersects enemy.collider
          laser.impact enemy, Δt
          enemy.last-hit = player
          check-destroyed enemy, player, Δt


  enemies := enemies.filter (.damage.alive)


# Test explosion particles

effects-b = new EffectsDriver
scales = [ 1 2 3 4 5 ]
scale-index = -1

explosion-test-frame = (Δt, time) ->
  shaker.update Δt
  effects.update Δt, time
  effects-b.update Δt * time-factor, time * time-factor

  # TODO: Put a real timer here
  on-explosion = ->
    scale-index := wrap 0, scales.length-1, scale-index + 1
    scale = scales[scale-index]
    tint  = players[floor rnd player-count].explosion-tint-color

    effects.push   new Explosion [ -100, 0 ], scale, tint
    effects-b.push new Explosion [  100, 0 ], scale, tint


# Test forcefield effect

forcefield-test-frame = (Δt, time) ->
  player.dont-auto-move!
  player.move-to [0 0]
  backdrop.update Δt, time
  player.update Δt, time


# Test crowd avoidance

new-crowd = (n) ->
  [ small ] = wave-size.next!value
  for i from 0 til small
    pos = [ (rnd 100), (rnd 100) ]
    pos = [0 0]
    enemy = new Enemy pos
    enemies.push enemy

crowding-test-frame = (Δt, time) ->
  crowd-bin-space.clear!

  # Spawn new enemies if we've run out
  if enemies.length < 1
    new-crowd wave-size

  # Update enemies and their bullets
  for enemy in enemies
    crowd-bin-space.assign-bin enemy
    if enemy.damage.alive
      enemy.update Δt, time

  # De-crowd enemies
  for enemy in enemies
    de-crowd enemy, crowd-bin-space.get-bin-collisions enemy

  # Check for collisions on the black plane
  for player in players
    if player.forcefield-active and not player.dead
      emit-force-blast repulse-force, player, enemies, Δt
      shaker.trigger 5/player-count, 0.1


# Test laser effect

{ Laser } = require \./bullet

laser-timer = new Timer 4

laser-effect-frame = (Δt, time) ->
  shaker.update Δt
  laser-timer.update Δt

  if laser-timer.elapsed
    players.0.laser shaker
    laser-timer.reset!

  for player, i in players
    player.update Δt, time
    player.dont-auto-move!
    #player.move-to [ (-2.5 + i) * 50, -board-size.1 + 50 ]


# Test Weapon Rankings

weapons-test-frame = (Δt) ->
  for player, i in players
    player.dont-auto-move!
    player.update Δt * time-factor
    player.move-to [ -board-size.0/3 * 2.5 + board-size.0/3 * i, -board-size.1*0.85 ]


# Standard renderer

render-frame = (frame) ->
  main-canvas.clear!
  main-canvas.set-offset shaker.get-offset!
  backdrop.draw main-canvas
  effects.draw main-canvas
  effects-b.draw main-canvas

  #enemy-bin-space.draw main-canvas
  #player-bin-space.draw main-canvas
  #crowd-bin-space.draw main-canvas

  pickups.map (.draw main-canvas)
  enemies.map (.draw main-canvas)

  # This order is important
  players.map (.draw-projectiles main-canvas)
  players.map (.draw-lasers main-canvas)
  players.map (.draw-ship main-canvas)


# Listen

ENTER = 13
KEY_Z = 90
KEY_X = 88
KEY_C = 67
SPACE = 32
ESCAPE = 27

my-player-index = 0

document.add-event-listener \keydown, ({ which }:event) ->
  switch which
  | ESCAPE => frame-driver.toggle!
  | ENTER  => players.map (.unkill!)
  | SPACE  => players[my-player-index].forcefield-active = yes
  | KEY_Z  => players[my-player-index].laser shaker
  #| KEY_Z  => players.map (.laser shaker)
  | KEY_C  => players[my-player-index].beam-vortex-active = yes
  | _  => return event
  event.prevent-default!
  return false

document.add-event-listener \keyup, ({ which }:event) ->
  switch which
  | SPACE  => players[my-player-index].forcefield-active = no
  | KEY_C  => players[my-player-index].beam-vortex-active = no
  | _  => return event
  event.prevent-default!
  return false

main-canvas.canvas.add-event-listener \mousemove, ({ pageX, pageY }) ->
  player = players[my-player-index]
  mouse  = [ pageX, pageY ]
  dest   = main-canvas.screen-space-to-game-space mouse
  player.move-to dest
  player.dont-auto-move!


# Init - default play-test-frame

frame-driver = new FrameDriver
frame-driver.on-frame render-frame
frame-driver.on-tick ->
  try
    #weapons-test-frame ...
    play-test-frame ...
  catch exception
    frame-driver.stop!
    throw exception
frame-driver.start!

