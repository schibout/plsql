-- =====================================================================
-- Insertion des données manquantes depuis le backup vers la table actuelle
-- =====================================================================
-- Date de création : 06/03/2026
-- Auteur : GitHub Copilot
-- Base de données : Oracle EBS Production
--
-- OBJECTIF : Insérer dans DKA_IARPAFAC_INTERFACE toutes les données qui 
--            existent dans DKA_IARPAFAC_INTERFACE_BKP_05032026 mais pas 
--            dans la table actuelle
--
-- CRITÈRES D'UNICITÉ : TOUTES LES COLONNES MÉTIER
--   (Comparaison de toutes les colonnes sauf IARPAFAC_ID et les dates de création/modification)
--
-- USAGE : 
--   0. Exécuter PARTIE 0 pour créer une sauvegarde avant insertion
--   1. Exécuter PARTIE 1 pour voir les données manquantes
--   2. Exécuter PARTIE 2 pour insérer les données manquantes
--   3. Exécuter PARTIE 3 pour vérifier l'insertion
--
-- ⚠️  ATTENTION : Ce script modifie la table de production DKA_IARPAFAC_INTERFACE
-- =====================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200
SET PAGESIZE 1000

-- =============================================================================
-- PARTIE 0 : SAUVEGARDE DE LA TABLE AVANT INSERTION
-- =============================================================================

PROMPT =====================================================
PROMPT PARTIE 0 : SAUVEGARDE DE LA TABLE ACTUELLE
PROMPT =====================================================
PROMPT
PROMPT Création d'une sauvegarde de la table DKA_IARPAFAC_INTERFACE
PROMPT avant insertion des données manquantes...
PROMPT

-- Suppression de l'ancienne table de sauvegarde si elle existe
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE DKA_IARPAFAC_INTERFACE_BKP_06032026';
    DBMS_OUTPUT.PUT_LINE('✓ Ancienne table de sauvegarde supprimée');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -942 THEN
            DBMS_OUTPUT.PUT_LINE('→ Aucune ancienne table de sauvegarde à supprimer');
        ELSE
            RAISE;
        END IF;
END;
/

-- Création de la nouvelle table de sauvegarde
PROMPT
PROMPT Création de DKA_IARPAFAC_INTERFACE_BKP_06032026...
PROMPT

CREATE TABLE DKA_IARPAFAC_INTERFACE_BKP_06032026 AS
SELECT * FROM DKA_IARPAFAC_INTERFACE;

PROMPT
PROMPT ✓ Sauvegarde créée avec succès !
PROMPT

-- Vérification du nombre de lignes sauvegardées
SELECT 
    'DKA_IARPAFAC_INTERFACE' AS TABLE_SOURCE,
    COUNT(*) AS NB_LIGNES
FROM DKA_IARPAFAC_INTERFACE
UNION ALL
SELECT 
    'DKA_IARPAFAC_INTERFACE_BKP_06032026' AS TABLE_BACKUP,
    COUNT(*) AS NB_LIGNES
FROM DKA_IARPAFAC_INTERFACE_BKP_06032026;

PROMPT
PROMPT ✓ En cas de problème, vous pouvez restaurer avec :
PROMPT   TRUNCATE TABLE DKA_IARPAFAC_INTERFACE;
PROMPT   INSERT INTO DKA_IARPAFAC_INTERFACE SELECT * FROM DKA_IARPAFAC_INTERFACE_BKP_06032026;
PROMPT   COMMIT;
PROMPT
PROMPT =====================================================
PROMPT Fin de PARTIE 0
PROMPT =====================================================


-- =============================================================================
-- PARTIE 1 : IDENTIFICATION DES DONNÉES MANQUANTES
-- =============================================================================

PROMPT =====================================================
PROMPT PARTIE 1 : IDENTIFICATION DES DONNÉES MANQUANTES
PROMPT =====================================================
PROMPT
PROMPT Recherche des enregistrements présents dans le backup mais absents de la table actuelle...
PROMPT

-- Comptage global
SELECT 
    'BACKUP' AS SOURCE,
    COUNT(*) AS NB_LIGNES
FROM DKA_IARPAFAC_INTERFACE_BKP_05032026
UNION ALL
SELECT 
    'ACTUEL' AS SOURCE,
    COUNT(*) AS NB_LIGNES
FROM DKA_IARPAFAC_INTERFACE
ORDER BY SOURCE;

PROMPT
PROMPT Comptage des données manquantes par critères d unicité...
PROMPT

