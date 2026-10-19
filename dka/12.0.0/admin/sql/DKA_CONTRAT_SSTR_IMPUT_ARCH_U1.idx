----------------------------------------------------------------------------------------------      
-- $Id$                                                                                             
-- Capgemini                                                                     
-- PROJET           : DALKIA Oracle Applications                                                    
-- NOM              : DKA_CONTRAT_SSTR_IMPUT_ARCH_U1.idx                                                            
-- DESCRIPTION      : Création de l'index DKA_CONTRAT_SSTR_IMPUT_ARCH_U1                                                                                                                
-- AUTEUR           : CDE                                                              
-- DATE DE CREATION : 25/01/2010                                                                       
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
PROMPT CREATION DE L'INDEX DKA_CONTRAT_SSTR_IMPUT_ARCH_U1                                                                  
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
CREATE UNIQUE INDEX DKA_CONTRAT_SSTR_IMPUT_ARCH_U1  ON DKA.DKA_CONTRAT_SSTR_IMPUT_ARCHI (
         contrat_imputation_id, revision_num  
)
TABLESPACE &3 ;                                                    
                                                                                                    
EXIT;                                                                                               
                                                             
