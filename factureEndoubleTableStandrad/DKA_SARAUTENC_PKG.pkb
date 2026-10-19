CREATE OR REPLACE PACKAGE DKA_SPOODCAP_PKG AS
  ---------------------------------------------------------------------------------------------- 
  -- $$
  -- CAP GEMINI ERNST AND YOUNG
  -- PROJET            : DALKIA Oracle Applications
  -- NOM               : DKA_SPOODCAP_PKG.pks
  -- DESCRIPTION       : DKA_SPOODCAP_PKG package spec : package pour ******************  
  ---
  --- AUTEUR           : Oussama BENHAYOUN
  --- DATE DE CREATION : 23/10/2018
  --- DOC. ASSOCIEE    : 
  -- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
  ----------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- ---------- --- -------------------------------------------------------------------------
  ----------------------------------------------------------------------------------------------


  ---------------------------------------------------------------------------------------------------
  --  Nom           : main
  --  Description   : Procédure principale du spécifique DKA_SPOODCAP
  --        
  --  
  --  PARAMETRES    :
  -- pv_errbuf                 Entrée/Sortie      message d'erreur
  -- pn_retcode                Sortie             code de retour: 'o=normal', '1=warning', '2=erreur'
  --  VALEUR RETOURNEE :
  --     N/A
  ----------------------------------------------------------------------------------------------------------
  PROCEDURE main(pv_errbuf  IN OUT VARCHAR2,
                 pn_retcode OUT NUMBER,
				 pv_period_name IN VARCHAR2);

END DKA_SPOODCAP_PKG;
/
SHOW ERROR
EXIT;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
