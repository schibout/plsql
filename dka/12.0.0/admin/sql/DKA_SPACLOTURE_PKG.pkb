CREATE OR REPLACE PACKAGE BODY DKA_SPACLOTURE_PKG
AS

--------------------------------------------------------------------------------------------
-- $Id: DKA_SPACLOTURE_PKG.pkb 271 2008-03-26 10:13:20Z NORDEST\jdequidt $
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SPACLOTURE_PKG.pkb
-- DESCRIPTION       : DKA_SPACLOTURE_PKG package body :
---
--- AUTEUR           : Ulrich VANDEWEGHE (CGEY)
--- DATE DE CREATION : 28/05/2002
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
--------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--- 07/10/2002 BER Procedure pa_check_transfer_to_ap , curseur check_transfer_to_ap_cur
---                 Ajout de la clause : AND invdist.line_type_lookup_code != 'TAX'
---                 pour ne pas prendre les lignes de TVA ayant un code projet renseigne
---                Procedure main : correction gestion des status de periode dans pa_periods_all
--- 31/01/2003 XD  pa_check_draft_revenue : optimisation
---                  Mise en forme du script
--- 01/05/2003 CD  optimisation : suppression du hint dans le package pa_check_draft_revenue
--- 03/06/2003 CD  optimisation : ajout calcul stats sur tables PA
--- 23/07/2003 AD  optimisation : Curseur pa_check_draft_revenue.
--- 25/10/2006 EM  Le calcul des statistiques devient obsolète
--- 21/03/2008 JDE CSP Portabilité
--- 24/11/2016 RBE Migration R12
--- 19/01/2017 RBE artf2086124 
--- 05/09/2017 OBE artf2219268 : SPE053 - Erreur ORA-06502 - Defect Oracle_R12 #902
--------------------------------------------------------------------------------------------

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PRIVEES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PUBLIQUES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


-------------------------------------------------------------------------------------------------------------------
--  Nom           : CHERCHE_PERIOD
--  Description   : Recherche la période à fermer pour une application
--
--  PARAMETRES    :
--     pn_org_id    number
--
--  VALEUR RETOURNEE :
--     pv_errbuf    varchar2
--     pd_start_date    date
--     pd_end_date  date
--     pd_period_name   varchar2
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE cherche_period (
        --pn_sob_id        IN OUT   NUMBER,
        --pn_org_id        IN OUT   NUMBER,
        pv_errbuf        OUT      VARCHAR2,
        pd_start_date    OUT      DATE,
        pd_end_date      OUT      DATE,
        pv_period_name   OUT      VARCHAR2
    )
    IS
        vd_start_date    DATE;
        vd_end_date      DATE;
        vv_period_name   VARCHAR2 (30);
        vv_err           VARCHAR2 (400);
    BEGIN
        pv_errbuf         := NULL;

        -- Recherche de la première période en status ouvert
        --RBE MigR12
        /*
        SELECT   MIN (start_date),
                 end_date,
                 period_name
        INTO     vd_start_date,
                 vd_end_date,
                 vv_period_name
        FROM     gl_period_statuses
        WHERE        application_id = 275
                 AND set_of_books_id = pn_sob_id
                 AND closing_status = 'O'
                 AND ROWNUM = 1
        GROUP BY start_date,
                 end_date,
                 period_name;*/
        
        --RBE MigR12
        SELECT START_DATE,
               END_DATE,
               PERIOD_NAME 
        INTO   vd_start_date,
               vd_end_date,
               vv_period_name
        FROM  PA_PERIODS_ALL  
        WHERE START_DATE IN (
                            SELECT   MIN (PAP.START_DATE)
                            FROM PA_PERIODS_ALL PAP,
                              GL_PERIODS GLP,
                              PA_IMPLEMENTATIONS_ALL PAIMP,
                              GL_LEDGERS GLL,
                              PER_SECURITY_PROFILES_V PSP, 
                              PER_SECURITY_ORGANIZATIONS_V PSO
                            WHERE PAP.GL_PERIOD_NAME       = GLP.PERIOD_NAME
                            AND GLP.PERIOD_SET_NAME        = GLL.PERIOD_SET_NAME
                            AND GLL.LEDGER_ID              = PAIMP.SET_OF_BOOKS_ID
                            AND GLP.ADJUSTMENT_PERIOD_FLAG = 'N'
                            AND PAIMP.ORG_ID               = PAP.ORG_ID
                            AND PAP.STATUS                 = 'O'
                            AND PSO.SECURITY_PROFILE_ID    = PSP.SECURITY_PROFILE_ID
                            AND PSP.SECURITY_PROFILE_ID    = FND_PROFILE.VALUE ('XLA_MO_SECURITY_PROFILE_LEVEL')--YWA artf2073174 --FND_PROFILE.VALUE ('PER_SECURITY_PROFILE_ID')
                            AND PSO.organization_id        = PAP.org_id
                            )
        AND ROWNUM = 1
        ;
                 
        pd_start_date     := vd_start_date;
        pd_end_date       := vd_end_date;
        pv_period_name    := vv_period_name;
        
    EXCEPTION
        WHEN OTHERS
        THEN
            vv_err       := SUBSTR (SQLERRM, 1, 400);
            pv_errbuf    := vv_err;
    END;


-------------------------------------------------------------------------------------------------------------------
--  Nom           : CHERCHE_NEXT_PERIOD
--  Description   : Recherche la période prochaine periode
--
--  PARAMETRES    :
--     pn_sob_id    number
--     pv_period_name   varchar2
--
--  VALEUR RETOURNEE :
--     pv_errbuf    varchar2
--     pd_start_date    date
--     pd_end_date  date
--     pd_period_name   varchar2
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE cherche_next_period (
        --pn_sob_id        IN OUT   NUMBER,
        pv_errbuf        OUT      VARCHAR2,
        pd_start_date    OUT      DATE,
        pd_end_date      OUT      DATE,
        pv_period_name   IN       VARCHAR2,
        pv_next_period_name   IN OUT   VARCHAR2
    )
    IS
        vd_start_date    DATE;
        vd_end_date      DATE;
        vv_period_name   VARCHAR2 (30);
        vv_err           VARCHAR2 (400);
    BEGIN
        pv_errbuf         := NULL;

        -- Recherche de la première période en status ouvert
        SELECT start_date,
               end_date,
               period_name
        INTO   vd_start_date,
               vd_end_date,
               vv_period_name
        FROM   PA_PERIODS_ALL
        WHERE      start_date IN (SELECT end_date + 1
                                  FROM   PA_PERIODS_ALL
                                  WHERE      period_name = pv_period_name )
        AND ROWNUM = 1
                ;

        pd_start_date     := vd_start_date;
        pd_end_date       := vd_end_date;
        pv_next_period_name    := vv_period_name;
    EXCEPTION
        WHEN OTHERS
        THEN
            vv_err       := SUBSTR (SQLERRM, 1, 400);
            pv_errbuf    := vv_err;
    END;


