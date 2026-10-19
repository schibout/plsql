CREATE OR REPLACE TRIGGER DKA_IARPAFAC_INTERFACE_BRI
---------------------------------------------------------------------------------------------- 
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_IARPAFAC_INTERFACE_BRI.trg 
-- DESCRIPTION	    : Alimentation du champ IARPAFAC_ID
--
-- AUTEUR           : GUILLAUME CHABRIER
-- DATE DE CREATION : 03/01/02
-- DOC. ASSOCIEE    : 
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS                        
--                           
--------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- -------------------------------------------------------------------------
-- 03/05/2017 MEG artf2148687 : INT006 - Trigger DKA_IARPAFAC_INTERFACE_BRI
--                              MAJ du trigger pour l utilisateur XXEAI Defect#623
--------------------------------------------------------------------------------------------

BEFORE INSERT
ON dka.dka_iarpafac_interface
FOR EACH ROW
	
BEGIN
	
  SELECT dka_iarpafac_interface_s.nextval, sysdate
  INTO
  :new.iarpafac_id, :new.creation_date 
  FROM dual;

END;
/
SHOW ERRORS;
EXIT;
