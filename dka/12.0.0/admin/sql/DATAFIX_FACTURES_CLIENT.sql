
   
update ar.ra_customer_trx_all 
set interface_header_attribute3 = trx_number
where interface_header_attribute3 != trx_number;

/



  update AR_SYSTEM_PARAMETERS_ALL
   set ai_max_memory_in_bytes = 3145728,
       ai_acct_flex_key_left_prompt = 'PROJET_FI',
       last_update_date = sysdate,
       last_updated_by = 1301,
       last_update_login= -1;
	   
/

EXIT;