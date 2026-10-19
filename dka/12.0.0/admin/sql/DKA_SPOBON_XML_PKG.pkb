SET VERIFY OFF;
DEFINE package_name = "DKA_SPOBON_XML_PKG";

CREATE OR REPLACE PACKAGE BODY &&package_name
AS
----------------------------------------------------------------------------------------------
-- $$
-- CAP GEMINI 
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SPOBON_XML_PKG.pkb
-- DESCRIPTION       : DKA_SPOBON_XML_PKG package body :
--                     Edition du bon de commande en XML
--- AUTEUR           : Julien Jardez
--- DATE DE CREATION : 26/03/2013
--- DOC. ASSOCIEE    : FINANCES__DGE20130002_Envoi des commandes d'achat par mail au format XML.doc
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--- 16/07/2013 JJA DPE20130064 : Avenant : commande XML
---                Ajout des champs livraisons sur les lignes de commandes
--- 03/01/2014 JJA correction pour les contrats de sous-traitance
--- 29/01/2014 JJA DPE20130099 : ajout de MANUFACTURER_PART_NUM et modification de la gestion des
---                              adresses occasionnelles 
--- 18/03/2014 JJA INC000000512897 : Correction des envois de mails
--- 11/12/2014 JJA INC000000623226 : Correctif et ajout de la zone SpecialHandling
--- 19/05/2016 MEG Migration R12
--- 14/02/2017 OBE Modification - artf2098623
--- 21/02/2017 MEG Modification - artf2098623
--- 14/03/2017 MEG Modification - artf2120388 
--- 31/03/2017 MEG Modification - artf2109672 
--- 19/04/2017 YWA Modification - artf2140678,artf2140586
--- 22/25/2017 YWA artf2140678 
--- 14/02/2018 JJA artf2372328 Correctif requête principale Bon de commande
--- 28/03/2018 CDE INC0189666 : Correction envoi des pièces jointes niveau en-tête DA
--- 27/04/2018 RBE EDB106 
--- 05/06/2018 MEG artf2717390 : INC0221516 - SPE061 - Montant errone pour les commandes SSTR qd multi lignes imputation
--- 29/08/2018 OBE artf3024627 : INC0242822 Données appro à supprimer du mail envoyé au fournisseur
--- 04/11/2018 RBE artf3050473 : INC0266665 - Edition BDC probleme UO
--- 05/12/2019 SEL INC0323746 :  Modification du message d erreur et le statut du programme
--- 24/10/2019 AAM INC0361005 :  Ajout des traces pour capter les org_id et les resp_id 
--- 16/04/2019 SEL INC0410929 :  Envoi par mail BdC pas en erreur alors que Problème SMTP 

--------------------------------------------------------------------------------------------

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES GLOBALES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
gv_order_number          po_headers_all.segment1%TYPE;
gv_supplier_notif_method po_vendor_sites_all.supplier_notif_method%TYPE;
gv_mail_fournisseur      po_vendor_sites_all.email_address%TYPE;
--gn_piece_jointe          NUMBER;

gv_expediteur                VARCHAR2(150);
gv_acheteur                  VARCHAR2(150);
gv_subject                   VARCHAR2(4000);
gv_body                      VARCHAR2(4000);
gv_conn                      VARCHAR2(30);
gv_base_prod                 VARCHAR2(30);
gn_amt                       BINARY_INTEGER := 672 * 3;  /* ensures proper format;  2016 */
BOUNDARY            CONSTANT VARCHAR2(256) := '=_NextPart_DC7E1BB5_1105_4DB3_BAE3_2A6208EB099D';
FIRST_BOUNDARY      CONSTANT VARCHAR2(256) := '--' || BOUNDARY || utl_tcp.CRLF;
LAST_BOUNDARY       CONSTANT VARCHAR2(256) := '--' || BOUNDARY || '--' ||utl_tcp.CRLF;
MULTIPART_MIME_TYPE CONSTANT VARCHAR2(256) := 'multipart/mixed; boundary='||BOUNDARY;
MAX_LINE_WIDTH               PLS_INTEGER := 54;
gv_base                      v$database.name%TYPE;
gv_plat_appro_mail           VARCHAR2(100); --adresse mail de retour pour les adresses mails en anomalie

--TEST
gv_test_exp                  VARCHAR2(150);
gv_test_dest                 VARCHAR2(150);

gv_envoi_mail            VARCHAR2(50);
gv_block_envoi           VARCHAR2(50);
gv_order_type            VARCHAR2(50); -- JJA - 03/01/2014
gv_global_agreement_flag VARCHAR2(50);
gv_pdf_file              fnd_concurrent_requests.outfile_name%TYPE;
gv_xml_file              VARCHAR2(4000);
gv_order_header_note     VARCHAR2(4000);
gv_req_header_note       VARCHAR2(4000);
gv_req_header_file       VARCHAR2(4000);
g_step                   VARCHAR2(500);
gv_directory_path        VARCHAR2(4000);

gn_request_id            NUMBER; -- OBE
gn_org_id                NUMBER; -- RBE artf3050473

--MAIL
TYPE T_ORDER_MAIL IS RECORD
  ( ORG_NAME              VARCHAR2(500),
    ORDER_NUMBER          VARCHAR2(500),
    ORDER_DATE            VARCHAR2(500),
    SOC_NAME              VARCHAR2(500),
    SOC_NUM               VARCHAR2(500),
    DEMANDEUR             VARCHAR2(500),
    DEMANDEUR_MAIL        VARCHAR2(500),
    DEMANDEUR_NUM         VARCHAR2(500),
    ACHETEUR              VARCHAR2(500),
    ACHETEUR_MAIL         VARCHAR2(500),
    ACHETEUR_NUM          VARCHAR2(500),
    BILL_TO               VARCHAR2(500),
    SIRET                 VARCHAR2(500),
    ADRESSE               VARCHAR2(500),
    MONTANT               VARCHAR2(500),
    DEVISE                VARCHAR2(500),
    INTRACOMM             VARCHAR2(500),
    VENDOR_NAME           VARCHAR2(500),
    VENDOR_SITE           VARCHAR2(500)
  );

gr_ORDER_MAIL     T_ORDER_MAIL;

cv_prefixe        CONSTANT VARCHAR2(50) := 'ORDER_';

  -----------------------------------------------------------------
  --  Nom           : LOG_MSG
  --  Description   : procedure d'affichage des messages
  --
  --  PARAMETRES :
  --   p_message      texte a imprimer dans le log
  --
  -----------------------------------------------------------------
  PROCEDURE log_msg(p_message in varchar2) IS
    l_message VARCHAR2(1000);
  BEGIN

    l_message := SUBSTR(p_message, 1, 1000);

    IF (l_message IS NULL) THEN
      l_message := TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS');
    END IF;

    fnd_file.put_line(fnd_file.LOG, l_message);
    --dbms_output.put_line('LOG : '||substr(l_message,1,253));
  END log_msg;

  -----------------------------------------------------------------
  --  Nom           : OUT_MSG
  --  Description   : procedure d'affichage des messages
  --
  --  PARAMETRES :
  --   p_message          texte a imprimer dans la sortie
  --
  -----------------------------------------------------------------
  PROCEDURE out_msg(p_message in varchar2) IS
  BEGIN
    -- Ecriture dans le fichier de sortie
    fnd_file.put_line(fnd_file.output, p_message);
    --dbms_output.put_line(substr(text,1,255));
  END out_msg;

  -----------------------------------------------------------------
  --  Nom           : GET_TIME
  --  Description   : fonction qui retourne la date et l'heure
  --                  actuelle
  --
  --  PARAMETRES :
  --
  -----------------------------------------------------------------
  FUNCTION get_time RETURN VARCHAR2 IS
  BEGIN
    RETURN to_char(sysdate,'DD/MM/YYYY HH24:MI:SS');
  END get_time;
  
  -----------------------------------------------------------------
  --  Nom           : CONVERT_TYPE_MIME
  --  Description   : fonction qui retourne le type mime
  --
  --  PARAMETRES :
  --
  -----------------------------------------------------------------
  FUNCTION convert_type_mime (pv_extension VARCHAR2) return VARCHAR2 IS
  
    vv_type_mime VARCHAR2(50);
    vv_extension VARCHAR2(50);
    
  BEGIN
  
    vv_extension := pv_extension;
  
    CASE 
      WHEN vv_extension = 'dwg'  THEN vv_type_mime := 'application/acad';
      WHEN vv_extension = 'ccad' THEN vv_type_mime := 'application/clariscad';
      WHEN vv_extension = 'drw'  THEN vv_type_mime := 'application/drafting';
      WHEN vv_extension = 'dxf'  THEN vv_type_mime := 'application/dxf';
      WHEN vv_extension = 'unv'  THEN vv_type_mime := 'application/i-deas';
      WHEN vv_extension in ('igs','iges') THEN vv_type_mime := 'application/iges';
      WHEN vv_extension = 'bin' THEN vv_type_mime := 'application/octet-stream';
      WHEN vv_extension = 'oda' THEN vv_type_mime := 'application/oda';
      WHEN vv_extension = 'pdf' THEN vv_type_mime := 'application/pdf';
      WHEN vv_extension in ('ai','eps','ps') THEN vv_type_mime := 'application/postscript';
      WHEN vv_extension = 'prt' THEN vv_type_mime := 'application/pro_eng';
      WHEN vv_extension = 'rtf' THEN vv_type_mime := 'application/rtf';
      WHEN vv_extension = 'set' THEN vv_type_mime := 'application/set';
      WHEN vv_extension = 'stl' THEN vv_type_mime := 'application/sla';
      WHEN vv_extension = 'dwg' THEN vv_type_mime := 'application/solids';
      WHEN vv_extension = 'step' THEN vv_type_mime := 'application/step';
      WHEN vv_extension = 'vda' THEN vv_type_mime := 'application/vda';
      WHEN vv_extension = 'mif' THEN vv_type_mime := 'application/x-mif';
      WHEN vv_extension = 'dwg' THEN vv_type_mime := 'application/x-csh';
      WHEN vv_extension = 'dvi' THEN vv_type_mime := 'application/x-dvi';
      WHEN vv_extension = 'hdf' THEN vv_type_mime := 'application/hdf';
      WHEN vv_extension = 'latex' THEN vv_type_mime := 'application/x-latex';
      WHEN vv_extension in ('nc','cdf') THEN vv_type_mime := 'application/x-netcdf';
      WHEN vv_extension = 'dwg' THEN vv_type_mime := 'application/x-sh';
      WHEN vv_extension = 'tcl' THEN vv_type_mime := 'application/x-tcl';
      WHEN vv_extension = 'tex' THEN vv_type_mime := 'application/x-tex';
      WHEN vv_extension in ('texinfo','texi') THEN vv_type_mime := 'application/x-texinfo';
      WHEN vv_extension in ('t','tr','troff') THEN vv_type_mime := 'application/x-troff';
      WHEN vv_extension = 'man' THEN vv_type_mime := 'application/x-troff-man';
      WHEN vv_extension = 'me' THEN vv_type_mime := 'application/x-troff-me';
      WHEN vv_extension = 'ms' THEN vv_type_mime := 'application/x-troff-ms';
      WHEN vv_extension = 'src' THEN vv_type_mime := 'application/x-wais-source';
      WHEN vv_extension = 'bcpio' THEN vv_type_mime := 'application/x-bcpio';
      WHEN vv_extension = 'cpio' THEN vv_type_mime := 'application/x-cpio';
      WHEN vv_extension = 'gtar' THEN vv_type_mime := 'application/x-gtar';
      WHEN vv_extension = 'shar' THEN vv_type_mime := 'application/x-shar';
      WHEN vv_extension = 'sv4cpio' THEN vv_type_mime := 'application/x-sv4cpio';
      WHEN vv_extension = 'sc4crc' THEN vv_type_mime := 'application/x-sv4crc';
      WHEN vv_extension = 'tar' THEN vv_type_mime := 'application/x-tar';
      WHEN vv_extension = 'man' THEN vv_type_mime := 'application/x-ustar';
      WHEN vv_extension = 'man' THEN vv_type_mime := 'application/zip';
      WHEN vv_extension = 'au,snd' THEN vv_type_mime := 'audio/basic';
      WHEN vv_extension in ('aif','aiff','aifc') THEN vv_type_mime := 'audio/x-aiff';
      WHEN vv_extension = 'wav' THEN vv_type_mime := 'audio/x-wav';
      WHEN vv_extension = 'man' THEN vv_type_mime := 'image/gif';
      WHEN vv_extension = 'ief' THEN vv_type_mime := 'image/ief';
      WHEN vv_extension in ('jpg','jpeg','jpe') THEN vv_type_mime := 'image/jpeg';
      WHEN vv_extension in ('tiff','tif') THEN vv_type_mime := 'image/tiff';
      WHEN vv_extension = 'cmu' THEN vv_type_mime := 'image/x-cmu-raster';
      WHEN vv_extension = 'pnm' THEN vv_type_mime := 'image/x-portable-anymap';
      WHEN vv_extension = 'pbm' THEN vv_type_mime := 'image/x-portable-bitmap';
      WHEN vv_extension = 'pgm' THEN vv_type_mime := 'image/x-portable-graymap';
      WHEN vv_extension = 'ppm' THEN vv_type_mime := 'image/x-portable-pixmap';
      WHEN vv_extension = 'rgb' THEN vv_type_mime := 'image/x-rgb';
      WHEN vv_extension = 'xbm' THEN vv_type_mime := 'image/x-xbitmap';
      WHEN vv_extension = 'xpm' THEN vv_type_mime := 'image/x-xpixmap';
      WHEN vv_extension = 'man' THEN vv_type_mime := 'image/x-xwindowdump';
      WHEN vv_extension = 'zip' THEN vv_type_mime := 'multipart/x-zip';
      WHEN vv_extension in ('gz','gzip') THEN vv_type_mime := 'multipart/x-gzip';
      WHEN vv_extension in ('htm','html') THEN vv_type_mime := 'text/html';
      WHEN vv_extension in ('txt','g','h','c','cc','hh','m','f90') THEN vv_type_mime := 'text/plain';
      WHEN vv_extension = 'rtx' THEN vv_type_mime := 'text/richtext';
      WHEN vv_extension = 'tsv' THEN vv_type_mime := 'text/tab-separated-value';
      WHEN vv_extension = 'etx' THEN vv_type_mime := 'text/x-setext';
      WHEN vv_extension in ('mpeg','mpg','mpe') THEN vv_type_mime := 'video/mpeg';
      WHEN vv_extension in ('qt','mov') THEN vv_type_mime := 'video/quicktime';
      WHEN vv_extension = 'avi' THEN vv_type_mime := 'video/msvideo';
      WHEN vv_extension = 'movie' THEN vv_type_mime := 'video/x-sgi-movie';
      ELSE vv_type_mime := 'text/plain';
     END CASE;
     
     return vv_type_mime;
  
  END convert_type_mime;
  
  -----------------------------------------------------------------
  --  Nom           : GET_ORDER_HEADER_NOTE
  --  Description   : fonction qui retourne les documents joint sur une commande 
  --                  et fournisseur de type TEXT
  --
  --  PARAMETRES :
  --
  -----------------------------------------------------------------
  PROCEDURE get_order_header_note(pn_po_header_id  po_headers_all.po_header_id%TYPE,
                                  pn_vendor_id     po_vendors.vendor_id%TYPE,
                                  pn_req_header_id po_requisition_lines_all.requisition_header_id%TYPE,
                                  pn_note_req_temp  OUT VARCHAR2 )  IS
    
    --YWA artf2140678 
    /*CURSOR c_note(cn_po_header_id po_headers_all.po_header_id%TYPE,
                  cn_vendor_id    po_vendors.vendor_id%TYPE) IS 
     SELECT   fdst.short_text
      FROM     fnd_attached_documents ad,
               fnd_documents d,
               fnd_doc_category_usages dcu,
               fnd_attachment_functions af,
               fnd_documents_tl dt,
               fnd_documents_short_text fdst
      WHERE        fdst.media_id = d.media_id --YWA artf2140678 
               AND d.document_id = ad.document_id
               AND dt.document_id = d.document_id
               AND dt.LANGUAGE = USERENV ('LANG')
               AND dcu.category_id = d.category_id
               AND dcu.attachment_function_id = af.attachment_function_id
               AND dcu.enabled_flag = 'Y'
               AND (   (    ad.entity_name = 'PO_HEADERS'
                        AND ad.pk1_value = TO_CHAR (cn_po_header_id)
                       )
                    OR (    ad.entity_name = 'PO_VENDORS'
                        AND ad.pk1_value = TO_CHAR (cn_vendor_id)
                       )
                   )
               AND af.function_name = 'PO_PRINTPO'
               AND d.datatype_id = 1
      ORDER BY ad.seq_num;*/
      
      
      --YWA artf2140678 
     CURSOR c_req_short(cn_po_header_id po_headers_all.po_header_id%TYPE) IS 
      SELECT   /*+ ordered */
               fdst.short_text
      FROM     fnd_attached_documents ad,
               fnd_documents d,
               fnd_doc_category_usages dcu,
               fnd_attachment_functions af,
               fnd_documents_tl dt,
               fnd_documents_short_text fdst
      WHERE        d.document_id = ad.document_id
               AND dt.document_id = d.document_id
               AND dt.LANGUAGE = USERENV ('LANG')
               AND dcu.category_id = d.category_id
               AND dcu.attachment_function_id = af.attachment_function_id
               AND dcu.enabled_flag = 'Y'
               AND ad.entity_name = 'PO_HEADERS'
               AND ad.pk1_value = TO_CHAR (cn_po_header_id)
               AND af.function_name = 'PO_PRINTPO'
               AND fdst.media_id = d.media_id
               AND d.datatype_id = 1
      ORDER BY ad.seq_num;
      
      
      --YWA artf2140678 
    CURSOR c_req_long(cn_po_header_id po_headers_all.po_header_id%TYPE) IS 
      SELECT   /*+ ordered */
               fdlt.long_text
      FROM     fnd_attached_documents ad,
               fnd_documents d,
               fnd_doc_category_usages dcu,
               fnd_attachment_functions af,
               fnd_documents_tl dt,
               fnd_documents_long_text fdlt
      WHERE        d.document_id = ad.document_id
               AND dt.document_id = d.document_id
               AND dt.LANGUAGE = USERENV ('LANG')
               AND dcu.category_id = d.category_id
               AND dcu.attachment_function_id = af.attachment_function_id
               AND dcu.enabled_flag = 'Y'
               AND ad.entity_name = 'PO_HEADERS'
               AND ad.pk1_value = TO_CHAR (cn_po_header_id)
               AND af.function_name = 'PO_PRINTPO'
               AND fdlt.media_id = d.media_id
               AND d.datatype_id = 2
      ORDER BY ad.seq_num;
  
     note_temp       VARCHAR2 (2000);
     note_req_temp   VARCHAR2 (4000);
     i           NUMBER;
     
     vv_fichier  VARCHAR2(100);
     vf_fichier  utl_file.file_type;
     
  BEGIN
     
     g_step  := 'GET_ORDER_HEADER_NOTE 000 : DEBUT';
     log_msg(g_step);
     
     i := 0;
  
     /*g_step  := 'GET_ORDER_HEADER_NOTE 001 : Récupération des messages';
     log_msg(g_step);
     FOR note IN  c_note(pn_po_header_id,pn_vendor_id) LOOP
        i :=   i + 1;
  
        IF i > 1  THEN
           note_temp := note_temp || CHR (13);
        END IF;
  
        note_temp := note_temp || note.short_text;
     END LOOP;*/--YWA artf2140678 
     
     i := 0;
  
     g_step  := 'GET_ORDER_HEADER_NOTE 002 : Récupération des messages DA SHORT';
     log_msg(g_step);
     FOR note IN  c_req_short(pn_po_header_id) LOOP
        i :=   i + 1;
  
        IF i > 1  THEN
           note_req_temp := note_req_temp || CHR (13);
        END IF;
  
        note_req_temp := note_req_temp || note.short_text;
     END LOOP;
     
     g_step  := 'GET_ORDER_HEADER_NOTE 003 : Récupération des messages DA LONG';
     log_msg(g_step);
     FOR note IN  c_req_long(pn_po_header_id) LOOP
        i :=   i + 1;
  
        IF i > 1  THEN
           note_req_temp := note_req_temp || CHR (13);
        END IF;
  
        note_req_temp := note_req_temp || note.long_text;
     END LOOP;
     pn_note_req_temp := nvl((note_req_temp),' '); ----YWA artf2140678 
         
        
     --CREATION FICHIER A JOINDRE --YWA artf2140678 
     /*IF note_temp IS NOT NULL THEN
       g_step  := 'GET_ORDER_HEADER_NOTE 004 : Création fichier à joindre';
       log_msg(g_step);
       
       vv_fichier := 'NOTE_CDE_'||/*fnd_global.CONC_REQUEST_ID*/--gn_request_id/*OBE*/||to_char(SYSDATE,'YYYYMMDDHH24MISS')||'.txt';
      /* BEGIN
         vf_fichier := utl_file.fopen('DKA_OUT_DIR', vv_fichier, 'W', 32764);
         utl_file.put_line(vf_fichier,note_temp);
         utl_file.fclose(vf_fichier);
       
         gv_order_header_note := gv_directory_path||'/'||vv_fichier;
         
         g_step  := 'GET_ORDER_HEADER_NOTE 005 : Fichier : '||gv_order_header_note;
         log_msg(g_step);
         
       EXCEPTION
        WHEN OTHERS THEN
         g_step  := 'GET_ORDER_HEADER_NOTE 006 : Erreur dans la génération du fichier : '||SQLERRM;
         log_msg(g_step);
         gv_order_header_note := NULL;
       END;
     END IF; */--YWA artf2140678 
     
     --CREATION FICHIER A JOINDRE
     IF note_req_temp IS NOT NULL THEN
       g_step  := 'GET_ORDER_HEADER_NOTE 007 : Création fichier à joindre';
       log_msg(g_step);
       
       vv_fichier := 'NOTE_DA_'||/*fnd_global.CONC_REQUEST_ID*/gn_request_id/*OBE*/||to_char(SYSDATE,'YYYYMMDDHH24MISS')||'.txt';
       BEGIN
         vf_fichier := utl_file.fopen('DKA_OUT_DIR', vv_fichier, 'W', 32764);
         utl_file.put_line(vf_fichier,note_req_temp);
         utl_file.fclose(vf_fichier);
       
         gv_req_header_note := gv_directory_path||'/'||vv_fichier;
         
         g_step  := 'GET_ORDER_HEADER_NOTE 008 : Fichier : '||gv_req_header_note;
         log_msg(g_step);
         
       EXCEPTION
        WHEN OTHERS THEN
         g_step  := 'GET_ORDER_HEADER_NOTE 009 : Erreur dans la génération du fichier : '||SQLERRM;
         log_msg(g_step);
         gv_req_header_note := NULL;
       END;
     END IF; 
     
     g_step  := 'GET_ORDER_HEADER_NOTE 999 : FIN';
     log_msg(g_step);
     
  END get_order_header_note;
  
  -----------------------------------------------------------------
  --  Nom           : GET_REQ_FILE
  --  Description   : fonction qui retourne le 1er document joint la 
  --                  DA à l'origine de la commande
  --
  --  PARAMETRES :
  --
  -----------------------------------------------------------------
  PROCEDURE get_req_file(pn_req_header_id po_requisition_lines_all.requisition_header_id%TYPE,
                         p_errbuf        OUT VARCHAR2,
                         p_retcode       OUT NUMBER)  IS
    
     
     l_FILE_NAME  VARCHAR2(500);
     l_blob       BLOB;
     vn_media_id  fnd_documents_tl.media_id%TYPE;
    
  BEGIN
     
    g_step  := 'GET_REQ_FILE 000 : DEBUT';
    log_msg(g_step);
     
    g_step  := 'GET_REQ_FILE 001 : INIT';
    log_msg(g_step);
    l_blob := NULL;
    l_FILE_NAME := NULL;
    
    g_step  := 'GET_REQ_FILE 002 : Sélection du fichier joint / REQ_ID : '||pn_req_header_id;
    log_msg(g_step);
    SELECT   /*+ ordered */
               d.media_id
      INTO     vn_media_id               
      FROM     fnd_attached_documents ad,
               fnd_documents d,
               fnd_doc_category_usages dcu,
               fnd_attachment_functions af,
               fnd_documents_tl dt
      WHERE        d.document_id = ad.document_id
               AND dt.document_id = d.document_id
               AND dt.LANGUAGE = USERENV ('LANG')
               AND dcu.category_id = d.category_id
               AND dcu.attachment_function_id = af.attachment_function_id
               AND dcu.enabled_flag = 'Y'
               AND ad.entity_name = 'REQ_HEADERS'
               AND ad.pk1_value = TO_CHAR (pn_req_header_id)
               AND af.function_name = 'PO_PRINTPO'
               AND d.datatype_id NOT IN (1,2)
               AND ROWNUM = 1 --on prend uniquement le premier
      ORDER BY ad.seq_num;
    
    g_step  := 'GET_REQ_FILE 003 : Sélection des data du fichier joint et du nom /MEDIA_ID : '||vn_media_id;
    log_msg(g_step);
    SELECT file_data,
     substr(FILE_NAME,
     instr(FILE_NAME,'/',-1)+1 )
    INTO   l_blob,l_FILE_NAME
    FROM   fnd_lobs f
    WHERE  f.file_id = vn_media_id;
    
    g_step  := 'GET_REQ_FILE 004 : Définition du fichier à joindre';
    log_msg(g_step);
    gv_req_header_file := gv_directory_path||'/'||l_FILE_NAME;
    log_msg(gv_req_header_file);
    
    g_step  := 'GET_REQ_FILE 005 : Exécution de la procédure JAVA';
    log_msg(g_step);
    Dka_ExportBlob(gv_req_header_file,l_blob);
    
    g_step  := 'GET_REQ_FILE 999 : FIN';
    log_msg(g_step);
     
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     g_step  := 'Pas de pièce jointe à traiter';                 
     log_msg(g_step);
    WHEN OTHERS THEN
	 	-- SEL INC0323746 : Rendre le message d erreur lisible
      /*g_step  := 'Erreur procedure GET_REQ_FILE : Erreur dans la génération du fichier : '||
                 g_step ||chr(10)||SQLERRM;  */    
      g_step  := 'Problème d''envoi du devis, merci de contacter la plateforme d''approvisionnement pour ré-éditer la commande';

       -- SEL FIN	  
     log_msg(g_step);
     gv_req_header_file := NULL;  
	 
	 p_errbuf  := g_step;
     p_retcode := 2;
	 
  END get_req_file;
  
  -----------------------------------------------------------------
  --  Nom           : GET_ORDER_LINE_NOTE
  --  Description   : fonction qui retourne les documents joint sur une ligne de
  --                  commande de type TEXT
  --
  --  PARAMETRES :
  --
  -----------------------------------------------------------------
  FUNCTION get_order_line_note(pn_po_line_id       po_lines_all.po_line_id%TYPE) RETURN VARCHAR2 IS

    CURSOR c_note(cn_po_line_id po_lines_all.po_line_id%TYPE) IS
     SELECT    fdst.short_text
      FROM     fnd_attached_documents ad,
               fnd_documents d,
               fnd_doc_category_usages dcu,
               fnd_attachment_functions af,
               fnd_documents_tl dt,
               fnd_documents_short_text fdst
      WHERE    fdst.media_id = d.media_id --YWA artf2140678
               AND d.document_id = ad.document_id
               AND dt.document_id = d.document_id
               AND dt.LANGUAGE = USERENV ('LANG')
               AND dcu.category_id = d.category_id
               AND dcu.attachment_function_id = af.attachment_function_id
               AND dcu.enabled_flag = 'Y'
               AND ad.entity_name = 'PO_LINES'
               AND ad.pk1_value = TO_CHAR (cn_po_line_id)
               AND af.function_name = 'PO_PRINTPO'
               AND d.datatype_id = 1
      ORDER BY ad.seq_num;
      
      CURSOR c_note_l(cn_po_line_id po_lines_all.po_line_id%TYPE) IS
      
      SELECT    fdlt.long_text
      FROM     fnd_attached_documents ad,
               fnd_documents d,
               fnd_doc_category_usages dcu,
               fnd_attachment_functions af,
               fnd_documents_tl dt,
               fnd_documents_long_text fdlt
      WHERE    fdlt.media_id = d.media_id --YWA artf2140678
               AND d.document_id = ad.document_id
               AND dt.document_id = d.document_id
               AND dt.LANGUAGE = USERENV ('LANG')
               AND dcu.category_id = d.category_id
               AND dcu.attachment_function_id = af.attachment_function_id
               AND dcu.enabled_flag = 'Y'
               AND ad.entity_name = 'PO_LINES'
               AND ad.pk1_value = TO_CHAR (cn_po_line_id)
               AND af.function_name = 'PO_PRINTPO'
               AND d.datatype_id = 2
      ORDER BY ad.seq_num;
      
    
     note_temp                    VARCHAR2 (2000);
     short_note                   VARCHAR2(2000);
     long_note                    LONG;
     i                            NUMBER;

  BEGIN
     i := 0;

     --NOTE SHORT
     FOR note IN  c_note(pn_po_line_id) LOOP
        i :=   i + 1;

        IF i > 1  THEN
           note_temp := note_temp || CHR (13);
        END IF;

        note_temp := note_temp || note.short_text;
     END LOOP;
     
    --NOTE LONG
    FOR note IN  c_note_l(pn_po_line_id) LOOP
        i :=   i + 1;

        IF i > 1  THEN
           note_temp := note_temp || CHR (13);
        END IF;

        note_temp := note_temp || note.long_text;
     END LOOP;
     
     
     RETURN nvl((note_temp),' ');
     
  END get_order_line_note;
  
  -----------------------------------------------------------------
  --  Nom           : GET_ORDER_LINE_SHIPMENT
  --  Description   : fonction qui retourne l'adresse occasionnelle
  --
  --  PARAMETRES :
  --
  -----------------------------------------------------------------
  FUNCTION get_order_line_shipment(pn_line_location_id po_line_locations.line_location_id%TYPE) RETURN VARCHAR2 IS

     CURSOR c_shipment (cn_line_location_id po_line_locations.line_location_id%TYPE) IS
      SELECT   /*+ ordered */
               d.datatype_id shipment_note_datatype_id,
               d.media_id shipment_note_media_id --YWA  artf2140678
      FROM     fnd_attached_documents ad,
               fnd_documents d,
               fnd_doc_category_usages dcu,
               fnd_attachment_functions af,
               fnd_documents_tl dt
      WHERE        d.document_id = ad.document_id
               AND dt.document_id = d.document_id
               AND dt.LANGUAGE = USERENV ('LANG')
               AND dcu.category_id = d.category_id
               AND dcu.attachment_function_id = af.attachment_function_id
               AND dcu.enabled_flag = 'Y'
               AND ad.entity_name = 'PO_SHIPMENTS' 
               AND ad.pk1_value = TO_CHAR (cn_line_location_id)
               AND af.function_name = 'PO_PRINTPO'
      ORDER BY ad.seq_num;

     note_temp                    VARCHAR2 (2000);
     vv_shipment_note_datatype_id fnd_documents.datatype_id%TYPE;
     vv_shipment_note_media_id    fnd_documents_tl.media_id%TYPE;
     short_note                   VARCHAR2(2000);
     long_note                    LONG;
     i                            NUMBER;

  BEGIN
     i := 0;

     --NOTE LIVRAISON
     OPEN c_shipment (pn_line_location_id);
     FETCH c_shipment INTO vv_shipment_note_datatype_id,vv_shipment_note_media_id;
     
     IF c_shipment%FOUND THEN
          
      IF vv_shipment_note_datatype_id = 1 then
        SELECT short_text
          INTO short_note
          FROM fnd_documents_short_text
         WHERE media_id = vv_shipment_note_media_id;
                
        note_temp := short_note; 
  
      ELSIF vv_shipment_note_datatype_id = 2 then
      
        SELECT long_text
          INTO long_note
          FROM fnd_documents_long_text
         WHERE media_id = vv_shipment_note_media_id;
         
        note_temp := '' || long_note; 
        
      ELSE
       --Attachment is not a Text format
       NULL;
      END IF;
      
     ELSE      
      --PAS DE NOTE
      NULL;
     END IF;
     
     CLOSE c_shipment;

     RETURN nvl((note_temp),' ');
     
  END get_order_line_shipment;

  ----------------------------------------------------------------------------
  --  Nom           : write_boundary
  --  Description   : Procédure
  --
  --  PARAMETRES :
  ----------------------------------------------------------------------------
    PROCEDURE write_boundary(conn IN OUT NOCOPY utl_smtp.connection,
                             last IN BOOLEAN DEFAULT FALSE) IS
    BEGIN
       IF (last) THEN
          utl_smtp.write_data(conn, LAST_BOUNDARY);
       ELSE
          utl_smtp.write_data(conn, FIRST_BOUNDARY);
       END IF;
    END write_boundary;

  ----------------------------------------------------------------------------
  --  Nom           : begin_attachment
  --  Description   : Procédure
  --
  --  PARAMETRES :
  ----------------------------------------------------------------------------
  PROCEDURE begin_attachment(conn         IN OUT NOCOPY utl_smtp.connection,
                               mime_type    IN VARCHAR2 DEFAULT 'text/plain',
                               inline       IN BOOLEAN DEFAULT TRUE,
                               filename     IN VARCHAR2 DEFAULT NULL,
                               transfer_enc IN VARCHAR2 DEFAULT NULL) IS
  BEGIN
      write_boundary(conn);
      utl_smtp.write_raw_data(conn, utl_raw.cast_to_raw('Content-Type: ' || mime_type || utl_tcp.CRLF));
      IF (filename IS NOT NULL) THEN
          IF (inline) THEN
             utl_smtp.write_raw_data(conn, utl_raw.cast_to_raw('Content-Disposition: ' || 'inline; filename="'||filename||'"' || utl_tcp.CRLF));
          ELSE
             utl_smtp.write_raw_data(conn, utl_raw.cast_to_raw('Content-Disposition: ' || 'attachment; filename="'||filename||'"' || utl_tcp.CRLF));
          END IF;
      END IF;
      IF (transfer_enc IS NOT NULL) THEN
          utl_smtp.write_raw_data(conn, utl_raw.cast_to_raw('Content-Transfer-Encoding: ' || transfer_enc || utl_tcp.CRLF));
      END IF;
      utl_smtp.write_data(conn, utl_tcp.CRLF);
  END begin_attachment;

  ----------------------------------------------------------------------------
  --  Nom           : end_attachment
  --  Description   : Procédure
  --
  --  PARAMETRES :
  ----------------------------------------------------------------------------
  PROCEDURE end_attachment(conn IN OUT NOCOPY utl_smtp.connection,
                            last IN BOOLEAN DEFAULT FALSE) IS
  BEGIN
       utl_smtp.write_data(conn, utl_tcp.CRLF || utl_tcp.CRLF);
     IF (last) THEN
        write_boundary(conn, last);
     END IF;
  END end_attachment;
  
  -----------------------------------------------------------------
  --  Nom           : INIT
  --  Description   : procedure d'initialisation
  --
  --  PARAMETRES :
  --
  --
  -----------------------------------------------------------------
  PROCEDURE init(p_errbuf        OUT VARCHAR2,
                 p_retcode       OUT NUMBER,
                 p_order_number  IN  VARCHAR2,
                 p_envoi_mail    IN  VARCHAR2) IS
                 
    rec_param         dka_parameters%ROWTYPE;
    e_expediteur_vide EXCEPTION;
    e_plat_appro_vide EXCEPTION;
    --< OBE
    --vv_responsibility_ref      	 fnd_responsibility.responsibility_key%TYPE := 'TOUT_PO_ADMINISTRATEUR';
    vn_responsibility_id             NUMBER (15);
    vn_application_id                NUMBER (15);
    --> OBE
    vn_organisation                  hr_operating_units.name%TYPE; --AAM INC0361005 Ajout des traces
  BEGIN
    --Init des variables de sortie
    p_retcode := 0;
    p_errbuf  := '';
    
    --< OBE
    gn_request_id := FND_GLOBAL.CONC_REQUEST_ID;
    
    --RBE artf3050473
	--DEBUT AAM INC0361005 :  Ajout des traces pour capter les org_id et les resp_id 
        --gn_org_id := FND_GLOBAL.org_id; AAM INC0361005
	    BEGIN
            log_msg('Extraction du Org_id');
            SELECT 
             fcr_t_trt.org_id
            INTO 
             gn_org_id 
            FROM
             fnd_concurrent_requests    fcr,
             fnd_concurrent_requests    fcr_phase,   --PHASE
             fnd_concurrent_requests    fcr_main,    --MAIN
             fnd_concurrent_requests    fcr_t_phase, --TOUTE_PHASE
             fnd_concurrent_requests    fcr_t_trt,   --TOUT_TRT
             fnd_concurrent_programs_vl fcp
            WHERE
                 fcr.request_id                = gn_request_id--FND_GLOBAL.CONC_REQUEST_ID -- OBE
             AND fcr_phase.request_id          = fcr.parent_request_id
             AND fcr_main.request_id           = fcr_phase.parent_request_id
             AND fcr_t_phase.parent_request_id = fcr_main.request_id
             AND fcr_t_trt.parent_request_id   = fcr_t_phase.request_id
             AND fcp.CONCURRENT_PROGRAM_NAME   = 'DKA_SPOBON_PDF'
             AND fcp.CONCURRENT_PROGRAM_ID     = fcr_t_trt.concurrent_program_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
            gn_org_id := FND_GLOBAL.org_id;
        END;
        log_msg('La valeur du Org_id est : '||gn_org_id);
