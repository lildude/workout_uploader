#!/usr/bin/env ruby
#
require "rubygems"
require "bundler/setup"

require "httmultiparty"
require "time"
require "yaml"

CONFIG = YAML.load_file("config.yml") unless defined? CONFIG

@activity_count = 0
@upload_count = 0

def log(message, severity = "info")
  if CONFIG["log_file"]
    require "logger"
    logger = Logger.new(CONFIG["log_file"])
    logger.progname = "workout_uploader"
    logger.send(:"#{severity}", "#{message}")
    logger.close
  end
end

def startup()
  unless File.exists?("#{CONFIG['watch_path']}/.strava.tkr")
    dot_tkr = File.open("#{CONFIG['watch_path']}/.strava.tkr", "w+")
  else
    dot_tkr = File.open("#{CONFIG['watch_path']}/.strava.tkr", "r+")
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
  files.each { |f| upload_file(f) }

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

def upload_file(activity)

    log "Syncing Activity - #{File.basename(activity)} to Strava"
    params = { :data_type => "#{CONFIG['file_type']}".downcase, :file => File.open("#{activity}", 'r') }

    begin
      upload = HTTMultiParty.post(
        "https://www.strava.com/api/v3/uploads",
        body: params,
        headers: { "Authorization" => "Bearer #{CONFIG['plugins']['strava']['token']}" }
      )

      if upload.code < 400
        log "Success! Upload ID: #{upload["upload_id"]}"
        @upload_count = @upload_count + 1
      elsif upload.code == 400
        log upload["error"], 'warn'
        @upload_count = @upload_count + 1
      else
        log "Uh oh, something went wrong uploading the activity: #{upload["message"]}", "error"
        log "=> Errors: #{upload["errors"]}", "error"
      end

    rescue Exception => e
        log "Uh oh, something went wrong uploading the activity: #{e.message}", "fatal"
    end

end

startup()
