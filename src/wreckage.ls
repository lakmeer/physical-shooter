
{ id, log, max, box, rnd, v2, dampen } = require \std

rvel = (n = 100) -> [ n/2 - (rnd n), n/2 - (rnd n) ]


export class Wreckage

  new-particle = (pos, speed, damp, life) ->
    vel = rvel speed
    pos: [pos.0, pos.1]
    vel: vel
    acc: [0 0]
    age: 0
    life: life
    friction: damp

  limit = 3
  speed = 100
  damp = 0.99
  life = -> rnd 1
  size = [10 10]

  (@pos, @sprite) ->
    @particles = []

    @state =
      age: 0
      life: 1
      alive: yes

    for p from 0 til limit
      @particles.push new-particle @pos, speed, damp, life!

  update: (Δt) ->
    for p in @particles
      dampen p, damp, Δt
      p.age += Δt

    @state.age += Δt
    @state.alive = @state.age < @state.life

  draw: (ctx) ->
    for p in @particles
      t = p.age/p.life
      ctx.ctx.global-alpha = max 0, 1 - t #if t > 0.7 then 5 < t * 100 % 10 else 1
      ctx.sprite @sprite, p.pos, size
      ctx.ctx.global-alpha = 1

