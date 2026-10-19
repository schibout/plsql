CREATE OR REPLACE PACKAGE BODY DKA_IEOGLETF01_PKG AS
----------------------------------------------------------------------------------------------
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM		         : DKA_IEOGLETF01_PKG.pkb
-- DESCRIPTION	     : DKA_IEOGLETF01_PKG package body : package pour altaven: Extraction vers altaven
---
--- AUTEUR	         : AZIZ NOUJOUD(CGEY)
--- DATE DE CREATION : 29/05/2002
--- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--- 14/05/2002 DRA Ajout de messages de sortie dans la procédure main.
---                Gestion des erreurs dans la procédure init.
--- 23/06/2003 ADR extraction_altaven : Modification de l'insert dans DKA_IEOGLETF01_INT (--AD--)
---                suivant les remarques définit dans le dossier technique.
--- 21/08/2003 ADR extraction_altaven : Modifiaction de la jointure externe afin de prendre
---                les comptes n'ayant pas de code partenaire.
---                Adaptation de l'interface pour l'entité légale.
--- 25/11/2005 EB  INIT : Prise en compte du parametre pv_company_num
--- 17/07/2006 GV  extraction_altaven : correction de la requête pour le calcul concernant
---                                   l'entité légale (gv_flex_key_flag = 'Y')    
--- 04/08/2016 JPE MIGRATION R12    
--- 02/10/2018 OBE artf2945786 : INC0236790 : Probleme sur spécifique Extraction ALTAVEN
--------------------------------------------------------------------------------------------


--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PRIVEES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

cv_line 	                   	   VARCHAR2(100):='+----------------------------------------------------------------------+';
gn_ledger_id                 NUMBER;
-- AD--
gn_chart_of_acc_id                 gl_sets_of_books.chart_of_accounts_id%TYPE;
gv_flex_struct_code                fnd_id_flex_structures.id_flex_structure_code%TYPE;
gv_key_flex_op                     dka_parameters.varchar2_value%TYPE;
gv_key_flex_leg                    dka_parameters.varchar2_value%TYPE;
gv_flex_key_flag                   VARCHAR2(1);
gv_period_set_name                 gl_sets_of_books.period_set_name%TYPE;
-- AD --
gn_conc_request_id                 NUMBER;
gv_company_code                    VARCHAR2(4);
gn_seg3_flex_value_set_id          NUMBER;
gv_seg3_flex_value_set_name        VARCHAR2(60);
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

---------------------------------------------------------------------------------------------------
--  Nom           : init
--  Description   : Procédure d'initialisation du package
--                  Génère l'entête du fichier de sortie

--  PARAMETRES    :
--     N/A

--  VALEUR RETOURNEE :
--     N/A
----------------------------------------------------------------------------------------------------------
PROCEDURE init(pv_errbuf             IN      OUT       VARCHAR2,
               pn_retcode                    OUT       NUMBER,
               pv_company_num        IN                VARCHAR2,
			   pv_type_livre 		 IN                VARCHAR2)

IS
   company_flag         VARCHAR2(1);
   rec_param            dka_parameters%ROWTYPE;
   e_error              EXCEPTION;

