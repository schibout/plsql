----------------------------------------------------------------------------------------------      
-- $Id$                                                                                            
-- Capgemini                                                                     
-- PROJET           : DALKIA Oracle Applications                                                    
-- NOM              : DKA_IPOFRS_ENTETES_S.seq                                                            
-- DESCRIPTION      : Création de la séquence  DKA_IPOFRS_ENTETES_S                                                                                                              
-- AUTEUR           : Saloua HA                                                               
-- DATE DE CREATION : 12/05/2020                                                                      
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

--drop sequence DKA_IPOFRS_ENTETES_S;

CREATE SEQUENCE DKA_IPOFRS_ENTETES_S
INCREMENT BY 1
START WITH 1
;  

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
PROMPT CREATION DES GRANTS                                                                                
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

GRANT ALL ON DKA_IPOFRS_ENTETES_S TO &&3;

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
PROMPT DROP DES SYNONYMES                                                                                
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CONNECT &&3/&&4                                                                                          

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
PROMPT CREATE DES SYNONYMES                                                                                
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++   
                                                                                    



--drop SYNONYM DKA_IPOFRS_ENTETES_S; 
CREATE SYNONYM DKA_IPOFRS_ENTETES_S FOR &&1..DKA_IPOFRS_ENTETES_S;
/
EXIT;
