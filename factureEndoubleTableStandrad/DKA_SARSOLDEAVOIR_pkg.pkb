CREATE OR REPLACE TRIGGER APPS.dka_ap_invoices_dist_all_bri

-------------------------------------------------------------------------------
-- Capgemini
-- Projet       : Helios
-- Auteur       : Djamal BOUCHA
-- DATE Création    : 19.10.2001
-- Version livrables    :
--------------------------------------------------------------------------------
-- NOM                : dka_ap_invoices_all_bri.trg
-- DESCRIPTION        : Script de création du trigger dka_ap_invoices_all_bri
--
--------------------------------------------------------------------------------
---------------------------- M O D I F I C A T I O N S -------------------------
-- Version             :
-- DATE                :
-- Auteur              :
-- Problème            :
-- Solution            :
--------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--- 20/07/2004 SLE Portage spécifique pour projet PHENIX 2004
---            Evolution : mise en paiement automatique des factures ayant fait
---            l'objet d'un rapprochement ou, n'ayant pas fait l'objet
---            d'un rapprochement mais ayant un type de réglement par prélèvement
---            Pour cela, le trigger sera sur la table détails ap_invoice_distributions_all
---            au lieu de la table d'entête des factures ap_invoices_all
--- 14/08/2009 MT hold for credit invoices and invoices for SSTR type orders
--- 21/07/2016 BDE MAJ migration Helios
--- 24/03/2025 ARA EDB423
--------------------------------------------------------------------------------------------
    BEFORE INSERT
    ON ap_invoice_distributions_all  -- PHENIX 20004 ap_invoices_all  -> ap_invoice_distributions_all
    FOR EACH ROW
DECLARE
    vv_errbuf             VARCHAR2 (255);
    vn_retcode            NUMBER;
    gv_source             dka_parameters.varchar2_value%TYPE;
    gv_acompte            dka_parameters.varchar2_value%TYPE;
    gv_notes_de_frais     dka_parameters.varchar2_value%TYPE;
    gv_standard           dka_parameters.varchar2_value%TYPE;
    gv_hold_lookup_code   dka_parameters.varchar2_value%TYPE;
    vv_hold_description   ap_hold_codes.description%TYPE;
    rec_param             dka_parameters%ROWTYPE;
    vn_nbr                NUMBER;  -- PHENIX 2004 ajout
    vv_invoice_type       ap_invoices_all.invoice_type_lookup_code%TYPE; -- PHENIX 2004 Ajout
    vv_payment_method     ap_invoices_all.payment_method_lookup_code%TYPE; -- PHENIX 2004 Ajout
    vv_source             ap_invoices_all.source%TYPE;  -- PHENIX 2004 Ajout
    vv_order_type         VARCHAR2(5); --- 14/08/2009 MT
    gv_avoir              dka_parameters.varchar2_value%TYPE; --- 14/08/2009 MT
    --ARA EDB423
    vv_order_ivalua_type      VARCHAR2(5);

