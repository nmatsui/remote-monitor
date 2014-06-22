// Generated by CoffeeScript 1.7.1
(function() {
  var PeerServer, app, debug, server;

  debug = require('debug')('remote-monitor');

  app = require('../app');

  app.set('port', process.env.ROOT || 3000);

  server = app.listen(app.get('port'), function() {
    return debug("Express server listening on port " + (server.address().port));
  });

  PeerServer = require('peer').PeerServer;

  new PeerServer({
    port: 9000,
    path: '/remote-monitor'
  });

}).call(this);
