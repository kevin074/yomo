class SessionsController < ApplicationController
	def create
    auth = request.env["omniauth.auth"]
    user = User.where(:provider => auth["provider"], :uid => auth["uid"]).first_or_initialize(
      :refresh_token => auth["credentials"]["refresh_token"],
      :access_token => auth["credentials"]["token"],
      :expires => auth["credentials"]["expires_at"],
      :name => auth["info"]["name"],
    )
    url = session[:return_to] || root_path
    session[:return_to] = nil
    url = root_path if url.eql?('/logout')

    if user.save
      session[:user_id] = user.id
      session[:access_token] = auth["credentials"]["token"]
      session[:refresh_token] = auth["credentials"]["refresh_token"]

      notice = "Signed in!"
      logger.debug "URL to redirect to: #{url}"
      redirect_to url, :notice => notice
    else
      raise "Failed to login"
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_url, :notice => "Signed out!"
  end

  def index
    @YOUTUBE_SCOPES = ['https://www.googleapis.com/auth/youtube.readonly',
      'https://www.googleapis.com/auth/yt-analytics.readonly']
    @YOUTUBE_API_SERVICE_NAME = 'youtube'
    @YOUTUBE_API_VERSION = 'v3'
    @YOUTUBE_ANALYTICS_API_SERVICE_NAME = 'youtubeAnalytics'
    @YOUTUBE_ANALYTICS_API_VERSION = 'v1'
    now = Time.new.to_i
    # SECONDS_IN_DAY = 60 * 60 * 24
    # SECONDS_IN_WEEK = SECONDS_IN_DAY * 7
    # one_day_ago = Time.at(now - SECONDS_IN_DAY).strftime('%Y-%m-%d')
    # one_week_ago = Time.at(now - SECONDS_IN_WEEK).strftime('%Y-%m-%d')

    opts = Trollop::options do
      opt :metrics, 'Report metrics', :type => String, :default => 'views'
      opt :dimensions, 'Report dimensions', :type => String, :default => 'video'
      opt 'start-date', 'Start date, in YYYY-MM-DD format', :type => String, :default => '2012-01-01'
      opt 'end-date', 'Start date, in YYYY-MM-DD format', :type => String, :default => '2013-11-11'
      opt 'start-index', 'Start index', :type => :int, :default => 1
      opt 'max-results', 'Max results', :type => :int, :default => 10
      opt :sort, 'Sort order', :type => String, :default => '-views'
    end

    # Initialize the client, Youtube, and Youtube Analytics

    client = Google::APIClient.new
    youtube = client.discovered_api(@YOUTUBE_API_SERVICE_NAME, @YOUTUBE_API_VERSION)
    youtube_analytics = client.discovered_api(@YOUTUBE_ANALYTICS_API_SERVICE_NAME,
      @YOUTUBE_ANALYTICS_API_VERSION)

    require 'google/api_client/client_secrets'
    client.authorization = Google::APIClient::ClientSecrets.load('app/controllers/client_secrets.json').to_authorization

    # Initialize OAuth 2.0 client    
      client.authorization.client_id = '434092699375.apps.googleusercontent.com'
      client.authorization.client_secret = 'or1NmEWn2QOmObdok9No6jcV'
      # client.authorization.access_token = session[:access_token]
      client.authorization.redirect_uri = 'http://localhost:3000/auth/google_oauth2/callback'

      client.authorization.scope = 'https://www.googleapis.com/auth/youtube.readonly', # may not be necessary
      'https://www.googleapis.com/auth/yt-analytics.readonly' # may not be necessary

      client.authorization.update_token!(
        access_token: session[:access_token],
        refresh_token: session[:refresh_token] # may not be necessary
        )

###############################################################################
channels_response = client.execute!(
  :api_method => youtube.channels.list,
  :parameters => {
    :mine => true,
    :part => 'contentDetails',
    # :fields => 'snippet(title)'
  }
)
what2 = channels_response.data.items.to_json
what2 = JSON.parse(what2)
@what3 = what2[0]["contentDetails"]['uploads']

  # what2.each do |channel|
uploads_list_id = what2[0]['contentDetails']['uploads']

  playlistitems_response = client.execute!(
    :api_method => youtube.playlist_items.list,
    :parameters => {
      :playlistId => 'UUHjzmXcM52GFvKQxsSEuZ-g',
      :part => 'snippet',
      # :maxResults => 50
    }
  )

@hi=playlistitems_response.data.items[0]['snippet']['title']

#   puts "Videos in list #{uploads_list_id}"

#   playlistitems_response.data.items.each do |playlist_item|
#     title = playlist_item['snippet']['title']
#     video_id = playlist_item['snippet']['resourceId']['videoId']

#     puts "#{title} (#{video_id})"
#   end
#   puts
# end

############################################################################################
    
    channels_response.data.items.each do |channel|
      opts[:ids] = "channel==#{channel.id}"
      end

      analytics_response = client.execute!(
        :api_method => youtube_analytics.reports.query,
        :parameters => opts
      )

      # puts "Analytics Data for Channel #{channel.id}"

      analytics_response.data.columnHeaders.each do |column_header|
        printf '%-20s', column_header.name
      end
      puts

      @data = analytics_response.data.rows
    end
  end

