require 'json'

module League

    class GoalScorerPage < Jekyll::Page
        def initialize(site, base, dir, season_name, rank_table, team_hash, config)
            @site = site
            @base = base
            @dir = dir
            @name = 'goal_scorers.html'

            self.process(@name)
            self.read_yaml(File.join(base, '_layouts'), 'player_ranking.html')

            self.data['rank_title'] = 'goal_scorers'
            self.data['scoring_name'] = 'player.goals_penalty'
            self.data['field1'] = 'goals'
            self.data['field2'] = 'penalty'
            self.data['rank_table'] = rank_table
            self.data['team_hash'] = team_hash
            self.data['display_name'] = season_name
            self.data['link'] = config['link']
            self.data['description'] = config['description']
        end
    end

    class AssistsPage < Jekyll::Page
        def initialize(site, base, dir, season_name, rank_table, team_hash, config)
            @site = site
            @base = base
            @dir = dir
            @name = 'assists_list.html'

            self.process(@name)
            self.read_yaml(File.join(base, '_layouts'), 'player_ranking.html')

            self.data['rank_title'] = 'assist_list'
            self.data['scoring_name'] = 'player.assists_penalty'
            self.data['field1'] = 'assists'
            self.data['field2'] = 'penalty_make'
            self.data['rank_table'] = rank_table
            self.data['team_hash'] = team_hash
            self.data['display_name'] = season_name
            self.data['link'] = config['link']
            self.data['description'] = config['description']
        end
    end

    class TeamPage < Jekyll::Page
        def initialize(site, base, dir, team_key, team, season_key, season, history_stats)
            @site = site
            @base = base
            @dir = dir
            @name = 'index.html'

            self.process(@name)
            self.read_yaml(File.join(base, '_layouts'), 'team.html')
            

            self.data['team_key'] = team_key
            self.data['team'] = team
            self.data['season_key'] = season_key
            self.data['season'] = season

            self.data['history_stats'] = history_stats
        end
    end

    class GamePage < Jekyll::Page
        def buildStartingSquad(squad, team_player_hash)
            for i in 0..(squad.length-1)
                s = squad[i]
                l = s['locator']
                p = team_player_hash[s['name']]
                
                if p == nil
                    puts "!!!! Player '#{s['name']}' is not found in cur team"
                end

                if l != nil
                    squad[i] = {
                        'name' => p['name'],
                        'number' => p['number'],
                        'img' => p['img'],
                        'locator' => l
                    }
                else
                    squad[i] = team_player_hash[s['name']]
                end
            end
        end
        def buildBench(bench, team_player_hash)
            for i in 0..(bench.length-1)
                s = bench[i]
                bench[i] = team_player_hash[s['name']]
            end
        end

        def initialize(site, base, dir, key, game, home_team, away_team)
            @site = site
            @base = base
            @dir = dir
            @name = 'index.html'

            self.process(@name)
            self.read_yaml(File.join(base, '_layouts'), 'game.html')
            

            self.data['key'] = key
            self.data['game'] = game

            # build squad
            if game['home']['squad'] != nil
                if game['home']['squad'] == 'default'
                    game['home']['squad'] = home_team['players']['starting']
                else
                    self.buildStartingSquad(game['home']['squad'], home_team['player_hash'])
                end
            end
            if game['home']['bench'] != nil
                self.buildBench(game['home']['bench'], home_team['player_hash'])
            end

            if game['away']['squad'] != nil
                if game['away']['squad'] == 'default'
                    game['away']['squad'] = away_team['players']['starting']
                else
                    self.buildStartingSquad(game['away']['squad'], away_team['player_hash'])
                end
            end
            if game['away']['bench'] != nil
                self.buildBench(game['away']['bench'], away_team['player_hash'])
            end
            # self.data['home_team'] = home_team
            # self.data['away_team'] = away_team

            
        end
    end

    def self.calculate_table_player_contest (player_hash, games, group_games_hash)
        games.each do |key, score|
            # key = "G-A-宁广涵-张稞雨"
            # score = [ 10, 8 ]
            a = key.split('-', 4)
            group_games_hash[a[1]][key] = {
                'players' => [a[2], a[3]],
                'score' => score
            }
            if score.length > 0
                # already played
                p0 = player_hash[a[2]]
                p0['games_played'] += 1
                p0['scores'] += score[0]

                p1 = player_hash[a[3]]
                p1['games_played'] += 1
                p1['scores'] += score[1]

                if score[0] > score[1]
                    p0['wins'] += 1;
                    p1['loses'] += 1;
                elsif score[0] < score[1]
                    p1['wins'] += 1;
                    p0['loses'] += 1;
                else
                    p0['draws'] += 1;
                    p1['draws'] += 1;
                end
            end
        end

        # post process
        for p in player_hash
            p[1]['points'] = p[1]['wins'] * 3 + p[1]['draws']
        end
    end

    def self.calculate_table (team_hash, games_pair, entry)
        # Iterate games to calculate data

        # clear data 
        for team in team_hash
            team[1][entry] = {
                'games_played' => 0,
                'wins' => 0,
                'draws' => 0,
                'loses' => 0,
                'goals_for' => 0,
                'goals_against' => 0,
                'goals_diff' => 0,
                'points' => 0,
                'forfeits' => 0,
            }
        end

        for p in games_pair
            key = p[0]
            game = p[1]

            if game['schedule']
                next
            end

            t0 = team_hash[game['home']['key']][entry]
            t0['games_played'] += 1;
            t0['goals_for'] += game['home']['score'];
            t0['goals_against'] += game['away']['score'];

            t1 = team_hash[game['away']['key']][entry]
            t1['games_played'] += 1;
            t1['goals_for'] += game['away']['score'];
            t1['goals_against'] += game['home']['score'];
            
            if game['home']['score'] > game['away']['score']
                t0['wins'] += 1;
                t1['loses'] += 1;
            elsif game['home']['score'] < game['away']['score']
                t1['wins'] += 1;
                t0['loses'] += 1;
            else
                t0['draws'] += 1;
                t1['draws'] += 1;
            end

            if game['home']['forfeit'] != nil
                t0['forfeits'] += 1;
            elsif game['away']['forfeit'] != nil
                t1['forfeits'] += 1;
            end
        end

        # post process
        for team in team_hash
            t = team[1][entry]
            t['goals_diff'] = t['goals_for'] - t['goals_against']
            t['points'] = t['wins'] * 3 + t['draws'] - 3 * t['forfeits']

            t['avg_gf'] = t['games_played'] == 0 ? 0.0 : t['goals_for'].fdiv(t['games_played'])
            t['avg_ga'] = t['games_played'] == 0 ? 0.0 : t['goals_against'].fdiv(t['games_played'])

            t['avg_gf'] = sprintf("%0.1f", t['avg_gf'])
            t['avg_ga'] = sprintf("%0.1f", t['avg_ga'])
        end
    end

    def self.calculate_table_special_rank (team_hash, games_pair, entry)
        # Iterate games to calculate data

        # clear data 
        for team in team_hash
            team[1][entry] = {
                'games_played' => 0,
                'wins' => 0,
                'draws' => 0,
                'loses' => 0,
                'goals_for' => 0,
                'goals_against' => 0,
                'goals_diff' => 0,
                'points' => 0
            }
        end

        for p in games_pair
            key = p[0]
            game = p[1]

            if game['schedule']
                next
            end

            t0 = team_hash[game['home']['key']][entry]
            t0['games_played'] += 1;
            t0['goals_for'] += game['home']['score'];
            t0['goals_against'] += game['away']['score'];

            t1 = team_hash[game['away']['key']][entry]
            t1['games_played'] += 1;
            t1['goals_for'] += game['away']['score'];
            t1['goals_against'] += game['home']['score'];
            
            # TEMP: ranking win points special rules
            winpoint = game['type'] == 'rank-r1' ? 2 : 1;

            if game['home']['score'] > game['away']['score']
                t0['wins'] += 1;
                t1['loses'] += 1;
                t0['points'] += winpoint;
            elsif game['home']['score'] < game['away']['score']
                t1['wins'] += 1;
                t0['loses'] += 1;
                t1['points'] += winpoint;
            else
                t0['draws'] += 1;
                t1['draws'] += 1;
            end
        end

        # post process
        for team in team_hash
            t = team[1][entry]
            t['goals_diff'] = t['goals_for'] - t['goals_against']

            t['avg_gf'] = t['games_played'] == 0 ? 0.0 : t['goals_for'].fdiv(t['games_played'])
            t['avg_ga'] = t['games_played'] == 0 ? 0.0 : t['goals_against'].fdiv(t['games_played'])

            t['avg_gf'] = sprintf("%0.1f", t['avg_gf'])
            t['avg_ga'] = sprintf("%0.1f", t['avg_ga'])
        end
    end

    # default SeasonPage (League table)
    class LeagueSeasonPage < Jekyll::Page
    # class LeagueSeasonPage < Jekyll::PageWithoutAFile
        def initialize(site, base, dir, season, team_hash, games_pair, config, season_name)
            @site = site
            @base = base
            @dir = dir
            # @name = "#{season[0]}.html"
            @name = "index.html"
            # @layout = 'season.html'
            # @path = if site.in_theme_dir(base) == base # we're in a theme
            #     site.in_theme_dir(base, dir, name)
            #   else
            #     site.in_source_dir(base, dir, name)
            #   end

            # puts @path

            self.process(@name)
            
            
            # self.data = season[1]
            # puts base
            self.read_yaml(File.join(base, "_layouts"), "season.html")

            # self.data = {}
            
            # if config != nil and config['display_name'] != nil
            #     self.data['display_name'] = config['display_name']
            # else
            #     self.data['display_name'] = season
            # end
            # self.data["title"] = self.data['display_name']

            self.data['display_name'] = season_name
            self.data["title"] = season_name
            self.data['winner'] = config['winner'] ? team_hash[config['winner']] : nil
            
            self.data['link'] = config['link']

            # League.calculate_table(team_hash, games_pair, 'table')
            team_tables = team_hash.map{ |key, value| value }

            # team_array = (season[1]['teams'].to_a).map{|key, team| team}

            sorted = (team_tables.sort_by { |team| [ -team['table']['points'], -team['table']['goals_diff'], -team['table']['goals_for'], team['table']['goals_against'], team['table']['games_played'] ] })
            # sorted = (team_array.sort_by { |team| [ -team['table']['points'], -team['table']['goals_for'] + team['table']['goals_against'], -team['table']['goals_for'] ] })
            # puts sorted

            self.data['table'] = sorted

            self.data['games_pair'] = games_pair

            self.data['description'] = config['description']
            self.data['rules'] = config['rules']
        end
    end

    class FriendlySeasonPage < Jekyll::Page
        def initialize(site, base, dir, season, team_hash, games_pair, config, season_name)
            @site = site
            @base = base
            @dir = dir
            # @name = "#{season[0]}.html"
            @name = "index.html"

            self.process(@name)

            self.read_yaml(File.join(base, "_layouts"), "season_friendly.html")

            # self.data = {}

            self.data['display_name'] = season_name
            self.data["title"] = season_name
            self.data['link'] = config['link']

            self.data['table'] = team_hash.map{ |key, value| value }

            self.data['games_pair'] = games_pair

            self.data['description'] = config['description']
            self.data['rules'] = config['rules']
        end
    end

    # player contest for juggle cup
    class PlayerContestSeasonPage < Jekyll::Page
        def initialize(site, base, dir, season, team_info, config)
            @site = site
            @base = base
            @dir = dir
            @name = "index.html"
            self.process(@name)
            self.read_yaml(File.join(base, "_layouts"), "season_player_contest.html")

            season_name = config['display_name']

            self.data['display_name'] = season_name
            self.data["title"] = season_name
            self.data['description'] = config['description']
            self.data['rules'] = config['rules']

            games = config['games']

            self.data['winner'] = config['winner'] ? config['winner'] : nil

            # group stage

            groups = config['group_stage']

            player_hash = Hash.new

            if groups != nil

                group_games = Hash.new
                group_tables = Hash.new
                
                groups.each do |group_key, players|
                    group_games[group_key] = Hash.new
                    group_tables[group_key] = Hash.new
                    group_tables[group_key]['players'] = Hash.new
                    for player in players
                        player_hash[player] = {
                            'games_played' => 0,
                            'wins' => 0,
                            'draws' => 0,
                            'loses' => 0,
                            'scores' => 0,
                            'points' => 0,
                        }

                        group_tables[group_key]['players'][player] = player_hash[player]
                    end
                end

                team_info['players'].each do |info|
                    p = player_hash[info['name']]
                    if p != nil
                        p['info'] = info
                    end
                end


                group_games_input = games.select{|key, game| key.include? 'G-'}
                League.calculate_table_player_contest(player_hash, group_games_input, group_games)

                # Generate group games html contents

                group_tables.each do |group_key, group|
                    # simple not points version first
                    sorted = (group['players'].sort_by { |k, p| [ -p['points'], -p['scores'], p['games_played'] ] })
                    group['sorted'] = sorted
                end

                self.data['group_tables'] = group_tables
                self.data['group_games'] = group_games
                self.data['players'] = player_hash

            end

            knockout_stage = config['knockout_stage']
            if (knockout_stage != nil)
                # knock out stage

                # knockout_games_input = games.select{|key, game| key.include? 'K-'}

                # make it in correct order
                # self.data['knockout_teams']
                knockout_array = Array.new(knockout_stage.length)

                # puts knockout_stage.length

                # puts games

                for i in 0..(knockout_stage.length-1)
                    round = knockout_stage[i]
                    round_array = Array.new(round.length)

                    for j in 0..(round.length-1)
                        key = round[j]
                        
                        if key == nil
                            round_array[j] = nil
                            next
                        end

                        game = games[key]
                        a = key.split('-', 4)
                        game_array = Array.new(3)
                        round_array[j] = game_array

                        p0 = player_hash[a[2]]
                        p1 = player_hash[a[3]]

                        game_array[0] = p0 != nil ? p0 : {
                            'info' => {
                                'img' => 'question-mark.png',
                                'name' => a[2]
                            }
                        }

                        game_array[1] = p1 != nil ? p1 : {
                            'info' => {
                                'img' => 'question-mark.png',
                                'name' => a[3]
                            }
                        }

                        if game != nil
                            # key = "K-8-宁广涵-张稞雨"
                            # score = [ 10, 8 ]
                            if game.length > 0
                                game_array[2] = game
                            else
                                game_array[2] = nil
                            end
                        else
                            # key = "K-8-A1-B2"
                            # 还未进行的小组赛分档用
                            game_array[2] = nil
                        end
                    end

                    knockout_array[i] = round_array

                    # puts knockout_array[i]
                    # puts team_hash[round[0]]
                    # puts team_hash['613111']
                end

                # puts knockout_array

                self.data['knockout_array'] = knockout_array
            end

            

        end
    end

    # group + knockout for jxcup
    class GroupAndKnockOutSeasonPage < Jekyll::Page
        def initialize(site, base, dir, season, team_hash, games_hash, games_pair, config, season_name)
            @site = site
            @base = base
            @dir = dir
            @name = "index.html"
            self.process(@name)
            self.read_yaml(File.join(base, "_layouts"), "season_group_knockout.html")
            # if self.data['display_name'] != nil
            #     self.data['display_name'] = config['display_name']
            # else
            #     self.data['display_name'] = season
            # end
            # self.data["title"] = self.data['display_name']
            self.data['display_name'] = season_name
            self.data["title"] = season_name
            self.data['link'] = config['link']

            knockout_stage = config['knockout_stage']
            # puts knockout_stage

            if config['display_name'] != nil
                self.data['display_name'] = config['display_name']
            end

            if (knockout_stage != nil)
                # knock out stage

                # make it in correct order
                # self.data['knockout_teams']
                knockout_array = Array.new(knockout_stage.length)

                # puts knockout_stage.length

                for i in 0..(knockout_stage.length-1)
                    round = knockout_stage[i]
                    round_array = Array.new(round.length)

                    for j in 0..(round.length-1)
                        game = round[j]
                        game_array = Array.new(3)
                        
                        # there's team info in game
                        # but we still write team info
                        # because we display versus before game happens
                        game_array[0] = team_hash[game[0]]
                        game_array[1] = team_hash[game[1]]
                        game_array[2] = [game[2], games_hash[game[2]]]

                        round_array[j] = game_array
                    end

                    knockout_array[i] = round_array

                    # puts knockout_array[i]
                    # puts team_hash[round[0]]
                    # puts team_hash['613111']
                end

                # puts knockout_array

                self.data['knockout_array'] = knockout_array
            end

            self.data['winner'] = config['winner'] ? team_hash[config['winner']] : nil

            # group stage

            groups = config['group_stage']

            if groups != nil

                ##############################################

                # Iterate games to calculate data
                group_games_pair = games_pair.select{|key, game| game['type'].include? 'group'}
                League.calculate_table(team_hash, group_games_pair,'table')

                ##############################################


                # puts groups.count
                group_tables = Hash.new
                group_games = Hash.new

                groups.each do |group_key, team_keys|
                    # simple not points version first
                    team_array = team_keys.map{|key| team_hash[key]}
                    team_keys_set = team_keys.to_set
                    sorted = (team_array.sort_by { |team| [ -team['table']['points'], -team['table']['goals_diff'], -team['table']['goals_for'], team['table']['goals_against'], team['table']['games_played'] ] })
                    group_tables[group_key] = sorted

                    # puts team_keys_set
                    cur_group_games_pair = group_games_pair.select{|key, game| team_keys_set.include?(game['home']['key'])}

                    group_games[group_key] = cur_group_games_pair
                end

                self.data['group_tables'] = group_tables
                self.data['group_games'] = group_games

            end



            # self.data['games_pair'] = games_pair
            self.data['description'] = config['description']
            self.data['rules'] = config['rules']

        end
    end

    # region knockouts ranking for jxcup
    class RegionKnockoutsSeasonPage < Jekyll::Page
        def initialize(site, base, dir, season, team_hash, games_hash, games_pair, config, season_name)
            @site = site
            @base = base
            @dir = dir
            @name = "index.html"
            self.process(@name)
            self.read_yaml(File.join(base, "_layouts"), "season_region_knockouts.html")
            self.data['display_name'] = season_name
            self.data["title"] = season_name
            self.data['link'] = config['link']

            if config['display_name'] != nil
                self.data['display_name'] = config['display_name']
            end

            knockouts = config['knockouts']
            # puts knockouts

            if (knockouts != nil)
                # knock out stage

                self.data['knockouts'] = Hash.new

                knockouts.each do |knockout_key, k|

                    # make it in correct order
                    # self.data['knockout_teams']
                    knockout_array = Array.new(k['bracket'].length)

                    # puts knockouts.length

                    for i in 0..(k['bracket'].length-1)
                        round = k['bracket'][i]
                        round_array = Array.new(round.length)

                        for j in 0..(round.length-1)
                            game = round[j]
                            game_array = Array.new(3)
                            
                            # there's team info in game
                            # but we still write team info
                            # because we display versus before game happens
                            game_array[0] = team_hash[game[0]]
                            game_array[1] = team_hash[game[1]]
                            game_array[2] = [game[2], games_hash[game[2]]]

                            round_array[j] = game_array
                        end

                        knockout_array[i] = round_array

                        # puts knockout_array[i]
                        # puts team_hash[round[0]]
                        # puts team_hash['613111']
                    end

                    # puts knockout_array

                    # TODO: attach other games

                    self.data['knockouts'][knockout_key] = Hash.new
                    self.data['knockouts'][knockout_key]['knockout_array'] = knockout_array
                    if (k['winner'] != nil)
                        self.data['knockouts'][knockout_key]['winner'] = team_hash[k['winner']]
                    end
                    if (k['other_games'] != nil)
                        self.data['knockouts'][knockout_key]['other_games'] = Array.new(k['other_games'].length)
                        for i in 0..(k['other_games'].length-1)
                            gk = k['other_games'][i]
                            self.data['knockouts'][knockout_key]['other_games'][i] = [gk, games_hash[gk]]
                        end
                    end


                end
            end

            self.data['winner'] = config['winner'] ? team_hash[config['winner']] : nil

            # group stage

            groups = config['regions']

            if groups != nil

                ##############################################

                # Iterate games to calculate data
                group_games_pair = games_pair.select{|key, game| game['type'].include? 'rank'}
                # TEMP special rank
                League.calculate_table_special_rank(team_hash, group_games_pair,'table')

                ##############################################


                # puts groups.count
                group_tables = Hash.new
                group_games = Hash.new

                groups.each do |group_key, team_keys|
                    # simple not points version first
                    team_array = team_keys.map{|key| team_hash[key]}
                    team_keys_set = team_keys.to_set
                    sorted = (team_array.sort_by { |team| [ -team['table']['points'], -team['table']['goals_diff'], -team['table']['goals_for'], team['table']['goals_against'], team['table']['games_played'] ] })
                    group_tables[group_key] = sorted

                    # puts team_keys_set
                    cur_group_games_pair = group_games_pair.select{|key, game| team_keys_set.include?(game['home']['key'])}

                    group_games[group_key] = cur_group_games_pair
                end

                self.data['group_tables'] = group_tables
                self.data['group_games'] = group_games

            end



            # self.data['games_pair'] = games_pair
            self.data['description'] = config['description']
            self.data['rules'] = config['rules']

        end
    end

    class SeasonPageGenerator < Jekyll::Generator
        safe true

        def add_player_to_goal_scorers(player, team, e)
            if player == nil
                # puts e['player']
                team['player_hash'][e['player']] = {
                    'name' => e['player'],
                    'goals' => 0,
                    'penalty' => 0,
                    'assists' => 0,
                    'penalty_make' => 0,
                }
                player = team['player_hash'][e['player']]
            end
            
            player['goals'] += 1
            if e['type'] == 'penalty'
                player['penalty'] += 1
            end
        end

        def add_player_to_assists(player, team, e)
            if player == nil
                # puts e['player']
                team['player_hash'][e['player']] = {
                    'name' => e['player'],
                    'goals' => 0,
                    'penalty' => 0,
                    'assists' => 0,
                    'penalty_make' => 0,
                }
                player = team['player_hash'][e['player']]
            end
            
            player['assists'] += 1
            if e['type'] == 'penalty'
                player['penalty_make'] += 1
            end
        end

        def generate(site)

            # team_key => { season_key => stats }
            site.data['history_teams_stats'] = Hash.new


            site.data['seasons'].each do |season|
                # convert nilClass to array

                config = season[1]['config']

                # --------------------------------------------------------------
                # Player contests special

                if config != nil and config['type'] == 'player contest'
                    season_name = season[0]
                    if config['display_name'] != nil
                        season_name = config['display_name']
                    end

                    team_info = season[1][config['team_info']]

                    site.pages << PlayerContestSeasonPage.new(site, site.source, File.join('seasons', season[0]), season[0], team_info, config)
                    next
                end
                # -------------------------------------------------------------



                team_hash = season[1]['teams']
                team_hash.each do |key, team|
                    team['games'] = Array.new
                    team['key'] = key

                    team['player_hash'] = Hash.new
                    if team['players'] != nil
                        
                        starting = team['players']['starting']
                        if starting != nil
                            starting.each do |p|
                                p['goals'] = 0
                                p['penalty'] = 0
                                p['assists'] = 0
                                p['penalty_make'] = 0
                                team['player_hash'][p['name']] = p
                            end
                        end

                        subs = team['players']['subs']
                        if subs != nil
                            subs.each do |p|
                                p['goals'] = 0
                                p['penalty'] = 0
                                p['assists'] = 0
                                p['penalty_make'] = 0
                                team['player_hash'][p['name']] = p
                            end
                        end
                    end

                    # team['players']['starting'].each{|p| puts p}
                end
                # team_array = (team_hash.to_a).map{|key, team| team}

                

                games_pair = season[1]['games'].to_a

                # puts games_pair

                games_hash = Hash.new

                
                # generate each game page
                games_pair.each do |p|
                    key = p[0]
                    game = p[1]
                    games_hash[key] = game
                    # puts key
                    # puts game

                    # puts game['away']['key']

                    home_team = team_hash[game['home']['key']]
                    away_team = team_hash[game['away']['key']]

                    if home_team['players'] == nil
                        home_team['players'] = {
                            "starting" => [],
                            "subs" => []
                        }
                    end
                    if away_team['players'] == nil
                        away_team['players'] = {
                            "starting" => [],
                            "subs" => []
                        }
                    end

                    home_team['games'] << p
                    away_team['games'] << p

                    game['home']['display_name'] = home_team['display_name']
                    game['home']['logo'] = home_team['logo']
                    game['away']['display_name'] = away_team['display_name']
                    game['away']['logo'] = away_team['logo']

                    if game['home']['events'] != nil
                        game['home']['events'].each do |e|
                            next if e['player'] == '??'
                            if e['type'] == 'goal' or e['type'] == 'penalty'
                                player = home_team['player_hash'][e['player']]
                                add_player_to_goal_scorers(player, home_team, e)

                                if e['assist'] != nil
                                    assist_player = home_team['player_hash'][e['assist']]
                                    add_player_to_assists(assist_player, home_team, e)
                                end

                                # if player == nil
                                #     # puts e['player']
                                #     home_team['player_hash'][e['player']] = {'name' => e['player'], 'goals' => 0, 'penalty' => 0}
                                #     player = home_team['player_hash'][e['player']]
                                # end
                                
                                # player['goals'] += 1
                                # if e['type'] == 'penalty'
                                #     player['penalty'] += 1
                                # end
                            end
                        end
                    end

                    if game['home']['events'] != nil
                        game['away']['events'].each do |e|
                            next if e['player'] == '??'
                            if e['type'] == 'goal' or e['type'] == 'penalty'
                                player = away_team['player_hash'][e['player']]
                                add_player_to_goal_scorers(player, away_team, e)

                                if e['assist'] != nil
                                    assist_player = away_team['player_hash'][e['assist']]
                                    add_player_to_assists(assist_player, away_team, e)
                                end

                                # if player == nil
                                #     # puts e['player']
                                #     away_team['player_hash'][e['player']] = {'name' => e['player'], 'goals' => 0, 'penalty' => 0}
                                #     player = away_team['player_hash'][e['player']]
                                # end

                                # player['goals'] += 1
                                # if e['type'] == 'penalty'
                                #     player['penalty'] += 1
                                # end
                            end
                        end
                    end

                    site.pages << GamePage.new(site, site.source, File.join('seasons', season[0], 'games', key), key, game, home_team, away_team)
                end


                goal_scorers = Array.new
                assists_list = Array.new

                # include all games (groups and knockout for tournament)
                League.calculate_table(team_hash, games_pair, 'stats')

                season_name = season[0]
                if config != nil and config['display_name'] != nil
                    season_name = config['display_name']
                end

                stats_is_table = false
                if config == nil or config['type'] == 'league'
                    stats_is_table = true
                end

                history_team_stats = site.data['history_teams_stats']
                team_hash.each do |key, team|

                    team['player_hash'].each do |pk, p|
                        if p['goals'] > 0
                            p['teamkey'] = key
                            goal_scorers << p
                        end
                        if p['assists'] > 0
                            p['teamkey'] = key
                            assists_list << p
                        end
                    end

                    if stats_is_table
                        team['table'] = team['stats']
                    end

                    if history_team_stats[key] == nil
                        history_team_stats[key] = Hash.new
                    end
                    history_team_stats[key][season[0]] = team['stats']
                    history_team_stats[key][season[0]]['season_key'] = season[0]
                    history_team_stats[key][season[0]]['season_name'] = season_name
                    history_team_stats[key][season[0]]['is_winner'] = config['winner'] == key

                    # site.pages << TeamPage.new(site, site.source, File.join('seasons', season[0], key), key, team, season[0], season[1])
                end

                sorted_goal_scorers = (goal_scorers.sort_by { |p| [ -p['goals'], p['penalty'] ] })
                sorted_assists_list = (assists_list.sort_by { |p| [ -p['assists'], p['penalty_make'] ] })
                

                # puts games_hash

                


                # puts config
                if config == nil or config['type'] == 'league'
                    site.pages << LeagueSeasonPage.new(site, site.source, File.join('seasons', season[0]), season[0], team_hash, games_pair, config, season_name)
                elsif config['type'] == 'group + knockout'
                    site.pages << GroupAndKnockOutSeasonPage.new(site, site.source, File.join('seasons', season[0]), season[0], team_hash, games_hash, games_pair, config, season_name)
                elsif config['type'] == 'region knockouts ranking'
                    site.pages << RegionKnockoutsSeasonPage.new(site, site.source, File.join('seasons', season[0]), season[0], team_hash, games_hash, games_pair, config, season_name)
                elsif config['type'] == 'friendly'
                    site.pages << FriendlySeasonPage.new(site, site.source, File.join('seasons', season[0]), season[0], team_hash, games_pair, config, season_name)
                end

                
                site.pages << GoalScorerPage.new(site, site.source, File.join('seasons', season[0]), season_name, sorted_goal_scorers, team_hash, config)
                
                site.pages << AssistsPage.new(site, site.source, File.join('seasons', season[0]), season_name, sorted_assists_list, team_hash, config)


                # puts games_hash
                # puts games_pair
                # season table page
                
            end # each season

            site.data['nav_lists'] = Array.new
            site.data['seasons'].each do |season_key, season|
                if season['config']['type'] != 'player contest'
                    team_hash = season['teams']
                    team_hash.each do |team_key, team|
                        history_stats = site.data['history_teams_stats'][team_key].to_a.reverse()
                        site.pages << TeamPage.new(site, site.source, File.join('seasons', season_key, team_key), team_key, team, season_key, season, history_stats)
                    end

                end

                site.data['nav_lists'].push({
                    'key' => season_key,
                    'display_name' => season['config']['display_name']
                })

                # puts season['config']
            end

            site.data['nav_lists'] = (site.data['nav_lists'].sort_by { |s| s['key'] }).reverse()

            # puts site.data['nav_lists']

        end
    end

end