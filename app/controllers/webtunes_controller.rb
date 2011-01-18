class AppleScriptError < StandardError; end

class WebtunesController < ApplicationController
  
  def interface
    Rails.cache.clear
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
    if get_playing.chomp == 'stopped'
      itunes "play first track in playlist \"webTunes\""
    else
      itunes 'playpause'
    end
    Rails.cache.clear
    get_itunes_status
  end
  #skip the current_song
  def next
    itunes 'next track'
    Rails.cache.clear
    get_itunes_status
  end
  # back to the previous track
  def back
    itunes 'back track'
    Rails.cache.clear
    get_itunes_status
  end
  def set_volume
    itunes "set sound volume to #{params[:level]}"
    Rails.cache.clear
    get_itunes_status
  end
  
  def login
    get_itunes_status
    session[:name] = params[:id]
    render 'interface'
  end
  
  def search
    results = as_execute("set returnResults to {}

    set names to {}
    set ids to {}
    set myArtists to {}
    set myAlbums to {}

    tell application \"iTunes\"
    	set myResults to (search library playlist 1 for \"#{params[:query]}\")
    	repeat with a_track in myResults
    		set myArtist to artist of a_track
    		set myId to persistent ID of a_track
    		set myName to name of a_track
    		set myAlbum to album of a_track
    		copy myName to end of returnResults
    		copy myArtist to end of returnResults
    		copy myId to end of returnResults
    		copy myAlbum to end of returnResults
    	end repeat
    end tell

    --set returnResults to {names, myArtists, ids, myAlbums}
    return returnResults")

    results =  Shellwords.shellwords(results)
    
    results.each do |n|
      n.gsub!(/[,{}]/, "")
    end
    
    slicePoint = results.size/4
    
    @tracks = []
    0.upto(slicePoint) do |i|
      sub = []
      sub << results[4*i]
      sub << results[(4*i) + 1]
      sub << results[(4*i) + 2]
      sub << results[(4*i) + 3]
      @tracks << sub
    end
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
    Rails.cache.clear
    get_itunes_status
  end
  def add_song
    # I think this adds to the bottom of the playlist
    
    # Creates a new playlist becaue you can not reorder through applescript
    as_execute("set theplaylist to \"webTunes\"
    property pid : \"#{params[:id]}\"

    tell application \"iTunes\"
    	set this_song to (every track whose persistent ID is pid)
    	repeat with a_track in this_song
    		duplicate a_track to playlist theplaylist
    	end repeat
    end tell")
    Rails.cache.clear
    get_itunes_status
  end
  def remove
    Rails.cache.clear
    #removes the first song in the playlist that matches. Even if the user tried to remove a later duplicate
    as_execute("set theplaylist to \"webTunes\"
    property pid : \"#{params[:id]}\"

    tell application \"iTunes\"
    	set this_song to (every track in playlist theplaylist whose persistent ID is pid)
    	repeat with a_track in this_song
    		return delete a_track
    	end repeat
    end tell")
    
    get_itunes_status
  end
  
  def reorder
    Rails.cache.clear
    clear_old_tracks
    list =  params[:list].sub!(/[\[]/, "{").sub!(/[\]]/, "}")

    # Do this so that if someone reorders right after a song has finished we just ignore what they did
    currentPlaylist =  itunes("get persistent ID of every track of playlist \"webTunes\"").gsub(/ /,'').size
    if currentPlaylist > list.size + 5 || currentPlaylist < list.size - 5
      get_itunes_status
      render '/webtunes/_left_section'
      return
    end
    
    
    # There is not way to straight reorder a playlist through applescript
    # so instead I send a list of what the new playlist should be and 
    # create it fresh through a temp playlist
    
    # If song #1 in the new playlist is also in the old playlist it leaves
    # it there so that playback is not interrupted. Either way as soon as 
    # the new playlist is created it plays whatever song is #1
    
    # This should be updated so that it keeps it paused if the player was 
    # already paused
    as_execute("set theplaylist to \"webTunes\"
    set temp to \"webTunesTemp\"
    property ids : #{list}
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
    
    get_itunes_status
    render '/webtunes/_left_section'
  end
  
  def phoneHome
    # Rails.cache.clear and puts "clearing" if Time.now > @expire_time
    get_itunes_status
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
  
  def get_itunes_status     
    playlist = Rails.cache.fetch('status') do
      clear_old_tracks
      @volume = get_volume
      @state = get_playing.chomp
      names = Shellwords.shellwords(itunes("get name of every track of playlist \"webTunes\""))
      artists = Shellwords.shellwords(itunes("get artist of every track of playlist \"webTunes\""))
      persistentIDs = Shellwords.shellwords(itunes("get persistent ID of every track of playlist \"webTunes\""))
      
      names.each_with_index do |n, i|
        n.gsub!(/[,{}]/, "")
        artists[i].gsub!(/[,{}]/, "")
        persistentIDs[i].gsub!(/[,{}]/, "")
      end
      
      # time_left = itunes("if player state is playing then
      #        return (duration of current track) - player position
      #      else
      #        return false
      #      end if")
      # 
      # if time_left     
      #   puts "the end time is #{time_left} and"
      #   @end_time = Time.now + time_left.chomp.to_f
      #   puts "end time is #{@end_time}"
      #   puts "and teh current time is #{Time.now}"
      # end  
  
      @playlist_tracks = []
      0.upto(names.size - 1) do |index|
        sub = [names[index], artists[index], persistentIDs[index]]
        @playlist_tracks << sub
      end
      @playlist_tracks
    end

    #If song has ended and playlist needs to be updated
    pID = itunes("get persistent ID of current track")
    if pID != "" && playlist.size > 0 && pID.chomp!.gsub!(/[\""]/, "") != playlist[0][2]
      Rails.cache.clear
      get_itunes_status
    end
    
  end
  
  def clear_old_tracks
    itunes("set myIndex to index of current track
    	set oldTracks to every track in playlist \"webTunes\" whose index is less than myIndex

    	repeat with myTrack in oldTracks
    		delete myTrack
    	end repeat")
  end
  
  def get_volume
    itunes "get sound volume"
  end
  
  def get_playing
    itunes "get player state"
  end
end
