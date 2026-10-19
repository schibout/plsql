CREATE OR REPLACE PACKAGE APPS.DKA_SARETAT_AVOIR_REG_PKG IS
--------------------------------------------------------------------------------
  -- $
  -- Capgemini
  -- Projet           : DALKIA Oracle Applications
  -- Nom              : APPS.DKA_SARETAT_AVOIR_REG_PKG
  -- Description      : ENTETE du package APPS.DKA_SARETAT_AVOIR_REG_PKG
  -- Auteur           : ANAS RAOUF
  -- Date de création : 06/12/2024
  -- Doc. associée    :
  -- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur APPS
  --------------------------------------------------------------------------------
  -- Historique
  -- Date       Qui Description
  -- ---------- --- --------------------------------------------------------------

  --------------------------------------------------------------------------------

  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PRIVEES
  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PRIVEES
  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  ------------------------------------------------------------------------------------
  -- Nom              : Main
  -- Description      : Procédure principale du traitement
  --
  -- PARAMETRES       : p_errbuf         Sortie Message d'erreur
  --                    p_retcode        Sortie Code Retour de la procédure,
  --                                             '0' : Normal
  --                                             '1' : Avertissement
  --                                             '2' : Erreur
  --                    p_envoi_mail     p_envoi_mail
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  ------------------------------------------------------------------------------------
PROCEDURE out_msg(p_message in varchar2);
PROCEDURE log_msg(p_message in varchar2);
PROCEDURE init(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER);
PROCEDURE write_boundary(conn IN OUT NOCOPY utl_smtp.connection,
                             last IN BOOLEAN DEFAULT FALSE) ;
PROCEDURE begin_attachment(conn         IN OUT NOCOPY utl_smtp.connection,
                               mime_type    IN VARCHAR2 DEFAULT 'text/plain',
                               inline       IN BOOLEAN DEFAULT TRUE,
                               filename     IN VARCHAR2 DEFAULT NULL,
                               transfer_enc IN VARCHAR2 DEFAULT NULL);
 PROCEDURE end_attachment(conn IN OUT NOCOPY utl_smtp.connection,
                             last IN BOOLEAN DEFAULT FALSE);
 procedure check_value_set(p_value_set_name in fnd_flex_value_sets.flex_value_set_name%type
                ,p_errbuf    OUT      VARCHAR2,
                p_retcode   OUT      NUMBER);


PROCEDURE writeout(P_message IN VARCHAR2);

PROCEDURE extraction_avoir_reglee(Pv_Errbuf   IN OUT VARCHAR2,
                                 Pn_Retcode  IN OUT NUMBER,P_REGION       IN VARCHAR2,vv_filename  OUT VARCHAR2);
PROCEDURE main(
                P_ERRBUF    IN OUT  VARCHAR2,
                P_RETCODE   OUT     NUMBER,
                P_REGION       IN VARCHAR2) ;
END DKA_SARETAT_AVOIR_REG_PKG;

/
SHOW ERRORS
EXIT
