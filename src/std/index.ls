
export id = -> it

export log = -> console.log.apply console, &; &0

export raf = window.request-animation-frame

export floor = Math.floor

export v2 =
  add   : (a, b) -> [ a.0 + b.0, a.1 + b.1 ]
  sub   : (a, b) -> [ a.0 - b.0, a.1 - b.1 ]
  scale : (f, v) -> [ v.0 * f, v.1 * f ]

export box = (n) -> [ n, n ]

