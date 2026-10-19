 create or replace PACKAGE BODY DKA_FUSGLCTRLPR_PKG IS
--------------------------------------------------------------------------------------------
-- F-- $$
-- Capgemini
-- Projet           : DALKIA Oracle Applications
-- Nom              : DKA_FUSGLCTRLPR_PKG.pkb
-- Description      : DKA_FUSGLCTRLPR_PKG package body
-- Auteur           : S.HAHIOUI(Capgemini)
-- Date de création : 11/10/2019
-- Doc. associée    :
-- Commentaire      : à exécuter sous SQLPLUS avec l'utilisateur APPS
---------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
---------------------------------------------------------------------------------------------
-- Date           Qui Description
-- -------------- --- ---------------------------------------------------------------
------------------------------------------------------------------------------------
-- PARAMETRES       : pv_errbuf      Sortie Message d'erreur
--                    pn_retcode     Sortie Code Retour de la procédure
--                                   '0' : Normal
--                                   '1' : Avertissement
--                                   '2' : Erreur
--                  
-- VALEUR RETOURNEE :
-- Description       :
-- Valeurs possibles :
------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PRIVEES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

/*
 *************************************************************************
 * PROCEDURE NAME : main
 * 
 * DESCRIPTION
 *  Procédure principale
 *
 * PARAMETERS
 * ==========
 * NAME              DESCRIPTION
 * ----------------- ------------------------------------------------------
 * p_errbuf          Retour de message éventuel
 * p_retcode         Statut du traitement en sortie
 ************************************************************************
 */

 PROCEDURE main(p_errbuf     IN    OUT VARCHAR2,
                p_retcode          OUT NUMBER
             
              )
 IS
	v_current_program_unit     VARCHAR2(30);
    v_errbuf                   VARCHAR2(2500);
    v_retcode                  NUMBER;
    Erreur_Programme           EXCEPTION;
    v_warning                  BOOLEAN := FALSE;
	org_absorbé				   VARCHAR2(30);
	org_absorbé_1			   VARCHAR2(30);
	v_period                   varchar(30);
	v_RG_01                    NUMBER;
	v_RG_02                    NUMBER;
	v_RG_03                    NUMBER;
	v_RG_04                    NUMBER;
	v_RG_05                    NUMBER;
	test_ok                    boolean;
	
	CURSOR cur_tab_trans IS
	SELECT   DSTL.param1_value absorbe , 
	         DSTL.return_value absorbante,
			 DSTL.start_date START_DATE
			FROM
					   HR_ORGANIZATION_UNITS HOU,
					   DKA_STRANSCO_LINES DSTL,
					   DKA_STRANSCO_HEADERS DSTH
			WHERE
					   DSTL.SET_ID = DSTH.SET_ID
					   AND HOU.NAME = DSTL.PARAM1_VALUE
					   AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
					   AND DSTL.ENABLE = 'Y'
					   AND NVL(DSTL.END_DATE,TRUNC(SYSDATE) ) >= TRUNC(SYSDATE)
					  
                    ;
	CURSOR per_close_ok IS
			SELECT    distinct substr(DSTL.PARAM1_VALUE,4,7) ABSORBEE
			FROM	   HR_OPERATING_UNITS HOU,
					   DKA_STRANSCO_LINES DSTL,
					   DKA_STRANSCO_HEADERS DSTH
			WHERE
					   DSTL.SET_ID = DSTH.SET_ID
					   AND HOU.NAME = DSTL.PARAM1_VALUE
                       AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
					   AND DSTL.ENABLE = 'Y'
					   AND NVL(DSTL.END_DATE,TRUNC(SYSDATE) ) >= TRUNC(SYSDATE)
					   and (not exists (select 1
									from  gl_period_statuses gl
									where gl.CLOSING_STATUS <>'C'
									and   HOU.SET_OF_BOOKS_ID =ledger_id
									and   application_id in (200,222,101,201)
									and   gl.period_name = to_char(add_months(DSTL.START_DATE,-1),'MON-YY')
									and   rownum < 2)
						
						and not  exists (select 1 from       PA_PERIODS_ALL  pap 
										where pap.org_id                  = HOU.organization_id 
										AND STATUS <> 'C'
										AND pap.period_name  = to_char(add_months(DSTL.START_DATE,-1),'MON-YY')
										and   rownum < 2)
						and  (select to_char(to_date(period_name,'MON-YY'),'YYYYMM') PERIODE_FA_EN_COURS
										from fa_deprn_periods fadp
										where substr(book_type_code,1,4) = substr(HOU.name,4,4)
										and period_close_date is null
										and   rownum < 2)	> = TO_CHAR(DSTL.START_DATE,'YYYYMM'));
                            
	
	CURSOR per_close_ko IS
			SELECT    distinct substr(DSTL.PARAM1_VALUE,4,7) ABSORBEE
			FROM	   HR_OPERATING_UNITS HOU,
					   DKA_STRANSCO_LINES DSTL,
					   DKA_STRANSCO_HEADERS DSTH
			WHERE
					   DSTL.SET_ID = DSTH.SET_ID
					   AND HOU.NAME = DSTL.PARAM1_VALUE
                       AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
					   AND DSTL.ENABLE = 'Y'
					   AND NVL(DSTL.END_DATE,TRUNC(SYSDATE) ) >= TRUNC(SYSDATE)
					   and (exists (select 1
									from  gl_period_statuses gl
									where gl.CLOSING_STATUS <>'C'
									and   HOU.SET_OF_BOOKS_ID =ledger_id
									and   application_id in (200,222,101,201)
									and   gl.period_name = to_char(add_months(DSTL.START_DATE,-1),'MON-YY')
									and   rownum < 2)
						
						OR  exists (select 1 from       PA_PERIODS_ALL  pap 
										where pap.org_id                  = HOU.organization_id 
										AND STATUS <> 'C'
										AND pap.period_name  = to_char(add_months(DSTL.START_DATE,-1),'MON-YY')
										and   rownum < 2)
						OR ((select to_char(to_date(period_name,'MON-YY'),'YYYYMM') PERIODE_FA_EN_COURS
										from fa_deprn_periods fadp
										where substr(book_type_code,1,4) = substr(HOU.name,4,4)
										and period_close_date is null
										and   rownum < 2)	< TO_CHAR(DSTL.START_DATE,'YYYYMM')) );
                            
								  
	CURSOR per_ouvert_ok IS
			SELECT     distinct substr(DSTL.PARAM1_VALUE,4,7)  	SOCIETE
			           ,gl.period_name		PERIODE
			FROM	   HR_OPERATING_UNITS HOU,
					   DKA_STRANSCO_LINES DSTL,
					   DKA_STRANSCO_HEADERS DSTH,
					   GL_PERIOD_STATUSES GL
			WHERE
					   DSTL.SET_ID = DSTH.SET_ID
					   AND HOU.NAME = DSTL.PARAM1_VALUE
                       AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
					   AND DSTL.ENABLE = 'Y'
					   AND HOU.SET_OF_BOOKS_ID =ledger_id
					   AND application_id = 101
					   AND gl.period_name = to_char(DSTL.START_DATE,'MON-YY')
					   AND NVL(DSTL.END_DATE,TRUNC(SYSDATE) ) >= TRUNC(SYSDATE)
					   and gl.CLOSING_STATUS  = 'O'
					   ;
					   
	CURSOR per_ouvert_ko IS
			SELECT    distinct  substr(DSTL.PARAM1_VALUE,4,7)  	SOCIETE
			           ,gl.period_name		PERIODE
			FROM	   HR_OPERATING_UNITS HOU,
					   DKA_STRANSCO_LINES DSTL,
					   DKA_STRANSCO_HEADERS DSTH,
					   GL_PERIOD_STATUSES GL
			WHERE
					   DSTL.SET_ID = DSTH.SET_ID
					   AND HOU.NAME = DSTL.PARAM1_VALUE
                       AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
					   AND DSTL.ENABLE = 'Y'
					   AND HOU.SET_OF_BOOKS_ID =ledger_id
					   AND application_id = 101
					   AND gl.period_name = to_char(DSTL.START_DATE,'MON-YY')
					   AND NVL(DSTL.END_DATE,TRUNC(SYSDATE) ) >= TRUNC(SYSDATE)
					   and gl.CLOSING_STATUS <> 'O';
					   
	CURSOR per_ouvert_abs_ok IS
			SELECT    distinct  substr(DSTL.RETURN_VALUE,4,7)  	SOCIETE
			           ,gl.period_name		PERIODE
			FROM	   HR_OPERATING_UNITS HOU,
					   DKA_STRANSCO_LINES DSTL,
					   DKA_STRANSCO_HEADERS DSTH,
					   GL_PERIOD_STATUSES GL
			WHERE
					   DSTL.SET_ID = DSTH.SET_ID
					   AND HOU.NAME = DSTL.RETURN_VALUE
                       AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
					   AND DSTL.ENABLE = 'Y'
					   AND HOU.SET_OF_BOOKS_ID =ledger_id
					   AND application_id = 101
					   AND gl.period_name = to_char(DSTL.START_DATE,'MON-YY')
					   AND NVL(DSTL.END_DATE,TRUNC(SYSDATE) ) >= TRUNC(SYSDATE)
					   and gl.CLOSING_STATUS  = 'O';
					   
	CURSOR per_ouvert_abs_ko IS
			SELECT    distinct  substr(DSTL.RETURN_VALUE,4,7)  	SOCIETE
			           ,gl.period_name		PERIODE
			FROM	   HR_OPERATING_UNITS HOU,
					   DKA_STRANSCO_LINES DSTL,
					   DKA_STRANSCO_HEADERS DSTH,
					   GL_PERIOD_STATUSES GL
			WHERE
					   DSTL.SET_ID = DSTH.SET_ID
					   AND HOU.NAME = DSTL.RETURN_VALUE
                       AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
					   AND DSTL.ENABLE = 'Y'
					   AND HOU.SET_OF_BOOKS_ID =ledger_id
					   AND application_id = 101
					   AND gl.period_name = to_char(DSTL.START_DATE,'MON-YY')
					   AND NVL(DSTL.END_DATE,TRUNC(SYSDATE) ) >= TRUNC(SYSDATE)
					   and gl.CLOSING_STATUS  <> 'O';	
					   
	CURSOR controle_impu_ok IS
		    select distinct substr(HR.NAME,4,7) ABSORBEE 
	        from 	
		   		DKA_STRANSCO_LINES DSTL,
		   		DKA_STRANSCO_HEADERS DSTH,
		   		HR_OPERATING_UNITS HR
		    where DSTL.SET_ID = DSTH.SET_ID
		      AND HR.NAME = DSTL.PARAM1_VALUE
		      AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
		      AND DSTL.ENABLE = 'Y'
		      AND NVL(DSTL.END_DATE,TRUNC(SYSDATE) ) >= TRUNC(SYSDATE)
              and not exists (select 1 from GL_JE_HEADERS GL 
								where HR.set_of_books_id=gl.ledger_id
								and to_date(to_char(to_date(period_name,'MON-YY'),'DD-MM-YYYY'),'DD-MM-YYYY') <= DSTL.START_DATE
								and status 		<>'P'
								and rownum < 2
							)
		      ;
			  
	CURSOR controle_impu_ko IS
		   select distinct substr(HR.NAME,4,7) ABSORBEE 
	        from 	
		   		DKA_STRANSCO_LINES DSTL,
		   		DKA_STRANSCO_HEADERS DSTH,
		   		HR_OPERATING_UNITS HR
		    where DSTL.SET_ID = DSTH.SET_ID
		      AND HR.NAME = DSTL.PARAM1_VALUE
		      AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
		      AND DSTL.ENABLE = 'Y'
		      AND NVL(DSTL.END_DATE,TRUNC(SYSDATE) ) >= TRUNC(SYSDATE)
              and exists (select 1 from GL_JE_HEADERS GL 
							where HR.set_of_books_id=gl.ledger_id
							and to_date(to_char(to_date(period_name,'MON-YY'),'DD-MM-YYYY'),'DD-MM-YYYY') <= DSTL.START_DATE
							and status 		<>'P'
							and rownum < 2
						)
		      ;
	
	CURSOR controle_contre_pass_ok IS
		    select distinct substr(HR.NAME,4,7) ABSORBEE 
	        from 	
		   		DKA_STRANSCO_LINES DSTL,
		   		DKA_STRANSCO_HEADERS DSTH,
		   		HR_OPERATING_UNITS HR
		    where DSTL.SET_ID = DSTH.SET_ID
		      AND HR.NAME = DSTL.PARAM1_VALUE
		      AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
		      AND DSTL.ENABLE = 'Y'
		      AND NVL(DSTL.END_DATE,TRUNC(SYSDATE) ) >= TRUNC(SYSDATE)
              and not exists (select 1
							 from GL_JE_HEADERS GL 
							 where HR.set_of_books_id=gl.ledger_id
							  and period_name      = to_char(add_months(DSTL.START_DATE,-1),'MON-YY')
							  and status 	       = 'P'
                              and ACCRUAL_REV_FLAG ='Y'
                              and ACCRUAL_REV_STATUS is null
                              and ACCRUAL_REV_PERIOD_NAME = to_char(DSTL.START_DATE,'MON-YY')
							  and rownum < 2
						   )
		      ;
			  
	CURSOR controle_contre_pass_ko IS
		   select distinct substr(HR.NAME,4,7) ABSORBEE 
	        from 	
		   		DKA_STRANSCO_LINES DSTL,
		   		DKA_STRANSCO_HEADERS DSTH,
		   		HR_OPERATING_UNITS HR
		    where DSTL.SET_ID = DSTH.SET_ID
		      AND HR.NAME = DSTL.PARAM1_VALUE
		      AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
		      AND DSTL.ENABLE = 'Y'
		      AND NVL(DSTL.END_DATE,TRUNC(SYSDATE) ) >= TRUNC(SYSDATE)
              AND exists (select 1
							 from GL_JE_HEADERS GL  
							 where HR.set_of_books_id=gl.ledger_id
							  and period_name      = to_char(add_months(DSTL.START_DATE,-1),'MON-YY')
							  and status 	       = 'P'
                              and ACCRUAL_REV_FLAG = 'Y'
                              and ACCRUAL_REV_STATUS is null
                              and ACCRUAL_REV_PERIOD_NAME = to_char(DSTL.START_DATE,'MON-YY')
							  and rownum < 2
						   )
		      ;
			  
			  
	CURSOR op_reci_abst_abs_ok IS
      SELECT  substr(DSTL.RETURN_value,4,7) ABSORBANTE
             ,substr(DSTL.param1_value,4,7) ABSORBEE
             , 'KO' v_RG
       FROM 
         HR_ORGANIZATION_UNITS HRO,
         DKA_STRANSCO_LINES DSTL,
         DKA_STRANSCO_HEADERS DSTH

      WHERE DSTL.SET_ID     =  DSTH.SET_ID
        AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
        AND DSTL.ENABLE     =  'Y'
        AND HRO.NAME          =  DSTL.PARAM1_VALUE
        AND EXISTS  (SELECT sum((NVL(glb.begin_balance_dr,0) - NVL(glb.begin_balance_cr,0)) + ((NVL(glb.period_net_dr,0) - NVL(glb.period_net_cr,0) )))
          FROM GL_BALANCES glb,
               gl_ledgers gl,
               gl_code_combinations gcc
          WHERE gcc.code_combination_id=glb.code_combination_id  
          AND GL.LEDGER_Id        = GLB.LEDGER_Id   
          AND glb.TEMPLATE_ID IS NULL
          AND glb.period_name = to_char(DSTL.START_DATE,'MON-YY')
		  AND glb.currency_code = gl.currency_code
		  AND glb.actual_flag ='A'
          AND gl.short_name = substr(hro.name,4,4)
          AND substr(gcc.segment5,4,7)= substr(DSTL.RETURN_value,4,7)
          GROUP BY GL.LEDGER_Id
          HAVING sum((NVL(glb.begin_balance_dr,0) - NVL(glb.begin_balance_cr,0)) + ((NVL(glb.period_net_dr,0) - NVL(glb.period_net_cr,0) ))) <> 0)
      GROUP BY DSTL.param1_value,
               DSTL.RETURN_value
