
# Require

{ id, log, min, v2, rnd, pi, floor, delay, wrap, limit, random-from } = require \std

{ FrameDriver } = require \./frame-driver
{ Blitter }     = require \./blitter
{ BinSpace }    = require \./bin-space
{ Timer, OneShotTimer }       = require \./timer

{ Player }            = require \./player
{ Backdrop }          = require \./backdrop
{ Enemy, BigEnemy }   = require \./enemy
{ CollectableStream } = require \./collectable-stream

{ EffectsDriver }     = require \./effects-driver
{ ScreenShake }       = require \./screen-shake
{ Explosion }         = require \./explosion
{ Wreckage }          = require \./wreckage
{ EnemySpawnEffect }  = require \./enemy-spawn-effect
{ PlayerSpawnEffect } = require \./player-spawn-effect

{ LocalPilot, AutomatedPilot, WebsocketPilot } = require \./pilot


# Config

{ board-size, time-factor } = require \config


# Init

blast-force        = 20000
blast-force-large  = 100000
beam-attract-force = -100000
repulse-force      = 20000
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

pilots  = []
players = []
enemies = []
pickups = []


pod-center = [0 0]

main-canvas.install document.body

wave-size = do (n = start-wave-size, x = 0) ->*
  while true
    yield [ n += 1, floor x += 0.2 ]

wave-complete-timer = new OneShotTimer 3


# Homeless functions

ids = -> if it is 0 then 0 else 1 / (it*it)
idd = -> if it is 0 then 0 else 1 / (it)

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

  effects.push new EnemySpawnEffect x, y

  pod-center := [ x, y ]

  for i from 0 til small
    enemy = new Enemy [ x, y ]
    enemy.set-move-target pod-center
    enemies.push enemy

  for i from 0 til big
    enemy = new BigEnemy [ x, y ]
    enemy.set-move-target pod-center
    enemies.push enemy


check-destroyed = (enemy, owner, Δt) ->
  if enemy.damage.health <= 0 and enemy.damage.alive
    enemy.damage.alive = no
    shaker.trigger 10, 0.2
    pickups.push new CollectableStream enemy.bullets, owner
    effects.push new Explosion enemy.physics.pos, if enemy.type is \large then 2 else 1
    effects.push new Wreckage enemy.physics.pos, enemy.wreckage-sprite
    force = if enemy.type is \large then blast-force-large else blast-force
    emit-force-blast force, enemy, enemies, Δt


de-crowd = (self, others) ->
  max-speed = 0.5
  effective-distance = if self.type is \large then 100 else 25
  for other in others
    diff = v2.sub other.physics.pos, self.physics.pos
    dist = v2.hyp diff
    dir  =  diff `v2.scale` max-speed
    if dist < effective-distance
      x = dir.0 * max-speed * (dist/effective-distance)
      y = dir.1 * max-speed * (dist/effective-distance)
      self.physics.vel.0 -= x - 0.5 + rnd 1
      self.physics.vel.1 -= y - 0.5 + rnd 1
      #other.physics.vel.0 += x * 1.5 - 0.5 + rnd 1
      #other.physics.vel.1 += y * 1.0 - 0.5 + rnd 1


# Tick functions

