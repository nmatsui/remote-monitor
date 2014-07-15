ns = do ->
  exports = {}

  HOST  = '192.168.1.122' # シグナリングサーバのIPアドレスやホスト名
  PORT  = 9000 # シグナリングサーバが立ち上がっているポート
  PATH  = '/remote-monitor' # シグナリングサーバ立ち上げ時に指定したAPI Prefix
  DEBUG = 3

  class BaseClass
    # BaseClassの定義
    constructor: ->
      console.log "constructor of BaseClass"
      @peer = new Peer {host:HOST, port:PORT, path:PATH, debug:DEBUG}
      @ls = null
      @emc = null
      @edc = null
      @eh = null
  
    initialize: (video, initializing, waiting) ->
      console.log "initialize"
      initializing()
      navigator.getUserMedia = navigator.getUserMedia ||
                               navigator.webkitGetUserMedia ||
                               navigator.mozGetUserMedia
      navigator.getUserMedia {audio:true, video:true}
      , (stream) =>
        console.log "getUserMedia SuccessCallback"
        video.prop 'src', URL.createObjectURL(stream)
        @ls = stream
        @ls.getAudioTracks()[0].enabled = false
        waiting()
      , =>
        console.log "getUserMedia ErrorCollback"
        @eh "getUserMedia fail" if @eh?

    onOpen: (peerIDsetting = null) ->
      console.log "onOpen"
      @peer.on 'open', =>
        console.log "peer.on 'open' peer.id=#{@peer.id}"
        peerIDsetting(@peer.id) if peerIDsetting?
  
    onError: (showError, waiting) ->
      console.log "onError"
      @eh = showError
      @peer.on 'error', (err) =>
        console.log "peer.on 'error': #{err.message}"
        @eh "peer.error: #{err.message}" if @eh?
        waiting()

    closeCall: ->
      console.log "closeCall"
      @emc.close() if @emc?
      @edc.close() if @edc?
  
    terminate: ->
      console.log "terminate"
      @emc.close() if @emc?
      @edc.close() if @edc?
      @peer.destroy() if @peer?
  
    __connect: (mediaConnection, video, waiting) ->
      console.log "__connect"
      @emc.close() if @emc?
      @emc = mediaConnection
      mediaConnection.on 'stream', (stream) =>
        console.log "mediaConnection.on 'stream'"
        video.prop 'src', URL.createObjectURL(stream)
      mediaConnection.on 'close', =>
        console.log "mediaConnection.on 'close'"
        @ls.getAudioTracks()[0].enabled = false
        waiting()

  class exports.DeviceClass extends BaseClass
    # BaseClassを継承したDeviceClassの定義
    constructor: ->
      console.log "constructor of DeviceClass"
      super()

    onCall: (video, connecting, waiting) ->
      console.log "onCall"
      @peer.on 'call', (mediaConnection) =>
        console.log "peer.on 'call'"
        mediaConnection.answer @ls
        @__connect mediaConnection, video, waiting
        connecting()
  
    onConnection: (messageHandler = null, imageHandler = null)->
      console.log "onConnection"
      @peer.on 'connection', (dataConnection) =>
        console.log "peer.on 'connection'"
        dataConnection.on 'open', =>
          console.log "dataConnection.on 'open'"
          @edc.close() if @edc?
          @edc = dataConnection
        dataConnection.on 'data', (data) =>
          console.log "dataConnection.on 'data' #{data}"
          if /^event:(.*)/.exec data
            console.log "event received:#{RegExp.$1}"
            @__eventHandler(RegExp.$1)
          else if /^message:(.*)/.exec data
            console.log "message received:#{RegExp.$1}"
            messageHandler(RegExp.$1) if messageHandler
          else if /^data:(.*)/.exec data
            console.log "data received:#{RegExp.$1}"
            imageHandler(RegExp.$1) if imageHandler
          else
            console.log "unknown data received:#{data}"
        dataConnection.on 'close', =>
          console.log "dataConnection.on 'close'"
  
    __eventHandler: (event) ->
      console.log "__eventHandler event:#{event}"
      switch event
        when 'mic-on'
          console.log "event: mic-on"
          @ls.getAudioTracks()[0].enabled = true
        when 'mic-off'
          console.log "event: mic-off"
          @ls.getAudioTracks()[0].enabled = false
        else
          console.log "event: unknown"

  class exports.MonitorClass extends BaseClass
    # BaseClassを継承したMonitorClassの定義
    constructor: ->
      console.log "constructor of MonitorClass"
      super()

    makeCall: (callto, video, connecting, waiting) ->
      console.log "makeCall : #{callto}"
      @callto = callto
      
      mediaConnection = @peer.call callto, @ls
      @__connect mediaConnection, video, waiting

      dataConnection = @peer.connect callto, {reliable: true}
      dataConnection.on 'open', =>
        console.log "dataConnection.on 'open'"
        @edc.close() if @edc?
        @edc = dataConnection
      dataConnection.on 'close', ->
        console.log "dataConnection.on 'close'"

      connecting()
  
    toggleMIC: ->
      state = @ls.getAudioTracks()[0].enabled
      console.log "toggleMIC state:#{state}"
      @ls.getAudioTracks()[0].enabled = !state

      if state
        @__send "event:mic-off"
      else
        @__send "event:mic-on"

    sendMessage: (message) ->
      console.log "sendMessage: #{message}"
      @__send "message:#{message}"

    sendData: (data) ->
      console.log "sendData: #{data}"
      @__send "data:#{data}"

    __send: (data) ->
      head = if data.length < 20 then data else "#{data.substring 0, 20}..."
      if @edc? and @edc.open
        @edc.send(data)
        console.log "sent data:#{head}"
      else
        console.log "dataConnection is lost"
        @eh "dataConnection is lost" if @eh?

  exports
