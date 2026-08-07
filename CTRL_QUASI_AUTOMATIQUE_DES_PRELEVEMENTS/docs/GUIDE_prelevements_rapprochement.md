# Guide — Rapprochement journalier des prélèvements

`prelevements_rapprochement.bat` · `prelevements_rapprochement.py`

Ce document explique **ce que fait** ce contrôle, **comment le lancer**, **comment lire** le
classeur produit, **pourquoi** il est construit ainsi, et **quelles sont ses limites**. Aucune
connaissance du code n'est nécessaire.

> Cet outil produit une **photographie journalière** : combien Oracle a émis chaque jour, combien
> EDF a reçu. Pour savoir *pourquoi* un écart existe, voir
> [GUIDE_rapprochement_cle_metier.md](GUIDE_rapprochement_cle_metier.md).

---

## 1. À quoi sert ce contrôle ?

Dalkia émet des ordres de prélèvement depuis Oracle ; EDF renvoie chaque matin un état de
réception. Le contrôle rapproche les **volumes journaliers** des deux côtés et signale les
journées qui ne tombent pas juste.

```
  ORACLE/<date>/*PCX*|*PCL*.txt   ──►   EDF/IMPORT_AVP_DK.<date>.<heure>.csv
  ordres émis un jour donné              état de réception d'un jour donné

  EDF/REJETS/REJETS_INTERNES_DK.<date>.<heure>.csv
  prélèvements refusés (recopiés bruts, à titre d'information)
```

---

## 2. Comment lancer le contrôle ?

**Le plus simple (Windows) :** double-cliquer sur `prelevements_rapprochement.bat`. La fenêtre
reste ouverte à la fin pour laisser lire le résultat.

```bat
prelevements_rapprochement.bat
prelevements_rapprochement.bat --sortie "D:\mes rapports"
prelevements_rapprochement.bat --nom-si CIF
prelevements_rapprochement.bat --no-pause          (tâche planifiée : pas d'attente clavier)
prelevements_rapprochement.bat --help
```

Tous les arguments sauf `--no-pause` sont transmis au script Python. `--no-pause` est consommé par
le `.bat` lui-même.

**En Python directement :**

```bat
python prelevements_rapprochement.py --sortie D:\rapports
```

| Option | Défaut | Rôle |
|---|---|---|
| `--racine` | dossier du script | Où se trouvent `ORACLE\` et `EDF\` |
| `--sortie` | la racine | Où écrire le classeur |
| `--nom-si` | `ORACLE` | SI à rapprocher (les fichiers EDF contiennent aussi `CIF`) |
| `--recherche-jn N` | `0` (désactivé) | **Chercher** la date EDF parmi J+1..J+N au lieu d'appliquer la règle fixe — voir §5 |
| `--motifs-oracle` | `*PCX* *PCL*` | Fichiers Oracle à retenir |
| `--dossier-oracle` / `--dossier-edf` | `ORACLE` / `EDF` | Noms des sous-dossiers |

### Ce que fait le `.bat` avant de lancer Python

1. Se place dans son propre répertoire — un double-clic depuis n'importe où fonctionne.
2. Choisit l'interpréteur : `py` s'il existe, sinon `python`. Message clair si aucun n'est présent.
3. Vérifie `openpyxl` et l'installe depuis `requirements.txt` s'il manque.
4. Lance le contrôle, puis traduit le code retour en phrase lisible.
5. Attend un appui touche, sauf si `--no-pause`.

Chaque argument est ré-encadré de guillemets avant d'être transmis : un chemin contenant des
espaces passe intact.

### Codes retour

| Code | Signification |
|---|---|
| `0` | Aucun écart |
| `1` | Écarts détectés |
| `2` | Erreur de traitement (dossier absent, Python ou openpyxl indisponible…) |

Exploitable en supervision : `if %errorlevel%==1 ...`.

---

## 3. Le résultat attendu, sur un exemple

```
Analyse du dossier en cours : CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS
Oracle : 309 fichier(s), 1927 ligne(s), 18 date(s).
EDF : 56 fichier(s), 509 ligne(s) 'ORACLE', 35 date(s).
Rejets : 11 fichier(s), 41 ligne(s).
Génération du classeur Excel...

=======================================================
 Rapprochement complété avec succès !
 Fichier : ...\Rapprochement_Oracle_EDF_20260807_223518.xlsx
 Oracle : 1927 ligne(s) / EDF : 509 ligne(s) / Rejets : 41 ligne(s)
 7 date(s) en écart sur 18 rapprochée(s).
