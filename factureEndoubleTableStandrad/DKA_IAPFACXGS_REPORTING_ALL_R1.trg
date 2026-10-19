create or replace package DKA_FUSION_AR_PKG is
  ----------------------------------------------------------------------------------------------
  -- 
  --
  -- NOM               : DKA_FUSION_AR_PKG.pks
  -- DESCRIPTION       : Fusion des sociétés dans AP
  ---
  --- AUTEUR           : O.CLEMENT 
  --- DATE DE CREATION : 08/2019
  --- DOC. ASSOCIEE    : Spécifications fonctionnelles (0SPF 20050244)
  ---
  ----------------------------------------------------------------------------------------------
  --- NOM DU PROGRAMME :
  --- PARAMETRES       :
  ---
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- ---------- --- -------------------------------------------------------------------------
  --------------------------------------------------------------------------------------------


  -- Public function and procedure declarations
 PROCEDURE MAIN (PV_ERRBUF OUT VARCHAR2,PN_CODRET OUT NUMBER ,PV_SIMULATION IN VARCHAR2, PV_DEBUG IN VARCHAR2 DEFAULT 'N') ;
 PROCEDURE FUSION (PV_ERRBUF OUT VARCHAR2,PN_CODRET OUT NUMBER, PV_SIMULATION IN VARCHAR2, PV_DEBUG IN VARCHAR2 DEFAULT 'N') ;
 PROCEDURE ANNULATION_REGLEMENTS (PV_ERRBUF OUT VARCHAR2,PN_CODRET OUT NUMBER, PV_SIMULATION IN VARCHAR2,PV_DEBUG IN VARCHAR2 DEFAULT 'N' ) ;
 PROCEDURE POST_FUSION_AR (PV_ERRBUF OUT VARCHAR2,PN_CODRET OUT NUMBER, PV_SIMULATION IN VARCHAR2,PV_DEBUG IN VARCHAR2 DEFAULT 'N' ) ;
 PROCEDURE LISTE_MOUVEMENTS (PV_ERRBUF OUT VARCHAR2,PN_CODRET OUT NUMBER,  PV_DEBUG IN VARCHAR2 DEFAULT 'N') ;
 PROCEDURE LETTRAGE_ZERO (PV_ERRBUF OUT VARCHAR2,PN_CODRET OUT NUMBER, PV_SIMULATION IN VARCHAR2, PV_DEBUG IN VARCHAR2 DEFAULT 'N') ; 
 PROCEDURE CTR(PV_ERRBUF OUT VARCHAR2,PN_CODRET OUT NUMBER, PV_DEBUG IN VARCHAR2 DEFAULT 'N');
end DKA_FUSION_AR_PKG;
/
SHOW ERRORS
exit