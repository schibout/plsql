create or replace PACKAGE DKA_SEND_MAIL_PKG
AS

----------------------------------------------------------------------------------------------
-- $ $
--
-- NOM               : DKA_SEND_MAIL_PKG.pks
-- DESCRIPTION       : DKA_SEND_MAIL_PKG package spec : fonctions d'envoi de mail
---
--- AUTEUR           : J. JARDEZ
--- DATE DE CREATION : 25/03/2014
--- DOC. ASSOCIEE    :
---
----------------------------------------------------------------------------------------------
--- NOM DU PROGRAMME :
--- PARAMETRES       :
---
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--------------------------------------------------------------------------------------------

-----------------------------------------------------------------
--  Variables globales
-----------------------------------------------------------------
    gv_debug_mode        VARCHAR2 (1);

  -- -----------------------------------------------------------------------------
  -- Nom              : send_mail
  -- Description      : Procédure d'envoi de mail
  --
  -- PARAMETRES       : Pn_Request_Id      Sortie Numéro de traitement lancé
  --                    Pv_Errbuf          Sortie Message d'erreur
  --                    Pn_Retcode         Sortie Code Retour de la procédure
  --                                              '0' : Normal
  --                                              '1' : Avertissement
  --                                              '2' : Erreur
  --
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  -- -----------------------------------------------------------------------------
  PROCEDURE Send_Mail(Pv_Errbuf                OUT VARCHAR2,
                      Pn_Retcode               OUT NUMBER,
                      Pv_connexion          IN     VARCHAR2, --Connexion
                      Pv_expediteur         IN     VARCHAR2, --Expéditeur
                      Pv_retour_mail        IN     VARCHAR2, --Mail de retour
                      Pv_liste_destinataire IN     VARCHAR2, --JDV des destinataires
                      Pv_message_subject    IN     VARCHAR2, --Texte a mettre en objet
                      Pv_message_corps      IN     VARCHAR2, --Texte a mettre dans le corps
                      Pv_directory          IN     VARCHAR2, --Nom de a directory a utiliser pour ajouter les fichiers joints
                      Pv_liste_fichier      IN     VARCHAR2,  --Listes des fichiers séparés par des '/'
                      Pv_JDV_Attribute1     IN     VARCHAR2 DEFAULT NULL --Cuf Attribute1 JDV des destinataires
                      );

    --PRAGMA RESTRICT_REFERENCES (Send_Mail, WNDS);

----------------------------------------------------------------------------
--  Nom           : mail_test
--  Description   : Procedure mail_test
--
--PARAMETRES :
--  pv_mail_test   Entree   Mail de test
--  pv_mail_cible  Sortie   Mail cible
----------------------------------------------------------------------------
    PROCEDURE mail_test (pv_mail_test    IN    VARCHAR2,
                         pv_mail_cible   OUT   VARCHAR2);

END DKA_SEND_MAIL_PKG; -- Spécification du package
/

SHOW ERRORS PACKAGE DKA_SEND_MAIL_PKG; 
EXIT