=======================================================
```

Les compteurs affichés avant le classeur sont un contrôle en soi : si le nombre de fichiers ou de
lignes s'écarte de l'ordinaire, le rapport est suspect avant même d'être ouvert.

Le classeur s'appelle `Rapprochement_Oracle_EDF_<AAAAMMJJ>_<HHMMSS>.xlsx` — horodaté, donc jamais
écrasé — et il est écrit dans le **sous-dossier `rapport\`**, jamais au milieu des fichiers
sources analysés. Le dossier est créé automatiquement.

```
CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS\
├── ORACLE\        <- sources analysées
├── EDF\           <- sources analysées
└── rapport\       <- tout ce qui est produit
    └── Rapprochement_Oracle_EDF_20260807_235122.xlsx
```

`--sortie` désigne le dossier **parent** : le sous-dossier `rapport\` y est toujours ajouté.

---

## 4. Les trois onglets

### Onglet 1 — *Synthèse Journalière Brute*

Les deux sources côte à côte, sans interprétation : à gauche ce qu'Oracle a émis par date de
génération, à droite ce qu'EDF a reçu par date de fichier. Aucun rapprochement, aucune hypothèse —
c'est la matière première.

### Onglet 2 — *État Comparatif & Écarts*

Le cœur du rapport. Une ligne par date Oracle, rapprochée de la date EDF attendue.

```
Date(s) Gén. Oracle | Date Reç. EDF | Nb Ora | Nb EDF | Écart | Total Ora   | Total EDF   | Écart Mt  | Statut
22/06/2026          | 24/06/2026    | 485    | 484    | -1    | 2 923 846,19| 2 922 913,94| -932,25   | Écart (J+2)
23/06/2026          | 25/06/2026    | 1      | 1      | 0     | 5 615,50    | 5 615,50    | 0,00      | OK (J+2)
25/06/2026          | 29/06/2026    | 1      | 1      | 0     | 34 485,28   | 34 485,28   | 0,00      | OK (J+4)
06/07/2026          | 08/07/2026    | 2      | 1      | -1    | 15 600,75   | 8 000,00    | -7 600,75 | Écart (J+2)
```

**Lecture :** l'écart est toujours **EDF moins Oracle**. Un écart négatif signifie qu'il manque
quelque chose côté EDF. Les lignes en écart sont surlignées ; le `J+n` du statut est le délai
**réellement constaté**, pas une cible.

Sur la première ligne : 485 prélèvements émis le 22/06, 484 reçus le 24/06, **−932,25 €**.
Ce montant correspond exactement à un rejet (`CC01 mandat invalide`) présent dans l'onglet 3 —
mais **c'est à vous de faire le rapprochement**, l'outil ne le fait pas.

#### Les trois dernières colonnes : d'où viennent les données

| Colonne | Contenu |
|---|---|
| `Fichier(s) ORACLE` | Le ou les fichiers émetteurs |
| `Fichier EDF` | Le fichier de réception, ou `(aucun)` |
| `Fichier(s) REJET` | Le fichier de rejets qui explique l'écart — **renseigné uniquement sur les lignes en écart** |

EDF ne produit **qu'un seul fichier par date** : son nom est donc toujours exact et directement
exploitable.

Oracle, lui, peut compter **jusqu'à 78 fichiers pour une seule date**. La colonne s'adapte :

```
1 à 3 fichiers  ->  les noms complets
    DK_30003-0001DMSPCXFRST-20260624-48288632_20260624-002346.txt

plus de 3       ->  le dossier et le nombre
    ORACLE\20260622 (71 fichiers)
```

Le seuil évite qu'une cellule devienne illisible : au-delà de trois noms, le dossier suffit à
retrouver les fichiers, et le détail ligne par ligne relève de l'autre outil.

#### La colonne `Fichier(s) REJET`

Elle ne se remplit que sur les **lignes en écart**, pour ne pas encombrer les journées conformes.

```
REJETS_INTERNES_DK.20260624.070002.csv — 1 rejet(s), 932.25 € (CC01) : explique l'écart
```

**Comment le fichier est choisi.** Les fichiers de rejets **ne portent pas le nom du SI** : se
contenter de prendre ceux parus entre l'émission et la réception ramène aussi des rejets étrangers
à la ligne. Constaté sur vos données : pour l'écart du 23/07, deux fichiers tombent dans la
fenêtre, mais l'un ne contient que des rejets d'un autre SI.

L'outil ne désigne donc un fichier que lorsque **son total égale exactement l'écart**. Trois
formulations possibles :

| Ce qui s'affiche | Signification |
|---|---|
| `… : explique l'écart` | Le montant correspond au centime — écart justifié |
| `… : à vérifier` | Des rejets existent dans la période mais aucun ne correspond — **à ouvrir** |
| `(aucun)` | Aucun rejet sur la période : l'écart a une autre cause |

Sur vos données, les **6 écarts sont tous justifiés** par un fichier de rejets identifié nommément.

Les trois colonnes sont en **format texte** : les noms ne sont jamais réinterprétés par Excel.

