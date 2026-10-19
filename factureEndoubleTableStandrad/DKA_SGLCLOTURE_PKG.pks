----------------------------------------------------------------------------------------------
-- $$
-- CAPGEMINI
-- PROJET           : Hélios
-- NOM              : DKA_BANK_BRANCHES_V.vue
-- DESCRIPTION      : Création de la vue DKA_BANK_BRANCHES_V
--
-- AUTEUR           : Oussama BENHAYOUN
-- DATE DE CREATION : 26/09/2017
-- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
--------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- -------------------------------------------------------------------------
--------------------------------------------------------------------------------------------

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LA VUE DKA_BANK_BRANCHES_V
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE OR REPLACE FORCE EDITIONABLE VIEW "APPS"."DKA_BANK_BRANCHES_V" ("ROW_ID", "BANK_HOME_COUNTRY", "BANK_PARTY_ID", "BANK_NAME", "BANK_NAME_ALT", "SHORT_BANK_NAME", "BANK_NUMBER", "BRANCH_PARTY_ID", "BANK_BRANCH_NAME", "BANK_BRANCH_NAME_ALT", "BRANCH_NUMBER", "START_DATE", "END_DATE", "ADDRESS_LINE1", "ADDRESS_LINE2", "ADDRESS_LINE3", "ADDRESS_LINE4", "CITY", "STATE", "PROVINCE", "ZIP", "COUNTRY", "BANK_INSTITUTION_TYPE", "BANK_BRANCH_TYPE", "DESCRIPTION", "EFT_SWIFT_CODE", "EFT_USER_NUMBER", "EDI_ID_NUMBER", "PK_ID")
AS
  SELECT BranchParty.ROWID ROW_ID,
    BankOrgProfile.HOME_COUNTRY Bank_Home_Country,
    BankOrgProfile.PARTY_ID Bank_Party_Id,
    BankOrgProfile.ORGANIZATION_NAME Bank_Name,
    BankOrgProfile.ORGANIZATION_NAME_PHONETIC Bank_Name_Alt,
    BankOrgProfile.KNOWN_AS Short_Bank_Name,
    BankOrgProfile.BANK_OR_BRANCH_NUMBER Bank_Number,
    BranchParty.PARTY_ID Branch_Party_Id,
    BranchParty.PARTY_NAME Bank_Branch_Name,
    BranchParty.ORGANIZATION_NAME_PHONETIC Bank_Branch_Name_Alt,
    BranchOrgProfile.BANK_OR_BRANCH_NUMBER Branch_Number,
    BranchCA.start_date_active Start_Date,
    BranchCA.end_date_active End_Date,
    BranchParty.address1 Address_Line1,
    BranchParty.address2 Address_Line2,
    BranchParty.address3 Address_Line3,
    BranchParty.address4 Address_Line4,
    BranchParty.city City,
    BranchParty.state State,
    BranchParty.province Province,
    BranchParty.postal_code Zip,
    BranchParty.country Country,
    BankCA.class_code Bank_Institution_Type,
    BranchTypeCA.class_code Bank_Branch_Type,
    BranchParty.mission_statement Description,
    BranchCP.eft_swift_code EFT_Swift_Code,
    BranchCP.eft_user_number EFT_User_Number,
    EdiCP.edi_id_number EDI_ID_Number,
    BranchParty.PARTY_ID
  FROM HZ_ORGANIZATION_PROFILES BankOrgProfile,
    HZ_CODE_ASSIGNMENTS BankCA,
    HZ_PARTIES BranchParty,
    HZ_ORGANIZATION_PROFILES BranchOrgProfile,
    HZ_CODE_ASSIGNMENTS BranchCA,
    HZ_RELATIONSHIPS BRRel,
    HZ_CODE_ASSIGNMENTS BranchTypeCA,
    HZ_CONTACT_POINTS BranchCP,
    HZ_CONTACT_POINTS EdiCP
  WHERE SYSDATE BETWEEN TRUNC(BankOrgProfile.effective_start_date) AND NVL(TRUNC(BankOrgProfile.effective_end_date), SYSDATE+1)
  AND BankCA.CLASS_CATEGORY     = 'BANK_INSTITUTION_TYPE'
  AND BankCA.CLASS_CODE        IN ('BANK', 'CLEARINGHOUSE')
  AND BankCA.OWNER_TABLE_NAME   = 'HZ_PARTIES'
  AND (BankCA.STATUS            = 'A'
  OR BankCA.STATUS             IS NULL)
  AND BankCA.OWNER_TABLE_ID     = BankOrgProfile.PARTY_ID
  AND BranchParty.PARTY_TYPE    = 'ORGANIZATION'
  AND BranchParty.status        = 'A'
  AND BranchOrgProfile.PARTY_ID = BranchParty.PARTY_ID
  AND SYSDATE BETWEEN TRUNC(BranchOrgProfile.effective_start_date) AND NVL(TRUNC(BranchOrgProfile.effective_end_date), SYSDATE+1)
  AND BranchCA.CLASS_CATEGORY          = 'BANK_INSTITUTION_TYPE'
  AND BranchCA.CLASS_CODE             IN ('BANK_BRANCH', 'CLEARINGHOUSE_BRANCH')
  AND BranchCA.OWNER_TABLE_NAME        = 'HZ_PARTIES'
  AND (BranchCA.STATUS                 = 'A'
  OR BranchCA.STATUS                  IS NULL)
  AND BranchCA.OWNER_TABLE_ID          = BranchParty.PARTY_ID
  AND BankOrgProfile.PARTY_ID          = BRRel.OBJECT_ID
  AND BRRel.RELATIONSHIP_TYPE          = 'BANK_AND_BRANCH'
  AND BRRel.RELATIONSHIP_CODE          = 'BRANCH_OF'
  AND BRRel.STATUS                     = 'A'
  AND BRRel.SUBJECT_TABLE_NAME         = 'HZ_PARTIES'
  AND BRRel.SUBJECT_TYPE               = 'ORGANIZATION'
  AND BRRel.OBJECT_TABLE_NAME          = 'HZ_PARTIES'
  AND BRRel.OBJECT_TYPE                = 'ORGANIZATION'
  AND BRRel.SUBJECT_ID                 = BranchParty.PARTY_ID
  AND BranchTypeCA.CLASS_CATEGORY(+)   = 'BANK_BRANCH_TYPE'
  AND BranchTypeCA.PRIMARY_FLAG(+)     = 'Y'
  AND BranchTypeCA.OWNER_TABLE_NAME(+) = 'HZ_PARTIES'
  AND BranchTypeCA.OWNER_TABLE_ID(+)   = BranchParty.PARTY_ID
  AND BranchTypeCA.STATUS(+)           = 'A'
  AND BranchCP.owner_table_name(+)     = 'HZ_PARTIES'
  AND BranchCP.owner_table_id(+)       = BranchParty.party_id
  AND BranchCP.contact_point_type(+)   = 'EFT'
  AND BranchCP.status(+)               = 'A'
  AND EdiCP.owner_table_name(+)        = 'HZ_PARTIES'
  AND EdiCP.owner_table_id(+)          = BranchParty.party_id
  AND EdiCP.contact_point_type(+)      = 'EDI'
  AND EdiCP.status(+)                  = 'A';

SHOW ERROR

EXIT
