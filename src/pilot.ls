

{ id, log, pi, delay } = require \std

{ board-size } = require \config

{ Player } = require \./player


#
# Pilot
#
# Representations of agents which drive player avatars
#

export class Pilot

  speed = 2
  respawn-time = 2000

  (@index, @on-player-spawn) ->
    @spawn-player!

  bind-inputs: ->

  spawn-player: ~>
    @player = new Player @index
    @player.on-killed ~>
      delay respawn-time, @spawn-player
    @on-player-spawn @player
    @bind-inputs!

  kill-player: ->
    @player.kill!

  auto-pilot: (time, i = @player.index) ->
    m = Math.sin time + i * pi/3 * speed/10
    g = Math.cos time + i * pi/6 * speed/10
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

  update: (Δt, time) ->    # relies on back-refrence from player
    @auto-pilot time

  spawn-player: ~>
    super ...
    @player.auto-pilot = @pilots[n]


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
  TILDE = 192
  SPACE = 32
  ESCAPE = 27

  ->
    super ...

  bind-inputs: ->

    player = @player

    document.add-event-listener \keydown, ({ which }:event) ->
      log which
      switch which
      | SPACE  => player.level-up-weapon!
      | TILDE  => player.superpowers!
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
    if not @player? then return
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