-- Identification des données manquantes
WITH BACKUP_UNIQUE AS (
    -- Données distinctes dans le backup (basées sur TOUTES les colonnes métier)
    SELECT DISTINCT
        INVOICE_NUMBER,
        LINE_NUMBER,
        LINE_TYPE,
        INVOICE_DATE,
        GL_DATE,
        COMPANY_CODE,
        ORIGIN,
        LOCAL_ACCOUNT,
        COUNTER_ACCOUNT,
        AMOUNT,
        DEBIT_CREDIT_IND,
        CURRENCY_CODE,
        CUSTOMER_NAME,
        CUSTOMER_NUMBER,
        DESCRIPTION,
        FIC_IDENT,
        SEGMENT1,
        SEGMENT2,
        SEGMENT3,
        SEGMENT4,
        SEGMENT5,
        SEGMENT6,
        ATTRIBUTE1,
        ATTRIBUTE2,
        ATTRIBUTE3,
        ATTRIBUTE4,
        ATTRIBUTE5,
        ATTRIBUTE6,
        ATTRIBUTE7,
        ATTRIBUTE8,
        ATTRIBUTE9,
        ATTRIBUTE10,
        ATTRIBUTE11,
        ATTRIBUTE12,
        ATTRIBUTE13,
        ATTRIBUTE14,
        ATTRIBUTE15,
        OA_REQUEST_ID,
        ORG_ID
    FROM DKA_IARPAFAC_INTERFACE_BKP_05032026
),
ACTUEL_UNIQUE AS (
    -- Données distinctes dans la table actuelle
    SELECT DISTINCT
        INVOICE_NUMBER,
        LINE_NUMBER,
        LINE_TYPE,
        INVOICE_DATE,
        GL_DATE,
        COMPANY_CODE,
        ORIGIN,
        LOCAL_ACCOUNT,
        COUNTER_ACCOUNT,
        AMOUNT,
        DEBIT_CREDIT_IND,
        CURRENCY_CODE,
        CUSTOMER_NAME,
        CUSTOMER_NUMBER,
        DESCRIPTION,
        FIC_IDENT,
        SEGMENT1,
        SEGMENT2,
        SEGMENT3,
        SEGMENT4,
        SEGMENT5,
        SEGMENT6,
        ATTRIBUTE1,
        ATTRIBUTE2,
        ATTRIBUTE3,
        ATTRIBUTE4,
        ATTRIBUTE5,
        ATTRIBUTE6,
        ATTRIBUTE7,
        ATTRIBUTE8,
        ATTRIBUTE9,
        ATTRIBUTE10,
        ATTRIBUTE11,
        ATTRIBUTE12,
        ATTRIBUTE13,
        ATTRIBUTE14,
        ATTRIBUTE15,
        OA_REQUEST_ID,
        ORG_ID
    FROM DKA_IARPAFAC_INTERFACE
)
SELECT 
    (SELECT COUNT(*) FROM BACKUP_UNIQUE) AS NB_LIGNES_UNIQUES_BACKUP,
    (SELECT COUNT(*) FROM ACTUEL_UNIQUE) AS NB_LIGNES_UNIQUES_ACTUEL,
    (SELECT COUNT(*) FROM BACKUP_UNIQUE B 
     WHERE NOT EXISTS (
         SELECT 1 FROM ACTUEL_UNIQUE A
         WHERE NVL(A.INVOICE_NUMBER,'#') = NVL(B.INVOICE_NUMBER,'#')
           AND NVL(A.LINE_NUMBER,-999) = NVL(B.LINE_NUMBER,-999)
           AND NVL(A.LINE_TYPE,'#') = NVL(B.LINE_TYPE,'#')
           AND NVL(A.INVOICE_DATE, TO_DATE('01/01/1900','DD/MM/YYYY')) = NVL(B.INVOICE_DATE, TO_DATE('01/01/1900','DD/MM/YYYY'))
           AND NVL(A.GL_DATE, TO_DATE('01/01/1900','DD/MM/YYYY')) = NVL(B.GL_DATE, TO_DATE('01/01/1900','DD/MM/YYYY'))
           AND NVL(A.COMPANY_CODE,'#') = NVL(B.COMPANY_CODE,'#')
           AND NVL(A.ORIGIN,'#') = NVL(B.ORIGIN,'#')
           AND NVL(A.LOCAL_ACCOUNT,'#') = NVL(B.LOCAL_ACCOUNT,'#')
           AND NVL(A.COUNTER_ACCOUNT,'#') = NVL(B.COUNTER_ACCOUNT,'#')
           AND NVL(A.AMOUNT,-999999999) = NVL(B.AMOUNT,-999999999)
           AND NVL(A.DEBIT_CREDIT_IND,'#') = NVL(B.DEBIT_CREDIT_IND,'#')
           AND NVL(A.CURRENCY_CODE,'#') = NVL(B.CURRENCY_CODE,'#')
           AND NVL(A.CUSTOMER_NAME,'#') = NVL(B.CUSTOMER_NAME,'#')
           AND NVL(A.CUSTOMER_NUMBER,'#') = NVL(B.CUSTOMER_NUMBER,'#')
           AND NVL(A.DESCRIPTION,'#') = NVL(B.DESCRIPTION,'#')
           AND NVL(A.FIC_IDENT,'#') = NVL(B.FIC_IDENT,'#')
           AND NVL(A.SEGMENT1,'#') = NVL(B.SEGMENT1,'#')
           AND NVL(A.SEGMENT2,'#') = NVL(B.SEGMENT2,'#')
           AND NVL(A.SEGMENT3,'#') = NVL(B.SEGMENT3,'#')
           AND NVL(A.SEGMENT4,'#') = NVL(B.SEGMENT4,'#')
           AND NVL(A.SEGMENT5,'#') = NVL(B.SEGMENT5,'#')
           AND NVL(A.SEGMENT6,'#') = NVL(B.SEGMENT6,'#')
           AND NVL(A.ATTRIBUTE1,'#') = NVL(B.ATTRIBUTE1,'#')
           AND NVL(A.ATTRIBUTE2,'#') = NVL(B.ATTRIBUTE2,'#')
           AND NVL(A.ATTRIBUTE3,'#') = NVL(B.ATTRIBUTE3,'#')
           AND NVL(A.ATTRIBUTE4,'#') = NVL(B.ATTRIBUTE4,'#')
           AND NVL(A.ATTRIBUTE5,'#') = NVL(B.ATTRIBUTE5,'#')
           AND NVL(A.ATTRIBUTE6,'#') = NVL(B.ATTRIBUTE6,'#')
           AND NVL(A.ATTRIBUTE7,'#') = NVL(B.ATTRIBUTE7,'#')
           AND NVL(A.ATTRIBUTE8,'#') = NVL(B.ATTRIBUTE8,'#')
           AND NVL(A.ATTRIBUTE9,'#') = NVL(B.ATTRIBUTE9,'#')
           AND NVL(A.ATTRIBUTE10,'#') = NVL(B.ATTRIBUTE10,'#')
           AND NVL(A.ATTRIBUTE11,'#') = NVL(B.ATTRIBUTE11,'#')
           AND NVL(A.ATTRIBUTE12,'#') = NVL(B.ATTRIBUTE12,'#')
           AND NVL(A.ATTRIBUTE13,'#') = NVL(B.ATTRIBUTE13,'#')
           AND NVL(A.ATTRIBUTE14,'#') = NVL(B.ATTRIBUTE14,'#')
           AND NVL(A.ATTRIBUTE15,'#') = NVL(B.ATTRIBUTE15,'#')
           AND NVL(A.OA_REQUEST_ID,-999) = NVL(B.OA_REQUEST_ID,-999)
           AND NVL(A.ORG_ID,-999) = NVL(B.ORG_ID,-999)
     )) AS NB_LIGNES_MANQUANTES
