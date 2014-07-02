$ ->
  dc = new ns.DeviceClass()

  peerIDsetting = (id) ->
    $('#device-id').text(id)
  
  allhide = ->
    $('#initialize').hide()
    $('#peerid-container').hide()
    $('#monitor-video').hide()
    $('#device-video').hide()
    $('#connecting').hide()
    $('#image-container').hide()
  
  initializing = ->
    allhide()
    $('#initialize').show()
  
  waiting = ->
    allhide()
    $('#peerid-container').show()
  
  connecting = ->
    allhide()
    $('#connecting').show()
  
  showError = (errMessage) ->
    console.log "showError :#{errMessage}"
    alert(errMessage)
  
  showMessage = (message) ->
    $('#message').text(message)
  
  showImage = (image) ->
    $('#sent-image')[0].src = image
    $('#connecting').hide()
    $('#image-container').show()

  $('#end-call').click ->
    dc.closeCall()
    waiting()
  
  $('#close-image').click ->
    $('#sent-image')[0].src = ""
    $('#image-container').hide()
    $('#connecting').show()
  
  $('#terminate').click ->
    dc.terminate()
    window.open('about:blank', '_self').close()

  dc.onOpen(peerIDsetting)
  dc.onConnection(showMessage, showImage)
  dc.onCall($('#monitor-video'), connecting, waiting)
  dc.onError(showError, waiting)
  dc.initialize($('#device-video'), initializing, waiting)
