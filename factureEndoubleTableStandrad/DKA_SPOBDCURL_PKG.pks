create or replace PACKAGE DKA_IEOGLVEC01_PKG
AS

----------------------------------------------------------------------------------------------
-- $$
-- CAPGEMINI
-- PROJECT          : DALKIA Oracle Applications
-- NAME		        : DKA_IEOGLVEC01_PKG.pks
-- DESCRIPTION	    : Package VECTOR consolidation
-- AUTHOR	        : CDEL (CG)
-- CREATION DATE    : 19/10/2006
-- COMMENTS         : Execute on SQLPLUS with user APPS
--------------------------------------------------------------------------------------------
-- MODIFICATION HISTORY
-- Date       Who Description
-- ---------- --- -------------------------------------------------------------------------
-- 07/03/07   CDE Add function get_gl_period_end_date
-- 03/05/07   CDE Dependent segment managing for UK
-- 28/05/07   CDE Add function get_partner_code
-- 04/01/80   EMA Add variable gn_request_id
-- 23/11/16   PBR Migration R12 Ajout d'une variable globale avec le ledger_id
--------------------------------------------------------------------------------------------

  TYPE  IdTabTyp      IS TABLE OF NUMBER(15) INDEX BY BINARY_INTEGER;
  gv_application_short_name   fnd_application.application_short_name%TYPE;
  gn_request_id               NUMBER;
  
  GN_LEDGER_ID  GL_LEDGERS.LEDGER_ID%TYPE; --R12

-----------------------------------------------------------------
--  Nom           : GET_MESSAGE
--  Description   : Procedure to find messages in fnd_new_messages
--
--  PARAMETERS :
--      pv_application           Input      Application code
--      pv_name                  Input      Message name
--      pv_tokenx                Input      Parameter names in message
--      pv_valuex                Input      Parameter values in message
--
--  RETURN VALUE :
--     Description       : Message
-----------------------------------------------------------------

    FUNCTION get_message (
        pv_application   IN   VARCHAR2,
        pv_name          IN   VARCHAR2,
        pv_token1        IN   VARCHAR2 DEFAULT NULL,
        pv_value1        IN   VARCHAR2 DEFAULT NULL,
        pv_token2        IN   VARCHAR2 DEFAULT NULL,
        pv_value2        IN   VARCHAR2 DEFAULT NULL,
        pv_token3        IN   VARCHAR2 DEFAULT NULL,
        pv_value3        IN   VARCHAR2 DEFAULT NULL,
        pv_token4        IN   VARCHAR2 DEFAULT NULL,
        pv_value4        IN   VARCHAR2 DEFAULT NULL,
        pv_token5        IN   VARCHAR2 DEFAULT NULL,
        pv_value5        IN   VARCHAR2 DEFAULT NULL,
        pv_token6        IN   VARCHAR2 DEFAULT NULL,
        pv_value6        IN   VARCHAR2 DEFAULT NULL,
        pv_token7        IN   VARCHAR2 DEFAULT NULL,
        pv_value7        IN   VARCHAR2 DEFAULT NULL,
        pv_token8        IN   VARCHAR2 DEFAULT NULL,
        pv_value8        IN   VARCHAR2 DEFAULT NULL,
        pv_token9        IN   VARCHAR2 DEFAULT NULL,
        pv_value9        IN   VARCHAR2 DEFAULT NULL,
        pv_token10       IN   VARCHAR2 DEFAULT NULL,
        pv_value10       IN   VARCHAR2 DEFAULT NULL
    )
        RETURN VARCHAR2;


-----------------------------------------------------------------
--  Name          : PUT_OUT_HEADER
--  Description   : Output file Header Initialisation
--
--  PARAMETERS :
--     N/A
--
--  RETURN VALUE :
--     N/A
-----------------------------------------------------------------
    PROCEDURE put_out_header;


-----------------------------------------------------------------
--  Name          : GET_INSTANCE_NAME
--  Description   : Function to find the name of gl_set_of_books
--
--  PARAMETERS :
--     pn_gl_set_of_bks_id      gl_set_of_books_id
--
--  RETURN VALUE :
--     vv_instance_name      :  Instance name
-----------------------------------------------------------------
    FUNCTION get_instance_name (
        pn_gl_set_of_bks_id   IN   NUMBER
    )
        RETURN VARCHAR2;


-----------------------------------------------------------------
--  Name          : GET_APPLICATION_SHORT_NAME
--  Description   : Function to find the application short name of program request
--
--  PARAMETERS :
--     pn_appli_id      application_id
--
--  RETURN VALUE :
--     vv_application_short_name      :  application short name
-----------------------------------------------------------------
    FUNCTION get_application_short_name (
        pn_appli_id   IN   NUMBER
    )
        RETURN VARCHAR2;


