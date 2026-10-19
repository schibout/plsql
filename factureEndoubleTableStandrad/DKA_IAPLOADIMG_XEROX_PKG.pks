/*<TOAD_FILE_CHUNK>*/
CREATE OR REPLACE PACKAGE BODY dka_tva_collectee_pkg
AS
--------------------------------------------------------------------------------------------
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_TVA_COLLECTEE_PKG.pkb
-- DESCRIPTION       : DKA_TVA_COLLECTEE_PKG package body :
---
--- AUTEUR           : Anthony Deltour(CGEY)
--- DATE DE CREATION : 06/02/2003
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A executer sous SQLPLUS avec le user APPS
--------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--  15/04/03   AD  Ajout d'une clause dans la proc insert_data et pour les 3 types de TVA afin
--                 de ne pas prendre les factures en cours de saisies ou inachevées.
--  17/06/03   AD  INSERT_DATA: Suppression de la clause DISPLAY_FLAG = 'Y' sur la TVA de type ENC.
--  27/08/03   FL  Insertion des lignes de facture exonérées de TVA: ajout de "AND rctt.name != 'MANUEL_REMBOUR_AVOIR'"
--  26/09/03   AD  Correction de la modification du 27/08/03 en ajoutant la jointure sur la table
--                 ra_customer_trx_all.
--  17/10/2003 XD  Ajout de clauses hint dans les INSERT pour améliorer les performances
--                 Modification de la TVA sur encaissement en remplacant le EXISTS par un IN
--                 Mise en forme du script
--  27/10/2003 AD  INSERT_DATA : Suppression de la jointure sur la table ar de distribution.
--                 Lorsqu'il existe 1 ligne de mouvement pour x lignes de ventilation, la ligne de taxe 
--                 est dupliquée x fois  dans le cas de TVA sur Débit ou Encaissement.
--  04/10/2004 SLE Portage spécifique pour projet PHENIX 2004
--                 Modification de la procédure insert_data 
--  04/04/2006 EMA La colonne "TVA sur la facture" ne récupère pas le montant situé sur la ligne de distribution 
--                 de la facture mais sur la ligne d'article de la facture.
--  27/07/2016 YWA Migration R12
--  08/06/2017 NBO artf2158298 - ETA030 : Paralléliser les sous-traitements
--  11/07/2017 YWA artf2193682 : ETA030 - ETAT TVA COLLECTEE PREPARATOIRE : l'état ne retourne pas de données - Defect BeB 
--  24/08/2017 MEG artf2211943 : ETA030 - TVA Collectée - état préparatoire - defect ORACLE_R12 #800
--                 artf2210295 : Etats de TVA - restriction du paramètre société en fonction de la responsabilité de lancement
--  28/09/2017 YWA artf2227918 : ETA030 - Revoir calcul Montant réglé sur la période
--  15/03/2018 MEG artf2431228 : ETA030 - Etat Preparatoire de la TVA Collectee
--  23/05/2018 MEG artf2646675 : INC0208665 code taux TVA "COL_VNDECL" n'etaient pas repris dans les états preparatoires de la TVA collectee
--  12/07/2018 OBE artf2668295 : ETA030 - TVA Collectée - état préparatoire "COL_VNDECL"
--  08/08/2018 OBE artf2982864 : INC0238851 : Factures qui ne ressortent pas sur les Etats 0744
--------------------------------------------------------------------------------------------
-- Variables globales
--
---------------------------------------------------------------------------------------------------------------
--  Nom           : Insert_data
--  Description   : Procédure d'insertion dans la table DKA_TVA_COLLECTEE des données nécessaires à l'édition
--                  de l'état sur la TVA Collectee pour les lignes de facture:_ exonérées de TVA
--                                                                            _ de TVA sur débit
--                                                                            _ de TVA sur encaissement
--  PARAMETRES    :
--     pn_ledger_id        Entrée
--     pv_code_societe           Entrée           Code Societe
--     pd_periode                Entrée           Période Comptable
--     pv_user_id                Entrée           User_id de l'utilisateur
--     pn_conc_request_id        Entrée           Request_id du traitement
--     pv_debug_mode             Entrée           Mode Debug ('Y' ou 'N')
--     pv_errbuf                 Entrée/Sortie    message d'erreur
--     pn_retcode                Sortie           code de retour: '0=normal', '1=warning', '2=erreur'
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************LEDGER_ID
---------------------------------------------------------------------------------------------------------------
    -- PHENIX 2004 Remplacement de substr(gcc.segment1, 4, 4) par gcc.segment1 et de 
    -- substr(gcc.segment1, 1, 3) par gcc.segment2 
    PROCEDURE insert_data (
        pn_ledger_id   IN       NUMBER,
        pv_code_societe      IN       VARCHAR2,
        pd_periode           IN       VARCHAR2,
        pn_user_id           IN       NUMBER,
        pn_conc_request_id   IN       NUMBER,
        pv_debug_mode        IN       VARCHAR2,
        pv_errbuff           IN OUT   VARCHAR2,
        pn_retcode           OUT      NUMBER
    )
    IS
        e_error_pkg     EXCEPTION;
        vv_errbuff      VARCHAR2 (500);
        vn_retcode      NUMBER;
        vd_date_debut   DATE;
        vd_date_fin     DATE;
    BEGIN
        dka_tools_pkg.put_outdebug_message ('DEBUT : Procedure Insert_data');
        -- Initialisation des variables --
        pv_errbuff       := NULL;
        pn_retcode       := 0;
        vv_errbuff       := NULL;
        vn_retcode       := 0;
        
        --  08/06/2017 NBO artf2158298 - ETA030 : Paralléliser les sous-traitements
        --vd_date_debut    := ('01-' || pd_periode);
        --vd_date_fin      := LAST_DAY ('01-' || pd_periode);
        
        select start_date,end_date--trunc(end_date, 'MONTH'), last_day(end_date) ---YWA artf2227918 
        into vd_date_debut, vd_date_fin
        from gl_period_statuses
        where application_id = 200 and period_name = pd_periode and set_of_books_id = pn_ledger_id;
        
        -- Insertion des lignes de facture exonérées de TVA --
        dka_tools_pkg.put_outdebug_message ('Insertion des lignes de facture exonérées de TVA');

        INSERT INTO dka_tva_collectee
            (SELECT /*+ RULE */
                    pn_ledger_id set_of_books_id,
                    pn_conc_request_id conc_request_id,
                    pv_debug_mode DEBUG_MODE, --pv_debug_mode DEBUG_MODE,
                    gcc.segment1 code_societe, -- PHENIX 2004 SUBSTR (gcc.segment1, 4, 4) 
                    gcc.segment2 centre_gestion, -- PHENIX 2004 SUBSTR (gcc.segment1, 1, 3) 
                    0 taux_tva,
                    'EXO.' type_tva,
                    NULL compte_tva,
                    rc.customer_number code_client,
                    SUBSTR (rc.customer_name, 1, 20) nom_client,
                    rcta.customer_trx_id customer_trx_id,
                    rcta.trx_number numero_facture,
                    rcta.doc_sequence_value sequence_facture,
                    rctla.customer_trx_line_id customer_trx_line_id,
                    rctla.line_number ligne_facture,
                    rctlgda.gl_date date_facture,
                    rctla.extended_amount montant_ht,
                    NULL montant_tva,
                    rctla.extended_amount montant_ttc,
                    NULL montant_regle,   -- mise a jour par la suite --
                    NULL ht_a_declarer,   -- mise a jour par la suite --
                    NULL tva_a_declarer,   -- mise a jour par la suite --
                    NULL montant_total_facture,   -- mise a jour par la suite --
                    NULL montant_total_regle,   -- mise a jour par la suite --
                    pn_user_id created_by,
                    SYSDATE creation_date,
                    pn_user_id last_updated_by,
                    SYSDATE last_update_date,
                    rcta.org_id
             FROM   ra_customer_trx_all rcta,
                    ra_customer_trx_lines_all rctla,
                    ra_cust_trx_line_gl_dist_all rctlgda,
                    gl_code_combinations gcc,
                    ar_customers rc,--YWA
                    ra_cust_trx_types_all rctt
             WHERE      rcta.bill_to_customer_id = rc.customer_id
                    AND rcta.complete_flag = 'Y'   /*Bug : Sélection des factures n'ayant pas de doc_sequence_value */
                    AND rcta.customer_trx_id = rctla.customer_trx_id
                    AND rcta.org_id         = rctla.org_id --YWA
                    AND rcta.set_of_books_id = pn_ledger_id
                    AND rcta.cust_trx_type_id = rctt.cust_trx_type_id
                    AND rctt.name != 'MAN_REMB_AVOIR' --'MANUEL_REMBOUR_AVOIR' -- OBE artf2668295
                    AND rctt.org_id = rcta.org_id--ywa
                    AND rctla.customer_trx_line_id = rctlgda.customer_trx_line_id
                    AND rctla.org_id = rctlgda.org_id--ywa
                    AND rctla.line_type = 'LINE'
                    AND rctlgda.code_combination_id = gcc.code_combination_id
                    AND rctlgda.gl_date BETWEEN (vd_date_debut) AND (vd_date_fin)
                    AND gcc.segment1 = NVL (pv_code_societe, gcc.segment1) -- PHENIX 2004 SUBSTR (gcc.segment1, 4, 4) = NVL (pv_code_societe, SUBSTR (gcc.segment1, 4, 4)) 
                    AND (NOT EXISTS (SELECT 'X'
                                    FROM   ra_customer_trx_lines_all rctla1
                                    WHERE      rctla1.link_to_cust_trx_line_id = rctla.customer_trx_line_id
                                           AND rctla1.line_type = 'TAX')
                         OR
                         EXISTS (SELECT 'X' 
                                   FROM ZX_LINES
                                  WHERE trx_id = rctla.customer_trx_id
                                    AND trx_line_id = rctla.customer_trx_line_id
                                    AND tax_rate = '0'
									AND tax_rate_code NOT IN ('COL_VNDECL') -- OBE artf2668295
								)
                        )
                    AND  gcc.segment3 in (SELECT Ffv.flex_value
                                            FROM Fnd_Flex_Value_Sets Ffvs,
                                                 Fnd_Flex_Values     Ffv
                                           WHERE Ffvs.Flex_Value_Set_Name =  'DKA_CPTE_PRDT_TVA_EXO'
                                             AND Ffvs.Flex_Value_Set_Id = Ffv.Flex_Value_Set_Id 
                                             AND Ffv.Enabled_Flag = 'Y'
                                             AND Trunc(SYSDATE) BETWEEN
                                                 Nvl(Ffv.Start_Date_Active, Trunc(SYSDATE))
                                                 AND Nvl(Ffv.End_Date_Active, Trunc(SYSDATE))));--YWA artf2193682 


        IF SQL%ROWCOUNT != 0
        THEN
            dka_tools_pkg.put_outdebug_message ('Nb de ligne de facture exonérées de TVA :' || SQL%ROWCOUNT);
        ELSE
            dka_tools_pkg.put_outdebug_message ('Pas de ligne de facture exonérées de TVA');
        END IF;

        dka_tools_pkg.put_outdebug_message ('Fin insertion des lignes de facture exonérées de TVA');
        -- Insertion des lignes de facture de TVA sur débit --
        dka_tools_pkg.put_outdebug_message ('Insertion des lignes de facture de TVA sur débit');

        INSERT INTO dka_tva_collectee
            (SELECT /*+ RULE */
                    pn_ledger_id set_of_books_id,
                    pn_conc_request_id conc_request_id,
                    pv_debug_mode DEBUG_MODE, --pv_debug_mode DEBUG_MODE,
                    gcc.segment1 code_societe, -- PHENIX 2004 SUBSTR (gcc.segment1, 4, 4) 
                    gcc.segment2 centre_gestion, -- PHENIX 2004 SUBSTR (gcc.segment1, 1, 3) 
                    --avta.tax_rate taux_tva,
                    --DECODE (avta.tax_type, 'VAT', DECODE (avta.tax_rate, 0, 'EXO.', 'DEB.'), 'DEFERRED', 'ENC.', 'LIG.') type_tva,
                    --DECODE (avta.tax_rate, 0, NULL, gcc.segment3) compte_tva,
                    rctla.tax_rate taux_tva,
                    'DEB.' type_tva ,--zrtv.reporting_type_code type_tva, --YWA artf2193682 
                    DECODE (rctla.tax_rate, 0, NULL, gcc.segment3) compte_tva,
                    rc.customer_number code_client,
                    SUBSTR (rc.customer_name, 1, 20) nom_client,
                    rcta.customer_trx_id customer_trx_id,
                    rcta.trx_number numero_facture,
                    rcta.doc_sequence_value sequence_facture,
                    rctla1.customer_trx_line_id customer_trx_line_id,
                    rctla1.line_number ligne_facture,
                    rctlgda.gl_date date_facture,
                    rctla1.extended_amount montant_ht,
                    -- Début modif EMA du 04/04/2006
                    -- rctla.extended_amount montant_tva,
                    rctlgda.amount montant_tva,
                    -- Fin modif EMA du 04/04/2006
                    rctla1.extended_amount + rctla.extended_amount montant_ttc,
                    NULL montant_regle,   -- mise a jour par la suite --
                    NULL ht_a_declarer,   -- mise a jour par la suite --
                    NULL tva_a_declarer,   -- mise a jour par la suite --
                    NULL montant_total_facture,   -- mise a jour par la suite --
                    NULL montant_total_regle,   -- mise a jour par la suite --
                    pn_user_id created_by,
                    SYSDATE creation_date,
                    pn_user_id last_updated_by,
                    SYSDATE last_update_date,
                    rcta.org_id
             FROM   ra_customer_trx_all rcta,
                    ra_customer_trx_lines_all rctla,
                    ra_cust_trx_line_gl_dist_all rctlgda,
                    ra_customer_trx_lines_all rctla1,
                    --ra_cust_trx_line_gl_dist_all rctlgda1,
                    gl_code_combinations gcc,
                    ar_customers rc,--YWA
                    --ar_vat_tax_all avta--YWA
                    zx_report_codes_assoc zrca,
                    zx_reporting_types_vl zrtv,
                    zx_reporting_codes_vl zrcv
             WHERE      rcta.bill_to_customer_id = rc.customer_id
                    AND rcta.complete_flag = 'Y'   /*Bug : Sélection des factures n'ayant pas de doc_sequence_value */
                    AND rcta.customer_trx_id = rctla.customer_trx_id
                    AND rcta.org_id         = rctla.org_id --YWA
                    AND rcta.set_of_books_id = pn_ledger_id
                    AND rctla.customer_trx_line_id = rctlgda.customer_trx_line_id
                    AND rctla.org_id = rctlgda.org_id--ywa
                    AND rctla.line_type = 'TAX'
                    AND rctlgda.code_combination_id = gcc.code_combination_id
                    AND rctlgda.gl_date BETWEEN (vd_date_debut) AND (vd_date_fin)
                    --AND rctla.vat_tax_id = avta.vat_tax_id --YWA
                    --AND avta.tax_type = 'VAT'--YWA
                    -------reporting tva debut YWA 
                    AND   zrca.reporting_type_id = zrtv.reporting_type_id
                    AND    zrcv.reporting_type_id(+) =zrca.reporting_type_id
                    AND    zrcv.reporting_code_id(+) = zrca.reporting_code_id
                    AND    (nvl(zrca.reporting_code_char_value,nvl(to_char(zrca.reporting_code_num_value),zrca.reporting_code_date_value)) =
                          nvl(zrcv.reporting_code_char_value,nvl(to_char(zrcv.reporting_code_num_value),zrcv.reporting_code_date_value)) 
                          OR
                          nvl(zrcv.reporting_code_char_value,nvl(to_char(zrcv.reporting_code_num_value),zrcv.reporting_code_date_value)) IS NULL)

                    AND entity_id = rctla.vat_tax_id
                    AND entity_code = 'ZX_RATES'
                    and decode(zrtv.reporting_type_datatype_code,
                                'TEXT',
                                zrca.reporting_code_char_value,
                                'YES_NO',
                                zrca.reporting_code_char_value,
                                'DATE',
                                zrca.reporting_code_date_value,
                                'NUMERIC_VALUE',
                                to_char(zrca.reporting_code_num_value)) = 'VAT'
                    ---------reporting tva fin YWA 
                    AND rctla.link_to_cust_trx_line_id = rctla1.customer_trx_line_id
                    --AND rctla1.customer_trx_line_id = rctlgda1.customer_trx_line_id
                    AND gcc.segment1 = NVL (pv_code_societe, gcc.segment1)
					--< OBE artf2982864
                    --AND rctla1.tax_classification_code NOT IN ('COL_VNDECL')
                    AND NOT EXISTS (
                     SELECT 1
                     FROM zx_lines
                     WHERE trx_id = rctla1.customer_trx_id
                     AND trx_line_id = rctla1.customer_trx_line_id
                     AND tax_rate_code IN ('COL_VNDECL')
                    )
			        --> OBE artf2982864
                    AND NOT EXISTS  (SELECT 1
                                       FROM ra_cust_trx_line_gl_dist_all rctlgda1,
                                            gl_code_combinations         gcc1,
                                            Fnd_Flex_Value_Sets          Ffvs,
                                            Fnd_Flex_Values              Ffv,
                                            zx_lines                     zl
                                      WHERE rctla1.customer_trx_line_id = rctlgda1.customer_trx_line_id
                                        AND rctlgda1.code_combination_id = gcc1.code_combination_id
                                        AND Ffvs.Flex_Value_Set_Name = 'DKA_CPTE_PRDT_TVA_EXO'
                                        AND Ffvs.Flex_Value_Set_Id = Ffv.Flex_Value_Set_Id
                                        AND Ffv.Enabled_Flag = 'Y'
                                        AND Trunc(SYSDATE) BETWEEN Nvl(Ffv.Start_Date_Active, Trunc(SYSDATE)) AND
                                            Nvl(Ffv.End_Date_Active, Trunc(SYSDATE))
                                        AND gcc1.segment3 = Ffv.flex_value
                                        AND zl.trx_id = rcta.customer_trx_id
                                        AND zl.trx_line_id = rctla1.customer_trx_line_id
                                        AND zl.tax_rate = '0'
                                        )
                                       
                                       
                    ); -- PHENIX 2004 SUBSTR (gcc.segment1, 4, 4) = NVL (pv_code_societe, SUBSTR (gcc.segment1, 4, 4)) 

        IF SQL%ROWCOUNT != 0
        THEN
            dka_tools_pkg.put_outdebug_message ('Nb de ligne de facture de TVA sur débit :' || SQL%ROWCOUNT);
        ELSE
            dka_tools_pkg.put_outdebug_message ('Pas de ligne de facture de TVA sur débit');
        END IF;

        dka_tools_pkg.put_outdebug_message ('Fin insertion des lignes de facture de TVA sur débit');
        -- Insertion des lignes de facture de TVA sur encaissement --
        dka_tools_pkg.put_outdebug_message ('Insertion des lignes de facture de TVA sur encaissement');

        INSERT INTO dka_tva_collectee
            (SELECT /*+ RULE */
                    pn_ledger_id set_of_books_id,
                    pn_conc_request_id conc_request_id,
                    pv_debug_mode DEBUG_MODE, --pv_debug_mode DEBUG_MODE,
                    gcc.segment1 code_societe, -- PHENIX 2004 SUBSTR (gcc.segment1, 4, 4) 
                    gcc.segment2 centre_gestion, -- PHENIX 2004 SUBSTR (gcc.segment1, 1, 3) 
                    --avta.tax_rate taux_tva,
                    --DECODE (avta.tax_type, 'VAT', 'DEB.', 'DEFERRED', 'ENC.', 'LIG.') type_tva,
                    rctla.tax_rate taux_tva,
                    'ENC.' type_tva,--zrtv.reporting_type_code type_tva,--YWA artf2193682 
                    gcc.segment3 compte_tva,
                    rc.customer_number code_client,
                    SUBSTR (rc.customer_name, 1, 20) nom_client,
                    rcta.customer_trx_id customer_trx_id,
                    rcta.trx_number numero_facture,
                    rcta.doc_sequence_value sequence_facture,
                    rctla.customer_trx_line_id customer_trx_line_id,
                    rctla1.line_number ligne_facture,
                    rctlgda.gl_date date_facture,
                    rctla1.extended_amount montant_ht,
                    -- Début modif EMA du 04/04/2006
                    -- rctla.extended_amount montant_tva,
                    rctlgda.amount montant_tva,
                    -- Fin modif EMA du 04/04/2006
                    rctla1.extended_amount + rctla.extended_amount montant_ttc,
                    NULL montant_regle,   -- mise a jour par la suite --
                    NULL ht_a_declarer,   -- mise a jour par la suite --
                    NULL tva_a_declarer,   -- mise a jour par la suite --
                    NULL montant_total_facture,   -- mise a jour par la suite --
                    NULL montant_total_regle,   -- mise a jour par la suite --
                    pn_user_id created_by,
                    SYSDATE creation_date,
                    pn_user_id last_updated_by,
                    SYSDATE last_update_date,
                    rcta.org_id
             FROM   ra_customer_trx_all rcta,
                    ra_customer_trx_lines_all rctla,
                    ra_cust_trx_line_gl_dist_all rctlgda,
                    ra_customer_trx_lines_all rctla1,
                    --ra_cust_trx_line_gl_dist_all rctlgda1,
                    gl_code_combinations gcc,
                    ar_customers rc,--YWA
                    --ar_vat_tax_all avta
                     zx_report_codes_assoc zrca,
                    zx_reporting_types_vl zrtv,
                    zx_reporting_codes_vl zrcv
             WHERE      rcta.bill_to_customer_id = rc.customer_id
                    AND rcta.complete_flag = 'Y'   /*Bug : Sélection des factures n'ayant pas de doc_sequence_value */
                    AND rcta.customer_trx_id = rctla.customer_trx_id
                    AND rcta.org_id         = rctla.org_id --YWA
                    AND rcta.set_of_books_id = pn_ledger_id
                    AND rctla.customer_trx_line_id = rctlgda.customer_trx_line_id
                    AND rctla.org_id = rctlgda.org_id--ywa
                    AND rctla.line_type = 'TAX'
                    AND rctlgda.code_combination_id = gcc.code_combination_id
                    --AND rctla.vat_tax_id = avta.vat_tax_id
                    --AND avta.tax_type = 'DEFERRED'
                    -------reporting tva debut YWA 
                    AND   zrca.reporting_type_id = zrtv.reporting_type_id
                    AND    zrcv.reporting_type_id(+) =zrca.reporting_type_id
                    AND    zrcv.reporting_code_id(+) = zrca.reporting_code_id
                    AND    (nvl(zrca.reporting_code_char_value,nvl(to_char(zrca.reporting_code_num_value),zrca.reporting_code_date_value)) =
                          nvl(zrcv.reporting_code_char_value,nvl(to_char(zrcv.reporting_code_num_value),zrcv.reporting_code_date_value)) 
                          OR
                          nvl(zrcv.reporting_code_char_value,nvl(to_char(zrcv.reporting_code_num_value),zrcv.reporting_code_date_value)) IS NULL)

                    AND entity_id = rctla.vat_tax_id
                    AND entity_code = 'ZX_RATES'
                    and decode(zrtv.reporting_type_datatype_code,
					  'TEXT',
					  zrca.reporting_code_char_value,
					  'YES_NO',
					  zrca.reporting_code_char_value,
					  'DATE',
					  zrca.reporting_code_date_value,
					  'NUMERIC_VALUE',
					  to_char(zrca.reporting_code_num_value)) = 'DEFERRED'
            ---------reporting tva fin YWA 
            AND rctla.link_to_cust_trx_line_id = rctla1.customer_trx_line_id
            --AND rctla1.customer_trx_line_id = rctlgda1.customer_trx_line_id
            AND gcc.segment1 = NVL (pv_code_societe, gcc.segment1) -- PHENIX 2004 SUBSTR (gcc.segment1, 4, 4) = NVL (pv_code_societe, SUBSTR (gcc.segment1, 4, 4)) 
			--< OBE artf2982864
            --AND rctla1.tax_classification_code NOT IN ('COL_VNDECL')
			AND NOT EXISTS (
             SELECT 1
             FROM zx_lines
             WHERE trx_id = rctla1.customer_trx_id
             AND trx_line_id = rctla1.customer_trx_line_id
             AND tax_rate_code IN ('COL_VNDECL')
            )
			--> OBE artf2982864
            --AND    EXISTS
            --          ( SELECT 'X'
            --            FROM   ar_receivable_applications_all araa
            --            WHERE  araa.applied_customer_trx_id = rcta.customer_trx_id
            --            --AND    araa.display = 'Y'
            --            AND    araa.gl_date
            --                    BETWEEN (vd_date_debut)
            --                       AND    (vd_date_fin))
            AND rcta.customer_trx_id IN (SELECT araa.applied_customer_trx_id
                                         FROM   ar_receivable_applications_all araa
                                         WHERE  araa.gl_date BETWEEN (vd_date_debut) AND (vd_date_fin)));

        IF SQL%ROWCOUNT != 0
        THEN
            dka_tools_pkg.put_outdebug_message ('Nb de ligne de facture de TVA sur encaissement :' || SQL%ROWCOUNT);
        ELSE
            dka_tools_pkg.put_outdebug_message ('Pas de ligne de facture de TVA sur encaissement');
        END IF;

        dka_tools_pkg.put_outdebug_message ('Fin insertion des lignes de facture de TVA sur encaissement');
        COMMIT;
        -- Mise à jour du montant total et du montant total réglé --
        --  08/06/2017 NBO artf2158298 - ETA030 : Paralléliser les sous-traitements
        update_totaux_fact_regl (vd_date_debut, vd_date_fin, pn_conc_request_id, vv_errbuff, vn_retcode);

        IF vn_retcode != 0
        THEN
            RAISE e_error_pkg;
        END IF;

        COMMIT;
        -- Mise à jour du montant_regle , _HT, _TVA , pour les différents type de TVA:
        -- Exonéré , débit , Encaissement
        --  08/06/2017 NBO artf2158298 - ETA030 : Paralléliser les sous-traitements
        update_amount_ht_tva (pn_conc_request_id, vv_errbuff, vn_retcode);

        IF vn_retcode != 0
        THEN
            RAISE e_error_pkg;
        END IF;

        COMMIT;
        -- Mise à jour du montant_regle dans le cas ou il y plusieurs lignes de TVA sur encaissement --
        --  08/06/2017 NBO artf2158298 - ETA030 : Paralléliser les sous-traitements
        update_montant_regle (pn_conc_request_id, vv_errbuff, vn_retcode);

        IF vn_retcode != 0
        THEN
            RAISE e_error_pkg;
        END IF;

        COMMIT;
    EXCEPTION
        WHEN e_error_pkg
        THEN
            ROLLBACK;
            dka_tools_pkg.put_outdebug_message ('ERREUR Insert_data');
            dka_tools_pkg.put_outdebug_message (vv_errbuff);
            pn_retcode    := 2;
            pv_errbuff    := vv_errbuff;
        WHEN OTHERS
        THEN
            ROLLBACK;
            pn_retcode    := 2;
            pv_errbuff    := ('Une erreur est apparue lors de la procedure insert_data. ');
            dka_tools_pkg.put_outdebug_message (pv_errbuff);
            dka_tools_pkg.put_outdebug_message (SQLCODE || '-' || SQLERRM);
    END insert_data;

