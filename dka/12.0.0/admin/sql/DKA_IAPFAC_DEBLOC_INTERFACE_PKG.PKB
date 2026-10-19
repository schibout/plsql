CREATE OR REPLACE PACKAGE BODY DKA_IAPFAC_DEBLOC_PKG AS
  --------------------------------------------------------------------------------
  -- $
  -- Capgemini
  -- Projet           : DALKIA Oracle Applications
  -- Nom              : DKA_IAPFAC_DEBLOC_PKG 
  -- Nom              : DKA_IAPFAC_DEBLOC_PKG 
  -- Description      : Body du package DKA_IAPFAC_DEBLOC_PKG ( IMPORT DES RECEPTIONS PO )
  -- Auteur           : SELO
  -- Date de création : 17/06/2020
  -- Doc. associée    :
  -- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur APPS
  --------------------------------------------------------------------------------
  -- Historique
  -- Date       Qui Description
  -- ---------- --- --------------------------------------------------------------
  -- 15/04/2022 ARA TASK0174529 - Correctif approbation ligne rapprochée d'une commande ivalua
  --------------------------------------------------------------------------------  
  
 --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PRIVEES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    TYPE summary_typ IS RECORD 
    (
     loaded_header_rows               NUMBER      -- Nb des en-entêtes chargées en table specifique
    ,loaded_transaction_rows          NUMBER      -- Nb des transactions chargés en table specifique
    ,rec_final_rows                   NUMBER      -- Nb des en-entêtes chargées en table specifique
    ,rejected_header_rows             NUMBER      -- Nb de Lignes en-entêtes rejectées
    ,rejected_io_rows                 NUMBER      -- Nb de Lignes transaction rejectés
    ,complete_header_rows             NUMBER      -- SELO
    ,inserted_header_rows             NUMBER      -- Nb de Lignes en-entêtes insérées
    ,inserted_transaction_rows        NUMBER      -- Nb de Lignes transaction insérés
    ,purged_header_rows               NUMBER      -- Nb de Lignes purgées en table spécifique   
    ,purged_interface_rows            NUMBER      -- Nb de Lignes purgées en table spécifique 
    , purged_errors_rows              NUMBER
    , purged_transaction_rows         NUMBER
    ,message_flag                     NUMBER      -- Flag d'entete etat des erreurs
    ,reprise_flag                     VARCHAR2(1) -- Flag reprise
    ,warning_flag                     VARCHAR2(1) -- Flag warning
    )
    ;

    g_summary                      summary_typ;

    g_user_id                      fnd_user.user_id%TYPE;
    g_login_id                     fnd_logins.login_id%TYPE;
    g_request_id                   fnd_concurrent_requests.request_id%TYPE;
    g_loader_request_id            fnd_concurrent_requests.request_id%TYPE;
    gv_printer                     fnd_concurrent_requests.printer%TYPE;
    g_number_of_copies             fnd_concurrent_requests.number_of_copies%TYPE;
    g_tempo                        NUMBER;
    g_gl_date                      DATE; -- OBE
    --g_nb_entetes_group             NUMBER;


  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PRIVEES
  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  ------------------------------------------------------------------------------------
  -- Nom              : Main
  -- Description      : Procédure principale du traitement
  --
  -- PARAMETRES       : p_errbuf         Sortie Message d'erreur
  --                    p_retcode        Sortie Code Retour de la procédure
  --                                             '0' : Normal
  --                                             '1' : Avertissement
  --                                             '2' : Erreur
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  ------------------------------------------------------------------------------------
g_group_id NUMBER := 0;
g_group_id_correct NUMBER := 0;  --SELO
g_group_id_add NUMBER := 0;  --SELO
/*
 *************************************************************************
 * PROCEDURE NAME : Output_Header
 *
 * DESCRIPTION
 *  Procédure pour insérer une en-tête dans le fichier de sortie
 *
 * PARAMETERS
 * ==========
 * NAME              DESCRIPTION
 * ----------------- ------------------------------------------------------
 *
 *
 ************************************************************************
 */

  PROCEDURE output_header
  IS
        cv_line                     VARCHAR2 (100);
        v_conc_program_name         fnd_concurrent_programs.concurrent_program_name%TYPE;
        v_user_conc_program_name    fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;
  BEGIN

        cv_line    := '----------------------------------------------------------------------------------';

        ----- Récupération des noms abrégé et long du traitement en fonction de la langue -----
        BEGIN
            SELECT fcp.concurrent_program_name,
                   fcpt.user_concurrent_program_name
            INTO   v_conc_program_name,
                   v_user_conc_program_name
            FROM   fnd_concurrent_programs fcp,
                   fnd_concurrent_programs_tl fcpt
            WHERE  fcp.application_id = Fnd_Global.prog_appl_id
            AND    fcp.concurrent_program_id = Fnd_Global.conc_program_id
            AND    fcpt.application_id = Fnd_Global.prog_appl_id
            AND    fcpt.concurrent_program_id = Fnd_Global.conc_program_id
            AND    fcpt.LANGUAGE = Fnd_Global.current_language;
        EXCEPTION
            WHEN OTHERS
            THEN
                v_user_conc_program_name    := '???????????????????????';
                v_conc_program_name         := '???????';
        END;


        Fnd_File.put_line (Fnd_File.output, cv_line );
		Fnd_File.put_line (Fnd_File.output, 'COMPTE-RENDU DU TRAITEMENT « DKA : Import des codes de déblocage Facture depuis IVALUA »');
        Fnd_File.put_line (Fnd_File.output, 'Traitement n° '||fnd_global.conc_request_id);
        Fnd_File.put_line (Fnd_File.output, 'Le : ' || TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') );
		Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10));
        --Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10) || CHR(10));
  END output_header;
  
  
 /*
 *************************************************************************
 * PROCEDURE NAME : Request_parameters
 *
 * DESCRIPTION
 *  Procédure pour afficher les valeurs de paramètres du traitement
 *
 * PARAMETERS
 * ==========
 * NAME              DESCRIPTION
 * ----------------- ------------------------------------------------------
 *
 ************************************************************************
 */

  PROCEDURE Request_parameters
  IS

      CURSOR cur_parameters
            IS
            SELECT form_left_prompt
            FROM   fnd_concurrent_requests fcr,
                   fnd_concurrent_programs fcp,
                   fnd_descr_flex_col_usage_vl fdfcu
            WHERE  fdfcu.descriptive_flexfield_name = '$SRS$.'||fcp.concurrent_program_name
            AND    fcp.concurrent_program_id = fcr.concurrent_program_id
            AND    fcr.request_id = Fnd_Global.conc_request_id
            ORDER BY fdfcu.column_seq_num
            ;
        rec_parameters        cur_parameters%ROWTYPE;

        sql_req               VARCHAR2(500);
        v_argument_number    VARCHAR2(12);
        v_argument_num       NUMBER;
        v_argument_value     VARCHAR2(240);
  BEGIN

        Fnd_File.put_line (Fnd_File.log, 'PARAMETRES : ');
        Fnd_File.put_line (Fnd_File.log, '--------------');
       
	    Fnd_File.put_line (Fnd_File.output, 'PARAMETRES : ');		
        Fnd_File.put_line (Fnd_File.output, '--------------');
		

        
		v_argument_num := 1;

        OPEN cur_parameters;
        FETCH cur_parameters INTO rec_parameters;

             IF (cur_parameters%FOUND)
             THEN
                   v_argument_number := 'ARGUMENT'||v_argument_num;

                   sql_req := 'SELECT '||v_argument_number||
                              ' FROM fnd_concurrent_requests '||
                              'WHERE request_id = Fnd_Global.conc_request_id';

                   EXECUTE IMMEDIATE sql_req INTO v_argument_value;

                   --Fnd_File.put_line (Fnd_File.output, rec_parameters.form_left_prompt||' : '||v_argument_value);
                   Fnd_File.put_line (Fnd_File.log, rec_parameters.form_left_prompt||' : '||v_argument_value);
                   Fnd_File.put_line (Fnd_File.output, rec_parameters.form_left_prompt||' : '||v_argument_value);

                   LOOP
                      FETCH cur_parameters INTO rec_parameters;
                      EXIT WHEN cur_parameters%NOTFOUND;

                          v_argument_num := v_argument_num + 1;
                          v_argument_number := 'ARGUMENT'||v_argument_num;

                          sql_req := 'SELECT '||v_argument_number||
                                     ' FROM fnd_concurrent_requests '||
                                     'WHERE request_id = Fnd_Global.conc_request_id';

                          EXECUTE IMMEDIATE sql_req INTO v_argument_value;

                         -- Fnd_File.put_line (Fnd_File.output, rec_parameters.form_left_prompt||' : '||v_argument_value);
                          Fnd_File.put_line (Fnd_File.log, rec_parameters.form_left_prompt||' : '||v_argument_value);
						  Fnd_File.put_line (Fnd_File.output, rec_parameters.form_left_prompt||' : '||v_argument_value);
                   END LOOP;

                   --Fnd_File.put_line (Fnd_File.output,CHR(10));

            ELSE
                   --Fnd_File.put_line (Fnd_File.output,'Aucun argument');
                   Fnd_File.put_line (Fnd_File.log,'Aucun argument');
            END IF;

        CLOSE cur_parameters;
		Fnd_File.put_line (Fnd_File.output, CHR(10));

  END Request_parameters;

 /*
 *************************************************************************
 * PROCEDURE NAME : Output_End
 *
 * DESCRIPTION
 *  Procédure pour insérer une fin dans le fichier de sortie
 *
 * PARAMETERS
 * ==========
 * NAME              DESCRIPTION
 * ----------------- ------------------------------------------------------
 *
 *
 ************************************************************************
 */

  PROCEDURE output_end
  IS
        cv_line                     VARCHAR2 (100);
  BEGIN

        cv_line    := '---------------------------------------------------------------------------';

        Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10));
        Fnd_File.put_line (Fnd_File.output, 'Programme terminé le : ' || TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || CHR(10));
        Fnd_File.put_line (Fnd_File.output, cv_line);
  END output_end;

 /*
 *************************************************************************
 * PROCEDURE NAME : Add_Message
 *
 * DESCRIPTION
 *  Procédure pour insérer un message dans le fichier de sortie
 *
 * PARAMETERS
 * ==========
 * NAME              DESCRIPTION
 * ----------------- ------------------------------------------------------
 *
 *
 ************************************************************************
 */

  PROCEDURE Add_Message  (p_invoice_id        IN  VARCHAR2,
                          HOLD_CODE          IN  VARCHAR2,
                          record_id           IN  VARCHAR2,
                          p_message_text      IN  VARCHAR2,
                          p_phase             IN  VARCHAR2
                          ) 
  IS
        cv_line                     VARCHAR2 (500);
		p_invoice_num                     VARCHAR2 (500);
  BEGIN

    IF  g_summary.message_flag = 0 THEN
    --  cv_line := 'Liste des rejets de validation :';
    --  Fnd_File.put_line (Fnd_File.output, CHR(10)||cv_line);
    --  cv_line := '-----------------';
    --  Fnd_File.put_line (Fnd_File.output, cv_line);
      cv_line := 'Numéro Facture   Code Blocage         RECORD_ID  Phase       Message';
      Fnd_File.put_line (Fnd_File.output, cv_line);
      cv_line := '---------------  -------------------  ---------  ----------  ---------------------------------';
      Fnd_File.put_line (Fnd_File.output, cv_line);
      g_summary.message_flag := 1;
    END IF;
	begin 
    select invoice_num into p_invoice_num from ap_invoices_all where invoice_id = p_invoice_id;
	exception when others then
	p_invoice_num :=null;
	end;
	
    cv_line := RPAD(nvl(p_invoice_num,' '),15,' ') ||'  '||RPAD(NVL(HOLD_CODE,' '),19,' ') ||'  '||RPAD(NVL(record_id,' '),9,' ') ||'  '||RPAD(NVL(p_phase,' '),10,' ')|| '  ' || p_message_text ;

    Fnd_File.put_line (Fnd_File.output, cv_line);
   

  END Add_Message;

 
 FUNCTION get_organization_id (
                               p_societe IN VARCHAR2
                              ,p_region  IN VARCHAR2
                              )          
  RETURN NUMBER
  IS
    v_organization_id NUMBER;  
  BEGIN  
 
     -- Recherche si le fournisseur est présent dans l'OI             
     BEGIN
        SELECT hr.ORGANIZATION_ID
        INTO   v_organization_id
        FROM   hr_operating_units hr
        WHERE  hr.NAME = p_region||p_societe
        ; 
     EXCEPTION
     WHEN NO_DATA_FOUND
     THEN
         v_organization_id := -1;
     END;

     ----- return value -----
     RETURN (v_organization_id);  
  
END get_organization_id;  



--------------- FUNCTION GET_VENDOR_SITE_ID  ---------------------------------------

 FUNCTION GET_VENDOR_SITE_ID ( P_VENDOR_NUM IN VARCHAR2 , P_VENDOR_SITE_CODE IN VARCHAR2 , P_ORG_ID IN NUMBER ) RETURN VARCHAR2
  IS
 -----------------------------------------------------------------------------------
    V_VENDOR_SITE_ID NUMBER;

  BEGIN

     -- RECHERCHE SI LE SITE CODE FOURNISSEUR EST PRÉSENT DANS L'OI
     BEGIN
        SELECT ASSA.VENDOR_SITE_ID
            INTO V_VENDOR_SITE_ID
              FROM AP_SUPPLIERS ASA,
                   AP_SUPPLIER_SITES_ALL ASSA
              WHERE 1=1
              AND ASSA.VENDOR_SITE_CODE LIKE SUBSTR(P_VENDOR_SITE_CODE,5)||'%'
              AND ASA.SEGMENT1  = P_VENDOR_NUM
              AND ASSA.ORG_ID = P_ORG_ID
              AND ASA.VENDOR_ID =   ASSA.VENDOR_ID
              ;

      EXCEPTION
      WHEN others THEN 
          V_VENDOR_SITE_ID := -1;
          --fnd_file.put_line(fnd_file.log ,'Erreur de trouver un site code fournisseur||'|| V_VENDOR_SITE_ID ||'| erreur: '||sqlerrm);
    END;

     ----- RETURN VALUE -----
     RETURN (V_VENDOR_SITE_ID);

END GET_VENDOR_SITE_ID;

