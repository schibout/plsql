--------------------------------------------------------------------------------------------
-- FILENAME               
--    DKA_SGLFUSION_TMP.tab  V1.0
--
-- AUTEUR
--    Capgemini
--
-- DESCRIPTION       
--    Création de la table temporaire DKA_SGLFUSION_TMP permettant l'intégration des 
--    lignes de ventilation des commandes
--
-- USAGE
--   DKA_SGLFUSION_TMP
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
PROMPT DROP DE LA TABLE DKA_SGLFUSION_TMP                                                                         
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  
DROP TABLE DKA_SGLFUSION_TMP;

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
PROMPT CREATE DE LA TABLE DKA_SGLFUSION_TMP                                                                           
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- Create table
create table DKA_SGLFUSION_TMP
(
          TYPE_LIGNE                        VARCHAR2(20)
          ,TYPE_DONNEE                       VARCHAR2(20)
          ,SOC_ABSORBEE                      VARCHAR2(20)
          ,SOC_ABSORBANTE                    VARCHAR2(20)
          ,LIVRE                             VARCHAR2(20)
          ,SOCIETE                           VARCHAR2(25)
          ,UO                                VARCHAR2(25)
          ,COMPTE_LOCAL                      VARCHAR2(25)
          ,COMPTE_ANALYTIQUE                 VARCHAR2(25)
          ,INTERCO                           VARCHAR2(25)
          ,CENTRE_FINANCE                    VARCHAR2(25)
          ,CODE_AFFAIRE                      VARCHAR2(25)
          ,PROJET_FINANCE                    VARCHAR2(25)
          ,CODE_FLUX                         VARCHAR2(25)
          ,RESERVE_1                         VARCHAR2(25)
          ,RESERVE_2                         VARCHAR2(25)
          ,RESERVE_3                         VARCHAR2(25)
          ,DEBIT                             NUMBER
          ,CREDIT                            NUMBER
          ,DESCRIPTION_LIGNE                 VARCHAR2(250)
          ,PF                                VARCHAR2(250)
          ,TF                                VARCHAR2(250)
          ,TYPE_DEPENSE                      VARCHAR2(250)
          ,TYPE_EVENEMENT                    VARCHAR2(250)
          ,QTE                               NUMBER(30)
          ,FRAIS                             NUMBER(30)
          ,CODE_CLIENT                       VARCHAR2(150)
          ,CODE_INTERBANCAIRE                VARCHAR2(150)
          ,MATRICULE_EMPLOYE                 VARCHAR2(150)
          ,REF_LETTRAGE                      VARCHAR2(240)
          ,DEVISE                            VARCHAR2(150)
          ,CREATION_DATE                     DATE
          ,JE_HEADER_ID                      NUMBER
          ,PERIODE                           VARCHAR2(25)
		  ,CATEGORIE                         VARCHAR2(25)
          ,NOM_PIECE                         VARCHAR2(250)
          ,NUMERO_PIECE                      NUMBER
		  ,NUMERO_LIGNE                      NUMBER
		  ,CCF                               VARCHAR2(250)
		  ,LIBELLE_CPTE_LOCAL                VARCHAR2(150)
		  ,V_COMPTE_LOCAL                    VARCHAR2(25)
		  ,V_COMPTE_ANALYTIQUE               VARCHAR2(25)
		  ,V_CENTRE_FINANCE                  VARCHAR2(25)
		  ,V_CODE_AFFAIRE                    VARCHAR2(25)
		  ,V_PROJET_FINANCE                  VARCHAR2(25)
		  ,v_LIVRE                             VARCHAR2(20)
          ,v_SOCIETE                           VARCHAR2(25)
		  ,V_INTERCO                         VARCHAR2(25)
		  ,NUM_LIG							 NUMBER(38)
)
TABLESPACE &5;


PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
PROMPT CREATION DES GRANTS                                                                                
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

GRANT ALL ON DKA_SGLFUSION_TMP TO &&1;

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
PROMPT DROP DES SYNONYMES                                                                                
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CONNECT &&1/&&2                                                                                          

DROP SYNONYM DKA_SGLFUSION_TMP;

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
PROMPT CREATE DES SYNONYMES                                                                                
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE SYNONYM DKA_SGLFUSION_TMP FOR DKA.DKA_SGLFUSION_TMP;

EXIT;