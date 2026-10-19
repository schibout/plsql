create or replace PACKAGE BODY DKA_SARTRFMVT
AS
-------------------------------------------------------------------------------------------------------------------
--  Nom           : CHERCHE_PERIOD
--  Description   : Recherche la période à fermer pour une application
--
--  PARAMETRES    :
--     pn_sob_id	number
--
--  VALEUR RETOURNEE :
--     pv_errbuf	varchar2
--     pd_start_date 	date
--     pd_end_date 	date
--     pd_period_name 	varchar2
-------------------------------------------------------------------------------------------------------------------
PROCEDURE cherche_period ( pn_sob_id		IN OUT NUMBER,
               --GL_DAT           IN date,
			   pv_errbuf 		OUT VARCHAR2,
			   pd_start_date 	OUT DATE,
			   pd_end_date 		OUT DATE,
			   pv_period_name 	OUT VARCHAR2 ) 
IS
	vd_start_date DATE;
	vd_end_date DATE;
	vv_period_name VARCHAR2(30);
	vv_err VARCHAR2(400);

BEGIN	   

	pv_errbuf := NULL;


  SELECT START_DATE,
         END_DATE,
         PERIOD_NAME 
  INTO   vd_start_date,
         vd_end_date,
         vv_period_name
  FROM  gl_period_statuses  
  WHERE START_DATE IN (

                      SELECT MIN(gps.start_date)
                    	FROM gl_period_statuses gps, GL_ACCESS_SET_LEDGERS gasl
                    	WHERE gps.application_id = 222
                     AND GASL.ACCESS_SET_ID = pn_sob_id
                     AND GASL.ledger_id = gps.ledger_id
					  --and gps.ledger_id = pn_sob_id
                      AND gps.closing_status = 'O'

                    	)
	AND application_id = 222
	AND closing_status = 'O'
	--AND SET_OF_BOOKS_ID = pn_sob_id
  AND rownum = 1 
	; 
		
	pd_start_date := vd_start_date;
	pd_end_date := vd_end_date;
	pv_period_name := vv_period_name;

	EXCEPTION
		WHEN OTHERS THEN
			vv_err := substr(SQLERRM,1,400);
			
			pv_errbuf := vv_err;



END;
--------------------------------------------------------------------------------------------
-- $$
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SARTRFMVT.pkb
-- DESCRIPTION       : DKA_SARTRFMVT package body :
---
--- AUTEUR           : Saloua HAHIOUI
--- DATE DE CREATION : 02/03/2020
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
--------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
--  Nom           : CHERCHE_NEXT_PERIOD
--  Description   : Recherche la période prochaine periode
--
--  PARAMETRES    :
--     pn_sob_id	number
--     pv_period_name	varchar2
--
--  VALEUR RETOURNEE :
--     pv_errbuf	varchar2
--     pd_start_date 	date
--     pd_end_date 	date
--     pd_period_name 	varchar2
-------------------------------------------------------------------------------------------------------------------
PROCEDURE cherche_next_period ( pn_sob_id		IN OUT NUMBER,
            pv_errbuf 		OUT VARCHAR2,
            pv_period_name 	IN VARCHAR2, -- OBE artf2086030
			pd_next_start_date 		 OUT DATE,
            pd_next_end_date 		   OUT DATE,
            pv_next_period_name  IN OUT VARCHAR2) 
IS
	vd_start_date DATE;
	vd_end_date DATE;
	vv_period_name VARCHAR2(30);
	vv_err VARCHAR2(400);

BEGIN	   

	pv_errbuf := NULL;

    SELECT DISTINCT start_date, end_date, period_name
	INTO vd_start_date, vd_end_date, vv_period_name
	FROM gl_period_statuses
	WHERE start_date IN ( SELECT end_date+1 
                        FROM gl_period_statuses 
                        WHERE period_name = pv_period_name
                        AND application_id = 222
                      )
	AND application_id = 222;

    pd_next_start_date  := vd_start_date;
	pd_next_end_date    := vd_end_date;
	pv_next_period_name := vv_period_name;


	EXCEPTION
		WHEN OTHERS THEN
			vv_err := substr(SQLERRM,1,400);
			pv_errbuf := vv_err;	

