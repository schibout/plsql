CREATE OR REPLACE PACKAGE BODY dka_sglcloture_pkg
AS

---------------------------------------------------------------------------------------------------------------
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SGLCLOTURE_PKG.pkb
-- DESCRIPTION       : traitement de la clôture des traitements GL
---
--- AUTEUR           : Guillaume Chabrier
--- DATE DE CREATION : 11/06/2002
--- DOC. ASSOCIEE    :
--  COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--  15/07/2002 MSF ModIFication du message dans le journal
--  12/12/2003 XD  MAIN : Ne plus lancer le traitement de contrepassation
--  22/01/2004 AD  MAIN : Lancement du programme Open New Account Period pour l'entité légale.
--                        Ajout du paramètre ENTITE_LEGALE_AU_30/06 dans DKA_PARAMETERS.
--  03/05/2017 OBE artf2148176 : SPE045 : Cloture GL sur OCT-16 : Aucune configuration trouvée
--  06/06/2017 OBE artf2169708 : SPE045 : Cloture GL - suppression des références aux livres de restitution 
--  12/06/2017 OBE artf2172203 : DKA Clôture de la période GL - Ne ferme pas forcément les périodes les plus anciennes -Defect Beb#759
--  15/06/2017 YWA artf2151091 : SPE045 : Cloture GL : Amélioration des logs /artf2149693 : SPE045 : Cloture GL : Parallélisation de la cloture des sociétés 
--  09/11/2017 NBO artf2274387: SPE045 - Clôture de la période GL - Pb lié livre RESTIT - RUN6
---------------------------------------------------------------------------------------------------------------
gb_relance boolean;
--YWA artf2149693
g_cpt_close INTEGER := 0;
TYPE g_num_traitement_close IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
g_num_trait_list_close g_num_traitement_close;
g_cpt_open INTEGER :=0;
TYPE g_num_traitement_open IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
g_num_trait_list_open g_num_traitement_open;



  -------------------------------------------------------------------------------------------------------------------
--  Nom           : GET_CONFIGURATION_ID
--  Description   : Retourne l'id de configuration d'un livre primaire
--
--  PARAMETRES    :
--     pn_sob_id  number
--
--  VALEUR RETOURNEE :
--     pn_restit_id NUMBER
-------------------------------------------------------------------------------------------------------------------
function get_configuration_id(
    pn_sob_id    IN NUMBER

)return number
IS
  pn_configuration NUMBER;
  vn_not_found NUMBER;
  BEGIN
  dka_tools_pkg.put_log_message(TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||' - ' || 'Debut Fonction get_configuration_id');  
  vn_not_found:= -1;
    SELECT DISTINCT glconfig.configuration_id INTO pn_configuration
          FROM gl_ledger_configurations glconfig,
               gl_ledger_config_details glcd,
               gl_ledgers               ledgers,
               gl_lookups               gllookups,
               gl_lookups               gllookups2
         WHERE /*upper(ledgers.NAME) LIKE upper(:1)
           AND*/ glconfig.configuration_id = ledgers.configuration_id
           AND glconfig.configuration_id <> -1
           AND glconfig.configuration_id <> -2
           AND glcd.configuration_id = glconfig.configuration_id
           AND glcd.object_type_code = 'PRIMARY'
           AND glcd.setup_step_code = 'NONE'


           AND gllookups.lookup_type = 'GL_ASF_CFG_STATUS_CODES'
           AND gllookups.lookup_code = decode(glconfig.completion_status_code,
                                              'CONFIRMED',
                                              decode(ledgers.ledger_category_code,
                                                     'SECONDARY',
                                                     decode(ledgers.complete_flag,
                                                            'N',
                                                            'IN_PROGRESS',
                                                            glconfig.completion_status_code),
                                                     glconfig.completion_status_code),
                                              glconfig.completion_status_code)
           AND gllookups2.lookup_type = 'GL_ASF_LEDGER_CATEGORY'
           AND gllookups2.lookup_code = ledgers.ledger_category_code
           --AND gllookups2.meaning='Livre principal' -- OBE artf2148176
           AND gllookups2.lookup_code = 'PRIMARY'     -- OBE artf2148176
           AND ledgers.ledger_id=pn_sob_id;
	   dka_tools_pkg.put_debug_message('L''id de configuration a été trouvé : '||pn_configuration);
	dka_tools_pkg.put_log_message(TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||' - ' || 'Fin Fonction get_configuration_id');  
    RETURN pn_configuration;
    EXCEPTION
    WHEN NO_DATA_FOUND
    THEN
     dka_tools_pkg.put_log_message('Aucune configuration trouvée');
 

      RETURN vn_not_found;


    WHEN OTHERS
    THEN
	  dka_tools_pkg.put_log_message(TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||' - ' || 'Fin Fonction get_configuration_id suite à une exception');  
	    dka_tools_pkg.put_log_message(SQLERRM);

      RETURN vn_not_found;
  END get_configuration_id;



-------------------------------------------------------------------------------------------------------------------
--  Nom           : GET_LEGAL
--  Description   : Recherche le livre légal associé à un livre primaire
--
--  PARAMETRES    :
--     pn_sob_id  number
--
--  VALEUR RETOURNEE :
--     pn_restit_id NUMBER
-------------------------------------------------------------------------------------------------------------------
   FUNCTION get_legal(
    pn_sob_id    IN NUMBER) RETURN NUMBER
  IS
    vv_sledger_name    VARCHAR2(200);
    pn_legal_id     NUMBER;
    vn_not_found NUMBER;
  
    BEGIN
    vn_not_found:= -1;
	dka_tools_pkg.put_log_message(TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||' - ' || 'Debut de fonction get_legal');  

   
	  SELECT glr.target_ledger_name, target_ledger_id
	  INTO   vv_sledger_name, pn_legal_id
    FROM gl_ledger_relationships glr, gl_ledgers gl
   WHERE glr.TARGET_LEDGER_CATEGORY_CODE = 'SECONDARY'
     --AND gl.short_name = '0802'
     AND glr.source_ledger_id = pn_sob_id
     AND glr.source_ledger_id = gl.ledger_id
     AND glr.RELATIONSHIP_TYPE_CODE ='JOURNAL'                    
     AND glr.RELATIONSHIP_ENABLED_FLAG ='Y' ;

  dka_tools_pkg.put_debug_message('Livre secondaire récupéré LEGAL : '||vv_sledger_name);
  dka_tools_pkg.put_log_message(TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||' - ' || 'Fin de fonction get_legal');  
    RETURN pn_legal_id;

  
  EXCEPTION
  WHEN NO_DATA_FOUND
  THEN
    dka_tools_pkg.put_log_message('Aucun livre secondaire LEGAL trouvé');

    RETURN vn_not_found;

  WHEN OTHERS
    THEN
		dka_tools_pkg.put_log_message(TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||' - ' || 'Fin de fonction get_legal suite à une exception');  

   dka_tools_pkg.put_debug_message(SUBSTR (SQLERRM, 1, 250));
    RETURN vn_not_found;
  END get_legal;