FROM DUAL;

PROMPT
PROMPT Détail des 20 premières lignes manquantes :
PROMPT

-- Affichage des 20 premières lignes manquantes
SELECT * FROM (
    SELECT 
        BKP.INVOICE_NUMBER,
        BKP.LINE_NUMBER,
        BKP.LINE_TYPE,
        BKP.LOCAL_ACCOUNT,
        BKP.COMPANY_CODE,
        BKP.ORIGIN,
        BKP.FIC_IDENT,
        BKP.AMOUNT,
        TO_CHAR(BKP.CREATION_DATE, 'DD/MM/YYYY HH24:MI:SS') AS CREATION_DATE
    FROM DKA_IARPAFAC_INTERFACE_BKP_05032026 BKP
    WHERE NOT EXISTS (
        SELECT 1 
        FROM DKA_IARPAFAC_INTERFACE ACT
        WHERE NVL(ACT.INVOICE_NUMBER,'#') = NVL(BKP.INVOICE_NUMBER,'#')
          AND NVL(ACT.LINE_NUMBER,-999) = NVL(BKP.LINE_NUMBER,-999)
          AND NVL(ACT.LINE_TYPE,'#') = NVL(BKP.LINE_TYPE,'#')
          AND NVL(ACT.INVOICE_DATE, TO_DATE('01/01/1900','DD/MM/YYYY')) = NVL(BKP.INVOICE_DATE, TO_DATE('01/01/1900','DD/MM/YYYY'))
          AND NVL(ACT.GL_DATE, TO_DATE('01/01/1900','DD/MM/YYYY')) = NVL(BKP.GL_DATE, TO_DATE('01/01/1900','DD/MM/YYYY'))
          AND NVL(ACT.COMPANY_CODE,'#') = NVL(BKP.COMPANY_CODE,'#')
          AND NVL(ACT.ORIGIN,'#') = NVL(BKP.ORIGIN,'#')
          AND NVL(ACT.LOCAL_ACCOUNT,'#') = NVL(BKP.LOCAL_ACCOUNT,'#')
          AND NVL(ACT.COUNTER_ACCOUNT,'#') = NVL(BKP.COUNTER_ACCOUNT,'#')
          AND NVL(ACT.AMOUNT,-999999999) = NVL(BKP.AMOUNT,-999999999)
          AND NVL(ACT.DEBIT_CREDIT_IND,'#') = NVL(BKP.DEBIT_CREDIT_IND,'#')
          AND NVL(ACT.CURRENCY_CODE,'#') = NVL(BKP.CURRENCY_CODE,'#')
          AND NVL(ACT.CUSTOMER_NAME,'#') = NVL(BKP.CUSTOMER_NAME,'#')
          AND NVL(ACT.CUSTOMER_NUMBER,'#') = NVL(BKP.CUSTOMER_NUMBER,'#')
          AND NVL(ACT.DESCRIPTION,'#') = NVL(BKP.DESCRIPTION,'#')
          AND NVL(ACT.FIC_IDENT,'#') = NVL(BKP.FIC_IDENT,'#')
          AND NVL(ACT.SEGMENT1,'#') = NVL(BKP.SEGMENT1,'#')
          AND NVL(ACT.SEGMENT2,'#') = NVL(BKP.SEGMENT2,'#')
          AND NVL(ACT.SEGMENT3,'#') = NVL(BKP.SEGMENT3,'#')
          AND NVL(ACT.SEGMENT4,'#') = NVL(BKP.SEGMENT4,'#')
          AND NVL(ACT.SEGMENT5,'#') = NVL(BKP.SEGMENT5,'#')
          AND NVL(ACT.SEGMENT6,'#') = NVL(BKP.SEGMENT6,'#')
          AND NVL(ACT.ATTRIBUTE1,'#') = NVL(BKP.ATTRIBUTE1,'#')
          AND NVL(ACT.ATTRIBUTE2,'#') = NVL(BKP.ATTRIBUTE2,'#')
          AND NVL(ACT.ATTRIBUTE3,'#') = NVL(BKP.ATTRIBUTE3,'#')
          AND NVL(ACT.ATTRIBUTE4,'#') = NVL(BKP.ATTRIBUTE4,'#')
          AND NVL(ACT.ATTRIBUTE5,'#') = NVL(BKP.ATTRIBUTE5,'#')
          AND NVL(ACT.ATTRIBUTE6,'#') = NVL(BKP.ATTRIBUTE6,'#')
          AND NVL(ACT.ATTRIBUTE7,'#') = NVL(BKP.ATTRIBUTE7,'#')
          AND NVL(ACT.ATTRIBUTE8,'#') = NVL(BKP.ATTRIBUTE8,'#')
          AND NVL(ACT.ATTRIBUTE9,'#') = NVL(BKP.ATTRIBUTE9,'#')
          AND NVL(ACT.ATTRIBUTE10,'#') = NVL(BKP.ATTRIBUTE10,'#')
          AND NVL(ACT.ATTRIBUTE11,'#') = NVL(BKP.ATTRIBUTE11,'#')
          AND NVL(ACT.ATTRIBUTE12,'#') = NVL(BKP.ATTRIBUTE12,'#')
          AND NVL(ACT.ATTRIBUTE13,'#') = NVL(BKP.ATTRIBUTE13,'#')
          AND NVL(ACT.ATTRIBUTE14,'#') = NVL(BKP.ATTRIBUTE14,'#')
          AND NVL(ACT.ATTRIBUTE15,'#') = NVL(BKP.ATTRIBUTE15,'#')
          AND NVL(ACT.OA_REQUEST_ID,-999) = NVL(BKP.OA_REQUEST_ID,-999)
          AND NVL(ACT.ORG_ID,-999) = NVL(BKP.ORG_ID,-999)
    )
    ORDER BY BKP.INVOICE_NUMBER, BKP.LINE_NUMBER
)
WHERE ROWNUM <= 20;

