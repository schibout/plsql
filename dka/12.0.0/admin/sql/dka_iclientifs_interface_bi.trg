CREATE OR REPLACE TRIGGER apps.dka_iclientifs_interface_bi
----------------------------------------------------------------------------------------------
-- $$
-- CAPGEMINI
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_ICLIENTIFS_INTERFACE_BI.trg
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

  AFTER INSERT ON dka.dka_iclientifs_interface
  FOR EACH ROW

  WHEN (NEW.oa_status IS NULL)
BEGIN

  INSERT INTO dka.dka_iclientifs_interface_hist
    (customer_name,
     customer_number,
     intracom_number,
     customer_status,
     customer_category,
     customer_class,
     nom1,
     nom2,
     address1,
     address2,
     city,
     postal_code,
     country,
     address_status,
     profil_class,
     partner_code,
     code_client_destinataire,
     adresse_client_destinataire,
     recipient_only_flag,
     ref_address,
     gl_id_rec,
     gl_id_rev,
     insert_update_flag,
     cdg,
     soc,
     oa_status,
     oa_request_id,
     error_message,
     num_siret,
     receipt_method,
     region,
     TIMESTAMP)
  VALUES
    (:NEW.customer_name,
     :NEW.customer_number,
     :NEW.intracom_number,
     :NEW.customer_status,
     :NEW.customer_category,
     :NEW.customer_class,
     :NEW.nom1,
     :NEW.nom2,
     :NEW.address1,
     :NEW.address2,
     :NEW.city,
     :NEW.postal_code,
     :NEW.country,
     :NEW.address_status,
     :NEW.profil_class,
     :NEW.partner_code,
     :NEW.code_client_destinataire,
     :NEW.adresse_client_destinataire,
     :NEW.recipient_only_flag,
     :NEW.ref_address,
     :NEW.gl_id_rec,
     :NEW.gl_id_rev,
     :NEW.insert_update_flag,
     :NEW.cdg,
     :NEW.soc,
     :NEW.oa_status,
     :NEW.oa_request_id,
     :NEW.error_message,
     :NEW.num_siret,
     :NEW.receipt_method,
     :NEW.region,
     :NEW.timestamp);

END;
/

SHOW ERRORS TRIGGER dka_iclientifs_interface_bi
EXIT
