
# Require

{ id, log, floor } = require \std

{ FrameDriver } = require \./frame-driver
{ Blitter }     = require \./blitter
{ Player }      = require \./player
{ Enemy }       = require \./enemy

{ CollisionBox } = require \./collision-box


# Setup

main-canvas = new Blitter
main-canvas.install document.body

player = new Player
enemy  = new Enemy


# Listen

document.add-event-listener \keydown, ({ which }) ->
  switch which
  | 32 => player.shoot!
  | 27 => frame-driver.toggle!

document.add-event-listener \mousemove, ({ pageX, pageY }) ->
  tester.move-to main-canvas.screen-space-to-game-space [ pageX, pageY ]


# Init

{ time-factor } = require \config

last-shot-time = 0

frame-driver = new FrameDriver (Δt, time, frames) ->

  Δt   *= time-factor
  time *= time-factor

  main-canvas.clear!
  main-canvas.show-grid!

  enemy.update Δt, time
  enemy.draw main-canvas

  player.update Δt, time
  #player.move-to [ 0, -25 ]
  player.draw main-canvas

  for bullet in player.bullets
    if bullet.box.intersects enemy.box
      bullet.state.hit = true
      enemy.state.health -= 2

  new-shot-time = floor time*20

  if new-shot-time > last-shot-time
    player.shoot!
    last-shot-time := new-shot-time

frame-driver.start!

