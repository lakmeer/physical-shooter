
{ id, log, min } = require \std


#
# Histogram
#
# Draw player's relative scores between rounds
#

export class Histogram

  { board-size } = require \config

  box-size = board-size.0 / 14
  gap-size = box-size / 2

  max-score = (m, player) -> if m > player.score then m else player.score
  max-box-height = board-size.1 / 2

  ->
    @wave = 0
    @state =
      wave-transition-pending: no

  set-wave: (n) ->
    if n isnt @wave
      @state.wave-transition-pending = true
    @wave = n

  update: (Δt, time) ->

  dispatch-wave-transition: (players) ->
    for player in players
      player.process-wave-increase!
    @state.wave-transition-pending = no

  draw: (ctx, p, players) ->

    if @state.wave-transition-pending
      @dispatch-wave-transition players

    if not p then return
    if @wave is 0 then return

    best-score = players.reduce max-score, 0
    alpha = if p < 0.8 then 1 else 1 - (p - 0.8) * 5
    flash = min 1, p * 20

    g = 1 - min 1, p * 5
    grow = 1 - g*g*g

    ctx.alpha 1 - flash
    ctx.set-color \white
    ctx.rect [ -board-size.0, board-size.1 ], [ board-size.0 * 2, board-size.1 * 2 ]

    ctx.alpha alpha

    l = players.length

    for player, i in players
      score = player.score
      rank = score/best-score
      height = max-box-height * rank * grow
      pos  = [ ((l - 1)/-2 + i) * (box-size + gap-size), -max-box-height/2 + height ]
      size = [ box-size, height ]

      ctx.set-color player.palette.bullet-color 0
      ctx.rect pos, size

    ctx.alpha 1

