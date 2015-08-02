
{ id, log, box, rnd, v2 } = require \std

physics = (o, Δt) ->
  o.vel = (o.acc `v2.scale` Δt) `v2.add` o.vel
  o.pos = (o.vel `v2.scale` Δt) `v2.add` o.pos `v2.add` (o.acc `v2.scale` (0.5 * Δt * Δt))

rvel = (n = 100) -> [ n/2 - (rnd n), n/2 - (rnd n) ]

export class Explosion
  particle-a-limit = 20
  particle-b-limit = 10
  particle-c-limit = 3

  particle-color = [
    (life) -> "hsl(#{rnd 40}, #{100 - life*100}%, #{100 - life*100}%)"
    (life) -> "hsl(60,        #{100 - life*100}%, #{100 - life*100}%)"
    (life) -> "hsl(200,       #{100 - life*100}%, #{100 - life*100}%)"
  ]

  particle-size = [ 10 5 2 ]

  (@pos = [-50, 50]) ->
    @particles = [[] [] []]

    @state =
      alive: yes
      age: 0
      life: 2

    new-particle = (pos, vel, life) ->
      pos: [pos.0, pos.1]
      vel: (rvel vel)
      acc: [0 0]
      age: 0
      life: life

    for i from 0 til particle-a-limit
      @particles.0.push new-particle @pos, 100, 1 + rnd 0.4

    for i from 0 til particle-b-limit
      @particles.1.push new-particle @pos,  20, 1 + rnd 1

    for i from 0 til particle-c-limit
      @particles.1.push new-particle @pos, 500, 0 + rnd 2

  update: (Δt) ->
    for set in @particles
      for p in set
        physics p, Δt
        p.age += Δt

    @state.age += Δt
    @state.alive = @state.age < @state.life

  draw: (ctx) ->
    for set, type in @particles
      for p in set when p.age < p.life
        size = particle-size[type]
        ctx.ctx.global-alpha = 1 - p.age/p.life
        ctx.ctx.global-composite-operation = \lighter
        ctx.set-color particle-color[type] p.age/p.life
        ctx.rect p.pos `v2.add` [-size/2 size/2], box size
        ctx.ctx.global-alpha = 1
        ctx.ctx.global-composite-operation = \source-over

