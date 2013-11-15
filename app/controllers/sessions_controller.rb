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
      opt 'max-results', 'Max results', :type => :int, :default => 5
      opt :sort, 'Sort order', :type => String, :default => '-recent'
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
  # what2.each do |channel|

uploads_list_id = what2[0]['contentDetails']['uploads']

  playlistitems_response = client.execute!(
    :api_method => youtube.playlist_items.list,
    :parameters => {
      :playlistId => what2[0]['contentDetails']['relatedPlaylists']['uploads'],
      :part => 'snippet',
      :maxResults => 5
    }
  )

@what3 = JSON.parse(playlistitems_response.data.items.to_json)[0]['snippet']['thumbnails']['medium']

#   pts "Videos in list #{uploads_list_id}"
  @hi =[]
  playlistitems_response.data.items.each do |playlist_item|
    @hash = Hash["title" => "",
              "id" => "",
              "url" => "",
              "thumbnails" => "" ]

    @hash['title'] = playlist_item['snippet']['title']
    @hash['id'] = playlist_item['snippet']['resourceId']['videoId']
    @hash['url'] = 'http://www.youtube.com/watch?v='+playlist_item['snippet']['resourceId']['videoId'].to_s
    @hash['thumbnails'] = JSON.parse(playlist_item.to_json)['snippet']['thumbnails']['medium']['url']
    @hi<<@hash
  end

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





