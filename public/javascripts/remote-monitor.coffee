ns = do ->
  exports = {}

  HOST  = '192.168.1.122' # シグナリングサーバのIPアドレスやホスト名
  PORT  = 9000 # シグナリングサーバが立ち上がっているポート
  PATH  = '/remote-monitor' # シグナリングサーバ立ち上げ時に指定したAPI Prefix
  DEBUG = 3

  TYPE =
    event:  "event"
    message:"message"
    image:  "image"
  EVENT =
    mic:
      on:  "mic-on"
      off: "mic-off"

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
      # getUserMediaのブラウザ間際の吸収
      navigator.getUserMedia = navigator.getUserMedia ||
                               navigator.webkitGetUserMedia ||
                               navigator.mozGetUserMedia
      # MediaStreamの取得
      navigator.getUserMedia {audio:true, video:true}
      , (stream) =>
        # MediaStreamの取得に成功
        console.log "getUserMedia SuccessCallback"
        video.prop 'src', URL.createObjectURL(stream)
        @ls = stream
        @ls.getAudioTracks()[0].enabled = false
        waiting()
      , =>
        # MediaStreamの取得に失敗
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
  
    __connect: (mediaConnection, video, connecting, waiting) ->
      console.log "__connect"
      @emc.close() if @emc?
      @emc = mediaConnection

      # MediaConnectionのイベント処理
      mediaConnection.on 'stream', (stream) =>
        # 接続相手先のMediaStreamが利用可能となった際の処理
        console.log "mediaConnection.on 'stream'"
        video.prop 'src', URL.createObjectURL(stream)
        connecting()
      mediaConnection.on 'close', =>
        # 自分もしくは接続相手先がMediaConnectionを切断した際の処理
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
        @__connect mediaConnection, video, connecting, waiting
  
    onConnection: (messageHandler = null, imageHandler = null)->
      console.log "onConnection"
      @peer.on 'connection', (dataConnection) =>
        # DataConnectionが確立した際の処理
        console.log "peer.on 'connection'"
        dataConnection.on 'open', =>
          # DataConnectionが利用可能となった際の処理
          console.log "dataConnection.on 'open'"
          @edc.close() if @edc?
          @edc = dataConnection
        dataConnection.on 'data', (data) =>
          # 接続相手先からデータを受信した際の処理
          console.log "dataConnection.on 'data' #{JSON.stringify data}"
          switch data.type
            when TYPE.event
              console.log "event received:#{data.payload}"
              @__eventHandler data.payload
            when TYPE.message
              console.log "message received:#{data.payload}"
              messageHandler data.payload if messageHandler
            when TYPE.image
              console.log "image received:#{data.payload}"
              imageHandler data.payload if imageHandler
            else
              console.log "unknown data type"
        dataConnection.on 'close', =>
          # DataConnectionの接続が切断された際の処理
          console.log "dataConnection.on 'close'"
  
    __eventHandler: (event) ->
      console.log "__eventHandler event:#{event}"
      switch event
        when EVENT.mic.on
          console.log "event: mic-on"
          @ls.getAudioTracks()[0].enabled = true
        when EVENT.mic.off
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
     
      # MediaConnectionの接続要求処理
      mediaConnection = @peer.call callto, @ls
      @__connect mediaConnection, video, connecting, waiting

      # DataConnectionの接続要求処理
      dataConnection = @peer.connect callto, {reliable: true}

      # DataConnectionのイベント処理
      dataConnection.on 'open', =>
        # DataConnectionが利用可能となった際の処理
        console.log "dataConnection.on 'open'"
        @edc.close() if @edc?
        @edc = dataConnection
      dataConnection.on 'close', ->
        # DataConnectionが切断された際の処理
        console.log "dataConnection.on 'close'"
  
    toggleMIC: ->
      state = @ls.getAudioTracks()[0].enabled
      console.log "toggleMIC state:#{state}"
      @ls.getAudioTracks()[0].enabled = !state

      if state
        @__send TYPE.event, EVENT.mic.off
      else
        @__send TYPE.event, EVENT.mic.on

    sendMessage: (message) ->
      console.log "sendMessage: #{message}"
      @__send TYPE.message, message

    sendImage: (image) ->
      console.log "sendImage: #{image}"
      @__send TYPE.image, image

    __send: (type, payload) ->
      if @edc? and @edc.open
        data = {type:type, payload:payload}
        @edc.send data
        console.log "sent object:#{JSON.stringify data}"
      else
        console.log "dataConnection is lost"
        @eh "dataConnection is lost" if @eh?

  exports