--------------------------------------------------------------------------------------
/*
 *************************************************************************
 * PROCEDURE NAME : init
 * 
 * DESCRIPTION
 *  Procédure d'initialisation des variables globales
 *
 * PARAMETERS
 * ==========
 * NAME              DESCRIPTION
.* ----------------- ------------------------------------------------------
 * p_errbuf         Retour de message éventuel
 * p_retcode        Statut du traitement en sortie
 ************************************************************************
 */

  PROCEDURE init (
                  p_errbuf    OUT      VARCHAR2,
                  p_retcode   OUT      NUMBER,
                  p_reprise   IN       VARCHAR2--,
                  --p_gl_date   IN       VARCHAR2
                  )
  IS

    v_current_program_unit    VARCHAR2(30);
    v_step_program_error      VARCHAR2(1000);
    program_error             EXCEPTION;
    rec_param dka_parameters%ROWTYPE;

  BEGIN

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début init');

        ----------------------------------
        -- Initialisation des variables --
        ----------------------------------
        p_errbuf  := NULL;
        p_retcode := 0;
        v_current_program_unit := 'INIT';

        ------------------------
        -- Variables globales --
        ------------------------ 

        g_user_id                      := fnd_global.user_id;
        g_login_id                     := fnd_global.login_id;
        g_request_id                   := fnd_global.conc_request_id;
        g_tempo                        := 20;

        -- Variables globales de comptage

        g_summary.loaded_header_rows             := 0;
		g_summary.rec_final_rows                 := 0;
        g_summary.loaded_transaction_rows        := 0;

        g_summary.rejected_header_rows           := 0;
        g_summary.rejected_io_rows               := 0;
        g_summary.complete_header_rows           := 0;

        g_summary.inserted_header_rows           := 0;
        g_summary.inserted_transaction_rows      := 0;

        g_summary.purged_header_rows             := 0;
        g_summary.purged_interface_rows          := 0;
        g_summary.purged_errors_rows             := 0;
        g_summary.purged_transaction_rows        := 0;
        
        g_summary.message_flag                   := 0;
        g_summary.reprise_flag                   := NVL(p_reprise,'N');
        g_summary.warning_flag                   := 'N';
        
        
        -- Formatage de la date comptable 
        --bg_gl_date := TRUNC(fnd_date.canonical_to_date(p_gl_date)); -- SELO
        g_gl_date:=sysdate; -- SELO
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin init');
        
        BEGIN
           SELECT printer
                 ,number_of_copies
           INTO   gv_printer
                 ,g_number_of_copies
           FROM   fnd_concurrent_requests fcr
           WHERE  fcr.request_id = g_request_id;
        EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
           Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Erreur de récupération de l''imprimante');
           gv_printer := NULL;
           g_number_of_copies := 0;
        END;
        
    EXCEPTION
        WHEN program_error THEN
             fnd_file.put_line(fnd_file.log, 'ERREUR : ' || v_step_program_error);
             RAISE; 
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'INIT : ' ||SQLERRM;
  END init;
/*
 *************************************************************************
 * PROCEDURE NAME : validate_data_group
 * 
 * DESCRIPTION
 *  Procédure d'insertion dans les tables finales
 *
 * PARAMETERS
 * ==========
 * NAME               DESCRIPTION
.* -----------------  ------------------------------------------------------
 * p_errbuf          Retour de message éventuel
 * p_retcode         Statut du traitement en sortie
 * 
 ************************************************************************
 */
--------------------------------------------------------------------------------------
PROCEDURE validate_data_group(p_Errbuf OUT VARCHAR2, p_retcode OUT NUMBER, v_RECORD_ID NUMBER) IS

  v_person_id                   NUMBER;
  v_processing_status_code      VARCHAR2(100) DEFAULT 'PENDING';
  v_receipt_source_code         VARCHAR2(100) DEFAULT 'VENDOR';
  v_transaction_type            VARCHAR2(100) DEFAULT 'NEW';
  v_processing_mode_code        VARCHAR2(100) DEFAULT 'BATCH';
  v_code_site_four              VARCHAR2(100);
  v_org_id                      NUMBER;
  v_pers_id                     NUMBER;
  v_rcv_header_id               NUMBER;
  v_message                     VARCHAR2(500);
  v_flag_erreur                 BOOLEAN := FALSE;
  v_flag_erreur_trans           BOOLEAN := FALSE;
  v_ship_to_organization_id     NUMBER;
  v_code_site_four1             VARCHAR2(240);
  v_receive_trans_id            NUMBER;
  v_ship_to_location            VARCHAR2(100); -- OBE
  v_vendor_site_code            VARCHAR2(25); -- OBE
  v_vendor_site_code_2          VARCHAR2(25); -- OBE
  v_location_code               VARCHAR2(60); -- OBE
  v_deliver_to_location         VARCHAR2(60); -- OBE 
  v_deliver_to_location_id      NUMBER;       -- RBE
  v_DELIVER_TO_PERSON           VARCHAR2(240);
  e_err_org_not_exist           EXCEPTION;
  v_Multi_receipt               NUMBER; -- SELO
  v_org_ok                      Number; -- SELO
  v_vendor_id                   Number; -- SELO
  v_start_date                  DATE;
  V_RECEIPT_DATE                DATE;
  v_CMD_ID                      Number;
  v_vendor_site_id              Number;
  v_LIGNE_ID                    Number;
  v_reject                      Number;
  vs_ship_to_Org_Id             Number; 
  V_SHIPMENT_HEADER_ID          Number;
  vs_vendor_id                  Number;
  vs_vendor_site_id             Number;
  vs_packing_slip               VARCHAR2(60);
  v_rct_quantity                Number;
  v_shipment_line_id            Number;
  v_TRANSACTION_ID              Number;
  v_PARENT_TRANSACTION_ID       Number; 
  V_UNIT_OF_MEASURE             VARCHAR2(60);
  v_LINE_LOCATION_ID            Number; 
  v_PO_DISTRIBUTION_ID          Number; 
  
  
  V_Check_Warning     NUMBER;
  V_Check_Reject      NUMBER;
  
  -- Cursor des receptions
  CURSOR cur_recept IS
    SELECT *
      FROM dka.DKA_IAPFAC_DEBLOC_INTERFACE didi
     WHERE 1 = 1
      -- AND load_request_id = DECODE(g_loader_request_id, -1, load_request_id, g_loader_request_id) -- 
      -- AND flag = '-1' -- 
       and didi.record_id=v_RECORD_ID
     ORDER BY  record_id -- SOCIETE, REGION  ajout
       FOR UPDATE OF STATUT--, shipment_line_id, TRANSACTION_ID , PARENT_TRANSACTION_ID, vendor_id, ORG_ID  , VENDOR_SITE_ID, request_id       --, ORG_ID, CODE_SITE_FOUR -- 
       ;

