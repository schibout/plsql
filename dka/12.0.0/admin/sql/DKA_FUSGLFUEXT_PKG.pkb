create or replace PACKAGE BODY DKA_FUSGLFUEXT_PKG IS
--------------------------------------------------------------------------------
-- $$
-- Capgemini
-- Projet           : DALKIA Oracle Applications
-- Nom              : DKA_FUSGLFUEXT_PKG.pkb
-- Description      : DKA_FUSGLFUEXT_PKG package body
-- Auteur           : S.HAHIOUI(Capgemini)
-- Date de création : 21/10/2019
-- Doc. associée    :
-- Commentaire      : À exécuter sous SQLPLUS avec l'utilisateur APPS
--------------------------------------------------------------------------------
-- Historique
-- Date       Version Qui Description
-- ---------- ------- --- --------------------------------------------------------------
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PRIVEES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

------------------------------------------------------------------------------------
-- Nom              : EXTRACT_DATA
-- Description      : Procédure d'extraction des données dans une table spécifique 
--
-- PARAMETRES       : pv_errbuf      Sortie Message d'erreur
--                    pn_retgcc     Sortie gcc Retour de la procédure
--                                   '0' : Normal
--                                   '1' : Avertissement
--                                   '2' : Erreur
--                  pv_type_fusion type de fusion 
--                            
--
-- VALEUR RETOURNEE :
-- Description       :
-- Valeurs possibles :
------------------------------------------------------------------------------------

PROCEDURE EXTRACT_DATA (p_errbuf out varchar2 , p_retcode out number) IS

-----------------------------------------------------------
 -- curseur pour recuperer le couple absorbé - absorbante 
-----------------------------------------------------------

  CURSOR C_COUPLE_ABS_ABTE IS
  SELECT distinct 
  substr(DSTL.PARAM1_VALUE,4,4)       S_ABSORBE,
  substr(DSTL.RETURN_VALUE,4,4)       S_ABSORBANTE,
  DSTL.START_DATE                     D_FUSION
  FROM   DKA_STRANSCO_LINES      DSTL,
		 DKA_STRANSCO_HEADERS    DSTH 
  WHERE  DSTL.SET_ID 					 = DSTH.SET_ID
  AND    DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
  AND    DSTL.ENABLE					 = 'Y'
  AND    NVL(DSTL.END_DATE,TRUNC(SYSDATE) ) >= TRUNC(SYSDATE);
  
---------------------------------------------------------------------- 
 -- curseur pour recuperer les donnees soldes gl à extraire : COLLECTIF
-----------------------------------------------------------------------
 CURSOR C_COLLECTIF (P_ABSORBEE VARCHAR2, P_ABSORBANTE VARCHAR2 , P_DATE_FUSION  DATE )  IS
	SELECT
    'EXTRACTION'   													TYPE_LIGNE,
	'COLLECTIFS'  													TYPE_DONNEE,
	P_ABSORBEE  								                    SOC_ABSORBEE,
	P_ABSORBANTE   							                     	SOC_ABSORBANTE,
	gl.name 												    	LIVRE,
	gcc.SEGMENT1 													SOCIETE,
    gcc.SEGMENT2 													UO,
    gcc.SEGMENT3 													COMPTE_LOCAL,
    gcc.SEGMENT4 													COMPTE_ANALYTIQUE,
    gcc.SEGMENT5 													INTERCO,
    gcc.SEGMENT6 													CENTRE_FINANCE,
    gcc.SEGMENT7 													CODE_AFFAIRE,
    gcc.SEGMENT8 													PROJET_FINANCE,
    gcc.SEGMENT9 													CODE_FLUX,
    gcc.SEGMENT10 													RESERVE_1,
	gcc.SEGMENT11 													RESERVE_2,
	gcc.SEGMENT12	    											RESERVE_3,
    SUM(NVL(begin_balance_dr,0)) + SUM(NVL(period_net_dr,0))    	DEBIT,
    SUM(NVL(begin_balance_cr,0)) + SUM(NVL(period_net_cr,0)) 	  	CREDIT,
	'FUSION '||P_ABSORBEE||' VERS '||P_ABSORBANTE||'' 	            DESCRIPTION_LIGNE,
    NULL 															PF,
	NULL 															TF,
	NULL 															TYPE_DEPENSE,
	NULL 															TYPE_EVENEMENT,
	NULL 															QTE,
	NULL 															FRAIS,
	NULL 															CODE_CLIENT,
	NULL 															CODE_INTERBANCAIRE,
	NULL 															MATRICULE_EMPLOYE,
	NULL 															REF_LETTRAGE,
	bal.CURRENCY_CODE 												DEVISE,
	NULL 															CREATION_DATE,
	NULL 															JE_HEADER_ID,
	NULL 															PERIODE,
	NULL 															CATEGORIE,
	NULL 															NOM_PIECE,
	NULL 															NUMERO_PIECE,
	NULL 															NUMERO_LIGNE,
	NULL 															CCF,
	NULL 															LIBELLE_CPTE_LOCAL
    
FROM
    gl_balances 			bal ,
    GL_LEDGERS		 		gl ,
    gl_code_combinations 	gcc ,
	FND_FLEX_VALUE_SETS  	FFVS ,
    FND_FLEX_VALUES_VL   	FFVV
WHERE      bal.code_combination_id       = gcc.code_combination_id
    AND    bal.ledger_id 		         = gl.LEDGER_ID
	AND    bal.TEMPLATE_ID               is NULL
	and    bal.CURRENCY_CODE             = 'EUR'
	AND    bal.actual_flag               = 'A'
	AND    FFVS.FLEX_VALUE_SET_ID 	     = FFVv.FLEX_VALUE_SET_ID
    AND    FFVS.FLEX_VALUE_SET_NAME      = 'DAOPCCF_LOCAL'
	AND    GCC.SEGMENT3                  = FFVv.FLEX_VALUE
	AND     bal.PERIOD_NAME               = to_char(P_DATE_FUSION,'MON-YY')
	AND    gl.short_name                 = P_ABSORBEE 
	AND    gl.ledger_category_code       = 'PRIMARY'
	-------BILAN
    AND    substr(FFVv.COMPILED_VALUE_ATTRIBUTES,5,1) in ('O','L','A') 
	-------COLLECTIF
	AND    substr(FFVv.COMPILED_VALUE_ATTRIBUTES,7,1) = 'Y'
    GROUP BY 
            gl.name,
			bal.CURRENCY_CODE,
            GCC.SEGMENT1,
            GCC.SEGMENT2,
            GCC.SEGMENT3,
            GCC.SEGMENT4,
            GCC.SEGMENT5,
            GCC.SEGMENT6,
            GCC.SEGMENT7,
            GCC.SEGMENT8,
            GCC.SEGMENT9,
            GCC.SEGMENT10,
            GCC.SEGMENT11,
            GCC.SEGMENT12
      HAVING  ( (sum(NVL(bal.BEGIN_BALANCE_DR, 0) + NVL(PERIOD_NET_DR, 0)) - sum( NVL(bal.BEGIN_BALANCE_CR, 0) + NVL(PERIOD_NET_CR, 0)) <> 0 ));

---------------------------------------------------------------------- 
-- curseur pour recuperer les donnees soldes gl à extraire : NON LETTRABLES
-----------------------------------------------------------------------

  CURSOR C_NON_LETTRABLES (P_ABSORBEE VARCHAR2, P_ABSORBANTE VARCHAR2 , P_DATE_FUSION  DATE) IS
	SELECT
    'EXTRACTION'   													TYPE_LIGNE,
	'NON LETTRABLES'  												TYPE_DONNEE,
	P_ABSORBEE  								                    SOC_ABSORBEE,
	P_ABSORBANTE   							                     	SOC_ABSORBANTE,
	gl.name 														LIVRE,
	gcc.SEGMENT1 													SOCIETE,
    gcc.SEGMENT2 													UO,
    gcc.SEGMENT3 													COMPTE_LOCAL,
    gcc.SEGMENT4 													COMPTE_ANALYTIQUE,
    gcc.SEGMENT5 													INTERCO,
    gcc.SEGMENT6 													CENTRE_FINANCE,
    gcc.SEGMENT7 													CODE_AFFAIRE,
    gcc.SEGMENT8 													PROJET_FINANCE,
    gcc.SEGMENT9 													CODE_FLUX,
    gcc.SEGMENT10 													RESERVE_1,
	gcc.SEGMENT11 													RESERVE_2,
	gcc.SEGMENT12	    											RESERVE_3,
    SUM(NVL(begin_balance_dr,0)) + SUM(NVL(period_net_dr,0))    	DEBIT,
    SUM(NVL(begin_balance_cr,0)) + SUM(NVL(period_net_cr,0)) 	  	CREDIT,
	'FUSION '||P_ABSORBEE||' VERS '||P_ABSORBANTE||'' 	            DESCRIPTION_LIGNE,
    NULL 															PF,
	NULL 															TF,
	NULL 															TYPE_DEPENSE,
	NULL 															TYPE_EVENEMENT,
	NULL 															QTE,
	NULL 															FRAIS,
	NULL 															CODE_CLIENT,
	NULL 															CODE_INTERBANCAIRE,
	NULL 															MATRICULE_EMPLOYE,
	NULL 															REF_LETTRAGE,
	bal.CURRENCY_CODE 												DEVISE,
	NULL 															CREATION_DATE,
	NULL 															JE_HEADER_ID,
	NULL 															PERIODE,
	NULL 															CATEGORIE,
	NULL 															NOM_PIECE,
	NULL 															NUMERO_PIECE,
	NULL 															NUMERO_LIGNE,
	NULL 															CCF,
	NULL 															LIBELLE_CPTE_LOCAL
    
FROM
    gl_balances 			bal ,
    GL_LEDGERS		 		gl ,
    gl_code_combinations 	gcc ,
	FND_FLEX_VALUE_SETS  	FFVS ,
    FND_FLEX_VALUES_VL   	FFVV
WHERE      bal.code_combination_id       = gcc.code_combination_id
    AND    bal.ledger_id 		         = gl.LEDGER_ID
	AND    bal.TEMPLATE_ID               is NULL
	and    bal.CURRENCY_CODE             = 'EUR'
	AND    bal.actual_flag               = 'A'
	AND    FFVS.FLEX_VALUE_SET_ID 	     = FFVv.FLEX_VALUE_SET_ID
    AND    FFVS.FLEX_VALUE_SET_NAME      = 'DAOPCCF_LOCAL'
	AND    GCC.SEGMENT3                  = FFVv.FLEX_VALUE
	AND    bal.PERIOD_NAME               = to_char(P_DATE_FUSION,'MON-YY')
	AND    gl.short_name                 = P_ABSORBEE 
	AND    gl.ledger_category_code       = 'PRIMARY'
	--------- BILAN 
    AND    substr(FFVV.COMPILED_VALUE_ATTRIBUTES,5,1) in ('O','L','A') 
	--------- NON CORRECTIF
	AND    substr(FFVV.COMPILED_VALUE_ATTRIBUTES,7,1) <> 'Y'
	--------- NON LETTRABLE
	AND    substr(FFVV.COMPILED_VALUE_ATTRIBUTES,9,1) <> 'Y'
	--------- NON SUIVI RB 
	AND  not  EXISTS  ( select 1
					from CE_bank_accounts 		cba ,
						 RB_BANK_ACCOUNTS 		rba 
					where  rba.status 					 = 'Y'
					AND    rba.bank_account_id 			 = cba.bank_account_id
					AND    substr(cba.bank_account_name,10,6)= gcc.SEGMENT3
					AND    substr(cba.bank_account_name,1,4) = P_ABSORBEE 
	
					)
	 GROUP BY
            gl.name,
			bal.CURRENCY_CODE,
            GCC.SEGMENT1,
            GCC.SEGMENT2,
            GCC.SEGMENT3,
            GCC.SEGMENT4,
            GCC.SEGMENT5,
            GCC.SEGMENT6,
            GCC.SEGMENT7,
            GCC.SEGMENT8,
            GCC.SEGMENT9,
            GCC.SEGMENT10,
            GCC.SEGMENT11,
            GCC.SEGMENT12
     HAVING  ( (sum(NVL(bal.BEGIN_BALANCE_DR, 0) + NVL(PERIOD_NET_DR, 0)) - sum( NVL(bal.BEGIN_BALANCE_CR, 0) + NVL(PERIOD_NET_CR, 0)) <> 0 ));			
    
	
---------------------------------------------------------------------- 
-- curseur pour recuperer les donnees soldes gl à extraire : HORS BILAN
-----------------------------------------------------------------------
 
  CURSOR C_HORS_BILAN (P_ABSORBEE VARCHAR2, P_ABSORBANTE VARCHAR2 , P_DATE_FUSION  DATE) IS
	SELECT
    'EXTRACTION'   													TYPE_LIGNE,
	'HORS BILAN'  													TYPE_DONNEE,
	P_ABSORBEE  								                    SOC_ABSORBEE,
	P_ABSORBANTE   							                     	SOC_ABSORBANTE,
	gl.name 														LIVRE,
	gcc.SEGMENT1 													SOCIETE,
    gcc.SEGMENT2 													UO,
    gcc.SEGMENT3 													COMPTE_LOCAL,
    gcc.SEGMENT4 													COMPTE_ANALYTIQUE,
    gcc.SEGMENT5 													INTERCO,
    gcc.SEGMENT6 													CENTRE_FINANCE,
    gcc.SEGMENT7 													CODE_AFFAIRE,
    gcc.SEGMENT8 													PROJET_FINANCE,
    gcc.SEGMENT9 													CODE_FLUX,
    gcc.SEGMENT10 													RESERVE_1,
	gcc.SEGMENT11 													RESERVE_2,
	gcc.SEGMENT12	    											RESERVE_3,
    SUM(NVL(begin_balance_dr,0)) + SUM(NVL(period_net_dr,0))    	DEBIT,
    SUM(NVL(begin_balance_cr,0)) + SUM(NVL(period_net_cr,0)) 	  	CREDIT,
	'FUSION '||P_ABSORBEE||' VERS '||P_ABSORBANTE||'' 	            DESCRIPTION_LIGNE,
    NULL 															PF,
	NULL 															TF,
	NULL 															TYPE_DEPENSE,
	NULL 															TYPE_EVENEMENT,
	NULL 															QTE,
	NULL 															FRAIS,
	NULL 															CODE_CLIENT,
	NULL 															CODE_INTERBANCAIRE,
	NULL 															MATRICULE_EMPLOYE,
	NULL 															REF_LETTRAGE,
	bal.CURRENCY_CODE 												DEVISE,
	NULL 															CREATION_DATE,
	NULL 															JE_HEADER_ID,
	NULL 															PERIODE,
	NULL 															CATEGORIE,
	NULL 															NOM_PIECE,
	NULL 															NUMERO_PIECE,
	NULL 															NUMERO_LIGNE,
	NULL 															CCF,
	NULL 															LIBELLE_CPTE_LOCAL
    
FROM
    gl_balances 			bal ,
    GL_LEDGERS		 		gl ,
    gl_code_combinations 	gcc ,
	FND_FLEX_VALUE_SETS  	FFVS ,
    FND_FLEX_VALUES_VL   	FFVV
WHERE      bal.code_combination_id       = gcc.code_combination_id
    AND    bal.ledger_id 		         = gl.LEDGER_ID
	AND    bal.TEMPLATE_ID               is NULL
	and    bal.CURRENCY_CODE             = 'EUR'
	AND    bal.actual_flag               = 'A'
	AND    FFVS.FLEX_VALUE_SET_ID 	     = FFVv.FLEX_VALUE_SET_ID
    AND    FFVS.FLEX_VALUE_SET_NAME      = 'DAOPCCF_LOCAL'
	AND    GCC.SEGMENT3                  = FFVv.FLEX_VALUE
	AND    bal.PERIOD_NAME               = to_char(P_DATE_FUSION,'MON-YY')
	AND    gl.short_name                 = P_ABSORBEE 
	AND    gl.ledger_category_code       = 'PRIMARY'
	--------- HORS BILAN 
    AND    substr(FFVV.COMPILED_VALUE_ATTRIBUTES,5,1) not in ('O','L','A') 
    
    GROUP BY 
            gl.name,
			bal.CURRENCY_CODE,
            GCC.SEGMENT1,
            GCC.SEGMENT2,
            GCC.SEGMENT3,
            GCC.SEGMENT4,
            GCC.SEGMENT5,
            GCC.SEGMENT6,
            GCC.SEGMENT7,
            GCC.SEGMENT8,
            GCC.SEGMENT9,
            GCC.SEGMENT10,
            GCC.SEGMENT11,
            GCC.SEGMENT12
     HAVING  ( (sum(NVL(bal.BEGIN_BALANCE_DR, 0) + NVL(PERIOD_NET_DR, 0)) - sum( NVL(bal.BEGIN_BALANCE_CR, 0) + NVL(PERIOD_NET_CR, 0)) <> 0 ));
	
    
 ---------------------------------------------------------------------- 
 -- curseur pour recuperer les donnees soldes gl à extraire : LETTRABLES
 -----------------------------------------------------------------------
 
  CURSOR C_LETTRABLES (P_ABSORBEE VARCHAR2, P_ABSORBANTE VARCHAR2 , P_DATE_FUSION  DATE) IS
	SELECT
    'EXTRACTION'   													TYPE_LIGNE,
	'LETTRABLES'  													TYPE_DONNEE,
	P_ABSORBEE 														SOC_ABSORBEE,
	P_ABSORBANTE 													SOC_ABSORBANTE,
	GLS.NAME 							       					    LIVRE,
	GCC.SEGMENT1 													SOCIETE,
    GCC.SEGMENT2 													UO,
    GCC.SEGMENT3 													COMPTE_LOCAL,
    GCC.SEGMENT4 													COMPTE_ANALYTIQUE,
    GCC.SEGMENT5 													INTERCO,
    GCC.SEGMENT6 													CENTRE_FINANCE,
    GCC.SEGMENT7 													CODE_AFFAIRE,
    GCC.SEGMENT8 													PROJET_FINANCE,
    GCC.SEGMENT9 													CODE_FLUX,
    GCC.SEGMENT10 													RESERVE_1,
	GCC.SEGMENT11 													RESERVE_2,
	GCC.SEGMENT12	    											RESERVE_3,
	NVL(GJL.ACCOUNTED_DR,0)                     					DEBIT,
	NVL(GJL.ACCOUNTED_CR,0)										    CREDIT,
	GJL.DESCRIPTION 												DESCRIPTION_LIGNE,
    NULL 															PF,
	NULL 															TF,
	NULL 															TYPE_DEPENSE,
	NULL 															TYPE_EVENEMENT,
	NULL 															QTE,
	NULL 															FRAIS,
	DECODE (context3,'Y.X.Y',GJL.ATTRIBUTE17,NULL)						CODE_CLIENT,															
	DECODE (context3,'RB',GJL.ATTRIBUTE20,NULL)						CODE_INTERBANCAIRE,														
	DECODE (context3,'MAT',GJL.ATTRIBUTE11,NULL) 					    MATRICULE_EMPLOYE,														
	REC.JGZZ_RECON_REF 												REF_LETTRAGE,
	GJH.CURRENCY_CODE												DEVISE,
	GJH.CREATION_DATE        				                        CREATION_DATE,
	GJH.JE_HEADER_ID 												JE_HEADER_ID,
	GJH.PERIOD_NAME 												PERIODE,
	GJCV.USER_JE_CATEGORY_NAME  									CATEGORIE,
	GJH.NAME 														NOM_PIECE,
	GJH.DOC_SEQUENCE_VALUE											NUMERO_PIECE,
	GJL.JE_LINE_NUM 												NUMERO_LIGNE,
	GCC.SEGMENT1||'.'||GCC.SEGMENT2||'.'||GCC.SEGMENT3||'.'||
	GCC.SEGMENT4||'.'||GCC.SEGMENT5||'.'||GCC.SEGMENT6||'.'||
	GCC.SEGMENT7||'.'||GCC.SEGMENT8||'.'||GCC.SEGMENT9||'.'||
	GCC.SEGMENT10||'.'||GCC.SEGMENT11||'.'||GCC.SEGMENT12	        CCF,
	FFVV.DESCRIPTION 												LIBELLE_CPTE_LOCAL
    
