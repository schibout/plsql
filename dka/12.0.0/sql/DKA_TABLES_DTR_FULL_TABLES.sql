---------------------------------------------------------------------------------------------------------------
-- Capgemini
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_TABLES_DTR.sql
--
-- AUTEUR           : Anas RAOUF (Capgemini)
-- DATE DE CREATION : 07/04/2023
-- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user dka_consultation
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--  18/09/2024 : FULL deux tables
--  06/11/2024 : dump d'un jour sans les full des tables
---------------------------------------------------------------------------------------------------------------

SET VERIFY OFF
SET SERVEROUTPUT ON SIZE 1000000


BEGIN
    

BEGIN


execute immediate 'drop table dka_consultation.DKA_FND_USER';
execute immediate 'drop table dka_consultation.DKA_PER_ALL_PEOPLE_F';
execute immediate 'drop table dka_consultation.DKA_GL_CODE_COMBINATIONS';
execute immediate 'drop table dka_consultation.DKA_GL_PERIOD_STATUSES';
execute immediate 'drop table dka_consultation.DKA_PA_PROJECTS_ALL';
execute immediate 'drop table dka_consultation.DKA_FND_FLEX_VALUE_SETS';
execute immediate 'drop table dka_consultation.DKA_FND_FLEX_VALUES';
execute immediate 'drop table dka_consultation.DKA_HR_ALL_ORGANIZATION_UNITS';
execute immediate 'drop table dka_consultation.DKA_PA_TASKS';
execute immediate 'drop table dka_consultation.DKA_XLE_ENTITY_PROFILES';
execute immediate 'drop table dka_consultation.DKA_GL_LEDGERS';
execute immediate 'drop table dka_consultation.DKA_FND_FLEX_VALUES_TL';
execute immediate 'drop table dka_consultation.DKA_GL_LEDGER_CONFIGURATIONS';
execute immediate 'drop table dka_consultation.DKA_GL_LEDGER_NORM_SEG_VALS';
execute immediate 'drop table dka_consultation.DKA_HZ_GEOGRAPHIES';
execute immediate 'drop table dka_consultation.DKA_PA_PROJECT_STATUSES';
execute immediate 'drop table dka_consultation.DKA_PER_ALL_ASSIGNMENTS_F';
execute immediate 'drop table dka_consultation.DKA_FND_APPLICATION';
execute immediate 'drop table dka_consultation.DKA_AP_SUPPLIERS';
execute immediate 'drop table dka_consultation.DKA_AP_SUPPLIER_SITES_ALL';
execute immediate 'drop table dka_consultation.DKA_GL_BALANCES';
execute immediate 'drop table dka_consultation.DKA_GL_JE_LINES';
execute immediate 'drop table dka_consultation.DKA_GL_JE_HEADERS';
execute immediate 'drop table dka_consultation.DKA_GL_JE_BATCHES';
execute immediate 'drop table dka_consultation.DKA_GL_JE_LINES_RECON';
execute immediate 'drop table dka_consultation.DKA_AP_INVOICES_ALL';
execute immediate 'drop table dka_consultation.DKA_AP_HOLDS_ALL';
execute immediate 'drop table dka_consultation.DKA_AP_TERMS_TL';
execute immediate 'drop table dka_consultation.DKA_AP_INVOICE_PAYMENTS_ALL';
execute immediate 'drop table dka_consultation.DKA_FND_ATTACHED_DOCUMENTS';
execute immediate 'drop table dka_consultation.DKA_IBY_EXTERNAL_PAYEES_ALL';
execute immediate 'drop table dka_consultation.DKA_IBY_EXT_PARTY_PMT_MTHDS';
execute immediate 'drop table dka_consultation.DKA_HZ_PARTIES';
execute immediate 'drop table dka_consultation.DKA_FND_ID_FLEX_STRUCTURES_TL';
execute immediate 'drop table dka_consultation.DKA_PA_IND_RATE_SCHED_ALL_BG';
execute immediate 'drop table dka_consultation.DKA_AP_INV_DISTRIBUTIONS_ALL';
execute immediate 'drop table dka_consultation.DKA_PA_PROJECT_ASSET_ASSIGN';
execute immediate 'drop table dka_consultation.DKA_PA_PROJECT_ASSETS_ALL';
execute immediate 'drop table dka_consultation.DKA_GL_RECURRING_BATCHES';
execute immediate 'drop table dka_consultation.DKA_GL_RECURRING_HEADERS';
execute immediate 'drop table dka_consultation.DKA_GL_RECURRING_LINES';
execute immediate 'drop table dka_consultation.DKA_GL_REC_LINE_CALC_RULES';
execute immediate 'drop table dka_consultation.DKA_AP_CHECKS_ALL';
execute immediate 'drop table dka_consultation.DKA_AP_PAYMENT_SCHEDULES_ALL';
execute immediate 'drop table dka_consultation.DKA_MTL_CATEGORIES_B';
execute immediate 'drop table dka_consultation.DKA_MTL_CATEGORIES_TL';
execute immediate 'drop table dka_consultation.DKA_PA_COST_DIST_LINES_ALL';
execute immediate 'drop table dka_consultation.DKA_PA_DRAFT_REVENUES_ALL';
execute immediate 'drop table dka_consultation.DKA_PA_EVENTS';
execute immediate 'drop table dka_consultation.DKA_PA_EXPENDITURE_ITEMS_ALL';
execute immediate 'drop table dka_consultation.DKA_PA_EXPENDITURE_TYPES';
execute immediate 'drop table dka_consultation.DKA_PA_PERIODS_ALL';
execute immediate 'drop table dka_consultation.DKA_PA_PROJECT_ASSET_LINES_ALL';
execute immediate 'drop table dka_consultation.DKA_PO_ACTION_HISTORY';
execute immediate 'drop table dka_consultation.DKA_PO_DISTRIBUTIONS_ALL';
execute immediate 'drop table dka_consultation.DKA_PO_HEADERS_ALL';
execute immediate 'drop table dka_consultation.DKA_PO_LINES_ALL';
execute immediate 'drop table dka_consultation.DKA_PO_REQ_DISTRIBUTIONS_ALL';
execute immediate 'drop table dka_consultation.DKA_PO_REQUISITION_HEADERS_ALL';
execute immediate 'drop table dka_consultation.DKA_PO_REQUISITION_LINES_ALL';
execute immediate 'drop table dka_consultation.DKA_RA_CUSTOMER_TRX_ALL';
execute immediate 'drop table dka_consultation.DKA_HR_LOCATIONS_ALL';
execute immediate 'drop table dka_consultation.DKA_PA_PROJECT_ASSET_LINE_DET';
execute immediate 'drop table dka_consultation.DKA_PA_EVENT_TYPES';
execute immediate 'drop table dka_consultation.DKA_CUST_TRX_LINE_GL_DIST_ALL';
execute immediate 'drop table dka_consultation.DKA_RA_CUSTOMER_TRX_LINES_ALL';
execute immediate 'drop table dka_consultation.DKA_AR_ADJUSTMENTS_ALL';
execute immediate 'drop table dka_consultation.DKA_PA_CUST_EVENT_RDL_ALL';
execute immediate 'drop table dka_consultation.DKA_PO_POSITION_CONTROLS_ALL';
execute immediate 'drop table dka_consultation.DKA_PO_CONTROL_GROUPS_ALL';
execute immediate 'drop table dka_consultation.DKA_PO_CONTROL_RULES';
execute immediate 'drop table dka_consultation.DKA_PER_SECURITY_ORGANIZATIONS';
execute immediate 'drop table dka_consultation.DKA_PER_SECURITY_PROFILES';
execute immediate 'drop table dka_consultation.DKA_WF_NOTIFICATIONS';
execute immediate 'drop table dka_consultation.DKA_STRANSCO_LINES_1';
execute immediate 'drop table dka_consultation.DKA_STRANSCO_HEADERS_1';
execute immediate 'drop table dka_consultation.DKA_AP_INVOICE_LINES_ALL';
execute immediate 'drop table dka_consultation.DKA_HZ_CUST_ACCOUNTS';
execute immediate 'drop table dka_consultation.DKA_HZ_CUST_ACCT_SITES_ALL';
execute immediate 'drop table dka_consultation.DKA_HZ_PARTY_SITES';
execute immediate 'drop table dka_consultation.DKA_HZ_CUST_SITE_USES_ALL';
execute immediate 'drop table dka_consultation.DKA_HZ_LOCATIONS';
execute immediate 'drop table dka_consultation.DKA_ZX_LINES';
execute immediate 'drop table dka_consultation.DKA_AR_PAYMENT_SCHEDULES_ALL';
execute immediate 'drop table dka_consultation.DKA_AR_CASH_RECEIPTS_ALL';
execute immediate 'drop table dka_consultation.DKA_AR_REC_APPLICATIONS_ALL';
execute immediate 'drop table dka_consultation.DKA_RA_TERMS_TL';
execute immediate 'drop table dka_consultation.DKA_AR_RECEIPT_METHODS';
execute immediate 'drop table dka_consultation.DKA_RA_CUST_TRX_TYPES_ALL';
execute immediate 'drop table dka_consultation.DKA_RA_BATCH_SOURCES_ALL';
execute immediate 'drop table dka_consultation.DKA_FND_LOOKUP_VALUES';
execute immediate 'drop table dka_consultation.DKA_IBY_EXT_BANK_ACCOUNTS';
execute immediate 'drop table dka_consultation.DKA_CONTRAT_SSTR_1';
execute immediate 'drop table dka_consultation.DKA_CONTRAT_SSTR_IMPUTATION_1';
execute immediate 'drop table dka_consultation.DKA_PO_LINE_LOCATIONS_ALL';
execute immediate 'drop table dka_consultation.DKA_RCV_TRANSACTIONS';
execute immediate 'drop table dka_consultation.DKA_RCV_SHIPMENT_HEADERS';
execute immediate 'drop table dka_consultation.DKA_PO_LINES_ARCHIVE_ALL';
execute immediate 'drop table dka_consultation.DKA_PO_HEADERS_ARCHIVE_ALL';
execute immediate 'drop table dka_consultation.DKA_FND_REQUEST_GROUPS';
execute immediate 'drop table dka_consultation.DKA_FND_APPLICATION_TL';
execute immediate 'drop table dka_consultation.DKA_PER_JOBS_TL';
execute immediate 'drop table dka_consultation.DKA_PER_ASSIGN_STATUS_TYPES';
execute immediate 'drop table dka_consultation.DKA_PER_JOBS';
execute immediate 'drop table dka_consultation.DKA_PO_CONTROL_FUNCTIONS';
execute immediate 'drop table dka_consultation.DKA_FND_RESPONSIBILITY';
execute immediate 'drop table dka_consultation.DKA_FND_RESPONSIBILITY_TL';
execute immediate 'drop table dka_consultation.DKA_FND_PROFILE_OPTIONS';
execute immediate 'drop table dka_consultation.DKA_AK_WEB_USER_SEC_ATTR_VAL';
execute immediate 'drop table dka_consultation.DKA_AK_RESP_SECURITY_ATTR';
execute immediate 'drop table dka_consultation.DKA_PER_GRADES_TL';
execute immediate 'drop table dka_consultation.DKA_FND_SECURITY_GROUPS';
execute immediate 'drop table dka_consultation.DKA_WF_USER_ROLE_ASSIGNMENTS';
execute immediate 'drop table dka_consultation.DKA_WF_LOCAL_USER_ROLES';
execute immediate 'drop table dka_consultation.DKA_PER_ORGANIZATION_STRUCT';
execute immediate 'drop table dka_consultation.DKA_PER_ORG_STRUCTURE_VERSIONS';
execute immediate 'drop table dka_consultation.DKA_PER_ORG_STRUCTURE_ELEMENTS';
execute immediate 'drop table dka_consultation.DKA_CE_BANK_ACCOUNTS';
execute immediate 'drop table dka_consultation.DKA_IBY_PAYMENTS_ALL';
execute immediate 'drop table dka_consultation.DKA_GL_JE_CATEGORIES_TL';
execute immediate 'drop table dka_consultation.DKA_GL_JE_SOURCES_TL';
execute immediate 'drop table dka_consultation.DKA_FND_PROFILE_OPTIONS_TL';
execute immediate 'drop table dka_consultation.DKA_SAP_STATUT_FACTURE_1';
execute immediate 'drop table dka_consultation.DKA_FA_CATEGORIES_B';
execute immediate 'drop table dka_consultation.DKA_FA_CATEGORIES_TL';
execute immediate 'drop table dka_consultation.DKA_FA_CATEGORY_BOOKS';
execute immediate 'drop table dka_consultation.DKA_FA_ADJUSTMENTS';
execute immediate 'drop table dka_consultation.DKA_FA_CALENDAR_PERIODS';
execute immediate 'drop table dka_consultation.DKA_FA_DEPRN_DETAIL';
execute immediate 'drop table dka_consultation.DKA_FA_BOOK_CONTROLS';
execute immediate 'drop table dka_consultation.DKA_FA_ADDITIONS_B';
execute immediate 'drop table dka_consultation.DKA_FA_ADDITIONS_TL';
execute immediate 'drop table dka_consultation.DKA_FA_ASSET_INVOICES';
execute immediate 'drop table dka_consultation.DKA_FA_BOOKS';
execute immediate 'drop table dka_consultation.DKA_FA_DEPRN_PERIODS';
execute immediate 'drop table dka_consultation.DKA_FA_DISTRIBUTION_HISTORY';
execute immediate 'drop table dka_consultation.DKA_FA_LOCATIONS';
execute immediate 'drop table dka_consultation.DKA_FA_LOOKUPS_TL';
execute immediate 'drop table dka_consultation.DKA_FA_RETIREMENTS';
execute immediate 'drop table dka_consultation.DKA_FA_TRANSACTION_HEADERS';
execute immediate 'drop table dka_consultation.DKA_FA_LOOKUPS_B';
execute immediate 'drop table dka_consultation.DKA_FA_DEPRN_SUMMARY';
execute immediate 'drop table dka_consultation.DKA_FA_MC_DEPRN_SUMMARY';
execute immediate 'drop table dka_consultation.DKA_FA_MC_BOOKS';
execute immediate 'drop table dka_consultation.DKA_FA_MC_BOOK_CONTROLS';
execute immediate 'drop table dka_consultation.DKA_FA_DISTRIBUTION_ACCOUNTS';
execute immediate 'drop table dka_consultation.DKA_HZ_CUSTOMER_PROFILES';
execute immediate 'drop table dka_consultation.DKA_AR_COLLECTORS';
execute immediate 'drop table dka_consultation.DKA_FND_PROFILE_OPTION_VALUES';


