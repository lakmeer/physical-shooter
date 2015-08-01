
# Require

{ id, log, raf, floor } = require \std


#
# Frame Driver
#
# Small engine that creates a frame loop
#

export class FrameDriver

  fps-history-window = 20

  (@on-frame) ->
    log "FrameDriver::new"
    @state =
      zero: 0
      time: 0
      frame: 0
      running: no

    @fps = 0
    @fps-history = [ 0 ] * fps-history-window

  frame: ~>
    if @state.running then raf @frame

    now = Date.now! - @state.zero
    Δt = now - @state.time

    @push-history Δt

    @state.time  = now
    @state.frame = @state.frame + 1
    @state.Δt    = Δt
    @on-frame Δt/1000, @state.time/1000, @state.frame, @fps

  start: ->
    if @state.running is yes then return
    log "FrameDriver::Start - starting"
    @state.zero = Date.now!
    @state.time = 0
    @state.running = yes
    @frame!

  stop: ->
    if @state.running is no then return
    log "FrameDriver::Stop - stopping"
    @state.running = no

  toggle: ->
    if @state.running
      @stop!
    else
      @start!

  push-history: (Δt) ->
    @fps-history.push Δt
    @fps-history.shift!
    @fps = floor 1000 * fps-history-window / @fps-history.reduce (+), 0

