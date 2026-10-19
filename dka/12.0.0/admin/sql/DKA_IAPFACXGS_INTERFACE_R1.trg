REM Copyright (c) 2013 Oracle Corporation, All Rights Reserved 
REM $Header$ 
REM DKA_IAPFACXGS_INTERFACE_X1.sql 
REM   Update DKA_IAPFACXGS_INTERFACE.PRENBFAC

SET VERIFY OFF; 
WHENEVER SQLERROR EXIT FAILURE ROLLBACK; 
WHENEVER OSERROR EXIT FAILURE ROLLBACK; 

create or replace trigger DKA_IAPFACXGS_INTERFACE_R1 
  before insert or update or delete on DKA.DKA_IAPFACXGS_INTERFACE 
  for each row reverse crossedition 
  disable 
begin 
  if inserting or updating then 
    -- can only insert a max of 2 characters into the
    -- old column.
    :new.PRENBFAC := substr(:new.PRENBFAC#1, 1, 2);
  end if;
end; 
/ 

commit; 
exit; 
