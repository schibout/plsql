CREATE OR REPLACE PACKAGE DKA_FUSPORECVTOTAL_PKG IS
  ---PROD------------------------------------------------------------------------------------------------------------
  -- CAPGEMINI
  -- PROJET             : DALKIA Oracle Applications
  -- NOM                : DKA_SPORECEP_FRAISPORT.pkb
  -- DESCRIPTION        : DKA_SPORECEP_FRAISPORT package  :
  ---
  --- AUTEUR            : Samir EL OUAHABI
  --- DATE DE CREATION  : 13/09/2019
  --- DOC. ASSOCIEE     :
  -- COMMENTAIRE        : A exécuter sous SQLPLUS avec le user APPS
  ---------------------------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- 
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
  
 
  ------------------------------------------------------------------------------------------------------------------------
  --  Nom           : main
  --  Description   : Procédure principale enchaînant l'ensemble des autres procédures
  --
  --  PARAMETRES :
   --    pv_errbuf                   Entrée/Sortie       retour de message eventuel
  --    pn_retcode                  Sortie          status du traitement en sortie
  --
  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: normal, 1: warning, 2: erreur
  -----------------------------------------------------------------------------------------------------------------------
  PROCEDURE main(pv_errbuf      OUT VARCHAR2,
                 pn_retcode     IN OUT NUMBER
				 );

END DKA_FUSPORECVTOTAL_PKG;
/
SHOW ERROR
EXIT
