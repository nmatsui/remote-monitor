var ns = (function() {
  var exports = {};

  var host = '192.168.1.122';
  var port = 9000;
  var path = '/remote-monitor';
  var debug = 3;

  var RemoteMonitor = function() {
    this.peer = new Peer({host: host, port: port, path: path, debug: debug});
    this.callto = null;
    this.ls = null;
    this.ec = null;
  }
  RemoteMonitor.prototype.initialize = function(video, initializing, waiting) {
    console.log('initialize');
    var self = this;
    initializing();
    navigator.getUserMedia = navigator.getUserMedia ||
                             navigator.webkitGetUserMedia ||
                             navigator.mozGetUserMedia;
    navigator.getUserMedia({audio: true, video: true}, function(stream) {
      video.prop('src', URL.createObjectURL(stream));
      self.ls = stream;
      self.ls.getAudioTracks()[0].enabled = false;
      waiting();
    },
    function() {
      alert('ビデオカメラとマイクへのアクセスに失敗しました');
    });
  }
  RemoteMonitor.prototype.onOpen = function(peerIDsetting) {
    var self = this;
    self.peer.on('open', function() {
      console.log('peer.open');
      peerIDsetting(self.peer.id);
    });
  }
  RemoteMonitor.prototype.onError = function(waiting) {
    var self = this;
    self.peer.on('error', function(err) {
      console.log('peer.error');
      console.log(err.message);
      waiting();
    });
  }
  RemoteMonitor.prototype.onCall = function(video, connecting, waiting) {
    var self = this;
    self.peer.on('call', function(call) {
      console.log('peer.call');
      call.answer(self.ls);
      self.__connect(call, video, waiting);
      connecting();
    });
    self.peer.on('connection', function(conn) {
      conn.on('data', function(data) {
        console.log('peer.data:' + data);
        switch (data) {
          case 'mic-on':
            console.log('event: mic-on');
            self.ls.getAudioTracks()[0].enabled = true;
            break;
          case 'mic-off':
            console.log('event: mic-off');
            self.ls.getAudioTracks()[0].enabled = false;
            break;
          default:
            console.log('event: unknown');
            break;
        }
      });
    });
  }
  RemoteMonitor.prototype.makeCall = function(callto, video, connecting, waiting) {
    var self = this;
    console.log('makeCall:' + callto);
    self.callto = callto;
    var call = self.peer.call(callto, self.ls);
    self.__connect(call, video, waiting);
    connecting();
  }
  RemoteMonitor.prototype.closeCall = function() {
    var self = this;
    console.log('closeCall');
    self.ec.close();
  }
  RemoteMonitor.prototype.toggleMIC = function() {
    var self = this;
    var state = self.ls.getAudioTracks()[0].enabled;
    console.log('toggleMIC state:' + state);
    self.ls.getAudioTracks()[0].enabled = !state;

    var conn = self.peer.connect(self.callto);
    conn.on('open', function() {
      if (state) {
        conn.send('mic-off');
      }
      else {
        conn.send('mic-on');
      }
    });
  }
  RemoteMonitor.prototype.__connect = function(call, video, waiting) {
    var self = this;
    console.log('__connect');
    if (self.ec) {
      self.ec.close();
    }
    call.on('stream', function(stream) {
      video.prop('src', URL.createObjectURL(stream));
    });
    call.on('close', waiting);
    self.ec = call;
  }

  exports.RemoteMonitor = RemoteMonitor;

  return exports;
})();
