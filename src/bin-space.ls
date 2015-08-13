
{ id, log, floor, v2 } = require \std

export class BinSpace

  { board-size } = require \config

  (@cols, @rows, @color = \blue) ~>
    @bins = @init-bins!
    @bin-size = [ board-size.0 * 2/@cols, board-size.1 * 2/@rows ]

  clear: -> @init-bins!

  init-bins: ->
    @bins = [ [ [] for x from 0 til @cols ] for y from 0 til @rows ]

  draw: (ctx) ->
    ctx.set-color @color
    for row, y in @bins
      for bin, x in row
        if bin.length
          ctx.ctx.global-alpha = 0.1 * bin.length
          ctx.rect [
            -board-size.0 + x * @bin-size.0,
             board-size.1 - y * @bin-size.1
          ], @bin-size
    ctx.ctx.global-alpha = 1

  get-bin: (x, y) ->
    if x < 0 or x >= @cols
      []
    else if y < 0 or y >= @rows
      []
    else
      @bins[y][x]

  bin-address: ([ x, y ]) ->
    #log \addre, x, y, board-size, @bin-size, @cols, @rows
    [ (floor (-board-size.0 + x) / @bin-size.0 + @cols),
      (floor (-board-size.1 - y) / @bin-size.1 + @rows) ]

  assign-bin: (entity) ->
    #log \assign, entity
    [x, y] = @bin-address entity.physics?.pos
    #log \assign, x, y, entity
    @get-bin(x, y).push entity

  get-bin-collisions: (entity) ->
    [x, y] = @bin-address entity.physics?.pos
    #log \collision, x, y
    @accumulate-neighbours x, y

  accumulate-neighbours: (x, y) ->
    #log \accum, x, y
    [].concat @get-bin x - 1, y - 1
      .concat @get-bin x,     y - 1
      .concat @get-bin x - 1, y - 1
      .concat @get-bin x - 1, y
      .concat @get-bin x,     y
      .concat @get-bin x + 1, y
      .concat @get-bin x,     y + 1
      .concat @get-bin x - 1, y + 1
      .concat @get-bin x + 1, y + 1