BEGIN

   dka_tools_pkg.put_log_message('Début de la procédure init');
   
   pv_errbuf   := NULL;
   pn_retcode  := 0;

   -- Purge de la table temporaire.
   DELETE FROM dka_ieogletf01_int;

   -- Numéro du traitement.
   gn_conc_request_id := fnd_global.conc_request_id;

   --- 04/08/2016 JPE MIGRATION R12  
   -- Recuperation de la structure de clé comptable.
   -- SELECT fifs.id_flex_structure_code
   -- INTO   gv_flex_struct_code
   -- FROM   fnd_id_flex_structures fifs
   -- WHERE  fifs.application_id = 101
   -- AND    fifs.id_flex_code = 'GL#'
   -- AND    fifs.id_flex_num = gn_chart_of_acc_id;   

   -- Recupération des variables de la table des paramètres.
   -- dka_tools_pkg.get_parameter ('IEOGLETF01', 'CLE_ENTITE_OP', rec_param, pn_retcode, pv_errbuf);
   -- gv_key_flex_op  := rec_param.varchar2_value;

   -- IF pn_retcode != 0
     -- THEN
         -- pv_errbuf    := 'CLE_ENTITE_OP - ' || pv_errbuf;
         -- RAISE e_error;
   -- END IF;

   --dka_tools_pkg.get_parameter ('IEOGLETF01', 'CLE_ENTITE_LEG', rec_param, pn_retcode, pv_errbuf);
   --gv_key_flex_leg  := rec_param.varchar2_value;
                                                                                                                                                                                          
   -- IF pn_retcode != 0
     -- THEN
         -- pv_errbuf    := 'CLE_ENTITE_LEG - ' || pv_errbuf;
         -- RAISE e_error;
   -- END IF;

   -- Détermination de la structure de clé comptable
   IF (pv_type_livre = 'LEGAL')
      THEN
         gv_flex_key_flag := 'Y';
   ELSIF (pv_type_livre = 'OPERATIONNEL')
      THEN
         gv_flex_key_flag := 'N';
   ELSE
      pv_errbuf    := 'La structure de clé comptable est indéfinie dans la table des paramètres';
      RAISE e_error;
   END IF;
     
   /*-------- RECHERCHE DE L'ID DU JDV DU SEGMENT "COMPTE LOCAL" EN FONCTION DE L'ENTITE --------*/
   dka_tools_pkg.get_flex_key_seg_value_set ( pv_errbuf                 => pv_errbuf
                                              ,pn_retcode               => pn_retcode
                                              ,pv_legal_flex_key_flag   => gv_flex_key_flag
                                              -- on considère la ccf des organisations opérationnelles
                                              ,pn_segment_num           => 3
                                              ,pn_flex_value_set_id     => gn_seg3_flex_value_set_id ---valeur de retour
                                              ,pv_flex_value_set_name   => gv_seg3_flex_value_set_name);
   
   dka_tools_pkg.put_log_message('gv_flex_key_flag : ' || gv_flex_key_flag);
   dka_tools_pkg.put_log_message('gn_seg3_flex_value_set_id : ' || gn_seg3_flex_value_set_id);
   dka_tools_pkg.put_log_message('gv_seg3_flex_value_set_name : ' || gv_seg3_flex_value_set_name);
   dka_tools_pkg.put_log_message('pn_retcode : ' || pn_retcode);
   dka_tools_pkg.put_log_message('pv_errbuf : ' || pv_errbuf); 

   IF  pn_retcode != 0
      THEN
          pv_errbuf:= 'Erreur lors de la recherche de l''ID du JDV du segment "compte local"';
          dka_tools_pkg.put_outdebug_message(pv_errbuf);
          RETURN;
   END IF;
   gv_company_code := pv_company_num;
  -- AD --
  -- Verification du paramètre société.
   IF (gv_flex_key_flag = 'N') THEN   -- entité opérationnelle.
      BEGIN                           
        -- 04/08/2016 JPE MIGRATION R12     
		SELECT LEDGER_ID 
		INTO gn_ledger_id 
		FROM GL_LEDGERS
		WHERE SHORT_NAME = gv_company_code
		AND LEDGER_CATEGORY_CODE = 'PRIMARY';
		-- Recupération de l'entité.		
      EXCEPTION
         WHEN NO_DATA_FOUND
            THEN
                pn_retcode := 2;
                pv_errbuf  := SQLERRM;
                dka_tools_pkg.put_outdebug_message('Erreur : Pas de livre primaire trouvé pour le code société => '|| gv_company_code);
      END;
   ELSIF (gv_flex_key_flag = 'Y') THEN  -- Entité légale
	BEGIN
		-- 04/08/2016 JPE MIGRATION R12    
		SELECT glr.TARGET_LEDGER_id
		INTO gn_ledger_id
		FROM gl_ledger_relationships glr, gl_ledgers gl
		WHERE glr.TARGET_LEDGER_CATEGORY_CODE = 'SECONDARY'
		AND gl.short_name = gv_company_code
		AND glr.source_ledger_id = gl.ledger_id
		AND glr.RELATIONSHIP_TYPE_CODE ='JOURNAL'
		AND glr.RELATIONSHIP_ENABLED_FLAG ='Y';
	EXCEPTION
         WHEN NO_DATA_FOUND
            THEN
                pn_retcode := 2;
                pv_errbuf  := SQLERRM;
                dka_tools_pkg.put_outdebug_message('Erreur : Pas de livre secondaire trouvé pour le code société => '|| gv_company_code);
    END;
   END IF;
	
   -- Recherche du period_set_name en fonction du livre compatble.
   BEGIN
	   SELECT gsb.period_set_name
	   INTO   gv_period_set_name
	   FROM   gl_sets_of_books gsb
	   WHERE  gsb.set_of_books_id = gn_ledger_id;
   EXCEPTION
         WHEN NO_DATA_FOUND
            THEN
                pn_retcode := 2;
                pv_errbuf  := SQLERRM;
                dka_tools_pkg.put_outdebug_message('Erreur : Pas de type de période trouvée pour ce livre => '|| gn_ledger_id);
    END;
	
   dka_tools_pkg.put_log_message('gv_flex_key_flag : ' || gv_flex_key_flag);
   dka_tools_pkg.put_log_message('COMPANY CODE: ' || gv_company_code);
   dka_tools_pkg.put_log_message('gv_period_set_name : ' || gv_period_set_name);
   dka_tools_pkg.put_log_message('gn_ledger_id : ' || gn_ledger_id);
   dka_tools_pkg.put_log_message('gn_seg3_flex_value_set_id : ' || gn_seg3_flex_value_set_id);
   dka_tools_pkg.put_log_message('gv_seg3_flex_value_set_name : ' || gv_seg3_flex_value_set_name);
   dka_tools_pkg.put_log_message('gn_conc_request_id : ' || gn_conc_request_id);
   
   dka_tools_pkg.put_log_message('Fin de la procédure init');

