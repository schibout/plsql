--------------------------------------------------------------------------------
-- $Id: XXEAI_INFOS_BANQUE_TYP.sql $
-- Capgemini
-- Projet           : Dalkia
-- Nom              : XXEAI_INFOS_BANQUE_TYP.sql
-- Description      : Création de l'objet XXEAI_INFOS_BANQUE_OBJ
-- Auteur           : Julien Jardez
-- Date de création : 19/05/2014
-- Doc. associée    :
-- Commentaires     : A exécuter sous SQLPLUS avec l'utilisateur DKA en 
--                    passant en parametres
--                    1- Login APPS
--                    2- Password APPS
--
--------------------------------------------------------------------------------
-- Historique
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------
-- 08/09/2014 BCO DPE20140079 - Evolution appel de fonction Banque pour l'EAI
-- 02/12/2014 BCO DPE20140088 - Ajout des outils d'interface pour AP
-- 28/08/2017 YWA artf2215513 : SPE182 - Gestion des écritures de paie_Context MAT et ATTRIBUTE11 - EDB083 (FA + fnd_id_flex_structures_vl)
-- 05/02/2019 SFA artf3063732 : INC0283997 - Campagne règlement - IBAN sur plusieurs fournisseurs
-- 03/07/2023 ARA EDB363 - Compte 471000 (MODIFICATION FONCTION EAI – AJOUT DU CRITERE SET1).
--------------------------------------------------------------------------------

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT ON APPS.CE_BANK_BRANCHES_V
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT SELECT ON APPS.CE_BANK_BRANCHES_V TO XXEAI;


PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT ON APPS.CE_BANK_ACCOUNTS
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT SELECT ON APPS.CE_BANK_ACCOUNTS TO XXEAI;


PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT ON APPS.PA_PROJECTS_ALL
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT SELECT ON APPS.PA_PROJECTS_ALL TO XXEAI;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT ON APPS.PA_PROJECTS
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT SELECT ON APPS.PA_PROJECTS TO XXEAI;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT ON APPS.PA_TASKS
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT SELECT ON APPS.PA_TASKS TO XXEAI;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT ON PA.PA_PROJECT_CLASSES
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT SELECT ON PA.PA_PROJECT_CLASSES TO XXEAI;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT ON APPS.DKA_STRANSCO_HEADERS
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT SELECT ON APPS.DKA_STRANSCO_HEADERS TO XXEAI;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT ON APPS.DKA_STRANSCO_LINES
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT SELECT ON APPS.DKA_STRANSCO_LINES TO XXEAI;

--PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--PROMPT GRANT SELECT ON PA.PA_COST_DIST_OVERRIDES
--PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--GRANT SELECT ON PA.PA_COST_DIST_OVERRIDES TO XXEAI;
--
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT ON APPS.HR_ALL_ORGANIZATION_UNITS
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT SELECT ON APPS.HR_ALL_ORGANIZATION_UNITS TO XXEAI;

--PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--PROMPT GRANT SELECT ON PA.PA_EVENT_TYPES
--PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--GRANT SELECT ON PA.PA_EVENT_TYPES TO XXEAI;
--
--PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--PROMPT GRANT SELECT ON PA.PA_EXPENDITURE_TYPES
--PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--GRANT SELECT ON PA.PA_EXPENDITURE_TYPES TO XXEAI;
--
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT ON APPS.FND_FLEX_VALUES
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT SELECT ON APPS.FND_FLEX_VALUES TO XXEAI;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT ON APPS.FND_FLEX_VALUES_DFV
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT SELECT ON APPS.FND_FLEX_VALUES_DFV TO XXEAI;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT ON APPS.FND_FLEX_VALUES_TL
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--GRANT SELECT ON APPLSYS.FND_FLEX_VALUES_TL TO XXEAI;
GRANT SELECT ON APPS.FND_FLEX_VALUES_TL TO XXEAI; --EDB363

--
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT ON APPS.FND_FLEX_VALUE_SETS
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT SELECT ON APPS.FND_FLEX_VALUE_SETS TO XXEAI;

