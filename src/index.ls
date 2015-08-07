
# Require

{ id, log, v2, rnd, floor, limit } = require \std

{ FrameDriver } = require \./frame-driver
{ Blitter }     = require \./blitter

{ Player }          = require \./player
{ Enemy, BigEnemy } = require \./enemy
{ Backdrop }        = require \./backdrop

{ CollisionBox } = require \./collision-box
{ ScreenShake }  = require \./screen-shake
{ Explosion }    = require \./explosion
{ Wreckage }     = require \./wreckage


# Config

{ board-size, time-factor } = require \config


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

document.add-event-listener \mousemove, ({ pageX, pageY }) ->
  for player, i in players
    mouse = [ pageX, pageY ]
    #if i > 0 then mouse.0 = window.inner-width - pageX
    #if i > 1 then return
    dest = main-canvas.screen-space-to-game-space mouse
    player.move-to dest
    player.dont-auto-move!


# Game play note:
# Initialising a force weapon cost more than running it for longer -
# rapidly switching force weapons will use twoce as much as sustained use

# Init

blast-force        = 50000
attract-force      = -10000
repulse-force      = 10000
start-wave-size    = 30
bullets-per-second = 30
last-shot-time     = -1

player-count = 3

effects  = []
enemies  = []
players  = [ new Player i for i from 0 til player-count ]
stray-collections = []

wave-size = do (n = start-wave-size, x = 0) ->* while true => yield [ n += 5, x += 1 ]

#player   = new Player
shaker   = new ScreenShake
backdrop = new Backdrop

main-canvas = new Blitter
main-canvas.install document.body


# Homeless functions

emit-force-blast = (force, self, others, Δt) ->

  [ x, y ] = self.pos

  limiter = if force < 0 then limit force, 0 else limit 0, force

  blast = (target) ->
    xx  = x - target.pos.0
    yy  = y - target.pos.1
    d   = Math.sqrt( xx * xx + yy * yy )
    ids = if d is 0 then 0 else 1 / (d*d)
    push = [ force * -xx * ids * Δt, force * -yy * ids * Δt]
    target.vel = target.vel `v2.add` push

  for other in others when other isnt self
    blast other
    if other.bullets
      for bullet in other.bullets
        blast bullet

new-wave = (n) ->
  [ small, big ] = wave-size.next!value
  for i from 0 til small
    pos = [ -board-size.0 + 10 + (rnd board-size.0 * 2 - 10), board-size.1 - rnd (board-size.1/2 - 10) ]
    enemy = new Enemy pos
    enemy.fire-target = players.0
    enemies.push enemy

  for i from 0 til big
    pos = [ -board-size.0 + 10 + (rnd board-size.0 * 2 - 10), board-size.1 - rnd (board-size.1/2 - 10) ]
    enemy = new BigEnemy pos
    enemy.fire-target = players.0
    enemies.push enemy


move-toward = (target, object) ->

class CollectableStream
  (@items, @owner) ->
    for item in @items
      #bullet.vel = bullet.vel `v2.scale` 0.2
      item.stray = true
      item.owner = @owner
      item.color = @owner.stray-color 0
      item.friction = 0.99

  update: (Δt, time) ->
    owner = @owner
    @items = @items.filter (.update-stray Δt, owner)
    @items.length > 0
    emit-force-blast attract-force, @owner, @items, Δt

  draw: (ctx) ->
    @items.map (.draw ctx)



# Tick functions

play-test-frame = (Δt, time) ->

  Δt   *= time-factor
  time *= time-factor

  backdrop.update Δt, time
  shaker.update Δt
  players.map (.update Δt, time)

  stray-collections := stray-collections.filter (.update Δt, time)
  effects.map (.update Δt, time)

  if enemies.length < 1
    new-wave wave-size

  for enemy in enemies
    if enemy.damage.alive
      enemy.update Δt, time

      if not players.0.dead
        enemy.fire-target = players.0

      for bullet in enemy.bullets
        for player in players
          if player.damage.health > 0 and bullet.box.intersects player.box
            bullet.impact player, Δt

      for player in players
        for laser in player.lasers
          if laser.box.intersects enemy.box
            laser.impact enemy, Δt
            enemy.last-hit = player

        for bullet in player.bullets
          if bullet.box.intersects enemy.box
            bullet.impact enemy, Δt
            enemy.last-hit = player

      if enemy.damage.health <= 0
        enemy.damage.alive = no
        shaker.trigger 5, 0.2

        owner = enemy.last-hit
        stray-collections.push new CollectableStream enemy.bullets, owner
        effects.push new Explosion enemy.pos
        effects.push new Wreckage enemy.pos, enemy.wreckage-sprite
        emit-force-blast blast-force, enemy, enemies, Δt
        emit-force-blast blast-force, enemy, enemy.bullets, Δt


  for player in players
    if player.forcefield-active and not player.dead
      emit-force-blast repulse-force, player, enemies, Δt
      #emit-force-blast repulse-force, player, strays
      shaker.trigger 5/player-count, 0.1

    #if player.magnet-active and not player.dead
      #emit-force-blast attract-force, player, strays, Δt
      #shaker.trigger 2/player-count, 0.1

    if player.damage.health <= 0 and not player.dead
      effects.push new Explosion player.pos
      player.kill!
      for enemy in enemies
        enemy.fire-target = null

  enemies := enemies.filter (.damage.alive)
  effects := effects.filter (.state.alive)

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

  effects.map (.update Δt, time)
  effects := effects.filter (.state.alive)

  new-shot-time = floor time/2

  if new-shot-time > last-shot-time
    effects.push new Explosion [ 0, 0 ]
    shaker.trigger 10, 1
    last-shot-time := new-shot-time


forcefield-test-frame = (Δt, time) ->
  player.dont-auto-move!
  player.move-to [0 0]
  backdrop.update Δt, time
  player.update Δt, time


render-frame = (frame) ->
  main-canvas.clear!
  main-canvas.set-offset shaker.get-offset!
  backdrop.draw main-canvas

  stray-collections.map  (.draw main-canvas)
  effects.map (.draw main-canvas)
  enemies.map (.draw main-canvas)
  players.map (.draw main-canvas)


frame-driver = new FrameDriver
frame-driver.on-frame render-frame
frame-driver.on-tick play-test-frame
frame-driver.start!

