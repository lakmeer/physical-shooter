
{ id, log, rgb } = require \std


#
# Player Palettes
#
# Also, some enemies
#

export red =
  stray-color: \red
  laser-color: -> rgb(1, it, it)
  bullet-color: -> rgb(1-it, 0, 0)
  paintjob: <[ darkred lightblue darkred ]>

export blue =
  stray-color: \blue
  laser-color: -> rgb(it, it, 1)
  bullet-color: -> rgb(0, 0, 1-it)
  paintjob: <[ darkblue lightblue royalblue ]>

export green =
  stray-color: \forestgreen
  laser-color: -> rgb(0.9*it, 1, 0.9*it)
  bullet-color: -> rgb(0, 0.5*(1-it), 0)
  paintjob: <[ darkgreen lightblue forestgreen ]>

export magenta =
  stray-color: \magenta
  laser-color: -> rgb(1, it, 1)
  bullet-color: -> rgb(1-it, 0, 1-it)
  paintjob: <[ purple lightblue magenta ]>

export cyan =
  stray-color: \cyan
  laser-color: -> rgb(it, 1, 1)
  bullet-color: -> rgb(0, 1-it, 1-it)
  paintjob: <[ cyan lightblue skyblue ]>

export yellow =
  stray-color: \yellow
  laser-color: -> rgb(1, 1, it)
  bullet-color: -> rgb(1-it, 1-it, 0)
  paintjob: <[ yellow lightblue gold ]>


# Enemies

export enemy =
  bullet-color: -> \white

