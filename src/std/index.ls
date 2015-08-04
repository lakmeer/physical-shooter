
export id = -> it

export log = -> console.log.apply console, &; &0

export raf = window.request-animation-frame

export floor = Math.floor

export v2 =
  add   : (a, b) -> [ a.0 + b.0, a.1 + b.1 ]
  sub   : (a, b) -> [ a.0 - b.0, a.1 - b.1 ]
  scale : (v, f) -> [ v.0 * f, v.1 * f ]

export box = (n) -> [ n, n ]

export rnd = (n) -> n * Math.random!

export pi = Math.PI

export tau = pi * 2

export flip = (λ) -> (a, b) -> λ b, a

export delay = flip set-timeout


# Physics processors

export physics = (o, Δt) ->
  f = if o.friction then that else 1
  o.vel = ((o.acc `v2.scale` Δt) `v2.add` o.vel) `v2.scale` f
  o.pos = (o.vel `v2.scale` Δt) `v2.add` o.pos `v2.add` (o.acc `v2.scale` (0.5 * Δt * Δt))

export dampen = (o, damp, Δt) ->
  o.vel = (o.vel `v2.scale` damp)
  o.pos = (o.vel `v2.scale` Δt) `v2.add` o.pos


# Special logging

color-log = (col) -> (text, ...rest) ->
  log \%c + text, "color: #col", ...rest

red-log   = color-log '#e42'
green-log = color-log '#1d3'

export sfx = color-log '#28e'

