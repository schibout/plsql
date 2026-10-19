CREATE OR REPLACE PACKAGE DKA_SPOREPCOMCONT_PKG AS
-- -----------------------------------------------------------------------------
-- $$
-- Capgemini
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_SPOREPCOMCONT_PKG.pks
-- DESCRIPTION      : DKA_SPOREPCOMCONT_PKG Package Specifications
--
-- AUTEUR           : A.DELTOUR (Capgemini)
-- DATE DE CREATION : 28/08/2007
-- COMMENTAIRES     : A exécuter sous SQLPLUS avec le user apps
-- -----------------------------------------------------------------------------
--
-- -----------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------
--
-- -----------------------------------------------------------------------------

-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  gn_userid                    FND_USER.USER_ID%TYPE := Fnd_Global.USER_ID;
  gn_login_id                  FND_LOGINS.LOGIN_ID%TYPE := Fnd_Global.LOGIN_ID;
  gn_request_id                FND_CONCURRENT_REQUESTS.REQUEST_ID%TYPE := fnd_global.CONC_REQUEST_ID;
  gn_org_id                    HR_ALL_ORGANIZATION_UNITS.ORGANIZATION_ID%TYPE := fnd_profile.VALUE('ORG_ID');

  TYPE gt_distribution_typ IS TABLE OF PO_DISTRIBUTIONS_INTERFACE%ROWTYPE INDEX BY BINARY_INTEGER;

  gt_distribution_tab  gt_distribution_typ;
  
  TYPE gt_line_typ IS TABLE OF PO_LINES_INTERFACE%ROWTYPE INDEX BY BINARY_INTEGER;
  gt_line_tab  gt_line_typ;

-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- -----------------------------------------------------------------------------
-- Nom              : main
-- Description      : Procédure principale du traitement qui enchaîne l'ensemble
--                    des autres procédures.
--
-- PARAMETRES       : Pv_Errbuf         Sortie Message d'erreur
--                    Pn_Retcode        Sortie Code Retour de la procédure
--                                           '0' : Normal
--                                           '1' : Avertissement
--                                           '2' : Erreur
--
-- VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles :
-- -----------------------------------------------------------------------------
  PROCEDURE Main(Pv_Errbuf            OUT NOCOPY VARCHAR2,
                 Pn_Retcode           OUT NOCOPY NUMBER
                 );

END DKA_SPOREPCOMCONT_PKG;
/
SHOW ERRORS
EXIT
