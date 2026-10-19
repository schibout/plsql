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


execute immediate 'create table dka_consultation.DKA_FND_USER AS SELECT * FROM APPLSYS.FND_USER';
execute immediate 'create table dka_consultation.DKA_PER_ALL_PEOPLE_F AS SELECT * FROM HR.PER_ALL_PEOPLE_F';
execute immediate 'create table dka_consultation.DKA_GL_CODE_COMBINATIONS AS SELECT * FROM GL.GL_CODE_COMBINATIONS WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_GL_PERIOD_STATUSES AS SELECT * FROM GL.GL_PERIOD_STATUSES';
execute immediate 'create table dka_consultation.DKA_PA_PROJECTS_ALL AS SELECT * FROM PA.PA_PROJECTS_ALL WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1 AND TEMPLATE_FLAG=''N''';
execute immediate 'create table dka_consultation.DKA_FND_FLEX_VALUE_SETS AS SELECT * FROM APPLSYS.FND_FLEX_VALUE_SETS';
execute immediate 'create table dka_consultation.DKA_FND_FLEX_VALUES AS SELECT * FROM APPLSYS.FND_FLEX_VALUES';
execute immediate 'create table dka_consultation.DKA_HR_ALL_ORGANIZATION_UNITS AS SELECT * FROM HR.HR_ALL_ORGANIZATION_UNITS';
execute immediate 'create table dka_consultation.DKA_PA_TASKS AS SELECT * FROM PA.PA_TASKS WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_XLE_ENTITY_PROFILES AS SELECT * FROM XLE.XLE_ENTITY_PROFILES';
execute immediate 'create table dka_consultation.DKA_GL_LEDGERS AS SELECT * FROM GL.GL_LEDGERS';
execute immediate 'create table dka_consultation.DKA_FND_FLEX_VALUES_TL AS SELECT * FROM APPLSYS.FND_FLEX_VALUES_TL WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_GL_LEDGER_CONFIGURATIONS AS SELECT * FROM GL.GL_LEDGER_CONFIGURATIONS';
execute immediate 'create table dka_consultation.DKA_GL_LEDGER_NORM_SEG_VALS AS SELECT * FROM GL.GL_LEDGER_NORM_SEG_VALS WHERE SEGMENT_TYPE_CODE=''B'' AND NVL(STATUS_CODE, ''I'') <> ''D''';
execute immediate 'create table dka_consultation.DKA_HZ_GEOGRAPHIES AS SELECT * FROM AR.HZ_GEOGRAPHIES';
execute immediate 'create table dka_consultation.DKA_PA_PROJECT_STATUSES AS SELECT * FROM PA.PA_PROJECT_STATUSES';
execute immediate 'create table dka_consultation.DKA_PER_ALL_ASSIGNMENTS_F AS SELECT * FROM HR.PER_ALL_ASSIGNMENTS_F';
execute immediate 'create table dka_consultation.DKA_FND_APPLICATION AS SELECT * FROM APPLSYS.FND_APPLICATION';
execute immediate 'create table dka_consultation.DKA_AP_SUPPLIERS AS SELECT * FROM AP.AP_SUPPLIERS';
execute immediate 'create table dka_consultation.DKA_AP_SUPPLIER_SITES_ALL AS SELECT * FROM AP.AP_SUPPLIER_SITES_ALL WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_GL_BALANCES AS SELECT * FROM GL.GL_BALANCES WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_GL_JE_LINES AS SELECT * FROM GL.GL_JE_LINES WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_GL_JE_HEADERS AS SELECT * FROM GL.GL_JE_HEADERS WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_GL_JE_BATCHES AS SELECT * FROM GL.GL_JE_BATCHES WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1 ';
execute immediate 'create table dka_consultation.DKA_GL_JE_LINES_RECON AS SELECT * FROM GL.GL_JE_LINES_RECON WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_AP_INVOICES_ALL AS SELECT * FROM AP.AP_INVOICES_ALL WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_AP_HOLDS_ALL AS SELECT * FROM AP.AP_HOLDS_ALL WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_AP_TERMS_TL AS SELECT * FROM AP.AP_TERMS_TL';
execute immediate 'create table dka_consultation.DKA_AP_INVOICE_PAYMENTS_ALL AS SELECT * FROM AP.AP_INVOICE_PAYMENTS_ALL WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_FND_ATTACHED_DOCUMENTS AS SELECT * FROM APPLSYS.FND_ATTACHED_DOCUMENTS WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_IBY_EXTERNAL_PAYEES_ALL AS SELECT * FROM IBY.IBY_EXTERNAL_PAYEES_ALL WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1 AND SUPPLIER_SITE_ID IS NOT NULL';
execute immediate 'create table dka_consultation.DKA_IBY_EXT_PARTY_PMT_MTHDS AS SELECT * FROM IBY.IBY_EXT_PARTY_PMT_MTHDS WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_HZ_PARTIES AS SELECT * FROM AR.HZ_PARTIES WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_FND_ID_FLEX_STRUCTURES_TL AS SELECT * FROM APPLSYS.FND_ID_FLEX_STRUCTURES_TL';
execute immediate 'create table dka_consultation.DKA_PA_IND_RATE_SCHED_ALL_BG AS SELECT * FROM PA.PA_IND_RATE_SCHEDULES_ALL_BG';
execute immediate 'create table dka_consultation.DKA_AP_INV_DISTRIBUTIONS_ALL AS SELECT * FROM AP.AP_INVOICE_DISTRIBUTIONS_ALL WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_PA_PROJECT_ASSET_ASSIGN AS SELECT * FROM PA.PA_PROJECT_ASSET_ASSIGNMENTS';
execute immediate 'create table dka_consultation.DKA_PA_PROJECT_ASSETS_ALL AS SELECT * FROM PA.PA_PROJECT_ASSETS_ALL';
execute immediate 'create table dka_consultation.DKA_GL_RECURRING_BATCHES AS SELECT * FROM GL.GL_RECURRING_BATCHES';
execute immediate 'create table dka_consultation.DKA_GL_RECURRING_HEADERS AS SELECT * FROM GL.GL_RECURRING_HEADERS';
execute immediate 'create table dka_consultation.DKA_GL_RECURRING_LINES AS SELECT * FROM GL.GL_RECURRING_LINES';
execute immediate 'create table dka_consultation.DKA_GL_REC_LINE_CALC_RULES AS SELECT * FROM GL.GL_RECURRING_LINE_CALC_RULES';
execute immediate 'create table dka_consultation.DKA_AP_CHECKS_ALL AS SELECT * FROM AP.AP_CHECKS_ALL WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_AP_PAYMENT_SCHEDULES_ALL AS SELECT * FROM AP.AP_PAYMENT_SCHEDULES_ALL WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_MTL_CATEGORIES_B AS SELECT * FROM INV.MTL_CATEGORIES_B';
execute immediate 'create table dka_consultation.DKA_MTL_CATEGORIES_TL AS SELECT * FROM INV.MTL_CATEGORIES_TL';
execute immediate 'create table dka_consultation.DKA_PA_COST_DIST_LINES_ALL AS SELECT * FROM PA.PA_COST_DISTRIBUTION_LINES_ALL WHERE PROGRAM_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'')';
execute immediate 'create table dka_consultation.DKA_PA_DRAFT_REVENUES_ALL AS SELECT * FROM PA.PA_DRAFT_REVENUES_ALL WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_PA_EVENTS AS SELECT * FROM PA.PA_EVENTS WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_PA_EXPENDITURE_ITEMS_ALL AS SELECT * FROM PA.PA_EXPENDITURE_ITEMS_ALL WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_PA_EXPENDITURE_TYPES AS SELECT * FROM PA.PA_EXPENDITURE_TYPES';
execute immediate 'create table dka_consultation.DKA_PA_PERIODS_ALL AS SELECT * FROM PA.PA_PERIODS_ALL';
execute immediate 'create table dka_consultation.DKA_PA_PROJECT_ASSET_LINES_ALL AS SELECT * FROM PA.PA_PROJECT_ASSET_LINES_ALL WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_PO_ACTION_HISTORY AS SELECT * FROM PO.PO_ACTION_HISTORY WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
-- execute immediate 'create table dka_consultation.DKA_PO_DISTRIBUTIONS_ALL AS SELECT * FROM PO.PO_DISTRIBUTIONS_ALL WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_PO_DISTRIBUTIONS_ALL AS SELECT * FROM PO.PO_DISTRIBUTIONS_ALL';
execute immediate 'create table dka_consultation.DKA_PO_HEADERS_ALL AS SELECT * FROM PO.PO_HEADERS_ALL WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_PO_LINES_ALL AS SELECT * FROM PO.PO_LINES_ALL WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_PO_REQ_DISTRIBUTIONS_ALL AS SELECT * FROM PO.PO_REQ_DISTRIBUTIONS_ALL WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_PO_REQUISITION_HEADERS_ALL AS SELECT * FROM PO.PO_REQUISITION_HEADERS_ALL WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_PO_REQUISITION_LINES_ALL AS SELECT * FROM PO.PO_REQUISITION_LINES_ALL WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_RA_CUSTOMER_TRX_ALL AS SELECT * FROM AR.RA_CUSTOMER_TRX_ALL WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_HR_LOCATIONS_ALL AS SELECT * FROM HR.HR_LOCATIONS_ALL';
execute immediate 'create table dka_consultation.DKA_PA_PROJECT_ASSET_LINE_DET AS SELECT * FROM PA.PA_PROJECT_ASSET_LINE_DETAILS WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_PA_EVENT_TYPES AS SELECT * FROM PA.PA_EVENT_TYPES';
execute immediate 'create table dka_consultation.DKA_CUST_TRX_LINE_GL_DIST_ALL AS SELECT * FROM AR.RA_CUST_TRX_LINE_GL_DIST_ALL WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_RA_CUSTOMER_TRX_LINES_ALL AS SELECT * FROM AR.RA_CUSTOMER_TRX_LINES_ALL WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_AR_ADJUSTMENTS_ALL AS SELECT * FROM AR.AR_ADJUSTMENTS_ALL WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_PA_CUST_EVENT_RDL_ALL AS SELECT * FROM PA.PA_CUST_EVENT_RDL_ALL WHERE PROGRAM_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'')';
execute immediate 'create table dka_consultation.DKA_PO_POSITION_CONTROLS_ALL AS SELECT * FROM PO.PO_POSITION_CONTROLS_ALL';
execute immediate 'create table dka_consultation.DKA_PO_CONTROL_GROUPS_ALL AS SELECT * FROM PO.PO_CONTROL_GROUPS_ALL';
execute immediate 'create table dka_consultation.DKA_PO_CONTROL_RULES AS SELECT * FROM PO.PO_CONTROL_RULES';
execute immediate 'create table dka_consultation.DKA_PER_SECURITY_ORGANIZATIONS AS SELECT * FROM HR.PER_SECURITY_ORGANIZATIONS';
execute immediate 'create table dka_consultation.DKA_PER_SECURITY_PROFILES AS SELECT * FROM HR.PER_SECURITY_PROFILES';
execute immediate 'create table dka_consultation.DKA_WF_NOTIFICATIONS AS SELECT * FROM APPLSYS.WF_NOTIFICATIONS WHERE STATUS=''OPEN''';
execute immediate 'create table dka_consultation.DKA_STRANSCO_LINES_1 AS SELECT * FROM DKA.DKA_STRANSCO_LINES';
execute immediate 'create table dka_consultation.DKA_STRANSCO_HEADERS_1 AS SELECT * FROM DKA.DKA_STRANSCO_HEADERS';
execute immediate 'create table dka_consultation.DKA_AP_INVOICE_LINES_ALL AS SELECT * FROM AP.AP_INVOICE_LINES_ALL WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_HZ_CUST_ACCOUNTS AS SELECT * FROM AR.HZ_CUST_ACCOUNTS';
execute immediate 'create table dka_consultation.DKA_HZ_CUST_ACCT_SITES_ALL AS SELECT * FROM AR.HZ_CUST_ACCT_SITES_ALL WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_HZ_PARTY_SITES AS SELECT * FROM AR.HZ_PARTY_SITES WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_HZ_CUST_SITE_USES_ALL AS SELECT * FROM AR.HZ_CUST_SITE_USES_ALL WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_HZ_LOCATIONS AS SELECT * FROM AR.HZ_LOCATIONS';
execute immediate 'create table dka_consultation.DKA_ZX_LINES AS SELECT * FROM ZX.ZX_LINES WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_AR_PAYMENT_SCHEDULES_ALL AS SELECT * FROM AR.AR_PAYMENT_SCHEDULES_ALL WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_AR_CASH_RECEIPTS_ALL AS SELECT * FROM AR.AR_CASH_RECEIPTS_ALL WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_AR_REC_APPLICATIONS_ALL AS SELECT * FROM AR.AR_RECEIVABLE_APPLICATIONS_ALL WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_RA_TERMS_TL AS SELECT * FROM AR.RA_TERMS_TL';
execute immediate 'create table dka_consultation.DKA_AR_RECEIPT_METHODS AS SELECT * FROM AR.AR_RECEIPT_METHODS';
execute immediate 'create table dka_consultation.DKA_RA_CUST_TRX_TYPES_ALL AS SELECT * FROM AR.RA_CUST_TRX_TYPES_ALL';
execute immediate 'create table dka_consultation.DKA_RA_BATCH_SOURCES_ALL AS SELECT * FROM AR.RA_BATCH_SOURCES_ALL';
execute immediate 'create table dka_consultation.DKA_FND_LOOKUP_VALUES AS SELECT * FROM APPLSYS.FND_LOOKUP_VALUES WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_IBY_EXT_BANK_ACCOUNTS AS SELECT * FROM IBY.IBY_EXT_BANK_ACCOUNTS';
execute immediate 'create table dka_consultation.DKA_CONTRAT_SSTR_1 AS SELECT * FROM DKA.DKA_CONTRAT_SSTR WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_CONTRAT_SSTR_IMPUTATION_1 AS SELECT * FROM DKA.DKA_CONTRAT_SSTR_IMPUTATION WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
-- execute immediate 'create table dka_consultation.DKA_PO_LINE_LOCATIONS_ALL AS SELECT * FROM PO.PO_LINE_LOCATIONS_ALL WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_PO_LINE_LOCATIONS_ALL AS SELECT * FROM PO.PO_LINE_LOCATIONS_ALL';
execute immediate 'create table dka_consultation.DKA_RCV_TRANSACTIONS AS SELECT * FROM PO.RCV_TRANSACTIONS WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_RCV_SHIPMENT_HEADERS AS SELECT * FROM PO.RCV_SHIPMENT_HEADERS WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_PO_LINES_ARCHIVE_ALL AS SELECT * FROM PO.PO_LINES_ARCHIVE_ALL WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_PO_HEADERS_ARCHIVE_ALL AS SELECT * FROM PO.PO_HEADERS_ARCHIVE_ALL WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_FND_REQUEST_GROUPS AS SELECT * FROM APPLSYS.FND_REQUEST_GROUPS';
execute immediate 'create table dka_consultation.DKA_FND_APPLICATION_TL AS SELECT * FROM APPLSYS.FND_APPLICATION_TL';
execute immediate 'create table dka_consultation.DKA_PER_JOBS_TL AS SELECT * FROM HR.PER_JOBS_TL';
execute immediate 'create table dka_consultation.DKA_PER_ASSIGN_STATUS_TYPES AS SELECT * FROM HR.PER_ASSIGNMENT_STATUS_TYPES';
execute immediate 'create table dka_consultation.DKA_PER_JOBS AS SELECT * FROM HR.PER_JOBS';
execute immediate 'create table dka_consultation.DKA_PO_CONTROL_FUNCTIONS AS SELECT * FROM PO.PO_CONTROL_FUNCTIONS';
execute immediate 'create table dka_consultation.DKA_FND_RESPONSIBILITY AS SELECT * FROM APPLSYS.FND_RESPONSIBILITY';
execute immediate 'create table dka_consultation.DKA_FND_RESPONSIBILITY_TL AS SELECT * FROM APPLSYS.FND_RESPONSIBILITY_TL';
execute immediate 'create table dka_consultation.DKA_FND_PROFILE_OPTIONS AS SELECT * FROM APPLSYS.FND_PROFILE_OPTIONS';
execute immediate 'create table dka_consultation.DKA_AK_WEB_USER_SEC_ATTR_VAL AS SELECT * FROM AK.AK_WEB_USER_SEC_ATTR_VALUES';
execute immediate 'create table dka_consultation.DKA_AK_RESP_SECURITY_ATTR AS SELECT * FROM AK.AK_RESP_SECURITY_ATTRIBUTES';
execute immediate 'create table dka_consultation.DKA_PER_GRADES_TL AS SELECT * FROM HR.PER_GRADES_TL';
execute immediate 'create table dka_consultation.DKA_FND_SECURITY_GROUPS AS SELECT * FROM APPLSYS.FND_SECURITY_GROUPS';
execute immediate 'create table dka_consultation.DKA_WF_USER_ROLE_ASSIGNMENTS AS SELECT * FROM APPLSYS.WF_USER_ROLE_ASSIGNMENTS';
execute immediate 'create table dka_consultation.DKA_WF_LOCAL_USER_ROLES AS SELECT * FROM APPLSYS.WF_LOCAL_USER_ROLES WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_PER_ORGANIZATION_STRUCT AS SELECT * FROM HR.PER_ORGANIZATION_STRUCTURES';
execute immediate 'create table dka_consultation.DKA_PER_ORG_STRUCTURE_VERSIONS AS SELECT * FROM HR.PER_ORG_STRUCTURE_VERSIONS';
execute immediate 'create table dka_consultation.DKA_PER_ORG_STRUCTURE_ELEMENTS AS SELECT * FROM HR.PER_ORG_STRUCTURE_ELEMENTS';
execute immediate 'create table dka_consultation.DKA_CE_BANK_ACCOUNTS AS SELECT * FROM CE.CE_BANK_ACCOUNTS';
execute immediate 'create table dka_consultation.DKA_IBY_PAYMENTS_ALL AS SELECT * FROM IBY.IBY_PAYMENTS_ALL WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_GL_JE_CATEGORIES_TL AS SELECT * FROM GL.GL_JE_CATEGORIES_TL';
execute immediate 'create table dka_consultation.DKA_GL_JE_SOURCES_TL AS SELECT * FROM GL.GL_JE_SOURCES_TL';
execute immediate 'create table dka_consultation.DKA_FND_PROFILE_OPTIONS_TL AS SELECT * FROM APPLSYS.FND_PROFILE_OPTIONS_TL';
execute immediate 'create table dka_consultation.DKA_SAP_STATUT_FACTURE_1 AS SELECT * FROM DKA.DKA_SAP_STATUT_FACTURE WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_FA_CATEGORIES_B AS SELECT * FROM FA.FA_CATEGORIES_B';
execute immediate 'create table dka_consultation.DKA_FA_CATEGORIES_TL AS SELECT * FROM FA.FA_CATEGORIES_TL';
execute immediate 'create table dka_consultation.DKA_FA_CATEGORY_BOOKS AS SELECT * FROM FA.FA_CATEGORY_BOOKS WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_FA_ADJUSTMENTS AS SELECT * FROM FA.FA_ADJUSTMENTS WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_FA_CALENDAR_PERIODS AS SELECT * FROM FA.FA_CALENDAR_PERIODS WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_FA_DEPRN_DETAIL AS SELECT * FROM FA.FA_DEPRN_DETAIL WHERE DEPRN_RUN_DATE>=TO_DATE(''&1'',''YYYYMMDD'')';
execute immediate 'create table dka_consultation.DKA_FA_BOOK_CONTROLS AS SELECT * FROM FA.FA_BOOK_CONTROLS WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_FA_ADDITIONS_B AS SELECT * FROM FA.FA_ADDITIONS_B';
execute immediate 'create table dka_consultation.DKA_FA_ADDITIONS_TL AS SELECT * FROM FA.FA_ADDITIONS_TL';
execute immediate 'create table dka_consultation.DKA_FA_ASSET_INVOICES AS SELECT * FROM FA.FA_ASSET_INVOICES WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_FA_BOOKS AS SELECT * FROM FA.FA_BOOKS WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_FA_DEPRN_PERIODS AS SELECT * FROM FA.FA_DEPRN_PERIODS';
execute immediate 'create table dka_consultation.DKA_FA_DISTRIBUTION_HISTORY AS SELECT * FROM FA.FA_DISTRIBUTION_HISTORY WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_FA_LOCATIONS AS SELECT * FROM FA.FA_LOCATIONS WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_FA_LOOKUPS_TL AS SELECT * FROM FA.FA_LOOKUPS_TL';
execute immediate 'create table dka_consultation.DKA_FA_RETIREMENTS AS SELECT * FROM FA.FA_RETIREMENTS WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_FA_TRANSACTION_HEADERS AS SELECT * FROM FA.FA_TRANSACTION_HEADERS WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_FA_LOOKUPS_B AS SELECT * FROM FA.FA_LOOKUPS_B';
execute immediate 'create table dka_consultation.DKA_FA_DEPRN_SUMMARY AS SELECT * FROM FA.FA_DEPRN_SUMMARY WHERE DEPRN_RUN_DATE>=TO_DATE(''&1'',''YYYYMMDD'')';
execute immediate 'create table dka_consultation.DKA_FA_MC_DEPRN_SUMMARY AS SELECT * FROM FA.FA_MC_DEPRN_SUMMARY WHERE DEPRN_RUN_DATE>=TO_DATE(''&1'',''YYYYMMDD'')';
execute immediate 'create table dka_consultation.DKA_FA_MC_BOOKS AS SELECT * FROM FA.FA_MC_BOOKS WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_FA_MC_BOOK_CONTROLS AS SELECT * FROM FA.FA_MC_BOOK_CONTROLS WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_FA_DISTRIBUTION_ACCOUNTS AS SELECT * FROM FA.FA_DISTRIBUTION_ACCOUNTS WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_HZ_CUSTOMER_PROFILES AS SELECT * FROM AR.HZ_CUSTOMER_PROFILES WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_AR_COLLECTORS AS SELECT * FROM AR.AR_COLLECTORS WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';
execute immediate 'create table dka_consultation.DKA_FND_PROFILE_OPTION_VALUES AS SELECT * FROM APPLSYS.FND_PROFILE_OPTION_VALUES WHERE LAST_UPDATE_DATE>=TO_DATE(''&1'',''YYYYMMDD'') and LAST_UPDATE_DATE<TO_DATE(''&1'',''YYYYMMDD'') + 1';

