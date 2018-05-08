require_relative 'api_client'
require 'json'


class FootballFeed

  def initialize(options)
    @credentials = {:username => options[:username], :password => options[:password]}
    @options = options
    @client = ApiClient.new(@credentials)
  end

  #Use to print parsed scores of NFL games on a given day in a given season.
  def get_score
   valid_dates = get_schedule
   valid_dates.each do |date|
     date.gsub!("-","")
   end
   if valid_dates.include?(@options[:date])
    response = @client.scoreboard_score(@options[:season], @options[:date])
    parsed = parse_scoreboard_response(response)
    parse_scores(parsed)
   else
     puts "Not a valid date for the given season."
   end
  end

  #Use to get days in which NFL games where played in a given season. ex result: 2018-01-21
  def get_schedule
    response = @client.full_game_schedule(@options[:season])
    parse_schedule_response(response)
  end

  #Use to print out parsed scores for every game in a given NFL season.
  def get_all_scores
    games = {}
    urls = []
    threads = []
    tags = []
    tags_mutex = Mutex.new

    #creates a list of urls to call, one for each day a game is played in a NFL season.
    dates = get_schedule
    dates.each do |date|
      pass_date = date.gsub("-","")
      urls << @client.scoreboard(@options[:season], pass_date)
    end

    #Uses threading to call each url generated earlier.
    urls.each do |url|
      threads << Thread.new(url,tags) do |url,tags|
        tag = @client.send_request_threaded(url)
        tags_mutex.synchronize {tags << tag}
      end
    end

    threads.each(&:join)

    #Creating a hash to store results from each scoreboard call.
    tags.each do |tag|
      parsed = parse_scoreboard_response(tag)
      parsed.each do |game|
        games[game['date']] = parsed
      end
    end

    #Prints out game scores in easy to read fashion.
    if @options[:team].nil?
      parse_all_scores(games)
    else
      parse_team_scores(games)
    end
  end


  #Parse scoreboard JSON response
  def parse_scoreboard_response(response)
    daily_status = []
    parsed_response = JSON.parse(response)
    game_score = parsed_response['scoreboard']['gameScore']

    game_score.each do |game|
      status = {}
      status['date'] = game['game']['date']
      status['away_team'] = game['game']['awayTeam']['Name']
      status['home_team'] = game['game']['homeTeam']['Name']
      status['away_score'] = game['awayScore']
      status['home_score'] = game['homeScore']
      daily_status << status
    end

    daily_status
  end

  #parse full_game_schedule JSON response
  def parse_schedule_response(response)
    dates_of_games = []
    parsed_response = JSON.parse(response)
    games = parsed_response['fullgameschedule']['gameentry']

    games.each do |game|
      unless dates_of_games.include?(game['date'])
        dates_of_games << game['date']
      end
    end

    dates_of_games
  end

  #parse data structure created when getting all scores for a season.
  def parse_all_scores(games)
    sorted = games.sort_by {|date, games| date }
    sorted.each do |date, games|
      games.each do |game|
        puts "#{date} #{game['away_team']}: #{game['away_score']} #{game['home_team']}: #{game['home_score']}"
      end
    end
  end

  def parse_team_scores(games)
    team_there = 0
    sorted = games.sort_by {|date, games| date }
    sorted.each do |date, games|
      games.each do |game|
        if @options[:team].include?(game['away_team'].downcase) or @options[:team].include?(game['home_team'].downcase)
         puts "#{date} #{game['away_team']}: #{game['away_score']} #{game['home_team']}: #{game['home_score']}"
          team_there += 1
        end
      end
    end
    if team_there == 0
      puts "No team with that name found."
    end
  end

  #parse data structure created when getting scores for a given day.
  def parse_scores(games)
    games.each do |game|
      puts "#{game['date']} #{game['away_team']}: #{game['away_score']} #{game['home_team']}: #{game['home_score']}"
    end
  end

end