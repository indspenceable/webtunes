require 'applescript'
class WebtunesController < ApplicationController
  def interface
    if session[:name].nil?
      @needs_login = true
    end
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
  # back to the previous track
  def back
    itunes 'back track'
  end
  def set_volume
    itunes "set sound volume to #{params[:level]}"
    render :json => get_itunes_status
  end
  
  def login
    session[:name] = params[:id]
    render 'interface'
  end
  
  def playAlbum
    
  end

  private
  def itunes action
    #vim coloring gets messed up if I use %s{. Sorry.
    AppleScript.execute("tell application \"iTunes\" 
                          #{action} 
                        end tell")
  end

  def get_itunes_status
    'get sound volume'
  end

end
