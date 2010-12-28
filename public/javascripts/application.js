$(document).ready(function() {
    $('#play_pause').click(function() {
      $.post('play_pause')
      });
    $('#next').click(function() {
      $.post('next')
      });
    $('#prev').click(function() {
      $.post('back')
      });
    })
