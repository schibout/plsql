---------------------------------------------------------------------------------------------------------------
-- CAPGEMINI
-- PROJET           : DALKIA Oracle Applications Helios
-- NOM              : DKA_IHYPERION_QTE.sql
-- DESCRIPTION      : Lancement automatique du traitement IHYPERION
---
--- AUTEUR           : Samir EL OUAHABI (CAPGEMINI)
--- DATE DE CREATION : 27/11/2020
--- DOC. ASSOCIEE    :
--- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- 27/01/2020 SELO DGE20190021 Gestion des comptes en quantité
---------------------------------------------------------------------------------------------------------------

SET VERIFY OFF
SET SERVEROUTPUT ON SIZE 100000

VAR ret_code VARCHAR2(10);

DECLARE 
    vv_file1                          VARCHAR2 (80)  := '&&1';
    vv_file2                          VARCHAR2 (80)  := '&&2';
        V1 VARCHAR2(200); --32767
        F1 UTL_FILE.FILE_TYPE ; 
        l_file UTL_FILE.FILE_TYPE; 
		lv_nom_fichier          VARCHAR2(200);
     BEGIN 
        F1 := UTL_FILE.FOPEN('DKA_OUT_DIR', vv_file1,'R'); 
		    lv_nom_fichier := 'FIN01_SRC_ECRITURESCOMPTABLES_' || to_char(sysdate, 'YYYYMMDD-HH24miss') || '.csv';
         l_file := UTL_FILE.fopen('DKA_OUT_DIR', lv_nom_fichier, 'W');
        Loop
        BEGIN
    UTL_FILE.GET_LINE(F1,V1); 
    utl_file.put_line(l_file, V1);
    EXCEPTION WHEN No_Data_Found THEN EXIT; END;
        end loop;
 F1 := UTL_FILE.FOPEN('DKA_OUT_DIR',vv_file2,'R'); 
        Loop
        BEGIN
    UTL_FILE.GET_LINE(F1,V1); 
    utl_file.put_line(l_file, V1);
    EXCEPTION WHEN No_Data_Found THEN EXIT; END;
        end loop;

        UTL_FILE.FCLOSE(F1); 
        UTL_FILE.FCLOSE(l_file);

 --       F1 := UTL_FILE.FOPEN('DKA_OUT_DIR',lv_nom_fichier,'R'); 
 --        l_file := UTL_FILE.fopen('DKA_OUT_DIR', vv_file1, 'W');
 --       Loop
 --       BEGIN
 --   UTL_FILE.GET_LINE(F1,V1); 
 --   utl_file.put_line(l_file, V1);
 --   EXCEPTION WHEN No_Data_Found THEN EXIT; END;
 --       end loop;        
 --
 --       UTL_FILE.FCLOSE(F1); 
 --       UTL_FILE.FCLOSE(l_file);
        
--  UTL_FILE.FREMOVE ('DKA_OUT_DIR','tmp_file.csv');     
     END; 
     /
EXIT 
