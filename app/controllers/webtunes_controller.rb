class AppleScriptError < StandardError; end

class WebtunesController < ApplicationController
  def interface
    get_itunes_status
    if session[:name].nil?
      @needs_login = true
    end
    if @state == "stopped"
      @state = "paused"
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
  
  def play_album
    
  end
  def play_song
    as_execute("set theplaylist to \"webTunes\"
    set temp to \"webTunesTemp\"
    property pid : \"#{params[:id]}\"

    tell application \"iTunes\"
    	set this_song to (every track whose persistent ID is pid)
    	repeat with a_track in this_song
    		duplicate a_track to playlist theplaylist
    		duplicate (every track in playlist theplaylist) to playlist temp
    		delete (every track in playlist temp whose persistent ID is pid)
    		delete (every track in playlist theplaylist whose persistent ID is not pid)
    		play first track in playlist theplaylist
    		duplicate (every track in playlist temp) to playlist theplaylist
    		delete every track in playlist temp
    	end repeat
    end tell")
  end
  def add_song
    #I think this adds to the bottom of the playlist
    as_execute("set theplaylist to \"webTunes\"
    property pid : \"#{params[:id]}\"

    tell application \"iTunes\"
    	set this_song to (every track whose persistent ID is pid)
    	repeat with a_track in this_song
    		duplicate a_track to playlist theplaylist
    	end repeat
    end tell")
  end
  def remove
    #removes the first song in the playlist that matches. Even if the user tried to remove a later duplicate
    as_execute("set theplaylist to \"webTunes\"
    property pid : \"#{params[:id]}\"

    tell application \"iTunes\"
    	set this_song to (every track in playlist theplaylist whose persistent ID is pid)
    	repeat with a_track in this_song
    		return delete a_track
    	end repeat
    end tell")
  end
  def reorder
    as_execute("set theplaylist to \"webTunes\"
    set temp to \"webTunesTemp\"
    property ids : {#{params[:list]}}
    tell application \"iTunes\"
    	repeat with i from 1 to (length of ids)
    		set new_list to (every track whose persistent ID is (item i in ids as text))
    		repeat with a_track in new_list
    			duplicate a_track to playlist temp
    		end repeat
    	end repeat

    	delete (every track in playlist theplaylist whose persistent ID is not (item 1 in ids as text))
    	if number of tracks in playlist theplaylist is greater than 0 then
    		delete (every track in playlist temp whose persistent ID is (item 1 in ids as text))
    	end if
    	duplicate every track in playlist temp to playlist theplaylist
    	play first track in playlist theplaylist
    	delete every track in playlist temp
    end tell")
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
    @volume = get_volume
    @state = get_playing.chomp
    return
    names = itunes "get name of every track of current playlist"
    artists = itunes "get artist of every track of current playlist"
    durations = itunes "get duration of every track of current playlist"
    [(split_by_strings names), (split_by_strings artists), (split_by_numbers durations)]
  end
  
  def get_volume
    itunes "get sound volume"
  end
  
  def get_playing
    itunes "get player state"
  end
end
