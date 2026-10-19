----------------------------------------------------------------------------------------------            
-- $$                                                                                                     
-- CAP GEMINI ERNST AND YOUNG                                                                             
-- PROJET           : DALKIA Oracle Applications                                                          
                                                                  
-- DESCRIPTION	    : Création de la table  dka_SPOCHARGE_ERRORS                                                                                                                                                    
-- AUTEUR	    	: SELO                                                                    
-- DATE DE CREATION : 13/01/2020                                                                              
-- DOC. ASSOCIEE    :                                                                                     
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user DKA                                            
--                    en lui passant 3 paramètres :                                                       
--                           1) Password DKA                                                             
--                           2) Password APPS                                                             
--                           3) Tablespace des données pour schéma DKA                                    
--                           4) Tablespace des index   pour schéma DKA                                    
--------------------------------------------------------------------------------------------              
-- HISTORIQUE DES MODIFICATIONS                                                                           
-- Date       Qui Description                                                                             
-- ---------- --- -------------------------------------------------------------------------               
                                                             
--------------------------------------------------------------------------------------------              

Connect DKA/&1;

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT DROP DE LA TABLE dka_SPOCHARGE_ERRORS
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP TABLE dka_SPOCHARGE_ERRORS;
                                                                                                                                                                               
EXIT; 