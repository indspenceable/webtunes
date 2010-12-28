require 'applescript'
class WebtunesController < ApplicationController
  def interface
    puts "Hello, world."
    AppleScript.execute('tell application "iTunes"
      set sound volume to 40
      play
    end tell')
    puts "goodbye, world."
  end

  #skip the current_song
  def skip_song

  end

end
