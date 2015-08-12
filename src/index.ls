
# Require

{ id, log, min, tau, v2, rnd, pi, floor, delay, wrap, limit, random-from, random-range, ids, idd } = require \std

{ FrameDriver } = require \./frame-driver
{ Blitter }     = require \./blitter
{ BinSpace }    = require \./bin-space
{ Timer, OneShotTimer }       = require \./timer

{ Player }            = require \./player
{ Backdrop }          = require \./backdrop
{ CollectableStream } = require \./collectable-stream

{ EffectsDriver }     = require \./effects-driver
{ ScreenShake }       = require \./screen-shake
{ Explosion }         = require \./explosion
{ Wreckage }          = require \./wreckage
{ EnemySpawnEffect }  = require \./enemy-spawn-effect
{ PlayerSpawnEffect } = require \./player-spawn-effect


# Config

{ board-size, time-factor } = require \config


# Bespoke classes

class WavePod

  { Enemy, BigEnemy }   = require \./enemy

  { board-size } = require \config

  initial-small-enemies = 50
  initial-large-enemies = 3

  small-enemies-per-wave = 5
  large-enemies-per-wave = 0.3

  downtime   = 1
  spawn-time = 1

  center-drift-speed-factor = 4

  ({ @effects } = {}) ->
    @phase = 0
    @center = [0 0]

    @downtime-timer = new OneShotTimer downtime
    @spawn-timer    = new OneShotTimer spawn-time

    @wave-gen = do ->*
      small = initial-small-enemies
      large = initial-large-enemies

      while true => yield do
        small: small += small-enemies-per-wave
        large: floor large += large-enemies-per-wave

  update: (Δt, time, enemies) ->
    @phase += Δt
    @center = center = @get-pod-center @phase
    @spawn-timer.update Δt

    if enemies.length < 1
      @downtime-timer.begin!
      @downtime-timer.update Δt

      if @downtime-timer.elapsed
        @new-wave enemies

    enemies.map (.set-move-target center)

  get-pod-center: (phase) ->
    x =       0        + board-size.0 * 0.8 * Math.sin phase * 2/center-drift-speed-factor
    y = board-size.1/3 + board-size.1 * 0.4 * Math.cos phase * 1/center-drift-speed-factor
    [ x, y ]

  new-wave: (enemies) ->
    @spawn-timer.begin!
    @phase = random-range 0, tau

    { small, large } = @wave-gen.next!value
    @center = @get-pod-center @phase
    [ x, y ] = @center

    @effects.push new EnemySpawnEffect x, y

    for i from 0 til small
      enemy = new Enemy [ x, y ]
      enemies.push enemy

    for i from 0 til large
      enemy = new BigEnemy [ x, y ]
      enemies.push enemy

  draw: (ctx) ->
    ctx.rect @center, [ 20, 20 ]

  cull-destroyed-enemies: ->
    @enemies = @enemies.filter (.damage.alive)


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

pilots  = []
players = []
enemies = []
pickups = []

main-canvas.install document.body

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


class BulletImpact

  rad = 10
  life = 0.1

  (@bullet) ->
    @color = @bullet.owner.palette.bullet-color 1
    @pos   = @bullet.physics.clone-pos!
    @life = life

  update: (Δt) ->
    @life -= Δt
    @life > 0

  draw: (ctx) ->
    ctx.set-color @color
    ctx.alpha @life/life
    ctx.circle @pos, rad
    ctx.alpha 1



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

    # Check for collisions on the black plane
    for other in player-bin-space.get-bin-collisions player
      if player.damage.health > 0 and other.collider.intersects player.collider
        other.impact? player, Δt

    if player.state.forcefield-active
      repulsor player, enemies, Δt
      shaker.trigger 1, 0.1

    if player.state.vortex-active
      vortex player, enemies, Δt
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


  # Cull destroyed enemies
  enemies := enemies.filter (.damage.alive)


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


# Listen


# Multiplayer

class Server

  IO = require \socket.io-client

  { LocalPilot, WebsocketPilot } = require \./pilot
  { Player }            = require \./player

  { board-size } = require \config

  ({ @effects }, @push-player) ->

    @server = IO window.location.hostname + \:9999

    @pilots = []

    # Server callbacks
    @server.on \connect, @on-connect
    @server.on \pj, @on-player-joined
    @server.on \pd, @on-player-disconnected
    @server.on \p,  @on-player-update

  on-connect: ~>
    @server.emit \is-master

  on-player-joined: (index) ~>
    new-player = new Player index
    @pilots[index] = new WebsocketPilot new-player
    @effects.push new PlayerSpawnEffect new-player, @push-player

  on-player-disconnected: (index) ~>
    @pilots[index]?.kill-player!
    delete @pilots[index]

  on-player-update: (index, ...data) ~>
    @pilots[index]?.receive-update-data ...data

  add-local-player: (n) ->
    new-player = new Player n
    @pilots[n] = new LocalPilot new-player
    @effects.push new PlayerSpawnEffect new-player, @push-player
    @server.emit 'master-join', n
    return new-player

  add-local-player-at-next-open-slot: ->
    for i from 0 to 5
      if not @pilots[i]
        return @add-local-player i


#
# Setup
#

# Make connection to player relay server
frame-driver = new FrameDriver
server = new Server { effects }, -> players.push it


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

