
{ id, log, box, rnd, v2 } = require \std

physics = (o, Δt) ->
  o.vel = (o.acc `v2.scale` Δt) `v2.add` o.vel
  o.pos = (o.vel `v2.scale` Δt) `v2.add` o.pos `v2.add` (o.acc `v2.scale` (0.5 * Δt * Δt))

dampen = (o, Δt) ->
  o.vel = (o.vel `v2.scale` (0.96))
  o.pos = (o.vel `v2.scale` Δt) `v2.add` o.pos


rvel = (n = 100) -> [ n/2 - (rnd n), n/2 - (rnd n) ]

export class Explosion
  particle-a-limit = 15
  particle-b-limit = 10
  particle-c-limit = 2

  particle-color = [
    (life) -> "hsl(#{rnd 80 - life*80}, #{100 - life*100}%, #{100 - life*100}%)"
    (life) -> "hsl(60,        #{100 - life*100}%, #{100 - life*100}%)"
    (life) -> \white
  ]

  particle-size = [ 30 5 2 ]

  (@pos = [-50, 50]) ->
    @particles = [[] [] []]

    @state =
      alive: yes
      age: 0
      life: 2

    new-particle = (pos, speed, life) ->
      vel = rvel speed
      pos: [pos.0, pos.1]
      vel: vel
      acc: [0 0]
      age: 0
      life: life

    for i from 0 til particle-a-limit
      @particles.0.push new-particle @pos, 50, 1 + rnd 1

    for i from 0 til particle-b-limit
      @particles.1.push new-particle @pos, 100, 1 + rnd 1

    for i from 0 til particle-c-limit
      @particles.2.push new-particle @pos, 1000, 0 + rnd 2

  update: (Δt) ->
    for set in @particles
      for p in set
        dampen p, Δt
        p.age += Δt

    @state.age += Δt
    @state.alive = @state.age < @state.life

  draw: (ctx) ->
    ctx.ctx.global-composite-operation = \screen

    for set, type in @particles
      size = particle-size[type]

      for p in set when p.age < p.life
        ctx.ctx.global-alpha = 1 - p.age/p.life
        ctx.set-color particle-color[type] p.age/p.life
        ctx.circle p.pos, size

    ctx.ctx.global-alpha = 1
    ctx.ctx.global-composite-operation = \source-over

