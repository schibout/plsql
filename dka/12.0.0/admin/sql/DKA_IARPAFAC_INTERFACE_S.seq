----------------------------------------------------------------------------------------------            
-- $$                                                                                                     
-- CAP GEMINI ERNST AND YOUNG                                                                             
-- PROJET           : DALKIA Oracle Applications                                                          
-- NOM		    : DKA_IARPAFAC_INTERFACE_S.seq                                                                   
-- DESCRIPTION	    : Création de la sequence pour dka_iarpafac_interface.iarpafac_id                                                                                                                                                       
-- AUTEUR	    : GUILLAUME CHABRIER (CGEY)                                                                    
-- DATE DE CREATION : 26/12/2001                                                                              
-- DOC. ASSOCIEE    :                                                                                     
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user DKA                                            
--                    en lui passant 2 paramètres :                                                       
--                           1) Password DKA                                                             
--                           2) Password APPS                                                             
--------------------------------------------------------------------------------------------              
-- HISTORIQUE DES MODIFICATIONS                                                                           
-- Date       Qui Description                                                                             
-- ---------- --- -------------------------------------------------------------------------               
--------------------------------------------------------------------------------------------              

CONNECT DKA/&1;                                                                                          
                                                                                                          
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
PROMPT DROP DE LA SEQUENCE DKA_IARPAFAC_INTERFACE_S                                                                            
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
--DROP SEQUENCE dka_iarpafac_interface_s ;

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
PROMPT CREATE DE LA SEQUENCE DKA_IARPAFAC_INTERFACE_S                                                                            
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
CREATE SEQUENCE dka_iarpafac_interface_s
INCREMENT BY 1
START WITH 1 ;

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
PROMPT CREATION DES GRANTS                                                                                
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
GRANT ALL ON dka.dka_iarpafac_interface_s  TO apps WITH GRANT OPTION;


----- Création des synonymes sur les différentes sequences -----
CONNECT APPS/&2;                                                                                          

DROP SYNONYM dka_iarpafac_interface_s;
CREATE SYNONYM apps.dka_iarpafac_interface_s  FOR dka.dka_iarpafac_interface_s;


EXIT;