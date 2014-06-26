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

    onConnection: (handler = null)->
      console.log "onConnection"
      @peer.on 'connection', (conn) =>
        console.log "peer.connection"
        conn.on 'data', (data) =>
          console.log "conn.data #{data}"
          switch data
            when 'mic-on'
              console.log "event: mic-on"
              @ls.getAudioTracks()[0].enabled = true
            when 'mic-off'
              console.log "event: mic-off"
              @ls.getAudioTracks()[0].enabled = false
            else
              if handler?
                handler(data)
              else
                console.log "event: unknown"
  
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
  
      conn = @peer.connect @callto
      conn.on 'open', =>
        if state
          conn.send 'mic-off'
          console.log "sent message: mic-off"
        else
          conn.send 'mic-on'
          console.log "sent message: mic-on"

    sendMessage: (message) ->
      console.log "sendMessage: #{message}"
      conn = @peer.connect @callto
      conn.on 'open', =>
        conn.send message
        console.log "sent message: #{message}"

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

  exports
