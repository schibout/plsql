CREATE OR REPLACE PACKAGE BODY APPS.DKA_IPORECEPTION_IVALUA_PKG AS
  --------------------------------------------------------------------------------
  -- $
  -- Capgemini
  -- Projet           : DALKIA Oracle Applications
  -- Nom              : DKA_IPORECEPTION_IVALUA_PKG
  -- Nom              : DKA_IPORECEPTION_IVALUA_PKG
  -- Description      : Body du package DKA_IPORECEPTION_IVALUA_PKG ( IMPORT DES RECEPTIONS PO )
  -- Auteur           : SELO
  -- Date de crÃ¿Â©ation : 17/06/2020
  -- Doc. associÃ¿Â©e    :
  -- Commentaires     : Ã¿Â¿ exÃ¿Â©cuter sous SQLPLUS avec l'utilisateur APPS
  --------------------------------------------------------------------------------
  -- Historique
  -- Date SELO EDB262-C
  -- 09/09/2021 ARA DALKIA / artf07480504 - INC0583031 - INT089 - Interface des rÃ¿Â©ceptions en erreur - problÃ¿Å¡me de dÃ¿Â©cimal
  -- 20/09/2021 SELO EDB301
  -- 10/11/2023 SELO KDFI-1454
  -- 12/01/2024 BNZ  EDB375 AmÃ¿Â©liorer le traitement des rejets
  -- 08/01/2025 BNZ KDFI-2547 Correctif EXCEPTION non gÃ©rÃ©e
  -- 01/10/2024 BNZ EDB388 Ameliorer le traitement des rejets
  --------------------------------------------------------------------------------

 --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PRIVEES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    TYPE summary_typ IS RECORD
    (
     loaded_header_rows               NUMBER      -- Nb des en-entÃ¿Âªtes chargÃ¿Â©es en table specifique
    ,loaded_transaction_rows          NUMBER      -- Nb des transactions chargÃ¿Â©s en table specifique
    ,rec_final_rows                   NUMBER      -- Nb des en-entÃ¿Âªtes chargÃ¿Â©es en table specifique
    ,rejected_header_rows             NUMBER      -- Nb de Lignes en-entÃ¿Âªtes rejectÃ¿Â©es
  ,warning_header_rows              NUMBER      -- Nb de Lignes en-entÃ¿Âªtes avertissement
    ,rejected_io_rows                 NUMBER      -- Nb de Lignes transaction rejectÃ¿Â©s
    ,complete_header_rows             NUMBER      -- SELO
    ,inserted_header_rows             NUMBER      -- Nb de Lignes en-entÃ¿Âªtes insÃ¿Â©rÃ¿Â©es
    ,inserted_transaction_rows        NUMBER      -- Nb de Lignes transaction insÃ¿Â©rÃ¿Â©s
    ,purged_header_rows               NUMBER      -- Nb de Lignes purgÃ¿Â©es en table spÃ¿Â©cifique
    ,purged_interface_rows            NUMBER      -- Nb de Lignes purgÃ¿Â©es en table spÃ¿Â©cifique
    ,purged_errors_rows               NUMBER
    ,purged_transaction_rows          NUMBER
  ,header_rows                      NUMBER    --BNZ EDB375 Nb rÃ¿Â©ouverte partie entÃ¿Âªte
  ,line_rows                        NUMBER    --BNZ EDB375 Nb rÃ¿Â©ouverte partie ligne
  ,rec_rows_traite                  NUMBER    --BNZ EDB375 Nb rÃ¿Â©ouverte traite
  ,rec_rows_no_traite               NUMBER    --BNZ EDB375 Nb rÃ¿Â©ouverte no traite
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
  -- Description      : ProcÃ¿Â©dure principale du traitement
  --
  -- PARAMETRES       : p_errbuf         Sortie Message d'erreur
  --                    p_retcode        Sortie Code Retour de la procÃ¿Â©dure
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
 *  ProcÃ¿Â©dure pour insÃ¿Â©rer une en-tÃ¿Âªte dans le fichier de sortie
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

        ----- RÃ¿Â©cupÃ¿Â©ration des noms abrÃ¿Â©gÃ¿Â© et long du traitement en fonction de la langue -----
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
    Fnd_File.put_line (Fnd_File.output, 'COMPTE-RENDU DU TRAITEMENT Ã¿Â« DKA : Import des donnÃ¿Â©es RÃ¿Â©ceptions depuis iValua Ã¿Â»');
        Fnd_File.put_line (Fnd_File.output, 'Traitement nÃ¿Â° '||fnd_global.conc_request_id);
        Fnd_File.put_line (Fnd_File.output, 'Le : ' || TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') );
    Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10));
        --Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10) || CHR(10));
  END output_header;


 /*
 *************************************************************************
 * PROCEDURE NAME : Request_parameters
 *
 * DESCRIPTION
 *  ProcÃ¿Â©dure pour afficher les valeurs de paramÃ¿Å¡tres du traitement
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
                   END LOOP;

                   --Fnd_File.put_line (Fnd_File.output,CHR(10));

            ELSE
                   --Fnd_File.put_line (Fnd_File.output,'Aucun argument');
                   Fnd_File.put_line (Fnd_File.log,'Aucun argument');
            END IF;

        CLOSE cur_parameters;

  END Request_parameters;

 /*
 *************************************************************************
 * PROCEDURE NAME : Output_End
 *
 * DESCRIPTION
 *  ProcÃ¿Â©dure pour insÃ¿Â©rer une fin dans le fichier de sortie
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
        Fnd_File.put_line (Fnd_File.output, 'Programme terminÃ¿Â© le : ' || TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || CHR(10));
        Fnd_File.put_line (Fnd_File.output, cv_line);
  END output_end;

 /*
 *************************************************************************
 * PROCEDURE NAME : Add_Message
 *
 * DESCRIPTION
 *  ProcÃ¿Â©dure pour insÃ¿Â©rer un message dans le fichier de sortie
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
                          record_id        IN  VARCHAR2,
                          p_message_text      IN  VARCHAR2,
                          pv_table_id         IN  VARCHAR2
                          )
  IS
        cv_line                     VARCHAR2 (500);
  BEGIN

    IF  g_summary.message_flag = 0 THEN
    --  cv_line := 'Liste des rejets de validation :';
    --  Fnd_File.put_line (Fnd_File.output, CHR(10)||cv_line);
    --  cv_line := '-----------------';
    --  Fnd_File.put_line (Fnd_File.output, cv_line);
      cv_line := 'NumÃ¿Â©ro de reception  RECORD_ID   Message d''erreur';
      Fnd_File.put_line (Fnd_File.output, cv_line);
      cv_line := '-------------------  ---------   ----------------';
      Fnd_File.put_line (Fnd_File.output, cv_line);
      g_summary.message_flag := 1;
    END IF;

    cv_line := RPAD(nvl(p_document_num,' '),19,' ') ||'  '||RPAD(NVL(record_id,' '),10,' ') ||'  ' || p_message_text ;

    Fnd_File.put_line (Fnd_File.output, cv_line);


    /*

    -- RBE artf2125858 : Inserer dans la table des erreurs spÃ¿Â©cifiques
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
       );*/

  END Add_Message;
--< EDB375 BNZ

/*
 *************************************************************************
 * PROCEDURE NAME : Add_Message2
 *
 * DESCRIPTION
 *  ProcÃ¿Â©dure pour insÃ¿Â©rer un message dans le fichier de sortie
 *
 * PARAMETERS
 * ==========
 * NAME              DESCRIPTION
 * ----------------- ------------------------------------------------------
 *
 *
 ************************************************************************
 */

  PROCEDURE Add_Message2  (p_document_num      IN  VARCHAR2,
                          cmd_id        IN  VARCHAR2,
                          cmd_num      IN  VARCHAR2,
              id_ligne      IN  VARCHAR2,
                          Blocage         IN  VARCHAR2
                          )
  IS
        cv_line                     VARCHAR2 (500);
  BEGIN

    IF  g_summary.message_flag = 0 THEN

      cv_line := 'NumÃ¿Â©ro de reception  Commande_ID   Commande_num  Line_ID  Blocage';
      Fnd_File.put_line (Fnd_File.output, cv_line);
      cv_line := '-------------------  -----------   ------------  -------  -------';
      Fnd_File.put_line (Fnd_File.output, cv_line);
      g_summary.message_flag := 1;
    END IF;

    cv_line := RPAD(nvl(p_document_num,' '),19,' ') ||'  '||RPAD(NVL(cmd_id,' '),12,' ') ||'  '||RPAD(NVL(cmd_num,' '),12,' ') ||'  ' ||RPAD(NVL(id_ligne,' '),12,' ') ||'  ' || blocage ;

    Fnd_File.put_line (Fnd_File.output, cv_line);


  END Add_Message2;
--> EDB375 BNZ

 FUNCTION get_organization_id (
                               p_societe IN VARCHAR2
                              ,p_region  IN VARCHAR2
                              )
  RETURN NUMBER
  IS
    v_organization_id NUMBER;
  BEGIN

     -- Recherche si le fournisseur est prÃ¿Â©sent dans l'OI
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

     -- RECHERCHE SI LE SITE CODE FOURNISSEUR EST PRÃ¿Â¿SENT DANS L'OI
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
 *  ProcÃ¿Â©dure de purge des donnÃ¿Â©es
 *
 * PARAMETERS
 * ==========
 * NAME               DESCRIPTION
 * -----------------  ------------------------------------------------------
 *
 *************************************************************************/
