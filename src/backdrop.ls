
{ id, log, tau, floor, random-range } = require \std

{ sprite }  = require \./sprite


#
# Backdrop Class
#
# Renders the background moving underneath
#

export class Backdrop

  { board-size, screen-size, scale-factor } = require \config

  speed = 30

  star-count = 200

  bg-width  = 1200
  bg-height = 3840
  bg-aspect = bg-width / bg-height
  bgh       = screen-size.0 / bg-aspect

  bg  = sprite \/assets/bg.jpg, bg-width, bg-height

  ->
    @scroll = 0
    @travel = 0
    @offset = [0 0]
    @stars  = @generate-stars!

  set-offset: ([ x, y ]) ->
    @offset.0 = x
    @offset.1 = y

  generate-stars: ->
    for i from 0 to star-count
      x: random-range 0, screen-size.0
      y: random-range 0, screen-size.1
      z: random-range 1, 10
      r: random-range 0.5, 2

  draw-star: ({ x, y, r }, ctx) ->
    ctx.fill-style = \white
    ctx.global-alpha = 0.5
    ctx.begin-path!
    ctx.arc x + @offset.0, y + @offset.1, r/scale-factor, 0, tau
    ctx.close-path!
    ctx.fill!
    ctx.global-alpha = 1

  draw: (ctx) ->   # Do work in screenspace

    offset = @scroll % bgh

    ctx.ctx.global-alpha = 0.6
    ctx.ctx.draw-image bg, 0 + @offset.0, offset + @offset.1,       screen-size.0, bgh
    ctx.ctx.draw-image bg, 0 + @offset.0, offset + @offset.1 - bgh, screen-size.0, bgh
    ctx.ctx.global-alpha = 1

    for star in @stars
      star.y += @travel / bg-aspect * star.z

      if star.y >= screen-size.1
        star.y = -star.r
        star.x = random-range 0, screen-size.0

      @draw-star star, ctx.ctx

  update: (Δt, time, canvas) ->
    @travel = speed * Δt
    @scroll += @travel