BEGIN

  Fnd_File.put_line(Fnd_File.LOG, TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début validate_data');
  Fnd_File.put_line(Fnd_File.LOG,
                    TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                    'Validation des données dans les tables spécifiques - record_id : '||v_RECORD_ID);

  FOR rec_cur_recept IN cur_recept LOOP
    
       v_flag_erreur := FALSE;
       -- RG4332-01
	    BEGIN 
		   V_Check_Reject := null;
	          select 1 into V_Check_Reject
                from ap_invoices_all
               where invoice_ID =rec_cur_recept.invoice_id;
	       EXCEPTION
	        when others then
			    null;
			END;
	   if V_Check_Reject is not null then
	        begin 
	          select 1 into V_Check_Warning
                from ap_invoices_all
               where invoice_ID =rec_cur_recept.invoice_id
		         and cancelled_date is null
		     	and cancelled_by is null;
	        
	        exception
	          when others then
	        
             v_message :=dka_tools_pkg.get_message('DKA','DKA_IAPFAC_DEBLOC_W01', 'XXXXX', rec_cur_recept.invoice_id );
                     --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                     DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                     'DKA_IAPFAC_DEBLOC_INTERFACE', --prog_name
                                                     'INVOICE_ID',               --source
                                                     'DKA_IAPFAC_DEBLOC_INTERFACE' ,   --table_name
                                                     rec_cur_recept.RECORD_ID,  --table_id
                                                     'INVOICE_ID',  --column_name
                                                     rec_cur_recept.INVOICE_ID, --column_value
                                                     'W',                       --message_type
                                                    v_message                   --message_text
                                                     );
                         v_flag_erreur := TRUE;
                     
                     UPDATE DKA_IAPFAC_DEBLOC_INTERFACE
                      SET STATUT = 'COMPLETE'
                        , request_id = g_request_id
                    WHERE CURRENT OF cur_recept;
            
             END;	  
         if (V_Check_Warning is not null) and (not v_flag_erreur) then
            BEGIN 
	          select 1 into V_Check_Warning
                from ap_invoices_all
               where invoice_ID =rec_cur_recept.invoice_id
		         and WFAPPROVAL_STATUS <> 'WFAPPROVED';
	        EXCEPTION
	          when others then
	        
             v_message :=dka_tools_pkg.get_message('DKA','DKA_IAPFAC_DEBLOC_W02', 'XXXXX', rec_cur_recept.invoice_id );
                     --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                     DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                     'DKA_IAPFAC_DEBLOC_INTERFACE', --prog_name
                                                     'INVOICE_ID',               --source
                                                     'DKA_IAPFAC_DEBLOC_INTERFACE' ,   --table_name
                                                     rec_cur_recept.RECORD_ID,  --table_id
                                                     'INVOICE_ID',  --column_name
                                                     rec_cur_recept.INVOICE_ID, --column_value
                                                     'W',                       --message_type
                                                     v_message                   --message_text
                                                     );
                         v_flag_erreur := TRUE;
                     
                     UPDATE DKA_IAPFAC_DEBLOC_INTERFACE
                      SET STATUT = 'COMPLETE'
                        , request_id = g_request_id
                    WHERE CURRENT OF cur_recept;
            
             END;
      end if;
	  if (V_Check_Warning is not null) and (not v_flag_erreur) then
	        Begin
			      V_Check_Reject:=0;
		    	  select 1 into V_Check_Reject
                    from ap_holds_all
                   where hold_id = rec_cur_recept.hold_id;
	        EXCEPTION
	          when others then
			    null;
			END;
	  
	        if V_Check_Reject = 1 then
               BEGIN 
	            select 1 into V_Check_Warning
                  from ap_holds_all aha
                 where --invoice_id = rec_cur_recept.invoice_id
	  	         --and 
				     hold_id = rec_cur_recept.hold_id
	  	         and release_lookup_code is null;
	           EXCEPTION
	             when others then
	           
                v_message :=dka_tools_pkg.get_message('DKA','DKA_IAPFAC_DEBLOC_W03', 'XXXXX', rec_cur_recept.hold_id );
                        --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                        DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                        'DKA_IAPFAC_DEBLOC_INTERFACE', --prog_name
                                                        'hold_id',               --source
                                                        'DKA_IAPFAC_DEBLOC_INTERFACE' ,   --table_name
                                                        rec_cur_recept.RECORD_ID,  --table_id
                                                        'hold_id',  --column_name
                                                        rec_cur_recept.hold_id, --column_value
                                                        'W',                       --message_type
                                                       v_message                   --message_text
                                                        );
                            v_flag_erreur := TRUE;
                        
                        UPDATE DKA_IAPFAC_DEBLOC_INTERFACE
                         SET STATUT = 'COMPLETE'
                           , request_id = g_request_id
                       WHERE CURRENT OF cur_recept;
              
                END;
			  END IF;
             END if;
        ELSE 
		    V_Check_Warning :=1;
		END IF;
      if not v_flag_erreur then
	  V_Check_Reject := null;
	    -- RG4333-01 
		v_flag_erreur := FALSE;
	    IF rec_cur_recept.INVOICE_ID IS NULL THEN
                v_message :=dka_tools_pkg.get_message('DKA','DKA_IAPFAC_DEBLOC_R01');
                --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                'DKA_IAPFAC_DEBLOC_INTERFACE', --prog_name
                                                'INVOICE_ID',               --source
                                                'DKA_IAPFAC_DEBLOC_INTERFACE' ,   --table_name
                                                rec_cur_recept.RECORD_ID,  --table_id
                                                'INVOICE_ID',  --column_name
                                                rec_cur_recept.INVOICE_ID, --column_value
                                                'E',                       --message_type
                                               v_message                   --message_text
                                                );
                    v_flag_erreur := TRUE;
                
                UPDATE DKA_IAPFAC_DEBLOC_INTERFACE
                 SET STATUT = 'REJECTED'
                   , request_id = g_request_id
               WHERE CURRENT OF cur_recept;
        ELSE
	       BEGIN 
		   V_Check_Reject := null;
	          select 1 into V_Check_Reject
                from ap_invoices_all
               where invoice_ID =rec_cur_recept.invoice_id;
	       EXCEPTION
	        when others then
	      
           v_message :=dka_tools_pkg.get_message('DKA','DKA_IAPFAC_DEBLOC_R02', 'XXXXX', rec_cur_recept.invoice_id );
                   --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                   DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                   'DKA_IAPFAC_DEBLOC_INTERFACE', --prog_name
                                                   'INVOICE_ID',               --source
                                                   'DKA_IAPFAC_DEBLOC_INTERFACE' ,   --table_name
                                                   rec_cur_recept.RECORD_ID,  --table_id
                                                   'INVOICE_ID',  --column_name
                                                   rec_cur_recept.INVOICE_ID, --column_value
                                                   'E',                       --message_type
                                                  v_message                   --message_text
                                                   );
                       v_flag_erreur := TRUE;
                   
                   UPDATE DKA_IAPFAC_DEBLOC_INTERFACE
                    SET STATUT = 'REJECTED'
                      , request_id = g_request_id
                  WHERE CURRENT OF cur_recept;
         
           END;	
		END IF;
		
		-- RG4333-02 
		IF rec_cur_recept.HOLD_CODE IS NULL THEN
                v_message :=dka_tools_pkg.get_message('DKA','DKA_IAPFAC_DEBLOC_R03');
                --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                'DKA_IAPFAC_DEBLOC_INTERFACE', --prog_name
                                                'HOLD_CODE',               --source
                                                'DKA_IAPFAC_DEBLOC_INTERFACE' ,   --table_name
                                                rec_cur_recept.RECORD_ID,  --table_id
                                                'HOLD_CODE',  --column_name
                                                rec_cur_recept.HOLD_CODE, --column_value
                                                'E',                       --message_type
                                               v_message                   --message_text
                                                );
                    v_flag_erreur := TRUE;
                
                UPDATE DKA_IAPFAC_DEBLOC_INTERFACE
                 SET STATUT = 'REJECTED'
                   , request_id = g_request_id
               WHERE CURRENT OF cur_recept;
        ELSE
	       BEGIN 
		   V_Check_Reject := null;
           SELECT  1 into V_Check_Reject
            FROM
                DKA_STRANSCO_LINES DSTL,
                DKA_STRANSCO_HEADERS DSTH
            WHERE
                DSTL.SET_ID = DSTH.SET_ID
                 AND DSTH.SET_NAME LIKE 'DKA_BLOCAGES_IVALUA'
				 AND DSTL.param1_value=rec_cur_recept.HOLD_CODE
                 AND DSTL.ENABLE = 'Y'
                AND NVL(DSTL.END_DATE  ,TRUNC(SYSDATE) )   >= TRUNC(SYSDATE)
                AND NVL(DSTL.START_DATE,TRUNC(SYSDATE))  <= TRUNC(SYSDATE)
           ;
	       EXCEPTION
	        when others then
	      
           v_message :=dka_tools_pkg.get_message('DKA','DKA_IAPFAC_DEBLOC_R04', 'XXXXX', rec_cur_recept.HOLD_CODE );
                   --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                   DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                   'DKA_IAPFAC_DEBLOC_INTERFACE', --prog_name
                                                   'HOLD_CODE',               --source
                                                   'DKA_IAPFAC_DEBLOC_INTERFACE' ,   --table_name
                                                   rec_cur_recept.RECORD_ID,  --table_id
                                                   'HOLD_CODE',  --column_name
                                                   rec_cur_recept.HOLD_CODE, --column_value
                                                   'E',                       --message_type
                                                  v_message                   --message_text
                                                   );
                       v_flag_erreur := TRUE;
                   
                   UPDATE DKA_IAPFAC_DEBLOC_INTERFACE
                    SET STATUT = 'REJECTED'
                      , request_id = g_request_id
                  WHERE CURRENT OF cur_recept;
         
           END;	
		END IF;
	  -- RG4333-03
		IF rec_cur_recept.HOLD_ID IS NULL THEN
                v_message :=dka_tools_pkg.get_message('DKA','DKA_IAPFAC_DEBLOC_R05');
                --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                'DKA_IAPFAC_DEBLOC_INTERFACE', --prog_name
                                                'HOLD_ID',               --source
                                                'DKA_IAPFAC_DEBLOC_INTERFACE' ,   --table_name
                                                rec_cur_recept.RECORD_ID,  --table_id
                                                'HOLD_ID',  --column_name
                                                rec_cur_recept.HOLD_ID, --column_value
                                                'E',                       --message_type
                                               v_message                   --message_text
                                                );
                    v_flag_erreur := TRUE;
                
                UPDATE DKA_IAPFAC_DEBLOC_INTERFACE
                 SET STATUT = 'REJECTED'
                   , request_id = g_request_id
               WHERE CURRENT OF cur_recept;
        ELSE
	       BEGIN 
		   V_Check_Reject := null;
           
		   SELECT 1 into V_Check_Reject
            FROM ap_holds_all aha
            WHERE hold_id = rec_cur_recept.hold_id
           ;
	       EXCEPTION
	        when others then
	      
           v_message :=dka_tools_pkg.get_message('DKA','DKA_IAPFAC_DEBLOC_R06', 'XXXXX', rec_cur_recept.hold_id );
                   --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                   DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                   'DKA_IAPFAC_DEBLOC_INTERFACE', --prog_name
                                                   'hold_id',               --source
                                                   'DKA_IAPFAC_DEBLOC_INTERFACE' ,   --table_name
                                                   rec_cur_recept.RECORD_ID,  --table_id
                                                   'hold_id',  --column_name
                                                   rec_cur_recept.hold_id, --column_value
                                                   'E',                       --message_type
                                                  v_message                   --message_text
                                                   );
                       v_flag_erreur := TRUE;
                   
                   UPDATE DKA_IAPFAC_DEBLOC_INTERFACE
                    SET STATUT = 'REJECTED'
                      , request_id = g_request_id
                  WHERE CURRENT OF cur_recept;
         
           END;	
			 
	    IF V_Check_Reject IS NOT NULL THEN
		 BEGIN
		    SELECT 1 into V_Check_Reject
              FROM ap_holds_all aha
              WHERE hold_id = rec_cur_recept.hold_id
		        and invoice_id = rec_cur_recept.invoice_id
             ;
		 EXCEPTION
	        when others then
	      
           v_message :=dka_tools_pkg.get_message('DKA','DKA_IAPFAC_DEBLOC_R07', 'XXXXX', rec_cur_recept.hold_id, 'YYYYY', rec_cur_recept.INVOICE_ID );
                   --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                   DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                   'DKA_IAPFAC_DEBLOC_INTERFACE', --prog_name
                                                   'hold_id',               --source
                                                   'DKA_IAPFAC_DEBLOC_INTERFACE' ,   --table_name
                                                   rec_cur_recept.RECORD_ID,  --table_id
                                                   'hold_id',  --column_name
                                                   rec_cur_recept.hold_id, --column_value
                                                   'E',                       --message_type
                                                  v_message                   --message_text
                                                   );
                       v_flag_erreur := TRUE;
                   
                   UPDATE DKA_IAPFAC_DEBLOC_INTERFACE
                    SET STATUT = 'REJECTED'
                      , request_id = g_request_id
                  WHERE CURRENT OF cur_recept;
         
          END;	
		 BEGIN
		    SELECT 1 into V_Check_Reject
              FROM ap_holds_all aha
              WHERE hold_id = rec_cur_recept.hold_id
		        and HOLD_LOOKUP_code = rec_cur_recept.hold_code
             ;
		 EXCEPTION
	        when others then
	      
           v_message :=dka_tools_pkg.get_message('DKA','DKA_IAPFAC_DEBLOC_R08', 'XXXXX', rec_cur_recept.hold_id, 'YYYYY', rec_cur_recept.hold_code );
                   --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                   DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                   'DKA_IAPFAC_DEBLOC_INTERFACE', --prog_name
                                                   'hold_id',               --source
                                                   'DKA_IAPFAC_DEBLOC_INTERFACE' ,   --table_name
                                                   rec_cur_recept.RECORD_ID,  --table_id
                                                   'hold_id',  --column_name
                                                   rec_cur_recept.hold_id, --column_value
                                                   'E',                       --message_type
                                                  v_message                   --message_text
                                                   );
                       v_flag_erreur := TRUE;
                   
                   UPDATE DKA_IAPFAC_DEBLOC_INTERFACE
                    SET STATUT = 'REJECTED'
                      , request_id = g_request_id
                  WHERE CURRENT OF cur_recept;
         
          END;	
		  BEGIN
		      SELECT 1 into V_Check_Reject
                FROM ap_holds_all aha 
                   , po_headers_all pha
                   , po_lines_all pla
                   , po_line_locations_all plla
               WHERE aha.line_location_id = plla.line_location_id(+)
                 AND plla.po_line_id = pla.po_line_id(+)
                 AND plla.po_header_id = pha.po_header_id (+)
                 and aha.hold_id = rec_cur_recept.hold_id
				 and nvl(pla.attribute8,'A') = nvl(rec_cur_recept.IVALUA_PO_LINE_ID,'A')
             ;
		 EXCEPTION
	        when others then
	      
           v_message :=dka_tools_pkg.get_message('DKA','DKA_IAPFAC_DEBLOC_R09', 'XXXXX', rec_cur_recept.hold_id, 'YYYYY', rec_cur_recept.IVALUA_PO_LINE_ID );
                   --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                   DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                   'DKA_IAPFAC_DEBLOC_INTERFACE', --prog_name
                                                   'IVALUA_PO_LINE_ID',               --source
                                                   'DKA_IAPFAC_DEBLOC_INTERFACE' ,   --table_name
                                                   rec_cur_recept.RECORD_ID,  --table_id
                                                   'IVALUA_PO_LINE_ID',  --column_name
                                                   rec_cur_recept.IVALUA_PO_LINE_ID, --column_value
                                                   'E',                       --message_type
                                                  v_message                   --message_text
                                                   );
                       v_flag_erreur := TRUE;
                   
                   UPDATE DKA_IAPFAC_DEBLOC_INTERFACE
                    SET STATUT = 'REJECTED'
                      , request_id = g_request_id
                  WHERE CURRENT OF cur_recept;
         
          END;
		  BEGIN
		      SELECT 1 into V_Check_Reject
                FROM ap_holds_all aha
               WHERE aha.hold_id = rec_cur_recept.hold_id
				 and aha.attribute4 = 'Y'
             ;
		   EXCEPTION
	        when others then
                v_message :=dka_tools_pkg.get_message('DKA','DKA_IAPFAC_DEBLOC_R10', 'XXXXX', rec_cur_recept.hold_id);
                   --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                   DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                   'DKA_IAPFAC_DEBLOC_INTERFACE', --prog_name
                                                   'hold_id',               --source
                                                   'DKA_IAPFAC_DEBLOC_INTERFACE' ,   --table_name
                                                   rec_cur_recept.RECORD_ID,  --table_id
                                                   'hold_id',  --column_name
                                                   rec_cur_recept.hold_id, --column_value
                                                   'E',                       --message_type
                                                  v_message                   --message_text
                                                   );
                       v_flag_erreur := TRUE;
                   
                   UPDATE DKA_IAPFAC_DEBLOC_INTERFACE
                    SET STATUT = 'REJECTED'
                      , request_id = g_request_id
                  WHERE CURRENT OF cur_recept;
         
          END;
		END IF;
		END IF;
	    -- RG4333-04 
		IF rec_cur_recept.RESPONSE_CODE IS NULL THEN
                v_message :=dka_tools_pkg.get_message('DKA','DKA_IAPFAC_DEBLOC_R11');
                --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                'DKA_IAPFAC_DEBLOC_INTERFACE', --prog_name
                                                'RESPONSE_CODE',               --source
                                                'DKA_IAPFAC_DEBLOC_INTERFACE' ,   --table_name
                                                rec_cur_recept.RECORD_ID,  --table_id
                                                'RESPONSE_CODE',  --column_name
                                                rec_cur_recept.RESPONSE_CODE, --column_value
                                                'E',                       --message_type
                                               v_message                   --message_text
                                                );
                    v_flag_erreur := TRUE;
                
                UPDATE DKA_IAPFAC_DEBLOC_INTERFACE
                 SET STATUT = 'REJECTED'
                   , request_id = g_request_id
               WHERE CURRENT OF cur_recept;
        ELSE
	       V_Check_Reject := 0;
           
		   IF (rec_cur_recept.hold_code in ('PRICE', 'MAX SHIP AMOUNT', 'QTY ORD') ) then
		      IF (rec_cur_recept.RESPONSE_CODE not in ('DKA_ACCEPTE_IVALUA','DKA_REFUSE_IVALUA')) then
			    V_Check_Reject := 1;
			  END IF;
		   END IF;

		   IF (rec_cur_recept.hold_code ='QTY REC' ) then
		      IF (rec_cur_recept.RESPONSE_CODE not in ('DKA_TRAITE_IVALUA','DKA_REFUSE_IVALUA')) then
			    V_Check_Reject := 1;
			  END IF;
		   END IF;

		   IF (rec_cur_recept.hold_code ='En attente' ) then
		      IF (rec_cur_recept.RESPONSE_CODE not in ('DKA_ACCEPTE_IVALUA','DKA_REFUSE_IVALUA', 'DKA_HORS_PERIMETRE')) then
			    V_Check_Reject := 1;
			  END IF;
		   END IF;
		   if V_Check_Reject = 1 then
           v_message :=dka_tools_pkg.get_message('DKA','DKA_IAPFAC_DEBLOC_R12', 'XXXXX', rec_cur_recept.RESPONSE_CODE, 'YYYYY', rec_cur_recept.HOLD_CODE );
                   --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                   DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                   'DKA_IAPFAC_DEBLOC_INTERFACE', --prog_name
                                                   'hold_id',               --source
                                                   'DKA_IAPFAC_DEBLOC_INTERFACE' ,   --table_name
                                                   rec_cur_recept.RECORD_ID,  --table_id
                                                   'hold_id',  --column_name
                                                   rec_cur_recept.hold_id, --column_value
                                                   'E',                       --message_type
                                                  v_message                   --message_text
                                                   );
                       v_flag_erreur := TRUE;
                   
                   UPDATE DKA_IAPFAC_DEBLOC_INTERFACE
                    SET STATUT = 'REJECTED'
                      , request_id = g_request_id
                  WHERE CURRENT OF cur_recept;
         
           END if;	
		END IF;	
		IF (rec_cur_recept.hold_code ='QTY REC' and rec_cur_recept.RESPONSE_CODE = 'DKA_TRAITE_IVALUA' ) THEN
		     BEGIN
			 V_Check_Reject := null;
		        SELECT distinct 1 into V_Check_Reject
				 FROM ap_holds_all aha 
					, po_headers_all pha
					, po_lines_all pla
					, po_line_locations_all plla
					, ap_invoice_lines_all aila
				WHERE aha.line_location_id = plla.line_location_id
				  AND plla.po_line_id = pla.po_line_id
				  AND plla.po_header_id = pha.po_header_id 
				  and aha.hold_id = rec_cur_recept.hold_id
				  and pla.attribute8 = rec_cur_recept.IVALUA_PO_LINE_ID
				  and aila.invoice_id = rec_cur_recept.invoice_id
				  AND aila.po_header_id = pha.po_header_id
				  AND aila.po_line_location_id = plla.line_location_id
				  AND aila.po_line_id = pla.po_line_id 
				  and plla.QUANTITY_RECEIVED >= aila.quantity_invoiced
			  ;
		EXCEPTION
	        when others then
                v_message :=dka_tools_pkg.get_message('DKA','DKA_IAPFAC_DEBLOC_R19', 'XXXXX', rec_cur_recept.RESPONSE_CODE, 'YYYYY', rec_cur_recept.IVALUA_PO_LINE_ID);
                   --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                   DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                   'DKA_IAPFAC_DEBLOC_INTERFACE', --prog_name
                                                   'IVALUA_PO_LINE_ID',               --source
                                                   'DKA_IAPFAC_DEBLOC_INTERFACE' ,   --table_name
                                                   rec_cur_recept.RECORD_ID,  --table_id
                                                   'IVALUA_PO_LINE_ID',  --column_name
                                                   rec_cur_recept.IVALUA_PO_LINE_ID, --column_value
                                                   'E',                       --message_type
                                                  v_message                   --message_text
                                                   );
                       v_flag_erreur := TRUE;
                   
                   UPDATE DKA_IAPFAC_DEBLOC_INTERFACE
                    SET STATUT = 'REJECTED'
                      , request_id = g_request_id
                  WHERE CURRENT OF cur_recept;
         
          END;
	  
	    END IF;
	    --RG4333-05 
		IF rec_cur_recept.RESPONSE_DATE IS NULL THEN
                v_message :=dka_tools_pkg.get_message('DKA','DKA_IAPFAC_DEBLOC_R13');
                --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                'DKA_IAPFAC_DEBLOC_INTERFACE', --prog_name
                                                'RESPONSE_DATE',               --source
                                                'DKA_IAPFAC_DEBLOC_INTERFACE' ,   --table_name
                                                rec_cur_recept.RECORD_ID,  --table_id
                                                'RESPONSE_DATE',  --column_name
                                                rec_cur_recept.RESPONSE_DATE, --column_value
                                                'E',                       --message_type
                                               v_message                   --message_text
                                                );
                    v_flag_erreur := TRUE;
                
                UPDATE DKA_IAPFAC_DEBLOC_INTERFACE
                 SET STATUT = 'REJECTED'
                   , request_id = g_request_id
               WHERE CURRENT OF cur_recept;
        ELSIF (rec_cur_recept.RESPONSE_DATE > sysdate) then
           v_message :=dka_tools_pkg.get_message('DKA','DKA_IAPFAC_DEBLOC_R14', 'XXXXX', to_char(rec_cur_recept.RESPONSE_DATE,'dd/mm/yyyy hh24:mi:ss') );
                   --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                   DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                   'DKA_IAPFAC_DEBLOC_INTERFACE', --prog_name
                                                   'hold_id',               --source
                                                   'DKA_IAPFAC_DEBLOC_INTERFACE' ,   --table_name
                                                   rec_cur_recept.RECORD_ID,  --table_id
                                                   'hold_id',  --column_name
                                                   rec_cur_recept.hold_id, --column_value
                                                   'E',                       --message_type
                                                  v_message                   --message_text
                                                   );
                       v_flag_erreur := TRUE;
                   
                   UPDATE DKA_IAPFAC_DEBLOC_INTERFACE
                    SET STATUT = 'REJECTED'
                      , request_id = g_request_id
                  WHERE CURRENT OF cur_recept;
        
        ELSE
            
                begin
				    V_Check_Reject :=0;
					select 1 into V_Check_Reject
					  from ap_holds_all aha
					where hold_id = rec_cur_recept.hold_id;		
				EXCEPTION
				when others then
				    null;
				end;
			if  V_Check_Reject = 1 then
				BEGIN
					select 1 into V_Check_Reject
					  from ap_holds_all aha
					where hold_id = rec_cur_recept.hold_id
					  and hold_date <= rec_cur_recept.RESPONSE_DATE
					;
						
				EXCEPTION
				when others then
					v_message :=dka_tools_pkg.get_message('DKA','DKA_IAPFAC_DEBLOC_R15', 'XXXXX', to_char(rec_cur_recept.RESPONSE_DATE,'dd/mm/yyyy hh24:mi:ss'));
					   --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
					   DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
													   'DKA_IAPFAC_DEBLOC_INTERFACE', --prog_name
													   'RESPONSE_DATE',               --source
													   'DKA_IAPFAC_DEBLOC_INTERFACE' ,   --table_name
													   rec_cur_recept.RECORD_ID,  --table_id
													   'RESPONSE_DATE',  --column_name
													   rec_cur_recept.RESPONSE_DATE, --column_value
													   'E',                       --message_type
													  v_message                   --message_text
													   );
						   v_flag_erreur := TRUE;
					   
					   UPDATE DKA_IAPFAC_DEBLOC_INTERFACE
						SET STATUT = 'REJECTED'
						  , request_id = g_request_id
					  WHERE CURRENT OF cur_recept;
			 
				END;
		  END IF;
		END IF;
		IF ((rec_cur_recept.HOLD_CODE = 'En attente') and (REPLACE(rec_cur_recept.COMMENTAIRE,CHR(13),'') is null)) THEN
	        v_message :=dka_tools_pkg.get_message('DKA','DKA_IAPFAC_DEBLOC_R16');
		    --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
		    DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
										   'DKA_IAPFAC_DEBLOC_INTERFACE', --prog_name
										   'COMMENTAIRE',               --source
										   'DKA_IAPFAC_DEBLOC_INTERFACE' ,   --table_name
										   rec_cur_recept.RECORD_ID,  --table_id
										   'COMMENTAIRE',  --column_name
										   rec_cur_recept.COMMENTAIRE, --column_value
										   'E',                       --message_type
										  v_message                   --message_text
										   );
			   v_flag_erreur := TRUE;
		   
		     UPDATE DKA_IAPFAC_DEBLOC_INTERFACE
		  	    SET STATUT = 'REJECTED'
		  	      , request_id = g_request_id
		      WHERE CURRENT OF cur_recept;	  
	    END IF;
		IF ((rec_cur_recept.RESPONSE_CODE = 'DKA_REFUSE_IVALUA') and (REPLACE(rec_cur_recept.COMMENTAIRE,CHR(13),'') is null)) THEN
	        v_message :=dka_tools_pkg.get_message('DKA','DKA_IAPFAC_DEBLOC_R17');
		    --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
		    DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
										   'DKA_IAPFAC_DEBLOC_INTERFACE', --prog_name
										   'COMMENTAIRE',               --source
										   'DKA_IAPFAC_DEBLOC_INTERFACE' ,   --table_name
										   rec_cur_recept.RECORD_ID,  --table_id
										   'COMMENTAIRE',  --column_name
										   rec_cur_recept.COMMENTAIRE, --column_value
										   'E',                       --message_type
										  v_message                   --message_text
										   );
			   v_flag_erreur := TRUE;
		   
		     UPDATE DKA_IAPFAC_DEBLOC_INTERFACE
		  	    SET STATUT = 'REJECTED'
		  	      , request_id = g_request_id
		      WHERE CURRENT OF cur_recept;	  
	    END IF;
	  END IF;
  IF NOT v_flag_erreur THEN
	UPDATE DKA_IAPFAC_DEBLOC_INTERFACE
	   SET STATUT = 'VALIDATED'
		 , request_id = g_request_id
	 WHERE CURRENT OF cur_recept;    
  END IF ;
  END LOOP;
  
  Fnd_File.put_line(Fnd_File.LOG, TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin validate_data_group');

  COMMIT; 

EXCEPTION
  WHEN OTHERS THEN
    p_retcode := 2;
    p_errbuf  := 'validate_data_group : ' || SQLERRM;
    Fnd_File.put_line(Fnd_File.LOG, p_errbuf);
    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Fin de la procédure validate_data_group : EXCEPTION OTHERS ');		  
END validate_data_group;


 /*
 *************************************************************************
 * PROCEDURE NAME : validate_data
 * 
 * DESCRIPTION
 *  Procédure d'insertion dans les tables finales
 *
 * PARAMETERS
 * ==========
 * NAME               DESCRIPTION
.* -----------------  ------------------------------------------------------
 * p_errbuf          Retour de message éventuel
 * p_retcode         Statut du traitement en sortie
 * 
 ************************************************************************
 */
--------------------------------------------------------------------------------------
PROCEDURE validate_data(p_Errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS

  v_person_id                   NUMBER;
  v_processing_status_code      VARCHAR2(100) DEFAULT 'PENDING';
  v_receipt_source_code         VARCHAR2(100) DEFAULT 'VENDOR';
  v_transaction_type            VARCHAR2(100) DEFAULT 'NEW';
  v_processing_mode_code        VARCHAR2(100) DEFAULT 'BATCH';
  v_code_site_four              VARCHAR2(100);
  v_org_id                      NUMBER;
  v_pers_id                     NUMBER;
  v_rcv_header_id               NUMBER;
  v_message                     VARCHAR2(500);
  v_flag_erreur                 BOOLEAN := FALSE;
  v_flag_erreur_trans           BOOLEAN := FALSE;
  v_ship_to_organization_id     NUMBER;
  v_code_site_four1             VARCHAR2(240);
  v_receive_trans_id            NUMBER;
  v_ship_to_location            VARCHAR2(100); -- OBE
  v_vendor_site_code            VARCHAR2(25); -- OBE
  v_vendor_site_code_2          VARCHAR2(25); -- OBE
  v_location_code               VARCHAR2(60); -- OBE
  v_deliver_to_location         VARCHAR2(60); -- OBE 
  v_deliver_to_location_id      NUMBER;       -- RBE
  v_DELIVER_TO_PERSON           VARCHAR2(240);
  e_err_org_not_exist           EXCEPTION;
  v_Multi_receipt               NUMBER; -- SELO
  v_org_ok                      Number; -- SELO
  v_vendor_id                   Number; -- SELO
  v_start_date                  DATE;
  V_RECEIPT_DATE                DATE;
  v_CMD_ID                      Number;
  v_vendor_site_id              Number;
  v_LIGNE_ID                    Number;
  v_reject                      Number;
  vs_ship_to_Org_Id             Number; 
  V_SHIPMENT_HEADER_ID          Number;
  vs_vendor_id                  Number;
  vs_vendor_site_id             Number;
  vs_packing_slip               VARCHAR2(60);
  v_rct_quantity                Number;
  v_shipment_line_id            Number;
  v_TRANSACTION_ID              Number;
  v_PARENT_TRANSACTION_ID       Number; 
  V_UNIT_OF_MEASURE             VARCHAR2(60);
  v_LINE_LOCATION_ID            Number; 
  v_PO_DISTRIBUTION_ID          Number; 
  -- Cursor des receptions
  CURSOR cur_recept_new IS
    SELECT *
      FROM dka.DKA_IAPFAC_DEBLOC_INTERFACE didi
     WHERE 1 = 1
      -- AND load_request_id = DECODE(g_loader_request_id, -1, load_request_id, g_loader_request_id) -- 
      -- AND flag = '-1' 
       AND STATUT  in ('NEW','REJECTED','PROCESSING_ERROR')
	 ORDER BY record_id ;

 
 CURSOR cur_recept IS
    SELECT *
      FROM dka.DKA_IAPFAC_DEBLOC_INTERFACE didi
     WHERE 1 = 1
      -- AND load_request_id = DECODE(g_loader_request_id, -1, load_request_id, g_loader_request_id) -- 
      -- AND flag = '-1' -- 
     ORDER BY record_id -- SOCIETE, REGION  ajout
       FOR UPDATE OF STATUT --, request_id      --, shipment_line_id, TRANSACTION_ID , PARENT_TRANSACTION_ID, vendor_id, ORG_ID  , VENDOR_SITE_ID,   --, ORG_ID, CODE_SITE_FOUR -- 
       ;

BEGIN

  Fnd_File.put_line(Fnd_File.LOG, TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début validate_data');
  Fnd_File.put_line(Fnd_File.LOG,
                    TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                    'Validation des données dans les tables spécifiques : ');

     FOR rec_cur_recept IN cur_recept_new LOOP
         validate_data_group(p_Errbuf , p_retcode, rec_cur_recept.RECORD_ID) ;
     END LOOP;
 
     FOR rec_cur_recept IN cur_recept LOOP
        
        BEGIN 
           v_reject:=0;
           select distinct 1 into v_reject
             from DKA_IAPFAC_DEBLOC_INTERFACE DII
            where DII.invoice_id = rec_cur_recept.invoice_id
              and DII.hold_id <> rec_cur_recept.hold_id
              and rec_cur_recept.STATUT = 'VALIDATED'
              and DII.STATUT = 'REJECTED';
        EXCEPTION
          WHEN OTHERS THEN
               null;
        END;
        
        IF v_reject = 1 THEN
            v_message :=dka_tools_pkg.get_message('DKA','DKA_IAPFAC_DEBLOC_R18');
            --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                'DKA_IAPFAC_DEBLOC_INTERFACE', --prog_name
                                                'STATUT',               --source
                                                'DKA_IAPFAC_DEBLOC_INTERFACE' ,   --table_name
                                                rec_cur_recept.RECORD_ID,  --table_id
                                                'STATUT',  --column_name
                                                rec_cur_recept.STATUT, --column_value
                                                'E',                       --message_type
                                               v_message                   --message_text
                                                );
            v_flag_erreur := TRUE;
            
            UPDATE DKA_IAPFAC_DEBLOC_INTERFACE
               SET STATUT = 'REJECTED'
                 , request_id = g_request_id
             WHERE CURRENT OF cur_recept;               
        END IF;

      END LOOP;
 
 
  Fnd_File.put_line(Fnd_File.LOG, TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin validate_data');

  COMMIT; 

EXCEPTION
  WHEN OTHERS THEN
    p_retcode := 2;
    p_errbuf  := 'validate_data : ' || SQLERRM;
    Fnd_File.put_line(Fnd_File.LOG, p_errbuf);
    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Fin de la procédure validate_data : EXCEPTION OTHERS ');
END validate_data;



 /*
 *************************************************************************
 * PROCEDURE NAME : trt_data
 * 
 * DESCRIPTION
 *  Procédure d'insertion dans les tables d'interfaces
 *
 * PARAMETERS
 * ==========
 * NAME               DESCRIPTION
 * -----------------  -----------------------------------------------------
 * p_errbuf          Retour de message éventuel
 * p_retcode         Statut du traitement en sortie
 * 
 ************************************************************************
 */
PROCEDURE trt_data(p_Errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS
  v_person_id              NUMBER;
  v_processing_status_code VARCHAR2(100) DEFAULT 'PENDING';
  v_receipt_source_code    VARCHAR2(100) DEFAULT 'VENDOR';
  v_transaction_type       VARCHAR2(100) DEFAULT 'NEW';
  v_processing_mode_code   VARCHAR2(100) DEFAULT 'BATCH';
  v_code_site_four         VARCHAR2(100);
  v_org_id                 NUMBER;
  v_pers_id                NUMBER;
  v_rcv_header_id          NUMBER;
  v_transaction_id         NUMBER;
  v_cpt                    NUMBER := 0;
  v_employee_id            NUMBER; -- SELO
  v_inc_group              NUMBER := 0;
  v_hist_rec                ap_inv_aprvl_hist_all%ROWTYPE;
  v_invoice_amount         number; 
  v_check_ouvert           number;
  v_user_name              varchar2(50);
  v_litige                 varchar2(150);
  v_ap_holds_all_rec       ap_holds_all%ROWTYPE;
  v_description            varchar2(150);
  V_USER_IVALUA            NUMBER;
  V_line_location_id       NUMBER;


  vv_step       VARCHAR2(50);
  vn_dummy      NUMBER;
  vv_itemkey    VARCHAR2(100);
  vv_itemtype   VARCHAR2(10);
  vv_wf_process VARCHAR2(50);
  v_message     VARCHAR2(2000);
  v_flag_erreur BOOLEAN := FALSE;
  v_code_name   VARCHAR2(100);
  v_DKA_CSP_NEXTVAL NUMBER := 0;
  
  -- Curseur des receptions
  CURSOR cur_price_accpt IS
    SELECT *
      FROM DKA_IAPFAC_DEBLOC_INTERFACE
     WHERE 1 = 1
       AND STATUT = 'VALIDATED'
	   and HOLD_CODE in ('PRICE','MAX SHIP AMOUNT','QTY ORD')
	   and RESPONSE_CODE = 'DKA_ACCEPTE_IVALUA'
     ORDER BY record_id
       --FOR UPDATE OF STATUT, request_id
	   ;

  CURSOR cur_price_refuse IS
    SELECT *
      FROM DKA_IAPFAC_DEBLOC_INTERFACE
     WHERE 1 = 1
       AND STATUT = 'VALIDATED'
	   and HOLD_CODE in ('PRICE','MAX SHIP AMOUNT','QTY ORD', 'QTY REC')
	   and RESPONSE_CODE = 'DKA_REFUSE_IVALUA'
     ORDER BY record_id
       --FOR UPDATE OF STATUT, request_id
	   ;	   


  CURSOR cur_QTY_REC_TRAITE IS
    SELECT *
      FROM DKA_IAPFAC_DEBLOC_INTERFACE
     WHERE 1 = 1
       AND STATUT = 'VALIDATED'
	   and HOLD_CODE ='QTY REC'
	   and RESPONSE_CODE = 'DKA_TRAITE_IVALUA'
     ORDER BY record_id
       --FOR UPDATE OF STATUT, request_id
	   ;


  CURSOR cur_EN_ATTENTE_ACCPT IS
    SELECT *
      FROM DKA_IAPFAC_DEBLOC_INTERFACE
     WHERE 1 = 1
       AND STATUT = 'VALIDATED'
	   and HOLD_CODE ='En attente'
	   and RESPONSE_CODE in ( 'DKA_ACCEPTE_IVALUA', 'DKA_REFUSE_IVALUA')
     ORDER BY record_id
       --FOR UPDATE OF STATUT, request_id
	   ;

  CURSOR cur_EN_ATTENTE_HORS_PERIM IS
    SELECT *
      FROM DKA_IAPFAC_DEBLOC_INTERFACE
     WHERE 1 = 1
       AND STATUT = 'VALIDATED'
	   and HOLD_CODE ='En attente'
	   and RESPONSE_CODE = 'DKA_HORS_PERIMETRE'
     ORDER BY record_id
      -- FOR UPDATE OF STATUT, request_id
	   ;			   

BEGIN
    select user_id into V_USER_IVALUA from FND_USER where user_name = 'IVALUA';
	 -- GROUP_ID
    /*SELECT rcv_interface_groups_s.nextval 
      INTO g_group_id 
      FROM dual;
    */

    FOR rec_cur_price_accpt IN cur_price_accpt LOOP
        -- Controle qui permet de decouper par lot
         v_cpt := 0;
		begin 
		 update ap_holds_all
			set RELEASE_LOOKUP_CODE = 'MATCH OVERRIDE'
			  , release_reason = ( select description
									from AP_HOLD_CODES_V
								   where hold_lookup_code = 'MATCH OVERRIDE')
			  , last_update_date = sysdate
			  , last_updated_by = V_USER_IVALUA
			  where hold_id= rec_cur_price_accpt.hold_id; 
		exception
		 when others then
             v_message :='Echec lors de la levée du blocage : '||SQLERRM;
			 --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
			 DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
											 'DKA_IAPFAC_DEBLOC_INTERFACE', --prog_name
											 'INVOICE_ID',               --source
											 'DKA_IAPFAC_DEBLOC_INTERFACE' ,   --table_name
											 rec_cur_price_accpt.RECORD_ID,  --table_id
											 'INVOICE_ID',  --column_name
											 rec_cur_price_accpt.INVOICE_ID, --column_value
											 'E',                       --message_type
											 v_message                   --message_text
											 );
				 v_flag_erreur := TRUE;
			 
			 UPDATE DKA_IAPFAC_DEBLOC_INTERFACE
			  SET STATUT = 'PROCESSING_ERROR'
			WHERE record_id=rec_cur_price_accpt.record_id;
        end;		
		
        begin
           select invoice_amount, org_id into v_invoice_amount, v_org_id 
		     from ap_invoices_all 
			where invoice_id=rec_cur_price_accpt.invoice_id;
			
			select meaning into v_code_name
			from fnd_lookup_values_vl
			where lookup_type ='HOLD CODE' 
			and lookup_code =rec_cur_price_accpt.HOLD_CODE ;
			
		   -- v_hist_rec.history_type := 'DOCUMENTAPPROVAL';
            v_hist_rec.invoice_id := rec_cur_price_accpt.invoice_id;
           -- v_hist_rec.iteration := 0;
            v_hist_rec.org_id := v_org_id;
            v_hist_rec.approver_name := 'IVALUA';
            v_hist_rec.amount_approved := v_invoice_amount;
            v_hist_rec.created_by := g_user_id;
            v_hist_rec.last_updated_by := g_user_id;
            v_hist_rec.last_update_login := -1;
            v_hist_rec.creation_date := SYSDATE;
            v_hist_rec.last_update_date := rec_cur_price_accpt.response_date; --SYSDATE;
            v_hist_rec.response := rec_cur_price_accpt.RESPONSE_CODE; --'Ecart / BAP accepté dans IVALUA';
            v_hist_rec.approver_comments := v_code_name || ' - ' ||rec_cur_price_accpt.Commentaire;
			v_hist_rec.HOLD_ID := rec_cur_price_accpt.HOLD_ID;
			SELECT DKA_SAPWFCSP_s.NEXTVAL 
            INTO v_DKA_CSP_NEXTVAL
            FROM dual;			
			v_hist_rec.ITERATION := v_DKA_CSP_NEXTVAL;
			
		    ap_workflow_pkg.insert_history_table (v_hist_rec);
            COMMIT;
		
		
		exception
		 when others then
             v_message :='Echec lors de la mise à jour de l''historique d''approbation de la facture : '||SQLERRM;
			 --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
			 DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
											 'DKA_IAPFAC_DEBLOC_INTERFACE', --prog_name
											 'INVOICE_ID',               --source
											 'DKA_IAPFAC_DEBLOC_INTERFACE' ,   --table_name
											 rec_cur_price_accpt.RECORD_ID,  --table_id
											 'INVOICE_ID',  --column_name
											 rec_cur_price_accpt.INVOICE_ID, --column_value
											 'E',                       --message_type
											 v_message                   --message_text
											 );
				 v_flag_erreur := TRUE;
			 
			 UPDATE DKA_IAPFAC_DEBLOC_INTERFACE
			  SET STATUT = 'PROCESSING_ERROR'
			WHERE record_id=rec_cur_price_accpt.record_id;
        end;
       begin
	       update ap_holds_all
			set ATTRIBUTE4 = 'N'
			  ,last_update_date =SYSDATE
			  ,last_updated_by = V_USER_IVALUA
			  where hold_id= rec_cur_price_accpt.hold_id; 
           COMMIT;
		
		
		exception
		 when others then
            v_message :='Echec lors de la mise à jour du blocage afin qu''il ne soit plus marqué comme à traiter dans IVALUA : '||SQLERRM;
			 --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
			 DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
											 'DKA_IAPFAC_DEBLOC_INTERFACE', --prog_name
											 'INVOICE_ID',               --source
											 'DKA_IAPFAC_DEBLOC_INTERFACE' ,   --table_name
											 rec_cur_price_accpt.RECORD_ID,  --table_id
											 'INVOICE_ID',  --column_name
											 rec_cur_price_accpt.INVOICE_ID, --column_value
											 'E',                       --message_type
											 v_message                   --message_text
											 );
				 v_flag_erreur := TRUE;
			 
			 UPDATE DKA_IAPFAC_DEBLOC_INTERFACE
			  SET STATUT = 'PROCESSING_ERROR'
			WHERE record_id=rec_cur_price_accpt.record_id;
        end;	
        
		BEGIN
		v_check_ouvert :=0;
		    select distinct 1 into v_check_ouvert
			  from ap_holds_all
			 where invoice_id= rec_cur_price_accpt.invoice_id
			   and RELEASE_LOOKUP_CODE is null;
		
        exception
		 when others then
               Fnd_File.put_line(Fnd_File.LOG, TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Pas de blocage sur cette facture');
        end;
		
        IF v_check_ouvert = 0 then
            begin
			    UPDATE ap_invoices_all
                   SET wfapproval_status = 'WFAPPROVED'
				     , last_update_date = sysdate
			         , last_updated_by = g_user_id
                 WHERE invoice_id = rec_cur_price_accpt.invoice_id; 
				 
				 --ARA TASK0174529
				 UPDATE AP_INVOICE_LINES_ALL
					SET wfapproval_status ='NOT REQUIRED'
					WHERE  wfapproval_status IN ('INITIATED' , 'NEEDS WFREAPPROVAL', 'WFAPPROVED')
					AND invoice_id IN
					(SELECT invoice_id FROM ap_invoices_all WHERE wfapproval_status = 'WFAPPROVED' AND invoice_id = rec_cur_price_accpt.invoice_id);
				
			exception
		    when others then
                v_message :='Echec lors de la mise à jour du statut d''approbation de la facture : '||SQLERRM;
			      --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
			    DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
											 'DKA_IAPFAC_DEBLOC_INTERFACE', --prog_name
											 'INVOICE_ID',               --source
											 'DKA_IAPFAC_DEBLOC_INTERFACE' ,   --table_name
											 rec_cur_price_accpt.RECORD_ID,  --table_id
											 'INVOICE_ID',  --column_name
											 rec_cur_price_accpt.INVOICE_ID, --column_value
											 'E',                       --message_type
											 v_message                   --message_text
											 );
				 v_flag_erreur := TRUE;
			 
				 UPDATE DKA_IAPFAC_DEBLOC_INTERFACE
				  SET STATUT = 'PROCESSING_ERROR'
				WHERE record_id=rec_cur_price_accpt.record_id;
            end;
            begin  
			       select user_name into v_user_name from fnd_user where user_id = g_user_id;
				   
                  -- select invoice_amount, org_id into v_invoice_amount, v_org_id from ap_invoices_all where invoice_id=rec_cur_price_accpt.invoice_id;
				   
		            v_hist_rec.invoice_id := rec_cur_price_accpt.invoice_id;
                    v_hist_rec.org_id := v_org_id;
                    v_hist_rec.approver_name := v_user_name;
                    v_hist_rec.amount_approved := v_invoice_amount;
                    v_hist_rec.created_by := g_user_id;
                    v_hist_rec.last_updated_by := g_user_id;
                    v_hist_rec.last_update_login := -1;
                    v_hist_rec.creation_date := SYSDATE;
                    v_hist_rec.last_update_date := SYSDATE;
                    v_hist_rec.response := 'WFAPPROVED'; --'Ecart / BAP accepté dans IVALUA';
                    v_hist_rec.approver_comments := null;
		        	v_hist_rec.HOLD_ID := null;
		        	SELECT DKA_SAPWFCSP_s.NEXTVAL 
					INTO v_DKA_CSP_NEXTVAL
					FROM dual;			
					v_hist_rec.ITERATION := v_DKA_CSP_NEXTVAL;
		            ap_workflow_pkg.insert_history_table (v_hist_rec);
                    COMMIT;
		        
		    
		    exception
		    when others then
                v_message :='Echec lors de la mise à jour de l''historique d''approbation de la facture : '||SQLERRM;
			      --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
			    DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
											 'DKA_IAPFAC_DEBLOC_INTERFACE', --prog_name
											 'INVOICE_ID',               --source
											 'DKA_IAPFAC_DEBLOC_INTERFACE' ,   --table_name
											 rec_cur_price_accpt.RECORD_ID,  --table_id
											 'INVOICE_ID',  --column_name
											 rec_cur_price_accpt.INVOICE_ID, --column_value
											 'E',                       --message_type
											 v_message                   --message_text
											 );
				 v_flag_erreur := TRUE;
			 
				 UPDATE DKA_IAPFAC_DEBLOC_INTERFACE
				  SET STATUT = 'PROCESSING_ERROR'
				WHERE record_id=rec_cur_price_accpt.record_id;
            end;
        END IF;		
 		
		begin   
		    UPDATE DKA_IAPFAC_DEBLOC_INTERFACE
               SET STATUT = 'COMPLETE'
                 , request_id = g_request_id
             --WHERE CURRENT OF cur_price_accpt;  
			 where record_id = rec_cur_price_accpt.record_id
			   and STATUT <> 'PROCESSING_ERROR';	
        commit;
		exception
		 when others then
               null;
        end;
    END LOOP;
	
   FOR rec_cur_price_refuse IN cur_price_refuse LOOP
   --   BEGIN
        -- Controle qui permet de decouper par lot
        select invoice_amount, org_id into v_invoice_amount, v_org_id 
		     from ap_invoices_all 
			where invoice_id=rec_cur_price_refuse.invoice_id;				
         v_cpt := 0;
		begin 
		
		  SELECT  DSTL.return_value into v_litige
            FROM  DKA_STRANSCO_LINES DSTL,
                  DKA_STRANSCO_HEADERS DSTH
           WHERE
                  DSTL.SET_ID = DSTH.SET_ID
             AND  DSTH.SET_NAME LIKE 'DKA_BLOCAGES_IVALUA'
			 AND  DSTL.param1_value=rec_cur_price_refuse.HOLD_CODE
             AND  DSTL.ENABLE = 'Y'
             AND  NVL(DSTL.END_DATE  ,TRUNC(SYSDATE) )   >= TRUNC(SYSDATE)
             AND  NVL(DSTL.START_DATE,TRUNC(SYSDATE))  <= TRUNC(SYSDATE)  
           ;
		   SELECT aha.line_location_id into V_line_location_id
                FROM ap_holds_all aha 
                   , po_headers_all pha
                   , po_lines_all pla
                   , po_line_locations_all plla
               WHERE aha.line_location_id = plla.line_location_id
                 AND plla.po_line_id = pla.po_line_id
                 AND plla.po_header_id = pha.po_header_id 
                 and aha.hold_id = rec_cur_price_refuse.hold_id
				 and pla.attribute8 = rec_cur_price_refuse.IVALUA_PO_LINE_ID;
		
              v_ap_holds_all_rec.invoice_id             := rec_cur_price_refuse.invoice_id;
              v_ap_holds_all_rec.hold_lookup_code      := v_litige;
              
              select description into v_description
				from AP_HOLD_CODES_V
			   where hold_lookup_code = v_litige;
              v_ap_holds_all_rec.hold_reason            := v_description;
              
              
              v_ap_holds_all_rec.last_update_date       := SYSDATE ;
              v_ap_holds_all_rec.last_updated_by        := g_user_id;
              v_ap_holds_all_rec.held_by                := V_USER_IVALUA;
              v_ap_holds_all_rec.hold_date              := SYSDATE;
              
            --  v_ap_holds_all_rec.release_lookup_code    := c_b.release_lookup_code;
            --  v_ap_holds_all_rec.release_reason         := c_b.release_reason;
			  v_ap_holds_all_rec.line_location_id       := v_line_location_id;
              v_ap_holds_all_rec.status_flag            := 'S';
              v_ap_holds_all_rec.creation_date          := sysdate;
              v_ap_holds_all_rec.created_by             := g_user_id;
			  v_ap_holds_all_rec.LAST_UPDATED_BY        := g_user_id;
              v_ap_holds_all_rec.org_id                 := v_org_id;
              v_ap_holds_all_rec.hold_id                := ap_holds_s.NEXTVAL;		
         
                Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Debut insert_ap_holds_all');
                INSERT
                INTO   ap_holds_all
                VALUES v_ap_holds_all_rec;
         
                Fnd_File.put_line (Fnd_File.LOG,'le blocage '||v_ap_holds_all_rec.hold_id||' a bien été inséré pour la facture ID: ' ||v_ap_holds_all_rec.invoice_id);
                Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin insert_ap_holds_all');

            EXCEPTION
              WHEN OTHERS THEN
				v_message :='Echec lors de la création du blocage pour la mise en litige : '||SQLERRM;
			      --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
			    DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
											 'DKA_IAPFAC_DEBLOC_INTERFACE', --prog_name
											 'INVOICE_ID',               --source
											 'DKA_IAPFAC_DEBLOC_INTERFACE' ,   --table_name
											 rec_cur_price_refuse.RECORD_ID,  --table_id
											 'INVOICE_ID',  --column_name
											 rec_cur_price_refuse.INVOICE_ID, --column_value
											 'E',                       --message_type
											 v_message                   --message_text
											 );
				 v_flag_erreur := TRUE;
			 
				 UPDATE DKA_IAPFAC_DEBLOC_INTERFACE
				  SET STATUT = 'PROCESSING_ERROR'
				WHERE record_id=rec_cur_price_refuse.record_id;
                    Fnd_File.put_line (Fnd_File.LOG,'erreur lors de l''insertion du blocage '||v_ap_holds_all_rec.hold_id||' pour la facture ID: ' ||v_ap_holds_all_rec.invoice_id);
                    Fnd_File.put_line (Fnd_File.LOG,'Cause:'||SQLERRM);
                    p_retcode := 2;
          END;		
        begin
           select invoice_amount, org_id into v_invoice_amount, v_org_id from ap_invoices_all where invoice_id=rec_cur_price_refuse.invoice_id;
		   
		   	select meaning into v_code_name
			from fnd_lookup_values_vl
			where lookup_type ='HOLD CODE' 
			and lookup_code =rec_cur_price_refuse.HOLD_CODE ;
		   
		   -- v_hist_rec.history_type := 'DOCUMENTAPPROVAL';
            v_hist_rec.invoice_id := rec_cur_price_refuse.invoice_id;
           -- v_hist_rec.iteration := 0;
            v_hist_rec.org_id := v_org_id;
            v_hist_rec.approver_name := 'IVALUA';
            v_hist_rec.amount_approved := v_invoice_amount;
            v_hist_rec.created_by := g_user_id;
            v_hist_rec.last_updated_by := g_user_id;
            v_hist_rec.last_update_login := -1;
            v_hist_rec.creation_date := SYSDATE;
            v_hist_rec.last_update_date := rec_cur_price_refuse.response_date;
            v_hist_rec.response := rec_cur_price_refuse.RESPONSE_CODE; 
            v_hist_rec.approver_comments := v_code_name || ' - ' ||rec_cur_price_refuse.Commentaire;
			v_hist_rec.HOLD_ID := rec_cur_price_refuse.HOLD_ID;
			SELECT DKA_SAPWFCSP_s.NEXTVAL 
            INTO v_DKA_CSP_NEXTVAL
            FROM dual;			
			v_hist_rec.ITERATION := v_DKA_CSP_NEXTVAL;
			
		    ap_workflow_pkg.insert_history_table (v_hist_rec);
            COMMIT;
		
	
		exception
		 when others then
				v_message :='Echec lors de la mise à jour de l''historique d''approbation de la facture : '||SQLERRM;
			      --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
			    DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
											 'DKA_IAPFAC_DEBLOC_INTERFACE', --prog_name
											 'INVOICE_ID',               --source
											 'DKA_IAPFAC_DEBLOC_INTERFACE' ,   --table_name
											 rec_cur_price_refuse.RECORD_ID,  --table_id
											 'INVOICE_ID',  --column_name
											 rec_cur_price_refuse.INVOICE_ID, --column_value
											 'E',                       --message_type
											 v_message                   --message_text
											 );
				 v_flag_erreur := TRUE;
			 
				 UPDATE DKA_IAPFAC_DEBLOC_INTERFACE
				  SET STATUT = 'PROCESSING_ERROR'
				WHERE record_id=rec_cur_price_refuse.record_id;
        end;
       begin
	       update ap_holds_all
			set ATTRIBUTE4 = 'N'
			  ,last_update_date =SYSDATE
			  ,last_updated_by = V_USER_IVALUA
			  where hold_id= rec_cur_price_refuse.hold_id; 
           COMMIT;
		
		exception
		 when others then
              null;
        end;	
         		
		begin 
		    UPDATE DKA_IAPFAC_DEBLOC_INTERFACE
               SET STATUT = 'COMPLETE'
                 , request_id = g_request_id
            -- WHERE CURRENT OF cur_price_refuse; 
			 where record_id = rec_cur_price_refuse.record_id
			  and STATUT <> 'PROCESSING_ERROR';		
        commit;
		exception
		 when others then
              null;
        end;		
    END LOOP;

    FOR rec_cur_QTY_REC_TRAITE IN cur_QTY_REC_TRAITE LOOP
   --   BEGIN
        -- Controle qui permet de decouper par lot
         v_cpt := 0;

        begin
           select invoice_amount, org_id into v_invoice_amount, v_org_id from ap_invoices_all where invoice_id=rec_cur_QTY_REC_TRAITE.invoice_id;
		   
		   	select meaning into v_code_name
			from fnd_lookup_values_vl
			where lookup_type ='HOLD CODE' 
			and lookup_code =rec_cur_QTY_REC_TRAITE.HOLD_CODE ;
			
		   -- v_hist_rec.history_type := 'DOCUMENTAPPROVAL';
            v_hist_rec.invoice_id := rec_cur_QTY_REC_TRAITE.invoice_id;
           -- v_hist_rec.iteration := 0;
            v_hist_rec.org_id := v_org_id;
            v_hist_rec.approver_name := 'IVALUA';
            v_hist_rec.amount_approved := v_invoice_amount;
            v_hist_rec.created_by := g_user_id;
            v_hist_rec.last_updated_by := g_user_id;
            v_hist_rec.last_update_login := -1;
            v_hist_rec.creation_date := SYSDATE;
            v_hist_rec.last_update_date := rec_cur_QTY_REC_TRAITE.response_date;
            v_hist_rec.response := rec_cur_QTY_REC_TRAITE.RESPONSE_CODE; --'Ecart / BAP accepté dans IVALUA';
            v_hist_rec.approver_comments := v_code_name || ' - ' ||rec_cur_QTY_REC_TRAITE.Commentaire;
			v_hist_rec.HOLD_ID := rec_cur_QTY_REC_TRAITE.HOLD_ID;
			SELECT DKA_SAPWFCSP_s.NEXTVAL 
            INTO v_DKA_CSP_NEXTVAL
            FROM dual;			
			v_hist_rec.ITERATION := v_DKA_CSP_NEXTVAL;
			
		    ap_workflow_pkg.insert_history_table (v_hist_rec);
            COMMIT;
		
		
		exception
		 when others then
				v_message :='Echec lors de la mise à jour de l''historique d''approbation de la facture : '||SQLERRM;
			      --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
			    DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
											 'DKA_IAPFAC_DEBLOC_INTERFACE', --prog_name
											 'INVOICE_ID',               --source
											 'DKA_IAPFAC_DEBLOC_INTERFACE' ,   --table_name
											 rec_cur_QTY_REC_TRAITE.RECORD_ID,  --table_id
											 'INVOICE_ID',  --column_name
											 rec_cur_QTY_REC_TRAITE.INVOICE_ID, --column_value
											 'E',                       --message_type
											 v_message                   --message_text
											 );
				 v_flag_erreur := TRUE;
			 
				 UPDATE DKA_IAPFAC_DEBLOC_INTERFACE
				  SET STATUT = 'PROCESSING_ERROR'
				WHERE record_id=rec_cur_QTY_REC_TRAITE.record_id;
        end;
       begin
	   
	       update ap_holds_all
			set ATTRIBUTE4 = 'N'
			  ,last_update_date =SYSDATE
			  ,last_updated_by = V_USER_IVALUA
			  where hold_id= rec_cur_QTY_REC_TRAITE.hold_id; 
           COMMIT;
		
		
		exception
		 when others then
               null;
        end;	
        
		begin   
		    UPDATE DKA_IAPFAC_DEBLOC_INTERFACE
               SET STATUT = 'COMPLETE'
                 , request_id = g_request_id
            -- WHERE CURRENT OF cur_QTY_REC_TRAITE;  
			where record_id = rec_cur_QTY_REC_TRAITE.record_id
			  and STATUT <> 'PROCESSING_ERROR';		
        commit;
		exception
		 when others then
               null;
        end;		
    END LOOP;


    FOR rec_cur_EN_ATTENTE_ACCPT IN cur_EN_ATTENTE_ACCPT LOOP
   --   BEGIN
        -- Controle qui permet de decouper par lot
         v_cpt := 0;
        begin
           select invoice_amount, org_id into v_invoice_amount, v_org_id from ap_invoices_all where invoice_id=rec_cur_EN_ATTENTE_ACCPT.invoice_id;
		   
		   	select meaning into v_code_name
			from fnd_lookup_values_vl
			where lookup_type ='HOLD CODE' 
			and lookup_code =rec_cur_EN_ATTENTE_ACCPT.HOLD_CODE ;
			

		   
		   -- v_hist_rec.history_type := 'DOCUMENTAPPROVAL';
            v_hist_rec.invoice_id := rec_cur_EN_ATTENTE_ACCPT.invoice_id;
           -- v_hist_rec.iteration := 0;
            v_hist_rec.org_id := v_org_id;
            v_hist_rec.approver_name := 'IVALUA';
            v_hist_rec.amount_approved := v_invoice_amount;
            v_hist_rec.created_by := g_user_id;
            v_hist_rec.last_updated_by := g_user_id;
            v_hist_rec.last_update_login := -1;
            v_hist_rec.creation_date := SYSDATE;
            v_hist_rec.last_update_date := rec_cur_EN_ATTENTE_ACCPT.response_date;
            v_hist_rec.response := rec_cur_EN_ATTENTE_ACCPT.RESPONSE_CODE; --'Ecart / BAP accepté dans IVALUA';
            v_hist_rec.approver_comments := v_code_name || ' - ' ||rec_cur_EN_ATTENTE_ACCPT.Commentaire;
			v_hist_rec.HOLD_ID := rec_cur_EN_ATTENTE_ACCPT.HOLD_ID;
			SELECT DKA_SAPWFCSP_s.NEXTVAL 
            INTO v_DKA_CSP_NEXTVAL
            FROM dual;			
			v_hist_rec.ITERATION := v_DKA_CSP_NEXTVAL;
			
		    ap_workflow_pkg.insert_history_table (v_hist_rec);
            COMMIT;
            exception
			 when others then
				   	v_message :='Echec lors de la mise à jour de l''historique d''approbation de la facture : '||SQLERRM;
			      --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
			    DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
											 'DKA_IAPFAC_DEBLOC_INTERFACE', --prog_name
											 'INVOICE_ID',               --source
											 'DKA_IAPFAC_DEBLOC_INTERFACE' ,   --table_name
											 rec_cur_EN_ATTENTE_ACCPT.RECORD_ID,  --table_id
											 'INVOICE_ID',  --column_name
											 rec_cur_EN_ATTENTE_ACCPT.INVOICE_ID, --column_value
											 'E',                       --message_type
											 v_message                   --message_text
											 );
				 v_flag_erreur := TRUE;
			 
				 UPDATE DKA_IAPFAC_DEBLOC_INTERFACE
				  SET STATUT = 'PROCESSING_ERROR'
				WHERE record_id=rec_cur_EN_ATTENTE_ACCPT.record_id;
			end;
       BEGIN
		update ap_holds_all
			set ATTRIBUTE1 = null
			  , ATTRIBUTE2 = null
			  , ATTRIBUTE3 = null
			  ,last_update_date =SYSDATE
			  ,last_updated_by = V_USER_IVALUA			  
			  where hold_id= rec_cur_EN_ATTENTE_ACCPT.hold_id; 
           COMMIT;
               null;		   
		    exception
		    when others then
                null;
        end;
        

		BEGIN
		            vv_itemtype := 'DKA_CSP';
                    dbms_output.put_line('lancement de DKA_CSP pour fact' ||
                                         rec_cur_EN_ATTENTE_ACCPT.invoice_id);
                    
					vv_wf_process := 'DKA_BLOCAGE_IVALUA_ATTENTE';
                    
					SELECT to_char(DKA_SAPWFCSP_s.NEXTVAL) INTO vn_dummy FROM dual;
                    
					vv_itemkey := rec_cur_EN_ATTENTE_ACCPT.invoice_id || '_' || vn_dummy;
                    
					dbms_output.put_line('lancement de DKA_CSP ' || vv_wf_process ||
                                         'itemkey = ' || vv_itemkey);
                    -- Creation du process WF
                    wf_engine.createprocess(itemtype => vv_itemtype,
                                            itemkey  => vv_itemkey,
                                            process  => vv_wf_process);
					
					wf_engine.setitemattrnumber(itemtype => vv_itemtype,
                                        itemkey  => vv_itemkey,
                                        aname    => 'INVOICE_ID',
                                        avalue   => rec_cur_EN_ATTENTE_ACCPT.invoice_id);
               	wf_engine.setitemattrnumber(itemtype => vv_itemtype,
                                        itemkey  => vv_itemkey,
                                        aname    => 'DKA_HOLD_ID',
                                        avalue   => rec_cur_EN_ATTENTE_ACCPT.hold_id);

                    -- Kick off the process
                    wf_engine.startprocess(itemtype => vv_itemtype,
                                           itemkey  => vv_itemkey);
                    
                    -- FT 22
                    COMMIT;	
			 exception
		    when others then
                v_message :='Echec lors du lancement du workflow pour notification des réponses IVALUA au CSP : '||SQLERRM;
				 DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
											 'DKA_IAPFAC_DEBLOC_INTERFACE', --prog_name
											 'INVOICE_ID',               --source
											 'DKA_IAPFAC_DEBLOC_INTERFACE' ,   --table_name
											 rec_cur_EN_ATTENTE_ACCPT.RECORD_ID,  --table_id
											 'INVOICE_ID',  --column_name
											 rec_cur_EN_ATTENTE_ACCPT.INVOICE_ID, --column_value
											 'E',                       --message_type
											 v_message                   --message_text
											 );
				 v_flag_erreur := TRUE;
			 
				 UPDATE DKA_IAPFAC_DEBLOC_INTERFACE
				  SET STATUT = 'PROCESSING_ERROR'
				WHERE record_id=rec_cur_EN_ATTENTE_ACCPT.record_id;
            end;
         begin
	   
	       update ap_holds_all
			set ATTRIBUTE4 = 'N'
			  ,last_update_date =SYSDATE
			  ,last_updated_by = V_USER_IVALUA	
			  where hold_id= rec_cur_EN_ATTENTE_ACCPT.hold_id; 
           COMMIT;
          
		exception
		 when others then
            null;
        end;	 		
		begin   
		    UPDATE DKA_IAPFAC_DEBLOC_INTERFACE
               SET STATUT = 'COMPLETE'
                 , request_id = g_request_id
            -- WHERE CURRENT OF cur_EN_ATTENTE_ACCPT;
			where record_id = rec_cur_EN_ATTENTE_ACCPT.record_id
			  and STATUT <> 'PROCESSING_ERROR';					 
        commit;
		exception
		 when others then
            null;
        end;		
    END LOOP;


    FOR rec_cur_EN_ATTENTE_HORS_PERIM IN cur_EN_ATTENTE_HORS_PERIM LOOP
   --   BEGIN
        -- Controle qui permet de decouper par lot
         v_cpt := 0;

        begin
           select invoice_amount, org_id into v_invoice_amount, v_org_id from ap_invoices_all where invoice_id=rec_cur_EN_ATTENTE_HORS_PERIM.invoice_id;
		   
		   	select meaning into v_code_name
			from fnd_lookup_values_vl
			where lookup_type ='HOLD CODE' 
			and lookup_code =rec_cur_EN_ATTENTE_HORS_PERIM.HOLD_CODE ;
			
		   -- v_hist_rec.history_type := 'DOCUMENTAPPROVAL';
            v_hist_rec.invoice_id := rec_cur_EN_ATTENTE_HORS_PERIM.invoice_id;
           -- v_hist_rec.iteration := 0;
            v_hist_rec.org_id := v_org_id;
            v_hist_rec.approver_name := 'IVALUA';
            v_hist_rec.amount_approved := v_invoice_amount;
            v_hist_rec.created_by := g_user_id;
            v_hist_rec.last_updated_by := g_user_id;
            v_hist_rec.last_update_login := -1;
            v_hist_rec.creation_date := SYSDATE;
            v_hist_rec.last_update_date := rec_cur_EN_ATTENTE_HORS_PERIM.response_date;
            v_hist_rec.response := rec_cur_EN_ATTENTE_HORS_PERIM.RESPONSE_CODE; --'Ecart / BAP accepté dans IVALUA';
            v_hist_rec.approver_comments := v_code_name || ' - ' ||rec_cur_EN_ATTENTE_HORS_PERIM.Commentaire;
			v_hist_rec.HOLD_ID := rec_cur_EN_ATTENTE_HORS_PERIM.HOLD_ID;
			SELECT DKA_SAPWFCSP_s.NEXTVAL 
            INTO v_DKA_CSP_NEXTVAL
            FROM dual;			
			v_hist_rec.ITERATION := v_DKA_CSP_NEXTVAL;
			
		    ap_workflow_pkg.insert_history_table (v_hist_rec);
            COMMIT;
		
			exception
			 when others then
                 v_message :='Echec lors de la mise à jour de l''historique d''approbation de la facture : '||SQLERRM;
				 DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
											 'DKA_IAPFAC_DEBLOC_INTERFACE', --prog_name
											 'INVOICE_ID',               --source
											 'DKA_IAPFAC_DEBLOC_INTERFACE' ,   --table_name
											 rec_cur_EN_ATTENTE_HORS_PERIM.RECORD_ID,  --table_id
											 'INVOICE_ID',  --column_name
											 rec_cur_EN_ATTENTE_HORS_PERIM.INVOICE_ID, --column_value
											 'E',                       --message_type
											 v_message                   --message_text
											 );
				 v_flag_erreur := TRUE;
			 
				 UPDATE DKA_IAPFAC_DEBLOC_INTERFACE
				  SET STATUT = 'PROCESSING_ERROR'
				WHERE record_id=rec_cur_EN_ATTENTE_HORS_PERIM.record_id;
			end;
        begin
	   
	       update ap_holds_all
			set ATTRIBUTE4 = 'N'
			  ,last_update_date =SYSDATE
			  ,last_updated_by =  V_USER_IVALUA			
			  where hold_id= rec_cur_EN_ATTENTE_HORS_PERIM.hold_id; 
           COMMIT;
		

		exception
		 when others then
               null;
        end;	
        
		BEGIN
		update ap_holds_all
			set ATTRIBUTE1 = null
			  , ATTRIBUTE2 = null
			  , ATTRIBUTE3 = null
			  ,last_updated_by = V_USER_IVALUA	
			  ,last_update_date =SYSDATE
			  where 1=1
			    --and hold_id= rec_cur_EN_ATTENTE_HORS_PERIM.hold_id
				and hold_lookup_code = 'Imputation en attente'
			    and invoice_id = rec_cur_EN_ATTENTE_HORS_PERIM.invoice_id; 
           COMMIT;
		    exception
		    when others then
                null;
        end;
        
        		
		begin   
		    UPDATE DKA_IAPFAC_DEBLOC_INTERFACE
               SET STATUT = 'COMPLETE'
                 , request_id = g_request_id
            -- WHERE CURRENT OF cur_EN_ATTENTE_HORS_PERIM; 
			where record_id = rec_cur_EN_ATTENTE_HORS_PERIM.record_id
			  and STATUT <> 'PROCESSING_ERROR';							 
        commit;
		exception
		 when others then
               null;
        end;		
    END LOOP;     
    Fnd_File.put_line(Fnd_File.LOG, TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin trt_data');
    COMMIT; 

EXCEPTION
  WHEN OTHERS THEN
    p_retcode := 2;
    p_errbuf  := 'trt_data : ' || SQLERRM;
    Fnd_File.put_line(Fnd_File.LOG, p_errbuf);
    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Fin de la procédure trt_data : EXCEPTION OTHERS ');
    ROLLBACK; 

END trt_data;

------------------------------------------------------
/*
 *************************************************************************
 * PROCEDURE NAME : Launch_Loader
 *
 * DESCRIPTION
 *  Procédure de lancement du programme de chargement dans la table spécifique
 *
 * PARAMETERS
 * ==========
 * NAME               DESCRIPTION
.* -----------------  ------------------------------------------------------
 * p_directory       Répertoire du fichier
 * p_file_name       Nom du fichier à charger
 * p_errbuf          Retour de message éventuel
 * p_retcode         Statut du traitement en sortie
 *
 ************************************************************************
 */
  PROCEDURE Launch_Loader(p_Errbuf            OUT VARCHAR2,
                          p_retcode           OUT NUMBER
                          )
  IS
        v_phase                  VARCHAR2 (100);
        v_status                 VARCHAR2 (100);
        v_dev_phase              VARCHAR2 (100);
        v_dev_status             VARCHAR2 (100);
        v_message                VARCHAR2 (500);
        b_result                  BOOLEAN;

  BEGIN
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début Launch_Loader');
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                                         'Lancement de chargement du fichier dans la table d''interface spécifique : ');
		
		Fnd_File.put_line (Fnd_File.OUTPUT, 'CHARGEMENT DU FICHIER : ');
		Fnd_File.put_line (Fnd_File.OUTPUT, '-----------------------------------------------');

        ------------------------------------------------------
        -- Lancement du traitement de chargement du fichier --
        ------------------------------------------------------
        -- Positionnement des options d'impression
        b_result := fnd_request.set_print_options(printer => gv_printer,
                                                  copies => g_number_of_copies);
        -- Lancement du traitement
        g_loader_request_id         := Fnd_Request.submit_request (
                                                                   'DKA'                            -- APPL
                                                                  ,'DKA_IAPFAC_DEBLOC_LOADER' -- PROG
                                                                  ,NULL                             -- PROGRAM_NAME
                                                                  ,NULL                             -- START
                                                                  ,FALSE                            -- SUB_REQUEST
                                                                  );

        IF g_loader_request_id = 0
        THEN
            p_retcode    := 2;
            fnd_file.put_line(fnd_file.LOG, 'ERREUR : Le traitement de chargement du fichier a échoué' || CHR(10) ||
                                            'PROGRAMME  : DKA_IAPFAC_DEBLOC_LOADER'
                                            );
            --Fnd_File.put_line (Fnd_File.OUTPUT, '====> ERREUR : Le traitement de chargement du fichier a échoué');
        ELSE
            COMMIT;
            Fnd_File.put_line(Fnd_File.LOG, '=> LOAD REQUEST ID= ' || g_loader_request_id);
			
			Fnd_File.put_line (Fnd_File.OUTPUT, '. Numéro du traitement de chargement : '||g_loader_request_id);

            --Fnd_File.put_line(Fnd_File.OUTPUT, '. Numéro du traitement de chargement du fichier : ' || g_loader_request_id);

            -- Attente de la fin du traitement
            IF NOT (Fnd_Concurrent.wait_for_request (g_loader_request_id, g_tempo, 0, v_phase, v_status, v_dev_phase, v_dev_status, v_message))
            THEN
                p_Errbuf  := v_Message;
                Fnd_file.put_line(Fnd_file.log, 'ERREUR : Attente de la fin du programme de chargement du fichier dépassée : Fin du traitement' || CHR(10) ||
                                                'MESSAGE : ' || v_Message || CHR(10) );
            END IF;

            IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL')
            THEN
                Fnd_File.put_line(Fnd_File.LOG, 'COMPLETION= ' || 'Terminé' || '/' || 'Normal');
				Fnd_File.put_line (Fnd_File.OUTPUT, '. Statut de fin : ' || 'Terminé' || '/' || 'Normal');
   
                -- Phase insertion la table d archive
                BEGIN
                    insert into DKA_IAPFAC_DEBLOC_HIST_INTERF
                    select * from DKA_IAPFAC_DEBLOC_INTERFACE
                    WHERE  LOADER_REQUEST_ID = g_loader_request_id 
                    ;
                EXCEPTION
                WHEN OTHERS
                    THEN
                        p_retcode   := 2;
                        Begin 
                            select message_text
                              into p_errbuf
                              from fnd_new_messages
                             where message_name like 'DKA_IAPFAC_DEBLOC_E04'
                               and Language_code='F'; 
                        exception
                        WHEN OTHERS
                        THEN
                            p_errbuf:='Echec du chargement des données dans la table d’archive';
                        END;
						
						delete from DKA_IAPFAC_DEBLOC_INTERFACE
						 WHERE LOADER_REQUEST_ID = g_loader_request_id;
						
                        Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
						--Fnd_File.put_line (Fnd_File.OUTPUT, '===> ERREUR : '|| p_errbuf);
                        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure Launch_Loader : EXCEPTION OTHERS ');
                END;
                
                -- Phase insertion la table de reporting
                BEGIN
                    insert into DKA_IAPFAC_DEBLOC_REPOR_INTERF
                    select * from DKA_IAPFAC_DEBLOC_INTERFACE
                    WHERE  LOADER_REQUEST_ID = g_loader_request_id 
                    ;
                EXCEPTION
                WHEN OTHERS
                    THEN
                        p_retcode   := 2;
                        Begin 
                            select message_text
                              into p_errbuf
                              from fnd_new_messages
                             where message_name like 'DKA_IAPFAC_DEBLOC_E05'
                               and Language_code='F'; 
                        EXCEPTION
                        WHEN OTHERS
                        THEN
                            p_errbuf:='Echec du chargement des données dans la table de reporting';
                        END;
						delete from DKA_IAPFAC_DEBLOC_INTERFACE
						 WHERE LOADER_REQUEST_ID = g_loader_request_id;

						delete from DKA_IAPFAC_DEBLOC_HIST_INTERF
						 WHERE LOADER_REQUEST_ID = g_loader_request_id;
						 
                        Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
						--Fnd_File.put_line (Fnd_File.OUTPUT, '===> ERREUR : '|| p_errbuf);
                        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure Launch_Loader : EXCEPTION OTHERS ');
                END;
           
                
            ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING')
            THEN
                Fnd_File.put_line (Fnd_File.LOG, 'Fin du traitement de chargement en warning '|| g_loader_request_id);
                p_retcode    := 1;

            ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL')
            THEN
                p_retcode := 2;
                p_Errbuf  := 'ERREUR : Fin anormale du traitement de chargement : '||v_Message;

                fnd_file.put_line(fnd_file.LOG, 'ERREUR : Fin anormale du traitement de chargement '|| g_loader_request_id  || CHR(10) ||
                                                'Phase/Statut : ' || v_dev_phase || '/' || v_dev_status || CHR(10) ||
                                                'MESSAGE : ' || v_message || CHR(10) );
				Fnd_File.put_line (Fnd_File.OUTPUT, '. Statut de fin : ' || 'Terminé' || '/' || 'Erreur');
                --Fnd_File.put_line (Fnd_File.OUTPUT, '===> ERREUR : Fin anormale du traitement de chargement '||g_loader_request_id);
            END IF;

        END IF;

        -- Calcul des statistiques sur les tables specifiques
        fnd_stats.gather_table_stats('DKA', 'DKA_IAPFAC_DEBLOC_INTERFACE', dbms_stats.auto_sample_size);
        -- fnd_stats.gather_table_stats('DKA', 'DKA_RCV_TRANSACTIONS_TMP', dbms_stats.auto_sample_size); -- SELO

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin Launch_Loader');

  EXCEPTION
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'LAUNCH_LOADER : ' ||SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure Launch_Loader : EXCEPTION OTHERS ');
  END Launch_Loader;

 /*
 *************************************************************************
 * PROCEDURE NAME : Bilan
 * 
 * DESCRIPTION
 *  Procédure de génération du bilan du traitement d'interface
 *
 * PARAMETERS
 * ==========
 * NAME                 DESCRIPTION
.* -------------------- ---------------------------------------------------
 * p_errbuf            Retour de message éventuel
 * p_retcode           Statut du traitement en sortie
 ************************************************************************
 */
  PROCEDURE Report_Bilan(p_statut              IN NUMBER) 
  IS
    
	CURSOR cur_err_validate is
    select distinct invoice_id, hold_code, TABLE_ID, message_text, statut
      from dka_program_messages dpm,
	       DKA_IAPFAC_DEBLOC_INTERFACE didi
     where prog_name ='DKA_IAPFAC_DEBLOC_INTERFACE'
       and table_id=didi.record_id	 
       and didi.request_id=g_request_id
	   and dpm.request_id=g_request_id
	   and didi.statut in ( 'REJECTED', 'PROCESSING_ERROR')
	   order by TABLE_ID;	
	   
	CURSOR cur_err_avertissement is
    select distinct invoice_id, hold_code, TABLE_ID, message_text, statut
      from dka_program_messages dpm,
	       DKA_IAPFAC_DEBLOC_INTERFACE didi
     where prog_name ='DKA_IAPFAC_DEBLOC_INTERFACE'
       and table_id=didi.record_id	 
       and didi.request_id=g_request_id
	   and dpm.request_id=g_request_id
	   and didi.statut = 'COMPLETE'
	   and dpm.message_type='W'
	   order by TABLE_ID;		   
	
	
     cv_line    VARCHAR2(100);
     V_STATUT   VARCHAR2(15);
  BEGIN

        cv_line    := '----------------------------------------------------------------------------------';

  
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début Report_Bilan');

        --------------------    
        -- Initialisation --
        --------------------          
  
       BEGIN
            UPDATE DKA_IAPFAC_DEBLOC_REPOR_INTERF diri
               SET diri.Statut = (select statut 
                                    from DKA_IAPFAC_DEBLOC_INTERFACE didi
                                   where didi.record_id=diri.record_id
                                     and didi.request_id=g_request_id)
                                  where exists (select distinct 1
                             from DKA_IAPFAC_DEBLOC_INTERFACE didi
                            where didi.record_id=diri.record_id);
       
		EXCEPTION
		  when others then
		    null;
		END;
        BEGIN                          
            SELECT count(1)
              INTO g_summary.rejected_header_rows
              FROM DKA_IAPFAC_DEBLOC_INTERFACE
             WHERE STATUT = 'REJECTED'
            ;
            
            SELECT count(1)
              INTO g_summary.rejected_io_rows
              FROM DKA_IAPFAC_DEBLOC_INTERFACE 
             WHERE STATUT = 'PROCESSING_ERROR' 
            ;
            
            SELECT count(1)
              INTO g_summary.complete_header_rows
              FROM DKA_IAPFAC_DEBLOC_INTERFACE
             WHERE STATUT  = 'COMPLETE'
            ;
			
			SELECT count(1)
              INTO g_summary.loaded_header_rows
              FROM DKA_IAPFAC_DEBLOC_INTERFACE;

            SELECT count(1)
              INTO g_summary.rec_final_rows
              FROM DKA_IAPFAC_DEBLOC_INTERFACE 
             WHERE STATUT = 'COMPLETE' 
              -- AND flag_rec_finale = 'Y'
               ;            
                   	
            
            select decode(p_statut, 0, 'Normal', 1, 'Avertissement', 2, 'Erreur') into v_statut
		      from dual;
		EXCEPTION
		  when others then
		    null;
		END;	
		Fnd_File.put_line (Fnd_File.output, CHR(10));    		
        Fnd_File.put_line (Fnd_File.output, 'BILAN :');
		Fnd_File.put_line (Fnd_File.output, '-------');
	       
		
		fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''enregistrements à traiter (nouveaux et rejets)	                 : '||TO_CHAR(g_summary.loaded_header_rows));
		fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''enregistrements rejetés (phase de validation)                      : ' || TO_CHAR(g_summary.rejected_header_rows));
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''enregistrements rejetés (phase de traitement)                      : ' || TO_CHAR(g_summary.rejected_io_rows)); 
		fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''enregistrements traités avec succès :                              : '||TO_CHAR(g_summary.complete_header_rows));		

		Fnd_File.put_line (Fnd_File.output, CHR(10));
        Fnd_File.put_line (Fnd_File.output, 'LISTE DES ANOMALIES : ');
        Fnd_File.put_line (Fnd_File.output, '----------------------');        
		FOR rec_cur_err_validate IN cur_err_validate LOOP	
            if 	rec_cur_err_validate.STATUT = 'REJECTED'  then	
                Add_Message(rec_cur_err_validate.invoice_id, rec_cur_err_validate.HOLD_CODE,  rec_cur_err_validate.TABLE_ID, rec_cur_err_validate.message_text, 'VALIDATION');
			else
                Add_Message(rec_cur_err_validate.invoice_id, rec_cur_err_validate.HOLD_CODE, rec_cur_err_validate.TABLE_ID, rec_cur_err_validate.message_text, 'TRAITEMENT');			
			end if;
        END LOOP;			
		
		g_summary.message_flag := 0;
		
		Fnd_File.put_line (Fnd_File.output, CHR(10));
        Fnd_File.put_line (Fnd_File.output, 'LISTE DES AVERTISSEMENTS :'); 
        Fnd_File.put_line (Fnd_File.output, '----------------------'); 		
		FOR rec_cur_err_avertissement IN cur_err_avertissement LOOP		
            Add_Message(rec_cur_err_avertissement.invoice_id, rec_cur_err_avertissement.HOLD_CODE,  rec_cur_err_avertissement.TABLE_ID, rec_cur_err_avertissement.message_text, 'VALIDATION');
        END LOOP;	
        fnd_file.put_line(fnd_file.OUTPUT,CHR(10));
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin Report_Bilan');  
        
		/*                     
		 UPDATE DKA_IAPFAC_DEBLOC_INTERFACE
		  SET STATUT = 'COMPLETE'
		WHERE STATUT = 'COMPLETED';
		Commit;
        */
  END Report_Bilan; 

