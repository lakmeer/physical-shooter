
# Require

{ id, log, min, tau, v2, rnd, pi, floor, delay, wrap, limit, random-from, random-range, ids, idd } = require \std

{ FrameDriver } = require \./frame-driver
{ Blitter }     = require \./blitter
{ BinSpace }    = require \./bin-space
{ Server }      = require \./server

{ Player }            = require \./player
{ WavePod }           = require \./wave-pod
{ Backdrop }          = require \./backdrop
{ CollectableStream } = require \./collectable-stream

{ EffectsDriver } = require \./effects-driver
{ ScreenShake }   = require \./screen-shake
{ Explosion }     = require \./explosion
{ Wreckage }      = require \./wreckage
{ BulletImpact }  = require \./bullet-impact
{ Histogram }     = require \./histogram


# Config

{ board-size, time-factor } = require \config


# Init

blast-force       = 1000
blast-force-large = 4000
vortex-force      = -2000
repulsor-force    = 200
start-wave-size   = 10
effects-limit     = 50
player-count      = 6

shaker           = new ScreenShake
effects          = new EffectsDriver effects-limit
backdrop         = new Backdrop
main-canvas      = new Blitter
enemy-bin-space  = new BinSpace 40, 20, \white
player-bin-space = new BinSpace 40, 20, \black
crowd-bin-space  = new BinSpace 40, 20, \red
wave-pod         = new WavePod effects: effects
frame-driver     = new FrameDriver
histogram        = new Histogram


# State

pilots  = []
players = []
enemies = []
pickups = []

server = new Server { effects }, -> players.push it


# Wave callback


# Homeless functions

emit-force-blast = (force, self, others, Δt) ->
  [ x, y ] = self.physics.pos

  effective-distance = 100

  blast = (target) ->
    xx  = Math.sign target.physics.pos.0 - x
    yy  = Math.sign target.physics.pos.1 - y
    d   = v2.dist target.physics.pos, self.physics.pos

    if d > effective-distance then return
    push = [ force * ids(d) * xx * Δt, force * ids(d) * yy * Δt]
    target.physics.vel = target.physics.vel `v2.add` push

  for other in others when other isnt self
    blast other
    if other.bullets
      for bullet in other.bullets
        blast bullet


repulsor = (player, targets, Δt) ->
  [ x, y ] = player.physics.pos
  force = repulsor-force
  effective-distance = 100
  capture-radius = effective-distance / 2
  capture-velocity = 100

  blast = (target) ->
    xx  = Math.sign target.physics.pos.0 - x
    yy  = Math.sign target.physics.pos.1 - y
    d   = v2.dist target.physics.pos, player.physics.pos

    if d > effective-distance then return

    push = [ force * ids(d) * xx * Δt, force * ids(d) * yy * Δt]
    target.physics.vel = target.physics.vel `v2.add` push

    if (v2.hyp target.physics.vel) < capture-velocity
      target.claim-for-player player

  for other in targets when other isnt player
    blast other
    if other.bullets
      for bullet in other.bullets
        blast bullet


vortex = (player, targets, Δt) ->
  [ x ] = player.physics.pos
  effective-distance = 250
  min-dist = 10
  force = vortex-force

  draw = (target, push) ->
    xx  = target.physics.pos.0 - x
    s   = Math.sign xx
    if Math.abs(xx) < min-dist
      target.physics.vel.0 += xx * 8
      if push then target.physics.vel.1 *= 0.5
    else
      target.physics.vel.0 += s * force * Δt * ids xx

  for other in targets when other isnt player
    draw other
    if other.bullets
      for bullet in other.bullets
        draw bullet, true



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
    dir  = v2.norm diff # `v2.scale` max-speed
    if dist < effective-distance
      x = dir.0 * max-speed * (dist/effective-distance)
      y = dir.1 * max-speed * (dist/effective-distance)
      self.physics.vel.0 -= x * 1.5 - 0.5 + rnd 1
      self.physics.vel.1 -= y * 1.0 - 0.5 + rnd 1
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

  # Fill enemies if empty
  wave-pod.update Δt, time, enemies

  # Populate player bullet bin space
  for player in players
    player.update Δt, time
    for bullet in player.bullets
      enemy-bin-space.assign-bin bullet

  # Update enemies and their bullets
  for enemy in enemies
    crowd-bin-space.assign-bin enemy

    if enemy.damage.alive
      enemy.update Δt, time

      if not enemy.fire-target
        enemy.assign-target random-from players

      for bullet in enemy.bullets
        if bullet.claimed
          enemy-bin-space.assign-bin bullet
        else
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
          effects.push new BulletImpact other
          check-destroyed enemy, other.owner, Δt

  # Update players and their bullets
  players := players.filter (player) ->

    player.suppress-fire-if wave-pod.is-downtime!

    # Check for collisions on the black plane
    for other in player-bin-space.get-bin-collisions player
      if player.damage.health > 0 and other.collider.intersects player.collider
        other.impact? player, Δt

    # Update projectiles
    if player.state.forcefield-active
      repulsor player, enemies, Δt
      shaker.trigger 1, 0.1

    if player.state.vortex-active
      vortex player, enemies, Δt
      shaker.trigger 2, 0.1

    for laser in player.lasers
      shaker.trigger 10 * laser.strength!, 0.1
      for enemy in enemies
        if laser.collider.intersects enemy.collider
          laser.impact enemy, Δt
          enemy.last-hit = player
          check-destroyed enemy, player, Δt

    # Check for death
    if player.damage.health <= 0 and player.alive
      player.kill!
      effects.push new Explosion player.physics.pos, 3
      player.cleanup!
      shaker.trigger 10, 1

      for enemy in enemies
        if enemy.fire-target is player
          enemy.fire-target = null

    return player.alive


  # Cull destroyed enemies
  enemies := enemies.filter (.damage.alive)

  histogram.set-wave  wave-pod.wave-number
  histogram.update Δt, time

  server.send-charge-level players


# Standard renderer

render-frame = (frame) ->
  main-canvas.clear!
  main-canvas.set-offset shaker.get-offset!
  backdrop.set-offset shaker.get-offset!
  backdrop.draw main-canvas

  effects.draw main-canvas

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
  #players.map (.draw-hud main-canvas)

  histogram.draw main-canvas, wave-pod.downtime-progress!, players


#
# Setup
#

# Make connection to player relay server

if false
  for i from 0 to 5
    player = server.add-autonomous-player-at-next-open-slot!
    player.charge = 10000
    player.score = floor rnd 10000
    player.set-weapon-level 9


# Debug Controls

ENTER = 13
SPACE = 32
ESCAPE = 27

document.add-event-listener \keydown, ({ which }:event) ->
  switch which
  | ESCAPE => frame-driver.toggle!
  | ENTER  => server.add-local-player-at-next-open-slot!
  | _  => return event
  event.prevent-default!
  return false


# Init - default play-test-frame
frame-driver.on-frame render-frame
frame-driver.on-tick play-test-frame
frame-driver.start!

# Init - assign
main-canvas.install document.body


