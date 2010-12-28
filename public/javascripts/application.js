var is_paused = true;
$(document).ready(function() {
    $('#play_pause').click(function() {
      $.post('play_pause');
			is_paused = !is_paused;
			if (is_paused){
				$('#play_pause').css('background', "url('/images/play.png')");
			} else {
				$('#play_pause').css('background', "url('/images/pause.png')");
			}
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
