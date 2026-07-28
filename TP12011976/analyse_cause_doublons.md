# Analyse de la Cause des Doublons - DKA_IARPAFAC

**Date** : 12/01/2026  
**Incident** : REQUEST_ID 46750251 - ORA-00001 violation de contrainte unique  
**Programme** : DKA : Import des Factures clients (DKA_IARPAFAC)

---

## Résumé Exécutif

Les doublons ne sont **PAS** causés par une duplication de fichier ou un rechargement accidentel. Le problème vient de la **structure des données source** où plusieurs lignes de détail partagent le même numéro de ligne (`LINE_NUMBER`).

---

## Analyse Détaillée

### Exemple : Facture 0001S2601P211

Le fichier source `FAC02_SRC_FACTURESCLIENTS_090126-024105` contient les lignes suivantes :

| IARPAFAC_ID | LINE_NUMBER | LINE_TYPE | MONTANT (€) | TASK_CODE |
|-------------|-------------|-----------|-------------|-----------|
| 43072951 | 0 | CLIENT | 68 398,00 | - |
| 43072952 | 1 | PRODUIT | 75,17 | GL0012100A |
| 43072953 | 1 | PRODUIT | 100,16 | GL0012100A |
| 43072954 | 1 | PRODUIT | 201,45 | GL0012100A |
| 43072955 | 1 | PRODUIT | 300,69 | GL0012100A |
| 43072956 | 1 | PRODUIT | 400,64 | GL0012100A |
| 43072957 | 1 | PRODUIT | 805,78 | GL0012100A |
| 43072958 | 1 | PRODUIT | 3 941,54 | GL0012100A |
| 43072959 | 2 | GESTION | 75,36 | - |
| 43072960 | 2 | GESTION | 150,71 | - |
| 43072961 | 2 | GESTION | 788,03 | - |

**Observation** : 7 lignes PRODUIT différentes ont toutes `LINE_NUMBER = 1`

---

## Contrainte Unique Violée

La contrainte `AR.DKA_RA_INTERFACE_LINES_U1` impose l'unicité sur 7 colonnes :

| Position | Colonne | Valeur Source |
|----------|---------|---------------|
| 1 | INTERFACE_LINE_CONTEXT | Contexte DKA |
| 2 | INTERFACE_LINE_ATTRIBUTE1 | ORIGIN (ex: GCA) |
| 3 | INTERFACE_LINE_ATTRIBUTE2 | COMPANY_CODE (ex: 0001) |
| 4 | INTERFACE_LINE_ATTRIBUTE3 | INVOICE_NUMBER (ex: 0001S2601P211) |
| 5 | INTERFACE_LINE_ATTRIBUTE4 | LINE_NUMBER (ex: 1) |
| 6 | INTERFACE_LINE_ATTRIBUTE5 | Période YYYYMM (ex: 202601) |
| 7 | REQUEST_ID | ID de la requête |

### Le Problème

Quand le package `DKA_IARPAFAC_PKG` insère les 7 lignes PRODUIT dans `RA_INTERFACE_LINES_ALL`, elles génèrent toutes la **même clé unique** :

```
(CONTEXT, GCA, 0001, 0001S2601P211, 1, 202601, 46750251)
```

→ La 2ème insertion (et suivantes) viole la contrainte unique.

---

## Cause Racine

### Origine dans le Système Source FAC02/GCA

Le système source génère plusieurs lignes de détail avec :
- Des **montants différents** (75€, 100€, 201€, 300€, 400€, 805€, 3941€)
- Mais le **même LINE_NUMBER = 1**

C'est une **anomalie de structure des données source** car :
1. Le `LINE_NUMBER` devrait être unique par ligne de détail (1, 2, 3, 4, 5, 6, 7)
2. OU les montants devraient être consolidés en une seule ligne

### Ce n'est PAS :
- ❌ Un rechargement du même fichier
- ❌ Une duplication technique dans l'interface
- ❌ Un bug du programme DKA_IARPAFAC

---

## Statistiques de l'Incident

| Métrique | Valeur |
|----------|--------|
| Fichier source | FAC02_SRC_FACTURESCLIENTS_090126-024105 |
| Total lignes | 1 927 |
| Factures concernées | 362 |
| Combinaisons en doublon | 30 |
| Lignes rejetées | 138 |

---

## Solutions Possibles

### 1. Correction à la Source (Recommandé)
Demander à l'équipe FAC02/GCA de :
- Générer des `LINE_NUMBER` uniques pour chaque ligne de détail
- Ou consolider les lignes avec même `LINE_NUMBER`

### 2. Correction dans le Package DKA_IARPAFAC_PKG
Modifier le package pour générer un compteur séquentiel (`pn_line_num_cnt`) au lieu d'utiliser `LINE_NUMBER` du fichier source.

Le code actuel utilise déjà `pn_line_num_cnt` dans certains cas :
```sql
TO_CHAR (pn_line_num_cnt),   -- Interface_Line_Attribute4
```

Mais pas systématiquement pour toutes les lignes.

### 3. Action Immédiate
Pour traiter les 126 153 lignes en attente :

```sql
-- Supprimer les lignes rejetées
DELETE FROM DKA.DKA_IARPAFAC_INTERFACE
WHERE OA_STATUS = 'R';

-- Puis relancer le programme
```

---

## Conclusion

Le problème n'est pas un doublon de fichier mais une **structure de données source incorrecte** où le champ `LINE_NUMBER` n'identifie pas uniquement chaque ligne de détail au sein d'une facture.

**Action requise** : Remonter le problème à l'équipe responsable du flux FAC02/GCA pour correction à la source.