EXCEPTION
WHEN e_error
   THEN
      pn_retcode := 2;
      dka_tools_pkg.put_outdebug_message(pv_errbuf);
WHEN OTHERS
   THEN
      pn_retcode := 2;
      pv_errbuf :=SQLERRM;
      dka_tools_pkg.put_outdebug_message(pv_errbuf);
END init;

---------------------------------------------------------------------------------------------------
--  Nom           : extraction_altaven
--  Description   : Procédure permet de produire le fichier altaven
--

--  PARAMETRES    :
--  pv_errbuf    		Entrée/Sortie		message d'erreur

--  VALEUR RETOURNEE :	pn_retcode
--     Description       : code de retour => Statut du traitement OA
--     Valeurs possibles : 0=normal, 1=warning, 2=erreur
----------------------------------------------------------------------------------------------------------
PROCEDURE extraction_altaven(  pv_period_year    IN            NUMBER,
                             pv_period_name    IN            VARCHAR2,
                             pv_errbuf        IN    OUT     VARCHAR2,
                             pn_retcode             OUT     NUMBER)

IS

BEGIN
   dka_tools_pkg.put_log_message('Debut de la procedure extraction_altaven');
   INSERT INTO dka_ieogletf01_int(creation_date,
                                  request_id,
                                  company_code,
                                  local_account,
                                  partner_code,
                                  amount,
                                  description)
	  ( -- JPE 09/08/2016 MIGRATION R12 REFONTE DE LA REQUETE D'EXTRACTION POUR ALTAVEN
	    SELECT SYSDATE,
		   gn_conc_request_id,
		   gv_company_code,
		   gcc.segment3,
		   gcc.segment5,
		   sum(gb.begin_balance_dr - gb.begin_balance_cr + gb.period_net_dr - gb.period_net_cr) * 100,
		   ffvv.description
	  FROM gl_balances               gb,
		   gl_code_combinations      gcc,
		   fnd_flex_values_vl        ffvv,
		   gl_periods                gp,
		   gl_ledgers         gl
	 WHERE 1 = 1
	   AND gcc.code_combination_id = gb.code_combination_id
	   AND gb.ledger_id = gn_ledger_id
	   AND gb.actual_flag = 'A'
	   --AND gcc.summary_flag = 'Y' -- OBE artf2945786
	   AND gv_flex_key_flag in ('N','Y')
	   AND gcc.segment1 = gv_company_code
	   AND ffvv.flex_value_set_id = gn_seg3_flex_value_set_id
	   AND ffvv.flex_value = gcc.segment3
	   AND (gcc.segment3 between '100000' and '799999')
	   AND gp.period_year = pv_period_year
	   AND gp.period_name = pv_period_name
	   AND gp.period_year = gb.period_year
	   AND gp.period_name = gb.period_name
	   AND gp.period_set_name = gv_period_set_name
	   --AND gcc.segment2  = 'T' -- OBE artf2945786
	   --AND gcc.segment4  = 'T' -- OBE artf2945786
	   --AND gcc.segment6  = 'T' -- OBE artf2945786
	   --AND gcc.segment7  = 'T' -- OBE artf2945786
	   --AND gcc.segment8  = 'T' -- OBE artf2945786
	   --AND gcc.segment9  = 'T' -- OBE artf2945786
	   --AND gcc.segment10 = 'T' -- OBE artf2945786
	   --AND gcc.segment11 = 'T' -- OBE artf2945786
	   --AND gcc.segment12 = 'T' -- OBE artf2945786
	   AND gb.ledger_id = gl.ledger_id
	   AND gb.currency_code = gl.currency_code
	 GROUP BY 	gv_company_code, 
				gcc.segment3, 
				gcc.segment5, 
				ffvv.description
   );

   EXCEPTION
      WHEN OTHERS
         THEN
             pn_retcode := 2;
             pv_errbuf  :=SQLERRM;
             dka_tools_pkg.put_outdebug_message(pv_errbuf);
             dka_tools_pkg.put_log_message('Fin de la procédure extraction_altaven : EXCEPTION OTHERS ');

