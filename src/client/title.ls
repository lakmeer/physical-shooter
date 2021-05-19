
{ id, log } = require \std

#
# Title Screen
#

export class Title

  reveal-time  = 1.5
  reveal-delay = 0.4

  (@dom) ->
    @tap-text   = document.get-element-by-id \tap-text
    @title-text = document.get-element-by-id \title-text

    @state = ready: no

    @dom.add-event-listener \touchstart, ~> @state.ready = yes

  update: (Δt, time) ->
    if reveal-delay <= time <= reveal-time + reveal-delay
      p = (time - reveal-delay) / reveal-time
      t = 1 - p
      @title-text.style.display = \block
      @title-text.style.opacity = p * p
      @title-text.style.margin-top = 100 * ( t*t*t) + \px
      @tap-text.style.opacity = 0

    else
      @title-text.style.opacity = 1
      @title-text.style.margin-top = 0
      @tap-text.style.opacity = 0.5 + 0.25 * Math.sin time * 10

  show: -> @dom.style.display = \block
  hide: -> @dom.style.display = \none

