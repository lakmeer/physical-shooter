
# Require

{ id, log, rnd, floor } = require \std

{ FrameDriver } = require \./frame-driver
{ Blitter }     = require \./blitter
{ Player }      = require \./player
{ Enemy }       = require \./enemy

{ CollisionBox } = require \./collision-box
{ Explosion } = require \./explosion


# Setup

main-canvas = new Blitter
main-canvas.install document.body


# Listen

document.add-event-listener \keydown, ({ which }) ->
  switch which
  | 32 => player.shoot!
  | 27 => frame-driver.toggle!

document.add-event-listener \mousemove, ({ pageX, pageY }) ->
  player.move-to main-canvas.screen-space-to-game-space [ pageX, pageY ]
  player.dont-auto-move!


# Init

{ time-factor } = require \config

last-shot-time = -1

effects = []
enemies = []

player = new Player


play-test-frame = (Δt, time, frames) ->

  Δt   *= time-factor
  time *= time-factor

  main-canvas.clear!
  #main-canvas.show-grid!

  effects.map (.update Δt, time)
  effects.map (.draw main-canvas)

  player.update Δt, time
  #player.move-to [ 0, -25 ]
  player.draw main-canvas

  if enemies.length < 1
    for i from 0 til 50
      enemies.push new Enemy [ -90 + (rnd 180), 90 - rnd 90 ]

  for enemy in enemies

    if enemy.state.alive
      enemy.update Δt, time
      enemy.draw main-canvas

      for bullet in player.bullets
        if bullet.box.intersects enemy.box
          bullet.state.hit = true
          enemy.state.health -= 40

          if enemy.state.health <= 0
            enemy.state.alive = no
            effects.push new Explosion enemy.pos

  enemies := enemies.filter (.state.alive)
  effects := effects.filter (.state.alive)

  new-shot-time = floor time*10

  if new-shot-time > last-shot-time
    to-fire = new-shot-time - last-shot-time
    for i from 0 to to-fire
      player.shoot!
    last-shot-time := new-shot-time



explosion-test-frame = (Δt, time, frames) ->
  main-canvas.clear!
  main-canvas.show-grid!

  effects.map (.update Δt, time)
  effects := effects.filter (.state.alive)
  effects.map (.draw main-canvas)

  new-shot-time = floor time/2

  if new-shot-time > last-shot-time
    effects.push new Explosion [ 0, 0 ]
    last-shot-time := new-shot-time


circle-test-frame = (Δt, time, frames) ->
  main-canvas.clear!
  main-canvas.circle [0 0], 100


frame-driver = new FrameDriver play-test-frame
frame-driver.start!

