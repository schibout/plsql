CREATE OR REPLACE PACKAGE DKA_IPOEXTRACTCDE_PKG
AS

------------------------------------------------------------------------------------
-- $Id: DKA_IPOEXTRACTCDE_PKG.pks 190 2008-03-17 16:10:08Z NORDEST\jdequidt $
-- Capgemini
-- PROJET            : Helios
-- NOM               : DKA_IPOEXTRACTCDE_PKG.pks
-- DESCRIPTION       : DKA_IPOEXTRACTCDE_PKG package specifications
---
--- AUTEUR           : Jonathan Dequidt (Capgemini)
--- DATE DE CREATION : 25/01/2008
--- DOC. ASSOCIEE    :
--  COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -----------------------------------------------------------------
--- 03/05/2016 BDE Modifications du nom du package XXVE_IPOEXTRACTCDE_PKG en DKA_IPOEXTRACTCDE_PKG
------------------------------------------------------------------------------------


--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PUBLIQUES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

------------------------------------------------------------------------------------
--  Nom           : main
--  Description   : point d'entrée du traitement
--
--  PARAMETRES    :
--      pv_errbuf       message d'erreur
--      pn_retcode      code de retour
--  VALEUR RETOURNEE :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
------------------------------------------------------------------------------------
    PROCEDURE main (
        pv_errbuf     OUT      VARCHAR2,
        pn_retcode    OUT      NUMBER
    );

END DKA_IPOEXTRACTCDE_PKG;
/
show errors package DKA_IPOEXTRACTCDE_PKG;
EXIT;
