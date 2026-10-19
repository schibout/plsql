----------------------------------------------------------------------------------------------      
-- $Id$                                                                                               
-- Capgemini                                                                     
-- PROJET           : DALKIA Oracle Applications                                                    
-- NOM              : DKA_SAPCDE_CITY_TMP_S.seq                                                            
-- DESCRIPTION      : Création de la SEQUENCE DKA_SAPCDE_CITY_TMP_S
-- AUTEUR           : ARA                                                              
-- DATE DE CREATION : 18/05/2021                                                                       
-- DOC. ASSOCIEE    :                                                                               
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user DKA                                      
--                    en lui passant 3 paramètres :                                                 
--                           1) Password DKA                                                        
--                           2) Password APPS                                                       
--                           3) Tablespace des données pour schéma DKA                              
--                                                       
--------------------------------------------------------------------------------------------        
-- HISTORIQUE DES MODIFICATIONS                                                                     
-- Date       Qui Description                                                                       
-- ---------- --- -------------------------------------------------------------------------         
--
--------------------------------------------------------------------------------------------        
 
CONNECT &&1/&&2                                                                              


--PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--PROMPT DROP DE LA TABLE DKA_EXPCDE_IVALUA_FILE
--PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--DROP SEQUENCE DKA_SAPCDE_CITY_TMP_S;


CREATE SEQUENCE DKA_SAPCDE_CITY_TMP_S INCREMENT BY 1
START WITH 1;       
 GRANT ALL ON DKA_SAPCDE_CITY_TMP_S TO &&3; 
                                                                                                     
EXIT;