---------------------------------------------------------------------------------------------------------------
--  Nom           : update_totaux_fact_regl
--  Description   : Mise a jour du montant total de la facture et du montant total réglé
--
--  PARAMETRES    :
--     pd_gl_date_debut          Entree
--     pd_gl_date_fin            Entree
--     pv_errbuf                 Entrée/Sortie    message d'erreur
--     pn_retcode                Sortie           code de retour: '0=normal', '1=warning', '2=erreur'
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
--  08/06/2017 NBO artf2158298 - ETA030 : Paralléliser les sous-traitements 
   PROCEDURE update_totaux_fact_regl (
        pd_gl_date_debut   IN       DATE,
        pd_gl_date_fin     IN       DATE,
        pn_conc_request_id IN       NUMBER,
        pv_errbuff         IN OUT   VARCHAR2,
        pn_retcode         OUT      NUMBER
    )
    IS
        -- Curseur de mise à jour du montant réglé --
        CURSOR cur_montant_regle
        IS
            SELECT dtc.customer_trx_id,
                   dtc.montant_total_regle
            FROM   dka_tva_collectee dtc
            --  08/06/2017 NBO artf2158298 - ETA030 : Paralléliser les sous-traitements
            WHERE  request_id = pn_conc_request_id;

        rec_tva_collectee_amount   cur_montant_regle%ROWTYPE;
    BEGIN
        -- Initialisation des variables --
        pn_retcode    := 0;
        dka_tools_pkg.put_outdebug_message ('Début procédure update_totaux_fact_regl');

        -- Pour toutes les factures de la table DKA_TVA_COLLECTEE, calcul du montant total --
        -- de la facture ainsi que le montant total réglé --
        UPDATE dka_tva_collectee dtc
        SET montant_total_facture = (SELECT rctlgda.amount
                                     FROM   ra_cust_trx_line_gl_dist_all rctlgda
                                     WHERE      rctlgda.customer_trx_id = dtc.customer_trx_id
                                            AND rctlgda.account_class = 'REC'),
            montant_total_regle = (SELECT NVL (SUM (araa.amount_applied), 0)
                                   FROM   ar_receivable_applications_all araa
                                   WHERE      araa.applied_customer_trx_id = dtc.customer_trx_id
                                   AND araa.gl_date BETWEEN pd_gl_date_debut AND pd_gl_date_fin)
        --  08/06/2017 NBO artf2158298 - ETA030 : Paralléliser les sous-traitements
        WHERE request_id = pn_conc_request_id;

        -- Soustraction des ajustements realisés pour la période concernée --
        -- Ouverture du curseur --
        OPEN cur_montant_regle;

        -- Boucle de lecture sur DKA_TVA_COLLECTEE --
        LOOP
            FETCH cur_montant_regle
            INTO  rec_tva_collectee_amount;

            EXIT WHEN cur_montant_regle%NOTFOUND;

            DECLARE
                vn_amount_applied   ar_receivable_applications_all.amount_applied%TYPE;
            BEGIN
                vn_amount_applied    := 0;

                -- calcul des ajustements effectués sur les lignes de facture --
                SELECT NVL (SUM (aaa.amount), 0)
                INTO   vn_amount_applied
                FROM   ar_adjustments_all aaa
                WHERE      aaa.customer_trx_id = rec_tva_collectee_amount.customer_trx_id
                       AND aaa.gl_date BETWEEN pd_gl_date_debut AND pd_gl_date_fin;

                -- Mise a jour du montant réglé --
                IF vn_amount_applied != 0
                THEN
                    UPDATE dka_tva_collectee dtc
                    SET dtc.montant_total_regle = (rec_tva_collectee_amount.montant_total_regle - vn_amount_applied)
                    WHERE  dtc.customer_trx_id = rec_tva_collectee_amount.customer_trx_id
                    --  08/06/2017 NBO artf2158298 - ETA030 : Paralléliser les sous-traitements
                    AND request_id = pn_conc_request_id;
                END IF;
            EXCEPTION
                WHEN OTHERS
                THEN
                    dka_tools_pkg.put_debug_message (SQLCODE || '=' || SUBSTR (SQLERRM, 1, 400));
                    pv_errbuff    := 'UPDATE_TOTAUX_FACT_REGL - MONTANT_TOTAL_REGLE ' || SQLERRM;
                    pn_retcode    := SQLCODE;
            END;
        END LOOP;

        CLOSE cur_montant_regle;

        -- dka_tools_pkg.put_outdebug_message ('Nb de facture mise à jour :' || SQL%ROWCOUNT );
        dka_tools_pkg.put_outdebug_message ('Fin de la procedure update_totaux_fact_regl');
    EXCEPTION
        WHEN OTHERS
        THEN
            dka_tools_pkg.put_debug_message (SQLCODE || '=' || SUBSTR (SQLERRM, 1, 400));
            pv_errbuff    := 'UPDATE_TOTAUX_FACT_REGL - ' || SQLERRM;
            pn_retcode    := SQLCODE;
    END update_totaux_fact_regl;

