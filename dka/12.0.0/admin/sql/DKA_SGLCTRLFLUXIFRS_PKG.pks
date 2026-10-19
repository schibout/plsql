CREATE OR REPLACE PACKAGE DKA_SGLCTRLFLUXIFRS_PKG
AS

----------------------------------------------------------------------------------------------            
-- $$                                                                                                     
-- CAPGEMINI                                                                            
-- PROJECT          : DALKIA Oracle Applications                                                          
-- NAME             : DKA_SGLCTRLFLUXIFRS.pkb                                                              
-- DESCRIPTION      : Package VECTOR IFRS Flew control                                                   
-- AUTHOR           : CDEL (CG)                                                                   
-- CREATION DATE    : 09/04/2008                                                                          
-- COMMENTS         : Execute on SQLPLUS with user APPS                                
--------------------------------------------------------------------------------------------              
-- MODIFICATION HISTORY                                                                         
-- Date       Who Description  
-- 15/11/2016 PBR MIgration R12
-- ---------- --- -------------------------------------------------------------------------               
-- 
--------------------------------------------------------------------------------------------

  gv_application_short_name   fnd_application.application_short_name%TYPE;
  gn_request_id               NUMBER;
  gv_description_F00          VARCHAR2(50);
  gv_description_F99          VARCHAR2(50);
  gv_list_argos_account       VARCHAR2(20);
  gn_set_of_books_id          NUMBER;
  gv_columns                  VARCHAR2(250);
  gv_nature                   VARCHAR2(30);
  gv_total                    VARCHAR2(30);
  gv_title                    VARCHAR2(100);
    
----------------------------------------------------------------------------
--  Name          : main
--  Description   : Request main procedure
--
--  PARAMETERS :
--    pv_veolia_code         Conso code
--    pv_period_name         Name of period
--    pv_errbuf   Input/Output          error message
--
--  RETURN VALUE :  
--     pn_retcode       :  Return code (0=normal, 1=warning, 2=error)
----------------------------------------------------------------------------
    PROCEDURE main (
        pv_errbuf        IN OUT   VARCHAR2,
        pn_retcode       IN OUT   NUMBER,
        pv_conso_code    IN       VARCHAR2, --R12
        pv_period_name   IN       VARCHAR2,
        pv_nature        IN       VARCHAR2
    );

        
END DKA_SGLCTRLFLUXIFRS_PKG;
/

SHOW ERROR

EXIT
