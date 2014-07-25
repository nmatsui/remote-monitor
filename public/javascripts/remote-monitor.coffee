HOST  = '192.168.1.122' # シグナリングサーバのIPアドレスやホスト名
PORT  = 9000 # シグナリングサーバが立ち上がっているポート
PATH  = '/remote-monitor' # シグナリングサーバ立ち上げ時に指定したAPI Prefix
DEBUG = 3
CONF  = 
  iceServers:
    [{ url: 'stun:stun.l.google.com:19302' },
     { url: 'turn:homeo@turn.bistri.com:80', credential: 'homeo' }]

this.ns = {}

# DataConnection経由で転送されるデータの種類
TYPE =
  event:  "event"
  message:"message"
  image:  "image"

# DataConnection経由で指示されるイベント
EVENT =
  mic:
    on:  "mic-on"
    off: "mic-off"

class BaseClass
  # BaseClassの定義
  constructor: ->
    console.log "constructor of BaseClass"
    @peer = new Peer {host:HOST, port:PORT, path:PATH, debug:DEBUG, config:CONF}
    #@peer = new Peer {host:HOST, port:PORT, path:PATH, debug:DEBUG}
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

  connect: (mediaConnection, video, connecting, waiting) ->
    console.log "connect"
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
      @ems.close() if @ems?
      waiting()

class DeviceClass extends BaseClass
  # BaseClassを継承したDeviceClassの定義
  constructor: ->
    console.log "constructor of DeviceClass"
    super()

  onCall: (video, connecting, waiting) ->
    console.log "onCall"
    @peer.on 'call', (mediaConnection) =>
      console.log "peer.on 'call'"
      mediaConnection.answer @ls
      @connect mediaConnection, video, connecting, waiting

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
            # イベント受信時は、__eventHandlerに処理を委譲
            console.log "event received:#{data.payload}"
            @__eventHandler data.payload
          when TYPE.message
            # テキストメッセージ受信時は、device.coffeeから渡されるmessageHandlerへ処理を委譲
            console.log "message received:#{data.payload}"
            messageHandler data.payload if messageHandler
          when TYPE.image
            # 画像受信時は、device.coffeeから渡されるimageHandlerへ処理を委譲
            console.log "image received:#{data.payload}"
            imageHandler data.payload if imageHandler
          else
            # 上記以外のtypeの場合は何もしない
            console.log "unknown data type"
      dataConnection.on 'close', =>
        # DataConnectionの接続が切断された際の処理
        console.log "dataConnection.on 'close'"
        @edc.close() if @edc?

  __eventHandler: (event) ->
    # イベント受信時の処理
    console.log "__eventHandler event:#{event}"
    switch event
      when EVENT.mic.on
        # マイクONイベントを受信
        console.log "event: mic-on"
        @ls.getAudioTracks()[0].enabled = true
      when EVENT.mic.off
        # マイクOFFイベントを受信
        console.log "event: mic-off"
        @ls.getAudioTracks()[0].enabled = false
      else
        # 上記以外のイベントを受信した場合は何もしない
        console.log "event: unknown"

class MonitorClass extends BaseClass
  # BaseClassを継承したMonitorClassの定義
  constructor: ->
    console.log "constructor of MonitorClass"
    super()

  makeCall: (callto, video, connecting, waiting) ->
    console.log "makeCall : #{callto}"
    @callto = callto
   
    # MediaConnectionの接続要求処理
    mediaConnection = @peer.call callto, @ls
    @connect mediaConnection, video, connecting, waiting

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
      @edc.close if @edc?

  toggleMIC: ->
    # マイクON/OFFのイベント送信
    state = @ls.getAudioTracks()[0].enabled
    console.log "toggleMIC state:#{state}"
    @ls.getAudioTracks()[0].enabled = !state

    if state
      @__send TYPE.event, EVENT.mic.off
    else
      @__send TYPE.event, EVENT.mic.on

  sendMessage: (message) ->
    # テキストメッセージの送信
    console.log "sendMessage: #{message}"
    @__send TYPE.message, message

  sendImage: (image) ->
    # 画像の送信
    console.log "sendImage: #{image}"
    @__send TYPE.image, image

  __send: (type, payload) ->
    # 送信処理
    if @edc? and @edc.open
      # DataConnectionが確立し利用可能な場合はデータを送信
      data = {type:type, payload:payload}
      @edc.send data
      console.log "sent object:#{JSON.stringify data}"
    else
      # 何らかの理由でDataConnectionが利用できない場合はエラー発生
      console.log "dataConnection is lost"
      @eh "dataConnection is lost" if @eh?

this.ns.DeviceClass = DeviceClass
this.ns.MonitorClass = MonitorClass
