create or replace PACKAGE BODY DKA_IDECLIC_pkg AS
-- $$
-- Capgemini
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_IDECLIC_PKG.pkb
-- DESCRIPTION      : Creation du corps du package DKA_IDECLIC_PKG
-- AUTEUR           : Eric MATUSZEWSKI
-- DATE DE CREATION : 07/12/2004
-- PARAMETRES       : A exécuter sous SQLPLUS avec le user APPS
--
--------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
--------------------------------------------------------------------------------
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------
-- 22/12/2004 JV  Curseur de lecture des clients : remplacer les '0' devant le
--                code Anael par des espaces
-- 31/12/2004 JV  Non prise en compte des sub_id à -999 dans le calcul des
--                soldes clients
-- 06/09/2005 EMA Modification du curseur de lecture des projets cur_projets
--                suite à la migration en 11.5.9 (PHENIX).
--                Modification de la recherche des informations du Code D lié
--                au Code H.
-- 27/09/2005 EMA Dans la table DKA_I00RC, le code société est renseigné par ' '
--                et non par NULL pour la ligne de Total.
-- 14/06/2006 JVI Modification du curseur cur_projects
--                Prise en compte de tous les types P3 et non plus que les P3 
--                renouvellement
-- 23/11/2006 EMA L’extraction des soldes clients doit être modifiée afin d’y 
--                intégrer les clients qui ont :
--                - un solde négatif ou nul 
--                - un ratio client nul
--                Suppression des messages dans le log.
-- 30/11/2006 EMA Dans la table Dka_i00rc, on supprime les clients pour lesquels
--                le site est nul.
-- 04/10/2012 BCO Ajout de l'insertion des informations clients dans un fichier
--                  temporaire.
-- 28/10/2016 YWA Migration R12  
-- 22/02/2016 YWA artf2105168 
-- 09/06/2017 NBO artf2172224 - INT036 : Interface vers DECLIC - Le traitement se termine KO - Defect Bout en bout 763
-- 19/06/2017 RBE artf2173619 : INT036 : Interface vers DECLIC - Optimisation traitement et valeurs soldes à Zéro dans état 
-- 15/06/2018 NBO artf2766197 : Exportation vers PELICAN DECLIC
-- 25/06/2018 NBO artf2766197 : Exportation vers PELICAN DECLIC
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


        ---------------------------------
        -- Fonction de calcul du solde --
        ---------------------------------
        FUNCTION calcul_solde (p_bill_to_customer_id NUMBER DEFAULT NULL,
                               p_bill_to_site_use_id NUMBER DEFAULT NULL,
                               p_org_id             NUMBER,
                               p_period_name         VARCHAR2,
                               p_ledger_id  NUMBER)
        RETURN NUMBER
        IS
            v_solde NUMBER;
            v_solde1 NUMBER;
            v_solde2 NUMBER;
            v_solde3 NUMBER;
            l_count NUMBER;
            l_count2 NUMBER;
            l_count3 NUMBER;
        BEGIN
            /*SELECT NVL(SUM(NVL(end_balance_dr,0) - NVL(end_balance_cr, 0)), 0)
            INTO   v_solde
            FROM   ax_balances           ab,-- amodifier
                   gl_period_statuses    gps
            WHERE  gps.application_id  = 222
            AND    gps.set_of_books_id = 1
            AND    gps.period_name     = p_period_name
            AND    ab.application_id   = gps.application_id
            AND    ab.set_of_books_id  = gps.set_of_books_id
            AND    ab.period_name      = gps.period_name
            AND    ab.third_party_id   = NVL(p_bill_to_customer_id,ab.third_party_id)
            AND    ab.sub_id           = NVL(p_bill_to_site_use_id,ab.sub_id)
            AND    ab.sub_id          != -999
            AND    ab.org_id             = p_org_id
            AND    NOT EXISTS (SELECT 1
                               FROM   fnd_flex_values     ffv,
                                      fnd_flex_value_sets ffvs
                               WHERE  '0' = '0'
                               AND    ffv.flex_value_set_id    = ffvs.flex_value_set_id
                               AND    ffvs.flex_value_set_name = 'DKA_COMPTES_TIERS_CLIENT'
                               AND    ffv.flex_value           = ab.account_segment
                               AND    ffv.enabled_flag         = 'Y');*/--YWA
                               

            -- 15/06/2017 NBO artf2766197 : Exportation vers PELICAN DECLIC
            /*SELECT SUM(solde)
            INTO v_solde

            FROM (*/
            
            l_count := 0; l_count2 := 0; l_count3 := 0;

            -- 15/06/2018 NBO artf2766197 : Exportation vers PELICAN DECLIC
            -- 25/06/2018 NBO artf2766197 : Exportation vers PELICAN DECLIC
            -- Compteur pour éviter de lancer des requêtes inutiles
            select count(1) into l_count
             from gl_period_statuses           gps,
                   xla_ae_headers               xah,
                   ra_customer_trx_all          rcta,
                   xla.xla_transaction_entities xte
             WHERE gps.period_name = p_period_name
               AND gps.ledger_id = p_ledger_id
               AND gps.application_id = 222
               AND xah.period_name = gps.period_name
               AND xte.entity_code = 'TRANSACTIONS'
               AND rcta.customer_trx_id = nvl(xte.source_id_int_1, -99)
               AND xte.ledger_id = rcta.set_of_books_id
               AND gps.application_id = xte.application_id
               AND rcta.bill_to_customer_id = p_bill_to_customer_id
               AND rcta.bill_to_site_use_id = p_bill_to_site_use_id
               AND rcta.org_id = p_org_id
               AND xte.application_id = xah.application_id
               AND xte.entity_id = xah.entity_id;
               
            IF l_count = 0 THEN
            
            SELECT COUNT(1)
              INTO l_count2
              FROM gl_period_statuses           gps,
                   xla_ae_headers               xah,
                   ar_cash_receipts_all         acra,
                   xla.xla_transaction_entities xte
             WHERE gps.period_name = p_period_name
               AND gps.ledger_id = p_ledger_id
               AND gps.application_id = 222
               AND xah.ledger_id = gps.ledger_id
               AND xah.application_id = 222
               AND xah.period_name = gps.period_name
               AND xte.entity_code = 'RECEIPTS'
               AND acra.cash_receipt_id = nvl(xte.source_id_int_1, -99)
               AND xte.ledger_id = acra.set_of_books_id
               AND gps.application_id = xte.application_id
               AND acra.pay_from_customer = p_bill_to_customer_id
               AND acra.customer_site_use_id = p_bill_to_site_use_id
               AND acra.org_id = p_org_id
               AND xte.application_id = xah.application_id
               AND xte.entity_id = xah.entity_id;
            END IF;
            
            IF l_count2 = 0 THEN
            
            SELECT COUNT(1)
              INTO l_count3
              FROM gl_period_statuses           gps,
                   xla_ae_headers               xah,
                   ar_adjustments_all           aaa,
                   ra_customer_trx_all          rcta,
                   xla.xla_transaction_entities xte
             WHERE gps.period_name = p_period_name
               AND gps.ledger_id = p_ledger_id
               AND gps.application_id = 222
               AND xah.ledger_id = gps.ledger_id
               AND xah.application_id = gps.application_id
               AND xah.period_name = gps.period_name
               AND xte.entity_code = 'ADJUSTMENTS'
               AND aaa.adjustment_id = nvl(xte.source_id_int_1, -99)
               AND xte.ledger_id = aaa.set_of_books_id
               AND gps.application_id = xte.application_id
               AND rcta.bill_to_customer_id = p_bill_to_customer_id
               AND rcta.bill_to_site_use_id = p_bill_to_site_use_id
               AND rcta.org_id = p_org_id
               AND aaa.org_id = rcta.org_id
               AND aaa.customer_trx_id = rcta.customer_trx_id
               AND xte.entity_id = xah.entity_id;
            END IF;
              
            IF l_count > 0 OR l_count2 > 0 OR l_count3 > 0 THEN
                   
            SELECT  NVL(SUM(NVL(decode(apsa.CLASS,'INV',xal.accounted_dr,-1*xal.accounted_dr) ,0)), 0) solde
            INTO v_solde1
            FROM   gl_ledgers              gl,
                  gl_period_statuses      gps, 
                  xla_ae_lines            xal,
                  xla_ae_headers          xah,
                  ra_customer_trx_all     rcta,
                  xla.xla_transaction_entities xte,
                  ar_payment_schedules_all apsa
            WHERE     xal.ae_header_id = xah.ae_header_id
            AND    xal.application_id =xah.application_id
            AND    xte.application_id = xah.application_id
            AND    xte.entity_id = xah.entity_id
            AND   xah.period_name = gps.period_name
            --APSA
            AND    apsa.customer_id = rcta.bill_to_customer_id
            AND    apsa.customer_trx_id = rcta.customer_trx_id
            AND    apsa.org_id = rcta.org_id
            AND    apsa.status = 'OP'
            and    apsa.CLASS IN ('CM', 'INV')
            AND    xte.entity_code = 'TRANSACTIONS'
            -- 15/06/2017 NBO artf2766197 : Exportation vers PELICAN DECLIC
            --AND    rcta.customer_trx_id = xte.source_id_int_1
            AND   RCTA.CUSTOMER_TRX_ID = nvl(XTE.SOURCE_ID_INT_1,-99)
            AND   xte.ledger_id = rcta.set_of_books_id
            AND   gps.application_id =   xte.application_id
            AND    rcta.bill_to_customer_id =p_bill_to_customer_id
            AND   rcta.bill_to_site_use_id = p_bill_to_site_use_id
            AND   rcta.org_id = p_org_id
            AND   gl.ledger_id =  gps.ledger_id
            AND   gps.period_name = p_period_name
            AND   gps.ledger_id = p_ledger_id
            AND  gps.application_id = 222;
            --UNION          
            SELECT -1 * NVL(SUM(NVL(xal.accounted_cr, 0)), 0) solde
            INTO v_solde2
            FROM gl_ledgers                     gl,
                 gl_period_statuses             gps,
                 xla_ae_lines                   xal,
                 xla_ae_headers                 xah,
                 ar_cash_receipts_all           acra,
                 ar_payment_schedules_all       apsa,
                 xla.xla_transaction_entities   xte
           WHERE acra.CASH_RECEIPT_ID = apsa.CASH_RECEIPT_ID
             AND acra.ORG_ID = apsa.ORG_ID
             AND apsa.CUSTOMER_SITE_USE_ID = acra.customer_site_use_id
             AND apsa.status = 'OP'
             AND xal.ae_header_id = xah.ae_header_id
             AND xal.application_id = xah.application_id
             AND xte.application_id = xah.application_id
             AND xte.entity_id = xah.entity_id
             AND xah.period_name = gps.period_name
             AND xte.entity_code = 'RECEIPTS'
             -- 15/06/2017 NBO artf2766197 : Exportation vers PELICAN DECLIC
             --AND acra.cash_receipt_id = xte.source_id_int_1
             AND acra.cash_receipt_id = nvl(XTE.SOURCE_ID_INT_1,-99)
             AND xte.ledger_id = acra.set_of_books_id
             AND gps.application_id = xte.application_id
             AND acra.pay_from_customer = p_bill_to_customer_id
             AND acra.customer_site_use_id = p_bill_to_site_use_id
             AND acra.org_id = p_org_id
             AND gl.ledger_id = gps.ledger_id
             AND gps.period_name = p_period_name
             AND gps.ledger_id = p_ledger_id
             AND gps.application_id = 222;
                         
                         
            --UNION
            
            SELECT  -1*NVL(SUM(NVL(xal.accounted_cr,0)), 0) solde
            INTO v_solde3

            FROM    gl_ledgers              gl,
            gl_period_statuses      gps, 
            xla_ae_lines            xal,
            xla_ae_headers          xah,
            ar_adjustments_all       aaa,
            ra_customer_trx_all     rcta,
            ar_payment_schedules_all apsa,
            xla.xla_transaction_entities xte
            WHERE             apsa.customer_id = rcta.bill_to_customer_id
            AND    apsa.customer_trx_id = rcta.customer_trx_id
            AND    apsa.org_id = rcta.org_id
            AND    apsa.status = 'OP'
            AND    xal.ae_header_id = xah.ae_header_id
            AND    xal.application_id =xah.application_id
            AND    xte.application_id = xah.application_id
            AND    xte.entity_id = xah.entity_id
            --AND   xah.period_name = gps.period_name
            AND    xte.entity_code = 'ADJUSTMENTS'
            -- 15/06/2017 NBO artf2766197 : Exportation vers PELICAN DECLIC
            --AND    aaa.adjustment_id = xte.source_id_int_1
            AND aaa.adjustment_id = nvl(XTE.SOURCE_ID_INT_1,-99)
            AND xte.ledger_id = aaa.set_of_books_id
            AND  gps.application_id =   xte.application_id
            AND    rcta.bill_to_customer_id =p_bill_to_customer_id
            AND   rcta.bill_to_site_use_id = p_bill_to_site_use_id
            AND   rcta.org_id = p_org_id
            AND   aaa.org_id = rcta.org_id 
            AND    aaa.customer_trx_id = rcta.customer_trx_id
            AND   gl.ledger_id =  gps.ledger_id
            AND   gps.period_name = p_period_name
            AND  gps.ledger_id = p_ledger_id
            AND  gps.application_id = 222;

          ELSE
            v_solde1 := 0;
            v_solde2 := 0;
            v_solde3 := 0;
          END IF; 
              
           --   );
           v_solde := v_solde1 + v_solde2 + v_solde3;
                                          
            RETURN (v_solde);
        EXCEPTION
            WHEN OTHERS THEN
                 dka_tools_pkg.put_log_message('==> Erreur dans la fonction calcul_solde');
                 dka_tools_pkg.put_log_message('==> '||to_char(SQLCODE)||' - '||SQLERRM);
        END calcul_solde;

    --------------------------------------------------------------------------------
    --  Nom           : extract_i00rc
    --  Description   : procédure de remplissage de la table DKA_I00RC
    --
    --  PARAMETRES    : pv_errbuf   Entrée/Sortie    message d'erreur
    --                  pn_retcode         Sortie    code de retour: 'O=normal',
    ---                                                              '1=warning',
    --                                                               '2=erreur'
    --
    --  VALEUR RETOURNEE :
    --     Description       : ************************
    --     Valeurs possibles : ************************
    --------------------------------------------------------------------------------
    PROCEDURE extract_i00rc (pv_errbuf  IN OUT VARCHAR2,
                             pn_retcode    OUT NUMBER,
                             p_period_name gl_period_statuses.period_name%TYPE,
                             p_end_date gl_period_statuses.end_date%TYPE) IS

        --v_period_name           gl_period_statuses.period_name%TYPE;
        --v_start_date            gl_period_statuses.start_date%TYPE;
        
        v_effective_period_num  gl_period_statuses.effective_period_num%TYPE;
        v_ircsol                dka_i00rc.ircsol%TYPE;
        --v_ircrat                dka_i00rc.ircrat%TYPE;
        v_ratio                 NUMBER;
        v_solde                 NUMBER;
        v_ca                    NUMBER;
        v_ircdar                varchar2(6);
           
        -- Variable d'écriture dans le fichier log de sortie. --
        v_fileHandler           UTL_FILE.FILE_TYPE;
        v_filename              varchar2(50);
        v_nom_chemin         VARCHAR2(250) :='DKA_OUT_DIR';
        v_count NUMBER;
        
            
            
            
        ------------------------------------
        -- Curseur de lecture des clients --
        ------------------------------------
        CURSOR cur_client_uo  IS
                /*SELECT hcasa.attribute3                                   ircaux,                                
                    substr(hp.party_name, 1, 40)                       irclcl,                
                    hca.cust_account_id                                bill_to_customer_id,   
                    hcsua.site_use_id                                  bill_to_site_use_id,
                     hou.organization_id  
                FROM   hz_cust_site_uses_all                              hcsua,                 
                    hz_cust_acct_sites_all                             hcasa,                                                                           
                    hz_cust_accounts                                   hca,                   
                    hz_parties                                         hp,                    
                    hr_operating_units                                 hou                                                         
                WHERE  hcsua.site_use_code          = 'BILL_TO'                                  
                AND    hcsua.primary_flag           = 'N'                                        
                AND    hcsua.status                 = 'A'                                        
                AND    hcsua.cust_acct_site_id      = hcasa.cust_acct_site_id                    
                AND    hcasa.cust_account_id        = hca.cust_account_id                        
                AND    hca.party_id                 = hp.party_id                                
                AND   hou.organization_id =  hcsua.org_id                                        
                AND   hou.organization_id =  hcasa.org_id                                                       
                AND    substr(hcsua.location, 1, 2) NOT IN ('.', 'T0');  */   
                    
            SELECT  substr(hou.NAME, 1, 3)                     ircreg,
                    substr(hou.NAME, 4 )                       ircsoc,
                    hcasa.attribute3                           ircaux,                                
                    substr(hp.party_name, 1, 40)               irclcl,      
                    substr(xep.name, 1, 20)                    irclst, 
                    hca.cust_account_id                        bill_to_customer_id,   
                    hcsua.site_use_id                          bill_to_site_use_id,
                    hcasa.org_id  ,
                    hou.set_of_books_id                        ledger_id
                    -- 15/06/2017 NBO artf2766197 : Exportation vers PELICAN DECLIC
