
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

tester = new CollisionBox 0, 0, 10, 10


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
  main-canvas.show-grid!

  #enemy.update Δt, time
  #enemy.draw main-canvas

  #player.update Δt, time
  player.move-to [ 0, -25 ]
  player.draw main-canvas

  #tester.move-to [ 20 * Math.sin(time/1000), 20 * Math.cos(time/1000) ]
  tester.intersects player.box
  tester.draw main-canvas

  #if time/10 % 25 > 20 then player.shoot!

frame-driver.start!

