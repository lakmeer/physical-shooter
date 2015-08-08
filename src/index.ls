
# Require

{ id, log, min, v2, rnd, floor, limit } = require \std

{ FrameDriver } = require \./frame-driver
{ Blitter }     = require \./blitter
{ BinSpace }    = require \./bin-space

{ Player }            = require \./player
{ Backdrop }          = require \./backdrop
{ Enemy, BigEnemy }   = require \./enemy
{ CollectableStream } = require \./collectable-stream

{ CollisionBox } = require \./collision-box
{ ScreenShake }  = require \./screen-shake
{ Explosion }    = require \./explosion
{ Wreckage }     = require \./wreckage


class EffectsDriver
  (@limit) ->
    @effects = []

  push: (effect) ->
    if @effects.length >= @limit
      @effects.shift!
    @effects.push effect

  update: (Δt, time) ->
    @effects = @effects.filter (.update Δt, time)

  draw: (ctx) ->
    @effects.map (.draw ctx)


# Config

{ board-size, time-factor } = require \config


# Game play note:
# Initialising a force weapon cost more than running it for longer -
# rapidly switching force weapons will use twoce as much as sustained use

# Init

blast-force        = 50000
blast-force-large  = 500000
attract-force      = -10000
repulse-force      = 5000
start-wave-size    = 10
bullets-per-second = 30
last-shot-time     = -1
effects-limit      = 50
player-count       = 1

wave-size = do (n = start-wave-size, x = 0) ->* while true => yield [ n += 1, floor x += 0.2 ]

shaker           = new ScreenShake
effects          = new EffectsDriver effects-limit
backdrop         = new Backdrop
main-canvas      = new Blitter
enemy-bin-space  = new BinSpace 40, 20, \white
player-bin-space = new BinSpace 40, 20, \black
crowd-bin-space  = new BinSpace 40, 20, \red

players = [ new Player i for i from 0 til player-count ]
enemies = []
pickups = []

main-canvas.install document.body



# Homeless functions

ids = -> if it is 0 then 0 else 1 / (it*it)

emit-force-blast = (force, self, others, Δt) ->

  [ x, y ] = self.pos

  blast = (target) ->
    xx  = x - target.pos.0
    yy  = y - target.pos.1
    d   = v2.dist target.pos, self.pos
    push = [ force * -xx * ids(d) * Δt, force * -yy * ids(d) * Δt]
    target.vel = target.vel `v2.add` push

  for other in others when other isnt self
    blast other
    if other.bullets
      for bullet in other.bullets
        blast bullet

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
    effects.push new Explosion enemy.pos
    effects.push new Wreckage enemy.pos, enemy.wreckage-sprite
    force = if enemy.type is \large then blast-force-large else blast-force
    emit-force-blast force, enemy, enemies, Δt

de-crowd = (self, others) ->
  max-speed = 5
  effective-distance = if self.type is \large then 100 else 25
  for other in others
    diff = v2.sub other.pos, self.pos
    dist = v2.hyp diff
    dir  = v2.norm diff
    if dist < effective-distance
      x = dir.0 * max-speed * ( dist/effective-distance)
      y = dir.1 * max-speed * (dist/effective-distance)
      #self.vel.0 -= x - 0.5 + rnd 1
      #self.vel.1 -= y - 0.5 + rnd 1
      other.vel.0 += x * 1.5 - 0.5 + rnd 1
      other.vel.1 += y * 1.0 - 0.5 + rnd 1


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
    new-wave wave-size

  # Update players and their bullets
  for player in players
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
      if other.box.intersects enemy.box
        if other.impact?
          other.impact enemy, Δt
          check-destroyed enemy, other.owner, Δt

  # Check for collisions on the black plane
  for player in players
    for other in player-bin-space.get-bin-collisions player
      if player.damage.health > 0 and other.box.intersects player.box
        other.impact? player, Δt

    if player.forcefield-active and not player.dead
      emit-force-blast repulse-force, player, enemies, Δt
      shaker.trigger 1/player-count, 0.1

    if player.damage.health <= 0 and not player.dead
      effects.push new Explosion player.pos
      player.kill!
      for enemy in enemies
        enemy.fire-target = null

    for laser in player.lasers
      for enemy in enemies
        if laser.box.intersects enemy.box
          laser.impact enemy, Δt
          enemy.last-hit = player
          check-destroyed enemy, player, Δt


  enemies := enemies.filter (.damage.alive)

  new-shot-time = floor time * bullets-per-second

  if new-shot-time > last-shot-time
    to-fire = new-shot-time - last-shot-time
    for player in players
      if not player.forcefield-active
        for i from 0 til to-fire => player.shoot!
      last-shot-time := new-shot-time

explosion-test-frame = (Δt, time) ->
  Δt   *= time-factor
  time *= time-factor

  shaker.update Δt
  effects.update Δt, time

  new-shot-time = floor time/2

  if new-shot-time > last-shot-time
    log scale = 1 + floor rnd 4
    effects.push new Explosion [ 0, 0 ], scale
    shaker.trigger scale, 1 + scale/4
    last-shot-time := new-shot-time


forcefield-test-frame = (Δt, time) ->
  player.dont-auto-move!
  player.move-to [0 0]
  backdrop.update Δt, time
  player.update Δt, time

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


render-frame = (frame) ->
  main-canvas.clear!
  main-canvas.set-offset shaker.get-offset!
  backdrop.draw main-canvas
  effects.draw main-canvas

  #enemy-bin-space.draw main-canvas
  #player-bin-space.draw main-canvas
  #crowd-bin-space.draw main-canvas

  pickups.map (.draw main-canvas)
  enemies.map (.draw main-canvas)
  players.map (.draw main-canvas)


# Listen

KEY_Z = 90
KEY_X = 88
KEY_C = 67
SPACE = 32
ESCAPE = 27

document.add-event-listener \keydown, ({ which }:event) ->
  switch which
  | SPACE  => players.map (.forcefield-active = yes)
  | ESCAPE => frame-driver.toggle!
  | KEY_Z  => players.map (.unkill!)
  | KEY_X  => players.map (.magnet-active = yes)
  | _  => return event
  event.prevent-default!
  return false

document.add-event-listener \keyup, ({ which }:event) ->
  switch which
  | SPACE => players.map (.forcefield-active = no)
  | KEY_X => players.map (.magnet-active = no)
  | _  => return event
  event.prevent-default!
  return false

main-canvas.canvas.add-event-listener \mousemove, ({ pageX, pageY }) ->
  for player, i in players
    mouse = [ pageX, pageY ]
    #if i > 0 then mouse.0 = window.inner-width - pageX
    #if i > 1 then return
    dest = main-canvas.screen-space-to-game-space mouse
    player.move-to dest
    player.dont-auto-move!


# Init

frame-driver = new FrameDriver
frame-driver.on-frame render-frame
frame-driver.on-tick explosion-test-frame
frame-driver.start!

