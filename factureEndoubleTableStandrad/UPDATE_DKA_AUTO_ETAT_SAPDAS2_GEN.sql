----------------------------------------------------------------------------------------------      
-- $Id$                                                                                              
-- Capgemini                                                                     
-- PROJET           : DALKIA Oracle Applications                                                    
-- NOM              : DKA_CONTRAT_SSTR_IMPUTATION_N2.idx                                                            
-- DESCRIPTION      : Création de l'index DKA_CONTRAT_SSTR_IMPUTATION_N2                                                                                                                
-- AUTEUR           : V. KNAB                                                              
-- DATE DE CREATION : 10/09/2007                                                                       
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
-- 24/03/2016 RBE Migration R12
--------------------------------------------------------------------------------------------        
                                                                                                    
CONNECT DKA/&1;                                                                                     
                                                                                                    
                                                                                                   
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
PROMPT CREATION DE L'INDEX DKA_CONTRAT_SSTR_IMPUTATION_N2                                                                  
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
CREATE INDEX DKA_CONTRAT_SSTR_IMPUTATION_N2 ON DKA.DKA_CONTRAT_SSTR_IMPUTATION (
         project_id  
)
TABLESPACE &3;                                                    
                                                                                                    
EXIT;                                                                                               
                                                                               