-------------------------------------------------------------------------------------------------------------------
--  Nom           : pa_check_transfer_to_ap
--  Description   : Recherche si toutes Les factures AP sont transférées dans PA
--
--  PARAMETRES    :
--      pd_start_date   date
--      pd_end_date     date
--      pv_period_name  varchar2
--      pn_org_id       number
--
--  VALEUR RETOURNEE :
--      pv_errbuf       varchar2
--      pv_status       varchar2
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE pa_check_transfer_to_ap (
        pd_start_date    IN       DATE,
        pd_end_date      IN       DATE,
        pv_period_name   IN       VARCHAR2,
        pn_org_id        IN       NUMBER,
        --pn_sob_id        IN       NUMBER,
        pv_errbuf        OUT      VARCHAR2,
        pv_status        OUT      VARCHAR2
    )
    IS
        vv_uo_name           VARCHAR2 (100);
        vv_segment1          VARCHAR2 (20);
        vv_invoice_num       VARCHAR2 (100); -- OBE artf2219268
        vd_accounting_date   DATE;
        vn_amount            NUMBER;

        /*
        CURSOR check_transfer_to_ap_cur
        IS
            SELECT   hou.NAME,
                     pa.segment1,
                     inv.invoice_num,
                     TRUNC (invdist.accounting_date),
                     SUM (invdist.amount)
            FROM     gl_sets_of_books glsob,
                     po_vendors vend,
                     ap_invoice_distributions_all invdist,
                     ap_invoices_all inv,
                     pa_projects_all pa,
                     hr_all_organization_units hou
            WHERE        vend.vendor_id = inv.vendor_id
                     AND inv.invoice_id = invdist.invoice_id
                     AND invdist.project_id = pa.project_id
                     AND hou.organization_id = pn_org_id 
                     AND pa.org_id = hou.organization_id
                     AND inv.org_id = hou.organization_id
                     AND invdist.org_id = hou.organization_id
                     AND (   inv.invoice_type_lookup_code <> 'EXPENSE REPORT'
                          OR (    inv.invoice_type_lookup_code = 'EXPENSE REPORT'
                              AND vend.employee_id IS NOT NULL
                             )
                         )
                     AND invdist.project_id > 0
                     AND NVL (inv.SOURCE, 'XXX') <> 'Oracle Project Accounting'
                     AND invdist.pa_addition_flag NOT IN ('Y', 'Z', 'T', 'E')
                     AND invdist.posted_flag || '' = 'Y'
                     AND invdist.line_type_lookup_code != 'TAX'
                     AND glsob.set_of_books_id = invdist.set_of_books_id
                     AND glsob.set_of_books_id = pn_sob_id
                     AND invdist.accounting_date BETWEEN pd_start_date AND pd_end_date
            GROUP BY hou.NAME,
                     pa.segment1,
                     inv.invoice_num,
                     TRUNC (invdist.accounting_date)
            ORDER BY hou.NAME,
                     pa.segment1,
                     inv.invoice_num;
                     */

        CURSOR check_transfer_to_ap_cur
        IS
            SELECT   NAME,
                     SEGMENT1,
                     INVOICE_NUM,
                     ACCOUNTING_DATE,
                     SUM (AMOUNT)
            FROM (
                     SELECT INV.INVOICE_num,
                            hou.name,
                            PPA.SEGMENT1 ,
                            TRUNC (INVDIST.ACCOUNTING_DATE) ACCOUNTING_DATE,
                            invdist.amount amount
                         FROM
                         AP_INVOICE_DISTRIBUTIONS_ALL  INVDIST,
                         AP_INVOICES_ALL    INV,
                         PO_VENDORS VEND,
                         PA_IMPLEMENTATIONS_ALL IMP /* Bug13853995 */
                         ,PA_PROJECTS_ALL PPA --RBE
                         ,hr_all_organization_units hou --RBE
                         WHERE
                         INVDIST.PROJECT_ID  + 0 > 0
                         AND INVDIST.PROJECT_ID = PPA.PROJECT_ID  --RBE
                         AND hou.organization_id = INVDIST.ORG_ID --RBE
                         AND INVDIST.PA_ADDITION_FLAG || '' IN
                            ( 'A','B','C','D','I','J','K','M','N','O','P','Q','S','V','X')
                         AND INVDIST.POSTED_FLAG || '' = 'Y'
                         --AND INVDIST.accounting_date BETWEEN :pa_start_date AND :pa_end_date
                         AND INVDIST.accounting_date BETWEEN pd_start_date AND pd_end_date --RBE
                         
                         -- start 12i MOAC changes
                         -- and NVL(INVDIST.ORG_ID,-99) = NVL(:ctrl.org_id,-99)
                         --AND INVDIST.ORG_ID = :ctrl.org_id
                         AND INVDIST.ORG_ID = pn_org_id  --RBE
                         -- end 12i MOAC changes
                         AND INVDIST.INVOICE_ID  + 0 = INV.INVOICE_ID
                         AND INV.VENDOR_ID + 0 = VEND.VENDOR_ID
                         AND INVDIST.ORG_ID =IMP.ORG_ID              /* Bug13853995 */
                         AND NVL(invdist.tax_recoverable_flag,'N') = 'N'  /* Modified for bug 8688420*/
                         AND (((inv.invoice_type_lookup_code = 'EXPENSE REPORT'
                              --  AND inv.source IN ('XPENSEXPRESS','MANUAL INVOICE ENTRY','SELFSERVICE')  /* Commented  for bug#13016531 */
                                     AND inv.source IN ('XpenseXpress','Manual Invoice Entry','SelfService')  /*Added for bug#13016531*/
                                AND (vend.employee_id IS NOT NULL
                                OR Nvl(inv.paid_on_behalf_employee_id,0) > 0))
                             OR (inv.invoice_type_lookup_code IN ('STANDARD','CREDIT','MIXED')
                                AND inv.source IN ('CREDIT CARD','BOTH PAY')
                                AND Nvl(inv.paid_on_behalf_employee_id,0) > 0))
                             OR EXISTS (SELECT 1
                                        FROM   po_distributions po , AP_INVOICE_DISTRIBUTIONS_ALL APD
                                        WHERE  inv.paid_on_behalf_employee_id IS NULL
					AND APD.invoice_distribution_id              = invdist.invoice_distribution_id
                                        --AND invdist.po_distribution_id = po.po_distribution_id (+)
					AND APD.po_distribution_id                   = PO.po_distribution_id(+)
                                        AND Nvl(po.destination_type_code,'EXPENSE') = 'EXPENSE'
                                        AND inv.invoice_type_lookup_code NOT IN( 'EXPENSE REPORT','PREPAYMENT') -- added Prepayment for bug 9775901
					AND INVDIST.line_type_lookup_code <> 'PREPAY'     --for bug 13818502
                                        AND (Nvl(inv.source,'XX') NOT IN ('ORACLE PROJECT ACCOUNTING','PA_IC_INVOICES','PA_COST_ADJUSTMENTS')
                                             OR invdist.line_type_lookup_code = 'TAX')))                               
                          AND INV.SOURCE <> 'Oracle Project Accounting'
                        
                           /* Srart Bug13853995 */
                      AND (pa_nl_installed.is_nl_installed = 'N'
                       OR ( pa_nl_installed.is_nl_installed = 'Y'
                         AND NOT EXISTS
                            (SELECT 'X'
                             FROM po_distributions_all pod,mtl_system_items si, po_lines_all pol
                             WHERE pod.po_distribution_id   = INVDIST.po_distribution_id
                              AND pod.po_line_id             = pol.po_line_id
                              AND si.inventory_item_id       = pol.item_id
                              AND si.comms_nl_trackable_flag = 'Y'
                              AND (si.organization_id        = pod.org_id
                               OR si.organization_id  IN
                                (SELECT NVL(ship_to_organization_id,-9999)
                                 FROM po_line_locations_all pll
                                 WHERE pll.po_header_id = pod.po_header_id
                                 AND pll.po_line_id     = pod.po_line_id)))
                                 AND NOT EXISTS
                                (SELECT 'X'
                                 FROM ap_invoice_distributions_all apdist, po_distributions_all pod, mtl_system_items si, po_lines_all pol
                                 WHERE INVDIST.CHARGE_APPLICABLE_TO_DIST_ID = apdist.INVOICE_DISTRIBUTION_ID
                                  AND apdist.po_distribution_id           = pod.po_distribution_id
                                  AND pod.po_line_id                      = pol.po_line_id
                                  AND si.inventory_item_id                = pol.item_id
                                  AND si.comms_nl_trackable_flag          = 'Y'
                                  AND (si.organization_id                 = pod.org_id
                                    OR si.organization_id IN
                                      (SELECT NVL(ship_to_organization_id,-9999)
                                        FROM po_line_locations_all pll
                                        WHERE pll.po_header_id = pod.po_header_id
                                       AND pll.po_line_id     = pod.po_line_id)))))

                                           /* End Bug13853995 */
UNION ALL
                /*Bug 13602288: SELF ASSESSED TAX CHANGES*/
                SELECT  INV.INVOICE_num,
                        hou.name,
                        PPA.SEGMENT1,
                        TRUNC (INVDIST.ACCOUNTING_DATE),
                        invdist.amount
                           FROM 
                           AP_SELF_ASSESSED_TAX_DIST_ALL INVDIST,
                           AP_INVOICES_ALL INV,
                           PO_VENDORS VEND,
                           PA_PROJECTS_ALL PPA, --RBE
                           hr_all_organization_units hou --RBE
                           WHERE
                           INVDIST.PROJECT_ID + 0 > 0
                           AND INVDIST.PA_ADDITION_FLAG || '' IN
                           ('A','B','C','D','I','J','K','M','N','O','P','Q','S','V','X')
                           AND INVDIST.POSTED_FLAG|| ' ' = 'Y'
                           --AND INVDIST.accounting_date between :pa_start_date and :pa_end_date --RBE
                           AND INVDIST.accounting_date BETWEEN pd_start_date AND pd_end_date
                           --AND INVDIST.ORG_ID = :ctrl.org_id --RBE
                           AND INVDIST.ORG_ID = pn_org_id  --RBE
                           AND INVDIST.INVOICE_ID + 0 = INV.INVOICE_ID                               
	                         AND INV.VENDOR_ID + 0 = VEND.VENDOR_ID
                           AND Nvl(invdist.tax_recoverable_flag, 'N') = 'N'
                           AND (((inv.invoice_type_lookup_code = 'EXPENSE REPORT'
                               AND inv.source IN ('XpenseXpress','Manual Invoice Entry','SelfService')
                                   AND (vend.employee_id IS NOT NULL
                                   OR Nvl (inv.paid_on_behalf_employee_id,0) > 0))
                                   OR (inv.invoice_type_lookup_code IN ('STANDARD','CREDIT','MIXED')
                                    AND inv.source IN ('CREDIT CARD','BOTH PAY')
                                    AND Nvl (inv.paid_on_behalf_employee_id,0) > 0))
                                  OR EXISTS (SELECT 1
                                             FROM po_distributions po, AP_INVOICE_DISTRIBUTIONS_ALL APD
                                             WHERE inv.paid_on_behalf_employee_id IS NULL
					     AND APD.invoice_distribution_id              = invdist.invoice_distribution_id
                                             --AND invdist.po_distribution_id = po.po_distribution_id (+)
					     AND APD.po_distribution_id                   = PO.po_distribution_id(+)
                                             AND Nvl (po.destination_type_code,'EXPENSE') = 'EXPENSE'
                                             AND inv.invoice_type_lookup_code NOT IN ('EXPENSE REPORT','PREPAYMENT')
					     AND INVDIST.line_type_lookup_code <> 'PREPAY'     --for bug13818502
                                             AND (Nvl(inv.source,'XX') NOT IN ('ORACLE PROJECT ACCOUNTING','PA_IC_INVOICES','PA_COST_ADJUSTMENTS')
                                                  OR invdist.line_type_lookup_code = 'TAX')))
                                 AND INV.SOURCE <> 'Oracle Project Accounting'
                                   
                                    /* Srart Bug13853995 */
                                   AND (pa_nl_installed.is_nl_installed = 'N'
                                    OR ( pa_nl_installed.is_nl_installed = 'Y'
                                  AND NOT EXISTS
                                         (SELECT 'X'
                                           FROM po_distributions_all pod,mtl_system_items si, po_lines_all pol
                                          WHERE pod.po_distribution_id   = INVDIST.po_distribution_id
                                            AND pod.po_line_id             = pol.po_line_id
                                            AND si.inventory_item_id       = pol.item_id
                                            AND si.comms_nl_trackable_flag = 'Y'
                                            AND (si.organization_id        = pod.org_id
                                             OR si.organization_id  IN
                                                (SELECT NVL(ship_to_organization_id,-9999)
                                                  FROM po_line_locations_all pll
                                                  WHERE pll.po_header_id = pod.po_header_id
                                                   AND pll.po_line_id     = pod.po_line_id)))
                                                   AND NOT EXISTS
                                                     (SELECT 'X'
                                                      FROM AP_SELF_ASSESSED_TAX_DIST_ALL apdist, po_distributions_all pod, mtl_system_items si, po_lines_all pol
                                                      WHERE INVDIST.CHARGE_APPLICABLE_TO_DIST_ID = apdist.INVOICE_DISTRIBUTION_ID
                                                       AND apdist.po_distribution_id           = pod.po_distribution_id
                                                       AND pod.po_line_id                      = pol.po_line_id
                                                       AND si.inventory_item_id                = pol.item_id
                                                       AND si.comms_nl_trackable_flag          = 'Y'
                                                       AND (si.organization_id                 = pod.org_id
                                                        OR si.organization_id IN
                                                       (SELECT NVL(ship_to_organization_id,-9999)
                                                          FROM po_line_locations_all pll
                                                          WHERE pll.po_header_id = pod.po_header_id
                                                          AND pll.po_line_id     = pod.po_line_id)))))
                                                 /* End Bug13853995 */
            )
            GROUP BY NAME,
                     SEGMENT1,
                     INVOICE_NUM,
                     ACCOUNTING_DATE
            ;



    BEGIN
        OPEN check_transfer_to_ap_cur;
        FETCH check_transfer_to_ap_cur INTO vv_uo_name,
                                            vv_segment1,
                                            vv_invoice_num,
                                            vd_accounting_date,
                                            vn_amount;

        IF check_transfer_to_ap_cur%FOUND
        THEN
            pv_errbuf    := dka_tools_pkg.get_message ('PA', 'PA_PERIOD_PEND_AP_INV');
            dka_tools_pkg.put_outdebug_message (pv_errbuf);
            dka_tools_pkg.put_outdebug_message ('Uo Name : '|| vv_uo_name);
            dka_tools_pkg.put_outdebug_message ('Projet : '|| vv_segment1);
            dka_tools_pkg.put_outdebug_message ('Facture : '|| vv_invoice_num);
            dka_tools_pkg.put_outdebug_message ('Date : '|| TO_CHAR (vd_accounting_date, 'DD/MM/RRRR'));
            dka_tools_pkg.put_outdebug_message ('Montant '|| TO_CHAR (vn_amount, '999G999G999G999D99'));
            dka_tools_pkg.put_outdebug_message ('');

            LOOP
                FETCH check_transfer_to_ap_cur INTO vv_uo_name,
                                                    vv_segment1,
                                                    vv_invoice_num,
                                                    vd_accounting_date,
                                                    vn_amount;
                EXIT WHEN check_transfer_to_ap_cur%NOTFOUND;
                --pv_errbuf    := dka_tools_pkg.get_message ('PA', 'PA_PERIOD_PEND_AP_INV');
                dka_tools_pkg.put_outdebug_message ('Uo Name : '|| vv_uo_name);
                dka_tools_pkg.put_outdebug_message ('Projet : '|| vv_segment1);
                dka_tools_pkg.put_outdebug_message ('Facture : '|| vv_invoice_num);
                dka_tools_pkg.put_outdebug_message ('Date : '|| TO_CHAR (vd_accounting_date, 'DD/MM/RRRR'));
                dka_tools_pkg.put_outdebug_message ('Montant '|| TO_CHAR (vn_amount, '999G999G999G999D99'));
                dka_tools_pkg.put_outdebug_message ('');
            END LOOP;

            pv_status    := 'KO';
        ELSE
            pv_status    := 'OK';
        END IF;

        CLOSE check_transfer_to_ap_cur;
    END pa_check_transfer_to_ap;