EXCEPTION
WHEN OTHERS THEN
	DBMS_OUTPUT.put_line ('Erreur lors de la suppression des tables : ' || SQLERRM);

END;
	
DBMS_OUTPUT.put_line ('la suppression des tables terminee');	
	

BEGIN

DBMS_OUTPUT.put_line ('Debut creation des tables');


--execute immediate 'create table dka_consultation.DKA_PO_DISTRIBUTIONS_ALL AS SELECT * FROM PO.PO_DISTRIBUTIONS_ALL WHERE LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_PO_DISTRIBUTIONS_ALL AS SELECT * FROM PO.PO_DISTRIBUTIONS_ALL';
--execute immediate 'create table dka_consultation.DKA_PO_LINE_LOCATIONS_ALL AS SELECT * FROM PO.PO_LINE_LOCATIONS_ALL WHERE LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_PO_LINE_LOCATIONS_ALL AS SELECT * FROM PO.PO_LINE_LOCATIONS_ALL';

EXCEPTION
WHEN OTHERS THEN

DBMS_OUTPUT.put_line ('Erreur lors de la creation des tables : ' || SQLERRM);

END;

DBMS_OUTPUT.put_line ('Creation des tables terminee');

DBMS_OUTPUT.put_line ('Creation des valeurs par defaut des tables');

BEGIN

execute immediate 'alter table DKA_CONSULTATION.DKA_PO_DISTRIBUTIONS_ALL modify (ORG_ID default NULL)';
execute immediate 'alter table DKA_CONSULTATION.DKA_PO_LINE_LOCATIONS_ALL modify (ORG_ID default NULL)';

EXCEPTION
WHEN OTHERS THEN

DBMS_OUTPUT.put_line ('Erreur lors de la creation des valeurs par defaut des tables : ' || SQLERRM);

END;

DBMS_OUTPUT.put_line ('Creation des valeurs par defaut des tables terminee');

EXCEPTION
    WHEN OTHERS THEN
         DBMS_OUTPUT.PUT_LINE ( ' ==> ERREUR : ' || SQLERRM);
END;
/
EXIT