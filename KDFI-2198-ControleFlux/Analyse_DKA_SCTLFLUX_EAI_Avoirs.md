# Analyse – DKA_SCTLFLUX_EAI et écarts sur les avoirs (IGP/SVD)

-- =====================================================================
-- DKA : Extraction du contrôle de flux — Analyse des écarts sur avoirs
-- =====================================================================
-- Date de création : 03/12/2025
-- Auteur : GitHub Copilot
-- Base de données : Oracle EBS 12.2.13 (DB 19.25)
--
-- PROBLÈME RÉSOLU : Comprendre pourquoi les avoirs clients ne sont pas traités
-- à l’identique des factures, provoquant des écarts de montants dans le contrôle
-- des flux (folios IGP et SVD notamment).
--
-- CHANGEMENTS PAR RAPPORT À LA VERSION ORIGINALE :
-- 1. Proposition de consolidation par montant net (Dr - Cr) pour homogénéiser
--    les traitements des avoirs et des factures.
-- 2. Vérifications ciblées sur les clés de regroupement (REFERENCE4, ATTRIBUTE10)
--    et inclusion des lignes de taxe RA.
--
-- VOIR : Rapport_Traitements_Flux_DKA_SCTLFLUX_EAI.md
-- =====================================================================

## Constat (rappel demande KDFI-2198)
- Le contrôle amont et Oracle EBS affichent le même nombre de documents intégrés, mais des écarts apparaissent sur les montants lorsque des avoirs sont présents.
- Exemple récurrent sur les folios IGP et SVD.

## Fonctionnement du programme
- Programme concurrent: `DKA_SCTLFLUX_EAI` (PL/SQL), exécutable `DKA_SCTLFLUX_EAI_PKG.main`.
- Source principale des données: `GL_INTERFACE` (agrégation et insertion dans `DKA_SCTLFLUX_EAI`).
- Marquage de session: `attribute5 = FND_PROFILE('CONC_REQUEST_ID')` sur `GL_INTERFACE` et `GL_JE_LINES`.
- Filtrage folio via jeu de valeurs `DKA_PARAM_FOLIO_GL` (`ATTRIBUTE9`).
- Restriction aux ledgers primaires (`GL_LEDGERS.ledger_category_code = 'PRIMARY'`).

### Agrégations clés (INSERT_GL_DATA)
- NB_PIECE: `COUNT(DISTINCT (ATTRIBUTE9 || '|' || REFERENCE4))`.
- Montants: `DEBIT = SUM(Entered_Dr)`, `CREDIT = SUM(Entered_Cr)`.
- Fichier: `ATTRIBUTE10`.
- DATE_EXEC: `MIN(TRUNC(GI.DATE_CREATED))` (fix 18/05/2015).

## Hypothèse de cause – Avoirs mal reflétés
1) Direction des montants (Dr/Cr):
   - Les avoirs clients peuvent produire des écritures où la valeur « économique » du crédit est portée en `Entered_Dr` selon le sens comptable du compte.
   - En comparatif amont (souvent « montant net par fichier »), un calcul strict par `SUM(Entered_Cr)` pour les crédits peut sous-évaluer les avoirs.

2) Clé de regroupement des pièces:
   - `REFERENCE4` peut différer entre factures et avoirs (nature de l’interface, mapping AR/GL). La clé `ATTRIBUTE9||'|'||REFERENCE4` reste pertinente pour le décompte, mais peut scinder des montants d’un même document si `REFERENCE4` varie par ligne.

3) Attribution fichier (`ATTRIBUTE10`) et lignes de taxe RA:
   - Modification historique (25/11/2019) sur folio et nom de fichier pour lignes de taxe RA.
   - Les lignes de taxe d’avoirs peuvent s’agréger sous un nom de fichier distinct de l’amont, créant un écart par fichier.

4) Ledgers secondaires non inclus:
   - Si l’amont consolide des reporting-ledgers, la restriction aux ledgers primaires entraîne des montants inférieurs côté EBS pour certains fichiers.

## Pourquoi le nombre est correct mais le montant diverge
- Le décompte par `DISTINCT (ATTRIBUTE9||'|'||REFERENCE4)` stabilise le nombre de documents.
- Les montants dérivent car:
  - Le sens comptable déporte des valeurs sur `Entered_Dr` pour des avoirs.
  - Les lignes de taxe RA (avoir) changent de fichier (`ATTRIBUTE10`) post-fix 2019.
  - La consolidation attendue par l’amont est « net par fichier » alors que l’extraction EBS conserve la séparation Dr/Cr.

