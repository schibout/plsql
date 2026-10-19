--------------------------------------------------------------------------------------------
-- FILENAME               
--    DKA_MAIL_PARAM.tab  V1.0
--
-- AUTEUR
--    Capgemini
--
-- DESCRIPTION       
--    Création de la table DKA_MAIL_PARAM
--
-- USAGE
--   DKA_MAIL_PARAM
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
-- V1.0    27/03/2020     NBO Creation
---------------------------------------------------------------------------------------------

WHENEVER SQLERROR CONTINUE
CONNECT DKA/&&2

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
PROMPT DROP DE LA TABLE DKA_MAIL_PARAM                                                                         
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  
DROP TABLE DKA_MAIL_PARAM;

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
PROMPT CREATE DE LA TABLE DKA_MAIL_PARAM                                                                           
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- Create table
create table DKA_MAIL_PARAM
(
expediteur   VARCHAR2(4000),
  destinataire VARCHAR2(4000),
  objet        VARCHAR2(4000),
  corps        VARCHAR2(4000),
  req_id       NUMBER,
  attachement  VARCHAR2(1),
  filename     VARCHAR2(4000),
  CC_MAIL      VARCHAR2(4000)
)
TABLESPACE &3;

create index dka.DKA_MAIL_PARAM_I1 on DKA.DKA_MAIL_PARAM(req_id);


PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
PROMPT CREATION DES GRANTS                                                                                
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

GRANT ALL ON DKA_MAIL_PARAM TO APPS;

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
PROMPT DROP DES SYNONYMES                                                                                
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CONNECT APPS/&&1                                                                                          

DROP SYNONYM DKA_MAIL_PARAM;

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
PROMPT CREATE DES SYNONYMES                                                                                
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE SYNONYM DKA_MAIL_PARAM FOR DKA.DKA_MAIL_PARAM;

EXIT;