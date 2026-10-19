CREATE OR REPLACE PACKAGE BODY DKA_IMPTRECPO_PKG AS
  --------------------------------------------------------------------------------
  -- $
  -- Capgemini
  -- Projet           : DALKIA Oracle Applications
  -- Nom              : DKA_IMPTRECPO_PKG 
  -- Description      : Body du package DKA_IMPTRECPO_PKG ( IMPORT DES RECEPTIONS PO )
  -- Auteur           : R.AYMAZ
  -- Date de création : 23/04/2016
  -- Doc. associée    :
  -- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur APPS
  --------------------------------------------------------------------------------
  -- Historique
  -- Date       Qui Description
  -- ---------- --- --------------------------------------------------------------
  -- 23/03/2016 RAZ Création
  -- 02/09/2016 OBE Modification correctif artf2000309 
  -- 05/09/2016 OBE Modification correctif artf2000925 
  -- 27/01/2017 MEG Modification correctif artf2090363
  -- 23/03/2017 RBE Modification artf2125858
  -- 20/04/2017 MEG Modification artf2125858
  -- 03/07/2017 OBE artf2184213 : RUN ETI2 - Correction de réception et statut
  -- 02/08/2017 OBE artf2205872 : RDD recept - Correction contrôle sur lieu de mise à dispo
  --------------------------------------------------------------------------------  
  
 --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PRIVEES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    TYPE summary_typ IS RECORD 
    (
     loaded_header_rows               NUMBER      -- Nb des en-entêtes chargées en table specifique
    ,loaded_transaction_rows          NUMBER      -- Nb des transactions chargés en table specifique
    ,rejected_header_rows             NUMBER      -- Nb de Lignes en-entêtes rejectées
    ,rejected_transaction_rows        NUMBER      -- Nb de Lignes transaction rejectés
    ,inserted_header_rows             NUMBER      -- Nb de Lignes en-entêtes insérées
    ,inserted_transaction_rows        NUMBER      -- Nb de Lignes transaction insérés
    ,purged_header_rows               NUMBER      -- Nb de Lignes purgées en table spécifique   
    ,purged_transaction_rows          NUMBER      -- Nb de Lignes purgées en table spécifique 
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
    g_nb_entetes_group              NUMBER;


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

        cv_line    := '+-------------------------------------------------------------------------+';

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


        Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10));
        Fnd_File.put_line (Fnd_File.output, 'Nom du traitement  : ' || v_user_conc_program_name);
        Fnd_File.put_line (Fnd_File.output, 'Code du traitement : ' || v_conc_program_name);
        Fnd_File.put_line (Fnd_File.output, 'Programme lancé le : ' || TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || CHR(10));
        Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10) || CHR(10));
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

        Fnd_File.put_line (Fnd_File.output, 'PARAMETRES : ');
        Fnd_File.put_line (Fnd_File.output, '--------------');
        Fnd_File.put_line (Fnd_File.log, 'PARAMETRES : ');
        Fnd_File.put_line (Fnd_File.log, '--------------');

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

                   Fnd_File.put_line (Fnd_File.output, rec_parameters.form_left_prompt||' : '||v_argument_value);
                   Fnd_File.put_line (Fnd_File.log, rec_parameters.form_left_prompt||' : '||v_argument_value);


                   LOOP
                      FETCH cur_parameters INTO rec_parameters;
                      EXIT WHEN cur_parameters%NOTFOUND;

                          v_argument_num := v_argument_num + 1;
                          v_argument_number := 'ARGUMENT'||v_argument_num;

                          sql_req := 'SELECT '||v_argument_number||
                                     ' FROM fnd_concurrent_requests '||
                                     'WHERE request_id = Fnd_Global.conc_request_id';

                          EXECUTE IMMEDIATE sql_req INTO v_argument_value;

                          Fnd_File.put_line (Fnd_File.output, rec_parameters.form_left_prompt||' : '||v_argument_value);
                          Fnd_File.put_line (Fnd_File.log, rec_parameters.form_left_prompt||' : '||v_argument_value);
                   END LOOP;

                   Fnd_File.put_line (Fnd_File.output,CHR(10));

            ELSE
                   Fnd_File.put_line (Fnd_File.output,'Aucun argument');
                   Fnd_File.put_line (Fnd_File.log,'Aucun argument');
            END IF;

        CLOSE cur_parameters;

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

        cv_line    := '+-------------------------------------------------------------------------+';

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

  PROCEDURE Add_Message  (p_document_num      IN  VARCHAR2,
                          p_type_trans        IN  VARCHAR2,
                          p_message_text      IN  VARCHAR2,
                          pv_table_id         IN  VARCHAR2
                          ) 
  IS
        cv_line                     VARCHAR2 (500);
  BEGIN

    IF  g_summary.message_flag = 0 THEN
      cv_line := 'Etat des erreurs :';
      Fnd_File.put_line (Fnd_File.output, CHR(10)||cv_line);
      cv_line := '-----------------';
      Fnd_File.put_line (Fnd_File.output, cv_line);
      cv_line := 'Numéro de reception  Type de transaction  Message d''erreur';
      Fnd_File.put_line (Fnd_File.output, cv_line);
      cv_line := '-------------------  -------------------  ---------------';
      Fnd_File.put_line (Fnd_File.output, cv_line);
      g_summary.message_flag := 1;
    END IF;
    
    cv_line := RPAD(p_document_num,19,' ') ||'  '||RPAD(NVL(p_type_trans,' '),19,' ') ||'  ' || p_message_text ;

    Fnd_File.put_line (Fnd_File.output, cv_line);
    
    -- RBE artf2125858 : Inserer dans la table des erreurs spécifiques
    INSERT INTO dka_program_messages
      (request_id,
       prog_name,
       SOURCE,
       table_name,
       table_id,
       column_name,
       column_value,
       message_type,
       message_text)
    VALUES
      (g_request_id,        --request_id
       'DKA_IMPTRECPO',     --prog_name
       '11i',               --source
       DECODE(p_type_trans,NULL,'DKA_RCV_HEADERS_TMP','DKA_RCV_TRANSACTIONS_TMP') , --table_name
       pv_table_id,                                         --table_id
       DECODE(p_type_trans,NULL,NULL,'TRANSACTION_TYPE'),   --column_name
       p_type_trans,                                        --column_value
       'E',                                                 --message_type
       p_message_text                                       --message_text
       );

  END Add_Message;

  
--------------- FUNCTION get_organization_id ---------------------------------------
/*																					-- RBK MODIF FONCTION 
 FUNCTION get_organization_id ( p_document_num IN VARCHAR2 ) RETURN NUMBER
  IS
 -----------------------------------------------------------------------------------
    v_organization_id NUMBER;

  BEGIN

     -- RECHERCHE SI LE ORGANISATION ID EST PRÉSENT DANS L'OI
     BEGIN
        SELECT po.org_id
        INTO  v_organization_id
        FROM  po_headers_all po
        WHERE po.segment1 = p_document_num
        AND   (po.type_lookup_code LIKE 'STANDARD'
        OR    po.segment1 LIKE '%ST%')
        AND   rownum = 1 ;
     
     EXCEPTION
     WHEN NO_DATA_FOUND
     THEN
         v_organization_id := -1;
     END;

     ----- return value -----
     RETURN (v_organization_id);

END get_organization_id;
*/
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