/*  PROCEDURE update_region_societe(p_Errbuf            OUT VARCHAR2,
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
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procÃ¿Â©dure UPDATE_REGION_SOCIETE : EXCEPTION OTHERS ');
  END update_region_societe;
*/
--------------------------------------------------------------------------------------
/*
 *************************************************************************
 * PROCEDURE NAME : init
 *
 * DESCRIPTION
 *  ProcÃ¿Â©dure d'initialisation des variables globales
 *
 * PARAMETERS
 * ==========
 * NAME              DESCRIPTION
.* ----------------- ------------------------------------------------------
 * p_errbuf         Retour de message Ã¿Â©ventuel
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

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'DÃ¿Â©but init');

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
    g_summary.warning_header_rows            := 0;
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
           Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Erreur de rÃ¿Â©cupÃ¿Â©ration de l''imprimante');
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
 *  ProcÃ¿Â©dure d'insertion dans les tables finales
 *
 * PARAMETERS
 * ==========
 * NAME               DESCRIPTION
.* -----------------  ------------------------------------------------------
 * p_errbuf          Retour de message Ã¿Â©ventuel
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
  v_PO_VALIDE                   NUMBER;
  v_add                         Number; -- SELO EDB301
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
  v_ID_MVT_REC                  Number;
  v_ID_MVT_ORIGINE              Number;
  v_ID_MVT_ORIGINE_REC          Number;
  v_ID_MVT_ORIGINE_LIG          Number;
  v_flag_warning                Number;
  -- Cursor des receptions
  CURSOR cur_recept IS
    SELECT *
      FROM dka.DKA_IPOREC_INTERFACE dii
     WHERE 1 = 1
      -- AND load_request_id = DECODE(g_loader_request_id, -1, load_request_id, g_loader_request_id) --
      -- AND flag = '-1' --
       and dii.record_id=v_RECORD_ID
     ORDER BY RECEIPT_NUM, record_id -- SOCIETE, REGION  ajout
       FOR UPDATE OF STATUT, shipment_line_id, TRANSACTION_ID , PARENT_TRANSACTION_ID, vendor_id, ORG_ID  , VENDOR_SITE_ID, request_id       --, ORG_ID, CODE_SITE_FOUR --
       ;

BEGIN

  Fnd_File.put_line(Fnd_File.LOG, TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'DÃ¿Â©but validate_data');
  Fnd_File.put_line(Fnd_File.LOG,
                    TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                    'Validation des donnÃ¿Â©es dans les tables spÃ¿Â©cifiques - record_id : '||v_RECORD_ID);


  FOR rec_cur_recept IN cur_recept LOOP
    BEGIN
       v_flag_erreur := FALSE;
     v_flag_warning := 0; -- EDB301
       -- RG401
       BEGIN
        v_Multi_receipt:=0;
        SELECT distinct 1
          into v_Multi_receipt
          FROM dka.DKA_IPOREC_INTERFACE DII,
               dka.DKA_IPOREC_INTERFACE ER_DII
         WHERE 1 = 1
          -- AND DII.load_request_id = DECODE(g_loader_request_id, -1, load_request_id, g_loader_request_id)
          -- AND DII.flag = '-1' --
           AND DII.TRANSACTION_TYPE in ('RECEIVE','CORRECT')
           AND DII.STATUT  in ('NEW','REJECTED','REJECTED_OI')
           AND ER_DII.TRANSACTION_TYPE in ('RECEIVE','CORRECT')
           AND ER_DII.STATUT  in ('NEW','REJECTED','REJECTED_OI')
           AND DII.RECEIPT_NUM=ER_DII.RECEIPT_NUM
       and DII.record_id = rec_cur_recept.record_id
           AND (
                nvl(DII.ORG,'Z') <> nvl(ER_DII.ORG,'Z')
                or
                nvl(DII.VENDOR_NUM,'Z') <> nvl(ER_DII.VENDOR_NUM,'Z')
                or
                nvl(DII.VENDOR_SITE_CODE,'Z') <> nvl(ER_DII.VENDOR_SITE_CODE,'Z')
                or
                nvl(DII.ID_SITE_IVALUA,'Z') <> nvl(ER_DII.ID_SITE_IVALUA,'Z')
                or
                nvl(DII.BORDEREAU_NUM,'Z') <> nvl(ER_DII.BORDEREAU_NUM,'Z')
                );
            if     v_Multi_receipt = 1 then
                v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_005');
                --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                'DKA_IPORECEPTION_IVALUA', --prog_name
                                                'RECEPTION',               --source
                                                'DKA_IPOREC_INTERFACE' ,   --table_name
                                                rec_cur_recept.RECORD_ID,  --table_id
                                                'RECEIPT_NUM',  --column_name
                                                rec_cur_recept.receipt_num, --column_value
                                                'E',                       --message_type
                                               v_message                   --message_text
                                                );


                    v_flag_erreur := TRUE;

                UPDATE DKA_IPOREC_INTERFACE
                 SET STATUT = 'REJECTED'
                   , request_id = g_request_id
               WHERE CURRENT OF cur_recept;

            end if;
      EXCEPTION
        WHEN OTHERS THEN
          null;
      END;
      -- RG402
      IF rec_cur_recept.receipt_num IS NULL THEN
        v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_006');
                --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                'DKA_IPORECEPTION_IVALUA', --prog_name
                                                'RECEPTION',               --source
                                                'DKA_IPOREC_INTERFACE' ,   --table_name
                                                rec_cur_recept.RECORD_ID,  --table_id
                                                'RECEIPT_NUM',  --column_name
                                                rec_cur_recept.receipt_num, --column_value
                                                'E',                       --message_type
                                               v_message                   --message_text
                                                );
                    v_flag_erreur := TRUE;

                UPDATE DKA_IPOREC_INTERFACE
                 SET STATUT = 'REJECTED'
                   , request_id = g_request_id
               WHERE CURRENT OF cur_recept;
      END IF;

      -- RG403
      IF rec_cur_recept.org IS NULL THEN
        v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_007');
        --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
        DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                        'DKA_IPORECEPTION_IVALUA', --prog_name
                                        'RECEPTION',               --source
                                        'DKA_IPOREC_INTERFACE' ,   --table_name
                                        rec_cur_recept.RECORD_ID,  --table_id
                                        'ORG',  --column_name
                                        rec_cur_recept.org, --column_value
                                        'E',                       --message_type
                                        v_message                   --message_text
                                        );
            v_flag_erreur := TRUE;

        UPDATE DKA_IPOREC_INTERFACE
         SET STATUT = 'REJECTED'
           , request_id = g_request_id
       WHERE CURRENT OF cur_recept;

      ELSE
          BEGIN
              SELECT distinct hou.organization_id into v_org_id
                FROM per_security_organizations_v ov,
                     hr_organization_units hou
               WHERE ov.security_profile_id = fnd_profile.VALUE('XLA_MO_SECURITY_PROFILE_LEVEL')
                 AND ov.organization_id = hou.organization_id
                 AND hou.name = rec_cur_recept.org;

              UPDATE DKA_IPOREC_INTERFACE
                 SET ORG_ID = v_org_id
                   , request_id = g_request_id
               WHERE CURRENT OF cur_recept;

           EXCEPTION
            WHEN OTHERS THEN
                v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_008','ORG',rec_cur_recept.org);
                --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                'DKA_IPORECEPTION_IVALUA', --prog_name
                                                'RECEPTION',               --source
                                                'DKA_IPOREC_INTERFACE' ,   --table_name
                                                rec_cur_recept.RECORD_ID,  --table_id
                                                'ORG',  --column_name
                                                rec_cur_recept.org, --column_value
                                                'E',                       --message_type
                                               v_message                   --message_text
                                                );
                        v_flag_erreur := TRUE;

                UPDATE DKA_IPOREC_INTERFACE
                 SET STATUT = 'REJECTED'
                   , request_id = g_request_id
                WHERE CURRENT OF cur_recept;
                v_org_id := 0;
          END;
       END IF;
      -- RG404
      IF rec_cur_recept.vendor_num IS NULL THEN
        v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_009');
        --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
        DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                        'DKA_IPORECEPTION_IVALUA', --prog_name
                                        'RECEPTION',               --source
                                        'DKA_IPOREC_INTERFACE' ,   --table_name
                                        rec_cur_recept.RECORD_ID,  --table_id
                                        'VENDOR_NUM',  --column_name
                                        rec_cur_recept.vendor_num, --column_value
                                        'E',                       --message_type
                                        v_message                   --message_text
                                                );
        v_flag_erreur := TRUE;

        UPDATE DKA_IPOREC_INTERFACE
           SET STATUT = 'REJECTED'
             , request_id = g_request_id
         WHERE CURRENT OF cur_recept;
      ELSE
        v_vendor_id:=0;
        BEGIN
            SELECT VENDOR_ID
              INTO v_vendor_id
              FROM po_vendors
             WHERE segment1 = rec_cur_recept.vendor_num
               AND ROWNUM = 1;
        EXCEPTION
            WHEN OTHERS THEN
                v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_010','VENDOR_NUM',rec_cur_recept.vendor_num);
                --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                'DKA_IPORECEPTION_IVALUA', --prog_name
                                                'RECEPTION',               --source
                                                'DKA_IPOREC_INTERFACE' ,   --table_name
                                                rec_cur_recept.RECORD_ID,  --table_id
                                                'VENDOR_NUM',  --column_name
                                                rec_cur_recept.vendor_num, --column_value
                                                'E',                       --message_type
                                               v_message                   --message_text
                                                );
                v_flag_erreur := TRUE;

                UPDATE DKA_IPOREC_INTERFACE
                   SET STATUT = 'REJECTED'
                     , request_id = g_request_id
                 WHERE CURRENT OF cur_recept;
        END;
      END IF;

      IF v_vendor_id <> 0 THEN
          BEGIN
              SELECT VENDOR_ID
                INTO v_vendor_id
                FROM po_vendors
               WHERE segment1 = rec_cur_recept.vendor_num
                 AND NVL(END_DATE_ACTIVE,sysdate) >=sysdate;

               UPDATE DKA_IPOREC_INTERFACE DII
                  SET DII.vendor_id = v_VENDOR_ID
                    , request_id = g_request_id
                WHERE CURRENT OF cur_recept;
          EXCEPTION
            WHEN OTHERS THEN
                v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_011','VENDOR_NUM',rec_cur_recept.vendor_num);
                --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                'DKA_IPORECEPTION_IVALUA', --prog_name
                                                'RECEPTION',               --source
                                                'DKA_IPOREC_INTERFACE' ,   --table_name
                                                rec_cur_recept.RECORD_ID,  --table_id
                                                'VENDOR_NUM',  --column_name
                                                rec_cur_recept.vendor_num, --column_value
                                                'E',                       --message_type
                                               v_message                   --message_text
                                                );
                v_flag_erreur := TRUE;

                UPDATE DKA_IPOREC_INTERFACE
                   SET STATUT = 'REJECTED'
                     , request_id = g_request_id
                 WHERE CURRENT OF cur_recept;
           END;
      END IF;
      -- RG405
      IF rec_cur_recept.VENDOR_SITE_CODE IS NULL THEN
        v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_012');
        --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
        DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                        'DKA_IPORECEPTION_IVALUA', --prog_name
                                        'RECEPTION',               --source
                                        'DKA_IPOREC_INTERFACE' ,   --table_name
                                        rec_cur_recept.RECORD_ID,  --table_id
                                        'VENDOR_SITE_CODE',  --column_name
                                        rec_cur_recept.VENDOR_SITE_CODE, --column_value
                                        'E',                       --message_type
                                       v_message                   --message_text
                                        );
        v_flag_erreur := TRUE;

        UPDATE DKA_IPOREC_INTERFACE
           SET STATUT = 'REJECTED'
             , request_id = g_request_id
         WHERE CURRENT OF cur_recept;
      END IF;
     -- RG406
      IF rec_cur_recept.ID_SITE_IVALUA IS NULL THEN
        v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_013');
        --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
        DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                        'DKA_IPORECEPTION_IVALUA', --prog_name
                                        'RECEPTION',               --source
                                        'DKA_IPOREC_INTERFACE' ,   --table_name
                                        rec_cur_recept.RECORD_ID,  --table_id
                                        'ID_SITE_IVALUA',  --column_name
                                        rec_cur_recept.ID_SITE_IVALUA, --column_value
                                        'E',                       --message_type
                                       v_message                   --message_text
                                        );
        v_flag_erreur := TRUE;

        UPDATE DKA_IPOREC_INTERFACE
           SET STATUT = 'REJECTED'
             , request_id = g_request_id
         WHERE CURRENT OF cur_recept;
      END IF;

      -- RG407
      IF (v_org_id <> 0 AND v_vendor_id <> 0)
      THEN
         BEGIN
           v_vendor_site_code:=0;
           v_vendor_site_ID :=0;

           SELECT a.VENDOR_SITE_ID
             INTO v_vendor_site_ID
             FROM PO_VENDOR_SITES_ALL a
            WHERE a.VENDOR_SITE_code = rec_cur_recept.VENDOR_SITE_CODE
              AND a.org_id = v_org_id
              AND a.vendor_id=v_vendor_id
           ;
         EXCEPTION
         WHEN OTHERS THEN

           BEGIN
              SELECT a.VENDOR_SITE_ID
                INTO v_vendor_site_ID
                FROM PO_VENDOR_SITES_ALL a
               WHERE a.ATTRIBUTE4 = rec_cur_recept.ID_SITE_IVALUA
                 AND a.org_id = v_org_id
                 AND a.vendor_id=v_vendor_id
               ;
           EXCEPTION
           WHEN OTHERS THEN
              v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_014', 'ID_SITE_IVALUA', rec_cur_recept.ID_SITE_IVALUA,'VENDOR_NUM',rec_cur_recept.vendor_num ,'ORG',rec_cur_recept.org );
              --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
              DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                            'DKA_IPORECEPTION_IVALUA', --prog_name
                                            'RECEPTION',               --source
                                            'DKA_IPOREC_INTERFACE' ,   --table_name
                                            rec_cur_recept.RECORD_ID,  --table_id
                                            'ID_SITE_IVALUA',  --column_name
                                            rec_cur_recept.ID_SITE_IVALUA, --column_value
                                            'E',                       --message_type
                                           v_message                   --message_text
                                            );
              v_flag_erreur := TRUE;

              UPDATE DKA_IPOREC_INTERFACE
                 SET STATUT = 'REJECTED'
                   , request_id = g_request_id
              WHERE CURRENT OF cur_recept;

              v_vendor_site_code := 0;
           END;
         END;
      END IF;

      -- RG408
      if v_vendor_site_ID <> 0 then
        BEGIN

          v_vendor_site_code:=0;
          --v_vendor_site_id:=0;

          SELECT a.VENDOR_SITE_CODE --, a.vendor_site_id
            INTO v_vendor_site_code --, v_vendor_site_id
            FROM PO_VENDOR_SITES_ALL a
           WHERE a.vendor_site_ID = v_vendor_site_ID
             and a.org_id = v_org_id
             and a.vendor_id=v_vendor_id
             and nvl(INACTIVE_DATE,sysdate)>=sysdate
          ;

          UPDATE DKA_IPOREC_INTERFACE
             SET vendor_site_id = v_vendor_site_id
               , request_id = g_request_id
               , vendor_id = v_vendor_id
           WHERE CURRENT OF cur_recept;
        EXCEPTION
          WHEN OTHERS THEN
              v_vendor_site_code:=0;
              v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_015', 'ID_SITE_IVALUA', rec_cur_recept.ID_SITE_IVALUA,'VENDOR_NUM',rec_cur_recept.vendor_num ,'ORG',rec_cur_recept.org);
              --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
              DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                              'DKA_IPORECEPTION_IVALUA', --prog_name
                                              'RECEPTION',               --source
                                              'DKA_IPOREC_INTERFACE' ,   --table_name
                                              rec_cur_recept.RECORD_ID,  --table_id
                                              'ID_SITE_IVALUA',  --column_name
                                              rec_cur_recept.ID_SITE_IVALUA, --column_value
                                              'E',                       --message_type
                                             v_message                   --message_text
                                              );
                  v_flag_erreur := TRUE;

              UPDATE DKA_IPOREC_INTERFACE
                 SET STATUT = 'REJECTED'
                   , request_id = g_request_id
               WHERE CURRENT OF cur_recept;
        END;
      END IF;

      -- RG408
      V_RECEIPT_DATE := null;
      IF rec_cur_recept.RECEIPT_DATE IS NULL THEN
        v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_016');
        --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
        DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                        'DKA_IPORECEPTION_IVALUA', --prog_name
                                        'RECEPTION',               --source
                                        'DKA_IPOREC_INTERFACE' ,   --table_name
                                        rec_cur_recept.RECORD_ID,  --table_id
                                        'RECEIPT_DATE',  --column_name
                                        rec_cur_recept.RECEIPT_DATE, --column_value
                                        'E',                       --message_type
                                       v_message                   --message_text
                                        );
            v_flag_erreur := TRUE;

        UPDATE DKA_IPOREC_INTERFACE
           SET STATUT = 'REJECTED'
             , request_id = g_request_id
         WHERE CURRENT OF cur_recept;

      ELSIF rec_cur_recept.RECEIPT_DATE > sysdate THEN
        v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_017','RECEIPT_DATE',rec_cur_recept.RECEIPT_DATE);
        --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
        DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                        'DKA_IPORECEPTION_IVALUA', --prog_name
                                        'RECEPTION',               --source
                                        'DKA_IPOREC_INTERFACE' ,   --table_name
                                        rec_cur_recept.RECORD_ID,  --table_id
                                        'RECEIPT_DATE',  --column_name
                                        rec_cur_recept.RECEIPT_DATE, --column_value
                                        'E',                       --message_type
                                       v_message                   --message_text
                                        );
            v_flag_erreur := TRUE;

        UPDATE DKA_IPOREC_INTERFACE
           SET STATUT = 'REJECTED'
             , request_id = g_request_id
         WHERE CURRENT OF cur_recept;
      ELSE
        IF v_org_id <> 0
        THEN
          BEGIN
            SELECT rec_cur_recept.RECEIPT_DATE into V_RECEIPT_DATE
              FROM hr_operating_units           hou,
                   gl_ledgers                   gl,
                   gl_period_statuses           gls
             WHERE hou.set_of_books_id = gl.ledger_id
               AND HOU.organization_id = v_org_id
               AND gls.application_id = 201
               AND gls.closing_status = 'O'
               AND gls.set_of_books_id = gl.ledger_id
               and rec_cur_recept.RECEIPT_DATE BETWEEN gls.start_date and gls.end_date
               AND gl.period_set_name = 'GROUPE'
               and exists (select distinct 1
                             FROM hr_operating_units           hou,
                                  gl_ledgers                   gll,
                                  gl_period_statuses           glss
                            WHERE hou.set_of_books_id = gl.ledger_id
                              AND HOU.organization_id = v_org_id
                              AND glss.application_id = 101
                              AND glss.closing_status = 'O'
                              AND glss.set_of_books_id = gl.ledger_id
                              AND gll.period_set_name = 'GROUPE'
                              AND glss.period_name = gls.period_name);
          EXCEPTION
            WHEN OTHERS THEN

              -- RÃ¿Â©cupÃ¿Â©ration de la premiÃ¿Å¡re pÃ¿Â©riode GL ouverte
                SELECT min(start_date) into V_RECEIPT_DATE
                  FROM hr_operating_units           hou,
                       gl_ledgers                   gl,
                       gl_period_statuses           gls
                 WHERE hou.set_of_books_id = gl.ledger_id
                   AND HOU.organization_id = v_org_id
                   AND gls.application_id = 201
                   AND gls.closing_status = 'O'
                   AND gls.set_of_books_id = gl.ledger_id
                   AND gl.period_set_name = 'GROUPE'
                   and exists (select distinct 1
                                 FROM hr_operating_units           hou,
                                      gl_ledgers                   gll,
                                      gl_period_statuses           glss
                                WHERE hou.set_of_books_id = gl.ledger_id
                                  AND HOU.organization_id = v_org_id
                                  AND glss.application_id = 101
                                  AND glss.closing_status = 'O'
                                  AND glss.set_of_books_id = gl.ledger_id
                                  AND gll.period_set_name = 'GROUPE'
                                  AND glss.period_name = gls.period_name);
              IF V_RECEIPT_DATE is null THEN
                    v_message :='Aucune pÃ¿Â©riode ouverte dans PO et GL Ã¿Â  partir de la date de rÃ¿Â©ception' || to_char(rec_cur_recept.RECEIPT_DATE, 'DD/MM/YYYY');
                    --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                    DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                    'DKA_IPORECEPTION_IVALUA', --prog_name
                                                    'RECEPTION',               --source
                                                    'DKA_IPOREC_INTERFACE' ,   --table_name
                                                    rec_cur_recept.RECORD_ID,  --table_id
                                                    'RECEIPT_DATE',  --column_name
                                                    rec_cur_recept.RECEIPT_DATE, --column_value
                                                    'E',                       --message_type
                                                   v_message                   --message_text
                                                    );
                                v_flag_erreur := TRUE;
                    UPDATE DKA_IPOREC_INTERFACE
                       SET STATUT = 'REJECTED'
                         , request_id = g_request_id
                     WHERE CURRENT OF cur_recept;
              END IF;
          END;
        END IF;

         UPDATE DKA_IPOREC_INTERFACE
           SET Receipt_date_new = V_RECEIPT_DATE
             , request_id = g_request_id
         WHERE CURRENT OF cur_recept;

      END IF;


      -- RG410
      IF rec_cur_recept.DOCUMENT_NUM IS NULL THEN
        v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_020');
        --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
        DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                        'DKA_IPORECEPTION_IVALUA', --prog_name
                                        'RECEPTION',               --source
                                        'DKA_IPOREC_INTERFACE' ,   --table_name
                                        rec_cur_recept.RECORD_ID,  --table_id
                                        'DOCUMENT_NUM',  --column_name
                                        rec_cur_recept.DOCUMENT_NUM, --column_value
                                        'E',                       --message_type
                                       v_message                   --message_text
                                        );
            v_flag_erreur := TRUE;

        UPDATE DKA_IPOREC_INTERFACE
           SET STATUT = 'REJECTED'
             , request_id = g_request_id
         WHERE CURRENT OF cur_recept;
      ELSIF v_org_id <> 0
      THEN
        v_CMD_ID:=0;
        BEGIN
            select PHA.PO_header_id into v_CMD_ID
              from PO_HEADERS_ALL PHA
             where PHA.segment1=rec_cur_recept.DOCUMENT_NUM
             --and PHA.org_id=v_org_id
            ;
        EXCEPTION
            WHEN no_data_found THEN
                v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_021','DOCUMENT_NUM',rec_cur_recept.DOCUMENT_NUM);
                --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                'DKA_IPORECEPTION_IVALUA', --prog_name
                                                'RECEPTION',               --source
                                                'DKA_IPOREC_INTERFACE' ,   --table_name
                                                rec_cur_recept.RECORD_ID,  --table_id
                                                'DOCUMENT_NUM',  --column_name
                                                rec_cur_recept.DOCUMENT_NUM, --column_value
                                                'E',                       --message_type
                                               v_message                   --message_text
                                                );
                v_flag_erreur := TRUE;

                UPDATE DKA_IPOREC_INTERFACE
                   SET STATUT = 'REJECTED'
                     , request_id = g_request_id
                 WHERE CURRENT OF cur_recept;
                v_CMD_ID := 0;
            WHEN too_many_rows THEN
                v_CMD_ID:=1;
        END;


        IF v_CMD_ID <> 0 THEN
            BEGIN
              select PHA.PO_header_id into v_CMD_ID
                from PO_HEADERS_ALL PHA
               where PHA.segment1=rec_cur_recept.DOCUMENT_NUM
                 and PHA.org_id=v_org_id;
            EXCEPTION
            WHEN no_data_found THEN
                    v_CMD_ID:=0;
                    v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_022','DOCUMENT_NUM',rec_cur_recept.DOCUMENT_NUM,'ORG',rec_cur_recept.ORG);
                    --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                    DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                    'DKA_IPORECEPTION_IVALUA', --prog_name
                                                    'RECEPTION',               --source
                                                    'DKA_IPOREC_INTERFACE' ,   --table_name
                                                    rec_cur_recept.RECORD_ID,  --table_id
                                                    'DOCUMENT_NUM',  --column_name
                                                    rec_cur_recept.DOCUMENT_NUM, --column_value
                                                    'E',                       --message_type
                                                   v_message                   --message_text
                                                    );
                    v_flag_erreur := TRUE;

                    UPDATE DKA_IPOREC_INTERFACE
                       SET STATUT = 'REJECTED'
                         , request_id = g_request_id
                     WHERE CURRENT OF cur_recept;
            WHEN too_many_rows THEN
                    v_CMD_ID:=1;
            END;
        END IF;
      END IF;
      IF v_CMD_ID <> 0 THEN
          BEGIN
              select PHA.PO_header_id into v_CMD_ID
                from PO_HEADERS_ALL PHA,
                     PO_VENDORS PV
               where PHA.segment1=rec_cur_recept.DOCUMENT_NUM
                 and PHA.org_id=v_org_id
                 and PV.VENDOR_ID=PHA.VENDOR_ID
               and pv.segment1 = rec_cur_recept.vendor_num;
            EXCEPTION
            WHEN no_data_found THEN
               v_CMD_ID:=0;
               v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_023','DOCUMENT_NUM',rec_cur_recept.DOCUMENT_NUM,'VENDOR_NUM',rec_cur_recept.vendor_num);
                    --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                'DKA_IPORECEPTION_IVALUA', --prog_name
                                                'RECEPTION',               --source
                                                'DKA_IPOREC_INTERFACE' ,   --table_name
                                                rec_cur_recept.RECORD_ID,  --table_id
                                                'DOCUMENT_NUM',  --column_name
                                                rec_cur_recept.DOCUMENT_NUM, --column_value
                                                'E',                       --message_type
                                               v_message                   --message_text
                                                );
                        v_flag_erreur := TRUE;

                UPDATE DKA_IPOREC_INTERFACE
                   SET STATUT = 'REJECTED'
                     , request_id = g_request_id
                 WHERE CURRENT OF cur_recept;
      WHEN too_many_rows THEN
         v_CMD_ID:=1;
        END;
            IF v_CMD_ID <> 0 THEN
                BEGIN
                  select PHA.PO_header_id into v_CMD_ID
                    from PO_HEADERS_ALL PHA,
                         PO_VENDORS PV,
                         PO_VENDOR_SITES_ALL pvs
                   where PHA.segment1=rec_cur_recept.DOCUMENT_NUM
                     and PHA.org_id=v_org_id
                     and PHA.vendor_site_id=pvs.vendor_site_id
                     and PHA.vendor_site_id=v_vendor_site_id
                     and PV.VENDOR_ID=PHA.VENDOR_ID
                     and pv.vendor_id=pvs.vendor_id
                     and pvs.org_id= v_org_id;
                EXCEPTION
                WHEN no_data_found THEN
                   v_CMD_ID:=0;
                   v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_024','DOCUMENT_NUM',rec_cur_recept.DOCUMENT_NUM,'ID_SITE_IVALUA',rec_cur_recept.ID_SITE_IVALUA);
                        --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                    DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                    'DKA_IPORECEPTION_IVALUA', --prog_name
                                                    'RECEPTION',               --source
                                                    'DKA_IPOREC_INTERFACE' ,   --table_name
                                                    rec_cur_recept.RECORD_ID,  --table_id
                                                    'DOCUMENT_NUM',  --column_name
                                                    rec_cur_recept.DOCUMENT_NUM, --column_value
                                                    'E',                       --message_type
                                                   v_message                   --message_text
                                                    );
                            v_flag_erreur := TRUE;

                    UPDATE DKA_IPOREC_INTERFACE
                       SET STATUT = 'REJECTED'
                         , request_id = g_request_id
                     WHERE CURRENT OF cur_recept;
          WHEN too_many_rows THEN
              v_CMD_ID:=1;
            END;
            END IF;
      END IF;

      IF v_CMD_ID <> 0 THEN
    BEGIN
      select PHA.PO_header_id
        into v_CMD_ID
        from PO_HEADERS_ALL PHA, PO_VENDORS PV, PO_VENDOR_SITES_ALL pvs
       where PHA.segment1 = rec_cur_recept.DOCUMENT_NUM
         and PHA.org_id = v_org_id
         and PHA.vendor_site_id = pvs.vendor_site_id
         and PHA.vendor_site_id = v_vendor_site_id
         and PV.VENDOR_ID = PHA.VENDOR_ID
         and pv.vendor_id = pvs.vendor_id
         and PHA.AUTHORIZATION_STATUS = 'APPROVED'
         and PHA.CANCEL_FLAG <> 'Y'
         and pvs.org_id = v_org_id
         and nvl(CLOSED_CODE, 'A') not in ('FINALLY CLOSED'); -- EDB262-C

      UPDATE DKA_IPOREC_INTERFACE
         SET CMD_ID = v_CMD_ID, request_id = g_request_id
       WHERE CURRENT OF cur_recept;

    EXCEPTION
      WHEN others THEN
        /*v_CMD_ID:=0;
        v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_025','DOCUMENT_NUM',rec_cur_recept.DOCUMENT_NUM);
        --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
        DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                        'DKA_IPORECEPTION_IVALUA', --prog_name
                                        'RECEPTION',               --source
                                        'DKA_IPOREC_INTERFACE' ,   --table_name
                                        rec_cur_recept.RECORD_ID,  --table_id
                                        'DOCUMENT_NUM',  --column_name
                                        rec_cur_recept.DOCUMENT_NUM, --column_value
                                        'E',                       --message_type
                                       v_message                   --message_text
                                        );
        v_flag_erreur := TRUE;

        UPDATE DKA_IPOREC_INTERFACE
           SET STATUT = 'REJECTED'
             , request_id = g_request_id
         WHERE CURRENT OF cur_recept;*/

        --< BNZ EDB375
        begin
        select PHA.PO_header_id
          into v_CMD_ID
          from PO_HEADERS_ALL PHA, PO_VENDORS PV, PO_VENDOR_SITES_ALL pvs
         where PHA.segment1 = rec_cur_recept.DOCUMENT_NUM
           and PHA.org_id = v_org_id
           and PHA.vendor_site_id = pvs.vendor_site_id
           and PHA.vendor_site_id = v_vendor_site_id
           and PV.VENDOR_ID = PHA.VENDOR_ID
           and pv.vendor_id = pvs.vendor_id
           and PHA.AUTHORIZATION_STATUS = 'APPROVED'
           and PHA.CANCEL_FLAG <> 'Y'
           and pvs.org_id = v_org_id
           and CLOSED_CODE in ('FINALLY CLOSED');


        UPDATE DKA_IPOREC_INTERFACE
           SET CMD_ID = v_CMD_ID,
           request_id = g_request_id
         WHERE CURRENT OF cur_recept;
        -- add to table reject
        INSERT INTO DKA.DKA_IPOREC_REJECT
          (ID_CMD,
           STATUT_CMD,
           NUM_CMD,
           BLOCAGE,
           ID_LIGNE,
           NEW_STATUT_CMD,
           RECEIPT_NUM,
           REQUEST_ID)
          select distinct dii.CMD_ID ID_CMD,
                 'FINALLY CLOSED' STATUT_CMD,
                 dii.DOCUMENT_NUM NUM_CMD,
                 'Header' BLOCAGE,
                 NULL ID_LIGNE,
                 Null NEW_STATUT_CMD,
                 dii.RECEIPT_NUM,
                 dii.request_id REQUEST_ID
            from DKA_IPOREC_INTERFACE dii
           where  dii.CMD_ID = V_CMD_ID
       and dii.receipt_num = rec_cur_recept.RECEIPT_NUM
       and dii.request_id = g_REQUEST_ID;
