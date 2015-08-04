
# Require

{ id, log, v2, rnd, floor } = require \std

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

document.add-event-listener \keydown, ({ which }) ->
  switch which
  | 32 => player.shoot!
  | 27 => frame-driver.toggle!

document.add-event-listener \mousemove, ({ pageX, pageY }) ->
  player.move-to main-canvas.screen-space-to-game-space [ pageX, pageY ]
  player.dont-auto-move!


# Init

blast-force        = 100
wave-size          = 50
bullets-per-second = 30
last-shot-time     = -1

effects  = []
enemies  = []
player   = new Player
shaker   = new ScreenShake
backdrop = new Backdrop

main-canvas = new Blitter
main-canvas.install document.body


# Homeless functions

emit-force-blast = (self, others) ->
  force = blast-force

  [ x, y ] = self.pos

  for other in others when other isnt self
    xx  = x - other.pos.0
    yy  = y - other.pos.1
    d   = Math.sqrt( xx*xx + yy*yy )
    ids = if d is 0 then 0 else 1 / (d*d)
    push = [ force * -xx * ids, force * -yy * ids]

    if (isNaN push.0) or (isNaN push.0)
      log x, ox, xx, y, oy, yy, d, ids, push

    other.vel = other.vel `v2.add` push

new-wave = (n) ->
  for i from 0 til n
    pos = [ -board-size.0 + 10 + (rnd board-size.0*2), board-size.1 - rnd (board-size.1/2 - 10) ]
    enemies.push new Enemy pos


# Tick functions

play-test-frame = (Δt, time) ->

  Δt   *= time-factor
  time *= time-factor

  backdrop.update Δt, time
  shaker.update Δt
  player.update Δt, time

  effects.map (.update Δt, time)

  if enemies.length < 1
    new-wave wave-size

  for enemy in enemies
    if enemy.damage.alive
      enemy.update Δt, time

      for bullet in player.bullets
        if bullet.box.intersects enemy.box
          bullet.impact enemy, Δt

          if enemy.damage.health <= 0
            enemy.damage.alive = no
            shaker.trigger 5, 0.2
            effects.push new Explosion enemy.pos
            emit-force-blast enemy, enemies

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

explosion-test-frame = (Δt, time, frames) ->
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


render-frame = (frame) ->
  main-canvas.clear!
  main-canvas.set-offset shaker.get-offset!
  backdrop.draw main-canvas

  effects.map (.draw main-canvas)
  enemies.map (.draw main-canvas)
  player.draw main-canvas

frame-driver = new FrameDriver
frame-driver.on-tick play-test-frame
frame-driver.on-frame render-frame
frame-driver.start!