FROM GL_JE_HEADERS         	GJH,
    GL_JE_LINES        	    GJL,
	GL_JE_CATEGORIES_VL     GJCV,
	GL_LEDGERS 		        GLS ,
    GL_CODE_COMBINATIONS 	GCC ,
	FND_FLEX_VALUE_SETS  	FFVS ,
    FND_FLEX_VALUES_VL   	FFVV ,
	GL_JE_LINES_RECON       REC   ,
	gl_periods              PGL
WHERE      GJH.JE_HEADER_ID 			 = GJL.JE_HEADER_ID
    AND    GLS.LEDGER_ID 			     = GJH.LEDGER_ID
	AND    GJH.JE_CATEGORY               = GJCV.JE_CATEGORY_NAME
    AND    GCC.CODE_COMBINATION_ID 		 = GJL.CODE_COMBINATION_ID
	AND    GJH.CURRENCY_CODE             = 'EUR'
	AND    GJL.status    			     = 'P'
	AND    REC.JE_HEADER_ID              = GJL.JE_HEADER_ID
	AND    REC.JE_LINE_NUM               = GJL.JE_LINE_NUM
	AND    REC.JGZZ_RECON_STATUS         = 'U'
	AND    FFVS.FLEX_VALUE_SET_ID 	     = FFVv.FLEX_VALUE_SET_ID
    AND    FFVS.FLEX_VALUE_SET_NAME      = 'DAOPCCF_LOCAL'
	AND    GCC.SEGMENT3                  = FFVv.FLEX_VALUE
	--AND    to_date(GJH.PERIOD_NAME||'01','MON-YY-DD')  <= P_DATE_FUSION
	and    PGL.period_set_name           = GLS.period_set_name
	and    PGL.period_name               = GJH.PERIOD_NAME
	and    PGL.start_date                <= P_DATE_FUSION
	AND    GLS.short_name                = P_ABSORBEE 
	AND    GLS.ledger_category_code      = 'PRIMARY'
	--------- BILAN 
    AND    substr(FFVV.COMPILED_VALUE_ATTRIBUTES,5,1) in ('O','L','A') 
	--------- NON CORRECTIF
	AND    substr(FFVV.COMPILED_VALUE_ATTRIBUTES,7,1) <> 'Y'
	--------- LETTRABLE
	AND    substr(FFVV.COMPILED_VALUE_ATTRIBUTES,9,1) = 'Y'
    --------- NON RB
    AND NOT EXISTS  ( select 1
					from CE_bank_accounts 		cba ,
						 RB_BANK_ACCOUNTS 		rba 
					where  rba.status 					 = 'Y'
					AND    rba.bank_account_id 			 = cba.bank_account_id
					AND    substr(cba.bank_account_name,10,6)= gcc.SEGMENT3
					AND    substr(cba.bank_account_name,1,4) = P_ABSORBEE
	
					)
    ;
	
 ---------------------------------------------------------------------- 
 -- curseur pour recuperer les donnees soldes gl à extraire : SUIVI RB
 -----------------------------------------------------------------------

  CURSOR C_SUIVI_RB (P_ABSORBEE VARCHAR2, P_ABSORBANTE VARCHAR2 , P_DATE_FUSION  DATE) IS
	SELECT
    'EXTRACTION'   													TYPE_LIGNE,
	'SUIVI RB'  													TYPE_DONNEE,
	P_ABSORBEE 														SOC_ABSORBEE,
	P_ABSORBANTE 													SOC_ABSORBANTE,
	GLS.NAME 														LIVRE,
	GCC.SEGMENT1 													SOCIETE,
    GCC.SEGMENT2 													UO,
    GCC.SEGMENT3 													COMPTE_LOCAL,
    GCC.SEGMENT4 													COMPTE_ANALYTIQUE,
    GCC.SEGMENT5 													INTERCO,
    GCC.SEGMENT6 													CENTRE_FINANCE,
    GCC.SEGMENT7 													CODE_AFFAIRE,
    GCC.SEGMENT8 													PROJET_FINANCE,
    GCC.SEGMENT9 													CODE_FLUX,
    GCC.SEGMENT10 													RESERVE_1,
	GCC.SEGMENT11 													RESERVE_2,
	GCC.SEGMENT12	    											RESERVE_3,
	NVL(GJL.ACCOUNTED_DR,0)                     					DEBIT,
	NVL(GJL.ACCOUNTED_CR,0)										    CREDIT,
	GJL.DESCRIPTION 												DESCRIPTION_LIGNE,
    NULL 															PF,
	NULL 															TF,
	NULL 															TYPE_DEPENSE,
	NULL 															TYPE_EVENEMENT,
	NULL 															QTE,
	NULL 															FRAIS,
	DECODE (context3,'Y.X.Y',GJL.ATTRIBUTE17,NULL)					CODE_CLIENT,															
	DECODE (context3,'RB',GJL.ATTRIBUTE20,NULL)						CODE_INTERBANCAIRE,														
	DECODE (context3,'MAT',GJL.ATTRIBUTE11,NULL) 					MATRICULE_EMPLOYE,														
	NULL 										          		    REF_LETTRAGE,
	GJH.CURRENCY_CODE												DEVISE,
	GJH.CREATION_DATE 												CREATION_DATE,
	GJH.JE_HEADER_ID 												JE_HEADER_ID,
	GJH.PERIOD_NAME 												PERIODE,
	GJCV.USER_JE_CATEGORY_NAME 										CATEGORIE,
	GJH.NAME 														NOM_PIECE,
	GJH.DOC_SEQUENCE_VALUE											NUMERO_PIECE,
	GJL.JE_LINE_NUM 												NUMERO_LIGNE,
	GCC.SEGMENT1||'.'||GCC.SEGMENT2||'.'||GCC.SEGMENT3||'.'||
	GCC.SEGMENT4||'.'||GCC.SEGMENT5||'.'||GCC.SEGMENT6||'.'||
	GCC.SEGMENT7||'.'||GCC.SEGMENT8||'.'||GCC.SEGMENT9||'.'||
	GCC.SEGMENT10||'.'||GCC.SEGMENT11||'.'||GCC.SEGMENT12	        CCF,
	FFVV.DESCRIPTION  												LIBELLE_CPTE_LOCAL
    
FROM GL_JE_HEADERS         	GJH,
    GL_JE_LINES        	    GJL,
	GL_JE_CATEGORIES_VL     GJCV,
	GL_LEDGERS 		        GLS ,
    GL_CODE_COMBINATIONS 	GCC ,
	FND_FLEX_VALUE_SETS  	FFVS ,
    FND_FLEX_VALUES_VL   	FFVV ,
	gl_periods              PGL,
	XXRB.RB_LINES_ALL       RLA
WHERE      GJH.JE_HEADER_ID 			 = GJL.JE_HEADER_ID
    AND    GLS.LEDGER_ID 			     = GJH.LEDGER_ID
	AND    RLA.JE_HEADER_ID              = GJL.JE_HEADER_ID
	AND    RLA.JE_LINE_NUM               = GJL.JE_LINE_NUM
	AND    GJH.JE_CATEGORY               = GJCV.JE_CATEGORY_NAME
    AND    GCC.CODE_COMBINATION_ID 		 = GJL.CODE_COMBINATION_ID
	AND    GJH.CURRENCY_CODE             = 'EUR'
	AND    GJL.status    			     = 'P'
	AND    GJH.ACTUAL_FLAG               = 'A'
	AND    RLA.LINE_TYPE 				 = 'A'
	AND    RLA.MATCHING_STATUS 			 <> 'Y'
    AND    FFVS.FLEX_VALUE_SET_ID 	     = FFVv.FLEX_VALUE_SET_ID
    AND    FFVS.FLEX_VALUE_SET_NAME      = 'DAOPCCF_LOCAL'
	AND    GCC.SEGMENT3                  = FFVv.FLEX_VALUE
--	AND    to_date(GJH.PERIOD_NAME||'01','MON-YY-DD')  <= P_DATE_FUSION	
	and    PGL.period_set_name           = GLS.period_set_name
	and    PGL.period_name               = GJH.PERIOD_NAME
	and    PGL.start_date                <= P_DATE_FUSION
	AND    GLS.short_name                = P_ABSORBEE 
	AND    GLS.ledger_category_code      = 'PRIMARY'
	--------- BILAN 
    AND    substr(FFVV.COMPILED_VALUE_ATTRIBUTES,5,1) in ('O','L','A') 
	--------- NON CORRECTIF
	AND    substr(FFVV.COMPILED_VALUE_ATTRIBUTES,7,1) <> 'Y'
	--------- NON LETTRABLE
	AND    substr(FFVV.COMPILED_VALUE_ATTRIBUTES,9,1) <> 'Y'
	--------- SUIVI RB 
	AND    EXISTS  ( select 1
					from CE_bank_accounts 		cba ,
						 RB_BANK_ACCOUNTS 		rba 
					where  rba.status 					 = 'Y'
					AND    rba.bank_account_id 			 = cba.bank_account_id
					AND    substr(cba.bank_account_name,10,6)= gcc.SEGMENT3
					AND    substr(cba.bank_account_name,1,4) = P_ABSORBEE
	
					)		
    ;
  

  ERRORFILE EXCEPTION;
  n_compteur_collectif NUMBER := 0;
  n_compteur_non_lettrable NUMBER := 0;
  n_compteur_bilan NUMBER := 0;
  n_compteur_lettrable NUMBER := 0;
  n_compteur_RB NUMBER := 0;
  v_num_lig NUMBER :=0;
  
  
BEGIN
	p_errbuf  := NULL;
	p_retcode := 0;
---- Suppression de la table DKA_SGLFUSION_TMP
DELETE from DKA_SGLFUSION_TMP ;
COMMIT;
---- Insertion dans la table
FOR rec_ABS_ABTE IN C_COUPLE_ABS_ABTE LOOP
	
	FOR C_C IN C_COLLECTIF(rec_ABS_ABTE.S_ABSORBE ,rec_ABS_ABTE.S_ABSORBANTE ,rec_ABS_ABTE.D_FUSION ) LOOP 
	begin 
v_num_lig:=v_num_lig + 1;

INSERT INTO DKA_SGLFUSION_TMP
	VALUES (
		 C_C.TYPE_LIGNE          
		,C_C.TYPE_DONNEE         
		,C_C.SOC_ABSORBEE        
		,C_C.SOC_ABSORBANTE      
		,C_C.LIVRE               
		,C_C.SOCIETE             
		,C_C.UO                  
		,C_C.COMPTE_LOCAL        
		,C_C.COMPTE_ANALYTIQUE   
		,C_C.INTERCO             
		,C_C.CENTRE_FINANCE      
		,C_C.CODE_AFFAIRE        
		,C_C.PROJET_FINANCE      
		,C_C.CODE_FLUX           
		,C_C.RESERVE_1           
		,C_C.RESERVE_2           
		,C_C.RESERVE_3           
		,C_C.DEBIT              
		,C_C.CREDIT           
		,C_C.DESCRIPTION_LIGNE   
		,C_C.PF                  
		,C_C.TF                  
		,C_C.TYPE_DEPENSE        
		,C_C.TYPE_EVENEMENT      
		,C_C.QTE                 
		,C_C.FRAIS               
		,C_C.CODE_CLIENT         
		,C_C.CODE_INTERBANCAIRE  
		,C_C.MATRICULE_EMPLOYE   
		,C_C.REF_LETTRAGE         
		,C_C.DEVISE              
		,C_C.CREATION_DATE   
		,C_C.JE_HEADER_ID        
		,C_C.PERIODE            
		,C_C.CATEGORIE           
		,C_C.NOM_PIECE            
		,C_C.NUMERO_PIECE        
		,C_C.NUMERO_LIGNE        
		,C_C.CCF                 
		,C_C.LIBELLE_CPTE_LOCAL
		,C_C.COMPTE_LOCAL        
		,C_C.COMPTE_ANALYTIQUE 
		,C_C.CENTRE_FINANCE      
		,C_C.CODE_AFFAIRE        
		,C_C.PROJET_FINANCE 
		,C_C.SOCIETE
		,C_C.LIVRE
		,C_C.INTERCO 
		,v_num_lig
        );
	
	EXCEPTION
		  WHEN OTHERS THEN
				p_retcode := 1;
                DKA_TOOLS_PKG.Put_Outdebug_Message('problème d''insertion dans la table  DKA_SGLFUSION_TMP :C '|| SQLCODE ||
                                              ' - ' || SQLERRM);
				
END; 
END LOOP;
	COMMIT;

FOR C_NL IN C_NON_LETTRABLES(rec_ABS_ABTE.S_ABSORBE ,rec_ABS_ABTE.S_ABSORBANTE ,rec_ABS_ABTE.D_FUSION ) LOOP 

BEGIN 

v_num_lig:=v_num_lig + 1;
INSERT INTO DKA_SGLFUSION_TMP
	VALUES (
		 C_NL.TYPE_LIGNE          
		,C_NL.TYPE_DONNEE         
		,C_NL.SOC_ABSORBEE        
		,C_NL.SOC_ABSORBANTE      
		,C_NL.LIVRE               
		,C_NL.SOCIETE             
		,C_NL.UO                  
		,C_NL.COMPTE_LOCAL        
		,C_NL.COMPTE_ANALYTIQUE   
		,C_NL.INTERCO             
		,C_NL.CENTRE_FINANCE      
		,C_NL.CODE_AFFAIRE        
		,C_NL.PROJET_FINANCE      
		,C_NL.CODE_FLUX           
		,C_NL.RESERVE_1           
		,C_NL.RESERVE_2           
		,C_NL.RESERVE_3           
		,C_NL.DEBIT               
		,C_NL.CREDIT             
		,C_NL.DESCRIPTION_LIGNE   
		,C_NL.PF                  
		,C_NL.TF                  
		,C_NL.TYPE_DEPENSE        
		,C_NL.TYPE_EVENEMENT      
		,C_NL.QTE                 
		,C_NL.FRAIS               
		,C_NL.CODE_CLIENT         
		,C_NL.CODE_INTERBANCAIRE  
		,C_NL.MATRICULE_EMPLOYE   
		,C_NL.REF_LETTRAGE      
		,C_NL.DEVISE              
		,C_NL.CREATION_DATE   
		,C_NL.JE_HEADER_ID        
		,C_NL.PERIODE            
		,C_NL.CATEGORIE           
		,C_NL.NOM_PIECE            
		,C_NL.NUMERO_PIECE        
		,C_NL.NUMERO_LIGNE        
		,C_NL.CCF                 
		,C_NL.LIBELLE_CPTE_LOCAL
		,C_NL.COMPTE_LOCAL       
		,C_NL.COMPTE_ANALYTIQUE 
		,C_NL.CENTRE_FINANCE     
		,C_NL.CODE_AFFAIRE       
		,C_NL.PROJET_FINANCE 
		,C_NL.SOCIETE
		,C_NL.LIVRE
		,C_NL.INTERCO 
		,v_num_lig
		  );

	
	EXCEPTION
		  WHEN OTHERS THEN
				 p_retcode := 1;
                DKA_TOOLS_PKG.Put_Outdebug_Message('problème d''insertion dans la table  DKA_SGLFUSION_TMP :NL '|| SQLCODE ||
                                              ' - ' || SQLERRM);
				
END;
END LOOP;
	COMMIT;
	