-------------------------------------------------------------------------------------------------------------------
--  Nom           : GET_RESTIT
--  Description   : Recherche le livre de type restit associé à un livre primaire
--
--  PARAMETRES    :
--     pn_sob_id  number
--
--  VALEUR RETOURNEE :
--     pn_restit_id NUMBER
--     pv_errbuf  varchar2
--     pn_retcode   number
-------------------------------------------------------------------------------------------------------------------
   FUNCTION get_restit(
    pn_sob_id    IN NUMBER) RETURN NUMBER
  IS
    vv_sledger_name    VARCHAR2(200);
    vn_restit_id     NUMBER;
    vn_not_found  NUMBER;

    BEGIN
    vn_not_found:= -1;
	dka_tools_pkg.put_log_message(TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||' - ' || 'Début de la fonction get_restit');  

	  SELECT glr.target_ledger_name, target_ledger_id
	  INTO   vv_sledger_name, vn_restit_id
    FROM gl_ledger_relationships glr, gl_ledgers gl
   WHERE glr.TARGET_LEDGER_CATEGORY_CODE = 'SECONDARY'
     --AND gl.short_name = '0802'
     AND glr.source_ledger_id = pn_sob_id
     AND glr.source_ledger_id = gl.ledger_id
     AND glr.RELATIONSHIP_TYPE_CODE ='BALANCE'                    
     AND glr.RELATIONSHIP_ENABLED_FLAG ='Y' ;
	 
  dka_tools_pkg.put_debug_message('Livre secondaire récupéré(RESTIT) : '||vv_sledger_name);
	dka_tools_pkg.put_log_message(TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||' - ' || 'Fin de la fonction get_restit');  

  RETURN vn_restit_id;
  EXCEPTION
  WHEN NO_DATA_FOUND
  THEN
   dka_tools_pkg.put_log_message('Aucun livre secondaire RESTIT trouvé');
	--dka_tools_pkg.put_log_message(TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||' - ' || 'Fin de la fonction get_restit suite à une exception(No data found)');  

    RETURN vn_not_found;

  WHEN OTHERS
    THEN
	dka_tools_pkg.put_log_message(TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||' - ' || 'Fin de la fonction get_restit suite à une exception');  
	dka_tools_pkg.put_debug_message(SUBSTR (SQLERRM, 1, 250));

    RETURN vn_not_found;

  END get_restit;




