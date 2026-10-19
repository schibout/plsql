CREATE OR REPLACE PACKAGE BODY APPS.DKA_SPOODCAP_PKG AS

  ----------------------------------------------------------------------------------------------
  -- $$
  -- CAPGEMINI
  -- PROJET            : DALKIA Oracle Applications
  -- NOM               : DKA_SPOODCAP_PKG.pkb
  -- DESCRIPTION       : DKA_SPOODCAP_PKG package body : package du traitement de génération des CAP pour les commandes multi-sociétés 
  --
  -- AUTEUR            : Oussama BENHAYOUN
  -- DATE DE CREATION  : 23/10/2018
  -- DOC. ASSOCIEE     :
  -- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
  ----------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- ---------- --- -------------------------------------------------------------------------
  --  07/10/2019 YBE artf07147256 : Modification de la selection des lignes a traiter sur
  --                                    les CAP pour les commandes multi-societes
  ---------------------------------------------------------------------------------------------

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PRIVEES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  gn_conc_request_id fnd_concurrent_requests.request_id%TYPE;
  gn_login_id        fnd_logins.login_id%TYPE;
  G_LOG_LEVEL        CONSTANT NUMBER       := FND_LOG.G_CURRENT_RUNTIME_LEVEL;
  G_PKG_NAME         CONSTANT VARCHAR2(30) := 'DKA_SPOODCAP_PKG';
  gb_err_easylink    BOOLEAN               := FALSE;
  gn_count           NUMBER := 0;
  gn_request_id      NUMBER;

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PRIVEES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  
    ---------------------------------------------------------------------------------------------------
  --  Nom           : init
  --  Description   : Procédure d'initialisation du package
  --                  Génère l'entête du fichier de sortie

  --  PARAMETRES    :
  -- gv_je_source_name         Sortie
  -- gv_user_je_source_name    Sortie
  -- pv_errbuf                 Entrée/Sortie      message d'erreur
  -- pn_retcode                Sortie             code de retour: 'o=normal', '1=warning', '2=erreur'
  --  VALEUR RETOURNEE :
  --     N/A
  ----------------------------------------------------------------------------------------------------------
  PROCEDURE init(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER) IS
    v_data   dka_parameters%ROWTYPE;
    vn_dummy NUMBER(15);
    vv_parameter dka_parameters.parameter_name%TYPE := NULL;

  BEGIN


    Dka_Tools_Pkg.put_out_header;

    ----- Initialisation des variables -----
    vn_dummy   := 0;
    pn_retcode := 0;
    pv_errbuf  := NULL;


    gn_conc_request_id := Fnd_Global.conc_request_id;
    gn_login_id        := Fnd_Global.login_id;


  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf  := SQLERRM;
      Dka_Tools_Pkg.put_outdebug_message(pv_errbuf);
      Dka_Tools_Pkg.put_log_message('Fin de la procédure init : EXCEPTION OTHERS ');
  END init;

  ---------------------------------------------------------------------------------------------------
  --  Nom           : update_gl
  --  Description   : Procédure permettant de mettre a jour les CUF au niveau des pieces GL

  --  PARAMETRES    :
  -- pv_errbuf                 Entrée/Sortie      message d'erreur
  -- pn_retcode                Sortie             code de retour: 'o=normal', '1=warning', '2=erreur'
  --  VALEUR RETOURNEE :
  --     N/A
  ----------------------------------------------------------------------------------------------------------
  PROCEDURE update_gl(pn_interface_run_id OUT VARCHAR2,
                      pb_launch_easylink  OUT BOOLEAN,
					  pv_period_name      IN VARCHAR2,
                      pv_errbuf           IN OUT VARCHAR2,
                      pn_retcode          OUT NUMBER) IS

  pn_group_id               NUMBER;
  vn_interface_run_id       NUMBER (15); 
  vv_period_name            VARCHAR2(10);
  
  

  CURSOR cur_gl_je_lines IS
    SELECT distinct
	    gjh.je_header_id,
		gjl.je_line_num,
        gjl.reference_5,
		gjl.entered_dr,
        gjl.entered_cr,
		gjh.ledger_id,
		gjh.currency_code,
		gjh.DEFAULT_EFFECTIVE_DATE,
		SUBSTR(hr.name,4,4) soc_projet,
		SUBSTR(hr.name,1,3) region_projet
    FROM
        gl_je_batches gjb,
        apps.gl_je_headers gjh,
        apps.gl_je_lines gjl,
        apps.gl_code_combinations gcc,
        apps.hr_all_organization_units hr,
        pa_projects_all pa
    WHERE
        1 = 1
        AND  gjb.name LIKE 'PROVISION%' || pv_period_name || '%Cost Management%'
        AND  gjb.je_batch_id = gjh.je_batch_id
        AND  gjh.je_header_id = gjl.je_header_id
        AND  gjl.code_combination_id = gcc.code_combination_id
        AND  gcc.segment8 = pa.segment1
        AND  pa.org_id = hr.organization_id
        AND  (gcc.segment1 != SUBSTR(hr.name,4,4) OR gcc.segment2 != SUBSTR(hr.name,1,3)) -- YBE artf07147256
        AND  gjl.reference_5 IS NOT NULL
		AND  NVL(gjl.attribute2,'N') != 'Y'
        ORDER BY gjh.je_header_id
        ;

  
  BEGIN

    pb_launch_easylink := FALSE;
	
    Dka_Tools_Pkg.put_log_message('update_gl +');
  
    -- Selection du group_id --
    SELECT gl_interface_control_s.NEXTVAL
    INTO   pn_group_id
    FROM   DUAL;   
	
    -- Selection du interface_run_id --
    SELECT gl_journal_import_s.NEXTVAL
    INTO   pn_interface_run_id
    FROM   DUAL;	
	
	-- Récupération de la période courante 
    SELECT period_name
	INTO vv_period_name
    FROM
        gl_period_statuses
    WHERE
        trunc(SYSDATE) BETWEEN trunc(start_date) AND trunc(end_date)
        AND   application_id = 101
        AND   ROWNUM = 1;	
	
	
	-- insertion dans la table gl_interface_control
	Dka_Tools_Pkg.put_log_message('Insertion gl_interface_control');
	
	INSERT INTO gl_interface_control
	(je_source_name,
     status,
     interface_run_id,
     GROUP_ID,
     set_of_books_id,
     packet_id
	) values (
	'Cost Management',
	'S',
	pn_interface_run_id,
	pn_group_id,
	-1,
	NULL);

    
	Dka_Tools_Pkg.put_log_message('Début Insertion des lignes d''annulation et correction dans gl_interface');
	
    FOR rec IN cur_gl_je_lines LOOP
	
	
	  pb_launch_easylink := TRUE;
	  -- Insertion annulation
	  
      insert into gl_interface
      (status,
	  set_of_books_id,
		 ledger_id,
		 accounting_date,
		 currency_code,
		 date_created,
		 created_by,
		 actual_flag,
		 user_je_category_name,
		 user_je_source_name,
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
		 segment12,
		 entered_dr,
		 entered_cr,
		 reference1,
		 GROUP_ID,
		 Attribute11,
         Attribute13,
         Attribute14,
         Attribute17,
         Context3
		 
		)
        SELECT 
		'NEW', -- status,
		rec.ledger_id,
		 rec.ledger_id,
		 TRUNC(rec.DEFAULT_EFFECTIVE_DATE), -- accounting_date,
		 rec.currency_code, -- currency_code,
		 SYSDATE, -- date_created,
		 Fnd_Global.user_id, --created_by,
		 'A', --actual_flag,
		 'Provision',--gv_user_je_category_name, --user_je_category_name,
		 'Cost Management',--gv_user_je_source_name, --user_je_source_name,
		 gcc.segment1,
		 gcc.segment2,
		 gcc.segment3,
		 gcc.segment4,
		 gcc.segment5,
		 gcc.segment6,
		 gcc.segment7,
		 gcc.segment8,
		 gcc.segment9,
		 gcc.segment10,
		 gcc.segment11,
		 gcc.segment12,
		 gjl.entered_cr,
		 gjl.entered_dr,
		 'OD_PROVISION_'|| gll.name ||'_' || pv_period_name,--vv_period_name,
		 pn_group_id,
		 gjl.Attribute11,
         gjl.Attribute13,
         gjl.Attribute14,
         gjl.Attribute17,
         gjl.Context3
		from gl_je_lines gjl,gl_code_combinations gcc, gl_ledgers gll
		where gjl.reference_5 = rec.reference_5
		and gjl.je_header_id = rec.je_header_id
		and gjl.code_combination_id = gcc.code_combination_id
		and gll.ledger_id = rec.ledger_id
		;
		
		gn_count := gn_count + SQL%ROWCOUNT;
		
	  -- Insertion correction	
		
      insert into gl_interface
      (status,
	  set_of_books_id,
		 ledger_id,
		 accounting_date,
		 currency_code,
		 date_created,
		 created_by,
		 actual_flag,
		 user_je_category_name,
		 user_je_source_name,
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
		 segment12,
		 entered_dr,
		 entered_cr,
		 reference1,
		 GROUP_ID,
		 Attribute11,
         Attribute13,
         Attribute14,
         Attribute17,
         Context3
		)
        SELECT 
		'NEW', -- status,
		gll.ledger_id,
		 gll.ledger_id,
		 TRUNC(rec.DEFAULT_EFFECTIVE_DATE), -- accounting_date,
		 'EUR', -- currency_code,
		 SYSDATE, -- date_created,
		 Fnd_Global.user_id, --created_by,
		 'A', --actual_flag,
		 'Provision',--gv_user_je_category_name, --user_je_category_name,
		 'Cost Management',--gv_user_je_source_name, --user_je_source_name,
		 rec.soc_projet,
		 --gcc.segment2,
		 rec.region_projet,
		 gcc.segment3,
		 gcc.segment4,
		 gcc.segment5,
		 gcc.segment6,
		 gcc.segment7,
		 gcc.segment8,
		 gcc.segment9,
		 gcc.segment10,
		 gcc.segment11,
		 gcc.segment12,
		 gjl.entered_dr,
		 gjl.entered_cr, 
		 'OD_PROVISION_'|| gll.name ||'_' || pv_period_name,--vv_period_name,
		 pn_group_id,
		 gjl.Attribute11,
         gjl.Attribute13,
         gjl.Attribute14,
         gjl.Attribute17,
         gjl.Context3
		from gl_je_lines gjl ,gl_code_combinations gcc, gl_ledgers gll
		where gjl.reference_5 = rec.reference_5
		and gjl.je_header_id = rec.je_header_id
		and gjl.code_combination_id = gcc.code_combination_id
		and gll.short_name = rec.soc_projet
		;

        gn_count := gn_count + SQL%ROWCOUNT;   		
    
	
	-- Marquage des lignes
	UPDATE gl_je_lines
	SET attribute2 = 'Y'
	WHERE je_header_id = rec.je_header_id
	AND   je_line_num = rec.je_line_num;
	

    END LOOP;
	
	COMMIT;
	
    Dka_Tools_Pkg.put_log_message('update_gl -');

  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf  := SQLERRM;
      Dka_Tools_Pkg.put_outdebug_message(pv_errbuf);
      Dka_Tools_Pkg.put_debug_message('Fin de la procédure update_gl : EXCEPTION OTHERS ');
  END update_gl;



  -------------------------------------------------------------------------------------------------------------------------------------
  --  Nom           : run_prog_standard
  --  Description   : Procedure de lancement du traitement standard EASYLINK
  --  PARAMETRES    :
  -- pn_group_id              Entrée
  -- pn_interface_run_id       Entrée
  -- pn_request_id            Sortie
  -- pv_errbuf                 Entrée/Sortie    message d'erreur
  -- pn_retcode                Sortie           code de retour: 'o=normal', '1=warning', '2=erreur'

  --  VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  ------------------------------------------------------------------------------------------------------------------------------------------


  PROCEDURE run_prog_standard(pn_interface_run_id  IN NUMBER,
                              pb_launch_easylink   IN BOOLEAN,
                              pv_errbuf      OUT VARCHAR2,
                              pn_retcode     OUT NUMBER) IS

    vv_phase                  VARCHAR2 (100);
    vv_status                 VARCHAR2 (100);
    vv_dev_phase              VARCHAR2 (100);
    vv_name                   VARCHAR2 (100);
    vv_dev_status             VARCHAR2 (100);
    vv_message                VARCHAR2 (100);							  
    vn_request_id             fnd_concurrent_requests.request_id%TYPE;
	vn_responsibility_id      NUMBER;
    vn_application_id         NUMBER;
	vv_responsibility_ref     VARCHAR2(100);


  BEGIN

    Dka_Tools_Pkg.put_log_message('run_prog_standard +');

    ---Initialisation des variables--
    pv_errbuf   := NULL;
    pn_retcode  := 0;
	
	
	IF pb_launch_easylink THEN
	
	vv_responsibility_ref    := 'TOUT_GL_OPE_ADMINISTRATEUR';

    
    SELECT fr.responsibility_id,
           fr.application_id
    INTO   vn_responsibility_id,
           vn_application_id
    FROM   fnd_responsibility fr
    WHERE fr.responsibility_key = vv_responsibility_ref;
    
    fnd_global.apps_initialize (FND_PROFILE.VALUE('USER_ID'), vn_responsibility_id, vn_application_id);      

    Dka_Tools_Pkg.put_log_message('Lancement EasyLink. Interface_run_id : ' || pn_interface_run_id);	
    
    vn_request_id := Fnd_Request.submit_request (
                         'SQLGL', --APPL
                         'GLLEZL', --PROG
                         NULL, --PROGRAM_NAME
                         NULL, --START
                         FALSE, --SUB_REQUEST
                         pn_interface_run_id, --ARGUMENT1
                         FND_PROFILE.value('GL_ACCESS_SET_ID'),
                         --rec.set_of_books_id,               -- OBE
                         --vn_gl_set_of_bks_id, --ARGUMENT2 -- OBE
                         'N', --ARGUMENT3
                         NULL, --ARGUMENT4
                         NULL, --ARGUMENT5
                         'N', --ARGUMENT6
                         'O', --ARGUMENT7
                         'Y'
                     );
	
	
	IF vn_request_id = 0
        THEN
            pn_retcode    := 2;
            Dka_Tools_Pkg.put_log_message(' Le traitement EASYLINK a échoué!');
        ELSE
            COMMIT;
            Dka_Tools_Pkg.put_log_message('vn_request_id: '|| TO_CHAR (vn_request_id));
			gn_request_id := vn_request_id;

            IF NOT (Fnd_Concurrent.wait_for_request (vn_request_id, 60, 0, vv_phase, vv_status, vv_dev_phase, vv_dev_status, vv_message))
            THEN
                Dka_Tools_Pkg.put_log_message('Attente du programme de la fin EASYLINK dépassé : Fin du traitement ');
				pn_retcode    := 2;
            ELSIF (    vv_dev_phase = 'COMPLETE'
                   AND vv_dev_status = 'NORMAL'
                  )
            THEN
                Dka_Tools_Pkg.put_log_message('L''éxécution de EASYLINK OK');
                COMMIT;
			ELSE
                pn_retcode := 2;			
            END IF;
        END IF;	
    
	ELSE
	  Dka_Tools_Pkg.put_log_message('Aucune ligne à traiter. Pas de lancement d''EasyLink.');
	END IF;
	

    Dka_Tools_Pkg.put_log_message('run_prog_standard -');
	
  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf  := 'Fin de la procédure RUN_PROG_STANDARD : EXCEPTION OTHERS ' ||
                    SQLERRM;
      Dka_Tools_Pkg.put_outdebug_message(pv_errbuf);
  END run_prog_standard;



  ---------------------------------------------------------------------------------------------------
  --  Nom           : main
  --  Description   : Procédure principale du specifique SPOODCAP
  --
  --  PARAMETRES    :
  -- pv_errbuf                 Entrée/Sortie      message d'erreur
  -- pn_retcode                Sortie             code de retour: 'o=normal', '1=warning', '2=erreur'
  --  VALEUR RETOURNEE :
  --     N/A
  ----------------------------------------------------------------------------------------------------------
  PROCEDURE main(pv_errbuf  IN OUT VARCHAR2,
                 pn_retcode OUT NUMBER,
				 pv_period_name IN VARCHAR2) IS

    vv_error_message    VARCHAR2(200);
    vn_error_code       NUMBER(15);
	vn_interface_run_id NUMBER;
	vb_launch_easylink        BOOLEAN;

  BEGIN

    Dka_Tools_Pkg.put_log_message('main +');
    vn_error_code := 0;

    /************************** INITIALISATION **************************/
    init(pv_errbuf, pn_retcode);



    DKA_SPOODCAP_PKG.update_gl(vn_interface_run_id,vb_launch_easylink,pv_period_name,vv_error_message,vn_error_code);
    
    Dka_Tools_Pkg.put_log_message('update_gl, code_retour======>' ||
                                    vn_error_code);
    
    IF vn_error_code != 0 THEN
      pn_retcode := 2;
      pv_errbuf  := vv_error_message ||
                    '- Une erreur est survenue dans la procedure update_gl';
    END IF;
	
	
    DKA_SPOODCAP_PKG.run_prog_standard(vn_interface_run_id,vb_launch_easylink,vv_error_message,vn_error_code);
    
    Dka_Tools_Pkg.put_log_message('run_prog_standard, code_retour======>' ||
                                    vn_error_code);
    
    IF vn_error_code != 0 THEN
      pn_retcode := 2;
      pv_errbuf  := vv_error_message ||
                    '- Une erreur est survenue dans la procedure run_prog_standard';
    END IF;	
	
	Fnd_File.put_line (Fnd_File.output, '');
	Fnd_File.put_line (Fnd_File.output, 'Nombre de lignes insérées dans GL_INTERFACE :' || gn_count);
	
	IF vb_launch_easylink THEN
	 Fnd_File.put_line (Fnd_File.output, 'Numéro de traitement EasyLink : ' || gn_request_id);
	ELSE
	 Fnd_File.put_line (Fnd_File.output, 'Pas de traitement EasyLink.');
	END IF;


    Dka_Tools_Pkg.put_log_message('main -');

  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf := 'sortir de main avec erreur avec EXCEPTION OTHERS:' ||
                   SQLERRM;
      Dka_Tools_Pkg.put_outdebug_message(pv_errbuf);
      pn_retcode := 2;
  END main;

END DKA_SPOODCAP_PKG;
/
SHOW ERROR
EXIT;