[{
  "kind"=>"youtube#playlistItem", "etag"=>"\"GbgM9_0DKhSLzW6BxAmfOJZH9RI/SBChugaU4dSpjYxb3Oq-dXUHLhc\"", "id"=>"UUwmkRbFSbzggtR9QALpBBXlUvSGj20_Z_", 
  "snippet"=>{
    "publishedAt"=>"2013-10-21T16:38:23.000Z", 
    "channelId"=>"UCHjzmXcM52GFvKQxsSEuZ-g", 
    "title"=>"IMG 1662", 
    "description"=>"", 
    
                      "thumbnails"=>{
                      "default"=>{"url"=>"https://i1.ytimg.com/vi/F6SNbytKCvU/default.jpg"}, 
                      "medium"=>{"url"=>"https://i1.ytimg.com/vi/F6SNbytKCvU/mqdefault.jpg"}, 
                      "high"=>{"url"=>"https://i1.ytimg.com/vi/F6SNbytKCvU/hqdefault.jpg"}, 
                      "standard"=>{"url"=>"https://i1.ytimg.com/vi/F6SNbytKCvU/sddefault.jpg"}, 
                      "maxres"=>{"url"=>"https://i1.ytimg.com/vi/F6SNbytKCvU/maxresdefault.jpg"}
                              },

      "channelTitle"=>"coolstorybro9000", "playlistId"=>"UUHjzmXcM52GFvKQxsSEuZ-g", "position"=>0, 
      "resourceId"=>{"kind"=>"youtube#video", 

      "videoId"=>"F6SNbytKCvU"}
  }},


    {"kind"=>"youtube#playlistItem", "etag"=>"\"GbgM9_0DKhSLzW6BxAmfOJZH9RI/ySwPJgnt8zWanXeNFfAd73ZzWiY\"", "id"=>"UUwmkRbFSbzggiEhYe-Sm6B7gdczfjAFnq", "snippet"=>{"publishedAt"=>"2013-03-28T09:30:49.000Z", "channelId"=>"UCHjzmXcM52GFvKQxsSEuZ-g", "title"=>"DIY Elevator Muzak", "description"=>"I install music in our boring elevator.", "thumbnails"=>{"default"=>{"url"=>"https://i1.ytimg.com/vi/osstErWhP_A/default.jpg"}, "medium"=>{"url"=>"https://i1.ytimg.com/vi/osstErWhP_A/mqdefault.jpg"}, "high"=>{"url"=>"https://i1.ytimg.com/vi/osstErWhP_A/hqdefault.jpg"}, "standard"=>{"url"=>"https://i1.ytimg.com/vi/osstErWhP_A/sddefault.jpg"}, "maxres"=>{"url"=>"https://i1.ytimg.com/vi/osstErWhP_A/maxresdefault.jpg"}}, "channelTitle"=>"coolstorybro9000", "playlistId"=>"UUHjzmXcM52GFvKQxsSEuZ-g", "position"=>1, "resourceId"=>{"kind"=>"youtube#video", "videoId"=>"osstErWhP_A"}}}, {"kind"=>"youtube#playlistItem", "etag"=>"\"GbgM9_0DKhSLzW6BxAmfOJZH9RI/Jr900fGoLZakRdrNio6LEXeY8MM\"", "id"=>"UUwmkRbFSbzgikhQxkWjuwVPqOhLKmHypH", "snippet"=>{"publishedAt"=>"2012-11-03T11:56:21.000Z", "channelId"=>"UCHjzmXcM52GFvKQxsSEuZ-g", "title"=>"shit bags", "description"=>"", "thumbnails"=>{"default"=>{"url"=>"https://i1.ytimg.com/vi/d2ycHc_RnMk/default.jpg"}, "medium"=>{"url"=>"https://i1.ytimg.com/vi/d2ycHc_RnMk/mqdefault.jpg"}, "high"=>{"url"=>"https://i1.ytimg.com/vi/d2ycHc_RnMk/hqdefault.jpg"}, "standard"=>{"url"=>"https://i1.ytimg.com/vi/d2ycHc_RnMk/sddefault.jpg"}}, "channelTitle"=>"coolstorybro9000", "playlistId"=>"UUHjzmXcM52GFvKQxsSEuZ-g", "position"=>2, "resourceId"=>{"kind"=>"youtube#video", "videoId"=>"d2ycHc_RnMk"}}}, {"kind"=>"youtube#playlistItem", "etag"=>"\"GbgM9_0DKhSLzW6BxAmfOJZH9RI/GFwIRsPYrS3RBU-e3PbbLPhYHpM\"", "id"=>"UUwmkRbFSbzggphGS4swuvKkOUU2VD6KSD", "snippet"=>{"publishedAt"=>"2012-07-12T08:37:12.000Z", "channelId"=>"UCHjzmXcM52GFvKQxsSEuZ-g", "title"=>"Wordz to yur momz", "description"=>"", "thumbnails"=>{"default"=>{"url"=>"https://i1.ytimg.com/s_vi/CF9qCsRIJP8/default.jpg?sqp=CMyClpQF&rs=AOn4CLCMr_rJucEFS8S3Aa5sIrAZ-h163g"}, "medium"=>{"url"=>"https://i1.ytimg.com/s_vi/CF9qCsRIJP8/mqdefault.jpg?sqp=CMyClpQF&rs=AOn4CLDsoI6rJ4---_iOXkSuNW8x6KHqtg"}, "high"=>{"url"=>"https://i1.ytimg.com/s_vi/CF9qCsRIJP8/hqdefault.jpg?sqp=CMyClpQF&rs=AOn4CLDf08E5Cp7bsU2Ix2fHvvCqyvhgGg"}}, "channelTitle"=>"coolstorybro9000", "playlistId"=>"UUHjzmXcM52GFvKQxsSEuZ-g", "position"=>3, "resourceId"=>{"kind"=>"youtube#video", "videoId"=>"CF9qCsRIJP8"}}}, {"kind"=>"youtube#playlistItem", "etag"=>"\"GbgM9_0DKhSLzW6BxAmfOJZH9RI/57GC5LOUridwb6i1ce8Mhcsoz44\"", "id"=>"UUwmkRbFSbzgg_DAW7knGYa898R12HfxVF", "snippet"=>{"publishedAt"=>"2012-03-07T02:48:17.000Z", "channelId"=>"UCHjzmXcM52GFvKQxsSEuZ-g", "title"=>"Kids Sneak into Transformers the Ride in Hollywood!!", "description"=>"A couple dudes sneak into transformers the ride at universal studios in hollywood and get chased by security.", "thumbnails"=>{"default"=>{"url"=>"https://i1.ytimg.com/s_vi/ueItDRlbwQg/default.jpg?sqp=CMyClpQF&rs=AOn4CLASms7MXBRMDeH1SN4vFoqEdyOpTg"}, "medium"=>{"url"=>"https://i1.ytimg.com/s_vi/ueItDRlbwQg/mqdefault.jpg?sqp=CMyClpQF&rs=AOn4CLBqPhOf-yfHoGZ_iWgQoBELFZAy-g"}, "high"=>{"url"=>"https://i1.ytimg.com/s_vi/ueItDRlbwQg/hqdefault.jpg?sqp=CMyClpQF&rs=AOn4CLC33lOMp-cKAgGVMFwGdRmoXwz7Tg"}, "standard"=>{"url"=>"https://i1.ytimg.com/s_vi/ueItDRlbwQg/sddefault.jpg?sqp=CMyClpQF&rs=AOn4CLCiQWT9jTQ8FGOEAF0cNBEpvanyXQ"}, "maxres"=>{"url"=>"https://i1.ytimg.com/s_vi/ueItDRlbwQg/maxresdefault.jpg?sqp=CMyClpQF&rs=AOn4CLBjlZq_F2wcaTNiTDCfgjDr5rW0_Q"}}, "channelTitle"=>"coolstorybro9000", "playlistId"=>"UUHjzmXcM52GFvKQxsSEuZ-g", "position"=>4, "resourceId"=>{"kind"=>"youtube#video", "videoId"=>"ueItDRlbwQg"}}}, {"kind"=>"youtube#playlistItem", "etag"=>"\"GbgM9_0DKhSLzW6BxAmfOJZH9RI/3pYol-4we0lkI0oIeaEsjQdnRng\"", "id"=>"UUwmkRbFSbzgivV4EzT8Kw2pj9zQdFrP6r", "snippet"=>{"publishedAt"=>"2011-03-29T05:39:02.000Z", "channelId"=>"UCHjzmXcM52GFvKQxsSEuZ-g", "title"=>"Miami Horror @ Knitting Factory Brooklyn, NY 3/29/11 vid 3", "description"=>"", "thumbnails"=>{"default"=>{"url"=>"https://i1.ytimg.com/vi/QkfkFG4bOfw/default.jpg"}, "medium"=>{"url"=>"https://i1.ytimg.com/vi/QkfkFG4bOfw/mqdefault.jpg"}, "high"=>{"url"=>"https://i1.ytimg.com/vi/QkfkFG4bOfw/hqdefault.jpg"}, "standard"=>{"url"=>"https://i1.ytimg.com/vi/QkfkFG4bOfw/sddefault.jpg"}, "maxres"=>{"url"=>"https://i1.ytimg.com/vi/QkfkFG4bOfw/maxresdefault.jpg"}}, "channelTitle"=>"coolstorybro9000", "playlistId"=>"UUHjzmXcM52GFvKQxsSEuZ-g", "position"=>5, "resourceId"=>{"kind"=>"youtube#video", "videoId"=>"QkfkFG4bOfw"}}}, {"kind"=>"youtube#playlistItem", "etag"=>"\"GbgM9_0DKhSLzW6BxAmfOJZH9RI/GNEpHgstzcB-jpL1nVjG_TGuLts\"", "id"=>"UUwmkRbFSbzgg9ZfHfh0XaJzqVC5sB-aUk", "snippet"=>{"publishedAt"=>"2011-03-29T05:18:03.000Z", "channelId"=>"UCHjzmXcM52GFvKQxsSEuZ-g", "title"=>"Miami Horror @ Knitting Factory Brooklyn, NY 3/29/11 vid 2", "description"=>"", "thumbnails"=>{"default"=>{"url"=>"https://i1.ytimg.com/vi/tUJdsEC3U7c/default.jpg"}, "medium"=>{"url"=>"https://i1.ytimg.com/vi/tUJdsEC3U7c/mqdefault.jpg"}, "high"=>{"url"=>"https://i1.ytimg.com/vi/tUJdsEC3U7c/hqdefault.jpg"}, "standard"=>{"url"=>"https://i1.ytimg.com/vi/tUJdsEC3U7c/sddefault.jpg"}, "maxres"=>{"url"=>"https://i1.ytimg.com/vi/tUJdsEC3U7c/maxresdefault.jpg"}}, "channelTitle"=>"coolstorybro9000", "playlistId"=>"UUHjzmXcM52GFvKQxsSEuZ-g", "position"=>6, "resourceId"=>{"kind"=>"youtube#video", "videoId"=>"tUJdsEC3U7c"}}}, {"kind"=>"youtube#playlistItem", "etag"=>"\"GbgM9_0DKhSLzW6BxAmfOJZH9RI/oF_VM3PJz4LIG6xjMRjOXiQel08\"", "id"=>"UUwmkRbFSbzgiRGObBE2PzRJgYw0fm51mP", "snippet"=>{"publishedAt"=>"2011-03-29T04:53:05.000Z", "channelId"=>"UCHjzmXcM52GFvKQxsSEuZ-g", "title"=>"Miami Horror @ Knitting Factory Brooklyn, NY 3/29/11", "description"=>"", "thumbnails"=>{"default"=>{"url"=>"https://i1.ytimg.com/s_vi/iGUEM4p5JOA/default.jpg?sqp=CMyClpQF&rs=AOn4CLD6aJGAOlT-jFtt7W2kVohdS_WoXw"}, "medium"=>{"url"=>"https://i1.ytimg.com/s_vi/iGUEM4p5JOA/mqdefault.jpg?sqp=CMyClpQF&rs=AOn4CLD2QC94bNxcoaB-o3wS81WHnFAycg"}, "high"=>{"url"=>"https://i1.ytimg.com/s_vi/iGUEM4p5JOA/hqdefault.jpg?sqp=CMyClpQF&rs=AOn4CLDJR9noysL3mrbrwg5dyRdK9kTnkA"}, "standard"=>{"url"=>"https://i1.ytimg.com/s_vi/iGUEM4p5JOA/sddefault.jpg?sqp=CMyClpQF&rs=AOn4CLBG--spz7sWKLK9NIN9JVLJ2jskLQ"}, "maxres"=>{"url"=>"https://i1.ytimg.com/s_vi/iGUEM4p5JOA/maxresdefault.jpg?sqp=CMyClpQF&rs=AOn4CLDmBx-69cto9bS_3nqrpV2LCyMQOQ"}}, "channelTitle"=>"coolstorybro9000", "playlistId"=>"UUHjzmXcM52GFvKQxsSEuZ-g", "position"=>7, "resourceId"=>{"kind"=>"youtube#video", "videoId"=>"iGUEM4p5JOA"}}}, {"kind"=>"youtube#playlistItem", "etag"=>"\"GbgM9_0DKhSLzW6BxAmfOJZH9RI/-utYBkjdt7nFGmIjNJ9kqAxEe1I\"", "id"=>"UUwmkRbFSbzgiJgncJtrH1q0AnjdxOnv1H", "snippet"=>{"publishedAt"=>"2011-02-28T11:31:21.000Z", "channelId"=>"UCHjzmXcM52GFvKQxsSEuZ-g", "title"=>"Nero at voyeur", "description"=>"Hero at voyeur", "thumbnails"=>{"default"=>{"url"=>"https://i1.ytimg.com/vi/0Yc5rwzfEcU/default.jpg"}, "medium"=>{"url"=>"https://i1.ytimg.com/vi/0Yc5rwzfEcU/mqdefault.jpg"}, "high"=>{"url"=>"https://i1.ytimg.com/vi/0Yc5rwzfEcU/hqdefault.jpg"}}, "channelTitle"=>"coolstorybro9000", "playlistId"=>"UUHjzmXcM52GFvKQxsSEuZ-g", "position"=>8, "resourceId"=>{"kind"=>"youtube#video", "videoId"=>"0Yc5rwzfEcU"}}}, {"kind"=>"youtube#playlistItem", "etag"=>"\"GbgM9_0DKhSLzW6BxAmfOJZH9RI/RKBp-8wnfsou6C5ZZ2vKAVV7SKA\"", "id"=>"UUwmkRbFSbzgj2QG0rhFOdsdalAK3XIc7p", "snippet"=>{"publishedAt"=>"2011-02-28T11:30:47.000Z", "channelId"=>"UCHjzmXcM52GFvKQxsSEuZ-g", "title"=>"Nero at voyeur San Diego 2/27/11", "description"=>"Nero at voyeur San Diego 2/27/11", "thumbnails"=>{"default"=>{"url"=>"https://i1.ytimg.com/s_vi/ypGN6H3EKOA/default.jpg?sqp=CMyClpQF&rs=AOn4CLDY15AJbl8V8IrMR-MsXVbntVmK6g"}, "medium"=>{"url"=>"https://i1.ytimg.com/s_vi/ypGN6H3EKOA/mqdefault.jpg?sqp=CMyClpQF&rs=AOn4CLDDH6sh2DXAYZs0xupeoba3oLtsAQ"}, "high"=>{"url"=>"https://i1.ytimg.com/s_vi/ypGN6H3EKOA/hqdefault.jpg?sqp=CMyClpQF&rs=AOn4CLB-xIZIklL10YwybWwe6gFvHAYFqw"}, "standard"=>{"url"=>"https://i1.ytimg.com/s_vi/ypGN6H3EKOA/sddefault.jpg?sqp=CMyClpQF&rs=AOn4CLB1TLaKGtVJzQaCd3FVzli0Mv7dBg"}, "maxres"=>{"url"=>"https://i1.ytimg.com/s_vi/ypGN6H3EKOA/maxresdefault.jpg?sqp=CMyClpQF&rs=AOn4CLAZ92iYLfaabQxFfxQeNkFG_k1njw"}}, "channelTitle"=>"coolstorybro9000", "playlistId"=>"UUHjzmXcM52GFvKQxsSEuZ-g", "position"=>9, "resourceId"=>{"kind"=>"youtube#video", "videoId"=>"ypGN6H3EKOA"}}}, {"kind"=>"youtube#playlistItem", "etag"=>"\"GbgM9_0DKhSLzW6BxAmfOJZH9RI/oDYLWvxsHPcQOmOV_SkBQODZFqM\"", "id"=>"UUwmkRbFSbzgjCKIrgLGe3RrTVKX2jcc6_", "snippet"=>{"publishedAt"=>"2011-01-05T18:05:05.000Z", "channelId"=>"UCHjzmXcM52GFvKQxsSEuZ-g", "title"=>"Hey dog", "description"=>"Dogs", "thumbnails"=>{"default"=>{"url"=>"https://i1.ytimg.com/s_vi/sQPy9A3uiqc/default.jpg?sqp=CMyClpQF&rs=AOn4CLDpk7WmnR4hWWCs9GY5JN4myQvYqQ"}, "medium"=>{"url"=>"https://i1.ytimg.com/s_vi/sQPy9A3uiqc/mqdefault.jpg?sqp=CMyClpQF&rs=AOn4CLCYn-E3QytGY7W7lzKwIQQT5f4BQA"}, "high"=>{"url"=>"https://i1.ytimg.com/s_vi/sQPy9A3uiqc/hqdefault.jpg?sqp=CMyClpQF&rs=AOn4CLBepG8jcQJJH15nOkS13Y6gPClwLQ"}}, "channelTitle"=>"coolstorybro9000", "playlistId"=>"UUHjzmXcM52GFvKQxsSEuZ-g", "position"=>10, "resourceId"=>{"kind"=>"youtube#video", "videoId"=>"sQPy9A3uiqc"}}}, {"kind"=>"youtube#playlistItem", "etag"=>"\"GbgM9_0DKhSLzW6BxAmfOJZH9RI/xzn5TIZV824wvDZr8RhOm6v651s\"", "id"=>"UUwmkRbFSbzghar2X3Y9dlgN1ktND_KzCx", "snippet"=>{"publishedAt"=>"2011-01-05T18:04:52.000Z", "channelId"=>"UCHjzmXcM52GFvKQxsSEuZ-g", "title"=>"Crazy hula hoop animal dance girl", "description"=>"Crazy girl creates new dance sensation, the animal hula hoop. Alligator, monkey, chicken, tiger all included in this masterpiece of dane.", "thumbnails"=>{"default"=>{"url"=>"https://i1.ytimg.com/vi/l9LYuIbMdcY/default.jpg"}, "medium"=>{"url"=>"https://i1.ytimg.com/vi/l9LYuIbMdcY/mqdefault.jpg"}, "high"=>{"url"=>"https://i1.ytimg.com/vi/l9LYuIbMdcY/hqdefault.jpg"}, "standard"=>{"url"=>"https://i1.ytimg.com/vi/l9LYuIbMdcY/sddefault.jpg"}, "maxres"=>{"url"=>"https://i1.ytimg.com/vi/l9LYuIbMdcY/maxresdefault.jpg"}}, "channelTitle"=>"coolstorybro9000", "playlistId"=>"UUHjzmXcM52GFvKQxsSEuZ-g", "position"=>11, "resourceId"=>{"kind"=>"youtube#video", "videoId"=>"l9LYuIbMdcY"}}}, {"kind"=>"youtube#playlistItem", "etag"=>"\"GbgM9_0DKhSLzW6BxAmfOJZH9RI/mvdHx2vWsRRLpLlcEY1_tAaX1D0\"", "id"=>"UUwmkRbFSbzggtisZt9rw2vo5qpZbcfG2b", "snippet"=>{"publishedAt"=>"2011-01-05T17:59:43.000Z", "channelId"=>"UCHjzmXcM52GFvKQxsSEuZ-g", "title"=>"Supperclub nye", "description"=>"Nye at supperclub la", "thumbnails"=>{"default"=>{"url"=>"https://i1.ytimg.com/s_vi/CPG9jjd7328/default.jpg?sqp=CMyClpQF&rs=AOn4CLBoyCttD0keT8Klj6mhrfEr25IhmA"}, "medium"=>{"url"=>"https://i1.ytimg.com/s_vi/CPG9jjd7328/mqdefault.jpg?sqp=CMyClpQF&rs=AOn4CLCEe4c4N-miR73SXzC7wORoG13bsQ"}, "high"=>{"url"=>"https://i1.ytimg.com/s_vi/CPG9jjd7328/hqdefault.jpg?sqp=CMyClpQF&rs=AOn4CLAsZXt1XXfZsdiaHRmYM5TgBKwKug"}, "standard"=>{"url"=>"https://i1.ytimg.com/s_vi/CPG9jjd7328/sddefault.jpg?sqp=CMyClpQF&rs=AOn4CLBtsLPf2b2IH5tjSKZXMO58mtpiFg"}, "maxres"=>{"url"=>"https://i1.ytimg.com/s_vi/CPG9jjd7328/maxresdefault.jpg?sqp=CMyClpQF&rs=AOn4CLD-uZFl_4CvGGImToanviKQWxwl8A"}}, "channelTitle"=>"coolstorybro9000", "playlistId"=>"UUHjzmXcM52GFvKQxsSEuZ-g", "position"=>12, "resourceId"=>{"kind"=>"youtube#video", "videoId"=>"CPG9jjd7328"}}}, {"kind"=>"youtube#playlistItem", "etag"=>"\"GbgM9_0DKhSLzW6BxAmfOJZH9RI/vPIiMLEotjf6F9vGLioSeW12NQk\"", "id"=>"UUwmkRbFSbzgiU68xnnDuDmWaOKjUXwZhd", "snippet"=>{"publishedAt"=>"2010-09-30T03:58:14.000Z", "channelId"=>"UCHjzmXcM52GFvKQxsSEuZ-g", "title"=>"Id is stolen", "description"=>"This video was uploaded from an Android phone.", "thumbnails"=>{"default"=>{"url"=>"https://i1.ytimg.com/s_vi/kC36OAqf1Ls/default.jpg?sqp=CMyClpQF&rs=AOn4CLDz5534CrFZ23kvc5ravnN4ImGieA"}, "medium"=>{"url"=>"https://i1.ytimg.com/s_vi/kC36OAqf1Ls/mqdefault.jpg?sqp=CMyClpQF&rs=AOn4CLD6FDVDZg4CW06SvWURejKpy9nmSg"}, "high"=>{"url"=>"https://i1.ytimg.com/s_vi/kC36OAqf1Ls/hqdefault.jpg?sqp=CMyClpQF&rs=AOn4CLAwY2PAny5aJpVEA9A57yHE62AVQA"}, "standard"=>{"url"=>"https://i1.ytimg.com/s_vi/kC36OAqf1Ls/sddefault.jpg?sqp=CMyClpQF&rs=AOn4CLDdKKYiQbskQOoq3YU2JjpVVOMEzw"}, "maxres"=>{"url"=>"https://i1.ytimg.com/s_vi/kC36OAqf1Ls/maxresdefault.jpg?sqp=CMyClpQF&rs=AOn4CLALDw68aCmUF1Hki4f-YCWipe7Elg"}}, "channelTitle"=>"coolstorybro9000", "playlistId"=>"UUHjzmXcM52GFvKQxsSEuZ-g", "position"=>13, "resourceId"=>{"kind"=>"youtube#video", "videoId"=>"kC36OAqf1Ls"}}}, {"kind"=>"youtube#playlistItem", "etag"=>"\"GbgM9_0DKhSLzW6BxAmfOJZH9RI/7LW-evHMlcxGwQ8W6xtbDnUooSo\"", "id"=>"UUwmkRbFSbzgjn6ct52hq2id3Gy24Qgxg4", "snippet"=>{"publishedAt"=>"2010-09-28T06:37:07.000Z", "channelId"=>"UCHjzmXcM52GFvKQxsSEuZ-g", "title"=>"Corgi jumps off roof, lands in pool", "description"=>"Like the title says.", "thumbnails"=>{"default"=>{"url"=>"https://i1.ytimg.com/s_vi/0MOQ9xzgHBU/default.jpg?sqp=CMyClpQF&rs=AOn4CLDAd_bTs8qEzTFyAD2UKUd0-qX1Uw"}, "medium"=>{"url"=>"https://i1.ytimg.com/s_vi/0MOQ9xzgHBU/mqdefault.jpg?sqp=CMyClpQF&rs=AOn4CLCJxH9HjH_Z9J7q0ZEkLRBZbxktQA"}, "high"=>{"url"=>"https://i1.ytimg.com/s_vi/0MOQ9xzgHBU/hqdefault.jpg?sqp=CMyClpQF&rs=AOn4CLDmZ7-DFcsZN0fRPptpsi2QfU_wzQ"}}, "channelTitle"=>"coolstorybro9000", "playlistId"=>"UUHjzmXcM52GFvKQxsSEuZ-g", "position"=>14, "resourceId"=>{"kind"=>"youtube#video", "videoId"=>"0MOQ9xzgHBU"}}}]



































