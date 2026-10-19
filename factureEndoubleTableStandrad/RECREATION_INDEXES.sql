----------------------------------------------------------------------------------------------            
-- $$                                                                                                     
-- CAP GEMINI ERNST AND YOUNG                                                                             
-- PROJET           : DALKIA Oracle Applications                                                          
-- NOM		    : DKA_SARAUTENC_S.seq                                                                   
-- DESCRIPTION	    : Création de la sequence pour l'automatisation des etapes d'encaissement
-- AUTEUR	    : Oussama BENHAYOUN                                                                    
-- DATE DE CREATION : 13/08/2018                                                                             
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
PROMPT DROP DE LA SEQUENCE DKA_FUSION_COUTS_S                                                                           
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
DROP SEQUENCE DKA.DKA_FUSION_COUTS_S ;

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
PROMPT CREATE DE LA SEQUENCE DKA_FUSION_COUTS_S                                                                                 
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
CREATE SEQUENCE DKA.DKA_FUSION_COUTS_S      
INCREMENT BY 1
START WITH 1 ;

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
PROMPT CREATION DES GRANTS                                                                                
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
GRANT ALL ON dka.DKA_FUSION_COUTS_S  TO apps WITH GRANT OPTION;


----- Création des synonymes sur les différentes sequences -----
CONNECT APPS/&2;                                                                                          

DROP SYNONYM DKA_FUSION_COUTS_S;
CREATE SYNONYM apps.DKA_FUSION_COUTS_S        FOR dka.DKA_FUSION_COUTS_S;


EXIT;