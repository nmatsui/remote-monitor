$ ->
  rm = new ns.RemoteMonitor()

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
    rm.closeCall()
    waiting()
  
  $('#close-image').click ->
    $('#sent-image')[0].src = ""
    $('#image-container').hide()
    $('#connecting').show()
  
  $('#terminate').click ->
    rm.terminate()
    window.open('about:blank', '_self').close()

  rm.onOpen(peerIDsetting)
  rm.onError(showError, waiting)
  rm.onConnection(showMessage, showImage)
  rm.onCall($('#monitor-video'), connecting, waiting)
  rm.initialize($('#device-video'), initializing, waiting)
