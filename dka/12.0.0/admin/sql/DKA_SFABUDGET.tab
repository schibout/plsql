----------------------------------------------------------------------------
-- $Header: 
--
-- DESCRIPTION  : Creation des tables temporaires:
--
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user DKA
--                    en lui passant 3 paramètres :
--                           1) Password DKA
--                           2) Password APPS
--                           3) Tablespace des données pour schéma DKA
--                           4) Tablespace des index   pour schéma DKA
--
-- Version              :
-- Date                 : 02/08/2019
-- Auteur               : SELO
----------------------------------------------------------------------------

CONNECT DKA/&2;

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LA TABLE DKA_SFABUDGET_WORK
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP TABLE DKA_SFABUDGET_WORK;
create table DKA_SFABUDGET_WORK                            
(                                                          
  REGION           VARCHAR2(30)                            
, CENTRE           VARCHAR2(30)                            
, CPT_GPE          VARCHAR2(30)                            
, COST_CENTER      VARCHAR2(30)                            
, PROJET           VARCHAR2(30)                            
, SOC              VARCHAR2(30)                            
, NUM_IMMO         VARCHAR2(15)                            
, ASSET_ID         NUMBER                                  
, BOOK_TYPE_CODE   VARCHAR2(15)                            
, DESC_IMMO        VARCHAR2(80)                            
, RECOVERABLE_COST NUMBER                                  
, DATE_IN          DATE                                    
, Date_FROM        DATE                                    
, DATE_TO          DATE                                    
, LIFE_IN_MONTHS   NUMBER                                  
, DOTATION_JAN     NUMBER                                  
, DOTATION_FEB     NUMBER                                  
, DOTATION_MAR     NUMBER                                  
, DOTATION_AVR     NUMBER                                  
, DOTATION_MAI     NUMBER                                  
, DOTATION_JUN     NUMBER                                  
, DOTATION_JUL     NUMBER                                  
, DOTATION_AOU     NUMBER                                  
, DOTATION_SEP     NUMBER                                  
, DOTATION_OCT     NUMBER                                  
, DOTATION_NOV     NUMBER                                  
, DOTATION_DEC     NUMBER                                  
, DOTATION_ANNUELLE NUMBER                                 
, DOTATION_N        NUMBER                                 
, CATEGORIE         VARCHAR2(30)                           
, CPTE_CATEG        VARCHAR2(25)                           
, CPTE_EXCEP_FLAG   CHAR(1)                                
, CATEG_SEGMENT2    VARCHAR2(30)                           
, TOTAL_CESSION_N   NUMBER --09/11/2009
, TACHE_PARENT 		VARCHAR2(50)
, LIVRE_FA 			VARCHAR2(50)
, AJUSTEMENT_N 		NUMBER
,FC_INVESTISSEMENT  VARCHAR2(50)
,GY_INVESTISSEMENT  VARCHAR2(50)
)     
TABLESPACE &3;
 
---------------------------------------------
-- Grants et synonyms sur les tables créées --
---------------------------------------------

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DES GRANTS
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT ALL ON DKA_SFABUDGET_WORK TO APPS;


PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DU SYNONYME
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CONNECT APPS/&1

DROP SYNONYM DKA_SFABUDGET_WORK;
CREATE SYNONYM DKA_SFABUDGET_WORK FOR DKA.DKA_SFABUDGET_WORK;

EXIT;
