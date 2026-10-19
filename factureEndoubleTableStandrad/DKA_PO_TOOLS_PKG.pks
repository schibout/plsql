----------------------------------------------------------------------------------------------      
-- $Id$                                                                                              
-- Capgemini                                                                     
-- PROJET           : DALKIA Oracle Applications                                                    
-- NOM              : DKA_OPTI_N.idx                                                            
-- DESCRIPTION      : Creation des index dans le cadre de l'optimisation du specifique (artf2016223)                                                                                                             
-- AUTEUR           : Maxime EGOT                                                              
-- DATE DE CREATION : 24/10/2016                                                                      
-- DOC. ASSOCIEE    :                                                                               
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user DKA                                      
--                    en lui passant 3 paramètres :                                                                                                     
--                           1) Password APPS                                                                                  
--                                                       
--------------------------------------------------------------------------------------------        
-- HISTORIQUE DES MODIFICATIONS                                                                     
-- Date       Qui Description                                                                       
-- ---------- --- -------------------------------------------------------------------------         
-- 24/10/2016 MEG Migration R12
--------------------------------------------------------------------------------------------        
                                                                                                    
CONNECT APPS/&1;    
                                                                                 
--===========================================================================================                                                                                                    
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
PROMPT DROP DE L''INDEX AR.DKA_RA_CUSTOMERS_INTERFACE_N1                                                                    
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
DROP INDEX AR.DKA_RA_CUSTOMERS_INTERFACE_N1;
                                                                                                    
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
PROMPT CREATION DE L''INDEX AR.DKA_RA_CUSTOMERS_INTERFACE_N1                                                                 
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
--CREATE INDEX AR.DKA_RA_CUSTOMERS_INTERFACE_N1 
--          ON AR.RA_CUSTOMERS_INTERFACE_ALL (INTERFACE_STATUS, 
--                                            ORIG_SYSTEM_CUSTOMER_REF, 
--                                            ORIG_SYSTEM_PARTY_REF, 
--                                            PERSON_FLAG)
--TABLESPACE APPS_TS_INTERFACE;                                                

--=========================================================================================== 
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
PROMPT DROP DE L''INDEX AR.DKA_HZ_DQM_SYNC_INTERFACE_N1                                                                   
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
DROP INDEX AR.DKA_HZ_DQM_SYNC_INTERFACE_N1;
                                                                                                    
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
PROMPT CREATION DE L''INDEX AR.DKA_HZ_DQM_SYNC_INTERFACE_N1                                                                
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
CREATE INDEX AR.DKA_HZ_DQM_SYNC_INTERFACE_N1 
          ON AR.HZ_DQM_SYNC_INTERFACE (PARTY_ID, 
                                       RECORD_ID)
TABLESPACE APPS_TS_INTERFACE;

--=========================================================================================== 
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
PROMPT DROP DE L''INDEX AR.DKA_HZ_DQM_SYNC_INTERFACE_N2                                                                   
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
DROP INDEX AR.DKA_HZ_DQM_SYNC_INTERFACE_N2;
                                                                                                    
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
PROMPT CREATION DE L''INDEX AR.DKA_HZ_DQM_SYNC_INTERFACE_N2                                                                
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
CREATE INDEX AR.DKA_HZ_DQM_SYNC_INTERFACE_N2 on AR.HZ_DQM_SYNC_INTERFACE (ENTITY, 
                                                                          PARTY_ID, 
                                                                          STAGED_FLAG)
TABLESPACE APPS_TS_INTERFACE;

EXIT;                                                                                               
