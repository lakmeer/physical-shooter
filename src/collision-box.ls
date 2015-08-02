
{ test } = require \test

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
      ( left  <=  @left  < right or right >= @right >  left ) and
      (bottom <= @bottom <  top  or  top  >=  @top  > bottom)

#
# Tests
#

test "CollisionBox - intersection", ->

  a = new CollisionBox 0,  0, 10, 10
  b = new CollisionBox 0, 20, 10, 10

  @equal "Does not intersect when clearly apart Y"
  .expect a.intersects b
  .to-be false

  b.move-to [ 20, 0 ]
  @equal "Does not intersect when clearly apart X"
  .expect a.intersects b
  .to-be false

  b.move-to [ 2, 2 ]
  @equal "Intersects when clearly overlapping"
  .expect a.intersects b
  .to-be true

  b.move-to [ 0, 10 ]
  @equal "Does not intersect when abutted (top)"
  .expect a.intersects b
  .to-be false

  b.move-to [ -10, 0 ]
  @equal "Does not intersect when abutted (left)"
  .expect a.intersects b
  .to-be false

  b.move-to [ 10, 0 ]
  @equal "Does not intersect when abutted (right)"
  .expect a.intersects b
  .to-be false

  b.move-to [ 0, -10 ]
  @equal "Does not intersect when abutted (bottom)"
  .expect a.intersects b
  .to-be false

