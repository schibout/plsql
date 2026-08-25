# Spécification : contrôle des écritures GL

**Author:** Codex  
**Date:** 25/08/2026  
**Status:** Approved
**Reviewers:** utilisateur du projet  
**Exemple de référence :** `04072026_GL_GER/`

## Contexte

Le projet possède des contrôles Windows pour les flux FAC02 clients et fournisseurs, mais aucun contrôle équivalent pour les écritures GL. L'instance de référence contient un SRC de 124 lignes, un CTL de deux lignes, un pivot TARGET et un témoin Talend.

L'analyse de cette instance démontre la règle de rapprochement suivante : le CTL agrège le SRC par origine (colonne 12 du SRC). Pour chaque origine, il contient le nombre de numéros de pièce distincts (colonne 1), la somme des débits (colonne 9) et la somme des crédits (colonne 10). L'exemple donne 36 pièces et 11 971,96 EUR au débit/crédit pour GER, puis 5 pièces et 13 216,66 EUR au débit/crédit pour FGE.

La correspondance Oracle est reprise du contrôle multi-flux `ControleFolioRose` : l'origine GL est stockée dans `attribute9` et le nom du fichier transmis dans `attribute10`. Le contrôle compare les écritures définitives (`APPS.GL_JE_HEADERS` / `APPS.GL_JE_LINES`) avec l'open interface (`APPS.GL_INTERFACE`).

## Functional Requirements

- FR-1: Le contrôle **MUST** accepter un dossier, un fichier SRC ou aucun argument.
- FR-2: Pour un dossier, le contrôle **MUST** rechercher récursivement le fichier `*_SRC_ECRITURESGL*.csv` le plus récent dont le répertoire parent est nommé `SOURCE`, afin que le dossier d'exemple complet soit accepté sans sélectionner un fichier de `TARGET`.
- FR-3: Sans argument, le contrôle **MUST** chercher un dossier `SOURCE` aux emplacements connus à côté du lanceur.
- FR-4: Le contrôle **MUST** accepter un fichier CTL explicite en second argument ou déduire son nom en remplaçant `_SRC_` par `_CTL_`.
- FR-5: Le lecteur SRC **MUST** interpréter le séparateur `;`, l'encodage Windows-1252/Latin-1 et les montants décimaux à virgule.
- FR-6: Le contrôle **MUST** agréger les lignes SRC par origine de flux (colonne 12, index 11).
- FR-7: Pour chaque origine, le contrôle **MUST** calculer le nombre de numéros de pièce distincts (colonne 1, index 0), le débit en centimes (colonne 9, index 8) et le crédit en centimes (colonne 10, index 9).
- FR-8: Le contrôle **MUST** lire dans le CTL l'origine (colonne 1), le nombre de pièces (colonne 3), le débit (colonne 4), le crédit (colonne 5) et le nom du SRC (colonne 6).
- FR-9: Le contrôle **MUST** comparer les origines présentes des deux côtés, les nombres de pièces, les débits et les crédits avec une tolérance maximale de 0,005 EUR.
- FR-10: Le contrôle **MUST** signaler toute écriture ou origine déséquilibrée lorsque le total débit diffère du total crédit.
- FR-11: Le contrôle **MUST** afficher une synthèse par origine et une synthèse globale.
- FR-12: Le contrôle local **SHOULD** générer un rapport Excel dans `rapport/` lorsque `openpyxl` est disponible ; l'absence d'`openpyxl` **MUST NOT** empêcher le contrôle texte.
- FR-13: Le lanceur `controleGL.bat` **MUST** retourner `0` si le contrôle est conforme, `1` pour une erreur technique et `2` pour une anomalie métier.
- FR-14: Le contrôle **MUST NOT** modifier un fichier SRC, CTL ou TARGET.
- FR-15: Le lanceur **MUST** exécuter ensuite `Verifier_Oracle_Ecritures_GL.ps1` sur le même fichier SRC.
- FR-16: La requête Oracle **MUST** filtrer `GL_JE_LINES` et `GL_INTERFACE` par `attribute9 = origine` et `attribute10 LIKE nom_fichier%`, conformément à `ControleFolioRose`.
- FR-17: La vérification Oracle **MUST** comparer, par origine, le nombre et les montants débit/crédit du SRC avec les tables définitives et les montants de l'interface.
- FR-18: Le rapport Oracle **MUST** produire un classeur coloré dans `Logs/`, avec une synthèse et le détail des pièces SRC ; bleu foncé pour les en-têtes, vert pâle pour `INTEGREE` et pêche pour les autres statuts, sur le modèle de `CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS`.
- FR-19: Si Excel n'est pas installé, la vérification Oracle **MUST** produire deux CSV de secours sans masquer le résultat métier.

