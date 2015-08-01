
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

player = new Player
#enemy  = new Enemy

tester = new CollisionBox 0, 0.5, 0.03, 0.03


# Listen

document.add-event-listener \keydown, ({ which }) ->
  switch which
  | 32 => player.shoot!
  | 27 => frame-driver.toggle!

document.add-event-listener \mousemove, ({ pageX, pageY }) ->
  tester.move-to main-canvas.screen-space-to-game-space [ pageX, pageY ]




# Init

frame-driver = new FrameDriver (Δt, time, frames) ->
  main-canvas.clear!
  #enemy.update Δt, time
  #enemy.draw main-canvas
  #player.update Δt, time
  #player.draw main-canvas

  #tester.move-to [ (10 * Math.sin time/500), 10 + 5 * Math.cos time/500 ]
  tester.intersects player.box
  #tester.draw main-canvas

  #if time/10 % 25 > 20 then player.shoot!

  x = 30 * Math.sin time/500
  y = 30 * Math.cos time/500

  main-canvas.rect [ x, y ], [ 10, 10 ]




frame-driver.start!

