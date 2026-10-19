--------------------------------------------------------------------------------------------
-- FILENAME               
--    DKA_STRANSCO_LINES_HIST.tab  V1.0
--
-- AUTEUR
--    Capgemini
--
-- DESCRIPTION       
--    Création de la table temporaire DKA_STRANSCO_LINES_HIST permettant l'intégration des 
--    lignes de ventilation des commandes
--
-- USAGE
--   DKA_STRANSCO_LINES_HIST
--
-- NOTES
--
-- PARAMETERS
--   1. Login APPS       : &&1
--   2. Password APPS    : &&2
--   3. Login DKA        : &&3 
--   4. Password DKA     : &&4
--
---------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
---------------------------------------------------------------------------------------------
-- Version   Date         Qui Description
---------- -------------- --- ---------------------------------------------------------------
-- V1.0    22/03/2016     OBN Creation
---------------------------------------------------------------------------------------------

WHENEVER SQLERROR CONTINUE
CONNECT &&3/&&4

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
PROMPT DROP DE LA TABLE DKA_STRANSCO_LINES_HIST                                                                         
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  
DROP TABLE DKA_STRANSCO_LINES_HIST;

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
PROMPT CREATE DE LA TABLE DKA_STRANSCO_LINES_HIST                                                                           
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- Create table
create table DKA_STRANSCO_LINES_HIST
(
	 SET_ID                  NUMBER        
	,LINE_ID                 NUMBER        
	,PARAM1_VALUE            VARCHAR2(100) 
	,PARAM2_VALUE            VARCHAR2(100) 
	,PARAM3_VALUE            VARCHAR2(100) 
	,PARAMS_VALUE            VARCHAR2(300) 
	,RETURN_VALUE            VARCHAR2(100) 
	,ENABLE                  VARCHAR2(1)   
	,CREATION_DATE           DATE          
	,CREATED_BY              NUMBER        
	,LAST_UPDATE_DATE        DATE          
	,LAST_UPDATED_BY         NUMBER        
	,INACTIVE_DATE           DATE          
	,START_DATE              DATE          
	,END_DATE                DATE      
);
TABLESPACE &5;


PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
PROMPT CREATION DES GRANTS                                                                                
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

GRANT ALL ON DKA_STRANSCO_LINES_HIST TO &&1;

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
PROMPT DROP DES SYNONYMES                                                                                
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CONNECT &&1/&&2                                                                                          

DROP SYNONYM DKA_STRANSCO_LINES_HIST;

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
PROMPT CREATE DES SYNONYMES                                                                                
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE SYNONYM DKA_STRANSCO_LINES_HIST FOR DKA.DKA_STRANSCO_LINES_HIST;

EXIT;