/*
      SELECT fr.responsibility_id,
             fr.application_id
      INTO   vn_responsibility_id,
             vn_application_id
      FROM   fnd_responsibility fr
      WHERE  fr.responsibility_key = vv_responsibility_ref;
*/ 
      BEGIN
	        log_msg('Extraction du nom de l''organisation');
            SELECT hou.name
			INTO   vn_organisation
			FROM   hr_operating_units hou
			WHERE  hou.organization_id = gn_org_id;
        END;
		log_msg('Le nom de l''organisation est : '||vn_organisation);
		
    	BEGIN
		    log_msg('Extraction de l''identifiant responsabilité');
            SELECT  fresp.responsibility_id, 
                    fresp.application_id 
            INTO    vn_responsibility_id,
                    vn_application_id
            FROM   fnd_responsibility_tl fresp 
            WHERE  1=1
            AND    fresp.responsibility_name like vn_organisation||'_PO_ADMINISTRATEUR'
            AND    fresp.language='F';
		END;
		log_msg('l''identifiant responsabilité est : '||vn_responsibility_id);
		
      DBMS_OUTPUT.put_line ('Initialisation dans le contexte OA');
      fnd_global.apps_initialize (fnd_global.user_id, vn_responsibility_id, vn_application_id);   --AAM INC0361005  enlever le commentaire
      MO_GLOBAL.INIT('PO');
    --> OBE
    --FIN AAM INC0361005 :  Ajout des traces pour capter les org_id et les resp_id 
	
    g_step  := 'INIT 000 : DEBUT';
    log_msg(g_step);
    
    g_step  := 'INIT 001 : Initialisation des paramétres';
    log_msg(g_step);
    
    gv_order_number := p_order_number;
    gv_envoi_mail   := p_envoi_mail;
    
    log_msg('Arguments'||chr(10)||'---------');
    log_msg('Numéro de commande : '||nvl(gv_order_number,'<PAS DE N° CDE>'));
    log_msg('Envoi de mail      : '||nvl(gv_envoi_mail,'<PAS D''ENVOI DE MAIL>'));
    log_msg('---------');
    
    IF gv_order_number IS NULL THEN
      g_step  := 'INIT 002 : Recherche du numéro de commande';
      log_msg(g_step);
      
      BEGIN
        log_msg('Request id is : '||gn_request_id);
        SELECT 
         fcr_t_trt.argument3,
         fcr_t_trt.outfile_name --,
        -- fcr_t_trt.org_id --AAM INC0361005 :  Ajout des traces pour capter les org_id et les resp_id 
        INTO 
         gv_order_number,
         gv_pdf_file --,
        -- gn_org_id --RBE artf3050473 --AAM INC0361005 :  Ajout des traces pour capter les org_id et les resp_id 
        FROM
         fnd_concurrent_requests    fcr,
         fnd_concurrent_requests    fcr_phase,   --PHASE
         fnd_concurrent_requests    fcr_main,    --MAIN
         fnd_concurrent_requests    fcr_t_phase, --TOUTE_PHASE
         fnd_concurrent_requests    fcr_t_trt,   --TOUT_TRT
         fnd_concurrent_programs_vl fcp
        WHERE
             fcr.request_id                = gn_request_id--FND_GLOBAL.CONC_REQUEST_ID -- OBE
         AND fcr_phase.request_id          = fcr.parent_request_id
         AND fcr_main.request_id           = fcr_phase.parent_request_id
         AND fcr_t_phase.parent_request_id = fcr_main.request_id
         AND fcr_t_trt.parent_request_id   = fcr_t_phase.request_id
         AND fcp.CONCURRENT_PROGRAM_NAME   = 'DKA_SPOBON_PDF'
         AND fcp.CONCURRENT_PROGRAM_ID     = fcr_t_trt.concurrent_program_id;
      EXCEPTION
       WHEN NO_DATA_FOUND THEN
        p_errbuf  := 'Aucun numéro de commande trouvé';
        log_msg(p_errbuf);
        p_retcode := 2;
      END;
      
      g_step  := 'INIT 002 : numéro de commande à traiter : '||gv_order_number;
      log_msg(g_step);
    
    END IF;
    
    g_step  := 'INIT 003 : Recherche du chemin OUT';
    log_msg(g_step);
    SELECT ad.directory_path
    INTO gv_directory_path
    FROM all_directories ad
    WHERE ad.directory_name = 'DKA_OUT_DIR';
    
    g_step  := 'INIT 003 : '||gv_directory_path;
    log_msg(g_step);
    
    g_step  := 'INIT 004 : Recherche de la méthode de notification du fournisseur';
    log_msg(g_step);
	g_step  := 'INIT 004 : Org_id est :'||gn_org_id; --AAM INC0361005 :  Ajout des traces
    log_msg(g_step);                                 --AAM INC0361005 :  Ajout des traces
    BEGIN
        SELECT 
          nvl(pvs.supplier_notif_method,'<VIDE>'),
          pvs.email_address,
          ph.attribute6,
          ph.TYPE_LOOKUP_CODE, -- JJA - 03/01/2014
          NVL(ph.GLOBAL_AGREEMENT_FLAG,'N')
        INTO 
          gv_supplier_notif_method,
          gv_mail_fournisseur,
          gv_block_envoi,
          gv_order_type, -- JJA - 03/01/2014
          gv_global_agreement_flag
        FROM
         po_headers ph,
         po_vendor_sites pvs
        WHERE
         ph.segment1 = gv_order_number
         AND ph.vendor_site_id = pvs.vendor_site_id
         AND ph.org_id = gn_org_id --RBE artf3050473
        ;
		-- debut AAM INC0361005 :  Ajout des traces -ajout de l'exception
    EXCEPTION
	    WHEN NO_DATA_FOUND THEN
		g_step  := 'INIT 004 : La requête ne ramène aucune donnée en utilisant le paramètre org_id  '||gn_org_id||' et le numéro commande '||gv_order_number;
        log_msg(g_step);
	END;
	   -- fin AAM INC0361005 :  Ajout des traces
    g_step  := 'INIT 004 : supplier_notif_method : '||gv_supplier_notif_method;
    log_msg(g_step);
    g_step  := 'INIT 004 : mail_fournisseur      : '||gv_mail_fournisseur;
    log_msg(g_step);
    g_step  := 'INIT 004 : block_envoi           : '||gv_block_envoi;
    log_msg(g_step);
    
    g_step  := 'INIT 005 : Recherche de l''expéditeur du mail';
    log_msg(g_step);
    Dka_Tools_Pkg.get_parameter ('SPOBON_MAIL', 'EXPEDITEUR_MAIL', rec_param, p_errbuf, p_retcode);
    gv_expediteur := rec_param.varchar2_value;
    g_step  := 'INIT 005 : '||gv_expediteur;
    log_msg(g_step);
    
    IF gv_expediteur IS NULL THEN
     RAISE e_expediteur_vide;
    END IF;
    
    g_step  := 'INIT 005b : Recherche du mail de la plateforme d''approvisionnement';
    log_msg(g_step);
    Dka_Tools_Pkg.get_parameter ('SPOBON_MAIL', 'MAIL_PLATEFORME', rec_param, p_errbuf, p_retcode);
    gv_plat_appro_mail := rec_param.varchar2_value;
    g_step  := 'INIT 005b : '||gv_plat_appro_mail;
    log_msg(g_step);
    
    IF gv_plat_appro_mail IS NULL THEN
     RAISE e_plat_appro_vide;
    END IF;
    
    g_step  := 'INIT 006 : Récupération du nom de la base de données concernée';
    log_msg(g_step);
    SELECT name
    INTO gv_base
    FROM v$database;
    g_step  := 'INIT 006 : '||gv_base;
    log_msg(g_step);
    
    g_step  := 'INIT 007 : Récuperation des paramètres de connexion';
    log_msg(g_step);
    Dka_Tools_Pkg.get_parameter ('SPOBON_MAIL', 'SMTP_CONNECTION', rec_param, p_errbuf, p_retcode);
    gv_conn := rec_param.varchar2_value;
    g_step  := 'INIT 007 : '||gv_conn;
    log_msg(g_step);
    
    g_step  := 'INIT 008 : Récuperation du nom de la base de production';
    log_msg(g_step);
    Dka_Tools_Pkg.get_parameter ('TOOLS', 'BASE_PRODUCTION', rec_param, p_errbuf, p_retcode);
    gv_base_prod := rec_param.varchar2_value;
    g_step  := 'INIT 008 : '||gv_base_prod;
    log_msg(g_step);
    
    /*
    g_step  := 'INIT 008 : Récuperation des pièces jointes DA';
    log_msg(g_step);
    Dka_Tools_Pkg.get_parameter ('SPOBON_MAIL', 'DOC_FOURNISSEUR_'||fnd_profile.value('ORG_ID'), rec_param, p_errbuf, p_retcode);
    gn_piece_jointe := rec_param.number_value;
    g_step  := 'INIT 008 : '||gn_piece_jointe;
    log_msg(g_step);
    */
    
    IF gv_base != gv_base_prod THEN
      --BASE DE DEVELOPPEMENT
      g_step  := 'INIT 009 : TEST Récuperation des paramètres Expéditeur TEST';
      log_msg(g_step);
      Dka_Tools_Pkg.get_parameter ('SPOBON_MAIL', 'TEST_EXP_MAIL', rec_param, p_errbuf, p_retcode);
      gv_test_exp := rec_param.varchar2_value;
      g_step  := 'INIT 009 : '||gv_test_exp;
      log_msg(g_step);
      
      g_step  := 'INIT 010 : TEST Récuperation des paramètres Destinataire TEST';
      log_msg(g_step);
      Dka_Tools_Pkg.get_parameter ('SPOBON_MAIL', 'TEST_DEST_MAIL', rec_param, p_errbuf, p_retcode);
      gv_test_dest := rec_param.varchar2_value;
      g_step  := 'INIT 010 : '||gv_test_dest;
      log_msg(g_step);
    END IF;
    
    --Reinit des variables de sortie
    p_retcode := 0;
    p_errbuf  := '';
    
    g_step  := 'INIT 999 : FIN';
    log_msg(g_step);
    
  EXCEPTION
   WHEN e_expediteur_vide THEN
    p_errbuf  := 'Aucun expéditeur trouvé';
    log_msg(p_errbuf);
    p_retcode := 2;
   WHEN e_plat_appro_vide THEN
    p_errbuf  := 'Aucun mail de la plateforme d''approvisionnement trouvé';
    log_msg(p_errbuf);
    p_retcode := 2;
   WHEN OTHERS THEN
    p_errbuf  := 'Erreur procedure INIT :'|| 
                 g_step ||chr(10)||SQLERRM;
    log_msg(p_errbuf);
    p_retcode := 2;
  END init;
  
   
  -----------------------------------------------------------------
  --  Nom           : MAJ_ORDER
  --  Description   : procedure d'initialisation
  --
  --  PARAMETRES :
  --
  --
  -----------------------------------------------------------------
  PROCEDURE maj_order(p_errbuf        OUT VARCHAR2,
                      p_retcode       OUT NUMBER) IS
                 
   vn_revision_num po_headers_all.revision_num%TYPE;
   
  BEGIN
    --Init des variables de sortie
    p_retcode := 0;
    p_errbuf  := '';
  
    g_step  := 'MAJ_ORDER 000 : DEBUT';
    log_msg(g_step);  
    
    g_step  := 'MAJ_ORDER 001 : Sélection du numéro de révision';  
    log_msg(g_step);  
    
    SELECT revision_num
    INTO vn_revision_num
    FROM po_headers ph
    WHERE segment1 = gv_order_number
      AND ph.org_id = gn_org_id; --RBE artf3050473
    
    g_step  := 'MAJ_ORDER 001 : '||vn_revision_num;
    log_msg(g_step);
    
    g_step  := 'MAJ_ORDER 002 : Mise à jour de la table d''archive';  
    log_msg(g_step);
    UPDATE PO_HEADERS_ARCHIVE pha
    SET attribute12 = gv_mail_fournisseur
    WHERE segment1 = gv_order_number
     AND revision_num = vn_revision_num
     AND pha.org_id = gn_org_id; --RBE artf3050473
    
    g_step  := 'MAJ_ORDER 002 : Commande mis à jour : '||SQL%ROWCOUNT;  
    log_msg(g_step);
    
    g_step  := 'MAJ_ORDER 999 : FIN';
    log_msg(g_step);
    
  EXCEPTION
   WHEN OTHERS THEN
    p_errbuf  := 'Erreur procedure MAJ_ORDER :'||
                 g_step ||chr(10)||SQLERRM;
    log_msg(p_errbuf);
    p_retcode := 2;
  END maj_order;
  
  -----------------------------------------------------------------
  --  Nom           : CONSTRUCTION_XML
  --  Description   : procedure de contruction du fichier XML
  --
  --  PARAMETRES :
  --
  --
  -----------------------------------------------------------------
  PROCEDURE construction_xml(p_errbuf        OUT VARCHAR2,
                             p_retcode       OUT NUMBER) IS
   
    CURSOR c_select(cv_n_cde VARCHAR2) IS
      SELECT 
        php.po_type,
        php.po_header_id,
        prla.requisition_header_id,
        pol.po_line_id,
        pll.LINE_LOCATION_ID,
        pod.po_distribution_id,
        php.vendor_id,
        php.vendor_site_id,
        php.po_num || DECODE (php.revision_num, '0', NULL,    '-V' || TO_CHAR (php.revision_num)) BuyerOrderNumber,
        to_char(php.last_update_date,'dd/mm/yyyy')                                                OrderIssueDate,
        nvl(to_char(DECODE(DKA_SPOBON_PKG.nb_promised_date (php.po_header_id),
                           1, NVL (polla.promised_date, polla.need_by_date),
                           NULL),'dd/mm/yyyy'),' ')                                               RequestedDeliverByDate,
