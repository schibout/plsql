CREATE OR REPLACE PACKAGE DKA_SPOWFDA_ERRORS_PKG
AS

----------------------------------------------------------------------------
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SPOWFDA_ERRORS_PKG.pks
-- DESCRIPTION       : DKA_SPOWFDA_ERRORS_PKG package spécifications
---
--- AUTEUR           : C. Delcasso
--- DATE DE CREATION : 26/09/2006
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- ---------------------------------------------------------
--- 25/10/2016 RGH Migration R12
----------------------------------------------------------------------------


----------------------------------------------------------------------------
--  Nom           : init
--  Description   : Procédure d'initialisation
--
--PARAMETRES :
--  pv_errbuf   Entrée/Sortie          message d'erreur
--  VALEUR RETOURNEE :  pn_retcode
--Valeurs possibles : 0=normal, 1=warning, 2=erreur
----------------------------------------------------------------------------
    PROCEDURE init (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    );


----------------------------------------------------------------------------
--  Nom           : insert_dka_spowfda_errors
--  Description   :
--
--PARAMETRES :
--  pv_errbuf   Entrée/Sortie          message d'erreur
--  VALEUR RETOURNEE :  pn_retcode
--Valeurs possibles : 0=normal, 1=warning, 2=erreur
----------------------------------------------------------------------------
    PROCEDURE insert_dka_spowfda_errors (
        pv_errbuf           IN OUT  VARCHAR2,
        pn_retcode          OUT     NUMBER
    );

-------------------------------------------------------------------------------------
--  Nom           : maj_da
--  Description   :
--
--  PARAMETRES    :
--    pv_errbuf       Sortie
--    pv_retcode          Sortie

--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: OK, 2: erreur ou code erreur ORA
------------------------------------------------------------------------------------
    PROCEDURE maj_da (
        pn_requisition_header_id     IN    NUMBER,
        pv_errbuf                   OUT   VARCHAR2,
        pn_retcode                  OUT   NUMBER
    );

-------------------------------------------------------------------------------------
--  Nom           : fermeture_notif_erreur
--  Description   :
--
--  PARAMETRES    :
--    pv_errbuf       Sortie
--    pv_retcode          Sortie

--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: OK, 2: erreur ou code erreur ORA
------------------------------------------------------------------------------------
    PROCEDURE fermeture_notif_erreur (
        pn_notif_err                IN    NUMBER,
        pv_item_key_err             IN    VARCHAR2,
        pv_item_key_da              IN    VARCHAR2,
        pv_errbuf                   OUT   VARCHAR2,
        pn_retcode                  OUT   NUMBER
    );

-------------------------------------------------------------------------------------
--  Nom           : mail
--  Description   :
--
--  PARAMETRES    :
--    pv_errbuf       Sortie
--    pv_retcode          Sortie

--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: OK, 2: erreur ou code erreur ORA
------------------------------------------------------------------------------------
    PROCEDURE mail (
        pv_segment1                 IN    VARCHAR2,
        pv_description              IN    VARCHAR2,
        pv_centrefinance_demandeur         IN    VARCHAR2,
        pv_adresse_mail             IN    VARCHAR2,
        pv_destinataire             IN    VARCHAR2,
        pv_errbuf                   OUT   VARCHAR2,
        pn_retcode                  OUT   NUMBER
    );

-------------------------------------------------------------------------------------
--  Nom           : deblocage_da
--  Description   :
--
--  PARAMETRES    :
--    pv_errbuf       Sortie
--    pv_retcode          Sortie

--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: OK, 2: erreur ou code erreur ORA
------------------------------------------------------------------------------------

    PROCEDURE deblocage_da (
        pv_errbuf       OUT      VARCHAR2,
        pn_retcode      OUT      NUMBER
    );

-------------------------------------------------------------------------------------
--  Nom           : envoi_mail
--  Description   :
--
--  PARAMETRES    :
--    pv_errbuf       Sortie
--    pv_retcode          Sortie

--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: OK, 2: erreur ou code erreur ORA
------------------------------------------------------------------------------------

    PROCEDURE envoi_mail (
        pv_errbuf       OUT      VARCHAR2,
        pn_retcode      OUT      NUMBER
    );

--------------------------------------------------------------------------------------
 --  Nom           : MAIN
 --  Description   : Procédure principale enchaînant l'ensemble des autres procédures
 --
 --  PARAMETRES :
 --    pv_errbuf                   Entrée/Sortie       retour de message eventuel
 --    pn_retcode                  Sortie          status du traitement en sortie
 --
 --  VALEUR RETOURNEE :
 --     Description       : code retour de validité
 --     Valeurs possibles : 0: normal, 1: warning, 2: erreur
 --
 ----------------------------------------------------------------------------------------
    PROCEDURE main (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER,
        pv_mail_test IN VARCHAR2
    );

END DKA_SPOWFDA_ERRORS_PKG;
/

SHOW ERROR

EXIT