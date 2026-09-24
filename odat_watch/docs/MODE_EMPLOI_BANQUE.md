# Mode d'emploi — Banque

Chaque onglet de 🏦 Banque suit le même cycle : **déposer** les fichiers du jour dans les dossiers indiqués
ci-dessus (réglables dans `config.ini`), **lancer** le contrôle depuis l'onglet, **lire** les tuiles puis les
sections dépliables, **diffuser** le rapport HTML ou le mail. Chaque lancement est enregistré en base : l'historique
et la trésorerie restent consultables même si les fichiers sont ensuite déplacés.

## Relevés bancaires

Suivi de la chaîne des relevés : PFE (Talend) → Control-M (FINEXT_J14INT_05/06) → EBS (import RBAFBIMP, contrôle
DKA_SRBCTRLRB). Deux flux par matinée : **flux A** (toutes banques) et **flux B** (Société Générale seule, banque
`banque_flux_b`).

### 1. Déposer

| Dossier | Contenu |
|---|---|
| `dossier_pfe` | Une exécution PFE par sous-dossier `<uuid>` (SOURCE / TARGET / TALEND), copiée telle quelle |
| `dossier_ebs` | Fichiers `AFB120.txt_<AAAAMMJJHHMMSS>` reçus par EBS (`data/traite`) |
| `dossiers_logs` | Logs `l<request_id>.req` et `o<request_id>.out` des imports RBAFBIMP et des contrôles DKA_SRBCTRLRB (sous-dossiers inclus) |

Les logs manquants se récupèrent en deux temps : le bouton **📋 list_releves.txt des logs manquants** écrit la
liste (`fichier_liste`), à passer à `copy_ebs_logs.sh` sur le serveur EBS ; déposer ensuite les logs rapatriés.

### 2. Lancer

