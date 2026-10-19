----------------------------------------------------------------------------------------------      
-- $Id$                                                                                            
-- Capgemini                                                                     
-- PROJET           : DALKIA Oracle Applications                                                    
-- NOM              : DKA_REPAPFRSIMP_FOUR_FACTOR_S.seq                                                            
-- DESCRIPTION      : Création de la séquence  DKA_REPAPFRSIMP_FOUR_FACTOR_S                                                                                                              
-- AUTEUR           : Younes WARID                                                               
-- DATE DE CREATION : 05/04/2016                                                                       
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
-- 05/04/2016 RBE Migration R12
--------------------------------------------------------------------------------------------   
WHENEVER SQLERROR CONTINUE
CONNECT &&1/&&2

--drop sequence DKA_REPAPFRSIMP_FOUR_FACTOR_S;

create sequence DKA_REPAPFRSIMP_FOUR_FACTOR_S START WITH  100000;

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
PROMPT CREATION DES GRANTS                                                                                
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

GRANT ALL ON DKA_REPAPFRSIMP_FOUR_FACTOR_S TO &&3;

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
PROMPT DROP DES SYNONYMES                                                                                
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CONNECT &&3/&&4                                                                                          

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
PROMPT CREATE DES SYNONYMES                                                                                
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--drop SYNONYM DKA_REPAPFRSIMP_FOUR_FACTOR_S;

CREATE SYNONYM DKA_REPAPFRSIMP_FOUR_FACTOR_S FOR &&1..DKA_REPAPFRSIMP_FOUR_FACTOR_S;

EXIT;
