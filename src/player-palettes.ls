
{ id, log, rgb } = require \std


#
# Player Palettes
#
# Also, some enemies
#

export red =
  stray-color: \red
  laser-color: -> rgb(1, it, it)
  bullet-color: -> \#E24F58 # rgb(1-it, 0, 0)
  paintjob: <[ darkred lightblue darkred ]>
  vortex-particle-color: \#600
  ui-color: \red
  selector-image: \/assets/ship-red.png

export blue =
  stray-color: \blue
  laser-color: -> rgb(it, it, 1)
  bullet-color: -> \#4296dB # rgb(0, 0, 1-it)
  paintjob: <[ darkblue lightblue royalblue ]>
  vortex-particle-color: \#005
  ui-color: \blue
  selector-image: \/assets/ship-blue.png

export green =
  stray-color: \forestgreen
  laser-color: -> rgb(0.9*it, 1, 0.9*it)
  bullet-color: -> \#00A361 #rgb(0, 0.9*(1-it), 0)
  paintjob: <[ darkgreen lightblue forestgreen ]>
  vortex-particle-color: \#050
  ui-color: \#0f0
  selector-image: \/assets/ship-green.png

export magenta =
  stray-color: \magenta
  laser-color: -> rgb(1, it, 1)
  bullet-color: -> \#c446c1 #rgb(1-it, 0, 1-it)
  paintjob: <[ purple lightblue magenta ]>
  vortex-particle-color: \#606
  ui-color: \#f0f
  selector-image: \/assets/ship-magenta.png

export cyan =
  stray-color: \cyan
  laser-color: -> rgb(it, 1, 1)
  bullet-color: -> \#52c6cB #rgb(0, 1-it, 1-it)
  paintjob: <[ cyan lightblue skyblue ]>
  vortex-particle-color: \#055
  ui-color: \#0ff
  selector-image: \/assets/ship-cyan.png

export yellow =
  stray-color: \yellow
  laser-color: -> rgb(1, 1, it)
  bullet-color: -> \#F7CF50 # rgb(1-it, 1-it, 0)
  paintjob: <[ yellow lightblue gold ]>
  vortex-particle-color: \#660
  ui-color: \#ff0
  selector-image: \/assets/ship-yellow.png

export grey =
  stray-color: \white
  laser-color: -> rgb(1, 1, 1)
  bullet-color: -> \#ddd
  paintjob: <[ lightgrey lightgrey lightgrey ]>
  vortex-particle-color: \black


# Enemies

export enemy =
  bullet-color: -> \white

