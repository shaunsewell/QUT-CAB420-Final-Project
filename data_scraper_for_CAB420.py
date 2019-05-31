# data_scraper_for_CAB420.py
# Modified by Shaun Sewell on 28/5/19
#
# Modified version of my footywire.comau data scraper.
# Original version availible from https://github.com/shaunsewell/AFL-Analysis

from bs4 import BeautifulSoup
import requests
import re
from progress.bar import Bar
import csv

# Outline stats to gather
stats = ['Disposals', 'Kicks', 'Handballs', 'Marks', 
        'Tackles', 'Hitouts', 'Clearances', 'Clangers',
        'Frees For', 'Frees Against', 'Goals Kicked', 
        'Behinds Kicked', 'Rushed Behinds', 'Scoring Shots', 
        'Goal Assists', 'Inside 50s', 'Rebound 50s']

advanced_stats = ['Contested Possessions', 'Uncontested Possessions', 
                'Effective Disposals', 'Disposal Efficiency %','Contested Marks', 
                'Marks Inside 50','One Percenters',
                'Bounces']

# Need to remove spaces from team names
converted_names = {'Gold Coast' : 'Gold_Coast', 'North Melbourne' : 'North_Melbourne', 
                    'Port Adelaide': 'Port_Adelaide', 'St Kilda': 'St_Kilda', 
                    'West Coast': 'West_Coast', 'Western Bulldogs': 'Western_Bulldogs'}

teams_to_numbers = {'Adelaide' : 1, 'Brisbane' : 2, 'Carlton' : 3, 'Collingwood' : 4, 
                    'Essendon' : 5, 'Fremantle' : 6, 'Geelong' : 7, 'Gold_Coast' : 8,
                    'GWS' : 9, 'Hawthorn' : 10, 'Melbourne' : 11, 'North_Melbourne' : 12,
                    'Port_Adelaide' : 13, 'Richmond' : 14, 'St_Kilda' : 15, 'Sydney' : 16,
                    'West_Coast' : 17, 'Western_Bulldogs' : 18}

#-----------------------------------------------------------------------------------------------------------------------
# Convenience functions

def export_match_stats(list_of_matches, season, file_name):

    stat_list = []

    with Bar('Processing stats for export', max=len(list_of_matches), suffix='%(percent)d%% - %(eta)ds remaining') as stats_bar:
        for match in list_of_matches:
            # Home team
            home_stat_line = [season, match.round_number]
            home_team_number = 0
            away_team_number = 0
            for k in teams_to_numbers:
                if k == match.home_team:
                  home_team_number = teams_to_numbers[k]
                elif k == match.away_team:
                    away_team_number = teams_to_numbers[k]

            home_stat_line.append(home_team_number)   # Team
            home_stat_line.append(away_team_number)   # Opponent
            home_stat_line.append(1)        # Home team flag
            for keys in match.home_team_stats:
                home_stat_line.append(match.home_team_stats[keys])
            stat_list.append(home_stat_line)
            
            # Away Team
            away_stat_line = [season, match.round_number]

            away_stat_line.append(away_team_number) # Team
            away_stat_line.append(home_team_number) # Opponent
            away_stat_line.append(0)        # Home team flag
            for keys in match.away_team_stats:
                away_stat_line.append(match.away_team_stats[keys])
            stat_list.append(away_stat_line)
            stats_bar.next()
        stats_bar.finish()

    with Bar('Exporting', max=len(stat_list), suffix='%(percent)d%% - %(eta)ds remaining') as export_bar:
        with open(file_name, mode='w') as stats_file:
            stats_writer = csv.writer(stats_file, delimiter=',')
            for row in stat_list:
                stats_writer.writerow(row)
                export_bar.next()
        export_bar.finish()
#-----------------------------------------------------------------------------------------------------------------------

