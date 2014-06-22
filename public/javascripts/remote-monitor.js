// Generated by CoffeeScript 1.7.1
var ns;

ns = (function() {
  var debug, exports, host, path, port;
  exports = {};
  host = '192.168.1.122';
  port = 9000;
  path = '/remote-monitor';
  debug = 3;
  exports.RemoteMonitor = (function() {
    function RemoteMonitor() {
      console.log("constructor");
      this.peer = new Peer({
        host: host,
        port: port,
        path: path,
        debug: debug
      });
    }

    RemoteMonitor.prototype.initialize = function(video, initializing, waiting) {
      console.log("initialize");
      initializing();
      navigator.getUserMedia = navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia;
      return navigator.getUserMedia({
        audio: true,
        video: true
      }, (function(_this) {
        return function(stream) {
          video.prop('src', URL.createObjectURL(stream));
          _this.ls = stream;
          _this.ls.getAudioTracks()[0].enabled = false;
          return waiting();
        };
      })(this), (function(_this) {
        return function() {
          return console.log("ビデオカメラとマイクへのアクセスに失敗しました");
        };
      })(this));
    };

    RemoteMonitor.prototype.onOpen = function(peerIDsetting) {
      console.log("onOpen");
      return this.peer.on('open', (function(_this) {
        return function() {
          console.log("peer.open");
          return peerIDsetting(_this.peer.id);
        };
      })(this));
    };

    RemoteMonitor.prototype.onError = function(waiting) {
      console.log("onError");
      return this.peer.on('error', (function(_this) {
        return function(err) {
          console.log("peer.error: " + err.message);
          return waiting();
        };
      })(this));
    };

    RemoteMonitor.prototype.onCall = function(video, connecting, waiting) {
      console.log("onCall");
      this.peer.on('call', (function(_this) {
        return function(call) {
          console.log("peer.call");
          call.answer(_this.ls);
          _this.__connect(call, video, waiting);
          return connecting();
        };
      })(this));
      return this.peer.on('connection', (function(_this) {
        return function(conn) {
          console.log("peer.connection");
          return conn.on('data', function(data) {
            console.log("conn.data " + data);
            switch (data) {
              case 'mic-on':
                console.log("event: mic-on");
                return _this.ls.getAudioTracks()[0].enabled = true;
              case 'mic-off':
                console.log("event: mic-off");
                return _this.ls.getAudioTracks()[0].enabled = false;
              default:
                return console.log("event: unknown");
            }
          });
        };
      })(this));
    };

    RemoteMonitor.prototype.makeCall = function(callto, video, connecting, waiting) {
      var call;
      console.log("makeCall : " + callto);
      this.callto = callto;
      call = this.peer.call(callto, this.ls);
      this.__connect(call, video, waiting);
      return connecting();
    };

    RemoteMonitor.prototype.closeCall = function() {
      console.log("closeCall");
      return this.ec.close();
    };

    RemoteMonitor.prototype.toggleMIC = function() {
      var conn, state;
      state = this.ls.getAudioTracks()[0].enabled;
      console.log("toggleMIC state:" + state);
      this.ls.getAudioTracks()[0].enabled = !state;
      conn = this.peer.connect(this.callto);
      return conn.on('open', (function(_this) {
        return function() {
          if (state) {
            return conn.send('mic-off');
          } else {
            return conn.send('mic-on');
          }
        };
      })(this));
    };

    RemoteMonitor.prototype.terminate = function() {
      return this.peer.destroy();
    };

    RemoteMonitor.prototype.__connect = function(call, video, waiting) {
      console.log("__connect");
      if (this.ec != null) {
        this.ec.close();
      }
      call.on('stream', (function(_this) {
        return function(stream) {
          return video.prop('src', URL.createObjectURL(stream));
        };
      })(this));
      call.on('close', waiting);
      return this.ec = call;
    };

    return RemoteMonitor;

  })();
  return exports;
})();
