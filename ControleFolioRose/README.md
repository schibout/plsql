# Contrôle Folio Rose — Réconciliation des factures

## Objectif

Vérifier, pour chaque **Folio** d'un export « Folio Rose », que le montant déclaré en
amont (`App Amont Débit`) correspond bien au montant réellement intégré dans **Oracle EBS**
(module AR — factures clients). Le script produit un rapport `OK` / `KO` par ligne, en
conservant les colonnes du fichier d'entrée.

---

## Fichiers du dossier

| Fichier | Rôle |
|---|---|
| `Lancer_Verification.bat` | Lanceur Windows (double-clic ou glisser-déposer du CSV). |
| `Verifier_Factures.ps1` | Script principal : lit le CSV, interroge Oracle, génère le rapport. |
| `config.ps1` | **Connexion Oracle** (serveur, service, utilisateur, mot de passe). Seul fichier à modifier pour changer d'environnement. |
| `ExportCSV-*.csv` | Fichier **d'entrée** (export Folio Rose). |
| `Logs\Rapport_Verification_*.csv` | Rapports **de sortie** horodatés. |

---

## Prérequis

1. **PowerShell 5.1+** (présent par défaut sous Windows).
2. **Client Oracle** disponible dans le PATH : `sqlplus` (Instant Client ou client complet).
   - Vérifier : ouvrir PowerShell et taper `sqlplus -V` → doit afficher une version.
3. **Accès réseau** au serveur Oracle (port `1521`).
   - Vérifier : `Test-NetConnection prdscanc1pdb03.dalkia.net -Port 1521` → `TcpTestSucceeded : True`.

---

## Configuration (`config.ps1`)

```powershell
$ORA_USER    = "aroux"                      # Utilisateur Oracle
$ORA_PWD     = "********"                    # Mot de passe
$ORA_HOST    = "prdscanc1pdb03.dalkia.net"  # Serveur Oracle
$ORA_PORT    = "1521"                        # Port
$ORA_SERVICE = "ebs_PDBFINP1"               # Service (PDB)
```

> ⚠️ **Sécurité** : ce fichier contient un mot de passe en clair. Ne pas le versionner
> dans un dépôt partagé et restreindre l'accès au dossier.

---

## Utilisation

### Méthode 1 — Glisser-déposer (la plus simple)

Glisser le fichier `ExportCSV-xxxx.csv` **sur** `Lancer_Verification.bat`.

### Méthode 2 — Double-clic avec nom de fichier

Ouvrir une invite dans le dossier et lancer :

```bat
Lancer_Verification.bat ExportCSV-04-06-2026.csv
```

### Méthode 3 — Directement en PowerShell

```powershell
.\Verifier_Factures.ps1 -CheminFichierCsv "ExportCSV-04-06-2026.csv"
```

À la fin, le chemin du rapport généré s'affiche en vert. Le rapport est dans `Logs\`.

---

## Format du fichier d'entrée

- Séparateur auto-détecté (`;`, `,` ou tabulation).
- Les **2 premières lignes** de filtres (ex. `Folio;Ecart;Début de période…`) sont
  automatiquement ignorées.
- Colonnes utilisées : **`Folio`**, **`Type`**, **`Date`**, **`App Amont Nb piéce`**,
  **`App Amont Débit`**, **`Nom fichier transmis`**.
  - Les lignes sans `Folio` **ou** sans `Nom fichier transmis` sont ignorées.

---

## Rapport de sortie (`Logs\Rapport_Verification_*.csv`)

Colonnes, dans cet ordre :