EXCEPTION
WHEN OTHERS THEN

DBMS_OUTPUT.put_line ('Erreur lors de la creation des tables : ' || SQLERRM);

END;

DBMS_OUTPUT.put_line ('Creation des tables terminee');

DBMS_OUTPUT.put_line ('Creation des valeurs par defaut des tables');

BEGIN

execute immediate 'alter table DKA_CONSULTATION.DKA_AK_RESP_SECURITY_ATTR modify (ZD_EDITION_NAME default ''ORA$BASE'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_AK_RESP_SECURITY_ATTR modify (ZD_SYNC default ''SYNCED'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_AP_CHECKS_ALL modify (ORG_ID default NULL)';
execute immediate 'alter table DKA_CONSULTATION.DKA_AP_CHECKS_ALL modify (POSITIVE_PAY_STATUS_CODE default ''UNSENT'')';
execute immediate 'alter table DKA_CONSULTATION.DKA_AP_HOLDS_ALL modify (ORG_ID default NULL)';
execute immediate 'alter table DKA_CONSULTATION.DKA_AP_INVOICES_ALL modify (ORG_ID default NULL)';
execute immediate 'alter table DKA_CONSULTATION.DKA_AP_INV_DISTRIBUTIONS_ALL modify (ORG_ID default NULL)';
execute immediate 'alter table DKA_CONSULTATION.DKA_AP_INVOICE_LINES_ALL modify (ORG_ID default NULL)';
execute immediate 'alter table DKA_CONSULTATION.DKA_AP_INVOICE_PAYMENTS_ALL modify (ORG_ID default NULL)';
execute immediate 'alter table DKA_CONSULTATION.DKA_AP_PAYMENT_SCHEDULES_ALL modify (ORG_ID default NULL)';
execute immediate 'alter table DKA_CONSULTATION.DKA_AP_PAYMENT_SCHEDULES_ALL modify (DBI_EVENTS_COMPLETE_FLAG default ''N'')';
execute immediate 'alter table DKA_CONSULTATION.DKA_AP_SUPPLIER_SITES_ALL modify (ORG_ID default NULL)';
execute immediate 'alter table DKA_CONSULTATION.DKA_AR_ADJUSTMENTS_ALL modify (POSTING_CONTROL_ID default -3)';
execute immediate 'alter table DKA_CONSULTATION.DKA_AR_ADJUSTMENTS_ALL modify (ORG_ID default NULL)';
execute immediate 'alter table DKA_CONSULTATION.DKA_AR_CASH_RECEIPTS_ALL modify (ORG_ID default NULL)';
execute immediate 'alter table DKA_CONSULTATION.DKA_AR_CASH_RECEIPTS_ALL modify (UNIQUE_REFERENCE default SYS_GUID ( ))';
execute immediate 'alter table DKA_CONSULTATION.DKA_AR_COLLECTORS modify (ZD_EDITION_NAME default ''ORA$BASE'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_AR_COLLECTORS modify (ZD_SYNC default ''SYNCED'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_AR_PAYMENT_SCHEDULES_ALL modify (ORG_ID default NULL)';
execute immediate 'alter table DKA_CONSULTATION.DKA_AR_RECEIPT_METHODS modify (ZD_EDITION_NAME default ''ORA$BASE'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_AR_RECEIPT_METHODS modify (ZD_SYNC default ''SYNCED'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_AR_REC_APPLICATIONS_ALL modify (POSTING_CONTROL_ID default -3)';
execute immediate 'alter table DKA_CONSULTATION.DKA_AR_REC_APPLICATIONS_ALL modify (ORG_ID default NULL)';
execute immediate 'alter table DKA_CONSULTATION.DKA_STRANSCO_HEADERS_1 modify (PARAM1_FLAG default ''N'')';
execute immediate 'alter table DKA_CONSULTATION.DKA_STRANSCO_HEADERS_1 modify (PARAM2_FLAG default ''N'')';
execute immediate 'alter table DKA_CONSULTATION.DKA_STRANSCO_HEADERS_1 modify (PARAM3_FLAG default ''N'')';
execute immediate 'alter table DKA_CONSULTATION.DKA_STRANSCO_LINES_1 modify (ENABLE default ''N'')';
execute immediate 'alter table DKA_CONSULTATION.DKA_FA_BOOK_CONTROLS modify (USE_CURRENT_NBV_FOR_DEPRN default ''NO'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_FA_BOOK_CONTROLS modify (COPY_ADDITIONS_FLAG default ''YES'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_FA_LOOKUPS_B modify (ZD_EDITION_NAME default ''ORA$BASE'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_FA_LOOKUPS_B modify (ZD_SYNC default ''SYNCED'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_FA_LOOKUPS_TL modify (ZD_EDITION_NAME default ''ORA$BASE'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_FA_LOOKUPS_TL modify (ZD_SYNC default ''SYNCED'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_FA_MC_BOOKS modify (SET_OF_BOOKS_ID default NVL ( TO_NUMBER ( SUBSTRB ( USERENV ( ''CLIENT_INFO'') ,45,10 ) ) ,-1 ) )';
execute immediate 'alter table DKA_CONSULTATION.DKA_FA_MC_BOOKS modify (CONVERTED_FLAG default ''Y'')';
execute immediate 'alter table DKA_CONSULTATION.DKA_FA_MC_DEPRN_SUMMARY modify (SET_OF_BOOKS_ID default NVL ( TO_NUMBER ( SUBSTRB ( USERENV ( ''CLIENT_INFO'') ,45,10 ) ) ,-1 ) )';
execute immediate 'alter table DKA_CONSULTATION.DKA_FA_MC_DEPRN_SUMMARY modify (CONVERTED_FLAG default ''Y'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_FND_APPLICATION modify (ZD_EDITION_NAME default ''ORA$BASE'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_FND_APPLICATION modify (ZD_SYNC default ''SYNCED'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_FND_APPLICATION_TL modify (ZD_EDITION_NAME default ''ORA$BASE'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_FND_APPLICATION_TL modify (ZD_SYNC default ''SYNCED'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_FND_FLEX_VALUES modify (ZD_EDITION_NAME default ''ORA$BASE'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_FND_FLEX_VALUES modify (ZD_SYNC default ''SYNCED'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_FND_FLEX_VALUES_TL modify (ZD_EDITION_NAME default ''ORA$BASE'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_FND_FLEX_VALUES_TL modify (ZD_SYNC default ''SYNCED'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_FND_FLEX_VALUE_SETS modify (ZD_EDITION_NAME default ''ORA$BASE'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_FND_FLEX_VALUE_SETS modify (ZD_SYNC default ''SYNCED'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_FND_ID_FLEX_STRUCTURES_TL modify (ZD_EDITION_NAME default ''ORA$BASE'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_FND_ID_FLEX_STRUCTURES_TL modify (ZD_SYNC default ''SYNCED'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_FND_LOOKUP_VALUES modify (SECURITY_GROUP_ID default 0)';
execute immediate 'alter table DKA_CONSULTATION.DKA_FND_LOOKUP_VALUES modify (ZD_EDITION_NAME default ''ORA$BASE'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_FND_LOOKUP_VALUES modify (ZD_SYNC default ''SYNCED'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_FND_PROFILE_OPTIONS modify (SERVERRESP_ENABLED_FLAG default ''N'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_FND_PROFILE_OPTIONS modify (SERVERRESP_UPDATE_ALLOWED_FLAG default ''N'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_FND_PROFILE_OPTIONS modify (ZD_EDITION_NAME default ''ORA$BASE'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_FND_PROFILE_OPTIONS modify (ZD_SYNC default ''SYNCED'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_FND_PROFILE_OPTIONS_TL modify (ZD_EDITION_NAME default ''ORA$BASE'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_FND_PROFILE_OPTIONS_TL modify (ZD_SYNC default ''SYNCED'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_FND_PROFILE_OPTION_VALUES modify (ZD_EDITION_NAME default ''ORA$BASE'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_FND_PROFILE_OPTION_VALUES modify (ZD_SYNC default ''SYNCED'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_FND_REQUEST_GROUPS modify (ZD_EDITION_NAME default ''ORA$BASE'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_FND_REQUEST_GROUPS modify (ZD_SYNC default ''SYNCED'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_FND_RESPONSIBILITY modify (ZD_EDITION_NAME default ''ORA$BASE'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_FND_RESPONSIBILITY modify (ZD_SYNC default ''SYNCED'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_FND_RESPONSIBILITY_TL modify (ZD_EDITION_NAME default ''ORA$BASE'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_FND_RESPONSIBILITY_TL modify (ZD_SYNC default ''SYNCED'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_FND_SECURITY_GROUPS modify (ZD_EDITION_NAME default ''ORA$BASE'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_FND_SECURITY_GROUPS modify (ZD_SYNC default ''SYNCED'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_GL_JE_CATEGORIES_TL modify (ZD_EDITION_NAME default ''ORA$BASE'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_GL_JE_CATEGORIES_TL modify (ZD_SYNC default ''SYNCED'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_GL_JE_LINES_RECON modify (JGZZ_RECON_STATUS default ''U'')';
execute immediate 'alter table DKA_CONSULTATION.DKA_GL_JE_SOURCES_TL modify (ZD_EDITION_NAME default ''ORA$BASE'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_GL_JE_SOURCES_TL modify (ZD_SYNC default ''SYNCED'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_HZ_CUST_ACCT_SITES_ALL modify (ORG_ID default to_number(decode(substrb(userenv(''CLIENT_INFO''),1,1),'' '',null,substrb(userenv(''CLIENT_INFO''),1,10))))';
execute immediate 'alter table DKA_CONSULTATION.DKA_HZ_CUST_SITE_USES_ALL modify (ORG_ID default to_number(decode(substrb(userenv(''CLIENT_INFO''),1,1),'' '',null,substrb(userenv(''CLIENT_INFO''),1,10))))';
execute immediate 'alter table DKA_CONSULTATION.DKA_HZ_LOCATIONS modify (ACTUAL_CONTENT_SOURCE default ''USER_ENTERED'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_HZ_PARTY_SITES modify (ACTUAL_CONTENT_SOURCE default ''USER_ENTERED'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_IBY_PAYMENTS_ALL modify (PAYMENT_CURRENCY_CODE#1 default ''*NULL*'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_MTL_CATEGORIES_B modify (ZD_EDITION_NAME default ''ORA$BASE'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_MTL_CATEGORIES_B modify (ZD_SYNC default ''SYNCED'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_MTL_CATEGORIES_TL modify (ZD_EDITION_NAME default ''ORA$BASE'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_MTL_CATEGORIES_TL modify (ZD_SYNC default ''SYNCED'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_PA_COST_DIST_LINES_ALL modify (ORG_ID default NULL)';
execute immediate 'alter table DKA_CONSULTATION.DKA_PA_COST_DIST_LINES_ALL modify (UTIL_SUMMARIZED_FLAG default ''N'')';
execute immediate 'alter table DKA_CONSULTATION.DKA_PA_COST_DIST_LINES_ALL modify (AMOUNT#1 default 0)';
execute immediate 'alter table DKA_CONSULTATION.DKA_PA_COST_DIST_LINES_ALL modify (QUANTITY#1 default 0)';
execute immediate 'alter table DKA_CONSULTATION.DKA_PA_CUST_EVENT_RDL_ALL modify (ORG_ID default NULL)';
execute immediate 'alter table DKA_CONSULTATION.DKA_PA_DRAFT_REVENUES_ALL modify (ORG_ID default NULL)';
execute immediate 'alter table DKA_CONSULTATION.DKA_PA_DRAFT_REVENUES_ALL modify (UBR_UER_PROCESS_FLAG default ''N'')';
execute immediate 'alter table DKA_CONSULTATION.DKA_PA_EVENTS modify (BILLED_FLAG default ''N'')';
execute immediate 'alter table DKA_CONSULTATION.DKA_PA_EXPENDITURE_ITEMS_ALL modify (ORG_ID default NULL)';
execute immediate 'alter table DKA_CONSULTATION.DKA_PA_EXPENDITURE_ITEMS_ALL modify (CC_CROSS_CHARGE_CODE default ''P'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_PA_EXPENDITURE_ITEMS_ALL modify (CC_CROSS_CHARGE_TYPE default ''NO'')';
execute immediate 'alter table DKA_CONSULTATION.DKA_PA_EXPENDITURE_ITEMS_ALL modify (CC_BL_DISTRIBUTED_CODE default ''X'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_PA_EXPENDITURE_ITEMS_ALL modify (CC_IC_PROCESSED_CODE default ''X'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_PA_EXPENDITURE_ITEMS_ALL modify (CC_PRVDR_COST_RECLASS_CODE default ''N'')';
execute immediate 'alter table DKA_CONSULTATION.DKA_PA_EXPENDITURE_ITEMS_ALL modify (HISTORICAL_FLAG default ''N'')';
execute immediate 'alter table DKA_CONSULTATION.DKA_PA_EXPENDITURE_TYPES modify (ADW_NOTIFY_FLAG default ''Y'')';
execute immediate 'alter table DKA_CONSULTATION.DKA_PA_PERIODS_ALL modify (ORG_ID default NULL)';
execute immediate 'alter table DKA_CONSULTATION.DKA_PA_PROJECTS_ALL modify (ORG_ID default NULL)';
execute immediate 'alter table DKA_CONSULTATION.DKA_PA_PROJECTS_ALL modify (ADW_NOTIFY_FLAG default ''Y'')';
execute immediate 'alter table DKA_CONSULTATION.DKA_PA_PROJECTS_ALL modify (CC_PROCESS_LABOR_FLAG default ''N'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_PA_PROJECTS_ALL modify (CC_PROCESS_NL_FLAG default ''N'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_PA_PROJECTS_ALL modify (AR_REC_NOTIFY_FLAG default ''N'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_PA_PROJECTS_ALL modify (AUTO_RELEASE_PWP_INV default ''Y'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_PA_PROJECTS_ALL modify (BILL_LABOR_ACCRUAL default ''N'')';
execute immediate 'alter table DKA_CONSULTATION.DKA_PA_PROJECTS_ALL modify (ADJ_ON_STD_INV default ''N'')';
execute immediate 'alter table DKA_CONSULTATION.DKA_PA_PROJECTS_ALL modify (PJT_ROLLUP_ENABLED_FLAG default ''N'')';
execute immediate 'alter table DKA_CONSULTATION.DKA_PA_PROJECT_ASSETS_ALL modify (ORG_ID default NULL)';
execute immediate 'alter table DKA_CONSULTATION.DKA_PA_PROJECT_ASSETS_ALL modify (PROJECT_ASSET_TYPE default ''ESTIMATED'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_PA_PROJECT_ASSETS_ALL modify (CAPITAL_HOLD_FLAG default ''N'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_PA_PROJECT_STATUSES modify (ZD_EDITION_NAME default ''ORA$BASE'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_PA_PROJECT_STATUSES modify (ZD_SYNC default ''SYNCED'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_PA_PROJECT_ASSET_LINES_ALL modify (ORG_ID default NULL)';
execute immediate 'alter table DKA_CONSULTATION.DKA_PA_TASKS modify (CC_PROCESS_LABOR_FLAG default ''N'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_PA_TASKS modify (CC_PROCESS_NL_FLAG default ''N'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_PA_TASKS modify (ADW_NOTIFY_FLAG default ''Y'')';
execute immediate 'alter table DKA_CONSULTATION.DKA_PER_ASSIGN_STATUS_TYPES modify (ZD_EDITION_NAME default ''ORA$BASE'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_PER_ASSIGN_STATUS_TYPES modify (ZD_SYNC default ''SYNCED'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_PO_CONTROL_FUNCTIONS modify (ZD_EDITION_NAME default ''ORA$BASE'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_PO_CONTROL_FUNCTIONS modify (ZD_SYNC default ''SYNCED'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_PO_CONTROL_GROUPS_ALL modify (ORG_ID default NULL)';
execute immediate 'alter table DKA_CONSULTATION.DKA_PO_DISTRIBUTIONS_ALL modify (ORG_ID default NULL)';
execute immediate 'alter table DKA_CONSULTATION.DKA_PO_HEADERS_ALL modify (ORG_ID default NULL)';
execute immediate 'alter table DKA_CONSULTATION.DKA_PO_HEADERS_ARCHIVE_ALL modify (ORG_ID default NULL)';
execute immediate 'alter table DKA_CONSULTATION.DKA_PO_LINES_ALL modify (ORG_ID default NULL)';
execute immediate 'alter table DKA_CONSULTATION.DKA_PO_LINES_ARCHIVE_ALL modify (ORG_ID default NULL)';
execute immediate 'alter table DKA_CONSULTATION.DKA_PO_LINE_LOCATIONS_ALL modify (ORG_ID default NULL)';
execute immediate 'alter table DKA_CONSULTATION.DKA_PO_POSITION_CONTROLS_ALL modify (ORG_ID default NULL)';
execute immediate 'alter table DKA_CONSULTATION.DKA_PO_REQ_DISTRIBUTIONS_ALL modify (ORG_ID default NULL)';
execute immediate 'alter table DKA_CONSULTATION.DKA_PO_REQUISITION_HEADERS_ALL modify (ORG_ID default NULL)';
execute immediate 'alter table DKA_CONSULTATION.DKA_PO_REQUISITION_LINES_ALL modify (ORG_ID default NULL)';
execute immediate 'alter table DKA_CONSULTATION.DKA_RA_BATCH_SOURCES_ALL modify (ORG_ID default NULL)';
execute immediate 'alter table DKA_CONSULTATION.DKA_RA_BATCH_SOURCES_ALL modify (ZD_EDITION_NAME default ''ORA$BASE'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_RA_BATCH_SOURCES_ALL modify (ZD_SYNC default ''SYNCED'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_RA_CUSTOMER_TRX_ALL modify (ORG_ID default NULL)';
execute immediate 'alter table DKA_CONSULTATION.DKA_CUST_TRX_LINE_GL_DIST_ALL modify (POSTING_CONTROL_ID default -3)';
execute immediate 'alter table DKA_CONSULTATION.DKA_CUST_TRX_LINE_GL_DIST_ALL modify (ORG_ID default NULL)';
execute immediate 'alter table DKA_CONSULTATION.DKA_RA_CUSTOMER_TRX_LINES_ALL modify (ORG_ID default NULL)';
execute immediate 'alter table DKA_CONSULTATION.DKA_RA_CUST_TRX_TYPES_ALL modify (ZD_EDITION_NAME default ''ORA$BASE'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_RA_CUST_TRX_TYPES_ALL modify (ZD_SYNC default ''SYNCED'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_RA_CUST_TRX_TYPES_ALL modify (ORG_ID default NULL)';
execute immediate 'alter table DKA_CONSULTATION.DKA_RA_TERMS_TL modify (ZD_EDITION_NAME default ''ORA$BASE'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_RA_TERMS_TL modify (ZD_SYNC default ''SYNCED'' )';
execute immediate 'alter table DKA_CONSULTATION.DKA_RCV_TRANSACTIONS modify (PA_ADDITION_FLAG default ''N'')';
execute immediate 'alter table DKA_CONSULTATION.DKA_WF_LOCAL_USER_ROLES modify (USER_ORIG_SYSTEM default ''WF_LOCAL_ROLES'')';
execute immediate 'alter table DKA_CONSULTATION.DKA_WF_LOCAL_USER_ROLES modify (USER_ORIG_SYSTEM_ID default 0)';
execute immediate 'alter table DKA_CONSULTATION.DKA_WF_LOCAL_USER_ROLES modify (ROLE_ORIG_SYSTEM default ''WF_LOCAL_ROLES'')';
execute immediate 'alter table DKA_CONSULTATION.DKA_WF_LOCAL_USER_ROLES modify (ROLE_ORIG_SYSTEM_ID default 0)';
execute immediate 'alter table DKA_CONSULTATION.DKA_WF_LOCAL_USER_ROLES modify (START_DATE default null)';
execute immediate 'alter table DKA_CONSULTATION.DKA_WF_LOCAL_USER_ROLES modify (EXPIRATION_DATE default null)';
execute immediate 'alter table DKA_CONSULTATION.DKA_WF_LOCAL_USER_ROLES modify (SECURITY_GROUP_ID default null)';
execute immediate 'alter table DKA_CONSULTATION.DKA_WF_LOCAL_USER_ROLES modify (PARTITION_ID default 0)';


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