## Vérifications rapides recommandées (SQL)

```sql
-- 1) Distribution Dr/Cr sur avoirs (par fichier)
SELECT ATTRIBUTE10 fichier,
       SUM(Entered_Dr) dr,
       SUM(Entered_Cr) cr,
       SUM(NVL(Entered_Dr,0) - NVL(Entered_Cr,0)) net
FROM GL_INTERFACE
WHERE ATTRIBUTE9 IN (SELECT ffv.attribute1
                       FROM fnd_flex_values_vl ffv
                       JOIN fnd_flex_value_sets s ON s.flex_value_set_id = ffv.flex_value_set_id
                      WHERE s.flex_value_set_name = 'DKA_PARAM_FOLIO_GL'
                        AND ffv.enabled_flag = 'Y')
  AND DATE_CREATED BETWEEN :date_debut AND :date_fin
  AND ATTRIBUTE10 = :fichier
GROUP BY ATTRIBUTE10;

-- 2) Clé de regroupement et cardinalité par document
SELECT ATTRIBUTE9 folio,
       REFERENCE4 doc_ref,
       COUNT(*) lignes,
       SUM(NVL(Entered_Dr,0) - NVL(Entered_Cr,0)) net
FROM GL_INTERFACE
WHERE ATTRIBUTE10 = :fichier
  AND DATE_CREATED BETWEEN :date_debut AND :date_fin
GROUP BY ATTRIBUTE9, REFERENCE4
ORDER BY 1,2;

-- 3) Lignes de taxe RA rattachées à des avoirs
SELECT ATTRIBUTE10 fichier,
       COUNT(*) nb_tax_lines,
       SUM(NVL(Entered_Dr,0) - NVL(Entered_Cr,0)) net
FROM GL_INTERFACE
WHERE SOURCE = 'RA' -- si la colonne SOURCE est disponible, sinon utiliser le code segment
  AND ATTRIBUTE10 = :fichier
  AND DATE_CREATED BETWEEN :date_debut AND :date_fin
GROUP BY ATTRIBUTE10;
```

## Recommandations de correction
- Calcul des montants « net » pour comparatif amont:
  - Ajouter une colonne NET = `SUM(NVL(Entered_Dr,0) - NVL(Entered_Cr,0))` dans l’insertion vers `DKA_SCTLFLUX_EAI` (sans supprimer DEBIT/CREDIT).
  - Utiliser NET pour la réconciliation avec l’amont (fichier par fichier).

- Harmonisation fichier pour lignes de taxe RA:
  - Vérifier que `ATTRIBUTE10` des lignes de taxe d’avoirs correspond au fichier parent du document.
  - Si nécessaire, normaliser `ATTRIBUTE10` au moment de l’agrégation.

- Paramètres d’exploitation:
  - S’assurer que `pv_folio` appartient à `DKA_PARAM_FOLIO_GL`.
  - Ajuster la fenêtre `pd_date_debut`/`pd_date_fin` aux fichiers examinés.
  - Si l’amont inclut des ledgers secondaires, prévoir une option d’inclusion contrôlée.

## Proposition de patch (indicatif)
- Bloc `INSERT INTO DKA_SCTLFLUX_EAI (...) SELECT ... FROM GL_INTERFACE ...` :
  - Ajouter le champ `NET` dans la cible (si la table le permet) ou un champ libre (ex: `ATTRIBUTE1`).
  - Calcul: `SUM(NVL(GI.Entered_Dr,0) - NVL(GI.Entered_Cr,0))`.
  - Continuer à peupler DEBIT/CREDIT pour compatibilité descendante.

## Conclusion
Les écarts de montants en présence d’avoirs proviennent principalement d’un calcul basé sur la séparation Dr/Cr qui ne reflète pas le « net amont » attendu, combiné à des spécificités de regroupement (`REFERENCE4`) et d’attribution fichier (`ATTRIBUTE10`) pour les lignes de taxe RA. La consolidation par montant net et la normalisation des fichiers améliorent la concordance sans altérer les décomptes de documents.
