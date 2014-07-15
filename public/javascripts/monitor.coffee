$ ->
  mc = new ns.MonitorClass() # MonitorClassのインスタンス化
 
  ## ローカル変数の定義
  LINE_WIDTH = 2
  LINE_COLOR = 'rgb(255, 0, 0)'

  mic = null
  cap = null
  drawing = null
  sx = null
  sy = null

  ## 画面コンポーネントを操作するコールバック関数の定義
  allhide = ->
    $('#initialize').hide()
    $('#waiting').hide()
    $('#connecting-form').hide()
    $('#device-video').hide()
    $('#monitor-video').hide()
    $('#capture-canvas').hide()

  initializing = ->
    allhide()
    $('#initialize').show()

  waiting = ->
    allhide()
    mic = false
    cap = false
    drawing = false
    sx = 0
    sy = 0
    $('#toggle-mic').text('MIC ON')
    $('#send-image').prop('disabled', true)
    $('#toggle-capture').text('CAPTURE')
    $('#message').val("")
    $('#waiting').show()
    $('#callto-id').focus()

  connecting = ->
    allhide()
    $('#send-image').prop('disabled', true)
    $('#toggle-capture').text('CAPTURE')
    $('#connecting-form').show()
    $('#device-video').show()

  capturing = ->
    $('#send-image').prop('disabled', false)
    $('#toggle-capture').text('LIVE')
    $('#device-video').hide()
    $('#capture-canvas').show()
  
  showError = (errMessage) ->
    console.log "showError :#{errMessage}"
    alert(errMessage)

  ## ボタンクリック時の処理定義
  $('#make-call').click ->
    calltoId = $('#callto-id').val()
    video = $('#device-video')
    mc.makeCall(calltoId, video, connecting, waiting)
  
  $('#end-call').click ->
    mc.closeCall()
    waiting()
  
  $('#toggle-mic').click ->
    mc.toggleMIC()
    mic = !mic
    if mic
      $('#toggle-mic').text('MIC OFF')
    else
      $('#toggle-mic').text('MIC ON')
  
  $('#toggle-capture').click ->
    cap = !cap
    if cap
      video = $('#device-video')[0]
      canvas = $('#capture-canvas')[0]
      captureVideo(video, canvas)
      capturing()
    else
      connecting()
  
  $('#send-message').click ->
    message = $('#message').val()
    mc.sendMessage(message)
  
  $('#send-image').click ->
    data = $('#capture-canvas')[0].toDataURL('image/png')
    mc.sendData(data)
  
  $('#terminate').click ->
    mc.terminate()
    window.open('about:blank', '_self').close()

  ## カメラ映像のキャプチャとフリーハンドでの指示を描く処理
  captureVideo = (video, canvas) ->
    ctx = canvas.getContext('2d')
    canvas.width = video.videoWidth
    canvas.height = video.videoHeight
    ctx.drawImage(video, 0, 0)

  $('#capture-canvas').on 'mousedown', (e) ->
    drawing = true
    sx = e.pageX - $(this).offset().left
    sy = e.pageY - $(this).offset().top
    false
  
  $('#capture-canvas').on 'mousemove', (e) ->
    if drawing
      ctx = this.getContext('2d')
      ex = e.pageX - $(this).offset().left
      ey = e.pageY - $(this).offset().top
      ctx.lineWidth = LINE_WIDTH
      ctx.strokeStyle = LINE_COLOR
      ctx.beginPath()
      ctx.moveTo(sx, sy)
      ctx.lineTo(ex, ey)
      ctx.stroke()
      ctx.closePath()
      sx = ex
      sy = ey
    false
  
  $('#capture-canvas').on 'mouseup', ->
    drawing = false
    false
  
  $('#capture-canvas').on 'mouseleave', ->
    drawing = false
    false

  ## MonitorClassの各種イベント処理へ画面コンポーネントを操作するコールバック関数を設定
  mc.onOpen()
  mc.onError(showError, waiting)

  ## MediaStreamの初期化処理を呼び出す
  mc.initialize($('#monitor-video'), initializing, waiting)
