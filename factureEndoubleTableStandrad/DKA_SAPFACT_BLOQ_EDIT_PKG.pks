CREATE OR REPLACE PACKAGE DKA_SARENCAIS_MAIL_PKG AS

  -- -----------------------------------------------------------------------------
  -- $$
  -- Capgemini
  -- PROJET           : DALKIA Oracle Applications
  -- NOM              : DKA_SARENCAIS_MAIL_PKG .pkb
  -- DESCRIPTION      : DKA_SARENCAIS_MAIL_PKG  Package Specifications
  --
  -- AUTEUR           : Benjamin Coudrier  (Capgemini)
  -- DATE DE CREATION : 20/08/2012
  -- COMMENTAIRES     : A exécuter sous SQLPLUS avec le user apps
  -- -----------------------------------------------------------------------------
  -- HISTORIQUE DES MODIFICATIONS
  -- Date       Qui Description
  -- 10/04/2013 BCO INC000000395045 - Création d'une procédure d'attente de fin d'exécution de
  --           traitement + Lancement de la procédure en début de traitement.
  -- ---------- --- --------------------------------------------------------------

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PUBLIQUES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  BOUNDARY            CONSTANT VARCHAR2(256) := '-----7D81B75CCC90D2974F7A1CBD';
  FIRST_BOUNDARY      CONSTANT VARCHAR2(256) := '--' || BOUNDARY ||
                                                utl_tcp.CRLF;
  LAST_BOUNDARY       CONSTANT VARCHAR2(256) := '--' || BOUNDARY || '--' ||
                                                utl_tcp.CRLF;
  MULTIPART_MIME_TYPE CONSTANT VARCHAR2(256) := 'multipart/mixed; boundary="' ||
                                                BOUNDARY || '"';
  MAX_LINE_WIDTH PLS_INTEGER := 54;

  -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PRIVEES
  -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  -- -----------------------------------------------------------------------------
  -- Nom              : Attente_Fin_Trait_Sarencais
  -- Description      : Procédure d'attente de la fin de tous les traitements.
  --
  -- PARAMETRES       : Pv_Errbuf          Sortie Message d'erreur
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
  PROCEDURE Attente_Fin_Trait_Sarencais(Pv_Errbuf  OUT VARCHAR2,
                                        Pn_Retcode OUT NUMBER);

  ----------------------------------------------------------------------------
  --  Nom           : init
  --  Description   : Procédure d'initialisation
  --
  --  PARAMETRES :
  --    pv_errbuf   Entrée/Sortie          message d'erreur
  --    VALEUR RETOURNEE :  pn_retcode
  --  Valeurs possibles : 0=normal, 1=warning, 2=erreur
  ----------------------------------------------------------------------------
  PROCEDURE init(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER);

  ----------------------------------------------------------------------------
  --  Nom           : write_boundary
  --  Description   : Procédure
  --
  --  PARAMETRES :
  --    VALEUR RETOURNEE :
  --  Valeurs possibles : 0=normal, 1=warning, 2=erreur
  ----------------------------------------------------------------------------
  PROCEDURE write_boundary(conn IN OUT NOCOPY utl_smtp.connection,
                           last IN BOOLEAN DEFAULT FALSE);

  ----------------------------------------------------------------------------
  --  Nom           : begin_attachment
  --  Description   : Procédure
  --
  --  PARAMETRES :
  --    VALEUR RETOURNEE :
  --  Valeurs possibles : 0=normal, 1=warning, 2=erreur
  ----------------------------------------------------------------------------
  PROCEDURE begin_attachment(conn         IN OUT NOCOPY utl_smtp.connection,
                             mime_type    IN VARCHAR2 DEFAULT 'text/plain',
                             inline       IN BOOLEAN DEFAULT TRUE,
                             filename     IN VARCHAR2 DEFAULT NULL,
                             transfer_enc IN VARCHAR2 DEFAULT NULL);

  ----------------------------------------------------------------------------
  --  Nom           : end_attachment
  --  Description   : Procédure
  --
  --  PARAMETRES :
  --    VALEUR RETOURNEE :
  --  Valeurs possibles : 0=normal, 1=warning, 2=erreur
  ----------------------------------------------------------------------------
  PROCEDURE end_attachment(conn IN OUT NOCOPY utl_smtp.connection,
                           last IN BOOLEAN DEFAULT FALSE);

  -------------------------------------------------------------------------------------
  --  Nom           : ENVOI_MAIL
  --  Description   : procedure d'envoi de mail
  --
  --  PARAMETRES    :
  --  pv_program_name   IN       Nom de l'Etat
  --  pv_request_date   IN       Date de l'Etat
  --  pv_file_name      IN       Nom du fichier en pièce jointe.
  --  pv_errbuf         OUT      Message de sortie.
  --  pn_retcode        OUT      Code retour.
  --  VALEUR RETOURNEE :  pn_retcode
  --  Valeurs possibles : 0=normal, 1=warning, 2=erreur
  ------------------------------------------------------------------------------------
  PROCEDURE envoi_mail(pv_program_name IN VARCHAR2,
                       pv_request_date IN VARCHAR2,
                       pv_file_name    IN VARCHAR2,
                       pv_mail         IN VARCHAR2,
                       pv_errbuf       OUT VARCHAR2,
                       pn_retcode      OUT NUMBER);

  -----------------------------------------------------------------
  -- NOM         : main
  -- DESCRIPTION : Procédure principale d'envoi par mail des
  --        rejets de la surtaxe communale.
  --        traitements DKA : Paiement intra groupe AP/AR.
  -- PARAMETRE   : pv_errbuf     OUT   Message de sortie
  --        pn_retcode   OUT   Code retour
  -----------------------------------------------------------------
  PROCEDURE main(pv_errbuf OUT VARCHAR2, pn_retcode OUT NUMBER);

END DKA_SARENCAIS_MAIL_PKG;
/
SHOW ERRORS;

EXIT