| Colonne | Source |
|---|---|
| `Folio` | fichier d'entrée |
| `Date` | fichier d'entrée |
| `App Amont Nb piéce` | fichier d'entrée |
| `App Amont Débit` | fichier d'entrée |
| `Nom fichier transmis` | fichier d'entrée |
| `Ecarts Débit` | calculé (`App Amont Débit` - `Montant Oracle`) |
| `Nb Pieces Oracle` | Oracle (`RA_CUSTOMER_TRX_*`) |
| `Montant Oracle` | Oracle (somme `EXTENDED_AMOUNT`) |
| `Montant Interface` | Oracle (`DKA_IARPAFAC_INTERFACE`, comptes 411) |
| `Statut Verification` | `OK` si `App Amont Débit` = `Montant Oracle`, sinon `KO` |

Un tableau récapitulatif s'affiche aussi à l'écran (vert = OK, rouge = KO).

---

## Logique de contrôle

Pour chaque couple `Folio` + `Nom fichier transmis`, le script interroge Oracle :

- **Côté facturation (AR)** : nombre de factures et somme des montants dans
  `RA_CUSTOMER_TRX_ALL` / `RA_CUSTOMER_TRX_LINES_ALL`
  (`attribute9 = Folio`, `attribute10 = Nom fichier`).
- **Côté interface** : somme des montants sur les comptes clients (`LOCAL_ACCOUNT LIKE '411%'`,
  `OA_status != 'A'`) dans `DKA_IARPAFAC_INTERFACE`.

Le **statut** est `OK` uniquement si le montant amont correspond au montant Oracle.

> ℹ️ **Évolution Multi-Flux** : Le script intègre désormais un routage par type de flux (via la colonne `Type`). Actuellement, seul le contrôle des factures **clients (AR)** est implémenté (`Type='CLIENT'`). Des *placeholders* sont préparés dans le code pour accueillir les futures requêtes de contrôle pour les flux **Fournisseurs (AP)** et **Grand Livre (GL)**.

---

## Tester sur un serveur distant

Deux cas possibles :

1. **Connexion à l'Oracle distant depuis ce poste (cas standard)** :
   il n'y a rien de plus à faire — `config.ps1` pointe déjà vers le serveur distant.
   Assurez-vous seulement que `sqlplus` est installé et que le port 1521 est joignable
   (voir *Prérequis*).

2. **Exécuter le script sur un autre serveur Windows** (ex. serveur d'exploitation) :
   - Copier le dossier complet sur le serveur cible.
   - Vérifier que ce serveur a un client Oracle (`sqlplus`) et l'accès réseau au 1521.
   - Lancer comme en *Méthode 2/3*.
   - À distance via PowerShell Remoting (si activé) :
     ```powershell
     Invoke-Command -ComputerName <SERVEUR> -ScriptBlock {
         & "C:\Chemin\ControleFolioRose\Verifier_Factures.ps1" `
            -CheminFichierCsv "C:\Chemin\ControleFolioRose\ExportCSV-04-06-2026.csv"
     }
     ```

---

## Dépannage

| Symptôme | Cause probable / solution |
|---|---|
| `sqlplus n'est pas reconnu` | Client Oracle absent du PATH → installer Instant Client ou ajouter son dossier au PATH. |
| `TcpTestSucceeded : False` | Pas d'accès réseau au serveur 1521 (VPN, pare-feu). |
| `ORA-01017` | Identifiants Oracle erronés dans `config.ps1`. |
| Toutes les lignes en `KO` | Vérifier que l'export contient bien des flux AR ; vérifier le rapprochement métier. |
| Accents cassés dans le rapport | Conserver `Verifier_Factures.ps1` en **UTF-8 avec BOM** (sinon les regex accentuées échouent sous PowerShell 5.1). |

---

## Notes techniques

- Une seule connexion Oracle par exécution : toutes les requêtes sont regroupées dans un
  fichier SQL temporaire, exécutées en un appel `sqlplus`, puis le rapport est reconstruit
  côté PowerShell.
- Les fichiers temporaires (`temp_verif_*.sql` / `.log`) sont supprimés en fin de traitement.
- Le rapport est piloté par le fichier d'entrée : chaque ligne valide apparaît une fois,
  dans l'ordre du CSV source.
