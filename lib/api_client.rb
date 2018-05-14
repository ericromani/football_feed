require 'net/http'
require 'net/https'
require 'base64'

class ApiClient


  def initialize(credentials)
    @credentials = credentials
  end

  #Generates url for an Api call getting info for NFL games for a given day in a given season.
  #season ex. 2018-playoff ex. date 20180121
  def scoreboard(season, date)
    endpoint = season + "/scoreboard.json?fordate=" + date
    url = "https://api.mysportsfeeds.com/v1.2/pull/nfl/" + endpoint
    url
  end

  #Api call getting info for NFL games for a given day in a given season.
  #Season ex. 2018-playoff ex. date 20180121
  def scoreboard_score(season,date)
    endpoint = season + "/scoreboard.json?fordate=" + date
    send_request(endpoint)
  end

  #Api call getting info for all NFL games scheduled in a given season.
  #season ex. 2017-regular
  def full_game_schedule(season)
    endpoint = season + "/full_game_schedule.json"
    send_request(endpoint)
  end


  # Request (GET)
  def send_request(endpoint_or_url)

    if endpoint_or_url.include?("https://api.mysportsfeeds.com/v1.2/pull/nfl/")
      uri = URI(endpoint_or_url)
    else
      request_url = "https://api.mysportsfeeds.com/v1.2/pull/nfl/" + endpoint_or_url
      uri = URI(request_url)
    end

    # Create client
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER

    # Create Request
    req =  Net::HTTP::Get.new(uri)

    # Add headers
    header =  "Basic " + Base64.encode64(@credentials[:username] + ":" + @credentials[:password])
    req.add_field "Authorization", header.strip

    # Fetch Request
    response = http.request(req)
    if response.code == "401"
      abort "Invalid username or password"
    elsif response.code == "400"
      abort "Invalid season - can only get information from completed seasons ex. 2018-playoff or 2017-regular."
    elsif response.code == "429"
      abort "Too many requests sent, wait and then retry"
    end
    response.body
  rescue StandardError => e
    raise "HTTP Request failed (#{e.message})"
  end

end