PROMPT
PROMPT =====================================================
PROMPT Fin de PARTIE 1
PROMPT =====================================================


-- =============================================================================
-- PARTIE 2 : INSERTION DES DONNÉES MANQUANTES
-- =============================================================================

PROMPT
PROMPT
PROMPT =====================================================
PROMPT PARTIE 2 : INSERTION DES DONNÉES MANQUANTES
PROMPT =====================================================
PROMPT
PROMPT ⚠️  ATTENTION : Cette opération va modifier la table de production !
PROMPT
PROMPT Pour des raisons de sécurité, le script est en mode COMMENTAIRE.
PROMPT Décommentez le bloc ci-dessous pour exécuter l'insertion.
PROMPT
PROMPT =====================================================

/*
-- Insertion des données manquantes
INSERT INTO DKA_IARPAFAC_INTERFACE (
    IARPAFAC_ID,
    INVOICE_NUMBER,
    LINE_NUMBER,
    LINE_TYPE,
    INVOICE_DATE,
    GL_DATE,
    COMPANY_CODE,
    ORIGIN,
    LOCAL_ACCOUNT,
    COUNTER_ACCOUNT,
    AMOUNT,
    DEBIT_CREDIT_IND,
    CURRENCY_CODE,
    CUSTOMER_NAME,
    CUSTOMER_NUMBER,
    DESCRIPTION,
    FIC_IDENT,
    SEGMENT1,
    SEGMENT2,
    SEGMENT3,
    SEGMENT4,
    SEGMENT5,
    SEGMENT6,
    ATTRIBUTE1,
    ATTRIBUTE2,
    ATTRIBUTE3,
    ATTRIBUTE4,
    ATTRIBUTE5,
    ATTRIBUTE6,
    ATTRIBUTE7,
    ATTRIBUTE8,
    ATTRIBUTE9,
    ATTRIBUTE10,
    ATTRIBUTE11,
    ATTRIBUTE12,
    ATTRIBUTE13,
    ATTRIBUTE14,
    ATTRIBUTE15,
    OA_REQUEST_ID,
    CREATION_DATE,
    CREATED_BY,
    LAST_UPDATE_DATE,
    LAST_UPDATED_BY,
    LAST_UPDATE_LOGIN,
    ORG_ID
)
SELECT 
    APPS.DKA_IARPAFAC_INTERFACE_S.NEXTVAL,  -- Nouveau IARPAFAC_ID
    BKP.INVOICE_NUMBER,
    BKP.LINE_NUMBER,
    BKP.LINE_TYPE,
    BKP.INVOICE_DATE,
    BKP.GL_DATE,
    BKP.COMPANY_CODE,
    BKP.ORIGIN,
    BKP.LOCAL_ACCOUNT,
    BKP.COUNTER_ACCOUNT,
    BKP.AMOUNT,
    BKP.DEBIT_CREDIT_IND,
    BKP.CURRENCY_CODE,
    BKP.CUSTOMER_NAME,
    BKP.CUSTOMER_NUMBER,
    BKP.DESCRIPTION,
    BKP.FIC_IDENT,
    BKP.SEGMENT1,
    BKP.SEGMENT2,
    BKP.SEGMENT3,
    BKP.SEGMENT4,
    BKP.SEGMENT5,
    BKP.SEGMENT6,
    BKP.ATTRIBUTE1,
    BKP.ATTRIBUTE2,
    BKP.ATTRIBUTE3,
    BKP.ATTRIBUTE4,
    BKP.ATTRIBUTE5,
    BKP.ATTRIBUTE6,
    BKP.ATTRIBUTE7,
    BKP.ATTRIBUTE8,
    BKP.ATTRIBUTE9,
    BKP.ATTRIBUTE10,
    BKP.ATTRIBUTE11,
    BKP.ATTRIBUTE12,
    BKP.ATTRIBUTE13,
    BKP.ATTRIBUTE14,
    BKP.ATTRIBUTE15,
    BKP.OA_REQUEST_ID,
    SYSDATE,                -- CREATION_DATE : nouvelle date
    BKP.CREATED_BY,         -- Conserver l'auteur original
    SYSDATE,                -- LAST_UPDATE_DATE : nouvelle date
    BKP.LAST_UPDATED_BY,    -- Conserver l'auteur original
    BKP.LAST_UPDATE_LOGIN,
    BKP.ORG_ID
FROM DKA_IARPAFAC_INTERFACE_BKP_05032026 BKP
WHERE NOT EXISTS (
    -- Vérifier que la ligne n'existe pas déjà selon TOUTES les colonnes métier
    SELECT 1 
    FROM DKA_IARPAFAC_INTERFACE ACT
    WHERE NVL(ACT.INVOICE_NUMBER,'#') = NVL(BKP.INVOICE_NUMBER,'#')
      AND NVL(ACT.LINE_NUMBER,-999) = NVL(BKP.LINE_NUMBER,-999)
      AND NVL(ACT.LINE_TYPE,'#') = NVL(BKP.LINE_TYPE,'#')
      AND NVL(ACT.INVOICE_DATE, TO_DATE('01/01/1900','DD/MM/YYYY')) = NVL(BKP.INVOICE_DATE, TO_DATE('01/01/1900','DD/MM/YYYY'))
      AND NVL(ACT.GL_DATE, TO_DATE('01/01/1900','DD/MM/YYYY')) = NVL(BKP.GL_DATE, TO_DATE('01/01/1900','DD/MM/YYYY'))
      AND NVL(ACT.COMPANY_CODE,'#') = NVL(BKP.COMPANY_CODE,'#')
      AND NVL(ACT.ORIGIN,'#') = NVL(BKP.ORIGIN,'#')
      AND NVL(ACT.LOCAL_ACCOUNT,'#') = NVL(BKP.LOCAL_ACCOUNT,'#')
      AND NVL(ACT.COUNTER_ACCOUNT,'#') = NVL(BKP.COUNTER_ACCOUNT,'#')
      AND NVL(ACT.AMOUNT,-999999999) = NVL(BKP.AMOUNT,-999999999)
      AND NVL(ACT.DEBIT_CREDIT_IND,'#') = NVL(BKP.DEBIT_CREDIT_IND,'#')
      AND NVL(ACT.CURRENCY_CODE,'#') = NVL(BKP.CURRENCY_CODE,'#')
      AND NVL(ACT.CUSTOMER_NAME,'#') = NVL(BKP.CUSTOMER_NAME,'#')
      AND NVL(ACT.CUSTOMER_NUMBER,'#') = NVL(BKP.CUSTOMER_NUMBER,'#')
      AND NVL(ACT.DESCRIPTION,'#') = NVL(BKP.DESCRIPTION,'#')
      AND NVL(ACT.FIC_IDENT,'#') = NVL(BKP.FIC_IDENT,'#')
      AND NVL(ACT.SEGMENT1,'#') = NVL(BKP.SEGMENT1,'#')
      AND NVL(ACT.SEGMENT2,'#') = NVL(BKP.SEGMENT2,'#')
      AND NVL(ACT.SEGMENT3,'#') = NVL(BKP.SEGMENT3,'#')
      AND NVL(ACT.SEGMENT4,'#') = NVL(BKP.SEGMENT4,'#')
      AND NVL(ACT.SEGMENT5,'#') = NVL(BKP.SEGMENT5,'#')
      AND NVL(ACT.SEGMENT6,'#') = NVL(BKP.SEGMENT6,'#')
      AND NVL(ACT.ATTRIBUTE1,'#') = NVL(BKP.ATTRIBUTE1,'#')
      AND NVL(ACT.ATTRIBUTE2,'#') = NVL(BKP.ATTRIBUTE2,'#')
      AND NVL(ACT.ATTRIBUTE3,'#') = NVL(BKP.ATTRIBUTE3,'#')
      AND NVL(ACT.ATTRIBUTE4,'#') = NVL(BKP.ATTRIBUTE4,'#')
      AND NVL(ACT.ATTRIBUTE5,'#') = NVL(BKP.ATTRIBUTE5,'#')
      AND NVL(ACT.ATTRIBUTE6,'#') = NVL(BKP.ATTRIBUTE6,'#')
      AND NVL(ACT.ATTRIBUTE7,'#') = NVL(BKP.ATTRIBUTE7,'#')
      AND NVL(ACT.ATTRIBUTE8,'#') = NVL(BKP.ATTRIBUTE8,'#')
      AND NVL(ACT.ATTRIBUTE9,'#') = NVL(BKP.ATTRIBUTE9,'#')
      AND NVL(ACT.ATTRIBUTE10,'#') = NVL(BKP.ATTRIBUTE10,'#')
      AND NVL(ACT.ATTRIBUTE11,'#') = NVL(BKP.ATTRIBUTE11,'#')
      AND NVL(ACT.ATTRIBUTE12,'#') = NVL(BKP.ATTRIBUTE12,'#')
      AND NVL(ACT.ATTRIBUTE13,'#') = NVL(BKP.ATTRIBUTE13,'#')
      AND NVL(ACT.ATTRIBUTE14,'#') = NVL(BKP.ATTRIBUTE14,'#')
      AND NVL(ACT.ATTRIBUTE15,'#') = NVL(BKP.ATTRIBUTE15,'#')
      AND NVL(ACT.OA_REQUEST_ID,-999) = NVL(BKP.OA_REQUEST_ID,-999)
      AND NVL(ACT.ORG_ID,-999) = NVL(BKP.ORG_ID,-999)
);

-- Affichage du nombre de lignes insérées
PROMPT
PROMPT Nombre de lignes insérées :
SELECT SQL%ROWCOUNT AS NB_LIGNES_INSEREES FROM DUAL;

COMMIT;

PROMPT
PROMPT ✓ COMMIT effectué - Données insérées avec succès !
PROMPT

*/

