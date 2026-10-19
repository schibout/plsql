create or replace TRIGGER "APPS"."DKA_FND_HTTP_TICKETS_BI" before insert  on "APPLSYS"."FND_HTTP_TICKETS" for each row
 begin
   if :new.operation='GFM_TICKET' then
     :new.end_date:=add_months(sysdate,120); -- on ajoute 10 ans
   end if;
end;
/
exit