### Onglet 3 — *Fichiers de Rejets Bruts*

Les rejets internes présentés **en tableau exploitable**, et non plus en texte brut.

Les fichiers de rejets ont une structure constante, vérifiée sur l'ensemble du gisement :

```
ligne 1  LISTE DES REJETS INTERNES AU:24/06/2026 a 07:00     -> devient une COLONNE
ligne 2  IBAN CREANCIER;RUM;IBAN DEBITEUR;DATE D'ECHEANCE;…  -> devient les EN-TÊTES
ligne 3+ FR7630003012070002018665043;NVOA0147…;…             -> deviennent les LIGNES
```

L'onglet reprend cette structure :

| Nom du Fichier Source | LISTE DES REJETS INTERNES AU | IBAN CREANCIER | RUM | … | MONTANT | CODE REJET | MOTIF DU REJET |
|---|---|---|---|---|---|---|---|
| REJETS_INTERNES_DK.20260624… | 24/06/2026 a 07:00 | FR7630003012070… | NVOA0147072… | … | 932,25 | CC01 | MANDAT INVALIDE |

Trois points utiles :

- **Les en-têtes sont lus dans le fichier**, jamais codés en dur. Un changement de format côté EDF
  déclenche un avertissement au lieu de décaler silencieusement les colonnes.
- **`MONTANT` est un nombre** : la colonne est sommable et filtrable directement dans Excel. Tout
  le reste (IBAN, RUM, dates) reste en texte strict, donc jamais réinterprété.
- **Filtre automatique et en-têtes figés** : on isole un code rejet ou un créancier en deux clics.

Sur vos données, l'onglet passe de 41 lignes de texte brut à **19 lignes de données réelles**.

---

## 5. Pourquoi ces choix

### Pourquoi une projection de date J+2 / J+4

Oracle émet un jour, EDF confirme quelques jours plus tard. Pour comparer deux journées, il faut
bien décider **laquelle répond à laquelle**. La règle par défaut est calendaire :

```
jeudi    → +4 jours          samedi → +2 jours
vendredi → +4 jours          sinon  → +2 jours
```

C'est une approximation de « J+2 ouvré », choisie pour sa simplicité : aucun calendrier à
maintenir, comportement prévisible. Elle a toutefois un défaut de fond, traité ci-dessous.

### `--recherche-jn` : chercher le décalage au lieu de le supposer

Le décalage réel **n'est pas constant** : il dépend du jour de la semaine, du rythme de production
d'EDF et des jours fériés. Plutôt que de le postuler, l'option `--recherche-jn N` essaie J+1 à J+N
et retient le meilleur candidat.

```bat
prelevements_rapprochement.bat --recherche-jn 8
```

L'option est **désactivée par défaut** : sans elle, le comportement est strictement inchangé.

#### Ce que cela change, sur un cas réel

| Date Oracle | Règle fixe J+2/J+4 | Recherche J+1..J+8 |
|---|---|---|
| 10/07/2026 | → 14/07, **EDF 0**, `Écart (J+4)` | → 15/07, **EDF 376**, `Écart (J+5)` |
| 05/08/2026 | → 07/08, EDF 0, `Écart (J+2)` | → 07/08, EDF 0, **`Non trouvé`** |

La première ligne est un **faux positif à 4,6 M€**. Le 10/07 est un vendredi : la règle fixe vise
le **14/07, jour férié où EDF n'a produit aucun fichier**, et conclut que 377 prélèvements ont
disparu. La recherche trouve le 15/07 avec 376 prélèvements reçus — l'écart réel est **un seul
rejet de 3 333,95 €**.

La seconde ligne remplace un « écart » trompeur par un constat honnête : les prélèvements sont
émis, EDF ne les a simplement pas encore remontés.

Sur l'ensemble des données, la recherche trouve des décalages de **J+2, J+4 et J+5** — ce dernier
étant hors de portée de la règle fixe. Les 6 écarts restants correspondent tous, au centime près,
à des rejets connus.

#### Comment le bon candidat est choisi

Deux règles, l'une et l'autre nécessaires :

1. **Contrainte de signe.** EDF remonte **net des rejets**, donc une journée EDF crédible ne peut
   jamais afficher **plus** qu'Oracle n'a émis, ni en nombre ni en montant.

   Sans cette contrainte : le 25/07, Oracle émet 2 prélèvements pour 3 821,10 €. Cinq jours plus
   tard, EDF affiche **exactement 2 prélèvements**… pour 16 461,74 €. Une recherche sur le seul
   nombre retiendrait cette journée et afficherait `OK`.

