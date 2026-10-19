----------------------------------------------------------------------------------------------      
-- $Id$                                                                                               
-- Capgemini                                                                     
-- PROJET           : DALKIA Oracle Applications                                                    
-- NOM              : DKA_SPOCDE_TRANSFRS_HIST_S.seq                                                            
-- DESCRIPTION      : Création de la SEQUENCE DKA_SPOCDE_TRANSFRS_HIST_S
-- AUTEUR           : ARA                                                              
-- DATE DE CREATION : 04/01/2021                                                                       
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
--DROP SEQUENCE DKA_SPOCDE_TRANSFRS_HIST_S;


CREATE SEQUENCE DKA_SPOCDE_TRANSFRS_HIST_S INCREMENT BY 1
START WITH 1;       
 GRANT ALL ON DKA_SPOCDE_TRANSFRS_HIST_S TO &&3; 
                                                                                                     
EXIT;