-------------------------------------------------------------------------------------------------------------------
--  Nom           : pa_check_cost_transfer_to_ap
--  Description   : Recherche si tous les couts sont transférés dans AP ( module PA )
--
--  PARAMETRES    :
--      pd_start_date   date
--      pd_end_date     date
--      pv_period_name  varchar2
--      pn_org_id       number
--
--  VALEUR RETOURNEE :
--      pv_errbuf   varchar2
--      pv_status   varchar2
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE pa_check_cost_transfer_to_ap (
        pd_start_date    IN       DATE,
        pd_end_date      IN       DATE,
        pv_period_name   IN       VARCHAR2,
        pn_org_id        IN       NUMBER,    /* CSP Portabilité */
        --pn_sob_id        IN       NUMBER,
        pv_errbuf        OUT      VARCHAR2,
        pv_status        OUT      VARCHAR2
    )
    IS
        vv_uo_name            VARCHAR2 (100);
        vv_segment1           VARCHAR2 (30);
        vv_expenditure_type   VARCHAR2 (30);
        vd_expenditure_date   DATE;
        vn_quantity           NUMBER;
        vv_rejet              VARCHAR2 (30);
        vv_cdl_exception_type VARCHAR2 (30);

/* --RBE Migration R12
        CURSOR check_cost_transfer_to_ap_cur
        IS
            SELECT hou.NAME,
                   pa.segment1,
                   ei.expenditure_type,
                   TRUNC (ei.expenditure_item_date),
                   ei.quantity,
                   cdl.transfer_rejection_reason
            FROM   pa_cost_distribution_lines_all cdl,
                   pa_expenditure_items_all ei,
                   pa_projects_all pa,
                   pa_implementations_all imp,
                   hr_all_organization_units hou
            WHERE      hou.organization_id = pn_org_id 
                   AND ei.org_id = hou.organization_id
                   AND cdl.org_id = hou.organization_id
                   AND imp.org_id = hou.organization_id
                   AND pa.project_id = ei.project_id
                   AND pa.org_id = hou.organization_id
                   AND ei.expenditure_item_id = cdl.expenditure_item_id
                   AND cdl.transfer_status_code IN ('P', 'T', 'R', 'X')
                   AND ei.system_linkage_function IN ('ER', 'VI')
                   AND cdl.line_type = 'R'
                   AND cdl.pa_date BETWEEN pd_start_date AND pd_end_date
                   AND imp.set_of_books_id = pn_sob_id
            UNION
            SELECT hou.NAME,
                   pa.segment1,
                   ei.expenditure_type,
                   TRUNC (ei.expenditure_item_date),
                   ei.quantity,
                   cdl.transfer_rejection_reason
            FROM   pa_expenditure_items_all ei,
                   pa_projects_all pa,
                   pa_cost_distribution_lines_all cdl,
                   pa_implementations_all imp,
                   gl_je_categories c,
                   gl_je_sources s,
                   gl_interface INT,
                   hr_all_organization_units hou
            WHERE      hou.organization_id = pn_org_id  
                   AND ei.org_id = hou.organization_id
                   AND cdl.org_id = hou.organization_id
                   AND imp.org_id = hou.organization_id
                   AND ei.project_id = pa.project_id
                   AND pa.org_id = hou.organization_id
                   AND ei.expenditure_item_id = cdl.expenditure_item_id
                   AND INT.user_je_category_name = c.user_je_category_name
                   AND c.je_category_name IN ('Labor Cost', 'Usage Cost', 'Total Burdened Cost')
                   AND INT.user_je_source_name = s.user_je_source_name
                   AND s.je_source_name = 'Project Accounting'
                   AND INT.set_of_books_id = imp.set_of_books_id
                   AND INT.set_of_books_id = pn_sob_id
                   AND INT.reference21 = cdl.batch_name
                   AND INT.code_combination_id = cdl.dr_code_combination_id
                   AND cdl.pa_date BETWEEN pd_start_date AND pd_end_date
            UNION
            SELECT hou.NAME,
                   pa.segment1,
                   ei.expenditure_type,
                   TRUNC (ei.expenditure_item_date),
                   ei.quantity,
                   cdl.transfer_rejection_reason
            FROM   pa_cost_distribution_lines_all cdl,
                   pa_expenditure_items_all ei,
                   pa_projects_all pa,
                   pa_implementations_all imp,
                   hr_all_organization_units hou
            WHERE      hou.organization_id = pn_org_id    
                   AND ei.org_id = hou.organization_id
                   AND cdl.org_id = hou.organization_id
                   AND imp.org_id = hou.organization_id
                   AND pa.org_id = hou.organization_id
                   AND pa.project_id = ei.project_id
                   AND cdl.transfer_status_code IN ('P', 'R', 'X', 'T')
                   AND ei.expenditure_item_id = cdl.expenditure_item_id
                   AND (   (    ei.system_linkage_function IN ('ST', 'OT', 'BTC')
                            AND imp.interface_labor_to_gl_flag = 'Y'
                           )
                        OR (    ei.system_linkage_function = 'USG'
                            AND imp.interface_usage_to_gl_flag = 'Y'
                           )
                       )
                   AND imp.set_of_books_id = pn_sob_id
                   AND cdl.pa_date BETWEEN pd_start_date AND pd_end_date
            UNION
            SELECT hou.NAME,
                   pa.segment1,
                   ei.expenditure_type,
                   TRUNC (ei.expenditure_item_date),
                   ei.quantity,
                   cdl.transfer_rejection_reason
            FROM   pa_cost_distribution_lines cdl,
                   pa_expenditure_items ei,
                   pa_projects_all pa,
                   hr_all_organization_units hou
            WHERE      hou.organization_id = pn_org_id   
                   AND ei.org_id = hou.organization_id
                   AND cdl.org_id = hou.organization_id
                   AND pa.project_id = ei.project_id
                   AND pa.org_id = hou.organization_id
                   AND cdl.burden_sum_source_run_id = -999
                   AND ei.expenditure_item_id = cdl.expenditure_item_id
                   AND cdl.pa_date BETWEEN pd_start_date AND pd_end_date;
                   */
--RBE Migration R12
					  CURSOR check_cost_transfer_to_ap_cur
					  IS
					  SELECT hou.NAME,
                   pa.segment1,
                   cdl.expenditure_type,
                   TRUNC (cdl.expenditure_item_date),
                   cdl.quantity,
                   cdl.transfer_rejection_reason,
                   cdl.cdl_exception_type
						FROM 	pa_cost_exceptions_sum_v cdl,
						      pa_tasks pt,
						      pa_projects_all pa,
						      hr_all_organization_units hou
						WHERE	cdl.pa_date BETWEEN pd_start_date AND	pd_end_date
						AND   cdl.cdl_exception_type  IN ('P','I','B')
						AND   pt.task_id = cdl.task_id
						AND   pt.project_id = pa.project_id
						AND   cdl.org_id = hou.organization_id
						AND   cdl.org_id = pn_org_id;

    BEGIN

        OPEN check_cost_transfer_to_ap_cur;
        FETCH check_cost_transfer_to_ap_cur INTO vv_uo_name,
                                                 vv_segment1,
                                                 vv_expenditure_type,
                                                 vd_expenditure_date,
                                                 vn_quantity,
                                                 vv_rejet,
                                                 vv_cdl_exception_type; --RBE

        IF (check_cost_transfer_to_ap_cur%FOUND)
        THEN
            IF vv_cdl_exception_type = 'B' THEN
              pv_errbuf    := dka_tools_pkg.get_message ('PA', 'PA_PERIOD_PEND_BURDEN_CDL');
            ELSE
              pv_errbuf    := dka_tools_pkg.get_message ('PA', 'PA_PERIOD_PEND_LOAD_CDL_GL'); --PA_PERIOD_PEND_CDL_AP
            END IF;
            dka_tools_pkg.put_outdebug_message (pv_errbuf);
            dka_tools_pkg.put_outdebug_message ('Uo name : '|| vv_uo_name);
            dka_tools_pkg.put_outdebug_message ('Projet : '|| vv_segment1);
            dka_tools_pkg.put_outdebug_message ('Type de dépense : '|| vv_expenditure_type);
            dka_tools_pkg.put_outdebug_message ('Date de la dépense :'|| TO_CHAR (vd_expenditure_date, 'DD/MM/RRRR'));
            dka_tools_pkg.put_outdebug_message ('Quantité :'|| TO_CHAR (vn_quantity));
            dka_tools_pkg.put_outdebug_message ('Rejet :'|| vv_rejet);
            dka_tools_pkg.put_outdebug_message ('');

            LOOP
                FETCH check_cost_transfer_to_ap_cur INTO vv_uo_name,
                                                         vv_segment1,
                                                         vv_expenditure_type,
                                                         vd_expenditure_date,
                                                         vn_quantity,
                                                         vv_rejet,
                                                         vv_cdl_exception_type;--RBE
                EXIT WHEN check_cost_transfer_to_ap_cur%NOTFOUND;