play-test-frame = (Δt, time) ->

  # Scale time if needed
  Δt   *= time-factor
  time *= time-factor

  # Update scene features
  backdrop.update Δt, time, main-canvas.canvas
  shaker.update Δt
  effects.update Δt, time

  # Update autonomous moving things
  pickups := pickups.filter (.update Δt, time)

  # Prepare for simulation
  enemy-bin-space.clear!
  crowd-bin-space.clear!
  player-bin-space.clear!

  # Move the pod
  pod-center.0 = board-size.0 * 0.8 * Math.sin time*1/5
  pod-center.1 = board-size.1 * 0.8 * Math.cos time*3/5

  # Populate player bullet bin space
  for player in players
    player.update Δt, time
    for bullet in player.bullets
      enemy-bin-space.assign-bin bullet

  # Spawn new enemies if we've run out
  if enemies.length < 1
    wave-complete-timer.begin!
    wave-complete-timer.update Δt

    #log wave-complete-timer.get-progress!
    if wave-complete-timer.elapsed
      new-wave wave-size

  # Update enemies and their bullets
  for enemy in enemies
    crowd-bin-space.assign-bin enemy

    if enemy.damage.alive
      enemy.update Δt, time

      if not enemy.fire-target
        enemy.assign-target random-from players

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

  # Update players and their bullets
  players := players.filter (player) ->

    # Check for collisions on the black plane
    for other in player-bin-space.get-bin-collisions player
      if player.damage.health > 0 and other.collider.intersects player.collider
        other.impact? player, Δt

    if player.state.forcefield-active
      emit-force-blast repulse-force, player, enemies, Δt
      shaker.trigger 1, 0.1

    if player.state.vortex-active
      emit-beam-blast beam-attract-force, player, enemies, Δt
      shaker.trigger 2, 0.1

    if player.damage.health <= 0 and player.alive
      player.kill!
      for enemy in enemies
        if enemy.fire-target is player
          enemy.fire-target = null

    for laser in player.lasers
      shaker.trigger 10 * laser.strength!, 0.1

      for enemy in enemies
        if laser.collider.intersects enemy.collider
          laser.impact enemy, Δt
          enemy.last-hit = player
          check-destroyed enemy, player, Δt

    if not player.alive
      effects.push new Explosion player.physics.pos, 3
      player.cleanup!
      shaker.trigger 10, 1
      return false

    return true


  enemies := enemies.filter (.damage.alive)


# Standard renderer

render-frame = (frame) ->
  main-canvas.clear!
  main-canvas.set-offset shaker.get-offset!
  backdrop.set-offset shaker.get-offset!
  backdrop.draw main-canvas
  effects.draw main-canvas
  effects-b.draw main-canvas

  main-canvas.rect pod-center, [ 20, 20 ]

  #enemy-bin-space.draw main-canvas
  #player-bin-space.draw main-canvas
  #crowd-bin-space.draw main-canvas

  pickups.map (.draw main-canvas)
  enemies.map (.draw main-canvas)

  # This order is important
  players.map (.draw-projectiles main-canvas)
  players.map (.draw-special-effects main-canvas)
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


# Multiplayer

autopilot-time = 0
last-time = Date.now!


# Server callbacks

on-connect = ->
  player-server.emit \is-master

on-player-joined = (index) ->
  new-player = new Player index
  pilots[index] = new WebsocketPilot new-player
  effects.push new PlayerSpawnEffect new-player, -> players.push new-player

on-player-disconnected = (index) ->
  pilots[index]?.kill-player!
  delete pilots[index]

on-player-update = (index, ...data) ->
  autopilot-time := last-time - Date.now!/1000
  pilots[index]?.receive-update-data ...data, autopilot-time


# Init - make connection to player relay server

IO = require \socket.io-client

player-server = IO window.location.hostname + \:9999
player-server.on \connect, on-connect
player-server.on \pj, on-player-joined
player-server.on \pd, on-player-disconnected
player-server.on \p,  on-player-update


# Debug Controls

add-local-player = (n) ->
  new-player = new Player n
  pilots[n] = new LocalPilot new-player
  effects.push new PlayerSpawnEffect new-player, -> players.push new-player
  player-server.emit 'master-join', n
  return new-player


document.add-event-listener \keydown, ({ which }:event) ->
  switch which
  | ESCAPE => frame-driver.toggle!
  | ENTER  =>
      for i from 0 to 6
        if not pilots[i]
          add-local-player i
          event.prevent-default!
          return false
  | _  => return event
  event.prevent-default!
  return false


if window.location.hash is \#debug
  for let i from 0 to 5
    delay 200 * i, ->
      player = add-local-player i
      player.move-towards [ board-size.0 * 0.06 * (-2.5 - 13 + i), 0.8 * -board-size.1 ]
      player.activate-vortex!
  for let i from 0 to 5
    delay 1400 + 200 * i, ->
      player = add-local-player i
      player.move-towards [ board-size.0 * 0.06 * (-2.5 - 0 + i), 0.8 * -board-size.1 ]
      player.activate-vortex!




#
# DEBUG TICK FUNCTIONS
#
# Non-game tick functions for testing engine features
#


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
    if player.forcefield-active and alive player
      emit-force-blast repulse-force, player, enemies, Δt
      shaker.trigger 10/player-count, 0.1


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
    player.move-towards [ -board-size.0/3 * 2.5 + board-size.0/3 * i, -board-size.1*0.85 ]


#
# END DEBUG TICK FUNCTIONS
#



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

