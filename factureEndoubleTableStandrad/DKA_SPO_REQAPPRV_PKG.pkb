CREATE OR REPLACE PACKAGE BODY DKA_REPAPIMGIMP_PKG AS
----------------------------------------------------------------------
-- PROGRAM : DKA_REPAPIMGIMP_PKG.sql                                 -
-- Version : 1.0                                                     -
-- AUTEUR  : H. Descroizette - Capgemini                             -
-- DATE    : 09/05/16                                                -
----------------------------------------------------------------------
-- APPELE PAR :                                                      -
-- FONCTION   : Reprise des images de factures fournisseurs via      -
--              le database link entre la 11i et la R12              -
--              Alimentation de FND_DOCUMENTS et tables associées    -
-- SFD :  HLS-ORA-CONC-LIV-004-Reprise-données-Encours-Fournisseurs.V1.2 --
--                                                                   -
----------------------------------------------------------------------
-- VERSION              :        1.0                                 -
-- PROGRAMME MODIFIE LE :                                            -
-- PAR                  :                                            -
-- NUM_ANOMALIE         :                                            -
-- OBJET                :                                            -
--                                                                   -
----------------------------------------------------------------------

----------------------------------------------------------------------
-- constantes
k_package_name CONSTANT ALL_OBJECTS.OBJECT_NAME%TYPE := $$PLSQL_UNIT;
k_nom_traitement CONSTANT VARCHAR2(100) := 'Reprise des images de factures';


----------------------------------------------------------------------
-- curseurs

-- Pour chacune des factures importées dans la R12 par le programme de reprise, qui n'ont pas d'image facture attachée
CURSOR cur_invoices(p_org_id IN NUMBER) IS
SELECT haou.organization_id AS org_id, haou.name AS org_name,
       pv.segment1 AS vendor_num, pv.vendor_name, assa.vendor_site_code,
       aia.invoice_id, aia.invoice_num, aia.attribute3, aia.invoice_amount, aia.attribute13
FROM AP_INVOICES_ALL                     aia
JOIN HR_ALL_ORGANIZATION_UNITS           haou  ON (aia.org_id = haou.organization_id)
JOIN AP_SUPPLIER_SITES_ALL               assa  ON (assa.vendor_site_id = aia.vendor_site_id)
JOIN AP_SUPPLIERS                        pv    ON (pv.vendor_id = assa.vendor_id)
WHERE 1 = 1
  AND aia.source = 'REPRISE'
  AND (aia.org_id = p_org_id OR p_org_id IS NULL)
  AND NOT EXISTS (SELECT 'image déjà reprise dans la R12'
                  FROM FND_ATTACHED_DOCUMENTS  fad
                  JOIN FND_DOCUMENTS           fd ON (fd.document_id = fad.document_id)
                  JOIN FND_DOCUMENTS_TL        fdt ON (fdt.document_id = fd.document_id AND fdt.language = fdt.source_lang)
                  WHERE fad.entity_name = 'AP_INVOICES'
                    AND fdt.description = 'IMAGE FACTURE'
                    AND fad.pk1_value    = aia.invoice_id)
ORDER BY aia.org_id, pv.segment1, assa.vendor_site_code, aia.invoice_num;

----------------------------------------------------------------------
-- variables globales
g_default_category_id NUMBER;

