
#
# Collision Box
#
# Modular component for collision detection
#

export class CollisionBox
  (@x, @y, @w, @h) ->
    @xx = @x + @w
    @yy = @y + @h
    @colliding = no

  draw: ->
    it.set-line-color if @colliding then \red else \white
    it.stroke-rect [ @x, @y ], [ @w, @h ]

  move-to: ([ x, y ]) ->
    @x = x - @w
    @y = y + @h/2

  intersects: ({ x, y, xx, yy }) ->
    @colliding = x > @x and y > @y