/* *************************************************************************
 * PROCEDURE NAME : purge_data
 *
 * DESCRIPTION
 *  Procédure de purge des données
 *
 * PARAMETERS
 * ==========
 * NAME               DESCRIPTION
 * -----------------  ------------------------------------------------------
 *
 *************************************************************************/
  PROCEDURE purge_data(p_Errbuf            OUT VARCHAR2,
                       p_retcode           OUT NUMBER
                              ) 
  IS

  BEGIN




     -- On supprime les enregistrements
     --RG304
     Fnd_File.Put_Line(Fnd_File.LOG, '-> DKA_IAPFAC_DEBLOC_INTERFACE - Complete' );
	 
	 
     Fnd_File.Put_Line(Fnd_File.LOG, '-> DKA_IAPFAC_DEBLOC_INTERFACE' );
     DELETE FROM DKA_IAPFAC_DEBLOC_INTERFACE
     where STATUT = 'COMPLETE';

     g_summary.purged_header_rows := SQL%ROWCOUNT;
     Fnd_File.Put_Line(Fnd_File.LOG, '=> Deleted rows dans la table DKA_IAPFAC_DEBLOC_INTERFACE :'||TO_CHAR(g_summary.purged_header_rows));
     

/*
     Fnd_File.Put_Line(Fnd_File.LOG, '-> Recyclage des enregistrements remplacés par une nouvelle version. ' );

     update DKA_IAPFAC_DEBLOC_REPOR_INTERF DIDI
	    set STATUT = 'DELETED'
	  where exists (select distinct 1
		              from DKA_IAPFAC_DEBLOC_INTERFACE DII
					 where DII.HOLD_ID=DIDI.HOLD_ID
					   and dii.STATUT ='NEW'
					   and dii.file_name <> DIDI.file_name)
		and DIDI.STATUT in ('REJECTED','PROCESSING_ERROR');

	 
	 delete from DKA_IAPFAC_DEBLOC_INTERFACE DIDI
	  where DIDI.STATUT in ('REJECTED','PROCESSING_ERROR')
	    and exists (select distinct 1
		              from DKA_IAPFAC_DEBLOC_INTERFACE DII
					 where DII.HOLD_ID=DIDI.HOLD_ID
					   and dii.STATUT ='NEW'
					   and dii.file_name <> DIDI.file_name);
*/
    Fnd_File.Put_Line(Fnd_File.LOG, '-> Nettoyage dka_program_messages. ' );   
	DELETE FROM dka_program_messages dpm
     where prog_name ='DKA_IAPFAC_DEBLOC_INTERFACE';	
	
	
	
  EXCEPTION
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'PURGE_DATA : ' ||SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure PURGE_DATA : EXCEPTION OTHERS ');
  END purge_data;