FOR C_HB IN C_HORS_BILAN(rec_ABS_ABTE.S_ABSORBE ,rec_ABS_ABTE.S_ABSORBANTE ,rec_ABS_ABTE.D_FUSION ) LOOP 
BEGIN 
v_num_lig:=v_num_lig + 1;
INSERT INTO DKA_SGLFUSION_TMP
	VALUES (
		 C_HB.TYPE_LIGNE          
		,C_HB.TYPE_DONNEE         
		,C_HB.SOC_ABSORBEE        
		,C_HB.SOC_ABSORBANTE      
		,C_HB.LIVRE               
		,C_HB.SOCIETE             
		,C_HB.UO                  
		,C_HB.COMPTE_LOCAL        
		,C_HB.COMPTE_ANALYTIQUE   
		,C_HB.INTERCO             
		,C_HB.CENTRE_FINANCE      
		,C_HB.CODE_AFFAIRE        
		,C_HB.PROJET_FINANCE      
		,C_HB.CODE_FLUX           
		,C_HB.RESERVE_1           
		,C_HB.RESERVE_2           
		,C_HB.RESERVE_3           
		,C_HB.DEBIT              
		,C_HB.CREDIT             
		,C_HB.DESCRIPTION_LIGNE   
		,C_HB.PF                  
		,C_HB.TF                  
		,C_HB.TYPE_DEPENSE        
		,C_HB.TYPE_EVENEMENT      
		,C_HB.QTE                 
		,C_HB.FRAIS               
		,C_HB.CODE_CLIENT         
		,C_HB.CODE_INTERBANCAIRE  
		,C_HB.MATRICULE_EMPLOYE   
		,C_HB.REF_LETTRAGE         
		,C_HB.DEVISE              
		,C_HB.CREATION_DATE  
		,C_HB.JE_HEADER_ID        
		,C_HB.PERIODE            
		,C_HB.CATEGORIE           
		,C_HB.NOM_PIECE            
		,C_HB.NUMERO_PIECE        
		,C_HB.NUMERO_LIGNE        
		,C_HB.CCF                 
		,C_HB.LIBELLE_CPTE_LOCAL  
		,C_HB.COMPTE_LOCAL       
        ,C_HB.COMPTE_ANALYTIQUE 
        ,C_HB.CENTRE_FINANCE     
        ,C_HB.CODE_AFFAIRE       
        ,C_HB.PROJET_FINANCE 
        ,C_HB.SOCIETE
        ,C_HB.LIVRE
		,C_HB.INTERCO 
		,v_num_lig		
				);

	
	EXCEPTION
		  WHEN OTHERS THEN
				 p_retcode := 1;
                DKA_TOOLS_PKG.Put_Outdebug_Message('problème d''insertion dans la table  DKA_SGLFUSION_TMP :HB '|| SQLCODE ||
                                              ' - ' || SQLERRM);
				
END;
END LOOP;
	COMMIT;
	
FOR C_L IN C_LETTRABLES(rec_ABS_ABTE.S_ABSORBE ,rec_ABS_ABTE.S_ABSORBANTE ,rec_ABS_ABTE.D_FUSION ) LOOP 
BEGIN
v_num_lig:=v_num_lig + 1;
INSERT INTO DKA_SGLFUSION_TMP
	VALUES (
		 C_L.TYPE_LIGNE          
		,C_L.TYPE_DONNEE         
		,C_L.SOC_ABSORBEE        
		,C_L.SOC_ABSORBANTE      
		,C_L.LIVRE               
		,C_L.SOCIETE             
		,C_L.UO                  
		,C_L.COMPTE_LOCAL        
		,C_L.COMPTE_ANALYTIQUE   
		,C_L.INTERCO             
		,C_L.CENTRE_FINANCE      
		,C_L.CODE_AFFAIRE        
		,C_L.PROJET_FINANCE      
		,C_L.CODE_FLUX           
		,C_L.RESERVE_1           
		,C_L.RESERVE_2           
		,C_L.RESERVE_3           
		,C_L.DEBIT               
		,C_L.CREDIT             
		,C_L.DESCRIPTION_LIGNE   
		,C_L.PF                  
		,C_L.TF                  
		,C_L.TYPE_DEPENSE        
		,C_L.TYPE_EVENEMENT      
		,C_L.QTE                 
		,C_L.FRAIS               
		,C_L.CODE_CLIENT         
		,C_L.CODE_INTERBANCAIRE  
		,C_L.MATRICULE_EMPLOYE   
		,C_L.REF_LETTRAGE        
		,C_L.DEVISE              
		,C_L.CREATION_DATE  
		,C_L.JE_HEADER_ID        
		,C_L.PERIODE            
		,C_L.CATEGORIE           
		,C_L.NOM_PIECE            
		,C_L.NUMERO_PIECE        
		,C_L.NUMERO_LIGNE        
		,C_L.CCF                 
		,C_L.LIBELLE_CPTE_LOCAL 
		,C_L.COMPTE_LOCAL      
		,C_L.COMPTE_ANALYTIQUE 
		,C_L.CENTRE_FINANCE    
		,C_L.CODE_AFFAIRE      
		,C_L.PROJET_FINANCE 
		,C_L.SOCIETE
		,C_L.LIVRE
		,C_L.INTERCO 
		,v_num_lig		
		);

	
	
	
	EXCEPTION
		  WHEN OTHERS THEN
				 p_retcode := 1;
                DKA_TOOLS_PKG.Put_Outdebug_Message('problème d''insertion dans la table  DKA_SGLFUSION_TMP :L '||C_L.JE_HEADER_ID ||' :END '||SQLCODE ||
                                              ' - ' || SQLERRM);
				

END;
END LOOP;
	COMMIT;
	
FOR C_RB IN C_SUIVI_RB(rec_ABS_ABTE.S_ABSORBE ,rec_ABS_ABTE.S_ABSORBANTE ,rec_ABS_ABTE.D_FUSION ) LOOP 
BEGIN
v_num_lig:=v_num_lig + 1;
INSERT INTO DKA_SGLFUSION_TMP
	VALUES (
		 C_RB.TYPE_LIGNE          
		,C_RB.TYPE_DONNEE         
		,C_RB.SOC_ABSORBEE        
		,C_RB.SOC_ABSORBANTE      
		,C_RB.LIVRE               
		,C_RB.SOCIETE             
		,C_RB.UO                  
		,C_RB.COMPTE_LOCAL        
		,C_RB.COMPTE_ANALYTIQUE   
		,C_RB.INTERCO             
		,C_RB.CENTRE_FINANCE      
		,C_RB.CODE_AFFAIRE        
		,C_RB.PROJET_FINANCE      
		,C_RB.CODE_FLUX           
		,C_RB.RESERVE_1           
		,C_RB.RESERVE_2           
		,C_RB.RESERVE_3           
		,C_RB.DEBIT              
		,C_RB.CREDIT             
		,C_RB.DESCRIPTION_LIGNE   
		,C_RB.PF                  
		,C_RB.TF                  
		,C_RB.TYPE_DEPENSE        
		,C_RB.TYPE_EVENEMENT      
		,C_RB.QTE                 
		,C_RB.FRAIS               
		,C_RB.CODE_CLIENT         
		,C_RB.CODE_INTERBANCAIRE  
		,C_RB.MATRICULE_EMPLOYE   
		,C_RB.REF_LETTRAGE        
		,C_RB.DEVISE              
		,C_RB.CREATION_DATE  
		,C_RB.JE_HEADER_ID        
		,C_RB.PERIODE            
		,C_RB.CATEGORIE           
		,C_RB.NOM_PIECE           
		,C_RB.NUMERO_PIECE        
		,C_RB.NUMERO_LIGNE        
		,C_RB.CCF                 
		,C_RB.LIBELLE_CPTE_LOCAL
		,C_RB.COMPTE_LOCAL      
		,C_RB.COMPTE_ANALYTIQUE 
		,C_RB.CENTRE_FINANCE    
		,C_RB.CODE_AFFAIRE      
		,C_RB.PROJET_FINANCE 
		,C_RB.SOCIETE
		,C_RB.LIVRE
		,C_RB.INTERCO 
		,v_num_lig
				);
	
	
	EXCEPTION
	
		  WHEN OTHERS THEN
				p_retcode := 1;
                DKA_TOOLS_PKG.Put_Outdebug_Message('problème d''insertion dans la table  DKA_SGLFUSION_TMP :RB '|| SQLCODE ||
                                              ' - ' || SQLERRM);
				
END;
END LOOP; 
END LOOP;
COMMIT;
END EXTRACT_DATA;

 /*************************************************************************
 * PROCEDURE NAME : UPDATE_TMP
 *
 * DESCRIPTION
 *  Procédure MAJ table TMP
 *
 * PARAMETERS
 * ==========
 * NAME              DESCRIPTION
 * ----------------- ------------------------------------------------------
 *
 *
 ************************************************************************
 */
 
PROCEDURE UPDATE_TMP (
	p_compte_local		in varchar2,
	p_compte_analytique in varchar2,
	p_centre_finance    in varchar2,
	p_code_affaire	  	in varchar2,
	p_project_finance 	in varchar2,
	p_societe           in varchar2,
	p_livre             in varchar2,
	p_interco           in varchar2,
    p_NUM_LIG       in number
	) IS
BEGIN

update DKA_SGLFUSION_TMP 
	SET 
	 compte_local		= p_compte_local
	,compte_analytique	= p_compte_analytique
	,centre_finance		= p_centre_finance
	,code_affaire	  	= p_code_affaire	  						
	,projet_finance 	= p_project_finance 			
    ,societe            = p_societe
    ,livre              = p_livre 
	,interco            = p_interco
	WHERE num_lig 		= p_NUM_LIG
		and TYPE_LIGNE = 'EXTRACTION';
commit;

END;	
	
	

/*
 *************************************************************************
 * PROCEDURE NAME : VALIDATE_DATA
 *
 * DESCRIPTION
 *  Procédure pour traiter les données extraites 
 *
 * PARAMETERS
 * ==========
 * NAME              DESCRIPTION
 * ----------------- ------------------------------------------------------
 *
 *
 ************************************************************************
 */
 
PROCEDURE VALIDATE_DATA  (  p_Errbuf            OUT VARCHAR2,
                            p_retcode           OUT NUMBER ,
							p_type_fusion       IN VARCHAR2
                          )   IS
					
	V_DEBIT               	 NUMBER;
	V_CREDIT               	 NUMBER;	
	V_TYPE_LIGNE             VARCHAR2(25);
	v_compte_local			 VARCHAR2(25);
	v_compte_local_6		 VARCHAR2(25);
	v_compte_local_7		 VARCHAR2(25);
	v_compte_local_10		 VARCHAR2(25);
	v_compte_local_40		 VARCHAR2(25);
	v_compte_local_41		 VARCHAR2(25);
	v_compte_local_416		 VARCHAR2(25);
	v_compte_analytique_6	 VARCHAR2(25);
	v_compte_analytique_7	 VARCHAR2(25);
	v_compte_analytique_10	 VARCHAR2(25);
	v_compte_analytique_40	 VARCHAR2(25);
	v_compte_analytique_41	 VARCHAR2(25);
	v_compte_analytique_416	 VARCHAR2(25);
	v_compte_net			 VARCHAR2(25);
    v_compte_analytique      VARCHAR2(25);
	v_compte_analy           VARCHAR2(25);
    v_livre                  VARCHAR2(25);
	v_interco				 VARCHAR2(25);
    v_SOCIETE                VARCHAR2(25);
	v_date_fin_periode       DATE;
	v_centre_finance 	 	 VARCHAR2(25);
	v_code_affaire   		 VARCHAR2(25);	
	v_project_finance		 VARCHAR2(25);
	v_centre_finance_6 	 	 VARCHAR2(25);
	v_code_affaire_6   		 VARCHAR2(25);	
	v_project_finance_6		 VARCHAR2(25);
    v_num_lig                NUMBER :=0;	
	
	CURSOR CUR_ANNULATION IS
      SELECT *
      FROM DKA_SGLFUSION_TMP;
	
	CURSOR CUR_EXTRACTION IS 
	  SELECT *
      FROM DKA_SGLFUSION_TMP
	  WHERE TYPE_LIGNE = 'EXTRACTION';
	  --and rownum<3      ;

    

BEGIN
------------------------ MISE A JOUR DES SEGMENT ANALYTIQUE -----------------------------------------
BEGIN 
		SELECT  return_value
		INTO v_centre_finance_6
		FROM DKA_STRANSCO_LINES DSTL,
        DKA_STRANSCO_HEADERS    DSTH
		WHERE  DSTH.SET_NAME LIKE 'FUSION_COMPTES_GEN'
		AND    DSTL.ENABLE					 = 'Y'
		AND    NVL(DSTL.END_DATE,TRUNC(SYSDATE))>= TRUNC(SYSDATE)
		and param1_value  ='GL'
		and  param2_value ='CENTRE FINANCE';
EXCEPTION WHEN OTHERS THEN 
        p_retcode := 1;
	    DKA_TOOLS_PKG.Put_Outdebug_Message('Problème de recupération du CENTRE FINANCE pour le module « GL » et le segment « CENTRE FINANCE » '|| SQLCODE ||
					  ' - ' || SQLERRM);

END;			
BEGIN 
		SELECT  return_value
		INTO v_code_affaire_6
		FROM DKA_STRANSCO_LINES DSTL,
        DKA_STRANSCO_HEADERS    DSTH
		WHERE  DSTH.SET_NAME LIKE 'FUSION_COMPTES_GEN'
		AND    DSTL.ENABLE					 = 'Y'
		AND    NVL(DSTL.END_DATE,TRUNC(SYSDATE))>= TRUNC(SYSDATE)
		and param1_value  ='GL'
		and  param2_value ='CODE AFFAIRE';
EXCEPTION WHEN OTHERS THEN 
        p_retcode := 1;
        DKA_TOOLS_PKG.Put_Outdebug_Message('Problème de recupération du CODE AFFAIRE pour le module « GL » et le segment « CODE AFFAIRE » '|| SQLCODE ||
					  ' - ' || SQLERRM);

END;			
BEGIN 		
		SELECT  return_value
		INTO v_project_finance_6
		FROM DKA_STRANSCO_LINES DSTL,
			 DKA_STRANSCO_HEADERS    DSTH
		WHERE  DSTH.SET_NAME LIKE 'FUSION_COMPTES_GEN'
		AND    DSTL.ENABLE					 = 'Y'
		AND    NVL(DSTL.END_DATE,TRUNC(SYSDATE))>= TRUNC(SYSDATE)
		and param1_value  ='GL'
		and  param2_value ='PROJET FINANCE';
EXCEPTION WHEN OTHERS THEN 
        p_retcode := 1;
        DKA_TOOLS_PKG.Put_Outdebug_Message('Problème de recupération du projet finance pour le module « GL » et le segment « PROJET FINANCE » '|| SQLCODE ||
					  ' - ' || SQLERRM);
END;
BEGIN
		SELECT return_value
		INTO v_compte_local_6
		FROM 	DKA_STRANSCO_LINES DSTL,
			    DKA_STRANSCO_HEADERS DSTH
		WHERE  	DSTH.SET_NAME LIKE 'FUSION_COMPTES_GEN'
		AND    	DSTL.ENABLE					 = 'Y'
		AND    	NVL(DSTL.END_DATE,TRUNC(SYSDATE))>= TRUNC(SYSDATE)
		and param1_value  = 'GL'
		and  param2_value = 'TUP COMPTE CHARGES';
	EXCEPTION WHEN OTHERS THEN 
        p_retcode := 1;
        DKA_TOOLS_PKG.Put_Outdebug_Message('Problème de recupération du compte local pour le module « GL » et le segment « TUP COMPTE CHARGES » '|| SQLCODE ||
					  ' - ' || SQLERRM);
END;
BEGIN		
		SELECT return_value 
		INTO v_compte_analytique_6
		FROM 	DKA_STRANSCO_LINES DSTL,
			    DKA_STRANSCO_HEADERS    DSTH
		WHERE  	DSTH.SET_NAME LIKE 'MIGR_GROUP_ACCOUNT_CLASS_BILAN'
		AND    	DSTL.ENABLE					 = 'Y'
		AND    	NVL(DSTL.END_DATE,TRUNC(SYSDATE))>= TRUNC(SYSDATE)
		and param1_value  = v_compte_local_6;	
	EXCEPTION WHEN OTHERS THEN 
        p_retcode := 1;
        DKA_TOOLS_PKG.Put_Outdebug_Message('Problème de recupération du compte analytique pour le compte local : '||v_compte_local_6 ||  '/' ||SQLCODE ||
					  ' - ' || SQLERRM);

	

END;
BEGIN
	    SELECT return_value
		INTO v_compte_local_7
		FROM 	DKA_STRANSCO_LINES DSTL,
			    DKA_STRANSCO_HEADERS    DSTH
		WHERE  	DSTH.SET_NAME LIKE 'FUSION_COMPTES_GEN'
		AND    	DSTL.ENABLE					 = 'Y'
		AND    	NVL(DSTL.END_DATE,TRUNC(SYSDATE))>= TRUNC(SYSDATE)
		and param1_value  = 'GL'
		and  param2_value = 'TUP COMPTE PRODUITS';
	EXCEPTION WHEN OTHERS THEN 
        p_retcode := 1;
        DKA_TOOLS_PKG.Put_Outdebug_Message('Problème de recupération du compte local pour le module « GL » et le segment « TUP COMPTE PRODUITS » '|| SQLCODE ||
					  ' - ' || SQLERRM);

END;
BEGIN	
	SELECT return_value 
		INTO v_compte_analytique_7
		FROM 	DKA_STRANSCO_LINES DSTL,
			    DKA_STRANSCO_HEADERS    DSTH
		WHERE  	DSTH.SET_NAME LIKE 'MIGR_GROUP_ACCOUNT_CLASS_BILAN'
		AND    	DSTL.ENABLE					 = 'Y'
		AND    	NVL(DSTL.END_DATE,TRUNC(SYSDATE))>= TRUNC(SYSDATE)
		and param1_value  = v_compte_local_7;	
	EXCEPTION WHEN OTHERS THEN 
        p_retcode := 1;
        DKA_TOOLS_PKG.Put_Outdebug_Message('Problème de recupération du compte analytique pour le compte local : '||v_compte_local_7 || '/' ||SQLCODE ||
					  ' - ' || SQLERRM);
