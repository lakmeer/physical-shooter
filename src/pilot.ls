

{ id, log } = require \std

{ board-size } = require \config


#
# Pilot
#
# Representations of agents which drive player avatars
#

export class Pilot
  (@player) ->
    @bind-inputs!

  bind-inputs: ->
  kill-player: -> @player.kill!

  auto-pilot: (time, i = @player.index) ->
    m = Math.sin time + i * pi / 3
    g = Math.cos time + i * pi / 6
    @player.move-towards [ board-size.0 * 0.98 * m, -board-size.1 + board-size.1/3 + g * board-size.1/5 ]

#
# Automated Pilot
#
# Computer-driven pilot
#

export class AutomatedPilot extends Pilot

  ->
    super ...

  receive-update-data: (x, y, command, time) ->
    @auto-pilot time
    return


#
# Local Pilot
#
# Keyboard-and-mouse driven pilot on the same window as the Master view
#

export class LocalPilot extends Pilot

  ENTER = 13
  KEY_Z = 90
  KEY_X = 88
  KEY_C = 67
  SPACE = 32
  ESCAPE = 27

  ->
    super ...

  bind-inputs: ->

    player = @player

    document.add-event-listener \keydown, ({ which }:event) ->
      switch which
      | SPACE  => player.level-up-weapon!
      | KEY_Z  => player.activate-laser!
      | KEY_X  => player.activate-forcefield!
      | KEY_C  => player.activate-vortex!
      | _  => return event
      event.prevent-default!
      return false

    document.add-event-listener \keyup, ({ which }:event) ->
      switch which
      #| KEY_Z  => player.deactivate-laser! # Not allowed control over this # Not allowed control over this
      | KEY_X  => player.deactivate-forcefield!
      | KEY_C  => player.deactivate-vortex!
      | _  => return event
      event.prevent-default!
      return false

    document.add-event-listener \mousemove, ({ pageX, pageY }) ->
      x = pageX / window.inner-width
      y = pageY / window.inner-height

      player.move-towards [
        -board-size.0 + board-size.0 * 2 * x
        board-size.1 - board-size.1 * 2 * y
      ]


#
# Websocket Pilot
#
# This pilot is going to receive update packets from the network
#

export class WebsocketPilot extends Pilot
  ->
    super ...

  receive-update-data: (x, y, command, time) ->
    @player.move-towards [
      -board-size.0 + board-size.0 * 2 * x
      board-size.1 - board-size.1 * 2 * y
    ]

    switch command  # 0 = no command this frame
    | 1 => @player.activate-laser!
    | 2 => @player.activate-forcefield!
    | 3 => @player.activate-vortex!
    | 4 => # @player.deactivate-laser!   # Not allowed
    | 5 => @player.deactivate-forcefield!
    | 6 => @player.deactivate-vortex!

