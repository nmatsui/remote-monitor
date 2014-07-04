$ ->
  LINE_WIDTH = 2
  LINE_COLOR = 'rgb(255, 0, 0)'

  mc = new ns.MonitorClass()
  mic = false
  cap = false
  drawing = false
  sx = 0
  sy = 0

  allhide = ->
    $('#initialize').hide()
    $('#makecall-form').hide()
    $('#calling-form').hide()
    $('#device-video').hide()
    $('#monitor-video').hide()
    $('#capture-canvas').hide()
 
  initializing = ->
    allhide()
    $('#initialize').show()

  waiting = ->
    allhide()
    $('#makecall-form').show()

  connecting = ->
    allhide()
    $('#device-video').show()
  
  showError = (errMessage) ->
    console.log "showError :#{errMessage}"
    alert(errMessage)
  
  captureVideo = (video, canvas) ->
    ctx = canvas.getContext('2d')
    canvas.width = video.videoWidth
    canvas.height = video.videoHeight
    ctx.drawImage(video, 0, 0)

  $('#make-call').click ->
    calltoId = $('#callto-id').val()
    video = $('#device-video')
    mc.makeCall(calltoId, video, connecting, waiting)
    $('#makecall-form').hide()
    $('#calling-form').show()
  
  $('#end-call').click ->
    mc.closeCall()
    $('#calling-form').hide()
    $('#makecall-form').show()
  
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

      $('#device-video').hide()
      $('#capture-canvas').show()
      $('#send-image').prop('disabled', false)
      $('#toggle-capture').text('LIVE')
    else
      $('#capture-canvas').hide()
      $('#send-image').prop('disabled', true)
      $('#device-video').show()
      $('#toggle-capture').text('CAPTURE')
  
  $('#send-message').click ->
    message = $('#message').val()
    mc.sendMessage(message)
  
  $('#send-image').click ->
    data = $('#capture-canvas')[0].toDataURL('image/png')
    mc.sendData(data)
  
  $('#terminate').click ->
    mc.terminate()
    window.open('about:blank', '_self').close()

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

  mc.onOpen()
  mc.onError(showError, waiting)
  mc.initialize($('#monitor-video'), initializing, waiting)
