
# Require

{ id, log, random-range } = require \std

{ Timer } = require \./timer


#
# Player Spawn Effect
#

export class EnemySpawnEffect

  { board-size } = require \config

  max-offset = 50
  max-radius = 150

  simultaneous-circles = 4

  (@x, @y) ->
    @timer = new Timer 2
    @timer.start!
    @flash = 1

  update: (Δt, time) ->
    @timer.update Δt
    return @timer.active

  random-offset: (p) ->
    [ @x + p * (random-range -max-offset, max-offset), @y + p * (random-range -max-offset, max-offset) ]

  random-radius: (p) ->
    p * random-range max-radius/3, max-radius

  draw: (ctx) ->
    ctx.set-color \darkred
    ctx.set-line-color \#0f0
    ctx.ctx.global-alpha = 0.6
    ctx.ctx.global-composite-operation = \color-burn

    prog = @timer.get-progress!

    p = if prog < 0.5 then prog * 2 else 1 - (prog - 0.5) * 2

    for i from 0 to simultaneous-circles
      offset = @random-offset p
      radius = @random-radius p
      ctx.stroke-circle offset, radius
      ctx.circle offset, radius

    ctx.ctx.global-alpha = 1
    ctx.ctx.global-composite-operation = \source-over

