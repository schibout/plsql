# Controle Quotidien Complet - Mode Operatoire

## Objectif

Script de controle quotidien a executer chaque matin (avant 9h) pour verifier les traitements de la nuit et les flux Oracle EBS.

---

## Fichiers

| Fichier | Role |
|---|---|
| `Lancer_Controle_Quotidien.bat` | Lanceur Windows (double-clic) - appelle le script PowerShell avec les parametres par defaut |
| `Lancer_Controle_Quotidien.ps1` | Lanceur PowerShell - injecte les parametres, execute le SQL, analyse le log |
| `config.ps1` | **Configuration connexion Oracle et email** - seul fichier a modifier pour changer l'environnement |
| `Controle_Quotidien_Complet.sql` | Script SQL Oracle - requetes de controle (ne pas modifier les lignes `:v_xxx := N`) |
| `README.md` | Ce mode operatoire |
| `Logs\Controle_JJMMAAAA_AAAAMMJJ_HHMMSS.log` | Logs horodates generes automatiquement |

### config.ps1 - Parametres de connexion

```powershell
$ORA_USER    = "aroux"                          # Utilisateur Oracle
$ORA_PWD     = "GAERFTXF"                       # Mot de passe
$ORA_HOST    = "prdscanc1pdb03.dalkia.net"      # Serveur Oracle
$ORA_PORT    = "1521"                           # Port
$ORA_SERVICE = "ebs_PDBFINP1"                   # Service (PDB)
```

#### Configuration email (optionnel - pour `-EnvoyerMail`)

```powershell
$MAIL_SMTP_HOST  = "smtp.dalkia.net"         # Serveur SMTP
$MAIL_SMTP_PORT  = 25                         # Port (25 sans auth, 587 TLS)
$MAIL_FROM       = "ebs-controle@dalkia.fr"  # Expediteur
$MAIL_TO         = @("prenom.nom@dalkia.fr")  # Destinataires (tableau)
$MAIL_SSL        = $false                     # $true si TLS requis
# $MAIL_USER     = ""                         # Decommenter si auth SMTP requise
# $MAIL_PWD      = ""                         # Decommenter si auth SMTP requise
```

> Modifier uniquement `config.ps1` pour changer d'environnement (recette, preprod...). Ne pas versionner ce fichier s'il contient des mots de passe en clair.

---

## Lancement

### Utilisation standard (double-clic)

Double-cliquer sur `Lancer_Controle_Quotidien.bat` (utilise les parametres par defaut definis dans le `.bat`).

### Utilisation depuis PowerShell

```powershell
cd C:\Users\schibout\Documents\plsql\ControleMatinGenerique
.\Lancer_Controle_Quotidien.ps1
```

### Parametres disponibles

| Parametre | Defaut | Description |
|---|---|---|
| `-NbJoursHisto` | `3` | Nombre de jours d'historique a afficher dans les sections detail |
| `-HeureFermeture` | `19` | Heure de debut de la plage nuit (19h = 19:00) |
| `-HeureOuverture` | `7` | Heure de fin de la plage nuit (7h = 07:00) |
| `-GarderTempSQL` | _(absent)_ | Conserve le fichier SQL temporaire genere pour debug (voir ci-dessous) |
| `-EnvoyerMail` | _(absent)_ | Envoie le rapport par email apres execution (necessite la config email dans `config.ps1`) |

### Exemples

```powershell
# Voir 5 jours d'historique au lieu de 3
.\Lancer_Controle_Quotidien.ps1 -NbJoursHisto 5

# Plage nuit personnalisee (20h-8h)
.\Lancer_Controle_Quotidien.ps1 -HeureFermeture 20 -HeureOuverture 8

# Envoyer le rapport par mail apres execution
.\Lancer_Controle_Quotidien.ps1 -EnvoyerMail

# Debug : conserver le fichier SQL temporaire apres execution
.\Lancer_Controle_Quotidien.ps1 -GarderTempSQL

# Combinaison
.\Lancer_Controle_Quotidien.ps1 -NbJoursHisto 5 -HeureFermeture 20 -EnvoyerMail
```

---

## Deroulement automatique

Le script execute les etapes suivantes :

