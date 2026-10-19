CREATE OR REPLACE PACKAGE DKA_IAPCTRFLUX_XEROX_PKG AS
------------------------------------------------------------------------
-- $Id: DKA_IAPCTRFLUX_XEROX_PKG.pks 3586 2010-05-18 12:54:04Z CORP\qvanhout $
-- Projet           : Dalkia Puissance 4
-- Nom              : DKA_IAPCTRFLUX_XEROX_PKG.pks
-- Description      : Specification du package
--                    DKA_IAPCTRFLUX_XEROX_PKG
-- Auteur           : Mehdi Slama (Capgemini)
-- Date de creation : 13/02/2009
-- Commentaire      : A executer sous SQLPLUS avec le user APPS
------------------------------------------------------------------------
-- Historique des modifications
-- Date       Qui Description
-- ---------- --- ------------------------------------------------------
-- 2016/09/16 JJA Portage Helios 2016
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
  PROCEDURE main(pv_errbuf           OUT VARCHAR2,
                 pn_retcode          OUT NUMBER);
  
-- Insertion des de la table temporaire dans la table interface Xerox 
  PROCEDURE insert_dka_iapctrflux_xerox(pv_errbuf     OUT VARCHAR2,
                                        pn_retcode    OUT NUMBER);
                 
END DKA_IAPCTRFLUX_XEROX_PKG;

/
SHOW ERROR PACKAGE DKA_IAPCTRFLUX_XEROX_PKG;
EXIT
