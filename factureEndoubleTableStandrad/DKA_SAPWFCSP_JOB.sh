-------------------------------------------------------------------------------------------
-- $$
-- CAPGEMINI
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_IPOFRS_REP_IVALUA_LOADER_TAB.ctl
-- DESCRIPTION	    : Chargement de la table DKA_IPOFRS_MAJ_SITES_REPRIS
--
-- AUTEUR           : 
-- DATE DE CREATION : /05/2020
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
INTO TABLE DKA_IPOFRS_MAJ_SITES_REPRIS
FIELDS TERMINATED BY '|'
TRAILING NULLCOLS
(
SUPPLIER_NUMBER	             "RTRIM(LTRIM(:SUPPLIER_NUMBER))"
,VENDOR_SITE_ID	             "RTRIM(LTRIM(:VENDOR_SITE_ID))"
,IVALUA_SITE_SUPPLIER_ID     "REPLACE(:IVALUA_SITE_SUPPLIER_ID,CHR(13),'')"
,CREATION_DATE               SYSDATE
,CREATED_BY                  CONSTANT '!USER_ID!'
,LAST_UPDATE_DATE            SYSDATE
,LAST_UPDATED_BY             CONSTANT '!USER_ID!'     
,STATUT	                     CONSTANT "NEW"
,FILE_NAME	                 CONSTANT '!FILE_NAME!'
,LINE_NUM	                 RECNUM   
,RECORD_ID	                 "DKA_IPOFRS_MAJ_SITES_REPRIS_S.NEXTVAL" 
,LOADER_REQUEST_ID	         CONSTANT '!LOAD_REQUEST_ID!'
)



--Fin