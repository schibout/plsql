CREATE OR REPLACE TRIGGER DKA_stransco_lines_BIUR
---------------------------------------------------------------------------------------------- 
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_STRANSCO_LINES_BUIR.trg 
-- DESCRIPTION	    : trigger de mise à jour du champ params_value
--            par concatenation des champ param1_value, paramé_value, Param3_value
--            de la table dka_stransco_lines
--
-- AUTEUR           : Marc LAMBS
-- DATE DE CREATION : 20/12/2001
-- DOC. ASSOCIEE    : 
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS                        
--                           
--------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- -------------------------------------------------------------------------
-- 
--------------------------------------------------------------------------------------------
BEFORE INSERT OR UPDATE
  ----- le trigger se déclenche à chaque création ou modification  
OF param1_value , param2_value, param3_value ,params_value
ON dka_stransco_lines
FOR EACH ROW
BEGIN  
       :NEW.params_value := :NEW.param1_value ||:NEW.param2_value||:NEW.param3_value;
END;
/
SHOW ERRORS;
EXIT;
