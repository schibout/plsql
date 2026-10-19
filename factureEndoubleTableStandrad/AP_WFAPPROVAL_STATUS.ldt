  ---------------------------------------------------------------------------------------------------------------
  -- CAPGEMINI
  -- PROJET            : Hélios
  -- NOM               : DKA_IAPLOADIMG_PARAM.sql
  -- DESCRIPTION       : DKA_IAPLOADIMG_PARAM : Script complément de paramétrage pour la création de la
  --                                             nouvelle entité de documents joints AP_INVOICES_INTERFACE
  --
  -- AUTEUR            : CDE (CAPGEMINI)
  -- DATE DE CREATION  : 10/03/2008
  -- DOC. ASSOCIEE     :
  -- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
  ---------------------------------------------------------------------------------------------------------------
  -- HISTORIQUE DES MODIFICATIONS
  -- Date       Qui Description
  -- ---------- --- ---------------------------------------------------------------------------------------------
  -- 02/09/2016 BDE Modification pour Hélios
  ---------------------------------------------------------------------------------------------------------------


UPDATE fnd_document_entities
SET entity_name = 'AP_INVOICES_INTERFACE'
  , pk1_column = 'INVOICE_ID'
WHERE data_object_code = 'AP_INVOICES_INTERFACE';


EXIT;
