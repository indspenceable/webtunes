require 'applescript'
class WebtunesController < ApplicationController
  def interface
  end
  def test
  end

  #toggle playing status
  def play_pause
    puts "hello, world."
    #AppleScript.execute('tell application "iTunes"
    #                      play
    #                    end tell')
    itunes 'playpause'
  end

  #skip the current_song
  def next
    itunes 'next_track'
  end

  private
  def itunes action
    #vim coloring gets messed up if I use %s{. Sorry.
    AppleScript.execute("tell application \"iTunes\" 
                          #{action} 
                        end tell")
  end

end
