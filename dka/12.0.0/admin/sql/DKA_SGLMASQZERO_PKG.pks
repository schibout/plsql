create or replace PACKAGE DKA_SGLMASQZERO_PKG AS
--------------------------------------------------------------------------------
-- Programme           : Corps du package DKA_SGLMASQZERO_PKG
-- Version             : 1.0
-- Date de création    : 13/01/2020
-- Auteur              : Capgemini
-- Objet               : Supprimer les lignrsà zéro sous certaines conditions
--                       Ce package est appele par le package gl_import_hook_pkg
--
-- Remarques           :
------------------------------------------------------------------------------
--                INFORMATION RELATIVE A LA MAINTENANCE
------------------------------------------------------------------------------
--    Date         Ver  |      Nom      |   Description de l'intervention
------------------------------------------------------------------------------
--                      |               |                                    |
------------------------------------------------------------------------------
--  13/01/2020     1.0  |     Capgemini | Version creation                   |
------------------------------------------------------------------------------

FUNCTION MAIN (run_id   IN              NUMBER,
               errbuf   IN OUT NOCOPY   VARCHAR2) RETURN BOOLEAN;

END DKA_SGLMASQZERO_PKG;
/
SHOW ERRORS PACKAGE DKA_SGLMASQZERO_PKG;
EXIT
