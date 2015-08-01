
# Require

{ id, log } = require \std

{ FrameDriver } = require \./frame-driver
{ Blitter }     = require \./blitter
{ Player }      = require \./player
{ Enemy }       = require \./enemy

{ CollisionBox } = require \./collision-box


# Setup

main-canvas = new Blitter
main-canvas.install document.body

#player = new Player
#enemy  = new Enemy

tester = new CollisionBox 0, 0, 20 20


# Listen

document.add-event-listener \keydown, ({ which }) ->
  switch which
  | 32 => player.shoot!
  | 27 => frame-driver.toggle!

document.add-event-listener \mousemove, ({ pageX, pageY }) ->

  log pageX, pageY





# Init

frame-driver = new FrameDriver (Δt, time, frames) ->
  main-canvas.clear!
  #enemy.update Δt, time
  #enemy.draw main-canvas
  #player.update Δt, time
  #player.draw main-canvas

  #if time/10 % 25 > 20 then player.shoot!

frame-driver.start!


# Run Tests

{ BlitterTest } = require \../test

#BlitterTest.run!


