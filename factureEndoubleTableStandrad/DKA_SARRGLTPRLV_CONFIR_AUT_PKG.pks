----------------------------------------------------------------------------------------------      
-- $Id$                                                                                            
-- Capgemini                                                                     
-- PROJET           : DALKIA Oracle Applications                                                    
-- NOM              : ACTION_ID_S.seq                                                            
-- DESCRIPTION      : Création de la séquence  ACTION_ID_S                                                                                                              
-- AUTEUR           : Asma Amenkour                                                               
-- DATE DE CREATION : 22/01/2020                                                                      
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

--drop sequence ACTION_ID_S;

CREATE SEQUENCE ACTION_ID_S
INCREMENT BY 1
START WITH 20000
;  

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
PROMPT CREATION DES GRANTS                                                                                
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

GRANT ALL ON ACTION_ID_S TO &&3;

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
PROMPT DROP DES SYNONYMES                                                                                
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CONNECT &&3/&&4                                                                                          

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
PROMPT CREATE DES SYNONYMES                                                                                
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++   
                                                                                    



--drop SYNONYM ACTION_ID_S; 
CREATE SYNONYM ACTION_ID_S FOR &&1..ACTION_ID_S;
/
EXIT;
