CREATE OR REPLACE TRIGGER apps.dka_iclientifs_collectors_bi
----------------------------------------------------------------------------------------------
-- $$
-- CAPGEMINI
-- PROJET            : DALKIA Oracle Applications
-- NOM               : dka_iclientifs_collectors_bi.trg
-- DESCRIPTION       : Trigger sur la table DKA_ICLIENTIFS_INTERFACE
---
--- AUTEUR           : Nicolas BOUSSEKEYT (CG)
--- DATE DE CREATION : 12/07/2018
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- ---------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

  AFTER INSERT ON dka.dka_iclientifs_collectors
  FOR EACH ROW

  WHEN (NEW.oa_status IS NULL)
BEGIN

  INSERT INTO dka.dka_iclientifs_collectors_hist
    (customer_number,
     cdg,
     collector,
     oa_status,
     oa_request_id,
     error_message,
     TIMESTAMP)
  VALUES
    (:NEW.customer_number,
     :NEW.cdg,
     :NEW.collector,
     :NEW.oa_status,
     :NEW.oa_request_id,
     :NEW.error_message,
     :NEW.TIMESTAMP);

END;
/


SHOW ERRORS TRIGGER dka_iclientifs_collectors_bi
EXIT