
#
# Collision Box
#
# Modular component for collision detection
#

export class CollisionBox
  (@x, @y, @w, @h) ->
    @xx = @x + @w
    @yy = @y + @h

  intersects: ({ x, y, xx, yy }) ->
    x > @x and x < @xx and y > @y and y < @yy and
    x > @x and x < @xx and y > @y and y < @yy

  draw: ->
    it.stroke-rect [ @x, @y ], [ @w, @h ]

  move-to: ([ x, y ]) ->
    @x = x - @w
    @y = y + @h/2

