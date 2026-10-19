----------------------------------------------------------------------------------------------            
-- $$                                                                                                     
-- CAP GEMINI ERNST AND YOUNG                                                                             
-- PROJET           : DALKIA Oracle Applications                                                          
-- NOM		    : DKA_SGLABONNEMENT_S.seq                                                                   
-- DESCRIPTION	    : Création de la sequence pour les abonnements                                                                                                                                                       
-- AUTEUR	    : grégory VANACKERE                                                                    
-- DATE DE CREATION : 21/07/2006                                                                              
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
PROMPT DROP DE LA SEQUENCE DKA_SGLABONNEMENT_S                                                                            
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
DROP SEQUENCE dka_sglabonnement_s ;

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
PROMPT CREATE DE LA SEQUENCE DKA_SCTLFLUX_TMP_S                                                                            
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
CREATE SEQUENCE dka_sglabonnement_s
INCREMENT BY 1
START WITH 1 ;

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
PROMPT CREATION DES GRANTS                                                                                
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
GRANT ALL ON dka.dka_sglabonnement_s  TO apps WITH GRANT OPTION;


----- Création des synonymes sur les différentes sequences -----
CONNECT APPS/&2;                                                                                          

DROP SYNONYM dka_sglabonnement_s;
CREATE SYNONYM apps.dka_sglabonnement_s  FOR dka.dka_sglabonnement_s;


EXIT;