/**************************************************************************
 * PROCEDURE NAME : update_region_societe
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
  PROCEDURE update_region_societe(p_Errbuf            OUT VARCHAR2,
                                  p_retcode           OUT NUMBER
                                 ) 
  IS

  BEGIN

     Fnd_File.Put_Line(Fnd_File.LOG, '-> DEBUT UPDATE_REGION_SOCIETE' );

     UPDATE dka.DKA_RCV_HEADERS_TMP drh
        SET drh.region  = (SELECT substr(haou.name, 1, 3)
                             FROM po_headers_all pha, hr_all_organization_units haou
                            WHERE pha.org_id = haou.organization_id
                              AND pha.segment1 = drh.document_num),
            drh.societe = (SELECT substr(haou.name, 4)
                             FROM po_headers_all pha, hr_all_organization_units haou
                            WHERE pha.org_id = haou.organization_id
                              AND pha.segment1 = drh.document_num);

     UPDATE dka.DKA_RCV_TRANSACTIONS_TMP drh
        SET drh.region  = (SELECT substr(haou.name, 1, 3)
                             FROM po_headers_all pha, hr_all_organization_units haou
                            WHERE pha.org_id = haou.organization_id
                              AND pha.segment1 = drh.po_num),
            drh.societe = (SELECT substr(haou.name, 4)
                             FROM po_headers_all pha, hr_all_organization_units haou
                            WHERE pha.org_id = haou.organization_id
                              AND pha.segment1 = drh.po_num);


     Fnd_File.Put_Line(Fnd_File.LOG, '-> FIN UPDATE_REGION_SOCIETE' );

  EXCEPTION
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'UPDATE_REGION_SOCIETE : ' ||SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure UPDATE_REGION_SOCIETE : EXCEPTION OTHERS ');
  END update_region_societe;

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
                  p_reprise   IN       VARCHAR2,
                  p_gl_date   IN       VARCHAR2
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
        g_summary.loaded_transaction_rows        := 0;

        g_summary.rejected_header_rows           := 0;
        g_summary.rejected_transaction_rows      := 0;

        g_summary.inserted_header_rows           := 0;
        g_summary.inserted_transaction_rows      := 0;

        g_summary.purged_header_rows             := 0;
        g_summary.purged_transaction_rows        := 0;
        
        g_summary.message_flag                   := 0;
        g_summary.reprise_flag                   := NVL(p_reprise,'N');
        g_summary.warning_flag                   := 'N';
        
        
        -- Formatage de la date comptable 
        g_gl_date := TRUNC(fnd_date.canonical_to_date(p_gl_date));

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
        
        -- Récupération des variables de la table des paramètres
        Dka_Tools_Pkg.get_parameter('DKA_IMPTRECPO',
                                    'NB_ENTETE_GROUP_ID',
                                    rec_param,
                                    p_retcode,
                                    p_errbuf);
        g_nb_entetes_group := rec_param.number_value;
        IF p_retcode != 0 THEN
           p_errbuf := 'init : g_nb_entetes_group - ' || p_errbuf;
           RETURN;
        END IF;
 
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

  v_person_id              NUMBER;
  v_processing_status_code VARCHAR2(100) DEFAULT 'PENDING';
  v_receipt_source_code    VARCHAR2(100) DEFAULT 'VENDOR';
  v_transaction_type       VARCHAR2(100) DEFAULT 'NEW';
  v_processing_mode_code   VARCHAR2(100) DEFAULT 'BATCH';
  v_code_site_four         VARCHAR2(100);
  v_org_id                 NUMBER;
  v_pers_id                NUMBER;
  v_rcv_header_id          NUMBER;
  v_message                VARCHAR2(500);

  v_flag_erreur       BOOLEAN := FALSE;
  v_flag_erreur_trans BOOLEAN := FALSE;

  v_ship_to_organization_id NUMBER;
  v_code_site_four1         VARCHAR2(240);
  v_receive_trans_id        NUMBER;

  v_ship_to_location            VARCHAR2(100); -- OBE
  v_vendor_site_code            VARCHAR2(25); -- OBE
  v_vendor_site_code_2          VARCHAR2(25); -- OBE
  v_location_code               VARCHAR2(60); -- OBE
  v_deliver_to_location         VARCHAR2(60); -- OBE 
  v_deliver_to_location_id      NUMBER;       -- RBE
  v_DELIVER_TO_PERSON           VARCHAR2(240);
  e_err_org_not_exist           EXCEPTION;

  -- Cursor des receptions
  CURSOR cur_recept IS
    SELECT *
      FROM dka.DKA_RCV_HEADERS_TMP
     WHERE 1 = 1
       AND load_request_id = DECODE(g_loader_request_id, -1, load_request_id, g_loader_request_id)
       AND flag = '-1'
     ORDER BY RECEIPT_NUM, SOCIETE, REGION -- RBK ajout
       FOR UPDATE OF FLAG, ORG_ID, CODE_SITE_FOUR;
  -- Cursor des transactions
  CURSOR cur_transactions(p_receipt_num VARCHAR2, p_societe VARCHAR2 -- RBK ajout
  , p_region VARCHAR2 -- RBK ajout
  ) IS
    SELECT *
      FROM dka.DKA_RCV_TRANSACTIONS_TMP
     WHERE RECEIPT_NUM = p_receipt_num
       AND SOCIETE = p_societe -- RBK ajout
       AND REGION = p_region -- RBK ajout
     ORDER BY PO_LINE_NUM, PO_SHIP_LINE_NUM DESC -- RBK (transaction_id)   
       FOR UPDATE OF FLAG, ORG_ID, CODE_SITE_FOUR, PERSON_ID, INTERFACE_TRANSACTION_ID, SHIP_TO_LOCATION -- OBE
    , DELIVER_TO_PERSON;

BEGIN

  Fnd_File.put_line(Fnd_File.LOG, TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début validate_data');
  Fnd_File.put_line(Fnd_File.LOG,
                    TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                    'Validation des données dans les tables spécifiques : ');

  -- RBK ajout update IDs de PO
  UPDATE DKA_RCV_TRANSACTIONS_TMP drt
     set ORG_ID = (SELECT hr.ORGANIZATION_ID FROM hr_operating_units hr WHERE hr.NAME = drt.region || drt.societe)
   where flag = '-1';
  --
  UPDATE DKA_RCV_TRANSACTIONS_TMP drt
     set po_header_id = (select pha.po_header_id
                           from po_headers_all pha
                          where pha.segment1 = drt.PO_NUM
                            and pha.org_id = drt.org_id)
   where flag = '-1';
  --
  UPDATE DKA_RCV_TRANSACTIONS_TMP drt
     set po_line_id = (select pla.po_line_id
                         from po_lines_all pla
                        where pla.po_header_id = drt.po_header_id
                          and pla.line_num = drt.PO_LINE_NUM)
   where flag = '-1';
  --
  UPDATE DKA_RCV_TRANSACTIONS_TMP drt
     set po_line_location_id = (select plla.line_location_id
                                  from po_line_locations_all plla
                                 where plla.po_header_id = drt.po_header_id
                                   and plla.po_line_id = drt.po_line_id
                                   and plla.shipment_num = drt.PO_SHIP_LINE_NUM)
   where flag = '-1';
  --
  --RBE artf2125858
  UPDATE DKA_RCV_TRANSACTIONS_TMP drt
     set po_distribution_id = (select pda.po_distribution_id
                                 from po_distributions_all pda
                                where pda.po_header_id = drt.po_header_id
                                  and pda.po_line_id = drt.po_line_id
                                  and pda.line_location_id = drt.po_line_location_id
                                  and pda.distribution_num = drt.PO_DIST_NUM)
   where flag = '-1';
  --

  COMMIT;

  FOR rec_cur_recept IN cur_recept LOOP
    BEGIN
      v_flag_erreur := FALSE;
    
      -- ORG_ID
      --v_org_id := get_organization_id (rec_cur_recept.document_num);                -- RBK
      v_org_id := get_organization_id(rec_cur_recept.SOCIETE, rec_cur_recept.REGION);
    
      IF v_org_id = -1 THEN
        --erreur
        v_org_id  := NULL;
        v_message := 'Erreur de récupération du ORG_ID ';
        Add_Message(rec_cur_recept.RECEIPT_NUM, NULL, v_message, rec_cur_recept.receipt_num);
        v_flag_erreur := TRUE;
        RAISE e_err_org_not_exist;
      END IF;
    
      -- Site fournisseur
      --< OBE
      /*
      v_code_site_four:= GET_VENDOR_SITE_ID (rec_cur_recept.VENDOR_NUM,rec_cur_recept.VENDOR_SITE_CODE,v_org_id);
      IF v_code_site_four = -1 THEN
          --erreur
          v_code_site_four := NULL;
          v_message := 'Erreur de récupération du site fournisseur pour '||rec_cur_recept.VENDOR_NUM ||'/'||rec_cur_recept.VENDOR_SITE_CODE;
          Add_Message(rec_cur_recept.RECEIPT_NUM, NULL,v_message);
          v_flag_erreur := TRUE;
      END IF;
      */
    
      BEGIN
        SELECT FULL_NAME
          INTO rec_cur_recept.EMPLOYEE_NAME
          FROM apps.PER_ALL_PEOPLE_F ppf
         WHERE 1 = 1
           AND EMPLOYEE_NUMBER = rec_cur_recept.EMPLOYEE_NAME
           AND SYSDATE BETWEEN NVL(PPF.EFFECTIVE_START_DATE, SYSDATE) AND NVL(PPF.EFFECTIVE_END_DATE, SYSDATE)
           AND ppf.CURRENT_EMPLOYEE_FLAG = 'Y';
      EXCEPTION
        WHEN OTHERS THEN
          rec_cur_recept.EMPLOYEE_NAME := NULL;
      END;
    
      BEGIN
        SELECT a.VENDOR_SITE_CODE
          INTO v_vendor_site_code
          FROM PO_VENDOR_SITES_ALL a, po_headers_all b
         WHERE b.VENDOR_SITE_ID = a.VENDOR_SITE_ID
           AND b.segment1 = rec_cur_recept.document_num
           and b.org_id = v_org_id -- RBK ajout
        ;
      EXCEPTION
        WHEN OTHERS THEN
          v_vendor_site_code := NULL;
          v_message          := 'Erreur de récupération du site fournisseur pour ' || rec_cur_recept.VENDOR_NUM || '/' ||
                                rec_cur_recept.VENDOR_SITE_CODE;
          Add_Message(rec_cur_recept.RECEIPT_NUM, NULL, v_message, rec_cur_recept.receipt_num);
          v_flag_erreur := TRUE;
      END;
      --> OBE
    
      -- LIGNES DE RECEPTIONS
      FOR rec_cur_transactions IN cur_transactions(rec_cur_recept.RECEIPT_NUM,
                                                   rec_cur_recept.SOCIETE, -- RBK 
                                                   rec_cur_recept.REGION -- RBK
                                                   ) LOOP
        v_flag_erreur_trans := FALSE;

        -- RBK Ajout controle sur les IDs PO
        IF rec_cur_transactions.PO_HEADER_ID IS NULL THEN
          v_message := 'Erreur de récupération du PO_HEADER_ID ';
          Add_Message(rec_cur_recept.RECEIPT_NUM,
                      rec_cur_transactions.transaction_type,
                      v_message,
                      rec_cur_transactions.receipt_num);
          -- v_flag_erreur := TRUE;    -- OBE artf2184213
          v_flag_erreur_trans := TRUE; -- OBE artf2184213
        END IF;
      
        IF rec_cur_transactions.PO_LINE_ID IS NULL THEN
          v_message := 'Erreur de récupération du PO_LINE_ID ';
          Add_Message(rec_cur_recept.RECEIPT_NUM,
                      rec_cur_transactions.transaction_type,
                      v_message,
                      rec_cur_transactions.receipt_num);
          -- v_flag_erreur := TRUE;    -- OBE artf2184213
          v_flag_erreur_trans := TRUE; -- OBE artf2184213
        END IF;
      
        IF rec_cur_transactions.PO_LINE_LOCATION_ID IS NULL THEN
          v_message := 'Erreur de récupération du PO_LINE_LOCATION_ID ';
          Add_Message(rec_cur_recept.RECEIPT_NUM,
                      rec_cur_transactions.transaction_type,
                      v_message,
                      rec_cur_transactions.receipt_num);
          -- v_flag_erreur := TRUE;    -- OBE artf2184213
          v_flag_erreur_trans := TRUE; -- OBE artf2184213
        END IF;
      
        --RBE artf2125858
        IF rec_cur_transactions.po_distribution_id IS NULL THEN
          v_message := 'Erreur de récupération du PO_DISTRIBUTION_ID ';
          Add_Message(rec_cur_recept.RECEIPT_NUM,
                      rec_cur_transactions.transaction_type,
                      v_message,
                      rec_cur_transactions.receipt_num);
          -- v_flag_erreur := TRUE;    -- OBE artf2184213
          v_flag_erreur_trans := TRUE; -- OBE artf2184213
        END IF;

        --IF rec_cur_transactions.DELIVER_TO_PERSON IS NOT NULL THEN
        -- Recherche si le PERSON ID est présent
        BEGIN 
          SELECT pda.deliver_to_person_id, ppf.full_name
            INTO v_person_id, v_DELIVER_TO_PERSON
            FROM po_distributions_all pda, PER_ALL_PEOPLE_F ppf
           WHERE pda.po_header_id = rec_cur_transactions.po_header_id
             AND pda.po_line_id = rec_cur_transactions.po_line_id
             AND pda.line_location_id = rec_cur_transactions.po_line_location_id
             AND pda.distribution_num = rec_cur_transactions.po_dist_num
             AND pda.deliver_to_person_id = ppf.person_id
             AND sysdate BETWEEN nvl(ppf.effective_start_date, sysdate) AND nvl(ppf.effective_end_date, sysdate)
             AND ppf.current_employee_flag = 'Y';

          /*
          SELECT FULL_NAME
            INTO v_DELIVER_TO_PERSON
            FROM apps.PER_ALL_PEOPLE_F ppf
           WHERE 1 = 1
             AND EMPLOYEE_NUMBER = rec_cur_transactions.DELIVER_TO_PERSON
             AND SYSDATE BETWEEN NVL(PPF.EFFECTIVE_START_DATE, SYSDATE) AND NVL(PPF.EFFECTIVE_END_DATE, SYSDATE)
             AND ppf.CURRENT_EMPLOYEE_FLAG = 'Y';
          */
        EXCEPTION
          WHEN OTHERS THEN
            V_DELIVER_TO_PERSON := NULL;  
            v_person_id := NULL;           
        END;
        --ELSE
        --  V_DELIVER_TO_PERSON := NULL;
        --  v_person_id := NULL;
        --END IF;

