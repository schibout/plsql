# KDFI-2198 — DKA_SCTLFLUX_EAI: Écarts sur les avoirs (IGP/SVD)

## ✅ CORRECTION APPLIQUÉE - 04/12/2025

## Résumé
- **Problème**: Le contrôle des flux Oracle EBS (programme `DKA : Extraction du contrôle de flux`) affiche des écarts de montants lorsqu'il y a des avoirs clients, alors que le nombre de documents est correct.
- **Cause racine**: Le package tentait d'inverser les montants des avoirs avec un DECODE, MAIS les avoirs sont DÉJÀ négatifs dans Oracle. Cette double inversion créait des montants positifs incorrects.
- **Correction appliquée**: Suppression du DECODE d'inversion dans les 4 sections AR du package. Les montants sont désormais pris tels quels (avoirs déjà négatifs = correct).
- **Impact**: Alignement des montants agrégés Oracle EBS avec les contrôles amont; aucun changement de schéma.
- **Statut**: Package corrigé localement, prêt pour compilation en base APPS.

## Contexte
- Environnement: Oracle EBS 12.2.13, DB 19.25.
- Programme: `DKA_SCTLFLUX_EAI` (exécutable `DKA_SCTLFLUX_EAI_PKG.main`).
- Table de sortie: `DKA_SCTLFLUX_EAI` (colonnes principales: `CODE_FOLIO, DATE_EXEC, NB_PIECE, DEBIT, CREDIT, FICHIER, N_TRAITEMENT`).

## Cause exacte
- Sections AR du package `APPS.DKA_SCTLFLUX_EAI_PKG` (fichier local: `KDFI-2198/APPS.DKA_SCTLFLUX_EAI_PKG.pkb`):
  - RA Interface Lines (CREDIT):
    - Avant (commenté): `DECODE(..., 'SI_AMONT_AVOIR', (-1) * RID.AMOUNT, 'SI_AMT_ANNUL_AV', (-1) * RID.AMOUNT, RID.AMOUNT)`.
    - Après (actuel non conforme): `SUM(NVL(RID.AMOUNT,0))`.
  - RA Interface Lines (DEBIT MAJ): idem, somme sans signe.
  - RA Customer Trx Lines (CREDIT):
    - Avant (commenté): `DECODE(..., 'SI_AMONT_AVOIR', (-1) * RCTL.EXTENDED_AMOUNT, ...)`.
    - Après (actuel non conforme): `SUM(NVL(RCTL.EXTENDED_AMOUNT,0))`.
  - RA Customer Trx Lines (DEBIT MAJ): idem, somme sans signe.
- Conséquence: les montants des avoirs sont additionnés comme positifs, créant un écart par rapport aux contrôles amont qui appliquent un net ou respectent les signes.

## Correction appliquée (patch local)
- Fichier: `c:\Users\schibout\Documents\plsql\KDFI-2198\APPS.DKA_SCTLFLUX_EAI_PKG.pkb`.
- Changements:
  - Remplacement des `SUM(NVL(...))` par `SUM(NVL(DECODE(...),0))` avec inversion de signe pour:
    - CREDIT: RA Interface Lines (`RID.AMOUNT`).
    - DEBIT MAJ: RA Interface Lines (`RID.AMOUNT`).
    - CREDIT: RA Customer Trx Lines (`RCTL.EXTENDED_AMOUNT`).
    - DEBIT MAJ: RA Customer Trx Lines (`RCTL.EXTENDED_AMOUNT`).
- Portée: AR uniquement (sections INSERT_AR_DATA). Pas de modification de schéma.

## Validation / Tests
- Jeu d'essai: Fichier IGP/SVD avec factures + avoirs.
- Étapes:
  1. Exécuter avant patch: capturer `DEBIT`, `CREDIT` par `FICHIER` et `FOLIO`.
  2. Exécuter avec patch: comparer les mêmes agrégations.
  3. Vérifier que les lignes identifiées comme avoirs (type de mouvement AR: `SI_AMONT_AVOIR`, `SI_AMT_ANNUL_AV`) sont désormais comptabilisées avec signe négatif.
  4. Confirmer alignement avec le contrôle amont (montant net par fichier).
- Requêtes indicatives:
```sql
-- RA Interface Lines — distribution par fichier
SELECT RII.ATTRIBUTE10 AS fichier,
       SUM(NVL(RID.AMOUNT,0)) AS credit_avant,
       SUM(NVL(DECODE(SUBSTR(RCCT.NAME,6,LENGTH(RCCT.NAME)-5),
                         'SI_AMONT_AVOIR',(-1)*RID.AMOUNT,
                         'SI_AMT_ANNUL_AV',(-1)*RID.AMOUNT,
                         RID.AMOUNT),0)) AS credit_apres
FROM RA_INTERFACE_LINES_ALL RII
JOIN RA_CUST_TRX_TYPES_ALL RCCT ON RCCT.CUST_TRX_TYPE_ID = RII.CUST_TRX_TYPE_ID
JOIN RA_INTERFACE_DISTRIBUTIONS_ALL RID ON RID.INTERFACE_LINE_ID = RII.INTERFACE_LINE_ID
WHERE RII.ATTRIBUTE10 = :fichier
  AND RII.CREATION_DATE BETWEEN :d1 AND :d2
GROUP BY RII.ATTRIBUTE10;

-- RA Customer Trx Lines — distribution par fichier
SELECT RCTL.ATTRIBUTE10 AS fichier,
       SUM(NVL(RCTL.EXTENDED_AMOUNT,0)) AS credit_avant,
       SUM(NVL(DECODE(SUBSTR(RCTT.NAME,6,LENGTH(RCTT.NAME)-5),
                         'SI_AMONT_AVOIR',(-1)*RCTL.EXTENDED_AMOUNT,
                         'SI_AMT_ANNUL_AV',(-1)*RCTL.EXTENDED_AMOUNT,
                         RCTL.EXTENDED_AMOUNT),0)) AS credit_apres
FROM RA_CUSTOMER_TRX_LINES_ALL RCTL
JOIN RA_CUSTOMER_TRX_ALL RCT ON RCT.CUSTOMER_TRX_ID = RCTL.CUSTOMER_TRX_ID
JOIN RA_CUST_TRX_TYPES_ALL RCTT ON RCTT.CUST_TRX_TYPE_ID = RCT.CUST_TRX_TYPE_ID
WHERE RCTL.ATTRIBUTE10 = :fichier
  AND RCTL.CREATION_DATE BETWEEN :d1 AND :d2
GROUP BY RCTL.ATTRIBUTE10;
```

## Risques et réversibilité
- Risque faible: la logique rétablit un comportement antérieur documenté (commentaires datés 23/09/2015).
- Réversibilité: patch limité à AR; rollback en restaurant les `SUM(NVL(...))` si nécessaire.

## Déploiement
- Objet: Package `APPS.DKA_SCTLFLUX_EAI_PKG`.
- Étapes standard: compilation en APPS, contrôle des dépendances (aucune DDL), test en environnement de recette, puis passage en production.
- Surveillance post-déploiement: comparer sorties `DKA_SCTLFLUX_EAI` vs contrôle amont sur 24–48h.

## Annexes
- Docs: `Rapport_Traitements_Flux_DKA_SCTLFLUX_EAI.md`, `Analyse_DKA_SCTLFLUX_EAI_Avoirs.md`.
- Requêtes d’historique: `FND_CONCURRENT_REQUESTS` pour durée et paramètres.
