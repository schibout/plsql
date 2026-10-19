create or replace PACKAGE BODY DKA_SAPFRSDUPLI_PKG IS

--------------------------------------------------------------------------------
-- $$
-- Capgemini
-- Projet           : DALKIA Oracle Applications
-- Nom              : DKA_SAPFRSDUPLI_PKG.pkb
-- Description      : DKA_SAPFRSDUPLI_PKG package body
-- Auteur           : S.HAHIOUI(Capgemini)
-- Date de création : 13/12/2019
-- Doc. associée    :
-- Commentaire      : À exécuter sous SQLPLUS avec l'utilisateur APPS
--------------------------------------------------------------------------------
-- Historique
-- Date       Version Qui Description
-- 17/08/2020 AAM :Retour recette 
-- 12/01/2023 IBA  KDFI-652 Désynchronisation référentiel fournisseur
-- ---------- ------- --- --------------------------------------------------------------
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PRIVEES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  g_package                 VARCHAR2(30)  := 'DKA_SAPFRSDUPLI_PKG';
  g_nom_traitement          VARCHAR2(200) := 'duplication des sites fournisseurs';
  g_sqlerrm                 VARCHAR2(500) := NULL;
  g_retproc                 NUMBER        := 0;
  g_user                    NUMBER        := fnd_profile.value('USER_ID');
------------------------------------------------------------------------------------
-- Nom              : CONTROLE_SITE_FOURNISSEUR
-- Description      : Procédure de control des sites fournisseurs
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



PROCEDURE CONTROLE_SITE_FOURNISSEUR (
                                      p_retcode      OUT NUMBER,
                                      pv_id_site_fournisseur    IN  NUMBER,
                                      pn_resultat_controle      OUT Varchar2,
                                      pv_id_liste_erreur       OUT NUMBER
								     )
IS
--g_user                       NUMBER;
V_ADDRESS_LINE1 				VARCHAR2(240);
V_CITY							VARCHAR2(60);
V_ZIP							VARCHAR2(20);
V_COUNTRY 						VARCHAR2(25);
V_EMAIL_REGLEMENT 				VARCHAR2(2000);
V_EMAIL_COMMANDE				VARCHAR2(2000);
V_REMITTANCE_EMAIL              VARCHAR2(2000);
V_ACCTS_PAY_CODE_COMB_ID	    NUMBER;
V_PREPAY_CODE_COMBINATION_ID	NUMBER;
V_FUTURE_DATED_PAYMENT_CCID		NUMBER(15);
V_SUPPLIER_NOTIF_METHOD			VARCHAR2(25);
V_PURCHASING_SITE_FLAG          VARCHAR2(1);
V_CODE_INTERCO                  VARCHAR2(240);
V_ACTION_ID                     NUMBER;
V_VENDOR_SITE_CODE              VARCHAR2(15);
V_CODE_POSTAL                   NUMBER;
V_CODE_P						NUMBER;
v_vendor_type_lookup_code       varchar2(200) ;
V_COMPTE_LOCAL                  varchar2(200);
V_INTERCO_FOURNISSEUR           varchar2(200);
V_INTERCO_ACOMPTE               varchar2(200);
V_INTERCO_EFFET_PAYER           varchar2(200);
V_CODE_SUPL          			varchar2(15);
V_CODE_PAYS						varchar2(3);
BEGIN
--g_user :=1994;
--g_user := fnd_profile.value('USER_ID');
SELECT ACTION_ID_S.nextval
INTO   V_ACTION_ID
FROM   DUAL;
------------------------RG-CTL1 : Vérification des champs obligatoires ---------------------
--------------------------------------------------------------------------------------------
SELECT  aps.ADDRESS_LINE1
       ,aps.CITY
	   ,aps.ZIP
	   ,aps.EMAIL_ADDRESS
	   ,aps.REMITTANCE_EMAIL
	   ,aps.ACCTS_PAY_CODE_COMBINATION_ID
	   ,aps.PREPAY_CODE_COMBINATION_ID
	   ,aps.FUTURE_DATED_PAYMENT_CCID
	   ,aps.PURCHASING_SITE_FLAG
	   ,aps.SUPPLIER_NOTIF_METHOD
	   ,aps.VENDOR_SITE_CODE
	   ,aps.COUNTRY
	   ,ap.VENDOR_TYPE_LOOKUP_CODE

INTO
		  V_ADDRESS_LINE1
		 ,V_CITY
		 ,V_ZIP
		 ,V_EMAIL_COMMANDE
		 ,V_REMITTANCE_EMAIL
		 ,V_ACCTS_PAY_CODE_COMB_ID
		 ,V_PREPAY_CODE_COMBINATION_ID
		 ,V_FUTURE_DATED_PAYMENT_CCID
		 ,V_PURCHASING_SITE_FLAG
		 ,V_SUPPLIER_NOTIF_METHOD
		 ,V_VENDOR_SITE_CODE
		 ,V_COUNTRY
		 ,V_VENDOR_TYPE_LOOKUP_CODE

FROM
	AP_SUPPLIER_SITES_ALL aps,
	ap_suppliers ap
WHERE
    aps.VENDOR_SITE_ID = pv_id_site_fournisseur
	and ap.vendor_id= aps.vendor_id;

SELECT remit_advice_email 
INTO V_EMAIL_REGLEMENT
FROM  IBY_EXTERNAL_PAYEES_ALL
where supplier_site_id = pv_id_site_fournisseur;

------------------------ Contrôle Adresse ligne 1 -------------------------------
	IF (V_ADDRESS_LINE1 is null ) THEN
    begin
	    p_retcode := 1;
	    INSERT INTO DKA_SAPFRSDUPLI_ERROR_TMP
         values
		 ( V_ACTION_ID,
		 pv_id_site_fournisseur,
		 1,
		 'ERREUR',
		 'L''ADDRESS LINE doit être alimentée',
		 sysdate,
		 g_user) ;
    end;
	END IF;
------------------------     Contrôle ville       -------------------------------

	IF (V_CITY is null ) THEN
	    p_retcode := 1;
	    INSERT INTO DKA_SAPFRSDUPLI_ERROR_TMP values
		( V_ACTION_ID
		 ,pv_id_site_fournisseur
		 ,1
		 ,'ERREUR'
		 ,'La ville doit être alimentée'
		 ,sysdate
		,g_user);
	END IF;
------------------------  Contrôle code postale   -------------------------------
	IF (V_ZIP is null ) THEN
	    p_retcode := 1;
	    INSERT INTO DKA_SAPFRSDUPLI_ERROR_TMP values
		( V_ACTION_ID
		 ,pv_id_site_fournisseur
		 ,1
		 ,'ERREUR'
		 ,'Le Code Postal doit être alimenté'
		 ,sysdate
		 ,g_user);
	END IF;
------------------------      Contrôle pays       -------------------------------
	IF (V_COUNTRY is null ) THEN
	    p_retcode := 1;
	    INSERT INTO DKA_SAPFRSDUPLI_ERROR_TMP values
		( V_ACTION_ID
		 ,pv_id_site_fournisseur
		 ,1
		 ,'ERREUR'
		 ,'Le Pays doit être alimenté'
		 ,sysdate
		 ,g_user) ;
	END IF;
------------------------   Contrôle Adresse EMAIL -------------------------------
	IF (V_EMAIL_COMMANDE is null ) THEN
	    p_retcode := 1;
	    INSERT INTO DKA_SAPFRSDUPLI_ERROR_TMP values
		( V_ACTION_ID
		 ,pv_id_site_fournisseur
		 ,1
		 ,'ERREUR'
		 ,'L''adresse email de commande doit être alimentée'
		 ,sysdate
		 ,g_user) ;
	END IF;

	IF(V_EMAIL_REGLEMENT is null ) THEN
	    p_retcode := 1;
	    INSERT INTO DKA_SAPFRSDUPLI_ERROR_TMP values
		(V_ACTION_ID
		 ,pv_id_site_fournisseur
		 ,1
		 ,'ERREUR'
		 ,'L''adresse email de règlement doit être alimentée'
		 ,sysdate
		 ,g_user) ;
	END IF;


------------------Contrôle Clé comptable « Compte fournisseur » -----------------
	IF (V_ACCTS_PAY_CODE_COMB_ID is null ) THEN
	    p_retcode := 1;
	    INSERT INTO DKA_SAPFRSDUPLI_ERROR_TMP values
		(V_ACTION_ID
		 ,pv_id_site_fournisseur
		 ,'1'
		 ,'ERREUR'
		 ,'La Clé comptable « Compte fournisseur » doit être alimentée'
		 ,sysdate
		 ,g_user) ;
	END IF;


----------------- Contrôle Clé comptable « Acompte  » ---------------------------
	IF (V_PREPAY_CODE_COMBINATION_ID is null ) THEN
	    p_retcode := 1;
	    INSERT INTO DKA_SAPFRSDUPLI_ERROR_TMP values
		( V_ACTION_ID
		 ,pv_id_site_fournisseur
		 ,1
		 ,'ERREUR'
		 ,'La Clé comptable « Compte Acompte » doit être alimentée'
		 ,sysdate
		 ,g_user) ;
	END IF;

-------------- Contrôle Clé comptable « Effet à payer  » ------------------------

	IF (V_FUTURE_DATED_PAYMENT_CCID is null ) THEN
	    p_retcode := 1;
	    INSERT INTO DKA_SAPFRSDUPLI_ERROR_TMP values
		( V_ACTION_ID
		 ,pv_id_site_fournisseur
		 ,1
		 ,'ERREUR'
		 ,'La Clé comptable « Effet à payer » doit être alimentée'
		 ,sysdate
		 ,g_user) ;
	END IF;

------------------------RG-CTL2 : Vérification du mode de communication---------------------
--------------------------------------------------------------------------------------------
	IF (NVL(V_SUPPLIER_NOTIF_METHOD,'@§' ) <> 'EMAIL' and V_PURCHASING_SITE_FLAG = 'Y' ) THEN
	    p_retcode := 1;
	    INSERT INTO DKA_SAPFRSDUPLI_ERROR_TMP values
		( V_ACTION_ID,
		 pv_id_site_fournisseur,
         1,
		 'ERREUR',
		 'Seul le mode de communication « Email » doit être renseigné',
		 sysdate,
		 g_user) ;
	END IF;

-------------------------RG-CTL3 : Format des adresses email -------------------------------
--------------------------------------------------------------------------------------------
	if( not REGEXP_LIKE (V_EMAIL_COMMANDE,'^[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+\.[A-Za-z]{2,4}$')) then
        p_retcode := 1;
	    INSERT INTO DKA_SAPFRSDUPLI_ERROR_TMP values
		( V_ACTION_ID
		 ,pv_id_site_fournisseur
		 ,3
		 ,'ERREUR'
		 ,'Adresse mail de commande non conforme'
		 ,sysdate
		 ,g_user);
	END IF;
	if( not REGEXP_LIKE (V_EMAIL_REGLEMENT,'^[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+\.[A-Za-z]{2,4}$')) then
        p_retcode := 1;
	    INSERT INTO DKA_SAPFRSDUPLI_ERROR_TMP values
		( V_ACTION_ID
		 ,pv_id_site_fournisseur
		 ,3
		 ,'ERREUR'
		 ,'Adresse mail de réglement non conforme'
		 ,sysdate
		 ,g_user);
	END IF;

	------------------------
 if (v_vendor_type_lookup_code = 'PARTENAIRE' or v_vendor_type_lookup_code = 'EXTERNAL  PARTNER' )then
    SELECT  AP.ATTRIBUTE2,
	       (SELECT  gcc.segment3
			FROM  gl_code_combinations gcc
			WHERE gcc.code_combination_id = aps.accts_pay_code_combination_id

	        )
			,(SELECT  gcc.segment5
			FROM  gl_code_combinations gcc
			WHERE gcc.code_combination_id = aps.accts_pay_code_combination_id

	        )
			,(SELECT  gcc.segment5
			FROM  gl_code_combinations gcc
			WHERE gcc.code_combination_id = aps.PREPAY_CODE_COMBINATION_ID

	        )

			,(SELECT  gcc.segment5
			FROM  gl_code_combinations gcc
			WHERE gcc.code_combination_id = aps.FUTURE_DATED_PAYMENT_CCID

	        )

    INTO   V_CODE_INTERCO,
           V_COMPTE_LOCAL,
           V_INTERCO_FOURNISSEUR,
           V_INTERCO_ACOMPTE,
           V_INTERCO_EFFET_PAYER

    FROM
			ap_suppliers ap,
			ap_supplier_sites_all aps
    where aps.vendor_id = ap.vendor_id
	and ap.VENDOR_TYPE_LOOKUP_CODE in ('PARTENAIRE','EXTERNAL  PARTNER')
    and  aps.vendor_site_id = pv_id_site_fournisseur;


------------------ RG-CTL4 : Code interco pour les fournisseurs groupe ---------------------
--------------------------------------------------------------------------------------------
IF V_COMPTE_LOCAL <> '401050'
  THEN
      p_retcode := 1;
      INSERT INTO DKA_SAPFRSDUPLI_ERROR_TMP values
    ( V_ACTION_ID
     ,pv_id_site_fournisseur
     ,5
     ,'ERREUR'
     ,'Fournisseur groupe : le compte local n''est pas correctement renseigné sur la clé comptable fournisseur'
     ,sysdate
     ,g_user);
  END IF;   

  IF ((substr(V_INTERCO_FOURNISSEUR,(LENGTH(V_INTERCO_FOURNISSEUR) - 3),LENGTH(V_INTERCO_FOURNISSEUR))= V_CODE_INTERCO or V_INTERCO_FOURNISSEUR = '0')
      OR (substr(V_INTERCO_ACOMPTE,(LENGTH(V_INTERCO_ACOMPTE) - 3),LENGTH(V_INTERCO_ACOMPTE))= V_CODE_INTERCO or V_INTERCO_ACOMPTE = '0')
    OR (substr(V_INTERCO_EFFET_PAYER,(LENGTH(V_INTERCO_EFFET_PAYER) - 3),LENGTH(V_INTERCO_EFFET_PAYER))= V_CODE_INTERCO or V_INTERCO_EFFET_PAYER = '0')
        ) 
  THEN         
      INSERT INTO DKA_SAPFRSDUPLI_ERROR_TMP values
    ( V_ACTION_ID
     ,pv_id_site_fournisseur
     ,5
     ,'ERREUR'
     ,'Fournisseur groupe : le compte interco n''est pas correctement renseigné sur les clés comptables compte fournisseur, acompte et effets à payer'
     ,sysdate
     ,g_user) ;
  END IF;  


END IF;
----------------------- RG-CTL6 : Nommage du site fournisseur de référence -----------------
--------------------------------------------------------------------------------------------

 BEGIN
  SELECT ISO_TERRITORY_CODE
  INTO   V_CODE_PAYS
  FROM   FND_TERRITORIES
  WHERE  TERRITORY_CODE = V_COUNTRY ;
   EXCEPTION
        WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.OUTPUT,'code pays introuvable') ;
 END;
 BEGIN
  SELECT return_value
  INTO   V_CODE_P
  FROM   DKA_STRANSCO_LINES      DSTL,
		 DKA_STRANSCO_HEADERS    DSTH
  WHERE  DSTL.SET_ID 					 = DSTH.SET_ID
  AND    DSTH.SET_NAME LIKE 'DKA_PAYS_LONGUEUR_CODE_POSTAL'
  AND    DSTL.ENABLE					 = 'Y'
  and    params_value = V_CODE_PAYS
  AND    NVL(DSTL.END_DATE,TRUNC(SYSDATE) ) >= TRUNC(SYSDATE);
  EXCEPTION
        WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.OUTPUT,'longueur code postal introuvable') ;
  END;
--V_CODE_POSTAL := 4 + V_CODE_P;

  IF (length(V_VENDOR_SITE_CODE )>15) THEN
    p_retcode := 1;
	INSERT INTO DKA_SAPFRSDUPLI_ERROR_TMP values
	( V_ACTION_ID
	,pv_id_site_fournisseur
	,6
	,'ERREUR'
	,'Nommage du site non conforme (taille depassée)'
	,sysdate
	,g_user);
    ELSIF(substr(V_VENDOR_SITE_CODE,1,3) <> V_CODE_PAYS )then
		p_retcode := 1;
		INSERT INTO DKA_SAPFRSDUPLI_ERROR_TMP values
		( V_ACTION_ID
		,pv_id_site_fournisseur
		,6
		,'ERREUR'
		,'Nommage du site non conforme (code pays incorrect)'
		,sysdate
		,g_user);
		ELSIF(substr(V_VENDOR_SITE_CODE,4,V_CODE_P) <> V_ZIP or substr(V_VENDOR_SITE_CODE,4,V_CODE_P) is null)then
			p_retcode := 1;
			INSERT INTO DKA_SAPFRSDUPLI_ERROR_TMP values
			( V_ACTION_ID
			,pv_id_site_fournisseur
			,6
			,'ERREUR'
			,'Nommage du site non conforme (code postal incorrect)'
			,sysdate
			,g_user);
			ELSIF(substr(V_VENDOR_SITE_CODE,V_CODE_P + 4) is not null)then
					BEGIN
					   SELECT FLEX_VALUE
                       INTO V_CODE_SUPL
							FROM
							FND_FLEX_VALUE_SETS  	FFVS ,
							FND_FLEX_VALUES_VL   	FFVV
							WHERE  FFVS.FLEX_VALUE_SET_ID 	     = FFVv.FLEX_VALUE_SET_ID
							AND    FFVS.FLEX_VALUE_SET_NAME      = 'DKA_SITE_FRS_COMPLEMENT'
							and FLEX_VALUE = substr(V_VENDOR_SITE_CODE,V_CODE_POSTAL + 1,length(V_VENDOR_SITE_CODE ));
					EXCEPTION
					WHEN OTHERS THEN
					p_retcode := 1;
					INSERT INTO DKA_SAPFRSDUPLI_ERROR_TMP values
					( V_ACTION_ID
					,pv_id_site_fournisseur
					,6
					,'ERREUR'
					,'Nommage du site non conforme (code complémentaire incorrect)'
					,sysdate
					,g_user);
                    END;

 END IF;

