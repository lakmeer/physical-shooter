
# Require

{ id, log } = require \std


{ Controls } = require \./controls
{ Selector } = require \./selector



#
# UI
#

export class UI

  MODE_SELECT_PLAYER = 1
  MODE_CAPTURE_INPUT = 2

  (@server) ->
    @dom      = document.body
    @selector = new Selector document.get-element-by-id \selector
    @controls = new Controls document.get-element-by-id \controls

    @state =
      mode: MODE_SELECT_PLAYER
      ship: null

  colors-available: (colors) ->
    @selector.set-available-colors colors

  set-bg-color: (color) ->
    @dom.style.background-color = color

  submit-selection: (selection) ->
    @server.emit \join, selection.index

  update: (Δt) ->
    switch @state.mode
    | MODE_SELECT_PLAYER =>
      @selector.update Δt

      if @selector.get-selection!
        @submit-selection that
        @set-bg-color that.palette.bullet-color 0
        @set-mode MODE_CAPTURE_INPUT

    | MODE_CAPTURE_INPUT =>
      @controls.update Δt
      @server.emit \p, ...@controls.consume-pending-input!

  set-mode: (mode) ->
    @state.mode = mode

    switch mode
    | MODE_SELECT_PLAYER =>
      @selector.show!
      @controls.hide!
      @controls.release-inputs!

    | MODE_CAPTURE_INPUT =>
      @selector.hide!
      @controls.show!
      @controls.bind-inputs!

  disconnected: ->
    console.warn 'Connection lost'
    @set-mode MODE_SELECT_PLAYER



  # Static

  @modes = { MODE_SELECT_PLAYER, MODE_CAPTURE_INPUT }

