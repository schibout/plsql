----------------------------------------------------------------------------------------------      
-- $Id$                                                                                            
-- Capgemini                                                                     
-- PROJET           : DALKIA Oracle Applications                                                    
-- NOM              : DKA_AR_BATCHES_S.seq                                                            
-- DESCRIPTION      : Création de la séquence  DKA_AR_BATCHES_S                                                                                                              
-- AUTEUR           : Asma Amenkour                                                               
-- DATE DE CREATION : 12/09/2019                                                                       
-- DOC. ASSOCIEE    :                                                                               
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user DKA                                      
--                    en lui passant 4 paramètres :                                                 
--                           1) login DKA                                                        
--                           2) Password DKA           
--                           3) login APPS         
--                           4) Password APPS                                                            
--                                                       
--------------------------------------------------------------------------------------------        
-- HISTORIQUE DES MODIFICATIONS                                                                     
-- Date       Qui Description                                                                       
-- ---------- --- -------------------------------------------------------------------------         
--------------------------------------------------------------------------------------------   
WHENEVER SQLERROR CONTINUE
CONNECT &&1/&&2

--drop sequence DKA_AR_BATCHES_S;

CREATE SEQUENCE DKA_AR_BATCHES_S
INCREMENT BY 1
START WITH 20000
;  

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
PROMPT CREATION DES GRANTS                                                                                
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

GRANT ALL ON DKA_AR_BATCHES_S TO &&3;

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
PROMPT DROP DES SYNONYMES                                                                                
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CONNECT &&3/&&4                                                                                          

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
PROMPT CREATE DES SYNONYMES                                                                                
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++   
                                                                                    



--drop SYNONYM DKA_AR_BATCHES_S; 
CREATE SYNONYM DKA_AR_BATCHES_S FOR &&1..DKA_AR_BATCHES_S;
/
EXIT;