Commit;

IF p_retcode = 1
		THEN
         pn_resultat_controle := 'KO';
         pv_id_liste_erreur  := V_ACTION_ID;
	ELSE
         pn_resultat_controle := 'OK';
         p_retcode := 0;
	END IF;


END;



--------------------------------------------------------------------------------
-- $$
-- Capgemini
-- Projet           : DALKIA Oracle Applications
-- Nom              : DKA_SAPFRSDUPLI_PKG.pkb
-- Description      : DKA_SAPFRSDUPLI_PKG package body
-- Auteur           : Saloua.HA(Capgemini)
-- Date de création : 13/12/2019
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
  /*============================================================================*/
  /* Procedure         : writeout                                               */
  /* Description       : Ecriture dans fichier *.OUT                            */
  /* Parametres entree : P_message IN VARCHAR2 : message a ecrire               */
  /* Parametres sortie : AUCUN                                                  */
  /* Auteur            : Asma AMENKOUR                                          */
  /* Date              : 23/12/2019                                             */
  /* Remarques         :                                                        */
  /*============================================================================*/
  PROCEDURE writeout(P_message IN VARCHAR2) IS
    L_procedure VARCHAR2(30) := 'writeout';
    v_etape   VARCHAR2(100);
  BEGIN

    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, P_message);

  EXCEPTION
    WHEN OTHERS THEN
      G_retproc := 1;
      G_sqlerrm := SUBSTR(SQLERRM, 1, 200);
      Fnd_File.put_line(Fnd_File.LOG,
                        '-------------------- ERREUR --------------------');
      Fnd_File.put_line(Fnd_File.LOG, 'Package   : ' || G_package);
      Fnd_File.put_line(Fnd_File.LOG, 'Procedure : ' || L_procedure);
      Fnd_File.put_line(Fnd_File.LOG, 'Exception : OTHERS');
      Fnd_File.put_line(Fnd_File.LOG, 'Message   : ' || v_etape);
      Fnd_File.put_line(Fnd_File.LOG, 'Cause     : ' || G_sqlerrm);
  END writeout;
    /*============================================================================*/
  /* Procedure         : writelog                                               */
  /* Description       : Ecriture dans fichier *.LOG                            */
  /* Parametres entree : P_message IN VARCHAR2 : message a ecrire               */
  /*                   : P_av      IN NUMBER   : Nb de saut de ligne avant      */
  /*                   : P_ap      IN NUMBER   : Nb de saut de ligne apres      */
  /* Parametres sortie : AUCUN                                                  */
  /*============================================================================*/
  PROCEDURE writelog(p_message IN VARCHAR2, p_av IN NUMBER, p_ap IN NUMBER)
  IS

  i                             NUMBER       := 0;
  l_procedure                   VARCHAR2(30) := 'writelog';
  v_etape                     VARCHAR2(2000);

  BEGIN
      v_etape := 'appel a FND_FILE.PUT_LINE';

      FOR i IN 1 .. p_av
      LOOP
          fnd_file.put_line(fnd_file.LOG, ' ');
      END LOOP;

      fnd_file.put_line(fnd_file.LOG, p_message);

      FOR i IN 1 .. p_ap
      LOOP
          fnd_file.put_line(fnd_file.LOG, ' ');
      END LOOP;
  EXCEPTION
      WHEN OTHERS THEN
          g_retproc := 1;
          g_sqlerrm := substr(sqlerrm, 1, 500);
          writelog('-------------------- ERREUR --------------------', 1, 0);
          writelog('Package   : ' || g_package, 0, 0);
          writelog('Procedure : ' || l_procedure, 0, 0);
          writelog('Exception : OTHERS', 0, 0);
          writelog('Message   : ' || v_etape, 0, 0);
          writelog('Cause     : ' || g_sqlerrm, 0, 0);
          writelog('------------------------------------------------', 0, 0);
  END writelog;

------------------------------------------------------------------------------------
-- Nom              : DUPLICATION_SITE_FOURNISSEUR
-- Description      : Procédure de control des sites fournisseurs
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

PROCEDURE DUPLICATION_SITE_FOURNISSEUR (
                                      p_retcode      			OUT NUMBER,
                                      p_perimetre 			    IN  tabtype,
                                      pv_id_site_fournisseur    IN  NUMBER,
                                      pv_nombre_succes          OUT NUMBER,
                                      pv_nombre_echoues         OUT NUMBER,
                                      pv_nombre_ignores         OUT NUMBER,
                                      pn_resultat_duplication   OUT Varchar2,
                                      pv_nombre_existe          OUT NUMBER,
                                      pv_id_liste_erreur        OUT NUMBER,
                                      pv_id_site_cree           OUT NUMBER
                       )        
IS
    v_action_id                 NUMBER;
    vv_party_id                 NUMBER;
    v_status                    VARCHAR(1);
    vv_exist                    VARCHAR2(1);
    vn_vendor_site_id           NUMBER;
    vn_party_site_id            NUMBER;
    vn_location_id              NUMBER;
    vn_cpt_bank                 NUMBER := 0;
    vn_site_ok                  NUMBER := 0;
    vn_site_ko                  NUMBER := 0;
	  vn_site_ignores             NUMBER := 0;
    e_error                     EXCEPTION;
    --API
    vn_api_version              NUMBER;
    vv_init_msg_list            VARCHAR2(200);
    vv_commit                   VARCHAR2(200);
    vn_validation_level         NUMBER;
    vv_return_status            VARCHAR2(200);
    vv_message                  VARCHAR2(500);
    vn_cpt_existe               NUMBER := 0;
    vn_msg_count                NUMBER;
    vv_msg_data                 VARCHAR2(2000);
    vn_msg_index_out            NUMBER;
    vv_errbuf                   VARCHAR2(500);
    --g_user                    NUMBER;
    vn_assign_id                NUMBER;
    vn_retcode                  PLS_INTEGER := 0;
    vv_currency_code            VARCHAR(20);
    v_payment_method_code       IBY_EXT_PARTY_PMT_MTHDS.payment_method_code%TYPE;
    vr_payee_context_rec        iby_disbursement_setup_pub.payeecontext_rec_type;
    vr_assignment_attribs       iby_fndcpt_setup_pub.pmtinstrassignment_rec_type;
    p_ext_payee_tab             iby_disbursement_setup_pub.external_payee_tab_type;
    p_ext_payee_id_tab          iby_disbursement_setup_pub.Ext_Payee_ID_Tab_Type;
    vn_prepay_ccid              gl_code_combinations.code_combination_id%TYPE;
    vn_future_ccid              gl_code_combinations.code_combination_id%TYPE;
    vv_account_id               iby_ext_bank_accounts.ext_bank_account_id%TYPE;
    vv_bill_to_location_id      ap_supplier_sites_all.bill_to_location_id%TYPE;
	vv_ship_to_location_id      ap_supplier_sites_all.ship_to_location_id%TYPE;
    l_payee_upd_status          iby_disbursement_setup_pub.ext_payee_update_tab_type;
    l_payee_upd_id              iby_disbursement_setup_pub.Ext_Payee_ID_Tab_Type;
    p_external_payee_tab_type   iby_disbursement_setup_pub.external_payee_tab_type;
    p_ext_payee_id_tab_type     iby_disbursement_setup_pub.ext_payee_id_tab_type;
    vv_ext_payee_id             IBY_EXTERNAL_PAYEES_ALL.ext_payee_id%type;
    vv_payee_party_id           IBY_EXTERNAL_PAYEES_ALL.payee_party_id %type;
    vv_iban                     iby_ext_bank_accounts.iban%TYPE;
    vv_start_date               iby_pmt_instr_uses_all.start_date%TYPE;
    vv_end_date                 iby_pmt_instr_uses_all.end_date%TYPE;
    vr_site_rowtype             ap_supplier_sites_all%rowtype;
    vr_compte_rowtype           iby_external_payees_all%rowtype;
    vr_vendor_site_rec          ap_vendor_pub_pkg.r_vendor_site_rec_type;
    vn_accts_pay_ccid           gl_code_combinations.code_combination_id%TYPE;
    vr_response                 iby_fndcpt_common_pub.result_rec_type;
    vn_segment1                 gl_code_combinations.segment1%TYPE;
    vn_segment2                 gl_code_combinations.segment2%TYPE;
    vn_segment3                 gl_code_combinations.segment3%TYPE;
    vn_segment4                 gl_code_combinations.segment4%TYPE;
    vn_segment5                 gl_code_combinations.segment5%TYPE;
    vn_segment6                 gl_code_combinations.segment6%TYPE;
    vn_segment7                 gl_code_combinations.segment7%TYPE;
    vn_segment8                 gl_code_combinations.segment8%TYPE;
    vn_segment9                 gl_code_combinations.segment9%TYPE;
    vn_segment10                gl_code_combinations.segment10%TYPE;
    vn_segment11                gl_code_combinations.segment11%TYPE;
    vn_segment12                gl_code_combinations.segment12%TYPE;
    vv_bank_account             IBY_EXT_BANK_ACCOUNTS.BANK_ACCOUNT_NAME%type;
    vv_status_dup               VARCHAR2(1);
    vv_status_reg               VARCHAR2(1);
    vv_status_ratt              VARCHAR2(1):= 'S';
    x_return_status             VARCHAR2(200)                         := NULL;
    x_msg_count                 NUMBER                                := 0;
    i                           NUMBER                                := 0;
    x_msg_data                  VARCHAR2(200)                         := NULL;
    t_output                    VARCHAR2(200)                         := NULL;
    t_msg_dummy                 VARCHAR2(200)                         := NULL;
    v_code_partenaire           VARCHAR2(50);
    CURSOR c_uo ( vv_perimetre VARCHAR) 
    IS
     ----- cas ALL
     SELECT
        organization_id,
        name,
        set_of_books_id,
		    date_to
     FROM
        hr_operating_units
     WHERE
        organization_id IN (
            SELECT
                organization_id
            FROM
                per_security_organizations
            WHERE
                security_profile_id = (
                    SELECT
                        security_profile_id
                    FROM
                        per_security_profiles
                    WHERE
                        security_profile_name = 'DKA_TOUT'
                )
        )
        AND   vv_perimetre = 'ALL'
     UNION
	   ----- cas RÉGION
     SELECT
        organization_id,
        name,
        set_of_books_id,
		    date_to
     FROM
        hr_operating_units
     WHERE
        (
            substr(name,1,3) = vv_perimetre
            AND   organization_id IN (
                SELECT
                    organization_id
                FROM
                    per_security_organizations
                WHERE
                    security_profile_id = (
                        SELECT
                            security_profile_id
                        FROM
                            per_security_profiles
                        WHERE
                            security_profile_name = 'DKA_TOUT'
                    )
            )
            OR    name = vv_perimetre
        )
		 ;

     TYPE t_uo IS
        TABLE OF c_uo%rowtype INDEX BY BINARY_INTEGER;
     lt_uo                    t_uo;

     -- TYPE p_peri IS
        -- TABLE OF VARCHAR2(20);
     --  p_perimetre              p_peri := p_peri('DMS');


  	------- cursor des comptes bancaires
    CURSOR cur_c_banc_ref IS 
      SELECT IEB.ext_bank_account_id,
             IEB.BANK_ACCOUNT_NAME,
             IPI.start_date,
             IPI.end_date,
             APS.party_id,
             IPI.ORDER_OF_PREFERENCE
      FROM
             HZ_PARTIES HZP ,
             AP_SUPPLIERS APS ,
             HZ_PARTY_SITES SITE_SUPP ,
             AP_SUPPLIER_SITES_ALL ASS ,
             IBY_EXTERNAL_PAYEES_ALL IEP ,
             IBY_PMT_INSTR_USES_ALL IPI ,
             IBY_EXT_BANK_ACCOUNTS IEB
      WHERE
           HZP.PARTY_ID = APS.PARTY_ID
       AND HZP.PARTY_ID = SITE_SUPP.PARTY_ID
       AND SITE_SUPP.PARTY_SITE_ID = ASS.PARTY_SITE_ID
       AND ASS.VENDOR_ID = APS.VENDOR_ID
       AND IPI.payment_function = 'PAYABLES_DISB'
       AND IEP.PAYEE_PARTY_ID = HZP.PARTY_ID
       AND IEP.PARTY_SITE_ID = SITE_SUPP.PARTY_SITE_ID
       AND IEP.SUPPLIER_SITE_ID = ASS.VENDOR_SITE_ID
       AND IEP.EXT_PAYEE_ID = IPI.EXT_PMT_PARTY_ID
       AND IPI.INSTRUMENT_ID = IEB.EXT_BANK_ACCOUNT_ID
       AND ASS.VENDOR_SITE_ID = pv_id_site_fournisseur
       AND nvl(IPI.end_date,SYSDATE) >= SYSDATE
       ORDER BY IPI.ORDER_OF_PREFERENCE
 ;


