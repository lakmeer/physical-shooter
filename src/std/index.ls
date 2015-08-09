
export id = -> it

export log = -> console.log.apply console, &; &0

export raf = window.request-animation-frame

export floor = Math.floor

export sqrt = Math.sqrt

export min = Math.min

export max = Math.max

export asin = Math.asin

export v2 =
  hyp   : (v) -> sqrt (v.0 * v.0 + v.1 * v.1)
  norm  : (v) -> d = v2.hyp v; if d is 0 then [0 0] else [ v.0/d, v.1/d ]
  add   : (a, b) -> [ a.0 + b.0, a.1 + b.1 ]
  sub   : (a, b) -> [ a.0 - b.0, a.1 - b.1 ]
  scale : (v, f) -> [ v.0 * f, v.1 * f ]
  dist  : (a, b) -> x = [b.0 - a.0]; y = [b.1 - a.1]; sqrt x*x+y*y

export box = (n) -> [ n, n ]

export rnd = (n) -> n * Math.random!

export pi = Math.PI

export tau = pi * 2

export flip = (λ) -> (a, b) -> λ b, a

export delay = flip set-timeout

export limit = (min, max, n) --> if n < min then min else if n > max then max else n

export wrap = (min, max, n) --> if n < min then max else if n > max then min else n

export z = -> floor it * 255

export rgb = (r,g,b) -> "rgb(#{z r},#{z g},#{z b})"


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

