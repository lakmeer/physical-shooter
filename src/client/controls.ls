

{ id, log, min } = require \std


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

  active-region-ratio = 0.4

  pt = -> it * 100 + \%

  charge-meter-max = 5000

  (@dom) ->
    @state =
      x: 0.5
      y: 0.9
      laser: 0
      force: 0
      vortex: 0
      command: NO_COMMAND

    @crosshair     = document.get-element-by-id \crosshair
    @laser-button  = document.get-element-by-id \laser
    @force-button  = document.get-element-by-id \repulsor
    @vortex-button = document.get-element-by-id \vortex
    @meter         = document.get-element-by-id \charge

  is-in-steering-region: ({ pageX }) ->
    pageX > window.inner-width * active-region-ratio

  get-command: (is-release-event, { pageY }) ->
    h = window.inner-height
    command =
      if      pageY < h * 1/3 then LASER_ON
      else if pageY < h * 2/3 then VORTEX_ON
      else                         FORCE_ON
    return if is-release-event then command += 3 else command

  set-button-state: (command) ->
    switch command
    | NO_COMMAND => void
    | LASER_ON   => @laser-button.style.background-color = @color
    | FORCE_ON   => @force-button.style.background-color = @color
    | VORTEX_ON  => @vortex-button.style.background-color = @color
    | LASER_OFF  => @laser-button.style.background-color = \transparent
    | FORCE_OFF  => @force-button.style.background-color = \transparent
    | VORTEX_OFF => @vortex-button.style.background-color = \transparent

  set-meter-height: (charge) ->
    @meter.style.height = (charge * 100) + \vh

  hide: -> @dom.style.display = \none
  show: -> @dom.style.display = \block

  update: (Δt, time) ->
    @set-crosshair-pos @state.x, @state.y
    @set-meter-height @state.charge

  update-charge: (charge) ->
    @state.charge = min 1, charge/charge-meter-max

  set-crosshair-pos: (x, y) ->
    @crosshair.style.left = pt x
    @crosshair.style.top  = pt y

  set-ui-color: (color) ->
    @color = color
    @dom.style.border-color = color
    for child in @dom.children
      child.style.border-color = color

  consume-pending-input: (Δt) ->
    command = @state.command
    @state.command = NO_COMMAND
    [ @state.x, @state.y, command ]

  on-touchstart: (event) ~>
    w = window.inner-width
    h = window.inner-height
    a = active-region-ratio

    for touch in event.touches
      if @is-in-steering-region touch
        @state.x = (touch.pageX - w * a) / (window.inner-width * (1 - a))
        @state.y =  touch.pageY          /  window.inner-height
      else
        @state.command = @get-command no, touch
        @set-button-state @state.command
    event.prevent-default!
    return false

  on-touchmove: (event) ~>
    w = window.inner-width
    h = window.inner-height
    a = active-region-ratio

    for touch in event.touches
      if @is-in-steering-region touch
        @state.x = (touch.pageX - w * a) / (window.inner-width * (1 - a))
        @state.y =  touch.pageY          /  window.inner-height

      # XXX: Note - indent this back if touchend breaks
      event.prevent-default!
      return false

  on-touchend: (event) ~>
    for touch in event.changed-touches
      if not @is-in-steering-region touch
        @state.command = @get-command yes, touch
        @set-button-state @state.command
    event.prevent-default!
    return false

  bind-inputs: ->
    document.add-event-listener 'touchstart', @on-touchstart
    document.add-event-listener 'touchend',   @on-touchend
    document.add-event-listener 'touchleave', @on-touchend
    document.add-event-listener 'touchmove',  @on-touchmove

  release-inputs: ->
    document.remove-event-listener 'touchstart', @on-touchstart
    document.remove-event-listener 'touchend',   @on-touchend
    document.remove-event-listener 'touchmove',  @on-touchmove