--                IF vv_cdl_exception_type = 'B' THEN
--                  pv_errbuf    := dka_tools_pkg.get_message ('PA', 'PA_PERIOD_PEND_BURDEN_CDL');
--                ELSE
--                  pv_errbuf    := dka_tools_pkg.get_message ('PA', 'PA_PERIOD_PEND_LOAD_CDL_GL'); --PA_PERIOD_PEND_CDL_AP
--                END IF;
                dka_tools_pkg.put_outdebug_message ('Uo name : '|| vv_uo_name);
                dka_tools_pkg.put_outdebug_message ('Projet : '|| vv_segment1);
                dka_tools_pkg.put_outdebug_message ('Type de dépense : '|| vv_expenditure_type);
                dka_tools_pkg.put_outdebug_message ('Date de la dépense :'|| TO_CHAR (vd_expenditure_date, 'DD/MM/RRRR'));
                dka_tools_pkg.put_outdebug_message ('Quantité :'|| TO_CHAR (vn_quantity));
                dka_tools_pkg.put_outdebug_message ('Rejet :'|| vv_rejet);
                dka_tools_pkg.put_outdebug_message ('');
            END LOOP;

            pv_status    := 'KO';
        ELSE
            pv_status    := 'OK';
        END IF;

        CLOSE check_cost_transfer_to_ap_cur;
    END pa_check_cost_transfer_to_ap;


-------------------------------------------------------------------------------------------------------------------
--  Nom           : pa_check_cross_charge
--  Description   : Recherche si toutes les charges sont dans GL ( module PA )
--
--  PARAMETRES    :
--      pd_start_date   date
--      pd_end_date     date
--  pv_period_name  varchar2
--  pn_sob_id   number
--
--  VALEUR RETOURNEE :
--      pv_errbuf   varchar2
--  pv_status   varchar2
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE pa_check_cross_charge (
        pd_start_date    IN       DATE,
        pd_end_date      IN       DATE,
        pv_period_name   IN       VARCHAR2,
        pn_org_id        IN       NUMBER,   /* CSP Portabilité */
        --pn_sob_id        IN       NUMBER,
        pv_errbuf        OUT      VARCHAR2,
        pv_status        OUT      VARCHAR2
    )
    IS
        vv_uo_name    VARCHAR2 (100);
        vv_segment1   VARCHAR2 (30);
        vv_pa_date    DATE;
        vn_amount     NUMBER;
        vv_rejet      VARCHAR2 (30);

/*
        CURSOR check_cross_charge_cur
        IS
            SELECT   otl.NAME,
                     pp.segment1,
                     TRUNC (cdl.pa_date),
                     SUM (cdl.amount),
                     cdl.transfer_rejection_code
            FROM     pa_cc_dist_lines_all cdl,
                     pa_expenditure_items_all ei,
                     pa_expenditures_all EXP,
                     pa_projects_all pp,
                     hr_all_organization_units otl
            WHERE        ei.expenditure_item_id = cdl.expenditure_item_id
                     AND EXP.expenditure_id = ei.expenditure_id
                     AND cdl.project_id = pp.project_id
                     AND otl.organization_id = pn_org_id 
                     AND ei.recvr_org_id = otl.organization_id
                     AND cdl.org_id = otl.organization_id
                     AND pp.org_id = otl.organization_id
                     AND EXP.org_id = otl.organization_id
                     AND cdl.transfer_status_code IN ('P', 'R')
                     AND cdl.pa_date BETWEEN pd_start_date AND pd_end_date
            GROUP BY otl.NAME,
                     pp.segment1,
                     TRUNC (cdl.pa_date),
                     cdl.transfer_rejection_code
            UNION ALL
            SELECT   otl.NAME,
                     pp.segment1,
                     TRUNC (cdl.pa_date),
                     SUM (cdl.amount),
                     cdl.transfer_rejection_code
            FROM     pa_cc_dist_lines cdl,
                     pa_expenditure_items ei,
                     pa_expenditures_all EXP,
                     pa_projects_all pp,
                     hr_all_organization_units otl,
                     gl_je_categories c,
                     gl_je_sources s,
                     gl_interface INT
            WHERE        ei.expenditure_item_id = cdl.expenditure_item_id
                     AND EXP.expenditure_id = ei.expenditure_id
                     AND cdl.project_id = pp.project_id
                     AND otl.organization_id = pn_org_id   
                     AND ei.recvr_org_id = otl.organization_id
                     AND EXP.org_id = otl.organization_id
                     AND cdl.org_id = otl.organization_id
                     AND pp.org_id = otl.organization_id
                     AND cdl.transfer_status_code = 'A'
                     AND cdl.pa_date BETWEEN pd_start_date AND pd_end_date
                     AND INT.code_combination_id = cdl.dr_code_combination_id
                     AND INT.reference21 = cdl.gl_batch_name
                     AND INT.user_je_source_name = s.user_je_source_name
                     AND INT.user_je_category_name = c.user_je_category_name
                     AND s.je_source_name = 'Project Accounting'
                     AND c.je_category_name IN ('BORROWED_AND_LENT', 'PROVIDER_COST_RECLASS')
            GROUP BY otl.NAME,
                     pp.segment1,
                     TRUNC (cdl.pa_date),
                     cdl.transfer_rejection_code;
*/
 		  --rbe -- 
        CURSOR check_cross_charge_cur
        IS
            SELECT   hou.name,
                     pp.segment1,
                     TRUNC (ccd.pa_date),
                     SUM (ccd.amount),
                     ccd.EXCEPTION_CODE
             /* CCD not Accepted and in given PA period */
            FROM 	pa_cc_exceptions_sum_v ccd,
                  pa_projects_all pp,
                  hr_all_organization_units hou
            				WHERE   ccd.ccd_exception_type = 'I'	-- SLA Enhancement : ccd_exception_type is 'I' for the ccds for which the accounting events are still not created in SLA	
            				AND ccd.project_id = pp.project_id 
            				AND ccd.org_id = hou.organization_id
                    AND pp.org_id  = hou.organization_id
                    AND ccd.org_id = pn_org_id
            				AND	ccd.pa_date BETWEEN pd_start_date
            				AND	pd_end_date
            			and exists
            			(select null from pa_cc_dist_lines_all
            				where expenditure_item_id = ccd.expenditure_item_id
            				and line_num = ccd.cdl_line_num
            				and (line_type = 'BL' or
            				     (
            					line_type = 'PC' and reference_1 in 
            					(select draft_invoice_detail_id from pa_draft_invoice_Details_all
            					where expenditure_item_id = ccd.expenditure_item_id
            					and draft_invoice_num is not null)
            				     )
            				    )
            			)
            			GROUP BY hou.name,
                           pp.segment1,
                           TRUNC (ccd.pa_date),
                           ccd.EXCEPTION_CODE
                  ;
    BEGIN
        OPEN check_cross_charge_cur;
        FETCH check_cross_charge_cur INTO vv_uo_name,
                                          vv_segment1,
                                          vv_pa_date,
                                          vn_amount,
                                          vv_rejet;

        IF check_cross_charge_cur%FOUND
        THEN
            pv_errbuf    := dka_tools_pkg.get_message ('PA', 'PA_PERIOD_PEND_LOAD_CCD_GL'); -- PA_PERIOD_PEND_ACCPT_CCD_GL
            dka_tools_pkg.put_outdebug_message (pv_errbuf);
            dka_tools_pkg.put_outdebug_message ('Uo name : '|| vv_uo_name);
            dka_tools_pkg.put_outdebug_message ('Projet : '|| vv_segment1);
            dka_tools_pkg.put_outdebug_message ('Date : '|| TO_CHAR (vv_pa_date, 'DD/MM/RRRR'));
            dka_tools_pkg.put_outdebug_message ('Montant '|| TO_CHAR (vn_amount, '999G999G999G999D99'));
            dka_tools_pkg.put_outdebug_message ('Rejt '|| vv_rejet);
            dka_tools_pkg.put_outdebug_message ('');

            LOOP
                FETCH check_cross_charge_cur INTO vv_uo_name,
                                                  vv_segment1,
                                                  vv_pa_date,
                                                  vn_amount,
                                                  vv_rejet;
                EXIT WHEN check_cross_charge_cur%NOTFOUND;
                --pv_errbuf    := dka_tools_pkg.get_message ('PA', 'PA_PERIOD_PEND_LOAD_CCD_GL'); -- PA_PERIOD_PEND_ACCPT_CCD_GL
                dka_tools_pkg.put_outdebug_message ('Uo name : '|| vv_uo_name);
                dka_tools_pkg.put_outdebug_message ('Projet : '|| vv_segment1);
                dka_tools_pkg.put_outdebug_message ('Date : '|| TO_CHAR (vv_pa_date, 'DD/MM/RRRR'));
                dka_tools_pkg.put_outdebug_message ('Montant '|| TO_CHAR (vn_amount, '999G999G999G999D99'));
                dka_tools_pkg.put_outdebug_message ('Rejt '|| vv_rejet);
                dka_tools_pkg.put_outdebug_message ('');
            END LOOP;

            pv_status    := 'KO';
        ELSE
            pv_status    := 'OK';
        END IF;

        CLOSE check_cross_charge_cur;
    END pa_check_cross_charge;


-------------------------------------------------------------------------------------------------------------------
--  Nom           : pa_check_draft_revenue
--  Description   : Recherche si tous draft revenue sont OK ( module PA )
--
--  PARAMETRES    :
--      pd_start_date   date
--      pd_end_date     date
--  pv_period_name  varchar2
--  pn_sob_id   number
--
--  VALEUR RETOURNEE :
--      pv_errbuf   varchar2
--  pv_status   varchar2
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE pa_check_draft_revenue (
        pd_start_date    IN       DATE,
        pd_end_date      IN       DATE,
        pv_period_name   IN       VARCHAR2,
        pn_org_id        IN       NUMBER,    /* CSP Portabilité */ 
        --pn_sob_id        IN       NUMBER,
        pv_errbuf        OUT      VARCHAR2,
        pv_status        OUT      VARCHAR2
    )
    IS
        vv_uo_name    VARCHAR2 (100);
        vv_segment1   VARCHAR2 (30);
        vd_pa_date    DATE;
        vn_amount     NUMBER;
        vv_rejet      VARCHAR2 (30);
        vv_ADJUSTING_REVENUE_FLAG VARCHAR2 (30);
        
