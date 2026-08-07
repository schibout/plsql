# Guide — Rapprochement des prélèvements par clé métier

`rapprochement_cle_metier.py` · `rapprochement_cle_metier.bat`

Ce document explique **ce que fait** le contrôle, **comment le lancer**, **comment lire** son
résultat, et **pourquoi** il est construit ainsi. Aucune connaissance du code n'est nécessaire.

---

## 1. À quoi sert ce contrôle ?

Dalkia émet des ordres de prélèvement depuis Oracle. EDF les prend en charge et renvoie chaque
matin un état de réception.

**L'objectif quotidien est de justifier chaque écart et de dire de quel fichier il provient.**
C'est ce que produit l'onglet *Justification des écarts* (§4) : une ligne par cause, avec le
bénéficiaire, le motif, et les trois fichiers concernés — celui qui a émis, celui qui a rejeté,
celui qui a confirmé.

```
  ORACLE                         EDF                          REJETS INTERNES
  ORACLE/<date>/*PCL*.txt        IMPORT_AVP_DK.<date>.csv     REJETS_INTERNES_DK.<date>.csv
  ordres émis, ligne à ligne     accusé de réception,         prélèvements refusés
                                 agrégé par créancier         (mandat absent, invalide…)
```

Trois sources, une seule question par ligne du rapport : *ce que nous avons envoyé a-t-il été
reçu, et sinon, pourquoi ?*

---

## 2. Comment lancer le contrôle ?

**Le plus simple (Windows) :** double-cliquer sur `rapprochement_cle_metier.bat`.

```bat
rapprochement_cle_metier.bat
rapprochement_cle_metier.bat --date 2026-08-06
rapprochement_cle_metier.bat --jours 15
rapprochement_cle_metier.bat --sortie "D:\rapports"
rapprochement_cle_metier.bat --no-pause          (tâche planifiée : pas d'attente clavier)
```

**En Python directement :**

```bat
python rapprochement_cle_metier.py --date 2026-08-06 --jours 10
```

| Option | Défaut | Rôle |
|---|---|---|
| `--date` | aujourd'hui | Date de référence, au format **AAAA-MM-JJ** |
| `--jours` | `10` | Profondeur du périmètre, en jours calendaires |
| `--racine` | dossier du script | Où se trouvent `ORACLE\` et `EDF\` |
| `--sortie` | la racine | Où écrire le rapport |
| `--nom-si` | `ORACLE` | SI à rapprocher (les fichiers EDF contiennent aussi `CIF`) |

Le `.bat` installe automatiquement `openpyxl` s'il manque.

### Codes retour

| Code | Signification | À faire |
|---|---|---|
| `0` | Tout est rapproché ou expliqué | Rien |
| `1` | **Anomalies détectées** | Ouvrir l'onglet *Rapprochement*, filtrer sur la colonne *Statut* |
| `2` | Erreur de traitement | Le rapport n'est pas fiable, lire le message d'erreur |
| `3` | Exécution dégradée | Résultat **partiel** : lire les avertissements avant de conclure |

Le code `3` existe pour une raison précise : une exécution qui a ignoré 500 lignes illisibles ne
doit **jamais** ressembler à une exécution propre.

---

## 3. La clé de rapprochement, et pourquoi celle-là

C'est le choix structurant de l'outil.

Oracle et EDF portent tous deux, sans qu'on l'ait exploité jusqu'ici, **le même couple de
données** :

| | Oracle | EDF |
|---|---|---|
| Créancier | `ENTITYBANKACCOUNTNUMBER` | `IBAN CREANCIER` |
| Échéance | `TRANSACTIONDATE` | `DATE D'ECHEANCE` |