EXCEPTION
      WHEN others THEN --< BNZ KDFI-2547
        v_CMD_ID:=0;
        v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_025','DOCUMENT_NUM',rec_cur_recept.DOCUMENT_NUM);
        --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
        DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                        'DKA_IPORECEPTION_IVALUA', --prog_name
                                        'RECEPTION',               --source
                                        'DKA_IPOREC_INTERFACE' ,   --table_name
                                        rec_cur_recept.RECORD_ID,  --table_id
                                        'DOCUMENT_NUM',  --column_name
                                        rec_cur_recept.DOCUMENT_NUM, --column_value
                                        'E',                       --message_type
                                       v_message                   --message_text
                                        );
        v_flag_erreur := TRUE;

        UPDATE DKA_IPOREC_INTERFACE
           SET STATUT = 'REJECTED'
             , request_id = g_request_id
         WHERE CURRENT OF cur_recept;
      END;

    END; --> BNZ KDFI-2547



            -- EDB262-C BEGIN
            IF rec_cur_recept.TRANSACTION_TYPE = 'RECEIVE' THEN
                BEGIN
          v_PO_VALIDE := 0;
          select PHA.PO_header_id into v_PO_VALIDE
          from PO_HEADERS_ALL PHA
           where PHA.segment1=rec_cur_recept.DOCUMENT_NUM
           and PHA.org_id=v_org_id
           and PHA.vendor_site_id=v_vendor_site_id
           and PHA.AUTHORIZATION_STATUS ='APPROVED'
           and PHA.CANCEL_FLAG <> 'Y'; -- EDB262-C
        EXCEPTION
          WHEN OTHERS THEN
             v_PO_VALIDE := 0;
        END;
      END IF;


            IF ((rec_cur_recept.TRANSACTION_TYPE = 'RECEIVE') and (v_PO_VALIDE <> 0)) THEN
        BEGIN
          select PHA.PO_header_id into v_CMD_ID
          from PO_HEADERS_ALL PHA,
             PO_VENDORS PV,
             PO_VENDOR_SITES_ALL pvs
           where PHA.segment1=rec_cur_recept.DOCUMENT_NUM
           and PHA.org_id=v_org_id
           and PHA.vendor_site_id=pvs.vendor_site_id
           and PHA.vendor_site_id=v_vendor_site_id
           and PV.VENDOR_ID=PHA.VENDOR_ID
           and pv.vendor_id=pvs.vendor_id
           and PHA.AUTHORIZATION_STATUS ='APPROVED'
           and PHA.CANCEL_FLAG <> 'Y'
           and pvs.org_id= v_org_id
           and nvl(CLOSED_CODE,'A') not in ('CLOSED'); -- EDB262-C

          UPDATE DKA_IPOREC_INTERFACE
             SET CMD_ID = v_CMD_ID
             , request_id = g_request_id
           WHERE CURRENT OF cur_recept;

        EXCEPTION
          WHEN OTHERS THEN
            --BNZ EDB388
           /* v_CMD_ID:=0;
            v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_051','DOCUMENT_NUM',rec_cur_recept.DOCUMENT_NUM);
            --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
            DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                            'DKA_IPORECEPTION_IVALUA', --prog_name
                            'RECEPTION',               --source
                            'DKA_IPOREC_INTERFACE' ,   --table_name
                            rec_cur_recept.RECORD_ID,  --table_id
                            'DOCUMENT_NUM',  --column_name
                            rec_cur_recept.DOCUMENT_NUM, --column_value
                            'E',                       --message_type
                             v_message                   --message_text
                            );
            v_flag_erreur := TRUE;

            UPDATE DKA_IPOREC_INTERFACE
               SET STATUT = 'REJECTED'
               , request_id = g_request_id
             WHERE CURRENT OF cur_recept;
       */
        --< BNZ EDB388
 begin
             select PHA.PO_header_id into v_CMD_ID
          from PO_HEADERS_ALL PHA,
             PO_VENDORS PV,
             PO_VENDOR_SITES_ALL pvs
           where PHA.segment1=rec_cur_recept.DOCUMENT_NUM
           and PHA.org_id=v_org_id
           and PHA.vendor_site_id=pvs.vendor_site_id
           and PHA.vendor_site_id=v_vendor_site_id
           and PV.VENDOR_ID=PHA.VENDOR_ID
           and pv.vendor_id=pvs.vendor_id
           and PHA.AUTHORIZATION_STATUS ='APPROVED'
           and PHA.CANCEL_FLAG <> 'Y'
           and pvs.org_id= v_org_id
           and nvl(CLOSED_CODE,'A')  in ('CLOSED');


      UPDATE DKA_IPOREC_INTERFACE
             SET CMD_ID = v_CMD_ID
             , request_id = g_request_id
           WHERE CURRENT OF cur_recept;
       
    -- INSERT IN TABLE REJET
    
          INSERT INTO DKA.DKA_IPOREC_REJECT
          (ID_CMD,
           STATUT_CMD,
           NUM_CMD,
           BLOCAGE,
           ID_LIGNE,
           NEW_STATUT_CMD,
           RECEIPT_NUM,
           REQUEST_ID)
          select distinct dii.CMD_ID ID_CMD,
                 'CLOSED' STATUT_CMD,
                 dii.DOCUMENT_NUM NUM_CMD,
                 'Header' BLOCAGE,
                 NULL ID_LIGNE,
                 Null NEW_STATUT_CMD,
                 dii.RECEIPT_NUM,
                 dii.request_id REQUEST_ID
            from DKA_IPOREC_INTERFACE dii
           where  dii.CMD_ID = V_CMD_ID
       and dii.receipt_num = rec_cur_recept.RECEIPT_NUM
       and dii.request_id = g_REQUEST_ID;
  EXCEPTION
                WHEN others THEN
         v_CMD_ID:=0;
            v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_051','DOCUMENT_NUM',rec_cur_recept.DOCUMENT_NUM);
            --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
            DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                            'DKA_IPORECEPTION_IVALUA', --prog_name
                            'RECEPTION',               --source
                            'DKA_IPOREC_INTERFACE' ,   --table_name
                            rec_cur_recept.RECORD_ID,  --table_id
                            'DOCUMENT_NUM',  --column_name
                            rec_cur_recept.DOCUMENT_NUM, --column_value
                            'E',                       --message_type
                             v_message                   --message_text
                            );
            v_flag_erreur := TRUE;

            UPDATE DKA_IPOREC_INTERFACE
               SET STATUT = 'REJECTED'
               , request_id = g_request_id
             WHERE CURRENT OF cur_recept;
        --> BNZ EDB388
       END;
        END;
            END IF;
            -- EDB262-C END
      END IF;

      -- RG411
        IF rec_cur_recept.ID_LIGNE_IVALUA IS NULL THEN
            v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_026');
            --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
            DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                            'DKA_IPORECEPTION_IVALUA', --prog_name
                                            'RECEPTION',               --source
                                            'DKA_IPOREC_INTERFACE' ,   --table_name
                                            rec_cur_recept.RECORD_ID,  --table_id
                                            'ID_LIGNE_IVALUA',  --column_name
                                            rec_cur_recept.ID_LIGNE_IVALUA, --column_value
                                            'E',                       --message_type
                                           v_message                   --message_text
                                            );
                v_flag_erreur := TRUE;

            UPDATE DKA_IPOREC_INTERFACE
               SET STATUT = 'REJECTED'
                 , request_id = g_request_id
             WHERE CURRENT OF cur_recept;
        ELSE
            BEGIN
                v_LIGNE_ID := 0;
                select POLA.PO_LINE_id into v_LIGNE_ID
                  from PO_LINES_ALL POLA
                 where POLA.ATTRIBUTE8=rec_cur_recept.ID_LIGNE_IVALUA;
            EXCEPTION
                WHEN no_data_found THEN
                    v_LIGNE_ID:=0;
                    v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_027','ID_LIGNE_IVALUA',rec_cur_recept.ID_LIGNE_IVALUA);
                         --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                     DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                     'DKA_IPORECEPTION_IVALUA', --prog_name
                                                     'RECEPTION',               --source
                                                     'DKA_IPOREC_INTERFACE' ,   --table_name
                                                     rec_cur_recept.RECORD_ID,  --table_id
                                                     'ID_LIGNE_IVALUA',  --column_name
                                                     rec_cur_recept.ID_LIGNE_IVALUA, --column_value
                                                     'E',                       --message_type
                                                    v_message                   --message_text
                                                     );
                             v_flag_erreur := TRUE;

                     UPDATE DKA_IPOREC_INTERFACE
                      SET STATUT = 'REJECTED'
                        , request_id = g_request_id
                    WHERE CURRENT OF cur_recept;
                WHEN TOO_MANY_ROWS THEN
                    v_LIGNE_ID:=0;
                    v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_028','ID_LIGNE_IVALUA',rec_cur_recept.ID_LIGNE_IVALUA);
                    --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                    DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                    'DKA_IPORECEPTION_IVALUA', --prog_name
                                                    'RECEPTION',               --source
                                                    'DKA_IPOREC_INTERFACE' ,   --table_name
                                                    rec_cur_recept.RECORD_ID,  --table_id
                                                    'ID_LIGNE_IVALUA',  --column_name
                                                    rec_cur_recept.ID_LIGNE_IVALUA, --column_value
                                                    'E',                       --message_type
                                                   v_message                   --message_text
                                                    );
                    v_flag_erreur := TRUE;

                    UPDATE DKA_IPOREC_INTERFACE
                       SET STATUT = 'REJECTED'
                         , request_id = g_request_id
                     WHERE CURRENT OF cur_recept;
            END;
        END IF;

       IF (v_LIGNE_ID <> 0 AND v_CMD_ID <> 0) Then
          BEGIN
            select POLA.PO_LINE_id into v_LIGNE_ID
                from PO_HEADERS_ALL PHA,
                     PO_LINES_ALL POLA
               where PHA.po_header_id = v_CMD_ID
                -- and PHA.AUTHORIZATION_STATUS ='APPROVED'
                -- and PHA.CANCEL_FLAG <> 'Y'
                 --and nvl(PHA.CLOSED_CODE,'A') not in ('CLOSED','FINALLY CLOSED')
                 and PHA.PO_HEADER_ID  = POLA.PO_HEADER_ID
                 and POLA.ATTRIBUTE8=rec_cur_recept.ID_LIGNE_IVALUA;
          EXCEPTION
            WHEN others THEN
               v_LIGNE_ID:=0;
            END;
            IF v_LIGNE_ID = 0 then
               --v_LIGNE_ID := 0;
               v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_029','ID_LIGNE_IVALUA',rec_cur_recept.ID_LIGNE_IVALUA,'DOCUMENT_NUM',rec_cur_recept.DOCUMENT_NUM);
               --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                'DKA_IPORECEPTION_IVALUA', --prog_name
                                                'RECEPTION',               --source
                                                'DKA_IPOREC_INTERFACE' ,   --table_name
                                                rec_cur_recept.RECORD_ID,  --table_id
                                                'ID_LIGNE_IVALUA',  --column_name
                                                rec_cur_recept.ID_LIGNE_IVALUA, --column_value
                                                'E',                       --message_type
                                               v_message                   --message_text
                                                );
                   v_flag_erreur := TRUE;

                UPDATE DKA_IPOREC_INTERFACE
                 SET STATUT = 'REJECTED'
                   , request_id = g_request_id
               WHERE CURRENT OF cur_recept;
            END IF;
       END IF;


        IF v_LIGNE_ID <> 0 THEN
            BEGIN
                v_LIGNE_ID := 0;
                select POLA.PO_LINE_id, POLA.unit_meas_lookup_code  , PLLA.LINE_LOCATION_ID, PDA.PO_DISTRIBUTION_ID
                  into v_LIGNE_ID, V_UNIT_OF_MEASURE , v_LINE_LOCATION_ID, v_PO_DISTRIBUTION_ID
                  from PO_LINES_ALL POLA,
                       PO.PO_LINE_LOCATIONS_ALL PLLA ,
                       PO.PO_DISTRIBUTIONS_ALL PDA
                 where POLA.ATTRIBUTE8=rec_cur_recept.ID_LIGNE_IVALUA
                   and nvl(POLA.CLOSED_CODE,'A') not in ('FINALLY CLOSED') -- EDB262-C
                   and PLLA.LINE_LOCATION_ID = PDA.LINE_LOCATION_ID
                   and POLA.PO_LINE_ID = PDA.PO_LINE_ID
                  -- and PHA.PO_HEADER_ID = PDA.PO_HEADER_ID
                   and POLA.CANCEL_FLAG <> 'Y'
           ;

                   UPDATE DKA_IPOREC_INTERFACE
                   SET LIGNE_ID = v_LIGNE_ID
                     , UNIT_OF_MEASURE = V_UNIT_OF_MEASURE
                     , request_id = g_request_id
                     , LINE_LOCATION_ID = v_LINE_LOCATION_ID
                     , PO_DISTRIBUTION_ID = v_PO_DISTRIBUTION_ID
                 WHERE CURRENT OF cur_recept;
            EXCEPTION
                WHEN others THEN --< BNZ EDB375
                 /*   v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_030','ID_LIGNE_IVALUA',rec_cur_recept.ID_LIGNE_IVALUA);
                    --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                    DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                    'DKA_IPORECEPTION_IVALUA', --prog_name
                                                    'RECEPTION',               --source
                                                    'DKA_IPOREC_INTERFACE' ,   --table_name
                                                    rec_cur_recept.RECORD_ID,  --table_id
                                                    'ID_LIGNE_IVALUA',  --column_name
                                                    rec_cur_recept.ID_LIGNE_IVALUA, --column_value
                                                    'E',                       --message_type
                                                   v_message                   --message_text
                                                    );
                       v_flag_erreur := TRUE;

                    UPDATE DKA_IPOREC_INTERFACE
                       SET STATUT = 'REJECTED'
                         , request_id = g_request_id
                     WHERE CURRENT OF cur_recept;*/

        --< BNZ EDB375
  Begin --< BNZ KDFI-2547
              select POLA.PO_LINE_id, POLA.unit_meas_lookup_code  , PLLA.LINE_LOCATION_ID, PDA.PO_DISTRIBUTION_ID , POLA.PO_HEADER_ID
                  into v_LIGNE_ID, V_UNIT_OF_MEASURE , v_LINE_LOCATION_ID, v_PO_DISTRIBUTION_ID , v_CMD_ID
                  from PO_LINES_ALL POLA,
                       PO.PO_LINE_LOCATIONS_ALL PLLA ,
                       PO.PO_DISTRIBUTIONS_ALL PDA
                 where POLA.ATTRIBUTE8=rec_cur_recept.ID_LIGNE_IVALUA
                   and POLA.CLOSED_CODE in ('FINALLY CLOSED') -- EDB262-C
                   and PLLA.LINE_LOCATION_ID = PDA.LINE_LOCATION_ID
                   and POLA.PO_LINE_ID = PDA.PO_LINE_ID
                   --and PHA.PO_HEADER_ID = PDA.PO_HEADER_ID
                   and POLA.CANCEL_FLAG <> 'Y';


                   UPDATE DKA_IPOREC_INTERFACE
                   SET LIGNE_ID = v_LIGNE_ID
           , CMD_ID = v_CMD_ID
                     , UNIT_OF_MEASURE = V_UNIT_OF_MEASURE
                     , request_id = g_request_id
                     , LINE_LOCATION_ID = v_LINE_LOCATION_ID
                     , PO_DISTRIBUTION_ID = v_PO_DISTRIBUTION_ID
                 WHERE CURRENT OF cur_recept;


         INSERT INTO DKA.DKA_IPOREC_REJECT
        (
          ID_CMD,
          STATUT_CMD,
          NUM_CMD,
          BLOCAGE,
          ID_LIGNE,
          NEW_STATUT_CMD,
          RECEIPT_NUM,
          REQUEST_ID
        )
        select distinct dii.CMD_ID ID_CMD ,
              'FINALLY CLOSED' STATUT_CMD,
              dii.DOCUMENT_NUM NUM_CMD,
              'Line' BLOCAGE,
            dii.LIGNE_ID ID_LIGNE,
            NULL NEW_STATUT_CMD,
            dii.RECEIPT_NUM,
            dii.request_id REQUEST_ID
        from DKA_IPOREC_INTERFACE dii
      where dii.cmd_id = v_CMD_ID
      and dii.ligne_id = v_LIGNE_ID
      and dii.RECEIPT_NUM = rec_cur_recept.RECEIPT_NUM
      and dii.request_id = g_REQUEST_ID;

 EXCEPTION
                WHEN others THEN
                    v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_030','ID_LIGNE_IVALUA',rec_cur_recept.ID_LIGNE_IVALUA);
                    --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                    DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                    'DKA_IPORECEPTION_IVALUA', --prog_name
                                                    'RECEPTION',               --source
                                                    'DKA_IPOREC_INTERFACE' ,   --table_name
                                                    rec_cur_recept.RECORD_ID,  --table_id
                                                    'ID_LIGNE_IVALUA',  --column_name
                                                    rec_cur_recept.ID_LIGNE_IVALUA, --column_value
                                                    'E',                       --message_type
                                                   v_message                   --message_text
                                                    );
                       v_flag_erreur := TRUE;

                    UPDATE DKA_IPOREC_INTERFACE
                       SET STATUT = 'REJECTED'
                         , request_id = g_request_id
                     WHERE CURRENT OF cur_recept;
      END;--> BNZ KDFI-2547
        --> BNZ EDB375

            END;


      -- EDB262-C BEGIN
            IF rec_cur_recept.TRANSACTION_TYPE = 'RECEIVE' THEN
                BEGIN
          v_PO_VALIDE := 0;
         select POLA.PO_LINE_id
            into v_PO_VALIDE
            from PO_LINES_ALL POLA
           where POLA.ATTRIBUTE8=rec_cur_recept.ID_LIGNE_IVALUA
             and POLA.CANCEL_FLAG <> 'Y'; -- EDB262-C
        EXCEPTION
          WHEN OTHERS THEN
             v_PO_VALIDE := 0;
        END;

      END IF;


      IF  ((rec_cur_recept.TRANSACTION_TYPE = 'RECEIVE') and (v_PO_VALIDE <> 0) ) THEN
                BEGIN
          v_LIGNE_ID := 0;
          select POLA.PO_LINE_id, POLA.unit_meas_lookup_code  , PLLA.LINE_LOCATION_ID, PDA.PO_DISTRIBUTION_ID
            into v_LIGNE_ID, V_UNIT_OF_MEASURE , v_LINE_LOCATION_ID, v_PO_DISTRIBUTION_ID
            from PO_LINES_ALL POLA,
               PO.PO_LINE_LOCATIONS_ALL PLLA ,
               PO.PO_DISTRIBUTIONS_ALL PDA
           where POLA.ATTRIBUTE8=rec_cur_recept.ID_LIGNE_IVALUA
             and nvl(POLA.CLOSED_CODE,'A') not in ('CLOSED') -- EDB262-C
             and PLLA.LINE_LOCATION_ID = PDA.LINE_LOCATION_ID
             and POLA.PO_LINE_ID = PDA.PO_LINE_ID
             and POLA.CANCEL_FLAG <> 'Y'
             ;

             UPDATE DKA_IPOREC_INTERFACE
             SET LIGNE_ID = v_LIGNE_ID
             , UNIT_OF_MEASURE = V_UNIT_OF_MEASURE
             , request_id = g_request_id
             , LINE_LOCATION_ID = v_LINE_LOCATION_ID
             , PO_DISTRIBUTION_ID = v_PO_DISTRIBUTION_ID
           WHERE CURRENT OF cur_recept;
        EXCEPTION
          WHEN others THEN
             -- BNZ EDB388
         /*   v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_052','ID_LIGNE_IVALUA',rec_cur_recept.ID_LIGNE_IVALUA);
            --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
            DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                            'DKA_IPORECEPTION_IVALUA', --prog_name
                            'RECEPTION',               --source
                            'DKA_IPOREC_INTERFACE' ,   --table_name
                            rec_cur_recept.RECORD_ID,  --table_id
                            'ID_LIGNE_IVALUA',  --column_name
                            rec_cur_recept.ID_LIGNE_IVALUA, --column_value
                            'E',                       --message_type
                             v_message                   --message_text
                            );
               v_flag_erreur := TRUE;

            UPDATE DKA_IPOREC_INTERFACE
               SET STATUT = 'REJECTED'
               , request_id = g_request_id
             WHERE CURRENT OF cur_recept;
       */
       
  --< BNZ EDB388  