-- AD -- coupure de la seconde partie du curseur et ajout d'un union 
          CURSOR check_draft_revenue_cur
        IS
        /*  SELECT   hou.NAME,
                     pp.segment1,
                     dr.pa_date,
                     SUM (dri.amount),
                     dr.transfer_rejection_reason
            FROM     pa_draft_revenues_all dr,
                     pa_draft_revenue_items dri,
                     pa_implementations_all imp,
                     pa_projects_all pp,
                     hr_all_organization_units hou
            WHERE        imp.interface_revenue_to_gl_flag = 'Y'
                     AND dr.org_id = hou.organization_id
                     AND imp.org_id = hou.organization_id
                     AND imp.set_of_books_id = pn_sob_id
                     AND pp.org_id = hou.organization_id
                     AND pp.project_id = dr.project_id
                     AND dr.transfer_status_code IN ('P', 'R', 'X', 'T')   \* DRIVE FROM INDEX ON TRX STATUS *\
                     AND dr.draft_revenue_num = dri.draft_revenue_num
                     AND dr.project_id = dri.project_id
                     AND dr.pa_date BETWEEN pd_start_date AND pd_end_date
                     AND dr.generation_error_flag != 'Y'
            GROUP BY hou.NAME,
                     pp.segment1,
                     dr.pa_date,
                     dr.transfer_rejection_reason
            UNION
            SELECT   hou.NAME,
                     pp.segment1,
                     dr.pa_date,
                     SUM (dri.amount),
                     dr.transfer_rejection_reason
            FROM     pa_draft_revenues_all dr,
                     pa_draft_revenue_items dri,
                     pa_projects_all pp,
                     hr_all_organization_units hou
            WHERE        dr.draft_revenue_num = dri.draft_revenue_num
                     AND dr.org_id = hou.organization_id
                     AND pp.project_id = dr.project_id
                     AND pp.org_id = hou.organization_id
                     AND dr.project_id = dri.project_id
                     AND dr.pa_date BETWEEN pd_start_date AND pd_end_date
                     AND EXISTS ( SELECT 1
                                  FROM   pa_implementations_all imp,
                                         gl_je_categories c,
                                         gl_je_sources s,
                                         gl_interface INT,
                                         hr_all_organization_units hou2
                                  WHERE      imp.interface_revenue_to_gl_flag = 'Y'
                                         AND imp.org_id = hou2.organization_id
                                         AND imp.set_of_books_id = pn_sob_id
                                         AND INT.user_je_category_name = c.user_je_category_name
                                         AND c.je_category_name = 'Revenue'
                                         AND INT.user_je_source_name = s.user_je_source_name
                                         AND s.je_source_name = 'Project Accounting'
                                         AND INT.set_of_books_id = imp.set_of_books_id
                                         AND (   INT.reference21 = dr.unearned_batch_name
                                              OR INT.reference21 = dr.unbilled_batch_name
                                             ))
            GROUP BY hou.NAME,
                     pp.segment1,
                     dr.pa_date,
                     dr.transfer_rejection_reason;  */
  
  --RBE MigR12           
/*            SELECT   hou.NAME,
                     pp.segment1,
                     dr.pa_date,
                     SUM (dri.amount),
                     dr.transfer_rejection_reason
            FROM     pa_draft_revenues_all dr,
                     pa_draft_revenue_items dri,
                     pa_implementations_all imp,
                     pa_projects_all pp,
                     hr_all_organization_units hou
            WHERE        imp.interface_revenue_to_gl_flag = 'Y'
                     AND hou.organization_id = pn_org_id     
                     AND dr.org_id = hou.organization_id
                     AND imp.org_id = hou.organization_id
                     AND imp.set_of_books_id = pn_sob_id
                     AND pp.org_id = hou.organization_id
                     AND pp.project_id = dr.project_id
                     AND dr.transfer_status_code IN ('P', 'R', 'X', 'T')   -- DRIVE FROM INDEX ON TRX STATUS
                     AND dr.draft_revenue_num = dri.draft_revenue_num
                     AND dr.project_id = dri.project_id
                     AND dr.pa_date BETWEEN pd_start_date AND pd_end_date
                     AND dr.generation_error_flag != 'Y'
            GROUP BY hou.NAME,
                     pp.segment1,
                     dr.pa_date,
                     dr.transfer_rejection_reason
            UNION
            SELECT   hou.NAME,
                     pp.segment1,
                     dr.pa_date,
                     SUM (dri.amount),
                     dr.transfer_rejection_reason
            FROM     pa_draft_revenues_all dr,
                     pa_draft_revenue_items dri,
                     pa_projects_all pp,
                     hr_all_organization_units hou
            WHERE        dr.draft_revenue_num = dri.draft_revenue_num
                     AND hou.organization_id = pn_org_id      -- CSP Portabilité 
                     AND dr.org_id = hou.organization_id
                     AND pp.project_id = dr.project_id
                     AND pp.org_id = hou.organization_id
                     AND dr.project_id = dri.project_id
                     AND dr.pa_date BETWEEN pd_start_date AND pd_end_date
                     AND dr.unearned_batch_name IN ( SELECT INT.reference21
                                                     FROM   pa_implementations_all imp,
                                                            gl_je_categories c,
                                                            gl_je_sources s,
                                                            gl_interface INT,
                                                            hr_all_organization_units hou2
                                                     WHERE  imp.interface_revenue_to_gl_flag = 'Y'
                                                     AND    hou2.organization_id = pn_org_id      -- CSP Portabilité 
                                                     AND    imp.org_id = hou2.organization_id
                                                     AND    imp.set_of_books_id = pn_sob_id
                                                     AND    INT.user_je_category_name = c.user_je_category_name
                                                     AND    c.je_category_name = 'Revenue'
                                                     AND    INT.user_je_source_name = s.user_je_source_name
                                                     AND    s.je_source_name = 'Project Accounting'
                                                     AND    INT.set_of_books_id = imp.set_of_books_id
                                                    )
            GROUP BY hou.NAME,
                     pp.segment1,
                     dr.pa_date,
                     dr.transfer_rejection_reason
            UNION
            SELECT   hou.NAME,
                     pp.segment1,
                     dr.pa_date,
                     SUM (dri.amount),
                     dr.transfer_rejection_reason
            FROM     pa_draft_revenues_all dr,
                     pa_draft_revenue_items dri,
                     pa_projects_all pp,
                     hr_all_organization_units hou
            WHERE        dr.draft_revenue_num = dri.draft_revenue_num
                     AND hou.organization_id = pn_org_id      -- CSP Portabilité 
                     AND dr.org_id = hou.organization_id
                     AND pp.project_id = dr.project_id
                     AND pp.org_id = hou.organization_id
                     AND dr.project_id = dri.project_id
                     AND dr.pa_date BETWEEN pd_start_date AND pd_end_date
                     AND dr.unbilled_batch_name IN ( SELECT INT.reference21
                                                     FROM   pa_implementations_all imp,
                                                            gl_je_categories c,
                                                            gl_je_sources s,
                                                            gl_interface INT,
                                                            hr_all_organization_units hou2
                                                     WHERE  imp.interface_revenue_to_gl_flag = 'Y'
                                                     AND    hou2.organization_id = pn_org_id      -- CSP Portabilité 
                                                     AND    imp.org_id = hou2.organization_id
                                                     AND    imp.set_of_books_id = pn_sob_id
                                                     AND    INT.user_je_category_name = c.user_je_category_name
                                                     AND    c.je_category_name = 'Revenue'
                                                     AND    INT.user_je_source_name = s.user_je_source_name
                                                     AND    s.je_source_name = 'Project Accounting'
                                                     AND    INT.set_of_books_id = imp.set_of_books_id
                                                    )
            GROUP BY hou.NAME,
                     pp.segment1,
                     dr.pa_date,
                     dr.transfer_rejection_reason
;
*/

--RBE MigR12
            SELECT   hou.NAME,
                     pp.segment1,
                     dr.pa_date,
                     SUM (dri.amount),
                     dr.transfer_rejection_reason,
                     NVL(DR.ADJUSTING_REVENUE_FLAG,'N') 
            FROM  PA_DRAFT_REVENUES_ALL   DR,
                  pa_draft_revenue_items dri,
                  PA_IMPLEMENTATIONS  IMP,
                  PA_PROJECTS_ALL     PP,
                  hr_all_organization_units hou
            WHERE IMP.INTERFACE_REVENUE_TO_GL_FLAG = 'Y'
              AND DR.TRANSFER_STATUS_CODE IN ('P','R','X','T')
              AND DR.GENERATION_ERROR_FLAG <> 'Y'
              --AND NVL(DR.ADJUSTING_REVENUE_FLAG,'N')  = 'Y'
              --AND NVL(DR.ADJUSTING_REVENUE_FLAG,'N') <> 'Y'
              AND nvl(DR.PA_DATE,DR.PA_DATE) BETWEEN pd_start_date AND pd_end_date
              AND hou.organization_id = pn_org_id 
              AND dr.org_id     = hou.organization_id
              AND pp.project_id = dr.project_id
              AND pp.org_id     = hou.organization_id
              AND dr.project_id = dri.project_id
              AND dr.draft_revenue_num = dri.draft_revenue_num
            GROUP BY hou.NAME,
                     pp.segment1,
                     dr.pa_date,
                     dr.transfer_rejection_reason,
                     NVL(DR.ADJUSTING_REVENUE_FLAG,'N'); 

