CREATE OR REPLACE PACKAGE dka_iporecvtotal_pkg IS
  ---PROD------------------------------------------------------------------------------------------------------------
  -- $Id: DKA_IPORECVTOTAL_PKG.pks 264 2007-09-18 08:29:21Z NORDEST\nboussek $
  --
  -- CAPGEMINI
  -- PROJET             : DALKIA Oracle Applications
  -- NOM                : DKA_SPORECEP_FRAISPORT.pks
  -- DESCRIPTION        : DKA_SPORECEP_FRAISPORT package spec :
  ---
  --- AUTEUR        : Nicolas BOUSSEKEYT
  --- DATE DE CREATION  : 30/08/2007
  --- DOC. ASSOCIEE     :
  -- COMMENTAIRE        : A exécuter sous SQLPLUS avec le user APPS
  ---------------------------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- 26022010   MSL EID20090220 : Ajout procédures correction_reception, complement_recept_correction
  ---                              complement_recept_correction_2
  ---------------------------------------------------------------------------------------------------------------


  -----------------------------------------------------------------
  -- NOM         : put_line_log
  -- DESCRIPTION : Ecrit une ligne dans le fichier log du traitement
  -----------------------------------------------------------------
  PROCEDURE put_line_log(pv_buffer IN VARCHAR2);

  -----------------------------------------------------------------
  -- NOM         : put_line_out
  -- DESCRIPTION : Ecrit une ligne dans le fichier out du traitement
  -----------------------------------------------------------------
  PROCEDURE put_line_out(pv_buffer IN VARCHAR2);
  
  -------------------------------------------------------------------------------------
  --  Nom           : correction_reception
  --  Description   : Procédure qui permet de corriger les receptions 
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE correction_reception(itemtype  IN VARCHAR2,
                                 itemkey   IN VARCHAR2,
                                 actid     IN NUMBER,
                                 funcmode  IN VARCHAR2,                            
                                 resultout OUT NOCOPY VARCHAR2);

  -------------------------------------------------------------------------------------
  --  Nom           : complement_recept_correction
  --  Description   : Procédure qui permet de completer les receptions 
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
   PROCEDURE complement_recept_correction(itemtype  IN VARCHAR2,
                                             itemkey   IN VARCHAR2,
                                             actid     IN NUMBER,
                                             funcmode  IN VARCHAR2,                            
                                             resultout OUT NOCOPY VARCHAR2);
  -------------------------------------------------------------------------------------
  --  Nom           : complement_recept_creation
  --  Description   : Procédure qui permet de completer les receptions 
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
   PROCEDURE complement_recept_correction_2(itemtype  IN VARCHAR2,
                                            itemkey   IN VARCHAR2,
                                            actid     IN NUMBER,
                                            funcmode  IN VARCHAR2,                            
                                            resultout OUT NOCOPY VARCHAR2);

  ------------------------------------------------------------------------------------------------------------------------
  --  Nom           : main
  --  Description   : Procédure principale enchaînant l'ensemble des autres procédures
  --
  --  PARAMETRES :
  --    pv_periode_name         Sortie
  --    pv_errbuf                   Entrée/Sortie       retour de message eventuel
  --    pn_retcode                  Sortie          status du traitement en sortie
  --
  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: normal, 1: warning, 2: erreur
  -----------------------------------------------------------------------------------------------------------------------
  PROCEDURE main(pv_errbuf      OUT VARCHAR2,
                 pn_retcode     IN OUT NUMBER,
                 pn_commande_id IN NUMBER,
                 pn_batch_id    OUT NUMBER);

END dka_iporecvtotal_pkg;
/
SHOW ERROR
EXIT
