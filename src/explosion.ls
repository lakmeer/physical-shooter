
{ id, log, box, rnd, v2, physics, dampen } = require \std

rvel = (n = 100) -> [ n/2 - (rnd n), n/2 - (rnd n) ]


export class Explosion

  particle-types =
    * size: 15
      life: -> 0.1 + rnd 0.4
      color: -> "hsl(#{(rnd 60) - it*20}, 50%, 50%)"
      limit: 15
      speed: 100
      damp: 0.98

    * size:  5
      life: -> 0.3 + rnd 0.5
      color: -> "hsl(60, #{100 - it*100}%, #{rnd 100}%)"
      limit: 5
      speed: 500
      damp: 0.94

    * size:  1
      life: -> rnd 0.5
      color: -> \white
      limit: 3
      speed: 10000
      damp: 0.8

  new-particle = (pos, speed, damp, life) ->
    vel = rvel speed
    pos: [pos.0, pos.1]
    vel: vel
    acc: [0 0]
    age: 0
    life: life
    friction: damp

  (@pos = [-50, 50]) ->
    @particles = [[] [] []]

    @state =
      age: 0
      life: 2
      alive: yes

    for { speed, life, damp, limit }, i in particle-types
      for p from 0 til limit
        @particles[i]push new-particle @pos, speed, damp, life!

  update: (Δt) ->
    for set, type in @particles
      for p in set
        dampen p, particle-types[type].damp, Δt
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

