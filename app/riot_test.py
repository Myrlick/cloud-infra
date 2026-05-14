import requests
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
f = open(os.path.join(BASE_DIR, "../riot_api_key.txt"), "r")

API_KEY = f.readline().strip()
GAME_NAME = "HUGE PLAYER IQ"
TAG_LINE = "SMART"  # или твой тег без #


url = f"https://europe.api.riotgames.com/riot/account/v1/accounts/by-riot-id/{GAME_NAME}/{TAG_LINE}"

headers = {
    "X-Riot-Token": API_KEY
}

response = requests.get(url, headers=headers)
print(response.status_code)
print(response.json())
PUUID = response.json()["puuid"]
games = f"https://europe.api.riotgames.com/lol/match/v5/matches/by-puuid/{PUUID}/ids?start=0&count=5"
response2 = requests.get(games, headers=headers)
matchID = response2.json()[0]
match = f"https://europe.api.riotgames.com/lol/match/v5/matches/{matchID}"
response3 = requests.get(match, headers=headers)
print(response.status_code)
print(response2.status_code)
print(response.json())
print(response2.json())
print(response3.status_code)
print(response3.json())