begin  
    select POLA.PO_LINE_id, POLA.unit_meas_lookup_code  , PLLA.LINE_LOCATION_ID, PDA.PO_DISTRIBUTION_ID
            into v_LIGNE_ID, V_UNIT_OF_MEASURE , v_LINE_LOCATION_ID, v_PO_DISTRIBUTION_ID
            from PO_LINES_ALL POLA,
               PO.PO_LINE_LOCATIONS_ALL PLLA ,
               PO.PO_DISTRIBUTIONS_ALL PDA
           where POLA.ATTRIBUTE8=rec_cur_recept.ID_LIGNE_IVALUA
             and nvl(POLA.CLOSED_CODE,'A') in ('CLOSED') -- EDB262-C
             and PLLA.LINE_LOCATION_ID = PDA.LINE_LOCATION_ID
             and POLA.PO_LINE_ID = PDA.PO_LINE_ID
             and POLA.CANCEL_FLAG <> 'Y'
             ;

             UPDATE DKA_IPOREC_INTERFACE
             SET LIGNE_ID = v_LIGNE_ID
             , UNIT_OF_MEASURE = V_UNIT_OF_MEASURE
             , request_id = g_request_id
             , LINE_LOCATION_ID = v_LINE_LOCATION_ID
             , PO_DISTRIBUTION_ID = v_PO_DISTRIBUTION_ID
           WHERE CURRENT OF cur_recept;  
       
       
    INSERT INTO DKA.DKA_IPOREC_REJECT
        (
          ID_CMD,
          STATUT_CMD,
          NUM_CMD,
          BLOCAGE,
          ID_LIGNE,
          NEW_STATUT_CMD,
          RECEIPT_NUM,
          REQUEST_ID
        )
        select distinct dii.CMD_ID ID_CMD ,
              'CLOSED' STATUT_CMD,
              dii.DOCUMENT_NUM NUM_CMD,
              'Line' BLOCAGE,
            dii.LIGNE_ID ID_LIGNE,
            NULL NEW_STATUT_CMD,
            dii.RECEIPT_NUM,
            dii.request_id REQUEST_ID
        from DKA_IPOREC_INTERFACE dii
      where dii.cmd_id = v_CMD_ID
      and dii.ligne_id = v_LIGNE_ID
      and dii.RECEIPT_NUM = rec_cur_recept.RECEIPT_NUM
      and dii.request_id = g_REQUEST_ID;

               
        EXCEPTION
          WHEN others THEN
             -- BNZ EDB388
           v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_052','ID_LIGNE_IVALUA',rec_cur_recept.ID_LIGNE_IVALUA);
            --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
            DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                            'DKA_IPORECEPTION_IVALUA', --prog_name
                            'RECEPTION',               --source
                            'DKA_IPOREC_INTERFACE' ,   --table_name
                            rec_cur_recept.RECORD_ID,  --table_id
                            'ID_LIGNE_IVALUA',  --column_name
                            rec_cur_recept.ID_LIGNE_IVALUA, --column_value
                            'E',                       --message_type
                             v_message                   --message_text
                            );
               v_flag_erreur := TRUE;

            UPDATE DKA_IPOREC_INTERFACE
               SET STATUT = 'REJECTED'
               , request_id = g_request_id
             WHERE CURRENT OF cur_recept;
     END;
        --> BNZ EDB388
        END;
      END IF;
      -- EDB262-C FIN
      /*
      -- EDB301 BEGIN
      IF  ((rec_cur_recept.TRANSACTION_TYPE = 'RECEIVE') and (v_PO_VALIDE <> 0) and (v_add <> 0)) THEN
                BEGIN
          v_LIGNE_ID := 0;
          select POLA.PO_LINE_id, POLA.unit_meas_lookup_code  , PLLA.LINE_LOCATION_ID, PDA.PO_DISTRIBUTION_ID
            into v_LIGNE_ID, V_UNIT_OF_MEASURE , v_LINE_LOCATION_ID, v_PO_DISTRIBUTION_ID
            from PO_LINES_ALL POLA,
               PO.PO_LINE_LOCATIONS_ALL PLLA ,
               PO.PO_DISTRIBUTIONS_ALL PDA
           where POLA.ATTRIBUTE8=rec_cur_recept.ID_LIGNE_IVALUA
             and ( nvl(POLA.CLOSED_CODE,'A') <> 'CLOSED' and PLLA.CLOSED_CODE <> 'CLOSED FOR RECEIVING')
             and PLLA.LINE_LOCATION_ID = PDA.LINE_LOCATION_ID
             and POLA.PO_LINE_ID = PDA.PO_LINE_ID
             and POLA.CANCEL_FLAG <> 'Y'
             ;

             UPDATE DKA_IPOREC_INTERFACE
             SET LIGNE_ID = v_LIGNE_ID
             , UNIT_OF_MEASURE = V_UNIT_OF_MEASURE
             , request_id = g_request_id
             , LINE_LOCATION_ID = v_LINE_LOCATION_ID
             , PO_DISTRIBUTION_ID = v_PO_DISTRIBUTION_ID
           WHERE CURRENT OF cur_recept;
        EXCEPTION
          WHEN others THEN
            v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_053','ID_IVALUA',rec_cur_recept.ID_LIGNE_IVALUA, 'DOCUMENT_NUM',rec_cur_recept.DOCUMENT_NUM);
            --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
            DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                            'DKA_IPORECEPTION_IVALUA', --prog_name
                            'RECEPTION',               --source
                            'DKA_IPOREC_INTERFACE' ,   --table_name
                            rec_cur_recept.RECORD_ID,  --table_id
                            'ID_LIGNE_IVALUA',  --column_name
                            rec_cur_recept.ID_LIGNE_IVALUA, --column_value
                            'W',                       --message_type
                             v_message                   --message_text
                            );
               v_flag_erreur := TRUE;

            UPDATE DKA_IPOREC_INTERFACE
               SET STATUT = 'WARNING'
               , request_id = g_request_id
             WHERE CURRENT OF cur_recept;
        END;
      END IF;
      -- FIN EDB301
      */
        END IF;

        -- RG412
        IF rec_cur_recept.quantity is NULL THEN
            v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_031');
            --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
            DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                            'DKA_IPORECEPTION_IVALUA', --prog_name
                                            'RECEPTION',               --source
                                            'DKA_IPOREC_INTERFACE' ,   --table_name
                                            rec_cur_recept.RECORD_ID,  --table_id
                                            'QUANTITY',  --column_name
                                            rec_cur_recept.quantity, --column_value
                                            'E',                       --message_type
                                           v_message                   --message_text
                                            );
            v_flag_erreur := TRUE;

            UPDATE DKA_IPOREC_INTERFACE
               SET STATUT = 'REJECTED'
                 , request_id = g_request_id
             WHERE CURRENT OF cur_recept;
        ELSIF rec_cur_recept.QUANTITY*100000 != ROUND(rec_cur_recept.QUANTITY*100000,0) THEN
            v_message :='La quantitÃ¿Â© '||rec_cur_recept.QUANTITY||' Ã¿Â  plus de cinq dÃ¿Â©cimales';
            --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
            DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                            'DKA_IPORECEPTION_IVALUA', --prog_name
                                            'RECEPTION',               --source
                                            'DKA_IPOREC_INTERFACE' ,   --table_name
                                            rec_cur_recept.RECORD_ID,  --table_id
                                            'QUANTITY',  --column_name
                                            rec_cur_recept.quantity, --column_value
                                            'E',                       --message_type
                                           v_message                   --message_text
                                            );
            v_flag_erreur := TRUE;

            UPDATE DKA_IPOREC_INTERFACE
               SET STATUT = 'REJECTED'
                 , request_id = g_request_id
             WHERE CURRENT OF cur_recept;
        ELSIF ((rec_cur_recept.quantity < 0) and (rec_cur_recept.TRANSACTION_TYPE = 'RECEIVE')) THEN
            v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_032','QUANTITY',rec_cur_recept.quantity,'TRANSACTION_TYPE',rec_cur_recept.TRANSACTION_TYPE );
            --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
            DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                            'DKA_IPORECEPTION_IVALUA', --prog_name
                                            'RECEPTION',               --source
                                            'DKA_IPOREC_INTERFACE' ,   --table_name
                                            rec_cur_recept.RECORD_ID,  --table_id
                                            'QUANTITY',  --column_name
                                            rec_cur_recept.QUANTITY, --column_value
                                            'E',                       --message_type
                                           v_message                   --message_text
                                            );
                v_flag_erreur := TRUE;

            UPDATE DKA_IPOREC_INTERFACE
               SET STATUT = 'REJECTED'
                 , request_id = g_request_id
             WHERE CURRENT OF cur_recept;
        ELSIF ((rec_cur_recept.quantity >= 0) and (rec_cur_recept.TRANSACTION_TYPE = 'CORRECT')) THEN
            v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_033','QUANTITY',rec_cur_recept.quantity,'TRANSACTION_TYPE',rec_cur_recept.TRANSACTION_TYPE);
            --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
            DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                            'DKA_IPORECEPTION_IVALUA', --prog_name
                                            'RECEPTION',               --source
                                            'DKA_IPOREC_INTERFACE' ,   --table_name
                                            rec_cur_recept.RECORD_ID,  --table_id
                                            'QUANTITY',  --column_name
                                            rec_cur_recept.QUANTITY, --column_value
                                            'E',                       --message_type
                                           v_message                   --message_text
                                            );
                v_flag_erreur := TRUE;

            UPDATE DKA_IPOREC_INTERFACE
               SET STATUT = 'REJECTED'
                 , request_id = g_request_id
             WHERE CURRENT OF cur_recept;
        END IF;
              --  Fnd_File.put_line (Fnd_File.OUTPUT, '====> ERREUR : 'rec_cur_recept.QUANTITY*100000||'  '|| ROUND(rec_cur_recept.QUANTITY*100000,0));
        -- RG413
        IF rec_cur_recept.FLAG_REC_FINALE IS NULL THEN
            v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_034');
            --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
            DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                            'DKA_IPORECEPTION_IVALUA', --prog_name
                                            'RECEPTION',               --source
                                            'DKA_IPOREC_INTERFACE' ,   --table_name
                                            rec_cur_recept.RECORD_ID,  --table_id
                                            'FLAG_REC_FINALE',  --column_name
                                            rec_cur_recept.FLAG_REC_FINALE, --column_value
                                            'E',                       --message_type
                                           v_message                   --message_text
                                            );
                v_flag_erreur := TRUE;

            UPDATE DKA_IPOREC_INTERFACE
               SET STATUT = 'REJECTED'
                 , request_id = g_request_id
             WHERE CURRENT OF cur_recept;

        ELSE
            IF rec_cur_recept.FLAG_REC_FINALE not in ('Y','N') THEN
                v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_035', 'FLAG_REC_FINALE',rec_cur_recept.FLAG_REC_FINALE);
                --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                'DKA_IPORECEPTION_IVALUA', --prog_name
                                                'RECEPTION',               --source
                                                'DKA_IPOREC_INTERFACE' ,   --table_name
                                                rec_cur_recept.RECORD_ID,  --table_id
                                                'FLAG_REC_FINALE',  --column_name
                                                rec_cur_recept.FLAG_REC_FINALE, --column_value
                                                'E',                       --message_type
                                               v_message                   --message_text
                                                );
                    v_flag_erreur := TRUE;

                UPDATE DKA_IPOREC_INTERFACE
                   SET STATUT = 'REJECTED'
                     , request_id = g_request_id
                 WHERE CURRENT OF cur_recept;
            END IF;
        END IF;
        -- RG416


        IF rec_cur_recept.ID_MVT_REC IS NULL THEN
            v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_044');
            --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
            DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                            'DKA_IPORECEPTION_IVALUA', --prog_name
                                            'RECEPTION',               --source
                                            'DKA_IPOREC_INTERFACE' ,   --table_name
                                            rec_cur_recept.RECORD_ID,  --table_id
                                            'ID_MVT_REC',  --column_name
                                            rec_cur_recept.ID_MVT_REC, --column_value
                                            'E',                       --message_type
                                           v_message                   --message_text
                                            );
                v_flag_erreur := TRUE;

            UPDATE DKA_IPOREC_INTERFACE
               SET STATUT = 'REJECTED'
                 , request_id = g_request_id
             WHERE CURRENT OF cur_recept;

        ELSE
            BEGIN
      v_ID_MVT_REC :=0;
      select distinct 1 into v_ID_MVT_REC
        from DKA_IPOREC_INTERFACE
       where ID_MVT_REC = rec_cur_recept.ID_MVT_REC
         and record_id <> rec_cur_recept.record_id
        -- and file_name = rec_cur_recept.file_name
         and STATUT <> 'WARNING' --KDFI-1454
         ;
      EXCEPTION
      WHEN OTHERS THEN
          NULL;
      END;
      IF v_ID_MVT_REC = 1 then
          v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_045', 'ID_MVT_REC',rec_cur_recept.ID_MVT_REC);
                --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                'DKA_IPORECEPTION_IVALUA', --prog_name
                                                'RECEPTION',               --source
                                                'DKA_IPOREC_INTERFACE' ,   --table_name
                                                rec_cur_recept.RECORD_ID,  --table_id
                                                'ID_MVT_REC',  --column_name
                                                rec_cur_recept.ID_MVT_REC, --column_value
                                                'W',                       --message_type -- EDB301
                                               v_message                   --message_text
                                                );
                    v_flag_erreur := TRUE;
                    v_flag_warning := 1;  -- EDB301
                UPDATE DKA_IPOREC_INTERFACE
                   SET STATUT = 'WARNING'   -- EDB301
                     , request_id = g_request_id
                 WHERE CURRENT OF cur_recept;
            END IF;
      BEGIN
          v_ID_MVT_REC :=0;
          select distinct 1 into v_ID_MVT_REC
            from RCV_TRANSACTIONS
           where ATTRIBUTE2 = rec_cur_recept.ID_MVT_REC;
      EXCEPTION
      WHEN OTHERS THEN
          NULL;
      END;
      IF v_ID_MVT_REC = 1 then
          v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_046', 'ID_MVT_REC',rec_cur_recept.ID_MVT_REC);
                --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                'DKA_IPORECEPTION_IVALUA', --prog_name
                                                'RECEPTION',               --source
                                                'DKA_IPOREC_INTERFACE' ,   --table_name
                                                rec_cur_recept.RECORD_ID,  --table_id
                                                'ID_MVT_REC',  --column_name
                                                rec_cur_recept.ID_MVT_REC, --column_value
                                                'W',                       --message_type -- EDB301
                                               v_message                   --message_text
                                                );
                v_flag_erreur := TRUE;
                v_flag_warning := 1;  -- EDB301

                UPDATE DKA_IPOREC_INTERFACE
                   SET STATUT = 'WARNING'   -- EDB301
                     , request_id = g_request_id
                 WHERE CURRENT OF cur_recept;
            END IF;
        END IF;




  IF  (rec_cur_recept.TRANSACTION_TYPE = 'CORRECT') THEN
        IF (rec_cur_recept.ID_MVT_ORIGINE is null) THEN
            v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_047');
            --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
            DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                            'DKA_IPORECEPTION_IVALUA', --prog_name
                                            'RECEPTION',               --source
                                            'DKA_IPOREC_INTERFACE' ,   --table_name
                                            rec_cur_recept.RECORD_ID,  --table_id
                                            'ID_MVT_ORIGINE',  --column_name
                                            rec_cur_recept.ID_MVT_ORIGINE, --column_value
                                            'E',                       --message_type
                                           v_message                   --message_text
                                            );
                v_flag_erreur := TRUE;
            if v_flag_warning <> 1 then
        UPDATE DKA_IPOREC_INTERFACE
           SET STATUT = 'REJECTED'
           , request_id = g_request_id
         WHERE CURRENT OF cur_recept;
      end if;

        ELSE
      BEGIN
          v_ID_MVT_ORIGINE :=0;
          select distinct 1 into v_ID_MVT_ORIGINE
            from RCV_TRANSACTIONS
           where ATTRIBUTE2 = rec_cur_recept.ID_MVT_ORIGINE;
      EXCEPTION
      WHEN OTHERS THEN
          v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_048', 'ID_MVT_ORIGINE',rec_cur_recept.ID_MVT_ORIGINE);
                --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                'DKA_IPORECEPTION_IVALUA', --prog_name
                                                'RECEPTION',               --source
                                                'DKA_IPOREC_INTERFACE' ,   --table_name
                                                rec_cur_recept.RECORD_ID,  --table_id
                                                'ID_MVT_ORIGINE',  --column_name
                                                rec_cur_recept.ID_MVT_ORIGINE, --column_value
                                                'E',                       --message_type
                                               v_message                   --message_text
                                                );
                    v_flag_erreur := TRUE;

        if v_flag_warning <> 1 then
          UPDATE DKA_IPOREC_INTERFACE
             SET STATUT = 'REJECTED'
             , request_id = g_request_id
           WHERE CURRENT OF cur_recept;
        end if;
            END;


      IF (v_ID_MVT_ORIGINE = 1) and (rec_cur_recept.receipt_num is not NULL) THEN
          BEGIN
            v_ID_MVT_ORIGINE_REC :=0;
                    SELECT  1
                      into v_ID_MVT_ORIGINE_REC
                      FROM rcv_shipment_headers rsh
                         , rcv_shipment_lines rsl
             , RCV_TRANSACTIONS RCT
                     WHERE rsl.shipment_header_id = rsh.shipment_header_id
                       AND rsh.receipt_num <> rec_cur_recept.receipt_num
             AND rct.shipment_header_id = rsh.shipment_header_id
                       AND rct.shipment_line_id = rsl.shipment_line_id
               AND rct.ATTRIBUTE2 = rec_cur_recept.ID_MVT_ORIGINE;

                EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;
          IF v_ID_MVT_ORIGINE_REC = 1 then
              v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_049', 'ID_MVT_ORIGINE',rec_cur_recept.ID_MVT_ORIGINE, 'REC' ,rec_cur_recept.receipt_num);
                    --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                    DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                    'DKA_IPORECEPTION_IVALUA', --prog_name
                                                    'RECEPTION',               --source
                                                    'DKA_IPOREC_INTERFACE' ,   --table_name
                                                    rec_cur_recept.RECORD_ID,  --table_id
                                                    'ID_MVT_ORIGINE',  --column_name
                                                    rec_cur_recept.ID_MVT_ORIGINE, --column_value
                                                    'E',                       --message_type
                                                   v_message                   --message_text
                                                    );
                        v_flag_erreur := TRUE;

          if v_flag_warning <> 1 then
            UPDATE DKA_IPOREC_INTERFACE
               SET STATUT = 'REJECTED'
               , request_id = g_request_id
             WHERE CURRENT OF cur_recept;
          end if;
                END IF;
      END IF;

            IF (v_ID_MVT_ORIGINE = 1) and (v_ID_MVT_ORIGINE_REC = 0) THEN
          BEGIN
              v_ID_MVT_ORIGINE_LIG :=0;

          SELECT 1
                      into v_ID_MVT_ORIGINE_LIG
                      FROM rcv_shipment_headers rsh
                         , rcv_shipment_lines rsl
                         , rcv_transactions rct
                         , po_headers_all poh
                         , po_lines_all pol
                     WHERE 1=1
                       AND poh.po_header_id = pol.po_header_id
                       AND poh.po_header_id = rsl.po_header_id
                       AND rsl.shipment_header_id = rsh.shipment_header_id
                       AND rct.po_header_id = poh.po_header_id
                       AND rct.po_line_id = pol.po_line_id
                       AND rct.shipment_header_id = rsh.shipment_header_id
                       AND rct.shipment_line_id = rsl.shipment_line_id
                       AND rsh.receipt_num = rec_cur_recept.receipt_num
                       AND rct.DESTINATION_TYPE_CODE ='EXPENSE'
                       AND pol.ATTRIBUTE8 <> rec_cur_recept.ID_LIGNE_IVALUA
             AND rct.ATTRIBUTE2 = rec_cur_recept.ID_MVT_ORIGINE
                       AND rsh.vendor_id = v_vendor_id
                       AND rsh.vendor_site_id = v_vendor_site_id
                       AND rsh.ship_to_Org_Id = v_org_id;


                EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;
          IF v_ID_MVT_ORIGINE_LIG = 1 then
              v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_050', 'ID_MVT_ORIGINE',rec_cur_recept.ID_MVT_ORIGINE, 'ID_IVALUA' ,rec_cur_recept.ID_LIGNE_IVALUA);
                    --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                    DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                    'DKA_IPORECEPTION_IVALUA', --prog_name
                                                    'RECEPTION',               --source
                                                    'DKA_IPOREC_INTERFACE' ,   --table_name
                                                    rec_cur_recept.RECORD_ID,  --table_id
                                                    'ID_MVT_ORIGINE',  --column_name
                                                    rec_cur_recept.ID_MVT_ORIGINE, --column_value
                                                    'E',                       --message_type
                                                   v_message                   --message_text
                                                    );
                        v_flag_erreur := TRUE;

            if v_flag_warning <> 1 then
              UPDATE DKA_IPOREC_INTERFACE
                 SET STATUT = 'REJECTED'
                 , request_id = g_request_id
               WHERE CURRENT OF cur_recept;
            end if;
                END IF;
      END IF;

        END IF;
  END IF;

        BEGIN
            vs_ship_to_Org_Id := 0;
            vs_vendor_id := 0;
            vs_vendor_site_id := 0;
            vs_packing_slip := null;
            V_SHIPMENT_HEADER_ID := 0;
            select SHIPMENT_HEADER_ID, ship_to_Org_Id, vendor_id, vendor_site_id, rsh.packing_slip
              into V_SHIPMENT_HEADER_ID, vs_ship_to_Org_Id, vs_vendor_id, vs_vendor_site_id, vs_packing_slip
              from rcv_shipment_headers rsh
             where rsh.receipt_num = rec_cur_recept.receipt_num
         ;
        EXCEPTION
          WHEN OTHERS THEN
               null;
        END;
        IF V_SHIPMENT_HEADER_ID <>0 THEN
            IF ((vs_ship_to_Org_Id <> v_org_id) and rec_cur_recept.org IS NOT NULL)  THEN
                v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_037','ORG',rec_cur_recept.ORG);
                --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                'DKA_IPORECEPTION_IVALUA', --prog_name
                                                'RECEPTION',               --source
                                                'DKA_IPOREC_INTERFACE' ,   --table_name
                                                rec_cur_recept.RECORD_ID,  --table_id
                                                'RECEIPT_NUM',  --column_name
                                                rec_cur_recept.receipt_num, --column_value
                                                'E',                       --message_type
                                               v_message                   --message_text
                                                );
                v_flag_erreur := TRUE;

        if v_flag_warning <> 1 then
          UPDATE DKA_IPOREC_INTERFACE
             SET STATUT = 'REJECTED'
             , request_id = g_request_id
           WHERE CURRENT OF cur_recept;
        end if;

            END IF;

            IF ((vs_vendor_id <> v_vendor_id) and (v_vendor_id <> 0)) THEN
                v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_038','VENDOR_NUM',rec_cur_recept.vendor_num);
                --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                'DKA_IPORECEPTION_IVALUA', --prog_name
                                                'RECEPTION',               --source
                                                'DKA_IPOREC_INTERFACE' ,   --table_name
                                                rec_cur_recept.RECORD_ID,  --table_id
                                                'RECEIPT_NUM',  --column_name
                                                rec_cur_recept.receipt_num, --column_value
                                                'E',                       --message_type
                                               v_message                   --message_text
                                                );
                v_flag_erreur := TRUE;

        if v_flag_warning <> 1 then
          UPDATE DKA_IPOREC_INTERFACE
             SET STATUT = 'REJECTED'
             , request_id = g_request_id
           WHERE CURRENT OF cur_recept;
        end if;

            END IF;

            IF ((vs_vendor_site_id <> v_vendor_site_id) and (v_vendor_site_id <> 0 ) and (vs_ship_to_Org_Id = v_org_id)) THEN
                v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_039','ID_SITE_IVALUA',rec_cur_recept.ID_SITE_IVALUA);
                --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                'DKA_IPORECEPTION_IVALUA', --prog_name
                                                'RECEPTION',               --source
                                                'DKA_IPOREC_INTERFACE' ,   --table_name
                                                rec_cur_recept.RECORD_ID,  --table_id
                                                'RECEIPT_NUM',  --column_name
                                                rec_cur_recept.receipt_num, --column_value
                                                'E',                       --message_type
                                               v_message                   --message_text
                                                );
                v_flag_erreur := TRUE;

        if v_flag_warning <> 1 then
          UPDATE DKA_IPOREC_INTERFACE
             SET STATUT = 'REJECTED'
             , request_id = g_request_id
           WHERE CURRENT OF cur_recept;
        end if;
            END IF;

            IF nvl(vs_packing_slip,'*') <> nvl(rec_cur_recept.BORDEREAU_NUM,'*')  THEN

                v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_040','BORDEREAU_NUM',rec_cur_recept.BORDEREAU_NUM);
                --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                'DKA_IPORECEPTION_IVALUA', --prog_name
                                                'RECEPTION',               --source
                                                'DKA_IPOREC_INTERFACE' ,   --table_name
                                                rec_cur_recept.RECORD_ID,  --table_id
                                                'RECEIPT_NUM',  --column_name
                                                rec_cur_recept.receipt_num, --column_value
                                                'E',                       --message_type
                                               v_message                   --message_text
                                                );
                    v_flag_erreur := TRUE;

        if v_flag_warning <> 1 then
          UPDATE DKA_IPOREC_INTERFACE
             SET STATUT = 'REJECTED'
             , request_id = g_request_id
           WHERE CURRENT OF cur_recept;
        end if;

            END IF;

            IF ( (vs_ship_to_Org_Id = v_org_id) and (vs_vendor_id = v_vendor_id) and (vs_vendor_site_id = v_vendor_site_id) and (nvl(vs_packing_slip,'*') = nvl(rec_cur_recept.BORDEREAU_NUM,'*')) ) THEN
               UPDATE DKA_IPOREC_INTERFACE
                 SET SHIPMENT_HEADER_ID = v_SHIPMENT_HEADER_ID
                   , request_id = g_request_id
               WHERE CURRENT OF cur_recept;
            END IF;

        END IF;

        -- RG417
        IF (rec_cur_recept.TRANSACTION_TYPE ='CORRECT' AND rec_cur_recept.ID_MVT_ORIGINE is not null AND rec_cur_recept.receipt_num IS NOT NULL AND (vs_ship_to_Org_Id = v_org_id) and (vs_vendor_id = v_vendor_id) and (vs_vendor_site_id = v_vendor_site_id) and (nvl(vs_packing_slip,'*') = nvl(rec_cur_recept.BORDEREAU_NUM,'*')))
        THEN
            BEGIN
                 v_rct_quantity :=0;
                SELECT  rsl.QUANTITY_RECEIVED , rct.shipment_line_id, rct.TRANSACTION_ID , rct.PARENT_TRANSACTION_ID
                  into v_rct_quantity, v_shipment_line_id, v_TRANSACTION_ID , v_PARENT_TRANSACTION_ID
                  FROM rcv_shipment_headers rsh
                     , rcv_shipment_lines rsl
                     , rcv_transactions rct
                     , po_headers_all poh
                     , po_lines_all pol
                 WHERE 1=1
                   AND poh.po_header_id = pol.po_header_id
                   AND poh.po_header_id = rsl.po_header_id
                   AND rsl.shipment_header_id = rsh.shipment_header_id
                   AND rct.po_header_id = poh.po_header_id
                   AND rct.po_line_id = pol.po_line_id
                   AND rct.shipment_header_id = rsh.shipment_header_id
                   AND rct.shipment_line_id = rsl.shipment_line_id
                   AND rsh.receipt_num = rec_cur_recept.receipt_num
                   AND rct.DESTINATION_TYPE_CODE ='EXPENSE'
                   AND pol.ATTRIBUTE8=rec_cur_recept.ID_LIGNE_IVALUA
           AND rct.attribute2= rec_cur_recept.ID_MVT_ORIGINE
                   AND rsh.vendor_id = v_vendor_id
                   AND rsh.vendor_site_id = v_vendor_site_id
                   AND rsh.ship_to_Org_Id = v_org_id
                   AND nvl(rsh.packing_slip,'*') = nvl(rec_cur_recept.BORDEREAU_NUM,'*');
                IF  (v_rct_quantity < abs(rec_cur_recept.quantity)) THEN
                    v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_041','QUANTITY',rec_cur_recept.quantity);
                    --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                    DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                    'DKA_IPORECEPTION_IVALUA', --prog_name
                                                    'RECEPTION',               --source
                                                    'DKA_IPOREC_INTERFACE' ,   --table_name
                                                    rec_cur_recept.RECORD_ID,  --table_id
                                                    'QUANTITY',  --column_name
                                                    rec_cur_recept.quantity, --column_value
                                                    'E',                       --message_type
                                                   v_message                   --message_text
                                                    );
                            v_flag_erreur := TRUE;

          if v_flag_warning <> 1 then
            UPDATE DKA_IPOREC_INTERFACE
               SET STATUT = 'REJECTED'
               , request_id = g_request_id
             WHERE CURRENT OF cur_recept;
          end if;
                ELSE
                    UPDATE DKA_IPOREC_INTERFACE
                     SET shipment_line_id = v_shipment_line_id
                       , TRANSACTION_ID   = v_TRANSACTION_ID
                       , PARENT_TRANSACTION_ID = v_PARENT_TRANSACTION_ID
                       , vendor_id = v_vendor_id
                       , ORG_ID = v_org_id
                       , VENDOR_SITE_ID = v_vendor_site_id
                       , request_id = g_request_id
                     --  , STATUT = 'VALIDATED'
                   WHERE CURRENT OF cur_recept;
                END IF;
            EXCEPTION
                WHEN no_data_found THEN
                    v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_042','RECEIPT_NUM',rec_cur_recept.receipt_num,'ID_MVT_ORIGINE',rec_cur_recept.ID_MVT_ORIGINE,'ID_LIGNE_IVALUA',rec_cur_recept.ID_LIGNE_IVALUA);
                    --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                    DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                    'DKA_IPORECEPTION_IVALUA', --prog_name
                                                    'RECEPTION',               --source
                                                    'DKA_IPOREC_INTERFACE' ,   --table_name
                                                    rec_cur_recept.RECORD_ID,  --table_id
                                                    'QUANTITY',  --column_name
                                                    rec_cur_recept.QUANTITY, --column_value
                                                    'E',                       --message_type
                                                   v_message                   --message_text
                                                    );
                        v_flag_erreur := TRUE;

          if v_flag_warning <> 1 then
            UPDATE DKA_IPOREC_INTERFACE
               SET STATUT = 'REJECTED'
               , request_id = g_request_id
             WHERE CURRENT OF cur_recept;
          end if;
                WHEN TOO_MANY_ROWS THEN

                            v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_043','REC_NUM',rec_cur_recept.receipt_num,'ID_MVT_ORIGINE',rec_cur_recept.ID_MVT_ORIGINE,'ID_IVALUA',rec_cur_recept.ID_LIGNE_IVALUA);
                            --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                            DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                            'DKA_IPORECEPTION_IVALUA', --prog_name
                                                            'RECEPTION',               --source
                                                            'DKA_IPOREC_INTERFACE' ,   --table_name
                                                            rec_cur_recept.RECORD_ID,  --table_id
                                                            'QUANTITY',  --column_name
                                                            rec_cur_recept.QUANTITY, --column_value
                                                            'E',                       --message_type
                                                            v_message                   --message_text
                                                            );
                            v_flag_erreur := TRUE;

              if v_flag_warning <> 1 then
                UPDATE DKA_IPOREC_INTERFACE
                   SET STATUT = 'REJECTED'
                   , request_id = g_request_id
                 WHERE CURRENT OF cur_recept;
              end if;

            END;
        END IF;
        IF NOT v_flag_erreur THEN
            UPDATE DKA_IPOREC_INTERFACE
               SET STATUT = 'VALIDATED'
                 , request_id = g_request_id
             WHERE CURRENT OF cur_recept;
        END IF ;
    EXCEPTION
        WHEN others THEN
            fnd_file.put_line(fnd_file.log,
                              'VALIDATION RECEPTION IMPOSSIBLE||' || rec_cur_recept.RECEIPT_NUM || '| erreur: ' || sqlerrm);

            ROLLBACK;

            if v_flag_warning <> 1 then
        UPDATE DKA_IPOREC_INTERFACE
           SET STATUT = 'REJECTED'
           , request_id = g_request_id
         WHERE CURRENT OF cur_recept;
      end if;
    END;
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
                      'Fin de la procÃ¿Â©dure validate_data_group : EXCEPTION OTHERS ');
