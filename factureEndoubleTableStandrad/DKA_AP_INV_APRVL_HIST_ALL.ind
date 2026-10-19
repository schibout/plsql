CREATE OR REPLACE PACKAGE BODY DKA_SAPFACT_BLOQ_EDIT_PKG
AS
--------------------------------------------------------------------------------
-- $Id: DKA_SAPFACT_BLOQ_EDIT_PKG.pkb 1769 2009-04-09 08:36:21Z CORP\viknab $
-- Capgemini
-- Projet           : Puissance4
-- Nom              : DKA_SAPFACT_BLOQ_EDIT_PKG.pkb
-- Description      : Corps du package DKA_SAPFACT_BLOQ_EDIT_PKG
-- Auteur           : Vincent Knab
-- Date de création : 31/12/2008
-- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur APPS
--------------------------------------------------------------------------------
-- Historique
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------
---2016/07/05 JJA Portage Helios R12
--------------------------------------------------------------------------------

  ----------------------------------------------------------------------------
  -- CONSTANTES ET VARIABLES PRIVEES
  ----------------------------------------------------------------------------
  cb_debug constant boolean := false;
  
  
  

PROCEDURE main(pv_errbuf   OUT VARCHAR2, 
               pn_retcode  OUT NUMBER,
               pv_code_csp IN  VARCHAR2) is

vv_out VARCHAR2(4000);
begin
  pn_retcode := 0;
  pv_errbuf  := NULL;  
  Dka_Tools_Pkg.put_log_message('Demarrage du traitement');
  


  vv_out := fnd_message.get_string('DKA', 'DKA_SAPFACT_BLOQ_EDIT_01') || ';' ||
            fnd_message.get_string('DKA', 'DKA_SAPFACT_BLOQ_EDIT_02') || ';' ||
            fnd_message.get_string('DKA', 'DKA_SAPFACT_BLOQ_EDIT_03') || ';' ||
            fnd_message.get_string('DKA', 'DKA_SAPFACT_BLOQ_EDIT_04') || ';' ||
            fnd_message.get_string('DKA', 'DKA_SAPFACT_BLOQ_EDIT_05') || ';' ||
            fnd_message.get_string('DKA', 'DKA_SAPFACT_BLOQ_EDIT_06');
   Dka_Tools_Pkg.put_outdebug_message(vv_out);        
   FOR I in (
        select DISTINCT
             division, societe, invoice_num, NOTIF_SUBJECT, NOTIF_RESPONDER, NOTIF_CLOSE_DATE
         from DKA_SAPREINITBLOCAGE_TMP     
         where CSP = pv_code_csp
         order by division, societe, invoice_num, NOTIF_CLOSE_DATE, NOTIF_RESPONDER
   ) LOOP
     vv_out := I.division||';'|| I.societe||';'|| I.invoice_num||';'|| I.NOTIF_SUBJECT||';'|| I.NOTIF_RESPONDER||';'|| to_char(I.NOTIF_CLOSE_DATE,'DD/MM/YYYY HH24:MI:SS');
     Dka_Tools_Pkg.put_outdebug_message(vv_out);
   END LOOP;            
              

    
  EXCEPTION
  WHEN OTHERS THEN  
      pv_errbuf := 'traitement : EXCEPTION ' || substr(SQLERRM, 1, 500);
      Dka_Tools_Pkg.put_log_message(pv_errbuf);
      pn_retcode := 2;
  END;  
end;
/
show errors package body DKA_SAPFACT_BLOQ_EDIT_PKG;

EXIT