class DataScraper:
    def __init__(self):
        # Original Header for footywire.com.au 
        # Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3
        # Removed the image references to reduce response data.
        self.headers = {"User-Agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36","Accept":"text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8", "Referer":"http://www.google.com.au","Cache-Control":"max-age=0"}
        self.base_URL = "http://www.footywire.com/afl/footy/ft_match_statistics?mid="
        self.session_obj = requests.Session()
           
    def fix_title_string(self, soup):
        # Home Team defeated by Away Team at Venue Round Number Day, Date(dd,mm,yy)
        # St Kilda defeated by Melbourne at Marvel Stadium Round 1 Saturday, 25th March 2017
        # After spliting: 
        # ['AFL', 'Match', 'Statistics', ':', 'St_Kilda', 'defeated_by', 'Melbourne', 
        # 'at', 'Marvel', 'Stadium', 'Round', '1', 'Saturday,', '25th', 'March', '2017']

        seperators = ["defeated by", "defeats", "defeat", "drew with", "drew"]
        for s in seperators:
            title = soup.find(string=re.compile(s))
            if title != None:
                #replace defeated by with defeated_by to making traversing the array simpler
                if s == "defeated by":
                    title = title.replace('defeated by', 'defeated_by')
                elif s == "drew with":
                    title = title.replace('drew with', 'drew_with')

                #do the same for the multi word team names
                for key in converted_names:
                    title = title.replace(key, converted_names[key])

                split_title = title.split(' ')
                return split_title
        
    def get_matches(self, start_match_id, end_match_id):
        Matches = []
        with Bar('Getting Matches', max=(end_match_id + 1) - start_match_id, suffix='%(percent)d%% - %(eta)ds remaining') as bar:
            for id in range(start_match_id, end_match_id + 1): 
                try:
                    match = self.get_match(id)
                    Matches.append(match)
                except:
                    print("Failed to get match : " + str(id))
                    pass
                    
                bar.next()
            bar.finish()
        return Matches
    
    def get_match(self, match_id):
        response = self.session_obj.get(self.base_URL + str(match_id), headers=self.headers)
        soup = BeautifulSoup(response.text, features="html.parser")
        # returns a page title of the form: 
        

        split_title = self.fix_title_string(soup) 
        # index 0 - 3 is 'AFL' 'Match' 'Statistics' ':' and can be ignored
        # Set home and away teams
        home_team = split_title[4]
        away_team = split_title[6]
        
        # Set the venue and round number
        venue = ""
        round_number = ""
        if split_title[9] == 'Round':
            venue = split_title[8]
            round_number = split_title[10]
        elif split_title[10] == 'Round': 
            venue = split_title[8] + " " + split_title[9]
            round_number = split_title[11]
        elif split_title[11] == 'Round':
            venue = split_title[8] + " " + split_title[9] + " " + split_title[10]
            round_number = split_title[12]
        else: # Must be a final
            if split_title[10] == 'Final':
                venue = split_title[8]
                round_number = split_title[9] + " " + split_title[10]
            elif split_title[11] == 'Final': 
                venue = split_title[8] + " " + split_title[9]
                round_number = split_title[10] + " " + split_title[11]


        # Set the day and date of the match
        day = split_title[-4].replace(',','')
        date = split_title[-3] + ' ' + split_title[-2] + ' ' + split_title[-1]

        # Set the attendance
        attendance_string = soup.find(text=re.compile('Attendance:')).split(' ')
        attendance = attendance_string[-1]

        # Get the stats
        home_team_stats, away_team_stats = self.get_stats(soup)
        home_team_stats, away_team_stats = self.get_advanced_stats(match_id, home_team_stats, away_team_stats)
        home_team_stats, away_team_stats = self.get_match_winner(soup, home_team_stats, away_team_stats)
        return Match(match_id, home_team, away_team, venue, round_number, day, date, attendance, home_team_stats, away_team_stats)
    
    def get_stats(self, soup):
        home_stats = {}
        away_stats = {}

        for stat in stats:
            stat_row = soup.find_all('td', text=stat)[0].find_parent('tr')
            stat_elements = stat_row.find_all('td')

            if stat_elements != None:
                if stat_elements[0].text == '-':
                    home_stats[stat] = None
                else:
                    home_stats[stat] = stat_elements[0].text
                
                if stat_elements[2].text == '-':
                    away_stats[stat] = None
                else:
                    away_stats[stat] = stat_elements[2].text
            

        return home_stats, away_stats

    def get_advanced_stats(self, match_id, home_stats, away_stats):
        response = self.session_obj.get(self.base_URL + str(match_id) + "&advv=Y", headers=self.headers)
        advanced_soup = BeautifulSoup(response.text, features="html.parser")

        for stat in advanced_stats:
            try:
                advanced_stat_row = advanced_soup.find_all('td', text=stat)[0].find_parent('tr')
                advanced_stat_elements = advanced_stat_row.find_all('td')
            except:
                break
                

            if advanced_stat_elements != None:
                #Remove any annoying % signs
                temp_home = advanced_stat_elements[0].text.replace('%','')
                temp_away = advanced_stat_elements[2].text.replace('%','')

                if temp_home == '-':
                    home_stats[stat] = None
                else:
                    home_stats[stat] = temp_home
                
                if temp_away == '-':
                    away_stats[stat] = None
                else:
                    away_stats[stat] = temp_away
        
        return home_stats, away_stats

    def get_match_winner(self, soup, home_stats, away_stats):
        end_result = soup.find_all('td', text='End of Game')[0].find_parent('tr')
        end_result_element = end_result.find_all('td')
        if 'Won' in end_result_element[0].text:
            home_stats['Winner'] = 1
            away_stats['Winner'] = 0
        elif 'Won' in end_result_element[2].text:
            home_stats['Winner'] = 0
            away_stats['Winner'] = 1
        else:
            home_stats['Winner'] = 0
            away_stats['Winner'] = 0
        
        return home_stats, away_stats

