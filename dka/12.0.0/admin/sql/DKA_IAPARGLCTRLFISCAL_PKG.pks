CREATE OR REPLACE PACKAGE DKA_IAPARGLCTRLFISCAL_PKG
AS
------------------------------------------------------------------------------------
-- $Id: DKA_IAPARGLCTRLFISCAL_PKG.pks $
-- Capgemini
-- PROJET            : DALKIA
-- NOM               : DKA_IAPARGLCTRLFISCAL_PKG.pks
-- DESCRIPTION       : DKA_IAPARGLCTRLFISCAL_PKG package specifications
---
--- AUTEUR           : Julien Jardez
--- DATE DE CREATION : 20/08/2013
--- DOC. ASSOCIEE    :
--  COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
------------------------------------------------------------------------------------
--- ---------- --- -----------------------------------------------------------------
--- 1100 02/03/2022 SELO EDB334
----------------------------------------------------------------------------------------------
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
  --  pn_periode            Périodicité (1 mois, 2 mois .... 12 mois)
  --
  ------------------------------------------------------------------------------------
  PROCEDURE main(pv_errbuf       OUT NOCOPY VARCHAR2,
                 pn_retcode      OUT NOCOPY NUMBER,
                 pv_societe      IN         VARCHAR2,
                 pn_annee_ref    IN         NUMBER,
                 pn_periode      IN         NUMBER
  );
 PROCEDURE main_auto(pv_errbuf    OUT NOCOPY VARCHAR2,
                       pn_retcode   OUT NOCOPY NUMBER,
                       pv_type_exercice   IN VARCHAR2,
					   pv_annee_extraction in number -- 1100 EDB334
					  )
  ;

END DKA_IAPARGLCTRLFISCAL_PKG;
/
SHOW ERRORS;
EXIT 