---------------------------------------------------------------------------------------------------------------
--  Nom           : update_amount_ht_tva
--  Description   : Mise a jour du montant ht_a_declarer et tva_a_declarer pour les 3
--                  types de TVA.
--  PARAMETRES    :
--     pv_errbuf                 Sortie           message d'erreur
--     pn_retcode                Sortie           code de retour: '0=normal', '1=warning', '2=erreur'
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
--  08/06/2017 NBO artf2158298 - ETA030 : Paralléliser les sous-traitements
    PROCEDURE update_amount_ht_tva (
        pn_conc_request_id   IN       NUMBER,
        pv_errbuff   OUT   VARCHAR2,
        pn_retcode   OUT   NUMBER
    )
    IS
    BEGIN
        -- Initialisation des variables --
        pn_retcode    := 0;
        dka_tools_pkg.put_outdebug_message ('Début procédure update_amount_ht_tva');

        -- Mise à jour des montants réglés ht et tva à déclarer pour les lignes de facture exonéré de TVA--
        UPDATE dka_tva_collectee dtc
        SET dtc.montant_regle = NULL,
            dtc.ht_a_declarer = montant_ht,
            dtc.tva_a_declarer = NULL
        WHERE  dtc.type_tva IN ('EXO.')
        --  08/06/2017 NBO artf2158298 - ETA030 : Paralléliser les sous-traitements
        AND request_id = pn_conc_request_id;

        dka_tools_pkg.put_outdebug_message ('Nb de lignes de facture exonérées ddde TVA et updatées : ' || SQL%ROWCOUNT);

        -- Mise à jour des montants réglés ht et tva à déclarer pour les lignes de facture de TVA sur débit --
        UPDATE dka_tva_collectee dtc
        SET dtc.montant_regle = NULL,
            dtc.ht_a_declarer = montant_ht,
            dtc.tva_a_declarer = montant_tva
        WHERE  dtc.type_tva IN ('DEB.')
        --  08/06/2017 NBO artf2158298 - ETA030 : Paralléliser les sous-traitements
        AND request_id = pn_conc_request_id;

        dka_tools_pkg.put_outdebug_message ('Nb de lignes de facture de TVA sur débit et updatées : ' || SQL%ROWCOUNT);

        -- Mise à jour des montants réglés ht et tva à déclarer pour les lignes de facture de TVA sur encaissement --
        UPDATE dka_tva_collectee dtc
        SET dtc.montant_regle = montant_total_regle,
            dtc.ht_a_declarer = ROUND ((montant_total_regle / montant_total_facture) * montant_ht, 2),
            dtc.tva_a_declarer = ROUND ((montant_total_regle / montant_total_facture) * montant_tva, 2)
        WHERE  dtc.type_tva IN ('ENC.')
        --  08/06/2017 NBO artf2158298 - ETA030 : Paralléliser les sous-traitements
        AND request_id = pn_conc_request_id;

        dka_tools_pkg.put_outdebug_message ('Nb de lignes de facture de TVA sur encaissement et updatées : ' || SQL%ROWCOUNT);
        dka_tools_pkg.put_outdebug_message ('Fin procédure update_amount_ht_tva');
    EXCEPTION
        WHEN OTHERS
        THEN
            ROLLBACK;
            dka_tools_pkg.put_debug_message (SQLCODE || '=' || SUBSTR (SQLERRM, 1, 400));
            pv_errbuff    := 'UPDATE_AMOUNT_HT_TVA - ' || SQLERRM;
            pn_retcode    := SQLCODE;
    END update_amount_ht_tva;