/* *************************************************************************
 * PROCEDURE NAME : Rec_enreg_remp
 *
 * DESCRIPTION
 *  Procédure de purge des données
 *
 * PARAMETERS
 * ==========
 * NAME               DESCRIPTION
 * -----------------  ------------------------------------------------------
 *
 *************************************************************************/
  PROCEDURE Rec_enreg_remp(p_Errbuf            OUT VARCHAR2,
                            p_retcode           OUT NUMBER
                              ) 
  IS

  BEGIN

     Fnd_File.Put_Line(Fnd_File.LOG, '-> Recyclage des enregistrements remplacés par une nouvelle version. ' );

     update DKA_IAPFAC_DEBLOC_REPOR_INTERF DIDI
	    set STATUT = 'DELETED'
	  where exists (select distinct 1
		              from DKA_IAPFAC_DEBLOC_INTERFACE DII
					 where DII.HOLD_ID=DIDI.HOLD_ID
					   and dii.STATUT ='NEW'
					   and dii.file_name <> DIDI.file_name)
		and DIDI.STATUT in ('REJECTED','PROCESSING_ERROR');

	 
	 delete from DKA_IAPFAC_DEBLOC_INTERFACE DIDI
	  where DIDI.STATUT in ('REJECTED','PROCESSING_ERROR')
	    and exists (select distinct 1
		              from DKA_IAPFAC_DEBLOC_INTERFACE DII
					 where DII.HOLD_ID=DIDI.HOLD_ID
					   and dii.STATUT ='NEW'
					   and dii.file_name <> DIDI.file_name);

	/* update DKA_IAPFAC_DEBLOC_INTERFACE
        set STATUT = 'NEW'
		  , COMMENTAIRE = REPLACE(COMMENTAIRE,CHR(13),'');
    */

   EXCEPTION
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'Rec_enreg_remp : ' ||SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure Rec_enreg_remp : EXCEPTION OTHERS ');
  END Rec_enreg_remp;   
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