-------------------------------------------------------------------------------------------------------------------
--  Nom           : PERIOD_TO_CLOSE
--  Description   : Recherche la période à fermer pour une application
--
--  PARAMETRES    :
--     pn_sob_id  number
--
--  VALEUR RETOURNEE :
--     pv_errbuf  varchar2
--     pd_start_date    date
--     pd_END_date   date
--     pd_period_name   varchar2
-------------------------------------------------------------------------------------------------------------------
   PROCEDURE period_to_close (
	pv_period_name   OUT      VARCHAR2,
	pv_errbuf        OUT      VARCHAR2,
	pn_retcode       OUT      NUMBER
   )
   IS
   vn_nb_ledger NUMBER;
   vn_nb_ledger_ouvert NUMBER;
   BEGIN
    pn_retcode:=0;
	dka_tools_pkg.put_log_message(TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||' - '||'Lancement de la procédure de détermination de la période à fermer (period_to_close)');
	
  --< OBE artf2172203
  /*
	SELECT distinct period_name 
	INTO pv_period_name
	FROM gl_period_statuses 
	WHERE application_id=101 
	AND start_date = (SELECT max(start_date) FROM gl_period_statuses WHERE application_id=101 AND closing_status='O');
	--Récupération du nombre de livres qui sont concernés par le jeu de livre (livres primaires + livres secondaires associés)
	
	select count(*) INTO vn_nb_ledger from gl_ledger_relationships where RELATIONSHIP_ENABLED_FLAG = 'Y'and relationship_type_code <> 'BALANCE' and SOURCE_LEDGER_ID IN (SELECT   gl.ledger_id AS ledger_id
	FROM     gl_access_set_assignments gasa, gl_ledgers gl
	WHERE    access_set_id = Fnd_Profile.VALUE ('GL_ACCESS_SET_ID')
	AND      gl.ledger_id = gasa.ledger_id
	AND      gl.ledger_category_code = 'PRIMARY' );
   
	--SELECT count(*) INTO vn_nb_ledger FROM gl_ledgers WHERE ledger_category_code IN ('SECONDARY','PRIMARY'); 
	
	SELECT count(*) INTO vn_nb_ledger_ouvert 
	FROM gl_period_statuses
	WHERE application_id=101
	AND period_name=pv_period_name
	AND closing_status='O'
	AND ledger_id
	IN(select ledger_id from gl_ledger_relationships where RELATIONSHIP_ENABLED_FLAG = 'Y' and relationship_type_code <> 'BALANCE' and SOURCE_LEDGER_ID  IN (SELECT   gl.ledger_id AS ledger_id
		FROM     gl_access_set_assignments gasa, gl_ledgers gl
		WHERE    access_set_id = Fnd_Profile.VALUE ('GL_ACCESS_SET_ID')
		AND      gl.ledger_id = gasa.ledger_id
		AND      gl.ledger_category_code = 'PRIMARY' ));
	IF vn_nb_ledger <> vn_nb_ledger_ouvert 
	THEN	--Tous les livres ne sont pas ouverts à la même date, le script a donc été lancé dans des conditions normal.
		SELECT distinct period_name
		INTO pv_period_name
		FROM gl_period_statuses
		WHERE application_id=101 
		AND END_date =(SELECT distinct start_date FROM gl_period_statuses WHERE period_name=pv_period_name )-1;--(SELECT distinct start_date FROM gl_period_statuses WHERE period_name=pv_period_name )-1
		gb_relance:=true;
	END IF;
  */
  
  SELECT DISTINCT period_name
  INTO pv_period_name
  FROM gl_period_statuses
  WHERE application_id=101
  AND start_date      =
    (SELECT MIN(start_date)
    FROM gl_period_statuses
    WHERE application_id=101
    AND closing_status  ='O'
    AND ledger_id      IN
      (SELECT gl.ledger_id AS ledger_id
      FROM gl_access_set_assignments gasa,
        gl_ledgers gl
      WHERE access_set_id         = Fnd_Profile.VALUE ('GL_ACCESS_SET_ID')
      AND gl.ledger_id            = gasa.ledger_id
      AND gl.ledger_category_code = 'PRIMARY'
      )
    )
  AND ledger_id 
    IN
    (SELECT gl.ledger_id AS ledger_id
    FROM gl_access_set_assignments gasa,
      gl_ledgers gl
    WHERE access_set_id         = Fnd_Profile.VALUE ('GL_ACCESS_SET_ID')
    AND gl.ledger_id            = gasa.ledger_id
    AND gl.ledger_category_code = 'PRIMARY'
    )
    ;   
  
  --> OBE artf2172203
  
		dka_tools_pkg.put_log_message(TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||' - '||'Fin Procédure//La période déterminée est la période : '|| pv_period_name);

   EXCEPTION
      WHEN OTHERS
      THEN
		 dka_tools_pkg.put_debug_message(TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS')||'Fin de la procédure period_to_close suite à une exception: '||SQLERRM );

         pv_errbuf := SUBSTR (SQLERRM, 1, 250);
         pn_retcode := 2;
   END;
   
   
-------------------------------------------------------------------------------------------------------------------
--  Nom           : PERIOD_TO_OPEN
--  Description   : Recherche la période suivante
--
--  PARAMETRES    :
--     pn_sob_id  number
--     pv_period_name   varchar2
--
--  VALEUR RETOURNEE :
--     pv_errbuf  varchar2
--     pd_start_date    date
--     pd_END_date   date
--     pd_period_name   varchar2
-------------------------------------------------------------------------------------------------------------------
   PROCEDURE period_to_open (
	  pv_period_name_close		IN VARCHAR2,
      pv_period_name_open  OUT   VARCHAR2,
      pv_errbuf        OUT      VARCHAR2,
      pn_retcode       OUT      NUMBER
   )
   IS
	  pv_next_status        VARCHAR2 (1);
   BEGIN
	pn_retcode:=0;
		dka_tools_pkg.put_log_message('Lancement de la procédure period_to_open');	

      pv_errbuf := NULL;
      -- Recherche de la période suivante à ouvrir
	SELECT period_name ,closing_status
	INTO pv_period_name_open,pv_next_status
	FROM gl_period_statuses
	WHERE start_date IN (SELECT   END_date
						   + 1
					  FROM gl_period_statuses
					 WHERE period_name = pv_period_name_close
					   AND application_id = 101)
	AND application_id = 101
	AND ROWNUM = 1;
      dka_tools_pkg.put_debug_message (
            'pv_period_name / pv_next_status : '
         || pv_period_name_open
         || ' / '
         || pv_next_status
      );
      -- Recherche du statut de la periode suivante
      dka_tools_pkg.put_debug_message (
         'Cherche statut de la période suivante'
      );
	  dka_tools_pkg.put_debug_message('La période a ouvrir est la période : '||pv_period_name_open);	

      IF pv_next_status = 'O'
      THEN
         pn_retcode := 1;
         dka_tools_pkg.put_debug_message (
            'Status_next_periode = Opened / retcode = 1');
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         pv_errbuf := SUBSTR (SQLERRM, 1, 250);
         pn_retcode := 2;
		 dka_tools_pkg.put_log_message('Fin de la procédure period_to_open causé par une exception');
   END;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : CONSOLIDATION_RESTIT
--  Description   : Recherche la période suivante
--
--  PARAMETRES    :
--	pv_period_to_close VARCHAR2,
--	pn_restit_id NUMBER,
--	pv_errbuf  IN OUT VARCHAR2,
--	pn_retcode    OUT NUMBER
--
--  VALEUR RETOURNEE :
--     pv_errbuf  varchar2
--     pd_start_date    date
--	pv_errbuf  IN OUT VARCHAR2,
--	pn_retcode    OUT NUMBER
------------------------------------------------------------------------------------------------------------------

PROCEDURE CONSOLIDATION_RESTIT (pv_period_to_close VARCHAR2,
pn_restit_id NUMBER,
pv_errbuf  IN OUT VARCHAR2,
pn_retcode    OUT NUMBER)

IS
vv_phase VARCHAR2(50);
vv_dev_phase VARCHAR2(50);
vv_status VARCHAR2(50);
vv_dev_status VARCHAR2(50);
vv_message VARCHAR2(500);
OPEN_FAILED Exception;
req_id number;
consolidation_run_id NUMBER;
vd_date_period VARCHAR2(50);
vn_consolidation_id gl_consolidation_v.consolidation_id%type;
vv_type_montant varchar2(4);
   BEGIN
   pn_retcode:=0;
   vv_type_montant:='PTD';
   dka_tools_pkg.put_log_message('Lancement de la procédure consolidation_restit avec les paramètres suivants : période cible: '||pv_period_to_close ||'/ id de restit: '||pn_restit_id);	
		
	
   SELECT consolidation_id into vn_consolidation_id from gl_consolidation_v where to_ledger_id=pn_restit_id;

   consolidation_run_id:=gl_consolidation_history_s.nextval;

   --execute immediate 'ALTER SESSION SET NLS_LANGuAGE=American';
   INSERT INTO GL_CONSOLIDATION_HISTORY(consolidation_run_id,
	consolidation_id,
	FROM_PERIOD_NAME,
	TO_PERIOD_NAME,
	TO_CURRENCY_CODE,
	METHOD_FLAG,
	RUN_EASYLINK_FLAG,
	ACTUAL_FLAG,
	AVERAGE_CONSOLIDATION_FLAG,
	CREATION_DATE,
	CREATED_BY,
	LAST_UPDATE_DATE,
	LAST_UPDATED_BY,
	LAST_UPDATE_LOGIN,
	AMOUNT_TYPE,
	RUN_POSTING_FLAG) 
 VALUES (consolidation_run_id,vn_consolidation_id,pv_period_to_close,pv_period_to_close,'EUR','B','Y','A','N',sysdate,fnd_global.user_id,sysdate,fnd_global.user_id,fnd_global.user_id,'PTD','Y');   COMMIT;

      -- Submit a concurrent program request to open a new period.
      req_id := fnd_request.submit_request (
                   'SQLGL', --APPLICATION PROPRIETAIRE DU TRAITEMENT
                   'GLCCON', --SHORT NAME du Traitement
                   '',--PROGRAM_NAME
                   '',--START
                   FALSE,--SUB_REQUEST
                    vn_consolidation_id ,
					'S',
					pv_period_to_close,
					'',
					pv_period_to_close,
					'',
					'',
					vv_type_montant,
					'Y',
					'B',
					consolidation_run_id,
					'A',
					'',
					'',
					'Y',
					'N',
					'Y',
					'Y',
					'N',
					Fnd_Profile.VALUE ('GL_ACCESS_SET_ID'));
      COMMIT;

      IF NOT (fnd_concurrent.wait_for_request (
                 req_id,
                 15,
                 0,
                 vv_phase,
                 vv_status,
                 vv_dev_phase,
                 vv_dev_status,
                 vv_message
              )
             )
      THEN

         dka_tools_pkg.put_debug_message (
               '--> Traitement trop long: '
            || TO_CHAR (req_id)
         );
         pv_errbuf :=
               'Erreur sur le traitement CONSOLIDATION_RESTIT'|| TO_CHAR (req_id);
         RAISE open_failed;
      ELSIF (    vv_dev_phase = 'COMPLETE'
             AND vv_dev_status = 'NORMAL'
            )
      THEN

         dka_tools_pkg.put_debug_message (
               '--> Exécution du traitement '
            || TO_CHAR (req_id)
            || ' OK'
         );
		 pn_retcode := 0;

      END IF; -- fin IF NOT
	   dka_tools_pkg.put_log_message('Fin de la procédure consolidation_restit');	

   EXCEPTION
      WHEN open_failed
      THEN
         raise_application_error (
            -20000,
            'CONSOLIDATION_RESTIT'
         );
		 dka_tools_pkg.put_log_message('Fin de la procédure consolidation_restit');	

         pn_retcode := 2;
	  WHEN no_data_found
      THEN
		 dka_tools_pkg.put_log_message('Fin de la procédure consolidation_restit');	
		 pv_errbuf := 'Aucun id de consolidation n''a été trouvé pour la société : '||pn_restit_id;
         pn_retcode := 2;
      WHEN OTHERS
      THEN
         pv_errbuf := SUBSTR (SQLERRM, 1, 250);
         pn_retcode := 2;
		 dka_tools_pkg.put_log_message('Fin de la procédure consolidation_restit suite à une erreur :'||SUBSTR (SQLERRM, 1, 250));	


END CONSOLIDATION_RESTIT;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : OPEN_NEXT_PERIOD
--  Description   : Ouverture de la période suivante
--
--  PARAMETRES    :
--     pn_sob_id  number
--     pv_period_name   varchar2
--
--  VALEUR RETOURNEE :
--     pv_errbuf  varchar2
--     pd_start_date    date
--     pd_END_date   date
--     pd_period_name   varchar2
-------------------------------------------------------------------------------------------------------------------
   PROCEDURE open_next_period (
      pn_sob_id    IN   NUMBER,
    pn_access_id IN       NUMBER,
    pv_period_name IN     VARCHAR2,
      pv_errbuf    OUT   VARCHAR2,
      pn_retcode   OUT      NUMBER
   )
   IS
      req_id          NUMBER;
      vn_account_id   NUMBER;
      vv_phase        VARCHAR2 (100);
      vv_status       VARCHAR2 (100);
      vv_dev_phase    VARCHAR2 (100);
		vv_closing_status VARCHAR2(2);
      vv_dev_status   VARCHAR2 (100);
      vv_message      VARCHAR2 (100);
      open_failed     EXCEPTION;
   BEGIN
   	  dka_tools_pkg.put_log_message('Début de la procédure open_next_period avec les paramètres : '||
		'id du livre à ouvrir : '||pn_sob_id||'/ période à ouvrir :'||pv_period_name
		||'numéro du jeu d''accès: '||pn_access_id);

      ----- on détermine le account_id pour le traitement GLOOAP -----
	  pn_retcode:=0;
	  Select closing_status
	  INTO vv_closing_status 
	  FROM gl_period_statuses
	  WHERE period_name=pv_period_name
	  AND ledger_id=pn_sob_id
	  AND application_id=101;
	  
		IF  vv_closing_status = 'O'
		THEN
			--dka_tools_pkg.put_outdebug_message('La période est déjà ouverte ');
			dka_tools_pkg.put_debug_message('La période est déjà ouverte ');
			pn_retcode:=0;
			RETURN;
		END IF;
	  
      SELECT chart_of_accounts_id
        INTO vn_account_id
        FROM gl_ledgers
       WHERE ledger_id= pn_sob_id;
	
      --MSF: modIFication du message dans le journal
      dka_tools_pkg.put_debug_message (
            'Chart_Of_Accounts_Id : '
         || vn_account_id
      );
      -- Submit a concurrent program request to open a new period.
      req_id := fnd_request.submit_request (
                   'SQLGL', --APPLICATION PROPRIETAIRE DU TRAITEMENT
                   'GLOOAP', --SHORT NAME du Traitement
                   '',--PROGRAM_NAME
                   '',--START
                   FALSE,--SUB_REQUEST
                   '', --Nom abrégé du livre
                   pn_access_id, --ID jeu d'accès
           pn_sob_id, --ID livre
                   TO_CHAR (vn_account_id), --ID plan de comptes
                   TO_CHAR(101),--ID application
                   'P', -- Mode d'éxécution
           pv_period_name
                );
      --YWA artf2149693  
            
      IF req_id = 0 THEN
              
        pn_retcode    := 2;
        pv_errbuf := 'ERREUR : Le traitemen d''ouverture de période ' || CHR(10) ||'PROGRAMME  : GLOOAP';
        dka_tools_pkg.put_debug_message('ERREUR : Le traitement d''ouverture de la période ' || CHR(10) ||'PROGRAMME  : GLOOAP');
                  
      ELSE
              
        COMMIT;
        dka_tools_pkg.put_debug_message('=> REQUEST ID= ' || req_id);            
        dka_tools_pkg.put_debug_message('. Numéro du traitement d''ouverture de la période : ' || req_id);  
                    
        g_cpt_open := g_cpt_open + 1;
        g_num_trait_list_open(g_cpt_open) := req_id;
                  
      END IF;
      --YWA artf2149693 
     /* IF NOT (fnd_concurrent.wait_for_request (
                 req_id,
                 15,
                 0,
                 vv_phase,
                 vv_status,
                 vv_dev_phase,
                 vv_dev_status,
                 vv_message
              )
             )
      THEN
         dka_tools_pkg.put_debug_message (
               '--> Traitement trop long: '
            || TO_CHAR (req_id)
         );
         pv_errbuf :=
               'Erreur sur le traitement Ouvrir la période'
            || TO_CHAR (req_id);
         RAISE open_failed;
      ELSIF (    vv_dev_phase = 'COMPLETE'
             AND vv_dev_status = 'NORMAL'
            )
      THEN
	  dka_tools_pkg.put_log_message('Le traitement d''ouverture de la période:'||pv_period_name||' est un succès pour le livre : ' ||pn_sob_id);
         dka_tools_pkg.put_debug_message (
               '--> Exécution du traitement '
            || TO_CHAR (req_id)
            || ' OK'
         );
		 

		 pn_retcode := 0;

      END IF; -- fin IF NOT*/

/*      -- Failure in submission the concurrent request.
      IF (req_id = 0)
      THEN
         dka_tools_pkg.put_debug_message ('open_next_period');
         pv_errbuf := 'traitement GLOOAP ne s''est pas lancé';
         pn_retcode := 2;
         RETURN;
      END IF;
*/
    dka_tools_pkg.put_log_message('Fin de la procédure open_next_period ');	
   EXCEPTION
      WHEN OTHERS
      THEN
         pv_errbuf := SUBSTR (SQLERRM, 1, 250);
         pn_retcode := 2;
   END open_next_period;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : CLOSE_PREVIOUS_PERIOD
--  Description   : Ouverture de la période suivante
--
--  PARAMETRES    :
--     pn_sob_id  number
--     pv_period_name   varchar2
--
--  VALEUR RETOURNEE :
--     pv_errbuf  varchar2

--     pd_period_name   varchar2
-------------------------------------------------------------------------------------------------------------------
   PROCEDURE CLOSE_PREVIOUS_PERIOD (
      pn_sob_id    IN    NUMBER,
    pv_period_name IN     VARCHAR2,
    pn_access_id     IN    NUMBER,
      pv_errbuf    IN OUT   VARCHAR2,
      pn_retcode   OUT      NUMBER
   )
   IS
      req_id          NUMBER;
      vv_phase        VARCHAR2 (100);
      vv_status       VARCHAR2 (100);
      vv_dev_phase    VARCHAR2 (100);
      vv_dev_status   VARCHAR2 (100);
      vv_message      VARCHAR2 (100);
      open_failed     EXCEPTION;
   BEGIN
		pn_retcode:=0;
		dka_tools_pkg.put_log_message('Début de la procédure Close_previous_period avec les paramètres : '||
		'id du livre à fermer : '||pn_sob_id||'/ période à fermer :'||pv_period_name
		||'numéro du jeu d''accès: '||pn_access_id);

      -- Submit a concurrent program request to close a new period.

   SELECT closing_status
                     INTO   vv_status
                     FROM   gl_period_statuses
                     WHERE  period_name = pv_period_name
                     AND    application_id = 101
                     AND    set_of_books_id = pn_sob_id;

  IF vv_status <> 'C'
  THEN

    req_id := fnd_request.submit_request (
          'SQLGL', --APPLICATION PROPRIETAIRE DU TRAITEMENT
          'GLOCPP', --SHORT NAME du Traitement
          '',--PROGRAM_NAME
          '',--START
          FALSE,--SUB_REQUEST
          '', --Nom abrégé du livre
          pn_access_id, --ID jeu d'accès
          pn_sob_id, --ID livre
          pv_period_name, --nom de la période
          'N', --Fermeture de périodes consécutives
          'C', -- Statut de clôture
          101  -- ID application
                );
      
    --YWA artf2149693  
            
      IF req_id = 0 THEN
              
        pn_retcode    := 2;
        pv_errbuf := 'ERREUR : Le traitement de fermeture de periode ' || CHR(10) ||'PROGRAMME  : GLOCPP';
        dka_tools_pkg.put_debug_message('ERREUR : Le traitement de fermeture de periode ' || CHR(10) ||'PROGRAMME  : GLOCPP');
                  
      ELSE
              
        COMMIT;
        dka_tools_pkg.put_debug_message('=> REQUEST ID= ' || req_id);            
        dka_tools_pkg.put_debug_message('. Numéro du traitement de  fermeture de periode : ' || req_id);  
                    
        g_cpt_close := g_cpt_close + 1;
        g_num_trait_list_close(g_cpt_close) := req_id;
                  
      END IF;
      --YWA artf2149693  

    /*  IF NOT (fnd_concurrent.wait_for_request (
                 req_id,
                 15,
                 0,
                 vv_phase,
                 vv_status,
                 vv_dev_phase,
                 vv_dev_status,
                 vv_message
              )
             )
    THEN

    dka_tools_pkg.put_debug_message (
         '--> Traitement trop long: '
      || TO_CHAR (req_id)
     );
    pv_errbuf :=
         'Erreur sur le traitement Fermer la période'
      || TO_CHAR (req_id);
     RAISE open_failed;
    ELSIF (    vv_dev_phase = 'COMPLETE'
      AND vv_dev_status = 'NORMAL'
      )
    THEN

    dka_tools_pkg.put_log_message (
         '--> Exécution du traitement '
      || TO_CHAR (req_id)
      || ' OK'
     );
    END IF; -- fin IF NOT*/
  ELSE
    pn_retcode := 1;
    dka_tools_pkg.put_debug_message('La période est déjà fermée');
  END IF;
    dka_tools_pkg.put_log_message('Fin de la procédure close_previous_period ');	

  EXCEPTION
  WHEN OTHERS
  THEN
        dka_tools_pkg.put_log_message('Fin de la procédure close_previous_period provoquée par une exception'||SUBSTR (SQLERRM, 1, 250));	

        pv_errbuf := SUBSTR (SQLERRM, 1, 250);
        pn_retcode := 2;
  END CLOSE_PREVIOUS_PERIOD;
    
    
    --YWA artf2149693 
    -------------------------------------------------------------------------------------------------------------------
    --  Nom           : wait_for_request
    --  Description   : 
    --
    --  PARAMETRES    :

    --
    --  VALEUR RETOURNEE :
    --     pv_errbuf  varchar2

    --     pd_period_name   varchar2
    -------------------------------------------------------------------------------------------------------------------
    PROCEDURE wait_for_request (pv_errbuf     OUT   VARCHAR2,
                                        pn_retcode   OUT      NUMBER
                                    )
    IS
      vv_phase        VARCHAR2 (100);
      vv_status       VARCHAR2 (100);
      vv_dev_phase    VARCHAR2 (100);
      vv_dev_status   VARCHAR2 (100);
      vv_message      VARCHAR2 (100);
      open_failed     EXCEPTION;
    BEGIN
        pn_retcode:=0;
        dka_tools_pkg.put_log_message(TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||' - '||'Début de la procédure wait_for_request');
    
    FOR var IN 1 .. g_cpt_close LOOP 
        dka_tools_pkg.put_debug_message ('. Numéro de traitement de fermeture: ' ||g_num_trait_list_close(var));
        IF NOT (fnd_concurrent.wait_for_request (g_num_trait_list_close(var),
                                                 15,
                                                 0,
                                                 vv_phase,
                                                 vv_status,
                                                 vv_dev_phase,
                                                 vv_dev_status,
                                                 vv_message
                                              )
                 )
        THEN

            dka_tools_pkg.put_debug_message ('--> Traitement trop long: '|| TO_CHAR (g_num_trait_list_close(var)) );
            dka_tools_pkg.put_debug_message ('Erreur sur le traitement de fermeture de période'|| TO_CHAR (g_num_trait_list_close(var)));
            -- RAISE open_failed;
            pn_retcode := 2;
        ELSIF ( vv_dev_phase = 'COMPLETE'   AND vv_dev_status = 'NORMAL' )  THEN

            dka_tools_pkg.put_debug_message ('--> Exécution du traitement '|| TO_CHAR (g_num_trait_list_close(var))|| ' OK' );
        END IF; 
    END LOOP;
    
    FOR var IN 1 .. g_cpt_open LOOP 
        dka_tools_pkg.put_debug_message ('. Numéro  de traitement d''ouverture : ' ||g_num_trait_list_open(var));
        IF NOT (fnd_concurrent.wait_for_request (g_num_trait_list_open(var),
                                                 15,
                                                 0,
                                                 vv_phase,
                                                 vv_status,
                                                 vv_dev_phase,
                                                 vv_dev_status,
                                                 vv_message
                                              )
                 )

        THEN
            dka_tools_pkg.put_debug_message ('--> Traitement trop long: '|| TO_CHAR (g_num_trait_list_open(var)));
            dka_tools_pkg.put_debug_message ('Erreur sur le traitement d''ouverture de période'|| TO_CHAR (g_num_trait_list_open(var)));
            --RAISE open_failed;
            pn_retcode := 2;
        ELSIF (    vv_dev_phase = 'COMPLETE' AND vv_dev_status = 'NORMAL') THEN
      
            dka_tools_pkg.put_debug_message ('--> Exécution du traitement '|| TO_CHAR (g_num_trait_list_open(var))|| ' OK');

        END IF; 
        
    END LOOP;
    
    IF pn_retcode != 0 THEN
        pv_errbuf :='Des traitements se sont terminés en erreur';
    ELSE
        pv_errbuf :='Tout les traitements se sont terminés correctement';
    END IF;
    
    EXCEPTION
        /*WHEN open_failed THEN
            --raise_application_error (-20000,'Erreur sur le traitement wait_for_request');
            dka_tools_pkg.put_debug_message('Fin de la procédure wait_for_request suite à une exception');	

            pn_retcode := 2;*/
        WHEN OTHERS THEN
            dka_tools_pkg.put_log_message('Fin de la procédure wait_for_request provoquée par une exception'||SUBSTR (SQLERRM, 1, 250));	

            pv_errbuf := SUBSTR (SQLERRM, 1, 250);
            pn_retcode := 2;
            
    END wait_for_request;

  
-------------------------------------------------------------------------------------------------------------------
--  Nom           : CLOSE_LEDGER
--  Description   : Cette Procédure enchaîne l'ensemble des autres procédures pour un livre primaire
--
--  PARAMETRES    :
--
-- pv_errbuf                       Entrée/Sortie           retour de message eventuel
--       pn_retcode                      Sortie                  status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
-------------------------------------------------------------------------------------------------------------------
PROCEDURE CLOSE_LEDGER (pn_sob_id IN NUMBER, pn_access_id NUMBER,pn_access_id_legal NUMBER,pn_access_id_restit NUMBER,pv_period_to_close IN varchar2,pv_period_to_open IN varchar2, pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER)
IS
	vn_conf_id NUMBER;
	vn_restit_id NUMBER;
	vn_legal_id NUMBER;
	vv_closing_status VARCHAR2(5);
	vv_errbuf VARCHAR2(500);
	vn_retcode NUMBER;
BEGIN
	vn_retcode:=0;
	pn_retcode:=0;
	dka_tools_pkg.put_log_message('Début de la procédure CLOSE_LEDGER avec les paramètres:'||'id du livre : '||pn_sob_id || '/ id du jeu d''accès : '||pn_access_id ||
	'/ id du jeu d''accès(legal) : '||pn_access_id_legal || '/ id du jeu d''accès(restit) : '||pn_access_id_restit || '/ période à fermer: '||pv_period_to_close ||'/ période à ouvrir'||pv_period_to_open);
	

    --Récupération de l'id de configuration associé au livre primaire
    vn_conf_id:=get_configuration_id(pn_sob_id);
    IF vn_conf_id = -1 THEN
        dka_tools_pkg.put_debug_message(pv_errbuf);
        pn_retcode := 2; -- OBE artf2148176
        RETURN;
    END IF;

  --Récupération de l'id du livre secondaire restit associé à ce livre primaire
  --< OBE artf2169708
  /*
  vn_restit_id := get_restit(pn_sob_id);
  IF vn_restit_id = -1
  THEN
    dka_tools_pkg.put_debug_message(pv_errbuf);
  END IF;
  */
  --> OBE artf2169708
  
    --Récupération de l'id du livre secondaire legal associé à ce livre primaire
    vn_legal_id:=get_legal(pn_sob_id);
    IF vn_legal_id = -1 THEN
        dka_tools_pkg.put_debug_message(vv_errbuf);
    END IF;

    open_next_period( pn_sob_id, pn_access_id, pv_period_to_open, vv_errbuf, vn_retcode);
	IF vn_retcode <> 0 THEN
        pn_retcode:= vn_retcode;
    ELSE
        -- ouverture de la période légale
        IF vn_legal_id <> -1 THEN
            open_next_period( vn_legal_id, pn_access_id_legal, pv_period_to_open, vv_errbuf, vn_retcode); 
            IF pn_retcode < vn_retcode THEN --Si le code de retour de la de la fonction est plus grand que le code de retour actuel alors on met à jour sa valeur
             
                pn_retcode:= vn_retcode;
                dka_tools_pkg.put_debug_message(vv_errbuf);
            END IF;
        END IF;

		--Ouverture de la période pour le livre restit
    --< OBE artf2169708
    /*
		IF vn_restit_id <> -1 AND vn_retcode <> 2
		THEN
			if pn_retcode < vn_retcode --Si le code de retour de la de la fonction est plus grand que le code de retour actuel alors on met à jour sa valeur
			then 
			pn_retcode:= vn_retcode;
			dka_tools_pkg.put_debug_message(vv_errbuf);
			end if;
		END IF;
    */
    --> OBE artf2169708
		--fin Ouverture de la période pour le livre restit
	END IF;


 
	
	
  --fermeture de la période pour le livre primaire (même si la période n'a pas été ouverte)
    vn_retcode := 0;
    close_previous_period(pn_sob_id , pv_period_to_close,pn_access_id, vv_errbuf, vn_retcode);
	IF vn_retcode = 2 THEN
		pn_retcode := vn_retcode;
		pv_errbuf := vv_errbuf;
		RETURN;
	ELSIF vn_retcode =1 THEN--la période était déjà fermée 
	
		dka_tools_pkg.put_debug_message(vv_errbuf);
	ELSE
		IF vn_legal_id <> -1
		THEN
			close_previous_period(vn_legal_id,  pv_period_to_close,pn_access_id_legal, vv_errbuf, vn_retcode);
			IF vn_retcode = 2
			THEN
				dka_tools_pkg.put_debug_message(vv_errbuf);
			END IF;
		END IF;
    --< OBE artf2169708
    /*
		IF vn_restit_id <> -1
		THEN
			consolidation_restit (pv_period_to_close,vn_restit_id,vv_errbuf,vn_retcode);
			IF vn_retcode =2
			THEN
				dka_tools_pkg.put_debug_message(vv_errbuf);
				pn_retcode := 2;
			END IF;
		END IF;
    */
    --> OBE artf2169708
	END IF;
  --fin fermeture de la période pour le livre primaire
  


	

	
dka_tools_pkg.put_log_message('fin de la procédure close_ledger');
EXCEPTION
WHEN OTHERS THEN
    pv_errbuf := SQLERRM;
	dka_tools_pkg.put_log_message('Erreur lors de la procédure close_ledger');
	dka_tools_pkg.put_log_message(SQLERRM);
    pn_retcode := 2;

  --LANCEMENT DU TRAITEMENT STANDARD DE CONSOLIDATION

END CLOSE_LEDGER;


---------------------------------------------------------------------------------------------------------------
--  Nom           : Bilan
--  Description   : Lance la procédure de cloture pour tous les set_of_books
--
--  PARAMETRES    :
--  pv_errbuf                       Entrée/Sortie           retour de message eventuel
--      pn_retcode                      Sortie                  status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
----------------------------------------------------------------------------------------------------------------

PROCEDURE Bilan (pv_period_to_close IN VARCHAR2,pv_period_to_open IN VARCHAR2,pv_errbuf  IN OUT VARCHAR2,
                pn_retcode    IN OUT NUMBER)

IS
vn_ledger_id number;
vv_ledger_name VARCHAR2(50);
vv_closing_status VARCHAR2(2);

CURSOR c_bilan(pv_period VARCHAR2)  IS
select gps.closing_status, gl.name, period_name,gl.ledger_id
  from gl_period_statuses gps, gl_ledgers gl
 where application_id = 101
	and gl.ledger_id = gps.ledger_id
	and period_name = pv_period
	and gl.ledger_id IN
		 (SELECT gl.ledger_id AS ledger_id
						FROM gl_access_set_assignments gasa, gl_ledgers gl
					  WHERE access_set_id = Fnd_Profile.VALUE('GL_ACCESS_SET_ID')
						 AND gl.ledger_id = gasa.ledger_id
						 AND gl.ledger_category_code = 'PRIMARY');



BEGIN
	dka_tools_pkg.put_outdebug_message('Bilan du traitement : ');
	dka_tools_pkg.put_outdebug_message(RPAD('PERIOD_NAME',50,' ')||RPAD('LEDGER_NAME',40,' ')||RPAD('LEDGER_ID',40,' ')||RPAD('STATUS',40,' '));
	dka_tools_pkg.put_outdebug_message('-------------------------------------------------------------------------------------------------------------------------------------------------------');
	dka_tools_pkg.put_outdebug_message(chr(10));
	FOR v_tmp IN c_bilan(pv_period_to_close) LOOP
		  dka_tools_pkg.put_outdebug_message(RPAD(v_tmp.period_name,50,' ')||RPAD(v_tmp.name,40,' ')||RPAD(v_tmp.ledger_id,40,' ')||RPAD(v_tmp.closing_status,40,' '));
		  
		 begin
			  select target_ledger_id,target_ledger_name,gps.closing_status
			  into vn_ledger_id,vv_ledger_name,vv_closing_status
			  from gl_ledger_relationships glr,gl_ledgers gl,gl_period_statuses gps
			  where RELATIONSHIP_ENABLED_FLAG = 'Y'
			  and SOURCE_LEDGER_ID = v_tmp.ledger_id
			  and gl.ledger_id=source_ledger_id
			  and gps.ledger_id=gl.ledger_id
			  and gps.application_id=101
			  and gps.period_name=v_tmp.period_name
			  and RELATIONSHIP_TYPE_CODE ='JOURNAL' ;
			  dka_tools_pkg.put_outdebug_message(RPAD(v_tmp.period_name,50,' ')||RPAD(vv_ledger_name,40,' ')||RPAD(vn_ledger_id,40,' ')||RPAD(vv_closing_status,40,' '));
				EXCEPTION
				WHEN OTHERS THEN
				vn_ledger_id:=0;
		  end;
		  begin
			  select target_ledger_id,target_ledger_name,gps.closing_status
			  into vn_ledger_id,vv_ledger_name,vv_closing_status
			  from gl_ledger_relationships glr,gl_ledgers gl,gl_period_statuses gps
			  where RELATIONSHIP_ENABLED_FLAG = 'Y'
			  and SOURCE_LEDGER_ID = v_tmp.ledger_id
			  and gl.ledger_id=source_ledger_id
			  and gps.ledger_id=gl.ledger_id
			  and gps.application_id=101
			  and gps.period_name=v_tmp.period_name
			  and RELATIONSHIP_TYPE_CODE = 'BALANCE';
			  dka_tools_pkg.put_outdebug_message(RPAD(v_tmp.period_name,50,' ')||RPAD(vv_ledger_name,40,' ')||RPAD(vn_ledger_id,40,' ')||RPAD(vv_closing_status,40,' '));
				EXCEPTION
				WHEN OTHERS THEN
				vn_ledger_id:=0;
		  end;
	END LOOP;
	FOR v_tmp IN c_bilan(pv_period_to_open) LOOP
		dka_tools_pkg.put_outdebug_message(RPAD(v_tmp.period_name,50,' ')||RPAD(v_tmp.name,40,' ')||RPAD(v_tmp.ledger_id,40,' ')||RPAD(v_tmp.closing_status,40,' '));
		 begin
			  select target_ledger_id,target_ledger_name,gps.closing_status
			  into vn_ledger_id,vv_ledger_name,vv_closing_status
			  from gl_ledger_relationships glr,gl_ledgers gl,gl_period_statuses gps
			  where RELATIONSHIP_ENABLED_FLAG = 'Y'
			  and SOURCE_LEDGER_ID = v_tmp.ledger_id
			  and gl.ledger_id=source_ledger_id
			  and gps.ledger_id=gl.ledger_id
			  and gps.application_id=101
			  and gps.period_name=v_tmp.period_name
			  and RELATIONSHIP_TYPE_CODE = 'JOURNAL';
			  dka_tools_pkg.put_outdebug_message(RPAD(v_tmp.period_name,50,' ')||RPAD(vv_ledger_name,40,' ')||RPAD(vn_ledger_id,40,' ')||RPAD(vv_closing_status,40,' '));
				EXCEPTION
				WHEN OTHERS THEN
				vn_ledger_id:=0;
		  end;
		  begin
			  select target_ledger_id,target_ledger_name,gps.closing_status
			  into vn_ledger_id,vv_ledger_name,vv_closing_status
			  from gl_ledger_relationships glr,gl_ledgers gl,gl_period_statuses gps
			  where RELATIONSHIP_ENABLED_FLAG = 'Y'
			  and SOURCE_LEDGER_ID = v_tmp.ledger_id
			  and gl.ledger_id=source_ledger_id
			  and gps.ledger_id=gl.ledger_id
			  and gps.application_id=101
			  and gps.period_name=v_tmp.period_name
			  and RELATIONSHIP_TYPE_CODE = 'BALANCE';
			  dka_tools_pkg.put_outdebug_message(RPAD(v_tmp.period_name,50,' ')||RPAD(vv_ledger_name,40,' ')||RPAD(vn_ledger_id,40,' ')||RPAD(vv_closing_status,40,' '));
				EXCEPTION
				WHEN OTHERS THEN
				vn_ledger_id:=0;
		  end;
	
	 
	
	END LOOP;
			
EXCEPTION
WHEN OTHERS THEN
    pv_errbuf := SQLERRM;
	dka_tools_pkg.put_debug_message('Erreur lors de la procédure bilan');

	dka_tools_pkg.put_log_message(SQLERRM);
    pn_retcode := 2;

END Bilan;
---------------------------------------------------------------------------------------------------------------
--  Nom           : main
--  Description   : Lance la procédure de cloture pour tous les set_of_books
--
--  PARAMETRES    :
--  pv_errbuf                       Entrée/Sortie           retour de message eventuel
--      pn_retcode                      Sortie                  status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
----------------------------------------------------------------------------------------------------------------

PROCEDURE main (pv_errbuf  IN OUT VARCHAR2,
                pn_retcode    OUT NUMBER,
                pv_period_name IN VARCHAR2)

IS
vn_sob_id     NUMBER;
vv_errbuf          VARCHAR2(150);
vn_retcode         NUMBER;
vv_responsibility_name VARCHAR(100);
vn_responsibility_id NUMBER;
vn_application_id NUMBER;
vn_access_id_ope      NUMBER;
vn_access_id_legal     NUMBER;
vn_access_id_restit  NUMBER;

vv_restit_acces_name VARCHAR2(150);
vv_legal_acces_name VARCHAR2(150);
vv_period_to_close VARCHAR(150);
vv_period_to_open VARCHAR(150);
vr_data dka_parameters%ROWTYPE;


CURSOR cur_ledger_id  IS
SELECT   gl.ledger_id AS ledger_id, gl.name
FROM     gl_access_set_assignments gasa, gl_ledgers gl
WHERE    access_set_id = Fnd_Profile.VALUE ('GL_ACCESS_SET_ID')
AND      gl.ledger_id = gasa.ledger_id
AND      gl.ledger_category_code = 'PRIMARY';

CURSOR c_bilan(pv_period1 VARCHAR2,pv_period2 VARCHAR2)  IS
select gps.closing_status, gl.name, period_name
  from gl_period_statuses gps, gl_ledgers gl
 where application_id = 101
	and gl.ledger_id = gps.ledger_id
	and period_name IN (pv_period1,pv_period2)
	and gl.ledger_id IN
		 (select target_ledger_id
			 from gl_ledger_relationships
			where RELATIONSHIP_ENABLED_FLAG = 'Y'
			  and SOURCE_LEDGER_ID IN
					(SELECT gl.ledger_id AS ledger_id
						FROM gl_access_set_assignments gasa, gl_ledgers gl
					  WHERE access_set_id = Fnd_Profile.VALUE('GL_ACCESS_SET_ID')
						 AND gl.ledger_id = gasa.ledger_id
						 AND gl.ledger_category_code = 'PRIMARY'));



BEGIN


	vv_responsibility_name := 'TOUT_GL_OPE_ADMINISTRATEUR';
	SELECT fr.responsibility_id, fr.application_id
     INTO vn_responsibility_id, vn_application_id
     FROM fnd_responsibility fr
     WHERE fr.responsibility_key = vv_responsibility_name;
      dka_tools_pkg.put_debug_message('-------------------------------------------'||'Responsabilité : '|| vn_responsibility_id || vn_application_id );

      -- initialisation de l'environement OA pour correspondre a la societe en cours de traitement
      fnd_global.apps_initialize(fnd_global.user_id,vn_responsibility_id,vn_application_id);
	  
	
	vn_retcode:=0;
	vv_errbuf:='';
  
  pv_errbuf     := NULL; -- OBE artf2148176
  pn_retcode    := 0;    -- OBE artf2148176
    
  vn_access_id_ope := Fnd_Profile.VALUE ('GL_ACCESS_SET_ID');

--  09/11/2017 NBO artf2274387: SPE045 - Clôture de la période GL - Pb lié livre RESTIT - RUN6
/*      dka_tools_pkg.get_parameter (
      'DKA_SGLCLOTURE',
	  'JEU_RESTIT'   ,
	     vr_data,
        vn_retcode,
        vv_errbuf    
    );
	vv_restit_acces_name:=vr_data.varchar2_value;
  dka_tools_pkg.put_debug_message('vv_restit_acces_name : ' || vv_restit_acces_name);

	select access_set_id into vn_access_id_restit from gl_access_sets where name = vv_restit_acces_name;*/
	
	dka_tools_pkg.get_parameter (

      'DKA_SGLCLOTURE',
	  'JEU_LEGAL'   ,
	     vr_data,
        vn_retcode,
        vv_errbuf    
    );
	vv_legal_acces_name:=vr_data.varchar2_value;
  
  dka_tools_pkg.put_debug_message('vv_legal_acces_name : ' || vv_legal_acces_name);
  
	select access_set_id into vn_access_id_legal from gl_access_sets where name = vv_legal_acces_name;
  
  


	  
	    --Détermination de la période à fermer pour le livre primaire
	  
	  
	  
		if pv_period_name is not NULL
		then
		vv_period_to_close := pv_period_name;
			
		else
			period_to_close (
			vv_period_to_close,
			vv_errbuf,
			vn_retcode
			);
			IF vn_retcode = 2
				THEN
				pn_retcode := vn_retcode;
				pv_errbuf := vv_errbuf;
				dka_tools_pkg.put_debug_message('Aucune période à fermer n''a été trouvée'); 
				RETURN;
			END IF;
		end if;
	

		period_to_open (
		vv_period_to_close,
		vv_period_to_open,
		vv_errbuf,
		vn_retcode
		);
		
		IF vn_retcode = 2 THEN
            dka_tools_pkg.put_outdebug_message('Erreur lors de la recherche de la période à ouvrir, aucune période ne sera ouverte ni fermée');
            pn_retcode:=2;
            pv_errbuf:=vv_errbuf;
            RETURN;
		ELSE 
            dka_tools_pkg.put_outdebug_message('Période à ouvrir déterminée :'||vv_period_to_open||', période à fermer : '||vv_period_to_close);
            
            FOR rec_ledger IN cur_ledger_id() LOOP
				dka_tools_pkg.put_debug_message('----------------------------------------------------------------------------------------------------');
				dka_tools_pkg.put_debug_message('----------------------------------------------------------------------------------------------------');
				vn_sob_id:= rec_ledger.ledger_id;
				dka_tools_pkg.put_debug_message('Cloture sur le livre primaire: '||rec_ledger.ledger_id || '/' || rec_ledger.name);
				
				close_ledger (vn_sob_id , vn_access_id_ope,vn_access_id_legal,vn_access_id_restit,vv_period_to_close,vv_period_to_open,vv_errbuf , vn_retcode);
				dka_tools_pkg.put_debug_message('pn_retcode/vn_retcode ' || pn_retcode ||'  ' || vn_retcode);


				if pn_retcode < vn_retcode 
				then
					dka_tools_pkg.put_debug_message('pn_retcode/vn_retcode ' || pn_retcode ||'----' || vn_retcode);
					pn_retcode := vn_retcode ;
					pv_errbuf := vv_errbuf;
				end if;
				
				dka_tools_pkg.put_debug_message('Fin du lancement de cloture sur le livre '||rec_ledger.ledger_id);
				dka_tools_pkg.put_debug_message('---------------------------------------------------------------------------------------------------');
				dka_tools_pkg.put_debug_message('----------------------------------------------------------------------------------------------------');

			END LOOP;
            
            wait_for_request (vv_errbuf , vn_retcode);
            IF vn_retcode = 2 THEN
                pn_retcode := vn_retcode ;
                pv_errbuf := vv_errbuf;
            END IF;
            dka_tools_pkg.put_debug_message(vv_errbuf);
            
		END IF;
        
		bilan(vv_period_to_close ,vv_period_to_open ,pv_errbuf ,pn_retcode  );
		--bilan du programme 
		-- dka_tools_pkg.put_outdebug_message('Bilan du traitement : ');
		-- dka_tools_pkg.put_outdebug_message(RPAD('PERIOD_NAME',50,' ')||RPAD('LEDGER_NAME',40,' ')||RPAD('STATUS',40,' '));
		-- dka_tools_pkg.put_outdebug_message('-------------------------------------------------------------------------------------------------------------------------------------------------------');
		-- dka_tools_pkg.put_outdebug_message(chr(10));
		-- FOR v_tmp IN c1(vv_period_to_close,vv_period_to_open) LOOP
		  -- dka_tools_pkg.put_outdebug_message(RPAD(v_tmp.period_name,50,' ')||RPAD(v_tmp.name,40,' ')||RPAD(v_tmp.closing_status,40,' '));
		-- END LOOP;
    
    --< OBE artf2148176
    IF pn_retcode = 2 THEN
      pv_errbuf := 'Le traitement s''est terminé en Erreur. Tous les livres n''ont pas été traités';
    END IF;
    --> OBE artf2148176
			
EXCEPTION
WHEN OTHERS THEN
    pv_errbuf := SQLERRM;
	dka_tools_pkg.put_log_message('Erreur lors de la procédure main');

	dka_tools_pkg.put_debug_message(SQLERRM);
    pn_retcode := 2;

END main;


END dka_sglcloture_pkg; -- Package body
/
SHOW ERRORS;
EXIT;