BEGIN
    -- fnd_global.apps_initialize(user_id => 12244,resp_id => 50938,resp_appl_id => 200);
    SELECT
        action_id_s.NEXTVAL
    INTO
        v_action_id
    FROM
        dual;

    -- g_user := 1994;
	  -----site fournisseur
    BEGIN
        SELECT
            *
        INTO
            vr_site_rowtype
        FROM
            ap_supplier_sites_all assa
        WHERE
            assa.vendor_site_id = pv_id_site_fournisseur;
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                INSERT INTO dka_sapfrsdupli_error_tmp VALUES (
                    v_action_id,
                    pv_id_site_fournisseur,
                    1,
                    'AVERTISSEMENT',
                    'Impossible de récupérer les informations du site fournisseur pour l''id : '
                    || pv_id_site_fournisseur,
                    SYSDATE,
                    g_user
                );

            END;
    END;

    ------ compte bancaire
    BEGIN
        SELECT
            *
        INTO
            vr_compte_rowtype
        FROM
            iby_external_payees_all iepa
        WHERE 1 = 1
        AND   iepa.supplier_site_id = pv_id_site_fournisseur
        AND   iepa.org_id = vr_site_rowtype.org_id;
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                INSERT INTO dka_sapfrsdupli_error_tmp VALUES (
                    v_action_id,
                    pv_id_site_fournisseur,
                    2,
                    'AVERTISSEMENT',
                    'Impossible de récupérer les informations bancaires pour le site id :'
                    || pv_id_site_fournisseur,
                    SYSDATE,
                    g_user
                );

            END;
    END;



    BEGIN
        SELECT
            hps.status
        INTO
            v_status
        FROM
            ap_supplier_sites_all assa,
            hz_party_sites hps
        WHERE
            vendor_site_id = pv_id_site_fournisseur
            AND   assa.party_site_id = hps.party_site_id
            AND   hps.status = 'A';

    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                INSERT INTO dka_sapfrsdupli_error_tmp VALUES (
                    v_action_id,
                    pv_id_site_fournisseur,
                    3,
                    'AVERTISSEMENT',
                    'problème de recupération de statut pour le site id:'
                    || pv_id_site_fournisseur,
                    SYSDATE,
                    g_user
                );

            END;
    END;

    ------ Sites fournisseurs actifs
    IF
        ( v_status = 'A' )
    THEN
        FOR i IN p_perimetre.first..p_perimetre.last LOOP
          
          
            OPEN c_uo(p_perimetre(i) );
            FETCH c_uo BULK COLLECT INTO lt_uo;
            CLOSE c_uo;
              IF
                   lt_uo.count > 0
              THEN

                FOR k IN lt_uo.first..lt_uo.last LOOP
                  vv_status_ratt := 'S';-- AAM
                  Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début duplication vendor_site_id : '||pv_id_site_fournisseur||'; UO : '||lt_uo(k).name);
                  IF lt_uo(k).date_to is null THEN
                    BEGIN
                        SELECT
                            '1'
                        INTO
                            vv_exist
                        FROM
                            ap_supplier_sites_all apssa
                        WHERE
                            apssa.org_id = lt_uo(k).organization_id
                            AND   apssa.location_id = vr_site_rowtype.location_id;

                    EXCEPTION
                        WHEN too_many_rows THEN
                            vv_exist := '1';
                        WHEN OTHERS THEN
                            vv_exist := NULL;
                    END;

                    IF
                        vv_exist IS NULL
                    THEN
                      BEGIN
                         /*	------- infos compte bancaire
                             SELECT
                                 IEB.ext_bank_account_id,
                                 IEB.BANK_ACCOUNT_NAME,
                                 IPI.start_date,
                                 APS.party_id
                             into
                                 vv_account_id,
                                 vv_bank_account,
                                 vv_start_date,
                                 vv_party_id
                             FROM
                                 HZ_PARTIES HZP ,
                                 AP_SUPPLIERS APS ,
                                 HZ_PARTY_SITES SITE_SUPP ,
                                 AP_SUPPLIER_SITES_ALL ASS ,
                                 IBY_EXTERNAL_PAYEES_ALL IEP ,
                                 IBY_PMT_INSTR_USES_ALL IPI ,
                                 IBY_EXT_BANK_ACCOUNTS IEB
                             WHERE
                                 HZP.PARTY_ID = APS.PARTY_ID
                             AND HZP.PARTY_ID = SITE_SUPP.PARTY_ID
                             AND SITE_SUPP.PARTY_SITE_ID = ASS.PARTY_SITE_ID
                             AND ASS.VENDOR_ID = APS.VENDOR_ID
                             AND IPI.payment_function = 'PAYABLES_DISB'
                             AND IEP.PAYEE_PARTY_ID = HZP.PARTY_ID
                             AND IEP.PARTY_SITE_ID = SITE_SUPP.PARTY_SITE_ID
                             AND IEP.SUPPLIER_SITE_ID = ASS.VENDOR_SITE_ID
                             AND IEP.EXT_PAYEE_ID = IPI.EXT_PMT_PARTY_ID
                             AND IPI.INSTRUMENT_ID = IEB.EXT_BANK_ACCOUNT_ID
                             AND ASS.VENDOR_SITE_ID = pv_id_site_fournisseur
                             AND   nvl(ieb.end_date,SYSDATE) >= SYSDATE
                          ;*/

                         SELECT ieppm.payment_method_code  
                         INTO   v_payment_method_code
                         FROM IBY_EXT_PARTY_PMT_MTHDS ieppm
                            , IBY_EXTERNAL_PAYEES_ALL iepa
                         WHERE iepa.ext_payee_id = ieppm.ext_pmt_party_id
                         AND ieppm.payment_function = 'PAYABLES_DISB'
                         AND ieppm.primary_flag = 'Y'
                         AND iepa.supplier_site_id = pv_id_site_fournisseur;
                      EXCEPTION
                      WHEN OTHERS THEN
                          NULL;
                      END;


                      -- RG-DUP13 : Cas de la duplication du site d¿un fournisseur GROUPE sur la société du fournisseur 
                      BEGIN
                         SELECT aps.attribute2 
                         INTO   v_code_partenaire
                         FROM ap_suppliers aps ,
                              ap_supplier_sites_all assa 
                         WHERE aps.vendor_id = assa.vendor_id
                         AND   assa.vendor_site_id = pv_id_site_fournisseur;
                      EXCEPTION
                      WHEN OTHERS THEN
                          v_code_partenaire := NULL;
                      END;

                      IF (v_code_partenaire= substr(lt_uo(k).name,4,4))
                      THEN

                          INSERT INTO dka_sapfrsdupli_error_tmp VALUES (
                                    v_action_id,
                                    pv_id_site_fournisseur,
                                    4,
                                    'AVERTISSEMENT',
                                    'Le site ne peut pas être dupliqué sur la société du fournisseur partenaire : '||lt_uo(k).name
                                    || vv_errbuf,
                                    SYSDATE,
                                    g_user
                                );
                          vn_site_ignores := vn_site_ignores + 1;
                      ELSE
                        -- Récupération nouveau compte fournisseur
                        BEGIN
                            SELECT
                                segment1,
                                segment2,
                                segment3,
                                segment4,
                                segment5,
                                segment6,
                                segment7,
                                segment8,
                                segment9,
                                segment10,
                                segment11,
                                segment12
                            INTO
                                vn_segment1,
                                vn_segment2,
                                vn_segment3,
                                vn_segment4,
                                vn_segment5,
                                vn_segment6,
                                vn_segment7,
                                vn_segment8,
                                vn_segment9,
                                vn_segment10,
                                vn_segment11,
                                vn_segment12
                            FROM
                                gl_code_combinations
                            WHERE
                                code_combination_id = vr_site_rowtype.accts_pay_code_combination_id;

                        EXCEPTION
                        WHEN OTHERS THEN
                                NULL;
                        END;

                        --Compte GL founisseur
                        dka_tools_pkg.get_code_combination_id(
                                                  pv_segment1 => substr(lt_uo(k).name,4,4),
                                                  pv_segment2 => substr(lt_uo(k).name,1,3),
                                                  pv_segment3 =>vn_segment3,
                                                  pv_segment4 => vn_segment4,
                                                  pv_segment5 => vn_segment5,
                                                  pv_segment6 => vn_segment6,
                                                  pv_segment7 => vn_segment7,
                                                  pv_segment8 => vn_segment8,
                                                  pv_segment9 => vn_segment9,
                                                  pv_segment10 => vn_segment10,
                                                  pv_segment11 => vn_segment11,
                                                  pv_segment12 => vn_segment12,
                                                  pn_code_combination_id=> vn_accts_pay_ccid,
                                                  pv_errbuf => vv_errbuf,
                                                  pn_retcode => vn_retcode);

                        IF
                            vn_retcode != 0
                        THEN
                            BEGIN
                                INSERT INTO dka_sapfrsdupli_error_tmp VALUES (
                                    v_action_id,
                                    pv_id_site_fournisseur,
                                    4,
                                    'ERREUR',
                                    'La clé comptable '||substr(lt_uo(k).name,4,4)||'.'||substr(lt_uo(k).name,1,3)||'.'||vn_segment3||'.'||vn_segment4||'.'||vn_segment5||
                                    '.'||vn_segment6||'.'||vn_segment7||'.'||vn_segment8||'.'||vn_segment9||'.'||vn_segment10||'.'||vn_segment11||'.'||vn_segment12||
                                    ' n''a pas pu être générée- '||vv_errbuf,
                                    SYSDATE,
                                    g_user
                                );
                            vn_site_ko := vn_site_ko + 1;
                            GOTO Fin;
                            END;
                        END IF;

                        -- Récupération nouveau compte accompte
                        BEGIN
                            SELECT
                                segment1,
                                segment2,
                                segment3,
                                segment4,
                                segment5,
                                segment6,
                                segment7,
                                segment8,
                                segment9,
                                segment10,
                                segment11,
                                segment12
                            INTO
                                vn_segment1,vn_segment2,vn_segment3,vn_segment4,
                                vn_segment5,vn_segment6,vn_segment7,vn_segment8,
                                vn_segment9,vn_segment10,vn_segment11,vn_segment12
                            FROM
                                gl_code_combinations
                            WHERE
                                code_combination_id = vr_site_rowtype.prepay_code_combination_id;

                        EXCEPTION
                        WHEN OTHERS THEN
                                NULL;
                        END;

                        --Compte GL acompte

                        dka_tools_pkg.get_code_combination_id(
                                                  pv_segment1 => substr(lt_uo(k).name,4,4),
                                                  pv_segment2 => substr(lt_uo(k).name,1,3),
                                                  pv_segment3 =>vn_segment3,
                                                  pv_segment4 => vn_segment4,
                                                  pv_segment5 => vn_segment5,
                                                  pv_segment6 => vn_segment6,
                                                  pv_segment7 => vn_segment7,
                                                  pv_segment8 => vn_segment8,
                                                  pv_segment9 => vn_segment9,
                                                  pv_segment10 => vn_segment10,
                                                  pv_segment11 => vn_segment11,
                                                  pv_segment12 => vn_segment12,
                                                  pn_code_combination_id => vn_prepay_ccid,
                                                  pv_errbuf => vv_errbuf,
                                                  pn_retcode => vn_retcode);

                        IF
                            vn_retcode != 0
                        THEN
                            BEGIN
                                INSERT INTO dka_sapfrsdupli_error_tmp VALUES (
                                    v_action_id,
                                    pv_id_site_fournisseur,
                                    5,
                                    'ERREUR',
                                    'La clé comptable '||substr(lt_uo(k).name,4,4)||'.'||substr(lt_uo(k).name,1,3)||'.'||vn_segment3||'.'||vn_segment4||'.'||vn_segment5||
                                    '.'||vn_segment6||'.'||vn_segment7||'.'||vn_segment8||'.'||vn_segment9||'.'||vn_segment10||'.'||vn_segment11||'.'||vn_segment12||
                                    ' n''a pas pu être générée- '||vv_errbuf,
                                    SYSDATE,
                                    g_user
                                );
                            vn_site_ko := vn_site_ko + 1;
                            GOTO Fin;
                            END;
                        END IF;

                        BEGIN
                            SELECT
                                segment1,
                                segment2,
                                segment3,
                                segment4,
                                segment5,
                                segment6,
                                segment7,
                                segment8,
                                segment9,
                                segment10,
                                segment11,
                                segment12
                            INTO
                                vn_segment1,vn_segment2,vn_segment3,
                                vn_segment4,vn_segment5,vn_segment6,
                                vn_segment7,vn_segment8,vn_segment9,
                                vn_segment10,vn_segment11,vn_segment12
                            FROM
                                gl_code_combinations
                            WHERE
                                code_combination_id = vr_site_rowtype.future_dated_payment_ccid;

                        EXCEPTION
                        WHEN OTHERS THEN
                                NULL;
                        END;

                        dka_tools_pkg.get_code_combination_id(
                                pv_segment1 => substr(lt_uo(k).name,4,4),
                                pv_segment2 => substr(lt_uo(k).name,1,3),
                                pv_segment3 => vn_segment3,
                                pv_segment4 => vn_segment4,
                                pv_segment5 => vn_segment5,
                                pv_segment6 => vn_segment6,
                                pv_segment7 => vn_segment7,
                                pv_segment8 => vn_segment8,
                                pv_segment9 => vn_segment9,
                                pv_segment10 => vn_segment10,
                                pv_segment11 => vn_segment11,
                                pv_segment12 => vn_segment12,
                                pn_code_combination_id=> vn_future_ccid,
                                pv_errbuf => vv_errbuf,
                                pn_retcode => vn_retcode);

                        IF
                            vn_retcode != 0
                        THEN
                            BEGIN
                                INSERT INTO dka_sapfrsdupli_error_tmp VALUES (
                                    v_action_id,
                                    pv_id_site_fournisseur,
                                    6,
                                    'ERREUR',
                                    'La clé comptable '||substr(lt_uo(k).name,4,4)||'.'||substr(lt_uo(k).name,1,3)||'.'||vn_segment3||'.'||vn_segment4||'.'||vn_segment5||
                                    '.'||vn_segment6||'.'||vn_segment7||'.'||vn_segment8||'.'||vn_segment9||'.'||vn_segment10||'.'||vn_segment11||'.'||vn_segment12||
                                    ' n''a pas pu être générée- '||vv_errbuf,
                                    SYSDATE,
                                    g_user
                                );
                        vn_site_ko := vn_site_ko + 1;
                        GOTO Fin;
                          END;
                        END IF;


                        --------------Duplication des informations de devise
                        BEGIN
                            SELECT
                                currency_code
                            INTO
                                vv_currency_code
                            FROM
                                gl_ledgers gl
                            WHERE
                                gl.ledger_id = lt_uo(k).set_of_books_id;

                        EXCEPTION
                        WHEN OTHERS THEN
                              vv_message := 'currency_code manquant ';
                              writelog(vv_message,0,0);
                        END;

                        --------------bill to location
                        BEGIN
                            SELECT
                                bill_to_location_id
                            INTO
                                vv_bill_to_location_id
                            FROM
                                FINANCIALS_SYSTEM_PARAMS_ALL
                            WHERE
                                org_id = lt_uo(k).organization_id;

                        EXCEPTION
                        WHEN OTHERS THEN
                           -- vv_message := 'bill_to_location_id manquant ';
                           -- writelog(vv_message,0,0);
                           vv_bill_to_location_id := NULL;
                        END;
                     --------------ship to location
                        BEGIN
                            SELECT
                                ship_to_location_id
                            INTO
                                vv_ship_to_location_id
                            FROM
                                FINANCIALS_SYSTEM_PARAMS_ALL
                            WHERE
                                org_id = lt_uo(k).organization_id;

                        EXCEPTION
                        WHEN OTHERS THEN
                           
                           vv_ship_to_location_id := NULL;
                        END;

                        --Init valeur site fournisseur
                        vn_api_version      := 1.0;
                        vv_init_msg_list    := FND_API.G_TRUE;
                        vv_commit           := FND_API.G_FALSE;
                        vn_validation_level := FND_API.G_VALID_LEVEL_FULL;
                        vv_return_status    := NULL;
                        vn_msg_count        := NULL;
                        vv_msg_data         := NULL;

                        vn_vendor_site_id     := NULL;
                        vn_party_site_id      := NULL;
                        vn_location_id        := NULL;

                        vr_vendor_site_rec.vendor_site_id                := NULL;
                        vr_vendor_site_rec.last_update_date              := SYSDATE;
                        vr_vendor_site_rec.last_updated_by               := g_user ;---1;
                        vr_vendor_site_rec.vendor_id                     := vr_site_rowtype.vendor_id;
                        vr_vendor_site_rec.org_id                        := lt_uo(k).organization_id;
                        vr_vendor_site_rec.vendor_site_code              := vr_site_rowtype.vendor_site_code;
                        vr_vendor_site_rec.vendor_site_code_alt          := vr_site_rowtype.vendor_site_code_alt;
                        vr_vendor_site_rec.area_code                     := vr_site_rowtype.area_code;
                        vr_vendor_site_rec.phone                         := vr_site_rowtype.phone;
                        vr_vendor_site_rec.customer_num                  := vr_site_rowtype.customer_num;
                        vr_vendor_site_rec.ship_to_location_id           := vv_ship_to_location_id;
                        vr_vendor_site_rec.bill_to_location_id           := vv_bill_to_location_id;
                        vr_vendor_site_rec.ship_via_lookup_code          := vr_site_rowtype.ship_via_lookup_code;
                        vr_vendor_site_rec.freight_terms_lookup_code     := vr_site_rowtype.freight_terms_lookup_code;
                        vr_vendor_site_rec.fob_lookup_code               := vr_site_rowtype.fob_lookup_code;
                        vr_vendor_site_rec.inactive_date                 := vr_site_rowtype.inactive_date;
                        vr_vendor_site_rec.fax                           := vr_site_rowtype.fax;
                        vr_vendor_site_rec.fax_area_code                 := vr_site_rowtype.fax_area_code;
                        vr_vendor_site_rec.telex                         := vr_site_rowtype.telex;
                        vr_vendor_site_rec.terms_date_basis              := vr_site_rowtype.terms_date_basis;
                        vr_vendor_site_rec.distribution_set_id           := vr_site_rowtype.distribution_set_id;
                        vr_vendor_site_rec.accts_pay_code_combination_id := vn_ACCTS_PAY_CCID;
                        vr_vendor_site_rec.prepay_code_combination_id    := vn_PREPAY_CCID;
                        vr_vendor_site_rec.pay_group_lookup_code         := vr_site_rowtype.pay_group_lookup_code;
                        vr_vendor_site_rec.payment_priority              := vr_site_rowtype.payment_priority;
                        vr_vendor_site_rec.terms_id                      := vr_site_rowtype.terms_id;
                        vr_vendor_site_rec.invoice_amount_limit          := vr_site_rowtype.invoice_amount_limit;
                        vr_vendor_site_rec.pay_date_basis_lookup_code    := vr_site_rowtype.pay_date_basis_lookup_code;
                        vr_vendor_site_rec.always_take_disc_flag         := vr_site_rowtype.always_take_disc_flag;
                        vr_vendor_site_rec.invoice_currency_code         := vv_currency_code;
                        vr_vendor_site_rec.payment_currency_code         := vv_currency_code;
                        vr_vendor_site_rec.purchasing_site_flag          := vr_site_rowtype.purchasing_site_flag;
                        vr_vendor_site_rec.rfq_only_site_flag            := vr_site_rowtype.rfq_only_site_flag;
                        vr_vendor_site_rec.pay_site_flag                 := vr_site_rowtype.pay_site_flag;
                        vr_vendor_site_rec.attention_ar_flag             := vr_site_rowtype.attention_ar_flag;
                        vr_vendor_site_rec.hold_all_payments_flag        := vr_site_rowtype.hold_all_payments_flag;
                        vr_vendor_site_rec.hold_future_payments_flag     := vr_site_rowtype.hold_future_payments_flag;
                        vr_vendor_site_rec.hold_reason                   := vr_site_rowtype.hold_reason;
                        vr_vendor_site_rec.hold_unmatched_invoices_flag  := vr_site_rowtype.hold_unmatched_invoices_flag;
                        vr_vendor_site_rec.tax_reporting_site_flag       := vr_site_rowtype.tax_reporting_site_flag;
                        vr_vendor_site_rec.attribute_category            := vr_site_rowtype.attribute_category;
                        vr_vendor_site_rec.attribute1                    := vr_site_rowtype.attribute1;
                        vr_vendor_site_rec.attribute4                    := vr_site_rowtype.attribute4;
                        vr_vendor_site_rec.attribute6                    := vr_site_rowtype.attribute6;
                        vr_vendor_site_rec.attribute7                    := vr_site_rowtype.attribute7;
                        vr_vendor_site_rec.validation_number             := NULL;
                        vr_vendor_site_rec.exclude_freight_from_discount := vr_site_rowtype.exclude_freight_from_discount;
                        vr_vendor_site_rec.bank_charge_bearer            := vr_site_rowtype.bank_charge_bearer;
                        vr_vendor_site_rec.check_digits                  := vr_site_rowtype.check_digits;
                        vr_vendor_site_rec.allow_awt_flag                := vr_site_rowtype.allow_awt_flag;
                        vr_vendor_site_rec.awt_group_id                  := NULL;
                        vr_vendor_site_rec.pay_awt_group_id              := NULL;
                        vr_vendor_site_rec.default_pay_site_id           := NULL;
                        vr_vendor_site_rec.pay_on_code                   := vr_site_rowtype.pay_on_code;
                        vr_vendor_site_rec.pay_on_receipt_summary_code   := vr_site_rowtype.pay_on_receipt_summary_code;
                        vr_vendor_site_rec.global_attribute_category     := vr_site_rowtype.global_attribute_category;
                        vr_vendor_site_rec.global_attribute1             := vr_site_rowtype.global_attribute1;
                        vr_vendor_site_rec.global_attribute2             := vr_site_rowtype.global_attribute2;
                        vr_vendor_site_rec.global_attribute3             := vr_site_rowtype.global_attribute3;
                        vr_vendor_site_rec.global_attribute4             := vr_site_rowtype.global_attribute4;
                        vr_vendor_site_rec.global_attribute5             := vr_site_rowtype.global_attribute5;
                        vr_vendor_site_rec.global_attribute6             := vr_site_rowtype.global_attribute6;
                        vr_vendor_site_rec.global_attribute7             := vr_site_rowtype.global_attribute7;
                        vr_vendor_site_rec.global_attribute8             := vr_site_rowtype.global_attribute8;
                        vr_vendor_site_rec.global_attribute9             := vr_site_rowtype.global_attribute9;
                        vr_vendor_site_rec.global_attribute10            := vr_site_rowtype.global_attribute10;
                        vr_vendor_site_rec.global_attribute11            := vr_site_rowtype.global_attribute11;
                        vr_vendor_site_rec.global_attribute12            := vr_site_rowtype.global_attribute12;
                        vr_vendor_site_rec.global_attribute13            := vr_site_rowtype.global_attribute13;
                        vr_vendor_site_rec.global_attribute14            := vr_site_rowtype.global_attribute14;
                        vr_vendor_site_rec.global_attribute15            := vr_site_rowtype.global_attribute15;
                        vr_vendor_site_rec.global_attribute16            := vr_site_rowtype.global_attribute16;
                        vr_vendor_site_rec.global_attribute17            := vr_site_rowtype.global_attribute17;
                        vr_vendor_site_rec.global_attribute18            := vr_site_rowtype.global_attribute18;
                        vr_vendor_site_rec.global_attribute19            := vr_site_rowtype.global_attribute19;
                        vr_vendor_site_rec.global_attribute20            := vr_site_rowtype.global_attribute20;
                        vr_vendor_site_rec.tp_header_id                  := NULL;
                        vr_vendor_site_rec.ece_tp_location_code          := vr_site_rowtype.ece_tp_location_code;
                        vr_vendor_site_rec.pcard_site_flag               := vr_site_rowtype.pcard_site_flag;
                        vr_vendor_site_rec.match_option                  := vr_site_rowtype.match_option;
                        vr_vendor_site_rec.country_of_origin_code        := vr_site_rowtype.country_of_origin_code;
                        vr_vendor_site_rec.future_dated_payment_ccid     := vn_future_CCID;
                        vr_vendor_site_rec.create_debit_memo_flag        := vr_site_rowtype.create_debit_memo_flag;
                        vr_vendor_site_rec.supplier_notif_method         := vr_site_rowtype.supplier_notif_method;
                        vr_vendor_site_rec.email_address                 := vr_site_rowtype.email_address;
                        vr_vendor_site_rec.primary_pay_site_flag         := vr_site_rowtype.primary_pay_site_flag;
                        vr_vendor_site_rec.shipping_control              := vr_site_rowtype.shipping_control;
                        vr_vendor_site_rec.selling_company_identifier    := vr_site_rowtype.selling_company_identifier;
                        vr_vendor_site_rec.gapless_inv_num_flag          := vr_site_rowtype.gapless_inv_num_flag;
                        vr_vendor_site_rec.location_id                   := vr_site_rowtype.location_id;
                        vr_vendor_site_rec.party_site_id                 := vr_site_rowtype.party_site_id;
                        vr_vendor_site_rec.duns_number                   := vr_site_rowtype.duns_number;
                        vr_vendor_site_rec.address_style                 := vr_site_rowtype.address_style;
                        vr_vendor_site_rec.LANGUAGE                      := vr_site_rowtype.LANGUAGE;
                        vr_vendor_site_rec.province                      := vr_site_rowtype.province;
                        vr_vendor_site_rec.country                       := vr_site_rowtype.country;
                        vr_vendor_site_rec.address_line1                 := vr_site_rowtype.address_line1;
                        vr_vendor_site_rec.address_line2                 := vr_site_rowtype.address_line2;
                        vr_vendor_site_rec.address_line3                 := vr_site_rowtype.address_line3;
                        vr_vendor_site_rec.address_line4                 := vr_site_rowtype.address_line4;
                        vr_vendor_site_rec.address_lines_alt             := vr_site_rowtype.address_lines_alt;
                        vr_vendor_site_rec.county                        := vr_site_rowtype.county;
                        vr_vendor_site_rec.city                          := vr_site_rowtype.city;
                        vr_vendor_site_rec.state                         := vr_site_rowtype.state;
                        vr_vendor_site_rec.zip                           := vr_site_rowtype.zip;
                        vr_vendor_site_rec.terms_name                    := NULL; --AP_TERMS_TL.NAME;
                        vr_vendor_site_rec.default_terms_id              := NULL;
                        vr_vendor_site_rec.awt_group_name                := NULL; --AP_AWT_GROUPS.NAME;
                        vr_vendor_site_rec.pay_awt_group_name            := NULL; --AP_AWT_GROUPS.NAME;
                        vr_vendor_site_rec.distribution_set_name         := NULL;
                        vr_vendor_site_rec.default_dist_set_id           := NULL;
                        vr_vendor_site_rec.tolerance_id                  := vr_site_rowtype.tolerance_id;
                        vr_vendor_site_rec.vendor_interface_id           := NULL;
                        vr_vendor_site_rec.vendor_site_interface_id      := NULL;
                        vr_vendor_site_rec.retainage_rate                := vr_site_rowtype.retainage_rate;
                        vr_vendor_site_rec.services_tolerance_id         := vr_site_rowtype.services_tolerance_id;
                        vr_vendor_site_rec.shipping_location_id          := NULL;
                        vr_vendor_site_rec.vat_code                      := vr_site_rowtype.vat_code;
                        vr_vendor_site_rec.vat_registration_num          := vr_site_rowtype.vat_registration_num;
                        vr_vendor_site_rec.remittance_email              := vr_site_rowtype.remittance_email;
                        vr_vendor_site_rec.edi_id_number                 := vr_site_rowtype.edi_id_number;
                        vr_vendor_site_rec.edi_payment_format            := vr_site_rowtype.edi_payment_format;
                        vr_vendor_site_rec.edi_transaction_handling      := vr_site_rowtype.edi_transaction_handling;
                        vr_vendor_site_rec.edi_payment_method            := vr_site_rowtype.edi_payment_method;
                        vr_vendor_site_rec.edi_remittance_method         := vr_site_rowtype.edi_remittance_method;
                        vr_vendor_site_rec.edi_remittance_instruction    := vr_site_rowtype.edi_remittance_instruction;
                        vr_vendor_site_rec.offset_tax_flag               := vr_site_rowtype.offset_tax_flag;
                        vr_vendor_site_rec.auto_tax_calc_flag            := vr_site_rowtype.auto_tax_calc_flag;
                        vr_vendor_site_rec.cage_code                     := vr_site_rowtype.cage_code;
                        vr_vendor_site_rec.legal_business_name           := vr_site_rowtype.legal_business_name;
                        vr_vendor_site_rec.doing_bus_as_name             := vr_site_rowtype.doing_bus_as_name;
                        vr_vendor_site_rec.division_name                 := vr_site_rowtype.division_name;
                        vr_vendor_site_rec.small_business_code           := vr_site_rowtype.small_business_code;
                        vr_vendor_site_rec.ccr_comments                  := vr_site_rowtype.ccr_comments;
                        vr_vendor_site_rec.debarment_start_date          := vr_site_rowtype.debarment_start_date;
                        vr_vendor_site_rec.debarment_end_date            := vr_site_rowtype.debarment_end_date;
                        vr_vendor_site_rec.ap_tax_rounding_rule          := vr_site_rowtype.ap_tax_rounding_rule;
                        vr_vendor_site_rec.amount_includes_tax_flag      := vr_site_rowtype.amount_includes_tax_flag;

                        ap_vendor_pub_pkg.create_vendor_site(vn_api_version,
                               vv_init_msg_list,
                               vv_commit,
                               vn_validation_level,
                               vv_return_status,
                               vn_msg_count,
                               vv_msg_data,
                               vr_vendor_site_rec,
                               vn_vendor_site_id,
                               vn_party_site_id,
                               vn_location_id);

                        COMMIT;
                        IF
                            ( vv_return_status <> fnd_api.g_ret_sts_success )
                        THEN
                            FOR i IN 1..fnd_msg_pub.count_msg LOOP
                                vv_message := substr(fnd_msg_pub.get(p_msg_index => i,p_encoded => fnd_api.g_false),1,500);
                                vv_status_dup := 'E';
                                BEGIN
                                    INSERT INTO dka_sapfrsdupli_error_tmp VALUES (
                                        v_action_id,
                                        pv_id_site_fournisseur,
                                        7,
                                        'ERREUR',
                                        substr('Une erreur est survenue lors de la duplication du site sur l''UO '
                                        || lt_uo(k).name ||' - '||vv_message,1,500),
                                        SYSDATE,
                                        g_user
                                    );

                                END;


                            END LOOP;
                        ELSE
                            vv_status_dup := 'S';
                            vv_message := 'la duplication du site est terminée avec succès';
                            writelog(vv_message,0,0);

                            BEGIN
                               SELECT payee_party_id ,ext_payee_id
                               INTO vv_payee_party_id ,vv_ext_payee_id
                               FROM IBY_EXTERNAL_PAYEES_ALL
                               WHERE 1=1
                               AND SUPPLIER_SITE_ID  = vn_vendor_site_id
                               AND ORG_ID = lt_uo(k).organization_id
                            ;
                            EXCEPTION
                            WHEN OTHERS THEN
                                NULL;
                            END;

                            -- --Appel a l'API iby_disbursement_setup_pub.CREATE_external_payee
                            p_ext_payee_tab(i).default_pmt_method           := v_payment_method_code;
                            p_ext_payee_tab(i).delivery_channel             := vr_compte_rowtype.delivery_channel_code;
                            p_ext_payee_tab(i).bank_instr1_code             := vr_compte_rowtype.bank_instruction1_code;
                            p_ext_payee_tab(i).bank_instr2_code             := vr_compte_rowtype.bank_instruction2_code;
                            p_ext_payee_tab(i).bank_instr_detail            := vr_compte_rowtype.bank_instruction_details;
                            p_ext_payee_tab(i).settlement_priority          := vr_compte_rowtype.settlement_priority;
                            p_ext_payee_tab(i).pay_message1                 := vr_compte_rowtype.payment_text_message1;
                            p_ext_payee_tab(i).pay_message2                 := vr_compte_rowtype.payment_text_message2;
                            p_ext_payee_tab(i).pay_message3                 := vr_compte_rowtype.payment_text_message3;
                            p_ext_payee_tab(i).exclusive_pay_flag           := vr_compte_rowtype.exclusive_payment_flag;
                            p_ext_payee_tab(i).bank_charge_bearer           := vr_compte_rowtype.bank_charge_bearer;
                            p_ext_payee_tab(i).pay_reason_code              := vr_compte_rowtype.payment_reason_code;
                            p_ext_payee_tab(i).pay_reason_com               := vr_compte_rowtype.payment_reason_comments;
                            p_ext_payee_tab(i).pmt_format                   := vr_compte_rowtype.payment_format_code;
                            p_ext_payee_tab(i).remit_advice_delivery_method := vr_compte_rowtype.remit_advice_delivery_method;
                            p_ext_payee_tab(i).remit_advice_email           := vr_compte_rowtype.remit_advice_email;
                            p_ext_payee_tab(i).remit_advice_fax             := vr_compte_rowtype.remit_advice_fax;
                            p_ext_payee_tab (i).payee_party_id              := vv_payee_party_id;
                            p_ext_payee_tab(i).Payee_party_site_id          := vn_party_site_id;    
                            p_ext_payee_tab(i).Supplier_Site_id             := vn_vendor_site_id;   
                            p_ext_payee_tab(i).Payer_Org_Type               := 'OPERATING_UNIT';
                            p_ext_payee_tab(i).Payer_Org_id                 := lt_uo(k).organization_id;
                            p_ext_payee_tab (i).payment_function            := 'PAYABLES_DISB';
                            p_ext_payee_id_tab(i).ext_payee_id              := vv_ext_payee_id;


                            IBY_DISBURSEMENT_SETUP_PUB.update_external_payee ( 
                                                                   p_api_version            => 1.0,
                                                                   p_init_msg_list          => 'T',
                                                                   p_ext_payee_tab          => p_ext_payee_tab,
                                                                   p_ext_payee_id_tab       => p_ext_payee_id_tab,
                                                                   x_return_status          => x_return_status,
                                                                   x_msg_count              => x_msg_count,
                                                                   x_msg_data               => x_msg_data,
                                                                   x_ext_payee_status_tab   => l_payee_upd_status
                                                                  );


                            IF x_return_status = 'E'
                            THEN
                                   FOR k IN l_payee_upd_status.FIRST .. l_payee_upd_status.LAST
                                   LOOP
                                       vv_status_reg := 'E' ;
                                       INSERT INTO DKA_SAPFRSDUPLI_ERROR_TMP
                                       values
                                         ( v_action_id,
                                           pv_id_site_fournisseur,
                                           8,
                                          'ERREUR',
                                          'Une erreur est survenue lors de la mise à jour des informations de règlement'||' '|| l_payee_upd_status (k).Payee_update_Msg,
                                           sysdate,
                                           g_user) ;
                                   END LOOP;
                                   --RAISE e_reglement_error;
                            ELSE
                                  vv_status_reg := 'S';
                                  fnd_file.put_line(fnd_file.LOG,'la création des informations de réglement est terminée avec succès');

                            END IF;   

                            FOR rec_c_banc_ref IN cur_c_banc_ref 
                            LOOP
                                -- Attachement du compte bancaire API de création

                                vn_api_version := 1.0;
                                vv_init_msg_list := fnd_api.g_true;
                                vv_commit := fnd_api.g_false;
                                vn_validation_level := fnd_api.g_valid_level_full;
                                vv_return_status := NULL;
                                vn_msg_count := NULL;
                                vv_msg_data := NULL;
                                vr_payee_context_rec.payment_function := 'PAYABLES_DISB';
                                vr_payee_context_rec.party_site_id := vn_party_site_id;
                                vr_payee_context_rec.party_id := rec_c_banc_ref.party_id;
                                vr_payee_context_rec.supplier_site_id := vn_vendor_site_id;
                                vr_payee_context_rec.org_type := 'OPERATING_UNIT';
                                vr_payee_context_rec.org_id := lt_uo(k).organization_id;
                                vr_assignment_attribs.instrument.instrument_type := 'BANKACCOUNT';
                                vr_assignment_attribs.instrument.instrument_id := rec_c_banc_ref.ext_bank_account_id;
                                vr_assignment_attribs.start_date := rec_c_banc_ref.start_date;
                                vr_assignment_attribs.end_date := rec_c_banc_ref.end_date;
                                -- vr_assignment_attribs.priority := 1;
                                vr_assignment_attribs.priority   := rec_c_banc_ref.ORDER_OF_PREFERENCE;

                                -- account to site supplier
                                iby_disbursement_setup_pub.set_payee_instr_assignment(
                                           p_api_version => vn_api_version,
                                           p_init_msg_list => 	vv_init_msg_list,
                                           p_commit => vv_commit,
                                           x_return_status => vv_return_status,
                                           x_msg_count => vn_msg_count,
                                           x_msg_data => vv_msg_data,
                                           p_payee => vr_payee_context_rec,
                                           p_assignment_attribs=> vr_assignment_attribs,
                                           x_assign_id => vn_assign_id,
                                           x_response => vr_response);


                                IF
                                      ( vv_return_status <> fnd_api.g_ret_sts_success )
                                THEN
                                    FOR i IN 1..fnd_msg_pub.count_msg 
                                    LOOP
                                         vv_message := substr(fnd_msg_pub.get(p_msg_index => i,p_encoded => fnd_api.g_false),1,500);

                                       BEGIN
                                           INSERT INTO dka_sapfrsdupli_error_tmp VALUES (
                                               v_action_id,
                                               pv_id_site_fournisseur,
                                               9,
                                              'ERREUR',
                                              substr('Le compte bancaire '
                                              || vv_bank_account
                                              || ' n''a pas pu être rattaché au site fournisseur de l''UO  '
                                              || lt_uo(k).name||' - '||vv_message,1,500),
                                               SYSDATE,
                                               g_user
                                              );
                                          vv_status_ratt:= 'E';
                                       END;
                                    END LOOP;


                                ELSE
                                   vv_status_ratt:= 'S';
                                   vv_message := 'le rattachement du site est terminé avec succès';
                                   writelog(vv_message,0,0);
                                END IF;

                            END LOOP;	
                        END IF;
                      

                      IF vv_status_dup = 'S' and vv_status_ratt ='S' and  vv_status_reg ='S' 
                      THEN
                           vn_site_ok := vn_site_ok + 1;
                      ELSE 
                           vn_site_ko := vn_site_ko + 1;
                      END IF;
                      
                      vv_status_dup   := NULL;
                      vv_status_ratt	:= NULL;
                      vv_status_reg	  := NULL;
                      END IF; -- fin test frs goupe
                    ELSE
                        BEGIN
                            vn_cpt_existe := vn_cpt_existe + 1;

                            INSERT INTO dka_sapfrsdupli_error_tmp VALUES (
                                v_action_id,
                                pv_id_site_fournisseur,
                                10,
                                'AVERTISSEMENT',
                                'Le site a déjà été dupliqué sur cette unité opérationnelle : '
                                || lt_uo(k).name,
                                SYSDATE,
                                g_user
                            );

                        END;
                    END IF;

                 ELSE
                     vv_message :='UO ' ||lt_uo(k).name||' n''est pas active ';
                     writelog(vv_message,0,0);

                 END IF;
                  << Fin >> --AAM
                  writelog('Passer à la UO suivante',0,0);
               END LOOP;


            ELSE
                vv_message :='Le périmètre de duplication est manquant ou erroné';
                INSERT INTO dka_sapfrsdupli_error_tmp VALUES (
                    v_action_id,
                    pv_id_site_fournisseur,
                    11,
                    'ERREUR',
                    vv_message,
                    SYSDATE,
                    g_user
                    );
                vn_site_ko  := 1;
                writelog(vv_message,0,0);
            END IF;
        END LOOP;
    ELSE
        BEGIN
            INSERT INTO dka_sapfrsdupli_error_tmp VALUES (
                v_action_id,
                pv_id_site_fournisseur,
                12,
                'ERREUR',
                'Le site fournisseur n''est pas actif : '
                || pv_id_site_fournisseur,
                SYSDATE,
                g_user
            );

        END;
    END IF;

	--<< Fin >> AAM
    COMMIT;

    pv_nombre_echoues := vn_site_ko;
    pv_nombre_succes  := vn_site_ok;
    pv_nombre_existe  := vn_cpt_existe;
    pv_nombre_ignores := vn_site_ignores;


    IF pv_nombre_echoues = 0 and pv_nombre_existe = 0 
    THEN 
        pn_resultat_duplication := 'OK';

    ELSE 
        pn_resultat_duplication := 'KO';
    END IF ; 

    pv_id_liste_erreur := v_action_id;
    pv_id_site_cree    := vn_vendor_site_id;


