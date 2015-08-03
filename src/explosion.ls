
{ id, log, box, rnd, v2 } = require \std

physics = (o, Δt) ->
  o.vel = (o.acc `v2.scale` Δt) `v2.add` o.vel
  o.pos = (o.vel `v2.scale` Δt) `v2.add` o.pos `v2.add` (o.acc `v2.scale` (0.5 * Δt * Δt))

dampen = (o, Δt) ->
  o.vel = (o.vel `v2.scale` (0.96))
  o.pos = (o.vel `v2.scale` Δt) `v2.add` o.pos

rvel = (n = 100) -> [ n/2 - (rnd n), n/2 - (rnd n) ]


export class Explosion

  particle-types =
    * size: 20
      life: -> 0.3 + rnd 0.7
      color: -> "hsl(#{(rnd 80) - it*80}, 50%, 50%)"
      limit: 15
      speed: 50

    * size:  5
      life: -> 0.7 + rnd 0.3
      color: -> "hsl(60, #{100 - it*100}%, #{100 - it*100}%)"
      limit: 10
      speed: 100

    * size:  3
      life: -> 0.2 + rnd 0.3
      color: -> \white
      limit: 3
      speed: 1000

  new-particle = (pos, speed, life) ->
    vel = rvel speed
    pos: [pos.0, pos.1]
    vel: vel
    acc: [0 0]
    age: 0
    life: life

  (@pos = [-50, 50]) ->
    @particles = [[] [] []]

    @state =
      age: 0
      life: 2
      alive: yes


    for { speed, life, limit }, i in particle-types
      for p from 0 til limit
        @particles[i]push new-particle @pos, speed, life!

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
      { size, color } = particle-types[type]

      for p in set when p.age < p.life
        ctx.ctx.global-alpha = 1 - p.age/p.life
        ctx.set-color color p.age/p.life
        ctx.circle p.pos, size

    ctx.ctx.global-alpha = 1
    ctx.ctx.global-composite-operation = \source-over

