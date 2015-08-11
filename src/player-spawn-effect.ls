
# Require

{ id, log } = require \std

{ Timer } = require \./timer


#
# Player Spawn Effect
#

export class PlayerSpawnEffect

  { board-size } = require \config

  (@player, @done) ->
    @timer = new Timer 0.2
    @timer.start!
    @flash = 1

  update: (Δt, time) ->
    @timer.update Δt
    if @timer.elapsed => @done!
    return @timer.active

  draw: (ctx) ->
    p = @timer.get-progress!
    t = 1 - p

    tt = t*t
    pp = 1 - tt

    ttt = t*t*t
    ppp = 1 - ttt

    # Color overlay
    ctx.ctx.global-composite-operation = \hue
    ctx.set-color @player.palette.bullet-color 0
    ctx.rect [ -board-size.0, board-size.1  ], [ board-size.0 * 2, board-size.1 * 2 ]

    # Flashing
    ctx.ctx.global-composite-operation = \source-over # overlay
    ctx.ctx.global-alpha = @flash = 1 - @flash

    # Cross Formation
    offset-top  = pp * board-size.1
    offset-left = pp * board-size.0
    ctx.rect [ -board-size.0, board-size.1 - offset-top  ], [ board-size.0 * 2, board-size.1 * 2*tt ]
    ctx.rect [ -board-size.0 + offset-left, board-size.1 ], [ board-size.0 * 2*tt, board-size.1 * 2 ]

    ctx.set-color \white
    offset-top  = ppp * board-size.1
    offset-left = ppp * board-size.0
    ctx.rect [ -board-size.0, board-size.1 - offset-top  ], [ board-size.0 * 2, board-size.1 * 2*ttt ]
    ctx.rect [ -board-size.0 + offset-left, board-size.1 ], [ board-size.0 * 2*ttt, board-size.1 * 2 ]

    # Restore context
    ctx.ctx.global-composite-operation = \source-over
    ctx.ctx.global-alpha = 1