--
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT ON APPS.FND_FLEX_VALUES_VL
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT SELECT ON APPS.FND_FLEX_VALUES_VL TO XXEAI;
--
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT ON APPS.FND_ID_FLEX_SEGMENTS
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT SELECT ON APPS.FND_ID_FLEX_SEGMENTS TO XXEAI;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT ON APPS.FND_CURRENCIES
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT SELECT ON APPS.FND_CURRENCIES TO XXEAI;
--
--PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--PROMPT GRANT SELECT ON GL.gl_period_statuses TO XXEAI
--PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--GRANT SELECT ON GL.gl_period_statuses TO XXEAI;
--
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT ON APPS.AP_SUPPLIERS TO XXEAI
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT SELECT ON APPS.AP_SUPPLIERS TO XXEAI;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT ON APPS.PO_VENDORS_DFV TO XXEAI
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT SELECT ON APPS.PO_VENDORS_DFV TO XXEAI;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT ON APPS.AP_SUPPLIER_SITES_ALL TO XXEAI
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT SELECT ON APPS.AP_SUPPLIER_SITES_ALL TO XXEAI;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT ON APPS.GL_CODE_COMBINATIONS_KFV TO XXEAI
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT SELECT ON APPS.GL_CODE_COMBINATIONS_KFV TO XXEAI;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT ON APPS.ZX_RATES_B TO XXEAI
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT SELECT ON APPS.ZX_RATES_B TO XXEAI;

--PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--PROMPT GRANT SELECT ON PA.pa_cost_dist_overrides TO XXEAI
--PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--GRANT SELECT ON PA.pa_cost_dist_overrides TO XXEAI;
--
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT ON APPS.GL_LEDGERS TO XXEAI
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT SELECT ON APPS.GL_LEDGERS TO XXEAI;
--
--PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--PROMPT GRANT SELECT ON APPS.GL_JE_CATEGORIES TO XXEAI
--PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--GRANT SELECT ON APPS.GL_JE_CATEGORIES TO XXEAI;
--
--PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--PROMPT GRANT SELECT ON APPS.GL_JE_SOURCES TO XXEAI
--PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--GRANT SELECT ON APPS.GL_JE_SOURCES TO XXEAI;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT ON GL.GL_AUTOREV_CRITERIA_SETS TO XXEAI
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT SELECT ON GL.GL_AUTOREV_CRITERIA_SETS TO XXEAI;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT ON APPS.GL_AUTOREVERSE_OPTIONS_V TO XXEAI
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT SELECT ON APPS.GL_AUTOREVERSE_OPTIONS_V TO XXEAI;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT, INSERT, UPDATE ON GL.GL_INTERFACE TO XXEAI
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT SELECT, INSERT, UPDATE ON GL.GL_INTERFACE TO XXEAI;

--PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--PROMPT GRANT SELECT, INSERT, UPDATE ON AP.AP_INVOICES_INTERFACE TO XXEAI
--PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--GRANT SELECT, INSERT, UPDATE ON AP.AP_INVOICES_INTERFACE TO XXEAI;

--PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--PROMPT GRANT SELECT, INSERT, UPDATE ON AP.AP_INVOICE_LINES_INTERFACE TO XXEAI
--PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--GRANT SELECT, INSERT, UPDATE ON AP.AP_INVOICE_LINES_INTERFACE TO XXEAI;

--PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--PROMPT GRANT EXECUTE ON APPS.dka_ibdsoc_tools_pkg TO XXEAI
--PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--GRANT EXECUTE ON APPS.dka_ibdsoc_tools_pkg TO XXEAI;

--
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT EXECUTE ON APPS.FND_FLEX_EXT
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT EXECUTE ON APPS.FND_FLEX_EXT TO XXEAI;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT EXECUTE ON APPS.dka_stransco_pkg TO XXEAI
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT EXECUTE ON APPS.dka_stransco_pkg TO XXEAI;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT EXECUTE ON APPS.dka_spaautoaccounting_pkg TO XXEAI
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT EXECUTE ON APPS.dka_spaautoaccounting_pkg TO XXEAI;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT EXECUTE ON APPS.dka_tools_pkg TO XXEAI
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT EXECUTE ON APPS.dka_tools_pkg TO XXEAI;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT EXECUTE ON APPS.Dka_GL_Tools_Pkg TO XXEAI
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT EXECUTE ON APPS.Dka_GL_Tools_Pkg TO XXEAI;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT EXECUTE ON APPS.GL_AFF_AWC_API_PKG TO XXEAI
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT EXECUTE ON APPS.GL_AFF_AWC_API_PKG TO XXEAI;


PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT ON apps.FND_APPLICATION TO XXEAI
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--GRANT SELECT ON APPLSYS.FND_APPLICATION TO XXEAI;
GRANT SELECT ON apps.FND_APPLICATION TO XXEAI; --EDB363


PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT ON apps.fnd_columns TO XXEAI
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--GRANT SELECT ON APPLSYS.FND_COLUMNS TO XXEAI;  
GRANT SELECT ON apps.fnd_columns TO XXEAI;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT ON apps.fnd_descr_flex_column_usages TO XXEAI
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--GRANT SELECT ON APPLSYS.FND_DESCR_FLEX_COLUMN_USAGES TO XXEAI;  
GRANT SELECT ON apps.fnd_descr_flex_column_usages TO XXEAI; --EDB363

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT ON APPLSYS.FND_FLEX_VALIDATION_QUALIFIERS TO XXEAI
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT SELECT ON APPLSYS.FND_FLEX_VALIDATION_QUALIFIERS TO XXEAI;  

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT ON APPLSYS.FND_ID_FLEX_SEGMENTS TO XXEAI
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT SELECT ON APPLSYS.FND_ID_FLEX_SEGMENTS TO XXEAI;  

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT ON APPLSYS.FND_ID_FLEX_STRUCTURES TO XXEAI
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT SELECT ON APPLSYS.FND_ID_FLEX_STRUCTURES TO XXEAI;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT ON APPLSYS.FND_ID_FLEXS TO XXEAI
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT SELECT ON APPLSYS.FND_ID_FLEXS TO XXEAI;          

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT ON APPLSYS.FND_SEGMENT_ATTRIBUTE_VALUES TO XXEAI
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT SELECT ON APPLSYS.FND_SEGMENT_ATTRIBUTE_VALUES  TO XXEAI;  

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT ON APPLSYS.FND_SEGMENT_ATTRIBUTE_VALUES TO XXEAI
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT SELECT ON APPLSYS.FND_SEGMENT_ATTRIBUTE_VALUES TO XXEAI;  

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT ON apps.FND_TABLES TO XXEAI
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--GRANT SELECT ON APPLSYS.FND_TABLES TO XXEAI;        
GRANT SELECT ON apps.FND_TABLES TO XXEAI;--EDB363        


PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT ON APPLSYS.FND_VALUE_ATTRIBUTE_TYPES TO XXEAI
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT SELECT ON APPLSYS.FND_VALUE_ATTRIBUTE_TYPES TO XXEAI;  


PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT ON APPS.fa_categories_vl TO XXEAI
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT SELECT ON APPS.fa_categories_vl TO XXEAI;  

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT ON APPS.fa_category_books TO XXEAI
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT SELECT ON APPS.fa_category_books TO XXEAI;  


PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT ON APPS.FA_BOOK_CONTROLS TO XXEAI
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT SELECT ON APPS.FA_BOOK_CONTROLS TO XXEAI;  


PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT ON APPS.fnd_id_flex_structures_vl TO XXEAI
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT SELECT ON APPS.fnd_id_flex_structures_vl TO XXEAI;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT ON APPS.IBY_EXT_BANK_ACCOUNTS TO XXEAI
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT SELECT ON APPS.IBY_EXT_BANK_ACCOUNTS TO XXEAI;


PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT, UPDATE ON IBY.IBY_EXT_BANK_ACCOUNTS  TO XXEAI
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT SELECT, UPDATE ON IBY.IBY_EXT_BANK_ACCOUNTS TO XXEAI;


PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT, UPDATE ON CE.CE_BANK_ACCOUNTS  TO XXEAI
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT SELECT, UPDATE ON CE.CE_BANK_ACCOUNTS  TO XXEAI;

EXIT;