class Match:
    def __init__(self, match_id, home_team, away_team, venue, round_number, day, date, attendance, home_team_stats, away_team_stats):
        self.match_id = match_id
        self.home_team = home_team
        self.away_team = away_team
        self.venue = venue
        self.round_number = round_number
        self.day = day
        self.date = date
        self.attendance = attendance
        self.home_team_stats = home_team_stats
        self.away_team_stats = away_team_stats
        
class Player:
    def __init__(self, player_id, player_name, player_team, player_age, player_stats):
        self.player_id = player_id
        self.player_name = player_name
        self.player_team = player_team
        self.player_stats = player_stats
        
#-----------------------------------------------------------------------------------------------------------------------
# Testing implementation of functions  

scraper = DataScraper()

match_list_2012 = scraper.get_matches(5343, 5549)  #5343 5549
export_match_stats(match_list_2012, 2012, "AFLStats-2012.csv")
match_list_2013 = scraper.get_matches(5550, 5756)
export_match_stats(match_list_2013, 2013, "AFLStats-2013.csv")
match_list_2014 = scraper.get_matches(5757, 5963)
export_match_stats(match_list_2014, 2014, "AFLStats-2014.csv")
match_list_2015 = scraper.get_matches(5964, 6171)
export_match_stats(match_list_2015, 2015, "AFLStats-2015.csv")
match_list_2016_1 = scraper.get_matches(6172 , 6369)
match_list_2016_2 = scraper.get_matches(9298, 9306)
match_list_2016 = match_list_2016_1 + match_list_2016_2
export_match_stats(match_list_2016, 2016, "AFLStats-2016.csv")
match_list_2017 = scraper.get_matches(9307, 9513)
export_match_stats(match_list_2017, 2017, "AFLStats-2017.csv")
match_list_2018 = scraper.get_matches(9514, 9720) 
export_match_stats(match_list_2018, 2018, "AFLStats-2018.csv")

# Layout of columns in export files
# year, round, team, opponent, h/a flag, disposals, kicks, handballs, marks,
# tackles, hitouts, clearances, clangers, frees for, frees against, goals kicked,
# behinds kicked, rushed behinds, scoring shots, goal assists, inside 50s, rebound 50s,
# contested possessions, uncontested possessions, effective disposals, disposal efficiency %,
# contested marks, marks inside 50, one percenters, bounces
#