/*
        IF rec_cur_transactions.EMPLOYEE_NAME IS NOT NULL THEN
          -- Recherche si le PERSON ID est présent
          BEGIN
            SELECT PERSON_ID
              INTO v_person_id
              FROM apps.PER_ALL_PEOPLE_F ppf
             WHERE 1 = 1
               AND EMPLOYEE_NUMBER = rec_cur_transactions.EMPLOYEE_NAME
               AND SYSDATE BETWEEN NVL(PPF.EFFECTIVE_START_DATE, SYSDATE) AND NVL(PPF.EFFECTIVE_END_DATE, SYSDATE)
               AND ppf.CURRENT_EMPLOYEE_FLAG = 'Y';
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              BEGIN
                SELECT PERSON_ID
                  INTO v_person_id
                  FROM apps.PER_ALL_PEOPLE_F ppf
                 WHERE 1 = 1
                   AND FULL_NAME = 'REPRISE, REPRISE'
                   AND SYSDATE BETWEEN NVL(PPF.EFFECTIVE_START_DATE, SYSDATE) AND NVL(PPF.EFFECTIVE_END_DATE, SYSDATE)
                   AND ppf.CURRENT_EMPLOYEE_FLAG = 'Y';
              
                v_message := 'Avertissement : Acheteur ' || rec_cur_transactions.EMPLOYEE_NAME ||
                             ' n''existe pas en tant qu''employé, remplacé par REPRISE ';
                Add_Message(rec_cur_recept.RECEIPT_NUM,
                            rec_cur_transactions.transaction_type,
                            v_message,
                            rec_cur_transactions.receipt_num);
                g_summary.warning_flag := 'Y';
              
              EXCEPTION
                WHEN OTHERS THEN
                  v_person_id := NULL;
                  v_message   := 'Erreur de récupération du PERSON_ID ';
                  Add_Message(rec_cur_recept.RECEIPT_NUM,
                              rec_cur_transactions.transaction_type,
                              v_message,
                              rec_cur_transactions.receipt_num);
                  v_flag_erreur_trans := TRUE;
              END;
            WHEN OTHERS THEN
              v_person_id := NULL;
              v_message   := 'Erreur de récupération du PERSON_ID ';
              Add_Message(rec_cur_recept.RECEIPT_NUM,
                          rec_cur_transactions.transaction_type,
                          v_message,
                          rec_cur_transactions.receipt_num);
              v_flag_erreur_trans := TRUE;
            
          END;
       
        ELSE
          v_person_id := NULL;
        END IF;
*/

        --v_SHIP_TO_ORGANIZATION_ID := get_organization_id(rec_cur_transactions.PO_NUM);                      -- RBK 
        v_SHIP_TO_ORGANIZATION_ID := get_organization_id(rec_cur_transactions.SOCIETE, rec_cur_transactions.REGION);
        IF v_ship_to_organization_id = -1 THEN
          --erreur
          v_ship_to_organization_id := NULL;
          v_message                 := 'Erreur de récupération du ORG_ID ';
          Add_Message(rec_cur_recept.RECEIPT_NUM,
                      rec_cur_transactions.transaction_type,
                      v_message,
                      rec_cur_transactions.receipt_num);
          v_flag_erreur_trans := TRUE;
        END IF;
        /*
        v_code_site_four1 := GET_VENDOR_SITE_ID (rec_cur_transactions.VENDOR_NUM,rec_cur_transactions.VENDOR_SITE_CODE,v_SHIP_TO_ORGANIZATION_ID);
        IF v_code_site_four1 = -1 THEN
            --erreur
            v_code_site_four1 := NULL;
            v_message := 'Erreur de récupération du site fournisseur ';
            Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_transactions.transaction_type,v_message);
            v_flag_erreur_trans := TRUE;
        END IF;
        */
        --< OBE

        -- Récupération du VENDOR_SITE_CODE de la commande
        BEGIN
          SELECT a.VENDOR_SITE_CODE
            INTO v_vendor_site_code_2
            FROM PO_VENDOR_SITES_ALL a, po_headers_all b
           WHERE b.VENDOR_SITE_ID = a.VENDOR_SITE_ID
             AND b.segment1 = rec_cur_transactions.po_num
             and b.org_id = v_org_id -- RBK ajout
          ;
        EXCEPTION
          WHEN OTHERS THEN
            v_vendor_site_code_2 := NULL;
            v_message            := 'Erreur de récupération du site fournisseur pour ' || rec_cur_recept.VENDOR_NUM || '/' ||
                                    rec_cur_recept.VENDOR_SITE_CODE;
            Add_Message(rec_cur_recept.RECEIPT_NUM,
                        rec_cur_transactions.transaction_type,
                        v_message,
                        rec_cur_transactions.receipt_num);
            -- v_flag_erreur := TRUE;    -- OBE artf2184213
          v_flag_erreur_trans := TRUE; -- OBE artf2184213
        END;
        
        -- Récupération du SHIP_TO_LOCATION de la commande
        BEGIN
          /*
          SELECT b.LOCATION_CODE
            INTO v_ship_to_location
            FROM po_headers_all a, HR_LOCATIONS_ALL b
           WHERE a.SHIP_TO_LOCATION_ID = b.location_id
             AND a.segment1 = rec_cur_transactions.po_num
             and a.org_id = v_org_id; -- RBK ajout        
          */
          
          SELECT b.location_code
            INTO v_ship_to_location
            FROM po_line_locations_all plla, hr_locations_all b
           WHERE plla.ship_to_location_id = b.location_id
             AND plla.po_header_id = rec_cur_transactions.po_header_id
             AND plla.po_line_id = rec_cur_transactions.po_line_id
             AND plla.shipment_num = rec_cur_transactions.po_ship_line_num;
          
        EXCEPTION
          WHEN OTHERS THEN
            v_ship_to_location := NULL;
            v_message          := 'Erreur de récupération du lieu de livraison';
            Add_Message(rec_cur_recept.RECEIPT_NUM,
                        rec_cur_transactions.transaction_type,
                        v_message,
                        rec_cur_transactions.receipt_num);
            v_flag_erreur_trans := TRUE;
        END;
      
        -- Transcodification du champ LOCATION_CODE
        DKA_REP_TRANSCO_PKG.get_transco(pv_transco_name => '016_LIEUX_LIV_FACT',
                                        pv_column_01    => rec_cur_transactions.LOCATION_CODE,
                                        pv_out_01       => v_location_code);
      
        -- Transcodification du champ DELIVER_TO_LOCATION_CODE
      
        DKA_REP_TRANSCO_PKG.get_transco(pv_transco_name => '016_LIEUX_LIV_FACT',
                                        pv_column_01    => rec_cur_transactions.DELIVER_TO_LOCATION,
                                        pv_out_01       => v_deliver_to_location);
      
        -- RBK ajout car il est obligatoire 
        --IF v_deliver_to_location IS NULL THEN --RBE  artf2125858
        --v_deliver_to_location := 'DALKIA' ; --RBE   artf2125858
        --RBE artf2125858 : si le lieu de mise à disposition (DKA_RCV_TRANSACTIONS_TMP.deliver_to_location) n'existe pas ==> recuperer le lieu de mise à disposition de l'imputation de la commande
        BEGIN
          SELECT hla.location_code,hla.location_id --RBE
            INTO v_deliver_to_location,v_deliver_to_location_id -- RBE
            FROM HR_LOCATIONS_ALL hla
           WHERE hla.location_code = v_deliver_to_location;
        EXCEPTION
          WHEN OTHERS THEN
            BEGIN
              SELECT hla.location_code,hla.location_id --RBE artf2125858
                INTO v_deliver_to_location,v_deliver_to_location_id --RBE artf2125858
                FROM PO_DISTRIBUTIONS_ALL pda, HR_LOCATIONS_ALL hla
               WHERE 1 = 1
                 AND PDA.PO_HEADER_ID = rec_cur_transactions.PO_HEADER_ID
                 AND PDA.PO_LINE_ID = rec_cur_transactions.PO_LINE_ID
                 AND PDA.LINE_LOCATION_ID = rec_cur_transactions.PO_LINE_LOCATION_ID
                 AND PDA.PO_DISTRIBUTION_ID = rec_cur_transactions.PO_DISTRIBUTION_ID
                 AND HLA.LOCATION_ID = PDA.DELIVER_TO_LOCATION_ID;
            EXCEPTION
              WHEN OTHERS THEN
              
                --< OBE artf2205872 
                BEGIN 
                  SELECT hla.location_code,hla.location_id
                    INTO v_deliver_to_location,v_deliver_to_location_id
                    FROM PO_LINE_LOCATIONS_ALL plla, HR_LOCATIONS_ALL hla
                   WHERE 1 = 1
                     AND plla.PO_HEADER_ID = rec_cur_transactions.PO_HEADER_ID
                     AND plla.PO_LINE_ID = rec_cur_transactions.PO_LINE_ID
                     AND plla.LINE_LOCATION_ID = rec_cur_transactions.PO_LINE_LOCATION_ID
                     AND HLA.LOCATION_ID = plla.ship_to_location_id;                
                EXCEPTION
                  WHEN OTHERS THEN
                    v_deliver_to_location := NULL;
                    v_deliver_to_location_id := NULL;
                    v_message             := 'Erreur de récupération du lieu de livraison de la ligne de livraison de la commande';
                    Add_Message(rec_cur_recept.RECEIPT_NUM,
                                rec_cur_transactions.transaction_type,
                                v_message,
                                rec_cur_transactions.receipt_num);
                    v_flag_erreur_trans := TRUE;                  
                END;
                --> OBE artf2205872 
            END;
        END;
        --END IF; --RBE artf2125858

      
        --> OBE
      
        -- INTERFACE_TRANSACTION_ID
        /*IF rec_cur_transactions.transaction_type LIKE 'DELIVER' THEN
            SELECT INTERFACE_TRANSACTION_ID 
            INTO v_receive_trans_id
            FROM DKA_RCV_TRANSACTIONS_TMP
            WHERE transaction_id = rec_cur_transactions.parent_transaction_id;
        ELSE
            v_receive_trans_id := NULL;
        END IF;*/
      
        -- Mettre à jour la reception
        IF NOT v_flag_erreur_trans THEN
        
          UPDATE DKA_RCV_TRANSACTIONS_TMP
             SET FLAG                     = 'S',
                 ORG_ID                   = v_ship_to_organization_id,
                 CODE_SITE_FOUR           = v_code_site_four1,
                 PERSON_ID                = v_person_id,
                 INTERFACE_TRANSACTION_ID = NULL,
                 SHIP_TO_LOCATION         = v_ship_to_location, -- OBE
                 VENDOR_SITE_CODE         = v_vendor_site_code_2, -- OBE
                 LOCATION_CODE            = v_location_code, -- OBE
                 --LOCATION_ID              = v_location_id, -- RBE artf2125858
                 DELIVER_TO_LOCATION      = v_deliver_to_location, -- OBE
                 DELIVER_TO_LOCATION_ID   = v_deliver_to_location_id, -- RBE artf2125858
                 DELIVER_TO_PERSON        = v_DELIVER_TO_PERSON
           WHERE CURRENT OF cur_transactions;
        ELSE
          v_flag_erreur := TRUE;
          UPDATE DKA_RCV_TRANSACTIONS_TMP
             SET flag                     = 'E',
                 org_id                   = v_ship_to_organization_id,
                 code_site_four           = v_code_site_four1,
                 PERSON_ID                = v_person_id,
                 INTERFACE_TRANSACTION_ID = NULL,
                 SHIP_TO_LOCATION         = v_ship_to_location, -- OBE
                 VENDOR_SITE_CODE         = v_vendor_site_code_2, -- OBE
                 LOCATION_CODE            = v_location_code, -- OBE
                 --LOCATION_ID              = v_location_id, -- RBE artf2125858
                 DELIVER_TO_LOCATION      = v_deliver_to_location, -- OBE
                 DELIVER_TO_LOCATION_ID   = v_deliver_to_location_id, -- RBE artf2125858
                 DELIVER_TO_PERSON        = v_DELIVER_TO_PERSON
           WHERE CURRENT OF cur_transactions;
        
        END iF;
      
      END LOOP;
    
      -- Mettre à jour la reception
      IF NOT v_flag_erreur THEN
        UPDATE DKA_RCV_HEADERS_TMP
           SET FLAG             = 'S',
               ORG_ID           = v_org_id,
               code_site_four   = v_code_site_four,
               VENDOR_SITE_CODE = v_vendor_site_code, -- OBE
               EMPLOYEE_NAME    = rec_cur_recept.EMPLOYEE_NAME
         WHERE CURRENT OF cur_recept;
      ELSE
        UPDATE DKA_RCV_HEADERS_TMP
           SET FLAG             = 'E',
               ORG_ID           = v_org_id,
               code_site_four   = v_code_site_four,
               VENDOR_SITE_CODE = v_vendor_site_code, -- OBE
               EMPLOYEE_NAME    = rec_cur_recept.EMPLOYEE_NAME
         WHERE CURRENT OF cur_recept;
        
        --< OBE artf2184213
        UPDATE DKA_RCV_TRANSACTIONS_TMP drt
           SET FLAG = 'E'
         WHERE drt.RECEIPT_NUM = rec_cur_recept.RECEIPT_NUM
           AND drt.SOCIETE = rec_cur_recept.SOCIETE
           AND drt.REGION = rec_cur_recept.REGION
           ;  
        --> OBE artf2184213   
      END IF;
    
    EXCEPTION
      WHEN e_err_org_not_exist THEN
        UPDATE DKA_RCV_HEADERS_TMP SET FLAG = 'E' WHERE CURRENT OF cur_recept;
      
        UPDATE DKA_RCV_TRANSACTIONS_TMP drt
           SET FLAG = 'E'
         WHERE drt.RECEIPT_NUM = rec_cur_recept.RECEIPT_NUM
           AND NVL(drt.SOCIETE,'1') = NVL(rec_cur_recept.SOCIETE,'1') -- OBE artf2184213
           AND NVL(drt.REGION,'1') = NVL(rec_cur_recept.REGION,'1')   -- OBE artf2184213
           ;
      
      -- RBK ajout exception
      WHEN others THEN
        fnd_file.put_line(fnd_file.log,
                          'VALIDATION RECEPTION IMPOSSIBLE||' || rec_cur_recept.RECEIPT_NUM || '| erreur: ' || sqlerrm);
      
        ROLLBACK;
      
        UPDATE DKA_RCV_HEADERS_TMP SET FLAG = 'E' WHERE CURRENT OF cur_recept;
      
        UPDATE DKA_RCV_TRANSACTIONS_TMP drt
           SET FLAG = 'E'
         WHERE drt.RECEIPT_NUM = rec_cur_recept.RECEIPT_NUM
           AND NVL(drt.SOCIETE,'1') = NVL(rec_cur_recept.SOCIETE,'1') -- artf2184213
           AND NVL(drt.REGION,'1') = NVL(rec_cur_recept.REGION,'1')   -- artf2184213
           ;
      
    END;
  END LOOP;

  Fnd_File.put_line(Fnd_File.LOG, TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin validate_data');

  COMMIT; -- RBK

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
 * PROCEDURE NAME : import_data
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
PROCEDURE import_data(p_Errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS
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

  -- Curseur des receptions
  CURSOR cur_recep_imp IS
    SELECT *
      FROM DKA_RCV_HEADERS_TMP
     WHERE 1 = 1
       AND FLAG = 'S'
       AND load_request_id = DECODE(g_loader_request_id, -1, load_request_id, g_loader_request_id)
       FOR UPDATE OF FLAG;

  -- Cursor des transactions
  CURSOR cur_trans_imp(p_receipt_num VARCHAR2, p_org_id NUMBER -- RBK
  ) IS
    SELECT *
      FROM DKA_RCV_TRANSACTIONS_TMP
     WHERE receipt_num = p_receipt_num
       AND ORG_ID = p_org_id -- RBK
       AND transaction_TYPE = 'RECEIVE'
    --ORDER BY (transaction_id) DESC        -- RBK comment
       FOR UPDATE OF FLAG;

  -- Cursor des transactions
/*  CURSOR cur_trans_imp_2(p_receipt_num VARCHAR2, p_org_id NUMBER -- RBK
  ) IS
    SELECT *
      FROM DKA_RCV_TRANSACTIONS_TMP
     WHERE receipt_num = p_receipt_num
       AND ORG_ID = p_org_id -- RBK    
       AND transaction_TYPE != 'RECEIVE'
    --ORDER BY (transaction_id) DESC          -- RBK comment
       FOR UPDATE OF FLAG;*/
BEGIN

  -- GROUP_ID
  SELECT rcv_interface_groups_s.nextval 
    INTO g_group_id 
    FROM dual;

  -- Boucle sur les receptions
  FOR rec_cur_recep_imp IN cur_recep_imp LOOP
  
    BEGIN
      
      -- Controle qui permet de decouper par lot
      IF v_cpt = g_nb_entetes_group THEN
         
        v_cpt := 0;
      
        -- GROUP_ID
        SELECT rcv_interface_groups_s.nextval 
          INTO g_group_id 
          FROM dual;

      END IF;
    
      -- ID de la reception
      SELECT rcv_headers_interface_s.nextval 
        INTO v_rcv_header_id 
        FROM DUAL;
    
      -- Inserer la reception dans Open Interface
      INSERT INTO rcv_headers_interface
        (HEADER_INTERFACE_ID,
         GROUP_ID,
         PROCESSING_STATUS_CODE,
         RECEIPT_SOURCE_CODE,
         TRANSACTION_TYPE,
         LAST_UPDATE_DATE,
         LAST_UPDATED_BY,
         CREATION_DATE,
         CREATED_BY,
         SHIPMENT_NUM,
         RECEIPT_NUM,
         VENDOR_NUM,
         VENDOR_SITE_CODE,
         --VENDOR_SITE_ID,
         SHIP_TO_ORGANIZATION_ID,
         PACKING_SLIP,
         SHIPPED_DATE,
         EXPECTED_RECEIPT_DATE,
         COMMENTS,
         EMPLOYEE_NAME,
         ORG_ID,
         validation_flag)
      VALUES
        (v_rcv_header_id, --HEADER_INTERFACE_ID,
         g_group_id, --v_rcv_header_id, -- RBK  g_group_id,                                 --GROUP_ID,
         v_processing_status_code, --PROCESSING_STATUS_CODE,
         v_receipt_source_code, --RECEIPT_SOURCE_CODE,
         v_transaction_type, --TRANSACTION_TYPE,
         SYSDATE, --LAST_UPDATE_DATE ,
         g_user_id, --LAST_UPDATED_BY,
         SYSDATE, --CREATION_DATE,
         g_user_id, --CREATED_BY,
         rec_cur_recep_imp.SHIPMENT_NUM, --SHIPMENT_NUM,
         'REP'||rec_cur_recep_imp.RECEIPT_NUM, --RECEIPT_NUM, -- OBE artf2184213
         rec_cur_recep_imp.VENDOR_NUM, --VENDOR_NUM,
         rec_cur_recep_imp.VENDOR_SITE_CODE,
         --v_code_site_four,                           --VENDOR_SITE_CODE,    SUBSTR(rec_cur_recep_imp.VENDOR_SITE_CODE,5)   a ajouter apres
         rec_cur_recep_imp.org_id, --SHIP_TO_ORGANIZATION_ID
         rec_cur_recep_imp.BORDEREAU_NUM, --PACKING_SLIP,
         rec_cur_recep_imp.EXPEDITION_DATE, --SHIPPED_DATE,
         rec_cur_recep_imp.EXPECTED_RECEIPT_DATE, --EXPECTED_RECEIPT_DATE,
         rec_cur_recep_imp.COMMENTS, --COMMENTS,
         rec_cur_recep_imp.EMPLOYEE_NAME, --EMPLOYEE_NAME,
         rec_cur_recep_imp.org_id, --ORG_ID
         'Y' --VALIDATION_FLAG
         );
    
      g_summary.inserted_header_rows := g_summary.inserted_header_rows + 1;
    
      -- Transactions  RECEIVE
      FOR rec_cur_trans_imp IN cur_trans_imp(rec_cur_recep_imp.RECEIPT_NUM,
                                             rec_cur_recep_imp.ORG_ID -- RBK
                                             ) LOOP
      
        BEGIN
          -- ID transaction
          SELECT RCV_TRANSACTIONS_INTERFACE_S.NEXTVAL INTO v_transaction_id FROM DUAL;
        
          -- Inserer les transactions 
          INSERT INTO rcv_transactions_interface
            (INTERFACE_TRANSACTION_ID,
             GROUP_ID,
             lPN_GROUP_ID, -- RBK
             LAST_UPDATE_DATE,
             LAST_UPDATED_BY,
             CREATION_DATE,
             CREATED_BY,
             TRANSACTION_TYPE,
             TRANSACTION_DATE,
             PROCESSING_STATUS_CODE,
             PROCESSING_MODE_CODE,
             TRANSACTION_STATUS_CODE,
             --CATEGORY_ID,    -- OBE
             QUANTITY,
             UNIT_OF_MEASURE,
             ITEM_DESCRIPTION,
             UOM_CODE,
             EMPLOYEE_ID,
             PRIMARY_QUANTITY,
             PRIMARY_UNIT_OF_MEASURE,
             RECEIPT_SOURCE_CODE,
             TO_ORGANIZATION_ID,
             PO_UNIT_PRICE,
             CURRENCY_CODE,
             CURRENCY_CONVERSION_RATE,
             CURRENCY_CONVERSION_DATE,
             INSPECTION_STATUS_CODE,
             DESTINATION_TYPE_CODE,
             VENDOR_ITEM_NUM,
             COMMENTS,
             DESTINATION_CONTEXT,
             HEADER_INTERFACE_ID,
             DOCUMENT_NUM,
             DOCUMENT_LINE_NUM,
             DOCUMENT_SHIPMENT_LINE_NUM,
             DOCUMENT_DISTRIBUTION_NUM,
             SHIP_TO_LOCATION_CODE,
             --LOCATION_CODE, --RBE artf2125858
             LOCATION_ID,     --RBE artf2125858
             VENDOR_NUM,
             VENDOR_SITE_CODE,
             --VENDOR_SITE_ID,
             DELIVER_TO_PERSON_NAME,
             --DELIVER_TO_LOCATION_CODE,  -- RBE artf2125858
             Deliver_To_Location_Id,      -- RBE artf2125858
             -- QUANTITY_SHIPPED,
             PARENT_INTERFACE_TXN_ID,
             ORG_ID,
             AUTO_TRANSACT_CODE,
             SOURCE_DOCUMENT_CODE,
             VALIDATION_FLAG,
             PO_HEADER_ID, -- RBK 
             PO_LINE_ID, -- RBK 
             PO_LINE_LOCATION_ID, -- RBK
             PO_DISTRIBUTION_ID -- RBE artf2125858
             )
          VALUES
            (v_transaction_id, --INTERFACE_TRANSACTION_ID,
             g_group_id, --v_rcv_header_id, -- RBK  g_group_id ,                                        --GROUP_ID,
             v_rcv_header_id, -- RBK           -- LPN_GROUP_ID           -- Ajout afin de commiter reception par reception
             SYSDATE, --LAST_UPDATE_DATE,
             g_user_id, --LAST_UPDATED_BY,
             SYSDATE, --CREATION_DATE,
             g_user_id, --CREATED_BY,
             'RECEIVE', --rec_cur_trans_imp.TRANSACTION_TYPE, --TRANSACTION_TYPE,
             --TO_DATE('2016/12/31','YYYY/MM/DD'),                 --TRANSACTION_DATE,
             --rec_cur_trans_imp.TRANSACTION_DATE,                 --TRANSACTION_DATE,
             g_gl_date, -- OBE
             V_PROCESSING_STATUS_CODE, --PROCESSING_STATUS_CODE,
             V_PROCESSING_MODE_CODE, --PROCESSING_MODE_CODE,
             'PENDING', --TRANSACTION_STATUS_CODE
             --0,                                                  --CATEGORY_ID,  -- OBE
             rec_cur_trans_imp.QUANTITY, --QUANTITY,
             rec_cur_trans_imp.UNIT_OF_MESURE, --UNIT_OF_MEASURE,
             rec_cur_trans_imp.ITEM_DESCRIPTION, --ITEM_DESCRIPTION,
             rec_cur_trans_imp.UOM_CODE, --UOM_CODE,
             rec_cur_trans_imp.person_id, --EMPLOYEE_ID,
             rec_cur_trans_imp.PRIMARY_QTY, --PRIMARY_QUANTITY,
             rec_cur_trans_imp.PRIMARY_UOM, --PRIMARY_UNIT_OF_MEASURE,
             V_RECEIPT_SOURCE_CODE, --RECEIPT_SOURCE_CODE,
             rec_cur_trans_imp.org_id, --TO_ORGANIZATION_ID,
             rec_cur_trans_imp.PO_UNIT_PRICE, --PO_UNIT_PRICE,
             rec_cur_trans_imp.CURRENCY_CODE, --CURRENCY_CODE,
             rec_cur_trans_imp.CURR_CONV_RATE, --CURRENCY_CONVERSION_RATE,
             rec_cur_trans_imp.CURR_CONV_DATE, --CURRENCY_CONVERSION_DATE,
             rec_cur_trans_imp.INSPECTION, --INSPECTION_STATUS_CODE,
             rec_cur_trans_imp.DEST_TYPE_CODE, --DESTINATION_TYPE_CODE,
             rec_cur_trans_imp.VENDOR_ITEM_NUM, --VENDOR_ITEM_NUM,
             rec_cur_trans_imp.COMMENTS, --COMMENTS,
             rec_cur_trans_imp.DESTINATION_CONTEXT, --DESTINATION_CONTEXT,
             v_rcv_header_id, --HEADER_INTERFACE_ID,
             rec_cur_trans_imp.PO_NUM, --DOCUMENT_NUM,
             rec_cur_trans_imp.PO_LINE_NUM, --DOCUMENT_LINE_NUM,
             rec_cur_trans_imp.PO_SHIP_LINE_NUM, -- RBK     null, --rec_cur_trans_imp.PO_SHIP_LINE_NUM,         --DOCUMENT_SHIPMENT_LINE_NUM,
             null, --rec_cur_trans_imp.PO_DIST_NUM,              --DOCUMENT_DISTRIBUTION_NUM,        
             rec_cur_trans_imp.SHIP_TO_LOCATION, --SHIP_TO_LOCATION_CODE,
             --rec_cur_trans_imp.LOCATION_CODE, --LOCATION_CODE, --RBE artf2125858
             rec_cur_trans_imp.DELIVER_TO_LOCATION_ID, --RBE artf2125858
             rec_cur_trans_imp.VENDOR_NUM, --VENDOR_NUM,
             rec_cur_trans_imp.VENDOR_SITE_CODE,
             --SUBSTR(rec_cur_trans_imp.code_site_four,5),       --VENDOR_SITE_ID,
             rec_cur_trans_imp.DELIVER_TO_PERSON, --DELIVER_TO_PERSON_NAME,
             --rec_cur_trans_imp.DELIVER_TO_LOCATION, --DELIVER_TO_LOCATION_CODE, -- RBE artf2125858
             rec_cur_trans_imp.DELIVER_TO_LOCATION_ID, --DELIVER_TO_LOCATION_CODE_ID, -- RBE artf2125858
             -- rec_cur_trans_imp.QUANTITY_SHIPPED,               --QUANTITY_SHIPPED,
             rec_cur_trans_imp.INTERFACE_TRANSACTION_ID, --v_receive_trans_id,
             rec_cur_trans_imp.org_id, --ORG_ID
             'DELIVER', --rec_cur_trans_imp.transaction_type, --TRANSACTION_TYPE
             'PO', --SOURCE_DOCUMENT_CODE
             'Y', --VALIDATION_FLAG
             rec_cur_trans_imp.PO_HEADER_ID, --PO_HEADER_ID       -- RBK 
             rec_cur_trans_imp.PO_LINE_ID, --PO_LINE_ID          -- RBK 
             rec_cur_trans_imp.PO_LINE_LOCATION_ID, --PO_LINE_LOCATION_ID     -- RBK  
             rec_cur_trans_imp.PO_DISTRIBUTION_ID --PO_DISTRIBUTION_ID      -- RBE artf2125858          
             );
        
          ---- INTERFACE_TRANSACTION_ID                   -- RBK COMMENT
          --IF rec_cur_trans_imp.transaction_type = 'RECEIVE' THEN
          --    UPDATE DKA_RCV_TRANSACTIONS_TMP
          --    SET INTERFACE_TRANSACTION_ID = v_transaction_id
          --    WHERE parent_transaction_id = rec_cur_trans_imp.transaction_id
          --  ;
          --END IF;
        
/*          UPDATE DKA_RCV_TRANSACTIONS_TMP
             SET PARENT_TRANSACTION_ID = v_transaction_id
           WHERE TRANSACTION_TYPE = 'DELIVER'
             AND RECEIPT_NUM = rec_cur_recep_imp.RECEIPT_NUM
             AND ORG_ID = rec_cur_recep_imp.ORG_ID
             AND PO_NUM = rec_cur_trans_imp.PO_NUM
             AND PO_LINE_NUM = rec_cur_trans_imp.PO_LINE_NUM
             AND PO_SHIP_LINE_NUM = rec_cur_trans_imp.PO_SHIP_LINE_NUM;*/
        
          UPDATE DKA_RCV_TRANSACTIONS_TMP
             SET FLAG = 'T', INTERFACE_TRANSACTION_ID = v_transaction_id -- RBK 
           WHERE CURRENT OF cur_trans_imp;
        
          g_summary.inserted_transaction_rows := g_summary.inserted_transaction_rows + 1;
        
        EXCEPTION
          WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log,
                              'Insertion de la ligne ' || rec_cur_trans_imp.TRANSACTION_TYPE || ' impossible||' ||
                              rec_cur_trans_imp.receipt_num || '| erreur: ' || sqlerrm);
        END;
      END LOOP;
    
      -- Transactions deliver
/*
      FOR rec_cur_trans_imp_2 IN cur_trans_imp_2(rec_cur_recep_imp.RECEIPT_NUM,
                                                 rec_cur_recep_imp.ORG_ID -- RBK
                                                 ) LOOP
      
        BEGIN
          -- ID transaction
          SELECT RCV_TRANSACTIONS_INTERFACE_S.NEXTVAL INTO v_transaction_id FROM DUAL;
        
          -- Inserer les transactions 
          INSERT INTO rcv_transactions_interface
            (INTERFACE_TRANSACTION_ID,
             GROUP_ID,
             lPN_GROUP_ID, -- RBK
             LAST_UPDATE_DATE,
             LAST_UPDATED_BY,
             CREATION_DATE,
             CREATED_BY,
             TRANSACTION_TYPE,
             TRANSACTION_DATE,
             PROCESSING_STATUS_CODE,
             PROCESSING_MODE_CODE,
             TRANSACTION_STATUS_CODE,
             --CATEGORY_ID,  -- OBE
             QUANTITY,
             UNIT_OF_MEASURE,
             ITEM_DESCRIPTION,
             UOM_CODE,
             EMPLOYEE_ID,
             PRIMARY_QUANTITY,
             PRIMARY_UNIT_OF_MEASURE,
             RECEIPT_SOURCE_CODE,
             TO_ORGANIZATION_ID,
             PO_UNIT_PRICE,
             CURRENCY_CODE,
             CURRENCY_CONVERSION_RATE,
             CURRENCY_CONVERSION_DATE,
             INSPECTION_STATUS_CODE,
             DESTINATION_TYPE_CODE,
             VENDOR_ITEM_NUM,
             COMMENTS,
             DESTINATION_CONTEXT,
             HEADER_INTERFACE_ID,
             DOCUMENT_NUM,
             DOCUMENT_LINE_NUM,
             DOCUMENT_SHIPMENT_LINE_NUM,
             DOCUMENT_DISTRIBUTION_NUM,
             SHIP_TO_LOCATION_CODE,
             LOCATION_CODE,
             VENDOR_NUM,
             VENDOR_SITE_CODE,
             --VENDOR_SITE_ID,
             DELIVER_TO_PERSON_NAME,
             DELIVER_TO_LOCATION_CODE,
             -- QUANTITY_SHIPPED,
             PARENT_INTERFACE_TXN_ID,
             ORG_ID,
             AUTO_TRANSACT_CODE,
             SOURCE_DOCUMENT_CODE,
             VALIDATION_FLAG,
             PO_HEADER_ID, -- RBK 
             PO_LINE_ID, -- RBK 
             PO_LINE_LOCATION_ID, -- RBK    
             PO_DISTRIBUTION_ID -- RBE artf2125858               
             )
          VALUES
            (v_transaction_id, --INTERFACE_TRANSACTION_ID,
             g_group_id, --v_rcv_header_id, -- RBK  g_group_id ,                                        --GROUP_ID,
             v_rcv_header_id, -- RBK           -- LPN_GROUP_ID           -- Ajout afin de commiter reception par reception
             SYSDATE, --LAST_UPDATE_DATE,
             g_user_id, --LAST_UPDATED_BY,
             SYSDATE, --CREATION_DATE,
             g_user_id, --CREATED_BY,
             rec_cur_trans_imp_2.TRANSACTION_TYPE, --TRANSACTION_TYPE,
             --TO_DATE('2016/12/31','YYYY/MM/DD'),                 --TRANSACTION_DATE,
             --rec_cur_trans_imp_2.TRANSACTION_DATE,                 --TRANSACTION_DATE,
             g_gl_date, -- OBE
             V_PROCESSING_STATUS_CODE, --PROCESSING_STATUS_CODE,
             V_PROCESSING_MODE_CODE, --PROCESSING_MODE_CODE,
             'PENDING', --TRANSACTION_STATUS_CODE
             --0,                                                    --CATEGORY_ID, -- OBE
             rec_cur_trans_imp_2.QUANTITY, --QUANTITY,
             rec_cur_trans_imp_2.UNIT_OF_MESURE, --UNIT_OF_MEASURE,
             rec_cur_trans_imp_2.ITEM_DESCRIPTION, --ITEM_DESCRIPTION,
             rec_cur_trans_imp_2.UOM_CODE, --UOM_CODE,
             rec_cur_trans_imp_2.person_id, --EMPLOYEE_ID,
             rec_cur_trans_imp_2.PRIMARY_QTY, --PRIMARY_QUANTITY,
             rec_cur_trans_imp_2.PRIMARY_UOM, --PRIMARY_UNIT_OF_MEASURE,
             V_RECEIPT_SOURCE_CODE, --RECEIPT_SOURCE_CODE,
             rec_cur_trans_imp_2.org_id, --TO_ORGANIZATION_ID,
             rec_cur_trans_imp_2.PO_UNIT_PRICE, --PO_UNIT_PRICE,
             rec_cur_trans_imp_2.CURRENCY_CODE, --CURRENCY_CODE,
             rec_cur_trans_imp_2.CURR_CONV_RATE, --CURRENCY_CONVERSION_RATE,
             rec_cur_trans_imp_2.CURR_CONV_DATE, --CURRENCY_CONVERSION_DATE,
             rec_cur_trans_imp_2.INSPECTION, --INSPECTION_STATUS_CODE,
             rec_cur_trans_imp_2.DEST_TYPE_CODE, --DESTINATION_TYPE_CODE,
             rec_cur_trans_imp_2.VENDOR_ITEM_NUM, --VENDOR_ITEM_NUM,
             rec_cur_trans_imp_2.COMMENTS, --COMMENTS,
             rec_cur_trans_imp_2.DESTINATION_CONTEXT, --DESTINATION_CONTEXT,
             v_rcv_header_id, --HEADER_INTERFACE_ID,
             rec_cur_trans_imp_2.PO_NUM, --DOCUMENT_NUM,
             rec_cur_trans_imp_2.PO_LINE_NUM, --DOCUMENT_LINE_NUM,
             rec_cur_trans_imp_2.PO_SHIP_LINE_NUM, -- RBK    null, --rec_cur_trans_imp_2.PO_SHIP_LINE_NUM,         --DOCUMENT_SHIPMENT_LINE_NUM,
             null, --rec_cur_trans_imp_2.PO_DIST_NUM,              --DOCUMENT_DISTRIBUTION_NUM,
             rec_cur_trans_imp_2.SHIP_TO_LOCATION, --SHIP_TO_LOCATION_CODE,
             rec_cur_trans_imp_2.LOCATION_CODE, --LOCATION_CODE,
             rec_cur_trans_imp_2.VENDOR_NUM, --VENDOR_NUM,
             rec_cur_trans_imp_2.VENDOR_SITE_CODE,
             --SUBSTR(rec_cur_trans_imp_2.code_site_four,5),       --VENDOR_SITE_ID,
             rec_cur_trans_imp_2.DELIVER_TO_PERSON, --DELIVER_TO_PERSON_NAME,
             rec_cur_trans_imp_2.DELIVER_TO_LOCATION, --DELIVER_TO_LOCATION_CODE,
             -- rec_cur_trans_imp_2.QUANTITY_SHIPPED,               --QUANTITY_SHIPPED,
             rec_cur_trans_imp_2.parent_transaction_id, --RBK  rec_cur_trans_imp_2.INTERFACE_TRANSACTION_ID         --v_receive_trans_id,
             rec_cur_trans_imp_2.org_id, --ORG_ID
             rec_cur_trans_imp_2.transaction_type, --TRANSACTION_TYPE
             'PO', --SOURCE_DOCUMENT_CODE
             'Y', --VALIDATION_FLAG
             rec_cur_trans_imp_2.PO_HEADER_ID, --PO_HEADER_ID         -- RBK 
             rec_cur_trans_imp_2.PO_LINE_ID, --PO_LINE_ID          -- RBK 
             rec_cur_trans_imp_2.PO_LINE_LOCATION_ID, --PO_LINE_LOCATION_ID     -- RBK    
             rec_cur_trans_imp_2.PO_DISTRIBUTION_ID --PO_DISTRIBUTION_ID      -- RBE artf2125858
             );
        
          UPDATE DKA_RCV_TRANSACTIONS_TMP
             SET FLAG = 'T', INTERFACE_TRANSACTION_ID = v_transaction_id -- RBK ajout
           WHERE CURRENT OF cur_trans_imp_2;
        
          g_summary.inserted_transaction_rows := g_summary.inserted_transaction_rows + 1;
        
        EXCEPTION
          WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log,
                              'Insertion de la ligne ' || rec_cur_trans_imp_2.TRANSACTION_TYPE || ' impossible||' ||
                              rec_cur_trans_imp_2.receipt_num || '| erreur: ' || sqlerrm);
        END;
      END LOOP;
*/  

      UPDATE DKA_RCV_HEADERS_TMP SET FLAG = 'T' WHERE CURRENT OF cur_recep_imp;
      
      v_cpt := v_cpt + 1;
      
    EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.log,
                          'Insertion de la reception impossible ||' || rec_cur_recep_imp.RECEIPT_NUM || '| erreur: ' ||
                          sqlerrm);
    END;
    
  END LOOP;

  Fnd_File.put_line(Fnd_File.LOG, TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin import_data');
  COMMIT; --  RBK

EXCEPTION
  WHEN OTHERS THEN
    p_retcode := 2;
    p_errbuf  := 'import_data : ' || SQLERRM;
    Fnd_File.put_line(Fnd_File.LOG, p_errbuf);
    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Fin de la procédure import_data : EXCEPTION OTHERS ');
    ROLLBACK; -- RBK

END import_data;

/*
 *************************************************************************
 * PROCEDURE NAME : Launch_OI
 * 
 * DESCRIPTION
 *  Procédure de lancement du Programme maître de l'interface receptions
 *
 * PARAMETERS
 * ==========
 * NAME               DESCRIPTION
.* -----------------  ------------------------------------------------------
 * p_ou              Unité opérationnelle
 * p_errbuf          Retour de message éventuel
 * p_retcode         Statut du traitement en sortie
 * 
 ************************************************************************
 */
 
  PROCEDURE Launch_OI(p_errbuf            OUT VARCHAR2,
                      p_retcode           OUT NUMBER
                          ) 
  IS
    v_phase                  VARCHAR2 (100);
    v_status                 VARCHAR2 (100);
    v_dev_phase              VARCHAR2 (100);
    v_dev_status             VARCHAR2 (100);
    v_message                VARCHAR2 (100);
    b_result                 BOOLEAN;
    V_Batch_Source_Id        NUMBER;
    
    vn_tempo                 NUMBER := 20;   
    vn_request_id            Fnd_Concurrent_Requests.Request_Id%Type;
    TYPE t_request_id        IS TABLE OF PLS_INTEGER;
    va_request_id            t_request_id := t_request_id();
    vn_nb_traitements        PLS_INTEGER := 0;

  BEGIN
  
    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début Launch_OI');    
    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 
                                     'Lancement de l''interface des receptions : ');

    fnd_file.put_line(fnd_file.OUTPUT, CHR(10));
    fnd_file.put_line(fnd_file.OUTPUT, 'LANCEMENT DE L''INTERFACE DES RECEPTIONS :');
    fnd_file.put_line(fnd_file.OUTPUT, '----------------------');
          
    -- Calcul des statistiques sur les tables standards
    fnd_stats.gather_table_stats('PO', 'RCV_HEADERS_INTERFACE', dbms_stats.auto_sample_size);
    fnd_stats.gather_table_stats('PO', 'RCV_TRANSACTIONS_INTERFACE', dbms_stats.auto_sample_size);
          
    ---------------------------------------------------
    -- Lancement du traitement de l'interface des receptions --
    ---------------------------------------------------    
          
    FOR rec_group_id IN (SELECT DISTINCT group_id 
                           FROM rcv_headers_interface
                          WHERE processing_status_code = 'PENDING'
                       ORDER BY group_id) LOOP
           
      -- Positionnement des options d'impression
      b_result := fnd_request.set_print_options(printer => gv_printer,
                                                copies => g_number_of_copies); 
                                                      
      -- Lancement du traitement Programme maître de l'interface receptions
      vn_request_id := fnd_request.submit_request( application => 'PO',
                                                   program     => 'RVCTP',
                                                   description => NULL,
                                                   start_time  => NULL,
                                                   sub_request => FALSE,
                                                   Argument1   => 'BATCH',
                                                   Argument2   => rec_group_id.group_id 		-- RBK  case g_summary.reprise_flag when 'Y' then null else g_group_id end
                          );
            
      IF vn_request_id = 0 THEN
              
        p_retcode    := 2;
        fnd_file.put_line(fnd_file.LOG, 'ERREUR : Le traitement de l''interface des receptions a échoué' || CHR(10) ||
                                        'PROGRAMME  : RAXMTR');
        Fnd_File.put_line (Fnd_File.OUTPUT, '====> ERREUR : Le traitement de l''interface des receptions a échoué');
                  
      ELSE
              
        COMMIT;
        Fnd_File.put_line(Fnd_File.LOG, '=> REQUEST ID= ' || vn_request_id);            
        Fnd_File.put_line(Fnd_File.OUTPUT, '. Numéro du traitement de l''interface des receptions : ' || vn_request_id);  
                    
        --Stockage des numéros de traitements
        va_request_id.extend;
        vn_nb_traitements := vn_nb_traitements + 1;
        va_request_id(vn_nb_traitements) := vn_request_id;
                  
      END IF;
              
  /*                                                 
      IF g_int_request_id = 0
      THEN
          p_retcode    := 2;
          fnd_file.put_line(fnd_file.LOG, 'ERREUR : Le traitement de l''interface des receptions a échoué' || CHR(10) ||
                                          'PROGRAMME  : RAXMTR' --|| CHR(10) ||
                                          --'UNITE OPERATIONNELLE : ' || p_ou || CHR(10)
                                          );
          Fnd_File.put_line (Fnd_File.OUTPUT, '====> ERREUR : Le traitement de l''interface des receptions a échoué');
      ELSE
          COMMIT;
          Fnd_File.put_line(Fnd_File.LOG, '=> REQUEST ID= ' || g_int_request_id);            
          Fnd_File.put_line(Fnd_File.OUTPUT, '. Numéro du traitement de l''interface des receptions : ' || g_int_request_id);  
     
          -- Attente de la fin du traitement
          IF NOT (Fnd_Concurrent.wait_for_request (g_int_request_id, g_tempo, 0, v_phase, v_status, v_dev_phase, v_dev_status, v_message))
          THEN                        
              p_errbuf  := v_Message;
              Fnd_file.put_line(Fnd_file.log, 'ERREUR : Attente de la fin du programme de l''interface des receptions : Fin du traitement' || CHR(10) ||
                                              'MESSAGE : ' || v_Message || CHR(10) );  
          END IF;
                             
          IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL') 
          THEN          
              Fnd_File.put_line(Fnd_File.LOG, 'COMPLETION= ' || v_dev_phase || '/' || v_dev_status);
              Fnd_File.put_line(Fnd_File.OUTPUT, '. Statut de fin : ' || v_phase || '/' || v_status);

          ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING')
          THEN
              Fnd_File.put_line (Fnd_File.LOG, 'Fin du traitement de l''interface des receptions en warning '|| g_int_request_id);
              p_retcode    := 1;

          ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL')  
          THEN
              p_retcode := 2;
              p_errbuf  := 'ERREUR : Fin anormale du traitement de l''interface des receptions : '||v_Message;
      
              fnd_file.put_line(fnd_file.LOG, 'ERREUR : Fin anormale du traitement de l''interface des receptions '|| g_int_request_id  || CHR(10) ||
                                              'Phase/Statut : ' || v_dev_phase || '/' || v_dev_status || CHR(10) ||
                                              'MESSAGE : ' || v_message || CHR(10) );
              Fnd_File.put_line (Fnd_File.OUTPUT, '===> ERREUR : Fin anormale du traitement de l''interface des receptions '||g_int_request_id);
          END IF;
                
      END IF;
  */          
    
    END LOOP;
        
    -- Attente de la fin du traitement
    FOR i IN 1..vn_nb_traitements LOOP
      IF NOT (Fnd_Concurrent.wait_for_request (va_request_id(i), vn_tempo, 0, v_phase, v_status, v_dev_phase, v_dev_status, v_message))
      THEN                        
          p_errbuf  := v_Message;
          Fnd_file.put_line(Fnd_file.log, 'request_id = '||va_request_id(i)||' ERREUR : Attente de la fin du programme de l''interface des receptions : Fin du traitement' || CHR(10) ||
                                          'MESSAGE : ' || v_Message || CHR(10) );  
      END IF;
                       
      IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL') 
      THEN          
          Fnd_File.put_line(Fnd_File.LOG, 'request_id = '||va_request_id(i)||'COMPLETION= ' || v_dev_phase || '/' || v_dev_status);
          Fnd_File.put_line(Fnd_File.OUTPUT, 'request_id = '||va_request_id(i)||'. Statut de fin : ' || v_phase || '/' || v_status);

      ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING')
      THEN
          Fnd_File.put_line (Fnd_File.LOG, 'Fin du traitement de l''interface des receptions en warning '|| va_request_id(i));
          p_retcode    := 1;

      ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL')  
      THEN
          p_retcode := 1;--2;
          p_errbuf  := 'ERREUR : Fin anormale du traitement de l''interface des receptions : '||v_Message;

          fnd_file.put_line(fnd_file.LOG, 'ERREUR : Fin anormale du traitement de l''interface des receptions '|| va_request_id(i)  || CHR(10) ||
                                          'Phase/Statut : ' || v_dev_phase || '/' || v_dev_status || CHR(10) ||
                                          'MESSAGE : ' || v_message || CHR(10) );
          Fnd_File.put_line (Fnd_File.OUTPUT, '===> ERREUR : Fin anormale du traitement de l''interface des receptions '||va_request_id(i));
      END IF;
    END LOOP;
        
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin Launch_OI');    
  
  EXCEPTION
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'Launch_OI : ' ||SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure Launch_OI : EXCEPTION OTHERS ');
  END Launch_OI;  
  
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

        fnd_file.put_line(fnd_file.OUTPUT, CHR(10));
        fnd_file.put_line(fnd_file.OUTPUT, 'CHARGEMENT DU FICHIER :');
        fnd_file.put_line(fnd_file.OUTPUT, '----------------------');
        ------------------------------------------------------
        -- Lancement du traitement de chargement du fichier --
        ------------------------------------------------------
        -- Positionnement des options d'impression
        b_result := fnd_request.set_print_options(printer => gv_printer,
                                                  copies => g_number_of_copies);
        -- Lancement du traitement
        g_loader_request_id         := Fnd_Request.submit_request (
                                                                   'DKA'                            -- APPL
                                                                  ,'DKA_LOADER_REPRECPOIMP'         -- PROG
                                                                  ,NULL                             -- PROGRAM_NAME
                                                                  ,NULL                             -- START
                                                                  ,FALSE                            -- SUB_REQUEST
                                                                  );

        IF g_loader_request_id = 0
        THEN
            p_retcode    := 2;
            fnd_file.put_line(fnd_file.LOG, 'ERREUR : Le traitement de chargement du fichier a échoué' || CHR(10) ||
                                            'PROGRAMME  : DKA_LOADER_REPRECPOIMP'
                                            );
            Fnd_File.put_line (Fnd_File.OUTPUT, '====> ERREUR : Le traitement de chargement du fichier a échoué');
        ELSE
            COMMIT;
            Fnd_File.put_line(Fnd_File.LOG, '=> LOAD REQUEST ID= ' || g_loader_request_id);
            Fnd_File.put_line(Fnd_File.OUTPUT, '. Numéro du traitement de chargement du fichier : ' || g_loader_request_id);

            -- Attente de la fin du traitement
            IF NOT (Fnd_Concurrent.wait_for_request (g_loader_request_id, g_tempo, 0, v_phase, v_status, v_dev_phase, v_dev_status, v_message))
            THEN
                p_Errbuf  := v_Message;
                Fnd_file.put_line(Fnd_file.log, 'ERREUR : Attente de la fin du programme de chargement du fichier dépassée : Fin du traitement' || CHR(10) ||
                                                'MESSAGE : ' || v_Message || CHR(10) );
            END IF;

            IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL')
            THEN
                Fnd_File.put_line(Fnd_File.LOG, 'COMPLETION= ' || v_dev_phase || '/' || v_dev_status);
                Fnd_File.put_line(Fnd_File.OUTPUT, '. Statut de fin : ' || v_phase || '/' || v_status);
                
                SELECT count(1)
                INTO g_summary.loaded_header_rows
                FROM DKA_RCV_HEADERS_TMP
                WHERE  LOAD_REQUEST_ID = g_loader_request_id 
                ;
  
                SELECT count(1)
                INTO g_summary.loaded_transaction_rows
                FROM DKA_RCV_TRANSACTIONS_TMP
                WHERE  LOAD_REQUEST_ID = g_loader_request_id
                ;
                
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
                Fnd_File.put_line (Fnd_File.OUTPUT, '===> ERREUR : Fin anormale du traitement de chargement '||g_loader_request_id);
            END IF;

        END IF;

        -- Calcul des statistiques sur les tables specifiques
        fnd_stats.gather_table_stats('DKA', 'DKA_RCV_HEADERS_TMP', dbms_stats.auto_sample_size);
        fnd_stats.gather_table_stats('DKA', 'DKA_RCV_TRANSACTIONS_TMP', dbms_stats.auto_sample_size);

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
  PROCEDURE Report_Bilan(p_Errbuf            OUT VARCHAR2,
                         p_retcode           OUT NUMBER
                         ) 
  IS
 
  BEGIN
  
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début Report_Bilan');

        --------------------    
        -- Initialisation --
        --------------------          
  
        p_Errbuf  := NULL;
        p_retcode := 0;
 

        SELECT count(1)
        INTO g_summary.rejected_header_rows
        FROM DKA_RCV_HEADERS_TMP
        WHERE flag = 'E'
        ;

        SELECT count(1)
        INTO g_summary.rejected_transaction_rows
        FROM DKA_RCV_TRANSACTIONS_TMP 
        WHERE flag = 'E' 
        ;
        
        fnd_file.put_line(fnd_file.OUTPUT,CHR(10));
        fnd_file.put_line(fnd_file.OUTPUT,'BILAN :');
        fnd_file.put_line(fnd_file.OUTPUT,'-------');
        
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre des receptions chargées dans la table spécifique                     : '||TO_CHAR(g_summary.loaded_header_rows));
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre des transactions chargées dans la table spécifique                   : ' ||TO_CHAR(g_summary.loaded_transaction_rows)); 


        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre des receptions en rejet dans la table spécifique                     : ' || TO_CHAR(g_summary.rejected_header_rows));
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre des transactions en rejet  dans la table spécifique                  : ' || TO_CHAR(g_summary.rejected_transaction_rows));

        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''enregistrements inserés dans la table RCV_HEADERS_INTERFACE        : ' || TO_CHAR(g_summary.inserted_header_rows));
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''enregistrements inserés dans la table RCV_TRANSACTIONS_INTERFACE   : ' || TO_CHAR(g_summary.inserted_transaction_rows)); 
 
        fnd_file.put_line(fnd_file.OUTPUT,CHR(10));
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin Report_Bilan');  

  
  EXCEPTION
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'REPORT_BILAN : ' ||SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure Report_Bilan : EXCEPTION OTHERS ');
  END Report_Bilan; 

