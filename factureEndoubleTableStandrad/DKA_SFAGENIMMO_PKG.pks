--------------------------------------------------------------------------------
-- $Id: XXEAI_INFOS_BANQUE_TYP.sql $
-- Capgemini
-- Projet           : Dalkia
-- Nom              : XXEAI_SYNONYM_OBJECT.sql
-- Description      : Création des synonymes
-- Auteur           : Julien Jardez
-- Date de création : 06/04/2017
-- Doc. associée    :
-- Commentaires     : A exécuter sous SQLPLUS avec l'utilisateur APPS en 
--                    passant en parametres
--                    1- Login APPS
--                    2- Password APPS
--
--------------------------------------------------------------------------------
-- Historique
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------
-- 03/07/2023 ARA EDB363 - Compte 471000 (MODIFICATION FONCTION EAI – AJOUT DU CRITERE SET1).
--------------------------------------------------------------------------------

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATE OR REPLACE SYNONYM
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE OR REPLACE SYNONYM xxeai.dka_iclientifs_collectors FOR dka.dka_iclientifs_collectors;

CREATE OR REPLACE SYNONYM xxeai.dka_iclientifs_interface FOR dka.dka_iclientifs_interface;

CREATE OR REPLACE SYNONYM xxeai.dka_iarpafac_interface FOR dka.dka_iarpafac_interface;

CREATE OR REPLACE SYNONYM xxeai.dka_eai_projet FOR dka.dka_eai_projet;

CREATE OR REPLACE SYNONYM xxeai.dka_eai_tache FOR dka.dka_eai_tache;

CREATE OR REPLACE SYNONYM xxeai.dka_eai_organisation FOR dka.dka_eai_organisation;

CREATE OR REPLACE SYNONYM xxeai.GL_INTERFACE FOR gl.GL_INTERFACE;

CREATE OR REPLACE SYNONYM xxeai.AP_INVOICES_INTERFACE FOR ap.AP_INVOICES_INTERFACE;

CREATE OR REPLACE SYNONYM xxeai.AP_INVOICE_LINES_INTERFACE FOR ap.AP_INVOICE_LINES_INTERFACE;

--CREATE OR REPLACE SYNONYM xxeai.fnd_application FOR applsys.fnd_application; EDB363

--CREATE OR REPLACE SYNONYM xxeai.fnd_columns FOR applsys.fnd_columns;   EDB363

--CREATE OR REPLACE SYNONYM xxeai.fnd_descr_flex_column_usages FOR applsys.fnd_descr_flex_column_usages;  EDB363

CREATE OR REPLACE SYNONYM xxeai.fnd_flex_validation_qualifiers FOR applsys.fnd_flex_validation_qualifiers;  

CREATE OR REPLACE SYNONYM xxeai.fnd_id_flex_segments FOR applsys.fnd_id_flex_segments;  

CREATE OR REPLACE SYNONYM xxeai.FND_ID_FLEX_STRUCTURES FOR applsys.FND_ID_FLEX_STRUCTURES;          

CREATE OR REPLACE SYNONYM xxeai.FND_ID_FLEXS FOR applsys.FND_ID_FLEXS;

CREATE OR REPLACE SYNONYM xxeai.fnd_segment_attribute_values FOR applsys.fnd_segment_attribute_values;

CREATE OR REPLACE SYNONYM xxeai.fnd_segment_attribute_values FOR applsys.fnd_segment_attribute_values;  

--CREATE OR REPLACE SYNONYM xxeai.fnd_tables FOR applsys.fnd_tables;    EDB363 

CREATE OR REPLACE SYNONYM xxeai.fnd_value_attribute_types FOR applsys.fnd_value_attribute_types;  

CREATE OR REPLACE SYNONYM xxeai.GL_AFF_AWC_API_PKG FOR apps.GL_AFF_AWC_API_PKG;  

CREATE OR REPLACE SYNONYM xxeai.IBY_EXT_BANK_ACCOUNTS FOR apps.IBY_EXT_BANK_ACCOUNTS;

--ARA EDB363
CREATE OR REPLACE SYNONYM xxeai.fnd_application for APPLSYS.FND_APPLICATION#;
CREATE OR REPLACE SYNONYM xxeai.fnd_flex_values for APPLSYS.fnd_flex_values#;
CREATE OR REPLACE SYNONYM xxeai.fnd_flex_value_sets for APPLSYS.fnd_flex_value_sets#;
CREATE OR REPLACE SYNONYM xxeai.fnd_flex_values_tl for APPLSYS.fnd_flex_values_tl#;
CREATE OR REPLACE SYNONYM xxeai.fnd_columns  for APPLSYS.fnd_columns#;
CREATE OR REPLACE SYNONYM xxeai.fnd_descr_flex_column_usages for APPLSYS.fnd_descr_flex_column_usages#;
CREATE OR REPLACE SYNONYM XXEAI.FND_FLEX_VALUES_VL for APPS.FND_FLEX_VALUES_VL;
CREATE OR REPLACE SYNONYM XXEAI.FND_TABLES for APPLSYS.FND_TABLES#;

EXIT;


