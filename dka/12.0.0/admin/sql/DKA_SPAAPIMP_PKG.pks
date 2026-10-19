/* Formatted on 05/17/2002 16:12 (Formatter Plus v4.5.2) */
CREATE OR REPLACE PACKAGE DKA_SPAAPIMP_PKG
AS

---------------------------------------------------------------------------------------------------------------
-- CAPGEMINI
-- PROJET            : DALKIA Oracle Applications
-- NOM           : DKA_SPAAPIMP_PKG.pks
-- DESCRIPTION       : Approbation toutes sociétés des factures fournisseurs
---
--- AUTEUR       : Guillaume Chabrier
--- DATE DE CREATION : 15/01/2002
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- 30/10/2007 ADR ETANCHEITE DALKIA 2007
---------------------------------------------------------------------------------------------------------------
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
gn_per_business_group_id NUMBER := TO_NUMBER(FND_PROFILE.VALUE('PER_BUSINESS_GROUP_ID'));
gn_org_id                NUMBER := TO_NUMBER(FND_PROFILE.VALUE('ORG_ID'));
gn_sob                   NUMBER := TO_NUMBER(FND_PROFILE.VALUE('GL_SET_OF_BKS_ID'));

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
END dka_spaapimp_pkg;
/
SHOW ERROR
EXIT;