/**************************************************************************
 * PROCEDURE NAME : set_recovery_mode
 *
 * DESCRIPTION
 *  Procédure d'initialisation du mode reprise (Pas de fichier en entrée)
 *
 * PARAMETERS
 * ==========
 * NAME               DESCRIPTION
 * -----------------  ------------------------------------------------------
 *
 *************************************************************************/
  PROCEDURE set_recovery_mode(p_Errbuf            OUT VARCHAR2,
                              p_retcode           OUT NUMBER
                              ) 
  IS

  BEGIN

     --RESET g_loader_request_id
     g_loader_request_id := -1;
     
    UPDATE DKA_RCV_HEADERS_TMP
    SET  FLAG                 = '-1'
        ,ORG_ID               = NULL
    WHERE FLAG = 'E';
    
    UPDATE DKA_RCV_TRANSACTIONS_TMP
    SET FLAG = '-1'
        ,PERSON_ID          = NULL
    WHERE FLAG = 'E';
    

  EXCEPTION
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'SET_RECOVERY_MODE : ' ||SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure SET_RECOVERY_MODE : EXCEPTION OTHERS ');
  END set_recovery_mode;
  
 -------------------------------------------------------------------------------------
 -- PROCEDURE NAME : init_status_oi
 -- DESCRIPTION : Initialisation du statut des lignes en erreur dans l'open interface 
 --               afin qu'elles soient retraitées lors de l'import dans Oracle
 -------------------------------------------------------------------------------------
  PROCEDURE init_status_oi(p_Errbuf   OUT VARCHAR2,
                           p_retcode  OUT NUMBER) 
  IS

  BEGIN
  
    Fnd_File.Put_Line(Fnd_File.LOG, to_char(sysdate, 'DD/MM/YYYY HH24:MI:SS')||' - '||'Début init_status_oi');
    
    update rcv_headers_interface rhi   
    Set   --Rhi.Transaction_Type = 'ADD'      -- RBK
          Rhi.Transaction_Type = Nvl(   (Select 'ADD' 
                                         from rcv_shipment_headers rsh
                                         Where Rsh.Receipt_Num = Rhi.Receipt_Num  
                                         And Rsh.ship_to_Org_Id = Rhi.Org_Id   
                                        )   , 'NEW' ) 
        , Rhi.Processing_Status_Code = 'PENDING'
        , Processing_Request_Id = Null      -- RBK
        , Receipt_Header_Id = Null          -- RBK  
        , Validation_Flag = 'Y'             -- RBK 
        , Packing_Slip = Null               -- RBK   
        ,last_update_date = sysdate 		--RBK	    
    where exists (select 'exists'
                  from rcv_shipment_headers rsh
                  where rsh.receipt_num = rhi.receipt_num
				  And Rsh.ship_to_Org_Id = Rhi.Org_Id  				-- RBK ajout 
			     )
    AND NOT EXISTS (select 'exists'
                      from rcv_shipment_headers rsh
                      join rcv_shipment_lines   rsl on(rsl.shipment_header_id = rsh.shipment_header_id)
                      where rsh.receipt_num = rhi.receipt_num
					  And Rsh.ship_to_Org_Id = Rhi.Org_Id  				-- RBK ajout 
				)
	;    
    
	
    Update Rcv_Headers_Interface Rhi
    Set  Rhi.Transaction_Type = Nvl(   (Select 'ADD' 
                                        from rcv_shipment_headers rsh
                                        Where Rsh.Receipt_Num = Rhi.Receipt_Num  
                                        And Rsh.Ship_To_Org_Id = Rhi.Org_Id   
                                        )   , 'NEW' ) 
        , Rhi.Processing_Status_Code = 'PENDING'
        , Processing_Request_Id = Null      -- RBK
        , Receipt_Header_Id = Null          -- RBK  
        , Validation_Flag = 'Y'             -- RBK 
        , Packing_Slip = Null               -- RBK 
        ,last_update_date = sysdate --RBK
    where rhi.processing_status_code = 'ERROR'
      and exists (select 'exists'
                  from dka_rcv_headers_tmp drh
                  where 'REP'||drh.receipt_num =  rhi.receipt_num  -- OBE artf2184213 
                    --and drh.vendor_num = rhi.vendor_num					-- RBK comment
                    --and drh.vendor_site_code = rhi.vendor_site_code		-- RBK comment
                    and drh.org_id = rhi.org_id
                    and drh.flag = 'T'
			      )
	;
    
    update rcv_transactions_interface rti
    set rti.processing_status_code = 'PENDING',
        rti.transaction_status_code = 'PENDING'
		---- RBK 
        ,last_update_date = sysdate --RBK
       ,Request_Id = Null                 
       ,Processing_Request_Id = Null       
       ,Order_Transaction_Id = Null       
       ,Interface_Transaction_Qty = Null   
       ,Validation_Flag = 'Y'             
       ,Category_Id = Null
       ,Unit_Of_Measure = Null
       ,Shipment_Header_Id = Null
       --,Ship_To_Location_Id = Null  -- OBE artf2205872
       ,Routing_Header_Id = Null
       ,Routing_Step_Id = Null
      --,Po_Header_Id = Null, Po_Revision_Num = Null, Po_Line_Id = Null, Po_Line_Location_Id = Null, Po_Distribution_Id = Null 
      ,Charge_Account_Id = Null
      ,Deliver_to_Person_Id = Null
      ,Inspection_Status_Code = Null
      --,Location_Id = Null -- OBE artf2205872 
      --,Deliver_To_Location_Id = Null -- OBE artf2205872
      ,Expected_Receipt_Date = Null
      ,Source_Doc_Quantity = Null        ,Source_Doc_Unit_Of_Measure = Null 
      ,Tax_Amount  = Null
      ,Shipment_Line_Status_Code = Null
      ,Interface_Available_Qty = Null
      ,Matching_Basis  = Null 
      -- FIn RBK
    where (processing_status_code = 'ERROR' or transaction_status_code = 'ERROR')
      and exists (select 'exists'
                  from dka_rcv_transactions_tmp  drt
                  where drt.po_num = rti.document_num
                    and drt.po_line_num = rti.document_line_num
                    --and drt.vendor_num = rti.vendor_num						-- RBK comment
                    --and drt.vendor_site_code = rti.vendor_site_code			-- RBK comment
                    --and drt.ship_to_location = rti.ship_to_location_code		-- RBK comment
                    and drt.org_id = rti.org_id
                    and drt.transaction_type = rti.transaction_type
                    and drt.flag = 'T'
				 );
                           
    Fnd_File.Put_Line(Fnd_File.LOG, 'Nb de lignes avec statut mis à jour dans l''OI des réceptions: '||to_char(sql%rowcount));
    Fnd_File.Put_Line(Fnd_File.LOG, to_char(sysdate, 'DD/MM/YYYY HH24:MI:SS')||' - '||'Fin init_status_oi');

	COMMIT;		-- RBK  
	
  EXCEPTION
    WHEN OTHERS THEN
      p_retcode   := 2;
      p_errbuf    := 'INIT STATUS OI : ' ||SQLERRM;
      Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
      Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure INIT_STATUS_OI : EXCEPTION OTHERS ');
  END init_status_oi;