END;--- procédure duplication
  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : COMPARE_VALUE
  --  Description   : Mise à jour des sites fournisseurs .
  --
  --  PARAMETRES    : 
  --                  p_vendor_id_ref  Entrée  Identifiant du site fournisseur de référence
  --                  p_vendor_id_dup  Entrée  Identifiant du site fournisseur dupliqué

  -- Auteur         : Asma AMENKOUR
  -- Date           : 24/07/2020
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
PROCEDURE COMPARE_VALUE(p_vendor_id_ref IN NUMBER,
                        p_vendor_id_dup IN NUMBER) IS
v_concat_value_ref  VARCHAR2(5000);
v_concat_value_dup  VARCHAR2(5000);
vr_site_rowtype     ap_supplier_sites_all%ROWTYPE;
BEGIN
SELECT  
              address_line2                 
              ||address_line3                 
              ||address_line4                 
              ||county                        
              ||city                          
              ||state                         
              ||province                      
              ||address_lines_alt             
              ||zip                              
              ||attribute1                    
              ||attribute4                    
              ||attribute6                    
              ||attribute7                    
              ||supplier_notif_method         
              ||LANGUAGE                      
              ||area_code                     
              ||phone                         
              ||fax                           
              ||fax_area_code                 
              ||telex                         
              ||email_address                 
              ||edi_id_number                 
              ||ece_tp_location_code          
              ||customer_num                  
              ||vendor_site_code_alt                     
              ||vat_registration_num          
              ||ap_tax_rounding_rule          
              ||vat_code                      
              ||ship_to_location_id           
              ||ship_via_lookup_code          
              ||pay_on_code                   
              ||pay_on_receipt_summary_code           
              ||selling_company_identifier    
              ||fob_lookup_code               
              ||freight_terms_lookup_code     
              ||shipping_control              
              ||country_of_origin_code        
              ||invoice_amount_limit          
              ||tolerance_id                  
              ||match_option                      
              ||hold_reason                   
              ||pay_group_lookup_code         
              ||terms_date_basis              
              ||payment_priority              
              ||bank_charge_bearer            
              ||terms_id                      
              ||pay_date_basis_lookup_code    
              ||retainage_rate                
              ||exclude_freight_from_discount 