/*        nvl((SELECT ffvv.DESCRIPTION
              FROM fnd_flex_value_sets ffvs,
              fnd_flex_values_vl ffvv
              WHERE
               ffvs.flex_value_set_id = ffvv.FLEX_VALUE_SET_ID
               AND ffvs.flex_value_set_name = 'DAOPCCF_CENTRE'
               AND ffvv.FLEX_VALUE = hrla.attribute1),' ')                                        BuyerPartyAgencyCoded,*/
        nvl((SELECT ffvv.DESCRIPTION
               FROM fnd_flex_value_sets       ffvs,
                    fnd_flex_values_vl        ffvv,
                    Per_Assignments_f         paf,
                    hr_all_organization_units haou
              WHERE ffvs.flex_value_set_id = ffvv.FLEX_VALUE_SET_ID
                AND ffvs.flex_value_set_name = 'DAOPCCF_CENTREFI'
                AND paf.person_id = pap_dde.person_id
                AND haou.organization_id = paf.organization_id
                AND sysdate BETWEEN NVL(paf.effective_start_date,sysdate) AND NVL(paf.effective_end_date,sysdate)
                AND ffvv.FLEX_VALUE = to_char(haou.name)),' ')                                    BuyerPartyAgencyCoded,
        nvl(haou.name,' ')                                                                        BuyerPartyIdent,
        nvl(pap_ope.last_name || ' ' || pap_ope.first_name,' ')                                   BuyerPartyAch_name,
        nvl(pap_ope.work_telephone,nvl((SELECT phone_number
                                        FROM per_phones pp
                                        WHERE parent_id = pap_ope.person_id
                                         AND parent_table = 'PER_ALL_PEOPLE_F'
                                         AND SYSDATE BETWEEN NVL(pp.date_from,SYSDATE)
                                                         AND NVL(pp.date_to,SYSDATE)
                                       ),' '))                                                    BuyerPartyAch_tel,
        nvl(pap_ope.attribute5,' ')                                                               BuyerPartyAch_fax,
        nvl(pap_ope.attribute4,' ')                                                               BuyerPartyAch_mob,
        nvl(php.document_buyer_last_name || ' ' || php.document_buyer_first_name,' ')             BuyerPartyDde_name,
        nvl(php.document_buyer_phone_number,' ')                                                  BuyerPartyDde_tel,
        nvl(php.document_buyer_attribute5,' ')                                                    BuyerPartyDde_fax,
        nvl(php.document_buyer_attribute4,' ')                                                    BuyerPartyDde_mob,
      --nvl(document_buyer_attribute1,' ')                                                        BuyerPartyDde_appartenance,
        nvl((SELECT haou.name
               FROM Per_Assignments_f         paf,
                    hr_all_organization_units haou
              WHERE paf.person_id = pap_dde.person_id
                AND haou.organization_id = paf.organization_id
                AND sysdate BETWEEN NVL(paf.effective_start_date, sysdate) AND NVL(paf.effective_end_date, sysdate)
                ),' ')                                                                            BuyerPartyDde_appartenance,
        nvl(php.vendor_name,' ')                                                                  SellerParty_name,
        nvl(php.vendor_address_line1,' ')                                                         SellerParty_line1,
        nvl(php.vendor_address_line2,' ')                                                         SellerParty_line2,
        nvl(php.vendor_address_line3,' ')                                                         SellerParty_line3,
        nvl(php.vendor_postal_code,' ')                                                           SellerParty_zip,
        nvl(php.vendor_city,' ')                                                                  SellerParty_city,
        nvl(php.vendor_phone,' ')                                                                 SellerParty_phone,
        nvl(php.vendor_fax,' ')                                                                   SellerParty_fax,
        DECODE(DKA_SPOBON_PKG.nb_ship_to_location_id (php.po_header_id), 1, nvl(hrla.description,' '), ' ')    ShipTo_name,
        DECODE(DKA_SPOBON_PKG.nb_ship_to_location_id (php.po_header_id), 1, nvl(hrla.address_line_1,' '), ' ') ShipTo_line1,
        DECODE(DKA_SPOBON_PKG.nb_ship_to_location_id (php.po_header_id), 1, nvl(hrla.address_line_2,' '), 'Voir ci-dessous le détail des lignes de commande.') ShipTo_line2,
        DECODE(DKA_SPOBON_PKG.nb_ship_to_location_id (php.po_header_id), 1, nvl(hrla.address_line_3,' '), ' ') ShipTo_line3,
        DECODE(DKA_SPOBON_PKG.nb_ship_to_location_id (php.po_header_id),
               1, hrla.postal_code || ' ' || hrla.town_or_city,
               ' '        )                                                                           ShipTo_zip_city,
        DECODE(DKA_SPOBON_PKG.nb_ship_to_location_id (php.po_header_id), 1,
        (CASE 
          WHEN hrla.telephone_number_1 IS NOT NULL 
           AND hrla.telephone_number_2 IS NOT NULL THEN 'Tél : ' || hrla.telephone_number_1 || ' - Fax : '|| hrla.telephone_number_2
          WHEN hrla.telephone_number_1 IS NOT NULL
           AND hrla.telephone_number_2 IS NULL     THEN 'Tél : ' || hrla.telephone_number_1
          WHEN hrla.telephone_number_1 IS NULL
           AND hrla.telephone_number_2 IS NOT NULL THEN 'Fax : ' || hrla.telephone_number_2
          WHEN hrla.telephone_number_1 IS NULL
           AND hrla.telephone_number_2 IS NULL     THEN ' '
        END),' ')                                                                                 ShipTo_phone,
        DECODE(DKA_SPOBON_PKG.nb_ship_to_location_id (php.po_header_id), 1,nvl(hrla.attribute2,' '),' ') ShipTo_supp1,
        DECODE(DKA_SPOBON_PKG.nb_ship_to_location_id (php.po_header_id), 1,nvl(hrla.attribute3,' '),' ') ShipTo_supp2,
        gl.name                                                                                   soc_name,--YWA artf2140586
        nvl(php.bill_description,' ')                                                             BillTo_name,
        nvl(php.bill_address_line1,' ')                                                           BillTo_line1,
        nvl(php.bill_address_line2,' ')                                                           BillTo_line2,
        nvl(php.bill_address_line3,' ')                                                           BillTo_line3,
        nvl(php.bill_postal_code,' ')                                                             BillTo_zip,
        nvl(php.bill_city,' ')                                                                    BillTo_city,
        nvl(php.bill_telephone_number_1,' ')                                                      BillTo_phone1,
        nvl(php.bill_telephone_number_2,' ')                                                      BillTo_phone2,
        nvl(php.note_to_vendor,' ')                                                               OrderHeaderNote,
        nvl(atv.name,' ')                                                                         PaymentTerm,
        --nvl(flvv.attribute1,' ')                                                                  PaymentMethod,
        nvl(flvv.PAYMENT_METHOD_CODE,' ')                                                                  PaymentMethod,
        nvl(to_char(pol.line_num),' ')                                                            BuyerLineItemNum,
        nvl(pol.vendor_product_num,' ')                                                           SellerPartNumber,
        nvl(pol.item_description,' ')                                                             ItemDescription,
        nvl(( SELECT decode(prla.catalog_type,'CATALOG','true','false')
              FROM   PO_REQUISITION_LINES_ALL prla
              WHERE  prla.line_location_id      = pll.line_location_id),'false')                  CatalogFlag,
        nvl(to_char(pll.quantity),' ')                                                            Quantity,
        nvl(muom.attribute2,muom.uom_code)                                                        UnitOfMeasurement,
        nvl(to_char(pol.unit_price),' ')                                                          UnitPrice,
        nvl(pll.quantity*pol.unit_price,0)                                                        LineAmount,
        DECODE(DKA_SPOBON_PKG.nb_ship_to_location_id (php.po_header_id), 1, ' ' ,
                                                                         nvl(hla.description,' '))      ShipToLine_name,
        DECODE(DKA_SPOBON_PKG.nb_ship_to_location_id (php.po_header_id), 1, ' ' ,
                                                                         nvl(hla.address_line_1,' '))    ShipToLine_line1,
        DECODE(DKA_SPOBON_PKG.nb_ship_to_location_id (php.po_header_id), 1, ' ' ,
                                                                         nvl(hla.address_line_2,' '))    ShipToLine_line2,
        DECODE(DKA_SPOBON_PKG.nb_ship_to_location_id (php.po_header_id), 1, ' ' ,
                                                                         nvl(hla.address_line_3,' '))    ShipToLine_line3,
        DECODE(DKA_SPOBON_PKG.nb_ship_to_location_id (php.po_header_id), 1, ' ' ,
                                                                         nvl(hla.postal_code || ' ' || hla.town_or_city ,' ')) ShipToLine_zip_city,
        DECODE(DKA_SPOBON_PKG.nb_ship_to_location_id (php.po_header_id), 1, ' ' ,
                                                                        (CASE 
                                                                          WHEN hla.telephone_number_1 IS NOT NULL 
                                                                           AND hla.telephone_number_2 IS NOT NULL THEN 'Tél : ' || hla.telephone_number_1 || ' - Fax : '|| hla.telephone_number_2
                                                                          WHEN hla.telephone_number_1 IS NOT NULL
                                                                           AND hla.telephone_number_2 IS NULL     THEN 'Tél : ' || hla.telephone_number_1
                                                                          WHEN hla.telephone_number_1 IS NULL
                                                                           AND hla.telephone_number_2 IS NOT NULL THEN 'Fax : ' || hla.telephone_number_2
                                                                          WHEN hla.telephone_number_1 IS NULL
                                                                           AND hla.telephone_number_2 IS NULL     THEN ' '
                                                                        END))                            ShipToLine_phone,
        DECODE(DKA_SPOBON_PKG.nb_ship_to_location_id (php.po_header_id), 1, ' ' ,
                                                                         nvl(hla.attribute2,' '))        ShipToLine_supp1,
        DECODE(DKA_SPOBON_PKG.nb_ship_to_location_id (php.po_header_id), 1, ' ' ,
                                                                         nvl(hla.attribute3,' '))        ShipToLine_supp2,
        nvl(to_char(nvl(pll.promised_date,
                        pll.need_by_date),'dd/mm/yyyy'),' ')                                      RequestDeliveryDate_line,
        nvl(php.currency_code ,' ')                                                               CurrencyCode,
        nvl(pol.note_to_vendor,' ')                                                               OrderLineNote,
        --MAIL
        pvsa.email_address                                                                        pvsa_email_address,
        pap_ope.email_address                                                                     acheteur_email_address,
        nvl(pap_dde.email_address,' ')                                                            demandeur_email_address,
        pv.vat_registration_num                                                                   tva_intracom,
        pvsa.vendor_site_code                                                                     vendor_site_code,
        nvl(pvsa.COUNTRY,' ')                                                                     vendor_country,
        pvsa.attribute1                                                                           siret,
        /*decode(php.org_id,81,'DALKIA',
                          8007,'VEOLIA TRANSPORT',
                          9412,'VEOLIA PROPRETE',
                          'A DEFINIR')                                                            ORG_NAME,*/
        haou.name                                                                                 ORG_NAME,
        decode(hla.location_code,'Adresse temporaire',hla.description,' ')                        adresse_occ,
        NVL(pol.attribute3,' ')                                                                   codeDI --RBE EDB106
      FROM
         dka_po_headers_print_niv1_v php,
         po_line_locations           polla,
         hr_locations                hrla,
         fnd_lookups                 fl,
         po_releases                 por,
         fnd_user                    usr,
         per_phones                  ppfix,
         per_people_v7            pap_ope,
         --
         po_headers                  ph,
         --LINE
         po_lines/*_print*/          pol,
         --LINE_LOC
         po_line_locations           pll,
         hr_locations                hl,
         fnd_territories_tl          fte,
         --DISTRIB
         po_distributions            pod,
         --LOC
         hr_locations                hla,
         --DIV
         gl_code_combinations        gcc,
         hr_operating_units   haou, --YWA  artf2140586
         ap_terms_vl                 atv,
         --fnd_lookup_values_vl        flvv,
         (SELECT
          REPLACE(IEPPM.PAYMENT_METHOD_CODE,';','') PAYMENT_METHOD_CODE,
          HZP.PARTY_ID,
          SITE_SUPP.PARTY_SITE_ID,
          IEP.SUPPLIER_SITE_ID
          FROM
           HZ_PARTY_SITES SITE_SUPP ,
           HZ_PARTIES HZP ,
           IBY_EXTERNAL_PAYEES_ALL IEP ,
           IBY_EXT_PARTY_PMT_MTHDS IEPPM
          WHERE 
               HZP.PARTY_ID            = SITE_SUPP.PARTY_ID
           AND IEP.PAYEE_PARTY_ID      = HZP.PARTY_ID
           AND IEP.PARTY_SITE_ID       = SITE_SUPP.PARTY_SITE_ID
           AND IEP.EXT_PAYEE_ID        =  IEPPM.EXT_PMT_PARTY_ID
           AND IEPPM.primary_flag      = 'Y'
           AND IEP.ORG_TYPE IS NOT NULL
           AND SYSDATE >= NVL(IEPPM.inactive_date,SYSDATE)) flvv,
         mtl_units_of_measure_vl     muom,
         --PVS
         po_vendor_sites             pvsa,
         po_vendors                  pv,
         per_people_v7            pap_dde,
         --PRLA
         po_requisition_lines_all    prla,
          gl_ledgers  gl --YWA artf2140586
      WHERE
       hrla.location_id = polla.ship_to_location_id
       AND fl.lookup_type = 'JEES_EURO_COUNTRY_CODES'
       AND fl.lookup_code = hrla.country
       AND polla.line_location_id = (SELECT MIN (pll2.line_location_id)
                                     FROM   po_line_locations pll2
                                     WHERE  pll2.po_header_id = php.po_header_id) 
       AND php.approved_flag         ='Y'
       AND php.po_release_id         = por.po_release_id(+)
       AND ph.created_by             = usr.user_id
       AND usr.employee_id           = ppfix.parent_id(+)
       AND pap_ope.person_id         = usr.employee_id
       --HEADER
       AND ph.po_header_id = php.po_header_id
       --LINE
       --AND NVL(php.po_release_id, -1) = NVL(pol.po_release_id, -1)
       AND php.po_header_id = pol.po_header_id
       --LINE_LOC
       AND pol.po_line_id = pll.PO_LINE_ID
       --AND NVL(pol.po_release_id, -1) = nvl(pll.po_release_id,-1) 
       AND hl.location_id(+) = pll.ship_to_location_id
       AND hl.country = fte.territory_code(+)
       AND  fte.LANGUAGE (+) = USERENV ('LANG')
       --DISTRIB
       AND pod.line_location_id = pll.LINE_LOCATION_ID
       --
       AND pll.SHIP_TO_LOCATION_ID = hla.location_id
       --GCC
       AND gcc.code_combination_id = pod.code_combination_id
       --AND gcc.segment1 = haou.name
       AND haou.organization_id = pod.org_id
       AND gl.ledger_id = haou.set_of_books_id --YWA artf2140586
       --ATV
       AND atv.TERM_ID = php.terms_id
       --FLVV
       --AND flvv.lookup_type = 'PAYMENT METHOD'
       --AND flvv.LOOKUP_CODE = php.payment_method_lookup_code
       --AND flvv.PARTY_ID    = pv.PARTY_ID					-- artf07359094 
       --AND flvv.PARTY_SITE_ID   = pvsa.PARTY_SITE_ID		-- artf07359094 
       AND flvv.SUPPLIER_SITE_ID(+) = pvsa.VENDOR_SITE_ID 	-- artf07359094    

       --MUOM
       AND MUOM.unit_of_measure = pol.unit_meas_lookup_code
       --PVSA
       AND pvsa.vendor_site_id =  php.vendor_site_id
       --PAP_DDE
       AND pap_dde.person_id = php.document_buyer_agent_id
       --PV
       AND pv.vendor_id = php.vendor_id
       --PRLA
       AND prla.line_location_id (+) = polla.line_location_id --JJA - 03/01/2014
       --parameter
       AND php.org_id = gn_org_id --RBE artf3050473
       AND po_num = cv_n_cde
      ;          
    
    --XML
    doc           xmldom.domdocument;
    main_node     xmldom.domnode;
    root_node     xmldom.domnode;
    
    --NODE
    OrderHeader_node                        xmldom.domnode;
      OrderNumber_node                      xmldom.domnode;
      OrderDates_node                       xmldom.domnode;
      OrderParty_node                       xmldom.domnode;
        BuyerParty_node                     xmldom.domnode;
          PartyID_node                      xmldom.domnode;
            Agency_node                     xmldom.domnode;
          ListOfIdentifier_node             xmldom.domnode;
            Identifier_node                 xmldom.domnode;
          PrimaryContact_node               xmldom.domnode;
            ContactFunction_node            xmldom.domnode;
            ListOfContactNumber_node        xmldom.domnode;
              ContactNumber_node            xmldom.domnode;
          OtherContacts_node                xmldom.domnode;
            Contact_node                    xmldom.domnode;
        SellerParty_node                    xmldom.domnode;
          NameAddress_node                  xmldom.domnode;
            Country_node                    xmldom.domnode;
        ShipToParty_node                    xmldom.domnode;
        BillToParty_node                    xmldom.domnode;
      OrderTermsOfDelivery_node             xmldom.domnode;
      OrderPaymentInstructions_node         xmldom.domnode;
        PaymentTerms_node                   xmldom.domnode;
        PaymentMethod_node                  xmldom.domnode; 
    OrderDetail_node                        xmldom.domnode;
      ListOfItemDetail_node                 xmldom.domnode;
        ItemDetail_node                     xmldom.domnode;
          BaseItemDetail_node               xmldom.domnode;
            BaseItemReferences_node         xmldom.domnode;
              BaseItemReferencesType_node   xmldom.domnode;
            LineItemNum_node                xmldom.domnode; 
            ItemIdentifiers_node            xmldom.domnode;
              PartNumbers_node              xmldom.domnode;
                SellerPartNumber_node       xmldom.domnode;
                ManufacturerPartNumber_node xmldom.domnode;
            TotalQuantity_node              xmldom.domnode;
              UnitOfMeasurement_node        xmldom.domnode;
          PricingDetail_node                xmldom.domnode;
            ListOfPrice_node                xmldom.domnode;
                Price_node                  xmldom.domnode;
                  UnitPrice_node            xmldom.domnode;
                  PriceMultiplier_node      xmldom.domnode;
            LineItemTotal_node              xmldom.domnode;
          DeliveryDetail_node               xmldom.domnode;
            ShipToLocation_node             xmldom.domnode;
              LocationIdentifier_node       xmldom.domnode;
                LocID_node                  xmldom.domnode;
            ListOfScheduleLine_node         xmldom.domnode;
              ScheduleLine_node             xmldom.domnode;
    OrderSummary_node                       xmldom.domnode;
      OrderTotal_node                       xmldom.domnode;
        Currency_node                       xmldom.domnode;
    
    --SYSTEM NODE
    item_node xmldom.domnode;
    root_elmt xmldom.domelement;
    item_elmt xmldom.domelement;
    item_text xmldom.domtext;
    
    --Variables
    vn_po_header_id          po_distributions_all.po_header_id%TYPE;
    vn_requisition_header_id po_requisition_lines_all.requisition_header_id%TYPE;
    vn_po_line_id            po_distributions_all.po_line_id%TYPE;
    vn_line_location_id      po_distributions_all.line_location_id%TYPE;
    vn_po_distribution_id    po_distributions_all.po_distribution_id%TYPE;
    vv_currencycode          po_headers_all.currency_code%TYPE;
    vn_amount                NUMBER;
    vv_text_l                VARCHAR2(2000);
    vv_adresse               VARCHAR2(2000);
    vv_adresse_occ           VARCHAR2(50); 
    vv_manufacturer_part_num VARCHAR2(100); 
    
    v_note_req_temp   VARCHAR2(4000); --YWA artf2140678 
    
    --Constant
    cv_condition_livraison CONSTANT VARCHAR2(50) := 'Conditions de livraison';
    cv_acheteur            CONSTANT VARCHAR2(50) := 'Agent';
    cv_demandeur           CONSTANT VARCHAR2(50) := 'Requestor';
    cv_tel                 CONSTANT VARCHAR2(50) := 'TelephoneNumber';
    cv_fax                 CONSTANT VARCHAR2(50) := 'FaxNumber';
    cv_mob                 CONSTANT VARCHAR2(50) := 'MobileNumber';
    cv_email               CONSTANT VARCHAR2(50) := 'EmailAddress';
    cn_multiplier          CONSTANT NUMBER       := 1;
    
    cv_xmlns_core             CONSTANT VARCHAR2(50)  := 'xmlns:core';
    cv_xmlns_core_txt         CONSTANT VARCHAR2(150) := 'rrn:org.xcbl:schemas/xcbl/v4_0/core/core.xsd';
    cv_xmlns                  CONSTANT VARCHAR2(50)  := 'xmlns';
    cv_xmlns_txt              CONSTANT VARCHAR2(150) := 'rrn:org.xcbl:schemas/xcbl/v4_0/ordermanagement/v1_0/ordermanagement.xsd';
    cv_xmlns_xsi              CONSTANT VARCHAR2(50)  := 'xmlns:xsi';
    cv_xmlns_xsi_txt          CONSTANT VARCHAR2(150) := 'http://www.w3.org/2001/XMLSchema-instance';
    cv_xsi_schemaLocation     CONSTANT VARCHAR2(50)  := 'xsi:schemaLocation';
    cv_xsi_schemaLocation_txt CONSTANT VARCHAR2(200) := 'rrn:org.xcbl:schemas/xcbl/v4_0/ordermanagement/v1_0/ordermanagement.xsd ../../schema/org/xcbl/path_delim/schemas/xcbl/v4_0/ordermanagement/v1_0/ordermanagement.xsd';
    
    --SpecialHandling --JJA - 11/12/2014
    vv_special_handling  VARCHAR2(1000);
    SpecialHandling_node xmldom.domnode;
    
    --ListOfNameValueSet --RBE - 27/04/2018
    ListOfNameValueSet_node     xmldom.domnode;
    NameValueSet_node           xmldom.domnode;
    SetName_node                xmldom.domnode;
    ListOfNameValuePair_node    xmldom.domnode;
    NameValuePair_node          xmldom.domnode;
    
              
    CURSOR c_project(cn_line_location_id po_distributions_all.line_location_id%TYPE) IS
     SELECT ppa.segment1 
     FROM 
      pa_projects_all ppa,
      po_distributions_all pda
     where
      ppa.project_id = pda.project_id
      and pda.line_location_id = cn_line_location_id;
    
  BEGIN
    
    --Init des variables de sortie
    p_retcode := 0;
    p_errbuf  := '';
    
    g_step  := 'CONSTRUCTION_XML 000 : DEBUT';
    log_msg(g_step);
    
    vn_amount := 0;
    
    --Création du document
    g_step  := 'CONSTRUCTION_XML 001 : Création du document';
    log_msg(g_step);
    doc       := xmldom.newdomdocument;
    xmldom.setVersion(doc, '1.0');
    xmldom.setCharset(doc, 'UTF8');
    
    --NODE ORDER
    g_step  := 'CONSTRUCTION_XML 002.1 : NODE ORDER';
    log_msg(g_step);
    main_node := xmldom.makenode(doc);
    root_elmt := xmldom.createelement(doc, 'Order');
    xmldom.setattribute(root_elmt, cv_xmlns_core,         cv_xmlns_core_txt);
    xmldom.setattribute(root_elmt, cv_xmlns,              cv_xmlns_txt);
    xmldom.setattribute(root_elmt, cv_xmlns_xsi,          cv_xmlns_xsi_txt);
    xmldom.setattribute(root_elmt, cv_xsi_schemaLocation, cv_xsi_schemaLocation_txt);    
    root_node := xmldom.appendchild(main_node, xmldom.makenode(root_elmt));
    
    g_step  := 'CONSTRUCTION_XML 002.2 : NODE ORDER';
    log_msg(g_step);
    
    FOR ligne IN c_select(gv_order_number) LOOP
      g_step  := 'CONSTRUCTION_XML 003 : nouvelle ligne';
      log_msg(g_step);
      
      --GET ORDER LINE NOTE
      g_step  := 'CONSTRUCTION_XML 004 : GET ORDER LINE NOTE';
      log_msg(g_step);
      vv_text_l :=  get_order_line_note(ligne.po_line_id);
      
      IF vv_text_l != ' ' AND ligne.OrderLineNote != ' ' THEN
        vv_text_l := vv_text_l || ' / ' || ligne.OrderLineNote;
      ELSIF vv_text_l != ' ' THEN
        vv_text_l := vv_text_l;
      ELSE
       vv_text_l := ligne.OrderLineNote;
      END IF;
      
      --GET ORDER LINE SHIPMENT
      g_step  := 'CONSTRUCTION_XML 004b : GET ORDER LINE SHIPMENT';
      log_msg(g_step);
      vv_adresse :=  get_order_line_shipment(ligne.line_location_id);
      
      IF vv_adresse = ' ' THEN
       vv_adresse_occ := ' ';
      ELSE
       vv_adresse_occ := ligne.adresse_occ;
      END IF;
      
      -->JJA 29/01/2014
      --GET MANUFACTURER_PART_NUM
      BEGIN
       SELECT nvl(substr(icit.manufacturer_part_num,1,100),' ')    
       INTO vv_manufacturer_part_num
       FROM ICX_CAT_ITEMS_TLP icit
       WHERE
        icit.supplier_id           = ligne.vendor_id
        AND icit.supplier_part_num = ligne.SellerPartNumber;
        
      EXCEPTION
       WHEN OTHERS THEN
        vv_manufacturer_part_num := ' ';
      END;
      --<JJA 29/01/2014
      
      
      -->JJA 11/12/2014
      --SpecialHandling
      BEGIN
       vv_special_handling := NULL;
       
       FOR l_sh IN c_project(ligne.LINE_LOCATION_ID) LOOP
          vv_special_handling := vv_special_handling || l_sh.segment1 || ' , ';
       END LOOP;
       
       vv_special_handling :=   substr(vv_special_handling,1,length(vv_special_handling)-3) ;
             
      EXCEPTION
       WHEN OTHERS THEN
         vv_special_handling := ' ';
      END;
      --<JJA JJA 11/12/2014
      
      IF nvl(vn_po_header_id,-1) != ligne.po_header_id THEN 
        
        --IF nvl(gn_piece_jointe,0) != 0 THEN
          --GET ORDER HEADER NOTE 
          --Il n'est pas necessaire de récupérer les notes de type texte
          -- car présente niveau ligne
          
          
          g_step  := 'CONSTRUCTION_XML 005 : GET ORDER HEADER NOTE';
          log_msg(g_step);
          get_order_header_note(ligne.po_header_id,ligne.vendor_id,ligne.requisition_header_id,v_note_req_temp);--YWA artf2140678 
          --YWA artf2140678 
          IF v_note_req_temp != ' ' AND ligne.OrderLineNote != ' ' THEN
            v_note_req_temp := v_note_req_temp || ' / ' || ligne.OrderHeaderNote;
          ELSIF v_note_req_temp != ' ' THEN
            v_note_req_temp := v_note_req_temp;
          ELSE
           v_note_req_temp := ligne.OrderHeaderNote;
          END IF;--YWA artf2140678 
          
          g_step  := 'CONSTRUCTION_XML 005 : GET REQ FILE';
          log_msg(g_step);
          
          IF ligne.requisition_header_id IS NOT NULL THEN --JJA - 03/01/2014
            get_req_file(ligne.requisition_header_id, p_errbuf,p_retcode);
          END IF; --JJA - 03/01/2014
          
        --END IF;
        
        g_step  := 'CONSTRUCTION_XML 006 : PO_HEADER_ID :'||ligne.po_header_id;
        log_msg(g_step);
        
        --Sauvegarde des données
        vn_po_header_id        := ligne.po_header_id;
        vn_requisition_header_id := ligne.requisition_header_id;
        vn_po_line_id          := ligne.po_line_id;
        vn_line_location_id    := ligne.line_location_id;
        vn_po_distribution_id  := ligne.po_distribution_id;
        vv_currencycode        := ligne.CurrencyCode;
        
        g_step  := 'CONSTRUCTION_XML 007 : Construction du flux XML';
        log_msg(g_step);
        
        --OrderHeader
        g_step  := 'XML : OrderHeader';--log_msg(g_step);
        item_elmt := xmldom.createelement(doc, 'OrderHeader');
        OrderHeader_node := xmldom.appendchild(root_node, xmldom.makenode(item_elmt));
        
          --OrderNumber-----------------------------------------------------------
          g_step  := 'XML : OrderNumber';--log_msg(g_step);
          item_elmt                     := xmldom.createelement(doc, 'OrderNumber');
          OrderNumber_node              := xmldom.appendchild(OrderHeader_node, xmldom.makenode(item_elmt));
            --BuyerOrderNumber
            g_step  := 'XML : BuyerOrderNumber';--log_msg(g_step);
            item_elmt := xmldom.createelement(doc, 'BuyerOrderNumber');
            item_node := xmldom.appendchild(OrderNumber_node, xmldom.makenode(item_elmt));
            item_text := xmldom.createtextnode(doc, ligne.BuyerOrderNumber);
            item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
          
          --OrderDates------------------------------------------------------------
          g_step  := 'XML : OrderDates';--log_msg(g_step);
          item_elmt                     := xmldom.createelement(doc, 'OrderDates');
          OrderDates_node               := xmldom.appendchild(OrderHeader_node, xmldom.makenode(item_elmt));
            --RequestedDeliverByDate
            g_step  := 'XML : RequestedDeliverByDate';--log_msg(g_step);
            item_elmt := xmldom.createelement(doc, 'RequestedDeliverByDate');
            item_node := xmldom.appendchild(OrderDates_node, xmldom.makenode(item_elmt));
            item_text := xmldom.createtextnode(doc, ligne.RequestedDeliverByDate);
            item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
          
          --OrderParty------------------------------------------------------------
          g_step  := 'XML : OrderParty';--log_msg(g_step);
          item_elmt                     := xmldom.createelement(doc, 'OrderParty');
          OrderParty_node               := xmldom.appendchild(OrderHeader_node, xmldom.makenode(item_elmt));
            --BuyerParty
            g_step  := 'XML : BuyerParty';--log_msg(g_step);
            item_elmt                   := xmldom.createelement(doc, 'BuyerParty');
            BuyerParty_node             := xmldom.appendchild(OrderParty_node, xmldom.makenode(item_elmt));
              --PartyID
              g_step  := 'XML : PartyID';--log_msg(g_step);
              item_elmt                   := xmldom.createelement(doc, 'core:PartyID');
              PartyID_node                := xmldom.appendchild(BuyerParty_node, xmldom.makenode(item_elmt));
                --Agency
                g_step  := 'XML : Agency';--log_msg(g_step);
                item_elmt                   := xmldom.createelement(doc, 'core:Agency');
                Agency_node                 := xmldom.appendchild(PartyID_node, xmldom.makenode(item_elmt));
                  --core:AgencyCodedOther
                  g_step  := 'XML : AgencyCodedOther';--log_msg(g_step); 
                  item_elmt := xmldom.createelement(doc, 'core:AgencyCodedOther');
                  item_node := xmldom.appendchild(Agency_node, xmldom.makenode(item_elmt));
                  item_text := xmldom.createtextnode(doc, ligne.BuyerPartyDde_appartenance);
                  item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
                  --core:AgencyDescription
                  g_step  := 'XML : AgencyDescription';--log_msg(g_step); 
                  item_elmt := xmldom.createelement(doc, 'core:AgencyDescription');
                  item_node := xmldom.appendchild(Agency_node, xmldom.makenode(item_elmt));
                  item_text := xmldom.createtextnode(doc, ligne.BuyerPartyAgencyCoded);
                  item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
                --core:Ident
                g_step  := 'XML : Ident';--log_msg(g_step);
                item_elmt := xmldom.createelement(doc, 'core:Ident');
                item_node := xmldom.appendchild(PartyID_node, xmldom.makenode(item_elmt));
                item_text := xmldom.createtextnode(doc, ligne.BuyerPartyIdent);
                item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
              --ListOfIdentifier
              g_step  := 'XML : ListOfIdentifier';--log_msg(g_step);
              item_elmt                   := xmldom.createelement(doc, 'core:ListOfIdentifier');
              ListOfIdentifier_node       := xmldom.appendchild(BuyerParty_node, xmldom.makenode(item_elmt));
                --Identifier
                g_step  := 'XML : Identifier';--log_msg(g_step);
                item_elmt                   := xmldom.createelement(doc, 'core:Identifier');
                Identifier_node             := xmldom.appendchild(ListOfIdentifier_node, xmldom.makenode(item_elmt));
                  --Agency
                  g_step  := 'XML : Agency';--log_msg(g_step);
                  item_elmt                   := xmldom.createelement(doc, 'core:Agency');
                  Agency_node                 := xmldom.appendchild(Identifier_node, xmldom.makenode(item_elmt));
                    --core:AgencyDescription
                    g_step  := 'XML : AgencyDescription';--log_msg(g_step); 
                    item_elmt := xmldom.createelement(doc, 'core:AgencyDescription');
                    item_node := xmldom.appendchild(Agency_node, xmldom.makenode(item_elmt));
                    --item_text := xmldom.createtextnode(doc, NULL);
                    --item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
                  --core:Ident
                  g_step  := 'XML : Ident';--log_msg(g_step);
                  item_elmt := xmldom.createelement(doc, 'core:Ident');
                  item_node := xmldom.appendchild(Identifier_node, xmldom.makenode(item_elmt));
                  --item_text := xmldom.createtextnode(doc, NULL);
                  --item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
              --PrimaryContact
              g_step  := 'XML : PrimaryContact';--log_msg(g_step);
              item_elmt                   := xmldom.createelement(doc, 'core:PrimaryContact');
              PrimaryContact_node         := xmldom.appendchild(BuyerParty_node, xmldom.makenode(item_elmt));
                --ContactName
                g_step  := 'XML : ContactName';--log_msg(g_step);
                item_elmt := xmldom.createelement(doc, 'core:ContactName');
                item_node := xmldom.appendchild(PrimaryContact_node, xmldom.makenode(item_elmt));
                item_text := xmldom.createtextnode(doc, ligne.BuyerPartyAch_name);
                item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
                --ContactFunction
                g_step  := 'XML : ContactFunction';--log_msg(g_step);
                item_elmt                   := xmldom.createelement(doc, 'core:ContactFunction');
                ContactFunction_node        := xmldom.appendchild(PrimaryContact_node, xmldom.makenode(item_elmt));
                  --ContactFunctionCoded
                  g_step  := 'XML : ContactFunctionCoded';--log_msg(g_step);
                  item_elmt := xmldom.createelement(doc, 'core:ContactFunctionCoded');
                  item_node := xmldom.appendchild(ContactFunction_node, xmldom.makenode(item_elmt));
                  item_text := xmldom.createtextnode(doc, cv_acheteur);
                  item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
                --ListOfContactNumber
                g_step  := 'XML : ListOfContactNumber';--log_msg(g_step);
                item_elmt                   := xmldom.createelement(doc, 'core:ListOfContactNumber');
                ListOfContactNumber_node    := xmldom.appendchild(PrimaryContact_node, xmldom.makenode(item_elmt));  
                  --ContactNumber
                  g_step  := 'XML : ContactNumber';--log_msg(g_step);
                  item_elmt                   := xmldom.createelement(doc, 'core:ContactNumber');
                  ContactNumber_node          := xmldom.appendchild(ListOfContactNumber_node, xmldom.makenode(item_elmt)); 
                    --ContactNumberValue
                    g_step  := 'XML : ContactNumberValue';--log_msg(g_step);
                    item_elmt := xmldom.createelement(doc, 'core:ContactNumberValue');
                    item_node := xmldom.appendchild(ContactNumber_node, xmldom.makenode(item_elmt));
                    item_text := xmldom.createtextnode(doc, ligne.BuyerPartyAch_tel);
                    item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
                    --ContactNumberTypeCoded 
                    g_step  := 'XML : ContactNumberTypeCoded';--log_msg(g_step);
                    item_elmt := xmldom.createelement(doc, 'core:ContactNumberTypeCoded');
                    item_node := xmldom.appendchild(ContactNumber_node, xmldom.makenode(item_elmt));
                    item_text := xmldom.createtextnode(doc, cv_tel);
                    item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
                  --ContactNumber
                  g_step  := 'XML : ContactNumber';--log_msg(g_step);
                  item_elmt                   := xmldom.createelement(doc, 'core:ContactNumber');
                  ContactNumber_node          := xmldom.appendchild(ListOfContactNumber_node, xmldom.makenode(item_elmt)); 
                    --ContactNumberValue
                    g_step  := 'XML : ContactNumberValue';--log_msg(g_step);
                    item_elmt := xmldom.createelement(doc, 'core:ContactNumberValue');
                    item_node := xmldom.appendchild(ContactNumber_node, xmldom.makenode(item_elmt));
                    item_text := xmldom.createtextnode(doc, ligne.BuyerPartyAch_fax);
                    item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
                    --ContactNumberTypeCoded 
                    g_step  := 'XML : ContactNumberTypeCoded';--log_msg(g_step);
                    item_elmt := xmldom.createelement(doc, 'core:ContactNumberTypeCoded');
                    item_node := xmldom.appendchild(ContactNumber_node, xmldom.makenode(item_elmt));
                    item_text := xmldom.createtextnode(doc, cv_fax);
                    item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text)); 
                  --ContactNumber
                  g_step  := 'XML : ContactNumber';--log_msg(g_step);
                  item_elmt                   := xmldom.createelement(doc, 'core:ContactNumber');
                  ContactNumber_node          := xmldom.appendchild(ListOfContactNumber_node, xmldom.makenode(item_elmt)); 
                    --ContactNumberValue
                    g_step  := 'XML : ContactNumberValue';--log_msg(g_step);
                    item_elmt := xmldom.createelement(doc, 'core:ContactNumberValue');
                    item_node := xmldom.appendchild(ContactNumber_node, xmldom.makenode(item_elmt));
                    item_text := xmldom.createtextnode(doc, ligne.BuyerPartyAch_mob);
                    item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
                    --ContactNumberTypeCoded 
                    g_step  := 'XML : ContactNumberTypeCoded';--log_msg(g_step);
                    item_elmt := xmldom.createelement(doc, 'core:ContactNumberTypeCoded');
                    item_node := xmldom.appendchild(ContactNumber_node, xmldom.makenode(item_elmt));
                    item_text := xmldom.createtextnode(doc, cv_mob);
                    item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text)); 
                  --ContactNumber
                  g_step  := 'XML : ContactNumber';--log_msg(g_step);
                  item_elmt                   := xmldom.createelement(doc, 'core:ContactNumber');
                  ContactNumber_node          := xmldom.appendchild(ListOfContactNumber_node, xmldom.makenode(item_elmt));  
                    --ContactNumberValue
                    g_step  := 'XML : ContactNumberValue';--log_msg(g_step);
                    item_elmt := xmldom.createelement(doc, 'core:ContactNumberValue');
                    item_node := xmldom.appendchild(ContactNumber_node, xmldom.makenode(item_elmt));
                    item_text := xmldom.createtextnode(doc, nvl(ligne.acheteur_email_address,' '));
                    item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
                    --ContactNumberTypeCoded 
                    g_step  := 'XML : ContactNumberTypeCoded';--log_msg(g_step);
                    item_elmt := xmldom.createelement(doc, 'core:ContactNumberTypeCoded');
                    item_node := xmldom.appendchild(ContactNumber_node, xmldom.makenode(item_elmt));
                    item_text := xmldom.createtextnode(doc, cv_email);
                    item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
                  
              --OtherContacts
              g_step  := 'XML : OtherContacts';--log_msg(g_step);
              item_elmt                   := xmldom.createelement(doc, 'core:OtherContacts');
              OtherContacts_node          := xmldom.appendchild(BuyerParty_node, xmldom.makenode(item_elmt));
                --Contact
                g_step  := 'XML : Contact';--log_msg(g_step);
                item_elmt                   := xmldom.createelement(doc, 'core:Contact');
                Contact_node                := xmldom.appendchild(OtherContacts_node, xmldom.makenode(item_elmt));
                  --ContactName
                  g_step  := 'XML : ContactName';--log_msg(g_step);
                  item_elmt := xmldom.createelement(doc, 'core:ContactName');
                  item_node := xmldom.appendchild(Contact_node, xmldom.makenode(item_elmt));
                  item_text := xmldom.createtextnode(doc, ligne.BuyerPartyDde_name);
                  item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
                  --ContactFunction
                  g_step  := 'XML : ContactFunction';--log_msg(g_step);
                  item_elmt                   := xmldom.createelement(doc, 'core:ContactFunction');
                  ContactFunction_node        := xmldom.appendchild(Contact_node, xmldom.makenode(item_elmt));
                    --ContactFunctionCoded
                    g_step  := 'XML : ContactFunctionCoded';--log_msg(g_step);
                    item_elmt := xmldom.createelement(doc, 'core:ContactFunctionCoded');
                    item_node := xmldom.appendchild(ContactFunction_node, xmldom.makenode(item_elmt));
                    item_text := xmldom.createtextnode(doc, cv_demandeur);
                    item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
                  --ListOfContactNumber
                  g_step  := 'XML : ListOfContactNumber';--log_msg(g_step);
                  item_elmt                   := xmldom.createelement(doc, 'core:ListOfContactNumber');
                  ListOfContactNumber_node    := xmldom.appendchild(Contact_node, xmldom.makenode(item_elmt));  
                    --ContactNumber
                    g_step  := 'XML : ContactNumber';--log_msg(g_step);
                    item_elmt                   := xmldom.createelement(doc, 'core:ContactNumber');
                    ContactNumber_node          := xmldom.appendchild(ListOfContactNumber_node, xmldom.makenode(item_elmt)); 
                      --ContactNumberValue
                      g_step  := 'XML : ContactNumberValue';--log_msg(g_step);
                      item_elmt := xmldom.createelement(doc, 'core:ContactNumberValue');
                      item_node := xmldom.appendchild(ContactNumber_node, xmldom.makenode(item_elmt));
                      item_text := xmldom.createtextnode(doc, ligne.BuyerPartyDde_tel);
                      item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
                      --ContactNumberTypeCoded 
                      g_step  := 'XML : ContactNumberTypeCoded';--log_msg(g_step);
                      item_elmt := xmldom.createelement(doc, 'core:ContactNumberTypeCoded');
                      item_node := xmldom.appendchild(ContactNumber_node, xmldom.makenode(item_elmt));
                      item_text := xmldom.createtextnode(doc, cv_tel);
                      item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
                    --ContactNumber
                    g_step  := 'XML : ContactNumber';--log_msg(g_step);
                    item_elmt                   := xmldom.createelement(doc, 'core:ContactNumber');
                    ContactNumber_node          := xmldom.appendchild(ListOfContactNumber_node, xmldom.makenode(item_elmt)); 
                      --ContactNumberValue
                      g_step  := 'XML : ContactNumberValue';--log_msg(g_step);
                      item_elmt := xmldom.createelement(doc, 'core:ContactNumberValue');
                      item_node := xmldom.appendchild(ContactNumber_node, xmldom.makenode(item_elmt));
                      item_text := xmldom.createtextnode(doc, ligne.BuyerPartyDde_fax);
                      item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
                      --ContactNumberTypeCoded 
                      g_step  := 'XML : ContactNumberTypeCoded';--log_msg(g_step);
                      item_elmt := xmldom.createelement(doc, 'core:ContactNumberTypeCoded');
                      item_node := xmldom.appendchild(ContactNumber_node, xmldom.makenode(item_elmt));
                      item_text := xmldom.createtextnode(doc, cv_fax);
                      item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text)); 
                    --ContactNumber
                    g_step  := 'XML : ContactNumber';--log_msg(g_step);
                    item_elmt                   := xmldom.createelement(doc, 'core:ContactNumber');
                    ContactNumber_node          := xmldom.appendchild(ListOfContactNumber_node, xmldom.makenode(item_elmt)); 
                      --ContactNumberValue
                      g_step  := 'XML : ContactNumberValue';--log_msg(g_step);
                      item_elmt := xmldom.createelement(doc, 'core:ContactNumberValue');
                      item_node := xmldom.appendchild(ContactNumber_node, xmldom.makenode(item_elmt));
                      item_text := xmldom.createtextnode(doc, ligne.BuyerPartyDde_mob);
                      item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
                      --ContactNumberTypeCoded 
                      g_step  := 'XML : ContactNumberTypeCoded';--log_msg(g_step);
                      item_elmt := xmldom.createelement(doc, 'core:ContactNumberTypeCoded');
                      item_node := xmldom.appendchild(ContactNumber_node, xmldom.makenode(item_elmt));
                      item_text := xmldom.createtextnode(doc, cv_mob);
                      item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text)); 
                    --ContactNumber
                    g_step  := 'XML : ContactNumber';--log_msg(g_step);
                    item_elmt                   := xmldom.createelement(doc, 'core:ContactNumber');
                    ContactNumber_node          := xmldom.appendchild(ListOfContactNumber_node, xmldom.makenode(item_elmt));  
                      --ContactNumberValue
                      g_step  := 'XML : ContactNumberValue';--log_msg(g_step);
                      item_elmt := xmldom.createelement(doc, 'core:ContactNumberValue');
                      item_node := xmldom.appendchild(ContactNumber_node, xmldom.makenode(item_elmt));
                      item_text := xmldom.createtextnode(doc, ligne.demandeur_email_address);
                      item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
                      --ContactNumberTypeCoded 
                      g_step  := 'XML : ContactNumberTypeCoded';--log_msg(g_step);
                      item_elmt := xmldom.createelement(doc, 'core:ContactNumberTypeCoded');
                      item_node := xmldom.appendchild(ContactNumber_node, xmldom.makenode(item_elmt));
                      item_text := xmldom.createtextnode(doc, cv_email);
                      item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
                      
            --SellerParty
            g_step  := 'XML : SellerParty';--log_msg(g_step);
            item_elmt                   := xmldom.createelement(doc, 'SellerParty');
            SellerParty_node            := xmldom.appendchild(OrderParty_node, xmldom.makenode(item_elmt));
              --PartyID
              g_step  := 'XML : PartyID';--log_msg(g_step);
              item_elmt                   := xmldom.createelement(doc, 'core:PartyID');
              PartyID_node                := xmldom.appendchild(SellerParty_node, xmldom.makenode(item_elmt));
                --core:Ident
                g_step  := 'XML : Ident';--log_msg(g_step);
                item_elmt := xmldom.createelement(doc, 'core:Ident');
                item_node := xmldom.appendchild(PartyID_node, xmldom.makenode(item_elmt));
                --item_text := xmldom.createtextnode(doc, NULL);
                --item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));  
              --NameAddress
              g_step  := 'XML : NameAddress';--log_msg(g_step);
              item_elmt                   := xmldom.createelement(doc, 'core:NameAddress');
              NameAddress_node            := xmldom.appendchild(SellerParty_node, xmldom.makenode(item_elmt));
                --core:ExternalAddressID
                g_step  := 'XML : ExternalAddressID';--log_msg(g_step);
                item_elmt := xmldom.createelement(doc, 'core:ExternalAddressID');
                item_node := xmldom.appendchild(NameAddress_node, xmldom.makenode(item_elmt));
                item_text := xmldom.createtextnode(doc, ligne.SellerParty_name);
                item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));  
                --core:Name1
                g_step  := 'XML : Name1';--log_msg(g_step);
                item_elmt := xmldom.createelement(doc, 'core:Name1');
                item_node := xmldom.appendchild(NameAddress_node, xmldom.makenode(item_elmt));
                item_text := xmldom.createtextnode(doc, ligne.SellerParty_line1);
                item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));  
                --core:Name2
                g_step  := 'XML : Name2';--log_msg(g_step);
                item_elmt := xmldom.createelement(doc, 'core:Name2');
                item_node := xmldom.appendchild(NameAddress_node, xmldom.makenode(item_elmt));
                item_text := xmldom.createtextnode(doc, ligne.SellerParty_line2);
                item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));  
                --core:Name3
                g_step  := 'XML : Name3';--log_msg(g_step);
                item_elmt := xmldom.createelement(doc, 'core:Name3');
                item_node := xmldom.appendchild(NameAddress_node, xmldom.makenode(item_elmt));
                item_text := xmldom.createtextnode(doc, ligne.SellerParty_line3);
                item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));  
                --core:PostalCode
                g_step  := 'XML : PostalCode';--log_msg(g_step);
                item_elmt := xmldom.createelement(doc, 'core:PostalCode');
                item_node := xmldom.appendchild(NameAddress_node, xmldom.makenode(item_elmt));
                item_text := xmldom.createtextnode(doc, ligne.SellerParty_zip);
                item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));  
                --core:City
                g_step  := 'XML : City';--log_msg(g_step);
                item_elmt := xmldom.createelement(doc, 'core:City');
                item_node := xmldom.appendchild(NameAddress_node, xmldom.makenode(item_elmt));
                item_text := xmldom.createtextnode(doc, ligne.SellerParty_city);
                item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));  
                --core:Country
                g_step  := 'XML : Country';--log_msg(g_step);
                item_elmt                   := xmldom.createelement(doc, 'core:Country');
                Country_node                := xmldom.appendchild(NameAddress_node, xmldom.makenode(item_elmt));
                  --core:CountryCoded
                  g_step  := 'XML : CountryCoded';--log_msg(g_step);
                  item_elmt := xmldom.createelement(doc, 'core:CountryCoded');
                  item_node := xmldom.appendchild(Country_node, xmldom.makenode(item_elmt));
                  item_text := xmldom.createtextnode(doc, ligne.vendor_country);
                  item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));  
                
              --PrimaryContact
              g_step  := 'XML : PrimaryContact';--log_msg(g_step);
              item_elmt                   := xmldom.createelement(doc, 'core:PrimaryContact');
              PrimaryContact_node         := xmldom.appendchild(SellerParty_node, xmldom.makenode(item_elmt));
                --ListOfContactNumber
                g_step  := 'XML : ListOfContactNumber';--log_msg(g_step);
                item_elmt                   := xmldom.createelement(doc, 'core:ListOfContactNumber');
                ListOfContactNumber_node    := xmldom.appendchild(PrimaryContact_node, xmldom.makenode(item_elmt));  
                  --ContactNumber
                  g_step  := 'XML : ContactNumber';--log_msg(g_step);
                  item_elmt                   := xmldom.createelement(doc, 'core:ContactNumber');
                  ContactNumber_node          := xmldom.appendchild(ListOfContactNumber_node, xmldom.makenode(item_elmt)); 
                    --ContactNumberValue
                    g_step  := 'XML : ContactNumberValue';--log_msg(g_step);
                    item_elmt := xmldom.createelement(doc, 'core:ContactNumberValue');
                    item_node := xmldom.appendchild(ContactNumber_node, xmldom.makenode(item_elmt));
                    item_text := xmldom.createtextnode(doc, ligne.SellerParty_phone);
                    item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
                    --ContactNumberTypeCoded 
                    g_step  := 'XML : ContactNumberTypeCoded';--log_msg(g_step);
                    item_elmt := xmldom.createelement(doc, 'core:ContactNumberTypeCoded');
                    item_node := xmldom.appendchild(ContactNumber_node, xmldom.makenode(item_elmt));
                    item_text := xmldom.createtextnode(doc, cv_tel);
                    item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
                  --ContactNumber
                  --g_step  := 'XML : ContactNumber';--log_msg(g_step);
                  --item_elmt                   := xmldom.createelement(doc, 'core:ContactNumber');
                  --ContactNumber_node          := xmldom.appendchild(ListOfContactNumber_node, xmldom.makenode(item_elmt)); 
                    --ContactNumberValue
                    --g_step  := 'XML : ContactNumberValue';--log_msg(g_step);
                    --item_elmt := xmldom.createelement(doc, 'core:ContactNumberValue');
                    --item_node := xmldom.appendchild(ContactNumber_node, xmldom.makenode(item_elmt));
                    --item_text := xmldom.createtextnode(doc, ligne.SellerParty_fax);
                    --item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
                    --ContactNumberTypeCoded 
                    --g_step  := 'XML : ContactNumberTypeCoded';--log_msg(g_step);
                    --item_elmt := xmldom.createelement(doc, 'core:ContactNumberTypeCoded');
                    --item_node := xmldom.appendchild(ContactNumber_node, xmldom.makenode(item_elmt));
                    --item_text := xmldom.createtextnode(doc, cv_fax);
                    --item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text)); 
                                    
            --ShipToParty
            g_step  := 'XML : ShipToParty';--log_msg(g_step);
            item_elmt                   := xmldom.createelement(doc, 'ShipToParty');
            ShipToParty_node            := xmldom.appendchild(OrderParty_node, xmldom.makenode(item_elmt));
              --NameAddress
              g_step  := 'XML : NameAddress';--log_msg(g_step);
              item_elmt                   := xmldom.createelement(doc, 'core:NameAddress');
              NameAddress_node            := xmldom.appendchild(ShipToParty_node, xmldom.makenode(item_elmt));
                --core:ExternalAddressID
                g_step  := 'XML : ExternalAddressID';--log_msg(g_step);
                item_elmt := xmldom.createelement(doc, 'core:ExternalAddressID');
                item_node := xmldom.appendchild(NameAddress_node, xmldom.makenode(item_elmt));
                item_text := xmldom.createtextnode(doc, ligne.ShipTo_name);
                item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));  
                --core:Name1
                g_step  := 'XML : Name1';--log_msg(g_step);
                item_elmt := xmldom.createelement(doc, 'core:Name1');
                item_node := xmldom.appendchild(NameAddress_node, xmldom.makenode(item_elmt));
                item_text := xmldom.createtextnode(doc, ligne.ShipTo_line1);
                item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));  
                --core:Name2
                g_step  := 'XML : Name2';--log_msg(g_step);
                item_elmt := xmldom.createelement(doc, 'core:Name2');
                item_node := xmldom.appendchild(NameAddress_node, xmldom.makenode(item_elmt));
                item_text := xmldom.createtextnode(doc, ligne.ShipTo_line2);
                item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));  
                --core:Name3
                g_step  := 'XML : Name3';--log_msg(g_step);
                item_elmt := xmldom.createelement(doc, 'core:Name3');
                item_node := xmldom.appendchild(NameAddress_node, xmldom.makenode(item_elmt));
                item_text := xmldom.createtextnode(doc, ligne.ShipTo_line3);
                item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));  
                --core:Street
                g_step  := 'XML : Street';--log_msg(g_step);
                item_elmt := xmldom.createelement(doc, 'core:Street');
                item_node := xmldom.appendchild(NameAddress_node, xmldom.makenode(item_elmt));
                item_text := xmldom.createtextnode(doc, ligne.ShipTo_zip_city);
                item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));  
                --core:HouseNumber
                g_step  := 'XML : HouseNumber';--log_msg(g_step);
                item_elmt := xmldom.createelement(doc, 'core:HouseNumber');
                item_node := xmldom.appendchild(NameAddress_node, xmldom.makenode(item_elmt));
                item_text := xmldom.createtextnode(doc, ligne.ShipTo_phone);
                item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text)); 
                --core:StreetSupplement1
                g_step  := 'XML : StreetSupplement1';--log_msg(g_step);
                item_elmt := xmldom.createelement(doc, 'core:StreetSupplement1');
                item_node := xmldom.appendchild(NameAddress_node, xmldom.makenode(item_elmt));
                item_text := xmldom.createtextnode(doc, ligne.ShipTo_supp1);
                item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text)); 
                --core:StreetSupplement2
                g_step  := 'XML : StreetSupplement2';--log_msg(g_step);
                item_elmt := xmldom.createelement(doc, 'core:StreetSupplement2');
                item_node := xmldom.appendchild(NameAddress_node, xmldom.makenode(item_elmt));
                item_text := xmldom.createtextnode(doc, ligne.ShipTo_supp2);
                item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text)); 
                
            --BillToParty
            g_step  := 'XML : BillToParty';--log_msg(g_step);
            item_elmt                   := xmldom.createelement(doc, 'BillToParty');
            BillToParty_node            := xmldom.appendchild(OrderParty_node, xmldom.makenode(item_elmt));
              --NameAddress
              g_step  := 'XML : NameAddress';--log_msg(g_step);
              item_elmt                   := xmldom.createelement(doc, 'core:NameAddress');
              NameAddress_node            := xmldom.appendchild(BillToParty_node, xmldom.makenode(item_elmt));
                --core:ExternalAddressID
                g_step  := 'XML : ExternalAddressID';--log_msg(g_step);
                item_elmt := xmldom.createelement(doc, 'core:ExternalAddressID');
                item_node := xmldom.appendchild(NameAddress_node, xmldom.makenode(item_elmt));
                item_text := xmldom.createtextnode(doc, ligne.BillTo_name);
                item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));  
                --core:Name1
                g_step  := 'XML : Name1';--log_msg(g_step);
                item_elmt := xmldom.createelement(doc, 'core:Name1');
                item_node := xmldom.appendchild(NameAddress_node, xmldom.makenode(item_elmt));
                item_text := xmldom.createtextnode(doc, ligne.BillTo_line1);
                item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));  
                --core:Name2
                g_step  := 'XML : Name2';--log_msg(g_step);
                item_elmt := xmldom.createelement(doc, 'core:Name2');
                item_node := xmldom.appendchild(NameAddress_node, xmldom.makenode(item_elmt));
                item_text := xmldom.createtextnode(doc, ligne.BillTo_line2);
                item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));  
                --core:Name3
                g_step  := 'XML : Name3';--log_msg(g_step);
                item_elmt := xmldom.createelement(doc, 'core:Name3');
                item_node := xmldom.appendchild(NameAddress_node, xmldom.makenode(item_elmt));
                item_text := xmldom.createtextnode(doc, ligne.BillTo_line3);
                item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));  
                --core:PostalCode
                g_step  := 'XML : PostalCode';--log_msg(g_step);
                item_elmt := xmldom.createelement(doc, 'core:PostalCode');
                item_node := xmldom.appendchild(NameAddress_node, xmldom.makenode(item_elmt));
                item_text := xmldom.createtextnode(doc, ligne.BillTo_zip);
                item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));  
                --core:City
                g_step  := 'XML : City';--log_msg(g_step);
                item_elmt := xmldom.createelement(doc, 'core:City');
                item_node := xmldom.appendchild(NameAddress_node, xmldom.makenode(item_elmt));
                item_text := xmldom.createtextnode(doc, ligne.BillTo_city);
                item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));  
              --PrimaryContact
              g_step  := 'XML : PrimaryContact';--log_msg(g_step);
              item_elmt                   := xmldom.createelement(doc, 'core:PrimaryContact');
              PrimaryContact_node         := xmldom.appendchild(BillToParty_node, xmldom.makenode(item_elmt));
                --ListOfContactNumber
                g_step  := 'XML : ListOfContactNumber';--log_msg(g_step);
                item_elmt                   := xmldom.createelement(doc, 'core:ListOfContactNumber');
                ListOfContactNumber_node    := xmldom.appendchild(PrimaryContact_node, xmldom.makenode(item_elmt));  
                  --ContactNumber
                  g_step  := 'XML : ContactNumber';--log_msg(g_step);
                  item_elmt                   := xmldom.createelement(doc, 'core:ContactNumber');
                  ContactNumber_node          := xmldom.appendchild(ListOfContactNumber_node, xmldom.makenode(item_elmt)); 
                    --ContactNumberValue
                    g_step  := 'XML : ContactNumberValue';--log_msg(g_step);
                    item_elmt := xmldom.createelement(doc, 'core:ContactNumberValue');
                    item_node := xmldom.appendchild(ContactNumber_node, xmldom.makenode(item_elmt));
                    --item_text := xmldom.createtextnode(doc, NULL);
                    --item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
                    --ContactNumberTypeCoded 
                    g_step  := 'XML : ContactNumberTypeCoded';--log_msg(g_step);
                    item_elmt := xmldom.createelement(doc, 'core:ContactNumberTypeCoded');
                    item_node := xmldom.appendchild(ContactNumber_node, xmldom.makenode(item_elmt));
                    item_text := xmldom.createtextnode(doc, cv_email);
                    item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
                  --ContactNumber
                  g_step  := 'XML : ContactNumber';--log_msg(g_step);
                  item_elmt                   := xmldom.createelement(doc, 'core:ContactNumber');
                  ContactNumber_node          := xmldom.appendchild(ListOfContactNumber_node, xmldom.makenode(item_elmt)); 
                    --ContactNumberValue
                    g_step  := 'XML : ContactNumberValue';--log_msg(g_step);
                    item_elmt := xmldom.createelement(doc, 'core:ContactNumberValue');
                    item_node := xmldom.appendchild(ContactNumber_node, xmldom.makenode(item_elmt));
                    item_text := xmldom.createtextnode(doc, ligne.BillTo_phone1);
                    item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
                    --ContactNumberTypeCoded 
                    g_step  := 'XML : ContactNumberTypeCoded';--log_msg(g_step);
                    item_elmt := xmldom.createelement(doc, 'core:ContactNumberTypeCoded');
                    item_node := xmldom.appendchild(ContactNumber_node, xmldom.makenode(item_elmt));
                    item_text := xmldom.createtextnode(doc, cv_tel);
                    item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
                  --ContactNumber
                  g_step  := 'XML : ContactNumber';--log_msg(g_step);
                  item_elmt                   := xmldom.createelement(doc, 'core:ContactNumber');
                  ContactNumber_node          := xmldom.appendchild(ListOfContactNumber_node, xmldom.makenode(item_elmt)); 
                    --ContactNumberValue
                    g_step  := 'XML : ContactNumberValue';--log_msg(g_step);
                    item_elmt := xmldom.createelement(doc, 'core:ContactNumberValue');
                    item_node := xmldom.appendchild(ContactNumber_node, xmldom.makenode(item_elmt));
                    item_text := xmldom.createtextnode(doc, ligne.BillTo_phone2);
                    item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
                    --ContactNumberTypeCoded 
                    g_step  := 'XML : ContactNumberTypeCoded';--log_msg(g_step);
                    item_elmt := xmldom.createelement(doc, 'core:ContactNumberTypeCoded');
                    item_node := xmldom.appendchild(ContactNumber_node, xmldom.makenode(item_elmt));
                    item_text := xmldom.createtextnode(doc, cv_fax);
                    item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text)); 
                  
          --OrderTermsOfDelivery--------------------------------------------------
          g_step  := 'XML : OrderTermsOfDelivery';--log_msg(g_step);
          item_elmt                     := xmldom.createelement(doc, 'OrderTermsOfDelivery');
          OrderTermsOfDelivery_node     := xmldom.appendchild(OrderHeader_node, xmldom.makenode(item_elmt));
            --core:TermsOfDeliveryDescription
            g_step  := 'XML : TermsOfDeliveryDescription';--log_msg(g_step);
            item_elmt := xmldom.createelement(doc, 'core:TermsOfDeliveryDescription');
            item_node := xmldom.appendchild(OrderTermsOfDelivery_node, xmldom.makenode(item_elmt));
            item_text := xmldom.createtextnode(doc, cv_condition_livraison);
            item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
            
          --OrderPaymentInstructions----------------------------------------------
          g_step  := 'XML : OrderPaymentInstructions';--log_msg(g_step);
          item_elmt                     := xmldom.createelement(doc, 'OrderPaymentInstructions');
          OrderPaymentInstructions_node := xmldom.appendchild(OrderHeader_node, xmldom.makenode(item_elmt));
            --PaymentTerms
            g_step  := 'XML : PaymentTerms';--log_msg(g_step);
            item_elmt                     := xmldom.createelement(doc, 'core:PaymentTerms');        
            PaymentTerms_node             := xmldom.appendchild(OrderPaymentInstructions_node, xmldom.makenode(item_elmt));
              --core:PaymentTermsNote
              g_step  := 'XML : PaymentTermsNote';--log_msg(g_step);
              item_elmt := xmldom.createelement(doc, 'core:PaymentTermsNote');
              item_node := xmldom.appendchild(PaymentTerms_node, xmldom.makenode(item_elmt));
              item_text := xmldom.createtextnode(doc, ligne.PaymentTerm);
              item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
          
            --PaymentMethod
            g_step  := 'XML : PaymentMethod';--log_msg(g_step);
            item_elmt                     := xmldom.createelement(doc, 'core:PaymentMethod');        
            PaymentMethod_node            := xmldom.appendchild(OrderPaymentInstructions_node, xmldom.makenode(item_elmt));
              --core:PaymentMeanCoded
              g_step  := 'XML : PaymentMeanCoded';--log_msg(g_step); /*TRANSCO*/
              item_elmt := xmldom.createelement(doc, 'core:PaymentMeanCoded');
              item_node := xmldom.appendchild(PaymentMethod_node, xmldom.makenode(item_elmt));
              item_text := xmldom.createtextnode(doc, ligne.PaymentMethod);
              item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
            
        
          --OrderIssueDate--------------------------------------------------------
          g_step  := 'XML : OrderIssueDate';--log_msg(g_step);
          item_elmt := xmldom.createelement(doc, 'OrderIssueDate');
          item_node := xmldom.appendchild(OrderHeader_node, xmldom.makenode(item_elmt));
          item_text := xmldom.createtextnode(doc, ligne.OrderIssueDate);
          item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
          
          --OrderHeaderNote-------------------------------------------------------
          g_step  := 'XML : OrderHeaderNote';--log_msg(g_step);
          item_elmt := xmldom.createelement(doc, 'OrderHeaderNote');
          item_node := xmldom.appendchild(OrderHeader_node, xmldom.makenode(item_elmt));
          item_text := xmldom.createtextnode(doc, v_note_req_temp); --ligne.OrderHeaderNote);--YWA artf2140678 
          item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
        
        ------------------------------------------------------------------------
        --OrderDetail-----------------------------------------------------------
        ------------------------------------------------------------------------
        g_step  := 'XML : OrderDetail';--log_msg(g_step);
        item_elmt := xmldom.createelement(doc, 'OrderDetail');
        OrderDetail_node := xmldom.appendchild(root_node, xmldom.makenode(item_elmt));
          --ListOfItemDetail
          g_step  := 'XML : ListOfItemDetail';--log_msg(g_step);
          item_elmt := xmldom.createelement(doc, 'ListOfItemDetail');
          ListOfItemDetail_node := xmldom.appendchild(OrderDetail_node, xmldom.makenode(item_elmt));
          
        ------------------------------------------------------------------------
        --OrderSummary----------------------------------------------------------
        ------------------------------------------------------------------------
        g_step  := 'XML : OrderSummary';--log_msg(g_step);
        item_elmt := xmldom.createelement(doc, 'OrderSummary');
        OrderSummary_node := xmldom.appendchild(root_node, xmldom.makenode(item_elmt));
        
        /*CONSTRUCTION DES INFOS XML*/
        g_step  := 'CONSTRUCTION_XML 008 : Construction des infos xml'; log_msg(g_step);
        gr_ORDER_MAIL.ORDER_NUMBER   := ligne.BuyerOrderNumber;
        gr_ORDER_MAIL.ORDER_DATE     := ligne.OrderIssueDate;
        gr_ORDER_MAIL.SOC_NAME       := ligne.soc_name;--YWA artf2140586
        gr_ORDER_MAIL.SOC_NUM        := ligne.BuyerPartyIdent;
        gr_ORDER_MAIL.DEMANDEUR      := ligne.BuyerPartyDde_name;
        gr_ORDER_MAIL.DEMANDEUR_MAIL := ligne.demandeur_email_address;
        gr_ORDER_MAIL.DEMANDEUR_NUM  := ligne.BuyerPartyDde_tel;
        gr_ORDER_MAIL.ACHETEUR       := ligne.BuyerPartyAch_name;
        gr_ORDER_MAIL.ACHETEUR_MAIL  := ligne.acheteur_email_address;
        gr_ORDER_MAIL.ACHETEUR_NUM   := ligne.BuyerPartyAch_tel;
        gr_ORDER_MAIL.BILL_TO        := ligne.BillTo_name;
        gr_ORDER_MAIL.SIRET          := ligne.siret;
        gr_ORDER_MAIL.ADRESSE        := ligne.BillTo_line1 || '<br>' ||
                                        ligne.BillTo_line2 || '<br>' ||
                                        ligne.BillTo_line3 || '<br>';
        gr_ORDER_MAIL.DEVISE         := ligne.CurrencyCode;
        gr_ORDER_MAIL.INTRACOMM      := ligne.tva_intracom; 
        gr_ORDER_MAIL.ORG_NAME       := ligne.ORG_NAME;
        gr_ORDER_MAIL.VENDOR_NAME    := ligne.SellerParty_name;
        gr_ORDER_MAIL.VENDOR_SITE    := ligne.vendor_site_code;
        
        --Determination de l'expéditeur du mail
        g_step  := 'CONSTRUCTION_XML 009 : Determination de l''expéditeur du mail'; log_msg(g_step);
        gv_acheteur := nvl(ligne.acheteur_email_address,ligne.demandeur_email_address);
        
      END IF; --par commande : nvl(vn_po_header_id,-1) != ligne.po_header_id
      
      --par ligne
      ------------------------------------------------------------------------
      --ItemDetail------------------------------------------------------------
      ------------------------------------------------------------------------
      g_step  := 'XML : ItemDetail';--log_msg(g_step);
      item_elmt := xmldom.createelement(doc, 'ItemDetail');
      ItemDetail_node := xmldom.appendchild(ListOfItemDetail_node, xmldom.makenode(item_elmt));
        --BaseItemDetail----------------------------------------------------------
        g_step  := 'XML : BaseItemDetail';--log_msg(g_step);
        item_elmt := xmldom.createelement(doc, 'BaseItemDetail');
        BaseItemDetail_node := xmldom.appendchild(ItemDetail_node, xmldom.makenode(item_elmt));
          --LineItemNum
          g_step  := 'XML : LineItemNum';--log_msg(g_step);
          item_elmt := xmldom.createelement(doc, 'LineItemNum');
          BaseItemDetail_node := xmldom.appendchild(BaseItemDetail_node, xmldom.makenode(item_elmt));
            --core:BuyerLineItemNum
            g_step  := 'XML : BuyerLineItemNum';--log_msg(g_step);
            item_elmt := xmldom.createelement(doc, 'core:BuyerLineItemNum');
            item_node := xmldom.appendchild(BaseItemDetail_node, xmldom.makenode(item_elmt));
            item_text := xmldom.createtextnode(doc, ligne.BuyerLineItemNum);
            item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
          --BaseItemReferences
          g_step  := 'XML : BaseItemReferences';--log_msg(g_step);
          item_elmt := xmldom.createelement(doc, 'BaseItemReferences');
          BaseItemReferences_node := xmldom.appendchild(BaseItemDetail_node, xmldom.makenode(item_elmt));
            --core:BaseItemReferencesType
            g_step  := 'XML : BaseItemReferencesType';--log_msg(g_step);
            item_elmt := xmldom.createelement(doc, 'core:BaseItemReferencesType');
            BaseItemReferencesType_node := xmldom.appendchild(BaseItemReferences_node, xmldom.makenode(item_elmt));  
              --OffCatalogFlag
              g_step  := 'XML : OffCatalogFlag';--log_msg(g_step);
              item_elmt := xmldom.createelement(doc, 'OffCatalogFlag');
              item_node := xmldom.appendchild(BaseItemReferencesType_node, xmldom.makenode(item_elmt));
              item_text := xmldom.createtextnode(doc, ligne.CatalogFlag);
              item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
          --ItemIdentifiers
          g_step  := 'XML : ItemIdentifiers';--log_msg(g_step);
          item_elmt := xmldom.createelement(doc, 'ItemIdentifiers');
          ItemIdentifiers_node := xmldom.appendchild(BaseItemDetail_node, xmldom.makenode(item_elmt));
            --core:ItemDescription
            g_step  := 'XML : ItemDescription';--log_msg(g_step);
            item_elmt := xmldom.createelement(doc, 'core:ItemDescription');
            item_node := xmldom.appendchild(BaseItemDetail_node, xmldom.makenode(item_elmt));
            item_text := xmldom.createtextnode(doc, ligne.ItemDescription);
            item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
            --PartNumbers
            g_step  := 'XML : PartNumbers';--log_msg(g_step);
            item_elmt := xmldom.createelement(doc, 'core:PartNumbers');
            PartNumbers_node := xmldom.appendchild(ItemIdentifiers_node, xmldom.makenode(item_elmt));
              --SellerPartNumber
              g_step  := 'XML : SellerPartNumber';--log_msg(g_step);
              item_elmt := xmldom.createelement(doc, 'core:SellerPartNumber');
              SellerPartNumber_node := xmldom.appendchild(PartNumbers_node, xmldom.makenode(item_elmt));
                --core:PartID
                g_step  := 'XML : PartID';--log_msg(g_step);
                item_elmt := xmldom.createelement(doc, 'core:PartID');
                item_node := xmldom.appendchild(SellerPartNumber_node, xmldom.makenode(item_elmt));
                item_text := xmldom.createtextnode(doc, ligne.SellerPartNumber);
                item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
              --ManufacturerPartNumber
              g_step  := 'XML : ManufacturerPartNumber';--log_msg(g_step);
              item_elmt := xmldom.createelement(doc, 'core:ManufacturerPartNumber');
              ManufacturerPartNumber_node := xmldom.appendchild(PartNumbers_node, xmldom.makenode(item_elmt));
                --core:PartID
                g_step  := 'XML : PartID';--log_msg(g_step);
                item_elmt := xmldom.createelement(doc, 'core:PartID');
                item_node := xmldom.appendchild(ManufacturerPartNumber_node, xmldom.makenode(item_elmt));
                item_text := xmldom.createtextnode(doc, vv_manufacturer_part_num/*JJA 29/01/2014*/);
                item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
          --TotalQuantity
          g_step  := 'XML : TotalQuantity';--log_msg(g_step);
          item_elmt := xmldom.createelement(doc, 'TotalQuantity');
          TotalQuantity_node := xmldom.appendchild(BaseItemDetail_node, xmldom.makenode(item_elmt));
            --core:QuantityValue
            g_step  := 'XML : QuantityValue';--log_msg(g_step);
            item_elmt := xmldom.createelement(doc, 'core:QuantityValue');
            item_node := xmldom.appendchild(TotalQuantity_node, xmldom.makenode(item_elmt));
            item_text := xmldom.createtextnode(doc, ligne.Quantity);
            item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
            --UnitOfMeasurement
            g_step  := 'XML : UnitOfMeasurement';--log_msg(g_step);
            item_elmt := xmldom.createelement(doc, 'core:UnitOfMeasurement');
            UnitOfMeasurement_node := xmldom.appendchild(TotalQuantity_node, xmldom.makenode(item_elmt));
              --core:UOMCoded
              g_step  := 'XML : UnitOfMeasurement';--log_msg(g_step); /*TRANSCO*/
              item_elmt := xmldom.createelement(doc, 'core:UOMCoded');
              item_node := xmldom.appendchild(UnitOfMeasurement_node, xmldom.makenode(item_elmt));
              item_text := xmldom.createtextnode(doc, ligne.UnitOfMeasurement);
              item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
          
        --PricingDetail-----------------------------------------------------------
        g_step  := 'XML : PricingDetail';--log_msg(g_step);
        item_elmt := xmldom.createelement(doc, 'PricingDetail');
        PricingDetail_node := xmldom.appendchild(ItemDetail_node, xmldom.makenode(item_elmt));
          --ListOfPrice
          g_step  := 'XML : ListOfPrice';--log_msg(g_step);
          item_elmt := xmldom.createelement(doc, 'core:ListOfPrice');
          ListOfPrice_node := xmldom.appendchild(PricingDetail_node, xmldom.makenode(item_elmt));
            --Price
            g_step  := 'XML : Price';--log_msg(g_step);
            item_elmt := xmldom.createelement(doc, 'core:Price');
            Price_node := xmldom.appendchild(ListOfPrice_node, xmldom.makenode(item_elmt));
              --UnitPrice
              g_step  := 'XML : UnitPrice';--log_msg(g_step);
              item_elmt := xmldom.createelement(doc, 'core:UnitPrice');
              UnitPrice_node := xmldom.appendchild(Price_node, xmldom.makenode(item_elmt));
                --core:UnitPriceValue
                g_step  := 'XML : UnitPriceValue';--log_msg(g_step);
                item_elmt := xmldom.createelement(doc, 'core:UnitPriceValue');
                item_node := xmldom.appendchild(UnitPrice_node, xmldom.makenode(item_elmt));
                item_text := xmldom.createtextnode(doc, nvl(rtrim(rtrim(trim(' ' FROM to_char(round(ligne.UnitPrice,2),'999999999999999.999999')),'0'),'.'),0));
                item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
              --UnitOfMeasurement
              g_step  := 'XML : UnitOfMeasurement';--log_msg(g_step);
              item_elmt := xmldom.createelement(doc, 'core:UnitOfMeasurement');
              UnitOfMeasurement_node := xmldom.appendchild(Price_node, xmldom.makenode(item_elmt));
                --core:UOMCoded
                g_step  := 'XML : UOMCoded';--log_msg(g_step); /*TRANSCO*/
                item_elmt := xmldom.createelement(doc, 'core:UOMCoded');
                item_node := xmldom.appendchild(UnitOfMeasurement_node, xmldom.makenode(item_elmt));
                item_text := xmldom.createtextnode(doc, ligne.UnitOfMeasurement);
                item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
              --PriceMultiplier
              g_step  := 'XML : PriceMultiplier';--log_msg(g_step);
              item_elmt := xmldom.createelement(doc, 'core:PriceMultiplier');
              PriceMultiplier_node := xmldom.appendchild(Price_node, xmldom.makenode(item_elmt));
                --core:Multiplier
                g_step  := 'XML : Multiplier';--log_msg(g_step);
                item_elmt := xmldom.createelement(doc, 'core:Multiplier');
                item_node := xmldom.appendchild(PriceMultiplier_node, xmldom.makenode(item_elmt));
                item_text := xmldom.createtextnode(doc, cn_multiplier);
                item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
              
          --LineItemTotal
          g_step  := 'XML : LineItemTotal';--log_msg(g_step);
          item_elmt := xmldom.createelement(doc, 'core:LineItemTotal');
          LineItemTotal_node := xmldom.appendchild(PricingDetail_node, xmldom.makenode(item_elmt));
            --core:MonetaryAmount
            g_step  := 'XML : MonetaryAmount';--log_msg(g_step);
            item_elmt := xmldom.createelement(doc, 'core:MonetaryAmount');
            item_node := xmldom.appendchild(LineItemTotal_node, xmldom.makenode(item_elmt));
            item_text := xmldom.createtextnode(doc,nvl(rtrim(rtrim(trim(' ' FROM to_char(round(ligne.LineAmount,2),'999999999999999.999999')),'0'),'.'),0));
            item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
          
        --DeliveryDetail----------------------------------------------------------
        g_step  := 'XML : DeliveryDetail';--log_msg(g_step);
        item_elmt := xmldom.createelement(doc, 'DeliveryDetail');
        DeliveryDetail_node := xmldom.appendchild(ItemDetail_node, xmldom.makenode(item_elmt));
          --ShipToLocation
          g_step  := 'XML : ShipToLocation';--log_msg(g_step);
          item_elmt := xmldom.createelement(doc, 'core:ShipToLocation');
          ShipToLocation_node := xmldom.appendchild(DeliveryDetail_node, xmldom.makenode(item_elmt));
            --NameAddress
            g_step  := 'XML : NameAddress';--log_msg(g_step);
            item_elmt                   := xmldom.createelement(doc, 'core:NameAddress');
            NameAddress_node            := xmldom.appendchild(ShipToLocation_node, xmldom.makenode(item_elmt));
              --core:ExternalAddressID
              g_step  := 'XML : ExternalAddressID';--log_msg(g_step);
              item_elmt := xmldom.createelement(doc, 'core:ExternalAddressID');
              item_node := xmldom.appendchild(NameAddress_node, xmldom.makenode(item_elmt));
              item_text := xmldom.createtextnode(doc, ligne.ShipToLine_name);
              item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));  
              --core:Name1
              g_step  := 'XML : Name1';--log_msg(g_step);
              item_elmt := xmldom.createelement(doc, 'core:Name1');
              item_node := xmldom.appendchild(NameAddress_node, xmldom.makenode(item_elmt));
              item_text := xmldom.createtextnode(doc, ligne.ShipToLine_line1);
              item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));  
              --core:Name2
              g_step  := 'XML : Name2';--log_msg(g_step);
              item_elmt := xmldom.createelement(doc, 'core:Name2');
              item_node := xmldom.appendchild(NameAddress_node, xmldom.makenode(item_elmt));
              item_text := xmldom.createtextnode(doc, ligne.ShipToLine_line2);
              item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));  
              --core:Name3
              g_step  := 'XML : Name3';--log_msg(g_step);
              item_elmt := xmldom.createelement(doc, 'core:Name3');
              item_node := xmldom.appendchild(NameAddress_node, xmldom.makenode(item_elmt));
              item_text := xmldom.createtextnode(doc, ligne.ShipToLine_line3);
              item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));  
              --core:Street
              g_step  := 'XML : Street';--log_msg(g_step);
              item_elmt := xmldom.createelement(doc, 'core:Street');
              item_node := xmldom.appendchild(NameAddress_node, xmldom.makenode(item_elmt));
              item_text := xmldom.createtextnode(doc, ligne.ShipToLine_zip_city);
              item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));  
              --core:HouseNumber
              g_step  := 'XML : HouseNumber';--log_msg(g_step);
              item_elmt := xmldom.createelement(doc, 'core:HouseNumber');
              item_node := xmldom.appendchild(NameAddress_node, xmldom.makenode(item_elmt));
              item_text := xmldom.createtextnode(doc, ligne.ShipToLine_phone);
              item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text)); 
              --core:StreetSupplement1
              g_step  := 'XML : StreetSupplement1';--log_msg(g_step);
              item_elmt := xmldom.createelement(doc, 'core:StreetSupplement1');
              item_node := xmldom.appendchild(NameAddress_node, xmldom.makenode(item_elmt));
              item_text := xmldom.createtextnode(doc, ligne.ShipToLine_supp1);
              item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text)); 
              --core:StreetSupplement2
              g_step  := 'XML : StreetSupplement2';--log_msg(g_step);
              item_elmt := xmldom.createelement(doc, 'core:StreetSupplement2');
              item_node := xmldom.appendchild(NameAddress_node, xmldom.makenode(item_elmt));
              item_text := xmldom.createtextnode(doc, ligne.ShipToLine_supp2);
              item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text)); 
            --LocationIdentifier
            g_step  := 'XML : LocationIdentifier';--log_msg(g_step);
            item_elmt                   := xmldom.createelement(doc, 'core:LocationIdentifier');
            LocationIdentifier_node     := xmldom.appendchild(ShipToLocation_node, xmldom.makenode(item_elmt));
              --core:LocID
              g_step  := 'XML : LocID';--log_msg(g_step);
              item_elmt                   := xmldom.createelement(doc, 'core:LocID');
              LocID_node                  := xmldom.appendchild(LocationIdentifier_node, xmldom.makenode(item_elmt));
                --core:Ident
                g_step  := 'XML : Ident';--log_msg(g_step);
                item_elmt := xmldom.createelement(doc, 'core:Ident');
                item_node := xmldom.appendchild(LocID_node, xmldom.makenode(item_elmt));
                item_text := xmldom.createtextnode(doc, vv_adresse_occ );
                item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text)); 
              --core:LocationDescription
              g_step  := 'XML : LocationDescription';--log_msg(g_step);
              item_elmt := xmldom.createelement(doc, 'core:LocationDescription');
              item_node := xmldom.appendchild(LocationIdentifier_node, xmldom.makenode(item_elmt));
              item_text := xmldom.createtextnode(doc, vv_adresse );
              item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text)); 
          --ListOfScheduleLine
          g_step  := 'XML : ListOfScheduleLine';--log_msg(g_step);
          item_elmt := xmldom.createelement(doc, 'core:ListOfScheduleLine');
          ListOfScheduleLine_node := xmldom.appendchild(DeliveryDetail_node, xmldom.makenode(item_elmt));
            --ScheduleLine
            g_step  := 'XML : ScheduleLine';--log_msg(g_step);
            item_elmt := xmldom.createelement(doc, 'core:ScheduleLine');
            ScheduleLine_node := xmldom.appendchild(ListOfScheduleLine_node, xmldom.makenode(item_elmt));
              --core:RequestedDeliveryDate
              g_step  := 'XML : RequestedDeliveryDate';--log_msg(g_step);
              item_elmt := xmldom.createelement(doc, 'core:RequestedDeliveryDate');
              item_node := xmldom.appendchild(ScheduleLine_node, xmldom.makenode(item_elmt));
              item_text := xmldom.createtextnode(doc, ligne.RequestDeliveryDate_line);
              item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
          
        --LineItemNote------------------------------------------------------------
        g_step  := 'XML : LineItemNote';--log_msg(g_step);
        item_elmt := xmldom.createelement(doc, 'LineItemNote');
        item_node := xmldom.appendchild(ItemDetail_node, xmldom.makenode(item_elmt));
        item_text := xmldom.createtextnode(doc, vv_text_l);
        item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
        
        -->JJA 11/12/2014
        --SpecialHandling---------------------------------------------------------
        g_step  := 'XML : SpecialHandling';--log_msg(g_step);
        item_elmt := xmldom.createelement(doc, 'core:SpecialHandlingType');
        SpecialHandling_node := xmldom.appendchild(ItemDetail_node, xmldom.makenode(item_elmt));
          --core:SpecialHandlingCodedOther
          g_step  := 'XML : SpecialHandlingCodedOther';--log_msg(g_step);
          item_elmt := xmldom.createelement(doc, 'SpecialHandlingCodedOther');
          item_node := xmldom.appendchild(SpecialHandling_node, xmldom.makenode(item_elmt));
          item_text := xmldom.createtextnode(doc, vv_special_handling);
          item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
        --<JJA 11/12/2014

        -->RBE 27/04/2018
        --ListOfNameValueSet---------------------------------------------------------
        g_step  := 'XML : ListOfNameValueSet';--log_msg(g_step);
        item_elmt := xmldom.createelement(doc, 'ListOfNameValueSet');
        ListOfNameValueSet_node := xmldom.appendchild(ItemDetail_node, xmldom.makenode(item_elmt));
          --core:NameValueSet
          g_step  := 'XML : core:NameValueSet';--log_msg(g_step);
          item_elmt := xmldom.createelement(doc, 'core:NameValueSet');
          NameValueSet_node := xmldom.appendchild(ListOfNameValueSet_node, xmldom.makenode(item_elmt));

              --core:SetName
              g_step  := 'XML : core:SetName';--log_msg(g_step);
              item_elmt := xmldom.createelement(doc, 'core:SetName');
              SetName_node := xmldom.appendchild(NameValueSet_node, xmldom.makenode(item_elmt));
              item_text := xmldom.createtextnode(doc, 'CodeDI');
              SetName_node := xmldom.appendchild(SetName_node, xmldom.makenode(item_text));
          
              --core:ListOfNameValuePair
              g_step  := 'XML : core:ListOfNameValuePair';--log_msg(g_step);
              item_elmt := xmldom.createelement(doc, 'core:ListOfNameValuePair');
              ListOfNameValuePair_node := xmldom.appendchild(NameValueSet_node, xmldom.makenode(item_elmt));
                        
                  g_step  := 'XML : core:NameValuePair';--log_msg(g_step);
                  item_elmt := xmldom.createelement(doc, 'core:NameValuePair');
                  NameValuePair_node := xmldom.appendchild(ListOfNameValuePair_node, xmldom.makenode(item_elmt));
                  
                      g_step  := 'XML : core:Name';--log_msg(g_step);
                      item_elmt := xmldom.createelement(doc, 'core:Name');
                      item_node := xmldom.appendchild(NameValuePair_node, xmldom.makenode(item_elmt));
                      item_text := xmldom.createtextnode(doc, 'CodeDI');
                      item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
                      
                      g_step  := 'XML : core:Value';--log_msg(g_step);
                      item_elmt := xmldom.createelement(doc, 'core:Value');
                      item_node := xmldom.appendchild(NameValuePair_node, xmldom.makenode(item_elmt));
                      item_text := xmldom.createtextnode(doc, ligne.codeDI);
                      item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
                      
        --<RBE 27/04/2018
        
        --CALCUL MONTANT DE LA COMMANDE
        vn_amount := vn_amount + ligne.lineAmount;
        
    END LOOP;
 
    g_step  := 'CONSTRUCTION_XML 003 : fin nouvelle ligne';
    log_msg(g_step);
    
    --Affectation du montant
    gr_ORDER_MAIL.MONTANT := rtrim(rtrim(trim(' ' FROM to_char(round(vn_amount,2),'999999999999999.999999')),'0'),'.');
    
    --Fin de la commande
    --OrderTotal
    g_step  := 'XML : OrderTotal';--log_msg(g_step);
    item_elmt := xmldom.createelement(doc, 'OrderTotal');
    OrderTotal_node := xmldom.appendchild(OrderSummary_node, xmldom.makenode(item_elmt));
      --MonetaryAmount
      g_step  := 'XML : MonetaryAmount';--log_msg(g_step);
      item_elmt := xmldom.createelement(doc, 'core:MonetaryAmount');
      item_node := xmldom.appendchild(OrderTotal_node, xmldom.makenode(item_elmt));
      item_text := xmldom.createtextnode(doc, nvl(gr_ORDER_MAIL.MONTANT,0) );
      item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
      --Currency
      g_step  := 'XML : Currency';--log_msg(g_step);
      item_elmt := xmldom.createelement(doc, 'core:Currency');
      Currency_node := xmldom.appendchild(OrderTotal_node, xmldom.makenode(item_elmt));
        --CurrencyCoded
        g_step  := 'XML : CurrencyCoded';--log_msg(g_step); /*TRANSCO*/
        item_elmt := xmldom.createelement(doc, 'core:CurrencyCoded');
        item_node := xmldom.appendchild(Currency_node, xmldom.makenode(item_elmt));
        item_text := xmldom.createtextnode(doc, vv_currencycode);
        item_node := xmldom.appendchild(item_node, xmldom.makenode(item_text));
    
    --Fichier de sortie
    -- info : le gv_directory_path doit etre DECLARE dans l'utl_file_dir
    gv_xml_file := gv_directory_path||'/'||
                   cv_prefixe||gv_order_number||'_'||to_char(SYSDATE,'YYYYMMDDHH24MISS')||'.xml';
    
    g_step  := 'CONSTRUCTION_XML 010 : WRITETOFILE : '||gv_xml_file;
    log_msg(g_step);
    
    xmldom.writetofile(doc, gv_xml_file,'UTF-8');
    xmldom.freedocument(doc);
    
    g_step  := 'CONSTRUCTION_XML 999 : FIN';
    log_msg(g_step);
    
  EXCEPTION
   WHEN OTHERS THEN
    p_errbuf  := 'Erreur procedure CONSTRUCTION_XML :'||
                 g_step ||chr(10)||SQLERRM;
    log_msg(p_errbuf);
    p_retcode := 2;
  END construction_xml;
  
  
  -----------------------------------------------------------------
  --  Nom           : SEND_MAIL_REF
  --  Description   : procedure d'envoi de mail à la plateforme 
  --                  d'appro pour information
  --
  --  PARAMETRES :
  --
  --
  -----------------------------------------------------------------
  PROCEDURE send_mail_ref(pv_message_objet VARCHAR2,
                          pv_message_corps VARCHAR2,
                          pv_destinataire  VARCHAR2
                          ) IS
    
   l_conn     UTL_SMTP.CONNECTION;
   l_mesg     VARCHAR2( 4000 );
   
   vr_reply    UTL_SMTP.REPLY;
   vr_replies  UTL_SMTP.REPLIES;
   
   vv_subject  VARCHAR2(500);
   vv_body     VARCHAR2(500);
   
  BEGIN
    g_step  := 'SEND_MAIL_REF 000 : DEBUT';
    log_msg(g_step);
    
    --CONSTRUCTION DES MESSAGES
    --SUJET
    g_step  := 'SEND_MAIL_REF 001 : Définition du sujet';
    vv_subject := pv_message_objet;
                                            
    g_step  := 'SEND_MAIL_REF 002 : Définition du sujet';
    vv_body    := pv_message_corps;
                                            
    g_step  := 'SEND_MAIL_REF 003 : Connexion'; log_msg(g_step);
    vr_reply := utl_smtp.open_connection( gv_conn, 25, l_conn);
    utl_smtp.ehlo( l_conn , gv_conn );
    vr_reply := utl_smtp.mail( l_conn , gv_expediteur );
    vr_reply := utl_smtp.rcpt( l_conn , '<'||pv_destinataire||'>' );
    
    g_step  := 'SEND_MAIL_REF 004 : Ouverture/Ecriture des datas'; log_msg(g_step);
    utl_smtp.open_data(l_conn);
    l_mesg:=  'Date: ' || to_char(systimestamp, 'dd Mon yyyy hh24:mi:ss tzhtzm','NLS_DATE_LANGUAGE=American') || utl_tcp.CRLF ||
              'From: ' || gv_expediteur || utl_tcp.CRLF ||
              'To: ' || pv_destinataire || utl_tcp.CRLF ||
              'Subject: ' || vv_subject || utl_tcp.CRLF ||
              'MIME-Version: 1.0' || utl_tcp.CRLF ||
              'Content-Type: '|| MULTIPART_MIME_TYPE || utl_tcp.CRLF || utl_tcp.CRLF
              ;
    utl_smtp.write_data(l_conn, l_mesg);
    
    -- Insertion du corps du message
    g_step  := 'SEND_MAIL_REF 005 : Insertion du corps du message'; log_msg(g_step);
    BEGIN
      begin_attachment(conn => l_conn,
                       mime_type => 'text/html' );
      utl_smtp.write_data(l_conn, vv_body);
      end_attachment(conn => l_conn );
    END;
    
    g_step  := 'SEND_MAIL_REF 006 : Fermeture des attachements'; log_msg(g_step);
    end_attachment(conn => l_conn , last=> TRUE );
    
    --Envoi du mail
    g_step  := 'SEND_MAIL_REF 007 : Envoi du mail'; log_msg(g_step);
    vr_reply := utl_smtp.close_data(l_conn);
    vr_reply := utl_smtp.quit( l_conn );                                          
    
    g_step  := 'SEND_MAIL_REF 999 : FIN';
    log_msg(g_step);
    
  EXCEPTION
    WHEN OTHERS THEN  
      g_step  := 'REPLY : '||vr_reply.code || ' - ' ||vr_reply.text; 
      log_msg(g_step);
      
      g_step  := 'Erreur procedure SEND_MAIL_REF :'||
                 g_step ||chr(10)||SQLERRM;
      log_msg(g_step);
  END send_mail_ref;
  
  -----------------------------------------------------------------
  --  Nom           : ENVOI_MAIL
  --  Description   : procedure d'envoi de mail
  --
  --  PARAMETRES :
  --
  --
  -----------------------------------------------------------------
  PROCEDURE envoi_mail(p_errbuf        OUT VARCHAR2,
                       p_retcode       OUT NUMBER) IS
   
   l_mesg     VARCHAR2( 4000 );
   l_conn     UTL_SMTP.CONNECTION;
   l_file     BFILE;
   l_file_len PLS_INTEGER;
   l_modulo   PLS_INTEGER;
   l_pieces   PLS_INTEGER;
   l_filepos  PLS_INTEGER := 1; /* pointeur pour le fichier */
   l_buf      RAW(2100);
   l_data     RAW(2100);
   l_chunks   PLS_INTEGER;  
   
   vv_file_name  VARCHAR2(500);
   vv_repertoire VARCHAR2(500);
   vv_extension  VARCHAR2(50);
   
   vr_reply    UTL_SMTP.REPLY;
   vr_replies  UTL_SMTP.REPLIES;
   
   vv_mail_fournisseur      po_vendor_sites_all.email_address%TYPE;
   
   e_adresse_fournisseur    EXCEPTION;
   e_adresse_acheteur       EXCEPTION;
   
  BEGIN
    --Init des variables de sortie
    p_retcode := 0;
    p_errbuf  := '';
    
    g_step  := 'ENVOI_MAIL 000 : DEBUT';
    log_msg(g_step);
    
    --CONSTRUCTION DES MESSAGES
    --SUJET
    g_step  := 'ENVOI_MAIL 001 : Définition du sujet';
    
    gv_subject := Dka_Tools_Pkg.get_message('DKA','DKA_SPOBON_XML_MAIL_SUJET',
                                            'ORG',gr_ORDER_MAIL.ORG_NAME,
                                            'SOC_NAME',gr_ORDER_MAIL.SOC_NAME,
                                            'ORDER_NUM',gr_ORDER_MAIL.ORDER_NUMBER);
    
    --CORPS
    BEGIN
      g_step  := 'ENVOI_MAIL 003 : Définition du corps';log_msg(g_step);
      Fnd_Message.set_name ('DKA', 'DKA_SPOBON_XML_MAIL_CORPS');
      Fnd_Message.set_token ('ORDER_NUMBER'  , gr_ORDER_MAIL.ORDER_NUMBER);
      Fnd_Message.set_token ('ORDER_DATE'    , gr_ORDER_MAIL.ORDER_DATE);
      Fnd_Message.set_token ('SOC_NAME'      , gr_ORDER_MAIL.SOC_NAME);
      Fnd_Message.set_token ('SOC_NUM'       , gr_ORDER_MAIL.SOC_NUM);
      Fnd_Message.set_token ('DEMANDEUR'     , gr_ORDER_MAIL.DEMANDEUR);
      Fnd_Message.set_token ('DDE_MAIL'      , gr_ORDER_MAIL.DEMANDEUR_MAIL);
      Fnd_Message.set_token ('DDE_TEL'       , gr_ORDER_MAIL.DEMANDEUR_NUM);
      --Fnd_Message.set_token ('ACHETEUR'      , gr_ORDER_MAIL.ACHETEUR); -- OBE artf3024627
      --Fnd_Message.set_token ('ACH_MAIL'      , gr_ORDER_MAIL.ACHETEUR_MAIL); -- OBE artf3024627
      --Fnd_Message.set_token ('ACH_TEL'       , gr_ORDER_MAIL.ACHETEUR_NUM); -- OBE artf3024627
      Fnd_Message.set_token ('BILL_TO'       , gr_ORDER_MAIL.BILL_TO);
      Fnd_Message.set_token ('SIRET'         , gr_ORDER_MAIL.SIRET);
      Fnd_Message.set_token ('ADRESSE'       , gr_ORDER_MAIL.ADRESSE);
      Fnd_Message.set_token ('MONTANT'       , gr_ORDER_MAIL.MONTANT);
      Fnd_Message.set_token ('DEVISE'        , gr_ORDER_MAIL.DEVISE);
      Fnd_Message.set_token ('INTRACOMM'     , gr_ORDER_MAIL.INTRACOMM);
      gv_body := Fnd_Message.get;
    
    EXCEPTION
     WHEN OTHERS THEN
      p_errbuf  := 'Erreur Récupération du corps' ||chr(10)||SQLERRM;
      gv_body   := NULL;
    END; 
    
    g_step  := 'ENVOI_MAIL 002 : VERIFICATION BASE';
    log_msg(g_step);
    IF gv_base != gv_base_prod THEN
      --BASE DE DEVELOPPEMENT
      gv_acheteur         := gv_test_exp;
      vv_mail_fournisseur := gv_test_dest;
      gv_subject          := '[TEST] '||gv_subject;
    ELSE
      vv_mail_fournisseur := gv_mail_fournisseur;
    END IF;
    
    IF vv_mail_fournisseur IS NULL THEN
      g_step  := 'ENVOI_MAIL 002b : Adresse fournisseur vide';
      log_msg(g_step);
      raise e_adresse_fournisseur;
    END IF;
    
    IF gv_acheteur IS NULL THEN
      g_step  := 'ENVOI_MAIL 002b : Adresse acheteur vide';
      log_msg(g_step);
      raise e_adresse_acheteur;
    END IF;
    
    IF     gv_body             IS NOT NULL 
       AND gv_subject          IS NOT NULL THEN      
       
      -- Création et envoi du mail
      g_step  := 'ENVOI_MAIL 003 : Connexion'; log_msg(g_step);
      vr_reply := utl_smtp.open_connection( gv_conn, 25, l_conn );
      g_step  := 'REPLY OPEN_CONNECTION : '||vr_reply.code || ' - ' ||vr_reply.text; --log_msg(g_step);
      
      g_step  := 'ENVOI_MAIL 004 : Début construction mail'; log_msg(g_step);
     
      vr_replies := utl_smtp.ehlo( l_conn , gv_conn );
      IF vr_replies.COUNT>0 THEN
       FOR i IN vr_replies.FIRST..vr_replies.LAST LOOP
         g_step  := 'REPLY EHLO '||i||' : '||vr_replies(i).code || ' - ' ||vr_replies(i).text; --log_msg(g_step);
       END LOOP;
      END IF;
      
      
      vr_reply := utl_smtp.mail( l_conn , '<'||gv_acheteur||'>'/*gv_expediteur*/ );
      g_step  := 'REPLY MAIL : '||vr_reply.code || ' - ' ||vr_reply.text; --log_msg(g_step);
      
      vr_reply := utl_smtp.rcpt( l_conn , '<'||vv_mail_fournisseur||'>' );
      g_step  := 'REPLY RCPT : '||vr_reply.code || ' - ' ||vr_reply.text; log_msg(g_step);
      
      IF vr_reply.code = '501' THEN
        --on ferme la connexion
        vr_reply := utl_smtp.quit( l_conn ); 
        g_step  := 'REPLY QUIT : '||vr_reply.code || ' - ' ||vr_reply.text; -- log_msg(g_step);
      
        raise e_adresse_fournisseur;
      END IF;
        
      vr_reply := utl_smtp.open_data(l_conn);
      g_step  := 'REPLY OPEN_DATA : '||vr_reply.code || ' - ' ||vr_reply.text;  --log_msg(g_step);
      
      l_mesg:=  'Date: ' || to_char(systimestamp, 'dd Mon yyyy hh24:mi:ss tzhtzm','NLS_DATE_LANGUAGE=American') || utl_tcp.CRLF ||
                'From: ' || /*gv_acheteur*/gv_expediteur || utl_tcp.CRLF ||
                'To: ' || vv_mail_fournisseur || utl_tcp.CRLF ||
                'Subject: ' || gv_subject || utl_tcp.CRLF ||
                'Reply-To: ' || gv_plat_appro_mail || utl_tcp.CRLF ||
                'Return-Path: ' || gv_plat_appro_mail || utl_tcp.CRLF ||
                'MIME-Version: 1.0' || utl_tcp.CRLF ||
                'Content-Type: '|| MULTIPART_MIME_TYPE || utl_tcp.CRLF || utl_tcp.CRLF
                ;
      utl_smtp.write_data(l_conn, l_mesg);
      
      -- Insertion du corps du message
      g_step  := 'ENVOI_MAIL 005 : Insertion du corps du message'; log_msg(g_step);
      BEGIN
        begin_attachment(conn => l_conn,
                         mime_type => 'text/html' );
        utl_smtp.write_data(l_conn, gv_body);
        end_attachment(conn => l_conn );
      END;
      
      --------------------------------------------------------------------------
      -- Insertion du PDF
      --------------------------------------------------------------------------
      IF gv_pdf_file IS NOT NULL THEN
        g_step  := 'ENVOI_MAIL 006 : Pièce jointe : '||gv_pdf_file; log_msg(g_step);
        vv_file_name  := substr(gv_pdf_file,instr(gv_pdf_file,'/',-1)+1); 
        vv_repertoire := substr(gv_pdf_file,1,instr(gv_pdf_file,'/',-1)-1);
        l_filepos := 1;
        gn_amt    := 672 * 3;
        BEGIN
          begin_attachment(conn => l_conn,
                           mime_type => 'application/pdf',
                           inline => TRUE,
                           filename => cv_prefixe||gv_order_number||'.pdf', 
                           transfer_enc => 'base64');
          
          BEGIN
            l_file := BFILENAME('DALKIA_LOADBDC',vv_file_name); 
            l_file_len := dbms_lob.getlength(l_file);
            l_modulo := mod(l_file_len, gn_amt);
            l_pieces := trunc(l_file_len / gn_amt);
            l_buf := NULL;
            
            IF (l_modulo <> 0) THEN
              l_pieces := l_pieces + 1;
            END IF;
            
            dbms_lob.fileopen(l_file, dbms_lob.file_readonly);
            dbms_lob.read(l_file, gn_amt, l_filepos, l_buf);
            l_data := NULL;
            
            FOR i IN 1..l_pieces LOOP
              l_filepos := i * gn_amt + 1;
              l_file_len := l_file_len - gn_amt;
              l_data := utl_raw.concat(l_data, l_buf);
              l_chunks := trunc(utl_raw.length(l_data) / MAX_LINE_WIDTH);
              
              IF (i <> l_pieces) THEN
                l_chunks := l_chunks - 1;
              END IF;
              
              utl_smtp.write_raw_data( l_conn, utl_encode.base64_encode(l_data ) );
              l_data := NULL;
              
              IF (l_file_len < gn_amt AND l_file_len > 0) THEN
                gn_amt := l_file_len;
              END IF;
              
              IF l_pieces > 1 THEN
                dbms_lob.read(l_file, gn_amt, l_filepos, l_buf);
              END IF;
            END LOOP;
            
          END;
          dbms_lob.fileclose(l_file);
          
          end_attachment(conn => l_conn );
          
        END; -- Fin de l'insertion de la pièce jointe
      END IF;
      
      --------------------------------------------------------------------------
      -- Insertion du fichier XML
      --------------------------------------------------------------------------
      IF gv_xml_file IS NOT NULL THEN
        g_step  := 'ENVOI_MAIL 007 : Pièce jointe : '||gv_xml_file; log_msg(g_step);
        vv_file_name  := substr(gv_xml_file,instr(gv_xml_file,'/',-1)+1); 
        vv_repertoire := substr(gv_xml_file,1,instr(gv_xml_file,'/',-1)-1);
        l_filepos := 1;
        gn_amt    := 672 * 3;
		
		g_step  := 'INIT 007 : Org_id est :'||gn_org_id; --AAM INC0361005 :  Ajout des traces
        log_msg(g_step);                                 --AAM INC0361005 :  Ajout des traces
		
        BEGIN
		  g_step  := 'ENVOI_MAIL 007-1 : Appel à begin_attachment';  --AAM INC0361005 :  Ajout des traces
		  log_msg(g_step);                                           --AAM INC0361005 :  Ajout des traces
          begin_attachment(conn => l_conn,
                           mime_type => 'text/xml',
                           inline => TRUE,
                           filename => vv_file_name, 
                           transfer_enc => 'base64');
						   
          g_step  := 'ENVOI_MAIL 007-2 :Fin Appel à begin_attachment'; --AAM INC0361005 :  Ajout des traces
		  log_msg(g_step);                                             --AAM INC0361005 :  Ajout des traces
		
          BEGIN
		    g_step  := 'ENVOI_MAIL 007-3 : Récupération des informations du fichier';  --AAM INC0361005 :  Ajout des traces
		    log_msg(g_step); 
			
            l_file := BFILENAME('DKA_OUT_DIR',vv_file_name);
            l_file_len := dbms_lob.getlength(l_file);
            l_modulo := mod(l_file_len, gn_amt);
            l_pieces := trunc(l_file_len / gn_amt);
            l_buf := NULL;
            
            IF (l_modulo <> 0) THEN
              l_pieces := l_pieces + 1;
            END IF;
            
			g_step  := 'ENVOI_MAIL 007-4 : Ouverture Fichier';  --AAM INC0361005 :  Ajout des traces
		    log_msg(g_step);                                    --AAM INC0361005 :  Ajout des traces
			
            dbms_lob.fileopen(l_file, dbms_lob.file_readonly);
            dbms_lob.read(l_file, gn_amt, l_filepos, l_buf);
            l_data := NULL;
            
            FOR i IN 1..l_pieces LOOP
			  g_step  := 'ENVOI_MAIL 007-5 : Entree de la boucle'; --AAM INC0361005 :  Ajout des traces
		      log_msg(g_step);                                     --AAM INC0361005 :  Ajout des traces
			  
              l_filepos := i * gn_amt + 1;
              l_file_len := l_file_len - gn_amt;
              l_data := utl_raw.concat(l_data, l_buf);
              l_chunks := trunc(utl_raw.length(l_data) / MAX_LINE_WIDTH);
              
              IF (i <> l_pieces) THEN
                l_chunks := l_chunks - 1;
              END IF;
              
			  g_step  := 'ENVOI_MAIL 007-6 : Appel à utl_smtp.write_raw_data'; --AAM INC0361005 :  Ajout des traces
		      log_msg(g_step);                                                 --AAM INC0361005 :  Ajout des traces
			  
              utl_smtp.write_raw_data( l_conn, utl_encode.base64_encode(l_data ) );
			  
			  g_step  := 'ENVOI_MAIL 007-7 : Fin Appel à utl_smtp.write_raw_data';  --AAM INC0361005 :  Ajout des traces
		      log_msg(g_step);                                                      --AAM INC0361005 :  Ajout des traces
			  
              l_data := NULL;
              			  
			  g_step  := 'ENVOI_MAIL 007-8 : Test de la longueur du fichier';  --AAM INC0361005 :  Ajout des traces
		      log_msg(g_step);                                                 --AAM INC0361005 :  Ajout des traces
			  
              IF (l_file_len < gn_amt AND l_file_len > 0) THEN
                gn_amt := l_file_len;
              END IF;
              
			  g_step  := 'ENVOI_MAIL 007-9 : test sur la variable l_pieces ';  --AAM INC0361005 :  Ajout des traces
		      log_msg(g_step);                                                 --AAM INC0361005 :  Ajout des traces 
			  
              IF l_pieces > 1 THEN
                dbms_lob.read(l_file, gn_amt, l_filepos, l_buf);
              END IF;
            END LOOP;
            
          END;
		  
		  g_step  := 'ENVOI_MAIL 007-10 : Fermeture fichier'; --AAM INC0361005 :  Ajout des traces
		  log_msg(g_step);                                    --AAM INC0361005 :  Ajout des traces
		  
          dbms_lob.fileclose(l_file);
          
		  g_step  := 'ENVOI_MAIL 007-11 : Appel à end_attachment';  --AAM INC0361005 :  Ajout des traces
		  log_msg(g_step);                                          --AAM INC0361005 :  Ajout des traces
		  
          end_attachment(conn => l_conn );
		  
		  g_step  := 'ENVOI_MAIL 007-12 : Fin Appel à end_attachment'; --AAM INC0361005 :  Ajout des traces
		  log_msg(g_step);                                             --AAM INC0361005 :  Ajout des traces
          
        END; -- Fin de l'insertion de la pièce jointe
      END IF;
      
      --------------------------------------------------------------------------
      -- Récupération des doc joint : TEXTE ENTETE CDE - FOURN - DA
      --------------------------------------------------------------------------
      --IF nvl(gn_piece_jointe,0) != 0 AND gv_order_header_note IS NOT NULL THEN
      IF gv_order_header_note IS NOT NULL THEN
        g_step  := 'ENVOI_MAIL 008 : Pièce jointe : '||gv_order_header_note; log_msg(g_step);
        vv_file_name  := substr(gv_order_header_note,instr(gv_order_header_note,'/',-1)+1); 
        vv_repertoire := substr(gv_order_header_note,1,instr(gv_order_header_note,'/',-1)-1);
        l_filepos := 1;
        gn_amt    := 672 * 3;
        BEGIN
          begin_attachment(conn => l_conn,
                           mime_type => 'text/plain',
                           inline => TRUE,
                           filename => vv_file_name, 
                           transfer_enc => 'base64');
          
          BEGIN
            l_file := BFILENAME('DKA_OUT_DIR',vv_file_name);
            l_file_len := dbms_lob.getlength(l_file);
            l_modulo := mod(l_file_len, gn_amt);
            l_pieces := trunc(l_file_len / gn_amt);
            l_buf := NULL;
            
            IF (l_modulo <> 0) THEN
              l_pieces := l_pieces + 1;
            END IF;
            
            dbms_lob.fileopen(l_file, dbms_lob.file_readonly);
            dbms_lob.read(l_file, gn_amt, l_filepos, l_buf);
            l_data := NULL;
            
            FOR i IN 1..l_pieces LOOP
              l_filepos := i * gn_amt + 1;
              l_file_len := l_file_len - gn_amt;
              l_data := utl_raw.concat(l_data, l_buf);
              l_chunks := trunc(utl_raw.length(l_data) / MAX_LINE_WIDTH);
              
              IF (i <> l_pieces) THEN
                l_chunks := l_chunks - 1;
              END IF;
              
              utl_smtp.write_raw_data( l_conn, utl_encode.base64_encode(l_data ) );
              l_data := NULL;
              
              IF (l_file_len < gn_amt AND l_file_len > 0) THEN
                gn_amt := l_file_len;
              END IF;
              
              IF l_pieces > 1 THEN
                dbms_lob.read(l_file, gn_amt, l_filepos, l_buf);
              END IF;
              
            END LOOP;
            
          END;
          dbms_lob.fileclose(l_file);
          
          end_attachment(conn => l_conn );
        END; -- Fin de l'insertion de la pièce jointe
      END IF;
      
      --------------------------------------------------------------------------
      -- Récupération des doc joint : TEXTE ENTETE DA
      --------------------------------------------------------------------------
      --IF nvl(gn_piece_jointe,0) != 0 AND gv_req_header_note IS NOT NULL THEN
      IF gv_req_header_note IS NOT NULL THEN
        g_step  := 'ENVOI_MAIL 009 : Pièce jointe : '||gv_req_header_note; log_msg(g_step);
        vv_file_name  := substr(gv_req_header_note,instr(gv_req_header_note,'/',-1)+1); 
        vv_repertoire := substr(gv_req_header_note,1,instr(gv_req_header_note,'/',-1)-1);
        l_filepos := 1;
        gn_amt    := 672 * 3;
		
		g_step  := 'INIT 009 Hnote : Org_id est :'||gn_org_id; --AAM INC0361005 :  Ajout des traces
        log_msg(g_step);                                 --AAM INC0361005 :  Ajout des traces
		
        BEGIN
		  g_step  := 'ENVOI_MAIL 009-1 Hnote : Appel à begin_attachment';  --AAM INC0361005 :  Ajout des traces
		  log_msg(g_step);                                           --AAM INC0361005 :  Ajout des traces
		  
          begin_attachment(conn => l_conn,
                           mime_type => 'text/plain',
                           inline => TRUE,
                           filename => vv_file_name, 
                           transfer_enc => 'base64');
						   
          g_step  := 'ENVOI_MAIL 009-2 Hnote :Fin Appel à begin_attachment'; --AAM INC0361005 :  Ajout des traces
		  log_msg(g_step);                                             --AAM INC0361005 :  Ajout des traces
		
          BEGIN
		    g_step  := 'ENVOI_MAIL 009-3 Hnote : Récupération des informations du fichier';  --AAM INC0361005 :  Ajout des traces
		    log_msg(g_step);                                                                 --AAM INC0361005 :  Ajout des traces
			
            l_file := BFILENAME('DKA_OUT_DIR',vv_file_name);
            l_file_len := dbms_lob.getlength(l_file);
            l_modulo := mod(l_file_len, gn_amt);
            l_pieces := trunc(l_file_len / gn_amt);
            l_buf := NULL;
            
            IF (l_modulo <> 0) THEN
              l_pieces := l_pieces + 1;
            END IF;
			
			g_step  := 'ENVOI_MAIL 009-4 Hnote : Ouverture Fichier';  --AAM INC0361005 :  Ajout des traces
		    log_msg(g_step);                                          --AAM INC0361005 :  Ajout des traces
            
            dbms_lob.fileopen(l_file, dbms_lob.file_readonly);
            dbms_lob.read(l_file, gn_amt, l_filepos, l_buf);
            l_data := NULL;
            
            FOR i IN 1..l_pieces LOOP
			  
			  g_step  := 'ENVOI_MAIL 009-5 Hnote : Entree de la boucle'; --AAM INC0361005 :  Ajout des traces
		      log_msg(g_step);                                           --AAM INC0361005 :  Ajout des traces
			
              l_filepos := i * gn_amt + 1;
              l_file_len := l_file_len - gn_amt;
              l_data := utl_raw.concat(l_data, l_buf);
              l_chunks := trunc(utl_raw.length(l_data) / MAX_LINE_WIDTH);
              
              IF (i <> l_pieces) THEN
                l_chunks := l_chunks - 1;
              END IF;
			  
			  g_step  := 'ENVOI_MAIL 009-6 Hnote : Appel à utl_smtp.write_raw_data'; --AAM INC0361005 :  Ajout des traces
		      log_msg(g_step);                                                       --AAM INC0361005 :  Ajout des traces
              
              utl_smtp.write_raw_data( l_conn, utl_encode.base64_encode(l_data ) );
			  
			  g_step  := 'ENVOI_MAIL 009-7 Hnote : Fin Appel à utl_smtp.write_raw_data';  --AAM INC0361005 :  Ajout des traces
		      log_msg(g_step);                                                      --AAM INC0361005 :  Ajout des traces
			  
              l_data := NULL;
			  
			  g_step  := 'ENVOI_MAIL 009-8 Hnote : Test de la longueur du fichier';  --AAM INC0361005 :  Ajout des traces
		      log_msg(g_step);                                                       --AAM INC0361005 :  Ajout des traces
              
              IF (l_file_len < gn_amt AND l_file_len > 0) THEN
                gn_amt := l_file_len;
              END IF;
			  
			  g_step  := 'ENVOI_MAIL 009-9 Hnote : test sur la variable l_pieces ';  --AAM INC0361005 :  Ajout des traces
		      log_msg(g_step);                                                       --AAM INC0361005 :  Ajout des traces 
              
              IF l_pieces > 1 THEN
                dbms_lob.read(l_file, gn_amt, l_filepos, l_buf);
              END IF;
              
            END LOOP;
            
          END;
		  g_step  := 'ENVOI_MAIL 009-10 Hnote : Fermeture fichier'; --AAM INC0361005 :  Ajout des traces
		  log_msg(g_step);                                          --AAM INC0361005 :  Ajout des traces
		  
          dbms_lob.fileclose(l_file);
		  
		  g_step  := 'ENVOI_MAIL 009-11 Hnote : Appel à end_attachment';  --AAM INC0361005 :  Ajout des traces
		  log_msg(g_step);                                                --AAM INC0361005 :  Ajout des traces
          
          end_attachment(conn => l_conn );
		  
		  g_step  := 'ENVOI_MAIL 009-12 Hnote : Fin Appel à end_attachment'; --AAM INC0361005 :  Ajout des traces
		  log_msg(g_step);                                             --AAM INC0361005 :  Ajout des traces
		  		  
        END; -- Fin de l'insertion de la pièce jointe
      END IF;
      
      --------------------------------------------------------------------------
      -- Récupération des doc joint : FICHIER ENTETE DA
      --------------------------------------------------------------------------
      --IF nvl(gn_piece_jointe,0) != 0 AND gv_req_header_file IS NOT NULL THEN
      IF gv_req_header_file IS NOT NULL THEN
        g_step  := 'ENVOI_MAIL 009 : Pièce jointe : '||gv_req_header_file; log_msg(g_step);
        vv_file_name  := substr(gv_req_header_file,instr(gv_req_header_file,'/',-1)+1); 
        vv_repertoire := substr(gv_req_header_file,1,instr(gv_req_header_file,'/',-1)-1);
        vv_extension  := substr(gv_req_header_file,instr(gv_req_header_file,'.',-1)+1);
        l_filepos := 1;
        gn_amt    := 672 * 3;
        
		g_step  := 'INIT 009 : Org_id est :'||gn_org_id; --AAM INC0361005 :  Ajout des traces
        log_msg(g_step);  
         
        BEGIN
		g_step  := 'ENVOI_MAIL 009-1 : Appel à begin_attachment';  --AAM INC0361005 :  Ajout des traces
		log_msg(g_step);                                           --AAM INC0361005 :  Ajout des traces
		
          begin_attachment(conn => l_conn,
                           mime_type => convert_type_mime(vv_extension),
                           inline => TRUE,
                           filename => vv_file_name, 
                           transfer_enc => 'base64');
						   
        g_step  := 'ENVOI_MAIL 009-2 :Fin Appel à begin_attachment'; --AAM INC0361005 :  Ajout des traces
		log_msg(g_step);                                             --AAM INC0361005 :  Ajout des traces
		
          BEGIN
		    g_step  := 'ENVOI_MAIL 009-3 : Récupération des informations du fichier';  --AAM INC0361005 :  Ajout des traces
		    log_msg(g_step);                                                           --AAM INC0361005 :  Ajout des traces
			
            l_file := BFILENAME('DKA_OUT_DIR',vv_file_name);
            l_file_len := dbms_lob.getlength(l_file);
            l_modulo := mod(l_file_len, gn_amt);
            l_pieces := trunc(l_file_len / gn_amt);
            l_buf := NULL;
            
            IF (l_modulo <> 0) THEN
              l_pieces := l_pieces + 1;
            END IF;
            
			g_step  := 'ENVOI_MAIL 009-4 : Ouverture Fichier';  --AAM INC0361005 :  Ajout des traces
		    log_msg(g_step);                                    --AAM INC0361005 :  Ajout des traces
			
            dbms_lob.fileopen(l_file, dbms_lob.file_readonly);
            dbms_lob.read(l_file, gn_amt, l_filepos, l_buf);
            l_data := NULL;
            
            FOR i IN 1..l_pieces LOOP
			
			  g_step  := 'ENVOI_MAIL 009-5 : Entree de la boucle'; --AAM INC0361005 :  Ajout des traces
		      log_msg(g_step);                                     --AAM INC0361005 :  Ajout des traces
			  
              l_filepos := i * gn_amt + 1;
              l_file_len := l_file_len - gn_amt;
              l_data := utl_raw.concat(l_data, l_buf);
              l_chunks := trunc(utl_raw.length(l_data) / MAX_LINE_WIDTH);
              
              IF (i <> l_pieces) THEN
                l_chunks := l_chunks - 1;
              END IF;
			  
              g_step  := 'ENVOI_MAIL 009-6 : Appel à utl_smtp.write_raw_data'; --AAM INC0361005 :  Ajout des traces
		      log_msg(g_step);                                                 --AAM INC0361005 :  Ajout des traces
			
              utl_smtp.write_raw_data( l_conn, utl_encode.base64_encode(l_data ) );
			  
			  g_step  := 'ENVOI_MAIL 009-7 : Fin Appel à utl_smtp.write_raw_data';  --AAM INC0361005 :  Ajout des traces
		      log_msg(g_step);                                                      --AAM INC0361005 :  Ajout des traces
			
              l_data := NULL;
			  
              g_step  := 'ENVOI_MAIL 009-8 : Test de la longueur du fichier';  --AAM INC0361005 :  Ajout des traces
		      log_msg(g_step);                                                 --AAM INC0361005 :  Ajout des traces
			
              IF (l_file_len < gn_amt AND l_file_len > 0) THEN
                gn_amt := l_file_len;
              END IF;
			  
              g_step  := 'ENVOI_MAIL 009-9 : test sur la variable l_pieces ';  --AAM INC0361005 :  Ajout des traces
		      log_msg(g_step);                                                 --AAM INC0361005 :  Ajout des traces 
			
              IF l_pieces > 1 THEN
                dbms_lob.read(l_file, gn_amt, l_filepos, l_buf);
              END IF;
              
            END LOOP;
            
          END;
		  
		  g_step  := 'ENVOI_MAIL 009-10 : Fermeture fichier'; --AAM INC0361005 :  Ajout des traces
		  log_msg(g_step);                                    --AAM INC0361005 :  Ajout des traces
		  
          dbms_lob.fileclose(l_file);
		  
          g_step  := 'ENVOI_MAIL 009-11 : Appel à end_attachment';  --AAM INC0361005 :  Ajout des traces
		  log_msg(g_step);                                          --AAM INC0361005 :  Ajout des traces
		  
          end_attachment(conn => l_conn );
		  
		  g_step  := 'ENVOI_MAIL 009-12 : Fin Appel à end_attachment'; --AAM INC0361005 :  Ajout des traces
		  log_msg(g_step);                                             --AAM INC0361005 :  Ajout des traces
		  
        END; -- Fin de l'insertion de la pièce jointe
      END IF;
      
      g_step  := 'ENVOI_MAIL 010 : Fermeture des attachements'; log_msg(g_step);
      end_attachment(conn => l_conn , last=> TRUE );
      
      --Envoi du mail
      g_step  := 'ENVOI_MAIL 011 : Envoi du mail'; log_msg(g_step);
      vr_reply := utl_smtp.close_data(l_conn);
      g_step  := 'REPLY CLOSE_DATA : '||vr_reply.code || ' - ' ||vr_reply.text; -- log_msg(g_step);
      
      vr_reply := utl_smtp.quit( l_conn ); 
      g_step  := 'REPLY QUIT : '||vr_reply.code || ' - ' ||vr_reply.text; -- log_msg(g_step);
    
    ELSE
      
      g_step  := 'ENVOI_MAIL 013 : Pas d''envoi de mail';
      log_msg(g_step);
       
    END IF;
    
    g_step  := 'ENVOI_MAIL 999 : FIN';
    log_msg(g_step);
    
  EXCEPTION
   WHEN e_adresse_fournisseur THEN
    g_step  := 'ENVOI_MAIL EE1 : Erreur adresse fournisseur'; log_msg(g_step);
        
    send_mail_ref(Dka_Tools_Pkg.get_message('DKA','DKA_SPOBON_XML_REF_SUJET',
                                            'FOURN',gr_ORDER_MAIL.VENDOR_NAME),
                  Dka_Tools_Pkg.get_message('DKA','DKA_SPOBON_XML_REF_CORPS',
                            'NCDE',gr_ORDER_MAIL.ORDER_NUMBER,
                            'FOURN',gr_ORDER_MAIL.VENDOR_NAME ,
                            'SITE', gr_ORDER_MAIL.VENDOR_SITE),
                  gv_plat_appro_mail);
    
    IF gv_acheteur IS NOT NULL THEN
      send_mail_ref(Dka_Tools_Pkg.get_message('DKA','DKA_SPOBON_XML_ACH_SUJET',
                                              'NCDE',gr_ORDER_MAIL.ORDER_NUMBER),
                    Dka_Tools_Pkg.get_message('DKA','DKA_SPOBON_XML_ACH_CORPS',
                              'NCDE',gr_ORDER_MAIL.ORDER_NUMBER,
                              'FOURN',gr_ORDER_MAIL.VENDOR_NAME ,
                              'SITE', gr_ORDER_MAIL.VENDOR_SITE),
                    gv_acheteur);
    END IF;
    
    --Avertissement
    p_retcode := 1;
   WHEN e_adresse_acheteur THEN
    g_step  := 'ENVOI_MAIL EE2 : Erreur adresse acheteur'; log_msg(g_step);
        
    send_mail_ref(Dka_Tools_Pkg.get_message('DKA','DKA_SPOBON_XML_ABS_SUJET',
                                            'DDEUR',nvl(gr_ORDER_MAIL.ACHETEUR,gr_ORDER_MAIL.DEMANDEUR)), 
                  Dka_Tools_Pkg.get_message('DKA','DKA_SPOBON_XML_ABS_CORPS',
                                            'DDEUR',nvl(gr_ORDER_MAIL.ACHETEUR,gr_ORDER_MAIL.DEMANDEUR),
                                            'NCDE',gr_ORDER_MAIL.ORDER_NUMBER),
                  gv_plat_appro_mail);
    
    --Avertissement
    p_retcode := 1;
   WHEN OTHERS THEN
    p_errbuf  := 'Erreur procedure ENVOI_MAIL :'||
                 g_step ||chr(10)||SQLERRM;
    log_msg(p_errbuf);
    p_retcode := 2;
  END envoi_mail;

