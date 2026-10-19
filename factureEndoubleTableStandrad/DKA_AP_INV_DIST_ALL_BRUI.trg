---------------------------------------------------------------------------------------------------------------
-- Capgemini
-- PROJET           : DALKIA Oracle Applications
-- NOM              : UPDATE_DKA_AUTO_ETAT.sql
-- DESCRIPTION      : Lancement automatique du traitement UPDATE_DKA_AUTO_ETAT.sql
--
-- AUTEUR           : E.Matuszewski
-- DATE DE CREATION : 28/01/2010
-- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
---------------------------------------------------------------------------------------------------------------

SET VERIFY OFF
SET SERVEROUTPUT ON SIZE 1000000

DECLARE
    
    Vc_Dummy            VARCHAR2(1);

BEGIN
    
    BEGIN
        SELECT 'X'
        INTO   Vc_Dummy
        FROM   DKA_AUTO_ETAT
        WHERE  PROGRAM_SHORT_NAME = 'DKA_APXINAGE';

        DBMS_OUTPUT.PUT_LINE('La table Dka_Auto_Etat est a jour');

    EXCEPTION
        WHEN OTHERS THEN
             INSERT INTO DKA_AUTO_ETAT
                 (PROGRAM_SHORT_NAME,
                  CREATED_BY,
                  CREATION_DATE)
             VALUES 
                 ('DKA_APXINAGE',
                  -1,
                  SYSDATE);

        DBMS_OUTPUT.PUT_LINE('La table Dka_Auto_Etat a ete mise a jour');
    END;

    COMMIT;

END;
/
EXIT