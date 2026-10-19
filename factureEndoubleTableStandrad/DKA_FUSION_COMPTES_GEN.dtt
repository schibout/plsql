PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT DROP DU TRIGGER XXEAI_HR_PEOPLE_INT_BRI
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP TRIGGER XXEAI_HR_PEOPLE_INT_BRI;

CREATE OR REPLACE TRIGGER XXEAI_HR_PEOPLE_INT_BRI
---------------------------------------------------------------------------------------------- 
-- $$
-- CAP GEMINI
-- PROJET           : DALKIA Oracle Applications
-- NOM              : XXEAI_HR_PEOPLE_INT_BRI.trg 
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
ON XXEAI.XXEAI_HR_PEOPLE_INT
FOR EACH ROW
	
BEGIN
	
SELECT XXEAI.XXEAI_HR_PEOPLE_INT_s.nextval,sysdate
INTO
:new.XXEAI_PERSON_ID, :new.creation_date 
FROM dual;


END;
/
SHOW ERRORS;
EXIT;