UNION
      SELECT  substr(DSTL.RETURN_value,4,7) ABSORBANTE
             ,substr(DSTL.param1_value,4,7) ABSORBEE
             , 'OK' v_RG
       FROM 
         HR_ORGANIZATION_UNITS HRO,
         DKA_STRANSCO_LINES DSTL,
         DKA_STRANSCO_HEADERS DSTH

      WHERE DSTL.SET_ID     =  DSTH.SET_ID
        AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
        AND DSTL.ENABLE     =  'Y'
        AND HRO.NAME          =  DSTL.PARAM1_VALUE
        AND NOT EXISTS  (SELECT sum((NVL(glb.begin_balance_dr,0) - NVL(glb.begin_balance_cr,0)) + ((NVL(glb.period_net_dr,0) - NVL(glb.period_net_cr,0) )))
          FROM GL_BALANCES glb,
               gl_ledgers gl,
               gl_code_combinations gcc
          WHERE gcc.code_combination_id=glb.code_combination_id  
          AND GL.LEDGER_Id        = GLB.LEDGER_Id   
          AND glb.TEMPLATE_ID IS NULL
          AND glb.period_name = to_char(DSTL.START_DATE,'MON-YY')
		  AND glb.currency_code = gl.currency_code
		  AND glb.actual_flag ='A'
          AND gl.short_name = substr(hro.name,4,4)
          AND substr(gcc.segment5,4,7)= substr(DSTL.RETURN_value,4,7)
          GROUP BY GL.LEDGER_Id
          HAVING sum((NVL(glb.begin_balance_dr,0) - NVL(glb.begin_balance_cr,0)) + ((NVL(glb.period_net_dr,0) - NVL(glb.period_net_cr,0) ))) <> 0)
      GROUP BY DSTL.param1_value,
               DSTL.RETURN_value;


