#!/usr/bin/env ruby
require_relative '../lib/football_feed'
require 'thor'

@credentials = {}

class Feed < Thor
  class_option 'username', banner: 'USERNAME', type: :string, desc: 'Username for mysportsfeed.com'
  class_option 'password', banner: 'PASSWORD', type: :string, desc: 'Password for mysportsfeed.com'
  class_option 'credentials_file', banner: 'CREDENTIALS_FILE', type: :string, desc: 'Path to file with credentials for mysportsfeed.com'

  desc "get_score", "get the scores for a given day"
  option 'date', banner: 'DATE', type: :string, desc: 'The date of a game, ex 20180221', required: true
  option 'season', banner: 'SEASON', type: :string, desc: 'The season the game was played in, ex 2018-playoff', required: true
  def get_score
    opts = inject_credentials
    football = FootballFeed.new(opts)
    football.get_score
  end

  desc "get_schedule", "find dates for every game played in a given season"
  option 'season', banner: 'SEASON', type: :string, desc: 'The season you want dates for, ex 2017-regular', required: true
  def get_schedule
    opts = inject_credentials
    football = FootballFeed.new(opts)
    puts football.get_schedule
  end

  desc "get_all_scores", "gets the scores for all the games in a season"
  option 'season', banner: 'SEASON', type: :string, desc: 'The season you want scores for, ex 2018-playoff', required: true
  option 'team', banner: 'TEAM', type: :string, desc: 'The team you want scores for, ex patriots'
  def get_all_scores
    opts = inject_credentials
    football = FootballFeed.new(opts)
    football.get_all_scores
  end

  no_commands do

    def inject_credentials
      opts = options.dup
      unless options[:credentials_file].nil?
        credentials_file = File.open(options[:credentials_file]).read
        opts[:username] = credentials_file.split(",")[0].chomp
        opts[:password] = credentials_file.split(",")[1].chomp
      end
      opts
    end


  end




end

Feed.start(ARGV)
