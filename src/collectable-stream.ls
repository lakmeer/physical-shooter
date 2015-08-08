
{ id, log } = require \std

export class CollectableStream
  (@items, @owner) ->
    for item in @items
      #bullet.vel = bullet.vel `v2.scale` 0.2
      item.stray = true
      item.owner = @owner
      item.color = @owner.stray-color 0
      item.friction = 0.99

  update: (Δt, time) ->
    owner = @owner
    @items = @items.filter (.update-stray Δt, owner)
    @items.length > 0

  draw: (ctx) ->
    @items.map (.draw ctx)

