var http  = require('http');
var mosca = require('mosca');


var ascoltatore = {
  //using ascoltatore
  type: 'mongo',
  url: 'mongodb://localhost:27017/mqtt',
  pubsubCollection: 'ascoltatori',
  mongo: {}
};

var settings = {
  port: 1883,
  backend: ascoltatore
};

// Create the Servers
var wsServer = http.createServer();
var mqttServer = new mosca.Server(settings);

// Make them listen
mqttServer.attachHttpServer(wsServer);
wsServer.listen(3000);

mqttServer.on('clientConnected', function(client) {
    console.log('client connected', client.id);
});

// fired when a message is received
mqttServer.on('published', function(packet, client) {
  console.log('>> Published', packet.payload);
});

mqttServer.on('ready', function() {
	console.log('Mosca server is up and running');
});