END;
BEGIN
		SELECT return_value
		INTO v_compte_local_40
		FROM 	DKA_STRANSCO_LINES DSTL,
			    DKA_STRANSCO_HEADERS    DSTH
		WHERE  	DSTH.SET_NAME LIKE 'FUSION_COMPTES_GEN'
		AND    	DSTL.ENABLE					 = 'Y'
		AND    	NVL(DSTL.END_DATE,TRUNC(SYSDATE))>= TRUNC(SYSDATE)
		and param1_value  ='AP'
		and  param2_value ='Compte local';
	EXCEPTION WHEN OTHERS THEN 
        p_retcode := 1;
        DKA_TOOLS_PKG.Put_Outdebug_Message('Problème de recupération du compte local pour le module « AP » et le segment « Compte local » '|| SQLCODE ||
					  ' - ' || SQLERRM);
END;
BEGIN					  
		SELECT return_value 
		INTO v_compte_analytique_40
		FROM 	DKA_STRANSCO_LINES DSTL,
			    DKA_STRANSCO_HEADERS    DSTH
		WHERE  	DSTH.SET_NAME LIKE 'MIGR_GROUP_ACCOUNT_CLASS_BILAN'
		AND    	DSTL.ENABLE					 = 'Y'
		AND    	NVL(DSTL.END_DATE,TRUNC(SYSDATE))>= TRUNC(SYSDATE)
		and param1_value  = v_compte_local_40;	
	EXCEPTION WHEN OTHERS THEN 
        p_retcode := 1;
        DKA_TOOLS_PKG.Put_Outdebug_Message('Problème de recupération du compte analytique pour le compte local : '||v_compte_local_40 || '/' ||SQLCODE ||
					  ' - ' || SQLERRM);

	END;
	
BEGIN
		SELECT return_value
		INTO v_compte_local_41
		FROM 	DKA_STRANSCO_LINES DSTL,
			    DKA_STRANSCO_HEADERS    DSTH
		WHERE  	DSTH.SET_NAME LIKE 'FUSION_COMPTES_GEN'
		AND    	DSTL.ENABLE					 = 'Y'
		AND    	NVL(DSTL.END_DATE,TRUNC(SYSDATE))>= TRUNC(SYSDATE)
		and param1_value  ='AR'
		and  param2_value ='Compte local client';
	EXCEPTION WHEN OTHERS THEN 
        p_retcode := 1;
        DKA_TOOLS_PKG.Put_Outdebug_Message('Problème de recupération du compte local pour le module « AR » et le segment « Compte local client » '|| SQLCODE ||
					  ' - ' || SQLERRM);
END;
BEGIN		
		SELECT return_value 
		INTO v_compte_analytique_41
		FROM 	DKA_STRANSCO_LINES DSTL,
			    DKA_STRANSCO_HEADERS    DSTH
		WHERE  	DSTH.SET_NAME LIKE 'MIGR_GROUP_ACCOUNT_CLASS_BILAN'
		AND    	DSTL.ENABLE					 = 'Y'
		AND    	NVL(DSTL.END_DATE,TRUNC(SYSDATE))>= TRUNC(SYSDATE)
		and param1_value  = v_compte_local_41;	
	EXCEPTION WHEN OTHERS THEN 
        p_retcode := 1;
		DKA_TOOLS_PKG.Put_Outdebug_Message('Problème de recupération du compte analytique pour le compte local : '||v_compte_local_41 || '/' ||SQLCODE ||
					  ' - ' || SQLERRM);

	END;
BEGIN
		SELECT return_value
		INTO v_compte_local_416
		FROM 	DKA_STRANSCO_LINES DSTL,
			    DKA_STRANSCO_HEADERS    DSTH
		WHERE  	DSTH.SET_NAME LIKE 'FUSION_COMPTES_GEN'
		AND    	DSTL.ENABLE					 = 'Y'
		AND    	NVL(DSTL.END_DATE,TRUNC(SYSDATE))>= TRUNC(SYSDATE)
		and param1_value  ='AR'
		and  param2_value ='Compte local douteux';
	EXCEPTION WHEN OTHERS THEN 
        p_retcode := 1;
        DKA_TOOLS_PKG.Put_Outdebug_Message('Problème de recupération du compte local pour le module « AR » et le segment « Compte local douteux » '|| SQLCODE ||
					  ' - ' || SQLERRM);
END;
BEGIN					  
		SELECT return_value 
		INTO v_compte_analytique_416
		FROM 	DKA_STRANSCO_LINES DSTL,
			    DKA_STRANSCO_HEADERS    DSTH
		WHERE  	DSTH.SET_NAME LIKE 'MIGR_GROUP_ACCOUNT_CLASS_BILAN'
		AND    	DSTL.ENABLE					 = 'Y'
		AND    	NVL(DSTL.END_DATE,TRUNC(SYSDATE))>= TRUNC(SYSDATE)
		and param1_value  = v_compte_local_416;	
	EXCEPTION WHEN OTHERS THEN 
        p_retcode := 1;
        DKA_TOOLS_PKG.Put_Outdebug_Message('Problème de recupération du compte analytique pour le compte local : '||v_compte_local_416 || '/' ||SQLCODE ||
					  ' - ' || SQLERRM);

	END;
BEGIN
		SELECT return_value
		INTO v_compte_local_10
		FROM 	DKA_STRANSCO_LINES DSTL,
			    DKA_STRANSCO_HEADERS    DSTH
		WHERE  	DSTH.SET_NAME LIKE 'FUSION_COMPTES_GEN'
		AND    	DSTL.ENABLE					 = 'Y'
		AND    	NVL(DSTL.END_DATE,TRUNC(SYSDATE))>= TRUNC(SYSDATE)
		and param1_value  ='GL'
		and  param2_value ='CPTES DE SITUATION NETTE';
	EXCEPTION WHEN OTHERS THEN 
        p_retcode := 1;
        DKA_TOOLS_PKG.Put_Outdebug_Message('Problème de recupération du compte local pour le module « GL » et le segment « CPTES DE SITUATION NETTE » '|| SQLCODE ||
					  ' - ' || SQLERRM);
END;
BEGIN		
		SELECT return_value 
		INTO v_compte_analytique_10
		FROM 	DKA_STRANSCO_LINES DSTL,
			    DKA_STRANSCO_HEADERS    DSTH
		WHERE  	DSTH.SET_NAME LIKE 'MIGR_GROUP_ACCOUNT_CLASS_BILAN'
		AND    	DSTL.ENABLE					 = 'Y'
		AND    	NVL(DSTL.END_DATE,TRUNC(SYSDATE))>= TRUNC(SYSDATE)
		and param1_value  = v_compte_local_10;	
	EXCEPTION WHEN OTHERS THEN 
        p_retcode := 1;
        DKA_TOOLS_PKG.Put_Outdebug_Message('Problème de recupération du compte analytique pour le compte local : '||v_compte_local_10 || '/' ||SQLCODE ||
					  ' - ' || SQLERRM);

	END;		
	
	V_TYPE_LIGNE := 'ANNULATION';
	
--- REG.4.2.2.1 :	 Création des lignes d'annulation
-------------------------------------------------------

/***************** Ligne Annulation *********************/
BEGIN
FOR REC_A IN CUR_ANNULATION LOOP 

----------------------------------------------	
 if (substr(REC_A.COMPTE_LOCAL,1,1 )in (6,7))THEN 
 
	V_CENTRE_FINANCE 	:= V_CENTRE_FINANCE_6;
	V_CODE_AFFAIRE  	:= V_CODE_AFFAIRE_6 ;	
	V_PROJECT_FINANCE 	:= V_PROJECT_FINANCE_6;
 
ELSE 
	V_CENTRE_FINANCE 	:= REC_A.CENTRE_FINANCE;
	V_CODE_AFFAIRE  	:= REC_A.CODE_AFFAIRE;
	V_PROJECT_FINANCE   := REC_A.PROJET_FINANCE;		
END IF;

	V_DEBIT    := REC_A.CREDIT;
	V_CREDIT   := REC_A.DEBIT;
	select max(num_lig) into v_num_lig from DKA_SGLFUSION_TMP;
	v_num_lig := v_num_lig +1;
------------------------------------------------	
	INSERT INTO DKA_SGLFUSION_TMP
	VALUES (
		 V_TYPE_LIGNE          
		,REC_A.TYPE_DONNEE         
		,REC_A.SOC_ABSORBEE        
		,REC_A.SOC_ABSORBANTE      
		,REC_A.LIVRE               
		,REC_A.SOCIETE             
		,REC_A.UO                  
		,REC_A.COMPTE_LOCAL        
		,REC_A.COMPTE_ANALYTIQUE   
		,REC_A.INTERCO             
		,V_CENTRE_FINANCE     
		,V_CODE_AFFAIRE      
		,V_PROJECT_FINANCE    
		,REC_A.CODE_FLUX           
		,REC_A.RESERVE_1           
		,REC_A.RESERVE_2           
		,REC_A.RESERVE_3           
		,V_DEBIT                
		,V_CREDIT              
		,REC_A.DESCRIPTION_LIGNE   
		,REC_A.PF                  
		,REC_A.TF                  
		,REC_A.TYPE_DEPENSE        
		,REC_A.TYPE_EVENEMENT      
		,REC_A.QTE                 
		,REC_A.FRAIS               
		,REC_A.CODE_CLIENT         
		,REC_A.CODE_INTERBANCAIRE  
		,REC_A.MATRICULE_EMPLOYE   
		,REC_A.REF_LETTRAGE        
		,REC_A.DEVISE              
		,REC_A.CREATION_DATE       
		,REC_A.JE_HEADER_ID        
		,REC_A.PERIODE             
		,REC_A.CATEGORIE           
		,REC_A.NOM_PIECE           
		,REC_A.NUMERO_PIECE        
		,REC_A.NUMERO_LIGNE        
		,REC_A.CCF                 
		,REC_A.LIBELLE_CPTE_LOCAL  
		,REC_A.COMPTE_LOCAL      
		,REC_A.COMPTE_ANALYTIQUE 
		,REC_A.CENTRE_FINANCE    
		,REC_A.CODE_AFFAIRE      
		,REC_A.PROJET_FINANCE 
		,REC_A.SOCIETE
		,REC_A.LIVRE
		,REC_A.INTERCO 
        ,v_num_lig
        

				);
	
	END LOOP;
	COMMIT;
DKA_TOOLS_PKG.Put_Outdebug_Message('type fusion   '||p_type_fusion);	
/***************** Ligne EXTRACTION *********************/	
FOR REC_E IN CUR_EXTRACTION LOOP 
BEGIN
	
------Modification de la societe
  v_societe := REC_E.soc_absorbante;
------Modification du livre
  BEGIN
  select     gl.NAME 
     into v_livre
   FROM 
    gl_balances 			bal ,
    GL_LEDGERS		gl ,
    gl_code_combinations 	gcc 
   WHERE 
    bal.code_combination_id = gcc.code_combination_id
    AND    bal.ledger_id 		   = gl.ledger_id
	AND    gcc.SEGMENT1            = REC_E.soc_absorbante
    and rownum <2;
end;
------------------- COMPTE LOCAL
BEGIN
if (p_type_fusion = 'TUP' )	then
	if substr(REC_E.COMPTE_LOCAL,1,1 )= 6 then 
	v_compte_local      := v_compte_local_6;
	v_compte_analytique	:= v_compte_analytique_6;
	elsif substr(REC_E.COMPTE_LOCAL,1,1 )= 7 then 
	v_compte_local		:= v_compte_local_7;
	v_compte_analytique	:= v_compte_analytique_7;
	END IF;
END IF; 

if(	REC_E.TYPE_DONNEE = 'COLLECTIFS') then 
	if (REC_E.COMPTE_LOCAL = '425550' or SUBSTR(REC_E.COMPTE_LOCAL,1,2) ='40')THEN 
	v_compte_local		:= v_compte_local_40;
	v_compte_analytique	:= v_compte_analytique_40;	
	elsif (SUBSTR(REC_E.COMPTE_LOCAL,1,2) = '41' and SUBSTR(REC_E.COMPTE_LOCAL,1,3) <> '416')THEN
	v_compte_local		:= v_compte_local_41;
	v_compte_analytique	:= v_compte_analytique_41;
	elsif (SUBSTR(REC_E.COMPTE_LOCAL,1,3) = '416')THEN
	v_compte_local		:= v_compte_local_416;
	v_compte_analytique	:= v_compte_analytique_416;
	END IF;
END IF;

  

if(substr(REC_E.COMPTE_LOCAL,1,2 )in ('10','11','12','13','14'))THEN 
	v_compte_local		:= v_compte_local_10;
	v_compte_analytique	:= v_compte_analytique_10;
	v_interco 			:= 'XXX'||REC_E.soc_absorbee;
ELSE 
	v_interco  			:= REC_E.interco;
END IF;

IF ( v_compte_local is null) then
	v_compte_local         := REC_E.COMPTE_LOCAL ;
	v_compte_analytique	   := REC_E.COMPTE_ANALYTIQUE ;
END IF;

if (substr(REC_E.COMPTE_LOCAL,1,1 )in ('6','7'))THEN 
 
	V_CENTRE_FINANCE 	:= V_CENTRE_FINANCE_6;
	V_CODE_AFFAIRE  	:= V_CODE_AFFAIRE_6 ;	
	V_PROJECT_FINANCE 	:= V_PROJECT_FINANCE_6;
 
ELSE 
	V_CENTRE_FINANCE 	:= REC_E.CENTRE_FINANCE;
	V_CODE_AFFAIRE  	:= REC_E.CODE_AFFAIRE;
	V_PROJECT_FINANCE   := REC_E.PROJET_FINANCE;		
END IF;


		
END;

------------------------ MISE A JOUR DE LA TABLE DKA_SGLFUSION_TMP -----------------------------------------
	BEGIN	
	UPDATE_TMP (
	v_compte_local		,
	v_compte_analytique ,
	v_centre_finance    ,
	v_code_affaire	  	,
	v_project_finance 	,
	v_societe           ,
	v_livre             ,
	v_interco           ,
    rec_E.NUM_LIG
	);

	EXCEPTION
	when others then
	Fnd_File.put_line (Fnd_File.LOG, 'problème d''update dans la table DKA_SGLFUSION_TMP  :' ||SQLERRM);
	END;
END;

-------Reinitialiser les variables :
	v_compte_local		:= NULL;
	v_compte_analytique	:= NULL;
	v_interco           := NULL;
	v_societe			:= NULL;
	v_livre				:= NULL;
---------------------------------------------
END LOOP;
    COMMIT;
END ;

END VALIDATE_DATA; 
/*
 *************************************************************************
 * PROCEDURE NAME : IMPORT_DATA
 *
 * DESCRIPTION
 *  Procédure pour importer les données extraites  
 *
 * PARAMETERS
 * ==========
 * NAME              DESCRIPTION
 * ----------------- ------------------------------------------------------
 *
 *
 ************************************************************************
 */