BEGIN

    dka_tools_pkg.get_parameter ('SAPBLOCAGE', 'SOURCE', rec_param, vv_errbuf, vn_retcode);
    gv_source            := rec_param.varchar2_value;

    IF vn_retcode != 0
    THEN
        app_exception.raise_exception;
    END IF;

    dka_tools_pkg.get_parameter ('SAPBLOCAGE', 'ACOMPTE', rec_param, vv_errbuf, vn_retcode);
    gv_acompte           := rec_param.varchar2_value;
    IF vn_retcode != 0
    THEN
        app_exception.raise_exception;
    END IF;

    dka_tools_pkg.get_parameter ('SAPBLOCAGE', 'NOTES_DE_FRAIS', rec_param, vv_errbuf, vn_retcode);
    gv_notes_de_frais    := rec_param.varchar2_value;

    IF vn_retcode != 0
    THEN
        app_exception.raise_exception;
    END IF;
    dka_tools_pkg.get_parameter ('SAPBLOCAGE', 'CREDIT', rec_param, vv_errbuf, vn_retcode);
    gv_avoir    := rec_param.varchar2_value;

    IF vn_retcode != 0
    THEN
        app_exception.raise_exception;
    END IF;

    dka_tools_pkg.get_parameter ('SAPBLOCAGE', 'STANDARD', rec_param, vv_errbuf, vn_retcode);
    gv_standard          := rec_param.varchar2_value;
    IF vn_retcode != 0
    THEN
        app_exception.raise_exception;
    END IF;

    IF (    :NEW.LINE_TYPE_LOOKUP_CODE =  'ITEM'  -- PHENIX 2004
       )                                          -- PHENIX 2004
    THEN                                          -- PHENIX 2004
        dka_tools_pkg.get_parameter ('SAPBLOCAGE', 'HOLD_LOOKUP_CODE', rec_param, vv_errbuf, vn_retcode);
        gv_hold_lookup_code    := rec_param.varchar2_value;

        IF vn_retcode != 0
        THEN
            app_exception.raise_exception;
        END IF;

        -- PHENIX 2004 Ajout
        SELECT count(*)
        INTO   vn_nbr
        FROM   ap_holds_all ah
        WHERE  ah.invoice_id = :NEW.invoice_id
        AND    ah.hold_lookup_code = gv_hold_lookup_code
        AND    ah.RELEASE_LOOKUP_CODE is null ;
        IF     vn_nbr = 0
        THEN

                SELECT hc.description
                INTO   vv_hold_description
                FROM   ap_hold_codes hc
                WHERE  hc.hold_lookup_code = gv_hold_lookup_code;
                SELECT invoice_type_lookup_code, payment_method_code, source
                INTO   vv_invoice_type, vv_payment_method, vv_source
                FROM   ap_invoices_all
                WHERE  invoice_id = :NEW.INVOICE_ID;
                --payment_method_code
                IF :NEW.po_distribution_id is not null THEN --- 14/08/2009 MT
                 SELECT Substr(segment1,-6,2) , substr(pha.segment1, 0, 2)
                   INTO vv_order_type , vv_order_ivalua_type
                  FROM po_headers_all pha,
                       po_distributions_all pda
                 WHERE pha.po_header_id=pda.po_header_id
                   AND pda.po_distribution_id=:NEW.po_distribution_id;
                END IF;
                IF (    vv_invoice_type IN (gv_acompte, gv_notes_de_frais, gv_standard,gv_avoir) --- 14/08/2009 MT
                AND vv_SOURCE = gv_source
                    )
                THEN
                    IF (:NEW.po_distribution_id is null and vv_payment_method != 'WIRE')
                      OR (:NEW.po_distribution_id is not null and vv_order_type='ST' and vv_payment_method != 'WIRE') --- 14/08/2009 MT
                    THEN
                AP_HOLDS_PKG.insert_single_hold  (:NEW.invoice_id,
                                X_Hold_Lookup_Code              =>   gv_hold_lookup_code,
                                 X_Hold_Reason                         =>   vv_hold_description,
                                 X_Held_By                                =>  fnd_global.user_id,
                                 X_calling_sequence =>'DKA_AP_INVOICES_BRI.trg');
                    END IF;-- fin IF :NEW.po_distribution_id is null and vv.payment_method != 'WIRE'
                    --ARA EDB423
                    IF (:NEW.po_distribution_id is null and vv_payment_method != 'WIRE')
                      OR (:NEW.po_distribution_id is not null and vv_order_ivalua_type='ST' and vv_payment_method != 'WIRE') --- 14/08/2009 MT
                    THEN
								    AP_HOLDS_PKG.insert_single_hold  (:NEW.invoice_id,
                                X_Hold_Lookup_Code              =>   gv_hold_lookup_code,
                                 X_Hold_Reason                         =>   vv_hold_description,
                                 X_Held_By                                =>  fnd_global.user_id,
                                 X_calling_sequence =>'DKA_AP_INVOICES_BRI.trg');
                    END IF;-- fin ARA EDB423
                END IF ; --( IF   vv.invoice_type IN (gv_acompte, gv_notes_de_frais, gv_standard) AND vv.SOURCE = gv_source
        END IF; -- IF     vn_nbr = 0
        -- fin PHENIX 2004
    END IF; -- PHENIX 2004

END;
/
SHOW ERRORS TRIGGER dka_ap_invoices_dist_all_bri
EXIT