-- AD --                     
    BEGIN
        OPEN check_draft_revenue_cur;
        FETCH check_draft_revenue_cur INTO vv_uo_name,
                                           vv_segment1,
                                           vd_pa_date,
                                           vn_amount,
                                           vv_rejet,
                                           vv_ADJUSTING_REVENUE_FLAG;

        IF (check_draft_revenue_cur%FOUND)
        THEN
            IF vv_ADJUSTING_REVENUE_FLAG = 'Y' THEN
              pv_errbuf    := dka_tools_pkg.get_message ('PA', 'PA_PERIOD_PEND_RDL');
            ELSE
              pv_errbuf    := dka_tools_pkg.get_message ('PA', 'PA_PERIOD_PEND_ADJ_RDL');
            END IF;
            dka_tools_pkg.put_outdebug_message (pv_errbuf);
            dka_tools_pkg.put_outdebug_message ('Uo name : '|| vv_uo_name);
            dka_tools_pkg.put_outdebug_message ('Projet : '|| vv_segment1);
            dka_tools_pkg.put_outdebug_message ('Date : '|| TO_CHAR (vd_pa_date, 'DD/MM/RRRR'));
            dka_tools_pkg.put_outdebug_message ('Montant '|| TO_CHAR (vn_amount, '999G999G999G999D99'));
            dka_tools_pkg.put_outdebug_message ('Rejet : '|| vv_rejet);
            dka_tools_pkg.put_outdebug_message ('');

            LOOP
                FETCH check_draft_revenue_cur INTO vv_uo_name,
                                                   vv_segment1,
                                                   vd_pa_date,
                                                   vn_amount,
                                                   vv_rejet,
                                                   vv_ADJUSTING_REVENUE_FLAG;
                EXIT WHEN check_draft_revenue_cur%NOTFOUND;
--                IF vv_ADJUSTING_REVENUE_FLAG = 'Y' THEN
--                  pv_errbuf    := dka_tools_pkg.get_message ('PA', 'PA_PERIOD_PEND_RDL');
--                ELSE
--                  pv_errbuf    := dka_tools_pkg.get_message ('PA', 'PA_PERIOD_PEND_ADJ_RDL');
--                END IF;
                dka_tools_pkg.put_outdebug_message ('Uo name : '|| vv_uo_name);
                dka_tools_pkg.put_outdebug_message ('Projet : '|| vv_segment1);
                dka_tools_pkg.put_outdebug_message ('Date : '|| TO_CHAR (vd_pa_date, 'DD/MM/RRRR'));
                dka_tools_pkg.put_outdebug_message ('Montant '|| TO_CHAR (vn_amount, '999G999G999G999D99'));
                dka_tools_pkg.put_outdebug_message ('Rejet : '|| vv_rejet);
                dka_tools_pkg.put_outdebug_message ('');
            END LOOP;

            pv_status    := 'KO';
        ELSE
            pv_status    := 'OK';
        END IF;

        CLOSE check_draft_revenue_cur;
    END pa_check_draft_revenue;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : pa_check_pm
--  Description   : Recherche si toutes les transactions dans Project Manufacturing sont OK
--
--  PARAMETRES    :
--      pd_start_date   date
--      pd_end_date     date
--      pv_period_name  varchar2
--      pn_org_id       number
--
--  VALEUR RETOURNEE :
--      pv_errbuf   varchar2
--      pv_status   varchar2
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE pa_check_cst_pm (
        pd_start_date    IN       DATE,
        pd_end_date      IN       DATE,
        pv_period_name   IN       VARCHAR2,
        pn_org_id        IN       NUMBER,
        pv_errbuf        OUT      VARCHAR2,
        pv_status        OUT      VARCHAR2
    )
    IS
        vv_uo_name    VARCHAR2 (100);
        vv_segment1   VARCHAR2 (30);
        vd_pa_date    DATE;
        vn_amount     NUMBER;
        vv_rejet      VARCHAR2 (100);
        
        CURSOR check_cst_pm 
        IS  
        SELECT       org.organization_name,
                     pp.segment1,
                     cst.transaction_date,
                     to_char(cst.exception_code)
            FROM    cst_pm_pending_txn_v cst,  /* InvMfg transaction not interfaced to PA*/
                    pa_implementations_all imp,
                    org_organization_definitions org,
                    pa_projects_all pp
            WHERE   transaction_date BETWEEN pd_start_date  /*Bug# 3840484:Replaced pa_date by transaction_Date*/
            AND     pd_end_date
            AND    cst.organization_id = org.organization_id
            AND    pp.org_id = org.organization_id
            AND    cst.project_id = pp.project_id
            -- start 12i MOAC changes
            -- AND    nvl(org.operating_unit,-99) = nvl(imp.org_id, -99)
            AND    org.operating_unit = imp.org_id
            AND    cst.organization_id = pn_org_id
             AND  NOT EXISTS
                  ( SELECT 1 FROM gms_implementations_all WHERE org_id=imp.org_id AND enabled ='Y') 
                  /* Bug 17530628 : Added above not exist condition because grants does not support inventory Transaction*/
  
 			UNION      /*Added for bug 4165751 */
			(SELECT        hou.name,
                     pti.project_number,
                     pti.expenditure_item_date,
                     to_char(pa_exception_reasons_pub.get_exception_text('MFG_EXCP','CCRTIN',NULL,'R'))  Exception_Reason_Pmg 
			 from pa_transaction_interface pti,
			      hr_all_organization_units hou
					where  pti.transaction_source = 'Inventory Misc' 
					and    pti.transaction_status_code in ('P','R') 
					and    pti.system_linkage = 'INV' 
					and    pti.org_id = pn_org_id  
					and    hou.organization_id = pti.org_id 
					and    pti.expenditure_item_date BETWEEN pd_start_date
                                       AND pd_end_date
			)
       ;


    BEGIN
        OPEN check_cst_pm;
        FETCH check_cst_pm INTO  vv_uo_name,
                                 vv_segment1,
                                 vd_pa_date,
                                 vv_rejet;

        IF (check_cst_pm%FOUND)
        THEN
            pv_errbuf    := dka_tools_pkg.get_message ('PA', 'PA_PERIOD_PEND_INVENTORY_TXN');
            dka_tools_pkg.put_outdebug_message (pv_errbuf);
            dka_tools_pkg.put_outdebug_message ('Uo name : '|| vv_uo_name);
            dka_tools_pkg.put_outdebug_message ('Projet : '|| vv_segment1);
            dka_tools_pkg.put_outdebug_message ('Date : '|| TO_CHAR (vd_pa_date, 'DD/MM/RRRR'));
            dka_tools_pkg.put_outdebug_message ('Rejet : '|| vv_rejet);
            dka_tools_pkg.put_outdebug_message ('');

            LOOP
                FETCH check_cst_pm INTO  vv_uo_name,
                                         vv_segment1,
                                         vd_pa_date,
                                         vv_rejet;
                EXIT WHEN check_cst_pm%NOTFOUND;
                --pv_errbuf    := dka_tools_pkg.get_message ('PA', 'PA_PERIOD_PEND_INVENTORY_TXN');
                dka_tools_pkg.put_outdebug_message ('Uo name : '|| vv_uo_name);
                dka_tools_pkg.put_outdebug_message ('Projet : '|| vv_segment1);
                dka_tools_pkg.put_outdebug_message ('Date : '|| TO_CHAR (vd_pa_date, 'DD/MM/RRRR'));
                dka_tools_pkg.put_outdebug_message ('Rejet : '|| vv_rejet);
                dka_tools_pkg.put_outdebug_message ('');
            END LOOP;

            pv_status    := 'KO';
        ELSE
            pv_status    := 'OK';
        END IF;

        CLOSE check_cst_pm;
    END pa_check_cst_pm;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : pa_check_trans_uncosted
--  Description   : Recherche si tous les coûts des mouvements ont été imputés
--
--  PARAMETRES    :
--      pd_start_date   date
--      pd_end_date     date
--      pv_period_name  varchar2
--      pn_org_id       number
--
--  VALEUR RETOURNEE :
--      pv_errbuf   varchar2
--      pv_status   varchar2
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE pa_check_trans_uncosted (
        pd_start_date    IN       DATE,
        pd_end_date      IN       DATE,
        pv_period_name   IN       VARCHAR2,
        pn_org_id        IN       NUMBER,
        pv_errbuf        OUT      VARCHAR2,
        pv_status        OUT      VARCHAR2
    )
    IS
        vv_uo_name            VARCHAR2 (100);
        vv_segment1           VARCHAR2 (30);
        vv_expenditure_type   VARCHAR2 (30);
        vd_expenditure_date   DATE;
        vn_quantity           NUMBER;
        vv_rejet              VARCHAR2 (30);
        
        CURSOR check_trans_uncosted 
        IS  
        SELECT     hou.NAME,
                   pa.segment1,
                   pei.expenditure_type,
                   TRUNC (pei.expenditure_item_date),
                   pei.quantity,
                   pei.cost_dist_rejection_code
        FROM    pa_expenditure_items_all pei,
                pa_projects_all pa,
                hr_all_organization_units hou
        WHERE   (
                  (pei.system_linkage_function <> 'PJ' and pei.expenditure_item_date Between pd_start_date  AND     pd_end_date)
                or
                  (pei.system_linkage_function = 'PJ' and nvl(pei.prvdr_accrual_date,pei.expenditure_item_date) Between pd_start_date  AND     pd_end_date)
                )
        AND     pei.cost_distributed_flag = 'N'
        AND     pei.org_id = pn_org_id
        AND     pa.org_id = pei.org_id
        AND     pa.project_id = pei.project_id
        AND     pei.org_id = hou.organization_id
        ;

    BEGIN
        OPEN check_trans_uncosted;
        FETCH check_trans_uncosted INTO  vv_uo_name,
                                         vv_segment1,
                                         vv_expenditure_type,
                                         vd_expenditure_date,
                                         vn_quantity,
                                         vv_rejet;

        IF (check_trans_uncosted%FOUND)
        THEN
            pv_errbuf    := dka_tools_pkg.get_message ('PA', 'PA_PERIOD_PEND_UNCOSTED');
            dka_tools_pkg.put_outdebug_message (pv_errbuf);
            dka_tools_pkg.put_outdebug_message ('Uo name : '|| vv_uo_name);
            dka_tools_pkg.put_outdebug_message ('Projet : '|| vv_segment1);
            dka_tools_pkg.put_outdebug_message ('Type de dépense : '|| vv_expenditure_type);
            dka_tools_pkg.put_outdebug_message ('Date de la dépense :'|| TO_CHAR (vd_expenditure_date, 'DD/MM/RRRR'));
            dka_tools_pkg.put_outdebug_message ('Quantité :'|| TO_CHAR (vn_quantity));
            dka_tools_pkg.put_outdebug_message ('Rejet :'|| vv_rejet);
            dka_tools_pkg.put_outdebug_message ('');

            LOOP
                FETCH check_trans_uncosted INTO  vv_uo_name,
                                                 vv_segment1,
                                                 vv_expenditure_type,
                                                 vd_expenditure_date,
                                                 vn_quantity,
                                                 vv_rejet;
                EXIT WHEN check_trans_uncosted%NOTFOUND;
                --pv_errbuf    := dka_tools_pkg.get_message ('PA', 'PA_PERIOD_PEND_UNCOSTED');
                dka_tools_pkg.put_outdebug_message ('Uo name : '|| vv_uo_name);
                dka_tools_pkg.put_outdebug_message ('Projet : '|| vv_segment1);
                dka_tools_pkg.put_outdebug_message ('Type de dépense : '|| vv_expenditure_type);
                dka_tools_pkg.put_outdebug_message ('Date de la dépense :'|| TO_CHAR (vd_expenditure_date, 'DD/MM/RRRR'));
                dka_tools_pkg.put_outdebug_message ('Quantité :'|| TO_CHAR (vn_quantity));
                dka_tools_pkg.put_outdebug_message ('Rejet :'|| vv_rejet);
                dka_tools_pkg.put_outdebug_message ('');
            END LOOP;

            pv_status    := 'KO';
        ELSE
            pv_status    := 'OK';
        END IF;

        CLOSE check_trans_uncosted;
    END pa_check_trans_uncosted;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : main
