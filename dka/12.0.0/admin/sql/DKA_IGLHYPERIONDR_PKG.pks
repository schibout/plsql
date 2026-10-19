CREATE OR REPLACE PACKAGE APPS.DKA_IGLHYPERIONDR_PKG AS
  ------------------------------------------------------------------------------------
  -- $Id: DKA_IGLHYPERIONDR_PKG.pks $
  -- Capgemini
  -- PROJET            : DALKIA
  -- NOM               : DKA_IGLHYPERIONDR_PKG.pks
  -- DESCRIPTION       : DKA_IGLHYPERIONDR_PKG package specifications
  ---
  --- AUTEUR           : Maxime EGOT
  --- DATE DE CREATION : 04/11/2016
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
  --  pv_debug              Mode Debug (Oui / Non)
  --
  ------------------------------------------------------------------------------------
  PROCEDURE main(pv_errbuf       OUT NOCOPY VARCHAR2,
                 pn_retcode      OUT NOCOPY NUMBER,
                 pv_livre        IN VARCHAR2,
                 pv_period_param IN VARCHAR2);
				 
 PROCEDURE main_qte(pv_errbuf       OUT NOCOPY VARCHAR2,
                 pn_retcode      OUT NOCOPY NUMBER,
                 pv_livre        IN VARCHAR2,
                 pv_period_param IN VARCHAR2);
END DKA_IGLHYPERIONDR_PKG;
/
SHOW ERRORS;
EXIT 
