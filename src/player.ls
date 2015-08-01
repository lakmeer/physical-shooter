
{ id, log, box, v2 } = require \std

{ Ship } = require \./ship
{ CollisionBox } = require \./collision-box

#
# Player
#
# Contains things common to Players and Enemies
#

export class Player extends Ship

  ->
    super ...

    @pos = [0 0]
    @box = new CollisionBox ...@pos, 10, 10