Le rapprochement se fait donc sur **(IBAN créancier × date d'échéance)**. Mesuré sur les données
réelles : **261 clés communes, dont 256 concordent au centime et à la ligne près**, et les 5
écarts restants sont **intégralement expliqués par les rejets**.

### Pourquoi pas l'ancienne méthode

L'outil précédent comparait des **totaux journaliers**, en devinant la date EDF à partir de la
date Oracle via une règle écrite en dur :

```
jeudi   → +4 jours        samedi → +2 jours
vendredi → +4 jours       sinon  → +2 jours
```

Trois problèmes, tous mesurés :

1. **La règle est fausse.** Sur 264 lots, le vendredi part à **+5 jours dans 88 % des cas**.
2. **Elle ignore les jours fériés.** EDF n'a produit aucun fichier les 13, 14 et 16/07.
3. **Elle ne dit jamais *quoi*.** Un total journalier qui ne tombe pas juste indique qu'il manque
   quelque chose, jamais quoi ni pourquoi.

Avec la clé métier, la question du délai **disparaît** : peu importe quand EDF confirme, la clé
reste la même. Le délai devient une donnée observée, plus une hypothèse.

### Pourquoi la fenêtre porte sur l'échéance, pas sur les fichiers

`--jours 10` ne veut **pas** dire « ne lire que les fichiers des 10 derniers jours ». Une même
clé peut être alimentée par des lots Oracle séparés de **17 jours** :

```
FR7630003038590002515034791, échéance 10/08
  émis le 24/07 (102 lignes)  +  émis le 05/08 (1 ligne)   =  103
```

Une fenêtre sur les fichiers n'en capterait qu'une tranche et fabriquerait un écart de 102 lignes
sur une clé parfaitement saine.

Donc : `--jours 10` sélectionne les **échéances** à faire figurer au rapport, puis l'outil lit
**tous** les fichiers disponibles pour en calculer les totaux complets. Lire large ne peut pas
fausser un total, seulement le compléter — et le volume est négligeable (~1 900 lignes Oracle).

---

## 4. Le résultat attendu, sur un exemple

Exécution du **06/08/2026** sur 10 jours :

```
Oracle : 309 fichier(s), 1927 ligne(s)
EDF : 56 fichier(s), 509 ligne(s) 'ORACLE', dont 21 fichier(s) sans ligne 'ORACLE'.
Rejets : 11 fichier(s), 18 ligne(s), 1 doublon(s) ecarte(s).

=======================================================
   146  RAPPROCHE
     4  EXPLIQUE_PAR_REJET
     3  REJETE_INTEGRALEMENT
     1  EN_ATTENTE
     1  HORS_PERIMETRE_HISTORIQUE
-------------------------------------------------------
 Aucune anomalie : tout est rapproché ou expliqué.
=======================================================
```

**155 clés, aucune anomalie, code retour 0.** À comparer à l'ancien outil qui, sur les mêmes
données, affichait **7 dates « en écart » sans aucune explication**.

Trois fichiers sont produits, tous dans le **sous-dossier `rapport\`** — jamais au milieu des
fichiers sources. Le dossier est créé automatiquement, et `--sortie` désigne son **parent**.

| Fichier | Usage |
|---|---|
| `rapport\Rapprochement_Cle_Metier_<date>_<heure>.xlsx` | Lecture — commencer par l'onglet *Justification des écarts* |
| `rapport\..._justifications.csv` | **Les écarts justifiés**, un par ligne, exploitable en machine |
| `rapport\....csv` | Le rapprochement complet, toutes clés |

---

## 4bis. L'onglet *Justification des écarts* — le plan de travail quotidien

C'est le **premier onglet**, celui à ouvrir chaque matin. Une ligne **par cause**, pas par clé :
un écart de 3 prélèvements dû à 3 rejets produit 3 lignes, chacune nommant son bénéficiaire et
son fichier d'origine.

### Un exemple réel, tel qu'il sort

```
Échéance    31/07/2026    IBAN créancier  FR7630003011120002001135658
Cause       REJET         1 prélèvement   3 333,95 €
Bénéficiaire  BILTOKI ROUEN
RUM           NVOA0142306920230706001Biltoki
Motif         CC01 — MANDAT INVALIDE
Émis le       11/07/2026

  Fichier ORACLE d'origine : DK_30003-0001DSWPCLFRST-20260711-48460413_20260711-022706.txt
  Fichier REJET            : REJETS_INTERNES_DK.20260715.070020.csv
  Fichier EDF              : IMPORT_AVP_DK.20260715.070101.csv
```

Tout est là pour justifier l'écart sans rouvrir un seul fichier : le montant, le bénéficiaire, le
motif bancaire, et les trois fichiers de la chaîne.

### Les causes

| Cause | Signification | Action |
|---|---|---|
| `REJET` | Le prélèvement a été rejeté ; EDF remonte net | **Aucune** — l'écart est justifié |
| `NON_CONFIRME` | Émis, EDF ne l'a pas encore remonté | Surveiller la prochaine exécution |
| `INEXPLIQUE` | L'écart n'est couvert par aucun rejet | **À investiguer** — surligné |
| `SANS_ORACLE` | EDF remonte sans contrepartie Oracle | **À investiguer** — surligné |

L'onglet est livré avec un filtre automatique et les en-têtes figés : filtrer sur
`Cause = INEXPLIQUE` donne directement la liste de ce qui demande un travail réel.

### Une garantie de cohérence

**La somme des justifications est toujours égale à l'écart total.** Rien ne peut rester hors du
compte : si les rejets n'expliquent qu'une partie d'un écart, le reliquat apparaît explicitement
en ligne `INEXPLIQUE` avec son montant.

Sur l'exécution du 06/08 : **8 écarts, 30 641,36 € — justifiés à 100 %**, dont 7 par un rejet et
1 en attente de remontée. Aucun à investiguer.

---

## 5. Lire l'onglet *Rapprochement*

Une ligne par clé. Les colonnes qui comptent :

| Colonne | Contenu |
|---|---|
| `Écart Nb` / `Écart Montant` | EDF **moins** Oracle. Négatif = il manque quelque chose côté EDF |
| `Nb Rejets` / `Codes Rejet` | Rejets rattachés à cette clé |
| `Statut` | Le verdict (section 6) |
| `Émissions Oracle` | Les dates d'émission qui alimentent la clé |
| `Tranches EDF` | Le détail des remontées EDF : `27/07:102 + 06/08:1` |

Les deux dernières colonnes sont ce qui rend un écart **diagnosticable**. Sans elles, on sait
qu'il manque une ligne ; avec elles, on sait quel lot et quelle remontée regarder.

---

## 6. Les statuts, avec un cas réel pour chacun

Ils sont évalués **dans cet ordre** : le premier qui s'applique gagne.

### `RAPPROCHE` — tout concorde

```
FR7630003022800002572079247  échéance 29/06
  Oracle 1 / 5 615,50 €     EDF 1 / 5 615,50 €     écart 0
  émis le 24/06, remonté par le fichier EDF du 25/06
```

Nombre **et** montant identiques. Le contrôle porte toujours sur les deux : une clé au bon compte
et au mauvais montant n'est pas conforme.

### `EXPLIQUE_PAR_REJET` — l'écart correspond exactement aux rejets

```
FR7630003012070002018665043  échéance 10/07
  Oracle 21 / 24 703,22 €    EDF 20 / 23 770,97 €    écart -1 / -932,25 €
  rejets  1 /    932,25 € (CC01 mandat invalide)
```

Une ligne manque côté EDF, et il existe exactement un rejet de ce montant. **Ce n'est pas une
anomalie** : EDF remonte net des rejets. C'est le comportement normal du flux.

### `REJETE_INTEGRALEMENT` — EDF ne remonte rien, et c'est normal

```
FR7630003031750002028255110  échéance 07/07
  Oracle 1 / 7 600,75 €      EDF 0                  écart -1
  rejets  1 / 7 600,75 € (CC01)
```

Le seul prélèvement de la clé a été rejeté : le net est nul, donc **EDF n'émet aucune ligne**.
Sans ce statut, ces clés seraient signalées comme « non reçues » alors que tout est normal —
c'était le cas de **4 des 5 clés** initialement suspectes.

### `RAPPROCHE_AVEC_REJET_POSTERIEUR` — conforme, mais à surveiller

```
FR7630003022800002572079247  échéance 10/07
  Oracle 66 / 322 944,13 €   EDF 66 / 322 944,13 €   écart 0
  rejets  1 /     636,50 € (CC02 mandat absent)
  remonté par le fichier EDF du 24/06 — le rejet est daté du 26/06
```

Les totaux tombent juste, parce que le rejet est arrivé **après** la remontée EDF. Arithmétiquement
conforme, mais **un prélèvement va échouer**. Sans ce statut, le cas passerait totalement inaperçu.

### `EN_ATTENTE` — émis, pas encore confirmé, dans les délais

```
FR7630004008190001190336461  échéance 10/08
  Oracle 1 / 8 000,00 €      EDF 0
  émis le 06/08, aucun rejet
```

Pas encore d'anomalie : le délai normal n'est pas écoulé.

### `NON_RECU` — émis, non confirmé, hors délai · **anomalie**

Même situation, mais le délai est dépassé. **À traiter.**

> **Comment le délai est mesuré — et pourquoi ainsi**
>
> Pas en jours, mais en **nombre de fichiers EDF parus depuis l'émission**. Sur 264 lots, la
> confirmation arrive toujours dans le **1er ou le 2e** fichier, jamais le 3e.
>
> Le comptage en jours casserait sur les jours fériés (EDF n'a rien produit les 13, 14 et 16/07).
> Le comptage en fichiers s'y adapte tout seul, sans calendrier des fériés à maintenir.

### `REJET_PARTIEL_NON_CONFIRME` — à signaler

Des rejets existent mais EDF n'a encore rien remonté pour la clé. Situation transitoire à
surveiller.

### `ECART_PARTIEL` — écart inexpliqué · **anomalie**

L'écart ne correspond pas aux rejets. **C'est le vrai signal d'alerte** : quelque chose s'est
perdu entre Oracle et EDF.

### `EDF_SANS_ORACLE` — EDF remonte sans contrepartie · **anomalie**

EDF a pris en charge des prélèvements que nous n'avons pas trace d'avoir émis.

### `HORS_PERIMETRE_HISTORIQUE` — non concluant

```
FR7630003011120002001135658  échéance 07/05
  Oracle 0                   EDF 1 / 4 530,09 €
  remonté par le fichier EDF du 11/05
```

EDF remonte une échéance dont l'émission Oracle est **antérieure à l'archive disponible**. On ne
peut ni la retrouver, ni l'incriminer.

Sans ce garde-fou, l'outil signalerait **46 fausses anomalies** au seul motif que l'historique EDF
remonte plus loin que l'historique Oracle.

---

## 7. Deux subtilités qui expliquent des choix du code

### Les remontées EDF d'une même clé s'additionnent

Une clé peut apparaître dans plusieurs fichiers EDF. Ce sont des **remontées incrémentales**, pas
des photos successives :

```
FR7630003038590002515034791  échéance 10/08
  EDF : fichier du 27/07 → 102     fichier du 06/08 → 1     total 103
  Oracle : 24/07 → 102             05/08 → 1                total 103   ✓
```

Prendre « la dernière valeur » donnerait 1 au lieu de 103. **Elles se somment.**

### Les rejets sont rattachés par le RUM, pas par l'IBAN

Deux raisons, toutes deux vérifiées :

1. **Les fichiers de rejets ne portent pas le nom du SI**, et **3 IBAN créanciers sont partagés
   entre CIF et ORACLE**. Attribuer un rejet par IBAN seul est ambigu sur ces clés.
2. **Un rejet peut être republié à l'identique** dans un fichier ultérieur — vérifié : le rejet
   `NVCI0003392620230414001 / 150,00 €` figure à la fois le 20/07 et le 24/07. Le compter deux
   fois fausserait l'écart.

L'outil rattache donc chaque rejet à une ligne Oracle sur **(IBAN créancier, RUM, échéance)**, et
dédoublonne au préalable. L'onglet *Rejets* affiche le résultat de ce tri :

| RUM | Apparié Oracle |
|---|---|
| `NVOA0147072120260113001` | OUI |
| `NVCI0003409720260603001` | NON (autre SI) |

L'échéance fait partie de la signature de dédoublonnage : deux rejets de même RUM sur des
**échéances différentes** sont légitimes et doivent tous deux être comptés.

---

## 8. Que faire selon le résultat

**Le réflexe quotidien :** ouvrir l'onglet *Justification des écarts*, filtrer sur
`Cause = INEXPLIQUE` ou `SANS_ORACLE`. S'il n'y a rien, tous les écarts du jour sont justifiés et
le rapport peut être transmis tel quel.

| Statut remonté | Action |
|---|---|
| `ECART_PARTIEL` | Comparer `Émissions Oracle` et `Tranches EDF` : identifier le lot en défaut |
| `NON_RECU` | Vérifier d'abord qu'EDF a bien produit ses fichiers ; sinon, escalader |
| `EDF_SANS_ORACLE` | Vérifier que l'archive Oracle est complète sur la période |
| `RAPPROCHE_AVEC_REJET_POSTERIEUR` | Prévenir le métier : un prélèvement échouera |
| `REJET_PARTIEL_NON_CONFIRME` | Surveiller la prochaine exécution |
| Code retour `3` | Lire les avertissements **avant** de conclure quoi que ce soit |

---

## 9. Fichiers de l'outil

| Fichier | Rôle |
|---|---|
| `rapprochement_cle_metier.py` | Le contrôle |
| `rapprochement_cle_metier.bat` | Lanceur Windows |
| `requirements.txt` | Dépendance `openpyxl` |
| `tests\test_rapprochement_cle_metier.py` | 26 tests (`python -m pytest tests\`) |

L'outil précédent (`prelevements_rapprochement.py`) reste disponible et inchangé — voir
[GUIDE_prelevements_rapprochement.md](GUIDE_prelevements_rapprochement.md).
