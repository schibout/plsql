CREATE OR REPLACE PACKAGE DKA_ICE_BANKBRANCHES_DTR_PKG AS
  ------------------------------------------------------------------------------------
  -- $Id: DKA_ICE_BANKBRANCHES_DTR_PKG.pks $
  -- Capgemini
  -- PROJET            : DALKIA
  -- NOM               : DKA_ICE_BANKBRANCHES_DTR_PKG.pks
  -- DESCRIPTION       : DKA_ICE_BANKBRANCHES_DTR_PKG package specifications
  ---
  --- AUTEUR           : Oussama BENHAYOUN
  --- DATE DE CREATION : 19/09/2017
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
  PROCEDURE main(pv_errbuf      OUT NOCOPY VARCHAR2,
                 pn_retcode     OUT NOCOPY NUMBER,
                 p_date_der_exc IN VARCHAR2,
                 p_odate        IN VARCHAR2);

END DKA_ICE_BANKBRANCHES_DTR_PKG;
/
SHOW ERRORS;
EXIT 
