
{ id, log, random-range, tau, floor } = require \std

{ OneShotTimer }    = require \./timer
{ Enemy, BigEnemy } = require \./enemy
{ EnemySpawnEffect }  = require \./enemy-spawn-effect

#
# Wave Pod
#

export class WavePod

  { board-size } = require \config

  initial-small-enemies = 50
  initial-large-enemies = 3

  small-enemies-per-wave = 5
  large-enemies-per-wave = 0.3

  downtime   = 1
  spawn-time = 1

  center-drift-speed-factor = 4

  ({ @effects } = {}) ->
    @phase = 0
    @center = [0 0]

    @downtime-timer = new OneShotTimer downtime
    @spawn-timer    = new OneShotTimer spawn-time

    @wave-gen = do ->*
      small = initial-small-enemies
      large = initial-large-enemies

      while true => yield do
        small: small += small-enemies-per-wave
        large: floor large += large-enemies-per-wave

  update: (Δt, time, enemies) ->
    @phase += Δt
    @center = center = @get-pod-center @phase
    @spawn-timer.update Δt

    if enemies.length < 1
      @downtime-timer.begin!
      @downtime-timer.update Δt

      if @downtime-timer.elapsed
        @new-wave enemies

    enemies.map (.set-move-target center)

  get-pod-center: (phase) ->
    x =       0        + board-size.0 * 0.8 * Math.sin phase * 2/center-drift-speed-factor
    y = board-size.1/3 + board-size.1 * 0.4 * Math.cos phase * 1/center-drift-speed-factor
    [ x, y ]

  new-wave: (enemies) ->
    @spawn-timer.begin!
    @phase = random-range 0, tau

    { small, large } = @wave-gen.next!value
    @center = @get-pod-center @phase
    [ x, y ] = @center

    @effects.push new EnemySpawnEffect x, y

    for i from 0 til small
      enemy = new Enemy [ x, y ]
      enemies.push enemy

    for i from 0 til large
      enemy = new BigEnemy [ x, y ]
      enemies.push enemy

  draw: (ctx) ->
    ctx.rect @center, [ 20, 20 ]

  cull-destroyed-enemies: ->
    @enemies = @enemies.filter (.damage.alive)


