
{ id, log } = require \std


#
# Normal Timer
#
# Becomes inactive once completed but resets whenever you want
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

  start: ->
    @active = yes
    @elapsed = no

  reset: ->
    if @current > @target
      @current %= @target
    else
      @current = 0

    @active = yes
    @elapsed = no

#
# Recurring Timer
#
# Recurring Timer just goes over and over and doesn't stop.
# It's 'elapsed' for exactly one tick and doesn't have a reset.
#

export class RecurringTimer extends Timer
  (@target, @active = no) ->
    @current = 0
    @elapsed = not @active

  update: (Δt, time) ->
    if @elapsed
      @elapsed = no

    @current += Δt

    if @current > @target
      @current %= @target
      @elapsed = yes


#
# One Shot Timer
#
# Once triggered, will run exactly once and then stop.
# Only resets if not currently in progress.
#

export class OneShotTimer extends Timer
  (@target, @active = no) ->
    @current = 0
    @ready = not @active
    @elapsed = not @active

  update: (Δt, time) ->
    if @active
      @current += Δt

      if @current > @target
        @current = 0
        @active = no
        @elapsed = yes
        @ready = yes

  begin: ->
    if not @ready then return
    @active = yes
    @elapsed = no
    @ready = no

