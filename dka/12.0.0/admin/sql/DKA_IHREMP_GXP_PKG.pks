CREATE OR REPLACE PACKAGE DKA_IHREMP_GXP_PKG
AS
------------------------------------------------------------------------------------
-- $Id: DKA_IHREMP_GXP_PKG.pks $
-- Capgemini
-- PROJET            : DALKIA
-- NOM               : DKA_IHREMP_GXP_PKG.pks
-- DESCRIPTION       : DKA_IHREMP_GXP_PKG package specifications
---
--- AUTEUR           : Julien Jardez
--- DATE DE CREATION : 11/04/2016
--- DOC. ASSOCIEE    :
--  COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -----------------------------------------------------------------
--- 11/04/2016 JJA Portage HELIOS R12 (Réécriture)
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
  --  pv_debug              Mode Debug (Oui / Non)
  --
  ------------------------------------------------------------------------------------
  PROCEDURE main(pv_errbuf       OUT NOCOPY VARCHAR2,
                 pn_retcode      OUT NOCOPY NUMBER,
                 pv_debug        IN         VARCHAR2
  );

END DKA_IHREMP_GXP_PKG;
/
SHOW ERRORS;
EXIT 
