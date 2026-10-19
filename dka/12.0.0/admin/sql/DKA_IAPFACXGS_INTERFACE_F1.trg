REM Copyright (c) 2013 Oracle Corporation, All Rights Reserved 
REM $Header$ 
REM DKA_IAPFACXGS_INTERFACE_X1.sql 
REM   Update DKA_IAPFACXGS_INTERFACE.PRENBFAC

SET VERIFY OFF; 
WHENEVER SQLERROR EXIT FAILURE ROLLBACK; 
WHENEVER OSERROR EXIT FAILURE ROLLBACK; 

create or replace trigger DKA_IAPFACXGS_INTERFACE_F1 
  before insert or update or delete on DKA.DKA_IAPFACXGS_INTERFACE 
  for each row forward crossedition 
  disable 
begin 
  if inserting or updating then 
    :new.PRENBFAC#1 := :new.PRENBFAC ;
  end if;
end; 
/ 

commit; 
exit; 
