
{ id, log, rnd, delay } = require \std

export class ScreenShake

  shake = ->
    (0.5 - rnd 1) * 2 * rnd it

  shake-sum = (offset, { amp, prog }) ->
    offset.0 += shake amp * prog
    offset.1 += shake amp * prog
    offset

  ->
    @offset  = [0 0]
    @sources = []

  create-source: (amp, time) ->
    amp   : amp
    time  : 0
    limit : time
    prog  : 0

  update-source: (Δt, { time, limit }:source) ->
    source.time += Δt
    source.prog = 1 - time/limit
    return source.time < limit

  update: (Δt, time) ->
    @sources = @sources.filter @update-source Δt, _
    @offset  = @sources.reduce shake-sum, [0 0]

  trigger: (amount, time) ->
    @sources.push @create-source amount, time

  trigger-after: (wait, amount, time) ->
    delay wait*1000, this.trigger.bind this, amount, time

  get-offset: ->
    @offset

