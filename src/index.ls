
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
  | KEY_C  => player
  | _  => return event
  event.prevent-default!
  return false

document.add-event-listener \keyup, ({ which }:event) ->
  switch which
  | 32 => player.forcefield-active = no
  | _  => return event
  event.prevent-default!
  return false

document.add-event-listener \mousemove, ({ pageX, pageY }) ->
  player.move-to main-canvas.screen-space-to-game-space [ pageX, pageY ]
  player.dont-auto-move!


# Init

blast-force        = 1000
repulse-force      = 500
wave-size          = 50
bullets-per-second = 30
last-shot-time     = -1

effects  = []
enemies  = []
strays   = []
player   = new Player
shaker   = new ScreenShake
backdrop = new Backdrop

main-canvas = new Blitter
main-canvas.install document.body


# Homeless functions

emit-force-blast = (force, self, others) ->

  [ x, y ] = self.pos

  blast = (target) ->
    xx  = x - target.pos.0
    yy  = y - target.pos.1
    d   = Math.sqrt( xx*xx + yy*yy )
    ids = if d is 0 then 0 else 1 / (d*d)
    ids = limit 0, force/1000, ids
    push = [ force * -xx * ids, force * -yy * ids]
    target.vel = target.vel `v2.add` push

  for other in others when other isnt self
    blast other
    if other.bullets
      for bullet in other.bullets
        blast bullet

new-wave = (n) ->
  for i from 0 til n
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
        if bullet.box.intersects player.box
          bullet.impact player, Δt

      for bullet in player.bullets
        if bullet.box.intersects enemy.box
          bullet.impact enemy, Δt

          if enemy.damage.health <= 0
            enemy.damage.alive = no
            shaker.trigger 5, 0.2
            for bullet in enemy.bullets
              bullet.vel = bullet.vel `v2.scale` 0.5
              bullet.stray = true
              strays.push bullet
            effects.push new Explosion enemy.pos
            emit-force-blast blast-force, enemy, enemies
            emit-force-blast blast-force, enemy, strays

  if player.forcefield-active and not player.dead
    emit-force-blast repulse-force, player, enemies
    emit-force-blast repulse-force, player, strays
    shaker.trigger 8, 0.1

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
    for i from 0 til to-fire
      player.shoot!
    last-shot-time := new-shot-time

  return
  if enemies.length < 5
    for enemy in enemies
      log enemy.pos


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

