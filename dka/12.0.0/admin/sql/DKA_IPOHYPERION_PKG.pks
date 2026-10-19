CREATE OR REPLACE PACKAGE DKA_IPOHYPERION_PKG AS
  ------------------------------------------------------------------------------------
  -- $Id: DKA_IPOHYPERION_PKG.pks $
  -- Capgemini
  -- PROJET            : DALKIA
  -- NOM               : DKA_IPOHYPERION_PKG.pks
  -- DESCRIPTION       : DKA_IPOHYPERION_PKG package specifications
  ---
  -- AUTEUR           : HAHIOUI Saloua (CAPGEMINI)
  -- DATE DE CREATION : 03/04/2020
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
  PROCEDURE main(pv_errbuf  OUT NOCOPY VARCHAR2,
                 pn_retcode OUT NOCOPY NUMBER);

  ------------------------------------------------------------------------------------
  --  Nom           : main_detail_sstr
  --  Description   : point d'entrée du traitement
  --
  --  PARAMETRES    :
  -- Parametres
  --  pv_errbuf             message d'erreur si pn_retcode != 0
  --  pn_retcode            code de sortie (0 : normal, 1 : warning,2 : erreur)
  --  pv_debug              Mode Debug (Oui / Non)
  --
  ------------------------------------------------------------------------------------
  PROCEDURE main_detail_sstr(pv_errbuf  OUT NOCOPY VARCHAR2,
                             pn_retcode OUT NOCOPY NUMBER);

END DKA_IPOHYPERION_PKG;
/
SHOW ERRORS;
EXIT 
