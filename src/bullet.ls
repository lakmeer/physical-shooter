
{ id, log, v2 } = require \std

{ CollisionBox } = require \./collision-box


#
# Bullet
#
# Blam
#

export class Bullet

  (@pos, @vel = [0 0], @acc = [(100 * Math.random! - 50), 1000]) ->
    @w     = 2
    @box   = new CollisionBox ...@pos, @w, @w
    @state =
      alive: yes
      hit: no

  update: (Δt) ->
    @vel = (@acc `v2.scale` Δt) `v2.add` @vel
    @pos = (@vel `v2.scale` Δt) `v2.add` @pos `v2.add` (@acc `v2.scale` (0.5 * Δt * Δt))

    @box.move-to @pos
    @state.alive = @pos.1 <= 150

    return @state.alive and not @state.hit

  draw: ->
    it.set-color if @state.hit then \red else \yellow
    it.rect [@pos.0 - @w/2, @pos.1 + @w/2], [ @w, @w * (3 + @vel.1/100) ]
    @box.draw it

