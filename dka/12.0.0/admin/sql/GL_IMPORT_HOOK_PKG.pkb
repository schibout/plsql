CREATE OR REPLACE PACKAGE BODY APPS.gl_import_hook_pkg AS
/* $Header: glujihkb.pls 120.5 2005/05/05 01:39:55 kvora ship $ */
--------------------------------------------------------------------------------
-- Programme           : Package GL_IMPORT_HOOK_PKG
-- Version             : 1.0
-- Date de création    : 08/01/2019
-- Auteur              : SNI
-- Objet               : Alimenter les CUF Projet + Tâche + Type de dépense dans GL  en provenance
--                       des auxiliaires et FA
--                       Ce package est appele par le package GL_IMPORT_HOOK_PKG
--
-- Remarques           :
------------------------------------------------------------------------------
--  Date modif      Qui    Commentaire
-- 11/01/2019       CDE    Correction nom du package spécifique
-- 20/04/2020       CDE    Version incluant EDB109 et EDB247
------------------------------------------------------------------------------
--
-- PUBLIC FUNCTIONS
--

  --
  -- Procedure
  --   pre_module_hook
  -- Purpose
  --   Hook into journal import for other products.
  --   This procedure is called after journal import has selected
  --   the sources to process, but before it has started processing the data.
  --   If you need to use this hook, please add a call to your own
  --   package before the return statement.  Please do NOT commit
  --   your changes in your package.
  -- Returns
  --   TRUE - upon success (allows journal import to continue)
  --   FALSE - upon failure (causes journal import to abort and display the
  --			     error in errbuf)
  -- History
  --   19-JUN-95  D. J. Ogg    Created
  -- Arguments
  --   run_id		The import run id
  --   errbuf		The error message printed upon error
  -- Example
  --   gl_import_hook_pkg.pre_module_hook(2, 100, errbuf);
  -- Notes
  --
  FUNCTION pre_module_hook(run_id    IN     NUMBER,
			   errbuf    IN OUT NOCOPY VARCHAR2) RETURN BOOLEAN IS
  BEGIN
    -- Please put your function call here.  Make it the following format:
    --    IF (NOT dummy(sob_id, run_id, errbuf)) THEN
    --      RETURN(FALSE);
    --    END IF;

    IF NOT DKA_SGLALIREFEMP_PKG.MAIN (run_id => run_id, errbuf => errbuf)
    THEN
       RETURN FALSE;
    END IF;

    IF NOT dka_sglmasqzero_pkg.MAIN (run_id => run_id, errbuf => errbuf)
    THEN
       RETURN FALSE;
    END IF;

    RETURN(TRUE);

  END pre_module_hook;


  --
  -- Procedure
  --   post_module_hook
  -- Purpose
  --   Hook into journal import for other products.
  --   This procedure is called after journal import has inserted all of the
  --   data into gl_je_batches, gl_je_headers, and gl_je_lines, but before
  --   it does the final commit.
  --   This routine is called once per 100 batches.
  --   If you need to use this hook, please add a call to your own
  --   package before the return statement.  Please do NOT commit
  --   your changes in your package.
  -- Returns
  --   TRUE - upon success (allows journal import to continue)
  --   FALSE - upon failure (causes journal import to abort and display the
  --			     error in errbuf)
  -- History
  --   28-FEB-00  D. J. Ogg    Created
  -- Arguments
  --   batch_ids        A list of batch ids, separated by the separator
  --   separator        The separator
  --   last_set         Indicates whether or not this is the last set
  --   errbuf		The error message printed upon error
  -- Example
  --   gl_import_hook_pkg.post_module_hook(2, 100, errbuf);
  -- Notes
  --
  FUNCTION post_module_hook(batch_ids  IN     VARCHAR2,
                            separator  IN     VARCHAR2,
                            last_set   IN     BOOLEAN,
			    errbuf     IN OUT NOCOPY VARCHAR2) RETURN BOOLEAN IS


  BEGIN
    -- gl_ip_process_batches_pkg.process_batches(batch_ids, separator, last_set);

    -- Please put your function call here.  Make it the following format:
    --    IF (NOT dummy(sob_id, run_id, errbuf)) THEN
    --      RETURN(FALSE);
    --    END IF;

    -- Mise a jour du CUF des lignes des pieces GL venant des auxiliaires artf3029416
    IF NOT DKA_SGLALICUF_PKG.MAIN (batch_ids => batch_ids, separator => separator, last_set => last_set, errbuf => errbuf)
    THEN
       RETURN FALSE;
    END IF;
    RETURN(TRUE);
  END post_module_hook;
END gl_import_hook_pkg;
/
SHOW ERRORS;

EXIT