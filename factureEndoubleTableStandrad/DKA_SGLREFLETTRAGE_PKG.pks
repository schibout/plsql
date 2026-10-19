----------------------------------------------------------------------------------------------
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : dka_po_dist_interface_bir.trg
-- DESCRIPTION      : Trigger sur la table PO_DISTRIBUTIONS_INTERFACE
---
--- AUTEUR           : Sebastien ROLAND (CGEY)
--- DATE DE CREATION : 31/01/2003
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- 23/10/2019 SEL INC0361012 Correctif Tri DA / Cde 
--- ---------- --- -------------------------------------------------------------------------
--------------------------------------------------------------------------------------------


PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DU TRIGGER dka_po_dist_interface_bir
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE OR REPLACE TRIGGER dka_po_dist_interface_bir
    BEFORE 
    INSERT
    ON po.po_distributions_interface
    FOR EACH ROW
    
DECLARE
vn_requisition_header_id NUMBER;
vn_nbre_ligne_interface NUMBER;
vn_nbre_ligne_DA NUMBER;
vv_action po_headers_interface.action%TYPE;
vv_group_code po_headers_interface.group_code%TYPE;
vn_seq NUMBER := 0;

BEGIN

     -- Vérification que c'est une nouvelle commande et non un ajout
     -- et que le mode de regroupement est "Demande d'appro." et non "Par défaut"
     BEGIN
            SELECT action,
                   group_code
              INTO vv_action,
                   vv_group_code
              FROM po_headers_interface phi
             WHERE phi.interface_header_id = :NEW.interface_header_id;
     EXCEPTION
         WHEN OTHERS THEN
         vv_action := NULL;
         vv_group_code := NULL;
     END;     
     
     
IF vv_action = 'NEW' AND vv_group_code = 'REQUISITION'
THEN
     -- Vérification que la future commande est faite à partir d'une seule DA
     BEGIN
            SELECT distinct prla.requisition_header_id
                  , count(pli.requisition_line_id)
              INTO vn_requisition_header_id
                  , vn_nbre_ligne_interface
              FROM po_requisition_lines_all prla,
                   po_lines_interface pli
             WHERE    prla.requisition_line_id = pli.requisition_line_id     
                  AND pli.interface_header_id = :NEW.interface_header_id
             GROUP BY prla.requisition_header_id;
     EXCEPTION
         WHEN OTHERS THEN
         vn_requisition_header_id := 0;
         vn_nbre_ligne_interface := 0;
     END;

     
     IF vn_requisition_header_id != 0
     THEN

           -- Vérification que c'est une création complète de DA et non partielle.
           BEGIN
            SELECT count(*)
              INTO vn_nbre_ligne_DA
              FROM po_requisition_lines_all prla
             WHERE prla.requisition_header_id = vn_requisition_header_id;
           EXCEPTION
             WHEN OTHERS THEN
                vn_nbre_ligne_DA := 0;
           END;

              IF vn_nbre_ligne_DA != 0 AND vn_nbre_ligne_DA = vn_nbre_ligne_interface
              THEN
              
                BEGIN
                  -- Mise à jour de la ligne correspondante dans po_lines_interface à partir du numéro de 
                  -- ligne de la DA d'origine
              
                  UPDATE po_lines_interface pli
                     SET line_num = (SELECT line_num 
                                       FROM po_requisition_lines_all prla
                                      WHERE prla.requisition_line_id = pli.requisition_line_id)
                        ,shipment_num = 1
                   WHERE interface_line_id = :NEW.interface_line_id
                     AND line_num IS NULL
                     AND shipment_num IS NULL;
                 EXCEPTION
                   WHEN OTHERS THEN
                   -- Ne rien faire
                   NULL;
                 END;  
             END IF;
      END IF;
END IF;
               
END;
/

SHOW ERROR

EXIT;