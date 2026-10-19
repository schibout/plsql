--------------------------------------------------------------------------------------------------------------- 
-- CAP GEMINI
-- PROJET           : DALKIA Oracle Applications  
-- NOM              : DKA_SAPWFSIMP.sql
-- DESCRIPTION      : Traitement de réaffectation de valeurs dans la table DKA_PARAMETERS
---
--- AUTEUR           : Q.VANHOUTE (CG)
--- DATE DE CREATION : 01/04/2010
--- DOC. ASSOCIEE    :
--- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- --------------------------------------------------------------------------------------------
--- 2016/07/05 JJA Portage Helios R12
---------------------------------------------------------------------------------------------------------------
set serveroutput on

VAR ret_code VARCHAR2(10);
DECLARE


vv_perimetre  VARCHAR2(20) := '&&1' ;
vn_org_id VARCHAR2(20) := '&&2';
vv_step VARCHAR2(20);

 BEGIN

	DBMS_OUTPUT.ENABLE(2000000);

	BEGIN

    dka_tools_pkg.put_log_message ('Mise a jour de la valeur VARCHAR2_VALUE de la table dka_parameters: '||vv_perimetre||'/'||'METHODE_'||vn_org_id);
 		
		
	  UPDATE DKA_PARAMETERS
	     SET VARCHAR2_VALUE = vv_perimetre
	   WHERE PROGRAM_CODE = 'DKA_SAPWFCSP'
	     AND PARAMETER_NAME = 'METHODE_'||vn_org_id; 

    IF SQL%ROWCOUNT < 1 THEN
     
     dka_tools_pkg.put_log_message ('Insertion de la valeur dans la table dka_parameters: '||vv_perimetre||'/'||'METHODE_'||vn_org_id);
     
     INSERT INTO DKA_PARAMETERS
     (PROGRAM_CODE,
      PARAMETER_NAME,
      DESCRIPTION,
      DATA_TYPE,
      VARCHAR2_VALUE)
     VALUES
    ('DKA_SAPWFCSP',
     'METHODE_'||vn_org_id,
     'Périmetre d''intervention des déblocages',
     'VARCHAR2',
     'JOURNALIER');
    END IF;
    
		EXCEPTION
		WHEN OTHERS then
		    dka_tools_pkg.put_outdebug_message('Erreur lors de la mise a jour du champs VARCHAR2_VALUE');
			  dka_tools_pkg.put_outdebug_message(SQLERRM);
			  :ret_code    := 'FAILURE';
	END;
	COMMIT;

END;
/
COL :ret_code NEW_VALUE ret_code;
SELECT :ret_code
FROM   DUAL;
EXIT &ret_code