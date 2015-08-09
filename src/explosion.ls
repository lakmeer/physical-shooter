
{ id, log, box, rnd, v2, floor, physics } = require \std

rvel = (n = 100) -> [ n/2 - (rnd n), n/2 - (rnd n) ]

export class Explosion

  particle-types =
    * size: 15
      life: -> 0.3 + rnd 0.7
      color: -> "hsl(#{(rnd 60) - it*20}, #{ 50 - it*it*50}%, 50%)"
      limit: 10
      speed: 100
      damp: 0.95

    * size:  5
      life: -> 0.3 + rnd 0.1
      color: -> "hsl(60, #{100 - it*100}%, 80%)" #{rnd 100}%)"
      limit: 5
      speed: 500
      damp: 0.94

    * size:  1
      life: -> rnd 0.5
      color: -> \black
      limit: 2
      speed: 2000
      damp: 0.9

  new-particle = (pos, speed, damp, life) ->
    vel = rvel speed
    pos: [pos.0, pos.1]
    vel: vel
    acc: [0 0]
    age: 0
    life: life
    friction: damp

  (@pos = [-50, 50], @scale = 1, @tint-color = \white) ->
    @particles = [[] [] []]

    @state =
      age: 0
      life: 1.5 + 0.5 * @scale
      alive: yes

    for { speed, life, damp, limit }, i in particle-types
      if i is 2 then limit *= @scale * 2
      for p from 0 til limit
        @particles[i]push new-particle @pos, speed * @scale, damp, life!*0.5 + @scale/2 * life!

  update: (Δt) ->
    for set, type in @particles
      for p in set
        physics p, Δt
        p.age += Δt

    @state.age += Δt
    @state.alive = @state.age < @state.life

  draw: (ctx) ->
    ctx.ctx.global-composite-operation = \screen
    ctx.ctx.global-composite-operation = \lighter

    for set, type in @particles
      { size, color } = particle-types[type]

      for p in set when p.age < p.life
        ctx.ctx.global-alpha = 1 - p.age/p.life
        ctx.set-color color p.age/p.life, @tint-color
        ctx.circle p.pos, size * @scale

    ctx.ctx.global-alpha = 1
    ctx.ctx.global-composite-operation = \source-over

