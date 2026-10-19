CREATE OR REPLACE PACKAGE BODY APPS.DKA_IAPFAC_IVALUA_PKG IS
  --------------------------------------------------------------------------------
  -- $Id: DKA_IAPFAC_IVALUA_PKG.pkb
  -- Capgemini
  -- Projet           :
  -- Nom              : DKA_IAPFAC_IVALUA_PKG.pks
  -- Description      : Corps du package DKA_IAPFAC_IVALUA_PKG
  -- Auteur           : Asma AMENKOUR
  -- Date de creation : 15/09/2020
  -- Commentaires     :
  --------------------------------------------------------------------------------
  -- Modification     : Samir EL OUAHABI
  -- Date de creation : 01/12/2020
  -- Commentaires     : EDB278B
  --------------------------------------------------------------------------------
  -- Modification     : Samir EL OUAHABI
  -- Date de creation : 12/01/2021
  -- Commentaires     : EDB278C
  --------------------------------------------------------------------------------
  -- Modification     : Nicolas BOUSSEKEYT
  -- Date de creation : 01/07/2021
  -- Commentaires     : artf07467299 - INC0559716 - Les deux traitement d'export ci-dessous se sont termine en erreur
  --------------------------------------------------------------------------------
  -- Modification     : Nicolas BOUSSEKEYT
  -- Date de creation : 23/08/2021
  -- Commentaires     : artf07477573 - INC0558671 - Le traitement DKA : Export des donnees Factures vers iValua dure plus qu'une heure tous les jours.
  --------------------------------------------------------------------------------
  -- Modification     : Jerome WYCKAERT
  -- Date de creation : 14/10/2021
  -- Commentaires     : INC0589061 - Export Ivalua qui dure 12h malgré la MEP du correctif
  --------------------------------------------------------------------------------
  -- Modification     : Saloua HAHIOUI
  -- Date de creation : 05/11/2021
  -- Commentaires     : Correction suite au correctif INC0601593
  --------------------------------------------------------------------------------
  -- Modification     : Aurélien FAVIERE
  -- Date de creation : 09/11/2021
  -- Commentaires     : Correction suite au correctif INC0601593
  --------------------------------------------------------------------------------
  -- Modification     : Saloua HAHIOUI
  -- Date de creation : 12/11/2021
  -- Commentaires     : Correction suite au correctif INC0601593
  -------------------------------------------------------------------------------
  -- Modification   : Samir EL OUAHABI - TAG: SELO INC0610720
  -- Date de creation : 16/12/2021
  -- Commentaires     : Correction suite au correctif INC0610720
  -------------------------------------------------------------------------------
  -- Modification   : SELO
  -- Date de creation : 20/04/2022
  -- Commentaires     : SELO EDB329

  -------------------------------------------------------------------------------
  -- Modification   : SELO
  -- Date de creation : 13/07/2022
  -- Commentaires     :  INC0695437

  -------------------------------------------------------------------------------  
  -- Modification   : Anas RAOUF
  -- Date de creation : 18/10/2022
  -- Commentaires     :  EDB351 Lot 1

  -------------------------------------------------------------------------------
  -- Modification   : Ikrame BALKHITY
  -- Date de creation : 10/11/2022
  -- Commentaires     :  EDB351 Lot 1

  -------------------------------------------------------------------------------
  -------------------------------------------------------------------------------
  -- Modification   : Ikrame BALKHITY
  -- Date de creation : 02/02/2023
  -- Commentaires     :  EDB351 Lot 1

  -------------------------------------------------------------------------------    
  -- Modification   : Marina ENDJAH
  -- Date de creation : 26/07/2022
  -- Commentaires     : INC0704435: Traitement du Saut de ligne sur les champs PAYMENT_NUM et INVOICE_NUM dans les fichiers d'export des Règlements et les Entêtes
  -------------------------------------------------------------------------------  
  -------------------------------------------------------------------------------
  -- Modification   : Anas RAOUF
  -- Date de creation : 05/02/2023
  -- Commentaires     :  KDFI-1692 Problème sur l'export des factures PoFlip vers Ivalua
  ------------------------------------------------------------------------------- 
  -- Modification   : Zakaria BEN DAOUD
  -- Date de creation : 21/01/2025
  -- Commentaires     :  BNZ EDB392 
  ------------------------------------------------------------------------------- 

  g_package VARCHAR2(30) := 'DKA_IAPFAC_IVALUA_PKG';
  --g_nom_traitement          VARCHAR2(200) := 'DKA : Export des donnees Factures vers iValua ';
  g_sqlerrm         VARCHAR2(500) := NULL;
  g_retproc         NUMBER := 0;
  g_nom_traitement  FND_CONCURRENT_PROGRAMS_VL.USER_CONCURRENT_PROGRAM_NAME%TYPE;
  g_code_traitement FND_CONCURRENT_PROGRAMS_VL.CONCURRENT_PROGRAM_NAME%TYPE;
  g_request_id      NUMBER := fnd_global.CONC_REQUEST_ID;
  g_user            NUMBER := fnd_profile.value('USER_ID');
  g_date            DATE := SYSDATE;
  g_date_exec       VARCHAR2(50);
  g_header_file     VARCHAR2(240);
  g_line_file       VARCHAR2(240);
  g_hold_file       VARCHAR2(240);
  g_payment_file    VARCHAR2(240);
  g_supervision     VARCHAR2(240);
  g_pic_file        VARCHAR2(240) := 'DSP01_INV_ENTETE_IMG_' ||
                                     TO_CHAR(g_date, 'YYYYMMDDHH24MISS') ||
                                     '_ST_FIN01_' || to_char(g_request_id);
  g_img_file        VARCHAR2(240);
  G_separateur      VARCHAR2(1) := '|';
  G_NOM_SQL         VARCHAR2(40);
  g_step            VARCHAR2(500);
  gv_img_file       VARCHAR2(4000);
  gv_directory_path VARCHAR2(4000);
  g_reason_commen   VARCHAR2(240); --- IBA EDB351

  NB_FACTURE   NUMBER;
  NB_LIGNE     NUMBER;
  NB_BLOCAGE   NUMBER;
  NB_REGLEMENT NUMBER;
  NB_IMAGE     NUMBER;

  vv_commentaire VARCHAR2(400);

  /*============================================================================*/
  -- Procedure         : writeout
  -- Description       : Ecriture dans fichier *.OUT
  -- Parametres entree : P_message IN VARCHAR2 : message a ecrire
  -- Parametres sortie : AUCUN
  -- Auteur            : Asma AMENKOUR
  /*============================================================================*/
  PROCEDURE writeout(P_message IN VARCHAR2) IS
    L_procedure VARCHAR2(30) := 'writeout';
    v_etape     VARCHAR2(100);
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
  /* Fonction          : sortie_traitement                                      */
  /* Description       : affiche les statistiques dans la sortie de traitement  */
  /*                                                                            */
  /* Parametres entree : AUCUN                                                  */
  /* Parametres sortie : AUCUN                                                  */
  /*============================================================================*/
  PROCEDURE sortie_traitement IS
  
    l_procedure VARCHAR2(30) := 'sortie_traitement';
    l_message   VARCHAR2(2000);
  
  BEGIN
    writeout('Date de derniere execution de l''export : ' || g_date_exec);
    writeout('                                                 ');
    writeout('Nom du fichier ENTETES genere : ' || g_header_file);
    writeout('Nom du fichier LIGNES genere : ' || g_line_file);
    writeout('Nom du fichier BLOCAGES genere : ' || g_hold_file);
    writeout('Nom du fichier REGLEMENTS genere : ' || g_payment_file);
    writeout('Nom du fichier IMAGES genere : ' || g_pic_file || '.zip');
  
    writeout('');
    writeout('');
  
  END sortie_traitement;
  /*============================================================================*/
  /* Fonction          : entete_de_sortie                                      */
  /* Description       : entete de la sortie                 */
  /*                                                                            */
  /* Parametres entree : nom de fichier                                                  */
  /* Parametres sortie : AUCUN                                                  */
  /*============================================================================*/
  PROCEDURE entete_de_sortie IS
  
    l_procedure VARCHAR2(30) := 'entete_de_sortie';
    l_message   VARCHAR2(2000);
  
  BEGIN
  
    writeout('+-------------------------------------------------------------------------+');
    writeout('TRAITEMENT < DKA : Export des donnees Factures vers iValua >');
    writeout('Traitement n? : ' || g_request_id);
    writeout('Programme lance le : ' ||
             to_char(sysdate, 'DD/MM/YYYY HH24:MI:SS'));
    writeout('+-------------------------------------------------------------------------+');
    writeout('                                                                           ');
    writeout('                                                                           ');
  END entete_de_sortie;
  /*============================================================================*/
  /* Fonction          : fin_de_sortie                                      */
  /* Description       : fin de la sortie                 */
  /*                                                                            */
  /* Parametres entree : AUCUN                                                  */
  /* Parametres sortie : AUCUN                                                  */
  /*============================================================================*/
  PROCEDURE fin_de_sortie IS
  
    l_procedure VARCHAR2(30) := 'fin_de_sortie';
    l_message   VARCHAR2(2000);
  
  BEGIN
    writeout('');
    writeout('');
  
    writeout('+-------------------------------------------------------------------------+');
    writeout('                                                                           ');
    writeout('Programme termine le : ' ||
             to_char(sysdate, 'DD/MM/YYYY HH24:MI:SS'));
    writeout('                                                                           ');
    writeout('+-------------------------------------------------------------------------+');
  END fin_de_sortie;

  /*============================================================================*/
  /* Fonction          : MAJ_DATE_LANCEMENT                                      */
  /* Description       : Mise a jour de la date dans DKA_PARAMETERS                */
  /*                                                                            */
  /* Parametres entree : AUCUN                                                  */
  /* Parametres sortie : AUCUN                                                  */
  /*============================================================================*/
  PROCEDURE MAJ_DATE_LANCEMENT IS
  
    l_procedure VARCHAR2(30) := 'MAJ_DATE_LANCEMENT';
    l_message   VARCHAR2(2000);
  
  BEGIN
    UPDATE DKA_PARAMETERS
       SET date_value = g_date
     WHERE program_code = 'DKA_IAPFAC_IVALUA'
       AND parameter_name = 'DATE_DERNIERE_EXECUTION';
  END;
  /*======================================================================================================*/
  --  Nom           : get_img_file
  --  Description   : procedure
  --  PARAMETRES    : pn_invoive_id       Entree           identifiant de la facture
  --                  pv_errbuf           Entree/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: '0=normal', '1=warning', '2=erreur'
  --  DATE          : 22/09/2020
  /*=========================================================================================================*/
  /*  PROCEDURE get_img_file(pn_invoice_id ap_invoices_all.invoice_id%TYPE,
                           p_errbuf        OUT VARCHAR2,
                           p_retcode       OUT NUMBER)  IS
  
  
       l_FILE_NAME  VARCHAR2(500);
       l_blob       BLOB;
       vn_media_id  fnd_documents_tl.media_id%TYPE;
  
    BEGIN
  
      g_step  := 'get_img_file 000 : DEBUT';
      DKA_TOOLS_PKG.put_log_message(g_step);
  
      g_step  := 'get_img_file 001 : INIT';
      DKA_TOOLS_PKG.put_log_message(g_step);
      l_blob := NULL;
      l_FILE_NAME := NULL;
  
      g_step  := 'get_img_file 002 : Selection du fichier joint / invoice_ID : '||pn_invoice_id;
      DKA_TOOLS_PKG.put_log_message(g_step);
        SELECT
                 d.media_id
        INTO     vn_media_id
        FROM  fnd_documents_tl dt,
         fnd_documents d,
         fnd_document_categories_tl dct,
         fnd_attached_documents ad,
         fnd_document_datatypes dat
        WHERE d.document_id = ad.document_id
         AND   dt.document_id = d.document_id
         AND   dt.language = 'F'
         AND   dct.category_id = d.category_id
         AND   dct.language = 'F'
         AND   dct.name     ='MISC'
         AND   entity_name='AP_INVOICES'
         AND   dt.description ='IMAGE FACTURE'
         AND   d.datatype_id = dat.datatype_id
         AND   dat.language = 'F'
         AND   dat.name = 'FILE'
         AND   pk1_value = TO_CHAR(pn_invoice_id)
         AND   ROWNUM = 1 --on prend uniquement le premier
  ;
      g_step  := 'get_img_file 003 : Selection des data du fichier joint et du nom /MEDIA_ID : '||vn_media_id;
      DKA_TOOLS_PKG.put_log_message(g_step);
      SELECT file_data,
       substr(FILE_NAME,
       instr(FILE_NAME,'/',-1)+1 )
      INTO   l_blob,l_FILE_NAME
      FROM   fnd_lobs f
      WHERE  f.file_id = vn_media_id;
  
       SELECT ad.directory_path
      INTO gv_directory_path
      FROM all_directories ad
      WHERE ad.directory_name = 'DKA_OUT_DIR';
  
      g_step  := 'get_img_file 004 : Definition du fichier a joindre';
      DKA_TOOLS_PKG.put_log_message(g_step);
      gv_img_file := gv_directory_path||'/'||l_FILE_NAME;
      DKA_TOOLS_PKG.put_log_message(gv_img_file);
  
      g_step  := 'get_img_file 005 : Execution de la procedure JAVA';
      DKA_TOOLS_PKG.put_log_message(g_step);
      Dka_ExportBlob(gv_img_file,l_blob);
  
      g_step  := 'get_img_file 999 : FIN';
      DKA_TOOLS_PKG.put_log_message(g_step);
  
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
       g_step  := 'Pas de piece jointe a traiter';
  
       p_retcode := 2;
  
    END get_img_file;  */
  /*============================================================================*/
  /* Procedure         : purge_tables                                      */
  /* Description       :                */
  /*                                                                            */
  /* Parametres entree : AUCUN                                                  */
  /* Parametres sortie : AUCUN                                                  */
  /*============================================================================*/
  PROCEDURE purge_tables IS
  BEGIN
    delete from DKA_IAPFAC_IVALUA;
    commit;
  
    -- 14/10/2021 - JWYC - INC0589061 - Export Ivalua qui dure 12h malgré la MEP du correctif
    delete from dka_iapfac_ivalua_img_maj;
    commit;
  END;

  /*============================================================================*/
  /* Procedure         : generate_files                                      */
  /* Description       :                */
  /*                                                                            */
  /* Parametres entree : AUCUN                                                  */
  /* Parametres sortie : AUCUN                                                  */
  /*============================================================================*/
  PROCEDURE generate_files(pv_errbuf  IN OUT VARCHAR2,
                           pn_retcode OUT NUMBER,
                           p_date     IN date) IS
  
    l_procedure      VARCHAR2(30) := 'generate_files';
    l_message        VARCHAR2(2000);
    l_execute_code   BOOLEAN;
    l_req_interval   NUMBER := 30;
    l_req_max_wait   NUMBER := 999999;
    l_req_phase      VARCHAR2(255);
    l_req_status     VARCHAR2(255);
    l_req_dev_phase  VARCHAR2(255);
    l_req_dev_status VARCHAR2(255);
    l_req_message    VARCHAR2(255);
  
    CURSOR c_inv_header(p_date DATE) IS
      SELECT v.*
        FROM (SELECT aia.invoice_id,
                     --aia.invoice_num, --MEND INC0704435
                     replace(replace(to_char(aia.invoice_num), chr(13)),
                             chr(10)) invoice_num,
                     aia.source,
                     hou.name UO,
                     aps.segment1 supplier_num,
                     assa.attribute4 ID_IVALUA_SITE -- SELO EDB278C
                    ,
                     aia.INVOICE_TYPE_LOOKUP_CODE,
                     aia.INVOICE_CURRENCY_CODE,
                     replace(ROUND(aia.INVOICE_AMOUNT, 2), ',', '.') INVOICE_AMOUNT
                     --,      nvl(aia.TAX_AMOUNT,0)
                    ,
                     replace(ROUND((aia.INVOICE_AMOUNT -
                                   nvl(aia.TOTAL_TAX_AMOUNT, 0)),
                                   2),
                             ',',
                             '.') MNT_HT,
                     to_char(aia.invoice_date, 'DD/MM/YYYY') invoice_date,
                     aia.TERMS_ID,
                     apt.NAME payment_terms_name,
                     aia.payment_method_code term_name,
                     aia.WFAPPROVAL_STATUS
                     --,     alc1.displayed_field invoice_status
                    ,
                     DECODE(AP_INVOICES_PKG.GET_APPROVAL_STATUS(aia.invoice_id,
                                                                aia.invoice_amount,
                                                                aia.payment_status_flag,
                                                                aia.invoice_type_lookup_code),
                            'CANCELLED',
                            'CANCELED',
                            CASE
                              WHEN aia.WFAPPROVAL_STATUS = 'WFAPPROVED' THEN
                               'APPROVED'
                              WHEN aia.WFAPPROVAL_STATUS != 'WFAPPROVED' THEN
                               'NOT_APPROVED'
                            END) invoice_status
                     --,     replace(to_char(aia.AMOUNT_PAID,'999999.99'),',','.') AMOUNT_PAID
                    ,
                     replace(ROUND(nvl(aia.AMOUNT_PAID, 0), 2), ',', '.') AMOUNT_PAID,
                     DECODE(aia.PAY_GROUP_LOOKUP_CODE, 'PMTDIR', 'Y', 'N') direct_payment,
                     DECODE(aia.attribute9, 'DSP', 'Y', 'N') inv_po_flip,
                     DECODE(aia.REMIT_TO_SUPPLIER_SITE, null, 'N', 'Y') factoring
                     --,     DECODE(aia.attribute9,'DSP',substr(aia.attribute10, instr(aia.attribute10,'INV'),9),'') ID_FACTURE_IVALUA -- SELO - EDB296
                    ,
                     -- SELO INC0695437 - recuperation du ID_FACTURE_IVALUA pour les factures de type CREDIT
                     DECODE(aia.attribute9,
                            'DSP',
                            decode(instr(aia.attribute10, 'INV'),
                                   0,
                                   decode(instr(aia.attribute10, 'CRE'),
                                          0,
                                          '',
                                          SUBSTR(aia.attribute10,
                                                 INSTR(aia.attribute10, 'CRE'),
                                                 INSTR(aia.attribute10, '.') -
                                                 INSTR(aia.attribute10, 'CRE')) --ARA KDFI-1692
                                          ),
                                   SUBSTR(aia.attribute10,
                                          INSTR(aia.attribute10, 'INV'),
                                          INSTR(aia.attribute10, '.') -
                                          INSTR(aia.attribute10, 'INV')) --ARA KDFI-1692
                                   ),
                            '') ID_FACTURE_IVALUA -- SELO - EDB296
                    ,
                     aia.last_update_date
                FROM ap_invoices_all       aia,
                     ap_suppliers          aps,
                     AP_SUPPLIER_SITES_ALL assa -- SELO EDB278C
                    ,
                     POS_BUS_CLASS_ATTR    pbc
                     --,   ap_invoice_lines_all aila
                     -- ,   ap_distribution_sets_all apid
                     -- ,   po_distributions_all pda
                     --,   po_headers_all pha
                    ,
                     ap_holds_all aha
                     ------------------------
                    ,
                     hr_operating_units       hou,
                     AP_TERMS_TL              apt,
                     ap_payment_schedules_all apsa
              --,    AP_LOOKUP_CODES alc
               WHERE 1 = 1
                 AND aia.vendor_id = aps.vendor_id
                 and assa.vendor_site_id = aia.vendor_site_id -- SELO EDB278C
                 AND aia.INVOICE_TYPE_LOOKUP_CODE IN ('STANDARD', 'CREDIT')
                 AND aps.vendor_type_lookup_code != 'EMPLOYEE'
                 AND pbc.vendor_id(+) = aps.vendor_id
                 AND pbc.lookup_code(+) = 'MINORITY_OWNED'
                 AND NVL(pbc.EXT_ATTR_1, 'XX') != 'APPRENTIS'
                 AND aia.invoice_id = aha.invoice_id(+)
                    -- AND  aia.invoice_id = aila.invoice_id
                    -- AND   aila.distribution_set_id = apid.distribution_set_id (+)
                    -- AND   aila.po_distribution_id  = pda.po_distribution_id (+)
                    -- AND   aila.po_header_id = pha.po_header_id
                    --AND   pha.attribute7 = 'IVALUA'
                 AND EXISTS
               (SELECT 1
                        from po_headers_all pha, ap_invoice_lines_all aila
                       where pha.attribute7 = 'IVALUA'
                         AND aila.po_header_id = pha.po_header_id
                         AND aia.invoice_id = aila.invoice_id)
                    
                 and aha.HOLD_LOOKUP_CODE(+) = 'LINE VARIANCE'
                 and decode(aha.HOLD_LOOKUP_CODE,
                            null,
                            'YY',
                            AHA.RELEASE_LOOKUP_CODE) is not null
                    
                    -- DEFECT 1163 FIN
                    -------------------------------
                 AND aia.org_id = hou.organization_id
                 AND apt.term_id = aia.terms_id
                 AND apt.LANGUAGE = 'F'
                 AND aia.invoice_id = apsa.invoice_id) v
       WHERE ((v.last_update_date > p_date) OR EXISTS
              (select 1
                 from ap_holds_all ahaa
                where ahaa.last_update_date > p_date
                  and ahaa.invoice_id = v.invoice_id) OR EXISTS
              (select 1
                 from ap_invoice_lines_all ailaa
                where ailaa.last_update_date > p_date
                  and ailaa.invoice_id = v.invoice_id)
             -- 14/10/2021 - JWYC - INC0589061 - Export Ivalua qui dure 12h malgré la MEP du correctif
             /* OR EXISTS(select 1
                                         from fnd_attached_documents ad
               where ad.last_update_date >  p_date
                 and pk1_value = v.invoice_id
               and entity_name = 'AP_INVOICES'
             )*/
              OR EXISTS (select 1
                           from dka_iapfac_ivalua_img_maj tmp
                          where tmp.invoice_id = v.invoice_id))
      -- 787, 5126
      UNION /*ALL*/
      -- 23/08/2021 - NBO - artf07477573 - INC0558671 - Le traitement DKA : Export des données Factures vers iValua dure plus qu'une heure tous les jours.
      SELECT aia.invoice_id,
             --aia.invoice_num, --MEND INC0704435
             replace(replace(to_char(aia.invoice_num), chr(13)), chr(10)) invoice_num,
             aia.source,
             hou.name UO,
             aps.segment1 supplier_num,
             assa.attribute4 ID_IVALUA_SITE -- SELO EDB278C
            ,
             aia.INVOICE_TYPE_LOOKUP_CODE,
             aia.INVOICE_CURRENCY_CODE,
             replace(ROUND(aia.INVOICE_AMOUNT, 2), ',', '.') INVOICE_AMOUNT
             --,      nvl(aia.TAX_AMOUNT,0)
            ,
             replace(ROUND((aia.INVOICE_AMOUNT -
                           nvl(aia.TOTAL_TAX_AMOUNT, 0)),
                           2),
                     ',',
                     '.') MNT_HT,
             to_char(aia.invoice_date, 'DD/MM/YYYY') invoice_date,
             aia.TERMS_ID,
             apt.NAME payment_terms_name,
             aia.payment_method_code term_name,
             aia.WFAPPROVAL_STATUS
             --,     alc1.displayed_field invoice_status
            ,
             DECODE(AP_INVOICES_PKG.GET_APPROVAL_STATUS(aia.invoice_id,
                                                        aia.invoice_amount,
                                                        aia.payment_status_flag,
                                                        aia.invoice_type_lookup_code),
                    'CANCELLED',
                    'CANCELED',
                    CASE
                      WHEN aia.WFAPPROVAL_STATUS = 'WFAPPROVED' THEN
                       'APPROVED'
                      WHEN aia.WFAPPROVAL_STATUS != 'WFAPPROVED' THEN
                       'NOT_APPROVED'
                    END) invoice_status
             --,     replace(to_char(aia.AMOUNT_PAID,'999999.99'),',','.') AMOUNT_PAID
            ,
             replace(ROUND(nvl(aia.AMOUNT_PAID, 0), 2), ',', '.') AMOUNT_PAID,
             DECODE(aia.PAY_GROUP_LOOKUP_CODE, 'PMTDIR', 'Y', 'N') direct_payment,
             DECODE(aia.attribute9, 'DSP', 'Y', 'N') inv_po_flip,
             DECODE(aia.REMIT_TO_SUPPLIER_SITE, null, 'N', 'Y') factoring
             -- ,     DECODE(aia.attribute9,'DSP',substr(aia.attribute10, instr(aia.attribute10,'INV'),9),'') ID_FACTURE_IVALUA -- SELO - EDB296
            ,
             -- SELO INC0695437 - recuperation du ID_FACTURE_IVALUA pour les factures de type CREDIT
             DECODE(aia.attribute9,
                    'DSP',
                    decode(instr(aia.attribute10, 'INV'),
                           0,
                           decode(instr(aia.attribute10, 'CRE'),
                                  0,
                                  '',
                                  SUBSTR(aia.attribute10,
                                         INSTR(aia.attribute10, 'CRE'),
                                         INSTR(aia.attribute10, '.') -
                                         INSTR(aia.attribute10, 'CRE')) --ARA KDFI-1692
                                  ),
                           SUBSTR(aia.attribute10,
                                  INSTR(aia.attribute10, 'INV'),
                                  INSTR(aia.attribute10, '.') -
                                  INSTR(aia.attribute10, 'INV')) --ARA KDFI-1692
                           ),
                    '') ID_FACTURE_IVALUA -- SELO - EDB296
             
            ,
             aia.last_update_date
        FROM ap_invoices_all       aia,
             ap_suppliers          aps,
             AP_SUPPLIER_SITES_ALL assa -- SELO EDB278C
            ,
             POS_BUS_CLASS_ATTR    pbc
             -- ,   ap_invoice_lines_all aila
             --,    ap_holds_all aha        --EDB278-E
             ------------------------
            ,
             hr_operating_units       hou,
             AP_TERMS_TL              apt,
             ap_payment_schedules_all apsa
      --,    AP_LOOKUP_CODES alc
       WHERE 1 = 1
         AND aia.vendor_id = aps.vendor_id
         and assa.vendor_site_id = aia.vendor_site_id -- SELO EDB278C
         AND aia.INVOICE_TYPE_LOOKUP_CODE IN ('STANDARD', 'CREDIT')
         AND aps.vendor_type_lookup_code != 'EMPLOYEE'
         AND pbc.vendor_id(+) = aps.vendor_id
         AND pbc.lookup_code(+) = 'MINORITY_OWNED'
         AND NVL(pbc.EXT_ATTR_1, 'XX') != 'APPRENTIS'
            --  AND  aia.invoice_id = aha.invoice_id  --EDB278-E
            
            -- 23/08/2021 - NBO - artf07477573 - INC0558671 - Le traitement DKA : Export des données Factures vers iValua dure plus qu'une heure tous les jours.
         AND aia.invoice_id IN
             (select aha.invoice_id
                from ap_holds_all aha
               where aia.invoice_id = aha.invoice_id
                 and aha.hold_lookup_code = 'En attente'
                 and (aha.attribute4 is not null)) --EDB278-E
            
            -- AND  aia.invoice_id = aila.invoice_id
            -- 23/08/2021 - NBO - artf07477573 - INC0558671 - Le traitement DKA : Export des données Factures vers iValua dure plus qu'une heure tous les jours.
         AND ((aia.last_update_date > p_date) OR EXISTS
              (select 1
                 from ap_holds_all ahaa
                where ahaa.last_update_date > p_date
                  and ahaa.invoice_id = aia.invoice_id) OR EXISTS
              (select 1
                 from ap_invoice_lines_all ailaa
                where ailaa.last_update_date > p_date
                  and ailaa.invoice_id = aia.invoice_id)
             
             -- 14/10/2021 - JWYC - INC0589061 - Export Ivalua qui dure 12h malgré la MEP du correctif
             /*    OR EXISTS (select 1
                                         from fnd_attached_documents ad
               where ad.last_update_date >  p_date
                 and pk1_value = aia.invoice_id
               and entity_name = 'AP_INVOICES'
             )*/
              OR EXISTS (select 1
                           from dka_iapfac_ivalua_img_maj tmp
                          where tmp.invoice_id = aia.invoice_id))
            
         AND aia.org_id = hou.organization_id
         AND apt.term_id = aia.terms_id
         AND apt.LANGUAGE = 'F'
         AND aia.invoice_id = apsa.invoice_id;
  
    CURSOR c_inv_line(p_invoice_id NUMBER) IS
      SELECT aila.invoice_id,
             aila.LINE_NUMBER,
             aila.LINE_TYPE_LOOKUP_CODE,
             replace(ROUND(aila.amount, 2), ',', '.') amount,
             DECODE(aila.LINE_TYPE_LOOKUP_CODE,
                    'TAX',
                    aila.TAX_RATE_CODE,
                    null) TAX_RATE_CODE,
             REPLACE(REPLACE(aila.DESCRIPTION, CHR(10), ''), CHR(157), ' ') DESCRIPTION, --AFE INC0601593
             nvl(pha.clm_document_number, pha.segment1) po_number,
             pla.attribute8 ivalua_po_line,
             replace(ROUND(plla.QUANTITY_RECEIVED, 5), ',', '.') QUANTITY_RECEIVED,
             replace(ROUND(aila.quantity_invoiced, 5), ',', '.') quantity_invoiced,
             replace(ROUND(aila.UNIT_PRICE, 2), ',', '.') UNIT_PRICE,
             DECODE(aila.DISCARDED_FLAG, '', 'N', aila.DISCARDED_FLAG) as DISCARDED_FLAG, --BNZ EDB392
             DECODE(aila.CANCELLED_FLAG, '', 'N', aila.CANCELLED_FLAG) as CANCELLED_FLAG --BNZ EDB392
      
        FROM ap_invoice_lines_all     aila,
             ap_distribution_sets_all apid,
             po_distributions_all     pda,
             po_headers_all           pha,
             po_lines_all             pla,
             po_line_locations_all    plla
      
       WHERE aila.invoice_id = p_invoice_id
         AND aila.LINE_TYPE_LOOKUP_CODE != 'PREPAY'
         AND aila.distribution_set_id = apid.distribution_set_id(+)
         AND aila.po_distribution_id = pda.po_distribution_id(+)
         AND aila.po_header_id = pha.po_header_id(+)
         AND aila.po_line_location_id = plla.line_location_id(+)
         AND aila.po_line_id = pla.po_line_id(+)
      
      ;
  
    CURSOR c_inv_hold(p_invoice_id NUMBER) IS
      SELECT aha.invoice_id
             --,      nvl(pha.clm_document_number,pha.segment1)
             --,      pla.line_num
            ,
             aha.attribute2 item_key --ARA EDB351 Lot 1
            ,
             pla.attribute8 Id_line_Ivalua,
             aha.hold_id,
             aha.hold_lookup_code,
             aha.attribute5 type_blocage_en_attente,
             ppf.employee_number employe_a_notifier,
             to_char(aha.hold_date, 'DD/MM/YYYY') hold_date,
             REPLACE(REPLACE(aha.hold_reason, CHR(10), ''), CHR(13), '') hold_reason,
             aha.RELEASE_LOOKUP_CODE,
             DECODE(aha.release_lookup_code,
                    NULL,
                    NULL,
                    to_char(aha.last_update_date, 'DD/MM/YYYY')) release_date,
             REPLACE(REPLACE(aha.RELEASE_REASON, CHR(10), ''), CHR(13), '') RELEASE_REASON,
             DECODE(aha.RELEASE_LOOKUP_CODE,
                    NULL,
                    (CASE
                      WHEN aha.ATTRIBUTE4 = 'Y' then
                       'A_TRAITER_IVALUA'
                      WHEN nvl(aha.ATTRIBUTE4, 'N') = 'N' then
                       'A_TRAITER_ORACLE'
                    END),
                    'TRAITE') statut_blocage,
             ----<DEBUT EDB351 IBA
             (select '-' || translate(wfna.TEXT_VALUE,
                                      chr(10) || chr(11) || chr(13),
                                      '    ')
                from ap_holds_all               aha2,
                     dka_stransco_headers       dsh_bn,
                     dka_stransco_lines         dsl_bn,
                     dka_stransco_headers       dsh_nm,
                     dka_stransco_lines         dsl_nm,
                     wf_notifications           wfn,
                     wf_notification_attributes wfna
               where aha.INVOICE_ID = aha2.INVOICE_ID
                 and dsh_bn.set_name = 'DKA_BLOCAGES_TYPE_WF' --'DKA_BLOCAGES_NOTIFS' --ARA EDB351 
                 and dsh_bn.set_id = dsl_bn.set_id
                 and aha2.HOLD_LOOKUP_CODE = dsl_bn.PARAMS_VALUE
                 and dsh_nm.set_name = 'DKA_MSG_NOTIF' --'DKA_NOTIF_METIER' --ARA EDB351
                 and dsh_nm.set_id = dsl_nm.set_id
                 and dsl_nm.RETURN_VALUE = dsl_bn.RETURN_VALUE
                 and wfn.notification_id = wfna.notification_id
                 and wfn.MESSAGE_TYPE = 'DKA_CSP'
                 AND wfna.name = 'DKA_COMMENTS'
                 and wfn.item_key = aha2.ATTRIBUTE2
                 and wfn.MESSAGE_NAME = dsl_nm.PARAM1_VALUE
                 and dsl_bn.PARAM1_VALUE = aha.hold_lookup_code -- type du blocage
                 and rownum = 1) as commentaire
      -----FIN IBA EDB351
        FROM ap_holds_all          aha,
             po_headers_all        pha,
             po_lines_all          pla,
             po_line_locations_all plla,
             per_people_f          ppf
       WHERE invoice_id = p_invoice_id
         AND hold_lookup_code in
            --< BNZ EDB392
             (SELECT ffv.flex_value
                FROM fnd_flex_value_sets ffvs, fnd_flex_values ffv
               WHERE ffvs.flex_value_set_name = 'DKA_EXP_HOLDS_IVALUA'
                 AND ffvs.flex_value_set_id = ffv.flex_value_set_id
                 AND ffv.ENABLED_FLAG = 'Y') --> BNZ EDB392
            
            /*('QTY REC',
            'QTY ORD',
            'En attente',
            'En litige Quantité CDE', -- SELO INC0610720
            'PRICE',
            'En litige Prix',
            'En litige Quantité REC', -- SELO INC0610720
            'MAX SHIP AMOUNT',
            'En litige BAP')*/
         AND aha.line_location_id = plla.line_location_id(+)
         AND plla.po_line_id = pla.po_line_id(+)
         AND plla.po_header_id = pha.po_header_id(+)
         AND ppf.person_id(+) = aha.ATTRIBUTE6
         AND sysdate BETWEEN NVL(ppf.effective_start_date, sysdate) AND
             NVL(ppf.effective_end_date, sysdate);
  
    CURSOR c_inv_payment(p_invoice_id NUMBER) IS
      SELECT INV.invoice_id,
             'REGLEMENT' PAYMENT_TYPE,
             -- SUBSTR(INV.INVOICE_NUM, 1, 20) NUM_FACTURE,
             AIP.INVOICE_PAYMENT_ID PAYMENT_ID,
             --to_char(ac.check_number) PAYMENT_NUM, --MEND INC0704435
             replace(replace(to_char(ac.check_number), chr(13)), chr(10)) PAYMENT_NUM,
             null PAYMENT_LINE_NUM,
             to_char(ac.check_date, 'DD/MM/YYYY') PAYMENT_DATE,
             replace(ROUND(nvl(AIP.AMOUNT, 0), 2), ',', '.') PAYMENT_AMOUNT,
             -- DECODE(INV.PAY_GROUP_LOOKUP_CODE, 'PMTDIR', 'Y', 'N') direct_payement -- BNZ EDB392
             
             --< BNZ EDB392
             iby.PAYMENT_METHOD_CODE PAYMENT_METHOD,
             DECODE(AC.STATUS_LOOKUP_CODE, 'VOIDED', 'Y', 'N') VOID
      --> BNZ EDB392
      
      --AIP.AMOUNT PAYMENT_AMOUNT
        FROM AP_INVOICES_all         INV,
             AP_INVOICE_PAYMENTS_all AIP,
             AP_CHECKS_ALL           AC,
             IBY_PAYMENT_METHODS_VL  iby --BNZ EDB392
          
       WHERE 1 = 1
         AND INV.INVOICE_ID = AIP.INVOICE_ID
            --AND NVL(INV.BASE_AMOUNT, INV.INVOICE_AMOUNT) <> 0
         and AIP.CHECK_ID = AC.CHECK_ID
          AND iby.payment_method_code(+) = AC.PAYMENT_METHOD_CODE --BNZ EDB392
            --  and inv.org_id=85
            --and INV.INVOICE_NUM='251486731'
         and inv.invoice_id = p_invoice_id
      --and rownum<3
      union
      select AI.invoice_ID,
             'ACOMPTE' PAYMENT_TYPE,
             AID1.INVOICE_DISTRIBUTION_ID PAYMENT_ID,
             --AI1.INVOICE_NUM PAYMENT_NUM, --MEND INC0704435
             replace(replace(AI1.INVOICE_NUM, chr(13)), chr(10)) PAYMENT_NUM,
             AIL1.LINE_NUMBER PAYMENT_LINE_NUM,
             to_char(AIL.ACCOUNTING_DATE, 'DD/MM/YYYY') PAYMENT_DATE,
             /* (-1)*AP_MATCHING_UTILS_PKG.Get_Recoup_Amt_Per_Prepay_Line
             (AIL.INVOICE_ID,AIL.LINE_NUMBER,
               AIL1.INVOICE_ID,AIL1.LINE_NUMBER) PAYMENT_AMOUNT,*/
             replace(ROUND(nvl(AIL1.AMOUNT -
                               NVL(AIL.INCLUDED_TAX_AMOUNT, 0),
                               0),
                           2),
                     ',',
                     '.') PAYMENT_AMOUNT,
             --< BNZ EDB392
             '' PAYMENT_METHOD,
             '' VOID
      --> BNZ EDB392
      
      --      AIL1.AMOUNT - NVL(AIL.INCLUDED_TAX_AMOUNT,0) PAYMENT_AMOUNT
        FROM AP_INVOICES_ALL              AI,
             AP_INVOICES_ALL              AI1,
             AP_INVOICE_LINES_all         AIL,
             AP_INVOICE_LINES_all         AIL1,
             AP_INVOICE_DISTRIBUTIONS_all AID,
             AP_INVOICE_DISTRIBUTIONS_all AID1
       WHERE AI.INVOICE_ID = AIL.INVOICE_ID
         and AI.invoice_id = p_invoice_id --1006374
         AND AID.INVOICE_ID = AIL.INVOICE_ID
         AND AID.INVOICE_LINE_NUMBER = AIL.LINE_NUMBER
         AND NVL(AIL.DISCARDED_FLAG, 'N') <> 'Y'
         AND AID.LINE_TYPE_LOOKUP_CODE = 'PREPAY'
         AND AID1.INVOICE_DISTRIBUTION_ID = AID.PREPAY_DISTRIBUTION_ID
         AND AIL1.INVOICE_ID = AID1.INVOICE_ID
         AND AIL1.LINE_NUMBER = AID1.INVOICE_LINE_NUMBER
         AND AI1.INVOICE_ID = AIL1.INVOICE_ID;
  
    l_fichier_entete UTL_FILE.FILE_TYPE;
    l_message_entete VARCHAR2(2000);
    l_entete_fac     VARCHAR2(2000);
  
    l_fichier_lignes  UTL_FILE.FILE_TYPE;
    l_message_lignes  VARCHAR2(2000);
    l_entete_lignes   VARCHAR2(2000);
    l_fichier_blocage UTL_FILE.FILE_TYPE;
    l_message_blocage VARCHAR2(2000);
    l_entete_blocage  VARCHAR2(2000);
    l_fichier_payment UTL_FILE.FILE_TYPE;
    l_message_payment VARCHAR2(2000);
    l_entete_payment  VARCHAR2(2000);
    L_line_count      NUMBER;
    l_path_c          VARCHAR2(240) := 'DKA_OUT_DIR';
    Vv_Conversion_In  VARCHAR2(255); --IBA EDB351
    Vv_Conversion_Out VARCHAR2(255); --IBA EDB351
  
    vv_step            VARCHAR2(500);
    v_file_name        fnd_documents.file_name%TYPE;
    vv_file_name       fnd_documents.file_name%TYPE;
    v_document_id      Number; --SELO EDB329
    v_media_id         Number; --SELO EDB329
    v_due_date         VARCHAR2(30);
    v_task             pa_tasks_expend_v.task_number%TYPE;
    v_expenditure_type ap_invoice_distributions_all.expenditure_type%TYPE;
  
    -- Defect # 1068
    vn_request_id Fnd_Concurrent_Requests.Request_Id%Type;
    CHEMIN        VARCHAR2(500);
  
  BEGIN
    DBMS_OUTPUT.ENABLE(1000000);
  
    select directory_path
      into CHEMIN
      from dba_directories
     where directory_name = 'DKA_OUT_DIR';
  
    vv_step := '001';
  
    IF UTL_FILE.IS_OPEN(l_fichier_entete) THEN
      UTL_FILE.FCLOSE(l_fichier_entete);
    END IF;
  
    IF UTL_FILE.IS_OPEN(l_fichier_lignes) THEN
      UTL_FILE.FCLOSE(l_fichier_lignes);
    END IF;
  
    IF UTL_FILE.IS_OPEN(l_fichier_blocage) THEN
      UTL_FILE.FCLOSE(l_fichier_blocage);
    END IF;
  
    IF UTL_FILE.IS_OPEN(l_fichier_payment) THEN
      UTL_FILE.FCLOSE(l_fichier_payment);
    END IF;
    vv_step      := '002';
    L_line_count := 0;
    NB_LIGNE     := 0; -- EDB265
    NB_BLOCAGE   := 0; -- EDB265
    NB_REGLEMENT := 0; -- EDB265
  
    g_header_file  := 'DSP01_INV_ENTETE_' ||
                      TO_CHAR(g_date, 'YYYYMMDDHH24MISS') || '_ST_FIN01_' ||
                      to_char(g_request_id) || '.csv';
    g_line_file    := 'DSP01_INV_LIGNE_' ||
                      TO_CHAR(g_date, 'YYYYMMDDHH24MISS') || '_ST_FIN01_' ||
                      to_char(g_request_id) || '.csv';
    g_hold_file    := 'DSP01_INV_BLOCAGE_' ||
                      TO_CHAR(g_date, 'YYYYMMDDHH24MISS') || '_ST_FIN01_' ||
                      to_char(g_request_id) || '.csv';
    g_payment_file := 'DSP01_INV_REGLT_' ||
                      TO_CHAR(g_date, 'YYYYMMDDHH24MISS') || '_ST_FIN01_' ||
                      to_char(g_request_id) || '.csv';
  
    vv_step := '003 : Nom du fichier entete' || ' : ' || g_header_file;
    DKA_TOOLS_PKG.put_log_message(vv_step);
  
    vv_step           := '004 : Ouverture du fichier des entetes';
    l_fichier_entete  := UTL_FILE.FOPEN(l_path_c, g_header_file, 'w');
    l_fichier_lignes  := UTL_FILE.FOPEN(l_path_c, g_line_file, 'w');
    l_fichier_blocage := UTL_FILE.FOPEN(l_path_c, g_hold_file, 'w');
    l_fichier_payment := UTL_FILE.FOPEN(l_path_c, g_payment_file, 'w');
  
    l_entete_fac := 'INVOICE_ID' || G_separateur || 'INVOICE_NUM' ||
                    G_separateur || 'UO' || G_separateur ||
                    'SUPPLIER_SITE_ID_IVALUA' -- SELO EDB278C  --'SUPPLIER_NUM'
                    || G_separateur || 'INVOICE_TYPE_LOOKUP_CODE' ||
                    G_separateur || 'INVOICE_CURRENCY' || G_separateur ||
                    'INVOICE_AMOUNT_TTC' || G_separateur ||
                    'INVOICE_AMOUNT_HT' || G_separateur || 'INVOICE_DATE' ||
                    G_separateur || 'PAYMENT_TERMS' || G_separateur ||
                    'DUE_DATE' || G_separateur || 'PAYMENT_METHOD' ||
                    G_separateur || 'INVOICE_STATUS' || G_separateur ||
                    'AMOUNT_PAID' || G_separateur || 'DIRECT_PAYMENT' ||
                    G_separateur || 'INVOICE_FILE_NAME' || G_separateur ||
                    'PO_FLIP' || G_separateur || 'FACTORING' ||
                    G_separateur || 'ID_FACTURE_IVALUA'
    --|| G_separateur || 'DIRECT_PAYEMENT ' -- BNZ EDB392
     ;
    UTL_FILE.PUT_LINE(l_fichier_entete, l_entete_fac);
    l_entete_lignes := 'INVOICE_ID' || G_separateur || 'INVOICE_LINE_NUM' ||
                       G_separateur || 'LINE_TYPE_LOOKUP_CODE' ||
                       G_separateur || 'LINE_AMOUNT' || G_separateur ||
                       'VAT_CODE' || G_separateur || 'LINE_DESCRIPTION' ||
                       G_separateur || 'PO_NUM' || G_separateur ||
                       'IVALUA_PO_LINE_ID' || G_separateur ||
                       'QTY_RECEIVED' || G_separateur || 'QTY_BILLED' ||
                       G_separateur || 'UNIT_PRICE' || G_separateur ||
                       'TASK_NUMBER' || G_separateur || 'EXPENDITURE_TYPE' ||
                       G_separateur || 'CANCELLED_FLAG' -- BNZ EDB392
                       || G_separateur || 'DISCARDED_FLAG' -- BNZ EDB392
    
     ;
    UTL_FILE.PUT_LINE(l_fichier_lignes, l_entete_lignes);
  
    l_entete_blocage := 'INVOICE_ID' || G_separateur || 'IVALUA_PO_LINE_ID' ||
                        G_separateur || 'HOLD_ID' || G_separateur ||
                        'HOLD_CODE' || G_separateur || 'HOLD_TYPE' ||
                        G_separateur || 'EMPLOYEE_TO_NOTIFY' ||
                        G_separateur || 'HOLD_DATE' || G_separateur ||
                        'HOLD_REASON' || G_separateur || 'RELEASE_CODE' ||
                        G_separateur || 'RELEASE_DATE' || G_separateur ||
                        'RELEASE_REASON' || G_separateur || 'HOLD_STATUS'
    
     ;
    UTL_FILE.PUT_LINE(l_fichier_blocage, l_entete_blocage);
  
    l_entete_payment := 'INVOICE_ID' || G_separateur || 'PAYMENT_TYPE' ||
                        G_separateur || 'PAYMENT_ID' || G_separateur ||
                        'PAYMENT_NUM' || G_separateur || 'PAYMENT_LINE_NUM' ||
                        G_separateur || 'PAYMENT_DATE' || G_separateur ||
                        'PAYMENT_AMOUNT' || G_separateur ||
                        'PAYMENT_METHOD' || -- BNZ EDB392
                        G_separateur || 'VOID' -- BNZ EDB392
     ;
    UTL_FILE.PUT_LINE(l_fichier_payment, l_entete_payment);
  
    -- 14/10/2021 - JWYC - INC0589061 - Export Ivalua qui dure 12h malgré la MEP du correctif
    vv_step := 'Insertion en table temporaire des factures pour lesquelles la date de derniere maj des images est superieure a celle des factures';
    DKA_TOOLS_PKG.put_log_message(vv_step);
  
    insert into dka_iapfac_ivalua_img_maj
      select aia.invoice_id,
             aia.last_update_date     inv_last_update_date,
             fad.attached_document_id,
             fad.last_update_date     doc_last_update_date
        from fnd_attached_documents fad, ap_invoices_all aia
       where fad.entity_name = 'AP_INVOICES'
         and fad.pk1_value = aia.invoice_id
         and fad.last_update_date > aia.last_update_date
         and fad.last_update_date > p_date;
    -- /JWYC
  
    vv_step := 'Boucle sur les entetes';
    DKA_TOOLS_PKG.put_log_message(vv_step);
    FOR rec_inv_header IN c_inv_header(p_date) LOOP
      vv_step := 'invoice_id : ' || rec_inv_header.invoice_id;
      DKA_TOOLS_PKG.put_log_message(vv_step);
      BEGIN
        SELECT d.file_name,
               dt.document_id -- SELO EDB329
              ,
               d.media_id -- SELO EDB329
          INTO v_file_name,
               v_document_id -- SELO EDB329
              ,
               v_media_id -- SELO EDB329
          FROM fnd_documents_tl           dt,
               fnd_documents              d,
               fnd_document_categories_tl dct,
               fnd_attached_documents     ad,
               fnd_document_datatypes     dat
         WHERE d.document_id = ad.document_id
           AND dt.document_id = d.document_id
           AND dt.language = 'F'
           AND dct.category_id = d.category_id
           AND dct.language = 'F'
           AND dct.name = 'MISC'
           AND entity_name = 'AP_INVOICES'
           AND dt.description = 'IMAGE FACTURE'
           AND d.datatype_id = dat.datatype_id
           AND dat.language = 'F'
           AND dat.name = 'FILE'
           AND pk1_value = to_char(rec_inv_header.invoice_id)
           AND rec_inv_header.inv_po_flip != 'Y' -- EDB278-D
           AND ((ad.ATTRIBUTE1 IS NULL) or
               (to_date(ad.ATTRIBUTE1, 'DD/MM/YYYY HH24:MI:SS') <
               ad.last_update_date)) -- EDB278-D
         order by ad.creation_date
         fetch first 1 row only;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_file_name   := null;
          v_document_id := null; --EDB329
          v_media_id    := null; --EDB329
      END;
      BEGIN
        SELECT to_char(apsa.due_date, 'DD/MM/YYYY')
          INTO v_due_date
          FROM ap_payment_schedules_all apsa
         WHERE apsa.invoice_id = rec_inv_header.invoice_id
         order by apsa.due_date
         fetch first 1 row only;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_due_date := null;
      END;
      if ((rec_inv_header.source like 'Manual%') and
         (v_file_name is not null) and (v_document_id is not null) and
         (v_media_id is not null)) then
        -- SELO EDB329
        vv_file_name := 'IMG_' || to_char(rec_inv_header.invoice_id) || '_' ||
                        REGEXP_REPLACE(v_file_name, '[^0-9A-Za-z.]', ''); -- SELO EDB329
        vv_file_name := substr(vv_file_name, 1, 146) ||
                        substr(vv_file_name,
                               length(vv_file_name) - 3,
                               length(vv_file_name)); -- BNZ EDB392
      
      else
        vv_file_name := v_file_name;
    vv_file_name := substr(vv_file_name, 1, 146) ||
                        substr(vv_file_name,
                               length(vv_file_name) - 3,
                               length(vv_file_name)); -- BNZ EDB392
      end if; -- SELO EDB329
      l_message_entete := rec_inv_header.invoice_id || G_separateur ||
                          rec_inv_header.invoice_num || G_separateur ||
                          rec_inv_header.uo || G_separateur ||
                          rec_inv_header.ID_IVALUA_SITE -- SELO EDB278C   -- rec_inv_header.supplier_num
                          || G_separateur ||
                          rec_inv_header.INVOICE_TYPE_LOOKUP_CODE ||
                         -- G_separateur || rec_inv_header.direct_payment  || -- BNZ EDB392 VIDE
                          G_separateur ||
                          rec_inv_header.INVOICE_CURRENCY_CODE ||
                          G_separateur || rec_inv_header.INVOICE_AMOUNT ||
                          G_separateur || rec_inv_header.MNT_HT ||
                          G_separateur || rec_inv_header.invoice_date ||
                          G_separateur || rec_inv_header.payment_terms_name ||
                          G_separateur || v_due_date || G_separateur ||
                          rec_inv_header.term_name || G_separateur ||
                          rec_inv_header.invoice_status || G_separateur ||
                          rec_inv_header.AMOUNT_PAID || G_separateur ||
                          rec_inv_header.direct_payment || G_separateur ||
                          vv_file_name || G_separateur ||
                          rec_inv_header.inv_po_flip || G_separateur ||
                          rec_inv_header.factoring || G_separateur ||
                          rec_inv_header.ID_FACTURE_IVALUA -- SELO EDB296
       ;
    
      L_line_count := L_line_count + 1;
      UTL_FILE.PUT_LINE(l_fichier_entete, l_message_entete);
    
      INSERT INTO DKA_IAPFAC_IVALUA
        (INVOICE_ID,
         INVOICE_NUM,
         PO_Flip,
         inv_file_name,
         CREATION_DATE,
         CREATED_BY,
         LAST_UPDATE_DATE,
         LAST_UPDATED_BY)
      values
        (rec_inv_header.invoice_id,
         rec_inv_header.invoice_num,
         rec_inv_header.inv_po_flip,
         vv_file_name, -- SELO EDB329
         sysdate,
         g_user,
         sysdate,
         g_user);
    
      -- SELO EDB329 DEBUT
      -- SELO EDB329 DEBUT
      if ((rec_inv_header.source is not null) and
         (v_file_name is not null) and (v_document_id is not null) and
         (v_media_id is not null)) then --BNZ EDB392
        -- SELO EDB329     
        update fnd_lobs
           set file_name = vv_file_name
         where file_id = v_media_id
     AND file_name != vv_file_name; --BNZ EDB392
      
        update fnd_documents_tl
           set file_name = vv_file_name
         where document_id = v_document_id
       AND file_name != vv_file_name; --BNZ EDB392
        update fnd_documents
           set file_name = vv_file_name
         where document_id = v_document_id
      AND file_name != vv_file_name; --BNZ EDB392
      
        COMMIT;
      end if;
      -- SELO EDB329 FIN
    
      FOR rec_inv_line IN c_inv_line(rec_inv_header.invoice_id) LOOP
        IF rec_inv_line.LINE_TYPE_LOOKUP_CODE != 'TAX' THEN
          BEGIN
            SELECT pat.task_number, aida.expenditure_type
              INTO v_task, v_expenditure_type
              FROM ap_invoice_distributions_all aida,
                   pa_tasks_expend_v            pat,
                   pa_projects_all              pap
             WHERE aida.invoice_id = rec_inv_line.invoice_id
               AND aida.INVOICE_LINE_NUMBER = rec_inv_line.LINE_NUMBER
               AND aida.LINE_TYPE_LOOKUP_CODE =
                   rec_inv_line.LINE_TYPE_LOOKUP_CODE
                  --AND   aida.task_id = pat.task_id (+)
               AND DECODE(pap.project_type,
                          'REFAC',
                          to_number(aida.attribute7),
                          aida.task_id) = pat.task_id(+)
               AND aida.project_id = pap.project_id(+)
                  --AND   aida.amount is not null
               AND nvl(aida.amount, 0) != 0
               AND rownum = 1;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              v_task             := null;
              v_expenditure_type := null;
          END;
        ELSE
          v_task             := null;
          v_expenditure_type := null;
        END IF;
      
        l_message_lignes := rec_inv_line.invoice_id || G_separateur ||
                            rec_inv_line.LINE_NUMBER || G_separateur ||
                            rec_inv_line.LINE_TYPE_LOOKUP_CODE ||
                            G_separateur || rec_inv_line.amount ||
                            G_separateur || rec_inv_line.TAX_RATE_CODE ||
                            G_separateur || rec_inv_line.DESCRIPTION ||
                            G_separateur || rec_inv_line.po_number ||
                            G_separateur || rec_inv_line.ivalua_po_line ||
                            G_separateur || rec_inv_line.QUANTITY_RECEIVED ||
                            G_separateur || rec_inv_line.quantity_invoiced ||
                            G_separateur || rec_inv_line.UNIT_PRICE ||
                            G_separateur || v_task || G_separateur ||
                            v_expenditure_type || G_separateur ||
                            rec_inv_line.CANCELLED_FLAG || -- BNZ EDB392 
                            G_separateur || rec_inv_line.DISCARDED_FLAG -- BNZ EDB392
         ;
        UTL_FILE.PUT_LINE(l_fichier_lignes, l_message_lignes);
        NB_LIGNE := NB_LIGNE + 1;
      END LOOP;
      Vv_Conversion_In  := 'ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÑÒÓÔÕÖÙÚÛÜYÝàáâãäåæçèéêëìíîïñòóôõöùúûüýÿ|'; --IBA EDB351
      Vv_Conversion_Out := 'AAAAAAACEEEEIIIINOOOOOUUUUYYaaaaaaaceeeeiiiinooooouuuuyy '; --IBA EDB351
    
      FOR rec_inv_hold IN c_inv_hold(rec_inv_header.invoice_id) LOOP
      
        --EDB351
        IF rec_inv_hold.statut_blocage = 'A_TRAITER_IVALUA' THEN
          vv_commentaire := rec_inv_hold.commentaire;
        ELSE
          vv_commentaire := null;
        END IF;
        --END EDB351
      
        g_reason_commen := translate(substr(rec_inv_hold.hold_reason ||
                                            vv_commentaire,
                                            0,
                                            240),
                                     Vv_Conversion_In,
                                     Vv_Conversion_Out); -- ARA EDB351 LOT 1
      
        l_message_blocage := rec_inv_hold.invoice_id || G_separateur ||
                             rec_inv_hold.Id_line_Ivalua || G_separateur ||
                             rec_inv_hold.hold_id || G_separateur ||
                             rec_inv_hold.hold_lookup_code || G_separateur ||
                             rec_inv_hold.type_blocage_en_attente ||
                             G_separateur ||
                             rec_inv_hold.employe_a_notifier ||
                             G_separateur || rec_inv_hold.hold_date ||
                             G_separateur || REPLACE(g_reason_commen,
                                                     CHR(13) || CHR(10),
                                                     '') || -- ARA EDB351 LOT 1
                             G_separateur ||
                             rec_inv_hold.RELEASE_LOOKUP_CODE ||
                             G_separateur || rec_inv_hold.release_date ||
                             G_separateur || rec_inv_hold.RELEASE_REASON ||
                             G_separateur || rec_inv_hold.statut_blocage
        
         ;
        UTL_FILE.PUT_LINE(l_fichier_blocage, l_message_blocage);
        NB_BLOCAGE := NB_BLOCAGE + 1;
      END LOOP;
    
      FOR rec_inv_payment IN c_inv_payment(rec_inv_header.invoice_id) LOOP
      
        l_message_payment := rec_inv_payment.invoice_id || G_separateur ||
                             rec_inv_payment.PAYMENT_TYPE || G_separateur ||
                             rec_inv_payment.PAYMENT_ID || G_separateur ||
                             rec_inv_payment.PAYMENT_NUM || G_separateur ||
                             rec_inv_payment.PAYMENT_LINE_NUM ||
                             G_separateur || rec_inv_payment.PAYMENT_DATE ||
                             G_separateur || rec_inv_payment.PAYMENT_AMOUNT ||
                             G_separateur || rec_inv_payment.PAYMENT_METHOD || -- BNZ EDB392
                             G_separateur || rec_inv_payment.VOID -- BNZ EDB392
         ;
        UTL_FILE.PUT_LINE(l_fichier_payment, l_message_payment);
        NB_REGLEMENT := NB_REGLEMENT + 1;
      END LOOP;
    
    END LOOP;
  
    NB_FACTURE := L_line_count;
  
    DKA_TOOLS_PKG.put_log_message('Nombre d''entete charges : ' ||
                                  L_line_count);
    vv_step := '005 : Fermeture du fichier entete';
    DKA_TOOLS_PKG.put_log_message(vv_step);
    UTL_FILE.fclose(l_fichier_payment);
    UTL_FILE.fclose(l_fichier_lignes);
    UTL_FILE.fclose(l_fichier_blocage);
    UTL_FILE.fclose(l_fichier_entete);
  
    -- SELO Defect # 1068 : Debut
  
    fnd_file.put_line(fnd_file.LOG, 'Conversion des fichiers vers UTF-8');
    vn_request_id := fnd_request.submit_request(application => 'DKA',
                                                program     => 'DKA_SLAUNCHER',
                                                description => NULL,
                                                start_time  => NULL,
                                                sub_request => FALSE,
                                                Argument1   => 'DKA_SLAUNCHER_CONCAT',
                                                Argument2   => TO_CHAR(g_date,
                                                                       'YYYYMMDDHH24MISS'),
                                                Argument3   => CHEMIN);
    COMMIT;
  
    IF vn_request_id != 0 THEN
      l_message := 'Attente fin traitement';
      DKA_TOOLS_PKG.put_log_message(l_message);
      l_execute_code := FND_CONCURRENT.WAIT_FOR_REQUEST(REQUEST_ID => vn_request_id,
                                                        INTERVAL   => l_req_interval,
                                                        MAX_WAIT   => l_req_max_wait,
                                                        PHASE      => l_req_phase,
                                                        STATUS     => l_req_status,
                                                        DEV_PHASE  => l_req_dev_phase,
                                                        DEV_STATUS => l_req_dev_status,
                                                        MESSAGE    => l_req_message);
    
      IF l_req_dev_phase = 'COMPLETE' AND l_req_dev_status = 'WARNING' THEN
        l_message := l_procedure ||
                     ' Le traitement de conversion des fichiers en UTF-8 est termine en avertissement';
        DKA_TOOLS_PKG.put_log_message(l_message);
        pn_retcode := 1;
      
      ELSIF l_req_dev_phase = 'COMPLETE' AND l_req_dev_status = 'ERROR' THEN
        l_message := ' Le traitement de conversion des fichiers en UTF-8 est termine en erreur';
        DKA_TOOLS_PKG.put_log_message(l_message);
        pn_retcode := 2;
      ELSIF l_req_dev_phase = 'COMPLETE' AND l_req_dev_status = 'NORMAL' THEN
        l_message := ' le traitement de conversion des fichiers en UTF-8 est termine normal';
        DKA_TOOLS_PKG.put_log_message(l_message);
        Fnd_File.put_line(Fnd_File.LOG, l_message);
        pn_retcode := 0;
      END IF;
    ELSE
      l_message := ' Erreur lors du lancement du traitement de conversion des fichiers en UTF-8';
      DKA_TOOLS_PKG.put_log_message(l_message);
      DBMS_OUTPUT.PUT_LINE(l_message);
      pn_retcode := 2;
    
    END IF;
  
    -- SELO Defect # 1068 : Fin
  
  END;

  /*======================================================================================================*/
  --  Nom           : checkFileExistOrNot
  --  Description   : check l existance d un fichier dans un repertoire.
  --  DATE          : 19/02/2021
  /*=========================================================================================================*/

  PROCEDURE checkFileExistOrNot(v_dir         IN VARCHAR2,
                                v_file        in VARCHAR2,
                                lb_file_exist out boolean) IS
    ln_size       number;
    ln_block_size number;
  
  BEGIN
    sys.utl_file.fgetattr(v_dir,
                          v_file,
                          lb_file_exist,
                          ln_size,
                          ln_block_size);
  EXCEPTION
    when others Then
      null;
  END;

  /*======================================================================================================*/
  --  Nom           : dka_retrieve_lob_to_file
  --  Description   : procedure principale du traitement qui enchainera l'ensemble
  --                  des autres procedures.
  --  PARAMETRES    :
  --  DATE          : 22/09/2020
  /*=========================================================================================================*/
  PROCEDURE dka_retrieve_lob_to_file(temp_blob  in BLOB,
                                     file_path  in varchar2,
                                     file_name  in varchar2,
                                     pv_errbuf  IN OUT VARCHAR2 -- EDB278-D
                                    ,
                                     pn_retcode OUT NUMBER -- EDB278-D
                                    ,
                                     FCP_REQID  in number,
                                     pk_value   in varchar2) IS
    data_buffer   RAW(32767);
    position      INTEGER := 1;
    filehandle    utl_file.file_type;
    error_number  NUMBER;
    error_message VARCHAR2(100);
    blob_length   INTEGER;
    chunk_size    BINARY_INTEGER := 32767;
  
    v_file_path_out VARCHAR2(200); -- EDB278-D
    v_file_name_out VARCHAR2(200); -- EDB278-D
    v_file_path_log VARCHAR2(200); -- EDB278-D
    v_file_name_log VARCHAR2(200); -- EDB278-D
    v_line_out      VARCHAR2(1000); -- EDB278-D
    v_line_log      VARCHAR2(200); -- EDB278-D
    v_file_log      UTL_FILE.FILE_TYPE;
    v_file_out      UTL_FILE.FILE_TYPE;
    vb_file_exist   BOOLEAN;
  BEGIN
    -- EDB278-D DEBUT
  
    DBMS_OUTPUT.ENABLE(2000000);
  
    pn_retcode := 0;
  
    --v_file_out    := UTL_FILE.fopen ('DKA_OUTPUT' ,v_file_name_out ,'w');
  
    -- EDB278-D FIN
    blob_length := dbms_lob.getlength(temp_blob);
  
    -- NBO 01/07/21 artf07467299 - INC0559716 - Les deux traitement d'export ci-dessous se sont termine en erreur : => DKA : Export des donnees Factures vers iValua
    filehandle := utl_file.fopen(file_path, file_name, 'wb', 32767);
  
    WHILE position < blob_length LOOP
      --UTL_FILE.put_line (v_file_log ,'SELO : file_path : '||file_path||', Fichier : ' ||file_name );
      dbms_lob.read(temp_blob, chunk_size, position, data_buffer);
      utl_file.put_raw(filehandle, data_buffer);
      position    := position + chunk_size;
      data_buffer := null;
      --UTL_FILE.put_line (v_file_log ,'SELO : file_path : '||file_path||', Fichier - OK: ' ||file_name );
    END LOOP;
  
    utl_file.fclose(filehandle);
    -- v_file_out    := UTL_FILE.fopen ('DKA_OUTPUT' ,v_file_name_out ,'w');
    -- UTL_FILE.fclose ( v_file_log);
    --UTL_FILE.fclose ( v_file_out);
  
  EXCEPTION
    WHEN OTHERS THEN
      BEGIN
        error_number  := sqlcode;
        error_message := substr(sqlerrm, 1, 100);
      
        checkFileExistOrNot('DKA_IMG_IVALUA', file_name, vb_file_exist);
        if vb_file_exist then
          pv_errbuf := error_message;
          dbms_output.put_line('Invoice_id : ' || pk_value ||
                               ', Fichier : ' || file_name ||
                               ' , Avertissement # ' || error_number);
          dbms_output.put_line('Invoice_id : ' || pk_value ||
                               ', Fichier : ' || file_name ||
                               ', Message d''avertissement: ' ||
                               error_message);
        else
          pn_retcode := 2;
          pv_errbuf  := error_message;
          dbms_output.put_line('Invoice_id : ' || pk_value ||
                               ', Fichier : ' || file_name ||
                               ' , Error # ' || error_number);
          dbms_output.put_line('Invoice_id : ' || pk_value ||
                               ', Fichier : ' || file_name ||
                               ', Error Message: ' || error_message);
        end if;
      
        --UTL_FILE.put_line (v_file_out ,'Invoice_id : '||pk_value||', Fichier : ' ||file_name || ', Error # '|| error_number);
        --UTL_FILE.put_line (v_file_out ,'Invoice_id : '||pk_value||', Fichier : ' ||file_name || ', Error Message: ' || error_message);
        --UTL_FILE.fclose ( v_file_out);
        utl_file.fclose_all;
      END;
  END;
  /*======================================================================================================*/
  --  Nom           : EXPORT_IMG
  --  Description   : procedure principale du traitement qui enchainera l'ensemble
  --                  des autres procedures.
  --  PARAMETRES    : p_file : nom de fichier ou les images sont exportees
  --  DATE          : 22/09/2020
  /*=========================================================================================================*/
  PROCEDURE EXPORT_IMG(p_file        in varchar2,
                       req_id        in number,
                       p_user_id     in number,
                       Sn_retcode    IN OUT NUMBER,
                       g_date_export in varchar2) IS
  
    CURSOR c_img_to_export IS
      SELECT d.media_id,
             fl.file_data,
             fl.file_name,
             ad.document_id,
             ad.pk1_value
        FROM fnd_documents          d,
             fnd_attached_documents ad,
             DKA_IAPFAC_IVALUA      dii,
             fnd_lobs               fl
       WHERE d.document_id = ad.document_id
         AND ad.pk1_value = TO_CHAR(dii.invoice_id)
         AND d.file_name = dii.inv_file_name
         AND fl.file_id = d.media_id
         AND dii.po_flip != 'Y'
            --  AND  ad.ATTRIBUTE1 IS NULL  --EDB278-D
         AND ((ad.ATTRIBUTE1 IS NULL) or
             (to_date(ad.ATTRIBUTE1, 'DD/MM/YYYY HH24:MI:SS') <
             ad.last_update_date)) --EDB278-D
      ;
    l_file_data        fnd_lobs.file_data%TYPE;
    l_file_name        fnd_lobs.file_name%TYPE;
    l_fichier_img      UTL_FILE.FILE_TYPE;
    l_path_img         VARCHAR2(240) := 'DKA_IMG_IVALUA';
    v_file             VARCHAR2(240);
    r_img_to_export    c_img_to_export%ROWTYPE;
    v_row_conut        NUMBER;
    l_message          VARCHAR2(250);
    vv_errbuf          VARCHAR2(500);
    vn_retcode         NUMBER;
    g_date_execution   VARCHAR2(50);
    g_date_format_date date;
  BEGIN
    Sn_retcode := 0;
    DBMS_OUTPUT.ENABLE(1000000);
  
    select to_char(to_date(g_date_export, 'YYYYMMDDHH24MISS'),
                   'DD/MM/YYYY HH24:MI:SS'),
           to_date(g_date_export, 'YYYYMMDDHH24MISS')
      into g_date_execution, g_date_format_date
      from dual;
  
    SELECT ad.directory_path
      INTO gv_directory_path
      FROM all_directories ad
     WHERE ad.directory_name = 'DKA_IMG_IVALUA';
    /*v_file := gv_directory_path||'/'||p_file;
    execute immediate 'create or replace directory DKA_IMGFAC_IVALUA as '''||v_file||'''';*/
    OPEN c_img_to_export;
    LOOP
      FETCH c_img_to_export
        INTO r_img_to_export;
      EXIT WHEN c_img_to_export%notfound;
      vn_retcode := 0; -- EDB278-D
    
      dka_retrieve_lob_to_file(r_img_to_export.file_data,
                               'DKA_IMG_IVALUA',
                               r_img_to_export.file_name,
                               vv_errbuf -- EDB278-D
                              ,
                               vn_retcode -- EDB278-D
                              ,
                               req_id -- EDB278-D
                              ,
                               r_img_to_export.pk1_value);
      -- EDB278-D Debut
      If vn_retcode != 2 then
        UPDATE fnd_attached_documents
           Set attribute1       = g_date_execution --TO_CHAR(g_date,'DD/MM/YYYY HH24:MI:SS')
              ,
               LAST_UPDATED_BY  = p_user_id,
               LAST_UPDATE_DATE = g_date_format_date --g_date -- SYSDATE  -- EDB278-D
         WHERE document_id = r_img_to_export.document_id;
        --pn_retcode := vn_retcode;
      else
        Sn_retcode := 1;
      End IF;
      -- EDB278-D fin
    END LOOP;
  
    v_row_conut := c_img_to_export%ROWCOUNT;
    dbms_output.put_line('v_row_conut: ' || v_row_conut);
    --NB_IMAGE := v_row_conut;
    IF v_row_conut = 0 THEN
      --dbms_output.put_line('v_row_conut is null');
      IF UTL_FILE.IS_OPEN(l_fichier_img) THEN
        UTL_FILE.FCLOSE(l_fichier_img);
      END IF;
      g_img_file    := 'DSP01_INV_IMAGES_DEFAULT_FILE.txt';
      l_fichier_img := UTL_FILE.FOPEN(l_path_img, g_img_file, 'w');
      --UTL_FILE.PUT_LINE(l_fichier_img, 'test_aam');
      UTL_FILE.fclose(l_fichier_img);
    end if;
    g_pic_file := p_file;
    COMMIT; --SHA Correction suite au correctif INC0601593
  END;
  /*==============================================================================*/
  -- Procedure         : LANCE_EXPORT_IMG
  -- Description       : Procedure pour lancer l'export des images
  -- Parametres entree : AUCUN
  -- Parametres sortie : AUCUN
  -- Auteur            : Asma AMENKOUR
  -- Date              : 25/09/2020
  -- Remarques         :
  /*=================================================================================*/
  PROCEDURE LANCE_EXPORT_IMG(pv_errbuf  IN OUT VARCHAR2,
                             pn_retcode OUT NUMBER) IS
  
    l_procedure        VARCHAR2(30) := 'LANCE_EXPORT_IMG';
    l_message          VARCHAR2(2000);
    l_request_id       NUMBER;
    l_application_code VARCHAR2(50) := 'DKA';
    l_conc_program     VARCHAR2(50) := 'DKA_IAPIMG_IVALUA';
    l_execute_code     BOOLEAN;
    l_req_interval     NUMBER := 30;
    l_req_max_wait     NUMBER := 999999;
    l_req_ret_code     NUMBER;
    l_req_phase        VARCHAR2(255);
    l_req_status       VARCHAR2(255);
    l_req_dev_phase    VARCHAR2(255);
    l_req_dev_status   VARCHAR2(255);
    l_status           VARCHAR2(255);
    l_req_message      VARCHAR2(255);
  
    vf_errbuf         VARCHAR2(500);
    vf_retcode        NUMBER;
    v_date_attribute1 VARCHAR2(50);
    --v_SYSDATE                     DATE := SYSDATE;
    --v_user                        NUMBER        := fnd_profile.value('USER_ID');
  BEGIN
    DBMS_OUTPUT.ENABLE(1000000);
    l_message := l_procedure || '- 01 - Debut';
    Fnd_File.put_line(Fnd_File.LOG, l_message);
  
    l_message := l_procedure || '- 02 - Submit Request';
    Fnd_File.put_line(Fnd_File.LOG, l_message);
  
    l_request_id := FND_REQUEST.submit_request(l_application_code,
                                               l_conc_program,
                                               '',
                                               SYSDATE,
                                               FALSE,
                                               g_pic_file,
                                               to_char(g_date,
                                                       'DD/MM/YYYY"T"HH24:MI:SS'));
  
    COMMIT;
    IF l_request_id != 0 THEN
      l_message := l_procedure || ' - 03 - Attente fin traitement';
      DKA_TOOLS_PKG.put_log_message(l_message);
      l_execute_code := FND_CONCURRENT.WAIT_FOR_REQUEST(REQUEST_ID => l_request_id,
                                                        INTERVAL   => l_req_interval,
                                                        MAX_WAIT   => l_req_max_wait,
                                                        PHASE      => l_req_phase,
                                                        STATUS     => l_req_status,
                                                        DEV_PHASE  => l_req_dev_phase,
                                                        DEV_STATUS => l_req_dev_status,
                                                        MESSAGE    => l_req_message);
    
      IF l_req_dev_phase = 'COMPLETE' AND l_req_dev_status = 'WARNING' THEN
        l_status  := 'Avertissement';
        l_message := l_procedure ||
                     ' - 04a - Traitement termine en avertissement';
        DKA_TOOLS_PKG.put_log_message(l_message);
        pn_retcode := 1;
      ELSIF l_req_dev_phase = 'COMPLETE' AND l_req_dev_status = 'ERROR' THEN
        l_status  := 'Erreur';
        l_message := l_procedure || ' - 04b - Traitement termine en erreur';
        DKA_TOOLS_PKG.put_log_message(l_message);
        pn_retcode := 2;
      ELSIF l_req_dev_phase = 'COMPLETE' AND l_req_dev_status = 'NORMAL' THEN
        l_status  := 'Normal';
        l_message := l_procedure || ' - 04b - Traitement termine normal';
        DKA_TOOLS_PKG.put_log_message(l_message);
        pn_retcode := 0;
        /*v_date_attribute1 := TO_CHAR(g_date,'DD/MM/YYYY HH24:MI:SS')  ;
        l_message := 'v_date_attribute1 est :'||v_date_attribute1;
        DKA_TOOLS_PKG.put_log_message(l_message);
        l_message := 'v_user est :'||v_user;
        DKA_TOOLS_PKG.put_log_message(l_message);
        l_message := 'v_sysdate est :'||v_sysdate;
        DKA_TOOLS_PKG.put_log_message(l_message);
        
        FOR rec IN (SELECT  ad.document_id
                 FROM
                  fnd_documents d
                 , fnd_attached_documents ad
                 , DKA_IAPFAC_IVALUA      dii
                 , fnd_lobs   fl
                 WHERE d.document_id = ad.document_id
                  AND  ad.pk1_value = TO_CHAR(dii.invoice_id)
                  AND  d.file_name  = dii.inv_file_name
                  AND  fl.file_id   = d.media_id
                  AND  dii.po_flip != 'Y'
                  AND  ad.ATTRIBUTE1 IS NULL) LOOP
          BEGIN
            UPDATE fnd_attached_documents
            Set attribute1 = v_date_attribute1
            --,   LAST_UPDATED_BY =  v_user
            --,   LAST_UPDATE_DATE = v_SYSDATE
            WHERE document_id = rec.document_id ;
          EXCEPTION
          WHEN OTHERS THEN
            l_message := 'Erreur lors de la mise a jour de l''attribute1 de la table fnd_attached_documents';
            DKA_TOOLS_PKG.put_log_message(l_message);
          END;
         END LOOP;*/
      END IF;
    ELSE
      l_message := l_procedure ||
                   ' - 03 - Erreur lors du lancement du traitement';
      DKA_TOOLS_PKG.put_log_message(l_message);
      DBMS_OUTPUT.PUT_LINE(l_message);
      pn_retcode := 2;
    
    END IF;
    COMMIT;
  
  END LANCE_EXPORT_IMG;
  /*==============================================================================*/
  -- Procedure         : log_supervision
  -- Description       : Procedure pour generer le fichier de supervision
  -- Parametres entree : AUCUN
  -- Parametres sortie : AUCUN
  -- Auteur            : SELO
  -- Date              : 28/01/2021
  -- Remarques         : EDB265
  /*=================================================================================*/
  PROCEDURE log_supervision(pv_errbuf  IN OUT VARCHAR2,
                            pn_retcode IN OUT NUMBER) IS
  
    l_fichier_supervision UTL_FILE.FILE_TYPE; -- SELO EDB265
    l_message_supervision VARCHAR2(2000); -- SELO EDB265
    l_path_ST             VARCHAR2(240) := 'DKA_OUT_ST'; -- SELO EDB265
    g_supervision         VARCHAR2(240);
    p_statut              VARCHAR2(10);
  
    CURSOR c_inv_header IS
      Select INVOICE_ID, INVOICE_NUM
        From DKA_IAPFAC_IVALUA
       order by INVOICE_ID;
  
  BEGIN
  
    -- SELO EDB265 debut
    IF UTL_FILE.IS_OPEN(l_fichier_supervision) THEN
      UTL_FILE.FCLOSE(l_fichier_supervision);
    END IF;
  
    g_supervision := 'DSP01-INV_ST_FIN01_' || to_char(g_request_id) ||
                     '.DAT';
  
    l_fichier_supervision := UTL_FILE.FOPEN(l_path_ST, g_supervision, 'w');
  
    IF pn_retcode != 2 then
      --SHA Correction suite au correctif INC0601593
      p_statut := 'OK';
    ELSE
      p_statut := 'KO';
    END IF;
  
    -- writeout('SELO TEST : Date de derniere execution de l''export : '|| TO_CHAR(g_date,'DD/MM/YYYY HH24:MI:SS'));
  
    SELECT count(distinct(dii.inv_file_name))
      into NB_IMAGE
      FROM fnd_documents          d,
           fnd_attached_documents ad,
           DKA_IAPFAC_IVALUA      dii,
           fnd_lobs               fl
     WHERE d.document_id = ad.document_id
       AND ad.pk1_value = TO_CHAR(dii.invoice_id)
       AND d.file_name = dii.inv_file_name
       AND fl.file_id = d.media_id
       AND dii.po_flip != 'Y'
       AND to_date(ad.ATTRIBUTE1, 'dd/mm/yyyy hh24:mi:ss') =
           ad.last_update_date; --TO_CHAR(g_date,'DD/MM/YYYY HH24:MI:SS');
  
    FOR rec_inv_header IN c_inv_header LOOP
      -- SELO EDB265 debut
      l_message_supervision := 'EVENT_TIMESTAMP=' ||
                               TO_CHAR(g_date, 'YYYY-MM-DD"T"HH24:MI:SS') ||
                               '.000' || G_separateur || 'EVENT_ID=' ||
                               rec_inv_header.invoice_id || '_' ||
                               g_request_id || G_separateur ||
                               'EVENT_NAME=' || G_separateur ||
                               'EVENT_STATUS=INFO' || G_separateur ||
                               'EVENT_MESSAGE=FACTURE ' ||
                               rec_inv_header.invoice_num || G_separateur ||
                               'EVENT_ERRORSTACK=' || G_separateur ||
                               'COMPONENT=' || G_separateur || 'Module=' ||
                               G_separateur || 'NUMERO_FACTURE=' ||
                               rec_inv_header.invoice_num || G_separateur ||
                               'LOGTYPE=ST' || G_separateur ||
                               'STEP_NAME=EXPORT' || G_separateur ||
                               'STEP_STATUS=' || p_statut || G_separateur ||
                               'STEP_ID=EXP_' || g_request_id ||
                               G_separateur || 'ACTIVITY_NAME=FACTURE' ||
                               G_separateur || 'ACTIVITY_STATUS=' ||
                               p_statut || G_separateur || 'ACTIVITY_ID=' ||
                               g_request_id || G_separateur ||
                               'TRAITEMENT_NAME=DKA : Export des donnees Factures vers iValua' ||
                               G_separateur || 'TRAITEMENT_ID=' ||
                               g_request_id || G_separateur ||
                               'TRAITEMENT_STATUS=' || p_statut ||
                               G_separateur ||
                               'PROCESS_NAME=Flux Factures ORACLE vers IVALUA' ||
                               G_separateur || 'PROCESS_ID=FIN01_' ||
                               g_request_id;
    
      --L_line_count := L_line_count + 1;
      UTL_FILE.PUT_LINE(l_fichier_supervision, l_message_supervision);
    
    END LOOP;
  
    l_message_supervision := 'EVENT_TIMESTAMP=' ||
                             TO_CHAR(g_date, 'YYYY-MM-DD"T"HH24:MI:SS') ||
                             '.000' || G_separateur || 'EVENT_ID=BIL_' ||
                             g_request_id || G_separateur || 'EVENT_NAME=' ||
                             G_separateur || 'EVENT_STATUS=INFO' ||
                             G_separateur || 'EVENT_MESSAGE=Nb Factures = ' ||
                             NB_FACTURE || ', Nb Lignes = ' || NB_LIGNE ||
                             ', Nb Blocages = ' || NB_BLOCAGE ||
                             ', Nb Reglements = ' || NB_REGLEMENT ||
                             ', Nb Images = ' || NB_IMAGE || G_separateur ||
                             'EVENT_ERRORSTACK=' || G_separateur ||
                             'COMPONENT=' || G_separateur || 'Module=' ||
                             G_separateur || 'NB_FACTURE=' || NB_FACTURE ||
                             G_separateur || 'NB_LIGNE=' || NB_LIGNE ||
                             G_separateur || 'NB_BLOCAGE=' || NB_BLOCAGE ||
                             G_separateur || 'NB_REGLEMENT=' ||
                             NB_REGLEMENT || G_separateur || 'NB_IMAGE=' ||
                             NB_IMAGE || G_separateur || 'LOGTYPE=ST' ||
                             G_separateur || 'STEP_NAME=BILAN' ||
                             G_separateur || 'STEP_STATUS=' || p_statut ||
                             G_separateur || 'STEP_ID=BIL_' || g_request_id ||
                             G_separateur || 'ACTIVITY_NAME=FACTURE' ||
                             G_separateur || 'ACTIVITY_STATUS=' || p_statut ||
                             G_separateur || 'ACTIVITY_ID=' || g_request_id ||
                             G_separateur ||
                             'TRAITEMENT_NAME=DKA : Export des donnees Factures vers iValua' ||
                             G_separateur || 'TRAITEMENT_ID=' ||
                             g_request_id || G_separateur ||
                             'TRAITEMENT_STATUS=' || p_statut ||
                             G_separateur ||
                             'PROCESS_NAME=Flux Factures ORACLE vers IVALUA' ||
                             G_separateur || 'PROCESS_ID=FIN01_' ||
                             g_request_id;
  
    UTL_FILE.PUT_LINE(l_fichier_supervision, l_message_supervision);
  
    UTL_FILE.fclose(l_fichier_supervision);
  
  END log_supervision;
  /*======================================================================================================*/
  --  Nom           : UPDATE_ATTACH_DOC
  --  Description   :
  --
  --  PARAMETRES    :

  --  DATE          : 02/10/2020
  /*=========================================================================================================*/
  PROCEDURE UPDATE_ATTACH_DOC IS
  
    CURSOR c_attach_doc IS
      SELECT ad.document_id
        FROM fnd_documents          d,
             fnd_attached_documents ad,
             DKA_IAPFAC_IVALUA      dii,
             fnd_lobs               fl
       WHERE d.document_id = ad.document_id
         AND ad.pk1_value = TO_CHAR(dii.invoice_id)
         AND d.file_name = dii.inv_file_name
         AND fl.file_id = d.media_id
         AND dii.po_flip != 'Y'
            -- AND  ad.ATTRIBUTE1 IS NULL  --EDB278-D
         AND ((ad.ATTRIBUTE1 IS NULL) or
             (to_date(ad.ATTRIBUTE1, 'DD/MM/YYYY HH24:MI:SS') <
             ad.last_update_date)) -- EDB278-D
      ;
    v_date_attribute1 VARCHAR2(50) := TO_CHAR(g_date,
                                              'DD/MM/YYYY HH24:MI:SS');
  BEGIN
  
    FOR rec_attach_doc IN c_attach_doc LOOP
    
      UPDATE fnd_attached_documents
         Set attribute1       = v_date_attribute1,
             LAST_UPDATED_BY  = g_user,
             LAST_UPDATE_DATE = v_date_attribute1 -- SYSDATE  -- EDB278-D
       WHERE document_id = rec_attach_doc.document_id;
    
    END LOOP;
  END;
  /*======================================================================================================*/
  --  Nom           : main
  --  Description   : procedure principale du traitement qui enchainera l'ensemble
  --                  des autres procedures.
  --  PARAMETRES    : pv_errbuf           Entree/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: '0=normal', '1=warning', '2=erreur'
  --  DATE          : 15/09/2020
  /*=========================================================================================================*/
  PROCEDURE MAIN(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER) IS
  
    v_etape     VARCHAR2(100);
    l_message   VARCHAR2(500);
    vv_errbuf   VARCHAR2(500);
    vn_retcode  NUMBER;
    v_date_exec DATE;
  
  BEGIN
    entete_de_sortie;
    v_etape := 'Determination de parametre date de derniere mise a jour';
    DKA_TOOLS_PKG.put_log_message(v_etape);
    pn_retcode := 0;
    BEGIN
      SELECT date_value
        INTO v_date_exec
        FROM DKA_PARAMETERS
       WHERE program_code = 'DKA_IAPFAC_IVALUA'
         AND parameter_name = 'DATE_DERNIERE_EXECUTION';
    EXCEPTION
      WHEN OTHERS THEN
        l_message  := 'erreur lors de la recuperation de parametre de derniere mise a jour';
        pn_retcode := 2;
      
    END;
    v_etape := 'Purges tables';
    DKA_TOOLS_PKG.put_log_message(v_etape);
    purge_tables;
  
    v_etape := 'Generation des fichiers';
    DKA_TOOLS_PKG.put_log_message(v_etape);
    generate_files(vv_errbuf, vn_retcode, v_date_exec);
    IF vn_retcode = 2 THEN
      pv_errbuf  := vv_errbuf;
      pn_retcode := vn_retcode;
    END IF;
  
    v_etape := 'Lancement du traitement d''export des images';
    DKA_TOOLS_PKG.put_log_message(v_etape);
    LANCE_EXPORT_IMG(vv_errbuf, vn_retcode);
    IF (vn_retcode = 2 and pn_retcode != 2) THEN
      --SHA Correction suite au correctif INC0601593
      pv_errbuf  := 'Le traitement d''export des images s''est terminé en erreur'; --SHA Correction suite au correctif INC0601593
      pn_retcode := 1; --SHA Correction suite au correctif INC0601593
    END IF;
    -- UPDATE_ATTACH_DOC;   --EDB278-D
  
    Log_supervision(vv_errbuf, pn_retcode); --SHA Correction suite au correctif INC0601593
  
    v_etape := 'Mise a jour de la derniere date d''execution';
    DKA_TOOLS_PKG.put_log_message(v_etape);
    MAJ_DATE_LANCEMENT;
  
    g_date_exec := to_char(v_date_exec, 'DD/MM/YYYY HH24:MI:SS');
  
    v_etape := 'Sortie de traitement';
    DKA_TOOLS_PKG.put_log_message(v_etape);
    sortie_traitement;
  
    IF pn_retcode = 2 THEN
      pv_errbuf := 'ATTENTION : Erreur bloquante : ' || pv_errbuf;
    ELSIF pn_retcode = 1 THEN
      pv_errbuf  := 'ATTENTION : Il y a des cas d''avertissement : ' ||
                    pv_errbuf; --SHA Correction suite au correctif INC0601593
      pn_retcode := 1;
    ELSE
      pv_errbuf  := 'Fin normale du traitement.';
      pn_retcode := 0;
    END IF;
  
    writeout(pv_errbuf);
    fin_de_sortie;
  END;

END DKA_IAPFAC_IVALUA_PKG;

/
SHOW ERRORS
EXIT
