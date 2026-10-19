create or replace PACKAGE DKA_SGLALICUF_PKG AS
--------------------------------------------------------------------------------
-- Programme           : Corps du package DKA_SGLALICUF_PKG
-- Version             : 1.0
-- Date de création    : 18/12/2018
-- Auteur              : Capgemini
-- Objet               : Alimenter les CUF Projet + Tâche + Type de dépense dans GL  en provenance
--                       des auxiliaires et FA
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

FUNCTION MAIN (batch_ids  IN     VARCHAR2,
               separator  IN     VARCHAR2,
               last_set   IN     BOOLEAN,
               errbuf     IN OUT NOCOPY VARCHAR2
               ) RETURN BOOLEAN;

END DKA_SGLALICUF_PKG;
/

SHOW ERRORS PACKAGE DKA_SGLALICUF_PKG;
EXIT