PROMPT
PROMPT =====================================================
PROMPT Fin de PARTIE 2 (en mode COMMENTAIRE)
PROMPT =====================================================


-- =============================================================================
-- PARTIINVOICE_DATE,
        GL_DATE,
        COMPANY_CODE,
        ORIGIN,
        LOCAL_ACCOUNT,
        COUNTER_ACCOUNT,
        AMOUNT,
        DEBIT_CREDIT_IND,
        CURRENCY_CODE,
        CUSTOMER_NAME,
        CUSTOMER_NUMBER,
        DESCRIPTION,
        FIC_IDENT,
        SEGMENT1,
        SEGMENT2,
        SEGMENT3,
        SEGMENT4,
        SEGMENT5,
        SEGMENT6,
        ATTRIBUTE1,
        ATTRIBUTE2,
        ATTRIBUTE3,
        ATTRIBUTE4,
        ATTRIBUTE5,
        ATTRIBUTE6,
        ATTRIBUTE7,
        ATTRIBUTE8,
        ATTRIBUTE9,
        ATTRIBUTE10,
        ATTRIBUTE11,
        ATTRIBUTE12,
        ATTRIBUTE13,
        ATTRIBUTE14,
        ATTRIBUTE15,
        OA_REQUEST_ID,
        ORG_ID
    FROM DKA_IARPAFAC_INTERFACE_BKP_05032026
),
ACTUEL_UNIQUE AS (
    SELECT DISTINCT
        INVOICE_NUMBER,
        LINE_NUMBER,
        LINE_TYPE,
        INVOICE_DATE,
        GL_DATE,
        COMPANY_CODE,
        ORIGIN,
        LOCAL_ACCOUNT,
        COUNTER_ACCOUNT,
        AMOUNT,
        DEBIT_CREDIT_IND,
        CURRENCY_CODE,
        CUSTOMER_NAME,
        CUSTOMER_NUMBER,
        DESCRIPTION,
        FIC_IDENT,
        SEGMENT1,
        SEGMENT2,
        SEGMENT3,
        SEGMENT4,
        SEGMENT5,
        SEGMENT6,
        ATTRIBUTE1,
        ATTRIBUTE2,
        ATTRIBUTE3,
        ATTRIBUTE4,
        ATTRIBUTE5,
        ATTRIBUTE6,
        ATTRIBUTE7,
        ATTRIBUTE8,
        ATTRIBUTE9,
        ATTRIBUTE10,
        ATTRIBUTE11,
        ATTRIBUTE12,
        ATTRIBUTE13,
        ATTRIBUTE14,
        ATTRIBUTE15,
        OA_REQUEST_ID,
        ORG_ID
    FROM DKA_IARPAFAC_INTERFACE
)
SELECT 
    (SELECT COUNT(*) FROM BACKUP_UNIQUE B 
     WHERE NOT EXISTS (
         SELECT 1 FROM ACTUEL_UNIQUE A
         WHERE NVL(A.INVOICE_NUMBER,'#') = NVL(B.INVOICE_NUMBER,'#')
           AND NVL(A.LINE_NUMBER,-999) = NVL(B.LINE_NUMBER,-999)
           AND NVL(A.LINE_TYPE,'#') = NVL(B.LINE_TYPE,'#')
           AND NVL(A.INVOICE_DATE, TO_DATE('01/01/1900','DD/MM/YYYY')) = NVL(B.INVOICE_DATE, TO_DATE('01/01/1900','DD/MM/YYYY'))
           AND NVL(A.GL_DATE, TO_DATE('01/01/1900','DD/MM/YYYY')) = NVL(B.GL_DATE, TO_DATE('01/01/1900','DD/MM/YYYY'))
           AND NVL(A.COMPANY_CODE,'#') = NVL(B.COMPANY_CODE,'#')
           AND NVL(A.ORIGIN,'#') = NVL(B.ORIGIN,'#')
           AND NVL(A.LOCAL_ACCOUNT,'#') = NVL(B.LOCAL_ACCOUNT,'#')
           AND NVL(A.COUNTER_ACCOUNT,'#') = NVL(B.COUNTER_ACCOUNT,'#')
           AND NVL(A.AMOUNT,-999999999) = NVL(B.AMOUNT,-999999999)
           AND NVL(A.DEBIT_CREDIT_IND,'#') = NVL(B.DEBIT_CREDIT_IND,'#')
           AND NVL(A.CURRENCY_CODE,'#') = NVL(B.CURRENCY_CODE,'#')
           AND NVL(A.CUSTOMER_NAME,'#') = NVL(B.CUSTOMER_NAME,'#')
           AND NVL(A.CUSTOMER_NUMBER,'#') = NVL(B.CUSTOMER_NUMBER,'#')
           AND NVL(A.DESCRIPTION,'#') = NVL(B.DESCRIPTION,'#')
           AND NVL(A.FIC_IDENT,'#') = NVL(B.FIC_IDENT,'#')
           AND NVL(A.SEGMENT1,'#') = NVL(B.SEGMENT1,'#')
           AND NVL(A.SEGMENT2,'#') = NVL(B.SEGMENT2,'#')
           AND NVL(A.SEGMENT3,'#') = NVL(B.SEGMENT3,'#')
           AND NVL(A.SEGMENT4,'#') = NVL(B.SEGMENT4,'#')
           AND NVL(A.SEGMENT5,'#') = NVL(B.SEGMENT5,'#')
           AND NVL(A.SEGMENT6,'#') = NVL(B.SEGMENT6,'#')
           AND NVL(A.ATTRIBUTE1,'#') = NVL(B.ATTRIBUTE1,'#')
           AND NVL(A.ATTRIBUTE2,'#') = NVL(B.ATTRIBUTE2,'#')
           AND NVL(A.ATTRIBUTE3,'#') = NVL(B.ATTRIBUTE3,'#')
           AND NVL(A.ATTRIBUTE4,'#') = NVL(B.ATTRIBUTE4,'#')
           AND NVL(A.ATTRIBUTE5,'#') = NVL(B.ATTRIBUTE5,'#')
           AND NVL(A.ATTRIBUTE6,'#') = NVL(B.ATTRIBUTE6,'#')
           AND NVL(A.ATTRIBUTE7,'#') = NVL(B.ATTRIBUTE7,'#')
           AND NVL(A.ATTRIBUTE8,'#') = NVL(B.ATTRIBUTE8,'#')
           AND NVL(A.ATTRIBUTE9,'#') = NVL(B.ATTRIBUTE9,'#')
           AND NVL(A.ATTRIBUTE10,'#') = NVL(B.ATTRIBUTE10,'#')
           AND NVL(A.ATTRIBUTE11,'#') = NVL(B.ATTRIBUTE11,'#')
           AND NVL(A.ATTRIBUTE12,'#') = NVL(B.ATTRIBUTE12,'#')
           AND NVL(A.ATTRIBUTE13,'#') = NVL(B.ATTRIBUTE13,'#')
           AND NVL(A.ATTRIBUTE14,'#') = NVL(B.ATTRIBUTE14,'#')
           AND NVL(A.ATTRIBUTE15,'#') = NVL(B.ATTRIBUTE15,'#')
           AND NVL(A.OA_REQUEST_ID,-999) = NVL(B.OA_REQUEST_ID,-999)
           AND NVL(A.ORG_ID,-999) = NVL(B.ORG_ID,-999)
    SELECT DISTINCT
        INVOICE_NUMBER,
        LINE_NUMBER,
        LINE_TYPE,
        LOCAL_ACCOUNT,
        COMPANY_CODE,
        ORIGIN,
        FIC_IDENT
    FROM DKA_IARPAFAC_INTERFACE_BKP_05032026
),
ACTUEL_UNIQUE AS (
    SELECT DISTINCT
        INVOICE_NUMBER,
        LINE_NUMBER,
        LINE_TYPE,
        LOCAL_ACCOUNT,
        COMPANY_CODE,
        ORIGIN,
        FIC_IDENT
    FROM DKA_IARPAFAC_INTERFACE
)
SELECT 
    (SELECT COUNT(*) FROM BACKUP_UNIQUE B 
     WHERE NOT EXISTS (
         SELECT 1 FROM ACTUEL_UNIQUE A
         WHERE A.INVOICE_NUMBER = B.INVOICE_NUMBER
           AND A.LINE_NUMBER = B.LINE_NUMBER
           AND A.LINE_TYPE = B.LINE_TYPE
           AND A.LOCAL_ACCOUNT = B.LOCAL_ACCOUNT
           AND A.COMPANY_CODE = B.COMPANY_CODE
           AND A.ORIGIN = B.ORIGIN
           AND A.FIC_IDENT = B.FIC_IDENT
     )) AS NB_LIGNES_ENCORE_MANQUANTES
FROM DUAL;

PROMPT
PROMPT ✓ Si NB_LIGNES_ENCORE_MANQUANTES = 0, alors toutes les données ont été restaurées !
PROMPT
PROMPT =====================================================
PROMPT Fin de PARTIE 3
PROMPT =====================================================