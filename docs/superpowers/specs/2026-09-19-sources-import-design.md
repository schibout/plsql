# ODAT Watch — choix des dossiers d'import ODAT

Date : 19/09/2026. Validé avec l'utilisateur.

## Objectif
Le bouton « 📥 Importer les nouveaux fichiers ODAT » ne scanne que `../ODAT` et `~/Downloads`.
L'utilisateur veut choisir lui-même le(s) dossier(s) à importer, via une boîte de dialogue Windows,
et que ce choix soit mémorisé. CSV seulement (pas de zip), pas de glisser-déposer.

## Design
- **Stockage** : table SQLite `parametres(cle TEXT PRIMARY KEY, valeur TEXT)` dans `odat.db`,
  clé `import.dossiers` (chemins séparés par `;`). Pas d'écriture dans `config.ini`.
- **`sources.py`** : `dossiers_memorises(con) -> list[Path]`, `ajouter_dossier(con, chemin)`,
  `retirer_dossier(con, chemin)`, `choisir_dossier() -> Path | None` (boîte de dialogue tkinter
  `askdirectory` lancée dans un sous-processus Python, pour ne pas bloquer le thread Streamlit ;
  `None` si annulé ou tkinter absent), `SOURCES_DEFAUT = [ODAT_DIR, DOWNLOADS]`.
- **`ingest.run(roots)`** : inchangé dans sa logique ; le journal commence par une ligne par dossier
  scanné (« <dossier> : N fichier(s) », ou « absent »).
- **Barre latérale (`app.py`)** : expander « Sources d'import » sous le bouton d'import :
  case « Scanner aussi ODAT et Téléchargements » (cochée), champ « Dossier » + boutons
  « 📂 Parcourir… » et « Ajouter », liste des dossiers mémorisés avec ✖ et mention « absent ».
  L'import scanne défauts (si cochés) + mémorisés.
- **Tests** : paramètres (ajout, doublon, retrait, persistance), `run()` sur un dossier temporaire
  avec une photo réelle copiée depuis l'archive (import puis doublon), commande du sous-processus.

## Hors périmètre
Zips, glisser-déposer, planification.
