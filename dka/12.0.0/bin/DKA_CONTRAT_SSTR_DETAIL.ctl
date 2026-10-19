--------------------------------------------------------------------------------------------
-- FILENAME
--   DKA_CONTRAT_SSTR_DETAIL.ctl   V1.0
--
-- AUTEUR
--   Capgemini
--
-- DESCRIPTION
--   Chargement de la table temporaire DKA_CONTRAT_SSTR_DETAIL_TMP
--
-- USAGE
--   DKA_CONTRAT_SSTR_DETAIL.ctl
--
-- NOTES
--
---------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
---------------------------------------------------------------------------------------------
-- Version   Date         Qui Description
---------- -------------- --- ---------------------------------------------------------------
-- V1.0    28/03/2016     RBE Creation
---------------------------------------------------------------------------------------------

OPTIONS (SKIP=1)
LOAD DATA
APPEND
INTO TABLE DKA_CONTRAT_SSTR_DETAIL_TMP
FIELDS TERMINATED BY '|'
TRAILING NULLCOLS
(
 DATA_TYPE                        CHAR                NULLIF (DATA_TYPE                     = BLANKS)
,DOCUMENT_NUM                     CHAR                NULLIF (DOCUMENT_NUM                  = BLANKS)
,DOCUMENT_NUM_CADRE               CHAR                NULLIF (DOCUMENT_NUM_CADRE            = BLANKS)
,FLAG_TACITE_RECONDUCTION         CHAR                NULLIF (FLAG_TACITE_RECONDUCTION      = BLANKS)
,NB_RECONDUCTION                  INTEGER EXTERNAL    NULLIF (NB_RECONDUCTION               = BLANKS)
,PREAVIS_RESILIATION              INTEGER EXTERNAL    NULLIF (PREAVIS_RESILIATION           = BLANKS)
,FLAG_REVISION                    CHAR                NULLIF (FLAG_REVISION                 = BLANKS)
,DATE_REVISION                    DATE  'YYYY/MM/DD'  NULLIF (DATE_REVISION                 = BLANKS)
,NB_INTERVENTION                  INTEGER EXTERNAL    NULLIF (NB_INTERVENTION               = BLANKS)
,PERIODICITE_INTERVENTION         CHAR                NULLIF (PERIODICITE_INTERVENTION      = BLANKS)
,NB_INTERVENTION_REALISE          INTEGER EXTERNAL    NULLIF (NB_INTERVENTION_REALISE       = BLANKS)
,FLAG_FACTURATION                 CHAR                NULLIF (FLAG_FACTURATION              = BLANKS)
,COMMENTAIRE_FACTURATION          CHAR                NULLIF (COMMENTAIRE_FACTURATION       = BLANKS)
,PERIODICITE_FACTURATION          INTEGER EXTERNAL    NULLIF (PERIODICITE_FACTURATION       = BLANKS)
,SIGNATAIRE_CONTRAT               CHAR                NULLIF (SIGNATAIRE_CONTRAT            = BLANKS)
,REF_CONTRAT_FOURNISSEUR          CHAR                NULLIF (REF_CONTRAT_FOURNISSEUR       = BLANKS)
,DESCRIPTION_SPECIFIQUE_CONTRAT   CHAR                NULLIF (DESCRIPTION_SPECIFIQUE_CONTRAT= BLANKS)
,FLAG_MAIL_AVERTISSEMENT          CHAR                NULLIF (FLAG_MAIL_AVERTISSEMENT       = BLANKS)
,DATE_EFFET                       DATE 'YYYY/MM/DD'   NULLIF (DATE_EFFET                    = BLANKS)
,RECONDUCTION_NUM                 INTEGER EXTERNAL    NULLIF (RECONDUCTION_NUM              = BLANKS)
,REVISION_NUM                     INTEGER EXTERNAL    NULLIF (REVISION_NUM                  = BLANKS)
,COMMANDE_NUM                     CHAR                NULLIF (COMMANDE_NUM                  = BLANKS)
,COMMANDE_VERSION                 INTEGER EXTERNAL    NULLIF (COMMANDE_VERSION              = BLANKS)
,DATE_RESILIATION                 DATE 'YYYY/MM/DD'   NULLIF (DATE_RESILIATION              = BLANKS)
,ANNULATION                       CHAR                NULLIF (ANNULATION                    = BLANKS)
,CREATION_DATE                    SYSDATE
,CREATED_BY                       CONSTANT '!USER_ID!'      
,LAST_UPDATE_DATE                 SYSDATE                   
,LAST_UPDATED_BY                  CONSTANT '!USER_ID!'      
,LOAD_REQUEST_ID                  CONSTANT '!LOAD_REQUEST_ID!'
,STATUT                           CONSTANT '-1'
)

--Fin