-----------------------------------------------------------------
--  Name          : GET_SEGMENT_NUM
--  Description   : Function to find the segment number of the key link to qualifier
--                  in parameter
--
--  PARAMETERS :
--     pv_qualifier      qualifier code
--
--  RETURN VALUE :
--     segment_num       :  Key segment number
-----------------------------------------------------------------
    FUNCTION get_segment_num (
        pv_qualifier   IN   VARCHAR2
    )
        RETURN VARCHAR2;


-----------------------------------------------------------------
--  Name           : GET_QUAL_FLEX_VALUE_SET_ID
--  Description    : Function to find flex_value_set_id link to qualifier in parameter
--
--
--  PARAMETERS :
--     pv_qualifier      qualifier code
--
--  RETURN VALUE :
--     vn_flex_value_set_id       :  value set id
-----------------------------------------------------------------
    FUNCTION get_qual_flex_value_set_id (
        pv_qualifier   IN   VARCHAR2
    )
        RETURN NUMBER;


-----------------------------------------------------------------
--  Name           : GET_QUAL_FLEX_VALUE_SET_NAME
--  Description    : Function to find flex_value_set_name link to qualifier in parameter
--
--
--  PARAMETERS :
--     pv_qualifier      qualifier code
--
--  RETURN VALUE :
--     vn_flex_value_set_name      :  value set name
-----------------------------------------------------------------
    FUNCTION get_qual_flex_value_set_name (
        pv_qualifier   IN   VARCHAR2
    )
        RETURN VARCHAR2;

-----------------------------------------------------------------
--  Name           : GET_QUAL_VALUE_SET_VAL_TYPE
--  Description    : Function to find validation type of the flex value set
--                   link to qualifier in parameter
--
--
--  PARAMETERS :
--     pv_qualifier      qualifier code
--
--  RETURN VALUE :
--     vv_validation_type      :  validation type of the flex value set (D or I)
-----------------------------------------------------------------
    FUNCTION get_qual_value_set_val_type (
        pv_qualifier   IN   VARCHAR2
    )
        RETURN VARCHAR2;

-----------------------------------------------------------------
--  Name           : GET_QUAL_FLEX_VALUE_SET_PARENT
--  Description    : Function to find parent flex set of the flex value set
--                   link to qualifier in parameter
--
--
--  PARAMETERS :
--     pv_qualifier      qualifier code
--
--  RETURN VALUE :
--     vn_parent_flex_value_set_id      :  parent of the flex value set dependent
-----------------------------------------------------------------
    FUNCTION get_qual_flex_value_set_parent (
        pv_qualifier   IN   VARCHAR2
    )
        RETURN VARCHAR2;

-----------------------------------------------------------------
--  Name          : GET_CUF_ATTRIBUTE_NUM
--  Description   : Function to find attribute number link to a qualifier
--                  in parameter
--
--  PARAMETRES :
--     pv_qualifier           qualifier code
--     pv_code_attribute      attribute code
--
--  VALEUR RETOURNEE :
--     attribute_num       :  attribute number in CUF
-----------------------------------------------------------------
    FUNCTION get_cuf_attribute_num (
        pv_qualifier        IN   VARCHAR2,
        pv_code_attribute   IN   VARCHAR2
    )
        RETURN VARCHAR2;


-----------------------------------------------------------------
--  Name          : GET_CUF_ATTRIBUTE_VALUE
--  Description   : Function to find attribute value link to segment in parameter
--
--
--  PARAMETRES :
--     pv_value_set_name      set value name
--     pv_code_attribute      attribute code
--
--  VALEUR RETOURNEE :
--     attribute_num       :  attribute number in CUF
-----------------------------------------------------------------
    FUNCTION get_cuf_attribute_value (
        pv_qualifier        IN   VARCHAR2,
        pv_flex_value       IN   VARCHAR2,
        pv_code_attribute   IN   VARCHAR2
    )
        RETURN VARCHAR2;

-----------------------------------------------------------------
--  Name          : GET_CUF_ATTRIBUTE_VALUE_DEP
--  Description   : Function to find attribute value of descriptive flexfield link to segment in parameter
--                   and segment parent in parameter
--
--  PARAMETERS :
--     pv_qualifier           qualifier code
--     pv_flex_value          flex value
--     pv_parent_flex_value   parent flex value
--     pv_code_attribute      attribute code
--
--  RETURN VALUE :
--     attribute_value       :  value of the attribute
-----------------------------------------------------------------
    FUNCTION get_cuf_attribute_value_dep (
        pv_qualifier         IN   VARCHAR2,
        pv_flex_value        IN   VARCHAR2,
        pv_parent_flex_value IN   VARCHAR2,
        pv_code_attribute    IN   VARCHAR2
    )
        RETURN VARCHAR2;

