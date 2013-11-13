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
      opt :metrics, 'Report metrics', :type => String, :default => 'views,comments,favoritesAdded,favoritesRemoved,likes,dislikes,shares'
      opt :dimensions, 'Report dimensions', :type => String, :default => 'video'
      opt 'start-date', 'Start date, in YYYY-MM-DD format', :type => String, :default => 'one_week_ago'
      opt 'end-date', 'Start date, in YYYY-MM-DD format', :type => String, :default => 'one_day_ago'
      opt 'start-index', 'Start index', :type => :int, :default => 1
      opt 'max-results', 'Max results', :type => :int, :default => 10
      opt :sort, 'Sort order', :type => String, :default => '-views'
    end

    # Initialize the client, Youtube, and Youtube Analytics

    client = Google::APIClient.new
    youtube = client.discovered_api(@YOUTUBE_API_SERVICE_NAME, @YOUTUBE_API_VERSION)
    youtube_analytics = client.discovered_api(@YOUTUBE_ANALYTICS_API_SERVICE_NAME,
      @YOUTUBE_ANALYTICS_API_VERSION)

    # Initialize OAuth 2.0 client    
      client.authorization.client_id = '434092699375.apps.googleusercontent.com'
      client.authorization.client_secret = 'or1NmEWn2QOmObdok9No6jcV'
      client.authorization.access_token = session[:access_token]
      client.authorization.redirect_uri = 'http://localhost:3000/auth/google_oauth2/callback'
      client.authorization.scope = 'https://www.googleapis.com/auth/youtube.readonly',
      'https://www.googleapis.com/auth/yt-analytics.readonly'

      # Request authorization
      redirect_uri = client.authorization.authorization_uri

    # Delete the following two lines in future if possible. We have already autheniticated using Google OAuth 2. 
    # auth_util = CommandLineOAuthHelper.new(@YOUTUBE_SCOPES)
    # client.authorization = auth_util.authorize()

    # Wait for authorization code then exchange for token
      client.authorization.code = '...'
      client.authorization.fetch_access_token!

    channels_response = client.execute!(
      :api_method => youtube.channels.list,
      :parameters => {
        :mine => true,
        :part => 'id'
      }
    )

    channels_response.data.items.each do |channel|
      opts[:ids] = "channel==#{channel.id}"

      analytics_response = client.execute!(
        :api_method => youtube_analytics.reports.query,
        :parameters => opts
      )

      puts "Analytics Data for Channel #{channel.id}"

      analytics_response.data.columnHeaders.each do |column_header|
        printf '%-20s', column_header.name
      end
      puts

      # analytics_response.data.rows.each do |row|
      #   row.each do |value|
      #     printf '%-20s', value
      #   end
      #   puts
      # end
      @data = analytics_response.data.rows
    end
  end
end
