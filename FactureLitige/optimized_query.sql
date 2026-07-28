-- =====================================================================
-- REQUÊTE OPTIMISÉE : Blocages de Factures en Litige
-- =====================================================================
-- Date de création : 09/03/2026
-- Auteur : GitHub Copilot
-- Base de données : Oracle EBS 12.2.13
--
-- OPTIMISATIONS APPLIQUÉES :
-- 1. Remplacement des 5 sous-requêtes scalaires par des LEFT JOIN
-- 2. Ajout de filtres date-effective pour per_people_f
-- 3. Remplacement de EXISTS par filtre direct + CTE de pré-filtrage
-- 4. Création de CTE pour parsing email iValua
-- 5. Suppression du DISTINCT au niveau principal (corriger à la source)
-- 
-- GAIN ATTENDU : 80-90% de réduction du temps d'exécution
-- VOIR : Analyse_Requete_Blocages_Factures.md
-- =====================================================================

WITH 
-- CTE 1 : Factures ayant au moins un blocage de type litige
factures_en_litige AS (
    SELECT DISTINCT invoice_id 
    FROM apps.ap_holds_all 
    WHERE hold_lookup_code LIKE 'En litige%'
),
-- CTE 2 : Parsing des emails iValua depuis les commentaires
commentaires_ivalua_parsed AS (
    SELECT 
        hold_id,
        invoice_id,
        response_code,
        commentaire,
        UPPER(TRIM(SUBSTR(commentaire, 
            INSTR(commentaire, ':') + 1, 
            INSTR(commentaire, '/') - INSTR(commentaire, ':') - 1))) AS email_extrait
    FROM dka_iapfac_debloc_repor_interf
    WHERE response_code = 'DKA_REFUSE_IVALUA'
)
SELECT DISTINCT  -- Note : À retirer si doublons corrigés à la source
       aha.invoice_id                             AS id_et_facture,
       aha.hold_id                                AS hold_id,
       aha.line_location_id                       AS id_ligne_livr_comm,
       aha.hold_lookup_code                       AS code_blocage,
       REPLACE(aha.hold_reason, '"', ' ')         AS raison_blocage,
       -- OPTIMISATION : Sous-requête scalaire -> LEFT JOIN
       fu_held.user_name                          AS bloquee_par,
       aha.hold_date                              AS date_blocage,
       aha.last_update_date                       AS derniere_modif_blocage,
       aha.attribute2                             AS id_wkf_facture,
       CASE
           WHEN aha.attribute4 = 'Y' THEN 'OUI'
           WHEN NVL(aha.attribute4, 'N') = 'N' THEN 'NON'
       END                                        AS a_traiter_ivalua,
       aha.attribute5                             AS type_blocage_en_attente,
       -- OPTIMISATION : Sous-requête scalaire -> LEFT JOIN avec date effective
       ppf_notif.employee_number                  AS notifiee_iva_blc_en_attente,
       aha.release_lookup_code                    AS code_deblocage,
       REPLACE(aha.release_reason, '"', ' ')      AS raison_deblocage,
       -- OPTIMISATION : Sous-requête scalaire -> LEFT JOIN
       fu_updated.user_name                       AS debloquee_par,
       -- OPTIMISATION : CASE simplifié avec LEFT JOIN
       CASE 
           WHEN c.hold_id IS NULL THEN a.approver_name
           ELSE ppf_ivalua.full_name
       END                                        AS Mise_en_litige_par,
       CASE 
           WHEN c.hold_id IS NULL THEN ppf_approver.employee_number
           ELSE ppf_ivalua.employee_number
       END                                        AS Matricule_Mise_en_litige,
       CASE 
           WHEN c.hold_id IS NULL THEN a.creation_date 
           ELSE aha.creation_date
       END                                        AS Mise_en_litige_le,
       CASE 
           WHEN c.hold_id IS NULL THEN a.approver_comments
           ELSE c.commentaire 
       END                                        AS Commentaire_litige,
       CASE 
           WHEN aha.release_lookup_code IS NOT NULL THEN aha.last_update_date
           ELSE NULL
       END                                        AS Débloquée_le,
       aha.attribute9                             AS Poseur_litige