-----------------------------------------------------------------
--  Name          : GET_VEOLIA_CODE
--  Description   : Function to find veolia code link to a balancing segment value
--
--
--  PARAMETERS :
--     pv_flex_value          flex value
--     pv_op_unit             operating unit value
--
--  RETURN VALUE :
--     attribute_value       :  value of the attribute
-----------------------------------------------------------------
    FUNCTION get_conso_code (
        pv_flex_value      IN   VARCHAR2,
        pv_op_unit         IN   VARCHAR2
    )
        RETURN VARCHAR2;


-----------------------------------------------------------------
--  Name          : GET_PARTNER_CODE
--  Description   : Function to find partner code link to a partner segment value
--
--
--  PARAMETERS :
--     pv_flex_value          flex value
--     pv_op_unit             operating unit value
--
--  RETURN VALUE :
--     attribute_value       :  value of the attribute
-----------------------------------------------------------------
    FUNCTION get_partner_code (
        pv_seg_partner       IN   VARCHAR2,
        pv_op_unit           IN   VARCHAR2
    )
        RETURN VARCHAR2;


-----------------------------------------------------------------
--  Name          : QUALIFIER_EXISTS
--  Description   : Function to find if a qualifier is setup
--
--  PARAMETERS :
--     pv_qualifier      qualifier code
--
--  RETURN VALUE :
--     vv_exist       :  OK/KO
-----------------------------------------------------------------
    FUNCTION qualifier_exists (
        pv_qualifier   IN   VARCHAR2
    )
        RETURN VARCHAR2;


-----------------------------------------------------------------
--  Name          : ATTRIBUTE_EXISTS
--  Description   : Function to find if an attribute is setup to attribute code in parameter
--
--  PARAMETERS :
--     pv_qualifier      qualifier code
--     pv_code_attribute attribute code
--
--  RETURN VALUE :
--     vv_exists       :  OK/KO
-----------------------------------------------------------------
    FUNCTION attribute_exists (
        pv_qualifier        IN   VARCHAR2,
        pv_code_attribute   IN   VARCHAR2
    )
        RETURN VARCHAR2;


-----------------------------------------------------------------
--  Name          : PROFILE_OPTION_EXISTS
--  Description   : Function to find if an profile option is setup and with a value
--
--  PARAMETERS :
--     pv_profile_option      profile option code
--
--  RETURN VALUE :
--     vv_exists       :  OK/KO
-----------------------------------------------------------------
    FUNCTION profile_option_exists (
        pv_profile_option        IN   VARCHAR2
    )
        RETURN VARCHAR2;

-----------------------------------------------------------------
--  Name          : GET_GL_PERIOD_END_DATE
--  Description   : Function to return end_date of a gl period
--
--  PARAMETERS :
--     pv_period_name      period name
--
--  RETURN VALUE :
--     vv_end_date       :  date
-----------------------------------------------------------------
    FUNCTION get_gl_period_end_date (
        pv_period_name        IN   VARCHAR2
    )
        RETURN DATE;


----------------------------------------------------------------------------------------------------------------------
--  Nom           : main
--  Description   : Procédure principale du traitement
--
--PARAMETRES :
--  pv_errbuf   Entrée/Sortie          message d'erreur
--  VALEUR RETOURNEE :  pn_retcode
--Valeurs possibles : 0=normal, 1=warning, 2=erreur
----------------------------------------------------------------------------------------------------------------------
    PROCEDURE main (
        pv_errbuf        IN OUT   VARCHAR2,
        pn_retcode       IN OUT   NUMBER,
        pv_conso_code   IN       VARCHAR2,
        pv_period_name   IN       VARCHAR2
    );


----------------------------------------------------------------------------
--  Name          : control
--  Description   : Request control procedure
--
--  PARAMETERS :
--    pv_errbuf   Input/Output          error message
--
--  RETURN VALUE :
--     pn_retcode       :  Return code (0=normal, 1=warning, 2=error)
----------------------------------------------------------------------------
    PROCEDURE control (
        pv_errbuf        IN OUT   VARCHAR2,
        pn_retcode       IN OUT   NUMBER
    );


END DKA_IEOGLVEC01_PKG;
/
SHOW ERROR

EXIT
