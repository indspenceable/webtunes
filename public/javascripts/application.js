$(document).ready(function() {
    $('#play_pause').click(function() {
      $.post('play_pause');
			$('#play_pause').toggleClass( 'pause')
      });
    $('#next').click(function() {
      $.post('next')
      });
    $('#prev').click(function() {
      $.post('back')
      });
    $('#vol').click(function() {
      $.post('set_volume',{level: 40})
      });
})
