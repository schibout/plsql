----------------------------------------------------------------------------------------------            
-- $$                                                                                                     
-- CAP GEMINI ERNST AND YOUNG                                                                             
-- PROJET           : DALKIA Oracle Applications                                                          
-- NOM		    : DKA_IEOGLETF01_INT.tab                                                                   
-- DESCRIPTION	    : Création de la table  DKA_IEOGLETF01_INT pour l'extraction ETAFI                                                                                                                                                   
-- AUTEUR	    : AZIZ NOUJOUD (CGEY)                                                                    
-- DATE DE CREATION : 29/05/2002                                                                              
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

CONNECT APPS/&1;                                                                                          
                                                                                                          
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
PROMPT DROP DE LA TABLE DKA_IEOGLETF01_INT                                                                           
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++      

DROP TABLE DKA.DKA_IEOGLETF01_INT;
DROP SYNONYM APPS.DKA_IEOGLETF01_INT;
DROP VIEW DKA.DKA_IEOGLETF01_INT#;                                                                 
                                                                                                          
                                                                                                                                                                                 
EXIT; 