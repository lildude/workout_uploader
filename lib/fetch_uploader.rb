#!/usr/bin/env ruby
#
# TODO: Turn this into a plugin
#
require "rubygems"
require "bundler/setup"

require "mechanize"
require "time"
require "yaml"
require "logger"

CONFIG = YAML.load_file("config.yml") unless defined? CONFIG

@activity_count = 0
@upload_count = 0

def log(message, severity = "info")
  if CONFIG["log_file"]
    logger = Logger.new(CONFIG["log_file"])
  else
    logger = Logger.new(STDOUT)
  end
  logger.progname = "workout_uploader"
  logger.send(:"#{severity}", "#{message}")
  logger.close if CONFIG["log_file"]
end

def startup()
  unless File.exists?("#{CONFIG['watch_path']}/.fetch.tkr")
    dot_tkr = File.open("#{CONFIG['watch_path']}/.fetch.tkr", "w+")
  else
    dot_tkr = File.open("#{CONFIG['watch_path']}/.fetch.tkr", "r+")
  end

  last_upload_time = dot_tkr.read
  if last_upload_time.length > 0
    last_upload_time = Time.parse(last_upload_time)
  end

  if last_upload_time.is_a?(Time)
    files = Dir.glob("#{CONFIG['watch_path']}/*.#{CONFIG['file_type']}", File::FNM_CASEFOLD).
      select{ |f| File.mtime(f) > last_upload_time }
  else
    files = Dir.glob("#{CONFIG['watch_path']}/*.#{CONFIG['file_type']}", File::FNM_CASEFOLD)
  end

  @activity_count = files.length

  if @activity_count > 0
    # Sign in to FetchEveryone
    fe = sign_in()
    # Upload
    files.each { |f| upload_file(f, fe) }
  end

  # Update tracker file
  if @activity_count == 0
    log "No activities to sync"
  elsif @upload_count == @activity_count
    last_upload_time = Time.now
    # Go back to the beginning of the file and update the timestamp
    dot_tkr.rewind
    dot_tkr.write(last_upload_time)
    log "#{@activity_count} activities have been uploaded. Good work!"
  else
    log "Some activities were skipped. Look into this.", "warn"
  end
  dot_tkr.close
end

def sign_in()
  fe = Mechanize.new
  fe.user_agent_alias = 'Mac Safari' # Other agents are visible with puts Mechanize::AGENT_ALIASES
  fe.get('http://www.fetcheveryone.com/index.php') do |page|
    log "Signing in to FetchEveryone..."
    page.form_with(:action => "dologin.php") do |f|
      f.email = CONFIG['plugins']['fetcheveryone']['email']
      f.password = CONFIG['plugins']['fetcheveryone']['password']
    end.submit
  end
  fe
end

def upload_file(activity, fe)
  log "Syncing Activity - #{File.basename(activity)} to FetchEveryone"
  begin
    # Load the upload page
    upload_page = fe.get('http://www.fetcheveryone.com/training-import-tcx.php')

    # Upload the file
    upload_page.forms()[1].file_upload_with(:name => /tcxfile/).file_name = activity
    upload_page.forms()[1].category = "R"
    up = upload_page.forms()[1].submit

    if up.code == "200"
      log "Success! #{up.uri}"
      @upload_count = @upload_count + 1
    else
      log "Uh oh, something went wrong uploading the activity: #{up.code}"
    end
  rescue Exception => e
    log "Uh oh, something went wrong uploading the activity: #{e.message}", "fatal"
  end
end

startup()