PROCEDURE IMPORT_DATA  	 (  p_Errbuf            OUT VARCHAR2,
                            p_retcode           OUT NUMBER
                          )   IS
					
	-- variable pour le fichier de sortie
	p_fic_out_ptr_c           UTL_FILE.FILE_TYPE;
	p_fic_out_ptr_rc          UTL_FILE.FILE_TYPE;
	p_fic_out_ptr_h_b         UTL_FILE.FILE_TYPE;
	p_fic_out_ptr_l           UTL_FILE.FILE_TYPE;
	p_fic_out_ptr_rb          UTL_FILE.FILE_TYPE;
	p_fic_out_ptr_nl          UTL_FILE.FILE_TYPE;
	p_fic_out_ptr_rnl          UTL_FILE.FILE_TYPE;
	p_fic_out_ptr_rh_b         UTL_FILE.FILE_TYPE;
	p_fic_out_ptr_rl           UTL_FILE.FILE_TYPE;
	p_fic_out_ptr_rrb          UTL_FILE.FILE_TYPE;
	pv_dir_out             	  VARCHAR2(120);
	pv_fic_out_name        	  VARCHAR2(80);
	pv_fic_out_name_c      	  VARCHAR2(80);
	pv_fic_out_name_rc        VARCHAR2(80);
	pv_fic_out_name_h_b    	  VARCHAR2(80);
	pv_fic_out_name_rh_b      VARCHAR2(80);
	pv_fic_out_name_l      	  VARCHAR2(80);
	pv_fic_out_name_rl        VARCHAR2(80);
	pv_fic_out_name_rb     	  VARCHAR2(80);
	pv_fic_out_name_rrb       VARCHAR2(80);
	pv_fic_out_name_nl     	  VARCHAR2(80);
	pv_fic_out_name_rnl       VARCHAR2(80);
	pv_err_msg             	  VARCHAR2(2000);
	cv_seperator 			  VARCHAR2(1)  :=  ';';
	 
	CURSOR CUR_AFFICHAGE IS
		SELECT distinct soc_absorbee SOC_ABSORBEE
		,soc_absorbante SOC_ABSORBANTE
		FROM DKA_SGLFUSION_TMP;
		
    CURSOR CUR_DETAIL_ANNU(absorbee varchar2 , absorbante varchar2) IS
		SELECT *
		FROM DKA_SGLFUSION_TMP
		where SOC_ABSORBEE = absorbee
		AND SOC_ABSORBANTE = absorbante
		AND TYPE_LIGNE='ANNULATION'
		AND TYPE_DONNEE in ('LETTRABLES','SUIVI RB')
	    AND (DEBIT <> 0 OR CREDIT <> 0);
		
	CURSOR CUR_SOLDE_ANNU(absorbee varchar2 , absorbante varchar2) IS
		SELECT
		TYPE_DONNEE,
		LIVRE,
		SOCIETE,
		UO,
		COMPTE_LOCAL,
		COMPTE_ANALYTIQUE,
		INTERCO,
		CENTRE_FINANCE,
		CODE_AFFAIRE,
		PROJET_FINANCE,
		CODE_FLUX,
		RESERVE_1,
		RESERVE_2,
		RESERVE_3,
		SUM(NVL(DEBIT,0)) DEBIT,
		SUM(NVL(CREDIT,0)) CREDIT,
		DESCRIPTION_LIGNE,
		PF,
		TF,
		TYPE_DEPENSE,
		TYPE_EVENEMENT,
		QTE,
		FRAIS,
		CODE_CLIENT,
		CODE_INTERBANCAIRE,
		MATRICULE_EMPLOYE,
		REF_LETTRAGE,
		DEVISE,
		CREATION_DATE,
		JE_HEADER_ID,
		PERIODE,
		CATEGORIE,
		NOM_PIECE, 
		NUMERO_PIECE,
		NUMERO_LIGNE, 
		CCF,
		LIBELLE_CPTE_LOCAL
	    FROM DKA_SGLFUSION_TMP
		where SOC_ABSORBEE = absorbee
		AND SOC_ABSORBANTE = absorbante
		AND TYPE_DONNEE in ('COLLECTIFS','HORS BILAN','NON LETTRABLES')
		AND TYPE_LIGNE='ANNULATION'
		AND (DEBIT <> 0 OR CREDIT <> 0)
		GROUP BY 
		TYPE_DONNEE,
		LIVRE,
		SOCIETE,
		UO,
		COMPTE_LOCAL,
		COMPTE_ANALYTIQUE,
		INTERCO,
		CENTRE_FINANCE,
		CODE_AFFAIRE,
		PROJET_FINANCE,
		CODE_FLUX,
		RESERVE_1,
		RESERVE_2,
		RESERVE_3,
		DESCRIPTION_LIGNE,
		PF,
		TF,
		TYPE_DEPENSE,
		TYPE_EVENEMENT,
		QTE,
		FRAIS,
		CODE_CLIENT,
		CODE_INTERBANCAIRE,
		MATRICULE_EMPLOYE,
		REF_LETTRAGE,
		DEVISE,
		CREATION_DATE,
		JE_HEADER_ID,
		PERIODE,
		CATEGORIE,
		NOM_PIECE, 
		NUMERO_PIECE,
		NUMERO_LIGNE, 
		CCF,
		LIBELLE_CPTE_LOCAL
		HAVING (SUM(NVL(DEBIT,0) - NVL(CREDIT,0))<> 0);	
	
	 CURSOR CUR_SOLDE(absorbee varchar2 , absorbante varchar2) IS
		SELECT
		TYPE_DONNEE,
		LIVRE,
		SOCIETE,
		UO,
		COMPTE_LOCAL,
		COMPTE_ANALYTIQUE,
		INTERCO,
		CENTRE_FINANCE,
		CODE_AFFAIRE,
		PROJET_FINANCE,
		CODE_FLUX,
		RESERVE_1,
		RESERVE_2,
		RESERVE_3,
		SUM(NVL(DEBIT,0)) DEBIT,
		SUM(NVL(CREDIT,0)) CREDIT,
		DESCRIPTION_LIGNE,
		PF,
		TF,
		TYPE_DEPENSE,
		TYPE_EVENEMENT,
		QTE,
		FRAIS,
		CODE_CLIENT,
		CODE_INTERBANCAIRE,
		MATRICULE_EMPLOYE,
		REF_LETTRAGE,
		DEVISE,
		CREATION_DATE,
		JE_HEADER_ID,
		PERIODE,
		CATEGORIE,
		NOM_PIECE, 
		NUMERO_PIECE,
		NUMERO_LIGNE, 
		CCF,
		LIBELLE_CPTE_LOCAL
	    FROM DKA_SGLFUSION_TMP
		where SOC_ABSORBEE = absorbee
		AND SOC_ABSORBANTE = absorbante
		AND TYPE_DONNEE in ('COLLECTIFS','HORS BILAN','NON LETTRABLES')
		AND TYPE_LIGNE='EXTRACTION'
		AND (DEBIT <> 0 OR CREDIT <> 0)
		GROUP BY 
		TYPE_DONNEE,
		LIVRE,
		SOCIETE,
		UO,
		COMPTE_LOCAL,
		COMPTE_ANALYTIQUE,
		INTERCO,
		CENTRE_FINANCE,
		CODE_AFFAIRE,
		PROJET_FINANCE,
		CODE_FLUX,
		RESERVE_1,
		RESERVE_2,
		RESERVE_3,
		DESCRIPTION_LIGNE,
		PF,
		TF,
		TYPE_DEPENSE,
		TYPE_EVENEMENT,
		QTE,
		FRAIS,
		CODE_CLIENT,
		CODE_INTERBANCAIRE,
		MATRICULE_EMPLOYE,
		REF_LETTRAGE,
		DEVISE,
		CREATION_DATE,
		JE_HEADER_ID,
		PERIODE,
		CATEGORIE,
		NOM_PIECE, 
		NUMERO_PIECE,
		NUMERO_LIGNE, 
		CCF,
		LIBELLE_CPTE_LOCAL
		HAVING (SUM(NVL(DEBIT,0) - NVL(CREDIT,0))<> 0);
		
	CURSOR CUR_DETAIL(absorbee varchar2 , absorbante varchar2) IS
		SELECT *
		FROM DKA_SGLFUSION_TMP
		where TYPE_DONNEE in ('LETTRABLES','SUIVI RB')
		AND TYPE_LIGNE='EXTRACTION'
		AND SOC_ABSORBEE = absorbee
		and SOC_ABSORBANTE = absorbante
	    AND (DEBIT <> 0 OR CREDIT <> 0);
	
BEGIN
FOR REC_A IN CUR_AFFICHAGE LOOP 
	-- Ouverture du fichier plat de sortie
		pv_fic_out_name_c   := 'FUSION_'||REC_A.SOC_ABSORBEE||'_TO_'||REC_A.SOC_ABSORBANTE||'_ANNUL_Cptes_Bilan_Collectifs.csv';
		pv_fic_out_name_h_b := 'FUSION_'||REC_A.SOC_ABSORBEE||'_TO_'||REC_A.SOC_ABSORBANTE||'_ANNUL_Cptes_Hors_Bilan.csv';
		pv_fic_out_name_nl 	:= 'FUSION_'||REC_A.SOC_ABSORBEE||'_TO_'||REC_A.SOC_ABSORBANTE||'_ANNUL_Cptes_Bilan.csv';
		pv_fic_out_name_rb 	:= 'FUSION_'||REC_A.SOC_ABSORBEE||'_TO_'||REC_A.SOC_ABSORBANTE||'_ANNUL_Cptes_Bilan_Suivis_RB.csv';
		pv_fic_out_name_l   := 'FUSION_'||REC_A.SOC_ABSORBEE||'_TO_'||REC_A.SOC_ABSORBANTE||'_ANNUL_Cptes_Bilan_Lettrable.csv';
	-- Initialisation de la sortie
	    pv_dir_out          := 'DKA_OUT_DIR';
		DKA_TOOLS_PKG.put_out_header;
		DKA_TOOLS_PKG.OPEN_UTL_FILE(pv_dir_out, pv_fic_out_name_c, p_fic_out_ptr_c, pv_err_msg);
		DKA_TOOLS_PKG.OPEN_UTL_FILE(pv_dir_out, pv_fic_out_name_h_b, p_fic_out_ptr_h_b, pv_err_msg);
		DKA_TOOLS_PKG.OPEN_UTL_FILE(pv_dir_out, pv_fic_out_name_nl, p_fic_out_ptr_nl, pv_err_msg);
		DKA_TOOLS_PKG.OPEN_UTL_FILE(pv_dir_out, pv_fic_out_name_rb, p_fic_out_ptr_rb, pv_err_msg);
		DKA_TOOLS_PKG.OPEN_UTL_FILE(pv_dir_out, pv_fic_out_name_l, p_fic_out_ptr_l, pv_err_msg);
		-- Ecriture de l'entete du fichier plat
				
		UTL_FILE.PUT_LINE(p_fic_out_ptr_c,
          'LIVRE'   					|| cv_seperator ||
             'SOCIETE'   				|| cv_seperator ||
             'UO'   					|| cv_seperator ||
             'COMPTE_LOCAL'   			|| cv_seperator ||
             'COMPTE_ANALYTIQUE'   		|| cv_seperator ||
             'INTERCO'   				|| cv_seperator ||
             'CENTRE_FINANCE'   		|| cv_seperator ||
             'CODE_AFFAIRE'   			|| cv_seperator ||
             'PROJET_FINANCE'   		|| cv_seperator ||
             'CODE_FLUX'   				|| cv_seperator ||
             'RESERVE_1'   				|| cv_seperator ||
             'RESERVE_2'   				|| cv_seperator ||
             'RESERVE_3'   				|| cv_seperator ||
             'DEBIT'   					|| cv_seperator ||
             'CREDIT'   				|| cv_seperator ||
             'DESCRIPTION_LIGNE'   		|| cv_seperator ||
             'PF'   					|| cv_seperator ||
             'TF'   					|| cv_seperator ||
             'TYPE_DEPENSE'   			|| cv_seperator ||
             'TYPE_EVENEMENT'   		|| cv_seperator ||
             'QTE'   					|| cv_seperator ||
             'FRAIS'   					|| cv_seperator ||
             'CODE_CLIENT'   			|| cv_seperator ||
             'CODE_INTERBANCAIRE'   	|| cv_seperator ||
             'MATRICULE_EMPLOYE'   		|| cv_seperator ||
             'REF_LETTRAGE'   			|| cv_seperator ||
             'DEVISE'   				|| cv_seperator ||
             'CREATION_DATE'   			|| cv_seperator ||
             'JE_HEADER_ID'   			|| cv_seperator ||
             'PERIODE'   				|| cv_seperator ||
             'CATEGORIE'   				|| cv_seperator ||
             'NOM_PIECE'   				|| cv_seperator ||
             'NUMERO_PIECE'   			|| cv_seperator ||
             'NUMERO_LIGNE'   			|| cv_seperator ||
             'CCF'   					|| cv_seperator ||
			'LIBELLE_CPTE_LOCAL' 

             ) ;
UTL_FILE.PUT_LINE(p_fic_out_ptr_h_b,
           'LIVRE'   					|| cv_seperator ||
             'SOCIETE'   				|| cv_seperator ||
             'UO'   					|| cv_seperator ||
             'COMPTE_LOCAL'   			|| cv_seperator ||
             'COMPTE_ANALYTIQUE'   		|| cv_seperator ||
             'INTERCO'   				|| cv_seperator ||
             'CENTRE_FINANCE'   		|| cv_seperator ||
             'CODE_AFFAIRE'   			|| cv_seperator ||
             'PROJET_FINANCE'   		|| cv_seperator ||
             'CODE_FLUX'   				|| cv_seperator ||
             'RESERVE_1'   				|| cv_seperator ||
             'RESERVE_2'   				|| cv_seperator ||
             'RESERVE_3'   				|| cv_seperator ||
             'DEBIT'   					|| cv_seperator ||
             'CREDIT'   				|| cv_seperator ||
             'DESCRIPTION_LIGNE'   		|| cv_seperator ||
             'PF'   					|| cv_seperator ||
             'TF'   					|| cv_seperator ||
             'TYPE_DEPENSE'   			|| cv_seperator ||
             'TYPE_EVENEMENT'   		|| cv_seperator ||
             'QTE'   					|| cv_seperator ||
             'FRAIS'   					|| cv_seperator ||
             'CODE_CLIENT'   			|| cv_seperator ||
             'CODE_INTERBANCAIRE'   	|| cv_seperator ||
             'MATRICULE_EMPLOYE'   		|| cv_seperator ||
             'REF_LETTRAGE'   			|| cv_seperator ||
             'DEVISE'   				|| cv_seperator ||
             'CREATION_DATE'   			|| cv_seperator ||
             'JE_HEADER_ID'   			|| cv_seperator ||
             'PERIODE'   				|| cv_seperator ||
             'CATEGORIE'   				|| cv_seperator ||
             'NOM_PIECE'   				|| cv_seperator ||
             'NUMERO_PIECE'   			|| cv_seperator ||
             'NUMERO_LIGNE'   			|| cv_seperator ||
             'CCF'   					|| cv_seperator ||
			'LIBELLE_CPTE_LOCAL'
             ) ;
UTL_FILE.PUT_LINE(p_fic_out_ptr_l,
           'LIVRE'   					|| cv_seperator ||
             'SOCIETE'   				|| cv_seperator ||
             'UO'   					|| cv_seperator ||
             'COMPTE_LOCAL'   			|| cv_seperator ||
             'COMPTE_ANALYTIQUE'   		|| cv_seperator ||
             'INTERCO'   				|| cv_seperator ||
             'CENTRE_FINANCE'   		|| cv_seperator ||
             'CODE_AFFAIRE'   			|| cv_seperator ||
             'PROJET_FINANCE'   		|| cv_seperator ||
             'CODE_FLUX'   				|| cv_seperator ||
             'RESERVE_1'   				|| cv_seperator ||
             'RESERVE_2'   				|| cv_seperator ||
             'RESERVE_3'   				|| cv_seperator ||
             'DEBIT'   					|| cv_seperator ||
             'CREDIT'   				|| cv_seperator ||
             'DESCRIPTION_LIGNE'   		|| cv_seperator ||
             'PF'   					|| cv_seperator ||
             'TF'   					|| cv_seperator ||
             'TYPE_DEPENSE'   			|| cv_seperator ||
             'TYPE_EVENEMENT'   		|| cv_seperator ||
             'QTE'   					|| cv_seperator ||
             'FRAIS'   					|| cv_seperator ||
             'CODE_CLIENT'   			|| cv_seperator ||
             'CODE_INTERBANCAIRE'   	|| cv_seperator ||
             'MATRICULE_EMPLOYE'   		|| cv_seperator ||
             'REF_LETTRAGE'   			|| cv_seperator ||
             'DEVISE'   				|| cv_seperator ||
             'CREATION_DATE'   			|| cv_seperator ||
             'JE_HEADER_ID'   			|| cv_seperator ||
             'PERIODE'   				|| cv_seperator ||
             'CATEGORIE'   				|| cv_seperator ||
             'NOM_PIECE'   				|| cv_seperator ||
             'NUMERO_PIECE'   			|| cv_seperator ||
             'NUMERO_LIGNE'   			|| cv_seperator ||
             'CCF'   					|| cv_seperator ||
			'LIBELLE_CPTE_LOCAL'  

             ) ;
UTL_FILE.PUT_LINE(p_fic_out_ptr_rb,
            'LIVRE'   					|| cv_seperator ||
             'SOCIETE'   				|| cv_seperator ||
             'UO'   					|| cv_seperator ||
             'COMPTE_LOCAL'   			|| cv_seperator ||
             'COMPTE_ANALYTIQUE'   		|| cv_seperator ||
             'INTERCO'   				|| cv_seperator ||
             'CENTRE_FINANCE'   		|| cv_seperator ||
             'CODE_AFFAIRE'   			|| cv_seperator ||
             'PROJET_FINANCE'   		|| cv_seperator ||
             'CODE_FLUX'   				|| cv_seperator ||
             'RESERVE_1'   				|| cv_seperator ||
             'RESERVE_2'   				|| cv_seperator ||
             'RESERVE_3'   				|| cv_seperator ||
             'DEBIT'   					|| cv_seperator ||
             'CREDIT'   				|| cv_seperator ||
             'DESCRIPTION_LIGNE'   		|| cv_seperator ||
             'PF'   					|| cv_seperator ||
             'TF'   					|| cv_seperator ||
             'TYPE_DEPENSE'   			|| cv_seperator ||
             'TYPE_EVENEMENT'   		|| cv_seperator ||
             'QTE'   					|| cv_seperator ||
             'FRAIS'   					|| cv_seperator ||
             'CODE_CLIENT'   			|| cv_seperator ||
             'CODE_INTERBANCAIRE'   	|| cv_seperator ||
             'MATRICULE_EMPLOYE'   		|| cv_seperator ||
             'REF_LETTRAGE'   			|| cv_seperator ||
             'DEVISE'   				|| cv_seperator ||
             'CREATION_DATE'   			|| cv_seperator ||
             'JE_HEADER_ID'   			|| cv_seperator ||
             'PERIODE'   				|| cv_seperator ||
             'CATEGORIE'   				|| cv_seperator ||
             'NOM_PIECE'   				|| cv_seperator ||
             'NUMERO_PIECE'   			|| cv_seperator ||
             'NUMERO_LIGNE'   			|| cv_seperator ||
             'CCF'   					|| cv_seperator ||
			'LIBELLE_CPTE_LOCAL'

             ) ;