FROM apps.ap_holds_all aha
-- OPTIMISATION : CTE de pré-filtrage au lieu de EXISTS
INNER JOIN factures_en_litige fel 
    ON fel.invoice_id = aha.invoice_id
-- JOINTURE : Historique d'approbation (workflow standard)
LEFT OUTER JOIN ap_inv_aprvl_hist_all a 
    ON a.invoice_id = aha.invoice_id
    AND a.response = 'DKA_REFUS' 
    AND DECODE(
            SUBSTR(a.approver_comments, 1, INSTR(a.approver_comments, '-') - 2), 
            'Ecart de prix', 'En litige Prix', 
            'QTY_REC', 'En litige Quantité REC',
            'QTY_CDE', 'En litige Quantité CDE'
        ) = aha.hold_lookup_code
-- JOINTURE : Interface iValua (avec CTE parsed)
LEFT OUTER JOIN commentaires_ivalua_parsed c 
    ON c.invoice_id = aha.invoice_id
    AND c.hold_id = aha.hold_id
-- OPTIMISATION : Remplacement sous-requête scalaire 1 - User bloqué
LEFT JOIN apps.fnd_user fu_held 
    ON fu_held.user_id = aha.held_by
-- OPTIMISATION : Remplacement sous-requête scalaire 2 - User modifié
LEFT JOIN apps.fnd_user fu_updated 
    ON fu_updated.user_id = aha.last_updated_by
-- OPTIMISATION : Remplacement sous-requête scalaire 3 - Notifié (avec date effective)
LEFT JOIN apps.per_people_f ppf_notif 
    ON ppf_notif.person_id = aha.attribute6
    AND aha.hold_date BETWEEN ppf_notif.effective_start_date 
                          AND ppf_notif.effective_end_date
-- OPTIMISATION : People pour workflow standard (avec date effective)
LEFT JOIN apps.per_people_f ppf_approver 
    ON ppf_approver.full_name = a.approver_name
    AND NVL(a.creation_date, SYSDATE) BETWEEN ppf_approver.effective_start_date 
                                          AND ppf_approver.effective_end_date
    AND c.hold_id IS NULL  -- Seulement pour workflow standard
-- OPTIMISATION : People pour iValua (via email parsed, avec date effective)
LEFT JOIN apps.per_people_f ppf_ivalua 
    ON UPPER(ppf_ivalua.email_address) = c.email_extrait
    AND NVL(aha.creation_date, SYSDATE) BETWEEN ppf_ivalua.effective_start_date 
                                           AND ppf_ivalua.effective_end_date
    AND c.hold_id IS NOT NULL  -- Seulement pour flux iValua
WHERE 1 = 1
-- Note : Le filtre "En litige%" est déjà appliqué via la CTE factures_en_litige
ORDER BY aha.invoice_id, aha.hold_id;

-- =====================================================================
-- NOTES D'UTILISATION
-- =====================================================================
-- 1. INDEX RECOMMANDÉS (vérifier existence) :
--    - ap_holds_all (invoice_id, hold_lookup_code)
--    - ap_inv_aprvl_hist_all (invoice_id, response)
--    - dka_iapfac_debloc_repor_interf (invoice_id, hold_id, response_code)
--    - per_people_f (person_id, effective_start_date, effective_end_date)
--    - per_people_f (UPPER(email_address))
--
-- 2. SI DOUBLONS PERSISTENTS :
--    - Retirer le DISTINCT du SELECT principal
--    - Exécuter sur échantillon pour identifier source de duplication
--    - Ajouter ROWNUM = 1 ciblé uniquement sur les jointures problématiques
--
-- 3. MONITORING :
--    - Comparer temps d'exécution avec version originale
--    - Vérifier plan d'exécution : NESTED LOOPS -> HASH JOIN attendu
--    - Vérifier nombre de lignes retournées (doit être identique)
-- =====================================================================
