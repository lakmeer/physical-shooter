
# Require

{ id, log, v2, rnd, floor, limit } = require \std

{ FrameDriver } = require \./frame-driver
{ Blitter }     = require \./blitter

{ Player }   = require \./player
{ Enemy }    = require \./enemy
{ Backdrop } = require \./backdrop

{ CollisionBox } = require \./collision-box
{ ScreenShake }  = require \./screen-shake
{ Explosion }    = require \./explosion


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
  | SPACE  => player.forcefield-active = yes
  | ESCAPE => frame-driver.toggle!
  | KEY_Z  => player.unkill!
  | KEY_X  => player.magnet-active = yes
  | KEY_C  => player
  | _  => return event
  event.prevent-default!
  return false

document.add-event-listener \keyup, ({ which }:event) ->
  switch which
  | SPACE => player.forcefield-active = no
  | KEY_X => player.magnet-active = no
  | _  => return event
  event.prevent-default!
  return false

document.add-event-listener \mousemove, ({ pageX, pageY }) ->
  player.move-to main-canvas.screen-space-to-game-space [ pageX, pageY ]
  player.dont-auto-move!


# Game play note:
# Initialising a force weapon cost more than running it for longer -
# rapidly switching force weapons will use twoce as much as sustained use

# Init

blast-force        = 50000
attract-force      = -10000
repulse-force      = 10000
start-wave-size    = 25
bullets-per-second = 30
last-shot-time     = -1

effects  = []
enemies  = []
strays   = []

wave-size = do (n = start-wave-size) ->* while true => yield n += 5

player   = new Player
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
  for i from 0 til log wave-size.next!value
    pos = [ -board-size.0 + 10 + (rnd board-size.0 * 2 - 10), board-size.1 - rnd (board-size.1/2 - 10) ]
    enemy = new Enemy pos
    enemy.fire-target = player
    enemies.push enemy


# Tick functions

play-test-frame = (Δt, time) ->

  Δt   *= time-factor
  time *= time-factor

  backdrop.update Δt, time
  shaker.update Δt
  player.update Δt, time

  strays := strays.filter (.update Δt, time)
  effects.map (.update Δt, time)

  if enemies.length < 1
    new-wave wave-size

  for enemy in enemies
    if enemy.damage.alive
      enemy.update Δt, time

      if not player.dead
        enemy.fire-target = player

      for bullet in enemy.bullets
        if player.damage.health > 0 and bullet.box.intersects player.box
          bullet.impact player, Δt

      for bullet in player.bullets
        if bullet.box.intersects enemy.box
          bullet.impact enemy, Δt

          if enemy.damage.health <= 0
            enemy.damage.alive = no
            shaker.trigger 5, 0.2
            for bullet in enemy.bullets
              #bullet.vel = bullet.vel `v2.scale` 0.2
              bullet.stray = true
              bullet.friction = 0.99
              strays.push bullet
            effects.push new Explosion enemy.pos
            emit-force-blast blast-force, enemy, enemies, Δt
            emit-force-blast blast-force, enemy, strays, Δt

  if player.forcefield-active and not player.dead
    emit-force-blast repulse-force, player, enemies, Δt
    #emit-force-blast repulse-force, player, strays
    shaker.trigger 5, 0.1

  if player.magnet-active and not player.dead
    emit-force-blast attract-force, player, strays, Δt
    shaker.trigger 2, 0.1

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
    if not player.forcefield-active
      for i from 0 til to-fire => player.shoot!
    last-shot-time := new-shot-time

  for stray in strays
    for enemy in enemies
      if stray.box.intersects enemy.box
        stray.impact enemy, Δt

        if enemy.damage.health <= 0
          enemy.damage.alive = no
          shaker.trigger 5, 0.2
          for bullet in enemy.bullets
            #bullet.vel = bullet.vel `v2.scale` 0.2
            bullet.stray = true
            bullet.friction = 0.99
            strays.push bullet
          effects.push new Explosion enemy.pos
          emit-force-blast blast-force, enemy, enemies, Δt
          emit-force-blast blast-force, enemy, strays, Δt




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

  strays.map  (.draw main-canvas)
  effects.map (.draw main-canvas)
  enemies.map (.draw main-canvas)
  player.draw main-canvas


frame-driver = new FrameDriver
frame-driver.on-frame render-frame
frame-driver.on-tick play-test-frame
frame-driver.start!
