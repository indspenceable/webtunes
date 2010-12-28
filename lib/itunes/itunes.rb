require 'appscript'
include Appscript

module Itunes
  def self.play
    app('iTunes').play
  end
  def self.current_track
    current_track = app('iTunes').current_track
    current_track.artist.get + " - " + current_track.name.get
  end
  #Skip track
  # => nil
  def self.next_track
    app('iTunes').next_track
    nil
  end
end