CURSOR op_reci_abs_abst_ok IS
      SELECT  substr(DSTL.RETURN_value,4,7) ABSORBANTE
             ,substr(DSTL.param1_value,4,7) ABSORBEE
             , 'KO' v_RG
       FROM 
         HR_ORGANIZATION_UNITS HRO,
         DKA_STRANSCO_LINES DSTL,
         DKA_STRANSCO_HEADERS DSTH

      WHERE DSTL.SET_ID     =  DSTH.SET_ID
        AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
        AND DSTL.ENABLE     =  'Y'
        AND HRO.NAME          =  DSTL.RETURN_value
        AND EXISTS  (SELECT sum((NVL(glb.begin_balance_dr,0) - NVL(glb.begin_balance_cr,0)) + ((NVL(glb.period_net_dr,0) - NVL(glb.period_net_cr,0) )))
          FROM GL_BALANCES glb,
               gl_ledgers gl,
               gl_code_combinations gcc
          WHERE gcc.code_combination_id=glb.code_combination_id  
          AND GL.LEDGER_Id        = GLB.LEDGER_Id   
          AND glb.TEMPLATE_ID IS NULL
          AND glb.period_name = to_char(DSTL.START_DATE,'MON-YY')
          AND gl.short_name = substr(hro.name,4,4)
          AND substr(gcc.segment5,4,7)= substr(DSTL.PARAM1_VALUE,4,7)
          GROUP BY GL.LEDGER_Id
          HAVING sum((NVL(glb.begin_balance_dr,0) - NVL(glb.begin_balance_cr,0)) + ((NVL(glb.period_net_dr,0) - NVL(glb.period_net_cr,0) ))) <> 0)
      GROUP BY DSTL.param1_value,
               DSTL.RETURN_value
