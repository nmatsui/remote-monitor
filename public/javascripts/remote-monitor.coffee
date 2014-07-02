ns = do ->
  exports = {}

  host = '192.168.1.122'
  port = 9000
  path = '/remote-monitor'
  debug = 3

  class exports.RemoteMonitor
    constructor: ->
      console.log "constructor"
      @peer = new Peer {host:host, port:port, path:path, debug:debug}
  
    initialize: (video, initializing, waiting) ->
      console.log "initialize"
      initializing()
      navigator.getUserMedia = navigator.getUserMedia ||
                               navigator.webkitGetUserMedia ||
                               navigator.mozGetUserMedia
      navigator.getUserMedia {audio:true, video:true}
      , (stream) =>
        console.log "getUserMedia success"
        video.prop 'src', URL.createObjectURL(stream)
        @ls = stream
        @ls.getAudioTracks()[0].enabled = false
        waiting()
      , =>
        console.log "getUserMedia fail"
        console.log "ビデオカメラとマイクへのアクセスに失敗しました"

    onOpen: (peerIDsetting) ->
      console.log "onOpen"
      @peer.on 'open', =>
        console.log "peer.open"
        peerIDsetting(@peer.id)
  
    onError: (showError, waiting) ->
      console.log "onError"
      @peer.on 'error', (err) =>
        console.log "peer.error: #{err.message}"
        showError(err.message)
        waiting()

    onConnection: (messageHandler = null, imageHandler = null)->
      console.log "onConnection"
      @peer.on 'connection', (conn) =>
        console.log "peer.connection"
        conn.on 'data', (data) =>
          console.log "conn.data #{data}"

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
  
    onCall: (video, connecting, waiting) ->
      console.log "onCall"
      @peer.on 'call', (call) =>
        console.log "peer.call"
        call.answer @ls
        @__connect call, video, waiting
        connecting()
  
    makeCall: (callto, video, connecting, waiting) ->
      console.log "makeCall : #{callto}"
      @callto = callto
      call = @peer.call callto, @ls
      @__connect call, video, waiting
      connecting()
  
    closeCall: ->
      console.log "closeCall"
      @ec.close()
  
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

    terminate: ->
      console.log "terminate"
      @peer.destroy()
  
    __connect: (call, video, waiting) ->
      console.log "__connect"
      @ec.close() if @ec?
      call.on 'stream', (stream) =>
        console.log "call.stream"
        video.prop 'src', URL.createObjectURL(stream)
      call.on 'close', ->
        console.log "call.close"
        waiting()
      @ec = call

    __send: (data) ->
      head = if data.length < 20 then data else "#{data.substring 0, 20}..."
      conn = @peer.connect @callto, {reliable: true}
      conn.on 'open', =>
        conn.send data
        console.log "sent data:#{head}"

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

  exports
