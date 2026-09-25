# Obtenir un jeton d'accès Google Drive / Sheets

Le lanceur central (`CapAppro_CENTRAL.py`) et le worker (`CapAppro_GENERIQUE_EXECUTION.py`)
n'appellent pas Google directement : ils passent par la librairie maison `gdrive`
(`C:\RPA\python-libraries\`), instanciée avec `gdrive(<id dossier>, token=GDRIVE_TOKEN)`
(`GDRIVE_TOKEN = générique` dans `config_lanceur_central.ini`, section `[ordonnanceur]`).

Il ne s'agit pas d'une « clé API » : Drive et Sheets exigent une authentification **OAuth**.
Une clé API ne donne accès qu'aux fichiers publics. Il faut donc :

1. un **identifiant client OAuth** (`credentials.json`), qui identifie l'application ;
2. un **jeton** (`token.json`), qui autorise l'application à agir au nom de votre compte Google.

## 1. Créer l'identifiant client OAuth (une seule fois)

Dans https://console.cloud.google.com :

1. Créer (ou choisir) un projet, par exemple `capappro-local`.
2. **API et services › Bibliothèque** : activer **Google Drive API** et **Google Sheets API**
   (Sheets : le lanceur lit le classeur d'ordonnancement).
3. **API et services › Écran de consentement OAuth** :
   - type **Interne** si le compte appartient à une organisation Google Workspace, **Externe** sinon ;
   - en type Externe, ajouter votre adresse dans les **utilisateurs de test**.
4. **Identifiants › Créer des identifiants › ID client OAuth**, type **Application de bureau**.
5. **⬇ Télécharger le JSON**, le renommer `credentials.json` et le placer dans ce dossier.

À défaut de téléchargement, copier `credentials.exemple.json` en `credentials.json` et remplacer
les trois valeurs `A_REMPLACER` :

| Champ | Valeur (page de l'ID client) |
|---|---|
| `client_id` | **ID client**, se termine par `.apps.googleusercontent.com` |
| `client_secret` | **Code secret du client**, commence en général par `GOCSPX-` |
| `project_id` | **ID du projet** (pas son nom affiché) |

Le client doit être de type **Application de bureau** : le JSON commence alors par `"installed"`.
Un client « Application Web » (`"web"`) ne fonctionne pas avec `get_token.py`.

Sur un compte d'entreprise, l'administrateur Workspace bloque souvent la création de projets ou de
clients OAuth : demander alors le `credentials.json` à l'équipe qui gère la machine RPA.

## 2. Générer le jeton

```powershell
py -m pip install google-auth google-auth-oauthlib google-api-python-client
py get_token.py
```

Le navigateur s'ouvre : se connecter au compte Google et accepter les autorisations (Drive + Sheets).
Le script écrit `token.json` puis affiche le compte connecté et 5 fichiers du Drive pour vérification.

`token.json` contient un *refresh token* renouvelé automatiquement. Exception : en type **Externe**
avec l'application en mode « Test », il expire au bout de **7 jours** (relancer `get_token.py`).

## 3. Utilisation par la librairie `gdrive`

Non vérifié (le code de `gdrive.py` n'est pas dans ce dépôt) : l'emplacement, le nom et le format
(JSON ou pickle) du jeton attendu pour `token="générique"`, ainsi que les scopes demandés. Dans
`gdrive.py`, chercher `Credentials.from_authorized_user_file` / `pickle.load` (OAuth utilisateur) ou
`service_account.Credentials` (compte de service), et le chemin construit à partir du paramètre `token`.

## Sécurité

`credentials.json` et `token.json` donnent accès à tout le Drive du compte. Ils sont exclus par le
`.gitignore` racine : ne jamais les versionner, ni les joindre à un mail ou un ticket.
