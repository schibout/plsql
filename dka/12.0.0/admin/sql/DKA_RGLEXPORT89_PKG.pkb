CREATE OR REPLACE PACKAGE BODY dka_rglexport89_pkg AS
  ----------------------------------------------------------------------------------------------
  -- $Id$
  -- CAPGEMINI
  -- PROJET            : DALKIA Oracle Applications
  -- NOM               : DKA_RGLEXPORT89_PKG.pkb
  -- DESCRIPTION       : DKA_RGLEXPORT89_PKG package body :
  ---
  --- AUTEUR           : Julien Jardez
  --- DATE DE CREATION : 17/12/2013
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
  ----------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  ---------------------------- M O D I F I C A T I O N S -------------------------
  -- Date                : 06/06/2016
  -- Auteur              : Younes WARID
  -- Description         : Migration R12
  --- ---------- --- ---------------------------------------------------------------------------
  --- 06/06/2016 YWA Migration R12
  --- 22/06/2017 YWA artf2180347 
  ----------------------------------------------------------------------------------------------

  --CONSTANTE
  cv_package_name CONSTANT VARCHAR2(30) := 'DKA_RGLEXPORT89_PKG';
  cv_sep          CONSTANT VARCHAR2(1) := ';';

  --CONSTANTE JEU DE VALEUR, TRANSCO ....
  cv_program_name   CONSTANT VARCHAR2(30) := 'IAPARGLCTRLFISCAL';
  cv_param_nb_annee CONSTANT VARCHAR2(30) := 'NB_ANNEE';
  cv_directory      CONSTANT VARCHAR2(30) := 'DKA_OUT_DIR';
  cv_jdv_cpt_local  CONSTANT VARCHAR2(30) := 'DAOPCCF_LOCAL';
  cv_jdv_ste        CONSTANT VARCHAR2(30) := 'DAOPCCF_STE';
  cv_jdv_caract_spe CONSTANT VARCHAR2(30) := 'DKA_CARACTERE_EXTRACT_FISCALE';

  cn_annee_prec    CONSTANT PLS_INTEGER := 1;
  cv_devise        CONSTANT VARCHAR2(10) := 'EUR';
  cv_nom_fichier   CONSTANT VARCHAR2(10) := 'FEC';
  cv_extension     CONSTANT VARCHAR2(10) := '.txt';
  cn_nb_annee      CONSTANT PLS_INTEGER := 1;
  cv_line          CONSTANT VARCHAR2(75) := '+-------------------------------------------------------------------------+';
  cv_compte_loc_cr CONSTANT VARCHAR2(10) := '120000';
  cv_compte_loc_dr CONSTANT VARCHAR2(10) := '119000';

  --VARIABLE GLOBALES
  gn_sob_id          gl_sets_of_books.set_of_books_id%TYPE;
  gn_conc_request_id fnd_concurrent_requests.request_id%TYPE;
  gn_nb_annee        dka_parameters.number_value%TYPE;
  gv_siren           xle_registrations.registration_number%TYPE;
  gv_nom_societe     fnd_flex_values_vl.description%TYPE;
  gv_ligne_entete    VARCHAR2(500);
  gv_out_message     VARCHAR2(4000);
  gn_insert          PLS_INTEGER;
  gn_cpt             PLS_INTEGER;
  gv_step            VARCHAR2(500);

  gd_date_debut DATE;
  gd_date_fin   DATE;
  gv_period     VARCHAR2(10);

  gv_transco_de VARCHAR2(4000);
  gv_transco_a  VARCHAR2(4000);

  gv_desc_cpte_loc_cr VARCHAR2(240);
  gv_desc_cpte_loc_dr VARCHAR2(240);

  --PARAMETRES
  gv_societe   VARCHAR2(10);
  gn_annee_ref NUMBER;
  gn_periode   NUMBER;

  -----------------------------------------------------------------------
  -- GET_TIME
  ----------------------------------------------------------------------
  --  fonction qui retourne la date et l'heure actuelle
  --
  --  Parametres : N/A
  --
  -----------------------------------------------------------------
  FUNCTION get_time RETURN VARCHAR2 IS
  BEGIN
	RETURN to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS');
  END get_time;

  -----------------------------------------------------------------------
  -- TRANSLATE_TEXTE
  ----------------------------------------------------------------------
  --  fonction traduit le texte en fonction des caractères spéciaux
  --
  --  Parametres : N/A
  --
  -----------------------------------------------------------------
  FUNCTION translate_texte(p_texte_to_translate IN VARCHAR2) RETURN VARCHAR2 IS
  
	lv_current_program_unit VARCHAR2(30) := 'translate_texte';
	pv_errbuf               VARCHAR2(500);
  
	l_texte_transcode VARCHAR2(4004);
  
  BEGIN
	gv_step := lv_current_program_unit || ' 000 : DEBUT';
	--dka_tools_pkg.put_debug_message(gv_step);
  
	gv_step := lv_current_program_unit || ' 001 : INIT';
	--dka_tools_pkg.put_debug_message(gv_step);
	l_texte_transcode := p_texte_to_translate;
  
	--On ne traduit que si les paramètres de transco sont alimentés
	IF gv_transco_de IS NOT NULL
	   AND gv_transco_a IS NOT NULL THEN
	
	  gv_step := lv_current_program_unit ||
				 ' 002 : Suppression des blancs en début et fin de texte';
	  --dka_tools_pkg.put_debug_message(gv_step);
	  l_texte_transcode := TRIM(' ' FROM l_texte_transcode);
	
	  gv_step := lv_current_program_unit ||
				 ' 003 : Traduction du texte avec paramètre';
	  --dka_tools_pkg.put_debug_message(gv_step);
	  l_texte_transcode := translate(l_texte_transcode,
									 ' ' || gv_transco_de,
									 ' ' || gv_transco_a);
	
	  gv_step := lv_current_program_unit || ' 004 : l_texte_transcode : ' ||
				 l_texte_transcode;
	  --dka_tools_pkg.put_debug_message(gv_step);
	
	END IF;
  
	gv_step := lv_current_program_unit || ' 999 : FIN';
	--dka_tools_pkg.put_debug_message(gv_step);
  
	RETURN l_texte_transcode;
  
  EXCEPTION
	WHEN OTHERS THEN
	  gv_step := lv_current_program_unit || ' EE1 : ERREUR lors de :' ||
				 gv_step;
	  dka_tools_pkg.put_log_message(gv_step);
	  pv_errbuf := 'Erreur procedure ' || cv_package_name || '.' ||
				   lv_current_program_unit || chr(10) || SQLERRM;
	  dka_tools_pkg.put_log_message(pv_errbuf);
  END translate_texte;

  -----------------------------------------------------------------
  --  Nom           : get_parameters
  --  Description   : procedure d'initialisation
  --
  --  PARAMETRES :
  --   pv_errbuf        OUT NOCOPY VARCHAR2,
  --   pn_retcode       OUT NOCOPY NUMBER
  -----------------------------------------------------------------
  PROCEDURE get_parameters(pv_errbuf    OUT NOCOPY VARCHAR2,
						   pn_retcode   OUT NOCOPY NUMBER,
						   pv_societe   IN VARCHAR2,
						   pn_annee_ref IN NUMBER) IS
  
	lv_current_program_unit VARCHAR2(30) := 'get_parameters';
  
  BEGIN
  
	gv_step := lv_current_program_unit || ' 000 : DEBUT';
	--dka_tools_pkg.put_debug_message(gv_step);
  
	gv_step := lv_current_program_unit ||
			   ' 001 : Affectations aux variables globales';
	--dka_tools_pkg.put_debug_message(gv_step);
  
	gv_societe   := pv_societe;
	gn_annee_ref := pn_annee_ref;
  
	gv_step := lv_current_program_unit || ' 999 : FIN';
	--dka_tools_pkg.put_debug_message(gv_step);
  
  EXCEPTION
	WHEN OTHERS THEN
	  gv_step := lv_current_program_unit || ' EE2 : ERREUR lors de :' ||
				 gv_step;
	  dka_tools_pkg.put_log_message(gv_step);
	  pv_errbuf := 'Erreur procedure ' || cv_package_name || '.' ||
				   lv_current_program_unit || chr(10) || SQLERRM;
	  dka_tools_pkg.put_log_message(pv_errbuf);
	  pn_retcode := 2;
  END get_parameters;

  -----------------------------------------------------------------
  --  Nom           : INIT
  --  Description   : procedure d'initialisation
  --
  --  PARAMETRES :
  --   pv_errbuf        OUT NOCOPY VARCHAR2,
  --   pn_retcode       OUT NOCOPY NUMBER
  -----------------------------------------------------------------
  PROCEDURE init(pv_errbuf  OUT NOCOPY VARCHAR2,
				 pn_retcode OUT NOCOPY NUMBER) IS
  
	lv_current_program_unit VARCHAR2(30) := 'init';
	rec_param               dka_parameters%ROWTYPE;
  
	lv_ligne       VARCHAR2(500);
	ln_annee_debut PLS_INTEGER;
	ln_annee_fin   PLS_INTEGER;
  
	CURSOR c_transco IS
	  SELECT ffvv.flex_value,
			 ffvv.description,
			 ffvv.enabled_flag
	  FROM   fnd_flex_values_vl  ffvv,
			 fnd_flex_value_sets ffvs
	  WHERE  ffvs.flex_value_set_name = cv_jdv_caract_spe
	  AND    ffvs.flex_value_set_id = ffvv.flex_value_set_id
	  AND    SYSDATE BETWEEN nvl(ffvv.start_date_active, SYSDATE) AND
			 nvl(ffvv.end_date_active, SYSDATE)
	  ORDER  BY description ASC,
				ffvv.enabled_flag DESC,
				to_number(ffvv.flex_value) ASC;
  
  BEGIN
  
	gv_step := lv_current_program_unit || ' 000 : DEBUT';
	--dka_tools_pkg.put_debug_message(gv_step);
  
	gv_step := lv_current_program_unit || ' 001 : Init variables';
	--dka_tools_pkg.put_debug_message(gv_step);
  
	--gn_sob_id          := fnd_profile.value('GL_SET_OF_BKS_ID');
	gn_conc_request_id := fnd_global.conc_request_id;
	gn_insert          := 0;
	gn_cpt             := 0;
  
	gv_step := lv_current_program_unit ||
			   ' 002 : Détermination des date début et fin extraction en fonction de la societe';
	--dka_tools_pkg.put_debug_message(gv_step);
  
	SELECT xr.registration_number,
		   gl.ledger_id
	INTO   gv_siren,
		   gn_sob_id
	FROM   xle_registrations   xr,
		   gl_ledgers          gl,
		   xle_entity_profiles xep
	WHERE  xr.source_id = xep.legal_entity_id
	AND    xr.source_table = 'XLE_ENTITY_PROFILES'
	AND    gl.name = xep.name
    AND    gl.ledger_category_code = 'PRIMARY'
	AND    xep.legal_entity_id IN
		   (SELECT DISTINCT default_legal_context_id
			 FROM   hr_operating_units
			 WHERE  NAME LIKE '%' || gv_societe); --YWA
  
	ln_annee_debut := gn_annee_ref /*PARAM*/
					  -cn_nb_annee;
	ln_annee_fin   := gn_annee_ref /*PARAM*/
	 ;
  
	/*SELECT add_months(to_date('01/' || to_char(add_months(to_date(first_ledger_period_name,
																  'MM-YY'),
														  -1),
											   'MM') || '/' ||
							  ln_annee_debut,
							  'dd/mm/yyyy'),
					  1) date_debut,
		   last_day(to_date('01/' || to_char(add_months(to_date(first_ledger_period_name,
																'MM-YY'),
														-1),
											 'MM') || '/' || ln_annee_fin,
							'dd/mm/yyyy')) date_fin,
		   substr(first_ledger_period_name, 1, 3) periode_debut
	INTO   gd_date_debut,
		   gd_date_fin,
		   gv_period
	FROM   gl_ledgers          gl,
		   xle_entity_profiles xep
	WHERE  gl.name = xep.name
	AND    xep.legal_entity_id IN
		   (SELECT DISTINCT default_legal_context_id
			 FROM   hr_operating_units
			 WHERE  NAME LIKE '%' || gv_societe); --YWA*/
  
    SELECT gp_start.start_date,
      gp_end.end_date,
      SUBSTR(first_ledger_period_name, 1, 3) periode_debut
    INTO   gd_date_debut,
           gd_date_fin,
           gv_period
    FROM gl_ledgers gl,
      gl_periods gp_start ,
      gl_periods gp_end
    WHERE gl.SHORT_NAME      = gv_societe
    AND gl.period_set_name   = gp_start.period_set_name
    AND gp_start.period_name = SUBSTR(first_ledger_period_name, 1, 3)
      ||'-'
      ||SUBSTR(DECODE(gp_start.period_set_name,'GROUPE',ln_annee_debut+1,ln_annee_debut), 3, 4)
    AND gl.period_set_name = gp_end.period_set_name
    AND gp_end.period_name = TO_CHAR(add_months(to_date(first_ledger_period_name,'MM-YY'),-1),'MON')
      ||'-'
      ||SUBSTR(ln_annee_fin, 3, 4);--YWA artf2180347 
  
	/*SELECT
       add_months(to_date('01/'||dbc.close_month||'/'||ln_annee_debut,'dd/mm/yyyy'),1) date_debut,
       add_months(to_date('01/'||dbc.close_month||'/'||ln_annee_fin||' 23:59:59','dd/mm/yyyy hh24:mi:ss'),1) -1 date_fin,
       decode(dbc.close_month,'12','JAN','06','JUL') periode_debut
    INTO
       gd_date_debut,
       gd_date_fin,
       gv_period
    FROM   dka_ibdsoc_i00dgic       dii,
           dka_ibdsoc_general_info  digi,
           dka_bdste_comptable      dbc
    WHERE  dii.company_code    = digi.company_code
    AND    dii.company_code    = dbc.company_code
    AND    dii.company_code    = gv_societe
    AND    dbc.effective_date  = ( SELECT MAX(db2.effective_date) FROM dka_bdste_comptable db2 WHERE dbc.company_code = db2.company_code);*/
  
	gv_step := lv_current_program_unit || ' 002 : Date début : ' ||
			   to_char(gd_date_debut, 'dd/mm/yyyy hh24:mi:ss');
	dka_tools_pkg.put_debug_message(gv_step);
	gv_step := lv_current_program_unit || ' 002 : Date fin   : ' ||
			   to_char(gd_date_fin, 'dd/mm/yyyy hh24:mi:ss');
	dka_tools_pkg.put_debug_message(gv_step);
  
	gv_step := 'INIT 003 : Recherche du numéro siren et du nom de la societe';
	--dka_tools_pkg.put_debug_message(gv_step);
  
	SELECT ffvv.description
	INTO   gv_nom_societe
	FROM   fnd_flex_value_sets ffvs,
		   fnd_flex_values_vl  ffvv
	WHERE  ffvs.flex_value_set_id = ffvv.flex_value_set_id
	AND    ffvs.flex_value_set_name = cv_jdv_ste
	AND    ffvv.flex_value = gv_societe;
  
	gv_step := lv_current_program_unit || '003 : ' || gv_siren;
	--dka_tools_pkg.put_debug_message(gv_step);
	gv_step := lv_current_program_unit || '003 : ' || gv_nom_societe;
	--dka_tools_pkg.put_debug_message(gv_step);
  
	gv_step := lv_current_program_unit ||
			   ' 004 : Récupération des paramètres de traduction';
	--dka_tools_pkg.put_debug_message(gv_step);
	FOR c_transco_rec IN c_transco
	LOOP
	  gv_transco_de := gv_transco_de || chr(c_transco_rec.flex_value);
	  IF c_transco_rec.enabled_flag = 'Y'
		 OR c_transco_rec.description IS NOT NULL THEN
		IF c_transco_rec.description = 'SP' THEN
		  gv_transco_a := gv_transco_a || ' ';
		ELSE
		  gv_transco_a := gv_transco_a ||
						  nvl(c_transco_rec.description,
							  chr(c_transco_rec.flex_value));
		END IF;
	  END IF;
	END LOOP;
	gv_step := lv_current_program_unit || ' 004 : transco_de : ' ||
			   gv_transco_de;
	--dka_tools_pkg.put_debug_message(gv_step);
	gv_step := lv_current_program_unit || ' 004 : transco_a  : ' ||
			   gv_transco_a;
	--dka_tools_pkg.put_debug_message(gv_step);
  
	gv_step := lv_current_program_unit || ' 999 : FIN';
	--dka_tools_pkg.put_debug_message(gv_step);
  
  EXCEPTION
	WHEN OTHERS THEN
	  gv_step := lv_current_program_unit || ' EE2 : ERREUR lors de :' ||
				 gv_step;
	  dka_tools_pkg.put_log_message(gv_step);
	  pv_errbuf := 'Erreur procedure ' || cv_package_name || '.' ||
				   lv_current_program_unit || chr(10) || SQLERRM;
	  dka_tools_pkg.put_log_message(pv_errbuf);
	  pn_retcode := 2;
  END init;

  -----------------------------------------------------------------
  --  Nom           : DISPLAY_ECR_GL
  --  Description   : procedure d'affichage des données GL
  --
  --  PARAMETRES :
  --   pv_errbuf        OUT NOCOPY VARCHAR2,
  --   pn_retcode       OUT NOCOPY NUMBER
  -----------------------------------------------------------------
  PROCEDURE display_ecr_gl(pv_errbuf  OUT NOCOPY VARCHAR2,
						   pn_retcode OUT NOCOPY NUMBER) IS
  
	lv_current_program_unit VARCHAR2(30) := 'display_ecr_gl';
	lv_buffer               VARCHAR2(500);
	ln_cpt                  PLS_INTEGER := 0;
	ln_annee_debut          PLS_INTEGER := gn_annee_ref /*PARAM*/
										   -cn_nb_annee /*DKA*/
	 ;
  
	CURSOR c_select IS
	  SELECT *
	  FROM   (SELECT gv_societe societe_code,
					 gv_nom_societe societe_lib,
					 gv_siren siren,
					 gjh.je_category journal_code,
					 gjct.user_je_category_name journal_lib,
					 to_char(gjh.doc_sequence_value) ecriture_num,
					 gp.period_name periode_comptable,
					 gjh.posted_date ecriture_date,
					 nvl(gjl.description, gjh.name) ecriture_lib,
					 gcc.segment3 compte_num,
					 nvl(xal.accounted_dr, 0) debit,
					 nvl(xal.accounted_cr, 0) credit
			  FROM   gl_je_lines          gjl,
					 gl_je_headers        gjh,
					 gl_je_batches        gjb,
					 gl_je_sources_tl     gjst,
					 gl_je_categories_tl  gjct,
					 gl_je_lines_recon    gjlr,
					 gl_code_combinations gcc,
					 gl_ledgers           gl,
					 gl_periods           gp, -- periode comptable
					 gl_period_sets       gps, --calandrier comptable
					 gl_import_references gir, --lien avec xla
					 gl_lookups           glk,
					 --
					 xla_ae_lines             xal,
					 xla_ae_headers           xah,
					 xla_transaction_entities xte,
					 --CPTE LOCAL
					 fnd_flex_value_sets ffvs_loc,
					 fnd_flex_values_vl  ffvv_loc
			  WHERE  gjl.je_header_id = gir.je_header_id
			  AND    gjl.je_line_num = gir.je_line_num
			  AND    gjh.je_header_id = gir.je_header_id
			  AND    gjb.je_batch_id = gir.je_batch_id
			  AND    gjh.je_from_sla_flag IN ('U', 'Y') -- bug 7163158
			  AND    glk.lookup_type = 'BATCH_STATUS'
			  AND    glk.lookup_code = gjb.status
			  AND    gjh.status = 'P'
			  AND    gjlr.je_header_id(+) = gjl.je_header_id -- Added for French audit file ER
			  AND    gjlr.je_line_num(+) = gjl.je_line_num
			  AND    gjct.je_category_name = gjh.je_category
			  AND    gjct.language = 'F'
			  AND    gjst.je_source_name = gjh.je_source --bug12408239
			  AND    gjst.language = 'F' --bug12408239
			  AND    gcc.code_combination_id = gjl.code_combination_id
			  AND    gjh.ledger_id = gl.ledger_id
					-- periode
			  AND    gps.period_set_name = gp.period_set_name
			  AND    gps.zd_edition_name = gp.zd_edition_name
			  AND    gl.period_set_name = gps.period_set_name
              AND    gjh.period_name  = gp.period_name
					-----
			  AND    gir.gl_sl_link_id = xal.gl_sl_link_id
			  AND    gir.gl_sl_link_table = xal.gl_sl_link_table
			  AND    xal.ae_header_id = xah.ae_header_id
			  AND    xte.application_id = xah.application_id
			  AND    xal.application_id = xah.application_id
			  AND    xte.entity_id = xah.entity_id
					
					--CPTE LOCAL
			  AND    ffvv_loc.flex_value_set_id = ffvs_loc.flex_value_set_id
			  AND    ffvs_loc.flex_value_set_name = 'DAOPCCF_LOCAL'
			  AND    ffvv_loc.flex_value = gcc.segment3
			  AND    substr(gcc.segment3, 1, 1) IN ('8', '9')
					--param
			  AND    gcc.segment1 = gv_societe
			  AND    gjh.default_effective_date BETWEEN gd_date_debut AND
					 gd_date_fin
			  AND    gl.ledger_id = gn_sob_id
			 -- AND    gjh.currency_code = cv_devise
			  -----------------
			  UNION ALL
			  -----------------
			  SELECT gv_societe societe_code,
					 gv_nom_societe societe_lib,
					 gv_siren siren,
					 '0' journal_code,
					 'Journal ouverture' journal_lib,
					 substr(to_char(v.period_year), -2) || '0000001' ecriture_num,
					 v.period_name periode_comptable,
					 to_date('01/' || lpad(v.period_num, 2, '0') || '/' ||
							 v.period_year,
							 'dd/mm/yyyy') ecriture_date,
					 'Report à nouveau compte ' || v.segment3 ecriture_lib,
					 v.segment3 compte_num,
					 CASE
					   WHEN v.somme_period_net_dr > v.somme_period_net_cr THEN
						(v.somme_period_net_dr - v.somme_period_net_cr)
					   ELSE
						0
					 END debit,
					 CASE
					   WHEN v.somme_period_net_cr > v.somme_period_net_dr THEN
						(v.somme_period_net_cr - v.somme_period_net_dr)
					   ELSE
						0
					 END credit
			  FROM   (SELECT gcc.segment3,
							  gb.period_name,
							  gb.period_num,
							  gb.period_year,
							  SUM(begin_balance_dr) somme_period_net_dr,
							  SUM(begin_balance_cr) somme_period_net_cr
					   FROM   gl_balances          gb,
							  gl_code_combinations gcc,
							  fnd_flex_value_sets  ffvs,
							  fnd_flex_values_vl   ffv
					   WHERE 
					   --GB
						--gb.currency_code = cv_devise YWA
					      gb.ledger_id = gn_sob_id --ywa
					 AND    gb.actual_flag = 'A'
					   --GCC
					 AND    gb.code_combination_id = gcc.code_combination_id
					 AND    gcc.detail_posting_allowed_flag = 'Y'
					   --FFV
					 AND    gcc.segment3 = ffv.flex_value
					 AND    ffvs.flex_value_set_id = ffv.flex_value_set_id
					 AND    ffvs.flex_value_set_name = cv_jdv_cpt_local
					 AND    substr(gcc.segment3, 1, 1) IN ('8', '9')
					   --
					 AND    gb.period_name =
						gv_period || '-' ||
						substr(to_char(ln_annee_debut) + 1, -2)
					 AND    gcc.segment1 = gv_societe
					   GROUP  BY gcc.segment3,
								 gb.period_name,
								 gb.period_num,
								 gb.period_year) v,
					 --CPTE LOCAL
					 fnd_flex_value_sets ffvs_loc,
					 fnd_flex_values_vl  ffvv_loc
			  WHERE  v.somme_period_net_dr != v.somme_period_net_cr
					--CPTE LOCAL
			  AND    ffvv_loc.flex_value_set_id = ffvs_loc.flex_value_set_id
			  AND    ffvs_loc.flex_value_set_name = cv_jdv_cpt_local
			  AND    ffvv_loc.flex_value = v.segment3) v_data
	  ORDER  BY ecriture_date,
				journal_code,
				ecriture_num;
  
  BEGIN
  
	gv_step := lv_current_program_unit || ' 000 : DEBUT';
	--dka_tools_pkg.put_debug_message(gv_step);
  
	gv_step := lv_current_program_unit || ' 001 : AFFICHAGE DES ENTETES';
	dka_tools_pkg.put_log_message(gv_step);
  
	lv_buffer := 'Code société' || cv_sep || 'Nom société' || cv_sep ||
				 'N° Siren de la société' || cv_sep || 'Code journal' ||
				 cv_sep || 'Libellé journal' || cv_sep || 'N° Document' ||
				 cv_sep || 'Période' || cv_sep || 'Date' || cv_sep ||
				 'Libellé pièce GL' || cv_sep || 'Compte comptable' ||
				 cv_sep || 'Montant Débit' || cv_sep || 'Montant Crédit' ||
				 cv_sep;
	fnd_file.put_line(fnd_file.output, lv_buffer);
  
	gv_step := lv_current_program_unit || ' 002 : AFFICHAGE DES DONNEES';
	dka_tools_pkg.put_log_message(gv_step);
  
	FOR ligne IN c_select
	LOOP
	  lv_buffer := ligne.societe_code || cv_sep ||
				   translate_texte(ligne.societe_lib) || cv_sep ||
				   ligne.siren || cv_sep || ligne.journal_code || cv_sep ||
				   translate_texte(ligne.journal_lib) || cv_sep ||
				   ligne.ecriture_num || cv_sep || ligne.periode_comptable ||
				   cv_sep || to_char(ligne.ecriture_date, 'yyyymmdd') ||
				   cv_sep || translate_texte(ligne.ecriture_lib) || cv_sep ||
				   ligne.compte_num || cv_sep ||
				   to_char(ligne.debit, 'FM999999999999990D00') || cv_sep ||
				   to_char(ligne.credit, 'FM999999999999990D00') || cv_sep;
	
	  fnd_file.put_line(fnd_file.output, lv_buffer);
	
	  ln_cpt := ln_cpt + 1;
	
	END LOOP;
  
	gv_step := lv_current_program_unit || ' 003 : Nb de ligne affichée : ' ||
			   ln_cpt;
	dka_tools_pkg.put_log_message(gv_step);
  
	IF ln_cpt = 0 THEN
	  pn_retcode := 1;
	  pv_errbuf  := 'Pas de données extraites...';
	END IF;
  
	gv_step := lv_current_program_unit || ' 999 : FIN';
	--dka_tools_pkg.put_debug_message(gv_step);
  
  EXCEPTION
	WHEN OTHERS THEN
	  ROLLBACK;
	  gv_step := lv_current_program_unit || ' EE1 : ERREUR lors de :' ||
				 gv_step;
	  dka_tools_pkg.put_log_message(gv_step);
	  pv_errbuf := 'Erreur procedure ' || cv_package_name || '.' ||
				   lv_current_program_unit || chr(10) || SQLERRM;
	  dka_tools_pkg.put_log_message(pv_errbuf);
	  pn_retcode := 2;
  END display_ecr_gl;

  -----------------------------------------------------------------
  --  Nom           : AFFICHAGE_FICHIER_SORTIE
  --  Description   : procedure d'écriture dans le fichier de sortie
  --                  du traitement
  --
  --  PARAMETRES :
  --   pv_errbuf        OUT NOCOPY VARCHAR2,
  --   pn_retcode       OUT NOCOPY NUMBER
  -----------------------------------------------------------------
  PROCEDURE affichage_fichier_sortie(pv_errbuf  OUT NOCOPY VARCHAR2,
									 pn_retcode OUT NOCOPY NUMBER) IS
  
	lv_current_program_unit VARCHAR2(30) := 'affichage_fichier_sortie';
  
  BEGIN
  
	gv_step := lv_current_program_unit || ' 000 : DEBUT';
	--dka_tools_pkg.put_debug_message(gv_step);
  
	dka_tools_pkg.put_outdebug_message(cv_line || chr(10));
	dka_tools_pkg.put_outdebug_message('Nom du traitement    :' ||
									   'Liste des pièces GL avec comptes comptable 8 ou 9');
	dka_tools_pkg.put_outdebug_message('Code du traitement   :' ||
									   cv_program_name);
	dka_tools_pkg.put_outdebug_message('Numéro du traitement :' ||
									   fnd_global.conc_request_id);
	dka_tools_pkg.put_outdebug_message(cv_line || chr(10));
  
	dka_tools_pkg.put_outdebug_message('Date et heure système : ' ||
									   to_char(SYSDATE,
											   'DD/MM/YYYY HH24:MI:SS'));
	dka_tools_pkg.put_outdebug_message(cv_line || chr(10));
  
	dka_tools_pkg.put_outdebug_message('SOCIETE :' || gv_societe);
	dka_tools_pkg.put_outdebug_message('ANNEE   :' || gn_annee_ref);
	dka_tools_pkg.put_outdebug_message(cv_line || chr(10));
  
	gv_step := lv_current_program_unit || ' 999 : FIN';
	--dka_tools_pkg.put_debug_message(gv_step);
  
  EXCEPTION
	WHEN OTHERS THEN
	  gv_step := lv_current_program_unit || ' EE1 : ERREUR lors de :' ||
				 gv_step;
	  dka_tools_pkg.put_log_message(gv_step);
	  pv_errbuf := 'Erreur procedure ' || cv_package_name || '.' ||
				   lv_current_program_unit || chr(10) || SQLERRM;
	  dka_tools_pkg.put_log_message(pv_errbuf);
	  pn_retcode := 2;
  END affichage_fichier_sortie;

  ------------------------------------------------------------------------------------
  --  Nom           : main
  --  Description   : point d'entrée du traitement
  --
  --  PARAMETRES    :
  -- Parametres
  --  pv_errbuf             message d'erreur si pn_retcode != 0
  --  pn_retcode            code de sortie (0 : normal, 1 : warning,2 : erreur)
  --  pv_societe            Societe
  --  pn_annee_ref          Année de référence
  --
  ------------------------------------------------------------------------------------
  PROCEDURE main(pv_errbuf    OUT NOCOPY VARCHAR2,
				 pn_retcode   OUT NOCOPY NUMBER,
				 pv_societe   IN VARCHAR2,
				 pn_annee_ref IN NUMBER) IS
  
	lv_current_program_unit VARCHAR2(30) := 'main';
  
	--EXCEPTION
	e_init EXCEPTION;
	e_param EXCEPTION;
	e_display EXCEPTION;
	e_affichage_sortie EXCEPTION;
  
  BEGIN
  
	pn_retcode := 0;
	pv_errbuf  := NULL;
  
	----------------------------------------------------------------
	--RECUPERATION DES PARAMETRES
	----------------------------------------------------------------
	dka_tools_pkg.put_log_message(cv_line);
	dka_tools_pkg.put_log_message('Recuperation des parametres');
	dka_tools_pkg.put_log_message(cv_line);
  
	dka_tools_pkg.put_log_message('Debut : ' || get_time);
  
	--procedure de recuperation des parametres
	get_parameters(pv_errbuf, pn_retcode, pv_societe, pn_annee_ref);
	IF pn_retcode = 2 THEN
	  RAISE e_param;
	END IF;
  
	dka_tools_pkg.put_log_message('Recuperation des parametres OK...');
	dka_tools_pkg.put_log_message('Fin   : ' || get_time);
  
	----------------------------------------------------------------
	--INITIALISATION DU TRAITEMENT
	----------------------------------------------------------------
	dka_tools_pkg.put_log_message(cv_line);
	dka_tools_pkg.put_log_message('Initialisation');
	dka_tools_pkg.put_log_message(cv_line);
  
	dka_tools_pkg.put_log_message('Debut : ' || get_time);
  
	--procedure de initialisation
	init(pv_errbuf, pn_retcode);
	IF pn_retcode = 2 THEN
	  RAISE e_init;
	END IF;
  
	dka_tools_pkg.put_log_message('Initialisation OK...');
	dka_tools_pkg.put_log_message('Fin   : ' || get_time);
  
	----------------------------------------------------------------
	--AFFICHAGE DANS LE FICHIER DE SORTIE
	----------------------------------------------------------------
	dka_tools_pkg.put_log_message(cv_line);
	dka_tools_pkg.put_log_message('Affichage dans le fichier de sortie');
	dka_tools_pkg.put_log_message(cv_line);
  
	dka_tools_pkg.put_log_message('Debut : ' || get_time);
  
	--procedure d'affichage dans le fichier de sortie
	affichage_fichier_sortie(pv_errbuf, pn_retcode);
	IF pn_retcode = 2 THEN
	  RAISE e_affichage_sortie;
	END IF;
  
	dka_tools_pkg.put_log_message('Affichage dans le fichier de sortie OK...');
	dka_tools_pkg.put_log_message('Fin   : ' || get_time);
  
	----------------------------------------------------------------
	--AFFICHAGE DONNÉES GL
	----------------------------------------------------------------
	dka_tools_pkg.put_log_message(cv_line);
	dka_tools_pkg.put_log_message('Affichage données GL');
	dka_tools_pkg.put_log_message(cv_line);
  
	dka_tools_pkg.put_log_message('Debut : ' || get_time);
  
	--procedure d'affichage donnée
	display_ecr_gl(pv_errbuf, pn_retcode);
	IF pn_retcode = 2 THEN
	  RAISE e_display;
	END IF;
  
	dka_tools_pkg.put_log_message(chr(9) || 'Affichage données GL OK...');
	dka_tools_pkg.put_log_message('Fin   : ' || get_time);
  
  EXCEPTION
	WHEN e_init THEN
	  gv_step := lv_current_program_unit || ' EE1 : ERREUR lors de :' ||
				 gv_step;
	  dka_tools_pkg.put_log_message(gv_step);
	  pv_errbuf := 'Erreur procedure ' || cv_package_name || '.' ||
				   lv_current_program_unit || chr(10) || SQLERRM;
	  dka_tools_pkg.put_log_message(pv_errbuf);
	  pn_retcode := 2;
	WHEN e_param THEN
	  gv_step := lv_current_program_unit || ' EE2 : ERREUR lors de :' ||
				 gv_step;
	  dka_tools_pkg.put_log_message(gv_step);
	  pv_errbuf := 'Erreur procedure ' || cv_package_name || '.' ||
				   lv_current_program_unit || chr(10) || SQLERRM;
	  dka_tools_pkg.put_log_message(pv_errbuf);
	  pn_retcode := 2;
	WHEN e_affichage_sortie THEN
	  gv_step := lv_current_program_unit || ' EE2 : ERREUR lors de :' ||
				 gv_step;
	  dka_tools_pkg.put_log_message(gv_step);
	  pv_errbuf := 'Erreur procedure ' || cv_package_name || '.' ||
				   lv_current_program_unit || chr(10) || SQLERRM;
	  dka_tools_pkg.put_log_message(pv_errbuf);
	  pn_retcode := 2;
	WHEN e_display THEN
	  gv_step := lv_current_program_unit || ' EE3 : ERREUR lors de :' ||
				 gv_step;
	  dka_tools_pkg.put_log_message(gv_step);
	  pv_errbuf := 'Erreur procedure ' || cv_package_name || '.' ||
				   lv_current_program_unit || chr(10) || SQLERRM;
	  dka_tools_pkg.put_log_message(pv_errbuf);
	  pn_retcode := 2;
	WHEN OTHERS THEN
	  gv_step := lv_current_program_unit || ' EEE : ERREUR lors de :' ||
				 gv_step;
	  dka_tools_pkg.put_log_message(gv_step);
	  pv_errbuf := 'Erreur procedure ' || cv_package_name || '.' ||
				   lv_current_program_unit || chr(10) || SQLERRM;
	  dka_tools_pkg.put_log_message(pv_errbuf);
	  pn_retcode := 2;
  END main;

END dka_rglexport89_pkg;
/

SHOW ERROR PACKAGE BODY DKA_RGLEXPORT89_PKG;
EXIT