UNION
      SELECT  substr(DSTL.RETURN_value,4,7) ABSORBANTE
             ,substr(DSTL.param1_value,4,7) ABSORBEE
             , 'OK' v_RG
       FROM 
         HR_ORGANIZATION_UNITS HRO,
         DKA_STRANSCO_LINES DSTL,
         DKA_STRANSCO_HEADERS DSTH

      WHERE DSTL.SET_ID     =  DSTH.SET_ID
        AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
        AND DSTL.ENABLE     =  'Y'
        AND HRO.NAME          =  DSTL.RETURN_value
        AND NOT EXISTS  (SELECT sum((NVL(glb.begin_balance_dr,0) - NVL(glb.begin_balance_cr,0)) + ((NVL(glb.period_net_dr,0) - NVL(glb.period_net_cr,0) )))
          FROM GL_BALANCES glb,
               gl_ledgers gl,
               gl_code_combinations gcc
          WHERE gcc.code_combination_id=glb.code_combination_id  
          AND GL.LEDGER_Id        = GLB.LEDGER_Id   
          AND glb.TEMPLATE_ID IS NULL
          AND glb.period_name = to_char(DSTL.START_DATE,'MON-YY')
          AND gl.short_name = substr(hro.name,4,4)
          AND substr(gcc.segment5,4,7)= substr(DSTL.PARAM1_VALUE,4,7)
          GROUP BY GL.LEDGER_Id
          HAVING sum((NVL(glb.begin_balance_dr,0) - NVL(glb.begin_balance_cr,0)) + ((NVL(glb.period_net_dr,0) - NVL(glb.period_net_cr,0) ))) <> 0)
      GROUP BY DSTL.param1_value,
               DSTL.RETURN_value;
	   