END validate_data_group;


 /*
 *************************************************************************
 * PROCEDURE NAME : validate_data
 *
 * DESCRIPTION
 *  ProcÃ¿Â©dure d'insertion dans les tables finales
 *
 * PARAMETERS
 * ==========
 * NAME               DESCRIPTION
.* -----------------  ------------------------------------------------------
 * p_errbuf          Retour de message Ã¿Â©ventuel
 * p_retcode         Statut du traitement en sortie
 *
 ************************************************************************
 */
--------------------------------------------------------------------------------------
PROCEDURE validate_data(p_Errbuf OUT VARCHAR2, p_retcode OUT NUMBER, rec_type varchar2) IS

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
      FROM dka.DKA_IPOREC_INTERFACE dii
     WHERE 1 = 1
      -- AND load_request_id = DECODE(g_loader_request_id, -1, load_request_id, g_loader_request_id) --
      -- AND flag = '-1' --
       AND TRANSACTION_TYPE in ('RECEIVE')
       AND STATUT  in ('NEW','REJECTED','REJECTED_OI')
     AND not exists (select distinct 1 from RCV_SHIPMENT_HEADERS rsh where rsh.receipt_num = dii.RECEIPT_NUM and rownum<2)
     ORDER BY RECEIPT_NUM, record_id -- SOCIETE, REGION  ajout
    --   FOR UPDATE OF STATUT, shipment_line_id, TRANSACTION_ID , PARENT_TRANSACTION_ID, vendor_id, ORG_ID  , VENDOR_SITE_ID, request_id       --, ORG_ID, CODE_SITE_FOUR --
       ;

/*
  CURSOR cur_recept_cor IS
    SELECT *
      FROM dka.DKA_IPOREC_INTERFACE
     WHERE 1 = 1
      -- AND load_request_id = DECODE(g_loader_request_id, -1, load_request_id, g_loader_request_id) --
      -- AND flag = '-1' --
       AND TRANSACTION_TYPE in ('CORRECT')
       AND STATUT  in ('NEW','REJECTED','REJECTED_OI')
     ORDER BY RECEIPT_NUM, record_id -- SOCIETE, REGION  ajout
     --  FOR UPDATE OF STATUT, shipment_line_id, TRANSACTION_ID , PARENT_TRANSACTION_ID, vendor_id, ORG_ID  , VENDOR_SITE_ID, request_id       --, ORG_ID, CODE_SITE_FOUR --
       ;
*/
  CURSOR cur_recept_cor_add IS
    SELECT *
      FROM dka.DKA_IPOREC_INTERFACE dii
     WHERE 1 = 1
      -- AND load_request_id = DECODE(g_loader_request_id, -1, load_request_id, g_loader_request_id) --
      -- AND flag = '-1' --
       -- AND TRANSACTION_TYPE in ('RECEIVE')
       AND STATUT  in ('NEW','REJECTED','REJECTED_OI')
     AND (exists (select distinct 1 from RCV_SHIPMENT_HEADERS rsh where rsh.receipt_num = dii.RECEIPT_NUM and rownum<2)
           OR
        TRANSACTION_TYPE in ('CORRECT')
       )
     ORDER BY RECEIPT_NUM, record_id -- SOCIETE, REGION  ajout
    --   FOR UPDATE OF STATUT, shipment_line_id, TRANSACTION_ID , PARENT_TRANSACTION_ID, vendor_id, ORG_ID  , VENDOR_SITE_ID, request_id       --, ORG_ID, CODE_SITE_FOUR --
       ;

 CURSOR cur_recept IS
    SELECT *
      FROM dka.DKA_IPOREC_INTERFACE dii
     WHERE 1 = 1
      -- AND load_request_id = DECODE(g_loader_request_id, -1, load_request_id, g_loader_request_id) --
      -- AND flag = '-1' --
       AND TRANSACTION_TYPE in ('RECEIVE')
     ORDER BY RECEIPT_NUM, record_id -- SOCIETE, REGION  ajout
       FOR UPDATE OF STATUT, request_id      --, shipment_line_id, TRANSACTION_ID , PARENT_TRANSACTION_ID, vendor_id, ORG_ID  , VENDOR_SITE_ID,   --, ORG_ID, CODE_SITE_FOUR --
       ;

 CURSOR cur_recept_ERR_TYPE IS
    SELECT *
      FROM dka.DKA_IPOREC_INTERFACE dii
     WHERE 1 = 1
      -- AND load_request_id = DECODE(g_loader_request_id, -1, load_request_id, g_loader_request_id) --
      -- AND flag = '-1' --
       AND nvl(TRANSACTION_TYPE,'A') not in ('RECEIVE', 'CORRECT')
     ORDER BY RECEIPT_NUM, record_id -- SOCIETE, REGION  ajout
       FOR UPDATE OF STATUT, request_id      --, shipment_line_id, TRANSACTION_ID , PARENT_TRANSACTION_ID, vendor_id, ORG_ID  , VENDOR_SITE_ID,   --, ORG_ID, CODE_SITE_FOUR --
       ;
BEGIN

  Fnd_File.put_line(Fnd_File.LOG, TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'DÃ¿Â©but validate_data');
  Fnd_File.put_line(Fnd_File.LOG,
                    TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                    'Validation des donnÃ¿Â©es dans les tables spÃ¿Â©cifiques : ');

  /*
  UPDATE DKA_RCV_TRANSACTIONS_TMP drt
     SET ORG_ID = (SELECT hr.ORGANIZATION_ID FROM hr_operating_units hr WHERE hr.NAME = drt.region || drt.societe)
   where flag = '-1';
  --
  UPDATE DKA_RCV_TRANSACTIONS_TMP drt
     SET po_header_id = (select pha.po_header_id
                           from po_headers_all pha
                          where pha.segment1 = drt.PO_NUM
                            and pha.org_id = drt.org_id)
   where flag = '-1';
  --
  UPDATE DKA_RCV_TRANSACTIONS_TMP drt
     SET po_line_id = (select pla.po_line_id
                         from po_lines_all pla
                        where pla.po_header_id = drt.po_header_id
                          and pla.line_num = drt.PO_LINE_NUM)
   where flag = '-1';
  --
  UPDATE DKA_RCV_TRANSACTIONS_TMP drt
     SET po_line_location_id = (select plla.line_location_id
                                  from po_line_locations_all plla
                                 where plla.po_header_id = drt.po_header_id
                                   and plla.po_line_id = drt.po_line_id
                                   and plla.shipment_num = drt.PO_SHIP_LINE_NUM)
   where flag = '-1';
  --
  --RBE artf2125858
  UPDATE DKA_RCV_TRANSACTIONS_TMP drt
     SET po_distribution_id = (select pda.po_distribution_id
                                 from po_distributions_all pda
                                where pda.po_header_id = drt.po_header_id
                                  and pda.po_line_id = drt.po_line_id
                                  and pda.line_location_id = drt.po_line_location_id
                                  and pda.distribution_num = drt.PO_DIST_NUM)
   where flag = '-1';
  --

  COMMIT;
  */
  IF rec_type = 'RECEIVE' then
     FOR rec_cur_recept IN cur_recept_new LOOP
         validate_data_group(p_Errbuf , p_retcode, rec_cur_recept.RECORD_ID) ;
     END LOOP;
  END IF;
  IF rec_type = 'CORRECT_ADD' then
     FOR rec_cur_recept IN cur_recept_cor_add LOOP
         validate_data_group(p_Errbuf , p_retcode, rec_cur_recept.RECORD_ID) ;
     END LOOP;
  END IF;






  -- Transaction type non valide
  FOR rec_cur_recept IN cur_recept_ERR_TYPE LOOP
    -- RG409
      IF rec_cur_recept.TRANSACTION_TYPE IS NULL THEN
        v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_018');
        --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
        DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                        'DKA_IPORECEPTION_IVALUA', --prog_name
                                        'RECEPTION',               --source
                                        'DKA_IPOREC_INTERFACE' ,   --table_name
                                        rec_cur_recept.RECORD_ID,  --table_id
                                        'TRANSACTION_TYPE',  --column_name
                                        rec_cur_recept.TRANSACTION_TYPE, --column_value
                                        'E',                       --message_type
                                       v_message                   --message_text
                                        );
        v_flag_erreur := TRUE;

        UPDATE DKA_IPOREC_INTERFACE
           SET STATUT = 'REJECTED'
             , request_id = g_request_id
         WHERE CURRENT OF cur_recept_ERR_TYPE;
      ELSIF rec_cur_recept.TRANSACTION_TYPE not in ('RECEIVE', 'CORRECT') THEN
        v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_019','TRANSACTION_TYPE',rec_cur_recept.TRANSACTION_TYPE);
        --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
        DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                        'DKA_IPORECEPTION_IVALUA', --prog_name
                                        'RECEPTION',               --source
                                        'DKA_IPOREC_INTERFACE' ,   --table_name
                                        rec_cur_recept.RECORD_ID,  --table_id
                                        'TRANSACTION_TYPE',  --column_name
                                        rec_cur_recept.TRANSACTION_TYPE, --column_value
                                        'E',                       --message_type
                                       v_message                   --message_text
                                        );
        v_flag_erreur := TRUE;

        UPDATE DKA_IPOREC_INTERFACE
           SET STATUT = 'REJECTED'
             , request_id = g_request_id
         WHERE CURRENT OF cur_recept_ERR_TYPE;
      END IF;
  END LOOP;

 -- RG414
  FOR rec_cur_recept IN cur_recept LOOP

        BEGIN
           v_reject:=0;
           select distinct 1 into v_reject
             from DKA_IPOREC_INTERFACE DII
            where DII.receipt_num = rec_cur_recept.RECEIPT_NUM
              and DII.line_num <> rec_cur_recept.line_num
              and rec_cur_recept.TRANSACTION_TYPE = 'RECEIVE'
              and DII.TRANSACTION_TYPE = 'RECEIVE'
        and rec_cur_recept.STATUT = 'VALIDATED'
              and DII.STATUT = 'REJECTED';
        EXCEPTION
          WHEN OTHERS THEN
               null;
        END;

        IF v_reject = 1 THEN
            v_message :=dka_tools_pkg.get_message('DKA','DKA_IPOREC_036');
            --Add_Message(rec_cur_recept.RECEIPT_NUM, rec_cur_recept.RECORD_ID, v_message, rec_cur_recept.receipt_num);
                DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                                'DKA_IPORECEPTION_IVALUA', --prog_name
                                                'RECEPTION',               --source
                                                'DKA_IPOREC_INTERFACE' ,   --table_name
                                                rec_cur_recept.RECORD_ID,  --table_id
                                                'RECEIPT_NUM',  --column_name
                                                rec_cur_recept.receipt_num, --column_value
                                                'E',                       --message_type
                                               v_message                   --message_text
                                                );
            v_flag_erreur := TRUE;

            UPDATE DKA_IPOREC_INTERFACE
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
                      'Fin de la procÃ¿Â©dure validate_data : EXCEPTION OTHERS ');
