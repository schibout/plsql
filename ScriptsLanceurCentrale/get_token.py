"""Génère token.json (OAuth utilisateur) pour Drive + Sheets."""
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build

SCOPES = [
    "https://www.googleapis.com/auth/drive",
    "https://www.googleapis.com/auth/spreadsheets",
]

flow = InstalledAppFlow.from_client_secrets_file("credentials.json", SCOPES)
creds = flow.run_local_server(port=0)   # ouvre le navigateur : se connecter et accepter

with open("token.json", "w", encoding="utf-8") as f:
    f.write(creds.to_json())

# Vérification : affiche le compte et 5 fichiers du Drive
drive = build("drive", "v3", credentials=creds)
print("Connecté :", drive.about().get(fields="user").execute()["user"]["emailAddress"])
for fic in drive.files().list(pageSize=5, fields="files(id,name)").execute()["files"]:
    print(" -", fic["name"], fic["id"])