INTO  v_concat_value_ref
FROM ap_supplier_sites_all 
WHERE   vendor_site_id = p_vendor_id_ref;   

SELECT  
                address_line2                 
              ||address_line3                 
              ||address_line4                 
              ||county                        
              ||city                          
              ||state                         
              ||province                      
              ||address_lines_alt             
              ||zip                              
              ||attribute1                    
              ||attribute4                    
              ||attribute6                    
              ||attribute7                    
              ||supplier_notif_method         
              ||LANGUAGE                      
              ||area_code                     
              ||phone                         
              ||fax                           
              ||fax_area_code                 
              ||telex                         
              ||email_address                 
              ||edi_id_number                 
              ||ece_tp_location_code          
              ||customer_num                  
              ||vendor_site_code_alt                     
              ||vat_registration_num          
              ||ap_tax_rounding_rule          
              ||vat_code                      
              ||ship_to_location_id           
              ||ship_via_lookup_code          
              ||pay_on_code                   
              ||pay_on_receipt_summary_code           
              ||selling_company_identifier    
              ||fob_lookup_code               
              ||freight_terms_lookup_code     
              ||shipping_control              
              ||country_of_origin_code        
              ||invoice_amount_limit          
              ||tolerance_id                  
              ||match_option                      
              ||hold_reason                   
              ||pay_group_lookup_code         
              ||terms_date_basis              
              ||payment_priority              
              ||bank_charge_bearer            
              ||terms_id                      
              ||pay_date_basis_lookup_code    
              ||retainage_rate                
              ||exclude_freight_from_discount 
INTO  v_concat_value_dup
FROM ap_supplier_sites_all 
WHERE   vendor_site_id = p_vendor_id_dup;   

IF v_concat_value_ref != v_concat_value_dup THEN
  SELECT *
  INTO  vr_site_rowtype            
  FROM  ap_supplier_sites_all
  WHERE vendor_site_id = p_vendor_id_ref;  
  UPDATE ap_supplier_sites_all
  SET address_line2                  = vr_site_rowtype.address_line2                   ,
      address_line3                 = vr_site_rowtype.address_line3                     ,
      address_line4                 = vr_site_rowtype.address_line4                     ,
      county                        = vr_site_rowtype.county                            ,
      city                          = vr_site_rowtype.city                              ,
      state                         = vr_site_rowtype.state                             ,
      province                      = vr_site_rowtype.province                          ,
      address_lines_alt             = vr_site_rowtype.address_lines_alt                 ,
      zip                           = vr_site_rowtype.zip                               ,
      attribute1                    = vr_site_rowtype.attribute1                        ,
      attribute4                    = vr_site_rowtype.attribute4                        ,
      attribute6                    = vr_site_rowtype.attribute6                        ,
      attribute7                    = vr_site_rowtype.attribute7                        ,
      supplier_notif_method         = vr_site_rowtype.supplier_notif_method             ,
      LANGUAGE                      = vr_site_rowtype.LANGUAGE                          ,
      area_code                     = vr_site_rowtype.area_code                         ,
      phone                         = vr_site_rowtype.phone                             ,
      fax                           = vr_site_rowtype.fax                               ,
      fax_area_code                 = vr_site_rowtype.fax_area_code                     ,
      telex                         = vr_site_rowtype.telex                             ,
      email_address                 = vr_site_rowtype.email_address                     ,
      edi_id_number                 = vr_site_rowtype.edi_id_number                     ,
      ece_tp_location_code          = vr_site_rowtype.ece_tp_location_code              ,
      customer_num                  = vr_site_rowtype.customer_num                      ,
      vendor_site_code_alt          = vr_site_rowtype.vendor_site_code_alt              ,
      vat_registration_num          = vr_site_rowtype.vat_registration_num              ,
      ap_tax_rounding_rule          = vr_site_rowtype.ap_tax_rounding_rule              ,
      vat_code                      = vr_site_rowtype.vat_code                          ,
      ship_to_location_id           = vr_site_rowtype.ship_to_location_id               ,
      ship_via_lookup_code          = vr_site_rowtype.ship_via_lookup_code              ,
      pay_on_code                   = vr_site_rowtype.pay_on_code                       ,
      pay_on_receipt_summary_code   = vr_site_rowtype.pay_on_receipt_summary_code       ,
      selling_company_identifier    = vr_site_rowtype.selling_company_identifier        ,
      fob_lookup_code               = vr_site_rowtype.fob_lookup_code                   ,
      freight_terms_lookup_code     = vr_site_rowtype.freight_terms_lookup_code         ,
      shipping_control              = vr_site_rowtype.shipping_control                  ,
      country_of_origin_code        = vr_site_rowtype.country_of_origin_code            ,
      invoice_amount_limit          = vr_site_rowtype.invoice_amount_limit              ,
      tolerance_id                  = vr_site_rowtype.tolerance_id                      ,
      match_option                  = vr_site_rowtype.match_option                      ,
      hold_reason                   = vr_site_rowtype.hold_reason                       ,
      pay_group_lookup_code         = vr_site_rowtype.pay_group_lookup_code             ,
      terms_date_basis              = vr_site_rowtype.terms_date_basis                  ,
      payment_priority              = vr_site_rowtype.payment_priority                  ,
      bank_charge_bearer            = vr_site_rowtype.bank_charge_bearer                ,
      terms_id                      = vr_site_rowtype.terms_id                          ,
      pay_date_basis_lookup_code    = vr_site_rowtype.pay_date_basis_lookup_code        ,
      retainage_rate                = vr_site_rowtype.retainage_rate                    ,
      exclude_freight_from_discount = vr_site_rowtype.exclude_freight_from_discount     
  WHERE   vendor_site_id = p_vendor_id_dup; 