## Non-Functional Requirements

- **NFR-1 :** Les calculs monétaires DOIVENT être effectués en centimes entiers afin d'éviter les erreurs d'arrondi binaires.
- **NFR-2 :** Le contrôle local de l'instance de référence de 124 lignes DOIT terminer en moins de 5 secondes, hors génération Excel.
- **NFR-3 :** Le lanceur DOIT fonctionner sous Windows avec `cmd.exe` et Python 3.9 ou supérieur.
- **NFR-4 :** Les chemins contenant des espaces DOIVENT être pris en charge.
- **NFR-5 :** Une erreur de lecture DOIT indiquer le fichier et, pour une ligne mal formée, son numéro sans afficher de donnée de connexion.
- **NFR-6 :** Une erreur Oracle DOIT interrompre le contrôle avec le code 1 et ne DOIT jamais être transformée en résultat zéro ou `ABSENTE`.

## Acceptance Criteria

### AC-1: instance GL conforme (FR-1, FR-2, FR-4, FR-6, FR-7, FR-8, FR-9, FR-11, FR-13)

Given le dossier `04072026_GL_GER`, When `controleGL.bat` est exécuté avec ce dossier, Then le SRC et le CTL sont découverts, GER affiche 36 pièces et 11 971,96 EUR au débit/crédit, FGE affiche 5 pièces et 13 216,66 EUR au débit/crédit, et le code retour est 0.

### AC-2: CTL déduit (FR-4)

Given un fichier SRC dont le CTL homonyme existe, When le contrôle reçoit uniquement le SRC, Then il utilise le fichier obtenu par remplacement de `_SRC_` par `_CTL_`.

### AC-3: écart de montant (FR-9, FR-13)

Given un CTL dont le débit diffère du SRC de 0,01 EUR, When le contrôle est exécuté, Then l'origine est marquée `ECART` et le code retour est 2.

### AC-4: écriture déséquilibrée (FR-10, FR-13)

Given un SRC dont une pièce a un débit différent de son crédit, When le contrôle est exécuté, Then la pièce est signalée comme déséquilibrée et le code retour est 2.

### AC-5: fichier absent (FR-1, FR-3, FR-4, FR-13, NFR-5)

Given un chemin SRC ou CTL inexistant, When le contrôle est exécuté, Then il affiche le chemin introuvable et retourne 1.

### AC-6: ligne mal formée (FR-5, FR-13, NFR-5)

Given une ligne SRC ayant moins de 12 colonnes ou un montant illisible, When le contrôle la lit, Then il indique le numéro de ligne et retourne 1 sans produire de résultat conforme.

### AC-7: précision monétaire (FR-7, FR-9, NFR-1)

Given des montants avec deux décimales, When le contrôle les agrège, Then le résultat en centimes est exact et ne dépend pas de l'arithmétique flottante.

### AC-8: rapport optionnel (FR-12)

Given que `openpyxl` est absent, When le rapprochement est exécuté, Then la synthèse texte et le code retour restent disponibles et seul un avertissement de rapport non généré est affiché.

### AC-9: fichiers en lecture seule (FR-14)

Given des fichiers SRC, CTL et TARGET existants, When le contrôle est exécuté, Then leurs contenus et dates de modification restent inchangés.

### AC-10: requête Oracle GL (FR-15, FR-16, FR-17)

