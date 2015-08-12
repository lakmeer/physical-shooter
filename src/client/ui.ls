
# Require

{ id, log } = require \std

{ Title }    = require \./title
{ Controls } = require \./controls
{ Selector } = require \./selector


#
# UI
#

export class UI

  MODE_NO_MODE       = 0
  MODE_TITLE_SCREEN  = 1
  MODE_SELECT_PLAYER = 2
  MODE_CAPTURE_INPUT = 3

  (@server) ->
    @dom      = document.body
    @title    = new Title    document.get-element-by-id \title
    @selector = new Selector document.get-element-by-id \selector
    @controls = new Controls document.get-element-by-id \controls

    @state =
      mode: MODE_NO_MODE
      ship: null

  start: ->
    @set-mode MODE_CAPTURE_INPUT

    # Debug
    @controls.set-ui-color \red

  colors-available: (colors) ->
    @selector.set-available-colors colors

  set-bg-color: (color) ->
    @dom.style.background-color = color

  submit-selection: (selection) ->
    @server.emit \join, selection.index

  update: (Δt, time) ->
    switch @state.mode
    | MODE_TITLE_SCREEN =>
      @title.update Δt, time
      if @title.state.ready
        @set-mode MODE_SELECT_PLAYER

    | MODE_SELECT_PLAYER =>
      @selector.update Δt, time
      if @selector.get-selection!
        @submit-selection that
        @controls.set-ui-color = that.palette.ui-color
        @set-bg-color that.palette.bullet-color 0
        @set-mode MODE_CAPTURE_INPUT

    | MODE_CAPTURE_INPUT =>
      @controls.update Δt, time
      @server.emit \p, ...@controls.consume-pending-input!

  set-mode: (mode) ->
    @state.mode = mode

    switch mode
    | MODE_TITLE_SCREEN =>
      @title.show!
      @selector.hide!
      @controls.hide!

    | MODE_SELECT_PLAYER =>
      @title.hide!
      @selector.show!
      @controls.hide!
      @controls.release-inputs!

    | MODE_CAPTURE_INPUT =>
      @title.hide!
      @selector.hide!
      @controls.show!
      @controls.bind-inputs!

  disconnected: ->
    console.warn 'Connection lost'
    @set-mode MODE_SELECT_PLAYER


  # Static

  @modes = { MODE_TITLE_SCREEN, MODE_SELECT_PLAYER, MODE_CAPTURE_INPUT }

