# Correction du contrôle de flux - Gestion des avoirs clients

-- =====================================================================
-- DKA : Extraction du contrôle de flux — Correction écarts avoirs
-- =====================================================================
-- Date de correction : 04/12/2025
-- Auteur : GitHub Copilot
-- Base de données : Oracle EBS 12.2.13 (DB 19.25)
-- Package : APPS.DKA_SCTLFLUX_EAI_PKG
--
-- PROBLÈME CORRIGÉ : Les montants des avoirs clients n'étaient pas inversés
-- dans les agrégations du contrôle de flux, causant des écarts avec l'amont.
--
-- VOIR : CONCLUSION_DKA_SCTLFLUX_EAI_Avoirs_Jira.md
--        Analyse_DKA_SCTLFLUX_EAI_Avoirs.md
-- =====================================================================

## Résumé du problème

**Symptôme** : Le nombre de factures/avoirs dans le contrôle de flux Oracle EBS est correct, mais les montants DEBIT et CREDIT affichent des écarts par rapport aux contrôles amont, particulièrement pour les folios IGP et SVD contenant des avoirs.

**Cause racine** : Le code qui inversait le signe des avoirs (`SI_AMONT_AVOIR`, `SI_AMT_ANNUL_AV`) avait été commenté dans le package `DKA_SCTLFLUX_EAI_PKG`. Les montants des avoirs étaient donc additionnés comme des valeurs positives au lieu d'être soustraits.

## Sections corrigées

### 1. RA_INTERFACE_LINES - Calcul CREDIT (INSERT)
**Ligne ~690**

**Avant (incorrect)** :
```sql
SUM(NVL(RID.AMOUNT, 0)), -- CREDIT
```

**Après (correct)** :
```sql
SUM(NVL(DECODE(SUBSTR(RCCT.NAME,6,LENGTH(RCCT.NAME)-5),
               'SI_AMONT_AVOIR',     (-1) * RID.AMOUNT,
               'SI_AMT_ANNUL_AV',    (-1) * RID.AMOUNT,
               RID.AMOUNT), 0)), -- CREDIT
```

### 2. RA_INTERFACE_LINES - Mise à jour DEBIT (UPDATE)
**Ligne ~714**

**Avant (incorrect)** :
```sql
SET DSE.DEBIT  = (SELECT SUM(NVL(RID.AMOUNT, 0))  -- DEBIT
```

**Après (correct)** :
```sql
SET DSE.DEBIT  = (SELECT SUM(NVL(DECODE(SUBSTR(RCCT.NAME,6,LENGTH(RCCT.NAME)-5),
                                         'SI_AMONT_AVOIR',     (-1) * RID.AMOUNT,
                                         'SI_AMT_ANNUL_AV',    (-1) * RID.AMOUNT,
                                         RID.AMOUNT), 0))  -- DEBIT
```

### 3. RA_CUSTOMER_TRX_LINES - Calcul CREDIT (INSERT)
**Ligne ~850**

**Avant (incorrect)** :
```sql
SUM(NVL(RCTL.EXTENDED_AMOUNT, 0)), -- CREDIT
```

**Après (correct)** :
```sql
SUM(NVL(DECODE(SUBSTR(RCTT.NAME,6,LENGTH(RCTT.NAME)-5),
               'SI_AMONT_AVOIR',     (-1) * RCTL.EXTENDED_AMOUNT,
               'SI_AMT_ANNUL_AV',    (-1) * RCTL.EXTENDED_AMOUNT,
               RCTL.EXTENDED_AMOUNT), 0)), -- CREDIT
```

### 4. RA_CUSTOMER_TRX_LINES - Mise à jour DEBIT (UPDATE)
**Ligne ~904**

**Avant (incorrect)** :
```sql
SET DSE.DEBIT  = (SELECT SUM(NVL(RCTL.EXTENDED_AMOUNT, 0)) --DEBIT
```

