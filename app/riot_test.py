import requests
import os

def parse_match(match_data, puuid):
    participants = match_data['info']['participants']
    
    for participant in participants:
        if participant['puuid'] == puuid:
            # вот тут достаёшь нужные поля
            return {
                "champion": participant['championName'],
                "kills": participant['kills'],
                "deaths": participant['deaths'],
                "assists": participant['assists'],
                "win": participant['win'],
                "damage": participant['totalDamageDealtToChampions'],
                "gold": participant['goldEarned'],
                "position": participant['individualPosition'],
                "duration": match_data['info']['gameDuration'],
                "game_date": match_data['info']['gameCreation']
            }


BASE_DIR = os.path.dirname(os.path.abspath(__file__))
f = open(os.path.join(BASE_DIR, "../riot_api_key.txt"), "r")

API_KEY = f.readline().strip()
GAME_NAME = "HUGE PLAYER IQ"
TAG_LINE = "SMART"

headers = {
    "X-Riot-Token": API_KEY
}

url = f"https://europe.api.riotgames.com/riot/account/v1/accounts/by-riot-id/{GAME_NAME}/{TAG_LINE}"
puuid_resp = requests.get(url, headers=headers)
PUUID = puuid_resp.json()["puuid"]

games = f"https://europe.api.riotgames.com/lol/match/v5/matches/by-puuid/{PUUID}/ids?start=0&count=5"
games_resp = requests.get(games, headers=headers)

matchID = games_resp.json()[0]
match = f"https://europe.api.riotgames.com/lol/match/v5/matches/{matchID}"
match_resp = requests.get(match, headers=headers)

print(parse_match(match_resp.json(), PUUID))