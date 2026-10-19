CREATE OR REPLACE PACKAGE DKA_SRBCTRLRB_PKG
AS
------------------------------------------------------------------------------------
-- $Id: DKA_SRBCTRLRB_PKG.pks $
-- Capgemini
-- PROJET            : DALKIA
-- NOM               : DKA_SRBCTRLRB_PKG.pks
-- DESCRIPTION       : DKA_SRBCTRLRB_PKG package specifications
---
--- AUTEUR           : Florent Peenaert
--- DATE DE CREATION : 05/03/2015
--- DOC. ASSOCIEE    :
--  COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
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
  --  pv_date_test          Date de référence
  --
  ------------------------------------------------------------------------------------
  PROCEDURE main(pv_errbuf       OUT NOCOPY VARCHAR2,
                 pn_retcode      OUT NOCOPY NUMBER,
                 pv_date_test    IN         VARCHAR2
  );

END DKA_SRBCTRLRB_PKG;
/
SHOW ERRORS;
EXIT 