UTL_FILE.PUT_LINE(p_fic_out_ptr_nl,
             'LIVRE'   					|| cv_seperator ||
             'SOCIETE'   				|| cv_seperator ||
             'UO'   					|| cv_seperator ||
             'COMPTE_LOCAL'   			|| cv_seperator ||
             'COMPTE_ANALYTIQUE'   		|| cv_seperator ||
             'INTERCO'   				|| cv_seperator ||
             'CENTRE_FINANCE'   		|| cv_seperator ||
             'CODE_AFFAIRE'   			|| cv_seperator ||
             'PROJET_FINANCE'   		|| cv_seperator ||
             'CODE_FLUX'   				|| cv_seperator ||
             'RESERVE_1'   				|| cv_seperator ||
             'RESERVE_2'   				|| cv_seperator ||
             'RESERVE_3'   				|| cv_seperator ||
             'DEBIT'   					|| cv_seperator ||
             'CREDIT'   				|| cv_seperator ||
             'DESCRIPTION_LIGNE'   		|| cv_seperator ||
             'PF'   					|| cv_seperator ||
             'TF'   					|| cv_seperator ||
             'TYPE_DEPENSE'   			|| cv_seperator ||
             'TYPE_EVENEMENT'   		|| cv_seperator ||
             'QTE'   					|| cv_seperator ||
             'FRAIS'   					|| cv_seperator ||
             'CODE_CLIENT'   			|| cv_seperator ||
             'CODE_INTERBANCAIRE'   	|| cv_seperator ||
             'MATRICULE_EMPLOYE'   		|| cv_seperator ||
             'REF_LETTRAGE'   			|| cv_seperator ||
             'DEVISE'   				|| cv_seperator ||
             'CREATION_DATE'   			|| cv_seperator ||
             'JE_HEADER_ID'   			|| cv_seperator ||
             'PERIODE'   				|| cv_seperator ||
             'CATEGORIE'   				|| cv_seperator ||
             'NOM_PIECE'   				|| cv_seperator ||
             'NUMERO_PIECE'   			|| cv_seperator ||
             'NUMERO_LIGNE'   			|| cv_seperator ||
             'CCF'   					|| cv_seperator ||
			'LIBELLE_CPTE_LOCAL'

             ) ;
		
FOR REC_S_AN IN CUR_SOLDE_ANNU(REC_A.SOC_ABSORBEE , REC_A.SOC_ABSORBANTE) LOOP	
-------COLLECTIFS
				
IF (REC_S_AN.TYPE_DONNEE='COLLECTIFS') then 
				
    UTL_FILE.PUT_LINE(p_fic_out_ptr_c,
		REC_S_AN.LIVRE              					|| cv_seperator ||
		REC_S_AN.SOCIETE            					|| cv_seperator ||
		REC_S_AN.UO                 					|| cv_seperator ||
		REC_S_AN.COMPTE_LOCAL       					|| cv_seperator ||
		REC_S_AN.COMPTE_ANALYTIQUE  					|| cv_seperator ||
		REC_S_AN.INTERCO            					|| cv_seperator ||
		REC_S_AN.CENTRE_FINANCE	 					|| cv_seperator ||
		REC_S_AN.CODE_AFFAIRE	     					|| cv_seperator ||
		REC_S_AN.PROJET_FINANCE    					|| cv_seperator ||
		REC_S_AN.CODE_FLUX         					|| cv_seperator ||  
		REC_S_AN.RESERVE_1         					|| cv_seperator ||
		REC_S_AN.RESERVE_2         					|| cv_seperator ||
		REC_S_AN.RESERVE_3         					|| cv_seperator ||
		REPLACE(ROUND(REC_S_AN.DEBIT,2),'.',',')      || cv_seperator ||
		REPLACE(ROUND(REC_S_AN.CREDIT,2),'.',',')     || cv_seperator ||
		REPLACE(REC_S_AN.DESCRIPTION_LIGNE,';','-')  	|| cv_seperator ||
		REC_S_AN.PF                 					|| cv_seperator ||
		REC_S_AN.TF                 					|| cv_seperator ||
		REC_S_AN.TYPE_DEPENSE       					|| cv_seperator ||      
		REC_S_AN.TYPE_EVENEMENT     					|| cv_seperator ||
		REC_S_AN.QTE                					|| cv_seperator ||
		REC_S_AN.FRAIS              					|| cv_seperator ||
		REC_S_AN.CODE_CLIENT        					|| cv_seperator ||
		REC_S_AN.CODE_INTERBANCAIRE 					|| cv_seperator ||
		REC_S_AN.MATRICULE_EMPLOYE  					|| cv_seperator ||
		REPLACE(REC_S_AN.REF_LETTRAGE,';','-')       	|| cv_seperator ||
		REC_S_AN.DEVISE             					|| cv_seperator ||
		to_char(REC_S_AN.CREATION_DATE,'DD/MM/YYYY HH24:MI:SS')|| cv_seperator ||
		REC_S_AN.JE_HEADER_ID       					|| cv_seperator ||
		REC_S_AN.PERIODE            					|| cv_seperator ||
		REC_S_AN.CATEGORIE          					|| cv_seperator ||
		REPLACE(REC_S_AN.NOM_PIECE,';','-')           || cv_seperator ||
		REC_S_AN.NUMERO_PIECE       					|| cv_seperator ||
		REC_S_AN.NUMERO_LIGNE       					|| cv_seperator ||
		REC_S_AN.CCF                					|| cv_seperator ||    
		REPLACE(REC_S_AN.LIBELLE_CPTE_LOCAL ,';','-')
	);

------------ HORS BILAN
ELSE IF(REC_S_AN.TYPE_DONNEE ='HORS BILAN') THEN 
 UTL_FILE.PUT_LINE(p_fic_out_ptr_h_b,
		REC_S_AN.LIVRE              					|| cv_seperator ||
		REC_S_AN.SOCIETE            					|| cv_seperator ||
		REC_S_AN.UO                 					|| cv_seperator ||
		REC_S_AN.COMPTE_LOCAL       					|| cv_seperator ||
		REC_S_AN.COMPTE_ANALYTIQUE  					|| cv_seperator ||
		REC_S_AN.INTERCO            					|| cv_seperator ||
		REC_S_AN.CENTRE_FINANCE	 					|| cv_seperator ||
		REC_S_AN.CODE_AFFAIRE	     					|| cv_seperator ||
		REC_S_AN.PROJET_FINANCE    					|| cv_seperator ||
		REC_S_AN.CODE_FLUX         					|| cv_seperator ||  
		REC_S_AN.RESERVE_1         					|| cv_seperator ||
		REC_S_AN.RESERVE_2         					|| cv_seperator ||
		REC_S_AN.RESERVE_3         					|| cv_seperator ||
		REPLACE(ROUND(REC_S_AN.DEBIT,2),'.',',')      || cv_seperator ||
		REPLACE(ROUND(REC_S_AN.CREDIT,2),'.',',')     || cv_seperator ||
		REPLACE(REC_S_AN.DESCRIPTION_LIGNE,';','-')  	|| cv_seperator ||
		REC_S_AN.PF                 					|| cv_seperator ||
		REC_S_AN.TF                 					|| cv_seperator ||
		REC_S_AN.TYPE_DEPENSE       					|| cv_seperator ||      
		REC_S_AN.TYPE_EVENEMENT     					|| cv_seperator ||
		REC_S_AN.QTE                					|| cv_seperator ||
		REC_S_AN.FRAIS              					|| cv_seperator ||
		REC_S_AN.CODE_CLIENT        					|| cv_seperator ||
		REC_S_AN.CODE_INTERBANCAIRE 					|| cv_seperator ||
		REC_S_AN.MATRICULE_EMPLOYE  					|| cv_seperator ||
		REPLACE(REC_S_AN.REF_LETTRAGE,';','-')       	|| cv_seperator ||
		REC_S_AN.DEVISE             					|| cv_seperator ||
		TO_char(REC_S_AN.CREATION_DATE,'DD/MM/YYYY HH24:MI:SS')|| cv_seperator ||
		REC_S_AN.JE_HEADER_ID       					|| cv_seperator ||
		REC_S_AN.PERIODE            					|| cv_seperator ||
		REC_S_AN.CATEGORIE          					|| cv_seperator ||
		REPLACE(REC_S_AN.NOM_PIECE,';','-')           || cv_seperator ||
		REC_S_AN.NUMERO_PIECE       					|| cv_seperator ||
		REC_S_AN.NUMERO_LIGNE       					|| cv_seperator ||
		REC_S_AN.CCF                					|| cv_seperator ||    
		REPLACE(REC_S_AN.LIBELLE_CPTE_LOCAL ,';','-')
	);
	------------ NON LETTRABLES
ELSE IF(REC_S_AN.TYPE_DONNEE ='NON LETTRABLES') THEN 
			
 UTL_FILE.PUT_LINE(p_fic_out_ptr_nl,
		REC_S_AN.LIVRE              					|| cv_seperator ||
		REC_S_AN.SOCIETE            					|| cv_seperator ||
		REC_S_AN.UO                 					|| cv_seperator ||
		REC_S_AN.COMPTE_LOCAL       					|| cv_seperator ||
		REC_S_AN.COMPTE_ANALYTIQUE  					|| cv_seperator ||
		REC_S_AN.INTERCO            					|| cv_seperator ||
		REC_S_AN.CENTRE_FINANCE	 					|| cv_seperator ||
		REC_S_AN.CODE_AFFAIRE	     					|| cv_seperator ||
		REC_S_AN.PROJET_FINANCE    					|| cv_seperator ||
		REC_S_AN.CODE_FLUX         					|| cv_seperator ||  
		REC_S_AN.RESERVE_1         					|| cv_seperator ||
		REC_S_AN.RESERVE_2         					|| cv_seperator ||
		REC_S_AN.RESERVE_3         					|| cv_seperator ||
		REPLACE(ROUND(REC_S_AN.DEBIT,2),'.',',')      || cv_seperator ||
		REPLACE(ROUND(REC_S_AN.CREDIT,2),'.',',')     || cv_seperator ||
		REPLACE(REC_S_AN.DESCRIPTION_LIGNE,';','-')  	|| cv_seperator ||
		REC_S_AN.PF                 					|| cv_seperator ||
		REC_S_AN.TF                 					|| cv_seperator ||
		REC_S_AN.TYPE_DEPENSE       					|| cv_seperator ||      
		REC_S_AN.TYPE_EVENEMENT     					|| cv_seperator ||
		REC_S_AN.QTE                					|| cv_seperator ||
		REC_S_AN.FRAIS              					|| cv_seperator ||
		REC_S_AN.CODE_CLIENT        					|| cv_seperator ||
		REC_S_AN.CODE_INTERBANCAIRE 					|| cv_seperator ||
		REC_S_AN.MATRICULE_EMPLOYE  					|| cv_seperator ||
		REPLACE(REC_S_AN.REF_LETTRAGE,';','-')       	|| cv_seperator ||
		REC_S_AN.DEVISE             					|| cv_seperator ||
		TO_char(REC_S_AN.CREATION_DATE,'DD/MM/YYYY HH24:MI:SS')|| cv_seperator ||
		REC_S_AN.JE_HEADER_ID       					|| cv_seperator ||
		REC_S_AN.PERIODE            					|| cv_seperator ||
		REC_S_AN.CATEGORIE          					|| cv_seperator ||
		REPLACE(REC_S_AN.NOM_PIECE,';','-')           || cv_seperator ||
		REC_S_AN.NUMERO_PIECE       					|| cv_seperator ||
		REC_S_AN.NUMERO_LIGNE       					|| cv_seperator ||
		REC_S_AN.CCF                					|| cv_seperator ||    
		REPLACE(REC_S_AN.LIBELLE_CPTE_LOCAL ,';','-')
	);
END IF ;
END IF ;
END IF ;
END LOOP;
FOR REC_D_AN IN CUR_DETAIL_ANNU(REC_A.SOC_ABSORBEE , REC_A.SOC_ABSORBANTE) LOOP	
----------LETTRABLES
 IF(REC_D_AN.TYPE_DONNEE ='LETTRABLES') THEN
 UTL_FILE.PUT_LINE(p_fic_out_ptr_l,
		REC_D_AN.LIVRE              					|| cv_seperator ||
		REC_D_AN.SOCIETE            					|| cv_seperator ||
		REC_D_AN.UO                 					|| cv_seperator ||
		REC_D_AN.COMPTE_LOCAL       					|| cv_seperator ||
		REC_D_AN.COMPTE_ANALYTIQUE  					|| cv_seperator ||
		REC_D_AN.INTERCO            					|| cv_seperator ||
		REC_D_AN.CENTRE_FINANCE	 					|| cv_seperator ||
		REC_D_AN.CODE_AFFAIRE	     					|| cv_seperator ||
		REC_D_AN.PROJET_FINANCE    					|| cv_seperator ||
		REC_D_AN.CODE_FLUX         					|| cv_seperator ||  
		REC_D_AN.RESERVE_1         					|| cv_seperator ||
		REC_D_AN.RESERVE_2         					|| cv_seperator ||
		REC_D_AN.RESERVE_3         					|| cv_seperator ||
		REPLACE(ROUND(REC_D_AN.DEBIT,2),'.',',')      || cv_seperator ||
		REPLACE(ROUND(REC_D_AN.CREDIT,2),'.',',')     || cv_seperator ||
		REPLACE(REC_D_AN.DESCRIPTION_LIGNE,';','-')  	|| cv_seperator ||
		REC_D_AN.PF                 					|| cv_seperator ||
		REC_D_AN.TF                 					|| cv_seperator ||
		REC_D_AN.TYPE_DEPENSE       					|| cv_seperator ||      
		REC_D_AN.TYPE_EVENEMENT     					|| cv_seperator ||
		REC_D_AN.QTE                					|| cv_seperator ||
		REC_D_AN.FRAIS              					|| cv_seperator ||
		REC_D_AN.CODE_CLIENT        					|| cv_seperator ||
		REC_D_AN.CODE_INTERBANCAIRE 					|| cv_seperator ||
		REC_D_AN.MATRICULE_EMPLOYE  					|| cv_seperator ||
		REPLACE(REC_D_AN.REF_LETTRAGE,';','-')       	|| cv_seperator ||
		REC_D_AN.DEVISE             					|| cv_seperator ||
		to_char(REC_D_AN.CREATION_DATE,'DD/MM/YYYY HH24:MI:SS')|| cv_seperator ||
		REC_D_AN.JE_HEADER_ID       					|| cv_seperator ||
		REC_D_AN.PERIODE            					|| cv_seperator ||
		REC_D_AN.CATEGORIE          					|| cv_seperator ||
		REPLACE(REC_D_AN.NOM_PIECE,';','-')           || cv_seperator ||
		REC_D_AN.NUMERO_PIECE       					|| cv_seperator ||
		REC_D_AN.NUMERO_LIGNE       					|| cv_seperator ||
		REC_D_AN.CCF                					|| cv_seperator ||    
		REPLACE(REC_D_AN.LIBELLE_CPTE_LOCAL ,';','-')
	);
------------ SUIVI RB
ELSE IF(REC_D_AN.TYPE_DONNEE ='SUIVI RB') THEN 
				
 UTL_FILE.PUT_LINE(p_fic_out_ptr_rb,
		REC_D_AN.LIVRE              					|| cv_seperator ||
		REC_D_AN.SOCIETE            					|| cv_seperator ||
		REC_D_AN.UO                 					|| cv_seperator ||
		REC_D_AN.COMPTE_LOCAL       					|| cv_seperator ||
		REC_D_AN.COMPTE_ANALYTIQUE  					|| cv_seperator ||
		REC_D_AN.INTERCO            					|| cv_seperator ||
		REC_D_AN.CENTRE_FINANCE	 					|| cv_seperator ||
		REC_D_AN.CODE_AFFAIRE	     					|| cv_seperator ||
		REC_D_AN.PROJET_FINANCE    					|| cv_seperator ||
		REC_D_AN.CODE_FLUX         					|| cv_seperator ||  
		REC_D_AN.RESERVE_1         					|| cv_seperator ||
		REC_D_AN.RESERVE_2         					|| cv_seperator ||
		REC_D_AN.RESERVE_3         					|| cv_seperator ||
		REPLACE(ROUND(REC_D_AN.DEBIT,2),'.',',')      || cv_seperator ||
		REPLACE(ROUND(REC_D_AN.CREDIT,2),'.',',')     || cv_seperator ||
		REPLACE(REC_D_AN.DESCRIPTION_LIGNE,';','-')  	|| cv_seperator ||
		REC_D_AN.PF                 					|| cv_seperator ||
		REC_D_AN.TF                 					|| cv_seperator ||
		REC_D_AN.TYPE_DEPENSE       					|| cv_seperator ||      
		REC_D_AN.TYPE_EVENEMENT     					|| cv_seperator ||
		REC_D_AN.QTE                					|| cv_seperator ||
		REC_D_AN.FRAIS              					|| cv_seperator ||
		REC_D_AN.CODE_CLIENT        					|| cv_seperator ||
		REC_D_AN.CODE_INTERBANCAIRE 					|| cv_seperator ||
		REC_D_AN.MATRICULE_EMPLOYE  					|| cv_seperator ||
		REPLACE(REC_D_AN.REF_LETTRAGE,';','-')       	|| cv_seperator ||
		REC_D_AN.DEVISE             					|| cv_seperator ||
		TO_char(REC_D_AN.CREATION_DATE,'DD/MM/YYYY HH24:MI:SS')|| cv_seperator ||
		REC_D_AN.JE_HEADER_ID       					|| cv_seperator ||
		REC_D_AN.PERIODE            					|| cv_seperator ||
		REC_D_AN.CATEGORIE          					|| cv_seperator ||
		REPLACE(REC_D_AN.NOM_PIECE,';','-')           || cv_seperator ||
		REC_D_AN.NUMERO_PIECE       					|| cv_seperator ||
		REC_D_AN.NUMERO_LIGNE       					|| cv_seperator ||
		REC_D_AN.CCF                					|| cv_seperator ||    
		REPLACE(REC_D_AN.LIBELLE_CPTE_LOCAL ,';','-')
	);
