
#
# Collision Box
#
# Modular component for collision detection
#

export class CollisionBox
  (x, y, @w, @h) ->
    @move-to [ x, y ]
    @colliding = no

  draw: ->
    it.set-line-color if @colliding then \red else \white
    it.stroke-rect [ @left, @top ], [ @w, @h ]

  move-to: ([ @x, @y ]) ->
    @top    = @y + @h/2
    @left   = @x - @w/2
    @right  = @x + @w/2
    @bottom = @y - @h/2

  intersects: ({ left, right, top, bottom }) ->
    @colliding =
      ((@left > left and @left < right) or (@right < right and @right > left)) and
      ((@bottom > bottom and @bottom < top) or (@top < top and @top > bottom))

