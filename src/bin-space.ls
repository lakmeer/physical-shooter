
{ id, log, floor, v2 } = require \std

export class BinSpace

  { board-size } = require \config

  (@cols, @rows, @color = \red) ->

    @bin-size = [ board-size.0 * 2/@cols, board-size.1 * 2/@rows ]

    @bins =
      for y from 0 til @rows
        for x from 0 til @cols
          []

  bin-address: (pos) ->
    x = floor (-board-size.0 + pos.0) / @bin-size.0 + @cols
    y = floor (-board-size.1 - pos.1) / @bin-size.1 + @rows
    [x, y]

  clear: ->
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

  assign-bin: ({pos}:entity) ->
    [x, y] = @bin-address pos
    @bins[y]?[x]?.push entity

  get-bin-collisions: ({pos}:entity) ->
    [x, y] = @bin-address pos
    members = @bins[y][x]

    if y > 0
      members = members.concat @bins[y-1][x]
      if x > 0
        members = members.concat @bins[y-1][x-1]
      if x < @cols - 1
        members = members.concat @bins[y-1][x+1]

    if x > 0
      members = members.concat @bins[y][x-1]
    if x < @cols - 1
      members = members.concat @bins[y][x+1]

    if y < @rows - 1
      members = members.concat @bins[y+1][x]
      if x > 0
        members = members.concat @bins[y+1][x-1]
      if x < @cols - 1
        members = members.concat @bins[y+1][x+1]

    return members

