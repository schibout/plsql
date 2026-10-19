-------------------------------------------------------------------------------------------
-- $$
-- CAPGEMINI
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_IPOCTR_SSTR_IVALUA_LOADER.ctl
-- DESCRIPTION	    : Chargement de la table DKA_IPOCTR_SSTR_IVALUA
--
-- AUTEUR           : K.HANNACH
-- DATE DE CREATION : 11/10/2024
-- DOC. ASSOCIEE    :
-- COMMENTAIRE      :Fichier de controle sql*loader                       -
--                   pour le chargement de la table de travail
-------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- -------------------------------------------------------------------------
--  
-------------------------------------------------------------------------------------------

OPTIONS (ERRORS=0,SKIP=1)
LOAD DATA
--CHARACTERSET UTF8
APPEND
INTO TABLE DKA_IPOCTR_SSTR_IVALUA
FIELDS TERMINATED BY '|'
TRAILING NULLCOLS
(
NUM_CONTRAT	             POSITION(1) "RTRIM(LTRIM(:NUM_CONTRAT))"
,VERSION_CONTRAT	             "RTRIM(LTRIM(:VERSION_CONTRAT))"
,DATE_DEBUT_PERIODE	             DATE  'DD/MM/YYYY'   NULLIF (DATE_DEBUT_PERIODE= BLANKS)
,DATE_FIN_PERIODE	             DATE  'DD/MM/YYYY'   NULLIF (DATE_FIN_PERIODE= BLANKS)
,NUM_COMMANDE	                 "RTRIM(LTRIM(:NUM_COMMANDE))"
,VERSION_COMMANDE	             "RTRIM(LTRIM(:VERSION_COMMANDE))"
,MONTANT_CONTRAT                 "REPLACE(:MONTANT_CONTRAT,',','.')" 
,DATE_RESILIATION	             DATE  'DD/MM/YYYY'   NULLIF (DATE_RESILIATION= BLANKS)  "REPLACE(:DATE_RESILIATION,CHR(13),'')"
,CREATION_DATE                   SYSDATE
,CREATED_BY                      CONSTANT '!USER_ID!'
,LAST_UPDATE_DATE                SYSDATE
,LAST_UPDATED_BY                 CONSTANT '!USER_ID!'     
,STATUT	                         CONSTANT "NEW"         
,FILE_NAME	                     CONSTANT '!FILE_NAME!'   
,LINE_NUM	                     RECNUM  
,RECORD_ID	                     "DKA_IPOCTR_SSTR_IVALUA_s.NEXTVAL" 
,LOADER_REQUEST_ID	             CONSTANT '!LOAD_REQUEST_ID!'
)
--Fin