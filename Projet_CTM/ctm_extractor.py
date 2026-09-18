import email
import imaplib
import os
import zipfile
from datetime import datetime

# --- CONFIGURATION ---
IMAP_SERVER = "imap.gmail.com"
EMAIL_USER = "dsin-finance-support@dalkia.fr"
# Remplacez les astérisques par votre mot de passe d'application de 16 caractères (sans espaces)
EMAIL_PASS = "supportfinance" 

# Dossier local de sauvegarde (créé automatiquement dans le même répertoire)
LOCAL_FOLDER = "./rapports_ctm"
SENDER_FILTER = "indic_ctm@dalkia.fr"

os.makedirs(LOCAL_FOLDER, exist_ok=True)

def fetch_ctm_reports():
    print("Connexion à Gmail...")
    try:
        mail = imaplib.IMAP4_SSL(IMAP_SERVER)
        mail.login(EMAIL_USER, EMAIL_PASS)
        mail.select("INBOX")
        print("Connecté avec succès !")
    except Exception as e:
        print(f"Erreur de connexion : {e}")
        return

    # Recherche des e-mails de l'expéditeur
    search_criteria = f'(FROM "{SENDER_FILTER}" SUBJECT "Extract CSV")'
    status, messages = mail.search(None, search_criteria)
    
    email_ids = messages[0].split()
    
    if not email_ids:
        print(f"Aucun e-mail trouvé avec le critère : {search_criteria}")
        mail.logout()
        return

    print(f"{len(email_ids)} e-mail(s) trouvé(s). Traitement en cours...")

    for num in email_ids:
        status, data = mail.fetch(num, "(RFC822)")
        for response_part in data:
            if isinstance(response_part, tuple):
                msg = email.message_from_bytes(response_part[1])
                
                # Récupération de l'horodatage
                msg_date = datetime.now().strftime("%Y%m%d_%H%M%S")

                # Analyse des pièces jointes
                for part in msg.walk():
                    if part.get_content_maintype() == 'multipart':
                        continue
                    if part.get('Content-Disposition') is None:
                        continue

                    filename = part.get_filename()
                    if filename:
                        filename = os.path.basename(filename)
                        filepath = os.path.join(LOCAL_FOLDER, filename)
                        
                        # Sauvegarde temporaire
                        with open(filepath, 'wb') as f:
                            f.write(part.get_payload(decode=True))
                        print(f"Pièce jointe trouvée : {filename}")

                        # Traitement .ZIP
                        if filename.endswith('.zip'):
                            try:
                                with zipfile.ZipFile(filepath, 'r') as zip_ref:
                                    for zipped_file in zip_ref.namelist():
                                        if zipped_file.endswith('.csv'):
                                            new_name = f"{msg_date}_{zipped_file}"
                                            extracted_path = zip_ref.extract(zipped_file, LOCAL_FOLDER)
                                            final_path = os.path.join(LOCAL_FOLDER, new_name)
                                            if os.path.exists(final_path):
                                                os.remove(final_path)
                                            os.rename(extracted_path, final_path)
                                            print(f" -> [ZIP] CSV extrait et renommé : {new_name}")
                            except Exception as e:
                                print(f"Erreur lors de la décompression du ZIP {filename}: {e}")
                            
                            os.remove(filepath)

                        # Traitement .CSV direct
                        elif filename.endswith('.csv'):
                            new_name = f"{msg_date}_{filename}"
                            final_path = os.path.join(LOCAL_FOLDER, new_name)
                            if os.path.exists(final_path):
                                os.remove(final_path)
                            os.rename(filepath, final_path)
                            print(f" -> [CSV] Fichier sauvegardé et renommé : {new_name}")

    mail.logout()
    print("Traitement terminé.")

if __name__ == "__main__":
    fetch_ctm_reports()