END extraction_altaven;
---------------------------------------------------------------------------------------------------
--  Nom           : main
--  Description   : Procédure principale du traitement d'extraction de GL vers altaven
--

--  PARAMETRES    :
--  pv_errbuf    		Entrée/Sortie		message d'erreur

--  VALEUR RETOURNEE :	pn_retcode
--     Description       : code de retour => Statut du traitement OA
--     Valeurs possibles : 0=normal, 1=warning, 2=erreur
----------------------------------------------------------------------------------------------------------
PROCEDURE main( pv_errbuf         IN    OUT     VARCHAR2,
                pn_retcode        IN    OUT     NUMBER,
                pv_period_year    IN            NUMBER,
                pv_period_name    IN            VARCHAR2,
                pv_company_num    IN            VARCHAR2,
				pv_type_livre 	  IN            VARCHAR2)
IS
 vn_error_code         NUMBER;
 vv_error_mess         VARCHAR2(200);
 vn_request_id         NUMBER;

BEGIN
   dka_tools_pkg.put_out_header;
   dka_tools_pkg.put_log_message('Debut de la procedure main');
   dka_tools_pkg.put_outdebug_message(' L''exercice comptable : PERIODE_YEAR ====> '||pv_period_year );
   dka_tools_pkg.put_outdebug_message(' Le mois de l''arret comptable : PERIODE_NAME ====> '||pv_period_name );
   dka_tools_pkg.put_outdebug_message(' Le société : société ====> '||pv_company_num );
   dka_tools_pkg.put_outdebug_message(' Le type de livre : type_livre ====> '||pv_type_livre );
   pv_errbuf      :=NULL;
   pn_retcode     :=0;

   -- Initailisation des paramètres globaux.
   init ( vv_error_mess, vn_error_code, pv_company_num, pv_type_livre);

   IF vn_error_code != 0
   THEN
       pn_retcode:=1;
       vv_error_mess:= 'Erreur dans la procédure init. Sortie du programme';
       dka_tools_pkg.put_log_message(vv_error_mess);
       RETURN;
   END IF;

/*------------------------ CALCUL DU MONTANTS EN FONCTION DE LA PERIODE COMPTABLE SPECIFIE PAR L'UTILISATEUR------------------------*/

/*------------------------ CONSTRUCTION DU FICHIER altaven------------------------*/
   dka_ieogletf01_pkg.extraction_altaven(	pv_period_year,
											pv_period_name,
											vv_error_mess,
											vn_error_code);

   IF(vn_error_code!=0)
      THEN
          pv_errbuf:='Erreur dans la procédure extraction_altaven';
          dka_tools_pkg.put_outdebug_message(pv_errbuf);
          pn_retcode:=1;
          RETURN;
   END IF;

   dka_tools_pkg.put_outdebug_message('Lancement du traitement de l''édition du fichier altaven') ;
   vn_request_id := fnd_request.submit_request('DKA',			--APPL
    					                                 'DKA_IEOGLETF01_2',-- PROG : nom court du programme simultané de generation du fichier
    					                                 NULL,			 	-- PROGRAM_NAME
    					                                 NULL,			 	-- START
    					                                 FALSE,			 	-- SUB_REQUEST
    					                                 gv_company_code 	-- ARGUMENT1
    					                                 );

   IF vn_request_id = 0
      THEN
          pn_retcode :=1;
          pv_errbuf  := 'Lancement du traitement de l''édition du fichier altaven a echoue';
          dka_tools_pkg.put_outdebug_message(pv_errbuf);
          dka_tools_pkg.ins_prog_message(gn_conc_request_id,
                                         'IEOGLETF01',
                                         'OA',
                                         'DKA_IEOGLETF01_INT',
                                         'ALL LINES',
                                         NULL,
                                         gv_company_code,
                                         'E',
                                         pv_errbuf);
          RETURN;
   END IF;

   COMMIT; -- commit indispensable à la prise en compte du traitement pour FND_CONCURRENT.WAIT_FOR_REQUEST

   dka_tools_pkg.put_outdebug_message('Le traitement de l''édition du fichier altaven a été lancé pour le numéro : ' || TO_CHAR(vn_request_id)) ;

   dka_tools_pkg.put_log_message('Fin de la procedure main');
EXCEPTION
   WHEN OTHERS
      THEN
         pn_retcode := 2;
         pv_errbuf  := SQLERRM;
         dka_tools_pkg.put_outdebug_message(pv_errbuf);
         dka_tools_pkg.put_log_message('Fin de la procédure main : EXCEPTION OTHERS ');
END main;

END DKA_IEOGLETF01_PKG;
/
SHOW ERRORS
EXIT