END IF ;
END IF ;
END LOOP ;
	-- Fermeture du fichier plat de sortie
	UTL_FILE.FCLOSE(p_fic_out_ptr_c);
	UTL_FILE.FCLOSE(p_fic_out_ptr_l);
	UTL_FILE.FCLOSE(p_fic_out_ptr_nl);
	UTL_FILE.FCLOSE(p_fic_out_ptr_h_b);
	UTL_FILE.FCLOSE(p_fic_out_ptr_rb);
 -- Ouverture du fichier plat de sortie
	pv_fic_out_name_rc   := 'FUSION_'||REC_A.SOC_ABSORBEE||'_TO_'||REC_A.SOC_ABSORBANTE||'_REPRISE_Cptes_Bilan_Collectifs.csv';
	pv_fic_out_name_rh_b := 'FUSION_'||REC_A.SOC_ABSORBEE||'_TO_'||REC_A.SOC_ABSORBANTE||'_REPRISE_Cptes_Hors_Bilan.csv';
	pv_fic_out_name_rnl 	:= 'FUSION_'||REC_A.SOC_ABSORBEE||'_TO_'||REC_A.SOC_ABSORBANTE||'_REPRISE_Cptes_Bilan.csv';
	pv_fic_out_name_rrb 	:= 'FUSION_'||REC_A.SOC_ABSORBEE||'_TO_'||REC_A.SOC_ABSORBANTE||'_REPRISE_Cptes_Bilan_Suivis_RB.csv';
	pv_fic_out_name_rl   := 'FUSION_'||REC_A.SOC_ABSORBEE||'_TO_'||REC_A.SOC_ABSORBANTE||'_REPRISE_Cptes_Bilan_Lettrable.csv';
-- Initialisation de la sortie
    pv_dir_out          := 'DKA_OUT_DIR';
	DKA_TOOLS_PKG.put_out_header;
	DKA_TOOLS_PKG.OPEN_UTL_FILE(pv_dir_out, pv_fic_out_name_rc, p_fic_out_ptr_rc, pv_err_msg);
	DKA_TOOLS_PKG.OPEN_UTL_FILE(pv_dir_out, pv_fic_out_name_rh_b, p_fic_out_ptr_rh_b, pv_err_msg);
	DKA_TOOLS_PKG.OPEN_UTL_FILE(pv_dir_out, pv_fic_out_name_rnl, p_fic_out_ptr_rnl, pv_err_msg);
	DKA_TOOLS_PKG.OPEN_UTL_FILE(pv_dir_out, pv_fic_out_name_rrb, p_fic_out_ptr_rrb, pv_err_msg);
	DKA_TOOLS_PKG.OPEN_UTL_FILE(pv_dir_out, pv_fic_out_name_rl, p_fic_out_ptr_rl, pv_err_msg);
		-- Ecriture de l'entete du fichier plat
						Dka_Tools_Pkg.Put_Outdebug_Message('3');
	UTL_FILE.PUT_LINE(p_fic_out_ptr_rc,
             'LIVRE'   					|| cv_seperator ||
             'SOCIETE'   				|| cv_seperator ||
             'UO'   					|| cv_seperator ||
             'COMPTE_LOCAL'   			|| cv_seperator ||
             'COMPTE_ANALYTIQUE'   		|| cv_seperator ||
             'INTERCO'   				|| cv_seperator ||
             'CENTRE_FINANCE'   		|| cv_seperator ||
             'CODE_AFFAIRE'   			|| cv_seperator ||
             'PROJET_FINANCE'   		|| cv_seperator ||
             'CODE_FLUX'   				|| cv_seperator ||
             'RESERVE_1'   				|| cv_seperator ||
             'RESERVE_2'   				|| cv_seperator ||
             'RESERVE_3'   				|| cv_seperator ||
             'DEBIT'   					|| cv_seperator ||
             'CREDIT'   				|| cv_seperator ||
             'DESCRIPTION_LIGNE'   		|| cv_seperator ||
             'PF'   					|| cv_seperator ||
             'TF'   					|| cv_seperator ||
             'TYPE_DEPENSE'   			|| cv_seperator ||
             'TYPE_EVENEMENT'   		|| cv_seperator ||
             'QTE'   					|| cv_seperator ||
             'FRAIS'   					|| cv_seperator ||
             'CODE_CLIENT'   			|| cv_seperator ||
             'CODE_INTERBANCAIRE'   	|| cv_seperator ||
             'MATRICULE_EMPLOYE'   		|| cv_seperator ||
             'REF_LETTRAGE'   			|| cv_seperator ||
             'DEVISE'   				|| cv_seperator ||
             'CREATION_DATE'   			|| cv_seperator ||
             'JE_HEADER_ID'   			|| cv_seperator ||
             'PERIODE'   				|| cv_seperator ||
             'CATEGORIE'   				|| cv_seperator ||
             'NOM_PIECE'   				|| cv_seperator ||
             'NUMERO_PIECE'   			|| cv_seperator ||
             'NUMERO_LIGNE'   			|| cv_seperator ||
             'CCF'   					|| cv_seperator ||
			'LIBELLE_CPTE_LOCAL'
             ) ;
UTL_FILE.PUT_LINE(p_fic_out_ptr_rh_b,
             'LIVRE'   					|| cv_seperator ||
             'SOCIETE'   				|| cv_seperator ||
             'UO'   					|| cv_seperator ||
             'COMPTE_LOCAL'   			|| cv_seperator ||
             'COMPTE_ANALYTIQUE'   		|| cv_seperator ||
             'INTERCO'   				|| cv_seperator ||
             'CENTRE_FINANCE'   		|| cv_seperator ||
             'CODE_AFFAIRE'   			|| cv_seperator ||
             'PROJET_FINANCE'   		|| cv_seperator ||
             'CODE_FLUX'   				|| cv_seperator ||
             'RESERVE_1'   				|| cv_seperator ||
             'RESERVE_2'   				|| cv_seperator ||
             'RESERVE_3'   				|| cv_seperator ||
             'DEBIT'   					|| cv_seperator ||
             'CREDIT'   				|| cv_seperator ||
             'DESCRIPTION_LIGNE'   		|| cv_seperator ||
             'PF'   					|| cv_seperator ||
             'TF'   					|| cv_seperator ||
             'TYPE_DEPENSE'   			|| cv_seperator ||
             'TYPE_EVENEMENT'   		|| cv_seperator ||
             'QTE'   					|| cv_seperator ||
             'FRAIS'   					|| cv_seperator ||
             'CODE_CLIENT'   			|| cv_seperator ||
             'CODE_INTERBANCAIRE'   	|| cv_seperator ||
             'MATRICULE_EMPLOYE'   		|| cv_seperator ||
             'REF_LETTRAGE'   			|| cv_seperator ||
             'DEVISE'   				|| cv_seperator ||
             'CREATION_DATE'   			|| cv_seperator ||
             'JE_HEADER_ID'   			|| cv_seperator ||
             'PERIODE'   				|| cv_seperator ||
             'CATEGORIE'   				|| cv_seperator ||
             'NOM_PIECE'   				|| cv_seperator ||
             'NUMERO_PIECE'   			|| cv_seperator ||
             'NUMERO_LIGNE'   			|| cv_seperator ||
             'CCF'   					|| cv_seperator ||
             'LIBELLE_CPTE_LOCAL'   

             ) ;
UTL_FILE.PUT_LINE(p_fic_out_ptr_rnl,
                'LIVRE'   					|| cv_seperator ||
             'SOCIETE'   				|| cv_seperator ||
             'UO'   					|| cv_seperator ||
             'COMPTE_LOCAL'   			|| cv_seperator ||
             'COMPTE_ANALYTIQUE'   		|| cv_seperator ||
             'INTERCO'   				|| cv_seperator ||
             'CENTRE_FINANCE'   		|| cv_seperator ||
             'CODE_AFFAIRE'   			|| cv_seperator ||
             'PROJET_FINANCE'   		|| cv_seperator ||
             'CODE_FLUX'   				|| cv_seperator ||
             'RESERVE_1'   				|| cv_seperator ||
             'RESERVE_2'   				|| cv_seperator ||
             'RESERVE_3'   				|| cv_seperator ||
             'DEBIT'   					|| cv_seperator ||
             'CREDIT'   				|| cv_seperator ||
             'DESCRIPTION_LIGNE'   		|| cv_seperator ||
             'PF'   					|| cv_seperator ||
             'TF'   					|| cv_seperator ||
             'TYPE_DEPENSE'   			|| cv_seperator ||
             'TYPE_EVENEMENT'   		|| cv_seperator ||
             'QTE'   					|| cv_seperator ||
             'FRAIS'   					|| cv_seperator ||
             'CODE_CLIENT'   			|| cv_seperator ||
             'CODE_INTERBANCAIRE'   	|| cv_seperator ||
             'MATRICULE_EMPLOYE'   		|| cv_seperator ||
             'REF_LETTRAGE'   			|| cv_seperator ||
             'DEVISE'   				|| cv_seperator ||
             'CREATION_DATE'   			|| cv_seperator ||
             'JE_HEADER_ID'   			|| cv_seperator ||
             'PERIODE'   				|| cv_seperator ||
             'CATEGORIE'   				|| cv_seperator ||
             'NOM_PIECE'   				|| cv_seperator ||
             'NUMERO_PIECE'   			|| cv_seperator ||
             'NUMERO_LIGNE'   			|| cv_seperator ||
             'CCF'   					|| cv_seperator ||
			 'LIBELLE_CPTE_LOCAL'

             ) ;
UTL_FILE.PUT_LINE(p_fic_out_ptr_rl,
               'LIVRE'   				|| cv_seperator ||
             'SOCIETE'   				|| cv_seperator ||
             'UO'   					|| cv_seperator ||
             'COMPTE_LOCAL'   			|| cv_seperator ||
             'COMPTE_ANALYTIQUE'   		|| cv_seperator ||
             'INTERCO'   				|| cv_seperator ||
             'CENTRE_FINANCE'   		|| cv_seperator ||
             'CODE_AFFAIRE'   			|| cv_seperator ||
             'PROJET_FINANCE'   		|| cv_seperator ||
             'CODE_FLUX'   				|| cv_seperator ||
             'RESERVE_1'   				|| cv_seperator ||
             'RESERVE_2'   				|| cv_seperator ||
             'RESERVE_3'   				|| cv_seperator ||
             'DEBIT'   					|| cv_seperator ||
             'CREDIT'   				|| cv_seperator ||
             'DESCRIPTION_LIGNE'   		|| cv_seperator ||
             'PF'   					|| cv_seperator ||
             'TF'   					|| cv_seperator ||
             'TYPE_DEPENSE'   			|| cv_seperator ||
             'TYPE_EVENEMENT'   		|| cv_seperator ||
             'QTE'   					|| cv_seperator ||
             'FRAIS'   					|| cv_seperator ||
             'CODE_CLIENT'   			|| cv_seperator ||
             'CODE_INTERBANCAIRE'   	|| cv_seperator ||
             'MATRICULE_EMPLOYE'   		|| cv_seperator ||
             'REF_LETTRAGE'   			|| cv_seperator ||
             'DEVISE'   				|| cv_seperator ||
             'CREATION_DATE'   			|| cv_seperator ||
             'JE_HEADER_ID'   			|| cv_seperator ||
             'PERIODE'   				|| cv_seperator ||
             'CATEGORIE'   				|| cv_seperator ||
             'NOM_PIECE'   				|| cv_seperator ||
             'NUMERO_PIECE'   			|| cv_seperator ||
             'NUMERO_LIGNE'   			|| cv_seperator ||
             'CCF'   					|| cv_seperator ||
			 'LIBELLE_CPTE_LOCAL'

             ) ;
UTL_FILE.PUT_LINE(p_fic_out_ptr_rrb,
             'LIVRE'   				    || cv_seperator ||
             'SOCIETE'   				|| cv_seperator ||
             'UO'   					|| cv_seperator ||
             'COMPTE_LOCAL'   			|| cv_seperator ||
             'COMPTE_ANALYTIQUE'   		|| cv_seperator ||
             'INTERCO'   				|| cv_seperator ||
             'CENTRE_FINANCE'   		|| cv_seperator ||
             'CODE_AFFAIRE'   			|| cv_seperator ||
             'PROJET_FINANCE'   		|| cv_seperator ||
             'CODE_FLUX'   				|| cv_seperator ||
             'RESERVE_1'   				|| cv_seperator ||
             'RESERVE_2'   				|| cv_seperator ||
             'RESERVE_3'   				|| cv_seperator ||
             'DEBIT'   					|| cv_seperator ||
             'CREDIT'   				|| cv_seperator ||
             'DESCRIPTION_LIGNE'   		|| cv_seperator ||
             'PF'   					|| cv_seperator ||
             'TF'   					|| cv_seperator ||
             'TYPE_DEPENSE'   			|| cv_seperator ||
             'TYPE_EVENEMENT'   		|| cv_seperator ||
             'QTE'   					|| cv_seperator ||
             'FRAIS'   					|| cv_seperator ||
             'CODE_CLIENT'   			|| cv_seperator ||
             'CODE_INTERBANCAIRE'   	|| cv_seperator ||
             'MATRICULE_EMPLOYE'   		|| cv_seperator ||
             'REF_LETTRAGE'   			|| cv_seperator ||
             'DEVISE'   				|| cv_seperator ||
             'CREATION_DATE'   			|| cv_seperator ||
             'JE_HEADER_ID'   			|| cv_seperator ||
             'PERIODE'   				|| cv_seperator ||
             'CATEGORIE'   				|| cv_seperator ||
             'NOM_PIECE'   				|| cv_seperator ||
             'NUMERO_PIECE'   			|| cv_seperator ||
             'NUMERO_LIGNE'   			|| cv_seperator ||
             'CCF'   					|| cv_seperator ||
			 'LIBELLE_CPTE_LOCAL'

             ) ;
FOR REC_S IN CUR_SOLDE(REC_A.SOC_ABSORBEE , REC_A.SOC_ABSORBANTE) LOOP	
-------COLLECTIFS
IF (REC_S.TYPE_DONNEE='COLLECTIFS') then 
				
    UTL_FILE.PUT_LINE(p_fic_out_ptr_rc,
		REC_S.LIVRE              					|| cv_seperator ||
		REC_S.SOCIETE            					|| cv_seperator ||
		REC_S.UO                 					|| cv_seperator ||
		REC_S.COMPTE_LOCAL       					|| cv_seperator ||
		REC_S.COMPTE_ANALYTIQUE  					|| cv_seperator ||
		REC_S.INTERCO            					|| cv_seperator ||
		REC_S.CENTRE_FINANCE	 					|| cv_seperator ||
		REC_S.CODE_AFFAIRE	     					|| cv_seperator ||
		REC_S.PROJET_FINANCE    					|| cv_seperator ||
		REC_S.CODE_FLUX         					|| cv_seperator ||  
		REC_S.RESERVE_1         					|| cv_seperator ||
		REC_S.RESERVE_2         					|| cv_seperator ||
		REC_S.RESERVE_3         					|| cv_seperator ||
		REPLACE(ROUND(REC_S.DEBIT,2),'.',',')      || cv_seperator ||
		REPLACE(ROUND(REC_S.CREDIT,2),'.',',')     || cv_seperator ||
		REPLACE(REC_S.DESCRIPTION_LIGNE,';','-')  	|| cv_seperator ||
		REC_S.PF                 					|| cv_seperator ||
		REC_S.TF                 					|| cv_seperator ||
		REC_S.TYPE_DEPENSE       					|| cv_seperator ||      
		REC_S.TYPE_EVENEMENT     					|| cv_seperator ||
		REC_S.QTE                					|| cv_seperator ||
		REC_S.FRAIS              					|| cv_seperator ||
		REC_S.CODE_CLIENT        					|| cv_seperator ||
		REC_S.CODE_INTERBANCAIRE 					|| cv_seperator ||
		REC_S.MATRICULE_EMPLOYE  					|| cv_seperator ||
		REPLACE(REC_S.REF_LETTRAGE,';','-')       	|| cv_seperator ||
		REC_S.DEVISE             					|| cv_seperator ||
		TO_char(REC_S.CREATION_DATE,'DD/MM/YYYY HH24:MI:SS')|| cv_seperator ||
		REC_S.JE_HEADER_ID       					|| cv_seperator ||
		REC_S.PERIODE            					|| cv_seperator ||
		REC_S.CATEGORIE          					|| cv_seperator ||
		REPLACE(REC_S.NOM_PIECE,';','-')           || cv_seperator ||
		REC_S.NUMERO_PIECE       					|| cv_seperator ||
		REC_S.NUMERO_LIGNE       					|| cv_seperator ||
		REC_S.CCF                					|| cv_seperator ||    
		REPLACE(REC_S.LIBELLE_CPTE_LOCAL ,';','-')
	);
----------LETTRABLES
ELSE IF(REC_S.TYPE_DONNEE ='NON LETTRABLES') THEN 
				
 UTL_FILE.PUT_LINE(p_fic_out_ptr_rnl,
		REC_S.LIVRE              					|| cv_seperator ||
		REC_S.SOCIETE            					|| cv_seperator ||
		REC_S.UO                 					|| cv_seperator ||
		REC_S.COMPTE_LOCAL       					|| cv_seperator ||
		REC_S.COMPTE_ANALYTIQUE  					|| cv_seperator ||
		REC_S.INTERCO            					|| cv_seperator ||
		REC_S.CENTRE_FINANCE	 					|| cv_seperator ||
		REC_S.CODE_AFFAIRE	     					|| cv_seperator ||
		REC_S.PROJET_FINANCE    					|| cv_seperator ||
		REC_S.CODE_FLUX         					|| cv_seperator ||  
		REC_S.RESERVE_1         					|| cv_seperator ||
		REC_S.RESERVE_2         					|| cv_seperator ||
		REC_S.RESERVE_3         					|| cv_seperator ||
		REPLACE(ROUND(REC_S.DEBIT,2),'.',',')      || cv_seperator ||
		REPLACE(ROUND(REC_S.CREDIT,2),'.',',')     || cv_seperator ||
		REPLACE(REC_S.DESCRIPTION_LIGNE,';','-')  	|| cv_seperator ||
		REC_S.PF                 					|| cv_seperator ||
		REC_S.TF                 					|| cv_seperator ||
		REC_S.TYPE_DEPENSE       					|| cv_seperator ||      
		REC_S.TYPE_EVENEMENT     					|| cv_seperator ||
		REC_S.QTE                					|| cv_seperator ||
		REC_S.FRAIS              					|| cv_seperator ||
		REC_S.CODE_CLIENT        					|| cv_seperator ||
		REC_S.CODE_INTERBANCAIRE 					|| cv_seperator ||
		REC_S.MATRICULE_EMPLOYE  					|| cv_seperator ||
		REPLACE(REC_S.REF_LETTRAGE,';','-')       	|| cv_seperator ||
		REC_S.DEVISE             					|| cv_seperator ||
		TO_char(REC_S.CREATION_DATE,'DD/MM/YYYY HH24:MI:SS')|| cv_seperator ||
		REC_S.JE_HEADER_ID       					|| cv_seperator ||
		REC_S.PERIODE            					|| cv_seperator ||
		REC_S.CATEGORIE          					|| cv_seperator ||
		REPLACE(REC_S.NOM_PIECE,';','-')           || cv_seperator ||
		REC_S.NUMERO_PIECE       					|| cv_seperator ||
		REC_S.NUMERO_LIGNE       					|| cv_seperator ||
		REC_S.CCF                					|| cv_seperator ||    
		REPLACE(REC_S.LIBELLE_CPTE_LOCAL ,';','-')
	);