-----------------------------------------------------------------
  --  NOM           : EDITION_OUTPUT
  --  DESCRIPTION   : procedure d'edition du fichier de sortie
  --
  --  PARAMETRES :
  --
  --  P_RETCODE             code retour out
  --  P_ERRBUF              description de l'erreur out
  --
  -----------------------------------------------------------------
  PROCEDURE edition_output(p_errbuf        OUT VARCHAR2,
                           p_retcode       OUT NUMBER) IS

   l_appl       fnd_application.application_short_name%TYPE;
   l_prgm_name  fnd_conc_req_summary_v.PROGRAM%TYPE;
   
   l_out        VARCHAR2(4000);
   l_ligne      VARCHAR2(100) := '---------------------------------------------------------------';

  BEGIN
    --Init des variables de sortie
    p_retcode := 0;
    p_errbuf  := '';
    
    g_step  := 'EDITION_OUTPUT 000 : DEBUT';
    log_msg(g_step);
  
     --Recuperation des informations
     BEGIN

      --Recuperation du nom de l'application
      SELECT fa.application_short_name
      INTO l_appl
      FROM fnd_application fa
      WHERE fa.application_id = fnd_profile.VALUE('RESP_APPL_ID');

      --Recuperation du nom du programme
      SELECT v.PROGRAM
      INTO l_prgm_name
      FROM fnd_conc_req_summary_v v
      WHERE v.REQUEST_ID =  gn_request_id;--fnd_global.CONC_REQUEST_ID; -- OBE
      
    EXCEPTION
     WHEN OTHERS THEN
      l_appl := '';
    END;


    --ENTETE
    l_out := 'Environnement   : '||gv_base||chr(10)||
             'Application     : '||l_appl||chr(10)||
             'Programme       : '||l_prgm_name||chr(10)||
             'Utilisateur     : '||fnd_profile.VALUE('USERNAME')||chr(10)||
             'Date            : '||to_char(SYSDATE,'DD/MM/YYYY HH24:MI:SS')||chr(10);
    out_msg(l_out);
    
    out_msg(l_ligne);
    
    --CORPS
    l_out := 'Commande à traiter                  : '||gv_order_number;out_msg(l_out);
    l_out := 'Envoi automatique niveau commande ? : '||gv_block_envoi;out_msg(l_out);
    l_out := 'Envoi d''email ?                     : '||gv_envoi_mail;out_msg(l_out);
    l_out := 'Méthode de notification fournisseur : '||gv_supplier_notif_method;out_msg(l_out);
    l_out := 'Mail expéditeur mail                : '||gv_acheteur;out_msg(l_out);
    l_out := 'Mail fournisseur                    : '||gv_mail_fournisseur;out_msg(l_out);
    l_out := chr(10)||chr(10)||l_ligne;
    out_msg(l_out);
    
    --XML
    l_out := 'Fichier XML généré   : '||gv_xml_file;out_msg(l_out);
    l_out := 'Fichier PDF récupéré : '||gv_pdf_file;out_msg(l_out);
    l_out := chr(10)||chr(10)||l_ligne;
    out_msg(l_out);
    
    --MAIL
    IF  nvl(gv_envoi_mail,'OUI') = 'OUI' THEN
      l_out := 'Sujet-----------------';out_msg(l_out);
      out_msg(gv_subject);
      out_msg(chr(10));
      
      l_out := 'Corps-----------------';out_msg(l_out);
      out_msg(gv_body);
      
      l_out := chr(10)||chr(10)||l_ligne;
      out_msg(l_out);
      
    END IF;
    
    g_step  := 'EDITION_OUTPUT 999 : FIN';
    log_msg(g_step);

  EXCEPTION
   WHEN OTHERS THEN
    p_retcode := 2;
    p_errbuf  := 'Erreur procedure EDITION_OUTPUT :'||
                 g_step ||chr(10)||SQLERRM;
    log_msg(p_errbuf);
  END edition_output;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : MAIN
