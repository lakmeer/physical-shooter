
# Require

{ id, log, raf, floor, delay } = require \std


#
# Frame Driver
#
# Small engine that creates a frame loop
#

export class FrameDriver

  tps-history-window = 20
  fps-history-window = 20

  RENDER_ON_TICK = no

  (@no-readout = true) ->
    log "FrameDriver::new"

    @state =
      zero: 0
      last-tick-time: 0
      last-frame-time: 0
      frame: 0
      running: no

    @callbacks =
      tick: id
      frame: id

    @tps =
      value: 0
      history: [ 0 ] * tps-history-window

    @fps =
      value: 0
      history: [ 0 ] * fps-history-window

    unless @no-readout
      @readout = document.create-element \pre
      @readout.style <<< { position: \absolute, top: 0, right: 0 }
      document.body.append-child @readout


  frame: ~>
    if @state.running then raf @frame

    now = Date.now! - @state.zero
    Δt  = now - @state.last-frame-time

    @push-frame-time Δt

    @state.last-frame-time = now
    @state.frame += 1
    @callbacks.frame @state.frame

  tick: ~>
    if @state.running then delay 0, @tick

    now = Date.now! - @state.zero
    Δt  = now - @state.last-tick-time

    unless @no-readout
      @readout.text-content = @fps.value + " | " + @tps.value

    @push-tick-time Δt
    @state.last-tick-time = now
    @callbacks.tick Δt/1000, @state.last-tick-time/1000, @state.frame, @fps

    if RENDER_ON_TICK
      @push-frame-time Δt
      @state.frame += 1
      @callbacks.frame @state.frame

  start: ->
    if @state.running is yes then return
    log "FrameDriver::Start - starting"
    @state.zero = Date.now!
    @state.last-tick-time = 0
    @state.last-frame-time = 0
    @state.running = yes
    @tick!
    @frame! unless RENDER_ON_TICK

  stop: ->
    if @state.running is no then return
    log "FrameDriver::Stop - stopping"
    @state.running = no

  toggle: ->
    if @state.running
      @stop!
    else
      @start!

  push-tick-time: (Δt) ->
    @tps.history.push Δt
    @tps.history.shift!
    @tps.value = floor 1000 * tps-history-window / @tps.history.reduce (+), 0

  push-frame-time: (Δt) ->
    @fps.history.push Δt
    @fps.history.shift!
    @fps.value = floor 1000 * fps-history-window / @fps.history.reduce (+), 0

  on-tick: (λ) ->
    @callbacks.tick = λ

  on-frame: (λ) ->
    @callbacks.frame = λ