------------ HORS BILAN
ELSE IF(REC_S.TYPE_DONNEE ='HORS BILAN') THEN 
				
 UTL_FILE.PUT_LINE(p_fic_out_ptr_rh_b,
		REC_S.LIVRE              					|| cv_seperator ||
		REC_S.SOCIETE            					|| cv_seperator ||
		REC_S.UO                 					|| cv_seperator ||
		REC_S.COMPTE_LOCAL       					|| cv_seperator ||
		REC_S.COMPTE_ANALYTIQUE  					|| cv_seperator ||
		REC_S.INTERCO            					|| cv_seperator ||
		REC_S.CENTRE_FINANCE	 					|| cv_seperator ||
		REC_S.CODE_AFFAIRE	     					|| cv_seperator ||
		REC_S.PROJET_FINANCE    					|| cv_seperator ||
		REC_S.CODE_FLUX         					|| cv_seperator ||  
		REC_S.RESERVE_1         					|| cv_seperator ||
		REC_S.RESERVE_2         					|| cv_seperator ||
		REC_S.RESERVE_3         					|| cv_seperator ||
		REPLACE(ROUND(REC_S.DEBIT,2),'.',',')      || cv_seperator ||
		REPLACE(ROUND(REC_S.CREDIT,2),'.',',')     || cv_seperator ||
		REPLACE(REC_S.DESCRIPTION_LIGNE,';','-')  	|| cv_seperator ||
		REC_S.PF                 					|| cv_seperator ||
		REC_S.TF                 					|| cv_seperator ||
		REC_S.TYPE_DEPENSE       					|| cv_seperator ||      
		REC_S.TYPE_EVENEMENT     					|| cv_seperator ||
		REC_S.QTE                					|| cv_seperator ||
		REC_S.FRAIS              					|| cv_seperator ||
		REC_S.CODE_CLIENT        					|| cv_seperator ||
		REC_S.CODE_INTERBANCAIRE 					|| cv_seperator ||
		REC_S.MATRICULE_EMPLOYE  					|| cv_seperator ||
		REPLACE(REC_S.REF_LETTRAGE,';','-')       	|| cv_seperator ||
		REC_S.DEVISE             					|| cv_seperator ||
		TO_char(REC_S.CREATION_DATE,'DD/MM/YYYY HH24:MI:SS')|| cv_seperator ||
		REC_S.JE_HEADER_ID       					|| cv_seperator ||
		REC_S.PERIODE            					|| cv_seperator ||
		REC_S.CATEGORIE          					|| cv_seperator ||
		REPLACE(REC_S.NOM_PIECE,';','-')            || cv_seperator ||
		REC_S.NUMERO_PIECE       					|| cv_seperator ||
		REC_S.NUMERO_LIGNE       					|| cv_seperator ||
		REC_S.CCF                					|| cv_seperator ||    
		REPLACE(REC_S.LIBELLE_CPTE_LOCAL ,';','-')
	);
END IF;
END IF ;
END IF ;
END LOOP ;
FOR REC_D IN CUR_DETAIL(REC_A.SOC_ABSORBEE , REC_A.SOC_ABSORBANTE) LOOP
------------ SUIVI RB
				
 IF(REC_D.TYPE_DONNEE ='SUIVI RB') THEN
				
 UTL_FILE.PUT_LINE(p_fic_out_ptr_rrb,
		REC_D.LIVRE              					|| cv_seperator ||
		REC_D.SOCIETE            					|| cv_seperator ||
		REC_D.UO                 					|| cv_seperator ||
		REC_D.COMPTE_LOCAL       					|| cv_seperator ||
		REC_D.COMPTE_ANALYTIQUE  					|| cv_seperator ||
		REC_D.INTERCO            					|| cv_seperator ||
		REC_D.CENTRE_FINANCE	 					|| cv_seperator ||
		REC_D.CODE_AFFAIRE	     					|| cv_seperator ||
		REC_D.PROJET_FINANCE    					|| cv_seperator ||
		REC_D.CODE_FLUX         					|| cv_seperator ||  
		REC_D.RESERVE_1         					|| cv_seperator ||
		REC_D.RESERVE_2         					|| cv_seperator ||
		REC_D.RESERVE_3         					|| cv_seperator ||
		REPLACE(ROUND(REC_D.DEBIT,2),'.',',')      || cv_seperator ||
		REPLACE(ROUND(REC_D.CREDIT,2),'.',',')     || cv_seperator ||
		REPLACE(REC_D.DESCRIPTION_LIGNE,';','-')  	|| cv_seperator ||
		REC_D.PF                 					|| cv_seperator ||
		REC_D.TF                 					|| cv_seperator ||
		REC_D.TYPE_DEPENSE       					|| cv_seperator ||      
		REC_D.TYPE_EVENEMENT     					|| cv_seperator ||
		REC_D.QTE                					|| cv_seperator ||
		REC_D.FRAIS              					|| cv_seperator ||
		REC_D.CODE_CLIENT        					|| cv_seperator ||
		REC_D.CODE_INTERBANCAIRE 					|| cv_seperator ||
		REC_D.MATRICULE_EMPLOYE  					|| cv_seperator ||
		REPLACE(REC_D.REF_LETTRAGE,';','-')       	|| cv_seperator ||
		REC_D.DEVISE             					|| cv_seperator ||
		TO_char(REC_D.CREATION_DATE,'DD/MM/YYYY HH24:MI:SS')|| cv_seperator ||
		REC_D.JE_HEADER_ID       					|| cv_seperator ||
		REC_D.PERIODE            					|| cv_seperator ||
		REC_D.CATEGORIE          					|| cv_seperator ||
		REPLACE(REC_D.NOM_PIECE,';','-')           || cv_seperator ||
		REC_D.NUMERO_PIECE       					|| cv_seperator ||
		REC_D.NUMERO_LIGNE       					|| cv_seperator ||
		REC_D.CCF                					|| cv_seperator ||    
		REPLACE(REC_D.LIBELLE_CPTE_LOCAL ,';','-')
	);
------------  LETTRABLES
ELSE IF(REC_D.TYPE_DONNEE ='LETTRABLES') THEN 
 UTL_FILE.PUT_LINE(p_fic_out_ptr_rl,
		REC_D.LIVRE              					|| cv_seperator ||
		REC_D.SOCIETE            					|| cv_seperator ||
		REC_D.UO                 					|| cv_seperator ||
		REC_D.COMPTE_LOCAL       					|| cv_seperator ||
		REC_D.COMPTE_ANALYTIQUE  					|| cv_seperator ||
		REC_D.INTERCO            					|| cv_seperator ||
		REC_D.CENTRE_FINANCE	 					|| cv_seperator ||
		REC_D.CODE_AFFAIRE	     					|| cv_seperator ||
		REC_D.PROJET_FINANCE    					|| cv_seperator ||
		REC_D.CODE_FLUX         					|| cv_seperator ||  
		REC_D.RESERVE_1         					|| cv_seperator ||
		REC_D.RESERVE_2         					|| cv_seperator ||
		REC_D.RESERVE_3         					|| cv_seperator ||
		REPLACE(ROUND(REC_D.DEBIT,2),'.',',')      || cv_seperator ||
		REPLACE(ROUND(REC_D.CREDIT,2),'.',',')     || cv_seperator ||
		REPLACE(REC_D.DESCRIPTION_LIGNE,';','-')  	|| cv_seperator ||
		REC_D.PF                 					|| cv_seperator ||
		REC_D.TF                 					|| cv_seperator ||
		REC_D.TYPE_DEPENSE       					|| cv_seperator ||      
		REC_D.TYPE_EVENEMENT     					|| cv_seperator ||
		REC_D.QTE                					|| cv_seperator ||
		REC_D.FRAIS              					|| cv_seperator ||
		REC_D.CODE_CLIENT        					|| cv_seperator ||
		REC_D.CODE_INTERBANCAIRE 					|| cv_seperator ||
		REC_D.MATRICULE_EMPLOYE  					|| cv_seperator ||
		REPLACE(REC_D.REF_LETTRAGE,';','-')       	|| cv_seperator ||
		REC_D.DEVISE             					|| cv_seperator ||
		to_char(REC_D.CREATION_DATE,'DD/MM/YYYY HH24:MI:SS')|| cv_seperator ||
		REC_D.JE_HEADER_ID       					|| cv_seperator ||
		REC_D.PERIODE            					|| cv_seperator ||
		REC_D.CATEGORIE          					|| cv_seperator ||
		REPLACE(REC_D.NOM_PIECE,';','-')            || cv_seperator ||
		REC_D.NUMERO_PIECE       					|| cv_seperator ||
		REC_D.NUMERO_LIGNE       					|| cv_seperator ||
		REC_D.CCF                					|| cv_seperator ||    
		REPLACE(REC_D.LIBELLE_CPTE_LOCAL ,';','-')
	);
END IF ;
END IF ;
END LOOP ;

	-- Fermeture du fichier plat de sortie
	UTL_FILE.FCLOSE(p_fic_out_ptr_rc);
	UTL_FILE.FCLOSE(p_fic_out_ptr_rl);
	UTL_FILE.FCLOSE(p_fic_out_ptr_rnl);
	UTL_FILE.FCLOSE(p_fic_out_ptr_rh_b);
	UTL_FILE.FCLOSE(p_fic_out_ptr_rrb);
END LOOP ;

END IMPORT_DATA;
/*
 *************************************************************************
 * PROCEDURE NAME : ARCHIVE_DATA
 *
 * DESCRIPTION
 *  Procédure pour Archiver les données extraites  
 *
 * PARAMETERS
 * ==========
 * NAME              DESCRIPTION
 * ----------------- ------------------------------------------------------
 *
 *
 *************************************************************************/
 

PROCEDURE ARCHIVE_DATA  	 (  p_Errbuf            OUT VARCHAR2,
                            p_retcode           OUT NUMBER
                          )   
						  IS
CURSOR CUR_ARCHIVE IS 
	  SELECT *
      FROM DKA_STRANSCO_LINES DSTL
	  WHERE DSTL.SET_ID in (SELECT DSTH.SET_ID 
							FROM  DKA_STRANSCO_HEADERS    DSTH
							WHERE DSTL.SET_ID  = DSTH.SET_ID
							AND    DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
	                       );
	  
BEGIN

FOR REC_ARCHIVE IN CUR_ARCHIVE LOOP
	BEGIN 

INSERT INTO DKA_STRANSCO_LINES_HIST
	VALUES (
		 REC_ARCHIVE.SET_ID            
		,REC_ARCHIVE.LINE_ID           
		,REC_ARCHIVE.PARAM1_VALUE      
		,REC_ARCHIVE.PARAM2_VALUE      
		,REC_ARCHIVE.PARAM3_VALUE      
		,REC_ARCHIVE.PARAMS_VALUE      
		,REC_ARCHIVE.RETURN_VALUE      
		,REC_ARCHIVE.ENABLE            
		,REC_ARCHIVE.CREATION_DATE     
		,REC_ARCHIVE.CREATED_BY        
		,REC_ARCHIVE.LAST_UPDATE_DATE  
		,REC_ARCHIVE.LAST_UPDATED_BY   
		,REC_ARCHIVE.INACTIVE_DATE     
		,REC_ARCHIVE.START_DATE        
		,REC_ARCHIVE.END_DATE          
        );
	
	EXCEPTION
		  WHEN OTHERS THEN
				p_retcode := 1;
                DKA_TOOLS_PKG.Put_Outdebug_Message('problème d''insertion dans la table  DKA_STRANSCO_LINES_HIST : '|| SQLCODE ||
                                              ' - ' || SQLERRM);
END;
END LOOP;
BEGIN				
DELETE from DKA_STRANSCO_LINES DSTL  WHERE DSTL.SET_ID in (SELECT DSTH.SET_ID 
							FROM  DKA_STRANSCO_HEADERS    DSTH
							WHERE DSTL.SET_ID  = DSTH.SET_ID
							AND    DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
	                       );
 EXCEPTION
		  WHEN OTHERS THEN
				p_retcode := 1;
                DKA_TOOLS_PKG.Put_Outdebug_Message('problème de suppression de la table  DKA_STRANSCO_LINES : '|| SQLCODE ||
                                              ' - ' || SQLERRM);

END;
COMMIT;
END;	

				
--------------------------- 	MAIN 

PROCEDURE MAIN(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER, pv_type_fusion IN VARCHAR2)  IS

	v_errbuf                   VARCHAR2(2500);
	v_retcode                  NUMBER;
	Erreur_Programme           EXCEPTION;
	v_current_program_unit VARCHAR2(30);
	v_warning                  BOOLEAN := FALSE;
	BEGIN

    Fnd_File.put_line(Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'DEBUT DE L''INTERFACE');
    Fnd_File.put_line(Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'PHASE D''INITIALISATION'); 
	
	v_current_program_unit := 'MAIN';
    v_errbuf  := NULL;
    v_retcode := 0;
    
	IF v_retcode = 2 
      THEN
          p_Errbuf  := v_errbuf;
          p_retcode := v_retcode;
        --  RAISE Erreur_Programme;
    END IF;   
Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'EXTRACTION DES DONNEES');
-- Lancement d'Extraction des données
	EXTRACT_DATA (
		v_errbuf  , 
		v_retcode 
				);
				
	IF v_retcode = 2 
		THEN
        RAISE Erreur_Programme;
	ELSIF v_retcode = 1 THEN
        v_warning := TRUE;
		END IF;
Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'VALIDATION DES DONNEES');
--Lancement de validation des données				
	VALIDATE_DATA (
		v_errbuf  ,
		v_retcode ,
		pv_type_fusion
		
				  );
				 
	IF v_retcode = 2 
		THEN
        RAISE Erreur_Programme;
	ELSIF v_retcode = 1 THEN
        v_warning := TRUE;
		END IF;
Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'IMPORTATION DES DONNEES');
--Lancement import donnee 
 IMPORT_DATA(
		v_errbuf  ,
		v_retcode 
		);
	
	IF v_retcode = 2 
		THEN
        RAISE Erreur_Programme;
	ELSIF v_retcode = 1 THEN
        v_warning := TRUE;
		END IF;
Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'ARCHIVAGE DES DONNEES');
--Lancement Archivage de donnees
	ARCHIVE_DATA(
		v_errbuf  ,
		v_retcode 
		);
	
	IF v_retcode = 2 
		THEN
        RAISE Erreur_Programme;
	ELSIF v_retcode = 1 THEN
        v_warning := TRUE;
		END IF;
IF p_retcode = 2
		THEN
         p_errbuf := 'ATTENTION : Erreur bloquante : '||p_errbuf;
	
ELSIF V_WARNING		THEN
         p_errbuf := 'ATTENTION : Il y a des cas de rejet ou avertissement.';
         p_retcode := 1;
	ELSE
         p_errbuf := 'Fin normale du traitement - Aucun rejet.';
         p_retcode := 0;
	END IF;
COMMIT;
 EXCEPTION
        WHEN Erreur_Programme
        THEN
            p_retcode   := 2;
            p_errbuf    := v_errbuf;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.OUTPUT, CHR(10)||p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure '||v_current_program_unit||' : EXCEPTION Erreur_Traitement ');
            Fnd_File.put_line (Fnd_File.OUTPUT, '==> Fin de la procédure '||v_current_program_unit||' : EXCEPTION Erreur_Traitement ');
        WHEN OTHERS
        THEN
           fnd_concurrent.af_rollback;
           p_retcode := 2;
           Fnd_File.put_line (Fnd_File.Log,'Erreur technique sur le composant   : '||'DKA_FUSGLFUEXT_PKG.' || v_current_program_unit||CHR(10)||'A retourné     : '||SQLERRM);
           Fnd_File.put_line (Fnd_File.Output ,CHR(10) || '==> Erreur technique (voir journal du traitement)' || CHR(10));
           p_errbuf := SQLERRM;
	
		Dka_Tools_Pkg.Put_Outdebug_Message('');
		Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
		Dka_Tools_Pkg.Put_Outdebug_Message('=> ETAT DES CONTROLES EFFECTUE :');
		Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
		Dka_Tools_Pkg.Put_Outdebug_Message(p_errbuf);
		Dka_Tools_Pkg.Put_Outdebug_Message('');
		Dka_Tools_Pkg.Put_Outdebug_Message('**************************************************************************************');
		Dka_Tools_Pkg.Put_Outdebug_Message('*********Fin des logs de traitements DKA : Fusion GL - Etape2 : FUSION             ***');
		Dka_Tools_Pkg.Put_Outdebug_Message('**************************************************************************************');
		Dka_Tools_Pkg.Put_Outdebug_Message('');
	

END MAIN ; 

END DKA_FUSGLFUEXT_PKG;

/
SHOW ERRORS
EXIT