----------------------------------------------------------------------------------------------      
-- $Id$                                                                                              
-- Capgemini                                                                     
-- PROJET           : DALKIA Oracle Applications                                                    
-- NOM              : DKA_CONTRAT_SSTR_N1.idx                                                            
-- DESCRIPTION      : Création de l'index DKA_CONTRAT_SSTR_N1                                                                                                                
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
                                                                                                    
CONNECT APPS/&2;                                                                                     
                                                                                                    
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
PROMPT DROP DE L'INDEX DKA_PO_HEADERS_ALL_N1                                                                    
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
DROP INDEX DKA_PO_HEADERS_ALL_N1;
                                                                                                    
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
PROMPT CREATION DE L'INDEX DKA_PO_HEADERS_ALL_N1                                                                  
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
CREATE INDEX DKA_PO_HEADERS_ALL_N1  ON PO.PO_HEADERS_ALL (
         type_lookup_code, attribute4  
)      
TABLESPACE &3 ;                                                    
                                                                                                    
EXIT;                                                                                               