**Après (correct)** :
```sql
SET DSE.DEBIT  = (SELECT SUM(NVL(DECODE(SUBSTR(RCTT.NAME,6,LENGTH(RCTT.NAME)-5),
                                         'SI_AMONT_AVOIR',     (-1) * RCTL.EXTENDED_AMOUNT,
                                         'SI_AMT_ANNUL_AV',    (-1) * RCTL.EXTENDED_AMOUNT,
                                         RCTL.EXTENDED_AMOUNT), 0)) --DEBIT
```

## Logique de la correction

La correction utilise `DECODE` sur le nom du type de transaction client pour détecter les avoirs :
- **SI_AMONT_AVOIR** : Avoir client standard provenant de l'amont
- **SI_AMT_ANNUL_AV** : Annulation d'avoir

Lorsqu'un de ces types est détecté, le montant est multiplié par `-1` pour l'inverser, permettant ainsi une agrégation nette correcte.

**Note** : La fonction `SUBSTR(RCCT.NAME,6,LENGTH(RCCT.NAME)-5)` ou `SUBSTR(RCTT.NAME,6,LENGTH(RCTT.NAME)-5)` extrait le code du type de mouvement en supprimant le préfixe standard du nom du type de transaction.

## Impact

- **Portée** : Module AR uniquement (Accounts Receivable - factures et avoirs clients)
- **Tables modifiées** : Aucune (modification de package uniquement)
- **Modules non affectés** : AP (Accounts Payable) et GL (General Ledger) - pas de modification

## Déploiement

### Compilation du package

```sql
-- Connexion en tant qu'utilisateur APPS
@APPS.DKA_SCTLFLUX_EAI_PKG.pkb

-- Vérification de la compilation
SELECT object_name, object_type, status
FROM dba_objects
WHERE owner = 'APPS'
  AND object_name = 'DKA_SCTLFLUX_EAI_PKG'
  AND object_type = 'PACKAGE BODY';
```

**Résultat attendu** : STATUS = 'VALID'

### Validation

#### Requête de test pour RA_INTERFACE_LINES

```sql
SELECT RII.ATTRIBUTE10 AS fichier,
       RII.ATTRIBUTE9 AS folio,
       SUBSTR(RCCT.NAME,6,LENGTH(RCCT.NAME)-5) AS type_mvt,
       COUNT(*) AS nb_lignes,
       SUM(RID.AMOUNT) AS montant_brut,
       SUM(DECODE(SUBSTR(RCCT.NAME,6,LENGTH(RCCT.NAME)-5),
                  'SI_AMONT_AVOIR',     (-1) * RID.AMOUNT,
                  'SI_AMT_ANNUL_AV',    (-1) * RID.AMOUNT,
                  RID.AMOUNT)) AS montant_net
FROM RA_INTERFACE_LINES_ALL RII
JOIN RA_CUST_TRX_TYPES_ALL RCCT ON RCCT.CUST_TRX_TYPE_ID = RII.CUST_TRX_TYPE_ID
JOIN RA_INTERFACE_DISTRIBUTIONS_ALL RID ON RID.INTERFACE_LINE_ID = RII.INTERFACE_LINE_ID
WHERE RII.CREATION_DATE >= TRUNC(SYSDATE) - 7
  AND RII.ATTRIBUTE9 IN ('IGP', 'SVD')
  AND SUBSTR(RID.SEGMENT3, 1, 3) = '411'
GROUP BY RII.ATTRIBUTE10, RII.ATTRIBUTE9, SUBSTR(RCCT.NAME,6,LENGTH(RCCT.NAME)-5)
ORDER BY 1, 2, 3;
```

**Interprétation** :
- `montant_brut` : somme simple (ancien comportement incorrect)
- `montant_net` : somme avec inversion des avoirs (nouveau comportement correct)
- Pour les types `SI_AMONT_AVOIR` et `SI_AMT_ANNUL_AV`, le montant_net doit être négatif

#### Requête de test pour RA_CUSTOMER_TRX_LINES

