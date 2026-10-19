----------------------------------------------------------------------------------------------      
-- $$                                                                                               
-- Capgemini                                                                     
-- PROJET           : DALKIA Oracle Applications                                                    
-- NOM              : DKA_IAPFACXGS_MTDISP.tab                                                            
-- DESCRIPTION      : Création de la table DKA_IAPFACXGS_MTDISP                                                                                                               
-- AUTEUR           : BEN. Zakaria                                                            
-- DATE DE CREATION : 04/04/2024                                                                      
-- DOC. ASSOCIEE    :                                                                               
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user DKA                                      
--                    en lui passant 3 parametres :                                                 
--                    1- Password DKA
--                    2- Password APPS
--                    3- Tablespace des données pour le schéma DKA
--------------------------------------------------------------------------------
-- Historique
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------
--
-------------------------------------------------------------------------------- 
                                                                                                    
CONNECT DKA/&1;                                                                                     
                                                                                                    
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
PROMPT DROP DE LA TABLE DKA_IAPFACXGS_MTDISP                                                                    
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
DROP TABLE DKA_IAPFACXGS_MTDISP;
                                                                                                    
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
PROMPT CREATION DE LA TABLE DKA_IAPFACXGS_MTDISP                                                                  
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++  
     
CREATE TABLE DKA_IAPFACXGS_MTDISP 
        (
        no_commande         VARCHAR2(15),
        num_fact            VARCHAR2(42),
        mht_fact            NUMBER,
        mht_commande        NUMBER,
        mht_dispo           NUMBER,
        org_id              NUMBER,
        id_fact             NUMBER,
        id_commande         NUMBER
        )
TABLESPACE &3;                                                    
                                                                                  
                                                                                                    
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
PROMPT CREATION DES GRANTS                                                                          
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
GRANT ALL ON DKA_IAPFACXGS_MTDISP TO APPS;                                                                         
                                                                                                    
                                                                                                    
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
PROMPT CREATION DU SYNONYME                                                                         
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++    
   
CONNECT APPS/&2;                                                                                    
                                                                                                    
DROP SYNONYM DKA_IAPFACXGS_MTDISP;                                                                                 
                                                                                                    
CREATE SYNONYM DKA_IAPFACXGS_MTDISP FOR DKA.DKA_IAPFACXGS_MTDISP;                                                                 
                                                                                                    
EXIT;                                                                                               
