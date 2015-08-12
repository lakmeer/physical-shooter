
#
# DEBUG TICK FUNCTIONS
#
# Non-game tick functions for testing engine features
#


# Test explosion particles

effects-b = new EffectsDriver
scales = [ 1 2 3 4 5 ]
scale-index = -1

explosion-test-frame = (Δt, time) ->
  shaker.update Δt
  effects.update Δt, time
  effects-b.update Δt * time-factor, time * time-factor

  # TODO: Put a real timer here
  on-explosion = ->
    scale-index := wrap 0, scales.length-1, scale-index + 1
    scale = scales[scale-index]
    tint  = players[floor rnd player-count].explosion-tint-color

    effects.push   new Explosion [ -100, 0 ], scale, tint
    effects-b.push new Explosion [  100, 0 ], scale, tint


# Test forcefield effect

forcefield-test-frame = (Δt, time) ->
  player.dont-auto-move!
  player.move-to [0 0]
  backdrop.update Δt, time
  player.update Δt, time


# Test crowd avoidance

new-crowd = (n) ->
  [ small ] = wave-size.next!value
  for i from 0 til small
    pos = [ (rnd 100), (rnd 100) ]
    pos = [0 0]
    enemy = new Enemy pos
    enemies.push enemy

crowding-test-frame = (Δt, time) ->
  crowd-bin-space.clear!

  # Spawn new enemies if we've run out
  if enemies.length < 1
    new-crowd wave-size

  # Update enemies and their bullets
  for enemy in enemies
    crowd-bin-space.assign-bin enemy
    if enemy.damage.alive
      enemy.update Δt, time

  # De-crowd enemies
  for enemy in enemies
    de-crowd enemy, crowd-bin-space.get-bin-collisions enemy

  # Check for collisions on the black plane
  for player in players
    if player.forcefield-active and alive player
      emit-force-blast repulse-force, player, enemies, Δt
      shaker.trigger 10/player-count, 0.1


# Test laser effect

{ Laser } = require \./bullet

laser-timer = new Timer 4

laser-effect-frame = (Δt, time) ->
  shaker.update Δt
  laser-timer.update Δt

  if laser-timer.elapsed
    players.0.laser shaker
    laser-timer.reset!

  for player, i in players
    player.update Δt, time
    player.dont-auto-move!
    #player.move-to [ (-2.5 + i) * 50, -board-size.1 + 50 ]


# Test Weapon Rankings

weapons-test-frame = (Δt) ->
  for player, i in players
    player.dont-auto-move!
    player.update Δt * time-factor
    player.move-towards [ -board-size.0/3 * 2.5 + board-size.0/3 * i, -board-size.1*0.85 ]


#
# END DEBUG TICK FUNCTIONS
#


