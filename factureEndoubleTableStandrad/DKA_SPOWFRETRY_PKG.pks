----------------------------------------------------------------------------------------------            
-- $$                                                                                                     
-- CAPGEMINI                                                                        
-- PROJET           : DALKIA Oracle Applications HELIOS R12                                                        
-- NOM		          : DKA_IARPAFAC_INTERFACE_GRANT.sql                                                                   
-- DESCRIPTION	    : Droits sur la table DKA_IARPAFAC_INTERFACE pour l'utilisateur XXEAI                                                                                                                                                      
-- AUTEUR	          : Maxime EGOT (CAPGEMINI)                                                                    
-- DATE DE CREATION : 08/06/2017                                                                            
-- DOC. ASSOCIEE    :                                                                                     
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user DKA                                            
--                    en lui passant 2 paramètres :                                                       
--                           1) Password DKA                                                                                                                        
--------------------------------------------------------------------------------------------              
-- HISTORIQUE DES MODIFICATIONS                                                                           
-- Date       Qui Description                                                                             
-- ---------- --- -------------------------------------------------------------------------               
--------------------------------------------------------------------------------------------              

CONNECT DKA/&1;                                                                                          
                                                                                                          
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
PROMPT GRANT SUR LA TABLE DKA_IARPAFAC_INTERFACE POUR XXEAI                                                    
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             

GRANT SELECT ON DKA_IARPAFAC_INTERFACE TO XXEAI;
GRANT UPDATE ON DKA_IARPAFAC_INTERFACE TO XXEAI;
GRANT INSERT ON DKA_IARPAFAC_INTERFACE TO XXEAI;

EXIT;