-------------------------------------------------------------------------------------------
-- $$
-- CAPGEMINI
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_SARG00C8_LOAD.ctl
-- DESCRIPTION	    : Chargement de la table DKA_SARG00C8
--
-- AUTEUR           : E.Matuszewski
-- DATE DE CREATION : 02/05/2011
-- DOC. ASSOCIEE    :
-- COMMENTAIRE      : 
-------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- -------------------------------------------------------------------------
--  
-------------------------------------------------------------------------------------------
LOAD DATA 
REPLACE
INTO TABLE DKA.DKA_SARG00C8
TRAILING NULLCOLS
  ( SOCIETE          POSITION(1:3)     "LPAD(:SOCIETE, 4, '0')"
  , NUM_FACTURE      POSITION(4:9)
  , DATE_FACTURE     POSITION(10:17)   "TO_DATE(:DATE_FACTURE, 'YYYYMMDD')"
  , CLIENT_PAYEUR    POSITION(18:25)   "LPAD(:CLIENT_PAYEUR, 8, '0')"
  , ORIGINE_FACTURE  POSITION(26:26)
  , CONTRAT_NEGOCE   POSITION(27:27)
  , MONTANT_TTC      POSITION(28:40)   "LTRIM(RTRIM(:MONTANT_TTC))"
  , SIGNE            POSITION(41:41)
  , INDIC_ANNULE     POSITION(42:42)
  , CREATION_DATE                      SYSDATE
  )