2. **Départage par l'écart le plus faible**, et non par la date la plus proche.

   Sans cela : le 22/06, Oracle émet 485 prélèvements. Le lendemain, EDF en affiche 6 — moins
   qu'Oracle, donc la contrainte de signe est satisfaite. Ce candidat proche mais absurde serait
   retenu à la place du 24/06 et de ses 484 prélèvements.

Quand deux journées EDF concordent **parfaitement**, l'outil retient la plus proche mais écrit
`ambigu` dans la colonne Statut : le choix n'est pas certain et doit être vérifié.

#### Ce que cette option ne résout pas

Elle corrige le **choix de la date**, pas la nature de la comparaison. Le rapprochement reste basé
sur des totaux journaliers : un écart n'est toujours pas expliqué, et deux erreurs opposées de même
montant se compensent toujours. Pour cela, voir
[le rapprochement par clé métier](GUIDE_rapprochement_cle_metier.md).

### Pourquoi les dates sont stockées en texte

Les colonnes de dates sont au format texte `jj/mm/aaaa`. Sans cela, Excel réinterprète les dates
selon la locale du poste et peut inverser jour et mois. Même raison pour l'onglet 3 : les IBAN et
les nombres à zéros de tête resteraient lisibles mais seraient convertis en nombres.

### Pourquoi l'écriture Excel se fait par blocs

Le classeur est rempli par plages entières plutôt que cellule par cellule. Sur quelques milliers
de lignes de rejets, l'écart de temps se compte en minutes.

### Pourquoi openpyxl plutôt que le pilotage d'Excel

La version PowerShell historique (`Prelevements_Rapprochement_Oracle_EDF.ps1`) pilote Microsoft
Excel. Cela impose Office sur le poste et laisse des processus `EXCEL.EXE` invisibles en cas
d'échec. La version Python génère le `.xlsx` directement : aucune dépendance à Office, exécution
possible sur un serveur, pas de processus résiduel.

---

## 6. Limites connues

Elles sont réelles et mesurées. Il faut les avoir en tête pour interpréter le rapport.

**La règle de projection par défaut est fausse le vendredi.** Sur 264 lots, le vendredi part à
**+5 jours dans 88 % des cas**, pas +4. Elle ignore aussi les jours fériés : EDF n'a produit aucun
fichier les 13, 14 et 16/07. → **Corrigé par `--recherche-jn`** (§5).

**Un écart est rattaché à un fichier de rejets, pas à un prélèvement.** La colonne
`Fichier(s) REJET` nomme le fichier qui explique l'écart, mais pas *quel* prélèvement a été rejeté
ni pour quel bénéficiaire. Ce niveau de détail relève de l'autre outil.

**La comparaison porte sur des totaux journaliers.** Une journée où un prélèvement manquerait et
un autre serait en trop du même montant tomberait juste.

**Le statut ne teste que le nombre.** Une journée au bon compte mais au mauvais montant est
affichée `OK`.

**Les rejets ne sont pas rattachés au prélèvement.** L'onglet 3 les présente en tableau et la
colonne `Fichier(s) REJET` désigne le fichier explicatif, mais le lien entre un rejet précis et la
ligne Oracle qui l'a émis n'est pas établi ici.

Ces limites sont précisément ce que corrige
[le rapprochement par clé métier](GUIDE_rapprochement_cle_metier.md), qui rapproche sur
`(IBAN créancier × échéance)` et rattache chaque rejet à sa ligne d'origine. Sur les mêmes
données : **0 anomalie réelle** contre 7 dates en écart inexpliquées ici.

**Les deux outils sont complémentaires** : celui-ci donne la vue journalière de volumétrie,
l'autre donne le diagnostic.

---

## 7. Que faire en cas d'écart

1. Lire la colonne `Fichier(s) REJET` de la ligne en écart :
   - `explique l'écart` → rien à faire, la justification est le fichier nommé ;
   - `à vérifier` ou `(aucun)` → passer à l'étape suivante.
2. Ouvrir le fichier nommé, ou l'onglet 3 qui en recopie le contenu.
3. Si l'écart reste inexpliqué, lancer `rapprochement_cle_metier.bat` — il descend jusqu'au
   prélèvement, au bénéficiaire et au fichier Oracle exact.
4. Si les compteurs de fichiers en tête d'exécution sont anormalement bas, vérifier d'abord la
   collecte avant toute analyse.

---

## 8. Fichiers de l'outil

| Fichier | Rôle |
|---|---|
| `prelevements_rapprochement.py` | Le contrôle |
| `prelevements_rapprochement.bat` | Lanceur Windows |
| `requirements.txt` | Dépendance `openpyxl` |
| `tests\test_prelevements_rapprochement.py` | 10 tests de la recherche J+n (`python -m pytest tests\`) |
| `Prelevements_Rapprochement_Oracle_EDF.ps1` | Version PowerShell historique, résultat identique, nécessite Excel installé |
