
{ id, log } = require \std

{ PlayerSpawnEffect } = require \./player-spawn-effect
{ LocalPilot }        = require \./pilot
{ AutomatedPilot }    = require \./pilot
{ WebsocketPilot }    = require \./pilot
{ Player }            = require \./player

IO = require \socket.io-client


#
# Server
#

export class Server

  { board-size } = require \config

  ({ @effects }, @push-player) ->

    @server = IO window.location.hostname + \:9999

    @pilots = []

    # Server callbacks
    @server.on \connect, @on-connect
    @server.on \pj, @on-player-joined
    @server.on \pd, @on-player-disconnected
    @server.on \p,  @on-player-update

  on-connect: ~>
    @server.emit \is-master

  on-player-joined: (index) ~>
    new-player = new Player index
    @pilots[index] = new WebsocketPilot new-player
    @effects.push new PlayerSpawnEffect new-player, @push-player

  on-player-disconnected: (index) ~>
    @pilots[index]?.kill-player!
    delete @pilots[index]

  on-player-update: (index, ...data) ~>
    @pilots[index]?.receive-update-data ...data

  add-local-player: (n) ->
    new-player = new Player n
    @pilots[n] = new LocalPilot new-player
    @effects.push new PlayerSpawnEffect new-player, @push-player
    @server.emit 'master-join', n
    return new-player

  add-autonomous-player: (n) ->
    new-player = new Player n
    @pilots[n] = new AutomatedPilot new-player
    @effects.push new PlayerSpawnEffect new-player, @push-player
    @server.emit 'master-join', n
    new-player.auto-pilot = @pilots[n]
    return new-player

  add-local-player-at-next-open-slot: ->
    for i from 0 to 5
      if not @pilots[i]
        return @add-local-player i

  add-autonomous-player-at-next-open-slot: ->
    for i from 0 to 5
      if not @pilots[i]
        return @add-autonomous-player i


