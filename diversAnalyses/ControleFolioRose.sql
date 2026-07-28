-- =====================================================================
-- Requêtes d'interrogation pour le Contrôle Folio (Rose)
-- Vue consolidée sur le Nom du fichier et le Folio
-- =====================================================================

-- 1. INTERROGATION SUR L'INTERFACE EN COURS (GL_INTERFACE)
-- Synthèse des montants et documents par Fichier et Folio
SELECT 
    ATTRIBUTE9 AS "Folio",
    ATTRIBUTE10 AS "Nom_Fichier",
    STATUS AS "Statut_Integration",
    COUNT(DISTINCT REFERENCE4) AS "Nombre_Documents",
    COUNT(*) AS "Nombre_Lignes",
    SUM(ENTERED_DR) AS "Total_Debit",
    SUM(ENTERED_CR) AS "Total_Credit",
    SUM(NVL(ENTERED_DR, 0) - NVL(ENTERED_CR, 0)) AS "Montant_Net"
FROM 
    APPS.GL_INTERFACE
WHERE 
    (ATTRIBUTE9 = :pv_folio OR :pv_folio IS NULL)
    AND (ATTRIBUTE10 = :pv_fichier OR :pv_fichier IS NULL)
GROUP BY 
    ATTRIBUTE9, 
    ATTRIBUTE10,
    STATUS
ORDER BY 
    ATTRIBUTE10, 
    ATTRIBUTE9;

-- 2. INTERROGATION SUR L'HISTORIQUE CONSOLIDÉ (DKA_SCTLFLUX_EAI)
-- Historique des traitements pour un Fichier et un Folio
SELECT 
    CODE_FOLIO,
    FICHIER,
    DATE_EXEC,
    NB_PIECE,
    DEBIT,
    CREDIT,
    (NVL(DEBIT, 0) - NVL(CREDIT, 0)) AS "Montant_Net",
    N_TRAITEMENT AS "Request_ID"
FROM 
    APPS.DKA_SCTLFLUX_EAI
WHERE 
    (CODE_FOLIO = :pv_folio OR :pv_folio IS NULL)
    AND (FICHIER = :pv_fichier OR :pv_fichier IS NULL)
ORDER BY 
    DATE_EXEC DESC;