END validate_data;



 /*
 *************************************************************************
 * PROCEDURE NAME : import_data
 *
 * DESCRIPTION
 *  ProcÃ¿Â©dure d'insertion dans les tables d'interfaces
 *
 * PARAMETERS
 * ==========
 * NAME               DESCRIPTION
 * -----------------  -----------------------------------------------------
 * p_errbuf          Retour de message Ã¿Â©ventuel
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
  v_employee_id            NUMBER; -- SELO
  v_inc_group              NUMBER := 0;


 --< BNZ 375
 -- Curseur des receptions fermer
 CURSOR cur_recep_imp_rejet IS
     SELECT  dir.*
        FROM DKA_IPOREC_INTERFACE dii, dka.DKA_IPOREC_REJECT dir
        WHERE dii.DOCUMENT_NUM = dir.num_cmd
        and dii.RECEIPT_NUM = dir.receipt_num
        AND dii.STATUT = 'VALIDATED'
       FOR UPDATE OF NEW_STATUT_CMD;
--> BNZ 375
  -- Curseur des receptions
  CURSOR cur_recep_imp IS
    SELECT *
      FROM DKA_IPOREC_INTERFACE
     WHERE 1 = 1
       -- AND FLAG = 'S'
       AND STATUT = 'VALIDATED'
       AND TRANSACTION_TYPE = 'RECEIVE'
       AND SHIPMENT_HEADER_ID is null
       --AND loader_request_id = DECODE(g_loader_request_id, -1, loader_request_id, g_loader_request_id)
     ORDER BY record_id
       FOR UPDATE OF STATUT, INTERFACE_TRANSACTION_ID;

  -- Cursor des transactions
  CURSOR cur_trans_imp(p_receipt_num VARCHAR2, p_org_id NUMBER
  ) IS
    SELECT *
      FROM DKA_IPOREC_INTERFACE
     WHERE receipt_num = p_receipt_num
       AND ORG_ID = p_org_id
       AND transaction_TYPE = 'RECEIVE'
       AND STATUT = 'VALIDATED'
       AND SHIPMENT_HEADER_ID is null
     ORDER BY record_id
    --ORDER BY (transaction_id) DESC         comment
       FOR UPDATE OF STATUT;


  -- Cursor des transactions
  CURSOR cur_trans_imp_correct --(p_receipt_num VARCHAR2, p_org_id NUMBER ) -- SELO
  IS
    SELECT *
      FROM DKA_IPOREC_INTERFACE
     WHERE 1=1
       -- AND receipt_num = p_receipt_num
       -- AND ORG_ID = p_org_id
       AND transaction_TYPE = 'CORRECT'
       AND STATUT = 'VALIDATED'
    --ORDER BY (transaction_id) DESC         comment
     ORDER BY record_id
       FOR UPDATE OF STATUT;

  CURSOR cur_recep_imp_ADD --(p_receipt_num VARCHAR2, p_org_id NUMBER ) -- SELO
  IS
    SELECT *
      FROM DKA_IPOREC_INTERFACE
     WHERE 1=1
       -- AND receipt_num = p_receipt_num
       -- AND ORG_ID = p_org_id
       AND transaction_TYPE = 'RECEIVE'
       AND SHIPMENT_HEADER_ID is not null
       AND STATUT = 'VALIDATED'
     ORDER BY record_id
    --ORDER BY (transaction_id) DESC         comment
       FOR UPDATE OF STATUT;

     CURSOR cur_trans_imp_add(p_receipt_num VARCHAR2, p_org_id NUMBER
  ) IS
    SELECT *
      FROM DKA_IPOREC_INTERFACE
     WHERE receipt_num = p_receipt_num
       AND ORG_ID = p_org_id
       AND transaction_TYPE = 'RECEIVE'
       AND SHIPMENT_HEADER_ID is not null
       AND STATUT = 'VALIDATED'
    --ORDER BY (transaction_id) DESC         comment
     ORDER BY record_id
       FOR UPDATE OF STATUT;

BEGIN
--<BNZ 375
 FOR rec_cur_recep_imp_rejet IN cur_recep_imp_rejet LOOP

--ouverture des commandes
  BEGIN
   if rec_cur_recep_imp_rejet.blocage = 'Line' then

-- MAJ des lignes de livraison
      UPDATE po_line_locations_all
      SET    closed_code  = 'OPEN'
            ,closed_date = NULL
      ,SHIPMENT_CLOSED_DATE = NULL
            ,last_update_date = sysdate
            ,CANCEL_FLAG='N'
            ,last_updated_by = g_user_id -- renseigner le matricule
      WHERE po_header_id = rec_cur_recep_imp_rejet.id_cmd
	  and po_line_id = rec_cur_recep_imp_rejet.id_ligne -- BNZ
      AND closed_code in('FINALLY CLOSED' , 'CLOSED', 'CLOSED FOR INVOICE');




      -- MAJ des lignes de commande
      UPDATE po_lines_all
      SET    closed_code  = 'OPEN'
            ,closed_date = NULL,
            CANCEL_FLAG='N'
            ,last_update_date = sysdate
            ,last_updated_by = g_user_id -- renseigner le matricule

      WHERE po_header_id = rec_cur_recep_imp_rejet.id_cmd
	  and po_line_id = rec_cur_recep_imp_rejet.id_ligne; --BNZ

      UPDATE dka.DKA_IPOREC_REJECT
            SET NEW_STATUT_CMD = 'OPEN'
            WHERE CURRENT OF cur_recep_imp_rejet;

     ELSIF rec_cur_recep_imp_rejet.blocage = 'Header' then

      -- MAJ entete de commande
      UPDATE po_headers_all
      SET    closed_date = null
            ,closed_code = 'OPEN'
            ,attribute9 = 'OUI',
            CANCEL_FLAG='N'
            ,last_update_date = sysdate
            ,last_updated_by = g_user_id -- renseigner le matricule
    WHERE po_header_id = rec_cur_recep_imp_rejet.id_cmd;

            UPDATE dka.DKA_IPOREC_REJECT
               SET NEW_STATUT_CMD = 'OPEN'
             WHERE CURRENT OF cur_recep_imp_rejet;

     end if;

          EXCEPTION
            WHEN OTHERS THEN
              fnd_file.put_line(fnd_file.log,
                                'impossible d''ouvrer la commande : ' || rec_cur_recep_imp_rejet.id_cmd || ' | erreur: ' || sqlerrm);
    END;

    END LOOP;
 --> BNZ 375


    -- GROUP_ID
    /*SELECT rcv_interface_groups_s.nextval
      INTO g_group_id
      FROM dual;
    */
    -- Boucle sur les receptions
    FOR rec_cur_recep_imp IN cur_recep_imp LOOP
      BEGIN
        -- Controle qui permet de decouper par lot
         v_cpt := 0;
                  -- GROUP_ID
          SELECT rcv_interface_groups_s.nextval
            INTO g_group_id
            FROM dual;


        -- ID de la reception
        SELECT rcv_headers_interface_s.nextval
          INTO v_rcv_header_id
          FROM DUAL;

        SELECT employee_id into v_employee_id
          FROM fnd_user
         WHERE user_name like 'IVALUA';
         --WHERE fax = 'IVALUA';

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
          -- SHIPMENT_NUM,
           RECEIPT_NUM,
           VENDOR_ID,
           VENDOR_SITE_ID,
          -- SHIP_TO_ORGANIZATION_ID,
           PACKING_SLIP,
           ATTRIBUTE1,
           EMPLOYEE_ID,
           VALIDATION_FLAG,
           ORG_ID
           )
        VALUES
          (v_rcv_header_id, --HEADER_INTERFACE_ID,
           g_group_id, --v_rcv_header_id,   g_group_id,                                 --GROUP_ID,
           v_processing_status_code, --PROCESSING_STATUS_CODE,
           v_receipt_source_code, --RECEIPT_SOURCE_CODE,
           v_transaction_type, --TRANSACTION_TYPE,
           SYSDATE, --LAST_UPDATE_DATE ,
           g_user_id, --LAST_UPDATED_BY,
           SYSDATE, --CREATION_DATE,
           g_user_id, --CREATED_BY,
           --rec_cur_recep_imp.SHIPMENT_NUM, --SHIPMENT_NUM,
           rec_cur_recep_imp.RECEIPT_NUM, --RECEIPT_NUM, -- OBE artf2184213
           rec_cur_recep_imp.vendor_id, --VENDOR_NUM,
           rec_cur_recep_imp.VENDOR_SITE_ID,
           --v_code_site_four,                           --VENDOR_SITE_CODE,    SUBSTR(rec_cur_recep_imp.VENDOR_SITE_CODE,5)   a ajouter apres
          -- rec_cur_recep_imp.org_id, --SHIP_TO_ORGANIZATION_ID
           rec_cur_recep_imp.BORDEREAU_NUM, --PACKING_SLIP,
           'IVALUA',
           v_employee_id,
           'Y', --VALIDATION_FLAG
           rec_cur_recep_imp.org_id --ORG_ID
           );

        g_summary.inserted_header_rows := g_summary.inserted_header_rows + 1;

        -- Transactions  RECEIVE
        FOR rec_cur_trans_imp IN cur_trans_imp(rec_cur_recep_imp.RECEIPT_NUM,
                                               rec_cur_recep_imp.ORG_ID
                                               ) LOOP

          BEGIN
            -- ID transaction
            SELECT RCV_TRANSACTIONS_INTERFACE_S.NEXTVAL INTO v_transaction_id FROM DUAL;

            -- Inserer les transactions
            INSERT INTO rcv_transactions_interface
              (INTERFACE_TRANSACTION_ID,
               GROUP_ID,
               -- lPN_GROUP_ID, -- SELO
               LAST_UPDATE_DATE,
               LAST_UPDATED_BY,
               CREATION_DATE,
               CREATED_BY,
               TRANSACTION_TYPE,
               AUTO_TRANSACT_CODE,
               PROCESSING_STATUS_CODE,
               PROCESSING_MODE_CODE,
               TRANSACTION_STATUS_CODE,
               TRANSACTION_DATE,
               --CATEGORY_ID,
               QUANTITY,
               UNIT_OF_MEASURE,
               RECEIPT_SOURCE_CODE,
               SOURCE_DOCUMENT_CODE,
               PO_HEADER_ID,
               PO_LINE_ID,
               PO_LINE_LOCATION_ID,
               PO_DISTRIBUTION_ID, -- RBE artf2125858
               COMMENTS,
               HEADER_INTERFACE_ID,
               TO_ORGANIZATION_ID,
               ORG_ID,
               VALIDATION_FLAG,
         ATTRIBUTE2
               )
            VALUES
              (v_transaction_id, --INTERFACE_TRANSACTION_ID,
               g_group_id, --v_rcv_header_id,   g_group_id ,                                        --GROUP_ID,
              -- v_rcv_header_id,            -- LPN_GROUP_ID           -- Ajout afin de commiter reception par reception
               SYSDATE, --LAST_UPDATE_DATE,
               g_user_id, --LAST_UPDATED_BY,
               SYSDATE, --CREATION_DATE,
               g_user_id, --CREATED_BY,
               'RECEIVE', --rec_cur_trans_imp.TRANSACTION_TYPE, --TRANSACTION_TYPE,
               'DELIVER', --rec_cur_trans_imp.transaction_type, --TRANSACTION_TYPE
               --TO_DATE('2016/12/31','YYYY/MM/DD'),                 --TRANSACTION_DATE,
               --rec_cur_trans_imp.TRANSACTION_DATE,                 --TRANSACTION_DATE,
               V_PROCESSING_STATUS_CODE, --PROCESSING_STATUS_CODE,
              -- g_gl_date, -- OBE

               V_PROCESSING_MODE_CODE, --PROCESSING_MODE_CODE,
               'PENDING', --TRANSACTION_STATUS_CODE
               rec_cur_trans_imp.Receipt_date_new, -- Transaction_date
               --0,                                                  --CATEGORY_ID,  -- OBE
               rec_cur_trans_imp.QUANTITY, --QUANTITY,
               rec_cur_trans_imp.UNIT_OF_MEASURE, --UNIT_OF_MEASURE,
               V_RECEIPT_SOURCE_CODE, --RECEIPT_SOURCE_CODE,
               'PO', --SOURCE_DOCUMENT_CODE
               rec_cur_trans_imp.CMD_ID , -- PO_HEADER_ID
               rec_cur_trans_imp.LIGNE_ID, --PO_LINE_ID
               rec_cur_trans_imp.LINE_LOCATION_ID, --PO_LINE_LOCATION_ID
               rec_cur_trans_imp.PO_DISTRIBUTION_ID, --PO_DISTRIBUTION_ID      -- RBE artf2125858
               rec_cur_trans_imp.COMMENTAIRE, --COMMENTS,
               v_rcv_header_id, --HEADER_INTERFACE_ID,
               rec_cur_trans_imp.org_id, --TO_ORGANIZATION_ID,
               rec_cur_trans_imp.org_id, --Org_id,
               'Y' , --VALIDATION_FLAG
         rec_cur_trans_imp.ID_MVT_REC
               );


            UPDATE DKA_IPOREC_INTERFACE
               SET INTERFACE_TRANSACTION_ID = v_transaction_id
                 , statut='INSERTED_OI'
             WHERE CURRENT OF cur_trans_imp;

            g_summary.inserted_transaction_rows := g_summary.inserted_transaction_rows + 1;

          EXCEPTION
            WHEN OTHERS THEN
              fnd_file.put_line(fnd_file.log,
                                'Insertion de la ligne ' || rec_cur_trans_imp.TRANSACTION_TYPE || ' impossible||' ||
                                rec_cur_trans_imp.receipt_num || '| erreur: ' || sqlerrm);
          END;
        END LOOP;

        v_cpt := v_cpt + 1;

      EXCEPTION
        WHEN OTHERS THEN
          fnd_file.put_line(fnd_file.log,
                            'Insertion de la reception impossible ||' || rec_cur_recep_imp.RECEIPT_NUM || '| erreur: ' ||
                            sqlerrm);
      END;

    END LOOP;


      FOR rec_cur_trans_imp_EXPENSE  IN cur_trans_imp_correct LOOP
          BEGIN

        IF v_inc_group = 0 THEN
            SELECT rcv_interface_groups_s.nextval
                  INTO g_group_id_CORRECT
                  FROM dual;
        v_inc_group := 1;
        END IF;
            -- ID transaction
            SELECT RCV_TRANSACTIONS_INTERFACE_S.NEXTVAL INTO v_transaction_id FROM DUAL;

            -- Inserer les transactions
            INSERT INTO rcv_transactions_interface
              (INTERFACE_TRANSACTION_ID,
               GROUP_ID,
               -- lPN_GROUP_ID, -- SELO
               LAST_UPDATE_DATE,
               LAST_UPDATED_BY,
               CREATION_DATE,
               CREATED_BY,
               TRANSACTION_TYPE,
               DESTINATION_TYPE_CODE,
                --AUTO_TRANSACT_CODE,
               PROCESSING_STATUS_CODE,
               PROCESSING_MODE_CODE,
               TRANSACTION_STATUS_CODE,
               SHIPMENT_HEADER_ID,
               shipment_line_id,
               PARENT_TRANSACTION_ID,
               TRANSACTION_DATE,
               --CATEGORY_ID,
               QUANTITY,
               UNIT_OF_MEASURE,
               RECEIPT_SOURCE_CODE,
               SOURCE_DOCUMENT_CODE,
               PO_HEADER_ID,
               PO_LINE_ID,
               PO_LINE_LOCATION_ID,
               PO_DISTRIBUTION_ID, -- RBE artf2125858
               COMMENTS,
               HEADER_INTERFACE_ID,
               TO_ORGANIZATION_ID,
               ORG_ID,
               VALIDATION_FLAG,
         ATTRIBUTE2
               )
            VALUES
              (v_transaction_id, --INTERFACE_TRANSACTION_ID,
               g_group_id_CORRECT, --v_rcv_header_id,   g_group_id ,                                        --GROUP_ID,
              -- v_rcv_header_id,            -- LPN_GROUP_ID           -- Ajout afin de commiter reception par reception
               SYSDATE, --LAST_UPDATE_DATE,
               g_user_id, --LAST_UPDATED_BY,
               SYSDATE, --CREATION_DATE,
               g_user_id, --CREATED_BY,
               'CORRECT', --rec_cur_trans_imp_EXPENSE.TRANSACTION_TYPE, --TRANSACTION_TYPE,
               'EXPENSE', --DESTINATION_TYPE_CODE
               -- 'EXPENSE', --rec_cur_trans_imp_EXPENSE.transaction_type, --TRANSACTION_TYPE
               --TO_DATE('2016/12/31','YYYY/MM/DD'),                 --TRANSACTION_DATE,
               --rec_cur_trans_imp_EXPENSE.TRANSACTION_DATE,                 --TRANSACTION_DATE,
               'PENDING', --PROCESSING_STATUS_CODE,
              -- g_gl_date, -- OBE
               'BATCH' , --PROCESSING_MODE_CODE,
               'PENDING', --TRANSACTION_STATUS_CODE
               rec_cur_trans_imp_EXPENSE.SHIPMENT_HEADER_ID,
               rec_cur_trans_imp_EXPENSE.shipment_line_id,
               rec_cur_trans_imp_EXPENSE.TRANSACTION_ID,
               rec_cur_trans_imp_EXPENSE.Receipt_date_new, -- Transaction_date
               --0,                                                  --CATEGORY_ID,  -- OBE
               rec_cur_trans_imp_EXPENSE.QUANTITY, --QUANTITY,
               rec_cur_trans_imp_EXPENSE.UNIT_OF_MEASURE, --UNIT_OF_MEASURE,
               V_RECEIPT_SOURCE_CODE, --RECEIPT_SOURCE_CODE,
               'PO', --SOURCE_DOCUMENT_CODE
               rec_cur_trans_imp_EXPENSE.CMD_ID , -- PO_HEADER_ID
               rec_cur_trans_imp_EXPENSE.LIGNE_ID, --PO_LINE_ID
               rec_cur_trans_imp_EXPENSE.LINE_LOCATION_ID, --PO_LINE_LOCATION_ID
               rec_cur_trans_imp_EXPENSE.PO_DISTRIBUTION_ID, --PO_DISTRIBUTION_ID      -- RBE artf2125858
               rec_cur_trans_imp_EXPENSE.COMMENTAIRE, --COMMENTS,
               v_rcv_header_id, --HEADER_INTERFACE_ID,
               rec_cur_trans_imp_EXPENSE.org_id, --TO_ORGANIZATION_ID,
               rec_cur_trans_imp_EXPENSE.org_id, --Org_id,
               'Y', --VALIDATION_FLAG
         rec_cur_trans_imp_EXPENSE.ID_MVT_REC
               );

              UPDATE DKA_IPOREC_INTERFACE
              SET INTERFACE_TRANSACTION_ID = v_transaction_id
              --  , statut='INSERTED_OI'
              WHERE CURRENT OF cur_trans_imp_correct;
          EXCEPTION
            WHEN OTHERS THEN
              fnd_file.put_line(fnd_file.log,
                                'Insertion de la ligne ' || rec_cur_trans_imp_EXPENSE.TRANSACTION_TYPE || ' impossible||' ||
                                rec_cur_trans_imp_EXPENSE.receipt_num || '| erreur: ' || sqlerrm);
          END;
        END LOOP;

        -- RG603
        FOR rec_cur_trans_imp_RECEIVING IN cur_trans_imp_correct LOOP
          BEGIN
            -- ID transaction
            SELECT RCV_TRANSACTIONS_INTERFACE_S.NEXTVAL INTO v_transaction_id FROM DUAL;
            -- Inserer les transactions
            INSERT INTO rcv_transactions_interface
              (INTERFACE_TRANSACTION_ID,
               GROUP_ID,
               -- lPN_GROUP_ID, -- SELO
               LAST_UPDATE_DATE,
               LAST_UPDATED_BY,
               CREATION_DATE,
               CREATED_BY,
               TRANSACTION_TYPE,
               DESTINATION_TYPE_CODE,
               --AUTO_TRANSACT_CODE,
               PROCESSING_STATUS_CODE,
               PROCESSING_MODE_CODE,
               TRANSACTION_STATUS_CODE,
               SHIPMENT_HEADER_ID,
               shipment_line_id,
               PARENT_TRANSACTION_ID,
               TRANSACTION_DATE,
               --CATEGORY_ID,
               QUANTITY,
               UNIT_OF_MEASURE,
               RECEIPT_SOURCE_CODE,
               SOURCE_DOCUMENT_CODE,
               PO_HEADER_ID,
               PO_LINE_ID,
               PO_LINE_LOCATION_ID,
               PO_DISTRIBUTION_ID, -- RBE artf2125858
               COMMENTS,
               HEADER_INTERFACE_ID,
               TO_ORGANIZATION_ID,
               ORG_ID,
               VALIDATION_FLAG,
         ATTRIBUTE2
               )
            VALUES
              (v_transaction_id, --INTERFACE_TRANSACTION_ID,
               g_group_id_CORRECT, --v_rcv_header_id,   g_group_id ,                                        --GROUP_ID,
              -- v_rcv_header_id,            -- LPN_GROUP_ID           -- Ajout afin de commiter reception par reception
               SYSDATE, --LAST_UPDATE_DATE,
               g_user_id, --LAST_UPDATED_BY,
               SYSDATE, --CREATION_DATE,
               g_user_id, --CREATED_BY,
               'CORRECT', --rec_cur_trans_imp_RECEIVING.TRANSACTION_TYPE, --TRANSACTION_TYPE,
               'RECEIVING', --DESTINATION_TYPE_CODE
               -- 'EXPENSE', --rec_cur_trans_imp_RECEIVING.transaction_type, --TRANSACTION_TYPE

               --TO_DATE('2016/12/31','YYYY/MM/DD'),                 --TRANSACTION_DATE,
               --rec_cur_trans_imp_RECEIVING.TRANSACTION_DATE,                 --TRANSACTION_DATE,
               'PENDING', --PROCESSING_STATUS_CODE,
              -- g_gl_date, -- OBE

               'BATCH' , --PROCESSING_MODE_CODE,
               'PENDING', --TRANSACTION_STATUS_CODE
               rec_cur_trans_imp_RECEIVING.SHIPMENT_HEADER_ID,
               rec_cur_trans_imp_RECEIVING.shipment_line_id,
               rec_cur_trans_imp_RECEIVING.PARENT_TRANSACTION_ID,
               rec_cur_trans_imp_RECEIVING.Receipt_date_new, -- Transaction_date
               --0,                                                  --CATEGORY_ID,  -- OBE
               rec_cur_trans_imp_RECEIVING.QUANTITY, --QUANTITY,
               rec_cur_trans_imp_RECEIVING.UNIT_OF_MEASURE, --UNIT_OF_MEASURE,
               V_RECEIPT_SOURCE_CODE, --RECEIPT_SOURCE_CODE,
               'PO', --SOURCE_DOCUMENT_CODE
               rec_cur_trans_imp_RECEIVING.CMD_ID , -- PO_HEADER_ID
               rec_cur_trans_imp_RECEIVING.LIGNE_ID, --PO_LINE_ID
               rec_cur_trans_imp_RECEIVING.LINE_LOCATION_ID, --PO_LINE_LOCATION_ID
               rec_cur_trans_imp_RECEIVING.PO_DISTRIBUTION_ID, --PO_DISTRIBUTION_ID      -- RBE artf2125858
               rec_cur_trans_imp_RECEIVING.COMMENTAIRE, --COMMENTS,
               v_rcv_header_id, --HEADER_INTERFACE_ID,
               rec_cur_trans_imp_RECEIVING.org_id, --TO_ORGANIZATION_ID,
               rec_cur_trans_imp_RECEIVING.org_id, --Org_id,
               'Y', --VALIDATION_FLAG
         rec_cur_trans_imp_RECEIVING.ID_MVT_REC
               );

            UPDATE DKA_IPOREC_INTERFACE
               SET INTERFACE_TRANSACTION_ID = v_transaction_id
              --  , statut='INSERTED_OI'
             WHERE CURRENT OF cur_trans_imp_correct;

          EXCEPTION
            WHEN OTHERS THEN
              fnd_file.put_line(fnd_file.log,
                                'Insertion de la ligne ' || rec_cur_trans_imp_RECEIVING.TRANSACTION_TYPE || ' impossible||' ||
                                rec_cur_trans_imp_RECEIVING.receipt_num || '| erreur: ' || sqlerrm);
          END;
        END LOOP;

        FOR rec_cur_trans_imp_RECEIVING IN cur_trans_imp_correct LOOP
           UPDATE DKA_IPOREC_INTERFACE
              SET statut='INSERTED_OI'
            WHERE CURRENT OF cur_trans_imp_correct;

            g_summary.inserted_transaction_rows := g_summary.inserted_transaction_rows + 1;
        END LOOP;
      -- RG701
        -- GROUP_ID
       v_inc_group := 0;

    -- Boucle sur les receptions
        FOR rec_cur_recep_imp_ADD IN cur_recep_imp_ADD LOOP

            BEGIN
        IF v_inc_group = 0 THEN
                   SELECT rcv_interface_groups_s.nextval
                     INTO g_group_id_ADD
                     FROM dual;
           v_inc_group := 1;
        END IF;
        -- ID de la reception
                SELECT rcv_headers_interface_s.nextval
                  INTO v_rcv_header_id
                  FROM DUAL;


                SELECT employee_id into v_employee_id
                  FROM fnd_user
                 WHERE user_name like 'IVALUA';
                 --WHERE fax = 'IVALUA';


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
                   RECEIPT_HEADER_ID,
                   VENDOR_ID,
                   VALIDATION_FLAG,
                   ORG_ID
                   )
                VALUES
                  (v_rcv_header_id, --HEADER_INTERFACE_ID,
                   g_group_id_ADD, --v_rcv_header_id,   g_group_id,                                 --GROUP_ID,
                   v_processing_status_code, --PROCESSING_STATUS_CODE,
                   v_receipt_source_code, --RECEIPT_SOURCE_CODE,
                   'ADD', --TRANSACTION_TYPE,
                   SYSDATE, --LAST_UPDATE_DATE ,
                   g_user_id, --LAST_UPDATED_BY,
                   SYSDATE, --CREATION_DATE,
                   g_user_id, --CREATED_BY,
                    rec_cur_recep_imp_ADD.SHIPMENT_HEADER_ID, --RECEIPT_HEADER_ID, -- OBE artf2184213
                   rec_cur_recep_imp_ADD.vendor_id, --VENDOR_NUM,
                   'Y', --VALIDATION_FLAG
                   rec_cur_recep_imp_ADD.org_id --ORG_ID
                   );

                g_summary.inserted_header_rows := g_summary.inserted_header_rows + 1;
                -- Transactions  RECEIVE
                FOR rec_cur_trans_imp_add IN cur_trans_imp_add(rec_cur_recep_imp_ADD.RECEIPT_NUM,
                                                               rec_cur_recep_imp_ADD.ORG_ID
                                                               ) LOOP

                  BEGIN
                    -- ID transaction
                    SELECT RCV_TRANSACTIONS_INTERFACE_S.NEXTVAL INTO v_transaction_id FROM DUAL;

                    -- Inserer les transactions
                    INSERT INTO rcv_transactions_interface
                      (INTERFACE_TRANSACTION_ID,
                       GROUP_ID,
                       -- lPN_GROUP_ID, -- SELO
                       LAST_UPDATE_DATE,
                       LAST_UPDATED_BY,
                       CREATION_DATE,
                       CREATED_BY,
                       TRANSACTION_TYPE,
                       AUTO_TRANSACT_CODE,
                       PROCESSING_STATUS_CODE,
                       PROCESSING_MODE_CODE,
                       TRANSACTION_STATUS_CODE,
                       TRANSACTION_DATE,
                       --CATEGORY_ID,
                       QUANTITY,
                       UNIT_OF_MEASURE,
                       RECEIPT_SOURCE_CODE,
                       SOURCE_DOCUMENT_CODE,
                       PO_HEADER_ID,
                       PO_LINE_ID,
                       PO_LINE_LOCATION_ID,
                       PO_DISTRIBUTION_ID, -- RBE artf2125858
                       COMMENTS,
                       HEADER_INTERFACE_ID,
                       TO_ORGANIZATION_ID,
                       ORG_ID,
                       VALIDATION_FLAG,
             ATTRIBUTE2
                       )
                    VALUES
                      (v_transaction_id, --INTERFACE_TRANSACTION_ID,
                       g_group_id_ADD, --v_rcv_header_id,   g_group_id ,                                        --GROUP_ID,
                      -- v_rcv_header_id,            -- LPN_GROUP_ID           -- Ajout afin de commiter reception par reception
                       SYSDATE, --LAST_UPDATE_DATE,
                       g_user_id, --LAST_UPDATED_BY,
                       SYSDATE, --CREATION_DATE,
                       g_user_id, --CREATED_BY,
                       'RECEIVE', --rec_cur_trans_imp_add.TRANSACTION_TYPE, --TRANSACTION_TYPE,
                       'DELIVER', --rec_cur_trans_imp_add.transaction_type, --TRANSACTION_TYPE
                       --TO_DATE('2016/12/31','YYYY/MM/DD'),                 --TRANSACTION_DATE,
                       --rec_cur_trans_imp_add.TRANSACTION_DATE,                 --TRANSACTION_DATE,
                       V_PROCESSING_STATUS_CODE, --PROCESSING_STATUS_CODE,
                      -- g_gl_date, -- OBE

                       V_PROCESSING_MODE_CODE, --PROCESSING_MODE_CODE,
                       'PENDING', --TRANSACTION_STATUS_CODE
                       rec_cur_trans_imp_add.Receipt_date_new, -- Transaction_date
                       --0,                                                  --CATEGORY_ID,  -- OBE
                       rec_cur_trans_imp_add.QUANTITY, --QUANTITY,
                       rec_cur_trans_imp_add.UNIT_OF_MEASURE, --UNIT_OF_MEASURE,
                       V_RECEIPT_SOURCE_CODE, --RECEIPT_SOURCE_CODE,
                       'PO', --SOURCE_DOCUMENT_CODE
                       rec_cur_trans_imp_add.CMD_ID , -- PO_HEADER_ID
                       rec_cur_trans_imp_add.LIGNE_ID, --PO_LINE_ID
                       rec_cur_trans_imp_add.LINE_LOCATION_ID, --PO_LINE_LOCATION_ID
                       rec_cur_trans_imp_add.PO_DISTRIBUTION_ID, --PO_DISTRIBUTION_ID      -- RBE artf2125858
                       rec_cur_trans_imp_add.COMMENTAIRE, --COMMENTS,
                       v_rcv_header_id, --HEADER_INTERFACE_ID,
                       rec_cur_trans_imp_add.org_id, --TO_ORGANIZATION_ID,
                       rec_cur_trans_imp_add.org_id, --Org_id,
                       'Y' , --VALIDATION_FLAG
             rec_cur_trans_imp_add.ID_MVT_REC
                       );

                    UPDATE DKA_IPOREC_INTERFACE
                       SET INTERFACE_TRANSACTION_ID = v_transaction_id
                         , statut='INSERTED_OI'
                     WHERE CURRENT OF cur_trans_imp_add;

                    g_summary.inserted_transaction_rows := g_summary.inserted_transaction_rows + 1;

                  EXCEPTION
                    WHEN OTHERS THEN
                      fnd_file.put_line(fnd_file.log,
                                        'Insertion de la ligne ' || rec_cur_trans_imp_add.TRANSACTION_TYPE || ' impossible||' ||
                                        rec_cur_trans_imp_add.receipt_num || '| erreur: ' || sqlerrm);
                  END;
                END LOOP;

      --  UPDATE DKA_RCV_HEADERS_TMP SET FLAG = 'T' WHERE CURRENT OF cur_recep_imp;

                v_cpt := v_cpt + 1;

            EXCEPTION
                WHEN OTHERS THEN
                    fnd_file.put_line(fnd_file.log,
                                      'Insertion de la reception impossible ||' || rec_cur_recep_imp_ADD.RECEIPT_NUM || '| erreur: ' ||
                                      sqlerrm);
            END;

        END LOOP;

    Fnd_File.put_line(Fnd_File.LOG, TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin import_data');
    COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    p_retcode := 2;
    p_errbuf  := 'import_data : ' || SQLERRM;
    Fnd_File.put_line(Fnd_File.LOG, p_errbuf);
    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Fin de la procÃ¿Â©dure import_data : EXCEPTION OTHERS ');
    ROLLBACK;

END import_data;

/*
 *************************************************************************
 * PROCEDURE NAME : Launch_OI
 *
 * DESCRIPTION
 *  ProcÃ¿Â©dure de lancement du Programme maÃ¿Â®tre de l'interface receptions
 *
 * PARAMETERS
 * ==========
 * NAME               DESCRIPTION
.* -----------------  ------------------------------------------------------
 * p_ou              UnitÃ¿Â© opÃ¿Â©rationnelle
 * p_errbuf          Retour de message Ã¿Â©ventuel
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

    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'DÃ¿Â©but Launch_OI');
    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                                     'Lancement de l''interface des receptions : ');


    -- Calcul des statistiques sur les tables standards
    fnd_stats.gather_table_stats('PO', 'RCV_HEADERS_INTERFACE', dbms_stats.auto_sample_size);
    fnd_stats.gather_table_stats('PO', 'RCV_TRANSACTIONS_INTERFACE', dbms_stats.auto_sample_size);

    ---------------------------------------------------
    -- Lancement du traitement de l'interface des receptions --
    ---------------------------------------------------

    FOR rec_group_id IN (SELECT DISTINCT 1
                           FROM rcv_headers_interface rhi
                  , rcv_transactions_interface rti
                  , DKA_IPOREC_INTERFACE DII
                          WHERE rhi.processing_status_code = 'PENDING'
                            and rhi.TRANSACTION_TYPE = 'NEW'
                            and rti.INTERFACE_TRANSACTION_ID = dii.INTERFACE_TRANSACTION_ID
              and rhi.header_interface_id = rti.header_interface_id
                and Statut= 'INSERTED_OI'
                          --ORDER BY group_id
              ) LOOP

      -- Positionnement des options d'impression
      b_result := fnd_request.set_print_options(printer => gv_printer,
                                                copies => g_number_of_copies);

      -- Lancement du traitement Programme maÃ¿Â®tre de l'interface receptions
      vn_request_id := fnd_request.submit_request( application => 'PO',
                                                   program     => 'RVCTP',
                                                   description => NULL,
                                                   start_time  => NULL,
                                                   sub_request => FALSE,
                                                   Argument1   => 'BATCH',
                                                   Argument2   => NULL --rec_group_id.group_id         --  case g_summary.reprise_flag when 'Y' then null else g_group_id end
                          );

      IF vn_request_id = 0 THEN

        p_retcode    := 2;
        fnd_file.put_line(fnd_file.LOG, 'ERREUR : Le traitement de l''interface des receptions a Ã¿Â©chouÃ¿Â©' || CHR(10) ||
                                        'PROGRAMME  : RAXMTR');
        Fnd_File.put_line (Fnd_File.OUTPUT, '====> ERREUR : Le traitement de l''interface des receptions a Ã¿Â©chouÃ¿Â©');

      ELSE

        COMMIT;
        --Fnd_File.put_line(Fnd_File.LOG, '=> REQUEST ID= ' || vn_request_id);
        --Fnd_File.put_line(Fnd_File.OUTPUT, '. NumÃ¿Â©ro du traitement de l''interface des receptions : ' || vn_request_id);

        --Stockage des numÃ¿Â©ros de traitements
        va_request_id.extend;
        vn_nb_traitements := vn_nb_traitements + 1;
        va_request_id(vn_nb_traitements) := vn_request_id;

      END IF;
    END LOOP;

    FOR rec_group_id IN (SELECT DISTINCT rti.group_id
                           FROM rcv_transactions_interface rti
                              , DKA_IPOREC_INTERFACE DII
                          WHERE rti.processing_status_code = 'PENDING'
                            and rti.TRANSACTION_TYPE = 'CORRECT'
                            and rti.INTERFACE_TRANSACTION_ID = dii.INTERFACE_TRANSACTION_ID
                            and Statut= 'INSERTED_OI'
                          ORDER BY group_id
              ) LOOP



      -- Positionnement des options d'impression
      b_result := fnd_request.set_print_options(printer => gv_printer,
                                                copies => g_number_of_copies);

      -- Lancement du traitement Programme maÃ¿Â®tre de l'interface receptions
      vn_request_id := fnd_request.submit_request( application => 'PO',
                                                   program     => 'RVCTP',
                                                   description => NULL,
                                                   start_time  => NULL,
                                                   sub_request => FALSE,
                                                   Argument1   => 'BATCH',
                                                   Argument2   => rec_group_id.group_id       --    case g_summary.reprise_flag when 'Y' then null else g_group_id end
                          );

      IF vn_request_id = 0 THEN

        p_retcode    := 2;
        fnd_file.put_line(fnd_file.LOG, 'ERREUR : Le traitement de l''interface des receptions a Ã¿Â©chouÃ¿Â©' || CHR(10) ||
                                        'PROGRAMME  : RAXMTR');
        Fnd_File.put_line (Fnd_File.OUTPUT, '====> ERREUR : Le traitement de l''interface des receptions a Ã¿Â©chouÃ¿Â©');

      ELSE

        COMMIT;
        Fnd_File.put_line(Fnd_File.LOG, '=> REQUEST ID= ' || vn_request_id);
        --Fnd_File.put_line(Fnd_File.OUTPUT, '. NumÃ¿Â©ro du traitement de l''interface des receptions : ' || vn_request_id);

        --Stockage des numÃ¿Â©ros de traitements
        va_request_id.extend;
        vn_nb_traitements := vn_nb_traitements + 1;
        va_request_id(vn_nb_traitements) := vn_request_id;

      END IF;
    END LOOP;
    FOR rec_group_id IN (SELECT DISTINCT rhi.group_id
                           FROM rcv_headers_interface rhi
                  , rcv_transactions_interface rti
                  , DKA_IPOREC_INTERFACE DII
                          WHERE rhi.processing_status_code = 'PENDING'
                            and rhi.TRANSACTION_TYPE = 'ADD'
                            and rti.INTERFACE_TRANSACTION_ID = dii.INTERFACE_TRANSACTION_ID
              and rhi.header_interface_id = rti.header_interface_id
                and Statut= 'INSERTED_OI'
                          ORDER BY group_id
              ) LOOP


      -- Positionnement des options d'impression
        b_result := fnd_request.set_print_options(printer => gv_printer,
                                                copies => g_number_of_copies);
      -- Lancement du traitement Programme maÃ¿Â®tre de l'interface receptions
        vn_request_id := fnd_request.submit_request( application => 'PO',
                                                     program     => 'RVCTP',
                                                     description => NULL,
                                                     start_time  => NULL,
                                                     sub_request => FALSE,
                                                     Argument1   => 'BATCH',
                                                     Argument2   => rec_group_id.group_id
                          );
        IF vn_request_id = 0 THEN

          p_retcode    := 2;
          fnd_file.put_line(fnd_file.LOG, 'ERREUR : Le traitement de l''interface des receptions a Ã¿Â©chouÃ¿Â©' || CHR(10) ||
                                          'PROGRAMME  : RAXMTR');
          Fnd_File.put_line (Fnd_File.OUTPUT, '====> ERREUR : Le traitement de l''interface des receptions a Ã¿Â©chouÃ¿Â©');

        ELSE

          COMMIT;
          Fnd_File.put_line(Fnd_File.LOG, '=> REQUEST ID= ' || vn_request_id);
        --  Fnd_File.put_line(Fnd_File.OUTPUT, '. NumÃ¿Â©ro du traitement de l''interface des receptions : ' || vn_request_id);

          --Stockage des numÃ¿Â©ros de traitements
          va_request_id.extend;
          vn_nb_traitements := vn_nb_traitements + 1;
          va_request_id(vn_nb_traitements) := vn_request_id;

        END IF;
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
        --    Fnd_File.put_line(Fnd_File.OUTPUT, 'request_id = '||va_request_id(i)||'. Statut de fin : ' || v_phase || '/' || v_status);

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


    UPDATE DKA_IPOREC_INTERFACE DII
       SET statut='COMPLETE'
     WHERE exists (select distinct 1
                     from rcv_shipment_headers rsh, rcv_shipment_lines rsl, rcv_transactions rt
                    where rsh.receipt_num = DII.receipt_num
                      and rsh.ship_to_Org_Id=DII.org_id
                      and rsl.po_header_id = DII.cmd_id
                      and rsl.po_distribution_id = DII.po_distribution_id
                      and rsl.shipment_header_id=rsh.shipment_header_id
                      and rt.shipment_line_id = rsl.shipment_line_id
                      and rt.interface_transaction_id = dii.interface_transaction_id)
    and STATUT = 'INSERTED_OI';


    UPDATE DKA_IPOREC_INTERFACE DII
       SET statut='REJECTED_OI'
     WHERE dii.INTERFACE_TRANSACTION_ID in (select rti.INTERFACE_TRANSACTION_ID
                                              from rcv_transactions_interface rti
                                             where rti.processing_status_code = 'ERROR' or rti.transaction_status_code = 'ERROR');

    commit;
  EXCEPTION
      WHEN OTHERS THEN
          p_retcode   := 2;
          p_errbuf    := 'Launch_OI : ' ||SQLERRM;
          Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
          Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procÃ¿Â©dure Launch_OI : EXCEPTION OTHERS ');
  END Launch_OI;

/*
 *************************************************************************
 * PROCEDURE NAME : UPDATE_REC
 *
 * DESCRIPTION
 *  ProcÃ¿Â©dure de mettre Ã¿Â  jour les receptions finale
 *
 * PARAMETERS
 * ==========
 * NAME               DESCRIPTION
.* -----------------  ------------------------------------------------------
 * p_ou              UnitÃ¿Â© opÃ¿Â©rationnelle
 * p_errbuf          Retour de message Ã¿Â©ventuel
 * p_retcode         Statut du traitement en sortie
 *
 ************************************************************************
 */

  PROCEDURE UPDATE_REC(p_errbuf            OUT VARCHAR2,
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
--< BNZ 375

  CURSOR cur_recep_imp_rejet IS

    SELECT *
      FROM dka.DKA_IPOREC_REJECT
    where NEW_STATUT_CMD = 'OPEN'
      FOR UPDATE OF NEW_STATUT_CMD;

BEGIN

 FOR rec_cur_recep_imp_rejet IN cur_recep_imp_rejet LOOP
--Fermeture des commandes
  BEGIN
    if rec_cur_recep_imp_rejet.blocage = 'Line' then
-- MAJ des lignes de livraison
     -- MAJ ligne de livraison
      UPDATE po_line_locations_all
      SET    closed_code  = rec_cur_recep_imp_rejet.STATUT_CMD   --'FINALLY CLOSED' --EDB388
            ,closed_date = sysdate
      ,SHIPMENT_CLOSED_DATE = SYSDATE --SNK artf07230322 27/03/2019
            ,closed_by = fnd_global.user_id
            ,last_update_date = sysdate
            ,last_updated_by = g_user_id --rensigner le matricule
      WHERE po_header_id = rec_cur_recep_imp_rejet.id_cmd
      AND po_line_id = rec_cur_recep_imp_rejet.id_ligne
      AND cancel_flag = 'N'
      AND LAST_UPDATED_BY = g_user_id ;
     -- AND closed_code = 'OPEN'

      -- MAJ des lignes de commande
      UPDATE po_lines_all
      SET    closed_code  = rec_cur_recep_imp_rejet.STATUT_CMD  --'FINALLY CLOSED' --EDB388
            ,closed_date = sysdate
            ,closed_by = fnd_global.user_id
            ,last_update_date = sysdate
            ,last_updated_by = g_user_id--rensigner le matricule
      WHERE po_header_id = rec_cur_recep_imp_rejet.id_cmd 
	  AND po_line_id = rec_cur_recep_imp_rejet.id_ligne;

      UPDATE dka.DKA_IPOREC_REJECT
            SET NEW_STATUT_CMD = rec_cur_recep_imp_rejet.STATUT_CMD -- 'FINALLY CLOSED' --EDB388
            WHERE CURRENT OF cur_recep_imp_rejet;

      ELSIF rec_cur_recep_imp_rejet.blocage = 'Header' then

      -- MAJ entete de commande
        UPDATE po_headers_all
    SET  closed_date = sysdate
            ,closed_code = rec_cur_recep_imp_rejet.STATUT_CMD -- 'FINALLY CLOSED' --EDB388
            ,attribute9 = NULL
            ,last_update_date = sysdate
            ,last_updated_by = g_user_id--rensigner le matricule
    WHERE po_header_id = rec_cur_recep_imp_rejet.id_cmd;

            UPDATE dka.DKA_IPOREC_REJECT
               SET NEW_STATUT_CMD = rec_cur_recep_imp_rejet.STATUT_CMD -- 'FINALLY CLOSED' --EDB388
             WHERE CURRENT OF cur_recep_imp_rejet;

        end if;

          EXCEPTION
            WHEN OTHERS THEN
              fnd_file.put_line(fnd_file.log,
                                'impossible de fermer la commande : ' || rec_cur_recep_imp_rejet.id_cmd || ' | erreur: ' || sqlerrm);
        END;
    END LOOP;


  --> BNZ 375




    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'DÃ¿Â©but UPDATE_REC');
    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                                     'mise Ã¿Â  jour en cas de rÃ¿Â©ception finale : ');


    UPDATE PO_LINE_LOCATIONS_ALL PLLA
       SET PLLA.CLOSED_CODE = 'CLOSED FOR RECEIVING'
         , PLLA.CLOSED_FOR_RECEIVING_DATE = SYSDATE
         , PLLA.ATTRIBUTE1='Fermeture pour rÃ¿Â©ception finale le '||to_char(sysdate,'dd/mm/yyyy')||' par l''import des rÃ¿Â©ceptions'
     where PLLA.LINE_LOCATION_ID in (select PDA.LINE_LOCATION_ID
                                       from PO_LINES_ALL POLA,
                                            PO.PO_DISTRIBUTIONS_ALL PDA,
                                            PO_HEADERS_ALL PHA,
                                            DKA_IPOREC_INTERFACE DII
                                      where POLA.PO_LINE_ID = PDA.PO_LINE_ID
                                        and PHA.PO_HEADER_ID = PDA.PO_HEADER_ID
                                        and PHA.po_header_id=DII.CMD_ID
                                        and POLA.po_line_id = DII.LIGNE_ID
                                        and DII.flag_rec_finale = 'Y'
                                        and DII.STATUT = 'COMPLETE'
                                        and DII.request_id=g_request_id);


        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin UPDATE_REC');

  EXCEPTION
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'UPDATE_REC : ' ||SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procÃ¿Â©dure UPDATE_REC : EXCEPTION OTHERS ');
  END UPDATE_REC;