/*,
                    calcul_solde (hca.cust_account_id,
                               hcsua.site_use_id,
                               hcasa.org_id,
                               p_period_name,
                               hou.set_of_books_id)  solde -- RBE artf2173619*/
                    
            FROM    hz_cust_site_uses_all                              hcsua,                 
                    hz_cust_acct_sites_all                             hcasa,                                                                           
                    hz_cust_accounts                                   hca,                   
                    hz_parties                                         hp,                    
                    hr_operating_units                                 hou,
                    xle_entity_profiles       xep
            WHERE  hcsua.site_use_code          = 'BILL_TO'                                  
            AND    hcsua.primary_flag           = 'N'                                        
            AND    hcsua.status                 = 'A'                                        
            AND    hcsua.cust_acct_site_id      = hcasa.cust_acct_site_id                    
            AND    hcasa.cust_account_id        = hca.cust_account_id                        
            AND    hca.party_id                 = hp.party_id         
            AND    hcsua.org_id  =hcasa.org_id
            AND    hou.organization_id =  hcsua.org_id                                        
            AND    hou.organization_id =  hcasa.org_id                                                       
            AND    substr(hcsua.location, 1, 2) NOT IN ('.', 'T0')
            AND    xep.legal_entity_id  =  hou.default_legal_context_id
            AND  hou.set_of_books_id in (SELECT ledger_id FROM   gl_access_set_ledgers  WHERE access_set_id = fnd_profile.value('GL_ACCESS_SET_ID')) 
             /*and EXISTS (SELECT 1
                            FROM   ra_customer_trx_all               rcta,
                                   ra_cust_trx_types_all             rctta,
                                   ra_cust_trx_line_gl_dist_all      rctlgda
                            WHERE  rcta.cust_trx_type_id        = rctta.cust_trx_type_id
                            AND    rctta.type IN ('CM', 'INV')
                            AND    rcta.complete_flag           = 'Y'
                            AND    rcta.customer_trx_id         = rctlgda.customer_trx_id
                            AND    rctta.name NOT IN ('PASSAGE_IRRECOUVRABL', 'MANUEL_REMBOUR_AVOIR')
                            AND    rctlgda.account_class        = 'REC'
                            AND    rctlgda.latest_rec_flag      = 'Y'
                            AND    rctlgda.gl_posted_date IS NOT NULL
                            AND    rcta.bill_to_customer_id     = hca.cust_account_id 
                            AND    rcta.bill_to_site_use_id     = hcsua.site_use_id  
                            AND rcta.org_id =hcasa.org_id
                            and rcta.org_id =rctta.org_id
                            and rcta.org_id =rctlgda.org_id)*/
             AND hcasa.attribute3 IS NOT NULL --RBE artf2173619
             ORDER BY irclcl,ircreg,ircsoc ;    
                    

                
        
        
        /*----------------------------------------
        -- Curseur de recherche de la société --
        ----------------------------------------
        CURSOR cur_societe (p_bill_to_customer_id NUMBER, 
                            p_bill_to_site_use_id NUMBER )IS
            SELECT DISTINCT SUBSTR(hou.name,0,3)                       ircreg,
                    SUBSTR(hou.name,4)                                 ircsoc,                                        
                    xep.name                                           irclst,   
                    hou.organization_id                                org_id,
                    (select ledger_id from  gl_ledgers where name = xep.name ) ledger_id,
                    (select currency_code from  gl_ledgers where name = xep.name ) currency_code
            FROM   hz_cust_site_uses_all                              hcsua,                 
                    hz_cust_acct_sites_all                             hcasa,                                                                                       
                    hz_cust_accounts                                   hca,                   
                    hz_parties                                         hp,                    
                    hr_operating_units                                 hou,                   
                    xle_entity_profiles            xep                                        
            WHERE  hcsua.site_use_code          = 'BILL_TO'                                  
            AND    hcsua.primary_flag           = 'N'                                        
            AND    hcsua.status                 = 'A'                                        
            AND    hcsua.cust_acct_site_id      = hcasa.cust_acct_site_id                    
            AND    hcasa.cust_account_id        = hca.cust_account_id                        
            AND    hca.party_id                 = hp.party_id                                
            AND   hou.organization_id =  hcsua.org_id                                        
            AND   hou.organization_id =  hcasa.org_id                                        
            AND   xep.legal_entity_id  =  hou.default_legal_context_id                       
            AND    substr(hcsua.location, 1, 2) NOT IN ('.', 'T0');     */                 
        
        ------------------------------
        -- Fonction de calcul du CA --
        ------------------------------
        /*FUNCTION calcul_ca (p_bill_to_customer_id NUMBER DEFAULT NULL,
                            p_bill_to_site_use_id NUMBER DEFAULT NULL,
                            p_societe     VARCHAR2,
                            p_region     VARCHAR2,
                            p_start_date          DATE,
                            p_end_date            DATE)
        RETURN NUMBER
        IS
            v_ca NUMBER;
        BEGIN
            SELECT NVL(SUM(rctlgda.amount), 0)    ca
            INTO   v_ca
            FROM   ra_customer_trx_all            rcta,
                   ra_cust_trx_types_all          rctta,
                   ra_cust_trx_line_gl_dist_all   rctlgda,
                   gl_code_combinations           gcc
            WHERE  rcta.cust_trx_type_id        = rctta.cust_trx_type_id
            AND    rctta.type IN ('CM', 'INV')
            AND    rcta.complete_flag           = 'Y'
            AND    rcta.customer_trx_id         = rctlgda.customer_trx_id
            AND    rctta.name NOT IN ('PASSAGE_IRRECOUVRABL', 'MANUEL_REMBOUR_AVOIR')
            AND    rctlgda.account_class        = 'REC'
            AND    rctlgda.latest_rec_flag      = 'Y'
            AND    rctlgda.gl_posted_date IS NOT NULL
            AND    rctlgda.code_combination_id  = gcc.code_combination_id
            AND    rctlgda.gl_date BETWEEN p_start_date
                                   AND     p_end_date
            AND    rcta.bill_to_customer_id     = NVL(p_bill_to_customer_id,rcta.bill_to_customer_id )
            AND    rcta.bill_to_site_use_id     = NVL(p_bill_to_site_use_id,rcta.bill_to_site_use_id)
            AND    gcc.segment1                 = p_societe
            AND    gcc.segment2                 = p_region
            AND    NOT EXISTS (SELECT 1
                               FROM   fnd_flex_values     ffv,
                                      fnd_flex_value_sets ffvs
                               WHERE  '0' = '0'
                               AND    ffv.flex_value_set_id    = ffvs.flex_value_set_id
                               AND    ffvs.flex_value_set_name = 'DKA_COMPTES_TIERS_CLIENT'
                               AND    ffv.flex_value           = gcc.segment3
                               AND    ffv.enabled_flag         = 'Y');

            RETURN (v_ca);

        EXCEPTION
            WHEN OTHERS THEN
                 dka_tools_pkg.put_log_message('==> Erreur dans la fonction calcul_ca');
                 dka_tools_pkg.put_log_message('==> '||to_char(SQLCODE)||' - '||SQLERRM);
        END calcul_ca;*/--YWA

