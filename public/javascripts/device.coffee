$ ->
  dc = new ns.DeviceClass() # DeviceClassのインスタンス化

  ## 画面コンポーネントを操作するコールバック関数の定義
  peerIDsetting = (id) ->
    $('#device-id').text(id)
  
  allhide = ->
    $('#initialize').hide()
    $('#waiting').hide()
    $('#connecting').hide()
    $('#image-viewing').hide()
    $('#video-container').hide()
  
  initializing = ->
    allhide()
    $('#initialize').show()
  
  waiting = ->
    allhide()
    $('#message').text("")
    $('#waiting').show()
    $('#terminate').focus()
  
  connecting = ->
    allhide()
    $('#connecting').show()
    $('#end-call').focus()

  imageViewing = ->
    allhide()
    $('#image-viewing').show()
    $('#close-image').focus()
  
  showError = (errMessage) ->
    console.log "showError :#{errMessage}"
    alert(errMessage)
  
  showMessage = (message) ->
    $('#message').text(message)
  
  showImage = (image) ->
    $('#sent-image')[0].src = image
    imageViewing()

  ## ボタンクリック時の処理定義
  $('#end-call').click ->
    dc.closeCall()
    waiting()
  
  $('#close-image').click ->
    $('#sent-image')[0].src = ""
    connecting()
  
  $('#terminate').click ->
    dc.terminate()
    window.open('about:blank', '_self').close()

  ## DeviceClassの各種イベント処理へ画面コンポーネントを操作するコールバック関数を設定
  dc.onOpen(peerIDsetting)
  dc.onError(showError, waiting)
  dc.onConnection(showMessage, showImage)
  dc.onCall($('#monitor-video'), connecting, waiting)

  ## MediaStreamの初期化処理を呼び出す
  dc.initialize($('#device-video'), initializing, waiting)
