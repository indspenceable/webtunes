require 'applescript'
class WebtunesController < ApplicationController
  def interface
  end
  def test
  end



  ## Controls for manipulating itunes
  #toggle playing status
  def play_pause
    itunes 'playpause'
  end

  #skip the current_song
  def next
    itunes 'next track'
  end

  def back
    itunes 'previous track'
  end


  private
  def itunes action
    #vim coloring gets messed up if I use %s{. Sorry.
    AppleScript.execute("tell application \"iTunes\" 
                          #{action} 
                        end tell")
  end

end