/* --RBE artf2173619 integre dans le cursor
        ---------------------------------
        -- Fonction de calcul du solde --
        ---------------------------------
        FUNCTION calcul_solde (p_bill_to_customer_id NUMBER DEFAULT NULL,
                               p_bill_to_site_use_id NUMBER DEFAULT NULL,
                               p_org_id             NUMBER,
                               p_period_name         VARCHAR2,
                               p_ledger_id  NUMBER)
        RETURN NUMBER
        IS
            v_solde NUMBER;
        BEGIN */ --RBE
            /*SELECT NVL(SUM(NVL(end_balance_dr,0) - NVL(end_balance_cr, 0)), 0)
            INTO   v_solde
            FROM   ax_balances           ab,-- amodifier
                   gl_period_statuses    gps
            WHERE  gps.application_id  = 222
            AND    gps.set_of_books_id = 1
            AND    gps.period_name     = p_period_name
            AND    ab.application_id   = gps.application_id
            AND    ab.set_of_books_id  = gps.set_of_books_id
            AND    ab.period_name      = gps.period_name
            AND    ab.third_party_id   = NVL(p_bill_to_customer_id,ab.third_party_id)
            AND    ab.sub_id           = NVL(p_bill_to_site_use_id,ab.sub_id)
            AND    ab.sub_id          != -999
            AND    ab.org_id             = p_org_id
            AND    NOT EXISTS (SELECT 1
                               FROM   fnd_flex_values     ffv,
                                      fnd_flex_value_sets ffvs
                               WHERE  '0' = '0'
                               AND    ffv.flex_value_set_id    = ffvs.flex_value_set_id
                               AND    ffvs.flex_value_set_name = 'DKA_COMPTES_TIERS_CLIENT'
                               AND    ffv.flex_value           = ab.account_segment
                               AND    ffv.enabled_flag         = 'Y');*/--YWA
                               
