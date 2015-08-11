
// Require
var SocketServer = require('socket.io');
var http   = require('http');

// Helpers
var id     = function (it) { return it; };
var log    = function () { console.log.apply(console, arguments); return arguments[0]; };

// Config
var config = { port: 9999 };
var playerTimeout = 5000;
var colors = [ 'red', 'blue', 'green', 'magenta', 'cyan', 'yellow' ];

// Player Factory
var Player = function (index) {
  return {
    index: index,
    color: colors[index],
    free: true,
    lastSeen: 0,
    socket: null,
    isLocal: false
  };
}

// State
var master = { emit: id }

var players = [];
var clientIds = {};
for (var i = 0; i < 6; i++) { players.push(Player(i)); }


// Servers
//var server = http.createServer().listen(config.port);
//var io = socket.listen(server);

var io = new SocketServer(config.port);


console.log('Running signalling server on ' + config.port);

// Functions
function freePlayer (playerIndex) {
  var player = players[playerIndex];
  player.free = true;
  player.socket = null;
  player.lastSeen = 0;
  player.isLocal = false;
}

function clearPlayers () {
  for (var i in players) {
    freePlayer(i);
  }
}

function claimPlayer (playerIndex, socket, isLocal) {
  var player = players[playerIndex];
  if (player.free) {
    player.socket = socket;
    player.free = false;
    player.lastSeen = Date.now();
    player.isLocal = !!isLocal;
    return true;
  }
  return false;
}

function isFree (player) {
  return player.free;
}

function createSelection (player) {
  return {
    free: player.free,
    color: player.color,
    index: player.index
  };
}

function reportPlayers () {
  log("Player Roster:");
  players.forEach(function (player) {
    log("  " + player.index + ": " + (player.free ? "----" : "LIVE") + " (" + player.color + ")" + (player.isLocal ? " (local)" : ""));
  });
}

function sendAvailablePlayers () {
  this.emit('available', players.map(createSelection));
}

function passSocket (socket, λ) {
  return function () {
    λ.apply(socket, arguments);
  };
}

function becomeMaster () {
  log('MASTER ATTACHED');
  reportPlayers();
  master = this;
  clearPlayers();
  clientIds = {};
  sendAvailablePlayers.apply(io);
};

function becomePlayer () {
  sendAvailablePlayers.apply(this);
  clientIds[this.id] = true;
}



// Socket callbacks
io.on('connection', function (socket) {

  var myPlayerIndex = 0;

  // Check for errors emitted by the socket engine
  socket.on('error',  log);

  // Deterimine role
  socket.on('is-master', passSocket(socket, becomeMaster));
  socket.on('is-client', passSocket(socket, becomePlayer));


  // Player functions

  socket.on('master-join', function onMasterJoin (playerIndex) {
    log('Master join:', colors[playerIndex]);

    if (claimPlayer(playerIndex, socket, true)) {
      myPlayerIndex = playerIndex;
      sendAvailablePlayers.apply(io);
      reportPlayers();
    } else {
      log('Master tried to claim player ' + playerIndex + ' but it was taken');
    }
  });

  socket.on('join', function onJoin (playerIndex) {
    log('Player join:', colors[playerIndex]);

    if (claimPlayer(playerIndex, socket)) {
      myPlayerIndex = playerIndex;
      master.emit('pj', playerIndex);
      sendAvailablePlayers.apply(io);
    } else {
      sendAvailablePlayers.apply(socket);
    }
    reportPlayers();
  });

  socket.on('p', function playerUpdate (x, y, command) {
    if (clientIds[socket.id]) {
      master.emit('p', myPlayerIndex, x, y, command);
      players[myPlayerIndex].lastSeen = Date.now();
    } else {
      socket.emit('reconnect');
    }
  });

  socket.on('disconnect', function () {
    log('Player lost:', myPlayerIndex);

    log(socket.id, clientIds);

    // If this socket isn't in the clientIds list, it doesn't have the right
    // to deallocate that player

    if (clientIds[socket.id]) {
      master.emit('pd', myPlayerIndex);
      freePlayer(myPlayerIndex);
      delete clientIds[socket.id];
    } else {
      socket.emit('reconnect');
    }
    reportPlayers();
  });

});


// Disconnect Monitor

// Start a timer
//
// On timer tick:
//   Check current time
//   Check all the connected player's last seen times
//   If player's haven't been heard from in 5 seconds
//     disconnect them and free their color

setInterval(function checkLastSeen () {
  var now = Date.now();

  players.forEach(function (player) {
    if (!player.free && !player.isLocal && (now - player.lastSeen) > playerTimeout) {
      log('Player index expired:', player.index);
      reportPlayers();
      master.emit('pd', player.index);
      freePlayer(player.index);
    }
  });
}, 500);