END;
-------------------------------------------------------------------------------------------------------------------
--  Nom           : main
--  Description   : Procédure principale enchaînant l'ensemble des autres procédures
--
--  PARAMETRES    :
--	pv_errbuf                       Entrée/Sortie           retour de message eventuel
--    	pn_retcode                      Sortie                  status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
-------------------------------------------------------------------------------------------------------------------
PROCEDURE main ( pv_errbuf	IN OUT varchar2,
		 pn_retcode 	OUT number	)
IS
vv_period_name		VARCHAR2(30) := NULL;
vv_next_period_name	    VARCHAR2(30);
vn_sob_id		NUMBER;
vv_mesg			VARCHAR2(4000);
vd_start_date		DATE;
vd_end_date		DATE;
vd_next_start_date	    DATE;
vd_next_end_date	      DATE;
vv_responsibility_name VARCHAR2(50);
vn_responsibility_id number;
vn_application_id number;
p_ledger_id       number;
NBR_ROW			  number;

cursor period_inv is
select to_date(gl_date||'01','YYYYMMDD') GL_DAT, pp.oa_status , pp.invoice_number,  pp.region ||   lpad( pp.company_code,4,'0') soc , pp.IARPAFAC_ID
  from DKA_IARPAFAC_INTERFACE pp
   where OA_status <> 'A' 
 --where pp.invoice_number= 'XTEM71'
 ;


BEGIN
    NBR_ROW := 0;
	vv_responsibility_name := 'TOUT_AR_ADMINISTRATEUR';
	SELECT fr.responsibility_id, fr.application_id
     INTO vn_responsibility_id, vn_application_id
     FROM fnd_responsibility fr
     WHERE fr.responsibility_key = vv_responsibility_name;
     --dka_tools_pkg.put_outdebug_message('-------------------------------------------'||'Responsabilité : '|| vn_responsibility_id || vn_application_id ); -- OBE
	 fnd_global.apps_initialize(fnd_global.user_id,vn_responsibility_id,vn_application_id);



	dka_tools_pkg.put_debug_message ('+------------------------------------------------+');
	dka_tools_pkg.put_debug_message ('| Recherche de la première période ouverte');
	dka_tools_pkg.put_debug_message ('+------------------------------------------------+');


	vn_sob_id := fnd_profile.VALUE ('GL_ACCESS_SET_ID');
	cherche_period(vn_sob_id,  vv_mesg,vd_start_date, vd_end_date, vv_period_name);
	
	IF vv_period_name IS NULL THEN
      Fnd_File.put_line (Fnd_File.LOG,'Il n''y a pas de période ouverte');
      Fnd_File.put_line (Fnd_File.OUTPUT,'Il n''y a pas de période ouverte');
      pn_retcode := 1;
	ELSE
			FOR c_tmp in period_inv  -- OBE artf2086030
			LOOP
				/*Begin
					select set_of_books_id into p_ledger_id
					  from hr_operating_units 
					where name like c_tmp.soc;
				exception
				when others then
					Fnd_File.put_line (Fnd_File.OUTPUT,'Problème pour recupérer la société ' || c_tmp.soc);
					pn_retcode := 1;
				end;
				*/
							
					if c_tmp.GL_DAT < vd_start_date then
				
						update  dka_iarpafac_interface 
						   SET GL_DATE = to_char(vd_start_date,'YYYYMM')  
						 WHERE invoice_number=c_tmp.invoice_number
						   and IARPAFAC_ID = c_tmp.IARPAFAC_ID
						;
						NBR_ROW := NBR_ROW + SQL%ROWCOUNT;
						COMMIT;
						Fnd_File.put_line (Fnd_File.LOG,'Transfert de la ligne '||c_tmp.IARPAFAC_ID||' de la pièce '||c_tmp.invoice_number||' vers la période ouverte : ' || vv_period_name);
					END IF;  
			END LOOP;
			Fnd_File.put_line (Fnd_File.OUTPUT,'Période sur laquelle les pièces ont été basculées : ' || vv_period_name);
	END IF;
	Fnd_File.put_line (Fnd_File.OUTPUT,'Nombre de lignes basculées :   ' || NBR_ROW);	
END;

END;
/

SHOW ERRORS;
EXIT