--  Description   : Procedure principale
--
--  PARAMETRES    :
--    p_order_number        VARCHAR2
--    p_envoi_mail          VARCHAR2
--  VALEUR RETOURNEE : N/A
-------------------------------------------------------------------------------------------------------------------
PROCEDURE main(p_errbuf        OUT NOCOPY VARCHAR2,
               p_retcode       OUT NOCOPY NUMBER,
               p_order_number  IN         VARCHAR2,
               p_envoi_mail    IN         VARCHAR2) IS

  --Exception
  e_init              EXCEPTION;
  e_not_email         EXCEPTION;
  e_construction_xml  EXCEPTION;
  e_envoi_mail        EXCEPTION;
  e_maj_order         EXCEPTION;
  e_edition_output    EXCEPTION;
  e_contract          EXCEPTION; --JJA - 03/01/2014
  e_open_blanket      EXCEPTION;
  e_ivalua            EXCEPTION;
 
  --variable temporaire pour le code retour
  l_retcode           NUMBER := 0;
  p_retmail			  NUMBER;
  l_count         NUMBER;

BEGIN
  
  p_retcode  := 0;
  p_errbuf   := '';
  p_retmail  := 0; -- SEL INC0410929 
  
  BEGIN

    ----------------------------------------------------------------
    --Initialisation du traitement
    ----------------------------------------------------------------
    log_msg('____________________________________________________________'||chr(10)||
            'Initialisation'||chr(10)||
            '____________________________________________________________'||chr(10));
  
    log_msg('Debut : '||get_time||chr(10));
    
    --procedure de initialisation
    init(p_errbuf,p_retcode,p_order_number,p_envoi_mail); 

    /*Code retour*/
    l_retcode := greatest(p_retcode,l_retcode);
    
     SELECT 
        COUNT(1)
      INTO 
        l_count
      FROM
       po_headers ph
      WHERE
       ph.segment1 = gv_order_number
       AND ph.org_id = gn_org_id
       AND NVL(ATTRIBUTE7, 'ORACLE') IN ('IVALUA', 'REPRISE')
      ;
    
    IF l_count > 0 THEN
      RAISE e_ivalua;
    END IF;

    IF p_retcode != 0 THEN
      RAISE e_init;
    ELSIF gv_supplier_notif_method != 'EMAIL' THEN
      RAISE e_not_email;
    ELSIF gv_order_type = 'CONTRACT' THEN -- JJA - 03/01/2014
      RAISE e_contract;
    ELSIF (gv_order_type = 'BLANKET' AND NVL(gv_global_agreement_flag,'N') = 'Y') THEN
      RAISE e_open_blanket;
    END IF; 
  
    log_msg('Initialisation OK...'||chr(10));
    log_msg('Fin   : '||get_time||chr(10));
  
    ----------------------------------------------------------------
    --Contruction du fichier XML
    ----------------------------------------------------------------
    log_msg('____________________________________________________________'||chr(10)||
            'Contruction du fichier XML'||chr(10)||
            '____________________________________________________________'||chr(10));
    log_msg('Debut : '||get_time||chr(10));
  
    --procedure contruction xml
    construction_xml(p_errbuf,p_retcode);
    /*Code retour*/l_retcode := greatest(p_retcode,l_retcode); 
    IF p_retcode != 0 THEN
      RAISE e_construction_xml;
    END IF; 
  
    log_msg('Contruction du fichier XML OK...'||chr(10));
    log_msg('Fin   : '||get_time||chr(10));
     
     
    IF nvl(gv_envoi_mail,'OUI') = 'OUI' AND
       nvl(gv_block_envoi,'OUI') = 'OUI' THEN 
      ----------------------------------------------------------------
      --Envoi du mail
      ----------------------------------------------------------------
      log_msg('____________________________________________________________'||chr(10)||
              'Envoi du mail'||chr(10)||
              '____________________________________________________________'||chr(10));
      log_msg('Debut : '||get_time||chr(10));
    
      --procedure d'envoi mail
      envoi_mail(p_errbuf,p_retcode);
      /*Code retour*/l_retcode := greatest(p_retcode,l_retcode);
      IF p_retcode = 2 THEN
	    l_retcode:=2;
        RAISE e_envoi_mail;
      END IF;
    
      log_msg('Envoi du mail OK...'||chr(10));
      log_msg('Fin   : '||get_time||chr(10));
      
      ----------------------------------------------------------------
      --Mise à jour de la commande
      ----------------------------------------------------------------
      log_msg('____________________________________________________________'||chr(10)||
              'Mise à jour de la commande'||chr(10)||
              '____________________________________________________________'||chr(10));
    
      log_msg('Debut : '||get_time||chr(10));
    
      --procedure de initialisation
      maj_order(p_errbuf,p_retcode);
      /*Code retour*/l_retcode := greatest(p_retcode,l_retcode);
      IF p_retcode = 2 THEN
        RAISE e_maj_order;
      END IF;
    
      log_msg('Mise à jour de la commande mails OK...'||chr(10));
      log_msg('Fin   : '||get_time||chr(10));
      
    END IF;

  EXCEPTION
   WHEN e_init THEN
     p_errbuf  := 'Erreur procedure INIT';
     p_retcode := 2;
     log_msg(p_errbuf);
   WHEN e_not_email THEN
     --CE N'EST PAS UNE ERREUR
     p_errbuf  := 'Méthode de notification du fournisseur n''est pas EMAIL';
     p_retcode := 1;
     log_msg(p_errbuf);
   WHEN e_contract THEN -- JJA - 03/01/2014
     --CE N'EST PAS UNE ERREUR
     p_errbuf  := 'L''ordre d''achat est un contrat, pas d''édition';
     p_retcode := 1;
     log_msg(p_errbuf);
   WHEN e_open_blanket THEN
     --CE N'EST PAS UNE ERREUR
     p_errbuf  := 'L''ordre d''achat est une commande ouverte globale, pas d''édition';
     p_retcode := 1;
     log_msg(p_errbuf);
   WHEN e_construction_xml THEN
     p_errbuf  := 'Erreur procedure CONSTRUCTION_XML';
     p_retcode := 2;
     log_msg(p_errbuf);
   WHEN e_envoi_mail THEN
     p_errbuf  := 'Erreur procedure ENVOI_MAIL';
     p_retcode := 2;
	 p_retmail := 2; 
     log_msg(p_errbuf);   
   WHEN e_maj_order THEN
     p_errbuf  := 'Erreur procedure MAJ_ORDER';
     p_retcode := 2;
     log_msg(p_errbuf);  
  END;
    
  ----------------------------------------------------------------
  --Edition fichier de sortie
  ----------------------------------------------------------------
  log_msg('____________________________________________________________'||chr(10)||
          'Edition fichier de sortie'||chr(10)||
          '____________________________________________________________'||chr(10));
  log_msg('Debut : '||get_time||chr(10));

  --procedure d'edition de la sortie
  edition_output(p_errbuf,p_retcode);
  /*Code retour*/l_retcode := greatest(p_retcode,l_retcode);
  IF p_retcode != 0 THEN
    RAISE e_edition_output;
  END IF;

	  log_msg('Edition fichier de sortie OK...'||chr(10));
	  log_msg('Fin   : '||get_time||chr(10));
  
  p_retcode := greatest(p_retcode,l_retcode);
  
  -- SEL INC0410929 
  if p_retmail = 2 then
     p_retcode := 2;
	 log_msg('Le traitement termine en erreur.');
  end if;
  
EXCEPTION
 WHEN e_edition_output THEN
   p_errbuf  := 'Erreur procedure EDITION_OUTPUT';
   p_retcode := 2;
   log_msg(p_errbuf);
 WHEN e_ivalua THEN
     p_errbuf  := 'Commande IVALUA ou REPRISE, pas d''envoi de mail';
     p_retcode := 1;
     log_msg(p_errbuf); 
 WHEN OTHERS THEN
   p_errbuf  := 'Erreur procedure MAIN '|| SQLERRM;
   p_retcode := 2;
   Dka_Tools_Pkg.put_outdebug_message(p_errbuf);
END MAIN;

END &&package_name;
/
SHOW ERRORS;

EXIT
