import sys
import pandas as pd

libraryPath = "C:\\Users\\schibout\\AppData\\Local\\Programs\\Python\\Python314\\Lib\\site-packages"
if libraryPath not in sys.path:
    sys.path.append(libraryPath)

try:
    import gdrive
    print(" Import du module gdrive réussi.")
except ImportError as e:
    print(f" Impossible d'importer 'gdrive' : {e}")
    sys.exit(1)

# ... reste du code ...

try:
    from gdrive import gdrive
    print(" Import de la classe gdrive réussi.")
except ImportError as e:
    print(f" Impossible d'importer 'gdrive' depuis {libraryPath}")
    print(f"Erreur : {e}")
    sys.exit(1)

# 2. Identifiants de test
DOSSIER_DRIVE_ID = "1bkXK77bOQb8TXG69y_n_Qw9zM-Wru1BO"
SPREADSHEET_ID = "1QNJUUM8lJcHkVOQTNguInGvmI5xZX69EwUqxYL0al1Q"
RANGE_NAME = "Feuil1"

def test_gdrive_connection():
    try:
        print("\n--- Début du test de connexion Google Drive ---")
        
        # Initialisation de la connexion
        print("Initialisation du client gdrive avec le token 'générique'...")
        gdrive_client = gdrive(DOSSIER_DRIVE_ID, token="générique")
        print(" Connexion établie / Instance gdrive créée.")

        # Test de lecture d'une feuille Google Sheets
        print(f"Tentative de lecture du Google Sheet (ID: {SPREADSHEET_ID})...")
        df = gdrive_client.exportGsheetToDataFrame(SPREADSHEET_ID, RANGE_NAME)

        print("\n Récupération des données réussie !")
        print(f"Nombre de lignes récupérées : {len(df)}")
        print("\nAperçu des 3 premières lignes :")
        print(df.head(3))

    except Exception as e:
        print("\n Échec de la connexion ou de la récupération des données.")
        print(f"Détail de l'erreur : {e}")

if __name__ == "__main__":
    test_gdrive_connection()