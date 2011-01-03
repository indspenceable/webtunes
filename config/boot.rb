require 'rubygems'

# Set up gems listed in the Gemfile.
gemfile = File.expand_path('../../Gemfile', __FILE__)
begin
  ENV['BUNDLE_GEMFILE'] = gemfile
  require 'bundler'
  Bundler.setup
rescue Bundler::GemNotFound => e
  STDERR.puts e.message
  STDERR.puts "Try running `bundle install`."
  exit!
end if File.exist?(gemfile)


# Same method as in controller
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

# Look for playlist called webTunes, create one if none exists
as_execute("tell application \"iTunes\"
if not (exists playlist \"webTunes\") then
	make new user playlist with properties {name:\"webTunes\"}
end if
end tell")