Given un SRC contenant GER et FGE, When la vérification Oracle prépare ses requêtes, Then une seule session Oracle interroge pour chaque origine `GL_JE_HEADERS`/`GL_JE_LINES` et `GL_INTERFACE` avec les filtres `attribute9` et `attribute10` issus du SRC.

### AC-11: rapport Oracle coloré (FR-18, FR-19)

Given une interrogation Oracle aboutie, When la restitution est produite, Then le classeur contient `Synthese Oracle` et `Detail Pieces SRC`, ses en-têtes sont bleu foncé, les statuts intégrés sont verts et les anomalies pêche ; si Excel est absent, les deux CSV équivalents sont créés.

## Edge Cases

- EC-1: Plusieurs SRC dans le dossier → sélectionner récursivement celui dont la date de modification est la plus récente.
- EC-2: Origine absente du CTL ou absente du SRC → la marquer `ECART`.
- EC-3: Numéro de pièce vide → erreur technique avec numéro de ligne.
- EC-4: Origine vide → erreur technique avec numéro de ligne.
- EC-5: Montant vide → l'interpréter comme zéro ; montant non vide et non numérique → erreur technique.
- EC-6: CTL duplique une origine → erreur technique afin d'éviter l'écrasement silencieux d'une attente.
- EC-7: Échec d'écriture du rapport Excel → afficher un avertissement, sans remplacer le résultat métier du rapprochement.
- EC-8: Dossier sans SRC correspondant → erreur technique et code retour 1.

## API Contracts

```text
controleGL.bat [dossier | fichier_SRC] [fichier_CTL]
python ctl_ecritures_gl.py fichier_SRC [fichier_CTL]
powershell -File Verifier_Oracle_Ecritures_GL.ps1 -CheminFichierSrc fichier_SRC

Sortie standard : synthèse par origine et synthèse globale
Sortie erreur    : fichier/ligne et cause technique
Code 0           : rapprochement et équilibre conformes
Code 1           : erreur technique ou entrée invalide
Code 2           : écart SRC/CTL ou déséquilibre comptable
```

L'accès Oracle est réalisé en lecture seule par `sqlplus`, `sqlcl` ou `sql`. L'interface publique reste la ligne de commande ci-dessus.

## Data Models

### Écriture GL SRC

| Champ | Type | Contraintes |
|---|---|---|
| Numéro de pièce | texte | Colonne 1, obligatoire, compté distinctement par origine |
| Débit | centimes entiers | Colonne 9, vide accepté comme zéro |
| Crédit | centimes entiers | Colonne 10, vide accepté comme zéro |
| Origine | texte | Colonne 12, obligatoire |
| Colonnes restantes | texte | Conservées hors calcul ; au moins 12 colonnes requises |

### Attente CTL GL

| Champ | Type | Contraintes |
|---|---|---|
| Origine | texte | Colonne 1, obligatoire et unique |
| Date | texte | Colonne 2, informative |
| Nombre de pièces | entier | Colonne 3, positif ou nul |
| Débit attendu | centimes entiers | Colonne 4 |
| Crédit attendu | centimes entiers | Colonne 5 |
| Nom du SRC | texte | Colonne 6 |
| Code | texte | Colonne 7, informatif |

### Résultat par origine

| Champ | Type | Contraintes |
|---|---|---|
| Origine | texte | Union des origines SRC et CTL |
| Pièces SRC/CTL | entier nullable | Comparées pour égalité |
| Débit SRC/CTL | centimes nullable | Comparés à 0,005 EUR près |
| Crédit SRC/CTL | centimes nullable | Comparés à 0,005 EUR près |
| Statut | `OK` ou `ECART` | `OK` uniquement si tous les contrôles passent |

## Out of Scope

- OS-1: Validation du contenu métier de `FAC02_PIVOT_GL_*` — les règles de transformation des colonnes ajoutées ne sont pas disponibles.
- OS-2: Modification ou correction automatique des écritures — le contrôle reste strictement en lecture seule.
- OS-3: Contrôle des flux clients et fournisseurs — déjà couvert par leurs lanceurs dédiés.