----------------------------------------------------------------------
-- Procedures et fonctions

  ---------------------------------------------------------
  PROCEDURE log(p_msg IN VARCHAR2)
  IS
  BEGIN
    fnd_file.put_line(fnd_file.log, p_msg);
    dbms_output.put_line(p_msg);
  END log;

  ---------------------------------------------------------
  PROCEDURE output(p_msg IN VARCHAR2)
  IS
  BEGIN
    fnd_file.put_line(fnd_file.output, p_msg);
    --dbms_output.put_line('>' || p_msg);
  END output;

  ---------------------------------------------------------
  PROCEDURE Error(
    p_msg IN VARCHAR2,
    p_procedure IN VARCHAR2 DEFAULT NULL,
    p_sqlerrm   IN VARCHAR2 DEFAULT NULL
    )
  IS
  BEGIN
    log('-------------------- ERREUR --------------------');
    log( 'Package   : '|| k_package_name);
    log( 'Procédure : '|| p_procedure);
    log( 'Message   : '|| p_msg);
    log( 'Cause     : '|| p_sqlerrm);
    log( '=========================================================================');
    log( 'Traitement '|| k_nom_traitement ||' terminé en erreur');
    log( '=========================================================================');
  END Error;

  ---------------------------------------------------------
  PROCEDURE init
  IS
    v_etape VARCHAR2(100) := 'init';
  BEGIN
    v_etape := 'g_default_category_id';
    SELECT category_id INTO g_default_category_id FROM FND_DOCUMENT_CATEGORIES_VL WHERE NAME = 'MISC';
  EXCEPTION
    WHEN OTHERS THEN
      Error(v_etape, 'init', SQLERRM);
      RAISE;
  END init;

  ---------------------------------------------------------
  FUNCTION Create_attachment(
    p_src_file_id        IN fnd_lobs.file_id%TYPE,
    p_org_id             IN NUMBER,
    p_invoice_id         IN NUMBER,
    p_datatype_id        IN fnd_documents.datatype_id%TYPE,
    p_file_name          IN fnd_documents_tl.file_name%TYPE) RETURN fnd_attached_documents.attached_document_id%TYPE
  IS
    v_etape                VARCHAR2(100) := 'init';
    v_fnd_doc_rowid        VARCHAR2(250);
    v_document_id          NUMBER;
    v_media_id             NUMBER;
    v_fnd_att_doc_rowid    VARCHAR2(250);
    v_attached_document_id NUMBER;
    v_seq_num              NUMBER;
  BEGIN
    -- FND LOB
    v_etape := 'FND_LOB';
    v_media_id := FND_LOBS_S.nextval;
    INSERT INTO fnd_lobs (FILE_ID, FILE_NAME, FILE_CONTENT_TYPE, FILE_DATA, UPLOAD_DATE, EXPIRATION_DATE,
                         PROGRAM_NAME, PROGRAM_TAG, LANGUAGE, ORACLE_CHARSET, FILE_FORMAT)
    SELECT v_media_id, FILE_NAME, FILE_CONTENT_TYPE, FILE_DATA, UPLOAD_DATE, EXPIRATION_DATE,
           PROGRAM_NAME, PROGRAM_TAG, LANGUAGE, ORACLE_CHARSET, FILE_FORMAT
    FROM DKA_AP_INV_LOBS
    WHERE file_id = p_src_file_id;

    IF SQL%ROWCOUNT > 0 THEN
      log('Blob créé : ' || v_media_id);
      -- FND_DOCUMENT et FND_DOCUMENT_TL
      v_etape := 'FND_DOCUMENT';
      fnd_documents_pkg.insert_row(
        X_Rowid                      => v_fnd_doc_rowid,
        X_document_id                => v_document_id,
        X_creation_date              => SYSDATE,
        X_created_by                 => fnd_global.user_id,
        X_last_update_date           => SYSDATE,
        X_last_updated_by            => fnd_global.user_id,
        X_last_update_login          => fnd_global.login_id,
        X_datatype_id                => p_datatype_id,
        X_category_id                => g_default_category_id,
        X_security_type              => 1,       -- organization
        X_security_id                => p_org_id,
        X_publish_flag               => 'Y',
        X_image_type                 => NULL,
        X_storage_type               => null,
        X_usage_type                 => NULL,
        X_request_id                 => fnd_global.conc_request_id,
        X_program_application_id     => fnd_global.prog_appl_id,
        X_program_id                 => fnd_global.conc_program_id,
        X_program_update_date        => SYSDATE,
        X_language                   => fnd_global.CURRENT_LANGUAGE,
        X_description                => 'IMAGE FACTURE',
        X_file_name                  => p_file_name,
        X_media_id                   => v_media_id,
        X_create_doc                 => 'N');
      log('Document créé : ' || v_document_id);

      v_etape := 'SEQ_NUM';
      SELECT (COUNT(*) + 1) * 10
      INTO v_seq_num
      FROM fnd_attached_documents
      WHERE entity_name  = 'AP_INVOICES'
      AND pk1_value = p_invoice_id;
      log('v_seq_num: ' || v_seq_num);

      -- FND_ATTACHED_DOCUMENT
      v_etape := 'FND_ATTACHED_DOCUMENT';
      v_attached_document_id := FND_ATTACHED_DOCUMENTS_S.nextval;
      fnd_attached_documents_pkg.insert_row(
        X_Rowid                        => v_fnd_att_doc_rowid,
        X_attached_document_id         => v_attached_document_id,
        X_document_id                  => v_document_id,
        X_creation_date                => SYSDATE,
        X_created_by                   => fnd_global.user_id,
        X_last_update_date             => SYSDATE,
        X_last_updated_by              => fnd_global.user_id,
        X_last_update_login            => fnd_global.login_id,
        X_seq_num                      => nvl(v_seq_num, 10),
        X_entity_name                  => 'AP_INVOICES',
        X_column1                      => NULL,
        X_pk1_value                    => p_invoice_id,
        X_pk2_value                    => NULL,
        X_pk3_value                    => NULL,
        X_pk4_value                    => NULL,
        X_pk5_value                    => NULL,
        X_automatically_added_flag     => 'N',
        X_request_id                   => fnd_global.conc_request_id,
        X_program_application_id       => fnd_global.prog_appl_id,
        X_program_id                   => fnd_global.conc_program_id,
        X_program_update_date          => SYSDATE,
        X_datatype_id                  => NULL,
        X_category_id                  => NULL,
        X_security_type                => NULL,
        X_publish_flag                 => NULL,
        X_usage_type                   => NULL,
        X_language                     => NULL,
        X_media_id                     => v_media_id,
        X_doc_attribute_Category       => NULL,
        X_doc_attribute1               => NULL,
        X_doc_attribute2               => NULL,
        X_doc_attribute3               => NULL,
        X_doc_attribute4               => NULL,
        X_doc_attribute5               => NULL,
        X_doc_attribute6               => NULL,
        X_doc_attribute7               => NULL,
        X_doc_attribute8               => NULL,
        X_doc_attribute9               => NULL,
        X_doc_attribute10              => NULL,
        X_doc_attribute11              => NULL,
        X_doc_attribute12              => NULL,
        X_doc_attribute13              => NULL,
        X_doc_attribute14              => NULL,
        X_doc_attribute15              => NULL);
      log ('document attaché:' || v_attached_document_id);
    END IF;

    RETURN v_attached_document_id;
  EXCEPTION
    WHEN OTHERS THEN
      log('Erreur Create_attachment : invoice_id = ' || p_invoice_id || '; etape=' || v_etape || '; msg=' || SQLERRM);
      RAISE;
  END Create_attachment;


  ---------------------------------------------------------
  FUNCTION import_image(p_invoice IN cur_invoices%ROWTYPE) RETURN fnd_attached_documents.attached_document_id%TYPE
  IS
    CURSOR cur_invoice_info(p_org_name IN VARCHAR2, p_vendor_num IN VARCHAR2, p_old_vendor_site_code IN VARCHAR2,
                            p_vendor_site_code IN VARCHAR2, p_invoice_num IN VARCHAR2, p_attribute3 IN VARCHAR2)
    IS
    SELECT media_id AS file_id, datatype_id, category_id, file_name , vendor_num, vendor_site_code
    FROM DKA_AP_INV_ATTACHED_DOCS
    WHERE vendor_num = p_vendor_num
      AND invoice_num = p_invoice_num
      AND (    vendor_site_code = p_old_vendor_site_code 
            OR vendor_site_code LIKE '%' || decode(instr(p_vendor_site_code,'-'),0,p_vendor_site_code, substr(p_vendor_site_code,1,instr(p_vendor_site_code,'-')-1)) || '%' 
            OR file_name = p_attribute3)
    ORDER BY decode(vendor_site_code, p_old_vendor_site_code, 1, 2),
             decode(substr(vendor_site_code,1, 3), substr(p_org_name, 1, 3), 1, 2), 
             decode(file_name, p_attribute3, 1, 2);    
    -- je prends, de préférence, les factures dont le site fournisseur 11i correspond, 
    --            puis celles dont le code site fournisseur commence par le même code oraganisation, 
    --            puis celle qui ont le même attriute3 (nom de fichier)

    v_invoice_info           cur_invoice_info%ROWTYPE;
    v_attached_document_id   fnd_attached_documents.attached_document_id%TYPE;
  BEGIN
    SAVEPOINT sp_import_image;

    -- Récupération des informations de l'image facture sur la base 11i
    OPEN cur_invoice_info(p_invoice.org_name, p_invoice.vendor_num, p_invoice.attribute13, 
                          p_invoice.vendor_site_code, p_invoice.invoice_num, p_invoice.attribute3);
    FETCH cur_invoice_info INTO v_invoice_info;
    IF cur_invoice_info%FOUND THEN
      -- création du document attaché
      log('file_id=' || v_invoice_info.file_id || ', file_name=' || v_invoice_info.file_name || ', vendor_site_code=' || v_invoice_info.vendor_site_code);
      v_attached_document_id := Create_attachment(
        p_src_file_id     => v_invoice_info.file_id,
        p_org_id          => p_invoice.org_id,
        p_invoice_id      => p_invoice.invoice_id,
        p_datatype_id     => v_invoice_info.datatype_id,
        p_file_name       => v_invoice_info.file_name);
    END IF;
    CLOSE cur_invoice_info;

    RETURN v_attached_document_id;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK TO sp_import_image;
      log('Erreur import_image : invoice_id = ' || p_invoice.invoice_id || '; msg=' || SQLERRM);
  END import_image;

  ---------------------------------------------------------
  FUNCTION import_blobs(p_org_id IN NUMBER) RETURN NUMBER
  IS
    v_org_name          VARCHAR2(200);
    v_org_id            NUMBER;
    v_nb_factures       PLS_INTEGER := 0;
    v_nb_images         PLS_INTEGER := 0;
    v_nb_factures_total PLS_INTEGER := 0;
    v_nb_images_total   PLS_INTEGER := 0;

    PROCEDURE new_org(invoice cur_invoices%ROWTYPE)
    IS
    BEGIN
      IF v_org_id IS NULL THEN
        -- affichage de l'entête
        output('==================================================================');
        output('| U.O                   | ORG_ID |   Nb factures |     Nb images |');
        output('==================================================================');
      ELSE
        output('| ' || rpad(v_org_name, 21) || ' | ' || lpad(v_org_id, 6) || ' | ' ||
               lpad(v_nb_factures, 13) || ' | ' || lpad(v_nb_images, 13) || ' |');
        log(v_org_name || '(' || v_org_id || ') : ' || v_nb_factures || ' factures parcourues ; ' || v_nb_images || ' images importées.');
      END IF;

      v_org_name    := invoice.org_name;
      v_org_id      := invoice.org_id;
      v_nb_factures := 0;
      v_nb_images   := 0;
      IF v_org_id IS NOT NULL THEN
        log(v_org_name || '(' || v_org_id || ')');
      END if;
    END new_org;
  BEGIN
    log('Début procédure import_blobs');
    log('   p_org_id = ' || nvl(to_char(p_org_id), '{null}'));
    log('');

    -- recherche des factures reprises qui n'ont pas d'image
    FOR invoice IN cur_invoices(p_org_id) LOOP
      IF v_org_id IS NULL OR invoice.org_id <> v_org_id THEN
        new_org(invoice);
      END IF;

      --récupération des images de la facture en cours
      log('vendor_name=' || invoice.vendor_name ||', invoice_num=' || invoice.invoice_num || ', vendor_site_code=' || invoice.vendor_site_code);
      IF import_image(invoice) IS NOT NULL THEN
        v_nb_images       := v_nb_images + 1;
        v_nb_images_total := v_nb_images_total + 1;
        IF MOD(v_nb_images_total, 100) = 0 THEN
          log('   ' || v_nb_images_total || ' images importées...');
        END IF;
      END IF;
      v_nb_factures       := v_nb_factures + 1;
      v_nb_factures_total := v_nb_factures_total + 1;
    END LOOP;
    new_org(NULL);

    output('==================================================================');
    output('| ' || lpad('TOTAL', 21) || ' | ' || lpad(' ', 6) || ' | ' ||
        lpad(v_nb_factures_total, 13) || ' | ' || lpad(v_nb_images_total, 13) || ' |');
    output('==================================================================');
    log('TOTAL : ' || v_nb_images_total || ' images importées.');

    RETURN v_nb_images_total;
  EXCEPTION
    WHEN OTHERS THEN
      Error(SQLERRM, 'import_blobs');
      RAISE;
  END import_blobs;


  ---------------------------------------------------------
  PROCEDURE MAIN(p_errbuf                 IN OUT VARCHAR2,
                 p_retcode                IN OUT NUMBER,
                 p_org_id                 IN NUMBER DEFAULT NULL,
                 p_simulation             IN VARCHAR2 DEFAULT 'N')
  IS
    v_nb_images NUMBER;
  BEGIN
    -- Début du Programme --
    log('Début procédure MAIN');
    log('   p_org_id = ' || nvl(to_char(p_org_id), '{null}'));
    log('   p_simulation = ' || p_simulation);
    p_retcode   := 0;
    p_errbuf    := NULL;
    init;

    -- import des images pour l'org_id choisie (ou toutes les org_id si p_org_id est null)
    v_nb_images := import_blobs(p_org_id);
    log('');
    log('Traitement terminé. ' || v_nb_images || ' images importées');

    IF upper(substr(nvl(p_simulation, 'N'), 1, 1)) = 'N' THEN
      COMMIT;
      log('COMMIT effectué');
    ELSE
      ROLLBACK;
      log('ROLLBACK effectué (mode simulation)');
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      p_errbuf := nvl(p_errbuf, SQLERRM);
      p_retcode := 2;
      Error(p_errbuf, 'main', SQLERRM);
  END MAIN;


END DKA_REPAPIMGIMP_PKG;
/
SHOW ERRORS ;
EXIT;