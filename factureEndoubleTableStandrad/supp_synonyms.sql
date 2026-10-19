----------------------------------------------------------------------------------------------      
-- $Id$                                                                                               
-- Capgemini                                                                     
-- PROJET           : DALKIA Oracle Applications                                                    
-- NOM              : DROP_DKA_CONTRAT_SSTR_HEADER_TMP.tab                                                            
-- DESCRIPTION      : Suppression de la table DROP_DKA_CONTRAT_SSTR_HEADER_TMP
-- AUTEUR           : Maxime EGOT                                                              
-- DATE DE CREATION : 06/11/2017                                                                      
-- DOC. ASSOCIEE    :                                                                               
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS                                                                                                 
--------------------------------------------------------------------------------------------        
-- HISTORIQUE DES MODIFICATIONS                                                                     
-- Date       Qui Description                                                                       
-- ---------- --- -------------------------------------------------------------------------         
-- 06/11/2017 MEG Correctif artf2271807 : Modification de la taille de la colonne SHIP_TO_LOCATION
--------------------------------------------------------------------------------------------  

DROP TABLE DKA.DKA_CONTRAT_SSTR_HEADER_TMP;
DROP VIEW DKA.DKA_CONTRAT_SSTR_HEADER_TMP#;
DROP SYNONYM DKA_CONTRAT_SSTR_HEADER_TMP;

EXIT;
