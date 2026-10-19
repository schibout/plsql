CREATE OR REPLACE PACKAGE DKA_RGLEXPORT89_PKG
AS
------------------------------------------------------------------------------------
-- $Id: DKA_RGLEXPORT89_PKG.pks $
-- Capgemini
-- PROJET            : DALKIA
-- NOM               : DKA_RGLEXPORT89_PKG.pks
-- DESCRIPTION       : DKA_RGLEXPORT89_PKG package specifications
---
--- AUTEUR           : Julien Jardez
--- DATE DE CREATION : 17/12/2013
--- DOC. ASSOCIEE    :
--  COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
------------------------------------------------------------------------------------
--- ---------- --- -----------------------------------------------------------------
---
------------------------------------------------------------------------------------


--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PUBLIQUES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  ------------------------------------------------------------------------------------
  --  Nom           : main
  --  Description   : point d'entrée du traitement
  --
  --  PARAMETRES    :
  -- Parametres
  --  pv_errbuf             message d'erreur si pn_retcode != 0
  --  pn_retcode            code de sortie (0 : normal, 1 : warning,2 : erreur)
  --  pv_societe            Societe
  --  pn_annee_ref          Année de référence
  --
  ------------------------------------------------------------------------------------
  PROCEDURE main(pv_errbuf       OUT NOCOPY VARCHAR2,
                 pn_retcode      OUT NOCOPY NUMBER,
                 pv_societe      IN         VARCHAR2,
                 pn_annee_ref    IN         NUMBER
  );

END DKA_RGLEXPORT89_PKG;
/
SHOW ERRORS;
EXIT 
