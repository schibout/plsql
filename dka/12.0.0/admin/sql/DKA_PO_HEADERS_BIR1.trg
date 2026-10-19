CREATE OR REPLACE TRIGGER DKA_PO_HEADERS_BIR1
  ----------------------------------------------------------------------------------------------
  -- $$
  -- CAP GEMINI
  -- PROJET            : DALKIA Oracle Applications
  -- NOM               : DKA_PO_HEADERS_BIR1.trg
  -- DESCRIPTION       : Trigger sur la table PO_HEADERS_ALL
  ---
  --- AUTEUR           : Nicolas BOUSSEKEYT (Capgemini)
  --- DATE DE CREATION : 09/02/2006
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
  ----------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- ---------- --- -------------------------------------------------------------------------
  --- 15/01/2018 NBO Création du trigger permettant la mise à jour des sites en mode global
  ---------------------------------------------------------------------------------------------

   BEFORE
   INSERT
   ON po.po_headers_all
   FOR EACH ROW

   when ( NVL(NEW.global_agreement_flag,'N') = 'Y' )
DECLARE
BEGIN
 :NEW.ENABLE_ALL_SITES := 'Y';    
END;
/
EXIT;
