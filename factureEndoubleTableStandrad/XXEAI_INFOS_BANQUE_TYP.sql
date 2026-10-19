SET VERIFY OFF;
DEFINE package_name = "DKA_SFNDCLOSETP_WF_PKG";

CREATE OR REPLACE PACKAGE &&package_name
AS
----------------------------------------------------------------------------------------------
-- $Id$
-- CAPGEMINI
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SFNDCLOSETP_WF_PKG.pks
-- DESCRIPTION       : DKA_SFNDCLOSETP_WF_PKG package spec :procedure utiliser dans le workflow
--- AUTEUR           : Julien Jardez
--- DATE DE CREATION : 02/02/2012
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--------------------------------------------------------------------------------------------


--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

 -------------------------------------------------------------------------------------------------------------------
 --  Nom           : IS_CLOSE_TP
 --  Description   : Vérification de la constante d'ouverture ou fermeture du TP
 --
 --  PARAMETRES    :
 --    itemtype        varchar2
 --    itemkey         varchar2
 --    actid           number
 --    funcmode        varchar2
 --  VALEUR RETOURNEE :
 --     Description       : Resultat de la verification
 --     Valeurs possibles : Yes:
 --                         No :
 -------------------------------------------------------------------------------------------------------------------
 PROCEDURE is_close_TP (
    itemtype    IN       VARCHAR2
   ,itemkey     IN       VARCHAR2
   ,actid       IN       NUMBER
   ,funcmode    IN       VARCHAR2
   ,resultout   OUT      VARCHAR2
 );


END &&package_name;
/
SHOW ERRORS;

EXIT;
