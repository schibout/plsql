-- =====================================================================
-- Requête CA Global par Région et par Mois - 2026
-- =====================================================================
-- Date de création : 03/03/2026
-- Auteur : GitHub Copilot
-- Base de données : Oracle EBS
--
-- PROBLÈME RÉSOLU : ORA-01839 - date not valid for month specified
-- CHANGEMENTS PAR RAPPORT À LA VERSION ORIGINALE :
-- 1. Correction date février 2026 : 29/02/2026 → 28/02/2026 (année non bissextile)
-- 2. Suppression des conversions to_date() imbriquées inutiles
-- 3. Nettoyage du code pour améliorer la lisibilité
-- 
-- VOIR : robot/error.txt (erreur d'origine)
-- =====================================================================

WITH final AS (
    SELECT 
        t1.region,
        SUM(Montant_Janvier_2026) Montant_Janvier_2026,
        SUM(Montant_Février_2026) Montant_Février_2026,
        SUM(Montant_Mars_2026) Montant_Mars_2026,
        SUM(Montant_Avril_2026) Montant_Avril_2026,
        SUM(Montant_Mai_2026) Montant_Mai_2026,
        SUM(Montant_Juin_2026) Montant_Juin_2026,
        SUM(Montant_Juillet_2026) Montant_Juillet_2026,
        SUM(Montant_Aout_2026) Montant_Aout_2026,
        SUM(Montant_Septembre_2026) Montant_Septembre_2026,
        SUM(Montant_Octobre_2026) Montant_Octobre_2026,
        SUM(Montant_Novembre_2026) Montant_Novembre_2026,
        SUM(Montant_Décembre_2026) Montant_Décembre_2026
    FROM (
        SELECT 
            gcc.segment2 region,
            -- Janvier 2026
            (SELECT SUM(RCTLGDB.AMOUNT)
             FROM RA_CUST_TRX_LINE_GL_DIST_ALL RCTLGDB,
                  ra_customer_trx_all rctab
             WHERE RCTLGDB.cust_trx_line_gl_dist_id = RCTLGD.cust_trx_line_gl_dist_id
               AND rctab.customer_trx_id = rctlgdb.customer_trx_id
               AND TRUNC(RCTLGD.gl_posted_date) >= TO_DATE('01/01/2026','DD/MM/YYYY')
               AND TRUNC(RCTLGD.gl_posted_date) <= TO_DATE('31/01/2026','DD/MM/YYYY')
            ) AS Montant_Janvier_2026,
            
            -- Février 2026 (CORRIGÉ: 28 jours au lieu de 29)
            (SELECT SUM(RCTLGDB.AMOUNT)
             FROM RA_CUST_TRX_LINE_GL_DIST_ALL RCTLGDB,
                  ra_customer_trx_all rctab
             WHERE RCTLGDB.cust_trx_line_gl_dist_id = RCTLGD.cust_trx_line_gl_dist_id
               AND rctab.customer_trx_id = rctlgdb.customer_trx_id
               AND TRUNC(RCTLGD.gl_posted_date) >= TO_DATE('01/02/2026','DD/MM/YYYY')
               AND TRUNC(RCTLGD.gl_posted_date) <= TO_DATE('28/02/2026','DD/MM/YYYY')
            ) AS Montant_Février_2026,
            
            -- Mars 2026
            (SELECT SUM(RCTLGDB.AMOUNT)
             FROM RA_CUST_TRX_LINE_GL_DIST_ALL RCTLGDB,
                  ra_customer_trx_all rctab
             WHERE RCTLGDB.cust_trx_line_gl_dist_id = RCTLGD.cust_trx_line_gl_dist_id
               AND rctab.customer_trx_id = rctlgdb.customer_trx_id
               AND TRUNC(RCTLGD.gl_posted_date) >= TO_DATE('01/03/2026','DD/MM/YYYY')
               AND TRUNC(RCTLGD.gl_posted_date) <= TO_DATE('31/03/2026','DD/MM/YYYY')
            ) AS Montant_Mars_2026,
            
            -- Avril 2026
            (SELECT SUM(RCTLGDB.AMOUNT)
             FROM RA_CUST_TRX_LINE_GL_DIST_ALL RCTLGDB,
                  ra_customer_trx_all rctab
             WHERE RCTLGDB.cust_trx_line_gl_dist_id = RCTLGD.cust_trx_line_gl_dist_id
               AND rctab.customer_trx_id = rctlgdb.customer_trx_id
               AND TRUNC(RCTLGD.gl_posted_date) >= TO_DATE('01/04/2026','DD/MM/YYYY')
               AND TRUNC(RCTLGD.gl_posted_date) <= TO_DATE('30/04/2026','DD/MM/YYYY')
            ) AS Montant_Avril_2026,
            
            -- Mai 2026
            (SELECT SUM(RCTLGDB.AMOUNT)
             FROM RA_CUST_TRX_LINE_GL_DIST_ALL RCTLGDB,
                  ra_customer_trx_all rctab
             WHERE RCTLGDB.cust_trx_line_gl_dist_id = RCTLGD.cust_trx_line_gl_dist_id
               AND rctab.customer_trx_id = rctlgdb.customer_trx_id
               AND TRUNC(RCTLGD.gl_posted_date) >= TO_DATE('01/05/2026','DD/MM/YYYY')
               AND TRUNC(RCTLGD.gl_posted_date) <= TO_DATE('31/05/2026','DD/MM/YYYY')
            ) AS Montant_Mai_2026,
            
            -- Juin 2026
            (SELECT SUM(RCTLGDB.AMOUNT)
             FROM RA_CUST_TRX_LINE_GL_DIST_ALL RCTLGDB,
                  ra_customer_trx_all rctab
             WHERE RCTLGDB.cust_trx_line_gl_dist_id = RCTLGD.cust_trx_line_gl_dist_id
               AND rctab.customer_trx_id = rctlgdb.customer_trx_id
               AND TRUNC(RCTLGD.gl_posted_date) >= TO_DATE('01/06/2026','DD/MM/YYYY')
               AND TRUNC(RCTLGD.gl_posted_date) <= TO_DATE('30/06/2026','DD/MM/YYYY')
            ) AS Montant_Juin_2026,
            
            -- Juillet 2026
            (SELECT SUM(RCTLGDB.AMOUNT)
             FROM RA_CUST_TRX_LINE_GL_DIST_ALL RCTLGDB,
                  ra_customer_trx_all rctab
             WHERE RCTLGDB.cust_trx_line_gl_dist_id = RCTLGD.cust_trx_line_gl_dist_id
               AND rctab.customer_trx_id = rctlgdb.customer_trx_id
               AND TRUNC(RCTLGD.gl_posted_date) >= TO_DATE('01/07/2026','DD/MM/YYYY')
               AND TRUNC(RCTLGD.gl_posted_date) <= TO_DATE('31/07/2026','DD/MM/YYYY')
            ) AS Montant_Juillet_2026,
            
            -- Août 2026
            (SELECT SUM(RCTLGDB.AMOUNT)
             FROM RA_CUST_TRX_LINE_GL_DIST_ALL RCTLGDB,
                  ra_customer_trx_all rctab
             WHERE RCTLGDB.cust_trx_line_gl_dist_id = RCTLGD.cust_trx_line_gl_dist_id
               AND rctab.customer_trx_id = rctlgdb.customer_trx_id
               AND TRUNC(RCTLGD.gl_posted_date) >= TO_DATE('01/08/2026','DD/MM/YYYY')
               AND TRUNC(RCTLGD.gl_posted_date) <= TO_DATE('31/08/2026','DD/MM/YYYY')
            ) AS Montant_Aout_2026,
            
            -- Septembre 2026
            (SELECT SUM(RCTLGDB.AMOUNT)
             FROM RA_CUST_TRX_LINE_GL_DIST_ALL RCTLGDB,
                  ra_customer_trx_all rctab
             WHERE RCTLGDB.cust_trx_line_gl_dist_id = RCTLGD.cust_trx_line_gl_dist_id
               AND rctab.customer_trx_id = rctlgdb.customer_trx_id
               AND TRUNC(RCTLGD.gl_posted_date) >= TO_DATE('01/09/2026','DD/MM/YYYY')
               AND TRUNC(RCTLGD.gl_posted_date) <= TO_DATE('30/09/2026','DD/MM/YYYY')
            ) AS Montant_Septembre_2026,
            
            -- Octobre 2026
            (SELECT SUM(RCTLGDB.AMOUNT)
             FROM RA_CUST_TRX_LINE_GL_DIST_ALL RCTLGDB,
                  ra_customer_trx_all rctab
             WHERE RCTLGDB.cust_trx_line_gl_dist_id = RCTLGD.cust_trx_line_gl_dist_id
               AND rctab.customer_trx_id = rctlgdb.customer_trx_id
               AND TRUNC(RCTLGD.gl_posted_date) >= TO_DATE('01/10/2026','DD/MM/YYYY')
               AND TRUNC(RCTLGD.gl_posted_date) <= TO_DATE('31/10/2026','DD/MM/YYYY')
            ) AS Montant_Octobre_2026,
            
            -- Novembre 2026
            (SELECT SUM(RCTLGDB.AMOUNT)
             FROM RA_CUST_TRX_LINE_GL_DIST_ALL RCTLGDB,
                  ra_customer_trx_all rctab
             WHERE RCTLGDB.cust_trx_line_gl_dist_id = RCTLGD.cust_trx_line_gl_dist_id
               AND rctab.customer_trx_id = rctlgdb.customer_trx_id
               AND TRUNC(RCTLGD.gl_posted_date) >= TO_DATE('01/11/2026','DD/MM/YYYY')
               AND TRUNC(RCTLGD.gl_posted_date) <= TO_DATE('30/11/2026','DD/MM/YYYY')
            ) AS Montant_Novembre_2026,
            
            -- Décembre 2026 (CORRIGÉ: suppression du to_date() imbriqué)
            (SELECT SUM(RCTLGDB.AMOUNT)
             FROM RA_CUST_TRX_LINE_GL_DIST_ALL RCTLGDB,
                  ra_customer_trx_all rctab
             WHERE RCTLGDB.cust_trx_line_gl_dist_id = RCTLGD.cust_trx_line_gl_dist_id
               AND rctab.customer_trx_id = rctlgdb.customer_trx_id
               AND TRUNC(RCTLGD.gl_posted_date) >= TO_DATE('01/12/2026','DD/MM/YYYY')
               AND TRUNC(RCTLGD.gl_posted_date) <= TO_DATE('31/12/2026','DD/MM/YYYY')
            ) AS Montant_Décembre_2026
            
        FROM hz_cust_accounts hca,
             ra_customer_trx_all rcta,
             hr_operating_units hou,
             HZ_PARTIES hp,
             HZ_CUST_SITE_USES_ALL hcsua,
             RA_CUST_TRX_LINE_GL_DIST_ALL RCTLGD,
             gl_code_combinations_kfv gcc,
             HZ_CUST_ACCT_SITES_ALL hcasa,
             gl_ledgers g,
             RA_BATCH_SOURCES_all rbs,
             fnd_user fu,
             RA_CUST_TRX_TYPES_all rctt
        WHERE 1 = 1
          AND hca.cust_account_id = rcta.BILL_TO_CUSTOMER_ID
          AND hp.PARTY_ID = hca.PARTY_ID
          AND rcta.ORG_ID = hou.organization_id
          AND rbs.org_id = rcta.org_id
          AND rctt.cust_trx_type_id = rcta.cust_trx_type_id
          AND rbs.batch_source_id = rcta.batch_source_id
          AND hcsua.site_use_id = rcta.bill_to_site_use_id
          AND hca.Cust_Account_Id = Hcasa.Cust_Account_Id
          AND hca.party_id = hp.party_id
          AND g.short_name = SUBSTR(hou.Name, 4, 4)
          AND hcsua.cust_acct_site_id = hcasa.cust_acct_site_id(+)
          AND rcta.customer_trx_id = rctlgd.customer_trx_id
          AND rctlgd.code_combination_id = gcc.code_combination_id
          AND rcta.created_by = fu.user_id
          AND rctlgd.account_class = 'REC'
          AND TRUNC(RCTLGD.gl_posted_date) >= TO_DATE('01/01/2026','DD/MM/YYYY')
          AND TRUNC(RCTLGD.gl_posted_date) <= TO_DATE('31/12/2026','DD/MM/YYYY')
          AND SUBSTR(hou.Name, 4, 4) != '0991'
          AND gcc.segment3 = '411100'
          AND gcc.segment2 != 'DOS'
          AND rctt.name NOT IN ('MAN_REMB_AVOIR', 'TRANSF_IRREC')
    ) t1
    GROUP BY t1.region
)
SELECT 
    final.*,
    SYSDATE AS date_extraction
FROM final
ORDER BY region;
