----------------------------------------------------------------------------------------------
-- $Id: DKA_PO_HEADERS_BIUR.trg 778 2008-06-10 16:08:49Z CORP\jjardez $
-- CAP GEMINI
-- PROJET            : DALKIA Oracle Applications
-- NOM               : dka_po_headers_biur.trg
-- DESCRIPTION      : Trigger sur la table PO_HEADERS_ALL
---
--- AUTEUR           : Sebastien ROLAND (CGEY)
--- DATE DE CREATION : 31/01/2003
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--- 04/02/2003 SRO Gérer le cas des commandes pur PO sans DIA où le demandeur est remplacé 
---                par le créateur de la commannde.
--------------------------------------------------------------------------------------------
--- 06/05/2004 CDE Modif suite ajout d'une deuxième ligne pour les employés partis
--------------------------------------------------------------------------------------------
--- 19/07/2004 STI Portage spécifique PHENIX 2004
---                ajout de la table gl_code_combinations, po_req_distribution_all
---                suppression de la table ht_organization_units 
--------------------------------------------------------------------------------------------
--- 27/12/2005 SRO Remplacement de DKA_PO_HEADERS_BUR2 par DKA_PO_HEADERS_BIUR pour déclencher
---                le trigger dès insertion ou mis à jour des 2 champs vendor_id et vendor_site_id
--------------------------------------------------------------------------------------------
--- 03/06/2008 JJA Correction sur l'étanchéité (business_group_id)
--------------------------------------------------------------------------------------------
--- 14/11/2012 JJA Correction la date d'inactivation du lieu de facturation
--------------------------------------------------------------------------------------------
--- 30/05/2016 MEG Migration R12
--------------------------------------------------------------------------------------------


PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DU TRIGGER dka_po_headers_biur
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE OR REPLACE TRIGGER dka_po_headers_biur
   BEFORE 
   INSERT
   or    
   UPDATE of vendor_id,vendor_site_id
   ON po.po_headers_all
   FOR EACH ROW
   WHEN (NVL(NEW.ATTRIBUTE7, 'ORACLE') NOT IN ('IVALUA', 'REPRISE') )   
DECLARE

    vv_to_person_id       po_requisition_lines_all.to_person_id%TYPE;
    vv_org_name           gl_code_combinations.segment1%TYPE; -- PHENIX 2004
    vv_location_id        hr_locations_all.location_id%TYPE;
    vn_org_id             po_requisition_lines_all.org_id%TYPE;
    ln_count              NUMBER;
    
BEGIN

    BEGIN
      
      SELECT prl.to_person_id
        , gcc.segment1 --PHENIX 2004
        , prl.org_id
        INTO vv_to_person_id
        , vv_org_name --PHENIX 2004
        , vn_org_id
        FROM po_requisition_headers_all prh
          	,po_requisition_lines_all   prl
         	  ,po_line_locations_all	    pll
         	  ,po_lines_all		    pl
         	  --PHENIX 2004
         	  ,po_req_distributions_all prda 
         	  , gl_code_combinations gcc
         	  --PHENIX 2004

       WHERE prda.code_combination_id  = gcc.code_combination_id -- PHENIX 2004
         AND prl.requisition_line_id   = prda.requisition_line_id -- PHENIX 2004
         AND prh.requisition_header_id = prl.requisition_header_id
         AND prl.line_location_id      = pll.line_location_id
         AND pll.po_line_id            = pl.po_line_id
         AND pl.po_header_id	         = :NEW.po_header_id
         AND ROWNUM = 1;

   EXCEPTION
        WHEN NO_DATA_FOUND
        THEN       
            vv_to_person_id := :NEW.agent_id;
            vn_org_id       := :NEW.org_id;
        WHEN OTHERS
        THEN
            app_exception.raise_exception;
    END;

    BEGIN
        BEGIN
            /* PHENIX 2004
            SELECT NAME
              INTO vv_org_name
              FROM hr_all_organization_units
             WHERE organization_id = :NEW.org_id;
	     FIN PHENIX 2004*/
            -- recherche si l'appartenance de l'employe est un site de facturation
           /* 
            SELECT location_id
              INTO vv_location_id
              FROM hr_locations_all hrla,
                   per_all_people_f pap
             WHERE pap.person_id = vv_to_person_id
               AND trunc(sysdate) between pap.effective_start_date and pap.effective_end_date
               AND hrla.location_code = pap.attribute1 || vv_org_name
               AND hrla.business_group_id = pap.business_group_id --JJA 2008/06/03
               AND NVL(hrla.inactive_date,SYSDATE) >= SYSDATE --JJA 2012/11/14
               AND hrla.bill_to_site_flag = 'Y';
           */
           
            -- recherche du lieu de facturation à partir de l'UO de la commande             
            SELECT fsp.bill_to_location_id
              INTO vv_location_id 
              FROM FINANCIALS_SYSTEM_PARAMS_ALL fsp
             WHERE fsp.org_id = vn_org_id;
           
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                /*
                BEGIN
                    -- recherche si le centre de rattachement de l'employe est un site de facturation
                    SELECT location_id
                      INTO vv_location_id
                      FROM hr_locations_all hrla,
                           per_all_people_f pap
                     WHERE pap.person_id = vv_to_person_id
                       AND trunc(sysdate) between pap.effective_start_date and pap.effective_end_date
                       AND hrla.location_code = pap.attribute3 || vv_org_name
                       AND hrla.business_group_id = pap.business_group_id --JJA 2008/06/03
                       AND NVL(hrla.inactive_date,SYSDATE) >= SYSDATE --JJA 2012/11/14
                       AND hrla.bill_to_site_flag = 'Y';
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        BEGIN
                            -- recherche si la region de rattachement de l'employe est un site de facturation
                            SELECT location_id
                              INTO vv_location_id
                              FROM hr_locations_all hrla,
                                   per_all_people_f pap
                             WHERE pap.person_id = vv_to_person_id
                               AND trunc(sysdate) between pap.effective_start_date and pap.effective_end_date
                               AND hrla.location_code = pap.attribute2 || vv_org_name
                               AND hrla.business_group_id = pap.business_group_id --JJA 2008/06/03
                               AND NVL(hrla.inactive_date,SYSDATE) >= SYSDATE --JJA 2012/11/14
                               AND hrla.bill_to_site_flag = 'Y';
                        EXCEPTION
                            WHEN NO_DATA_FOUND
                            THEN
                                vv_location_id    := NULL;
                            WHEN OTHERS
                            THEN
                                app_exception.raise_exception;
                        END;
                    WHEN OTHERS
                    THEN
                        app_exception.raise_exception;
                END;
                */
                vv_location_id    := NULL;
            WHEN OTHERS
            THEN
                app_exception.raise_exception;
        END;

        IF vv_location_id IS NOT NULL
        THEN
           :NEW.bill_to_location_id := vv_location_id;
        END IF;
    END;
END;
/
SHOW ERROR

EXIT;
