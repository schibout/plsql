CREATE OR REPLACE TRIGGER DKA_stransco_headers_BDR
---------------------------------------------------------------------------------------------- 
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_STRANSCO_HEADERS_BDR.trg 
-- DESCRIPTION	    : suppression des lignes de la tables des lignes correspondant à la table 
-- des entetes en cours de suppression
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
BEFORE DELETE 
ON dka_stransco_headers
  ----- le trigger se déclenche à chaque suppression d'une ligne d'entete  
FOR EACH ROW

BEGIN  

  DELETE FROM DKA_STRANSCO_LINES
  where set_id = :OLD.set_id;
  
END;
/
SHOW ERRORS;
EXIT;
