
# Require

{ id, log, tau, delay, random-range } = require \std

{ FrameDriver } = require \../frame-driver

{ UI } = require \./ui

SocketIO = require \socket.io-client


#
# Setup
#

driver = new FrameDriver true
server = new SocketIO window.location.hostname + \:9999
ui     = new UI server


# Callbacks

server.on \connect, ->
  delay 1000, ->
    driver.start!
    ui.start!
    server.emit \is-client

server.on \available, (colors) ->
  ui.colors-available colors

server.on \ch, (charge) ->
  log \charge-amount: charge

server.on \disconnect, ->
  ui.disconnected!
  #driver.stop!

driver.on-tick (Δt, time) ->
  ui.update Δt, time


#
# Init
#

s = -> window.scroll-to 0, 1

window.add-event-listener \load, s
window.add-event-listener \orientationchange, s

delay 1000, s

