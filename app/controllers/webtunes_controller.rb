class AppleScriptError < StandardError; end

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
    render :json => get_itunes_status
  end
  #skip the current_song
  def next
    itunes 'next track'
    render :json => get_itunes_status
  end
  # back to the previous track
  def back
    itunes 'back track'
    render :json => get_itunes_status
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
    as_execute("tell application \"iTunes\" 
                  #{action} 
                end tell")

  end

  def as_execute(script)
    #from applescript gem, by Lucas Carlson
    osascript = `which osascript`
    if not osascript.empty? and File.executable?(osascript)
      raise AppleScriptError, "osascript not found, make sure it is in the path"
    else
      #result = `osascript -e "#{script.gsub('"', '\"')}" 2>&1`
      result = `osascript -s s -e "#{script.gsub('"', '\"')}"`
      if result =~ /execution error/
        raise AppleScriptError, result
      end
      result
    end
  end

  #TODO - this doesn't HALT on poorly formed input.
  #this takes a list returned by 
  def split_by_strings s
    c = 2 # SHOULD BE A {"
    rtn = []
    while c < s.size - 2
      start = c
      while s[c] != "\"" && s[c-1] != "\\"
        c += 1
      end
      rtn << "#{s[start, c-start]}"
      c += 4
    end
    rtn
  end
  def split_by_numbers s
    c = 1 # SHOULD BE A {
    rtn = []
    while c < s.size - 1
      start = c
      while s[c] && c < s.size-1 != ","
        c += 1
      end
      rtn << "#{s[start, c-start]}"
      c += 2
    end
    rtn
  end
  def get_itunes_status
    names = itunes "get name of every track of current playlist"
    artists = itunes "get artist of every track of current playlist"
    durations = itunes "get duration of every track of current playlist"
    [(split_by_strings names), (split_by_strings artists), (split_by_numbers durations)]
  end
end