--  Description   : Procédure principale enchaînant l'ensemble des autres procédures
--
--  PARAMETRES    :
--  pv_errbuf                       Entrée/Sortie           retour de message eventuel
--      pn_retcode                      Sortie                  status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE main (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    )
    IS
        vn_org_id        NUMBER; /* CSP Portabilité */
        vn_sob_id        NUMBER;
        vv_mesg          VARCHAR2 (4000);
        vd_start_date    DATE;
        vd_end_date      DATE;
        vd_next_start_date    DATE;
        vd_next_end_date      DATE;
        vv_period_name   VARCHAR2 (30)   := NULL;
        vv_next_period_name VARCHAR2 (30)   := NULL;
        vn_count         NUMBER          := 0;
        vv_status        VARCHAR2 (2);
        vn_period_num    NUMBER;
        vn_user_id       NUMBER;
        rec_error        EXCEPTION;
        
      	/*CURSOR cur_ledger_id  IS
      	SELECT   gl.ledger_id AS ledger_id
      	FROM     gl_access_set_assignments gasa, gl_ledgers gl
      	WHERE    access_set_id = Fnd_Profile.VALUE ('GL_ACCESS_SET_ID')
      	AND      gl.ledger_id = gasa.ledger_id
      	AND      gl.ledger_category_code = 'PRIMARY';*/
      	
      	CURSOR cur_org  (pv_period_name VARCHAR2 )IS
      	SELECT DISTINCT PSO.organization_id,PSO.organization_name
        FROM PER_SECURITY_PROFILES_V PSP, 
             PER_SECURITY_ORGANIZATIONS_V PSO
        WHERE 1=1
        AND PSO.SECURITY_PROFILE_ID = PSP.SECURITY_PROFILE_ID
        AND PSP.SECURITY_PROFILE_ID = FND_PROFILE.VALUE ('XLA_MO_SECURITY_PROFILE_LEVEL') --YWA artf2073174  --FND_PROFILE.VALUE ('PER_SECURITY_PROFILE_ID')
        --AND PSP.SECURITY_PROFILE_NAME = 'DKA_TOUT' -- RBE juste pour test
        AND EXISTS (    SELECT  1
                        FROM PA_PERIODS_ALL PAP,
                          GL_PERIODS GLP,
                          PA_IMPLEMENTATIONS_ALL PAIMP,
                          GL_LEDGERS GLL
                        WHERE PAP.GL_PERIOD_NAME       = GLP.PERIOD_NAME
                        AND GLP.PERIOD_SET_NAME        = GLL.PERIOD_SET_NAME
                        AND GLL.LEDGER_ID              = PAIMP.SET_OF_BOOKS_ID
                        AND GLP.ADJUSTMENT_PERIOD_FLAG = 'N'
                        AND PAIMP.ORG_ID               = PAP.ORG_ID
                        AND PAP.STATUS                 = 'O'
                        AND PSO.organization_id        = PAP.org_id
                        AND GLP.PERIOD_NAME            = pv_period_name
                    )
        ;
      	
    BEGIN
        dka_tools_pkg.put_debug_message ('main (+)');
        pv_errbuf     := NULL;
        pn_retcode    := 0;

