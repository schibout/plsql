CREATE OR REPLACE PACKAGE DKA_IAPCTRFLUX_IVALUA_PKG AS
  ------------------------------------------------------------------------
  -- $Id: DKA_IAPCTRFLUX_XEROX_PKG.pks 
  -- Nom              : DKA.DKA_IAPCTRFLUX_IVALUA_PKG.pks
  -- Description      : Corps du package DKA.DKA_IAPCTRFLUX_IVALUA_PKG
  -- Auteur           : Mathieu TIABLIKOFF (Capgemini)
  -- Date de creation : 24/09/2020
  -- Commentaire      : A executer sous sqlplus avec le user APPS
  ------------------------------------------------------------------------
  -- Historique des modifications
  -- Date       Qui Description
  -- ---------- --- ------------------------------------------------------
  ------------------------------------------------------------------------

  ----------------------------------------------------------------------
  -- Genere un fichier CSV contenant, pour une periode donnee, le nombre
  -- de blocages crees et liberes.
  --
  -- Parametres
  --  pv_errbuf             message d'erreur si pn_retcode != 0
  --  pn_retcode            code de sortie (0 : normal, 1 : warning,
  --                        2 : erreur)
  ----------------------------------------------------------------------
  PROCEDURE main(pv_errbuf OUT VARCHAR2, pn_retcode OUT NUMBER);

  -- Insertion des de la table temporaire dans la table interface Xerox
  PROCEDURE insert_dka_iapctrflux_ivalua(pv_errbuf  OUT VARCHAR2,
                                         pn_retcode OUT NUMBER);

END DKA_IAPCTRFLUX_IVALUA_PKG;
/
SHOW ERROR PACKAGE DKA_IAPCTRFLUX_XEROX_PKG;
EXIT
