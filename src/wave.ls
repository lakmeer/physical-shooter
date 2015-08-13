
{ id, log, tau, floor, random-range, random-from } = require \std

{ OneShotTimer }    = require \./timer
{ Enemy, BigEnemy } = require \./enemy
{ EnemySpawnEffect }  = require \./enemy-spawn-effect


#
# Wave Pod
#

export class WavePod

  { board-size } = require \config

  center-drift-speed-factor = 4

  ->
    @dir = Math.sign Math.random!
    @phase = 0
    @center = [0 0]
    @prime!
    #@spawn-timer    = new OneShotTimer spawn-time

  update: (Δt, time, enemies) ->
    @phase += Δt * @dir
    @center = center = @get-pod-center @phase
    #@spawn-timer.update Δt

  get-pod-center: (phase) ->
    x =       0        + board-size.0 * 0.8 * Math.sin phase * 2/center-drift-speed-factor
    y = board-size.1/3 + board-size.1 * 0.4 * Math.cos phase * 1/center-drift-speed-factor
    [ x, y ]

  draw: (ctx) ->
    ctx.rect @center, [ 20, 20 ]

  assign: (EnemyType, effects) ->
    [ x, y ] = @center
    enemy = new EnemyType [ x, y ]
    enemy.assign-pod this
    effects.push new EnemySpawnEffect x, y, this
    return enemy

  prime: ->
    @phase = random-range 0, tau * center-drift-speed-factor


export class Wave

  downtime  = 3
  pod-count = 5

  initial-small-enemies = 20
  initial-large-enemies = 0

  small-enemies-per-wave = 2
  large-enemies-per-wave = 0.3

  ({ @effects }) ->
    @wave-number = 0

    @pods = [ new WavePod i for i from 0 to 5 ]

    @downtime-timer = new OneShotTimer downtime

    @wave-gen = do ~>*
      small = initial-small-enemies
      large = initial-large-enemies

      while true => yield do
        small: small += small-enemies-per-wave
        large: floor large += large-enemies-per-wave


  is-downtime: ->
    @downtime-timer.active

  downtime-progress: ->
    @downtime-timer.get-progress!

  update: (Δt, time, enemies) ->
    @pods.map (.update Δt, time, enemies)

    if enemies.length < 1
      @downtime-timer.begin!
      @downtime-timer.update Δt

      if @downtime-timer.elapsed
        @new-wave enemies, @wave-number + 1

  spawn-in-random-pod: (EnemyType, effects) ->
    pod = random-from @pods
    return pod.assign EnemyType, effects

  new-wave: (enemies, wave) ->
    @pods.map (.prime!)
    @wave-number = wave

    { small, large } = @wave-gen.next!value

    for i from 0 til small
      enemy = @spawn-in-random-pod Enemy, @effects
      enemies.push enemy

    for i from 0 til large
      enemy = @spawn-in-random-pod BigEnemy, @effects
      enemies.push enemy

  draw: (ctx) ->
    @pods.map (.draw ctx)