--        DELETE      dka_spacloture;

        COMMIT;
        --dka_tools_pkg.put_outdebug_message ('FND_PROFILE.VALUE (XLA_MO_SECURITY_PROFILE_LEVEL)'||FND_PROFILE.VALUE ('XLA_MO_SECURITY_PROFILE_LEVEL'));
        
        dka_tools_pkg.put_outdebug_message ('+-------------------------------------------------------+');
        --dka_tools_pkg.put_debug_message ('| Cloture de la période PA : '|| vv_period_name);
        dka_tools_pkg.put_outdebug_message ('| Traitement - DKA : Clôture de la période PA  ');
        dka_tools_pkg.put_outdebug_message ('+-------------------------------------------------------+');
        dka_tools_pkg.put_outdebug_message ('');
        
        dka_tools_pkg.put_outdebug_message ('+-------------------------------------------------------+');
        dka_tools_pkg.put_outdebug_message ('+ Début du traitement : '||TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
        dka_tools_pkg.put_outdebug_message ('+-------------------------------------------------------+');
        dka_tools_pkg.put_outdebug_message ('');
        
        dka_tools_pkg.put_debug_message ('+------------------------------------------------+');
        dka_tools_pkg.put_debug_message ('| Recherche de la première période ouverte');
        dka_tools_pkg.put_debug_message ('+------------------------------------------------+');
        /* Début CSP Portabilité */
        --vv_mesg       := 'RECHERCHE DE L''ORG ID';
        --vn_org_id     := TO_NUMBER(fnd_profile.VALUE ('ORG_ID'));  --RBE MigR12
        --vn_org_id     := rec_cur_ledger_id.organization_id ;         --RBE MigR12
        /* Fin CSP Portabilité */

        --vv_mesg       := 'RECHERCHE DU SOB ID';                                                   --RBE MigR12
        --vn_sob_id     := TO_NUMBER(fnd_profile.VALUE ('GL_SET_OF_BKS_ID')); /* CSP Portabilité */ --RBE MigR12
        
        ---- initialisation de VN_USER_ID pour recuperer l'ID d'user courant
        vn_user_id    := fnd_global.user_id;
        --dka_spacloture_pkg.cherche_period (vn_sob_id, vv_mesg, vd_start_date, vd_end_date, vv_period_name); --RBE MigR12
        dka_spacloture_pkg.cherche_period (vv_mesg, vd_start_date, vd_end_date, vv_period_name);
        dka_tools_pkg.put_outdebug_message ('+-------------------------------------------------------+');
        --dka_tools_pkg.put_debug_message ('| Cloture de la période PA : '|| vv_period_name);
        dka_tools_pkg.put_outdebug_message ('| La période PA à cloturer  : '|| vv_period_name);

        dka_spacloture_pkg.cherche_next_period (vv_mesg, vd_next_start_date, vd_next_end_date, vv_period_name,vv_next_period_name);
        dka_tools_pkg.put_outdebug_message ('| La période PA à ouvrir    : '|| vv_next_period_name);
        dka_tools_pkg.put_outdebug_message ('+-------------------------------------------------------+');
        -- Début modif EMA du 25/10/2006 : Le calcul des statistiques est obsolète
        -- CD 03/06 Calcul des statistiques sur les tables PA pour optimisation procedure pa_check_draft_revenue
        -- DBMS_DDL.ANALYZE_OBJECT('TABLE','PA','PA_DRAFT_REVENUES_ALL','ESTIMATE');
        -- DBMS_DDL.ANALYZE_OBJECT('TABLE','PA','PA_DRAFT_REVENUE_ITEMS','ESTIMATE');
        -- DBMS_DDL.ANALYZE_OBJECT('TABLE','PA','PA_PROJECTS_ALL','ESTIMATE');
        -- Fin modif EMA du 25/10/2006

        -- Test si une période est ouverte
        IF vv_period_name IS NULL
        THEN
            vv_mesg    := 'Il n''y a pas de période ouverte';
            RAISE rec_error;
        END IF;

    --RBE MigR12
    dka_tools_pkg.put_outdebug_message ('+-------------------------------------------------------+');
    dka_tools_pkg.put_outdebug_message ('| Contrôles des conditions de fermeture de la période '||vv_period_name);
    dka_tools_pkg.put_outdebug_message ('+-------------------------------------------------------+');
    FOR rec_cur_org IN cur_org (vv_period_name)
    LOOP

        DELETE      dka_spacloture;
                
        dka_tools_pkg.put_outdebug_message ('+-------------------------------------------------------+');
        dka_tools_pkg.put_outdebug_message ('+Unité opérationnelle : '||rec_cur_org.organization_name);
        dka_tools_pkg.put_outdebug_message ('+-------------------------------------------------------+');
        
        vn_org_id := rec_cur_org.organization_id;
        
        -- Test 1 :
        --dka_spacloture_pkg.pa_check_transfer_to_ap (vd_start_date, vd_end_date, vv_period_name, vn_org_id, vn_sob_id, vv_mesg, vv_status); --RBE MigR12
        dka_spacloture_pkg.pa_check_transfer_to_ap (vd_start_date, vd_end_date, vv_period_name, vn_org_id, vv_mesg, vv_status); --RBE MigR12
        
        IF vv_status = 'KO'
        THEN
            DBMS_OUTPUT.put_line (vv_mesg);
            dka_tools_pkg.put_outdebug_message ('===> Les factures AP sont transférées dans PA KO');

            INSERT INTO dka_spacloture
            VALUES      (vv_period_name,
                         '===> Les factures AP sont transférées dans PA KO',
                         'KO',
                         vv_mesg
                        );
        ELSE
            dka_tools_pkg.put_outdebug_message ('===> Les factures AP sont transférées dans PA OK');

            INSERT INTO dka_spacloture
            VALUES      (vv_period_name,
                         '===> Les factures AP sont transférées dans PA OK',
                         'OK',
                         vv_mesg
                        );
        END IF;

        -- Test 2
        --dka_spacloture_pkg.pa_check_cross_charge (vd_start_date, vd_end_date, vv_period_name, vn_org_id, vn_sob_id, vv_mesg, vv_status); --RBE MigR12
        dka_spacloture_pkg.pa_check_cross_charge (vd_start_date, vd_end_date, vv_period_name, vn_org_id, vv_mesg, vv_status); --RBE MigR12

        IF vv_status = 'KO'
        THEN
            dka_tools_pkg.put_outdebug_message ('===> Toutes les charges sont dans GL KO');

            INSERT INTO dka_spacloture
            VALUES      (vv_period_name,
                         '===> Toutes les charges sont dans GL KO',
                         'KO',
                         vv_mesg
                        );
        ELSE
            dka_tools_pkg.put_outdebug_message ('===> Toutes les charges sont dans GL OK');

            INSERT INTO dka_spacloture
            VALUES      (vv_period_name,
                         '===> Toutes les charges sont dans GL OK',
                         'OK',
                         vv_mesg
                        );
        END IF;

        -- Test 3
        --dka_spacloture_pkg.pa_check_cost_transfer_to_ap (vd_start_date, vd_end_date, vv_period_name, vn_org_id, vn_sob_id, vv_mesg, vv_status); --RBE MigR12
        dka_spacloture_pkg.pa_check_cost_transfer_to_ap (vd_start_date, vd_end_date, vv_period_name, vn_org_id, vv_mesg, vv_status); --RBE MigR12

        IF vv_status = 'KO'
        THEN
            dka_tools_pkg.put_outdebug_message ('===> Tous les couts sont transférés dans AP KO');

            INSERT INTO dka_spacloture
            VALUES      (vv_period_name,
                         '===> Tous les couts sont transférés dans AP KO',
                         'KO',
                         vv_mesg
                        );
        ELSE
            dka_tools_pkg.put_outdebug_message ('===> Tous les couts sont transférés dans AP OK');

            INSERT INTO dka_spacloture
            VALUES      (vv_period_name,
                         '===> Tous les couts sont transférés dans AP OK',
                         'OK',
                         vv_mesg
                        );
        END IF;

        -- Test 4
        --dka_spacloture_pkg.pa_check_draft_revenue (vd_start_date, vd_end_date, vv_period_name, vn_org_id, vn_sob_id, vv_mesg, vv_status); --RBE MigR12
        dka_spacloture_pkg.pa_check_draft_revenue (vd_start_date, vd_end_date, vv_period_name, vn_org_id,  vv_mesg, vv_status); --RBE MigR12

        IF vv_status = 'KO'
        THEN
            dka_tools_pkg.put_outdebug_message ('===> Tous draft revenue sont KO');

            INSERT INTO dka_spacloture
            VALUES      (vv_period_name,
                         '===> Tous draft revenue sont KO',
                         'KO',
                         vv_mesg
                        );
        ELSE
            dka_tools_pkg.put_outdebug_message ('===> Tous draft revenue sont OK');

            INSERT INTO dka_spacloture
            VALUES      (vv_period_name,
                         '===> Tous draft revenue sont OK',
                         'OK',
                         vv_mesg
                        );
        END IF;

        -- Test 5
        --Check for transactions in Project Manufacturing/Inventory
        dka_spacloture_pkg.pa_check_cst_pm (vd_start_date, vd_end_date, vv_period_name, vn_org_id, vv_mesg, vv_status);

        IF vv_status = 'KO'
        THEN
            dka_tools_pkg.put_outdebug_message ('===> Toutes les transactions dans Project Manufacturing/Inventory sont KO');

            INSERT INTO dka_spacloture
            VALUES      (vv_period_name,
                         '===> Toutes les transactions dans Project Manufacturing/Inventory sont KO',
                         'KO',
                         vv_mesg
                        );
        ELSE
            dka_tools_pkg.put_outdebug_message ('===> Toutes les transactions dans Project Manufacturing/Inventory OK');

            INSERT INTO dka_spacloture
            VALUES      (vv_period_name,
                         '===> Toutes les transactions dans Project Manufacturing/Inventory sont OK',
                         'OK',
                         vv_mesg
                        );
        END IF;
        
        -- Test 6
        --Check for transactions not yet cost distributed.
        dka_spacloture_pkg.pa_check_trans_uncosted (vd_start_date, vd_end_date, vv_period_name, vn_org_id, vv_mesg, vv_status);

        IF vv_status = 'KO'
        THEN
            dka_tools_pkg.put_outdebug_message ('===> Tous les coûts des mouvements sont imputés sont KO');

            INSERT INTO dka_spacloture
            VALUES      (vv_period_name,
                         '===> Tous les coûts des mouvements sont imputés sont KO',
                         'KO',
                         vv_mesg
                        );
        ELSE
            dka_tools_pkg.put_outdebug_message ('===> Tous les coûts des mouvements sont imputés OK');

            INSERT INTO dka_spacloture
            VALUES      (vv_period_name,
                         '===> Tous les coûts des mouvements sont imputés sont OK',
                         'OK',
                         vv_mesg
                        );
        END IF;

        --Fermeture/Ouverture des périodes PA
        SELECT COUNT (1)
        INTO   vn_count
        FROM   dka_spacloture
        WHERE  status = 'KO';
        
        IF vn_count = 0
        THEN
        
            dka_tools_pkg.put_outdebug_message ('');
            
            -- Fermeture
            UPDATE pa_periods_all
            SET    current_pa_period_flag = 'N',
                   status = 'C',
                   last_updated_by = vn_user_id,
                   last_update_date = SYSDATE
            WHERE  period_name = vv_period_name
              AND  org_id = rec_cur_org.organization_id;

            -- Ouverture de la suivante
            UPDATE pa_periods_all
            SET    current_pa_period_flag = 'Y',
                   status = 'O',
                   last_updated_by = vn_user_id,
                   last_update_date = SYSDATE
            WHERE  period_name = vv_next_period_name
              AND  org_id = rec_cur_org.organization_id;
              
            
            --RBE artf2086124 
            COMMIT;
              
            dka_tools_pkg.put_outdebug_message ('===> Fermeture/Ouverture des périodes PA :' );
            dka_tools_pkg.put_outdebug_message ('     Période fermée  : '||vv_period_name);
            dka_tools_pkg.put_outdebug_message ('     Période ouverte : '||vv_next_period_name);
              
        --RBE
        ELSE
            dka_tools_pkg.put_outdebug_message ('===> Fermeture/Ouverture des périodes PA : KO' );
            pn_retcode    := 2;
        END IF;
        
    END LOOP; --RBE MigR12
    
        -- Fermeture de la période ouverte et ouverture de la suivante
        -- Si pas d'erreur
--        dka_tools_pkg.put_outdebug_message ('');
--        dka_tools_pkg.put_outdebug_message ('+-------------------------------------------------------+');
--        dka_tools_pkg.put_outdebug_message ('| Fermeture/Ouverture des périodes PA ');
--        dka_tools_pkg.put_outdebug_message ('+-------------------------------------------------------+');
--        
--        SELECT COUNT (1)
--        INTO   vn_count
--        FROM   dka_spacloture
--        WHERE  status = 'KO';
--
--        IF vn_count = 0
--        THEN
-- 
--          --RBE MigR12
--          FOR rec_cur_org1 IN cur_org (vv_period_name)
--          LOOP
--            -- Fermeture
--            UPDATE pa_periods_all
--            SET    current_pa_period_flag = 'N',
--                   status = 'C',
--                   last_updated_by = vn_user_id,
--                   last_update_date = SYSDATE
--            WHERE  period_name = vv_period_name
--              AND  org_id = rec_cur_org1.organization_id;   /* CSP Portabilité */
--              
--            /*UPDATE gl_period_statuses
--            SET    closing_status = 'C',
--                   last_updated_by = vn_user_id,
--                   last_update_date = SYSDATE
--            WHERE      application_id = 275
--                   AND set_of_books_id = (SELECT SET_OF_BOOKS_ID 
--                                          FROM PA_IMPLEMENTATIONS_ALL 
--                                          WHERE ORG_ID = rec_cur_org.organization_id)
--                   AND period_name = vv_period_name
--                   AND start_date = vd_start_date
--                   AND end_date = vd_end_date; */
--                   
--            -- Ouverture de la suivante
--            --dka_tools_pkg.put_outdebug_message ('+-------------------------------------------------------+');
--            --dka_tools_pkg.put_outdebug_message ('| Ouverture de la période PA : '|| vv_next_period_name);
--            --dka_tools_pkg.put_outdebug_message ('+-------------------------------------------------------+');
--    
--            UPDATE pa_periods_all
--            SET    current_pa_period_flag = 'Y',
--                   status = 'O',
--                   last_updated_by = vn_user_id,
--                   last_update_date = SYSDATE
--            WHERE  period_name = vv_next_period_name
--              AND  org_id = rec_cur_org1.organization_id;   /* CSP Portabilité */
--              
--            dka_tools_pkg.put_outdebug_message ('===> Unité opérationnelle '|| rec_cur_org1.organization_name );
--            dka_tools_pkg.put_outdebug_message ('     Période fermée  : '||vv_period_name);
--            dka_tools_pkg.put_outdebug_message ('     Période ouverte : '||vv_next_period_name);
--            /*UPDATE gl_period_statuses
--            SET    closing_status = 'O',
--                   last_updated_by = vn_user_id,
--                   last_update_date = SYSDATE
--            WHERE      application_id = 275
--                  AND set_of_books_id = (SELECT SET_OF_BOOKS_ID 
--                      FROM PA_IMPLEMENTATIONS_ALL 
--                      WHERE ORG_ID = rec_cur_org.organization_id)
--                   AND period_name = vv_period_name
--                   AND start_date = vd_start_date
--                   AND end_date = vd_end_date; 
--                   */
--                   
--          END LOOP;
          dka_tools_pkg.put_outdebug_message ('');
          dka_tools_pkg.put_outdebug_message ('+-------------------------------------------------------+');
          dka_tools_pkg.put_outdebug_message ('+ Fin du traitement : '||TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
          dka_tools_pkg.put_outdebug_message ('+-------------------------------------------------------+');
          
--        ELSE
--            dka_tools_pkg.put_outdebug_message ('===> Aucune période n''a été ouverte ou fermée' );
--            vv_mesg    := 'La période '||vv_period_name || ' n''est pas fermée ';
--            dka_tools_pkg.put_outdebug_message ('');
--            dka_tools_pkg.put_outdebug_message ('+-------------------------------------------------------+');
--            dka_tools_pkg.put_outdebug_message ('+ Fin du traitement : '||TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
--            dka_tools_pkg.put_outdebug_message ('+-------------------------------------------------------+');
--            RAISE rec_error;
--        END IF;
    
    
    EXCEPTION
        WHEN rec_error
        THEN
            pv_errbuf     := vv_mesg;
            pn_retcode    := 2;
        WHEN OTHERS
        THEN
            vv_mesg       := vv_mesg || CHR (10) || SUBSTR (SQLERRM, 1, 400);
            pv_errbuf     := vv_mesg;
            pn_retcode    := 2;
    END;
END DKA_SPACLOTURE_PKG; -- Package body
/
SHOW ERRORS;
EXIT;