```sql
SELECT RCTL.ATTRIBUTE10 AS fichier,
       RCTL.ATTRIBUTE9 AS folio,
       SUBSTR(RCTT.NAME,6,LENGTH(RCTT.NAME)-5) AS type_mvt,
       COUNT(DISTINCT RCTL.CUSTOMER_TRX_ID) AS nb_docs,
       SUM(RCTL.EXTENDED_AMOUNT) AS montant_brut,
       SUM(DECODE(SUBSTR(RCTT.NAME,6,LENGTH(RCTT.NAME)-5),
                  'SI_AMONT_AVOIR',     (-1) * RCTL.EXTENDED_AMOUNT,
                  'SI_AMT_ANNUL_AV',    (-1) * RCTL.EXTENDED_AMOUNT,
                  RCTL.EXTENDED_AMOUNT)) AS montant_net
FROM RA_CUSTOMER_TRX_LINES_ALL RCTL
JOIN RA_CUSTOMER_TRX_ALL RCT ON RCT.CUSTOMER_TRX_ID = RCTL.CUSTOMER_TRX_ID
JOIN RA_CUST_TRX_TYPES_ALL RCTT ON RCTT.CUST_TRX_TYPE_ID = RCT.CUST_TRX_TYPE_ID
WHERE RCTL.CREATION_DATE >= TRUNC(SYSDATE) - 7
  AND RCTL.ATTRIBUTE9 IN ('IGP', 'SVD')
  AND RCT.INTERFACE_HEADER_CONTEXT = 'FACTURATION'
GROUP BY RCTL.ATTRIBUTE10, RCTL.ATTRIBUTE9, SUBSTR(RCTT.NAME,6,LENGTH(RCTT.NAME)-5)
ORDER BY 1, 2, 3;
```

#### Vérification du contrôle de flux

```sql
-- Exécuter le programme concurrent "DKA : Extraction du contrôle de flux"
-- avec les paramètres :
-- - Folio : IGP (ou SVD)
-- - Date de début : SYSDATE - 7
-- - Date de fin : SYSDATE

-- Puis comparer les résultats
SELECT CODE_FOLIO,
       FICHIER,
       NB_PIECE,
       DEBIT,
       CREDIT,
       (DEBIT - CREDIT) AS NET,
       N_TRAITEMENT,
       DATE_EXEC
FROM DKA_SCTLFLUX_EAI
WHERE N_TRAITEMENT = :request_id
  AND CODE_FOLIO IN ('IGP', 'SVD')
ORDER BY CODE_FOLIO, FICHIER;
```

**Validation attendue** :
- Les montants DEBIT et CREDIT doivent désormais correspondre aux montants nets calculés par l'amont
- Pour les fichiers contenant des avoirs, le CREDIT doit être réduit (ou négatif) par rapport à l'ancien calcul

## Risques et réversibilité

**Risques** : Faible - cette correction rétablit le comportement original du package qui avait été documenté dans les commentaires (historique 23/09/2015 JJA).

**Réversibilité** : Immédiate - en cas de problème, restaurer les 4 lignes `SUM(NVL(...))` simples sans le DECODE.

## Suivi post-déploiement

1. Exécuter le programme pour les folios IGP et SVD pendant 24-48h
2. Comparer systématiquement avec les contrôles amont
3. Vérifier que les écarts non justifiés ont disparu
4. Si nécessaire, retraiter les périodes récentes avec reprise manuelle

## Références

- **JIRA** : KDFI-2198
- **Package** : `APPS.DKA_SCTLFLUX_EAI_PKG` (body)
- **Programme concurrent** : "DKA : Extraction du contrôle de flux"
- **Tables impactées** : `DKA_SCTLFLUX_EAI`, `RA_INTERFACE_LINES_ALL`, `RA_CUSTOMER_TRX_LINES_ALL`
- **Historique original** : 23/09/2015 JJA - DPE20140071 (logique DECODE initiale)
