

{ id, log } = require \std


#
# Controls
#

export class Controls

  NO_COMMAND = 0
  LASER_ON   = 1
  FORCE_ON   = 2
  VORTEX_ON  = 3
  LASER_OFF  = 4
  FORCE_OFF  = 5
  VORTEX_OFF = 6

  (@dom) ->
    @state =
      x: 0.5
      y: 0.9
      laser: 0
      force: 0
      vortex: 0
      command: NO_COMMAND

  is-in-steering-region: ({ pageX }) ->
    pageX > window.inner-width / 2

  get-command: (is-release-event, { pageY }) ->
    h = window.inner-height
    command =
      if      pageY < h * 1/3 then LASER_ON
      else if pageY < h * 2/3 then FORCE_ON
      else                         VORTEX_ON
    return if is-release-event then command += 3 else command

  hide: -> @dom.style.display = \none
  show: -> @dom.style.display = \block

  update: (Δt) ->
    # TODO: update buttons when touched

  consume-pending-input: (Δt) ->
    command = @state.command
    @state.command = NO_COMMAND
    [ @state.x, @state.y, command ]

  on-touchstart: (event) ~>
    for touch in event.touches
      if @is-in-steering-region touch
        @state.x = 2 * (touch.pageX / window.inner-width) - 1
        @state.y = touch.pageY / window.inner-height
      else
        @state.command = @get-command no, touch
    event.prevent-default!
    return false

  on-touchend: (event) ~>
    for touch in event.changed-touches
      if not @is-in-steering-region touch
        @state.command = @get-command yes, touch
    event.prevent-default!
    return false

  on-touchmove: (event) ~>
    for touch in event.touches
      if @is-in-steering-region touch
        @state.x = 2 * (touch.pageX / window.inner-width) - 1
        @state.y = touch.pageY / window.inner-height

      # XXX: Note - indent this back if touchend breaks
      event.prevent-default!
      return false

  bind-inputs: ->
    log \bind
    document.add-event-listener 'touchstart', @on-touchstart
    document.add-event-listener 'touchend',   @on-touchend
    document.add-event-listener 'touchmove',  @on-touchmove

  release-inputs: ->
    document.remove-event-listener 'touchstart', @on-touchstart
    document.remove-event-listener 'touchend',   @on-touchend
    document.remove-event-listener 'touchmove',  @on-touchmove

