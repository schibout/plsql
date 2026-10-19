create or replace PACKAGE dka_sapfrs_history_pkg
AS

----------------------------------------------------------------------------------------------
-- $$
-- CAPGEMINI
-- PROJET            : DALKIA Oracle Applications
-- NOM               : dka_sapfrs_history_pkg.pks
-- DESCRIPTION       : dka_sapfrs_history_pkg package spec :
---
--- AUTEUR           : Saloua HAHIOUI
--- DATE DE CREATION : 23/12/2021
--- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------



--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    TYPE dka_typ_fields IS TABLE OF VARCHAR2(500) INDEX BY BINARY_INTEGER;
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

------------------------------------------------------------------------------------------------------------------------

    PROCEDURE get_user_name (pn_user_id IN NUMBER,
						     pn_user_name OUT VARCHAR2);
	PROCEDURE get_term_name (pn_term_id IN NUMBER,
    						 pn_term_name OUT VARCHAR2);
	PROCEDURE get_payement_method (pn_vendor_site_id  IN   NUMBER,
                               pn_ext_party_pmt_mthd_id  IN   NUMBER,
                               pn_primary_flag    IN   VARCHAR2,
							   pn_payment_method_code    OUT  VARCHAR2);
	PROCEDURE get_vendor_site_id (pn_ext_pmt_party_id  IN   NUMBER,
							      pn_vendor_site_id OUT  NUMBER);
	--PROCEDURE get_bank_vendor_site_id (pn_ext_bank_account_id  IN   NUMBER, 
	--						  pn_vendor_site_id    OUT  NUMBER) ;

	PROCEDURE get_vendor_id (pn_supplier_site_id  IN   NUMBER,
						    pn_vendor_id      OUT  NUMBER);

	PROCEDURE get_vendor_name (pn_supplier_site_id  IN   NUMBER,
							pn_vendor_name    out varchar2,
							pn_vendor_site_code out varchar2);

	PROCEDURE get_vendor_party (pn_party_site_id  IN   NUMBER,
						    pn_vendor_id      OUT  NUMBER,
							pn_vendor_site_id OUT  NUMBER);

	PROCEDURE insert_supplier_mode_p (pv_dml_type       IN VARCHAR2,
                                     pn_vendor_id              IN NUMBER,
                                     pn_vendor_site_id         IN NUMBER,
                                     pd_last_update_date       IN DATE,
                                     pn_last_updated_by        IN NUMBER,
                                     pt_field_names            IN dka_typ_fields,
                                     pt_field_old_values       IN dka_typ_fields,
                                     pt_field_new_values       IN dka_typ_fields
                                   );
    PROCEDURE insert_supplier_history (pv_dml_type               IN VARCHAR2,
                                     pn_vendor_id              IN NUMBER,
                                     pd_last_update_date       IN DATE,
                                     pn_last_updated_by        IN NUMBER,
                                     pt_field_names            IN dka_typ_fields,
                                     pt_field_old_values       IN dka_typ_fields,
                                     pt_field_new_values       IN dka_typ_fields
                                    );

    PROCEDURE insert_supplier_sites_history (pv_dml_type      IN VARCHAR2,
                                    pn_vendor_id              IN NUMBER,
								    pn_vendor_site_id         IN NUMBER,
                                    pd_last_update_date       IN DATE,
                                    pn_last_updated_by        IN NUMBER,
                                    pt_field_names            IN dka_typ_fields,
                                    pt_field_old_values       IN dka_typ_fields,
                                    pt_field_new_values       IN dka_typ_fields
                               );
    PROCEDURE INSERT_CUSTOMER_HISTORY (pv_dml_type             IN VARCHAR2,
                                     pn_ext_bank_account_id    IN NUMBER,
                                     pd_last_update_date       IN DATE,
                                     pn_last_updated_by        IN NUMBER,
                                     pt_field_names            IN dka_typ_fields,
                                     pt_field_old_values       IN dka_typ_fields,
                                     pt_field_new_values       IN dka_typ_fields
                                    );								

END dka_sapfrs_history_pkg;
/
SHOW ERRORS
EXIT