---------------------------------------------------------------------------------------------------------------
--  Nom           : update_montant_regle
--  Description   : Dans le cas où il existe, pour une seule facture, plusieurs lignes de TVA sur
--                  encaissement, on répartit le montant réglé sur ces lignes. La répartition du montant
--                  réglé se fait au prorata des montants HT à déclarer.
--
--  PARAMETRES    :
--     pv_errbuf                 Sortie           message d'erreur
--     pn_retcode                Sortie           code de retour: '0=normal', '1=warning', '2=erreur'
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
--  08/06/2017 NBO artf2158298 - ETA030 : Paralléliser les sous-traitements
   PROCEDURE update_montant_regle (
        pn_conc_request_id   IN       NUMBER,
        pv_errbuff   OUT   VARCHAR2,
        pn_retcode   OUT   NUMBER
    )
    IS
        -- Curseur de recherche des factures ayant plusieurs lignes de tva sur encaissement --
        CURSOR cur_tva_collectee
        IS
            SELECT   customer_trx_id,
                     SUM (ht_a_declarer) total_ht_a_declarer,
                     COUNT (*) nombre
            FROM     dka_tva_collectee
            WHERE    type_tva = 'ENC.'
            --  08/06/2017 NBO artf2158298 - ETA030 : Paralléliser les sous-traitements
            AND      request_id = pn_conc_request_id
            GROUP BY customer_trx_id
            HAVING   COUNT (*) > 1;

        rec_tva_collectee   cur_tva_collectee%ROWTYPE;
    BEGIN
        -- Initialisation des variables --
        pn_retcode    := 0;
        dka_tools_pkg.put_outdebug_message ('Debut procédure update_montant_regle');

        OPEN cur_tva_collectee;

        -- Boucle de lecture sur la table DKA_TVA_COLLECTEE --
        LOOP
            FETCH cur_tva_collectee
            INTO  rec_tva_collectee;

            EXIT WHEN cur_tva_collectee%NOTFOUND;

            UPDATE dka_tva_collectee
            SET montant_regle = ht_a_declarer+ tva_a_declarer/* ROUND (
                                     (
                                        ht_a_declarer
                                      / DECODE (rec_tva_collectee.total_ht_a_declarer, 0, 1, rec_tva_collectee.total_ht_a_declarer)
                                     )
                                   * montant_total_regle,
                                   2
                               )*/
            WHERE      customer_trx_id = rec_tva_collectee.customer_trx_id
                   AND type_tva = 'ENC.'
                   --  08/06/2017 NBO artf2158298 - ETA030 : Paralléliser les sous-traitements
                   AND      request_id = pn_conc_request_id;
        END LOOP;

        CLOSE cur_tva_collectee;

        dka_tools_pkg.put_outdebug_message ('Fin procédure update_montant_regle');
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            dka_tools_pkg.put_outdebug_message ('UPDATE_MONTANT_REGLE - NO_DATA_FOUND');
        WHEN OTHERS
        THEN
            ROLLBACK;
            dka_tools_pkg.put_debug_message (SQLCODE || '=' || SUBSTR (SQLERRM, 1, 400));
            pv_errbuff    := 'UPDATE_MONTANT_REGLE - ' || SQLERRM;
            pn_retcode    := SQLCODE;
    END update_montant_regle;

