CREATE OR REPLACE PACKAGE DKA_SPO_REQAPPRV_PKG 
AS

----------------------------------------------------------------------------
-- $Id$
-- CAP GEMINI
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SPO_REQAPPRV_PKG.pks
-- DESCRIPTION       : DKA_SPO_REQAPPRV_PKG package specifications
---
--- AUTEUR           : R. BELAYACHI
--- DATE DE CREATION : 08/05/2017
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A executer sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- ---------------------------------------------------------
----------------------------------------------------------------------------

--------------------------------------------------------------------------------------
 --  Nom           : GET_NB_APPROVER
 --  Description   : Fonction qui retourne le nombre des approbateurs d'une DA
 --
 --  PARAMETRES :
 --    PN_TRANSACTION_ID   : Id de la DA
 --
 --  VALEUR RETOURNEE :
 --     Nombre des approbateurs DA
 --
 ----------------------------------------------------------------------------------------
    FUNCTION GET_NB_APPROVER (
                                PN_TRANSACTION_ID  IN  NUMBER
                              ) RETURN NUMBER;

END DKA_SPO_REQAPPRV_PKG;
/
SHOW ERRORS
EXIT
