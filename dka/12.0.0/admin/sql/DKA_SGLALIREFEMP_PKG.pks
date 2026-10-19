create or replace PACKAGE DKA_SGLALIREFEMP_PKG AS
--------------------------------------------------------------------------------
-- Programme           : Corps du package DKA_SGLALIREFEMP
-- Version             : 1.0
-- Date de création    : 04/12/2019
-- Auteur              : Capgemini
-- Objet               : Alimenter la reference de lettrazge avec l'employee AP
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
--  18/12/2018     1.0  |     Capgemini | Version creation                   |
------------------------------------------------------------------------------

FUNCTION MAIN (run_id   IN              NUMBER,
               errbuf   IN OUT NOCOPY   VARCHAR2) RETURN BOOLEAN;

END DKA_SGLALIREFEMP_PKG;
/
SHOW ERRORS PACKAGE DKA_SGLALIREFEMP_PKG;
EXIT
