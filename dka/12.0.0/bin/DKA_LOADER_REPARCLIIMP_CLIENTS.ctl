--------------------------------------------------------------------------------------------
-- FILENAME
--   DKA_LOADER_REPARCLIIMP_CLIENTS.ctl   V1.0
--
-- AUTEUR
--   Capgemini
--
-- DESCRIPTION
--   Chargement de la table temporaire DKA_CLIENTS_TMP
--
-- USAGE
--   DKA_LOADER_REPARCLIIMP_CLIENTS.ctl
--
-- NOTES
--
---------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
---------------------------------------------------------------------------------------------
-- Version   Date         Qui Description
---------- -------------- --- ---------------------------------------------------------------
-- V1.0    06/05/2016     OBE Creation
---------------------------------------------------------------------------------------------

OPTIONS (SKIP=1)
LOAD DATA
APPEND
INTO TABLE DKA_CLIENTS_TMP
FIELDS TERMINATED BY '|'
TRAILING NULLCOLS
(
customer_name			                  CHAR NULLIF (customer_name= BLANKS)
,customer_number			              CHAR NULLIF (customer_number= BLANKS)
,intracom_number			              CHAR NULLIF (intracom_number= BLANKS)
,customer_status			              CHAR NULLIF (customer_status= BLANKS)
,customer_category		              CHAR NULLIF (customer_category= BLANKS)
,customer_class			                CHAR NULLIF (customer_class= BLANKS)
,Nom1			                          CHAR NULLIF (Nom1= BLANKS)
,Nom2			                          CHAR NULLIF (Nom2= BLANKS)
,Address1			                      CHAR NULLIF (Address1= BLANKS)
,Address2			                      CHAR NULLIF (Address2= BLANKS)
,CUSTOMER_TYPE			                CHAR NULLIF (CUSTOMER_TYPE= BLANKS)
,City				                        CHAR NULLIF (City= BLANKS)
,postal_code		                    CHAR NULLIF (postal_code= BLANKS)
,country				                    CHAR NULLIF (country =BLANKS)
,address_status			                CHAR NULLIF (address_status= BLANKS)
,profil_Class			                  CHAR NULLIF (profil_Class= BLANKS)
,partner_code			                  CHAR NULLIF (partner_code= BLANKS)
,LOCATION			                      CHAR NULLIF (LOCATION= BLANKS)
,Code_client_destinataire	          CHAR NULLIF (Code_client_destinataire= BLANKS)
,Adresse_client_destinataire        CHAR NULLIF (Adresse_client_destinataire= BLANKS)
,recipient_only_flag		            CHAR NULLIF (recipient_only_flag= BLANKS)
,ANAEL_ref			                    CHAR NULLIF (ANAEL_ref= BLANKS)
,Society				                    CHAR NULLIF (Society= BLANKS)
,INSERT_UPDATE_FLAG		              CHAR NULLIF (INSERT_UPDATE_FLAG= BLANKS)
,ETL_status			                    CHAR NULLIF (ETL_status= BLANKS)
,bank_name			                    CHAR NULLIF (bank_name= BLANKS)
,bank_num			                      CHAR NULLIF (bank_num= BLANKS)
,bank_branch_name			              CHAR NULLIF (bank_branch_name= BLANKS)
,bank_number			                  CHAR NULLIF (bank_number= BLANKS)
,country_bank			                  CHAR NULLIF (country_bank= BLANKS)
,bank_account_name			            CHAR NULLIF (bank_account_name= BLANKS)
,bank_account_num			              CHAR NULLIF (bank_account_num= BLANKS)
,currency_code			                CHAR NULLIF (currency_code= BLANKS)
,iban_number			                  CHAR NULLIF (iban_number= BLANKS)
,check_digits			                  CHAR NULLIF (check_digits= BLANKS)
,bank_start_date			              DATE 'YYYY/MM/DD' NULLIF (bank_start_date= BLANKS)
,bank_primary_flag			            CHAR NULLIF (bank_primary_flag= BLANKS)
,CDG			                          CHAR NULLIF (CDG= BLANKS)
,CUSTOMER_DKA_BANK_NAME             CHAR NULLIF (CUSTOMER_DKA_BANK_NAME= BLANKS)
,START_DATE                         DATE 'YYYY/MM/DD' NULLIF (START_DATE=BLANKS)
,RUM                                CHAR NULLIF (RUM= BLANKS)
,last_name			                    CHAR NULLIF (last_name= BLANKS)
,first_name			                    CHAR NULLIF (first_name= BLANKS)
,contact_number			                CHAR NULLIF (contact_number= BLANKS)
,orig_system_reference_ctc			    CHAR NULLIF (orig_system_reference_ctc= BLANKS)
,PHONE_NUMBER 			                CHAR NULLIF (PHONE_NUMBER= BLANKS)
,phone_type 			                  CHAR NULLIF (phone_type= BLANKS)
,contact_point_type 			          CHAR NULLIF (contact_point_type= BLANKS)
,orig_system_reference_ph 			    CHAR NULLIF (orig_system_reference_ph= BLANKS)
,SIRET         			                CHAR NULLIF (SIRET= BLANKS)
,receipt_method_name			          CHAR NULLIF (receipt_method_name= BLANKS)
,receipt_start_date			            DATE 'YYYY/MM/DD' NULLIF (receipt_start_date= BLANKS)
,receipt_primary_flag			          CHAR NULLIF (receipt_primary_flag= BLANKS)
,payment_terms			                CHAR NULLIF (payment_terms= BLANKS)
,GL_ID_REC                          INTEGER EXTERNAL NULLIF (GL_ID_REC= BLANKS)
,GL_ID_REV			                    INTEGER EXTERNAL NULLIF (GL_ID_REV= BLANKS)
,SOC				                        CHAR NULLIF (SOC= BLANKS)
,LOGICAL_LINE_NUM                   RECNUM
,CREATION_DATE                      SYSDATE
,CREATED_BY                         CONSTANT '!USER_ID!'
,LAST_UPDATE_DATE                   SYSDATE
,LAST_UPDATED_BY                    CONSTANT '!USER_ID!'
,LOAD_REQUEST_ID                    CONSTANT '!LOAD_REQUEST_ID!'
)

--Fin