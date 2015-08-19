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

var http_port = 3000

// Create the Servers
var wsServer = http.createServer();
var mqttServer = new mosca.Server(settings);

// Make them listen
mqttServer.attachHttpServer(wsServer);
wsServer.listen(http_port);

mqttServer.on('clientConnected', function(client) {
    console.log('=> Client connected with id:"' + client.id + '"');
});


mqttServer.on('ready', function() {
  console.log('== Mosca Server is Up and Running ==');
  console.log('   MQTT Port: ' + settings.port);
  console.log('   HTTP Port: ' + http_port);
});


mqttServer.on('published', function(packet, client) {
  console.log('>> Published to "' + packet.topic + '"', packet.payload);
  var str = Buffer(packet.payload).toString();
  console.log('   String: "' + str + '"');
});

mqttServer.on("subscribed", function(topic, client) {
  console.log('<< Subscribed to "' + topic + '"');
});

mqttServer.on('clientDisconnected', function(client) {
  
  console.log('Client Disconnected:', client.id);

  var message = {
    topic: client.id+'/status',
    payload: 'Offline', 
    qos: 0, 
    retain: true
  };

  mqttServer.publish(message, function() {
    console.log('done!');
  });

});


