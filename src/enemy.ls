
{ id, log, box, v2 } = require \std

{ Ship } = require \./ship
{ CollisionBox } = require \./collision-box

#
# Enemy
#
# Autonomous, computer-controlled version of Ship
# Idea: injected controller class - cpu vs human
#

export class Enemy extends Ship
  ->
    super ...
    @pos = [0, 0.92]

    @state =
      alive: yes

    @box = new CollisionBox ...@pos, 0.08, 0.08

  update: (Δt, time) ->
    @pos.0 = 0.5 * Math.cos time/1000
    @box.move-to @pos

  draw: ->
    it.set-color \#1d2
    it.rect (@pos `v2.add` [-0.08 0.04]), box 0.08
    @box.draw it

