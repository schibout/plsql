CREATE OR REPLACE PACKAGE DKA_IHREMP_PKG
AS
------------------------------------------------------------------------------------
-- $Id: DKA_IHREMP_PKG.pks $
-- Capgemini
-- PROJET            : DALKIA
-- NOM               : DKA_IHREMP_PKG.pks
-- DESCRIPTION       : DKA_IHREMP_PKG package specifications
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
--- 09/05/2017 MEG artf2151094 : EDB067_INT076 - Modification du contrôle sur le champ SOURCE
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

END DKA_IHREMP_PKG;
/
SHOW ERRORS;
EXIT 
