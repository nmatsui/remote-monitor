// Generated by CoffeeScript 1.7.1
(function() {
  $(function() {
    var LINE_COLOR, LINE_WIDTH, allhide, cap, captureVideo, capturing, connecting, drawing, initializing, mc, mic, showError, sx, sy, waiting;
    mc = new ns.MonitorClass();
    LINE_WIDTH = 2;
    LINE_COLOR = 'rgb(255, 0, 0)';
    mic = null;
    cap = null;
    drawing = null;
    sx = null;
    sy = null;
    allhide = function() {
      $('#initialize').hide();
      $('#waiting').hide();
      $('#connecting-form').hide();
      $('#device-video').hide();
      $('#monitor-video').hide();
      return $('#capture-canvas').hide();
    };
    initializing = function() {
      allhide();
      return $('#initialize').show();
    };
    waiting = function() {
      allhide();
      mic = false;
      cap = false;
      drawing = false;
      sx = 0;
      sy = 0;
      $('#toggle-mic').text('MIC ON');
      $('#send-image').prop('disabled', true);
      $('#toggle-capture').text('CAPTURE');
      $('#message').val("");
      $('#waiting').show();
      return $('#callto-id').focus();
    };
    connecting = function() {
      allhide();
      $('#send-image').prop('disabled', true);
      $('#toggle-capture').text('CAPTURE');
      $('#connecting-form').show();
      return $('#device-video').show();
    };
    capturing = function() {
      $('#send-image').prop('disabled', false);
      $('#toggle-capture').text('LIVE');
      $('#device-video').hide();
      return $('#capture-canvas').show();
    };
    showError = function(errMessage) {
      console.log("showError :" + errMessage);
      return alert(errMessage);
    };
    $('#make-call').click(function() {
      var calltoId, video;
      calltoId = $('#callto-id').val();
      video = $('#device-video');
      return mc.makeCall(calltoId, video, connecting, waiting);
    });
    $('#end-call').click(function() {
      mc.closeCall();
      return waiting();
    });
    $('#toggle-mic').click(function() {
      mc.toggleMIC();
      mic = !mic;
      if (mic) {
        return $('#toggle-mic').text('MIC OFF');
      } else {
        return $('#toggle-mic').text('MIC ON');
      }
    });
    $('#toggle-capture').click(function() {
      var canvas, video;
      cap = !cap;
      if (cap) {
        video = $('#device-video')[0];
        canvas = $('#capture-canvas')[0];
        captureVideo(video, canvas);
        return capturing();
      } else {
        return connecting();
      }
    });
    $('#send-message').click(function() {
      var message;
      message = $('#message').val();
      return mc.sendMessage(message);
    });
    $('#send-image').click(function() {
      var data;
      data = $('#capture-canvas')[0].toDataURL('image/png');
      return mc.sendData(data);
    });
    $('#terminate').click(function() {
      mc.terminate();
      return window.open('about:blank', '_self').close();
    });
    captureVideo = function(video, canvas) {
      var ctx;
      ctx = canvas.getContext('2d');
      canvas.width = video.videoWidth;
      canvas.height = video.videoHeight;
      return ctx.drawImage(video, 0, 0);
    };
    $('#capture-canvas').on('mousedown', function(e) {
      drawing = true;
      sx = e.pageX - $(this).offset().left;
      sy = e.pageY - $(this).offset().top;
      return false;
    });
    $('#capture-canvas').on('mousemove', function(e) {
      var ctx, ex, ey;
      if (drawing) {
        ctx = this.getContext('2d');
        ex = e.pageX - $(this).offset().left;
        ey = e.pageY - $(this).offset().top;
        ctx.lineWidth = LINE_WIDTH;
        ctx.strokeStyle = LINE_COLOR;
        ctx.beginPath();
        ctx.moveTo(sx, sy);
        ctx.lineTo(ex, ey);
        ctx.stroke();
        ctx.closePath();
        sx = ex;
        sy = ey;
      }
      return false;
    });
    $('#capture-canvas').on('mouseup', function() {
      drawing = false;
      return false;
    });
    $('#capture-canvas').on('mouseleave', function() {
      drawing = false;
      return false;
    });
    mc.onOpen();
    mc.onError(showError, waiting);
    return mc.initialize($('#monitor-video'), initializing, waiting);
  });

}).call(this);
