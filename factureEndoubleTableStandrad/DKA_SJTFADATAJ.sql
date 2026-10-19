-------------------------------------------------------------------------------
-- CAP GEMINI 
-- Projet          : DALKIA Oracle Applications
-- Auteur          : Julien Jardez
-- Date Création   :
--------------------------------------------------------------------------------
-- NOM             : Flag_tp.sql
-- DESCRIPTION     : Mise à jour du flag TP
--------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------
--- 11/06/2013 JJA Séparation avec le script Users.sql
--------------------------------------------------------------------------------
Set serveroutput On
Set verify Off

--Accept vv_function Prompt 'Desactiver (D) ou Reactiver (R): '&vv_function
--Accept vv_end_date Prompt 'Date de desactivation (DD/MM/YYYY): '&vv_end_date 

Begin
    Dbms_output.Put_Line ('.');
    Dbms_output.Put_Line ('.');

    --Fermeture du TP
    UPDATE dka_parameters
    SET number_value = 0
    WHERE
    program_code = 'SFND_CLOSE_TP'
    AND parameter_name = 'TP'
    AND Upper ('&1') = 'D';
    Dbms_output.Put_Line ('Fermeture du TP : '||SQL%ROWCOUNT || ' au ' || '&2');
     
    --Ouverture du TP
    UPDATE dka_parameters
    SET number_value = 1
    WHERE
    program_code = 'SFND_CLOSE_TP'
    AND parameter_name = 'TP'
    AND Upper ('&1') = 'R';
    Dbms_output.Put_Line ('Ouverture du TP : '||SQL%ROWCOUNT || ' au ' || '&2');    
    
End;
/

EXIT;