------------------------------------------------------
/*
 *************************************************************************
 * PROCEDURE NAME : Launch_Loader
 *
 * DESCRIPTION
 *  ProcÃ¿Â©dure de lancement du programme de chargement dans la table spÃ¿Â©cifique
 *
 * PARAMETERS
 * ==========
 * NAME               DESCRIPTION
.* -----------------  ------------------------------------------------------
 * p_directory       RÃ¿Â©pertoire du fichier
 * p_file_name       Nom du fichier Ã¿Â  charger
 * p_errbuf          Retour de message Ã¿Â©ventuel
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
    --- ARAOUF : pb de dÃ¿Â©cimales sur fichiers
    vb_state             BOOLEAN;

  BEGIN
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'DÃ¿Â©but Launch_Loader');
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                                         'Lancement de chargement du fichier dans la table d''interface spÃ¿Â©cifique : ');

        ------------------------------------------------------
        -- Lancement du traitement de chargement du fichier --
        ------------------------------------------------------
        -- Positionnement des options d'impression
        b_result := fnd_request.set_print_options(printer => gv_printer,

                                                  copies => g_number_of_copies);

    --- ARAOUF artf07480504 : pb de dÃ¿Â©cimales sur fichiers
    vb_state := FND_REQUEST.SET_OPTIONS(numeric_characters=>'.,');

        -- Lancement du traitement
        g_loader_request_id         := Fnd_Request.submit_request (
                                                                   'DKA'                            -- APPL
                                                                  ,'DKA_IPORECEPTION_IVALUA_LOADER' -- PROG
                                                                  ,NULL                             -- PROGRAM_NAME
                                                                  ,NULL                             -- START
                                                                  ,FALSE                            -- SUB_REQUEST
                                                                  );

        IF g_loader_request_id = 0
        THEN
            p_retcode    := 2;
            fnd_file.put_line(fnd_file.LOG, 'ERREUR : Le traitement de chargement du fichier a Ã¿Â©chouÃ¿Â©' || CHR(10) ||
                                            'PROGRAMME  : DKA_IPORECEPTION_IVALUA_LOADER'
                                            );
            --Fnd_File.put_line (Fnd_File.OUTPUT, '====> ERREUR : Le traitement de chargement du fichier a Ã¿Â©chouÃ¿Â©');
        ELSE
            COMMIT;
            Fnd_File.put_line(Fnd_File.LOG, '=> LOAD REQUEST ID= ' || g_loader_request_id);
            --Fnd_File.put_line(Fnd_File.OUTPUT, '. NumÃ¿Â©ro du traitement de chargement du fichier : ' || g_loader_request_id);

            -- Attente de la fin du traitement
            IF NOT (Fnd_Concurrent.wait_for_request (g_loader_request_id, g_tempo, 0, v_phase, v_status, v_dev_phase, v_dev_status, v_message))
            THEN
                p_Errbuf  := v_Message;
                Fnd_file.put_line(Fnd_file.log, 'ERREUR : Attente de la fin du programme de chargement du fichier dÃ¿Â©passÃ¿Â©e : Fin du traitement' || CHR(10) ||
                                                'MESSAGE : ' || v_Message || CHR(10) );
            END IF;

            IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL')
            THEN
                Fnd_File.put_line(Fnd_File.LOG, 'COMPLETION= ' || v_dev_phase || '/' || v_dev_status);
                --Fnd_File.put_line(Fnd_File.OUTPUT, '. Statut de fin : ' || v_phase || '/' || v_status);

               /*
         SELECT count(1)
                INTO g_summary.loaded_header_rows
                FROM DKA_IPOREC_INTERFACE
                WHERE  LOADER_REQUEST_ID = g_loader_request_id
                ;
                */
                -- Phase insertion la table d archive
                BEGIN
                    insert into DKA_IPOREC_HIST_INTERFACE
                    select * from DKA_IPOREC_INTERFACE
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
                             where message_name like 'DKA_IPOREC_003'
                               and Language_code='F';
                        exception
                        WHEN OTHERS
                        THEN
                            p_errbuf:='Echec du chargement des donnÃ¿Â©es dans la table dÃ¿Â¿archive';
                        END;
                        Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
                        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procÃ¿Â©dure Launch_Loader : EXCEPTION OTHERS ');
                END;

                -- Phase insertion la table de reporting
                BEGIN
                    insert into DKA_IPOREC_REPORTING_INTERFACE
                    select * from DKA_IPOREC_INTERFACE
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
                             where message_name like 'DKA_IPOREC_004'
                               and Language_code='F';
                        EXCEPTION
                        WHEN OTHERS
                        THEN
                            p_errbuf:='Echec du chargement des donnÃ¿Â©es dans la table de reporting';
                        END;
                        Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
                        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procÃ¿Â©dure Launch_Loader : EXCEPTION OTHERS ');
                END;
  /*
                SELECT count(1)
                INTO g_summary.loaded_transaction_rows
                FROM DKA_IPOREC_INTERFACE
                WHERE  LOAD_REQUEST_ID = g_loader_request_id;
   */

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
        fnd_stats.gather_table_stats('DKA', 'DKA_IPOREC_INTERFACE', dbms_stats.auto_sample_size);
        -- fnd_stats.gather_table_stats('DKA', 'DKA_RCV_TRANSACTIONS_TMP', dbms_stats.auto_sample_size); -- SELO

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin Launch_Loader');

  EXCEPTION
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'LAUNCH_LOADER : ' ||SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procÃ¿Â©dure Launch_Loader : EXCEPTION OTHERS ');
  END Launch_Loader;

 /*
 *************************************************************************
 * PROCEDURE NAME : Bilan
 *
 * DESCRIPTION
 *  Procedure de generation du bilan du traitement d'interface
 *
 * PARAMETERS
 * ==========
 * NAME                 DESCRIPTION
.* -------------------- ---------------------------------------------------
 * p_errbuf            Retour de message eventuel
 * p_retcode           Statut du traitement en sortie
 ************************************************************************
 */
  PROCEDURE Report_Bilan(p_statut              IN NUMBER)
  IS

  CURSOR cur_err_validate is
    select distinct dii.receipt_num, TABLE_ID, message_text
      from dka_program_messages dpm,
         DKA_IPOREC_INTERFACE dii
     where prog_name ='DKA_IPORECEPTION_IVALUA'
       and table_id=dii.record_id
       and dii.request_id=g_request_id
     and dpm.request_id=g_request_id
     and dpm.message_type='E'
     and dii.statut in ( 'REJECTED')
     order by TABLE_ID;

  --EDB301
  CURSOR cur_err_avertissement is
    select distinct dii.receipt_num, TABLE_ID, message_text
      from dka_program_messages dpm,
         DKA_IPOREC_INTERFACE dii
     where prog_name ='DKA_IPORECEPTION_IVALUA'
       and table_id=dii.record_id
       and dii.request_id=g_request_id
     and dpm.request_id=g_request_id
     and dii.statut = 'WARNING'
     and dpm.message_type='W'
     order by TABLE_ID;


  CURSOR cur_err IS
    SELECT dii.record_id, pie.interface_transaction_id, pie.Table_name, pie.column_name, replace(pie.error_message, CHR(10),' ') error_message,
           dii.receipt_num
      FROM PO_INTERFACE_ERRORS pie,
           RCV_TRANSACTIONS_INTERFACE rti,
           DKA_IPOREC_INTERFACE dii
     WHERE pie.interface_type = 'RCV-856'
       AND dii.interface_transaction_id = rti.interface_transaction_id
       AND nvl(rti.HEADER_INTERFACE_ID,1) = nvl(pie.INTERFACE_HEADER_ID,1)
       AND rti.interface_transaction_id = pie.INTERFACE_line_ID
       AND dii.request_id=g_request_id
     UNION         -- pour ajout des messages d'avertissement
    SELECT dii.record_id, pie.interface_transaction_id, pie.Table_name, pie.column_name, replace(pie.error_message, CHR(10),' ') error_message,
           dii.receipt_num
      FROM PO_INTERFACE_ERRORS pie,
           DKA_IPOREC_INTERFACE dii
     WHERE pie.interface_type = 'RCV-856'
       AND dii.interface_transaction_id = pie.INTERFACE_line_ID
       AND dii.request_id=g_request_id;

    CURSOR cur_processeur IS
    SELECT req.request_id , decode (req.STATUS_CODE  , 'C', 'Normal', 'G' , 'Avertissement', 'Erreur') STATUS_CODE
      FROM fnd_concurrent_requests req, fnd_concurrent_programs_tl pro
     WHERE     1 = 1
       and  req.PARENT_REQUEST_ID=g_REQUEST_ID
       AND req.concurrent_program_id = pro.concurrent_program_id
       and user_concurrent_program_name = 'Receiving Transaction Processor'
     order by  req.request_id
       ;
     cv_line    VARCHAR2(100);
     V_STATUT   VARCHAR2(15);
  BEGIN

        cv_line    := '----------------------------------------------------------------------------------';


        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Debut Report_Bilan');

        --------------------
        -- Initialisation --
        --------------------

       BEGIN
            UPDATE DKA_IPOREC_REPORTING_INTERFACE diri
               SET diri.Statut = (select statut
                                    from DKA_IPOREC_INTERFACE dii
                                   where dii.record_id=diri.record_id
                                     and dii.request_id=g_request_id)
                                  where exists (select distinct 1
                             from DKA_IPOREC_INTERFACE dii
                            where dii.record_id=diri.record_id);

             UPDATE DKA_IPOREC_REPORTING_INTERFACE diri
                SET diri.Statut = 'DELETED'
              where not exists (select distinct 1
                                    from DKA_IPOREC_INTERFACE dii
                                   where dii.record_id=diri.record_id
                                     and dii.request_id=g_request_id)
            AND STATUT <> 'COMPLETE';
    EXCEPTION
      when others then
        null;
    END;
        BEGIN
        -- SELO EDB301 DEBUT
           SELECT count(1)
              INTO g_summary.rejected_header_rows
              FROM DKA_IPOREC_INTERFACE
             WHERE STATUT = 'REJECTED'
            ;
      /*
      select count(1) INTO g_summary.rejected_header_rows
        from dka_program_messages dpm,
           DKA_IPOREC_INTERFACE dii
       where prog_name ='DKA_IPORECEPTION_IVALUA'
         and table_id=dii.record_id
         and dii.request_id=g_request_id
         and dpm.request_id=g_request_id
         and dpm.message_type='E'
         and dii.statut = 'REJECTED'
         group by  dii.receipt_num, TABLE_ID    ; */

      select count(dii.receipt_num) INTO g_summary.warning_header_rows
        from dka_program_messages dpm,
           DKA_IPOREC_INTERFACE dii
       where prog_name ='DKA_IPORECEPTION_IVALUA'
         and table_id=dii.record_id
         and dii.request_id=g_request_id
         and dpm.request_id=g_request_id
         and dpm.message_type='W'
         and dii.statut = 'WARNING'
         --group by  dii.receipt_num, TABLE_ID
         ;

            IF g_summary.warning_header_rows <> 0 THEN
                g_summary.warning_flag     :='Y';
            END IF;

        -- SELO EDB301 FIN

            SELECT count(1)
              INTO g_summary.rejected_io_rows
              FROM DKA_IPOREC_INTERFACE
             WHERE STATUT = 'REJECTED_OI'
            ;

            SELECT count(1)
              INTO g_summary.complete_header_rows
              FROM DKA_IPOREC_INTERFACE
             WHERE STATUT = 'COMPLETE'
            ;

      --g_summary.complete_header_rows := g_summary.complete_header_rows - g_summary.warning_header_rows; -- SELO EDB301

      SELECT count(1)
              INTO g_summary.loaded_header_rows
              FROM DKA_IPOREC_INTERFACE;

            SELECT count(1)
              INTO g_summary.rec_final_rows
              FROM DKA_IPOREC_INTERFACE
             WHERE STATUT = 'COMPLETE'
               AND flag_rec_finale = 'Y';

