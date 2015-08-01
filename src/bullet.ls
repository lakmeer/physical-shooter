
{ CollisionBox } = require \./collision-box


#
# Bullet
#
# Blam
#

export class Bullet

  { bullet-speed, screen-size } = require \config

  (@pos) ->
    @w = 0.01
    @l = @w * 20
    @state = alive: yes
    @box   = new CollisionBox ...@pos, @w, @l

  update: (Δt) ->
    @pos.1 += bullet-speed/screen-size
    @state.alive = @pos.1 <= 1.2
    @box.move-to @pos

  draw: ->
    it.set-color \yellow
    it.rect [@pos.0 - @w, @pos.1], [ @w, @l ]
    @box.draw it