/**************************************************************************
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


     Fnd_File.Put_Line(Fnd_File.LOG, '-> DKA_RCV_HEADERS_TMP' );

     -- On supprime les enregistrements

     DELETE FROM DKA_RCV_HEADERS_TMP;

     g_summary.purged_header_rows := SQL%ROWCOUNT;
     Fnd_File.Put_Line(Fnd_File.LOG, '=> Deleted rows '||TO_CHAR(g_summary.purged_header_rows));
     
     Fnd_File.Put_Line(Fnd_File.LOG, '-> DKA_RCV_TRANSACTIONS_TMP' );
     DELETE FROM DKA_RCV_TRANSACTIONS_TMP;

     g_summary.purged_transaction_rows := SQL%ROWCOUNT;
     Fnd_File.Put_Line(Fnd_File.LOG, '=> Deleted rows '||TO_CHAR(g_summary.purged_transaction_rows));


  EXCEPTION
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'PURGE_DATA : ' ||SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure PURGE_DATA : EXCEPTION OTHERS ');
  END purge_data;
   
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
                p_reprise   IN      VARCHAR2,
                p_gl_date       IN VARCHAR2
              )

IS
  v_errbuf                    VARCHAR2(2500);
  v_retcode                   NUMBER;
  Erreur_Programme            EXCEPTION;
  error                       EXCEPTION;
  v_current_program_unit      VARCHAR2(30);
  
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
      
      Init(v_errbuf, v_retcode, p_reprise, p_gl_date);
      
      IF v_retcode = 2 
      THEN
          p_Errbuf  := v_errbuf;
          p_retcode := v_retcode;
          RAISE Erreur_Programme;
      END IF;       

      IF g_summary.reprise_flag = 'N' THEN
        -------------------------------------------
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
      
      ELSE
        set_recovery_mode(v_errbuf,
                          v_retcode
                          );
      END IF;

      -- Maj des champs societe/region
      update_region_societe(v_errbuf,
                            v_retcode
                           );
                           
      IF v_retcode = 2 
      THEN
          RAISE Erreur_Programme;
      END IF;
      
      -- Lancement de validation des données
      validate_data(v_errbuf,
                   v_retcode
                   );
      IF v_retcode = 2 
      THEN
          RAISE Erreur_Programme;
      END IF;
      
      -- Initialisation du statut des lignes en erreur dans l'open interface
      IF g_summary.reprise_flag = 'Y' THEN
        init_status_oi(v_errbuf,
                       v_retcode);
                       
        if v_retcode = 2 then
          raise erreur_programme;
        end if;
      END IF;
      
      -- Lancement de l'insertion des données
      import_data( v_errbuf,
                   v_retcode
                   );
      IF v_retcode = 2 
      THEN
          RAISE Erreur_Programme;
      END IF;
      

      -----------------------------------------------
      -- PHASE DE LANCEMENT DU TRAITEMENT STANDARD --
      ----------------------------------------------- 
      Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'PHASE DE LANCEMENT DU TRAITEMENT STANDARD'); 
   
      -- Lancement du programme standard 
      Launch_OI(v_errbuf,
               v_retcode
               );
      IF v_retcode = 2 
      THEN
          RAISE Erreur_Programme;
      END IF;
      
      -- bilan
      Report_Bilan(p_Errbuf,
                   p_retcode
                   ); 
                 
      ---------------------------------------
      -- PHASE DE FIN DU TRAITEMENT MAITRE --
      ---------------------------------------
      IF p_retcode = 2
      THEN
         p_errbuf := 'ATTENTION : Erreur bloquante : '||p_errbuf;
      ELSIF (g_summary.rejected_header_rows > 0 OR g_summary.rejected_transaction_rows > 0 OR g_summary.warning_flag = 'Y')
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
           Fnd_File.put_line (Fnd_File.Log,'Erreur technique sur le composant   : '||'DKA_IMPTRECPO_PKG.' || v_current_program_unit||CHR(10)||'A retourné     : '||SQLERRM);
           Fnd_File.put_line (Fnd_File.Output ,CHR(10) || '==> Erreur technique (voir journal du traitement)' || CHR(10));
           p_errbuf := SQLERRM;
  END main; 

------------------------------------------------------
END DKA_IMPTRECPO_PKG;
/
SHOW ERRORS
EXIT
