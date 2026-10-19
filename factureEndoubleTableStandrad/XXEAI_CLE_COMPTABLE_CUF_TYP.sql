-------------------------------------------------------------------------------------
-- Capgemini
-- PROJET           : Dalkia Oracle Applications
-- NOM              : DKA_SARSURTAXE_TMP_POLICY.sql
-- DESCRIPTION      : Création de policy dka_sarsurtaxe_tmp
--
-- AUTEUR           : Oussama BENHAYOUN
-- DATE DE CREATION : 06/03/2017
-- DOC. ASSOCIEE    :
-- COMMENTAIRE      : 
-------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- -------------------------------------------------------------------
--
-------------------------------------------------------------------------------------


PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DU SYNONYME
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CONNECT APPS/&1;

DROP SYNONYM DKA_SARSURTAXE_TMP; 

CREATE SYNONYM DKA_SARSURTAXE_TMP FOR DKA.DKA_SARSURTAXE_TMP_ALL;



BEGIN

    dbms_rls.add_policy (
        'apps',                           --Schema Name
        'dka_sarsurtaxe_tmp',             --synonym name
        'ORG_SEC',                        -- Nom de la policy (convention ORG_SEC) 
        'apps',                           --function_schema
        'MO_GLOBAL.ORG_SECURITY',         --package standard assurant le maoc
        'SELECT, INSERT, UPDATE, DELETE', --tous les ordres
        TRUE,                             --update_check
        TRUE                              -- Policy enable
    );
                               
                                  
   dbms_output.put_line('Policies ajoutés au synonym dka_sarsurtaxe_tmp.');          
   COMMIT;
   
EXCEPTION
  WHEN OTHERS THEN
    dbms_output.put_line('KO : '||SQLERRM);
                              
END;
/

EXIT 