/* --RBE artf2173619
            SELECT SUM(solde)
            INTO v_solde

            FROM (
                   
            SELECT  NVL(SUM(NVL(decode(apsa.CLASS,'INV',xal.accounted_dr,-1*xal.accounted_dr) ,0)), 0) solde

            FROM   gl_ledgers              gl,
                  gl_period_statuses      gps, 
                  xla_ae_lines            xal,
                  xla_ae_headers          xah,
                  ra_customer_trx_all     rcta,
                  xla.xla_transaction_entities xte,
                  ar_payment_schedules_all apsa
            WHERE     xal.ae_header_id = xah.ae_header_id
            AND    xal.application_id =xah.application_id
            AND    xte.application_id = xah.application_id
            AND    xte.entity_id = xah.entity_id
            AND   xah.period_name = gps.period_name
            --APSA
            AND    apsa.customer_id = rcta.bill_to_customer_id
            AND    apsa.customer_trx_id = rcta.customer_trx_id
            AND    apsa.org_id = rcta.org_id
            AND    apsa.status = 'OP'
            and    apsa.CLASS IN ('CM', 'INV')
            AND    xte.entity_code = 'TRANSACTIONS'
            AND    rcta.customer_trx_id = xte.source_id_int_1
            AND   gps.application_id =   xte.application_id
            AND    rcta.bill_to_customer_id =p_bill_to_customer_id
            AND   rcta.bill_to_site_use_id = p_bill_to_site_use_id
            AND   rcta.org_id = p_org_id
            AND   gl.ledger_id =  gps.ledger_id
            AND   gps.period_name = p_period_name
            AND   gps.ledger_id = p_ledger_id
            AND  gps.application_id = 222
                      
            UNION          
            SELECT -1*NVL(SUM(NVL(xal.accounted_cr,0)), 0) solde
            FROM   gl_ledgers              gl,
                    gl_period_statuses      gps, 
                    xla_ae_lines            xal,
                    xla_ae_headers          xah,
                    ar_cash_receipts_all     acra,
                    ar_payment_schedules_all apsa,
                    xla.xla_transaction_entities xte
            WHERE  acra.CASH_RECEIPT_ID           = apsa.CASH_RECEIPT_ID
            AND acra.ORG_ID                           =apsa.ORG_ID
            AND apsa.CUSTOMER_SITE_USE_ID      = acra.customer_site_use_id 
            AND    apsa.status ='OP'
            AND    xal.ae_header_id = xah.ae_header_id
            AND    xal.application_id =xah.application_id
            AND    xte.application_id = xah.application_id
            AND    xte.entity_id = xah.entity_id
            AND   xah.period_name = gps.period_name
            AND    xte.entity_code = 'RECEIPTS'
            AND    acra.cash_receipt_id = xte.source_id_int_1
            AND  gps.application_id =   xte.application_id
            AND    acra.pay_from_customer =p_bill_to_customer_id
            AND   acra.customer_site_use_id = p_bill_to_site_use_id
            AND   acra.org_id = p_org_id
            AND   gl.ledger_id =  gps.ledger_id
            AND   gps.period_name = p_period_name
            AND gps.ledger_id = p_ledger_id
            AND  gps.application_id = 222
                         
            UNION
            
            SELECT  -1*NVL(SUM(NVL(xal.accounted_cr,0)), 0) solde

            FROM    gl_ledgers              gl,
            gl_period_statuses      gps, 
            xla_ae_lines            xal,
            xla_ae_headers          xah,
            ar_adjustments_all       aaa,
            ra_customer_trx_all     rcta,
            ar_payment_schedules_all apsa,
            xla.xla_transaction_entities xte
            WHERE             apsa.customer_id = rcta.bill_to_customer_id
            AND    apsa.customer_trx_id = rcta.customer_trx_id
            AND    apsa.org_id = rcta.org_id
            AND    apsa.status = 'OP'
            AND    xal.ae_header_id = xah.ae_header_id
            AND    xal.application_id =xah.application_id
            AND    xte.application_id = xah.application_id
            AND    xte.entity_id = xah.entity_id
            --AND   xah.period_name = gps.period_name
            AND    xte.entity_code = 'ADJUSTMENTS'
            AND    aaa.adjustment_id = xte.source_id_int_1
            AND  gps.application_id =   xte.application_id
            AND    rcta.bill_to_customer_id =p_bill_to_customer_id
            AND   rcta.bill_to_site_use_id = p_bill_to_site_use_id
            AND   rcta.org_id = p_org_id
            AND   aaa.org_id = rcta.org_id 
            AND    aaa.customer_trx_id = rcta.customer_trx_id
            AND   gl.ledger_id =  gps.ledger_id
            AND   gps.period_name = p_period_name
            AND  gps.ledger_id = p_ledger_id
            AND  gps.application_id = 222
              
              );
                               
            RETURN (v_solde);
        EXCEPTION
            WHEN OTHERS THEN
                 dka_tools_pkg.put_log_message('==> Erreur dans la fonction calcul_solde');
                 dka_tools_pkg.put_log_message('==> '||to_char(SQLCODE)||' - '||SQLERRM);
        END calcul_solde;
*/ --RBE artf2173619

        ----------------------------------------
        -- Fonction de calcul du ratio client --
        ----------------------------------------
       /*FUNCTION calcul_ratio (p_bill_to_customer_id  NUMBER DEFAULT NULL,
                               p_bill_to_site_use_id  NUMBER DEFAULT NULL,
                               p_set_of_books_id       NUMBER,
                               p_societe                VARCHAR2,
                               p_region                 VARCHAR2,
                               p_effective_period_num NUMBER,
                               p_solde                NUMBER)
        RETURN NUMBER
        IS
            v_solde NUMBER;
            v_reste NUMBER;
            v_ratio NUMBER;
            v_ca    NUMBER;

            -------------------------------------
            -- Curseur de lecture des périodes --
            -------------------------------------
            CURSOR cur_period IS
                SELECT gps.period_name, 
                       gps.start_date, 
                       gps.end_date, 
                       gps.effective_period_num
                FROM   gl_period_statuses gps
                WHERE  gps.application_id        = 222
                AND    gps.set_of_books_id       = p_set_of_books_id
                AND    gps.effective_period_num <= p_effective_period_num
                ORDER BY gps.effective_period_num DESC;

            rec_period cur_period%ROWTYPE;

        BEGIN

            -- dka_tools_pkg.put_debug_message('(+) calcul_ratio');

            v_ratio := 0;
            v_reste := p_solde;

            IF v_reste <= 0 THEN
               -- dka_tools_pkg.put_debug_message('==> v_reste <= 0');
               -- dka_tools_pkg.put_debug_message('==> v_ratio : 0');
               RETURN (0);
            END IF;

            ------------------------------------
            -- Boucle de lecture des périodes --
            ------------------------------------
            OPEN cur_period;
            LOOP
                FETCH cur_period INTO rec_period;
                EXIT WHEN cur_period%NOTFOUND;

                v_ca := calcul_ca (p_bill_to_customer_id, p_bill_to_site_use_id, p_societe,p_region, rec_period.start_date, rec_period.end_date);
                -- dka_tools_pkg.put_debug_message('==> v_ca ('||rec_period.period_name||') : '||v_ca);
                -- dka_tools_pkg.put_debug_message('==> v_reste : '||v_reste);
                IF v_reste <= v_ca THEN
                   -- dka_tools_pkg.put_debug_message('==> v_reste <= v_ca');
                   v_ratio := v_ratio + ROUND(30 * v_reste/v_ca);
                   -- dka_tools_pkg.put_debug_message('==> v_ratio : '||v_ratio);
                   -- dka_tools_pkg.put_debug_message('(-) calcul_ratio');
                   RETURN (v_ratio);
                ELSE
                   -- dka_tools_pkg.put_debug_message('==> v_reste > v_ca');
                   v_reste := v_reste - v_ca;
                   v_ratio := v_ratio + 30;
                   -- dka_tools_pkg.put_debug_message('==> v_reste : '||v_reste);
                   -- dka_tools_pkg.put_debug_message('==> v_ratio : '||v_ratio);
                END IF;

            END LOOP;
            CLOSE cur_period;

            -- dka_tools_pkg.put_debug_message('==> v_ratio : NULL');
            -- dka_tools_pkg.put_debug_message('(-) calcul_ratio');

            RETURN 99999;

        EXCEPTION
            WHEN OTHERS THEN
                 dka_tools_pkg.put_log_message('==> Erreur dans la fonction calcul_ratio');
                 dka_tools_pkg.put_log_message('==> '||to_char(SQLCODE)||' - '||SQLERRM);
        END calcul_ratio;**/--YWA
    BEGIN
        dka_tools_pkg.put_debug_message('(+) extract_i00rc');

        -----------------------------------------------------------
        -- Suppression des enregistrements de la table dka_i00rc --
        -----------------------------------------------------------
        DELETE FROM dka_i00rc;
        
        -- Insertion pour fichier de sortie . --
        --v_filename := 'FIN01_INT036_' || TO_CHAR(sysdate,'YYYYMMDD_HH24miss') || '.txt';
        v_filename := 'SOLDESCLIENTS_' || TO_CHAR(sysdate,'YYYYMMDD') || '.csv';--YWA artf2105168  
        
        -- Ouverture du fichier en mode écriture. --
        v_fileHandler := utl_file.fopen(v_nom_chemin, v_filename, 'w');
        utl_file.put_line(v_fileHandler, 'Fichier DECLIC DU : '|| to_char(sysdate,'DD/MM/YYYY HH24:mi:ss'));
        utl_file.put_line(v_fileHandler,'');
        utl_file.put_line(v_fileHandler,'---------------------------------------------------------------------------------------------------------------');
        
        v_ircdar := to_char(p_end_date, 'YYYYMM');  --RBE artf2173619
        
        utl_file.put_line(v_fileHandler,'IRCREG;IRCAUX;IRCSOC;IRCDAR;IRCSOL;IRCLST;IRCLCL');
        -----------------------------------
        -- Boucle de lecture des société --
        -----------------------------------
        dka_tools_pkg.put_log_message('Debut insertion table');
        
        v_count := 0;
        FOR client IN cur_client_uo LOOP
            /*BEGIN
                SELECT gps.period_name, 
                       gps.start_date, 
                       gps.end_date, 
                       gps.effective_period_num
                INTO   v_period_name, 
                       v_start_date, 
                       v_end_date, 
                       v_effective_period_num
                FROM   gl_period_statuses gps
                WHERE  gps.application_id  = 222
                AND    gps.set_of_books_id = societe.ledger_id
                AND    gps.end_date = (SELECT MAX(gps1.end_date)
                                       FROM   gl_period_statuses gps1
                                       WHERE  gps1.application_id  = gps.application_id
                                       AND    gps1.set_of_books_id = gps.set_of_books_id
                                       AND    gps1.closing_status  = 'C');
            EXCEPTION
                WHEN OTHERS THEN
                    dka_tools_pkg.put_log_message('==> Erreur lors de la recuperation de la periode');
                    dka_tools_pkg.put_log_message('==> '||to_char(SQLCODE)||' - '||SQLERRM);                           
            END;*/
            
            --v_ircdar := to_char(p_end_date, 'YYYYMM'); --RBE artf2173619 deplacé hors boocle
            ---------------------------------
            -- CALCUL DES LIGNES DE DETAIL --
            ---------------------------------
            
                -----------------------------
                -- Recherche de la société --
                -----------------------------
            --FOR client IN cur_client(societe.org_id) LOOP
            
            ---------------------
            -- Calcul du solde --
            ---------------------
            /*v_solde := client.solde;*/ --RBE artf2173619 utilisé directement
            /*calcul_solde (   client.bill_to_customer_id, 
                                        client.bill_to_site_use_id,
                                        client.org_id,
                                        p_period_name,
                                        client.ledger_id); */
            -- 15/06/2017 NBO artf2766197 : Exportation vers PELICAN DECLIC
            v_solde := calcul_solde (client.bill_to_customer_id, 
                               client.bill_to_site_use_id,
                               client.org_id,
                               p_period_name,
                               client.ledger_id);
            --dka_tools_pkg.put_debug_message(client.bill_to_customer_id||' - '||client.bill_to_site_use_id); --RBE artf2173619 optimisation
            --dka_tools_pkg.put_debug_message('==> v_solde  : '||v_solde);
 
            ----------------------------
            -- Calcul du ratio client --
            ----------------------------
            /*_ratio := calcul_ratio (client.bill_to_customer_id, client.bill_to_site_use_id,societe.set_of_books_id,
                                      societe.ircsoc,societe.ircreg, v_effective_period_num, v_solde);**/--YWA
            -------------------------------
            -- Affectation des variables --
            -------------------------------
            --v_ircsol := ROUND(v_solde, 2); --RBE artf2173619 opt
            ---_ircrat := v_ratio;---YWA
            
            --IF client.ircaux IS NOT NULL THEN --RBE artf2173619 ajouté dans cursor
                -- 15/06/2017 NBO artf2766197 : Exportation vers PELICAN DECLIC
                --utl_file.put_line(v_fileHandler,client.ircreg||';'||client.ircaux||';'||client.ircsoc||';'||v_ircdar||';'||ROUND(client.solde, 2)||';'||client.irclst||';'||client.irclcl); --RBE
                utl_file.put_line(v_fileHandler,client.ircreg||';'||client.ircaux||';'||client.ircsoc||';'||v_ircdar||';'||ROUND(v_solde, 2)||';'||client.irclst||';'||client.irclcl); --RBE
            --END IF;
            
            ---------------------------------------
            -- Insertion dans la table dka_i00rc --
            ---------------------------------------
            -- Modif EMA du 22/11/2006 : plus de test sur la valeur du ratio
            -- IF vn_ratio != 0 THEN
            --IF client.ircaux IS NOT NULL THEN --RBE fait dans le cursor
                INSERT INTO dka_i00rc
                   (ircreg, ircaux, ircsoc, ircdar,
                    ircsol, irclst, irclcl)
                VALUES
                   (client.ircreg, client.ircaux, client.ircsoc, v_ircdar,
                    -- 15/06/2017 NBO artf2766197 : Exportation vers PELICAN DECLIC
         --           ROUND(client.solde, 2),  client.irclst, client.irclcl);---YWA   --RBE artf2173619    
                    ROUND(v_solde, 2),  client.irclst, client.irclcl);---YWA   --RBE artf2173619    
           
            --END IF;
            -- END IF;
           --END LOOP;

            
            ---------------------------------
            -- CALCUL DE LA LIGNE DE TOTAL --  --YWA PLUS DE LIGNE DE TOTAL        ---------------------------------
            ---------------------
            -- Calcul du solde --
            ---------------------
            ---_solde := calcul_solde ( 'null','null',societe.org_id, v_period_name);---YWA        -- dka_tools_pkg.put_debug_message(client.bill_to_customer_id||' - '||client.bill_to_site_use_id);
            -- dka_tools_pkg.put_debug_message('==> v_solde  : '||v_solde);

            ----------------------------
            -- Calcul du ratio client --
            ----------------------------
            ---_ratio := calcul_ratio ( 'null','null',societe.set_of_books_id,societe.ircsoc,societe.ircreg, v_effective_period_num, v_solde);---YWA
            -------------------------------
            -- Affectation des variables --
            -------------------------------
            ---_ircsol := ROUND(v_solde, 2);---YWA        ---_ircrat := v_ratio;---YWA
         
            --utl_file.put_line(v_fileHandler,societe.ircreg||';'||'TOTAL'||';'||societe.ircsoc||';'||v_ircdar||';'||v_ircsol||';'||v_ircrat||';'||societe.irclst||';'||null);
       
             ------------------------------------------------------------
            -- Insertion de la ligne de total dans la table dka_i00rc --
            ------------------------------------------------------------
            -- Modif EMA du 22/11/2006 : plus de test sur la valeur du ratio
            -- IF vn_ratio != 0 THEN
            /*NSERT INTO dka_i00rc
               (ircreg, ircaux, ircsoc, ircdar,
                ircsol,  irclst, irclcl)
            VALUES
               -- Début modif EMA du 27/09/2005 : Le code société est renseigné par ' ' et non par NULL
               -- (rec_client.ircreg, rec_client.ircaux, NULL,    rec_client.ircdar,
               (societe.ircreg,' ',societe.ircsoc,v_ircdar,
               -- Fin modif EMA du 27/09/2005
               v_ircsol,             societe.irclst, 'TOTAL');**/--YWA        
            -- END IF;

            -- 25/06/2018 NBO artf2766197 : Exportation vers PELICAN DECLIC
            v_count := v_count + 1;
            
            IF nvl(v_count,0) >= 4000 THEN
              v_count := 0;
              COMMIT;
            END IF;
            
        END LOOP;
        dka_tools_pkg.put_log_message('Fin insertion table');
        
        dka_tools_pkg.put_debug_message('(-) extract_i00rc');
        
        -- Fermeture du fichier en écriture; --
        utl_file.fclose(v_fileHandler);
        
    EXCEPTION
        WHEN OTHERS THEN
             dka_tools_pkg.put_log_message('==> Erreur dans la fonction extract_i00rc');
             dka_tools_pkg.put_log_message('==> '||to_char(SQLCODE)||' - '||SQLERRM);
             pv_errbuf  := SQLCODE;
             pn_retcode := substr(SQLERRM, 1, 80);

    END extract_i00rc;

    --------------------------------------------------------------------------------
    --  Nom           : extract_i00eh
    --  Description   : procédure de remplissage de la table DKA_I00EH
    --
    --  PARAMETRES    : pv_errbuf   Entrée/Sortie    message d'erreur
    --                  pn_retcode         Sortie    code de retour: 'O=normal',
    ---                                                              '1=warning',
    --                                                               '2=erreur'
    --
    --  VALEUR RETOURNEE :
    --     Description       : ************************
    --     Valeurs possibles : ************************
    --------------------------------------------------------------------------------
    /*ROCEDURE extract_i00eh(pv_errbuf  IN OUT VARCHAR2,
                            pn_retcode    OUT NUMBER) IS
        vn_cost_iehmmo NUMBER;
        vn_cost_iehmfr NUMBER;
        vn_cost_iehmst NUMBER;
        vn_cost_iehmau NUMBER;
        vn_cost_iehmtv NUMBER;

        ------------------------------------
        -- Curseur de lecture des projets --
        ------------------------------------
        CURSOR cur_projets IS
            SELECT --substr(ppc_coded.code_description, 1, 7)                                     iehkid,  --PHENIX
                   ppc_coded.class_code                                                         iehkid,    --PHENIX
                   --substr(ppc_coded.code_description, 14, 30)                                   iehlid,  --PHENIX
                   substr(ppa_coded.description, instr(ppa_coded.description, '-', 1, 2)+1, 30) iehlid,    --PHENIX
                   --substr(ppc_coded.code_description, 10, 3)                                    iehsid,  --PHENIX
                   substr(ppc_societe.class_code, 2, 3)                                         iehsid,    --PHENIX
                   substr(ppa.attribute5, -2)                                                   iehkin,
                   NULL                                                                         iehlin,
                   ppa.segment1                                                                 iehkia,
                   --substr(ppa.NAME, 14, 30)                                                     iehlia,  --PHENIX
                   substr(ppa.name, instr(ppa.name, '-', 1, 2)+1, 30)                           iehlia,    --PHENIX
                   --substr(ppa.NAME, 10, 3)                                                      iehsia,  --PHENIX
                   substr(ppa.name, instr(ppa.name, '-', 1, 1)+2, 3)                            iehsia,    --PHENIX
                   to_char(to_date(ppa.attribute8, 'YYYY/MM/DD HH24:MI:SS'), 'YYYYMMDD')        iehdcl,
                   to_char(SYSDATE, 'YYYYMMDD')                                                 iehdtr,
                   to_char(ppea.end_date, 'YYYYMMDD')                                           iehdco,
                   NULL                                                                         iehkgs,
                   NULL                                                                         iehot1,
                   NULL                                                                         iehot2,
                   NULL                                                                         iehot3,
                   to_char(ppa.start_date, 'YYYYMMDD')                                          iehddt,
                   to_char(to_date(ppa.attribute2, 'YYYY/MM/DD HH24:MI:SS'), 'YYYYMMDD')        iehdft,
                   NULL                                                                         iehmmo,
                   NULL                                                                         iehmfr,
                   NULL                                                                         iehmst,
                   NULL                                                                         iehmtv,
                   NULL                                                                         iehtp3,
                   ppa.project_id                                                               project_id,
                   ppea.end_date                                                                end_date
            FROM   pa_projects_all       ppa,
                   pa_project_classes    ppc_codeh,
                   --pa_project_classes_v  ppc_coded,  --PHENIX
                   pa_project_classes    ppc_coded,    --PHENIX
                   pa_project_classes    ppc_societe,  --PHENIX
                   pa_projects_all       ppa_coded,    --PHENIX
                   (SELECT ppa.org_id,
                           MAX(ppa.start_date) start_date,
                           MAX(ppa.end_date)   end_date
                    FROM   pa_periods_all ppa
                    WHERE  ppa.status = 'C'
                    GROUP  BY ppa.org_id) ppea
            WHERE  ppa.project_type           = 'TRAVAUX INTERNES'
            AND    ppa.project_id             = ppc_codeh.project_id
            AND    ppc_codeh.class_category   = 'TYPE_CODE_H'
            AND    ppc_codeh.class_code    LIKE 'P3%'                      --JVI 14/06/06 
            AND    ppa.project_id             = ppc_coded.project_id(+)
            AND    ppc_coded.class_category   = 'CODE_ETABLISSEMENT'
            AND    ppa.project_id             = ppc_societe.project_id(+)  --PHENIX
            AND    ppc_societe.class_category = 'SOCIETE'                  --PHENIX
            AND    ppc_coded.class_code       = ppa_coded.segment1(+)      --PHENIX
            AND    ppa.org_id                 = ppea.org_id
            AND    to_date(ppa.attribute8, 'YYYY/MM/DD HH24:MI:SS') BETWEEN ppea.start_date
                                                                    AND     ppea.end_date;

        rec_projets cur_projets%ROWTYPE;

        -------------------------------------
        -- Fonction de calcul des dépenses --
        -------------------------------------
        FUNCTION calcul_cost(pn_project_id IN NUMBER,
                             pv_cost_type  IN VARCHAR2,
                             pd_end_date   IN DATE) RETURN NUMBER IS
            vn_cost NUMBER;
        BEGIN

            SELECT NVL(SUM(peia.burden_cost), 0)
            INTO   vn_cost
            FROM   pa_projects_all               ppa,
                   pa_tasks                      pt,
                   pa_expenditure_items_all      peia,
                   pa_expenditure_types_desc_v   petdv
            WHERE  ppa.project_id              = pn_project_id
            AND    ppa.project_id              = pt.project_id
            AND    pt.task_id                  = peia.task_id
            AND    peia.expenditure_type       = petdv.expenditure_type
            AND    ((petdv.attribute4          = pv_cost_type AND
                     pv_cost_type IS NOT NULL ) OR
                    (petdv.attribute4         IS NULL AND
                     pv_cost_type IS NULL ))
            AND    peia.expenditure_item_date <= pd_end_date;

            -- dka_tools_pkg.put_debug_message('==> calcul_cost '||pn_project_id||' - '||pv_cost_type||' - '||pd_end_date||' : '||vn_cost);

            RETURN nvl(vn_cost, 0);

        EXCEPTION
            WHEN OTHERS THEN
                 dka_tools_pkg.put_log_message('==> Erreur dans la fonction calcul_cost');
                 dka_tools_pkg.put_log_message('==> '||to_char(SQLCODE)||' - '||SQLERRM);
        END calcul_cost;

        ---------------------------------------
        -- Fonction de calcul des évènements --
        ---------------------------------------
        FUNCTION calcul_event(pn_project_id IN NUMBER,
                              pv_cost_type  IN VARCHAR2,
                              pd_end_date   IN DATE) RETURN NUMBER IS
            vn_cost NUMBER;
        BEGIN

            SELECT NVL(SUM(pe.revenue_amount), 0)
            INTO   vn_cost
            FROM   pa_events      pe,
                   pa_event_types pet
            WHERE  pe.project_id       = pn_project_id
            AND    pe.event_type       = pet.event_type
            AND    ((pet.attribute2    = pv_cost_type AND
                     pv_cost_type IS NOT NULL ) OR
                    (pet.attribute2   IS NULL AND
                     pv_cost_type IS NULL ))
            AND    pe.completion_date <= pd_end_date;

            -- dka_tools_pkg.put_debug_message('==> calcul_event '||pn_project_id||' - '||pv_cost_type||' - '||pd_end_date||' : '||vn_cost);

            RETURN nvl(vn_cost, 0);

        EXCEPTION
            WHEN OTHERS THEN
                 dka_tools_pkg.put_log_message('==> Erreur dans la fonction calcul_event');
                 dka_tools_pkg.put_log_message('==> '||to_char(SQLCODE)||' - '||SQLERRM);
        END calcul_event;


    BEGIN

        dka_tools_pkg.put_debug_message('(+) extract_i00eh');

        -----------------------------------------------------------
        -- Suppression des enregistrements de la table dka_i00eh --
        -----------------------------------------------------------
        DELETE FROM dka_i00eh;

        -----------------------------------
        -- Boucle de lecture des projets --
        -----------------------------------
        OPEN cur_projets;
        LOOP
            FETCH cur_projets INTO rec_projets;
            EXIT WHEN cur_projets%NOTFOUND;

            ---------------------------------------------------------
            -- Calcul des dépenses pour les différentes catégories --
            ---------------------------------------------------------
            -- dka_tools_pkg.put_debug_message(rec_projets.iehkia||' ('||rec_projets.project_id||')');
            vn_cost_iehmmo := calcul_cost(rec_projets.project_id, 'MAIN D''OEUVRE', rec_projets.end_date) -
                              calcul_event(rec_projets.project_id, 'MAIN D''OEUVRE', rec_projets.end_date);
            vn_cost_iehmfr := calcul_cost(rec_projets.project_id, 'FOURNITURES', rec_projets.end_date) -
                              calcul_event(rec_projets.project_id, 'FOURNITURES', rec_projets.end_date);
            vn_cost_iehmst := calcul_cost(rec_projets.project_id, 'SOUS-TRAITANCE', rec_projets.end_date) -
                              calcul_event(rec_projets.project_id, 'SOUS-TRAITANCE', rec_projets.end_date);
            vn_cost_iehmau := calcul_cost(rec_projets.project_id, NULL, rec_projets.end_date);

            -- dka_tools_pkg.put_debug_message('==> MAIN D''OEUVRE  : '||vn_cost_iehmmo);
            -- dka_tools_pkg.put_debug_message('==> FOURNITURES    : '||vn_cost_iehmfr);
            -- dka_tools_pkg.put_debug_message('==> SOUS-TRAITANCE : '||vn_cost_iehmst);
            -- dka_tools_pkg.put_debug_message('==> AUTRES         : '||vn_cost_iehmau);

            --------------------------------------------------------------------------------
            -- Les types de dépense pour lesquels le CUF n'est pas renseigné incrémentent --
            -- les dépenses de type 'FOURNITURES'                                         --
            --------------------------------------------------------------------------------
            vn_cost_iehmfr := vn_cost_iehmfr + vn_cost_iehmau;

            vn_cost_iehmtv := vn_cost_iehmmo + vn_cost_iehmfr + vn_cost_iehmst;

            ---------------------------------------
            -- Insertion dans la table dka_i00eh --
            ---------------------------------------
            INSERT INTO dka_i00eh
                (iehkid, iehlid, iehsid, iehkin,
                 iehlin, iehkia, iehlia, iehsia,
                 iehdcl, iehdtr, iehdco, iehkgs,
                 iehot1, iehot2, iehot3, iehddt,
                 iehdft, iehmmo, iehmfr, iehmst,
                 iehmtv, iehtp3)
            VALUES
                (rec_projets.iehkid, rec_projets.iehlid, rec_projets.iehsid, rec_projets.iehkin,
                 rec_projets.iehlin, rec_projets.iehkia, rec_projets.iehlia, rec_projets.iehsia,
                 rec_projets.iehdcl, rec_projets.iehdtr, rec_projets.iehdco, rec_projets.iehkgs,
                 rec_projets.iehot1, rec_projets.iehot2, rec_projets.iehot3, rec_projets.iehddt,
                 rec_projets.iehdft, vn_cost_iehmmo,     vn_cost_iehmfr,     vn_cost_iehmst,
                 vn_cost_iehmtv,     rec_projets.iehtp3);
        END LOOP;
        CLOSE cur_projets;
        NULL;

        dka_tools_pkg.put_debug_message('(-) extract_i00eh');
    EXCEPTION
        WHEN OTHERS THEN
             dka_tools_pkg.put_log_message('==> Erreur dans la fonction extract_i00eh');
             dka_tools_pkg.put_log_message('==> '||to_char(SQLCODE)||' - '||SQLERRM);
             pv_errbuf  := SQLCODE;
             pn_retcode := substr(SQLERRM, 1, 80);

    END extract_i00eh;**/--YWA
    --------------------------------------------------------------------------------
    --  Nom           : main
    --  Description   : procédure principale
    --
    --  PARAMETRES    : pv_errbuf   Entrée/Sortie    message d'erreur
    --                  pn_retcode         Sortie    code de retour: 'O=normal',
    ---                                                              '1=warning',
    --                                                               '2=erreur'
    --
    --  VALEUR RETOURNEE :
    --     Description       : ************************
    --     Valeurs possibles : ************************
    --------------------------------------------------------------------------------
    PROCEDURE main(pv_errbuf  IN OUT VARCHAR2,
                   pn_retcode    OUT NUMBER,
                   p_period_name VARCHAR2) IS
        vv_errbuf     VARCHAR2(500);
        vn_retcode    NUMBER;
        e_fatal_error EXCEPTION;
        v_end_date              gl_period_statuses.end_date%TYPE;
    BEGIN

        dka_tools_pkg.put_debug_message('(+) Main');

        ---------------------------------------------
        -- Initialisation des paramètres de sortie --
        ---------------------------------------------
        pn_retcode := 0;
        
        ---------------------------------------------
        -- verification de la periode cloturée pour toute les UO --
        ---------------------------------------------
        BEGIN 
            -- 09/06/2017 NBO artf2172224 - INT036 : Interface vers DECLIC - Le traitement se termine KO - Defect Bout en bout 763
            SELECT gps.end_date  --RBE artf2173619 au lieu de start_date
            INTO v_end_date
            FROM   gl_period_statuses gps
            WHERE  gps.application_id  = 222
            AND gps.closing_status  = 'C'
            AND gps.period_name = p_period_name
            --AND gps.set_of_books_id = ALL  (SELECT ledger_id FROM   gl_access_set_ledgers  WHERE access_set_id = fnd_profile.value('GL_ACCESS_SET_ID'))
            AND gps.set_of_books_id IN (SELECT ledger_id FROM   gl_access_set_ledgers  WHERE access_set_id = fnd_profile.value('GL_ACCESS_SET_ID'))
            AND ROWNUM=1;
        EXCEPTION
            WHEN OTHERS THEN
                dka_tools_pkg.put_log_message('==> Erreur lors de la recuperation de la periode la period ' ||p_period_name||' n''est pas cloturée pour tous les livres comptable');
                dka_tools_pkg.put_log_message('==> '||to_char(SQLCODE)||' - '||SQLERRM);     
                RAISE e_fatal_error;                
        END;
        
        

        ----------------------------------------------------------------
        -- Appel de la procédure de remplissage de la table DKA_I00RC --
        ----------------------------------------------------------------
        extract_i00rc(vn_retcode, vv_errbuf,p_period_name,v_end_date);
        IF vn_retcode = 1 THEN
            pn_retcode := 1;
            pv_errbuf  := vv_errbuf;
        ELSIF vn_retcode != 0 THEN
            pn_retcode := 2;
            pv_errbuf  := vv_errbuf;
            RAISE e_fatal_error;
        END IF;
        COMMIT;
        /*
        ----------------------------------------------------------------
        -- Appel de la procédure de remplissage de la table DKA_I00EH --
        ----------------------------------------------------------------
        extract_i00eh(vn_retcode, vv_errbuf);
        IF vn_retcode = 1 THEN
            pn_retcode := 1;
            pv_errbuf  := vv_errbuf;
        ELSIF vn_retcode != 0 THEN
            pn_retcode := 2;
            pv_errbuf  := vv_errbuf;
            RAISE e_fatal_error;
        END IF;

        COMMIT;*/---YWA    
        dka_tools_pkg.put_debug_message('(-) Main');

    EXCEPTION
        WHEN e_fatal_error THEN
            ROLLBACK;
            pn_retcode := 2;
        WHEN OTHERS THEN
            ROLLBACK;
            pn_retcode := 2;
            pv_errbuf  := SQLERRM;
    END main;

END dka_ideclic_pkg;
/
SHOW ERROR
EXIT
