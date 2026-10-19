----------------------------------------------------------------------------------------------
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_PO_HEADERS_BUR.trg
-- DESCRIPTION      : Trigger sur la table PO_HEADERS_ALL
---
--- AUTEUR           : Bernard HANQUIER (CGEY)
--- DATE DE CREATION : 05/04/2002
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
---
--------------------------------------------------------------------------------------------


PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DU TRIGGER dka_po_headers_bur
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE OR REPLACE TRIGGER dka_po_headers_bur
   BEFORE UPDATE
   ON po.po_headers_all
   FOR EACH ROW
   WHEN (   (   OLD.authorization_status IS  NULL
             OR OLD.authorization_status <> 'APPROVED'
            )
         AND NEW.authorization_status = 'APPROVED'
         AND NVL(NEW.ATTRIBUTE7, 'ORACLE') NOT IN ('IVALUA', 'REPRISE')  
        )
DECLARE
   vv_apps_source_code   po_requisition_headers_all.apps_source_code%TYPE;
   vv_to_person_id       po_requisition_lines_all.to_person_id%TYPE;
BEGIN
     
   BEGIN
      SELECT prh.apps_source_code
            ,prl.to_person_id
        INTO vv_apps_source_code
            ,vv_to_person_id
        FROM po_requisition_headers_all prh
          	,po_requisition_lines_all   prl
         	,po_line_locations_all	    pll
         	,po_lines_all		    pl
       WHERE prh.requisition_header_id = prl.requisition_header_id
         AND prl.line_location_id      = pll.line_location_id
         AND pll.po_line_id            = pl.po_line_id
         AND pl.po_header_id	         = :NEW.po_header_id
         AND ROWNUM = 1;



      IF vv_apps_source_code = 'POR'
      THEN
         :NEW.agent_id := NVL (vv_to_person_id, :NEW.agent_id);
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         NULL;
      WHEN OTHERS
      THEN
         app_exception.raise_exception;
   END;

END;
/
SHOW ERROR

EXIT;
