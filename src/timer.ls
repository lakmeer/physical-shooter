
{ id, log } = require \std


#
# Timer
#
# Becomes inactive once completed. Other types can be added
#

export class Timer
  (@target, @active = no) ->
    @current = 0
    @elapsed = not @active

  update: (Δt, time) ->
    if @active
      @current += Δt

      if @current > @target
        @current %= @target
        @active = no
        @elapsed = yes

  get-progress: ->
    @current/@target

  reset: ->
    if @current > @target
      @current %= @target
    else
      @current = 0

    @active = yes
    @elapsed = no