PROCEDURE main(
                p_Errbuf    IN OUT  VARCHAR2,
                p_retcode   OUT     NUMBER,
                p_reprise   IN      VARCHAR2
              )

IS
  v_errbuf                    VARCHAR2(2500);
  v_retcode                   NUMBER;
  Erreur_Programme            EXCEPTION;
  error                       EXCEPTION;
  v_current_program_unit      VARCHAR2(30);
  v_unicite_blocages          NUMBER;
  v_message                   VARCHAR2(2500);
  cursor 	CUR_UNICITE is
     select 'ID Blocage Oracle : '|| hold_id ||' / Nom de fichier : '|| file_name as UNICITE
       from DKA_IAPFAC_DEBLOC_INTERFACE
	  where 1=1
	    --and statut = 'NEW'
      group by 'ID Blocage Oracle : '|| hold_id ||' / Nom de fichier : '|| file_name
     having count('ID Blocage Oracle : '|| hold_id ||' / Nom de fichier : '|| file_name) >1;
  
BEGIN

      ----------------------------
      -- PHASE D'INITIALISATION --
      ----------------------------
      
      v_current_program_unit := 'main';
      Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'DEBUT DE L''INTERFACE'); 
      
      
      Output_Header;
    
      Request_parameters;   
      
      Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'PHASE D''INITIALISATION'); 
      
      v_errbuf  := NULL;
      v_retcode := 0;
      
      Init(v_errbuf, v_retcode, p_reprise);  -- SELO
      
      IF v_retcode = 2 
      THEN
          p_Errbuf  := v_errbuf;
          p_retcode := v_retcode;
          RAISE Erreur_Programme;
      END IF;       
       
	  ------------------------------------------
      -- PHASE DE PURGE DES ANCIENNES DONNEES  --
      -------------------------------------------
      Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'PURGE DES DONNEES'); 
      purge_data(v_errbuf,
                    v_retcode
                   );
      IF v_retcode = 2 
      THEN
          p_Errbuf  := v_errbuf;
          p_retcode := v_retcode;
          RAISE Erreur_Programme;
      END IF; 
      
	  
	  
      IF g_summary.reprise_flag = 'N' THEN
   
        ------------------------------------
        -- PHASE DE CHARGEMENT DU FICHIER --
        ------------------------------------ 
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'PHASE DE CHARGEMENT DU FICHIER'); 
      
      
        -- Lancement du programme de chargement
        Launch_Loader(v_errbuf,
                      v_retcode
                     );
        IF v_retcode = 2 
          THEN
          RAISE Erreur_Programme;
        END IF;
		
		BEGIN 
		    v_unicite_blocages := 0;
		  
			select distinct 1 into v_unicite_blocages
              from DKA_IAPFAC_DEBLOC_INTERFACE
	        -- where  statut = 'NEW'
             group by 'ID Blocage Oracle : '|| hold_id ||' / Nom de fichier : '|| file_name
            having count('ID Blocage Oracle : '|| hold_id ||' / Nom de fichier : '|| file_name) >1;
			
    	exception
		when others then
		    null;
		end;
		
		
   
      ELSE
        null; --SELO
      END IF;
	  
	  
	  
      
	  IF v_unicite_blocages = 1 then
	            v_message :=dka_tools_pkg.get_message('DKA','DKA_IAPFAC_DEBLOC_E03');
                --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                
               	Fnd_File.put_line (Fnd_File.output, v_message || CHR(10));
                
				Fnd_File.put_line (Fnd_File.output, 'Liste des « ID Blocage Oracle » en doublon :' );
                Fnd_File.put_line (Fnd_File.output, '-------------------------------------------');
				  FOR rec_cur_unicite IN cur_unicite LOOP
				      Fnd_File.put_line (Fnd_File.output, rec_cur_unicite.UNICITE);
			      END LOOP;                
                
				delete from DKA_IAPFAC_DEBLOC_HIST_INTERF where statut = 'NEW'
				and record_id in (select record_id from DKA_IAPFAC_DEBLOC_INTERFACE where statut = 'NEW');
				
				delete from DKA_IAPFAC_DEBLOC_REPOR_INTERF where statut = 'NEW'
				and record_id in (select record_id from DKA_IAPFAC_DEBLOC_INTERFACE where statut = 'NEW');
				
				delete from DKA_IAPFAC_DEBLOC_INTERFACE where statut = 'NEW';
				commit;
				fnd_file.put_line(fnd_file.OUTPUT,CHR(10));
				
				p_retcode := 2;
	  ELSE
 	  ------------------------------------------
      -- Recyclage des enregistrements remplaces par une nouvelle version  --
      -------------------------------------------
      Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Recyclage des enregistrements remplaces par une nouvelle version');      
	  Rec_enreg_remp(v_errbuf,
                    v_retcode
                   );
      IF v_retcode = 2 
      THEN
          p_Errbuf  := v_errbuf;
          p_retcode := v_retcode;
          RAISE Erreur_Programme;
      END IF; 
	  
	    -- Traitement des nouvelles données      
        -- Lancement de validation des données
        
	    validate_data(v_errbuf,
                      v_retcode
                     );
        IF v_retcode = 2 
        THEN
            RAISE Erreur_Programme;
        END IF;
        
        -- Lancement de l'insertion des données
        trt_data( v_errbuf,
                     v_retcode
                     );
        IF v_retcode = 2 
        THEN
            RAISE Erreur_Programme;
        END IF;
        
        -- bilan
        Report_Bilan(p_retcode); 	  
	 END IF;
     
                 
      ---------------------------------------
      -- PHASE DE FIN DU TRAITEMENT MAITRE --
      ---------------------------------------
      IF p_retcode = 2
      THEN
         p_errbuf := 'ATTENTION : Erreur bloquante : '||p_errbuf;
      ELSIF (g_summary.rejected_header_rows > 0 OR g_summary.rejected_io_rows > 0 OR g_summary.warning_flag = 'Y')
      THEN
         p_errbuf := 'ATTENTION : Il y a des cas de rejet ou avertissement.';
         p_retcode := 1;
      ELSIF (g_summary.loaded_header_rows = 0 AND g_summary.loaded_transaction_rows = 0 AND g_summary.reprise_flag = 'N')
      THEN
         p_errbuf := 'ATTENTION : Aucun enregistrement chargé.';
         p_retcode := 1;
      ELSE 
         p_errbuf := 'Fin normale du traitement - Aucun rejet.';
         p_retcode := 0;
      END IF;

	  
      COMMIT;
      Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
      Fnd_File.put_line (Fnd_File.OUTPUT, CHR(10)||p_errbuf||CHR(10));
      output_end;
      Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'FIN DE L''INTERFACE');       


  EXCEPTION
        WHEN Erreur_Programme THEN
            p_retcode   := 2;
            p_errbuf    := v_errbuf;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
        --    Fnd_File.put_line (Fnd_File.OUTPUT, CHR(10)||p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure '||v_current_program_unit||' : EXCEPTION Erreur_Traitement ');        
        --    Fnd_File.put_line (Fnd_File.OUTPUT, '==> Fin de la procédure '||v_current_program_unit||' : EXCEPTION Erreur_Traitement ');        
            output_end;			
       WHEN OTHERS 
       THEN
           fnd_concurrent.af_rollback;
           p_retcode := 2;
           Fnd_File.put_line (Fnd_File.Log,'Erreur technique sur le composant   : '||'DKA_IAPFAC_DEBLOC_PKG.' || v_current_program_unit||CHR(10)||'A retourné     : '||SQLERRM);
        --   Fnd_File.put_line (Fnd_File.Output ,CHR(10) || '==> Erreur technique (voir journal du traitement)' || CHR(10));
           p_errbuf := SQLERRM;
		   output_end;
  END main; 

------------------------------------------------------
END DKA_IAPFAC_DEBLOC_PKG;

/
SHOW ERRORS;

EXIT
