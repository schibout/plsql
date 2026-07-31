# Contrôle des Factures : Interface vs Standard AR

**Date de création** : 17/05/2024  
**Auteur** : Gemini Code Assist  
**Module** : AR (Accounts Receivable)

---

## 1. Objectif

Ce document fournit les requêtes et la procédure pour **vérifier que les factures clients** présentes dans la table d'interface spécifique `DKA.DKA_IARPAFAC_INTERFACE` ont bien été intégrées dans la table standard d'Oracle EBS `ar.ra_customer_trx_all`.

L'objectif est d'identifier rapidement les factures "bloquées" en interface qui n'ont pas été créées dans le module AR, afin de pouvoir analyser la cause racine (erreur de données, échec du programme AutoInvoice, etc.).

---

## 2. Principe de la vérification

La réconciliation se base sur une comparaison entre la table d'interface et la table standard en utilisant deux clés métier essentielles pour garantir l'unicité d'une facture :

1.  **Le numéro de facture** :
    *   Table d'interface : `DKA_IARPAFAC_INTERFACE.INVOICE_NUMBER`
    *   Table standard : `ra_customer_trx_all.TRX_NUMBER`

2.  **La source de la facture** :
    *   Table d'interface : `DKA_IARPAFAC_INTERFACE.ORIGIN`
    *   Table standard : `ra_batch_sources_all.NAME` (liée via `ra_customer_trx_all.batch_source_id`)

L'opérateur `NOT EXISTS` est utilisé pour sa performance et sa lisibilité. Il permet de sélectionner uniquement les enregistrements de la table d'interface qui n'ont **aucune correspondance** dans la table standard sur la base de ces deux clés.

---

## 3. Requêtes de contrôle

### Requête 1 : Lister le détail des factures manquantes

Cette requête retourne la liste détaillée de chaque facture présente dans l'interface mais absente de la table standard AR. C'est la requête principale pour l'investigation.

```oracle-sql
-- =====================================================================
-- Liste des factures de DKA_IARPAFAC_INTERFACE 
-- absentes de la table standard AR (ra_customer_trx_all)
-- =====================================================================
-- OBJECTIF :
-- Identifier les factures présentes dans la table d'interface spécifique
-- DKA_IARPAFAC_INTERFACE qui n'ont pas été intégrées dans la table
-- standard des transactions AR, ra_customer_trx_all.
--
-- CLES DE JOINTURE :
-- 1. Numéro de facture : 
--    - DKA_IARPAFAC_INTERFACE.INVOICE_NUMBER
--    - ra_customer_trx_all.TRX_NUMBER
-- 2. Source de la facture (pour éviter les faux positifs) :
--    - DKA_IARPAFAC_INTERFACE.ORIGIN
--    - ra_batch_sources_all.NAME
-- =====================================================================

SELECT DISTINCT
    dii.INVOICE_NUMBER,
    dii.ORIGIN,
    dii.FIC_IDENT,
    dii.COMPANY_CODE,
    dii.CREATION_DATE,
    dii.OA_STATUS,
    dii.IARPAFAC_ID -- ID utile pour chercher les erreurs dans RA_INTERFACE_ERRORS_ALL
FROM
    DKA.DKA_IARPAFAC_INTERFACE dii
WHERE NOT EXISTS (
    SELECT 1
    FROM ar.ra_customer_trx_all rct
    JOIN ar.ra_batch_sources_all rbs ON rct.batch_source_id = rbs.batch_source_id
    WHERE
        -- Correspondance sur le numéro de facture
        rct.trx_number = dii.INVOICE_NUMBER
        -- Correspondance sur la source pour plus de précision
        AND rbs.name = dii.ORIGIN
)
ORDER BY
    dii.CREATION_DATE DESC;
```

### Requête 2 : Synthèse du nombre de factures manquantes par source

Cette requête fournit une vue agrégée du nombre de factures manquantes, regroupées par leur `ORIGIN`. C'est très utile pour évaluer l'ampleur d'un incident et voir s'il est spécifique à un flux.

```oracle-sql
-- =====================================================================
-- Synthèse des factures de DKA_IARPAFAC_INTERFACE 
-- absentes de la table standard AR, par source
-- =====================================================================
WITH FacturesManquantes AS (
    SELECT DISTINCT
        dii.INVOICE_NUMBER,
        dii.ORIGIN
    FROM
        DKA.DKA_IARPAFAC_INTERFACE dii
    WHERE NOT EXISTS (
        SELECT 1
        FROM ar.ra_customer_trx_all rct
        JOIN ar.ra_batch_sources_all rbs ON rct.batch_source_id = rbs.batch_source_id
        WHERE
            rct.trx_number = dii.INVOICE_NUMBER
            AND rbs.name = dii.ORIGIN
    )
)
SELECT
    fm.ORIGIN,
    COUNT(fm.INVOICE_NUMBER) AS NOMBRE_FACTURES_MANQUANTES
FROM
    FacturesManquantes fm
GROUP BY
    fm.ORIGIN
ORDER BY
    NOMBRE_FACTURES_MANQUANTES DESC;
```

---

## 4. Analyse des résultats et actions futures

Si la **Requête 1** retourne des lignes, cela signifie que des factures sont bloquées. Pour chaque ligne :

1.  **Notez l'ID de l'interface** : Récupérez la colonne `IARPAFAC_ID`.
2.  **Recherchez l'erreur** : Utilisez cet ID pour interroger la table `AR.RA_INTERFACE_ERRORS_ALL` afin de trouver le message d'erreur exact retourné par le programme "AutoInvoice".
    ```sql
    SELECT * 
    FROM AR.RA_INTERFACE_ERRORS_ALL 
    WHERE INTERFACE_LINE_ID = :Votre_IARPAFAC_ID;
    ```
3.  **Analysez l'erreur** : Le message dans `RA_INTERFACE_ERRORS_ALL` (colonne `MESSAGE_TEXT`) vous indiquera la cause du rejet (ex: "Invalid customer reference", "GL date is not in an open period", etc.).
4.  **Corrigez et relancez** : En fonction de l'erreur, corrigez les données dans `DKA_IARPAFAC_INTERFACE` (si possible) ou dans les référentiels Oracle (clients, périodes comptables...), puis relancez le programme d'import "AutoInvoice".

Si la **Requête 2** montre un grand nombre de factures manquantes pour une source (`ORIGIN`) spécifique, cela peut indiquer un problème systémique avec ce flux d'intégration.