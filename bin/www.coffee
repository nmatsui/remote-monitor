debug = require('debug')('remote-monitor')
app = require('../app')

app.set('port', process.env.ROOT || 3000)
server = app.listen app.get('port'), ->
  debug "Express server listening on port #{server.address().port}"

PeerServer = require('peer').PeerServer
new PeerServer
  port: 9000
  path: '/remote-monitor'