BEGIN
		v_errbuf  := NULL;
		v_retcode := 0;
		Dka_Tools_Pkg.Put_Outdebug_Message('---------------------------------------------------------------------------------------------------------------------');
		Dka_Tools_Pkg.Put_Outdebug_Message('    Traitement                                                : DKA : Fusion GL - Etape1 : Contrôle pré-requis');
		Dka_Tools_Pkg.Put_Outdebug_Message('    Date et Heure                                             : ' ||
                                            to_char(SYSDATE,
                                               'DD-MON-YYYY HH24:MI:SS'));
		Dka_Tools_Pkg.Put_Outdebug_Message('---------------------------------------------------------------------------------------------------------------------');
------------------------------------------------------------------------------------
--REG.3.2.4 :	Contrôle table de transcodification FUSION_SOCIETE_VERS_SOCIETE
------------------------------------------------------------------------------------
	
			Dka_Tools_Pkg.Put_Outdebug_Message('==> Contrôle table de transcodification FUSION_SOCIETE_VERS_SOCIETE ');
	BEGIN 
		SELECT 1 into v_RG_01
			FROM
					   HR_ORGANIZATION_UNITS HOU,
					   DKA_STRANSCO_LINES DSTL,
					   DKA_STRANSCO_HEADERS DSTH
			WHERE
					   DSTL.SET_ID = DSTH.SET_ID
					   AND HOU.NAME = DSTL.PARAM1_VALUE
					   AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
					   AND DSTL.ENABLE = 'Y'
					   AND NVL(DSTL.END_DATE,TRUNC(SYSDATE) ) >= TRUNC(SYSDATE)
					   and rownum <2
                    ;
		exception
		when others then
		v_RG_01:=0  ;       
        
       					
	END;
		if  v_RG_01 = 1 then
		     v_warning := false;
		else 
		    v_warning := TRUE;
			Dka_Tools_Pkg.put_log_message('Aucune fusion active définie dans la table de transco FUSION_SOCIETE_VERS_SOCIETE  ');
			Dka_Tools_Pkg.Put_Outdebug_Message('Aucune fusion active définie dans la table de transco FUSION_SOCIETE_VERS_SOCIETE  ');
			GOTO Fin;
		END if;
		
										
	BEGIN
	FOR cur_transco IN cur_tab_trans  LOOP
      BEGIN	
		SELECT 1 into v_RG_02 
			FROM
					   HR_ORGANIZATION_UNITS HOU,
					   DKA_STRANSCO_LINES DSTL,
					   DKA_STRANSCO_HEADERS DSTH
			WHERE
					   DSTL.SET_ID = DSTH.SET_ID
					   AND HOU.NAME = DSTL.PARAM1_VALUE
					   AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
					   AND DSTL.ENABLE = 'Y'
					   AND NVL(DSTL.END_DATE,TRUNC(SYSDATE) ) >= TRUNC(SYSDATE)
						AND substr(DSTL.PARAM1_VALUE,4,7) 	=  substr(cur_transco.absorbe,4,7)
						AND (substr(DSTL.RETURN_VALUE,4,7) 	<> substr(cur_transco.absorbante,4,7)
						      OR DSTL.START_DATE <> cur_transco.START_DATE)
							  and rownum <2
                                                ;	
										
      exception
		when others then
		v_RG_02:=0  ;  
		
      END;

		if v_RG_02 = 1 then
		    v_warning := TRUE;
			Dka_Tools_Pkg.put_log_message('Fusions mal définies dans la table de transco FUSION_SOCIETE_VERS_SOCIETE  ');
			Dka_Tools_Pkg.Put_Outdebug_Message('Fusions mal définies dans la table de transco FUSION_SOCIETE_VERS_SOCIETE   ');
			GOTO Fin;
		END if;
		
	END loop;
     
	END;
	
		
    Dka_Tools_Pkg.Put_Outdebug_Message('---------------------------------------------------------------------------------------------------------------------');
