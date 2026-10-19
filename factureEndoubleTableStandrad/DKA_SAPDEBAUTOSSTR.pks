----------------------------------------------------------------------------------------------      
-- $Id$                                                                                            
-- Capgemini                                                                     
-- PROJET           : DALKIA Oracle Applications                                                    
-- NOM              : DKA_IPOCTR_SSTR_IVALUA_S.seq                                                            
-- DESCRIPTION      : Création de la séquence  DKA_SPO_CONTRAT_SSTR_IVALUA_S                                                                                                              
-- AUTEUR           : KALTOUM HANNACH                                                             
-- DATE DE CREATION : 29/11/2024                                                                      
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

drop sequence DKA_SPO_CONTRAT_SSTR_IVALUA_S;

create sequence DKA_SPO_CONTRAT_SSTR_IVALUA_S;

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
PROMPT CREATION DES GRANTS                                                                                
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

GRANT ALL ON DKA_SPO_CONTRAT_SSTR_IVALUA_S TO &&3;

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
PROMPT DROP DES SYNONYMES                                                                                
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CONNECT &&3/&&4                                                                                          

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
PROMPT CREATE DES SYNONYMES                                                                                
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

drop SYNONYM DKA_SPO_CONTRAT_SSTR_IVALUA_S;

CREATE SYNONYM DKA_SPO_CONTRAT_SSTR_IVALUA_S FOR &&1..DKA_SPO_CONTRAT_SSTR_IVALUA_S;
/
EXIT;