END IF;   
END COMPARE_VALUE;          
  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : MAJ_SITE_FOURNISSEUR
  --  Description   : Mise à jour des sites fournisseurs .
  --
  --  PARAMETRES    : vv_errbuf           Entrée/Sortie    message d'erreur
  --                  vn_retcode          Sortie           code de retour: '0=normal', '1=warning', '2=erreur'
  --                  p_id_site_frns_ref  Entrée  Identifiant du site fournisseur de référence

  -- Auteur         : Asma AMENKOUR
  -- Date           : 23/12/2019
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE MAJ_SITE_FOURNISSEUR ( p_id_site_frns_ref    IN  NUMBER,
                                   p_result_maj          OUT VARCHAR2,
                                   p_nbr_maj_succes      OUT NUMBER,
                                   p_nbr_maj_echec       OUT NUMBER,
                                   p_maj_code_echec      OUT NUMBER,
                                   p_id_liste_erreur     OUT NUMBER
                              	 ) 
  IS
   l_procedure                VARCHAR2(30) := 	'MAJ_SITE_FOURNISSEUR';
   v_location_id              ap_supplier_sites_all.location_id%type;
   vd_vendor_site_id          ap_supplier_sites_all.vendor_site_id%type;
   vr_site_rowtype            ap_supplier_sites_all%ROWTYPE;
   vr_iby_rowtype             IBY_EXTERNAL_PAYEES_ALL%ROWTYPE;
   vn_cpt_site                VARCHAR2(2);
   vn_maj_code_echec          NUMBER := 0;
   vn_cpt_bank                VARCHAR2(2):= 'S';
   vn_cpt_reg                 VARCHAR2(2);
   vn_cpt_site_ok             NUMBER := 0;
   vn_cpt_site_ko             NUMBER := 0;
   vn_statut                  VARCHAR2(2);
   vv_message                 VARCHAR2(500);
   vr_vendor_site_rec         ap_vendor_pub_pkg.r_vendor_site_rec_type;
   l_payee_upd_status         iby_disbursement_setup_pub.ext_payee_update_tab_type;
   p_ext_payee_tab            iby_disbursement_setup_pub.external_payee_tab_type;
   p_ext_payee_id_tab         iby_disbursement_setup_pub.Ext_Payee_ID_Tab_Type;
   p_api_version              NUMBER;
   vv_init_msg_list           VARCHAR2(200);
   vv_commit                  VARCHAR2(200);
   vn_validation_level        NUMBER;
   x_return_status            VARCHAR2(200);
   x_msg_count                NUMBER;
   x_msg_data                 VARCHAR2(2000);
   vv_nbr_siteActif_uo        NUMBER;
   vv_nbr_site_uo             NUMBER;
   v_date_active              ap_supplier_sites_all.inactive_date%type;
   vv_ext_payee_id            IBY_EXTERNAL_PAYEES_ALL.ext_payee_id%type;
   vv_payee_party_id          IBY_EXTERNAL_PAYEES_ALL.payee_party_id%type;
   vv_account_id              iby_ext_bank_accounts.ext_bank_account_id%type;
   vv_start_date              iby_pmt_instr_uses_all.start_date%type;
   vv_end_date                iby_pmt_instr_uses_all.end_date%type;
   vv_account_id_ref          iby_ext_bank_accounts.ext_bank_account_id%type;
   vv_iban_ref                iby_ext_bank_accounts.iban%type;
   vv_start_date_ref          iby_pmt_instr_uses_all.start_date%type;
   vv_end_date_ref            iby_pmt_instr_uses_all.end_date%type;
   vr_response                iby_fndcpt_common_pub.result_rec_type;
   vv_country_code            iby_ext_bank_accounts.country_code%type;
   vv_branch_id               iby_ext_bank_accounts.branch_id%type;
   vv_bank_id                 iby_ext_bank_accounts.bank_id%type;
   vv_bank_account_name       iby_ext_bank_accounts.bank_account_name%type;
   vv_bank_account_num        iby_ext_bank_accounts.bank_account_num%type;
   vv_currecy_code            iby_ext_bank_accounts.currency_code%type;
   l_extbank_rec IBY_EXT_BANKACCT_PUB.ExtBankAcct_rec_type;
   vv_msg VARCHAR2 (4000);
   vv_msg_index_out NUMBER;

   vn_segment1      gl_code_combinations.segment1%TYPE;
   vn_segment2      gl_code_combinations.segment2%TYPE;
   vn_segment3      gl_code_combinations.segment3%TYPE;
   vn_segment4      gl_code_combinations.segment4%TYPE;
   vn_segment5      gl_code_combinations.segment5%TYPE;
   vn_segment6      gl_code_combinations.segment6%TYPE;
   vn_segment7      gl_code_combinations.segment7%TYPE;
   vn_segment8      gl_code_combinations.segment8%TYPE;
   vn_segment9      gl_code_combinations.segment9%TYPE;
   vn_segment10     gl_code_combinations.segment10%TYPE;
   vn_segment11     gl_code_combinations.segment11%TYPE;
   vn_segment12     gl_code_combinations.segment12%TYPE;

   vn_PREPAY_CCID       gl_code_combinations.code_combination_id%TYPE;
   vn_ACCTS_PAY_CCID    gl_code_combinations.code_combination_id%TYPE;
   vn_future_CCID       gl_code_combinations.code_combination_id%TYPE;

   vn_assign_id          NUMBER ;
   vr_payee_context_rec  IBY_DISBURSEMENT_SETUP_PUB.PayeeContext_rec_type;
   vr_assignment_attribs IBY_FNDCPT_SETUP_PUB.PmtInstrAssignment_rec_type;
   v_etape               varchar2(500);
   v_action_id           NUMBER;
   v_bank_exist          NUMBER;
   vv_errbuf             VARCHAR2(500);
   vn_retcode            PLS_INTEGER  := 0;
   v_meme_code_ref       NUMBER;

   v_payment_method_code  IBY_EXT_PARTY_PMT_MTHDS.payment_method_code%TYPE;
   v_count               NUMBER;

    i NUMBER := 0;

    Erreur_site EXCEPTION;

   --Liste des UO de duplication
   CURSOR c_uo_dupliques(p_location_id NUMBER)
   IS
     SELECT  distinct hou.name uo
           ,hou.organization_id
     FROM
           ap_supplier_sites_all ass
          ,hr_operating_units hou
    WHERE   ass.org_id      = hou.organization_id
    AND     ass.location_id = p_location_id   
    AND     hou.name != 'REF9999'
    ;

   --Liste des sites dupliqués depuis le site fournisseur de référence (en paramètre)
   CURSOR c_frns_dupliques( p_location_id NUMBER
                           ,p_organization_id NUMBER)
   IS
     SELECT ass.VENDOR_SITE_ID
           ,hou.name
           ,ass.INACTIVE_DATE
           ,ass.VENDOR_SITE_CODE
           ,ass.party_site_id
           ,asa.party_id
		   ,ass.ship_to_location_id
     FROM
           ap_supplier_sites_all ass
          ,ap_suppliers asa
          ,hr_operating_units hou
    WHERE   ass.org_id          = hou.organization_id
    AND     ass.vendor_id       = asa.vendor_id
  --AND     ass.INACTIVE_DATE is null
    AND     ass.location_id     = p_location_id
    AND     hou.organization_id = p_organization_id
   ;

   CURSOR c_cpt_bank_ref 
   IS
     --Info bancaires du site de réference
     SELECT ieb.ext_bank_account_id
           ,ieb.iban
           ,IEB.BANK_ACCOUNT_NAME
           ,IPI.start_date
         --,nvl(IPI.end_date,SYSDATE + 1) end_date
           ,IPI.end_date --end_date_relle
           ,IPI.ORDER_OF_PREFERENCE
     FROM iby_ext_bank_accounts ieb
         ,iby_pmt_instr_uses_all ipi
         ,iby_external_payees_all iep
     WHERE iep.supplier_site_id = p_id_site_frns_ref
      AND   iep.ext_payee_id = ipi.ext_pmt_party_id
      AND   ipi.instrument_id = ieb.ext_bank_account_id
      --AND   nvl(IPI.start_date,SYSDATE) <= SYSDATE
      --AND   nvl(IPI.end_date,SYSDATE) >= SYSDATE
      AND   ipi.payment_function = 'PAYABLES_DISB'
      --AND   iep.org_id = p_org_id
      --AND   ipi.order_of_preference = 1
    ;

  BEGIN
    v_etape := l_procedure||' 01 : Debut' ;

    SELECT ACTION_ID_S.nextval
    INTO   v_action_id
    FROM   DUAL;

    ---Détermination des informations à changées
    BEGIN
       SELECT *
       INTO vr_site_rowtype
       FROM
            ap_supplier_sites_all ass
       WHERE   ass.vendor_site_id = p_id_site_frns_ref
        ;
    EXCEPTION
    WHEN OTHERS THEN
            vv_message := 'Site de la référence introuvable id '||p_id_site_frns_ref;
            INSERT INTO DKA_SAPFRSDUPLI_ERROR_TMP
            values
             ( v_action_id,
              p_id_site_frns_ref,
              1,
             'ERREUR',
             vv_message,
             sysdate,
             g_user) ;
    END;

        ---info gestion de réglement----------
    BEGIN   

        SELECT *
        INTO vr_iby_rowtype
        FROM IBY_EXTERNAL_PAYEES_ALL  iepa
        WHERE 1=1
        AND   iepa.SUPPLIER_SITE_ID = p_id_site_frns_ref
        AND   iepa.org_id = vr_site_rowtype.org_id;
    EXCEPTION
    WHEN OTHERS THEN
            vv_message := 'Info règlement introuvable pour site id '||p_id_site_frns_ref;
            INSERT INTO DKA_SAPFRSDUPLI_ERROR_TMP
            values
             ( v_action_id,
              p_id_site_frns_ref,
              1,
             'ERREUR',
             vv_message,
             sysdate,
             g_user) ;
    END;

    BEGIN
        SELECT ieppm.payment_method_code  
        INTO   v_payment_method_code
        FROM IBY_EXT_PARTY_PMT_MTHDS ieppm
           , IBY_EXTERNAL_PAYEES_ALL iepa
        WHERE iepa.ext_payee_id = ieppm.ext_pmt_party_id
        AND ieppm.payment_function = 'PAYABLES_DISB'
        AND ieppm.primary_flag = 'Y'
        AND iepa.supplier_site_id = p_id_site_frns_ref;
    EXCEPTION
    WHEN OTHERS THEN
             v_payment_method_code := NULL;
    END;


 /*	--Info bancaires du site de réference
    BEGIN
        SELECT
             ieb.ext_bank_account_id,
             ieb.iban,
             IPI.start_date,
             IPI.end_date

        INTO
             vv_account_id_ref,
             vv_iban_ref,
             vv_start_date_ref,
             vv_end_date_ref

        FROM
             iby_ext_bank_accounts ieb,
             iby_pmt_instr_uses_all ipi,
             iby_external_payees_all iep
        WHERE 1 = 1
        AND   iep.supplier_site_id = p_id_site_frns_ref
        AND   iep.ext_payee_id = ipi.ext_pmt_party_id
        AND   ipi.instrument_id = ieb.ext_bank_account_id
        AND   nvl(ieb.start_date,SYSDATE) <= SYSDATE
        AND   nvl(ieb.end_date,SYSDATE) >= SYSDATE
        AND   ipi.payment_function = 'PAYABLES_DISB'
        AND   ipi.order_of_preference = 1;*/

    FOR rec_uo_dupliques IN c_uo_dupliques (vr_site_rowtype.location_id) 
    LOOP
        v_etape := ' 02 : entrée de la boucle des UO';
      /*DBMS_OUTPUT.PUT_LINE(v_etape);
      DBMS_OUTPUT.PUT_LINE('org_id :'||rec_uo_dupliques.organization_id);
      DBMS_OUTPUT.PUT_LINE('UO :'||rec_uo_dupliques.uo);*/
        BEGIN
           SELECT count(1)
           INTO vv_nbr_siteActif_uo
           FROM
               ap_supplier_sites_all ass
              ,hr_operating_units hou
           WHERE   ass.org_id          = hou.organization_id
           AND     ass.INACTIVE_DATE is null
           AND     ass.location_id     = vr_site_rowtype.location_id
           AND     hou.organization_id = rec_uo_dupliques.organization_id;
        EXCEPTION 
        WHEN OTHERS THEN
            vv_nbr_siteActif_uo := 0;  
        END;
        BEGIN
           SELECT count(1)
           INTO vv_nbr_site_uo
           FROM
               ap_supplier_sites_all ass
              ,hr_operating_units hou
           WHERE   ass.org_id          = hou.organization_id
           AND     ass.location_id     = vr_site_rowtype.location_id
           AND     hou.organization_id = rec_uo_dupliques.organization_id;
        EXCEPTION 
        WHEN OTHERS THEN
            vv_nbr_site_uo := 0;  
        END;
		---SHA Contrôle de l'unicité
        BEGIN
          
		    SELECT count(1)
               INTO  vd_vendor_site_id
               FROM  ap_supplier_sites_all assa,
                     hr_operating_units hou
               WHERE assa.location_id      = vr_site_rowtype.location_id
               AND   assa.org_id           = hou.organization_id
               AND   hou.name              = 'REF9999'
               ;
        EXCEPTION 
        WHEN OTHERS THEN
            vd_vendor_site_id := 0;  
        END;
		--fin SHA 
        v_etape := ' 03 : Contrôle sur le nombre des sites actifs';
        --IF vv_nbr_siteActif_uo >= 1 THEN
        FOR rec_frns_duplique IN c_frns_dupliques(vr_site_rowtype.location_id,rec_uo_dupliques.organization_id) 
        LOOP
            --  vn_maj_code_echec := 0;
            v_etape := ' 04 : entrée de la boucle des sites fournisseurs dupliqués';
            writelog('Début Mise à jour site id '||rec_frns_duplique.VENDOR_SITE_ID,0,0);
        IF vd_vendor_site_id > 1 
		    THEN 
		          vn_cpt_site_ko := vn_cpt_site_ko + 1;
		          vv_message :='Mise à jour impossible car le site fournisseur n''est pas unique pour cette adresse sur la référence.';
                  vn_maj_code_echec := 1;	
                  --DBMS_OUTPUT.put_line(vv_message);

                  INSERT INTO DKA_SAPFRSDUPLI_ERROR_TMP
                  values
                  (v_action_id,
                   rec_frns_duplique.VENDOR_SITE_ID,
                   1,
                   'ERREUR',
                   vv_message,
                   sysdate,
                   g_user) ;
		ELSE 
		
            -- Si le code du site fournisseur est différent de celui de la référence
          IF rec_frns_duplique.vendor_site_code != vr_site_rowtype.vendor_site_code --and  vv_nbr_siteActif_uo > 1           
          THEN
          --DBMS_OUTPUT.put_line('vendor_site_code différents');
          --DBMS_OUTPUT.put_line('rec_frns_duplique.vendor_site_code: '||rec_frns_duplique.vendor_site_code);
          --DBMS_OUTPUT.put_line('vr_site_rowtype.vendor_site_code : '||vr_site_rowtype.vendor_site_code);
            IF vv_nbr_site_uo = 1 THEN
              --DBMS_OUTPUT.put_line('un seul frns dupliqué');
              vr_vendor_site_rec.vendor_site_code := vr_site_rowtype.vendor_site_code;
            ELSE
            --DBMS_OUTPUT.put_line('plusieurs site dupliqués');
              IF rec_frns_duplique.INACTIVE_DATE is null                 
              THEN
                --DBMS_OUTPUT.put_line('site activé');
                IF vv_nbr_siteActif_uo > 1 
                THEN
                  --DBMS_OUTPUT.put_line('existe plusieurs sites actifs sur cette UO');
                  vr_vendor_site_rec.vendor_site_code              := rec_frns_duplique.vendor_site_code;
                  vv_message :='Le code du site fournisseur n''a pas été mis à jour car il y a plusieurs sites fournisseurs actifs sur cette UO';
                  vn_maj_code_echec := 1;	
                  --DBMS_OUTPUT.put_line(vv_message);

                  INSERT INTO DKA_SAPFRSDUPLI_ERROR_TMP
                  values
                  (v_action_id,
                   rec_frns_duplique.VENDOR_SITE_ID,
                   1,
                   'ERREUR',
                   vv_message,
                   sysdate,
                   g_user) ;
                ELSE 
                  --DBMS_OUTPUT.put_line('il existe un seul site actif sur cetteUO');
                  BEGIN
                    SELECT count(*)
                    INTO   v_meme_code_ref          
                    FROM ap_supplier_sites_all assa
                    ,    hr_operating_units hou
                    WHERE  vendor_site_code    = vr_site_rowtype.vendor_site_code
                    AND    assa.org_id          = hou.organization_id
                    AND    hou.organization_id = rec_uo_dupliques.organization_id;
                  EXCEPTION
                    WHEN OTHERS THEN 
                      v_meme_code_ref := 0;
                  END; 
                  IF v_meme_code_ref != 0 THEN 
                  --DBMS_OUTPUT.put_line('il existe un autre site sur cette UO avec le meme code de celui de référence');
                    vr_vendor_site_rec.vendor_site_code              := rec_frns_duplique.vendor_site_code;
                    vn_maj_code_echec := 1;	                    
                    vv_message := 'Le code du site fournisseur n''a pas été mis à jour car un autre site sur cette UO possède déjà le même code que celui de la référence';
                    --DBMS_OUTPUT.put_line(vv_message);
                    INSERT INTO DKA_SAPFRSDUPLI_ERROR_TMP
                    values
                    (v_action_id,
                     rec_frns_duplique.VENDOR_SITE_ID,
                     1,
                     'ERREUR',
                     vv_message,
                     sysdate,
                     g_user) ;
                  ELSE
                    --DBMS_OUTPUT.put_line('pas de site ayant le meme code de ref');
                    vr_vendor_site_rec.vendor_site_code := vr_site_rowtype.vendor_site_code;            
                  END IF ;
                END IF;                  
              ELSE
                --site fournisseur désactivé
                writelog('Site fournisseur désactivé '||rec_frns_duplique.vendor_site_code,0,0);
                --DBMS_OUTPUT.put_line('ite fournisseur désactivé '||rec_frns_duplique.vendor_site_code);
                vn_maj_code_echec := 1;	
                vr_vendor_site_rec.vendor_site_code := rec_frns_duplique.vendor_site_code;
              END IF;
            END IF;
          ELSE  
            vr_vendor_site_rec.vendor_site_code := vr_site_rowtype.vendor_site_code;          
          END IF; 
 
		  -- date désactivation
			v_date_active := rec_frns_duplique.INACTIVE_DATE;
			
		  IF v_date_active is null  THEN
		    v_date_active := vr_site_rowtype.inactive_date;
      END IF;
              v_etape := ' 05 : Récupération des segments comptables';
              -- Récupération nouveau compte fournisseur
              BEGIN
                SELECT segment1,
                       segment2,
                       segment3,
                       segment4,
                       segment5,
                       segment6,
                       segment7,
                       segment8,
                       segment9,
                       segment10,
                       segment11,
                       segment12
                INTO   vn_segment1,
                       vn_segment2,
                       vn_segment3,
                       vn_segment4,
                       vn_segment5,
                       vn_segment6,
                       vn_segment7,
                       vn_segment8,
                       vn_segment9,
                       vn_segment10,
                       vn_segment11,
                       vn_segment12
                FROM   gl_code_combinations
                WHERE  code_combination_id = vr_site_rowtype.accts_pay_code_combination_id
                ;
              EXCEPTION
                WHEN OTHERS THEN
                  NULL;
              END;

              v_etape := '05-1 : Récupération du segment Compte GL founisseur';
              Dka_Tools_Pkg.get_code_combination_id(pv_segment1              => substr(rec_uo_dupliques.uo,4,4),
                                                    pv_segment2              => substr(rec_uo_dupliques.uo, 1, 3),
                                                    pv_segment3              => vn_segment3,
                                                    pv_segment4              => vn_segment4,
                                                    pv_segment5              => vn_segment5,
                                                    pv_segment6              => vn_segment6,
                                                    pv_segment7              => vn_segment7,
                                                    pv_segment8              => vn_segment8,
                                                    pv_segment9              => vn_segment9,
                                                    pv_segment10             => vn_segment10,
                                                    pv_segment11             => vn_segment11,
                                                    pv_segment12             => vn_segment12,
                                                    pn_code_combination_id   => vn_ACCTS_PAY_CCID,
                                                    pv_errbuf                => vv_errbuf,
                                                    pn_retcode               => vn_retcode);

              v_etape  := 'Compte GL founisseur : '||vn_ACCTS_PAY_CCID;

              IF  vn_retcode != 0 
              THEN
                  vv_message := 'La clé comptable '||substr(rec_uo_dupliques.uo,4,4)||'.'||substr(rec_uo_dupliques.uo, 1, 3)||'.'||vn_segment3||'.'||vn_segment4||'.'||vn_segment5||
                                    '.'||vn_segment6||'.'||vn_segment7||'.'||vn_segment8||'.'||vn_segment9||'.'||vn_segment10||'.'||vn_segment11||'.'||vn_segment12||
                                    ' n''a pas pu être générée- '||vv_errbuf;
                  INSERT INTO DKA_SAPFRSDUPLI_ERROR_TMP
                  values
                 (v_action_id,
                  rec_frns_duplique.VENDOR_SITE_ID,
                  2,
                 'ERREUR',
                 vv_message,
                 sysdate,
                 g_user) ;
				 vn_ACCTS_PAY_CCID := vr_site_rowtype.accts_pay_code_combination_id ;

              END IF;

              -- Récupération nouveau compte accompte
              BEGIN
                SELECT segment1,
                       segment2,
                       segment3,
                       segment4,
                       segment5,
                       segment6,
                       segment7,
                       segment8,
                       segment9,
                       segment10,
                       segment11,
                       segment12
                INTO   vn_segment1,
                       vn_segment2,
                       vn_segment3,
                       vn_segment4,
                       vn_segment5,
                       vn_segment6,
                       vn_segment7,
                       vn_segment8,
                       vn_segment9,
                       vn_segment10,
                       vn_segment11,
                       vn_segment12
                FROM   gl_code_combinations
                WHERE  code_combination_id = vr_site_rowtype.prepay_code_combination_id
                ;
               EXCEPTION
               WHEN OTHERS THEN
                 NULL;
              END;

              v_etape := '05-2 : Récupération du segment Compte GL acompte';
              Dka_Tools_Pkg.get_code_combination_id(pv_segment1              => substr(rec_uo_dupliques.uo,4,4),
                                                    pv_segment2              => substr(rec_uo_dupliques.uo, 1, 3),
                                                    pv_segment3              => vn_segment3,
                                                    pv_segment4              => vn_segment4,
                                                    pv_segment5              => vn_segment5,
                                                    pv_segment6              => vn_segment6,
                                                    pv_segment7              => vn_segment7,
                                                    pv_segment8              => vn_segment8,
                                                    pv_segment9              => vn_segment9,
                                                    pv_segment10             => vn_segment10,
                                                    pv_segment11             => vn_segment11,
                                                    pv_segment12             => vn_segment12,
                                                    pn_code_combination_id   => vn_PREPAY_CCID,
                                                    pv_errbuf                => vv_errbuf,
                                                    pn_retcode               => vn_retcode);

              v_etape  := 'Compte GL acompte : '||vn_PREPAY_CCID;


              IF  vn_retcode != 0 
              THEN
                  vv_message := 'La clé comptable '||substr(rec_uo_dupliques.uo,4,4)||'.'||substr(rec_uo_dupliques.uo, 1, 3)||'.'||vn_segment3||'.'||vn_segment4||'.'||vn_segment5||
                                    '.'||vn_segment6||'.'||vn_segment7||'.'||vn_segment8||'.'||vn_segment9||'.'||vn_segment10||'.'||vn_segment11||'.'||vn_segment12||
                                    ' n''a pas pu être générée- '||vv_errbuf;
                  INSERT INTO DKA_SAPFRSDUPLI_ERROR_TMP
                  values
                  (v_action_id,
                  rec_frns_duplique.VENDOR_SITE_ID,
                  3,
                  'ERREUR',
                  vv_message,
                  sysdate,
                  g_user) ;
				    vn_PREPAY_CCID := vr_site_rowtype.prepay_code_combination_id ;


              END IF;


              BEGIN
               SELECT segment1,
                      segment2,
                      segment3,
                      segment4,
                      segment5,
                      segment6,
                      segment7,
                      segment8,
                      segment9,
                      segment10,
                      segment11,
                      segment12
               INTO   vn_segment1,
                      vn_segment2,
                      vn_segment3,
                      vn_segment4,
                      vn_segment5,
                      vn_segment6,
                      vn_segment7,
                      vn_segment8,
                      vn_segment9,
                      vn_segment10,
                      vn_segment11,
                      vn_segment12
               FROM  gl_code_combinations
               WHERE code_combination_id = vr_site_rowtype.future_dated_payment_ccid
               ;
              EXCEPTION
               WHEN OTHERS THEN
                 NULL;
              END;

              v_etape := '05-3 : Récupération du segment Effet à payer';
              Dka_Tools_Pkg.get_code_combination_id(pv_segment1              => substr(rec_uo_dupliques.uo,4,4),
                                                    pv_segment2              => substr(rec_uo_dupliques.uo, 1, 3),
                                                    pv_segment3              => vn_segment3,
                                                    pv_segment4              => vn_segment4,
                                                    pv_segment5              => vn_segment5,
                                                    pv_segment6              => vn_segment6,
                                                    pv_segment7              => vn_segment7,
                                                    pv_segment8              => vn_segment8,
                                                    pv_segment9              => vn_segment9,
                                                    pv_segment10             => vn_segment10,
                                                    pv_segment11             => vn_segment11,
                                                    pv_segment12             => vn_segment12,
                                                    pn_code_combination_id   => vn_future_CCID,
                                                    pv_errbuf                => vv_errbuf,
                                                    pn_retcode               => vn_retcode);

              v_etape  := 'Compte Effet à payer: '||vn_future_CCID;

              IF  vn_retcode != 0 
              THEN
                  vv_message := 'La clé comptable '||substr(rec_uo_dupliques.uo,4,4)||'.'||substr(rec_uo_dupliques.uo, 1, 3)||'.'||vn_segment3||'.'||vn_segment4||'.'||vn_segment5||
                                    '.'||vn_segment6||'.'||vn_segment7||'.'||vn_segment8||'.'||vn_segment9||'.'||vn_segment10||'.'||vn_segment11||'.'||vn_segment12||
                                    ' n''a pas pu être générée- '||vv_errbuf;
                  INSERT INTO DKA_SAPFRSDUPLI_ERROR_TMP
                  values
                 (v_action_id,
                  rec_frns_duplique.VENDOR_SITE_ID,
                  4,
                  'ERREUR',
                  vv_message,
                  sysdate,
                  g_user) ;


				vn_future_CCID := vr_site_rowtype.future_dated_payment_ccid;
              END IF;

              v_etape := ' 06 : Appel a l''API AP_VENDOR_PUB_PKG.UPDATE_VENDOR_SITE';
              --Appel a l'API AP_VENDOR_PUB_PKG.UPDATE_VENDOR_SITE
              p_api_version               := 1.0;
              vv_init_msg_list          := FND_API.G_TRUE;
              vv_commit                 := FND_API.G_FALSE;
              vn_validation_level       := FND_API.G_VALID_LEVEL_FULL;
              x_return_status           := NULL;
              x_msg_count               := NULL;
              x_msg_data                := NULL;

              vr_vendor_site_rec.org_id                        := rec_uo_dupliques.organization_id;
              vr_vendor_site_rec.last_update_date              := SYSDATE;
              vr_vendor_site_rec.last_updated_by               := g_user ;---1;
              ---Adresse site fournisseur-----
              vr_vendor_site_rec.location_id                   := vr_site_rowtype.location_id;
              vr_vendor_site_rec.country                       := vr_site_rowtype.country;
              vr_vendor_site_rec.address_line1                 := vr_site_rowtype.address_line1;
              vr_vendor_site_rec.address_line2                 := vr_site_rowtype.address_line2;
              vr_vendor_site_rec.address_line3                 := vr_site_rowtype.address_line3;
              vr_vendor_site_rec.address_line4                 := vr_site_rowtype.address_line4;
              vr_vendor_site_rec.county                        := vr_site_rowtype.county;
              vr_vendor_site_rec.city                          := vr_site_rowtype.city;
              vr_vendor_site_rec.state                         := vr_site_rowtype.state;
              vr_vendor_site_rec.province                      := vr_site_rowtype.province;
              vr_vendor_site_rec.address_lines_alt             := vr_site_rowtype.address_lines_alt;
              vr_vendor_site_rec.zip                           := vr_site_rowtype.zip;
              --vr_vendor_site_rec.vendor_site_code              := vr_site_rowtype.vendor_site_code;

              ---Fonctions site fournisseur-----
              vr_vendor_site_rec.purchasing_site_flag          := vr_site_rowtype.purchasing_site_flag; --A REVOIR
              vr_vendor_site_rec.rfq_only_site_flag            := vr_site_rowtype.rfq_only_site_flag;
              --vr_vendor_site_rec.pay_site_flag                 := vr_site_rowtype.pay_site_flag;
              --vr_vendor_site_rec.attention_ar_flag             := vr_site_rowtype.attention_ar_flag;
              vr_vendor_site_rec.pcard_site_flag               := vr_site_rowtype.pcard_site_flag;
              vr_vendor_site_rec.primary_pay_site_flag         := vr_site_rowtype.primary_pay_site_flag;

              ---CUF ---------------------------
              vr_vendor_site_rec.attribute1                    := vr_site_rowtype.attribute1;
              vr_vendor_site_rec.attribute4                    := vr_site_rowtype.attribute4;
              vr_vendor_site_rec.attribute6                    := vr_site_rowtype.attribute6;
              vr_vendor_site_rec.attribute7                    := vr_site_rowtype.attribute7;

              ---Info de communication----------
              vr_vendor_site_rec.supplier_notif_method          := vr_site_rowtype.supplier_notif_method;
              vr_vendor_site_rec.LANGUAGE                       := vr_site_rowtype.LANGUAGE;
              vr_vendor_site_rec.area_code                      := vr_site_rowtype.area_code;
              vr_vendor_site_rec.phone                          := vr_site_rowtype.phone;
              vr_vendor_site_rec.fax                            := vr_site_rowtype.fax;
              vr_vendor_site_rec.fax_area_code                  := vr_site_rowtype.fax_area_code;
              vr_vendor_site_rec.telex                          := vr_site_rowtype.telex;
              vr_vendor_site_rec.email_address                  := vr_site_rowtype.email_address;

              ---Info d'identification----------
              vr_vendor_site_rec.edi_id_number                 := vr_site_rowtype.edi_id_number;
              vr_vendor_site_rec.ece_tp_location_code          := vr_site_rowtype.ece_tp_location_code;
              vr_vendor_site_rec.customer_num                  := vr_site_rowtype.customer_num;
              vr_vendor_site_rec.vendor_site_code_alt          := vr_site_rowtype.vendor_site_code_alt ;

              ---Info gestion TVA--------------
              vr_vendor_site_rec.auto_tax_calc_flag            := vr_site_rowtype.auto_tax_calc_flag;
              vr_vendor_site_rec.vat_registration_num          := vr_site_rowtype.vat_registration_num;
              vr_vendor_site_rec.offset_tax_flag               := vr_site_rowtype.offset_tax_flag;
              vr_vendor_site_rec.ap_tax_rounding_rule          := vr_site_rowtype.ap_tax_rounding_rule;
              vr_vendor_site_rec.amount_includes_tax_flag      := vr_site_rowtype.amount_includes_tax_flag;
              vr_vendor_site_rec.vat_code                      := vr_site_rowtype.vat_code;
              vr_vendor_site_rec.tax_reporting_site_flag       := vr_site_rowtype.tax_reporting_site_flag;

              ---Info gestion achat-------------------------
              --vr_vendor_site_rec.ship_to_location_id           := vr_site_rowtype.ship_to_location_id;
              vr_vendor_site_rec.ship_via_lookup_code          := vr_site_rowtype.ship_via_lookup_code;
              vr_vendor_site_rec.pay_on_code                   := vr_site_rowtype.pay_on_code;
              vr_vendor_site_rec.default_pay_site_id           := vr_site_rowtype.default_pay_site_id;
              vr_vendor_site_rec.pay_on_receipt_summary_code   := vr_site_rowtype.pay_on_receipt_summary_code;
              vr_vendor_site_rec.create_debit_memo_flag        := vr_site_rowtype.create_debit_memo_flag;
              vr_vendor_site_rec.gapless_inv_num_flag          := vr_site_rowtype.gapless_inv_num_flag;
              vr_vendor_site_rec.selling_company_identifier    := vr_site_rowtype.selling_company_identifier;
              vr_vendor_site_rec.fob_lookup_code               := vr_site_rowtype.fob_lookup_code;
              vr_vendor_site_rec.freight_terms_lookup_code     := vr_site_rowtype.freight_terms_lookup_code;
              vr_vendor_site_rec.shipping_control              := vr_site_rowtype.shipping_control;
              vr_vendor_site_rec.country_of_origin_code        := vr_site_rowtype.country_of_origin_code;

              ----Info gestion facture----------------------
              vr_vendor_site_rec.invoice_amount_limit          := vr_site_rowtype.invoice_amount_limit;
              vr_vendor_site_rec.tolerance_id                  := vr_site_rowtype.tolerance_id;
              vr_vendor_site_rec.match_option                  := vr_site_rowtype.match_option;
              vr_vendor_site_rec.hold_all_payments_flag        := vr_site_rowtype.hold_all_payments_flag;
              vr_vendor_site_rec.hold_unmatched_invoices_flag  := vr_site_rowtype.hold_unmatched_invoices_flag;
              vr_vendor_site_rec.hold_future_payments_flag     := vr_site_rowtype.hold_future_payments_flag;
              vr_vendor_site_rec.hold_reason                   := vr_site_rowtype.hold_reason;
              vr_vendor_site_rec.purchasing_site_flag          := vr_site_rowtype.purchasing_site_flag;
              vr_vendor_site_rec.pay_group_lookup_code         := vr_site_rowtype.pay_group_lookup_code;
              vr_vendor_site_rec.terms_date_basis              := vr_site_rowtype.terms_date_basis;
              vr_vendor_site_rec.payment_priority              := vr_site_rowtype.payment_priority;
              vr_vendor_site_rec.bank_charge_bearer            := vr_site_rowtype.bank_charge_bearer;
              vr_vendor_site_rec.terms_id                      := vr_site_rowtype.terms_id;
              vr_vendor_site_rec.pay_date_basis_lookup_code    := vr_site_rowtype.pay_date_basis_lookup_code;
              vr_vendor_site_rec.retainage_rate                := vr_site_rowtype.retainage_rate;
              vr_vendor_site_rec.always_take_disc_flag         := vr_site_rowtype.always_take_disc_flag;
              vr_vendor_site_rec.exclude_freight_from_discount := vr_site_rowtype.exclude_freight_from_discount;
              vr_vendor_site_rec.inactive_date                 := v_date_active;
              ---Segments comptables-------------------------
              vr_vendor_site_rec.accts_pay_code_combination_id := vn_ACCTS_PAY_CCID;
              vr_vendor_site_rec.prepay_code_combination_id    := vn_PREPAY_CCID;
              vr_vendor_site_rec.future_dated_payment_ccid     := vn_future_CCID;

              --///MAJ du site fournisseur - API
              AP_VENDOR_PUB_PKG.UPDATE_VENDOR_SITE (p_api_version,
                                                    vv_init_msg_list,
                                                    vv_commit,
                                                    vn_validation_level,
                                                    x_return_status,
                                                    x_msg_count,
                                                    x_msg_data,
                                                    vr_vendor_site_rec,
                                                    rec_frns_duplique.VENDOR_SITE_ID
                                                    );

               IF (x_return_status <> fnd_api.g_ret_sts_success) 
               THEN
                     FOR i IN 1 .. fnd_msg_pub.count_msg 
                     LOOP
                          vv_message := substr(fnd_msg_pub.get(p_msg_index => i,p_encoded   => fnd_api.g_false),1,500);
                          writelog(vv_message,0,0);
                          INSERT INTO DKA_SAPFRSDUPLI_ERROR_TMP
                          values
                         (v_action_id,
                          rec_frns_duplique.VENDOR_SITE_ID,
                          5,
                         'ERREUR',
                          vv_message,
                          sysdate,
                          g_user) ;
                    END LOOP;

               ELSE
                    vv_message := 'Mise à jour du site fournisseur '||rec_frns_duplique.VENDOR_SITE_ID||' terminée OK';
                    writelog(vv_message,0,0);
                    vn_cpt_site := 'S';
					COMPARE_VALUE(vr_site_rowtype.vendor_site_id ,
                                  rec_frns_duplique.VENDOR_SITE_ID ) ;
					UPDATE ap_supplier_sites_all					
					SET ship_to_location_id  = rec_frns_duplique.ship_to_location_id
					where vendor_site_id     = rec_frns_duplique.VENDOR_SITE_ID ;
					
					IF rec_frns_duplique.VENDOR_SITE_CODE <> vr_vendor_site_rec.vendor_site_code 
					then 
					-- DEBUT SHA INC0513623
					update AP_CHECKS_ALL 
					set VENDOR_SITE_CODE    = vr_vendor_site_rec.vendor_site_code
					 where vendor_site_id = rec_frns_duplique.vendor_site_id;
					 
					update AP_CHECKS_ALL 
					set REMIT_TO_SUPPLIER_SITE = vr_vendor_site_rec.vendor_site_code
					where REMIT_TO_SUPPLIER_SITE_ID = rec_frns_duplique.vendor_site_id;
					
					END IF ;  
					
				commit;	
               END IF;

               v_etape := ' 07 : Appel a l''API iby_disbursement_setup_pub.update_external_payee';
               BEGIN
                  SELECT ext_payee_id,payee_party_id
                  INTO vv_ext_payee_id,vv_payee_party_id
                  FROM IBY_EXTERNAL_PAYEES_ALL  iepa
                  WHERE 1=1
                  AND iepa.SUPPLIER_SITE_ID = rec_frns_duplique.VENDOR_SITE_ID
                  AND iepa.ORG_ID = rec_uo_dupliques.organization_id;
               EXCEPTION
               WHEN OTHERS THEN
                  vv_ext_payee_id := NULL;
                  vv_payee_party_id := NULL;
               END ;

               --Appel a l'API iby_disbursement_setup_pub.update_external_payee
               x_return_status    := NULL;
               x_msg_count        := NULL;
               x_msg_data         := NULL;

               p_ext_payee_tab(i).delivery_channel             := vr_iby_rowtype.delivery_channel_code;
               p_ext_payee_tab(i).default_pmt_method           := v_payment_method_code;--vr_iby_rowtype.default_payment_method_code;
               p_ext_payee_tab(i).bank_instr1_code             := vr_iby_rowtype.bank_instruction1_code;
               p_ext_payee_tab(i).bank_instr2_code             := vr_iby_rowtype.bank_instruction2_code;
               p_ext_payee_tab(i).bank_instr_detail            := vr_iby_rowtype.bank_instruction_details;
               p_ext_payee_tab(i).settlement_priority          := vr_iby_rowtype.settlement_priority;
               p_ext_payee_tab(i).pay_message1                 := vr_iby_rowtype.payment_text_message1;
               p_ext_payee_tab(i).pay_message2                 := vr_iby_rowtype.payment_text_message2;
               p_ext_payee_tab(i).pay_message3                 := vr_iby_rowtype.payment_text_message3;
               p_ext_payee_tab(i).exclusive_pay_flag           := vr_iby_rowtype.exclusive_payment_flag;
               p_ext_payee_tab(i).bank_charge_bearer           := vr_iby_rowtype.bank_charge_bearer;
               p_ext_payee_tab(i).pay_reason_code              := vr_iby_rowtype.payment_reason_code;
               p_ext_payee_tab(i).pay_reason_com               := vr_iby_rowtype.payment_reason_comments;
               p_ext_payee_tab(i).pmt_format                   := vr_iby_rowtype.payment_format_code;
               p_ext_payee_tab(i).remit_advice_delivery_method := vr_iby_rowtype.remit_advice_delivery_method;
               p_ext_payee_tab(i).remit_advice_email           := vr_iby_rowtype.remit_advice_email;
               p_ext_payee_tab(i).remit_advice_fax             := vr_iby_rowtype.remit_advice_fax;
               p_ext_payee_tab(i).payee_party_id               := vv_payee_party_id;
               p_ext_payee_tab(i).Payee_party_site_id          := rec_frns_duplique.party_site_id;
               p_ext_payee_tab(i).Supplier_Site_id             := rec_frns_duplique.vendor_site_id;
               p_ext_payee_tab(i).Payer_Org_Type               := 'OPERATING_UNIT';
               p_ext_payee_tab(i).Payer_Org_id                 := rec_uo_dupliques.organization_id;
               p_ext_payee_tab (i).payment_function            := 'PAYABLES_DISB';
               p_ext_payee_id_tab(i).ext_payee_id              := vv_ext_payee_id;

                   ---<Debut IBA KDFI-652
			    update IBY_EXT_PARTY_PMT_MTHDS 
                   set PAYMENT_METHOD_CODE = v_payment_method_code
                    where ext_pmt_party_id = vv_ext_payee_id
                    and PRIMARY_FLAG = 'Y';
					
					--- FIN IBA KFI-652 >
			  
			   IBY_DISBURSEMENT_SETUP_PUB.update_external_payee (p_api_version            => 1.0,
                                                                 p_init_msg_list          => 'T',
                                                                 p_ext_payee_tab          => p_ext_payee_tab,
                                                                 p_ext_payee_id_tab       => p_ext_payee_id_tab,
                                                                 x_return_status          => x_return_status,
                                                                 x_msg_count              => x_msg_count,
                                                                 x_msg_data               => x_msg_data,
                                                                 x_ext_payee_status_tab   => l_payee_upd_status
                                                                  );


               IF x_return_status = 'E'
               THEN
                  FOR k IN l_payee_upd_status.FIRST .. l_payee_upd_status.LAST
                  LOOP
                       vv_message := 'Une erreur est survenue lors de la mise à jour des informations de règlement' ||' '|| l_payee_upd_status (k).Payee_update_Msg;
                       writelog(vv_message ||' '|| l_payee_upd_status (k).Payee_update_Msg,0,0);
                       INSERT INTO DKA_SAPFRSDUPLI_ERROR_TMP
                       values
                      (v_action_id,
                       rec_frns_duplique.VENDOR_SITE_ID,
                       6,
                       'ERREUR',
                       vv_message,
                       sysdate,
                       g_user) ;
                  END LOOP;                 

               ELSE
                  writelog('Mise à jour des informations de réglement terminée avec succès',0,0);
                  vn_cpt_reg := 'S';
               END IF;

               ---Mise à jour des coordonnées bancaires:
               v_count := 0;
               FOR rec_cpt_bank_ref IN c_cpt_bank_ref 
               LOOP
                  v_etape := ' 08 : Extraction des informations bancaires du site dipliqué';
                  BEGIN
                      SELECT 1
                      INTO   v_bank_exist
                      FROM
                        iby_ext_bank_accounts ieb
                       ,iby_pmt_instr_uses_all ipi
                       ,iby_external_payees_all iep
                      WHERE  iep.supplier_site_id         = rec_frns_duplique.vendor_site_id
                       AND   iep.ext_payee_id             = ipi.ext_pmt_party_id
                       AND   ipi.instrument_id            = ieb.ext_bank_account_id
                      -- AND   nvl(ipi.start_date,SYSDATE) <= SYSDATE
                      -- AND   nvl(ipi.end_date,SYSDATE)   >= SYSDATE
                       AND   ipi.payment_function         = 'PAYABLES_DISB'
                       AND   iep.org_id                   = rec_uo_dupliques.organization_id
                       AND   ieb.ext_bank_account_id      = rec_cpt_bank_ref.ext_bank_account_id;
                  EXCEPTION
                  WHEN OTHERS THEN
                     v_bank_exist := 0;
                  END;
                     --DBMS_OUTPUT.PUT_LINE('ext_bank_account_name : '||rec_cpt_bank_ref.BANK_ACCOUNT_NAME);
                     --DBMS_OUTPUT.PUT_LINE('v_bank_exist : '||v_bank_exist);
                     --DBMS_OUTPUT.PUT_LINE('date_fin : '||rec_cpt_bank_ref.end_date);

                  IF v_bank_exist != 1 AND (rec_cpt_bank_ref.end_date >= SYSDATE OR rec_cpt_bank_ref.end_date is null)  
                  THEN

                      v_etape := ' 09 : Attachement du compte bancaire API de création :IBY_DISBURSEMENT_SETUP_PUB.Set_Payee_Instr_Assignment';
                      --DBMS_OUTPUT.PUT_LINE(v_etape);
                      -- Attachement du compte bancaire API de création
                      p_api_version             := 1.0;
                      vv_init_msg_list          := FND_API.G_TRUE;
                      vv_commit                 := FND_API.G_FALSE;
                      vn_validation_level       := FND_API.G_VALID_LEVEL_FULL;
                      x_return_status           := NULL;
                      x_msg_count               := NULL;
                      x_msg_data                := NULL;


                      vr_payee_context_rec.Party_Id                     := rec_frns_duplique.party_id;
                      vr_payee_context_rec.payment_function             := 'PAYABLES_DISB';
                      vr_payee_context_rec.party_site_id                := rec_frns_duplique.party_site_id;
                      vr_payee_context_rec.Supplier_Site_id             := rec_frns_duplique.vendor_site_id;
                      vr_payee_context_rec.Org_Type                     := 'OPERATING_UNIT';
                      vr_payee_context_rec.Org_Id                       := rec_uo_dupliques.organization_id;

                      vr_assignment_attribs.instrument.instrument_type  :='BANKACCOUNT';
                      vr_assignment_attribs.instrument.instrument_id    := rec_cpt_bank_ref.ext_bank_account_id;
                      vr_assignment_attribs.start_date                  := rec_cpt_bank_ref.start_date;
                      vr_assignment_attribs.end_date                    := rec_cpt_bank_ref.end_date;
                      vr_assignment_attribs.priority                    := rec_cpt_bank_ref.ORDER_OF_PREFERENCE;

                      -- map account to site supplier
                      IBY_DISBURSEMENT_SETUP_PUB.Set_Payee_Instr_Assignment (p_api_version        => 1.0,
                                                                             p_init_msg_list      => vv_init_msg_list,
                                                                             p_commit             => vv_commit,
                                                                             x_return_status      => x_return_status,
                                                                             x_msg_count          => x_msg_count,
                                                                             x_msg_data           => x_msg_data,
                                                                             p_payee              => vr_payee_context_rec,
                                                                             p_assignment_attribs => vr_assignment_attribs,
                                                                             x_assign_id          => vn_assign_id,
                                                                             x_response           => vr_response
                                                                           );



                      IF (x_return_status <> fnd_api.g_ret_sts_success) 
                      THEN
                          FOR i IN 1 .. fnd_msg_pub.count_msg 
                          LOOP
                             vv_message := substr('Le compte bancaire '||rec_cpt_bank_ref.BANK_ACCOUNT_NAME||' n''a pas pu être rattaché au site fournisseur de l''UO '||rec_uo_dupliques.uo||':'||fnd_msg_pub.get(p_msg_index => i,p_encoded => fnd_api.g_false),1,500);
                             INSERT INTO DKA_SAPFRSDUPLI_ERROR_TMP
                             values
                            (v_action_id,
                             rec_frns_duplique.VENDOR_SITE_ID,
                             7,
                             'ERREUR',
                             vv_message,
                             sysdate,
                             g_user) ;
                          END LOOP;
                          vn_cpt_bank := 'E';
                      ELSE
                          vn_cpt_bank := 'S';
                      END IF;
                  ELSIF v_bank_exist = 1 
                  THEN
                     v_etape := ' 010 : le cas de compte bancaire déjà rattaché au site dupliqué';
                     --DBMS_OUTPUT.PUT_LINE(v_etape);
                     --- le cas de compte bancaire déjà rattaché au site dupliqué :

                     p_api_version             := 1.0;
                     vv_init_msg_list          := FND_API.G_TRUE;
                     vv_commit                 := FND_API.G_FALSE;
                     vn_validation_level       := FND_API.G_VALID_LEVEL_FULL;
                     x_return_status           := NULL;
                     x_msg_count               := NULL;
                     x_msg_data                := NULL;


                     vr_payee_context_rec.Party_Id                     := rec_frns_duplique.party_id;
                     vr_payee_context_rec.payment_function             := 'PAYABLES_DISB';
                     vr_payee_context_rec.party_site_id                := rec_frns_duplique.party_site_id;
                     vr_payee_context_rec.Supplier_Site_id             := rec_frns_duplique.vendor_site_id;
                     vr_payee_context_rec.Org_Type                     := 'OPERATING_UNIT';
                     vr_payee_context_rec.Org_Id                       := rec_uo_dupliques.organization_id;

                     vr_assignment_attribs.instrument.instrument_type  :='BANKACCOUNT';
                     vr_assignment_attribs.instrument.instrument_id    := rec_cpt_bank_ref.ext_bank_account_id;
                     vr_assignment_attribs.start_date                  := rec_cpt_bank_ref.start_date;
                     vr_assignment_attribs.end_date                    := rec_cpt_bank_ref.end_date;
                     vr_assignment_attribs.priority                    := rec_cpt_bank_ref.ORDER_OF_PREFERENCE;

                     -- map account to site supplier
                     IBY_DISBURSEMENT_SETUP_PUB.Set_Payee_Instr_Assignment (p_api_version        => 1.0,
                                                                            p_init_msg_list      => vv_init_msg_list,
                                                                            p_commit             => vv_commit,
                                                                            x_return_status      => x_return_status,
                                                                            x_msg_count          => x_msg_count,
                                                                            x_msg_data           => x_msg_data,
                                                                            p_payee              => vr_payee_context_rec,
                                                                            p_assignment_attribs => vr_assignment_attribs,
                                                                            x_assign_id          => vn_assign_id,
                                                                            x_response           => vr_response
                                                                            );



                     IF (x_return_status <> fnd_api.g_ret_sts_success) 
                     THEN
                        FOR i IN 1 .. fnd_msg_pub.count_msg 
                        LOOP
                              vv_message := substr('la mise à jour du compte bancaire '||rec_cpt_bank_ref.BANK_ACCOUNT_NAME||'est terminée avec erreur : '||fnd_msg_pub.get(p_msg_index => i,p_encoded => fnd_api.g_false),1,500);
                              INSERT INTO DKA_SAPFRSDUPLI_ERROR_TMP
                              values
                             (v_action_id,
                              rec_frns_duplique.VENDOR_SITE_ID,
                              8,
                             'ERREUR',
                             vv_message,
                             sysdate,
                             g_user) ;
                        END LOOP;
                            vn_cpt_bank := 'E';
                     ELSE
                       vv_message := 'la mise à jour du compte bancaire '||rec_cpt_bank_ref.BANK_ACCOUNT_NAME||'est terminée avec succès';
                       vn_cpt_bank := 'S';
                     END IF;
                  END IF;
                    v_count := v_count+1;
               END LOOP;
               --DBMS_OUTPUT.PUT_LINE('v_count : '||v_count); 

               v_etape := ' 011 : le cas de compte bancaire actif n''existant pas sur la référence';
               FOR rec_bank_a_descative IN (
                                     SELECT ieb.ext_bank_account_id
                                     ,      IEB.BANK_ACCOUNT_NAME
                                     FROM
                                               iby_ext_bank_accounts ieb
                                              ,iby_pmt_instr_uses_all ipi
                                              ,iby_external_payees_all iep
                                     WHERE  iep.supplier_site_id         = rec_frns_duplique.vendor_site_id
                                      AND   iep.ext_payee_id             = ipi.ext_pmt_party_id
                                      AND   ipi.instrument_id            = ieb.ext_bank_account_id
                                      AND   nvl(ipi.start_date,SYSDATE) <= SYSDATE
                                      AND   nvl(ipi.end_date,SYSDATE)   >= SYSDATE
                                      AND   ipi.payment_function         = 'PAYABLES_DISB'
                                      AND   iep.org_id                   = rec_uo_dupliques.organization_id
                                      AND   ieb.ext_bank_account_id     NOT IN (SELECT ieb.ext_bank_account_id
                                                                                FROM
                                                                                      iby_ext_bank_accounts ieb
                                                                                     ,iby_pmt_instr_uses_all ipi
                                                                                     ,iby_external_payees_all iep
                                                                                WHERE  iep.supplier_site_id         = p_id_site_frns_ref
                                                                                 AND   iep.ext_payee_id             = ipi.ext_pmt_party_id
                                                                                 AND   ipi.instrument_id            = ieb.ext_bank_account_id
                                                                                 AND   nvl(ipi.start_date,SYSDATE) <= SYSDATE
                                                                                 AND   nvl(ipi.end_date,SYSDATE)   >= SYSDATE
                                                                                 AND   ipi.payment_function         = 'PAYABLES_DISB'
                                                                                 -- AND   iep.org_id                   = rec_uo_dupliques.organization_id
                                                                                )) 
               LOOP


                  p_api_version             := 1.0;
                  vv_init_msg_list          := FND_API.G_TRUE;
                  vv_commit                 := FND_API.G_FALSE;
                  vn_validation_level       := FND_API.G_VALID_LEVEL_FULL;
                  x_return_status           := NULL;
                  x_msg_count               := NULL;
                  x_msg_data                := NULL;


                  vr_payee_context_rec.Party_Id                     := rec_frns_duplique.party_id;
                  vr_payee_context_rec.payment_function             := 'PAYABLES_DISB';
                  vr_payee_context_rec.party_site_id                := rec_frns_duplique.party_site_id;
                  vr_payee_context_rec.Supplier_Site_id             := rec_frns_duplique.vendor_site_id;
                  vr_payee_context_rec.Org_Type                     := 'OPERATING_UNIT';
                  vr_payee_context_rec.Org_Id                       := rec_uo_dupliques.organization_id;

                  vr_assignment_attribs.instrument.instrument_type  :='BANKACCOUNT';
                  vr_assignment_attribs.instrument.instrument_id    := rec_bank_a_descative.ext_bank_account_id;
                  vr_assignment_attribs.end_date                    := sysdate;

                  -- map account to site supplier
                  IBY_DISBURSEMENT_SETUP_PUB.Set_Payee_Instr_Assignment (p_api_version        => 1.0,
                                                                         p_init_msg_list      => vv_init_msg_list,
                                                                         p_commit             => vv_commit,
                                                                         x_return_status      => x_return_status,
                                                                         x_msg_count          => x_msg_count,
                                                                         x_msg_data           => x_msg_data,
                                                                         p_payee              => vr_payee_context_rec,
                                                                         p_assignment_attribs => vr_assignment_attribs,
                                                                         x_assign_id          => vn_assign_id,
                                                                         x_response           => vr_response
                                                                       );



                  IF (x_return_status <> fnd_api.g_ret_sts_success) 
                  THEN
                    FOR i IN 1 .. fnd_msg_pub.count_msg 
                    LOOP
                       vv_message := substr('la mise à jour du compte bancaire '||rec_bank_a_descative.BANK_ACCOUNT_NAME||' est terminée avec erreur'||' : '||fnd_msg_pub.get(p_msg_index => i,p_encoded => fnd_api.g_false),1,500) ;
                       INSERT INTO DKA_SAPFRSDUPLI_ERROR_TMP
                       values
                       (v_action_id,
                        rec_frns_duplique.VENDOR_SITE_ID,
                        9,
                        'ERREUR',
                        vv_message,
                        sysdate,
                        g_user) ;
                    END LOOP;
                  ELSE
	                  vv_message := 'la mise à jour du compte bancaire '||rec_bank_a_descative.BANK_ACCOUNT_NAME||' est terminée avec succès' ;
	                  --vn_cpt_bank := 'S';
                  END IF;

               END LOOP;

               v_etape := 'Le nombre des mises à jour'; 

               IF vn_cpt_site = 'S'  AND vn_cpt_reg = 'S'  AND vn_cpt_bank = 'S'  
               THEN
                  vn_cpt_site_ok := vn_cpt_site_ok + 1 ;
               ELSE
                  vn_cpt_site_ko := vn_cpt_site_ko + 1;
               END IF ;            

               vn_cpt_site := NULL;
               vn_cpt_reg  := NULL;
               --vn_cpt_bank := NULL;
       END IF;--controle unicite
        END LOOP;
      
   END LOOP;
   COMMIT;

   p_nbr_maj_succes := vn_cpt_site_ok;
   p_nbr_maj_echec  := vn_cpt_site_ko;
   IF p_nbr_maj_echec = 0 
   THEN
     p_result_maj :='OK';
   ELSE
     p_result_maj :='KO';
   END IF;

   p_id_liste_erreur := v_action_id;
   p_maj_code_echec := vn_maj_code_echec;

END MAJ_SITE_FOURNISSEUR;

END;

/
SHOW ERRORS
EXIT