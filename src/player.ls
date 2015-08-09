
{ id, log, limit, floor, v2, pi } = require \std

{ RadialCollider } = require \./collider
{ Physics } = require \./physics
{ Timer } = require \./timer
{ PlayerBullet, Laser } = require \./bullet

{ sprite, palette-sprite } = require \./sprite


# Generate graphic

lumin = sprite \/assets/ship-luminosity.svg, 200

color-schemes = [
  <[ darkred lightblue darkred ]>
  <[ darkblue lightblue royalblue ]>
  <[ darkgreen lightblue forestgreen ]>
  <[ purple lightblue magenta ]>
  <[ cyan lightblue skyblue ]>
  <[ yellow lightblue gold ]>
]

color-map = \/assets/ship-colormap.svg
lumin-map = \/assets/ship-luminosity.svg

ship-sprites = color-schemes.map (palette) ->
  palette-sprite color-map, lumin-map, palette, 200


#
# Player
#
# Contains things common to Players and Enemies
#

export class Player

  { board-size } = require \config

  laser-rate    = 2
  bullet-rate   = 0.05

  sprite-size   = [ 30, 30 ]
  sprite-offset = sprite-size `v2.scale` 0.5

  ch   = -> floor it * 255
  ich  = -> 255 - floor it * 255
  rgb  = (r, g, b) -> "rgb(#{ch r},#{ch g},#{ch b})"
  irgb = (r, g, b) -> "rgb(#{ich r},#{ich g},#{ich b})"

  ship-colors = [
    -> \red #rgb it, 0, 0
    -> \green #rgb 0, 0, it
    -> \blue #rgb 0, it*0.9, 0
    -> \magenta #rgb 0, it, it
    -> \cyan #rgb it, it, 0
    -> \yellow #rgb it, 0 , it
  ]

  z = -> floor it * 255

  rgb = (r,g,b) -> "rgb(#{z r},#{z g},#{z b})"

  ship-colors = [
    -> rgb(1-it, 0, 0)
    -> rgb(0, 0, 1-it)
    -> rgb(0, 0.9*(1-it), 0)
    -> rgb(1-it, 0, 1-it)
    -> rgb(0, 1-it, 1-it)
    -> rgb(1-it, 1-it, 0)
  ]


  (@index) ->
    @bullets   = []
    @lasers    = []
    @physics   = new Physics [0 20 - board-size.1]
    @collider  = new RadialCollider 0, 0, 10
    @auto-move = yes
    @score     = 0

    log "New Player: color=", @derive-bullet-color 1

    @damage =
      health: 200
      max-hp: 200

    @forcefield-phase = 0
    @forcefield-active = no

    @stray-color = ship-colors[@index]
    @explosion-tint-color = ship-colors[@index] 0

    @bullet-timer = new Timer bullet-rate
    @laser-timer = new Timer laser-rate

  kill: ->
    @dead = true
    @bullets = []

  unkill: ->
    @dead = false
    @damage.health = @damage.max-hp

  derive-color: ->
    p = limit 0, 1, @damage.health / @damage.max-hp
    ship-colors[@index] p

  derive-bullet-color: (p) ->
    ship-colors[@index] p

  auto-pilot: (time) ->
    m = Math.sin time + @index * pi / 3
    g = Math.cos time + @index * pi / 6
    @physics.pos.0 = board-size.0 * 0.98 * m # * Math.abs(m)
    @physics.pos.1 = -board-size.1 + board-size.1/3 + g * board-size.1/5

  update: (Δt, time) ->
    if @dead then return
    if @auto-move then @auto-pilot time

    pos = @physics.pos

    @forcefield-phase += Δt * 40
    @bullets = @bullets.filter (.update Δt)
    @lasers  = @lasers.filter (.update Δt, pos)

    @laser-timer.update Δt
    @bullet-timer.update Δt

    if @bullet-timer.expired
      @shoot!
      @bullet-timer.reset!

    @collider.move-to @physics.pos

  move-to: (pos) ->
    @physics.move-to pos
    @collider.move-to pos

  draw: (ctx) ->
    if @dead then return
    @draw-forcefield ctx if @forcefield-active
    @bullets.map (.draw ctx)
    @lasers.map (.draw ctx)
    ctx.sprite ship-sprites[@index], @physics.pos, sprite-size, offset: sprite-offset

  draw-forcefield: (ctx) ->
    shells = 4
    shell-gap = 20
    max-diam = 10 + shells * shell-gap
    ctx.set-line-color \white
    for shell from 0 til shells
      diam = 10 + shell * shell-gap + @forcefield-phase % shell-gap
      ctx.ctx.global-alpha = 1 - diam/max-diam
      ctx.stroke-circle @physics.pos, diam
    ctx.ctx.global-alpha = 1

  shoot: ->
    if @dead then return
    if @laser-timer.active then return
    if not @bullet-timer.active
      @bullets.push new PlayerBullet [ @physics.pos.0 - 3, @physics.pos.1 + 5 ], this
      @bullets.push new PlayerBullet [ @physics.pos.0 + 3, @physics.pos.1 + 5 ], this
      @bullet-timer.active = yes

  laser: (shaker) ->
    if @dead then return
    if @laser-timer.active is no
      @lasers.push new Laser [ @physics.pos.0, @physics.pos.1 ], this
      @laser-timer.active = yes
      if shaker?
        shaker.trigger-after 0.5, 10, 2.5
      return true
    return false

  dont-auto-move: ->
    @auto-move = no

  collect: (item) ->
    item.collected = yes
    #log @index, @score += 1


