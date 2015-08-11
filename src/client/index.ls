
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
  driver.start!

server.on \available, (colors) ->
  ui.colors-available colors

server.on \disconnect, ->
  ui.disconnected!
  driver.stop!

driver.on-tick (Δt, time) ->
  ui.update Δt


#
# Init
#

if window.location.hash is \#debug   # Debug - delay start so master can load first
  delay (random-range 1000, 2000), -> server.emit \is-client
else
  server.emit \is-client