1. **🔄 Scanner les dossiers** : lit tout ce qui est nouveau (les fichiers déjà lus sont reconnus, relancer ne double rien).
2. Choisir la **Matinée** à examiner (aujourd'hui par défaut).

### 3. Lire

- **Tuiles** : verdict du jour, verdict de chaque flux (OK / WARN / KO), comptes en rupture.
- **Frise de la matinée** : une ligne par flux, de la réception PFE au contrôle EBS ; l'étape en défaut est colorée.
- **🛠 Plan de reprise** (affiché seulement en cas de rupture) : les fichiers à rejouer **un par un, dans l'ordre**,
  en attendant la fin de chaque request RBAFBIMP avant la suivante.
- **Continuité des comptes** : dernier relevé chargé par compte, retard et trous.
- **Chaîne Control-M**, **Contrôles DKA_SRBCTRLRB** : détail pour l'analyse.
- **Comptes connus** : anomalies préexistantes, ignorées par le verdict. Les modifier ici puis **💾 Enregistrer**.

### 4. Diffuser

**📄 Rapport HTML** : écrit dans `dossier_rapports`.

## Virements

Contrôle de bout en bout d'une journée : Oracle → FIN01.VIREMENT → VIREMENT.EDF01 (ACK banque) → retour trésorerie
Quartz, avec recherche des doublons.

### 1. Déposer

Deux façons, au choix :

- **En vrac dans le dépôt** (`depot`), sans trier : instances Talend (dossiers `<uuid>`), exports Quartz (sous-dossier
  `EDF/` du dépôt Drive) et rejets bancaires (sous-dossier `REJET/`). Le bouton **📥 Importer** date chaque élément
  (par son nom, sinon par son contenu) et le range au bon endroit.
- **Directement** dans les dossiers ci-dessus :

| Dossier | Contenu |
|---|---|
| `dossier_oracle` | `JJMMAAAA\<uuid>` : une instance Talend par sous-dossier (SOURCE, TALEND, TARGET) |
| `dossier_edf` | `Liste des virements importés du jour<JJMMAAAA>.xls` (export Quartz, facultatif) |
| `dossier_rejets` | `JJMMAAAA_Liste des rejets bancaires du jour - Virement.xls` |

Sans le fichier Quartz, le contrôle tourne quand même : seul le niveau 3 (retour trésorerie) est ignoré.

### 2. Lancer

1. Choisir la **Journée** (les journées proposées sont celles présentes dans `dossier_oracle`).
2. **▶ Lancer le contrôle**. Le rapport est écrit dans `dossier_rapports\rapport_<JJMMAAAA>`.

### 3. Lire

- **Tuiles** : résultat global, virements et montant envoyés, doublons bloquants (🔴), points à vérifier (🟠),
  retour trésorerie repris ou non, rejets bancaires du jour.
- **Doublons** : D1 envoi transmis en double, D2 envois qui se recouvrent, D3 virement présent dans plusieurs envois,
  D4 virement répété dans un même envoi, D5 déjà transmis un jour précédent (`historique_jours` jours en arrière),
  D6 fichier d'origine rejoué. Un doublon est une **ligne entière identique**, jamais une simple ressemblance.
  La **liste pour la banque** s'exporte en CSV.
- **Contrôles de forme** : signature PGP, compte payeur, dates, pieds de fichier, code retour Talend, montants,
  IBAN, BIC.
- **Niveaux 0 à 3** : présence des fichiers, totaux par fichier d'origine et par envoi, virement par virement,
  écarts avec Quartz.
- **Rejets bancaires du jour** et **Synthèse complète** (`synthese.md`).

### 4. Diffuser

**📄 Générer le rapport HTML** (dans `dossier_rapports`), puis télécharger le rapport, le **mail prêt à envoyer
(.eml)**, ou **📤 Envoyer** si `[mail]` est renseigné. Le **texte court** se colle dans un mail ou Teams.
L'**historique** en bas de page reprend les 60 derniers jours.

## Prélèvements

Rapprochement des prélèvements émis par Oracle avec l'état de réception EDF CashCollection, par **clé métier**
(IBAN créancier × échéance), chaque écart étant expliqué par les rejets internes.

### 1. Déposer

| Dossier | Contenu |
|---|---|
| `dossier_oracle` | `<AAAAMMJJ>\` : fichiers `*PCX*` / `*PCL*` archivés depuis `DATA/Traite/OUT_SEPA` |
| `dossier_edf` | `IMPORT_AVP_DK.<date>.<heure>.csv`, pièces jointes du mail « Synthèse quotidienne des prélèvements Dalkia reçus par CashCollection » |
| `dossier_rejets` | `REJETS_INTERNES_DK.<date>.<heure>.csv` |

Garder l'historique : le rapprochement a besoin des émissions et des états EDF des jours précédents.

### 2. Lancer

1. **Date de référence** : aujourd'hui par défaut ; choisir une date déjà contrôlée pour revoir son rapport.
2. **Profondeur (j)** : nombre de jours d'échéances en arrière pris en compte (`jours` dans `config.ini`).
3. **▶ Lancer le rapprochement**. Le rapport (classeur Excel, CSV, justifications, résumé) est écrit dans
   `dossier_rapports`. Le **journal d'exécution** montre les fichiers lus et les avertissements.

Le même rapprochement se lance hors de l'application avec `rapprochement_cle_metier.bat` (dossier de l'outil),
sur les mêmes dossiers.

### 3. Lire

- **Tuiles** : résultat global, prélèvements et montant émis, nombre de clés, en attente EDF, anomalies, écarts à
  investiguer, émis en double.
- **Justification des écarts** : une ligne par cause (REJET, NON_CONFIRME, INEXPLIQUE, SANS_ORACLE…). Les causes
  INEXPLIQUE et SANS_ORACLE sont **à investiguer**.
- **Prélèvements émis en double** : ligne entière identique, caractère pour caractère.
- **Clés par statut** : voir le tableau des statuts ci-dessous.
- **Trésorerie EDF** (base, 90 jours) : chronologie des états reçus, jours ouvrés sans état, rejets internes,
  mandats rejetés plusieurs fois. Les fichiers connus en base mais disparus du disque sont signalés.

### 4. Diffuser

**📄 Générer le rapport HTML** (dans `dossier_rapports`), téléchargements du **rapprochement complet (CSV)** et du
**classeur Excel**, **mail .eml** ou **📤 Envoyer**, **texte court** pour un mail ou Teams.