---------------------------------------------------------------------------------------------------------------
--  Nom           : Delete_data
--  Description   : Procédure Supprime les données dans la table DKA_TVA_COLLECTEE en fonction
--                  du Request_id
--  PARAMETRES    :
--     pn_ledger_id        Entrée
--     pv_code_societe           Entrée           Code Societe
--     pd_periode                Entrée           Période Comptable
--     pv_user_id                Entrée           User_id de l'utilisateur
--     pn_conc_request_id        Entrée           Request_id du traitement
--     pv_debug_mode             Entrée           Mode Debug ('Y' ou 'N')
--     pv_errbuff                 Entrée/Sortie    message d'erreur
--     pn_retcode                Sortie           code de retour: '0=normal', '1=warning', '2=erreur'
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
    PROCEDURE delete_data (
        pn_ledger_id   IN       NUMBER,
        pn_conc_request_id   IN       NUMBER,
        pv_debug_mode        IN       VARCHAR2,
        pv_errbuff           IN OUT   VARCHAR2,
        pn_retcode           OUT      NUMBER
    )
    IS
    BEGIN
        --Initialisation des variables--
        pv_errbuff    := NULL;
        pn_retcode    := 0;
        dka_tools_pkg.put_outdebug_message ('DEBUT : Purge de la table DKA_TVA_COLLECTEE');

        --Suppression des données en fonction du request_id--
        IF pv_debug_mode = 'N'
        THEN
            DELETE FROM dka_tva_collectee
            WHERE           request_id = pn_conc_request_id
                        AND DEBUG_MODE = pv_debug_mode
                        AND set_of_books_id = pn_ledger_id;
        END IF;

        -- Controle du nb d'enregistrement supprimé --
        IF SQL%ROWCOUNT != 0
        THEN
            dka_tools_pkg.put_outdebug_message ('Nombre d enregistrement à supprimmer :' || SQL%ROWCOUNT);
            COMMIT;
        ELSE
            dka_tools_pkg.put_outdebug_message ('Pas de données supprimées');
        END IF;

        dka_tools_pkg.put_outdebug_message ('FIN : Procédure Delete_data');
    EXCEPTION
        WHEN OTHERS
        THEN
            ROLLBACK;
            pn_retcode    := 2;
            pv_errbuff    := ('Erreur lors de la tentavive de suppression dans DKA_TVA_CLLECTEE');
            dka_tools_pkg.put_outdebug_message (pv_errbuff);
            dka_tools_pkg.put_outdebug_message ('ERREUR :' || SQLCODE || '-' || SQLERRM);
    END delete_data;
END dka_tva_collectee_pkg;   --package body
/
/*<TOAD_FILE_CHUNK>*/
SHOW ERRORS;
EXIT
