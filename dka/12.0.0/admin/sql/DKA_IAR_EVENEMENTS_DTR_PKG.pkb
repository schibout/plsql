CREATE OR REPLACE PACKAGE BODY DKA_IAR_EVENEMENTS_DTR_PKG AS
  ----------------------------------------------------------------------------------------------
  -- $Id$
  -- CAPGEMINI
  -- PROJET            : DALKIA Oracle Applications
  -- NOM               : DKA_IAR_EVENEMENTS_DTR_PKG.pkb
  -- DESCRIPTION       : DKA_IAR_EVENEMENTS_DTR_PKG package body :
  ---
  --- AUTEUR           : Oussama BENHAYOUN
  --- DATE DE CREATION : 19/09/2017
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE       : 
  ----------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- ---------- --- ---------------------------------------------------------------------------
  --- 26/09/2017 OBE artf2227837 : INT082 - Nom des fichiers à corriger + Vue DKA  
  --- 15/11/2017 MEG artf2277408 : INT082 - Nom du fichier AR_EVENT errone
  --- 06/02/2018 OBE artf2359496 : INT082 - Extractions Oracle R12 vers DTR - Modification du critère de la date d'extraction
  --- 12/01/2023 IBA EDB353
  --- 18/10/2023 BNZ EDB371 : Suppression des caractères parasites lors du traitement DKA : Extraction des évènements AR
  ----------------------------------------------------------------------------------------------

  --EXCEPTIONS
  E_FATAL_ERROR EXCEPTION;
  PRAGMA EXCEPTION_INIT(E_FATAL_ERROR, -20012);
  K_FATAL_ERROR_NUM CONSTANT NUMBER := -20012;

  --CONSTANTE
  cv_package_name CONSTANT VARCHAR2(30) := 'DKA_IAR_EVENEMENTS_DTR_PKG';
  K_SEPARATOR     CONSTANT VARCHAR2(2) := ';';
  K_DIRECTORY     CONSTANT ALL_DIRECTORIES.directory_name%TYPE := 'DKA_OUT_DIR';
  
  gv_message_ledger VARCHAR2(32000) ;

  ------------------------------------------------------------------------------------
  --  Nom           : p_put_debug_message
  --  Description   : Ecrit dans le journal du traitement
  --
  --  PARAMETRES    : Message à afficher dans le journal  
  --
  ------------------------------------------------------------------------------------
  PROCEDURE p_put_debug_message(p_message IN VARCHAR2) IS
  
  BEGIN
  
    dka_tools_pkg.put_debug_message(p_message);
  
  END p_put_debug_message;

  ------------------------------------------------------------------------------------
  --  Nom           : p_validate
  --  Description   : 
  --
  --  PARAMETRES    : p_condition: Si FALSE => Affiche un message dans le journal et
  --                                           genere une erreur fatale   
  --                               Si TRUE  => Fait aucune action
  --                  p_message:   Message a afficher dans le journal
  ------------------------------------------------------------------------------------
  PROCEDURE p_validate(p_condition IN BOOLEAN, p_message IN VARCHAR2 DEFAULT NULL) IS
  BEGIN
  
    IF NOT p_condition THEN
      IF p_message IS NOT NULL THEN
        p_put_debug_message(p_message);
      END IF;
    
      RAISE_APPLICATION_ERROR(K_FATAL_ERROR_NUM, nvl(p_message, 'Erreur fatale : '));
    
    END IF;
  
  END p_validate;


  ------------------------------------------------------------------------------------
  --  Nom           : p_check_directory
  --  Description   : Verifie que le directory existe
  --
  --  PARAMETRES    :
  --  p_directory_name          nom du directory    
  --
  ------------------------------------------------------------------------------------
  PROCEDURE p_check_directory(p_directory_name in ALL_DIRECTORIES.directory_name%type) IS
  
    CURSOR cur_directory(p_directory_name IN ALL_DIRECTORIES.directory_name%type) IS
      SELECT owner, directory_name, directory_path FROM all_directories WHERE directory_name = p_directory_name;
    l_dir cur_directory%ROWTYPE;
  
  BEGIN
  
    OPEN cur_directory(p_directory_name);
    FETCH cur_directory
      INTO l_dir;
  
    IF cur_directory%NOTFOUND THEN
      CLOSE cur_directory;
      p_validate(FALSE, 'Le directory ' || p_directory_name || ' n''existe pas.');
    END IF;
  
    CLOSE cur_directory;
  
    p_put_debug_message('p_check_directory :  ' || p_directory_name || ' -> ' || l_dir.directory_path);
  
  END p_check_directory;

  ------------------------------------------------------------------------------------
  --  Nom           : p_extract_data
  --  Description   : Extrait les ecritures comptables vers Hyperion
  --
  --  PARAMETRES    :
  --  p_directory_name        Nom du directory
  --  p_file_name             Nom du fichier
  --  p_nb_lignes             Nombre de lignes inserees
  --  p_nb_lignes_maj         Nombre de lignes flaguees
  --
  ------------------------------------------------------------------------------------
  PROCEDURE p_extract_data(p_directory_name IN ALL_DIRECTORIES.directory_name%type, 
                           p_file_name      IN VARCHAR2,
                           p_nb_lignes      IN OUT VARCHAR2,
                           p_date_der_exc   IN DATE) IS
    
    vv_ligne         VARCHAR2(4000);
    vn_nb_lignes     NUMBER := -1;
    l_file           UTL_FILE.file_type;
            
            
    CURSOR cur_event_ar IS
     SELECT '"'||ROW_ID||'"#$#"'||RECEIVABLE_APPLICATION_ID||'"#$#"'||PAYMENT_SCHEDULE_ID||'"#$#"'||TRX_REC_NUMBER||'"#$#"'||TYPE||'"#$#"'||CLASS||'"#$#"'||APPLY_DATE||'"#$#"'||AMOUNT||'"#$#"'||STATUS||'"#$#"'||STATUS_MEANING||'"#$#"'||CURRENCY||'"#$#"'||TRX_OR_RECEIPT_AMOUNT||'"#$#"'||LINE||'"#$#"'||GL_DATE||'"#$#"'||DISCOUNT||'"#$#"'||TOTAL_AMOUNT||'"#$#"'||CASH_RECEIPT_ID||'"#$#"'||CUSTOMER_TRX_ID||'"#$#"'||ADJUSTMENT_ID||'"#$#"'||ATTRIBUTE_CATEGORY||'"#$#"'||ATTRIBUTE1||'"#$#"'||ATTRIBUTE2||'"#$#"'||ATTRIBUTE3||'"#$#"'||ATTRIBUTE4||'"#$#"'||ATTRIBUTE5||'"#$#"'||ATTRIBUTE6||'"#$#"'||ATTRIBUTE7||'"#$#"'||ATTRIBUTE8||'"#$#"'||ATTRIBUTE9||'"#$#"'||ATTRIBUTE10||'"#$#"'||ATTRIBUTE11||'"#$#"'||ATTRIBUTE12||'"#$#"'||ATTRIBUTE13||'"#$#"'||ATTRIBUTE14||'"#$#"'||ATTRIBUTE15||'"#$#"'||LAST_UPDATED_BY||'"#$#"'||LAST_UPDATE_DATE||'"#$#"'||LAST_UPDATE_LOGIN||'"#$#"'||CREATED_BY||'"#$#"'||CREATION_DATE||'"#$#"'||REASON_CODE||'"#$#"'||REASON_MEANING||'"#$#"'||MATURITY_DATE||'"#$#"'||RECEIPT_STATE||'"#$#"'||APPLIED_PAYMENT_SCHEDULE_ID||'"#$#"'||APPLIED_TERMS_SEQ_NUMBER||'"#$#"'||PS_CLASS||'"#$#"'||LINE_AMOUNT||'"#$#"'||TAX_AMOUNT||'"#$#"'||FREIGHT_AMOUNT||'"#$#"'||CHARGES_AMOUNT||'"#$#"'||APPLICATION_REF_TYPE||'"#$#"'||APPLICATION_REF_TYPE_MEANING||'"#$#"'||APPLICATION_REF_NUM||'"#$#"'||APPLICATION_REF_REASON||'"#$#"'||APPLICATION_REF_REASON_MEANING||'"#$#"'||CUSTOMER_REFERENCE||'"#$#"'||CUSTOMER_REASON||'"#$#"'||COMMENTS||'"#$#"'||REC_ACTIVITY_NAME||'"#$#"'||PURCHASE_ORDER||'"#$#"'||SECONDARY_APPLICATION_REF_NUM||'"#$#"'||SECONDARY_APPLICATION_REF_TYPE||'"#$#"'||SECONDARY_APP_REF_TYPE_MEANING||'"#$#"'||CREATED_BY_NAME||'"#$#"'||UPDATED_BY_NAME||'"'
      ---IBA EDB353  
    AS LIGNE
      FROM
      (
            SELECT 
              'ROW_ID' AS ROW_ID,
              'RECEIVABLE_APPLICATION_ID' AS RECEIVABLE_APPLICATION_ID,
              'PAYMENT_SCHEDULE_ID' AS PAYMENT_SCHEDULE_ID,
              'TRX_REC_NUMBER' AS TRX_REC_NUMBER,
              'TYPE' AS TYPE,
              'CLASS' AS CLASS,
              'APPLY_DATE' AS APPLY_DATE,
              'AMOUNT' AS AMOUNT,
              'STATUS' AS STATUS,
              'STATUS_MEANING' AS STATUS_MEANING,
              'CURRENCY' AS CURRENCY,
              'TRX_OR_RECEIPT_AMOUNT' AS TRX_OR_RECEIPT_AMOUNT,
              'LINE' AS LINE,
              'GL_DATE' AS GL_DATE,
              'DISCOUNT' AS DISCOUNT,
              'TOTAL_AMOUNT' AS TOTAL_AMOUNT,
              'CASH_RECEIPT_ID' AS CASH_RECEIPT_ID,
              'CUSTOMER_TRX_ID' AS CUSTOMER_TRX_ID,
              'ADJUSTMENT_ID' AS ADJUSTMENT_ID,
              'ATTRIBUTE_CATEGORY' AS ATTRIBUTE_CATEGORY,
              'ATTRIBUTE1' AS ATTRIBUTE1,
              'ATTRIBUTE2' AS ATTRIBUTE2,
              'ATTRIBUTE3' AS ATTRIBUTE3,
              'ATTRIBUTE4' AS ATTRIBUTE4,
              'ATTRIBUTE5' AS ATTRIBUTE5,
              'ATTRIBUTE6' AS ATTRIBUTE6,
              'ATTRIBUTE7' AS ATTRIBUTE7,
              'ATTRIBUTE8' AS ATTRIBUTE8,
              'ATTRIBUTE9' AS ATTRIBUTE9,
              'ATTRIBUTE10' AS ATTRIBUTE10,
              'ATTRIBUTE11' AS ATTRIBUTE11,
              'ATTRIBUTE12' AS ATTRIBUTE12,
              'ATTRIBUTE13' AS ATTRIBUTE13,
              'ATTRIBUTE14' AS ATTRIBUTE14,
              'ATTRIBUTE15' AS ATTRIBUTE15,
              'LAST_UPDATED_BY' AS LAST_UPDATED_BY,
              'LAST_UPDATE_DATE' AS LAST_UPDATE_DATE,
              'LAST_UPDATE_LOGIN' AS LAST_UPDATE_LOGIN,
              'CREATED_BY' AS CREATED_BY,
              'CREATION_DATE' AS CREATION_DATE,
              'REASON_CODE' AS REASON_CODE,
              'REASON_MEANING' AS REASON_MEANING,
              'MATURITY_DATE' AS MATURITY_DATE,
              'RECEIPT_STATE' AS RECEIPT_STATE,
              'APPLIED_PAYMENT_SCHEDULE_ID' AS APPLIED_PAYMENT_SCHEDULE_ID,
              'APPLIED_TERMS_SEQ_NUMBER' AS APPLIED_TERMS_SEQ_NUMBER,
              'PS_CLASS' AS PS_CLASS,
              'LINE_AMOUNT' AS LINE_AMOUNT,
              'TAX_AMOUNT' AS TAX_AMOUNT,
              'FREIGHT_AMOUNT' AS FREIGHT_AMOUNT,
              'CHARGES_AMOUNT' AS CHARGES_AMOUNT,
              'APPLICATION_REF_TYPE' AS APPLICATION_REF_TYPE,
              'APPLICATION_REF_TYPE_MEANING' AS APPLICATION_REF_TYPE_MEANING,
              'APPLICATION_REF_NUM' AS APPLICATION_REF_NUM,
              'APPLICATION_REF_REASON' AS APPLICATION_REF_REASON,
              'APPLICATION_REF_REASON_MEANING' AS APPLICATION_REF_REASON_MEANING,
              'CUSTOMER_REFERENCE' AS CUSTOMER_REFERENCE,
              'CUSTOMER_REASON' AS CUSTOMER_REASON,
              'COMMENTS' AS COMMENTS,
              'REC_ACTIVITY_NAME' AS REC_ACTIVITY_NAME,
              'PURCHASE_ORDER' AS PURCHASE_ORDER,
              'SECONDARY_APPLICATION_REF_NUM' AS SECONDARY_APPLICATION_REF_NUM,
              'SECONDARY_APPLICATION_REF_TYPE' AS SECONDARY_APPLICATION_REF_TYPE,
              'SECONDARY_APP_REF_TYPE_MEANING' AS SECONDARY_APP_REF_TYPE_MEANING,
              'CREATED_BY_NAME' AS CREATED_BY_NAME,
              'UPDATED_BY_NAME' AS UPDATED_BY_NAME
            FROM dual)
          UNION ALL
      --< debut BNZ : EDB371
 SELECT
              '"'||ROW_ID||'"#$#"'||RECEIVABLE_APPLICATION_ID||'"#$#"'||PAYMENT_SCHEDULE_ID||'"#$#"'||TRX_REC_NUMBER||'"#$#"'||TYPE||'"#$#"'||CLASS||'"#$#"'||to_char(APPLY_DATE,'YYYY/MM/DD HH24:MI:SS')||'"#$#"'||AMOUNT||'"#$#"'||STATUS||'"#$#"'||STATUS_MEANING||'"#$#"'||CURRENCY||'"#$#"'||TRX_OR_RECEIPT_AMOUNT||'"#$#"'||LINE||'"#$#"'||to_char(GL_DATE,'YYYY/MM/DD HH24:MI:SS')||'"#$#"'||DISCOUNT||'"#$#"'||TOTAL_AMOUNT||'"#$#"'||CASH_RECEIPT_ID||'"#$#"'||CUSTOMER_TRX_ID||'"#$#"'||ADJUSTMENT_ID||'"#$#"'||ATTRIBUTE_CATEGORY||'"#$#"'||ATTRIBUTE1||'"#$#"'||ATTRIBUTE2||'"#$#"'||ATTRIBUTE3||'"#$#"'||ATTRIBUTE4||'"#$#"'||ATTRIBUTE5||'"#$#"'||ATTRIBUTE6||'"#$#"'||ATTRIBUTE7||'"#$#"'||ATTRIBUTE8||'"#$#"'||ATTRIBUTE9||'"#$#"'||ATTRIBUTE10||'"#$#"'||ATTRIBUTE11||'"#$#"'||ATTRIBUTE12||'"#$#"'||ATTRIBUTE13||'"#$#"'||ATTRIBUTE14||'"#$#"'||ATTRIBUTE15||'"#$#"'||LAST_UPDATED_BY||'"#$#"'||to_char(LAST_UPDATE_DATE,'YYYY/MM/DD HH24:MI:SS')||'"#$#"'||LAST_UPDATE_LOGIN||'"#$#"'||CREATED_BY||'"#$#"'||to_char(CREATION_DATE,'YYYY/MM/DD HH24:MI:SS')||'"#$#"'||REASON_CODE||'"#$#"'||REASON_MEANING||'"#$#"'||to_char(MATURITY_DATE,'YYYY/MM/DD HH24:MI:SS')||'"#$#"'||RECEIPT_STATE||'"#$#"'||APPLIED_PAYMENT_SCHEDULE_ID||'"#$#"'||APPLIED_TERMS_SEQ_NUMBER||'"#$#"'||PS_CLASS||'"#$#"'||LINE_AMOUNT||'"#$#"'||TAX_AMOUNT||'"#$#"'||FREIGHT_AMOUNT||'"#$#"'||CHARGES_AMOUNT||'"#$#"'||APPLICATION_REF_TYPE||'"#$#"'||APPLICATION_REF_TYPE_MEANING||'"#$#"'||APPLICATION_REF_NUM||'"#$#"'||APPLICATION_REF_REASON||'"#$#"'||APPLICATION_REF_REASON_MEANING||'"#$#"'||CUSTOMER_REFERENCE||'"#$#"'||CUSTOMER_REASON||'"#$#"'||COMMENTS||'"#$#"'||REC_ACTIVITY_NAME||'"#$#"'||PURCHASE_ORDER||'"#$#"'||SECONDARY_APPLICATION_REF_NUM||'"#$#"'||SECONDARY_APPLICATION_REF_TYPE||'"#$#"'||SECONDARY_APP_REF_TYPE_MEANING||'"#$#"'||CREATED_BY_NAME||'"#$#"'||UPDATED_BY_NAME||'"'
          ---IBA EDB353  
          FROM
              (
          SELECT  app.receivable_application_id ROW_ID,
                  app.receivable_application_id RECEIVABLE_APPLICATION_ID,
          app.applied_payment_schedule_id PAYMENT_SCHEDULE_ID, 
          replace(replace( replace(ps.trx_number,'''',' '), ',', ' '),'"',' ') TRX_REC_NUMBER,
         replace(replace( replace(DECODE (app.application_type, 'CM', ctt.NAME, rm.NAME),'''',' '), ',', ' '),'"',' ') TYPE,
         replace(replace( replace((apps.arpt_sql_func_util.get_lookup_meaning ('INV/CM', ps.CLASS)),'''',' '), ',', ' '),'"',' ') CLASS,
          app.apply_date APPLY_DATE, 
          -NVL (app.amount_applied_from, app.amount_applied) AMOUNT,
          replace(replace( replace(app.status,'''',' '), ',', ' '),'"',' ') STATUS,
          replace(replace( replace((apps.arpt_sql_func_util.get_lookup_meaning('PAYMENT_TYPE', app.status)),'''',' '), ',', ' '),'"',' ') /* Bug 2758730: Currency is selected from PS instead of CR */ STATUS_MEANING,
          replace(replace( replace(ps.invoice_currency_code,'''',' '), ',', ' '),'"',' ') CURRENCY,
          -app.amount_applied TRX_OR_RECEIPT_AMOUNT, 
          ctl.line_number LINE,
          app.gl_date GL_DATE,
          - (  NVL (app.earned_discount_taken, 0)
           + NVL (app.unearned_discount_taken, 0)
          ) DISCOUNT,
          - (  app.amount_applied
           + NVL (app.earned_discount_taken, 0)
           + NVL (app.unearned_discount_taken, 0)
          ) TOTAL_AMOUNT,
          app.cash_receipt_id CASH_RECEIPT_ID, 
          app.customer_trx_id CUSTOMER_TRX_ID, 
          TO_NUMBER (NULL) ADJUSTMENT_ID,
          replace(replace( replace(app.attribute_category ,'''',' '), ',', ' '),'"',' ') ATTRIBUTE_CATEGORY, 
          replace(replace( replace(app.attribute1,'''',' '), ',', ' '),'"',' ') ATTRIBUTE1, 
          replace(replace( replace(app.attribute2,'''',' '), ',', ' '),'"',' ') ATTRIBUTE2,
          replace(replace( replace(app.attribute3,'''',' '), ',', ' '),'"',' ') ATTRIBUTE3, 
          replace(replace( replace(app.attribute4,'''',' '), ',', ' '),'"',' ') ATTRIBUTE4, 
          replace(replace( replace(app.attribute5,'''',' '), ',', ' '),'"',' ') ATTRIBUTE5, 
          replace(replace( replace(app.attribute6,'''',' '), ',', ' '),'"',' ') ATTRIBUTE6,
          replace(replace( replace(app.attribute7,'''',' '), ',', ' '),'"',' ') ATTRIBUTE7, 
          replace(replace( replace(app.attribute8,'''',' '), ',', ' '),'"',' ') ATTRIBUTE8, 
          replace(replace( replace(app.attribute9,'''',' '), ',', ' '),'"',' ') ATTRIBUTE9, 
          replace(replace( replace(app.attribute10,'''',' '), ',', ' '),'"',' ') ATTRIBUTE10,
          replace(replace( replace(app.attribute11,'''',' '), ',', ' '),'"',' ') ATTRIBUTE11, 
          replace(replace( replace(app.attribute12,'''',' '), ',', ' '),'"',' ') ATTRIBUTE12, 
          replace(replace( replace(app.attribute13,'''',' '), ',', ' '),'"',' ') ATTRIBUTE13, 
          replace(replace( replace(app.attribute14,'''',' '), ',', ' '),'"',' ') ATTRIBUTE14,
          replace(replace( replace(app.attribute15,'''',' '), ',', ' '),'"',' ') ATTRIBUTE15, 
          app.last_updated_by LAST_UPDATED_BY, 
          app.last_update_date LAST_UPDATE_DATE,
          app.last_update_login LAST_UPDATE_LOGIN, 
          app.created_by CREATED_BY, 
          app.creation_date CREATION_DATE,
          replace(replace( replace(ct.reason_code,'''',' '), ',', ' '),'"',' ') REASON_CODE,
           replace(replace( replace((NVL
           (apps.arpt_sql_func_util.get_lookup_meaning ('INVOICING_REASON',
                                  ct.reason_code
                                 ),
            apps.arpt_sql_func_util.get_lookup_meaning
                                ('CREDIT_MEMO_REASON',
                                 ct.reason_code
                                )
           )),'''',' '), ',', ' '),'"',' ') REASON_MEANING,
           
          DECODE (app.application_type, 'CASH', ps.due_date, NULL) MATURITY_DATE,
          replace(replace( replace((apps.arpt_sql_func_util.get_lookup_meaning
                               ('RECEIPT_CREATION_STATUS',
                              crh.status
                               ) ),'''',' '), ',', ' '),'"',' ') RECEIPT_STATE,
          ps.payment_schedule_id APPLIED_PAYMENT_SCHEDULE_ID, 
          ps.terms_sequence_number APPLIED_TERMS_SEQ_NUMBER, 
          replace(replace( replace(ps.CLASS,'''',' '), ',', ' '),'"',' ') PS_CLASS,
          -app.line_applied LINE_AMOUNT, 
          -app.tax_applied TAX_AMOUNT, 
          -app.freight_applied FREIGHT_AMOUNT,
          -app.receivables_charges_applied CHARGES_AMOUNT, 
          replace(replace( replace(app.application_ref_type,'''',' '), ',', ' '),'"',' ') APPLICATION_REF_TYPE,
          replace(replace( replace((apps.arpt_sql_func_util.get_lookup_meaning
           (DECODE (app.applied_payment_schedule_id,
                -7, 'AR_PREPAYMENT_TYPE',
                'APPLICATION_REF_TYPE'
               ),
            app.application_ref_type
           )),'''',' '), ',', ' '),'"',' ') APPLICATION_REF_TYPE_MEANING,
           
          replace(replace( replace(app.application_ref_num,'''',' '), ',', ' '),'"',' ') APPLICATION_REF_NUM, 
          replace(replace( replace(app.application_ref_reason,'''',' '), ',', ' '),'"',' ') APPLICATION_REF_REASON,
          replace(replace( replace((DECODE
           (app.application_ref_type,
            'CLAIM', apps.arp_deduction.get_tm_oracle_reason
                           (app.secondary_application_ref_id),
            NULL
           ) ),'''',' '), ',', ' '),'"',' ') APPLICATION_REF_REASON_MEANING,
          replace(replace( replace(app.customer_reference,'''',' '), ',', ' '),'"',' ')  CUSTOMER_REFERENCE, 
          replace(replace( replace(app.customer_reason ,'''',' '), ',', ' '),'"',' ') CUSTOMER_REASON, 
          replace(replace( replace(app.comments ,'''',' '), ',', ' '),'"',' ') COMMENTS,
          NULL /* rec_activity_name */ REC_ACTIVITY_NAME, 
          replace(replace( replace(ct.purchase_order,'''',' '), ',', ' '),'"',' ')  PURCHASE_ORDER,
          replace(replace( replace(app.secondary_application_ref_num,'''',' '), ',', ' '),'"',' ') SECONDARY_APPLICATION_REF_NUM,
          replace(replace( replace(app.secondary_application_ref_type ,'''',' '), ',', ' '),'"',' ') SECONDARY_APPLICATION_REF_TYPE,
          replace(replace( replace((apps.arpt_sql_func_util.get_lookup_meaning
           ('APPLICATION_REF_TYPE',
            app.secondary_application_ref_type
           )),'''',' '), ',', ' '),'"',' ') SECONDARY_APP_REF_TYPE_MEANING,
          fu.user_name CREATED_BY_NAME, 
         fumod.user_name UPDATED_BY_NAME
       FROM ar.ra_customer_trx_all ct,
          ar.ra_customer_trx_lines_all ctl,
          ar.ra_cust_trx_types_all ctt,
          ar.ar_receipt_methods rm,
          applsys.fnd_user fu,
          applsys.fnd_user fumod,
          ar.ar_cash_receipts_all cr,
          ar.ar_payment_schedules_all ps,
          ar.ar_receivable_applications_all app,
          ar.ar_cash_receipt_history_all crh
      WHERE app.status = 'APP'
        AND app.cash_receipt_id = cr.cash_receipt_id(+)
        AND cr.receipt_method_id = rm.receipt_method_id(+)
        AND app.payment_schedule_id = ps.payment_schedule_id
        AND ps.cust_trx_type_id = ctt.cust_trx_type_id(+)
        AND app.applied_customer_trx_id = ct.customer_trx_id(+)
        AND app.applied_customer_trx_line_id = ctl.customer_trx_line_id(+)
        AND cr.cash_receipt_id = crh.cash_receipt_id(+)
        AND crh.current_record_flag(+) = 'Y'
        AND app.created_by = fu.user_id
        AND app.last_updated_by = fumod.user_id
        AND NVL (ctt.org_id, ps.org_id) = ps.org_id
		AND app.last_update_date >= p_date_der_exc -- OBE artf2359496 
       UNION ALL
       SELECT app.receivable_application_id, app.receivable_application_id,
          app.payment_schedule_id,
          replace(replace( replace(( DECODE (SIGN (ps.payment_schedule_id),
              -1, apps.arpt_sql_func_util.get_lookup_meaning
                                    ('PAYMENT_TYPE',
                                     app.status
                                    ),
              ps.trx_number
             )),'''',' '), ',', ' '),'"',' '),
         
          replace(replace( replace(ctt.NAME,'''',' '), ',', ' '),'"',' '),
          DECODE (SIGN (ps.payment_schedule_id),
              -1, NULL,
              apps.arpt_sql_func_util.get_lookup_meaning ('INV/CM',
                                    ps.CLASS
                                   )
             ),
          app.apply_date, NVL (app.amount_applied_from, app.amount_applied),
           replace(replace( replace(app.status,'''',' '), ',', ' '),'"',' '),
           replace(replace( replace((apps.arpt_sql_func_util.get_lookup_meaning ('PAYMENT_TYPE',
                                app.status
                               )),'''',' '), ',', ' '),'"',' '),
          
          replace(replace( replace(ps.invoice_currency_code,'''',' '), ',', ' '),'"',' '),
          app.amount_applied,
          rtl.line_number,
          app.gl_date,
          DECODE (SIGN (ps.payment_schedule_id),
              -1, TO_NUMBER (NULL),
              NVL (app.earned_discount_taken, 0)
              + NVL (app.unearned_discount_taken, 0)
             ),
          DECODE (SIGN (ps.payment_schedule_id),
              -1, TO_NUMBER (NULL),
              app.amount_applied
             ),
          TO_NUMBER (NULL), app.applied_customer_trx_id, TO_NUMBER (NULL),
          replace(replace( replace(app.attribute_category ,'''',' '), ',', ' '),'"',' '), 
          replace(replace( replace(app.attribute1,'''',' '), ',', ' '),'"',' ') , 
          replace(replace( replace(app.attribute2,'''',' '), ',', ' '),'"',' ') ,
          replace(replace( replace(app.attribute3,'''',' '), ',', ' '),'"',' ') , 
          replace(replace( replace(app.attribute4,'''',' '), ',', ' '),'"',' ') , 
          replace(replace( replace(app.attribute5,'''',' '), ',', ' '),'"',' ') , 
          replace(replace( replace(app.attribute6,'''',' '), ',', ' '),'"',' ') ,
          replace(replace( replace(app.attribute7,'''',' '), ',', ' '),'"',' ') , 
          replace(replace( replace(app.attribute8,'''',' '), ',', ' '),'"',' ') , 
          replace(replace( replace(app.attribute9,'''',' '), ',', ' '),'"',' ') , 
          replace(replace( replace(app.attribute10,'''',' '), ',', ' '),'"',' ') ,
          replace(replace( replace(app.attribute11,'''',' '), ',', ' '),'"',' ') , 
          replace(replace( replace(app.attribute12,'''',' '), ',', ' '),'"',' ') , 
          replace(replace( replace(app.attribute13,'''',' '), ',', ' '),'"',' ') , 
          replace(replace( replace(app.attribute14,'''',' '), ',', ' '),'"',' ') ,
          replace(replace( replace(app.attribute15,'''',' '), ',', ' '),'"',' ') ,
      app.last_updated_by, app.last_update_date,
          app.last_update_login, app.created_by, app.creation_date,
          replace(replace( replace(ct.reason_code,'''',' '), ',', ' '),'"',' '),
          replace(replace( replace((NVL
           (apps.arpt_sql_func_util.get_lookup_meaning ('INVOICING_REASON',
                                  ct.reason_code
                                 ),
            apps.arpt_sql_func_util.get_lookup_meaning
                                ('CREDIT_MEMO_REASON',
                                 ct.reason_code
                                )
           )),'''',' '), ',', ' '),'"',' '),
          
          TO_DATE (NULL), TO_CHAR (NULL), ps.payment_schedule_id,
          ps.terms_sequence_number,
      replace(replace( replace(ps.CLASS,'''',' '), ',', ' '),'"',' '), 
      app.line_applied,
          app.tax_applied, app.freight_applied,
          app.receivables_charges_applied, 
           replace(replace( replace(app.application_ref_type,'''',' '), ',', ' '),'"',' '),
           replace(replace( replace((apps.arpt_sql_func_util.get_lookup_meaning
           (DECODE (app.applied_payment_schedule_id,
                -7, 'AR_PREPAYMENT_TYPE',
                'APPLICATION_REF_TYPE'
               ),
            app.application_ref_type
           )),'''',' '), ',', ' '),'"',' ') application_ref_type_meaning,
          replace(replace( replace(app.application_ref_num,'''',' '), ',', ' '),'"',' '),
          replace(replace( replace(app.application_ref_reason,'''',' '), ',', ' '),'"',' '),
          replace(replace( replace((DECODE
           (app.application_ref_type,
            'CLAIM', apps.arp_deduction.get_tm_oracle_reason
                           (app.secondary_application_ref_id),
            NULL
           ) ),'''',' '), ',', ' '),'"',' ')
           application_ref_reason_meaning,
          replace(replace( replace(app.customer_reference,'''',' '), ',', ' '),'"',' '), 
          replace(replace( replace(app.customer_reason ,'''',' '), ',', ' '),'"',' '),
          replace(replace( replace(app.comments,'''',' '), ',', ' '),'"',' '),
          NULL /* rec_activity_name */,
		  replace(replace( replace(ct.purchase_order,'''',' '), ',', ' '),'"',' '),
          replace(replace( replace(app.secondary_application_ref_num,'''',' '), ',', ' '),'"',' '),
          replace(replace( replace(app.secondary_application_ref_type,'''',' '), ',', ' '),'"',' '),
          replace(replace( replace((apps.arpt_sql_func_util.get_lookup_meaning
           ('APPLICATION_REF_TYPE',
            app.secondary_application_ref_type
           )),'''',' '), ',', ' '),'"',' ') secondary_app_ref_type_meaning, 
          fu.user_name created_by_name, fumod.user_name updated_by_name
       FROM ar.ra_customer_trx_all ct,
          ar.ra_customer_trx_lines_all rtl,
          ar.ra_cust_trx_types_all ctt,
          applsys.fnd_user fu,
          applsys.fnd_user fumod,
          ar.ar_payment_schedules_all ps,
          ar.ar_receivable_applications_all app
      WHERE app.applied_payment_schedule_id = ps.payment_schedule_id
        AND ps.cust_trx_type_id = ctt.cust_trx_type_id(+)
        AND app.applied_customer_trx_line_id = rtl.customer_trx_line_id(+)
        AND app.status NOT IN ('ACC', 'ACTIVITY', 'OTHER ACC')
        AND app.applied_customer_trx_id = ct.customer_trx_id(+)
        /* data for On-Account and Claim investigion lines */
        AND app.created_by = fu.user_id
        AND app.last_updated_by = fumod.user_id
        AND NVL (ctt.org_id, ps.org_id) = ps.org_id
        AND app.last_update_date >= p_date_der_exc -- OBE artf2359496 
       UNION ALL
       SELECT app.receivable_application_id,
          app.receivable_application_id,
          app.payment_schedule_id,
          DECODE (SIGN (ps.payment_schedule_id),
              -1, apps.arpt_sql_func_util.get_lookup_meaning
                                    ('PAYMENT_TYPE',
                                     app.status
                                    ),
              NULL
             ),                                       /*PS.TRX_NUMBER ),*/
          psa.trx_number,
          NULL,
          app.apply_date,
          NVL (app.amount_applied_from, app.amount_applied),
          app.status,
          replace(replace( replace((apps.arpt_sql_func_util.get_lookup_meaning ('PAYMENT_TYPE',
                                app.status
                               )),'''',' '), ',', ' '),'"',' '),
          ps.invoice_currency_code, /* Added for Deductions Phase III*/ app.amount_applied,
          TO_NUMBER (NULL), app.gl_date, TO_NUMBER (NULL),
          DECODE (SIGN (ps.payment_schedule_id),
              -1, TO_NUMBER (NULL),
              app.amount_applied
             ),
          app.cash_receipt_id, app.applied_customer_trx_id, TO_NUMBER (NULL),
          replace(replace( replace(app.attribute_category ,'''',' '), ',', ' '),'"',' '), 
          replace(replace( replace(app.attribute1,'''',' '), ',', ' '),'"',' ') , 
          replace(replace( replace(app.attribute2,'''',' '), ',', ' '),'"',' ') ,
          replace(replace( replace(app.attribute3,'''',' '), ',', ' '),'"',' ') , 
          replace(replace( replace(app.attribute4,'''',' '), ',', ' '),'"',' ') , 
          replace(replace( replace(app.attribute5,'''',' '), ',', ' '),'"',' ') , 
          replace(replace( replace(app.attribute6,'''',' '), ',', ' '),'"',' ') ,
          replace(replace( replace(app.attribute7,'''',' '), ',', ' '),'"',' ') , 
          replace(replace( replace(app.attribute8,'''',' '), ',', ' '),'"',' ') , 
          replace(replace( replace(app.attribute9,'''',' '), ',', ' '),'"',' ') , 
          replace(replace( replace(app.attribute10,'''',' '), ',', ' '),'"',' ') ,
          replace(replace( replace(app.attribute11,'''',' '), ',', ' '),'"',' ') , 
          replace(replace( replace(app.attribute12,'''',' '), ',', ' '),'"',' ') , 
          replace(replace( replace(app.attribute13,'''',' '), ',', ' '),'"',' ') , 
          replace(replace( replace(app.attribute14,'''',' '), ',', ' '),'"',' ') ,
          replace(replace( replace(app.attribute15,'''',' '), ',', ' '),'"',' ') ,
      app.last_updated_by, app.last_update_date,
          app.last_update_login, app.created_by, app.creation_date, NULL,
          NULL, TO_DATE (NULL), TO_CHAR (NULL), ps.payment_schedule_id,
          ps.terms_sequence_number,
      replace(replace( replace(ps.CLASS,'''',' '), ',', ' '),'"',' '),
      app.line_applied,
          app.tax_applied, app.freight_applied,
          app.receivables_charges_applied,
      replace(replace( replace(app.application_ref_type,'''',' '), ',', ' '),'"',' '),
          replace(replace( replace((apps.arpt_sql_func_util.get_lookup_meaning
           (DECODE (app.applied_payment_schedule_id,
                -7, 'AR_PREPAYMENT_TYPE',
                'APPLICATION_REF_TYPE'
               ),
            app.application_ref_type
           )),'''',' '), ',', ' '),'"',' ') application_ref_type_meaning,
           
          replace(replace( replace(app.application_ref_num,'''',' '), ',', ' '),'"',' '), 
          replace(replace( replace(app.application_ref_reason,'''',' '), ',', ' '),'"',' '),
          replace(replace( replace((DECODE
           (app.application_ref_type,
            'CLAIM', apps.arp_deduction.get_tm_oracle_reason
                           (app.secondary_application_ref_id),
            NULL
           ) ) ,'''',' '), ',', ' '),'"',' ') application_ref_reason_meaning,
          
          replace(replace( replace(app.customer_reference,'''',' '), ',', ' '),'"',' '),
          replace(replace( replace(app.customer_reason ,'''',' '), ',', ' '),'"',' '),
          replace(replace( replace(app.comments,'''',' '), ',', ' '),'"',' '),
          replace(replace( replace((DECODE (SIGN (app.applied_payment_schedule_id),
              -1, art.NAME,
              NULL
             )),'''',' '), ',', ' '),'"',' ') rec_activity_name,
          NULL purchase_order, 
      replace(replace( replace(app.secondary_application_ref_num,'''',' '), ',', ' '),'"',' '),
          replace(replace( replace(app.secondary_application_ref_type,'''',' '), ',', ' '),'"',' '),
          replace(replace( replace((apps.arpt_sql_func_util.get_lookup_meaning
           ('APPLICATION_REF_TYPE',
            app.secondary_application_ref_type
           )),'''',' '), ',', ' '),'"',' ') secondary_app_ref_type_meaning,
          
          fu.user_name created_by_name, fumod.user_name updated_by_name
       FROM ar.ar_payment_schedules_all ps,
          ar.ar_payment_schedules_all psa,
          applsys.fnd_user fu,
          applsys.fnd_user fumod,
          ar.ar_receivable_applications_all app,
          ar.ar_receivables_trx_all art
      WHERE app.payment_schedule_id = ps.payment_schedule_id
        AND app.applied_payment_schedule_id = psa.payment_schedule_id
        AND app.status IN ('ACC', 'OTHER ACC')
        AND art.receivables_trx_id(+) = app.receivables_trx_id
        AND app.created_by = fu.user_id
        AND app.last_updated_by = fumod.user_id
        AND app.org_id = art.org_id
        AND app.last_update_date >= p_date_der_exc -- OBE artf2359496 
       UNION ALL
       SELECT adj.adjustment_id, NULL AS receivable_application_id,
          adj.payment_schedule_id,
          DECODE (adj.receivables_trx_id,
              -15, (SELECT trx.trx_number
                  FROM ar.ra_customer_trx_all trx,
                     ar.ra_customer_trx_lines_all lines
                 WHERE trx.customer_trx_id = lines.customer_trx_id
                   AND lines.br_ref_customer_trx_id =
                                  ct.customer_trx_id
                   AND lines.br_adjustment_id = adj.adjustment_id),
              adj.adjustment_number
             ),
          DECODE
           (NVL (rt.TYPE, 'ADJUST'),
            'ENDORSEMENT', apps.arpt_sql_func_util.get_lookup_meaning
                                   ('RECEIVABLES_TRX',
                                  rt.TYPE
                                   ),
            DECODE
             (adj.receivables_trx_id,
              -15, apps.arpt_sql_func_util.get_lookup_meaning
                            ('MISC_PHRASES',
                             DECODE (adj.receivables_trx_id,
                                 -15, 'ASSIGNMENT',
                                 'ADJUSTMENT'
                                )
                            ),
              apps.arpt_sql_func_util.get_lookup_meaning
                                   ('ADJUSTMENT_TYPE',
                                  adj.TYPE
                                   )
             )
           ),
          apps.arpt_sql_func_util.get_lookup_meaning
                            ('MISC_PHRASES',
                             DECODE (adj.receivables_trx_id,
                                 -15, 'ASSIGNMENT',
                                 'ADJUSTMENT'
                                )
                            ),
          adj.apply_date, adj.amount, TO_CHAR (NULL) status,
          replace(replace( replace((apps.arpt_sql_func_util.get_lookup_meaning ('APPROVAL_TYPE',
                                adj.status
                               )),'''',' '), ',', ' '),'"',' '),
          ct.invoice_currency_code, TO_NUMBER (NULL), TO_NUMBER (NULL),
          adj.gl_date, TO_NUMBER (NULL), adj.amount, TO_NUMBER (NULL),
          adj.customer_trx_id, adj.adjustment_id,
	  replace(replace( replace(adj.attribute_category,'''',' '), ',', ' '),'"',' '),
      replace(replace( replace(adj.attribute1,'''',' '), ',', ' '),'"',' '),
      replace(replace( replace(adj.attribute2,'''',' '), ',', ' '),'"',' '),
      replace(replace( replace(adj.attribute3,'''',' '), ',', ' '),'"',' '),
      replace(replace( replace(adj.attribute4,'''',' '), ',', ' '),'"',' '),
      replace(replace( replace(adj.attribute5,'''',' '), ',', ' '),'"',' '),
      replace(replace( replace(adj.attribute6,'''',' '), ',', ' '),'"',' '),
      replace(replace( replace(adj.attribute7,'''',' '), ',', ' '),'"',' '),
      replace(replace( replace(adj.attribute8,'''',' '), ',', ' '),'"',' '),
      replace(replace( replace(adj.attribute9,'''',' '), ',', ' '),'"',' '),
      replace(replace( replace(adj.attribute10,'''',' '), ',', ' '),'"',' '),
      replace(replace( replace(adj.attribute11,'''',' '), ',', ' '),'"',' '),
      replace(replace( replace(adj.attribute12,'''',' '), ',', ' '),'"',' '),
      replace(replace( replace(adj.attribute13,'''',' '), ',', ' '),'"',' '),
      replace(replace( replace(adj.attribute14,'''',' '), ',', ' '),'"',' '),
      replace(replace( replace(adj.attribute15,'''',' '), ',', ' '),'"',' '),
          adj.last_updated_by, adj.last_update_date, adj.last_update_login,
          adj.created_by, adj.creation_date,
      replace(replace( replace(adj.reason_code,'''',' '), ',', ' '),'"',' '),
          replace(replace( replace((apps.arpt_sql_func_util.get_lookup_meaning ('ADJUST_REASON',
                                adj.reason_code
                               )),'''',' '), ',', ' '),'"',' '),
          TO_DATE (NULL), TO_CHAR (NULL), TO_NUMBER (NULL), TO_NUMBER (NULL),
          TO_CHAR (NULL), adj.line_adjusted, adj.tax_adjusted,
          adj.freight_adjusted, adj.receivables_charges_adjusted, NULL, NULL,
          NULL, NULL, NULL, NULL, NULL, NULL, NULL,
		  replace(replace( replace(ct.purchase_order,'''',' '), ',', ' '),'"',' '),
		  NULL,
          NULL, NULL, fu.user_name created_by_name,
          fumod.user_name updated_by_name
		FROM ar.ar_adjustments_all adj,
          applsys.fnd_user fu,
          applsys.fnd_user fumod,
          ar.ar_receivables_trx_all rt,
          ar.ra_customer_trx_all ct
		WHERE adj.status NOT IN ('R', 'U')
        AND adj.receivables_trx_id = rt.receivables_trx_id(+)
        AND rt.receivables_trx_id(+) > 0
        AND adj.customer_trx_id = ct.customer_trx_id(+)
        AND adj.created_by = fu.user_id
        AND adj.last_updated_by = fumod.user_id
        AND adj.last_update_date >= p_date_der_exc -- OBE artf2359496 
       UNION ALL
       SELECT app.receivable_application_id, app.receivable_application_id,
          app.payment_schedule_id, NULL trx_rec_number,
          
          /* do not want to see number for -ps_id */
          apps.arpt_sql_func_util.get_lookup_meaning ('RECEIVABLES_TRX',
                                rt.TYPE
                               ),
          NULL, /*apps.arpt_sql_func_util.get_lookup_meaning('INV/CM',PS.CLASS) ,*/ app.apply_date,
          NVL (app.amount_applied_from, app.amount_applied),
          app.status,
         replace(replace( replace((apps.arpt_sql_func_util.get_lookup_meaning ('PAYMENT_TYPE',
                                app.status
                               )),'''',' '), ',', ' '),'"',' '),
         
         replace(replace( replace(ps.invoice_currency_code,'''',' '), ',', ' '),'"',' '),
     app.amount_applied, TO_NUMBER (NULL),
          app.gl_date, TO_NUMBER (NULL), app.amount_applied,
          app.cash_receipt_id, app.customer_trx_id, TO_NUMBER (NULL),
           replace(replace( replace(app.attribute_category ,'''',' '), ',', ' '),'"',' '), 
          replace(replace( replace(app.attribute1,'''',' '), ',', ' '),'"',' ') , 
          replace(replace( replace(app.attribute2,'''',' '), ',', ' '),'"',' ') ,
          replace(replace( replace(app.attribute3,'''',' '), ',', ' '),'"',' ') , 
          replace(replace( replace(app.attribute4,'''',' '), ',', ' '),'"',' ') , 
          replace(replace( replace(app.attribute5,'''',' '), ',', ' '),'"',' ') , 
          replace(replace( replace(app.attribute6,'''',' '), ',', ' '),'"',' ') ,
          replace(replace( replace(app.attribute7,'''',' '), ',', ' '),'"',' ') , 
          replace(replace( replace(app.attribute8,'''',' '), ',', ' '),'"',' ') , 
          replace(replace( replace(app.attribute9,'''',' '), ',', ' '),'"',' ') , 
          replace(replace( replace(app.attribute10,'''',' '), ',', ' '),'"',' ') ,
          replace(replace( replace(app.attribute11,'''',' '), ',', ' '),'"',' ') , 
          replace(replace( replace(app.attribute12,'''',' '), ',', ' '),'"',' ') , 
          replace(replace( replace(app.attribute13,'''',' '), ',', ' '),'"',' ') , 
          replace(replace( replace(app.attribute14,'''',' '), ',', ' '),'"',' ') ,
          replace(replace( replace(app.attribute15,'''',' '), ',', ' '),'"',' ') ,
      app.last_updated_by, app.last_update_date,
          app.last_update_login, app.created_by, app.creation_date,
          TO_CHAR (NULL), TO_CHAR (NULL), TO_DATE (NULL), TO_CHAR (NULL),
          ps.payment_schedule_id, ps.terms_sequence_number, 
      replace(replace( replace(ps.CLASS,'''',' '), ',', ' '),'"',' '),
          app.line_applied, app.tax_applied, app.freight_applied,
          app.receivables_charges_applied,
     replace(replace( replace(app.application_ref_type,'''',' '), ',', ' '),'"',' '),
          replace(replace( replace((apps.arpt_sql_func_util.get_lookup_meaning
           (DECODE (app.applied_payment_schedule_id,
                -7, 'AR_PREPAYMENT_TYPE',
                'APPLICATION_REF_TYPE'
               ),
            app.application_ref_type
           )),'''',' '), ',', ' '),'"',' ') application_ref_type_meaning,
           
         replace(replace( replace(app.application_ref_num,'''',' '), ',', ' '),'"',' '),
          replace(replace( replace(app.application_ref_reason,'''',' '), ',', ' '),'"',' '),
          replace(replace( replace((DECODE
           (app.application_ref_type,
            'CLAIM', apps.arp_deduction.get_tm_oracle_reason
                           (app.secondary_application_ref_id),
            NULL
           ) ) ,'''',' '), ',', ' '),'"',' ') application_ref_reason_meaning,
          
           replace(replace( replace(app.customer_reference,'''',' '), ',', ' '),'"',' '),  
          replace(replace( replace(app.customer_reason ,'''',' '), ',', ' '),'"',' '), 
          replace(replace( replace(app.comments,'''',' '), ',', ' '),'"',' '),
          replace(replace( replace((DECODE (SIGN (app.applied_payment_schedule_id),
              -1, rt.NAME,
              NULL
             )),'''',' '), ',', ' '),'"',' ') rec_activity_name,
          NULL purchase_order, 
      replace(replace( replace(app.secondary_application_ref_num,'''',' '), ',', ' '),'"',' '),
           replace(replace( replace(app.secondary_application_ref_type,'''',' '), ',', ' '),'"',' '),
          replace(replace( replace((apps.arpt_sql_func_util.get_lookup_meaning
           ('APPLICATION_REF_TYPE',
            app.secondary_application_ref_type
           )),'''',' '), ',', ' '),'"',' ') secondary_app_ref_type_meaning,
          fu.user_name created_by_name, fumod.user_name updated_by_name
       FROM ar.ar_payment_schedules_all ps,
          applsys.fnd_user fu,
          applsys.fnd_user fumod,
          ar.ar_receivable_applications_all app,
          ar.ar_receivables_trx_all rt
      WHERE app.payment_schedule_id = ps.payment_schedule_id
        AND app.receivables_trx_id = rt.receivables_trx_id
        AND app.status = 'ACTIVITY'
        AND SIGN (app.applied_payment_schedule_id) < 0
        AND app.created_by = fu.user_id
        AND app.last_updated_by = fumod.user_id
        AND app.org_id = rt.org_id
		AND app.last_update_date >= p_date_der_exc -- OBE artf2359496 
       UNION ALL
       SELECT app.receivable_application_id, app.receivable_application_id,
          app.payment_schedule_id, ps_dummy.trx_number, rt.NAME,
          apps.arpt_sql_func_util.get_lookup_meaning ('INV/CM', ps.CLASS),
          app.apply_date, NVL (app.amount_applied_from, app.amount_applied),
          app.status,
          
           replace(replace( replace((apps.arpt_sql_func_util.get_lookup_meaning ('PAYMENT_TYPE',
                                app.status
                               )),'''',' '), ',', ' '),'"',' '),
          ps.invoice_currency_code, /* Added for DEDUCTIONS PHASE III */ app.amount_applied,
          TO_NUMBER (NULL), app.gl_date, TO_NUMBER (NULL), app.amount_applied,
          ps_dummy.cash_receipt_id, TO_NUMBER (NULL), TO_NUMBER (NULL),
         replace(replace( replace(app.attribute_category ,'''',' '), ',', ' '),'"',' '), 
          replace(replace( replace(app.attribute1,'''',' '), ',', ' '),'"',' ') , 
          replace(replace( replace(app.attribute2,'''',' '), ',', ' '),'"',' ') ,
          replace(replace( replace(app.attribute3,'''',' '), ',', ' '),'"',' ') , 
          replace(replace( replace(app.attribute4,'''',' '), ',', ' '),'"',' ') , 
          replace(replace( replace(app.attribute5,'''',' '), ',', ' '),'"',' ') , 
          replace(replace( replace(app.attribute6,'''',' '), ',', ' '),'"',' ') ,
          replace(replace( replace(app.attribute7,'''',' '), ',', ' '),'"',' ') , 
          replace(replace( replace(app.attribute8,'''',' '), ',', ' '),'"',' ') , 
          replace(replace( replace(app.attribute9,'''',' '), ',', ' '),'"',' ') , 
          replace(replace( replace(app.attribute10,'''',' '), ',', ' '),'"',' ') ,
          replace(replace( replace(app.attribute11,'''',' '), ',', ' '),'"',' ') , 
          replace(replace( replace(app.attribute12,'''',' '), ',', ' '),'"',' ') , 
          replace(replace( replace(app.attribute13,'''',' '), ',', ' '),'"',' ') , 
          replace(replace( replace(app.attribute14,'''',' '), ',', ' '),'"',' ') ,
          replace(replace( replace(app.attribute15,'''',' '), ',', ' '),'"',' ') ,
      app.last_updated_by, app.last_update_date,
          app.last_update_login, app.created_by, app.creation_date,
          TO_CHAR (NULL), TO_CHAR (NULL),
          DECODE (app.application_type,
              'CASH', ps_dummy.due_date,
              TO_DATE (NULL)
             ),
          apps.arpt_sql_func_util.get_lookup_meaning
                               ('RECEIPT_CREATION_STATUS',
                              crh.status
                               ),
          app.applied_payment_schedule_id, ps.terms_sequence_number, ps.CLASS,
          app.line_applied, app.tax_applied, app.freight_applied,
          app.receivables_charges_applied, app.application_ref_type,
          
          replace(replace( replace((apps.arpt_sql_func_util.get_lookup_meaning
           (DECODE (app.applied_payment_schedule_id,
                -7, 'AR_PREPAYMENT_TYPE',
                'APPLICATION_REF_TYPE'
               ),
            app.application_ref_type
           ) ) ,'''',' '), ',', ' '),'"',' ') application_ref_type_meaning,
          
          NULL, /* APP.APPLICATION_REF_NUM */ 
          replace(replace( replace(app.application_ref_reason,'''',' '), ',', ' '),'"',' '),
          replace(replace( replace((DECODE
           (app.application_ref_type,
            'CLAIM', apps.arp_deduction.get_tm_oracle_reason
                           (app.secondary_application_ref_id),
            NULL
           ) ) ,'''',' '), ',', ' '),'"',' ') application_ref_reason_meaning,
          
          replace(replace( replace(app.customer_reference,'''',' '), ',', ' '),'"',' '),
          replace(replace( replace(app.customer_reason ,'''',' '), ',', ' '),'"',' '), 
          replace(replace( replace(app.comments,'''',' '), ',', ' '),'"',' '),
          replace(replace( replace(rt.NAME,'''',' '), ',', ' '),'"',' ') rec_activity_name,
		  NULL purchase_order,
          replace(replace( replace(app.secondary_application_ref_num,'''',' '), ',', ' '),'"',' '),
          replace(replace( replace(app.secondary_application_ref_type,'''',' '), ',', ' '),'"',' '),
          replace(replace( replace((apps.arpt_sql_func_util.get_lookup_meaning
           ('APPLICATION_REF_TYPE',
            app.secondary_application_ref_type
           )),'''',' '), ',', ' '),'"',' ') secondary_app_ref_type_meaning,
          fu.user_name created_by_name, fumod.user_name updated_by_name
       FROM ar.ar_payment_schedules_all ps,
          ar.ar_payment_schedules_all ps_dummy,
          applsys.fnd_user fu,
          applsys.fnd_user fumod,
          ar.ar_receivable_applications_all app,
          ar.ar_receivables_trx_all rt,
          ar.ar_cash_receipt_history_all crh
      WHERE app.payment_schedule_id = ps.payment_schedule_id
        AND app.applied_payment_schedule_id = ps_dummy.payment_schedule_id
        AND ps_dummy.cash_receipt_id = crh.cash_receipt_id
        AND crh.current_record_flag = 'Y'
        AND app.receivables_trx_id = rt.receivables_trx_id
        AND app.status = 'ACTIVITY'
        AND SIGN (app.applied_payment_schedule_id) > 0
        AND app.created_by = fu.user_id
        AND app.last_updated_by = fumod.user_id
        AND app.org_id = rt.org_id
        AND app.last_update_date >= p_date_der_exc -- OBE artf2359496 
        );
    -- > Fin BNZ : EDB371
   
   TYPE t_event_ar IS TABLE OF cur_event_ar%ROWTYPE index by binary_integer;
   rec_event_ar t_event_ar;
   
  BEGIN
  
    Fnd_File.put_line(Fnd_File.output, '---------------------------------------------------------');
    Fnd_File.put_line(Fnd_File.output, '-- EXTRACTION DES DONNEES                                ');
    Fnd_File.put_line(Fnd_File.output, '---------------------------------------------------------');    
    p_put_debug_message('Dans la procedure p_extract_data (' || p_directory_name || ';' || p_file_name || ';' || p_nb_lignes || ')');  
                           
    -- Verification de l'existence du directory
    p_check_directory(p_directory_name);
    
    -- Ouverture du fichier
    l_file := UTL_FILE.fopen(p_directory_name, p_file_name, 'W',32767);
    
    -- Controle que le fichier est bien ouvert pour ecriture
    IF utl_file.is_open(l_file) THEN
      p_put_debug_message('Le fichier ' || p_directory_name || '/' || p_file_name || ' est ouvert en écriture');
    ELSE
      p_validate(FALSE, 'Le fichier ne peut pas être ouvert en écriture');
      Fnd_File.put_line(Fnd_File.output,'Erreur : Le fichier ne peut pas être ouvert en écriture.');
    END IF;
      
      
    OPEN cur_event_ar;
    FETCH cur_event_ar BULK COLLECT INTO rec_event_ar;
    CLOSE cur_event_ar;   
    -- Extraction des donnees
     
    IF rec_event_ar.COUNT > 0 THEN
       FOR i in rec_event_ar.FIRST..rec_event_ar.LAST LOOP
   
          vv_ligne := rec_event_ar(i).LIGNE;     
          -- Ecrit dans le fichier
          utl_file.put_line(l_file, vv_ligne);
          -- Maj des compteurs
          vn_nb_lignes := vn_nb_lignes + 1;
    
       END LOOP;  
       Fnd_File.put_line(Fnd_File.output,'Les données ont été correctement extraits.');
     ELSE
        p_validate(FALSE, 'Requête des évenements AR ne retourne aucune ligne.');
        Fnd_File.put_line(Fnd_File.output,'Aucune ligne n''a été extraite.');        
     END IF;
     
     COMMIT; 
    
    
    -- Fermeture du fichier
    UTL_FILE.FCLOSE(l_file);
    
    -- Remet les valeurs des compteurs dans les parametres de la procedure
    p_nb_lignes      := vn_nb_lignes;
   
    
  EXCEPTION
    WHEN OTHERS THEN
      p_validate(FALSE, 'Probleme dans la procedure p_extract_data (' || SQLERRM || ')'); 
   
  END p_extract_data;
  

  ------------------------------------------------------------------------------------
  --  Nom           : Output_Header
  --  Description   : Procédure pour insérer une en-tête dans le fichier de sortie
  --
  --  PARAMETRES    :
  --              
  --
  ------------------------------------------------------------------------------------  

  PROCEDURE output_header IS
    cv_line                  VARCHAR2(100);
    v_conc_program_name      fnd_concurrent_programs.concurrent_program_name%TYPE;
    v_user_conc_program_name fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;
  BEGIN
  
    cv_line := '+-------------------------------------------------------------------------+';
  
    ----- Récupération des noms abrégé et long du traitement en fonction de la langue -----
    BEGIN
      SELECT fcp.concurrent_program_name, fcpt.user_concurrent_program_name
        INTO v_conc_program_name, v_user_conc_program_name
        FROM fnd_concurrent_programs fcp, fnd_concurrent_programs_tl fcpt
       WHERE fcp.application_id = Fnd_Global.prog_appl_id
         AND fcp.concurrent_program_id = Fnd_Global.conc_program_id
         AND fcpt.application_id = Fnd_Global.prog_appl_id
         AND fcpt.concurrent_program_id = Fnd_Global.conc_program_id
         AND fcpt.LANGUAGE = Fnd_Global.current_language;
    EXCEPTION
      WHEN OTHERS THEN
        v_user_conc_program_name := '???????????????????????';
        v_conc_program_name      := '???????';
    END;
  
    Fnd_File.put_line(Fnd_File.output, cv_line || CHR(10));
    Fnd_File.put_line(Fnd_File.output,
                      'Nom du traitement  : ' || v_user_conc_program_name);
    Fnd_File.put_line(Fnd_File.output,
                      'Code du traitement : ' || v_conc_program_name);
    Fnd_File.put_line(Fnd_File.output,
                      'Programme lancé le : ' ||
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || CHR(10));
    Fnd_File.put_line(Fnd_File.output, cv_line || CHR(10) || CHR(10));
  END output_header;  

  ------------------------------------------------------------------------------------
  --  Nom           : p_bilan
  --  Description   : Affichage des stats
  --
  --  PARAMETRES    :
  --  p_nb_lignes      nombre de lignes extraites dans le fichier                  
  --
  ------------------------------------------------------------------------------------
  PROCEDURE p_bilan(p_nb_lignes IN NUMBER, p_date_der_exc IN DATE, p_odate IN DATE) IS
  
  BEGIN
  
    Fnd_File.put_line(Fnd_File.output, chr(10));
    Fnd_File.put_line(Fnd_File.output, '---------------------------------------------------------');
    Fnd_File.put_line(Fnd_File.output, '-- PARAMETRE DU TRAITEMENT, lancé le ' || to_char(sysdate, 'DD/MM/YYYY HH24:MI:SS'));
    Fnd_File.put_line(Fnd_File.output, '---------------------------------------------------------');
    Fnd_File.put_line(Fnd_File.output, '1) Date de dernière exécution : ' || p_date_der_exc);
    Fnd_File.put_line(Fnd_File.output, '2) Date du plan de production : ' || p_odate);
    Fnd_File.put_line(Fnd_File.output, chr(10));
    
    
    Fnd_File.put_line(Fnd_File.output, '---------------------------------------------------------');
    Fnd_File.put_line(Fnd_File.output, '-- BILAN                                                 ');
    Fnd_File.put_line(Fnd_File.output, '---------------------------------------------------------');
  
    IF p_nb_lignes > 0 THEN
      Fnd_File.put_line(Fnd_File.output, 'Volume des lignes extraites : ' || p_nb_lignes || ' lignes.');
    ELSE
      Fnd_File.put_line(Fnd_File.output, 'Aucune ligne trouvée.');
    END IF;
  
  END p_bilan;

  ------------------------------------------------------------------------------------
  --  Nom           : main
  --  Description   : point d'entrée du traitement
  --
  --  PARAMETRES    :
  --  pv_errbuf             message d'erreur si pn_retcode != 0
  --  pn_retcode            code de sortie (0 : normal, 1 : warning,2 : erreur)
  --  pv_livre              Jeu de livres
  --
  ------------------------------------------------------------------------------------
  PROCEDURE main(pv_errbuf OUT NOCOPY VARCHAR2, pn_retcode OUT NOCOPY NUMBER, p_date_der_exc IN VARCHAR2, p_odate IN VARCHAR2) IS
  
    lv_current_program_unit VARCHAR2(30) := 'main';
    lv_nom_fichier          VARCHAR2(200);
    ln_nb_lignes            NUMBER := 0;
    
    vd_odate        DATE;
    vd_date_der_exc DATE;
    
  BEGIN
    
    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'DEBUT DE L''INTERFACE');
    Output_Header;
    
    vd_odate := TRUNC(fnd_date.canonical_to_date(p_odate));     
    vd_date_der_exc := TRUNC(fnd_date.canonical_to_date(p_date_der_exc));     
  
    -- Construction du nom du fichier
    lv_nom_fichier := 'FIN01_' || TO_CHAR(SYSDATE, 'YYYYMMDDHH24miss') || '_DTR-AR-EVENTS-V_001_'||TO_CHAR(vd_date_der_exc, 'YYYYMMDD')
                      ||'_'|| TO_CHAR(vd_odate, 'YYYYMMDD') ||'.csv';  -- OBE artf2227837

    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'PHASE D''EXTRACTION DES DONNEES');
                      
    -- Extrait les lignes d'écritures dans le fichier
    p_extract_data(K_DIRECTORY, lv_nom_fichier, ln_nb_lignes, vd_date_der_exc);
    
    
    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'AFFICHAGE DU BILAN');    
    -- Edite un rapport de traitment
    p_bilan(ln_nb_lignes,vd_date_der_exc,vd_odate);
    
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'Erreur procedure ' || cv_package_name || '.' || lv_current_program_unit || chr(10) || SQLERRM;
      pn_retcode := 2;
  END main;

END DKA_IAR_EVENEMENTS_DTR_PKG;
/
SHOW ERROR PACKAGE BODY DKA_IAR_EVENEMENTS_DTR_PKG;
EXIT