1. **Prerequis** : verifie que `Controle_Quotidien_Complet.sql` existe, cree le dossier `Logs\` si absent, detecte le client Oracle disponible (`sqlcl`, `sql` ou `sqlplus`)
2. **Connexion Oracle** : charge `config.ps1` (parametres `ORA_USER`, `ORA_PWD`, `ORA_HOST`, `ORA_PORT`, `ORA_SERVICE`)
3. **Generation du SQL** : injecte les parametres `-NbJoursHisto`, `-HeureFermeture`, `-HeureOuverture` dans le SQL source, prefixe les directives `SET` et `SPOOL`, et ecrit un fichier `temp_controle_AAAAMMJJ_HHMMSS.sql` — supprime automatiquement apres execution (sauf avec `-GarderTempSQL`)
4. **Execution** : lance le SQL via le client Oracle, mesure la duree, spoolle le log horodate
5. **Analyse du log** : detecte les erreurs `ORA-`, `SP2-`, alertes images manquantes, flux DSP incomplets
6. **Affichage** : erreurs techniques en rouge, alertes fonctionnelles en jaune
7. **Resume** : synthese chiffree, ouverture automatique du log dans Notepad si erreur critique
8. **Envoi mail** _(si `-EnvoyerMail`)_ : envoie le rapport avec le log en piece jointe ; sujet prefixe `[OK]`, `[WARNING]`, `[ALERTE]` ou `[ERREUR]` selon le statut

---

## Sections du rapport

| Section | Contenu |
|---|---|
| **Synthese globale** | Tableau recapitulatif de tous les indicateurs avec statut OK/W |
| **DSP - Detail des flux** | Liste des fichiers iValua recus (fournisseurs, commandes, receptions, deblocage) |
| **DSP - Synthese par jour** | Comptage par type et par jour |
| **NOTILUS** | Nombre et montant des notes de frais integrees |
| **FACTURES - Synthese** | Comptage par source (Xerox, Tradeshift, DSP) |
| **XEROX - Sans images** | Liste des factures Xerox sans document attache `[ALERTE]` |
| **XEROX - Avec images** | Compteur des factures Xerox correctement documentees |
| **GL - Interface** | Lignes en attente dans `GL_INTERFACE` par source et statut |
| **GL - Lignes creees** | Lignes GL validees par source avec cumul debit |
| **NUIT - Synthese** | Comptage des traitements par statut (OK / ERREUR / WARNING / EN COURS) |
| **NUIT - Erreurs** | Detail des traitements en erreur |
| **NUIT - Warnings** | Detail des traitements en avertissement |
| **NUIT - Longs (> 30 min)** | Traitements dont la duree depasse 30 minutes |
| **NUIT - En cours** | Traitements encore actifs au moment de l'execution (potentiellement bloques) |
| **Rapprochement Bancaire** | Imports de releves bancaires par date |

---

## Alertes a surveiller

| Alerte | Couleur | Action |
|---|---|---|
| `ORA-XXXXX` dans le log | Rouge | Erreur Oracle - analyser le message et la section concernee |
| `SP2-XXXXX` dans le log | Rouge | Erreur SQL*Plus - verifier la syntaxe du script SQL |
| `IMAGES MANQUANTES` | Rouge | Factures Xerox sans image - relancer l'integration ou attacher manuellement |
| `flux DSP` + `ALERTE` | Jaune | Moins de 5 flux DSP recus un jour ouvre - verifier iValua |
| `WARNING` dans les traitements nuit | Jaune | Traitement termine avec avertissement - consulter le log Oracle concurrent |
| Traitement EN COURS au matin | Jaune | Traitement potentiellement bloque - verifier via `fnd_concurrent_requests` |

> **RAPPEL LUNDI** : Le fichier SG (Societe Generale) doit etre charge manuellement car les imports automatiques ne tournent pas le dimanche.

---

## Localisation des logs

```
ControleMatinGenerique\
    Logs\
        Controle_19032026_20260319_071215.log   <- format : Controle_JJMMAAAA_AAAAMMJJ_HHMMSS.log
        Controle_18032026_20260318_221058.log
        ...
```

Les logs sont horodates et conserves indefiniment. Faire un menage periodique si l'espace disque est limite.

---

## Prerequis techniques

- PowerShell 5.1 ou superieur
- Client Oracle installe et dans le PATH : `sqlcl`, `sql` ou `sqlplus`
- Acces reseau a `prdscanc1pdb03.dalkia.net:1521`
- Variable `NLS_LANG` positionnee automatiquement par le script (`FRENCH_FRANCE.AL32UTF8`)
