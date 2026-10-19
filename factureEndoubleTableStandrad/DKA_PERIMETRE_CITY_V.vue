CREATE OR REPLACE PACKAGE BODY dka_iaploadimg_xerox_pkg AS
  ----------------------------------------------------------------------------------------------
  -- $$
  -- CAPGEMINI
  -- PROJET            : Hélios
  -- NOM               : DKA_IAPLOADIMG_XEROX_PKG.pkb
  -- DESCRIPTION       : DKA_IAPLOADIMG_XEROX_PKG package body :
  --
  -- AUTEUR           : CDE (CAPGEMINI)
  -- DATE DE CREATION : 04/03/2008
  -- DOC. ASSOCIEE    :
  -- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
  ----------------------------------------------------------------------------------------------
  -- HISTORIQUE DES MODIFICATIONS
  -- Date       Qui Description
  -- ---------- --- ----------------------------------------------------------------------------   
  -- 29/04/08   CDE Suite problème perf : utilisation attribute9 au lieu de source dans 
  --                selection factures
  -- ---------- --- ----------------------------------------------------------------------------
  -- 20/06/2011 EMA Prise en compte des données EDIFIS
  -- 02/09/2016 BDE Modification pour Hélios
  -- 05/04/2017 MEG artf2135294 : SPE131 - Tests d'intégration
  -- 28/08/2018 OBE artf3024813 : INC0242938 - Correctif Facture AP inaccessible
  -- 14/10/2020 MTIA EDB264 - Rattachement des images pour IVALUA 
  ----------------------------------------------------------------------------------------------
  -- 30/11/2021 SELO artf07494353 - TASK0159627 - Archivage image facture
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PRIVEES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    gn_user_id                      fnd_user.user_id%TYPE;
    gn_login_id                     fnd_logins.login_id%TYPE;          
    --gn_org_id                       hr_all_organization_units.organization_id%TYPE;
    gn_org_name                     hr_all_organization_units.name%TYPE;
    gv_description                  VARCHAR2(250);
    gn_category_id                  NUMBER;
    gv_datatype_name                VARCHAR2(30) := 'FILE';
    gn_datatype_id                  NUMBER;
    gv_entity_name_ap               VARCHAR2(30) := 'AP_INVOICES';
    gv_entity_name_oi               VARCHAR2(30) := 'AP_INVOICES_INTERFACE';
    gv_source                       VARCHAR2(30) := 'SCAN_XGS';
    gv_attribute9                   VARCHAR2(30) := 'XGS';
  
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PRIVEES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PUBLIQUES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : init
  --  Description   : procédure d'initialisation
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------

    PROCEDURE init (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    )
    IS
        rec_param   dka_parameters%ROWTYPE;
        vv_category fnd_document_categories.name%TYPE;

    BEGIN
    
        dka_tools_pkg.put_debug_message ('(+) Init');
        pv_errbuf     := NULL;
        pn_retcode    := 0;

        -- En-tête du fichier de sortie
        dka_tools_pkg.put_out_header;

        -- Variables globale "WHO"
        gn_user_id                      := fnd_global.user_id;
        gn_login_id                     := fnd_global.login_id;
       -- gn_org_id                       := fnd_profile.value ('ORG_ID');
		

        -- dka_tools_pkg.get_code_societe(gn_org_id, gn_org_name, pv_errbuf, pn_retcode);
        -- IF pn_retcode != 0
        -- THEN 
            -- pv_errbuf    := 'Nom société : ' || pv_errbuf;            
            -- RETURN;
        -- END IF;

        -- dka_tools_pkg.put_outdebug_message('Unité opérationnelle : '||gn_org_name||CHR(10)||CHR(10));

        -- Variables liées à la création du document joint
        Dka_Tools_Pkg.get_parameter ('IAPLOADIMG_XEROX', 'DESCRIPTION', rec_param,  pn_retcode, pv_errbuf);
        gv_description                   := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
		
            pv_errbuf    := 'Paramètre DESCRIPTION : ' || pv_errbuf;
            RETURN;
        ELSIF gv_description IS NULL
        THEN
            pv_errbuf    := 'Paramètre DESCRIPTION : Aucune donnée trouvée';
            pn_retcode   := 2;
            RETURN;
        END IF;

        Dka_Tools_Pkg.put_debug_message (CHR (10) || 'gv_description : ' || gv_description);
        Dka_Tools_Pkg.get_parameter ('IAPLOADIMG_XEROX', 'CATEGORY', rec_param,  pn_retcode, pv_errbuf);
        vv_category                  := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'Paramètre CATEGORY : ' || pv_errbuf;
            RETURN;
        ELSIF vv_category IS NULL
        THEN
            pv_errbuf    := 'Paramètre CATEGORY : Aucune donnée trouvée';
            pn_retcode   := 2;
            RETURN;
        END IF;

        -- Récupération de l'id correspondant à la categorie de document
        SELECT category_id
        INTO gn_category_id
        FROM fnd_document_categories
        WHERE name = vv_category;

        Dka_Tools_Pkg.put_debug_message (CHR (10) || 'gn_category_id : ' || gn_category_id);

        -- Récupération de l'id correspondant au type de document
        SELECT distinct datatype_id
        INTO gn_datatype_id
        FROM fnd_document_datatypes
        WHERE name = gv_datatype_name;

        Dka_Tools_Pkg.put_debug_message (CHR (10) || 'gn_datatype_id : ' || gn_datatype_id);
        dka_tools_pkg.put_debug_message ('(-) Init');
        
    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode   := 2;
            pv_errbuf    := 'INIT : ' ||SQLERRM;
    END init;



  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : chargement_image
  --  Description   : procédure qui charge une image de facture en table
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE chargement_image(pn_nom_image IN VARCHAR2
                       , pb_existe    OUT BOOLEAN
                       , pn_file_id   OUT NUMBER
                       , pv_errbuf    OUT VARCHAR2
                       , pn_retcode   IN OUT NUMBER) 
  IS
    l_length NUMBER;
    l_blocksize NUMBER;
    l_src_fich BFILE;
    l_dst_fich BLOB;
    l_src_offset NUMBER := 1;
    l_dst_offset NUMBER := 1;


  BEGIN

    dka_tools_pkg.put_debug_message ('(+) chargement_image');
    pn_retcode := 0; 
    dbms_lob.createtemporary(l_dst_fich,true,dbms_lob.session);

    l_src_fich := bfilename('XEROX_LOADIMG', pn_nom_image);
    pb_existe := DBMS_LOB.FILEEXISTS(l_src_fich) = 1;

    IF pb_existe
    THEN
      dbms_lob.fileopen(l_src_fich, dbms_lob.file_readonly);
      dbms_lob.loadfromfile(l_dst_fich, l_src_fich, dbms_lob.lobmaxsize, l_src_offset, l_dst_offset);
      SELECT fnd_lobs_s.NEXTVAL
      INTO   pn_file_id
      FROM   dual;

      INSERT INTO fnd_lobs
            (file_id,
             file_name,
             file_content_type,
             file_data,
             file_format,
             upload_date,
             program_name)
      VALUES
            (pn_file_id,
             pn_nom_image,
             'image/tiff',
             l_dst_fich,
             'binary',
             sysdate,
             'FNDATTCH');

      DBMS_LOB.FILECLOSE(l_src_fich);
    END IF;

    dka_tools_pkg.put_debug_message ('(-) chargement_image');

  EXCEPTION
    WHEN OTHERS THEN
      dka_tools_pkg.put_debug_message('chargement_image - '|| SQLCODE || ' : '|| SQLERRM);
      pv_errbuf  := 'chargement_image - ' || SQLERRM;
      pn_retcode := 2;
      ROLLBACK;
  END chargement_image;


  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : create_attached_doc
  --  Description   : procédure qui crée le document joint
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE create_attached_doc(pv_filename    IN VARCHAR2
                             , pv_entity_name  IN VARCHAR2
                             , pn_invoice_id   IN NUMBER
                             , pn_file_id      IN NUMBER
                             , pv_description  IN VARCHAR2
                             , pv_errbuf       OUT VARCHAR2
                             , pn_retcode      IN OUT NUMBER) 
  IS

    l_document_id NUMBER;
    l_attached_document_id NUMBER;
    l_num_seq NUMBER;
  BEGIN

    dka_tools_pkg.put_debug_message ('(+) create_attached_doc');
    pn_retcode := 0;
    -- Recupération du dernier numéro de séquence
    BEGIN
    SELECT seq_num + 10
    INTO   l_num_seq
    FROM   fnd_attached_documents
    WHERE  entity_name   = pv_entity_name
           AND pk1_value = to_char(pn_invoice_id);

    
    EXCEPTION
    WHEN NO_DATA_FOUND
    THEN

        l_num_seq := 10;
    END;

    SELECT fnd_documents_s.nextval
    INTO l_document_id
    FROM DUAL;

    INSERT INTO fnd_documents_tl
                (document_id,
                file_name,
                media_id,
                description,
                creation_date,
                created_by,
                last_update_date,
                last_updated_by,
                language,
                source_lang)
           VALUES(l_document_id,
                  pv_filename,
                  pn_file_id,
                  pv_description,
                  sysdate,
                  -1,
                  sysdate,
                  -1,
                  userenv('LANG'),
                  userenv('LANG'));


    INSERT INTO fnd_documents
                (document_id,
                category_id,
                datatype_id,
                creation_date,
                created_by,
                last_update_date,
                last_updated_by,
                security_type,
                --security_id,
                publish_flag,
				media_id,
				file_name,
				USAGE_TYPE) -- OBE artf3024813
           VALUES(l_document_id,
                  gn_category_id, 
                  gn_datatype_id,   
                  sysdate,
                  -1,
                  sysdate,
                  -1,
                  1,
                  --gn_org_id,
                  'Y',
				  pn_file_id,
				  pv_filename,
				  'O'); -- OBE artf3024813
    SELECT fnd_attached_documents_s.nextval INTO l_attached_document_id FROM DUAL;

    INSERT INTO fnd_attached_documents
                (attached_document_id,
                document_id,
                seq_num,
                entity_name,
                pk1_value,
                creation_date,
                created_by,
                last_update_date,
                last_updated_by,
                automatically_added_flag)
           VALUES(l_attached_document_id,
                  l_document_id,
                  l_num_seq,
                  pv_entity_name,
                  pn_invoice_id,
                  sysdate,
                  -1,
                  sysdate,
                  -1,
                  'N');
    dka_tools_pkg.put_debug_message ('(-) create_attached_doc');

  EXCEPTION
    WHEN OTHERS THEN
      dka_tools_pkg.put_debug_message('create_attached_doc - ' || SQLCODE || '=' ||SQLERRM);
      pv_errbuf  := 'create_attached_doc - ' || SQLERRM;
      pn_retcode := 2;
      ROLLBACK;
  END create_attached_doc;


  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : delete_attached_doc
  --  Description   : procédure de suppression d'un document joint
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------


  PROCEDURE delete_attached_doc
                   (pn_document_id      IN NUMBER,
                    pv_errbuf           OUT VARCHAR2,
                    pn_retcode          IN OUT NUMBER)
  IS
    vn_media_id NUMBER; 
  
  BEGIN
    dka_tools_pkg.put_debug_message ('(+) delete_attached_doc');
    pn_retcode := 0;

      -- Récupération du media_id
      BEGIN
           SELECT media_id
           INTO   vn_media_id
           FROM   fnd_documents_tl
           WHERE  document_id = pn_document_id;
      EXCEPTION
      WHEN OTHERS THEN
           vn_media_id := NULL;
      END;

      DELETE fnd_lobs
      WHERE file_id = vn_media_id;

      DELETE fnd_documents_tl
      WHERE document_id = pn_document_id;
      
      DELETE fnd_documents
      WHERE document_id = pn_document_id;
      
      DELETE fnd_attached_documents
      WHERE document_id = pn_document_id;            

    dka_Tools_Pkg.put_outdebug_message ('  >  Suppression du document joint n° : '|| pn_document_id);
    dka_tools_pkg.put_debug_message ('(-) delete_attached_doc');
  EXCEPTION
    WHEN OTHERS THEN
      dka_tools_pkg.put_debug_message('delete_attached_doc -' || SQLCODE || '=' || SQLERRM);
      pv_errbuf  := 'delete_attached_doc - ' || SQLERRM;
      pn_retcode := 2;
      ROLLBACK;
  END delete_attached_doc;




  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : Stockage_image_facture_AP
  --  Description   : procédure de stockage d'image pour les factures insérées dans AP
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE stockage_image_facture_AP(pv_errbuf IN OUT VARCHAR2
                                     , pn_retcode OUT NUMBER) 
  IS


    CURSOR cur_factures_AP IS
      SELECT * FROM ap_invoices_all aia
      -- CD 290408 WHERE aia.source = gv_source
      -- WHERE aia.attribute9 = gv_attribute9       Modif EMA du 20/06/2011
      WHERE aia.attribute9 IN ('XGS', 'EDI' ,'DSP')     -- Modif MTIA EDB264 le 14/10/2020
      AND   aia.attribute3 IS NOT NULL
      MINUS
      SELECT * FROM ap_invoices_all aia
      -- CD 290408 WHERE aia.source = gv_source
      -- WHERE aia.attribute9 = gv_attribute9       Modif EMA du 20/06/2011
      WHERE aia.attribute9 IN ('XGS', 'EDI', 'DSP')     -- Modif MTIA EDB264 le 14/10/2020
      AND aia.attribute3 IS NOT NULL
      AND EXISTS (SELECT 'X' 
                  FROM   fnd_attached_documents fad
                  WHERE  fad.entity_name = gv_entity_name_ap
                  AND    fad.pk1_value = to_char(aia.invoice_id))
    ;

    rec_factures_AP         cur_factures_AP%ROWTYPE;
    e_exception1            EXCEPTION;
    l_existe                BOOLEAN;
    l_file_id               NUMBER;
    vn_nb_lignes_lues       NUMBER := 0;
    vn_nb_factures_ok       NUMBER := 0;
    vn_nb_factures_ko       NUMBER := 0;
    vn_nb_images_manquantes NUMBER := 0;  
    pn_retcode_1            BOOLEAN := FALSE; 
    pn_retcode_2            BOOLEAN := FALSE;


  BEGIN
    pn_retcode := 0;
    dka_tools_pkg.put_debug_message ('(+) stockage_image_facture_AP');

    dka_tools_pkg.put_outdebug_message('*****  STOCKAGE DES IMAGES SUR LES FACTURES AP  *****'||CHR(10));

    FOR rec_factures_AP IN cur_factures_AP LOOP
      BEGIN
          vn_nb_lignes_lues := vn_nb_lignes_lues + 1;

          chargement_image(rec_factures_AP.attribute3, l_existe, l_file_id, pv_errbuf, pn_retcode);

          IF pn_retcode != 0
          THEN
              RAISE e_exception1;
          END IF;

          IF l_existe
          THEN
              create_attached_doc(rec_factures_AP.attribute3, gv_entity_name_ap , rec_factures_AP.invoice_id, l_file_id, gv_description, pv_errbuf, pn_retcode);
					    UTL_FILE.FRENAME ('XEROX_LOADIMG', rec_factures_AP.attribute3, 'XEROX_MOVEIMG', rec_factures_AP.attribute3 || '_' || to_char(SYSDATE, 'YYYYMMDDHH24MISS'));

              IF pn_retcode != 0
              THEN
                  RAISE e_exception1;
              END IF;

              Dka_Tools_Pkg.put_outdebug_message('   > Traitement OK de l''image ' || rec_factures_AP.attribute3 || ' de la facture N° ' || rec_factures_AP.invoice_num || ' ,Id ' || rec_factures_AP.invoice_id);
              vn_nb_factures_ok := vn_nb_factures_ok + 1;
              COMMIT;
          ELSE
              Dka_Tools_Pkg.put_outdebug_message('   > Traitement KO de la facture N° ' || rec_factures_AP.invoice_num || ' ,Id ' || rec_factures_AP.invoice_id || ' ==> L''image '|| rec_factures_AP.attribute3 || ' n''a pas été trouvée');
              vn_nb_images_manquantes := vn_nb_images_manquantes + 1;
          END IF;

        EXCEPTION
           WHEN e_exception1 THEN
                vn_nb_factures_ko := vn_nb_factures_ko + 1;
                Dka_Tools_Pkg.put_outdebug_message('   > Traitement KO de l''image ' || rec_factures_AP.attribute3 || ' de la facture N° ' || rec_factures_AP.invoice_num || ' ,Id ' || rec_factures_AP.invoice_id);
                dka_tools_pkg.put_debug_message('         ==> ' || pv_errbuf);
                IF NOT pn_retcode_1 THEN pn_retcode_1 := TRUE; END IF; 
                ROLLBACK;

           WHEN OTHERS THEN
                vn_nb_factures_ko := vn_nb_factures_ko + 1;
                Dka_Tools_Pkg.put_outdebug_message('   > Traitement KO de l''image ' || rec_factures_AP.attribute3 || ' de la facture N° ' || rec_factures_AP.invoice_num || ' ,Id ' || rec_factures_AP.invoice_id);
                dka_tools_pkg.put_debug_message('         ==> ' || SQLCODE || ' : ' || SQLERRM);
                pv_errbuf  := 'Erreur dans la boucle - ' || SQLERRM;
                IF NOT pn_retcode_2 THEN pn_retcode_2 := TRUE; END IF;
                ROLLBACK;

      END;
    END LOOP;

    IF pn_retcode_2
    THEN
        pn_retcode := 2;
    ELSIF pn_retcode_1
    THEN
        pn_retcode := 1;
    ELSE
        pn_retcode := 0;
    END IF;

    fnd_file.put_line (fnd_file.output,CHR(10));
    dka_tools_pkg.put_outdebug_message(' Nombre de lignes lues           : ' || vn_nb_lignes_lues);
    dka_tools_pkg.put_outdebug_message(' Nombre de factures traitées     : ' || vn_nb_factures_ok);
    dka_tools_pkg.put_outdebug_message(' Nombre de factures sans images  : ' || vn_nb_images_manquantes);
    dka_tools_pkg.put_outdebug_message(' Nombre de factures en erreur    : ' || vn_nb_factures_ko || CHR(10));

    dka_tools_pkg.put_debug_message ('(-) stockage_image_facture_AP');


  EXCEPTION

    WHEN OTHERS THEN
      dka_tools_pkg.put_debug_message('stockage_image_facture_AP - '||SQLCODE || ' : ' ||SQLERRM);
      pv_errbuf  := 'Erreur dans stockage_image_facture_AP - ' || SQLERRM;
      pn_retcode := 2;
      ROLLBACK;
  END stockage_image_facture_AP;


  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : Stockage_image_facture_OI
  --  Description   : procédure de stockage des images pour les factures en rejet dans l'open interface
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE Stockage_image_facture_OI(pv_errbuf IN OUT VARCHAR2
                                    , pn_retcode OUT NUMBER) 
  IS


    CURSOR cur_factures_OI IS
      SELECT * FROM ap_invoices_interface aii
      -- CD 290408 WHERE aii.source = gv_source
      -- WHERE aii.attribute9 = gv_attribute9       Modif EMA du 20/06/2011
      WHERE aii.attribute9 IN ('XGS', 'EDI', 'DSP')     -- Modif MTIA EDB264 le 14/10/2020
      AND   aii.attribute3 IS NOT NULL
      AND   aii.status = 'REJECTED'
      --AND   aii.org_id = gn_org_id
      MINUS
      SELECT * FROM ap_invoices_interface aii
      -- CD 290408 WHERE aii.source = gv_source
      -- WHERE aii.attribute9 = gv_attribute9       Modif EMA du 20/06/2011
      WHERE aii.attribute9 IN ('XGS', 'EDI', 'DSP')     -- Modif MTIA EDB264 le 14/10/2020
      AND   aii.attribute3 IS NOT NULL
      AND   aii.status = 'REJECTED'
      --AND   aii.org_id = gn_org_id
      AND EXISTS (SELECT 'X' 
                  FROM   fnd_attached_documents fad
                  WHERE  fad.entity_name = gv_entity_name_oi
                  AND    fad.pk1_value = to_char(aii.invoice_id))
    ;

    rec_factures_OI         cur_factures_OI%ROWTYPE;
    e_exception1            EXCEPTION;
    l_existe                BOOLEAN;
    l_file_id               NUMBER;
    vn_nb_lignes_lues       NUMBER := 0;
    vn_nb_factures_ok       NUMBER := 0;
    vn_nb_factures_ko       NUMBER := 0;
    vn_nb_images_manquantes NUMBER := 0;  
    pn_retcode_1            BOOLEAN := FALSE; 
    pn_retcode_2            BOOLEAN := FALSE;


  BEGIN
    pn_retcode := 0;
    dka_tools_pkg.put_debug_message ('(+) Stockage_image_facture_OI');

    fnd_file.put_line (fnd_file.output,CHR(10));
    Dka_Tools_Pkg.put_outdebug_message('*****  STOCKAGE DES IMAGES SUR LES FACTURES EN REJET DANS LA PASSERELLE ******'||CHR(10));

    FOR rec_factures_OI IN cur_factures_OI LOOP
      BEGIN
          vn_nb_lignes_lues := vn_nb_lignes_lues + 1;

          chargement_image(rec_factures_OI.attribute3, l_existe, l_file_id, pv_errbuf, pn_retcode);

          IF pn_retcode != 0
          THEN
              RAISE e_exception1;
          END IF;

          IF l_existe
          THEN
              create_attached_doc(rec_factures_OI.attribute3, gv_entity_name_oi , rec_factures_OI.invoice_id, l_file_id, gv_description, pv_errbuf, pn_retcode);
                 UTL_FILE.FRENAME ('XEROX_LOADIMG', rec_factures_OI.attribute3, 'XEROX_MOVEIMG', rec_factures_OI.attribute3 || '_' || to_char(SYSDATE, 'YYYYMMDDHH24MISS')); -- SELO : artf07494353 - TASK0159627 - Archivage image facture
              IF pn_retcode != 0
              THEN
                  RAISE e_exception1;
              END IF;

              Dka_Tools_Pkg.put_outdebug_message('   > Traitement OK de l''image ' || rec_factures_OI.attribute3 || ' de la facture N° ' || rec_factures_OI.invoice_num || ' ,Id ' || rec_factures_OI.invoice_id);
              vn_nb_factures_ok := vn_nb_factures_ok + 1;
              COMMIT;
          ELSE
              Dka_Tools_Pkg.put_outdebug_message('   > Traitement KO de la facture N° ' || rec_factures_OI.invoice_num || ' ,Id ' || rec_factures_OI.invoice_id || ' ==> L''image '|| rec_factures_OI.attribute3 || ' n''a pas été trouvée');
              vn_nb_images_manquantes := vn_nb_images_manquantes + 1;
          END IF;

        EXCEPTION
           WHEN e_exception1 THEN
                vn_nb_factures_ko := vn_nb_factures_ko + 1;
                Dka_Tools_Pkg.put_outdebug_message('   > Traitement KO de l''image ' || rec_factures_OI.attribute3 || ' de la facture N° Id ' || rec_factures_OI.invoice_id);
                dka_tools_pkg.put_debug_message('         ==> ' || pv_errbuf);
                IF NOT pn_retcode_1 THEN pn_retcode_1 := TRUE; END IF; 
                ROLLBACK;

           WHEN OTHERS THEN
                vn_nb_factures_ko := vn_nb_factures_ko + 1;
                Dka_Tools_Pkg.put_outdebug_message('   > Traitement KO de l''image ' || rec_factures_OI.attribute3 || ' de la facture N° Id ' || rec_factures_OI.invoice_id);
                dka_tools_pkg.put_debug_message('         ==> ' || SQLCODE || ' : ' || SQLERRM);
                pv_errbuf  := 'Erreur dans la boucle - ' || SQLERRM;
                IF NOT pn_retcode_2 THEN pn_retcode_2 := TRUE; END IF;
                ROLLBACK;

      END;
    END LOOP; 

    IF pn_retcode_2
    THEN
        pn_retcode := 2;
    ELSIF pn_retcode_1
    THEN
        pn_retcode := 1;
    ELSE
        pn_retcode := 0;
    END IF;


    fnd_file.put_line (fnd_file.output,CHR(10));
    dka_tools_pkg.put_outdebug_message(' Nombre de lignes lues           : ' || vn_nb_lignes_lues);
    dka_Tools_pkg.put_outdebug_message(' Nombre de factures traitées     : ' || vn_nb_factures_ok);
    dka_Tools_pkg.put_outdebug_message(' Nombre de factures sans images  : ' || vn_nb_images_manquantes);
    dka_Tools_pkg.put_outdebug_message(' Nombre de factures en erreur    : ' || vn_nb_factures_ko ||CHR(10));

    dka_tools_pkg.put_debug_message ('(-) Stockage_image_facture_OI');

  EXCEPTION

    WHEN OTHERS THEN
      dka_tools_pkg.put_debug_message('Stockage_image_facture_OI : '|| SQLCODE || '=' || SQLERRM);
      pv_errbuf  := 'Erreur dans Stockage_image_facture_OI - ' || SQLERRM;
      pn_retcode := 2;
      ROLLBACK;
  END Stockage_image_facture_OI;


  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : Purge_document_joint_oi
  --  Description   : procédure de stockage des images pour les factures en rejet dans l'open interface
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE Purge_document_joint_oi (pv_errbuf IN OUT VARCHAR2
                                   , pn_retcode OUT NUMBER) 
  IS


    CURSOR cur_doc_joint_orphelin_OI IS
          SELECT * 
          FROM fnd_attached_documents fad
          WHERE entity_name = 'AP_INVOICES_INTERFACE'
          AND NOT EXISTS (SELECT 'x'
                          FROM ap_invoices_interface aii
                          WHERE to_char(aii.invoice_id) = fad.pk1_value)
    ;

    rec_doc_joint_orphelin_OI    cur_doc_joint_orphelin_OI%ROWTYPE;
    e_exception1                 EXCEPTION;
    vn_nb_lignes_lues            NUMBER := 0;
    vn_nb_suppression_ko         NUMBER := 0;
    vn_nb_suppression_ok         NUMBER := 0;
    pn_retcode_1                 BOOLEAN := FALSE; 


  BEGIN

    dka_tools_pkg.put_debug_message ('(+) Purge_document_joint_oi');

    pn_retcode := 0;
    fnd_file.put_line (fnd_file.output,CHR(10));          
    Dka_Tools_Pkg.put_outdebug_message('*****  PURGE DES DOCUMENTS JOINTS RESTES ORPHELINS DANS LA PASSERELLE ******'||CHR(10));


    FOR rec_doc_joint_orphelin_OI IN cur_doc_joint_orphelin_OI LOOP
      BEGIN
          vn_nb_lignes_lues := vn_nb_lignes_lues + 1;
       
          delete_attached_doc(rec_doc_joint_orphelin_OI.document_id, pv_errbuf, pn_retcode);              

          IF pn_retcode != 0
          THEN
              RAISE e_exception1;
          ELSE
              vn_nb_suppression_ok := vn_nb_suppression_ok + 1;
          END IF;
      
       EXCEPTION
       WHEN e_exception1 THEN
                vn_nb_suppression_ko := vn_nb_suppression_ko + 1;
                Dka_Tools_Pkg.put_outdebug_message('   > Suppression KO du document joint ' || rec_doc_joint_orphelin_OI.document_id);
                dka_tools_pkg.put_debug_message('         ==> ' || pv_errbuf);
                IF NOT pn_retcode_1 THEN pn_retcode_1 := TRUE; END IF; 
                ROLLBACK;

      END;
    END LOOP; 

    IF pn_retcode_1
    THEN
        pn_retcode := 1;
    ELSE
        pn_retcode := 0;
    END IF;

    fnd_file.put_line (fnd_file.output,CHR(10));
    dka_tools_pkg.put_outdebug_message(' Nombre de lignes lues               : ' || vn_nb_lignes_lues);
    dka_Tools_pkg.put_outdebug_message(' Nombre de suppressions traitées     : ' || vn_nb_suppression_ok);
    dka_Tools_pkg.put_outdebug_message(' Nombre de suppressions en erreur    : ' || vn_nb_suppression_ko);

    dka_tools_pkg.put_debug_message ('(-) Purge_document_joint_oi');

  EXCEPTION

    WHEN OTHERS THEN
      dka_tools_pkg.put_debug_message('Purge_document_joint_oi : '|| SQLCODE || '=' || SQLERRM);
      pv_errbuf  := 'Erreur dans Purge_document_joint_oi - ' || SQLERRM;
      pn_retcode := 2;
      ROLLBACK;
  END Purge_document_joint_oi;


  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : main
  --  Description   : procédure principale du traitement qui enchaînera l'ensemble
  --                  des autres procèdures.
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE main(pv_errbuf IN OUT VARCHAR2
               , pn_retcode OUT NUMBER) 
  IS


  BEGIN

    dka_tools_pkg.put_debug_message ('(+) Main');

    pn_retcode := 0;
    pv_errbuf  := NULL;
     
        ----- Appel de la procédure INIT -----
        init (pv_errbuf, pn_retcode);

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'INIT - ' || pv_errbuf;
            dka_tools_pkg.put_outdebug_message( CHR(10)||pv_errbuf);
            RETURN;
        END IF;

        ----- Appel de la procédure STOCKAGE_IMAGE_FACTURE_AP -----
        stockage_image_facture_AP (pv_errbuf, pn_retcode);

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'STOCKAGE_IMAGE_FACTURE_AP - ' || pv_errbuf;
            dka_tools_pkg.put_outdebug_message( CHR(10)||pv_errbuf);
        END IF;

        ----- Appel de la procédure STOCKAGE_IMAGE_FACTURE_OI -----
        Stockage_image_facture_OI (pv_errbuf, pn_retcode);

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'STOCKAGE_IMAGE_FACTURE_OI - ' || pv_errbuf;
            dka_tools_pkg.put_outdebug_message( CHR(10)||pv_errbuf);
        END IF;

        ----- Appel de la procédure PURGE DOCUMENT JOINT OI -----
        Purge_document_joint_oi (pv_errbuf, pn_retcode);

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'PURGE_DOCUMENT_JOINT_OI - ' || pv_errbuf;
            dka_tools_pkg.put_outdebug_message( CHR(10)||pv_errbuf);
        END IF;

    Fnd_File.put_line (Fnd_File.output,CHR(10)||'>>>> '||dka_tools_pkg.get_message('FND','CONC-CHECK LOG FOR DETAILS')||CHR(10));	
    Fnd_File.put_line (Fnd_File.output,'*******   FIN NORMAL DU TRAITEMENT   *******');

    dka_tools_pkg.put_debug_message ('(-) Main');
    
  EXCEPTION
    WHEN OTHERS THEN
      dka_tools_pkg.put_debug_message(SQLCODE || '=' || SQLERRM);
      pv_errbuf  := 'Erreur dans MAIN - ' || SQLERRM;
      pn_retcode := 2;
      ROLLBACK;
  END main;

END dka_iaploadimg_xerox_pkg;
/
show errors
exit;
