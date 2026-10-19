----------------------------------------------------------------------------------------------      
-- $Id$                                                                                               
-- Capgemini                                                                     
-- PROJET           : DALKIA Oracle Applications                                                    
-- NOM              : DKA_SFNDUSER_ASSRESP_S.seq                                                            
-- DESCRIPTION      : Création de la SEQUENCE DKA_SFNDUSER_ASSRESP_S
-- AUTEUR           : SEL                                                              
-- DATE DE CREATION : 26/05/2020                                                                       
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
 
CREATE SEQUENCE DKA_SFNDUSER_ASSRESP_S INCREMENT BY 1
START WITH 1;       
 GRANT ALL ON DKA_SFNDUSER_ASSRESP_S TO &&3; 
                                                                                                     
EXIT;
