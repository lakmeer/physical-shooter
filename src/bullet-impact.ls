
export class BulletImpact

  rad = 10
  life = 0.1

  (@bullet) ->
    @color = @bullet.owner.palette.bullet-color 1
    @pos   = @bullet.physics.clone-pos!
    @life = life

  update: (Δt) ->
    @life -= Δt
    @life > 0

  draw: (ctx) ->
    ctx.set-color @color
    ctx.alpha @life/life
    ctx.circle @pos, rad
    ctx.alpha 1

