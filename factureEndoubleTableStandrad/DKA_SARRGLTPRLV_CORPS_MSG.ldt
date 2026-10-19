PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT DROP DU TRIGGER XXEAI_HR_BANK_INT_ALL_BRI
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP TRIGGER XXEAI_HR_BANK_INT_ALL_BRI;

CREATE OR REPLACE TRIGGER XXEAI_HR_BANK_INT_ALL_BRI
---------------------------------------------------------------------------------------------- 
-- $$
-- CAP GEMINI
-- PROJET           : DALKIA Oracle Applications
-- NOM              : XXEAI_HR_BANK_INT_ALL_BRI.trg 
-- DESCRIPTION	    : Alimentation du champ XXEAI
--
-- AUTEUR           : Julien Jardez
-- DATE DE CREATION : 06/11/2014
-- DOC. ASSOCIEE    : 
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS                        
--                           
--------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- -------------------------------------------------------------------------
-- 
--------------------------------------------------------------------------------------------
BEFORE INSERT
ON XXEAI.XXEAI_HR_BANK_INT_ALL
FOR EACH ROW
	
BEGIN
	
SELECT XXEAI.XXEAI_HR_BANK_INT_ALL_s.nextval,sysdate
INTO
:new.XXEAI_BANK_ID, :new.creation_date 
FROM dual;


END;
/
SHOW ERRORS;
EXIT;
