CREATE OR REPLACE PACKAGE DKA_IEOARCRM01_PKG AUTHID DEFINER AS
     ----------------------------------------------------------------------------------------------
     -- $ $
     --
     -- NOM               : DKA_IEOARCRM01_PKG.pks
     -- DESCRIPTION       : DKA_IEOARCRM01_PKG package spec : ENCAPSULATION DES REQUETES CRM
     ---
     --- AUTEUR           : H Descroizette
     --- DATE DE CREATION : 06/10/2016  
     --- DOC. ASSOCIEE    :
     ---
     ----------------------------------------------------------------------------------------------
     --- NOM DU PROGRAMME :
     --- PARAMETRES       :
     ---
     --- HISTORIQUE DES MODIFICATIONS
     --- Date       Qui Description
     --- ---------- --- -------------------------------------------------------------------------
     --
     --------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------------
  --  Nom           : main
  --  Description   : Procédure principale du traitement.
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
---------------------------------------------------------------------------------------------------------------
  PROCEDURE main(    
    pv_errbuf                   IN OUT VARCHAR2, 
    pn_retcode                  OUT NUMBER);
    
END DKA_IEOARCRM01_PKG; -- Spécification du package
/

SHOW ERRORS
EXIT;     