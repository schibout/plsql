CREATE OR REPLACE PACKAGE dka_glparv_pkg
AS

---------------------------------------------------------------------------------------------------------------
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_GLPARV_PKG.pks
-- DESCRIPTION       : Lancement du traitement de contrepassation GL
---
--- AUTEUR           : Xavier Descamps
--- DATE DE CREATION : 15/12/2003
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
---------------------------------------------------------------------------------------------------------------
--- Date       Qui Description
--- ---------- --- --------------------------------------------------------------------------------------------
-- 05/11/02007 ADR ETANCHEITE DALKIA 2007
--- 21/06/2017 OBE artf2179450 : SPE046 - Contre Passation - Erreur de lancement batch DKA_GLPARV_JOB.sh - Defect BeB #831
---------------------------------------------------------------------------------------------------------------

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
/* ETANCHEITE DALKIA 2007 */
gn_per_business_group_id NUMBER := TO_NUMBER(FND_PROFILE.VALUE('PER_BUSINESS_GROUP_ID'));
gn_org_id                NUMBER := TO_NUMBER(FND_PROFILE.VALUE('ORG_ID'));
-- gn_set_of_bks_id         NUMBER := TO_NUMBER(FND_PROFILE.VALUE('GL_SET_OF_BKS_ID')); -- OBE artf2179450
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
---------------------------------------------------------------------------------------------------------------
--  Nom           : main
--  Description   : procédure principale du traitement qui enchaînera l'ensemble
--                  des autres procèdures.
--
--  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
--                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
    PROCEDURE main (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    );
---------------------------------------------------------------------------------------------------------------
END dka_glparv_pkg;
/
SHOW ERROR
EXIT;