--< BNZ EDB375

      SELECT count(1)
              INTO g_summary.header_rows
            FROM (select distinct * from dka.DKA_IPOREC_REJECT
      where Blocage = 'Header'
    and statut_cmd = New_statut_cmd
    and request_id = g_REQUEST_ID); -- and

      SELECT count(1)
              INTO g_summary.Line_rows
            FROM (select distinct * from dka.DKA_IPOREC_REJECT
      where Blocage = 'Line'
    and statut_cmd = New_statut_cmd
    and request_id = g_REQUEST_ID);



         SELECT count(1)
        INTO g_summary.rec_rows_traite
            FROM(select distinct dir.* from DKA_IPOREC_INTERFACE dii, dka.DKA_IPOREC_REJECT dir
            WHERE dii.DOCUMENT_NUM = dir.num_cmd
            and dii.RECEIPT_NUM = dir.receipt_num
        and dir.statut_cmd = dir.New_statut_cmd
                AND dii.STATUT = 'COMPLETE'
          and dii.request_id = g_REQUEST_ID);

       SELECT count(1)
              INTO g_summary.rec_rows_no_traite
             FROM(select distinct dir.* from dka.DKA_IPOREC_REJECT dir, DKA_IPOREC_INTERFACE dii
      where dii.document_num = dir.num_cmd
      and dii.RECEIPT_NUM = dir.receipt_num
      and dir.statut_cmd = dir.New_statut_cmd
      AND dii.STATUT != 'COMPLETE'
      and dir.request_id = g_REQUEST_ID) ;




-->BNZ EDB375


            select decode(p_statut, 0, 'Normal', 1, 'Avertissement', 2, 'Erreur') into v_statut
          from dual;
    EXCEPTION
      when others then
        null;
    END;
        Fnd_File.put_line (Fnd_File.output, 'Processeur des mouvements de reception :');

    FOR rec_cur_processeur IN cur_processeur LOOP
            Fnd_File.put_line (Fnd_File.output, 'Numero de traitement : '||rec_cur_processeur.request_id ||' Statut : ' ||rec_cur_processeur.STATUS_CODE );
        END LOOP;
    --    Fnd_File.put_line (Fnd_File.output, 'Numero de traitement : '||g_REQUEST_ID ||' Statut : ' ||v_statut);
        Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10)|| CHR(10));
        Fnd_File.put_line (Fnd_File.output, 'MOUVEMENTS DE RECEPTION : ');

       -- fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre des transactions chargees dans la table specifique                   : ' ||TO_CHAR(g_summary.loaded_transaction_rows));





     --   fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''enregistrements inseres dans la table RCV_HEADERS_INTERFACE        : ' || TO_CHAR(g_summary.inserted_header_rows));
     --   fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''enregistrements inseres dans la table RCV_TRANSACTIONS_INTERFACE   : ' || TO_CHAR(g_summary.inserted_transaction_rows));


    fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''enregistrements a traiter                                          : '||TO_CHAR(g_summary.loaded_header_rows));
    fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''enregistrements traites avec succes :                              : '||TO_CHAR(g_summary.complete_header_rows));

    fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''enregistrements rejetes (phase de validation)                      : ' || TO_CHAR(g_summary.rejected_header_rows));
    fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''enregistrements en avertissement (phase validation)                : ' || TO_CHAR(g_summary.warning_header_rows));
    fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''enregistrements rejetes (open interface)                           : ' || TO_CHAR(g_summary.rejected_io_rows) || CHR(10));
    fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''enregistrements traites pour reception finale                      : ' || TO_CHAR(g_summary.rec_final_rows) || CHR(10));
 --< BNZ EDB375

    fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre des commandes reouvertes au niveau de la partie entete               : ' || TO_CHAR(g_summary.header_rows));
    fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre des commandes reouvertes au niveau des lignes                        : ' || TO_CHAR(g_summary.Line_rows));
    fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre des receptions integrees apres la reouverture des commandes          : ' || TO_CHAR(g_summary.rec_rows_traite));
    fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre des receptions non traitees malgre la reouverture des commandes      : ' || TO_CHAR(g_summary.rec_rows_no_traite));





 Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10));
        Fnd_File.put_line (Fnd_File.output, 'Liste des commandes reouvertes : ');
    FOR rec_cur_reouverte IN (SELECT distinct dir.*
            FROM dka.DKA_IPOREC_REJECT dir, DKA_IPOREC_INTERFACE dii
      where dii.DOCUMENT_NUM = dir.num_cmd and dii.RECEIPT_NUM = dir.receipt_num
            and dir.statut_cmd = dir.new_statut_cmd
            and dir.request_id = g_REQUEST_ID
            order by dir.receipt_num ) LOOP
            Add_Message2(rec_cur_reouverte.RECEIPT_NUM, TO_CHAR(rec_cur_reouverte.id_cmd), rec_cur_reouverte.num_cmd, rec_cur_reouverte.id_ligne , rec_cur_reouverte.blocage);
        END LOOP;
g_summary.message_flag := 0; -- BNZ
Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10));
        Fnd_File.put_line (Fnd_File.output, 'Liste des receptions integrees apres la reouverture des commandes : ');
    FOR rec_cur_reouverte_int IN (SELECT distinct dir.*
            FROM dka.DKA_IPOREC_REJECT dir, DKA_IPOREC_INTERFACE dii
      where dii.document_num = dir.num_cmd and statut_cmd = New_statut_cmd and dii.RECEIPT_NUM = dir.receipt_num
        AND dii.STATUT = 'COMPLETE'
          and dir.request_id = g_REQUEST_ID
          order by dir.receipt_num) LOOP
           Add_Message2(rec_cur_reouverte_int.RECEIPT_NUM, TO_CHAR(rec_cur_reouverte_int.id_cmd), rec_cur_reouverte_int.num_cmd,rec_cur_reouverte_int.id_ligne, rec_cur_reouverte_int.blocage);

       END LOOP;
g_summary.message_flag := 0;

Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10));
        Fnd_File.put_line (Fnd_File.output, 'Liste des receptions non traitees malgre la reouvertes de la commande : ');
    FOR rec_cur_reouverte_no IN (SELECT distinct dir.*
            FROM dka.DKA_IPOREC_REJECT dir, DKA_IPOREC_INTERFACE dii
      where dii.document_num = dir.num_cmd and dii.RECEIPT_NUM = dir.receipt_num and statut_cmd = New_statut_cmd
        AND dii.STATUT != 'COMPLETE'
      and dir.request_id = g_REQUEST_ID
      order by dir.receipt_num
                 ) LOOP
           Add_Message2(rec_cur_reouverte_no.RECEIPT_NUM, TO_CHAR(rec_cur_reouverte_no.id_cmd), rec_cur_reouverte_no.num_cmd, rec_cur_reouverte_no.id_ligne , rec_cur_reouverte_no.blocage);

       END LOOP;




--> EDB375 BNZ
g_summary.message_flag := 0; -- BNZ


    Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10));
        Fnd_File.put_line (Fnd_File.output, 'Liste des rejets de validation : ');
    FOR rec_cur_err_validate IN cur_err_validate LOOP
            Add_Message(rec_cur_err_validate.RECEIPT_NUM, rec_cur_err_validate.TABLE_ID, rec_cur_err_validate.message_text, rec_cur_err_validate.receipt_num);

        END LOOP;

    Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10));
        Fnd_File.put_line (Fnd_File.output, 'Liste des avertissements de validation : ');
    FOR rec_cur_err_avertissement IN cur_err_avertissement LOOP
            Add_Message(rec_cur_err_avertissement.RECEIPT_NUM, rec_cur_err_avertissement.TABLE_ID, rec_cur_err_avertissement.message_text, rec_cur_err_avertissement.receipt_num);

        END LOOP;



    g_summary.message_flag := 0;

    Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10));
        Fnd_File.put_line (Fnd_File.output, 'Liste des rejets OI : ');

    FOR rec_cur_err IN cur_err LOOP
            Add_Message(rec_cur_err.receipt_num, rec_cur_err.RECORD_ID, rec_cur_err.error_message, rec_cur_err.receipt_num);
            DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                            'DKA_IPORECEPTION_IVALUA', --prog_name
                                            'RECEPTION',               --source
                                            'DKA_IPOREC_INTERFACE' ,   --table_name
                                            rec_cur_err.RECORD_ID,  --table_id
                                            rec_cur_err.column_name,  --column_name
                                            'RCV_TRANSACTIONS_INTERFACE', --column_value
                                            'E',                       --message_type
                                            rec_cur_err.error_message                   --message_text
                                            );
        END LOOP;

        fnd_file.put_line(fnd_file.OUTPUT,CHR(10));
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin Report_Bilan');


  END Report_Bilan;
/**************************************************************************
 * PROCEDURE NAME : set_recovery_mode
 *
 * DESCRIPTION
 *  ProcÃ¿Â©dure d'initialisation du mode reprise (Pas de fichier en entrÃ¿Â©e)
 *
 * PARAMETERS
 * ==========
 * NAME               DESCRIPTION
 * -----------------  ------------------------------------------------------
 *
 *************************************************************************/
/*  PROCEDURE set_recovery_mode(p_Errbuf            OUT VARCHAR2,
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
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procÃ¿Â©dure SET_RECOVERY_MODE : EXCEPTION OTHERS ');
  END set_recovery_mode;
*/
 -------------------------------------------------------------------------------------
 -- PROCEDURE NAME : init_status_oi
 -- DESCRIPTION : Initialisation du statut des lignes en erreur dans l'open interface
 --               afin qu'elles soient retraitÃ¿Â©es lors de l'import dans Oracle
 -------------------------------------------------------------------------------------
/*  PROCEDURE init_status_oi(p_Errbuf   OUT VARCHAR2,
                           p_retcode  OUT NUMBER)
  IS

  BEGIN

    Fnd_File.Put_Line(Fnd_File.LOG, to_char(sysdate, 'DD/MM/YYYY HH24:MI:SS')||' - '||'DÃ¿Â©but init_status_oi');

    UPDATE rcv_headers_interface rhi
    SET   --Rhi.Transaction_Type = 'ADD'
          Rhi.Transaction_Type = Nvl(   (Select 'ADD'
                                         from rcv_shipment_headers rsh
                                         Where Rsh.Receipt_Num = Rhi.Receipt_Num
                                         And Rsh.ship_to_Org_Id = Rhi.Org_Id
                                        )   , 'NEW' )
        , Rhi.Processing_Status_Code = 'PENDING'
        , Processing_Request_Id = Null
        , Receipt_Header_Id = Null
        , Validation_Flag = 'Y'
        , Packing_Slip = Null
        ,last_update_date = sysdate
    where exists (select 'exists'
                  from rcv_shipment_headers rsh
                  where rsh.receipt_num = rhi.receipt_num
                  And Rsh.ship_to_Org_Id = Rhi.Org_Id
                 )
    AND NOT EXISTS (select 'exists'
                      from rcv_shipment_headers rsh
                      join rcv_shipment_lines   rsl on(rsl.shipment_header_id = rsh.shipment_header_id)
                      where rsh.receipt_num = rhi.receipt_num
                      And Rsh.ship_to_Org_Id = Rhi.Org_Id
                )
    ;


    UPDATE Rcv_Headers_Interface Rhi
    SET  Rhi.Transaction_Type = Nvl(   (Select 'ADD'
                                        from rcv_shipment_headers rsh
                                        Where Rsh.Receipt_Num = Rhi.Receipt_Num
                                        And Rsh.Ship_To_Org_Id = Rhi.Org_Id
                                        )   , 'NEW' )
        , Rhi.Processing_Status_Code = 'PENDING'
        , Processing_Request_Id = Null
        , Receipt_Header_Id = Null
        , Validation_Flag = 'Y'
        , Packing_Slip = Null
        ,last_update_date = sysdate
    where rhi.processing_status_code = 'ERROR'
      and exists (select 'exists'
                  from dka_rcv_headers_tmp drh
                  where 'REP'||drh.receipt_num =  rhi.receipt_num  -- OBE artf2184213
                    --and drh.vendor_num = rhi.vendor_num                     comment
                    --and drh.vendor_site_code = rhi.vendor_site_code         comment
                    and drh.org_id = rhi.org_id
                    and drh.flag = 'T'
                  )
    ;

    UPDATE rcv_transactions_interface rti
    SET rti.processing_status_code = 'PENDING',
        rti.transaction_status_code = 'PENDING'
        --
        ,last_update_date = sysdate
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
                    --and drt.vendor_num = rti.vendor_num                         comment
                    --and drt.vendor_site_code = rti.vendor_site_code             comment
                    --and drt.ship_to_location = rti.ship_to_location_code         comment
                    and drt.org_id = rti.org_id
                    and drt.transaction_type = rti.transaction_type
                    and drt.flag = 'T'
                 );

    Fnd_File.Put_Line(Fnd_File.LOG, 'Nb de lignes avec statut mis Ã¿Â  jour dans l''OI des rÃ¿Â©ceptions: '||to_char(sql%rowcount));
    Fnd_File.Put_Line(Fnd_File.LOG, to_char(sysdate, 'DD/MM/YYYY HH24:MI:SS')||' - '||'Fin init_status_oi');

    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      p_retcode   := 2;
      p_errbuf    := 'INIT STATUS OI : ' ||SQLERRM;
      Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
      Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procÃ¿Â©dure INIT_STATUS_OI : EXCEPTION OTHERS ');
  END init_status_oi;
*/
/* *************************************************************************
 * PROCEDURE NAME : purge_data
 *
 * DESCRIPTION
 *  ProcÃ¿Â©dure de purge des donnÃ¿Â©es
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
     Fnd_File.Put_Line(Fnd_File.LOG, '-> RCV_HEADERS_INTERFACE - Complete' );
     DELETE FROM RCV_HEADERS_INTERFACE rhi
      where rhi.processing_status_code = 'SUCCESS'
        and exists (select distinct 1
                      from DKA_IPOREC_INTERFACE dii
                     where rhi.receipt_num=dii.receipt_num
                       and rhi.org_id=dii.org_id
                       and STATUT = 'COMPLETE');


     g_summary.purged_interface_rows := SQL%ROWCOUNT;
    -- Fnd_File.Put_Line(Fnd_File.LOG, '=> Deleted rows '||TO_CHAR(g_summary.purged_interface_rows));

     Fnd_File.Put_Line(Fnd_File.LOG, '-> PO_INTERFACE_ERRORS' );
     delete from PO_INTERFACE_ERRORS pie
            where pie.interface_type = 'RCV-856'
              and interface_header_id in (select rhi.header_interface_id
                                            from rcv_headers_interface rhi,
                                                 RCV_TRANSACTIONS_INTERFACE rti,
                                                 DKA_IPOREC_INTERFACE dii
                                           where rhi.header_interface_id = rti.header_interface_id
                                             and rti.INTERFACE_TRANSACTION_ID = dii.INTERFACE_TRANSACTION_ID
                                             and rhi.org_id=dii.org_id
                                             and STATUT = 'REJECTED_OI');

     g_summary.purged_errors_rows := SQL%ROWCOUNT;
     Fnd_File.Put_Line(Fnd_File.LOG, '=> Deleted rows dans la table PO_INTERFACE_ERRORS :'||TO_CHAR(g_summary.purged_errors_rows));

     Fnd_File.Put_Line(Fnd_File.LOG, '-> RCV_HEADERS_INTERFACE - Erreur' );
     DELETE FROM RCV_HEADERS_INTERFACE rhi
      where rhi.processing_status_code = 'ERROR'
        and exists (select distinct 1
                      from DKA_IPOREC_INTERFACE dii
                     where rhi.receipt_num=dii.receipt_num
                       and rhi.org_id=dii.org_id
                       and STATUT = 'REJECTED_OI');


     g_summary.purged_interface_rows := g_summary.purged_interface_rows+ SQL%ROWCOUNT;
     Fnd_File.Put_Line(Fnd_File.LOG, '=> Deleted rows dans la table RCV_HEADERS_INTERFACE avec le statut SUCESS ou ERREUR :'||TO_CHAR(g_summary.purged_interface_rows));


     Fnd_File.Put_Line(Fnd_File.LOG, '-> RCV_TRANSACTIONS_INTERFACE' );
    delete from RCV_TRANSACTIONS_INTERFACE rti
     where exists (select distinct 1
                     from DKA_IPOREC_INTERFACE dii
                   where rti.INTERFACE_TRANSACTION_ID = dii.INTERFACE_TRANSACTION_ID
                     and STATUT = 'REJECTED_OI')
       and rti.processing_status_code = 'ERROR';

     g_summary.purged_transaction_rows := SQL%ROWCOUNT;
     Fnd_File.Put_Line(Fnd_File.LOG, '=> Deleted rows dans la table RCV_TRANSACTIONS_INTERFACE :'||TO_CHAR(g_summary.purged_transaction_rows));


    DELETE FROM dka_program_messages dpm
     where prog_name ='DKA_IPORECEPTION_IVALUA'
       and table_id in (select dii.record_id
                          from DKA_IPOREC_INTERFACE dii
                         where dii.request_id <> g_request_id
                         and dpm.request_id=dii.request_id
               and dii.STATUT in ('REJECTED','REJECTED_OI'));

     Fnd_File.Put_Line(Fnd_File.LOG, '-> DKA_IPOREC_INTERFACE' );
     DELETE FROM DKA_IPOREC_INTERFACE
     where STATUT = 'COMPLETE';

   --EDB301
   DELETE FROM DKA_IPOREC_INTERFACE
     where STATUT = 'WARNING';

     g_summary.purged_header_rows := SQL%ROWCOUNT;
     Fnd_File.Put_Line(Fnd_File.LOG, '=> Deleted rows dans la table DKA_IPOREC_INTERFACE :'||TO_CHAR(g_summary.purged_header_rows));


      --EDB375
  DELETE FROM DKA_IPOREC_REJECT;
  Fnd_File.Put_Line(Fnd_File.LOG, '=> Deleted rows dans la table DKA_IPOREC_REJECT ');

   update DKA_IPOREC_INTERFACE
        set STATUT = 'NEW';


  EXCEPTION
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'PURGE_DATA : ' ||SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procÃ¿Â©dure PURGE_DATA : EXCEPTION OTHERS ');
  END purge_data;

 /*
 *************************************************************************
 * PROCEDURE NAME : main
 *
 * DESCRIPTION
 *  ProcÃ¿Â©dure principale
 *
 * PARAMETERS
 * ==========
 * NAME              DESCRIPTION
 * ----------------- ------------------------------------------------------
 * p_errbuf          Retour de message Ã¿Â©ventuel
 * p_retcode         Statut du traitement en sortie
 ************************************************************************
 */

PROCEDURE main(
                p_Errbuf    IN OUT  VARCHAR2,
                p_retcode   OUT     NUMBER,
                p_reprise   IN      VARCHAR2--,
              --  p_gl_date       IN VARCHAR2
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

      ELSE
        null; --SELO
      END IF;

      -- Maj des champs societe/region
    /*  update_region_societe(v_errbuf,
                            v_retcode
                           );

      IF v_retcode = 2
      THEN
          RAISE Erreur_Programme;
      END IF;
      */  --

    -- Traitement des nouvelles receptions
      -- Lancement de validation des donnÃ¿Â©es

    validate_data(v_errbuf,
                    v_retcode,
          'RECEIVE'
                   );
      IF v_retcode = 2
      THEN
          RAISE Erreur_Programme;
      END IF;

      -- Lancement de l'insertion des donnÃ¿Â©es
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

      update_REC(v_errbuf,
                   v_retcode
                   );
      IF v_retcode = 2
      THEN
          RAISE Erreur_Programme;
      END IF;

    -- Traitement des corrections sur des receptions
      -- Lancement de validation des donnÃ¿Â©es

    validate_data(v_errbuf,
                    v_retcode,
          'CORRECT_ADD'
                   );
      IF v_retcode = 2
      THEN
          RAISE Erreur_Programme;
      END IF;

      -- Lancement de l'insertion des donnÃ¿Â©es
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

      update_REC(v_errbuf,
                   v_retcode
                   );
      IF v_retcode = 2
      THEN
          RAISE Erreur_Programme;
      END IF;

/*
  -- Traitement ajout de receptions
      -- Lancement de validation des donnÃ¿Â©es
    validate_data(v_errbuf,
                    v_retcode,
          'ADD'
                   );
      IF v_retcode = 2
      THEN
          RAISE Erreur_Programme;
      END IF;

      -- Lancement de l'insertion des donnÃ¿Â©es
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

      update_REC(v_errbuf,
                   v_retcode
                   );
      IF v_retcode = 2
      THEN
          RAISE Erreur_Programme;
      END IF;
      */

        -- bilan
      Report_Bilan(p_retcode);

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
         p_errbuf := 'ATTENTION : Aucun enregistrement chargÃ¿Â©.';
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
            Fnd_File.put_line (Fnd_File.OUTPUT, CHR(10)||p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procÃ¿Â©dure '||v_current_program_unit||' : EXCEPTION Erreur_Traitement ');
            Fnd_File.put_line (Fnd_File.OUTPUT, '==> Fin de la procÃ¿Â©dure '||v_current_program_unit||' : EXCEPTION Erreur_Traitement ');
       WHEN OTHERS
       THEN
           fnd_concurrent.af_rollback;
           p_retcode := 2;
           Fnd_File.put_line (Fnd_File.Log,'Erreur technique sur le composant   : '||'DKA_IPORECEPTION_IVALUA_PKG.' || v_current_program_unit||CHR(10)||'A retournÃ¿Â©     : '||SQLERRM);
           Fnd_File.put_line (Fnd_File.Output ,CHR(10) || '==> Erreur technique (voir journal du traitement)' || CHR(10));
           p_errbuf := SQLERRM;
  END main;

------------------------------------------------------
END DKA_IPORECEPTION_IVALUA_PKG;
/
SHOW ERRORS
EXIT 