CREATE OR REPLACE PACKAGE DKA_RAPCTRLPRLVT_PKG AS
    ---------------------------------------------------------------------------------------------------------------
    -- $Id$
    --
    -- CAPGEMINI
    -- PROJET      : 
    -- NOM         : DKA_RAPCTRLPRLVT_PKG.pkb
    -- DESCRIPTION : DKA_RAPCTRLPRLVT_PKG package :
    ---
    --- AUTEUR       : Nicolas BOUSSEKEYT (CAPGEMINI)
    --- DATE DE CREATION : 26/01/2021
    --- DOC. ASSOCIEE    :
    -- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
    ---------------------------------------------------------------------------------------------------------------
    --- HISTORIQUE DES MODIFICATIONS
    --- Date       Qui Description
    --- ---------- --- --------------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------------------------------

    --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    -- CONSTANTES ET VARIABLES PUBLIQUES
    --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    -------------------------------------------------------------------------------------------------------------------
    --  Nom           : Main
    --  Description   : Procédure principal
    --
    --  PARAMETRES    :
    --          pv_invoices  varchar2
    --
    --  VALEUR RETOURNEE :
    --     	pv_errbuf	 varchar2
    --	    pv_status	 varchar2
    -------------------------------------------------------------------------------------------------------------------
    PROCEDURE main (
        pv_errbuf               IN OUT   VARCHAR2,
        pn_retcode                 OUT   NUMBER
    );
    
  -------------------------------------------------------------------------------------------------------------------
  --  Nom           : send_mail
  --  Description   : Procédure d'envoi de mail
  --
  --  PARAMETRES    :
  --
  --  VALEUR RETOURNEE :
  --      pv_errbuf  varchar2
  --      pv_status  varchar2
  -------------------------------------------------------------------------------------------------------------------
  PROCEDURE send_mail(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER);
    
END DKA_RAPCTRLPRLVT_PKG;
/
SHOW ERRORS;

EXIT