------------------------------------------------------------------------------------
--REG.3.2.5 :	Contrôle type de pièce « FUSION »
------------------------------------------------------------------------------------	
	Dka_Tools_Pkg.Put_Outdebug_Message('==> Contrôle type de pièce « FUSION » ');
	BEGIN
		select 1 into v_RG_03
			from GL_JE_CATEGORIES
			where USER_JE_CATEGORY_NAME ='FUSION';
		exception
		when others then
		v_RG_03:=0  ;
	END;
		if 	v_RG_03 = 1 then
		    test_ok:= TRUE;
			Dka_Tools_Pkg.put_log_message('OK. Le type "FUSION" existe');
			Dka_Tools_Pkg.Put_Outdebug_Message('OK. Le type "FUSION" existe');
		else 
			v_warning := TRUE;
			Dka_Tools_Pkg.put_log_message('KO. Le type "FUSION" n''existe pas');
			Dka_Tools_Pkg.Put_Outdebug_Message('KO. Le type "FUSION" n''existe pas');
		END if;
	Dka_Tools_Pkg.Put_Outdebug_Message('---------------------------------------------------------------------------------------------------------------------');
	Dka_Tools_Pkg.Put_Outdebug_Message('==> Contrôle origine de pièce « FUSION BALANCE » ');	
	BEGIN
		select 1 into v_RG_04
			from GL_JE_SOURCES
			where USER_JE_SOURCE_NAME ='FUSION BALANCE';
		exception
		when others then
		v_RG_04:=0  ;
	END;
		if 	v_RG_04 = 1 then
		    test_ok:= TRUE;
			Dka_Tools_Pkg.put_log_message('OK. L''origine "FUSION BALANCE" existe');
			Dka_Tools_Pkg.Put_Outdebug_Message('OK. L''origine "FUSION BALANCE" existe');
		else 
			v_warning := TRUE;
			Dka_Tools_Pkg.put_log_message('« KO. L''origine "FUSION BALANCE " n''existe pas');
			Dka_Tools_Pkg.Put_Outdebug_Message('KO. L''origine "FUSION BALANCE " n''existe pas');
		END if;
	Dka_Tools_Pkg.Put_Outdebug_Message('---------------------------------------------------------------------------------------------------------------------');
------------------------------------------------------------------------------------
--REG.3.2.7 :	Contrôle clôture période précédant la fusion
------------------------------------------------------------------------------------	
	Dka_Tools_Pkg.Put_Outdebug_Message('==> Contrôle clôture période précédant la fusion   ');
	FOR cur_clo_ok IN per_close_ok  LOOP										
	BEGIN
		test_ok:= TRUE;
		Dka_Tools_Pkg.put_log_message('OK. La période précédente est fermée pour la société absorbée ['||cur_clo_ok.ABSORBEE||']');
		Dka_Tools_Pkg.Put_Outdebug_Message('OK. La période précédente est fermée pour la société absorbée ['||cur_clo_ok.ABSORBEE||'] ');
	END;
	END LOOP;
	FOR cur_clo_ko IN per_close_ko  LOOP										
	BEGIN	
	    v_warning := TRUE;
	    Dka_Tools_Pkg.put_log_message('KO. La période précédente n''est pas fermée pour la société absorbée ['||cur_clo_ko.ABSORBEE||']');
	    Dka_Tools_Pkg.Put_Outdebug_Message('KO. La période précédente n''est pas fermée pour la société absorbée ['||cur_clo_ko.ABSORBEE||']');
	END;
	END LOOP;
	Dka_Tools_Pkg.Put_Outdebug_Message('---------------------------------------------------------------------------------------------------------------------');
