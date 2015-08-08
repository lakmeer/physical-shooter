
{ id, log, rnd, sqrt } = require \std

{ test } = require \test

intersect-box-with-radius = ({ left, right, top, bottom }, { x, y, rad }) ->


#
# Collision Radius
#
# Modular component for collision detection
#

export class CollisionRadius
  (x, y, @rad) ->
    @move-to [ x, y ]
    @colliding = no

  draw: (ctx, what) ->
    ctx.set-line-color if @colliding then \red else \white
    ctx.stroke-circle [ @x, @y ], @rad * 2

  move-to: ([ @x, @y ]) ->

  move-x: (@x) ->

  intersects: ({ x, y, rad }:target) ->
    xx = @x - x
    yy = @y - y
    dist = sqrt xx * xx + yy * yy
    @colliding = target.colliding = dist < @rad + rad


#
# Collision Box
#
# Modular component for collision detection
#

export class CollisionBox
  (x, y, @w, @h) ->
    @move-to [ x, y ]
    @colliding = no

  draw: (ctx, what) ->
    ctx.set-line-color if @colliding then \red else \white
    ctx.stroke-rect [ @left, @top ], [ @w, @h ]

  move-to: ([ @x, @y ]) ->
    @top    = @y + @h/2
    @left   = @x - @w/2
    @right  = @x + @w/2
    @bottom = @y - @h/2

  move-x: (@x) ->
    @top    = @y + @h/2
    @left   = @x - @w/2
    @right  = @x + @w/2
    @bottom = @y - @h/2

  intersects: ({ left, right, top, bottom }:target) ->
    a =
      ( left  <=  @left  < right or right >= @right >  left ) and
      (bottom <= @bottom <  top  or  top  >=  @top  > bottom)
    b =
      ( @left  <=  left  < @right or @right >= right >  @left ) and
      (@bottom <= bottom <  @top  or  @top  >=  top  > @bottom)

    @colliding = target.colliding = a or b


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




test "CollisionBox - speed", ->
  box-count = 1000
  new-box = -> new CollisionBox (rnd 100), (rnd 100), 10, 10
  boxes = [ new-box! for i from 0 til box-count ]
  label = "#{box-count * box-count} intersections"

  timer = ->
    start = Date.now!
    [ a.intersects b for b in boxes when b isnt a for a in boxes ]
    Date.now! - start

  average-time = (times, length) ->

  @equal label
  .expect do ->
    times = [ timer! for i from 1 to 10 ]
    (times.reduce (+), 0) / 10
  .to-be 0

