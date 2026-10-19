CREATE OR REPLACE PACKAGE DKA_SAPSUIVI_NOTIF_PKG 
AS

----------------------------------------------------------------------------
-- $Id$
-- CAP GEMINI
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SAPSUIVI_NOTIF_PKG.pks
-- DESCRIPTION       : DKA_SAPSUIVI_NOTIF_PKG package specifications
---
--- AUTEUR           : J. JARDEZ
--- DATE DE CREATION : 19/06/2008
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A executer sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- ---------------------------------------------------------
--- 2017/03/09 JJA artf2116249: ajout d'un parametre pour mail test
----------------------------------------------------------------------------

--Tableau de lignes de blocage
TYPE  T_BLOCAGE_TAB IS TABLE OF VARCHAR2(4000) INDEX BY BINARY_INTEGER;

--Enregistrement contenant le code blocage + les lignes de blocage
TYPE R_BLOCAGE IS RECORD
 (nom_blocage VARCHAR2(100),
  tab_blocage T_BLOCAGE_TAB);

--Tableau
TYPE T_LISTE_BLOCAGE IS TABLE OF R_BLOCAGE INDEX BY BINARY_INTEGER;

--------------------------------------------------------------------------------------
 --  Nom           : MAIN
 --  Description   : Procedure principale enchainant l'ensemble des autres procedures
 --
 --  PARAMETRES :
 --    pv_errbuf                   Entree/Sortie   retour de message eventuel
 --    pn_retcode                  Sortie          status du traitement en sortie
 --    pv_debug                    Entree          Mode debug ?
 --    pv_mail_test                Entree          Adresse mail destinataire pour test
 --
 --  VALEUR RETOURNEE :
 --     Description       : code retour de validite
 --     Valeurs possibles : 0: normal, 1: warning, 2: erreur
 --
 ----------------------------------------------------------------------------------------
    PROCEDURE main (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER,
        pv_debug     IN       VARCHAR2,
        pv_mail_test IN       VARCHAR2
    );

END DKA_SAPSUIVI_NOTIF_PKG;
/
SHOW ERRORS
EXIT