------------------------------------------------------------------------------------
--REG.3.2.8 :	Contrôle statut période de fusion
------------------------------------------------------------------------------------
	Dka_Tools_Pkg.Put_Outdebug_Message('==> Contrôle statut période de fusion   ');
	FOR cur_ouv_ok IN per_ouvert_ok  LOOP										
	BEGIN
		test_ok:= TRUE;
		Dka_Tools_Pkg.put_log_message('OK. La période ['||cur_ouv_ok.PERIODE||'] est ouverte pour la société ['||cur_ouv_ok.SOCIETE||']');
		Dka_Tools_Pkg.Put_Outdebug_Message('OK. La période ['||cur_ouv_ok.PERIODE||'] est ouverte pour la société ['||cur_ouv_ok.SOCIETE||']');
	END;
	END LOOP;
	FOR cur_ouv_ko IN per_ouvert_ko  LOOP										
	BEGIN	
		v_warning := TRUE;
		Dka_Tools_Pkg.put_log_message('KO. La période ['||cur_ouv_ko.PERIODE||'] n''est ouverte pour la société ['||cur_ouv_ko.SOCIETE||']');
		Dka_Tools_Pkg.Put_Outdebug_Message('KO. La période ['||cur_ouv_ko.PERIODE||'] n''est pas  ouverte pour la société ['||cur_ouv_ko.SOCIETE||']');	
	END;
	END LOOP;
	FOR cur_ouv_abs_ok IN per_ouvert_abs_ok  LOOP										
	BEGIN
		test_ok:= TRUE;
		Dka_Tools_Pkg.put_log_message('OK. La période ['||cur_ouv_abs_ok.PERIODE||'] est ouverte pour la société ['||cur_ouv_abs_ok.SOCIETE||']');
		Dka_Tools_Pkg.Put_Outdebug_Message('OK. La période ['||cur_ouv_abs_ok.PERIODE||'] est ouverte pour la société ['||cur_ouv_abs_ok.SOCIETE||']');
	END;
	END LOOP;
	FOR cur_ouv_abs_ko IN per_ouvert_abs_ko  LOOP										
	BEGIN	
		v_warning := TRUE;
		Dka_Tools_Pkg.put_log_message('KO. La période ['||cur_ouv_abs_ko.PERIODE||'] n''est ouverte pour la société ['||cur_ouv_abs_ko.SOCIETE||']');
		Dka_Tools_Pkg.Put_Outdebug_Message('KO. La période ['||cur_ouv_abs_ko.PERIODE||'] n''est pas  ouverte pour la société ['||cur_ouv_abs_ko.SOCIETE||']');	
	END;
	END LOOP;	
	Dka_Tools_Pkg.Put_Outdebug_Message('---------------------------------------------------------------------------------------------------------------------');
------------------------------------------------------------------------------------
--REG.3.2.9 :	Contrôle imputation des pièces dans la société absorbée
------------------------------------------------------------------------------------			
	Dka_Tools_Pkg.Put_Outdebug_Message('==> Contrôle imputation des pièces dans la société absorbée    ');
	FOR cur_ctr_impu_ko IN controle_impu_ko  LOOP
	BEGIN
		v_warning := TRUE;
		Dka_Tools_Pkg.put_log_message('KO. Certaines lignes de la société absorbée ['||cur_ctr_impu_ko.ABSORBEE||'] ne sont pas imputées');
		Dka_Tools_Pkg.Put_Outdebug_Message('KO. Certaines lignes de la société absorbée ['||cur_ctr_impu_ko.ABSORBEE||'] ne sont pas imputées');
	END;
	END LOOP;	
	FOR cur_ctr_impu_OK IN controle_impu_OK  LOOP
	BEGIN
		test_ok:= TRUE;
		Dka_Tools_Pkg.put_log_message('OK. Toutes les lignes de la société absorbée ['||cur_ctr_impu_OK.ABSORBEE||'] sont imputées dans GL');
		Dka_Tools_Pkg.Put_Outdebug_Message('OK. Toutes les lignes de la société absorbée ['||cur_ctr_impu_OK.ABSORBEE||'] sont imputées dans GL');
	END;
	END LOOP;
	Dka_Tools_Pkg.Put_Outdebug_Message('---------------------------------------------------------------------------------------------------------------------');
------------------------------------------------------------------------------------
--REG.3.2.9 :	Contrôle contrepassation du mois précédent la fusion dans la société absorbée
------------------------------------------------------------------------------------
	Dka_Tools_Pkg.Put_Outdebug_Message('==> Contrôle contrepassation du mois précédent la fusion dans la société absorbée ');
	FOR cur_ctr_pass_ok IN controle_contre_pass_ok  LOOP
	BEGIN
		test_ok:= TRUE;
		Dka_Tools_Pkg.put_log_message('OK. Les lignes du mois antérieur à la fusion ont été contrepassées dans la société absorbée  ['||cur_ctr_pass_ok.ABSORBEE||'] ');
		Dka_Tools_Pkg.Put_Outdebug_Message('OK. Les lignes du mois antérieur à la fusion ont été contrepassées dans la société absorbée ['||cur_ctr_pass_ok.ABSORBEE||'] ');
	END;
	END LOOP;	
	FOR cur_ctr_pass_ko IN controle_contre_pass_ko  LOOP
	BEGIN
		v_warning := TRUE;
		Dka_Tools_Pkg.put_log_message('KO. Les lignes du mois antérieur à la fusion ne sont pas toutes contrepassées dans la société absorbée ['||cur_ctr_pass_ko.ABSORBEE||'] ');
		Dka_Tools_Pkg.Put_Outdebug_Message('KO. Les lignes du mois antérieur à la fusion ne sont pas toutes contrepassées dans la société absorbée ['||cur_ctr_pass_ko.ABSORBEE||'] ');
	END;
	END LOOP;
	Dka_Tools_Pkg.Put_Outdebug_Message('---------------------------------------------------------------------------------------------------------------------');
