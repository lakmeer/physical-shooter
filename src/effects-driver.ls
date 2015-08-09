
export class EffectsDriver
  (@limit) ->
    @effects = []

  push: (effect) ->
    if @effects.length >= @limit
      @effects.shift!
    @effects.push effect

  update: (Δt, time) ->
    @effects = @effects.filter (.update Δt, time)

  draw: (ctx) ->
    @effects.map (.draw ctx)