----------------------------------------------------------------------------------------------------------------
--REG.3.2.11 :	Contrôle soldes d'opérations réciproques avec la société absorbante dans la société absorbée
----------------------------------------------------------------------------------------------------------------
	Dka_Tools_Pkg.Put_Outdebug_Message('==> Contrôle soldes d''opérations réciproques avec la société absorbante dans la société absorbée');
	FOR op_abst_abs_ok IN op_reci_abst_abs_ok  LOOP
	BEGIN
	if op_abst_abs_ok.v_RG = 'OK' then 
		test_ok:= TRUE;
		Dka_Tools_Pkg.put_log_message('OK. Il n''existe aucun solde d''opérations réciproques avec la société absorbante ['||op_abst_abs_ok.ABSORBANTE||'] dans la société absorbée ['||op_abst_abs_ok.ABSORBEE||'] ');
		Dka_Tools_Pkg.Put_Outdebug_Message('OK. Il n''existe aucun solde d''opérations réciproques avec la société absorbante ['||op_abst_abs_ok.ABSORBANTE||'] dans la société absorbée ['||op_abst_abs_ok.ABSORBEE||'] ');	
	
	else 
		v_warning := TRUE;
		Dka_Tools_Pkg.put_log_message('KO. Il existe au moins un solde non nul d''opérations réciproques avec la société absorbante ['||op_abst_abs_ok.ABSORBANTE||'] dans la société absorbée ['||op_abst_abs_ok.ABSORBEE||']. ');
		Dka_Tools_Pkg.Put_Outdebug_Message('KO. Il existe au moins un solde non nul d''opérations réciproques avec la société absorbante ['||op_abst_abs_ok.ABSORBANTE||'] dans la société absorbée ['||op_abst_abs_ok.ABSORBEE||'].');
		END IF;
	END;
	END LOOP;
	Dka_Tools_Pkg.Put_Outdebug_Message('---------------------------------------------------------------------------------------------------------------------');
----------------------------------------------------------------------------------------------------------------
--REG.3.2.12 :	Contrôle soldes d'opérations réciproques avec la société absorbée dans la société absorbante
----------------------------------------------------------------------------------------------------------------
	Dka_Tools_Pkg.Put_Outdebug_Message('==> Contrôle soldes d''opérations réciproques avec la société absorbée dans la société absorbante');
	FOR op_abs_abst_ok IN op_reci_abs_abst_ok  LOOP
	BEGIN
	if op_abs_abst_ok.v_RG = 'OK' then 
		test_ok:= TRUE;
		Dka_Tools_Pkg.put_log_message('OK. Il n''existe aucun solde d''opérations réciproques avec la société absorbée ['||op_abs_abst_ok.ABSORBEE||'] dans la société absorbante ['||op_abs_abst_ok.ABSORBANTE||'] ');
		Dka_Tools_Pkg.Put_Outdebug_Message('OK. Il n''existe aucun solde d''opérations réciproques avec la société absorbée ['||op_abs_abst_ok.ABSORBEE||'] dans la société absorbante ['||op_abs_abst_ok.ABSORBANTE||'] ');
		
	else 
		v_warning := TRUE;
		Dka_Tools_Pkg.put_log_message('KO. Il existe au moins un solde non nul d''opérations réciproques avec la société absorbée ['||op_abs_abst_ok.ABSORBEE||'] dans la société absorbante ['||op_abs_abst_ok.ABSORBANTE||']. ');
		Dka_Tools_Pkg.Put_Outdebug_Message('KO. Il existe au moins un solde non nul d''opérations réciproques avec la société absorbée ['||op_abs_abst_ok.ABSORBEE||'] dans la société absorbante ['||op_abs_abst_ok.ABSORBANTE||'].');
		
	END IF;
	END;
	END LOOP;
	Dka_Tools_Pkg.Put_Outdebug_Message('---------------------------------------------------------------------------------------------------------------------');
-------------------------------------------------------------------------------------
-- PHASE DE FIN DU TRAITEMENT MAITRE --
-------------------------------------------------------------------------------------
     << Fin >>
	IF p_retcode = 2
		THEN
         p_errbuf := 'ATTENTION : Erreur bloquante : '||p_errbuf;
	ELSIF  v_warning
		THEN
         p_errbuf := 'PRE REQUIS KO';
         p_retcode := 1;
	ELSIF test_ok
		THEN
         p_errbuf := 'PRE REQUIS OK';
         p_retcode := 0;
	END IF;
	
		Dka_Tools_Pkg.Put_Outdebug_Message('');
		Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
		Dka_Tools_Pkg.Put_Outdebug_Message('=> ETAT DES CONTROLES EFFECTUE :');
		Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
		Dka_Tools_Pkg.Put_Outdebug_Message(p_errbuf);
		Dka_Tools_Pkg.Put_Outdebug_Message('');
		Dka_Tools_Pkg.Put_Outdebug_Message('**************************************************************************************');
		Dka_Tools_Pkg.Put_Outdebug_Message('*********Fin des logs de traitements DKA : Fusion GL - Etape1 : Contrôle pré-requis***');
		Dka_Tools_Pkg.Put_Outdebug_Message('**************************************************************************************');
		Dka_Tools_Pkg.Put_Outdebug_Message('');
		

END main; 

END DKA_FUSGLCTRLPR_PKG;

/
SHOW ERRORS
EXIT