CREATE OR REPLACE PACKAGE BODY dka_spaploadimg_pkg AS
  ----------------------------------------------------------------------------------------------
  -- $$
  -- CAPGEMINI
  -- PROJET            : DALKIA Oracle Applications
  -- NOM               : DKA_OASCAN_PKG.pks
  -- DESCRIPTION       : DKA_OASCAN_PKG package body :
  ---
  --- AUTEUR           : Nicolas Boussekeyt (CAPGEMINI)
  --- DATE DE CREATION : 31/03/2005
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
  ----------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- 22/03/2006 GV  - Optimisation du package
  ---                   * suppression de la procédure verif_document, car elle revient à faire un test d'existence,
  ---                     qui peut être placé directement dans le curseur principal
  ---                   * ajout dans ce test d'existence du champ entity_name afin d'utiliser
  ---                     l'index standard FND_ATTACHED_DOCUMENTS_N1
  ---                   * Déplacement dans main de 2 requêtes ulilisées dans la procédure attach_doc_facture
  ---                - Ajout du bloc de l'exception e_exception1 qui n'existait pas!
  --- 27/06/2006 GV  main : - ajout d'un bloc de gestion d'erreur au sein de la boucle
  ---                       - déplacement du COMMIT à l'intérieur de la boucle
  ---                       - remaniement des traces de journal
  ---                charge_image + attach_doc_facture : ajout du réinit de pn_retcode
  --- 06/07/2006 GV  changement de valeur pour la variable globale g_categorie_doc => on la passe en MISC
  ---                main : le nom de limage déplacée est maintenant horodatée
  --- 15/02/2007 FM  Les temps de traitement pour la lecture du cursor deviennent trop long, utilisation MINUS, renseigner le numéro de
  ---                facture dans la sortie.
  --- 29/01/2008 GV  main : ajout du folio ECO
  --- 20/01/2012 CD Prise en compte de la dématérialisation des factures GDF
  --- 16/05/2013 BCO INC000000408547 - Oracle - Dématérialisation
  --- 26/07/2016 RGH  Migration R12
  --- 23/06/2017 YWA  artf2176002 : INT037 - EDB074 - Prise en compte des factures manuelles et folio CEE 
  --- 30/06/2017 YWA  artf2188850  
  --- 28/08/2018 OBE  artf3024813 : INC0242938 - Correctif Facture AP inaccessible
  --- 17/01/2020 SLH  EDB090 : Non respect de la casse sur le nom des images
  --- 23/08/2021 SHA  artf07477494 : INC0576461
  --- 26/01/2022 AFE TASK0166067 : Régression suite MEP du correctif INC0576461  
  --------------------------------------------------------------------------------------------

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PRIVEES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  g_extension VARCHAR2(10) := 'TIF';
  g_categorie_doc VARCHAR2(40) := 'MISC'; -- GV20060706
  g_entity_name VARCHAR2(30) := 'AP_INVOICES';
  g_source VARCHAR2(30) := 'SCAN';
  g_category_id NUMBER; -- Ajout GV20060322
  g_datatype_id NUMBER; -- Ajout GV20060322
  g_file_datatype_id NUMBER;   -- CD 20/01/2012
  g_web_datatype_id  NUMBER;   -- CD 20/01/2012
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PRIVEES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PUBLIQUES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

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
  PROCEDURE main(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER) IS
    -- Curseurs
    -- Modif FM20070215 : pblm temps du job ==> Changer le cursor, ajout à partir de MINUS ....
    -- Modif GV20080129 : ajout du folio ECO
    CURSOR c_dka_invoices IS
      SELECT * FROM ap_invoices_all aia
      WHERE --aia.attribute9 in ('OSC', 'NRJ', 'ECO') --RGH Migration R12
        aia.attribute9 IN (SELECT ffvv.flex_value
                          FROM   fnd_flex_value_sets ffvs,
                                 fnd_flex_values_vl  ffvv
                          WHERE  ffvs.flex_value_set_id = ffvv.flex_value_set_id
                          AND    ffvs.flex_value_set_name = 'DKA_PARAM_FOLIO_AP'
                          AND    ffvv.enabled_flag = 'Y'
                          AND    SYSDATE BETWEEN nvl(ffvv.start_date_active, SYSDATE) AND
                                 nvl(ffvv.end_date_active, SYSDATE)
                          AND ffvv.attribute14= 'OUI')-- YWA EDB074 in ('CEG', 'CEC', 'ECO')
        AND aia.attribute3 IS NOT NULL
      MINUS
      SELECT * FROM ap_invoices_all aia
      WHERE --aia.attribute9 in ('OSC', 'NRJ', 'ECO') --RGH Migration R12
      aia.attribute9 IN (SELECT ffvv.flex_value
                          FROM   fnd_flex_value_sets ffvs,
                                 fnd_flex_values_vl  ffvv
                          WHERE  ffvs.flex_value_set_id = ffvv.flex_value_set_id
                          AND    ffvs.flex_value_set_name = 'DKA_PARAM_FOLIO_AP'
                          AND    ffvv.enabled_flag = 'Y'
                          AND    SYSDATE BETWEEN nvl(ffvv.start_date_active, SYSDATE) AND
                                 nvl(ffvv.end_date_active, SYSDATE)
                          AND ffvv.attribute14= 'OUI')-- YWA EDB074 in ('CEG', 'CEC', 'ECO')
      AND aia.attribute3 IS NOT NULL
      AND EXISTS (select 'X' from fnd_attached_documents fad
                  where fad.entity_name = g_entity_name
                  and fad.pk1_value = aia.invoice_id)
      /*AND NOT EXISTS (select 'X' from fnd_attached_documents fad
                      where fad.entity_name = g_entity_name
                      and fad.pk1_value = aia.invoice_id)*/
        ;

    -- Record
    c_dka_invoices_rec c_dka_invoices%ROWTYPE;
    e_exception1 EXCEPTION;
    l_existe BOOLEAN;
    l_file_id NUMBER;
    vn_nb_lignes_lues       NUMBER := 0;
    vn_nb_factures_ok       NUMBER := 0;
    vn_nb_factures_ko       NUMBER := 0;
    vn_nb_images_manquantes NUMBER := 0; -- Ajout GV20060627
    pn_retcode_1            BOOLEAN := FALSE; -- Ajout GV20060627
    pn_retcode_2            BOOLEAN := FALSE; -- Ajout GV20060627

    rec_param               dka_parameters%ROWTYPE;
    vv_url                  dka_parameters.varchar2_value%TYPE;


  BEGIN
    pn_retcode := 0;
    Dka_Tools_Pkg.put_log_message ('> Début procédure MAIN');

     -- Modif GV20060322 : Les 2 select suivants ont été déplacés de la procédure attach_doc_facture
     select category_id
     into g_category_id
     from fnd_document_categories
     where name = g_categorie_doc;

     select datatype_id
     --into g_datatype_id                 CD 20/01/2012
     into g_file_datatype_id           -- CD 20/01/2012
     from fnd_document_datatypes
     where user_name = 'Fichier';

     -- Modif CD du 20/01/2012
     select datatype_id
     into g_web_datatype_id
     from fnd_document_datatypes
     where user_name = 'Page Web';


    FOR c_dka_invoices_rec IN c_dka_invoices LOOP
      BEGIN
          vn_nb_lignes_lues := vn_nb_lignes_lues + 1;
        -- Modif GV20060322 : verif_document ne sert plus
        --verif_document(c_dka_invoices_rec.invoice_id, l_existe, pv_errbuf, pn_retcode);

        --IF pn_retcode != 0 THEN
        --   RAISE e_exception1;
        --END IF;

        --IF l_existe = FALSE THEN

          -- Début Modif EMA 20/01/2012 : Si l'ATTRIBUTE12 n'est pas renseigné ou est renseigné par 'ALA',
          -- le chargement des images est effectué
          l_existe := FALSE;
          IF (c_dka_invoices_rec.attribute12 IS NULL ) THEN
            charge_image(c_dka_invoices_rec.attribute3, l_existe, l_file_id, pv_errbuf, pn_retcode);
          ELSE--YWA EDB074
              BEGIN
                  SELECT ffvv.flex_value
                  INTO   c_dka_invoices_rec.attribute12
                  FROM   fnd_flex_value_sets ffvs,
                         fnd_flex_values_vl  ffvv
                  WHERE  ffvs.flex_value_set_id = ffvv.flex_value_set_id
                  AND    ffvs.flex_value_set_name = 'DKA_TYPE_RATTACHEMENT_IMAGE'
                  AND    ffvv.enabled_flag = 'Y'
                  AND    SYSDATE BETWEEN nvl(ffvv.start_date_active, SYSDATE) AND
                         nvl(ffvv.end_date_active, SYSDATE)
                  AND ffvv.flex_value = c_dka_invoices_rec.attribute12 ;--YWA EDB074
              
                charge_image(c_dka_invoices_rec.attribute3, l_existe, l_file_id, pv_errbuf, pn_retcode);
              EXCEPTION  
                WHEN OTHERS THEN
                    Dka_Tools_Pkg.put_log_message('Pas de chargement d''image la valeur '||c_dka_invoices_rec.attribute12||' est introuvable dans le JDV DKA_TYPE_RATTACHEMENT_IMAGE');--YWA artf2188850 
                    --NULL;
              END;      
          END IF;
          -- Fin modif EMA du 20/01/2012

          IF pn_retcode != 0
          THEN
              RAISE e_exception1;
          END IF;

          IF l_existe
          THEN
              -- Le document joint est de type 'Fichier'
              g_datatype_id := g_file_datatype_id;

              attach_doc_facture(c_dka_invoices_rec.attribute3,NULL, c_dka_invoices_rec.invoice_id, l_file_id, pv_errbuf, pn_retcode);
			           UTL_FILE.FRENAME ('DALKIA_LOADIMG', upper(c_dka_invoices_rec.attribute3), 'DALKIA_MOVEIMG', upper(c_dka_invoices_rec.attribute3) || '_' || to_char(SYSDATE, 'YYYYMMDDHH24MISS'));

              IF pn_retcode != 0
              THEN
                  RAISE e_exception1;
              END IF;

              Dka_Tools_Pkg.put_log_message('   > Traitement OK de l''image ' || c_dka_invoices_rec.attribute3 || ' de la facture N° ' || c_dka_invoices_rec.invoice_num || ' ,Id ' || c_dka_invoices_rec.invoice_id);
              vn_nb_factures_ok := vn_nb_factures_ok + 1;
              -- Modif GV20060627 : on fait un COMMIT ici pour éviter que les données insérées ne soient annulées en cas de plantage
              COMMIT;
          -- Modif CD du 20/01/2012 : Cas des images dématérialisées
          --ELSIF (c_dka_invoices_rec.attribute12 IS NOT NULL AND c_dka_invoices_rec.attribute12 != 'ALA')
		  -- Modif BCO du 16/05/2013 : INC000000408547 - Oracle - Dématérialisation
		  ELSIF c_dka_invoices_rec.attribute12 = 'DKM-GDF'
          THEN
              -- Le début de l'URL est stockée dans la table Dka_Parameters
              Dka_Tools_Pkg.get_parameter ('DKA_SPAPLOADIMG', c_dka_invoices_rec.attribute12, rec_param, pv_errbuf, pn_retcode);
              vv_url := rec_param.varchar2_value;
              -- On ajoute un '/' à la fin de l'URL si nécessaire
              IF SUBSTR(vv_url, -1) != '/'
              THEN
                  vv_url := vv_url || '/';
              END IF;

              IF pn_retcode != 0
              THEN
                  RAISE e_exception1;
              END IF;

              -- Le document joint est de type 'Page Web'
              g_datatype_id := g_web_datatype_id;
              attach_doc_facture(NULL, vv_url ||c_dka_invoices_rec.attribute3, c_dka_invoices_rec.invoice_id, NULL, pv_errbuf, pn_retcode);

              Dka_Tools_Pkg.put_log_message('   > Traitement OK de l''image ' || vv_url || c_dka_invoices_rec.attribute3 || ' de la facture N° ' || c_dka_invoices_rec.invoice_num || ' ,Id ' || c_dka_invoices_rec.invoice_id);
              vn_nb_factures_ok := vn_nb_factures_ok + 1;
              COMMIT;
              -- Fin Modif CD du 20/01/2012
          ELSE
              Dka_Tools_Pkg.put_log_message('   > Traitement KO de la facture N° ' || c_dka_invoices_rec.invoice_num || ' ,Id ' || c_dka_invoices_rec.invoice_id || ' ==> L''image '|| c_dka_invoices_rec.attribute3 || ' n''a pas été trouvée');

              vn_nb_images_manquantes := vn_nb_images_manquantes + 1;
          END IF;
        --END IF;

        EXCEPTION
        -- Modif GV20060322 : Ajout bloc pour l'exception e_exception1
           WHEN e_exception1 THEN
                vn_nb_factures_ko := vn_nb_factures_ko + 1;
                Dka_Tools_Pkg.put_log_message('   > Traitement KO de l''image ' || c_dka_invoices_rec.attribute3 || ' de la facture N° Id ' || c_dka_invoices_rec.invoice_id);
                dka_tools_pkg.put_log_message('         ==> ' || pv_errbuf);

                IF NOT pn_retcode_1 THEN pn_retcode_1 := TRUE; END IF; -- Le traitement finit en avertissement
                ROLLBACK;

           WHEN OTHERS THEN
                vn_nb_factures_ko := vn_nb_factures_ko + 1;
                Dka_Tools_Pkg.put_log_message('   > Traitement KO de l''image ' || c_dka_invoices_rec.attribute3 || ' de la facture N° Id ' || c_dka_invoices_rec.invoice_id);
                dka_tools_pkg.put_log_message('         ==> ' || SQLCODE || ' : ' || SQLERRM);
                pv_errbuf  := 'Erreur dans la boucle - ' || SQLERRM;
                IF NOT pn_retcode_2 THEN pn_retcode_2 := TRUE; END IF; -- Le traitement finit en erreur
                ROLLBACK;

      END;
    END LOOP; -- Fin du traitement

    IF pn_retcode_2
    THEN
        pn_retcode := 2;
    ELSIF pn_retcode_1
    THEN
        pn_retcode := 1;
    ELSE
        pn_retcode := 0;
    END IF;

    --COMMIT; -- Modif GV20060627 : le COMMIT s'effectue dans la boucle FOR
    Dka_Tools_Pkg.put_log_message('< Fin procédure MAIN');
    dka_tools_pkg.put_log_message(' Nombre de lignes lues           : ' || vn_nb_lignes_lues);
    Dka_Tools_Pkg.put_log_message(' Nombre de factures traitées     : ' || vn_nb_factures_ok);
    Dka_Tools_Pkg.put_log_message(' Nombre de factures sans images  : ' || vn_nb_images_manquantes);
    Dka_Tools_Pkg.put_log_message(' Nombre de factures en erreur    : ' || vn_nb_factures_ko);

  EXCEPTION
    -- Modif GV20060322 : Ajout bloc pour l'exception e_exception1 => Modif GV20060627 : déplacé dans la boucle FOR
    --WHEN e_exception1 THEN
    --  dka_tools_pkg.put_log_message(pv_errbuf);
    --  dka_tools_pkg.put_log_message('Aucune facture n''a été traitée');
    --  ROLLBACK;

    WHEN OTHERS THEN
      dka_tools_pkg.put_log_message(SQLCODE || '=' ||
                                      substr(SQLERRM, 1, 400));
      pv_errbuf  := 'Erreur dans MAIN - ' || SQLERRM;
      pn_retcode := 2;
      ROLLBACK;
  END main;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : verif_document
  --  Description   : procédure qui vérifie si il y a des documents attaché sur la facture
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  /*PROCEDURE verif_document(pn_invoice_id IN NUMBER, pb_existe OUT BOOLEAN, pv_errbuf OUT VARCHAR2, pn_retcode IN OUT NUMBER) IS
    l_count NUMBER;

  BEGIN
    dbms_output.put_line('>>>> verif_document');
    SELECT COUNT(*) INTO l_count
    FROM FND_ATTACHED_DOCUMENTS WHERE PK1_VALUE = pn_invoice_id;

    IF l_count != 0 THEN
       pb_existe := TRUE;
    ELSE
       pb_existe := FALSE;
    END IF;
    dbms_output.put_line('<<<< verif_document');
  EXCEPTION
    WHEN OTHERS THEN
      dka_tools_pkg.put_log_message(SQLCODE || '=' ||
                                      substr(SQLERRM, 1, 400));
      dbms_output.put_line('verif_document - ' || SQLERRM);
      pv_errbuf  := 'verif_document - ' || SQLERRM;
      pn_retcode := 2;
      ROLLBACK;
  END verif_document;*/

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : charge_image
  --  Description   : procédure qui charge une image de facture en table
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE charge_image(pn_invoice IN VARCHAR2, pb_existe OUT BOOLEAN, pn_file_id OUT NUMBER, pv_errbuf OUT VARCHAR2, pn_retcode IN OUT NUMBER) IS
    l_length NUMBER;
    l_blocksize NUMBER;
    l_src_fich BFILE;
    l_dst_fich BLOB;
    l_src_offset NUMBER := 1;
    l_dst_offset NUMBER := 1;
    l_nom_img VARCHAR2(300);


  BEGIN

    pn_retcode := 0; -- Ajout GV20060627 : initialisation du code retour
    -- SELO : recherche par le nom de fichier en majuscule
	--l_nom_img := pn_invoice;
	BEGIN
	select upper(pn_invoice)
	  into l_nom_img 
	  from dual;

	EXCEPTION WHEN OTHERS THEN
	l_nom_img := pn_invoice;
    END; 

    dbms_lob.createtemporary(l_dst_fich,true,dbms_lob.session);

    l_src_fich := bfilename('DALKIA_LOADIMG', l_nom_img);

    pb_existe := DBMS_LOB.FILEEXISTS(l_src_fich) = 1;

    IF pb_existe
    THEN

      dbms_lob.fileopen(l_src_fich, dbms_lob.file_readonly);

      dbms_lob.loadfromfile(l_dst_fich, l_src_fich, dbms_lob.lobmaxsize, l_src_offset, l_dst_offset);

      SELECT fnd_lobs_s.NEXTVAL
      INTO   pn_file_id
      FROM   dual;

      insert into fnd_lobs
      (file_id,
      file_name,
      file_content_type,
      file_data,
      file_format,
      upload_date,
      program_name)
      values
      (pn_file_id,
      l_nom_img,
      'Image/tiff',
      l_dst_fich,
      'binary',
      sysdate,
      'FNDATTCH');

      DBMS_LOB.FILECLOSE(l_src_fich);

    END IF;

  EXCEPTION
    WHEN OTHERS THEN

      dka_tools_pkg.put_log_message('charge_image - ' ||
                                      substr(SQLERRM, 1, 400));
      dka_tools_pkg.put_log_message('charge_image - ' || SQLERRM);

      pv_errbuf  := 'charge_image - ' || SQLERRM;
      pn_retcode := 2;
      ROLLBACK;
  END charge_image;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : attach_doc_facture
  --  Description   : procédure qui charge une image de facture en table
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE attach_doc_facture(pv_filename IN VARCHAR2, pv_urlname IN VARCHAR2, pn_invoice_id IN NUMBER, pn_file_id IN NUMBER, pv_errbuf OUT VARCHAR2, pn_retcode IN OUT NUMBER) IS

    l_document_id NUMBER;
   -- l_category_id NUMBER; Modif GV20060322
   -- l_datatype_id NUMBER; Modif GV20060322
    l_attached_document_id NUMBER;
  BEGIN

    pn_retcode := 0; -- Ajout GV20060627 : initialisation du code retour

    SELECT fnd_documents_s.nextval
    INTO l_document_id
    FROM DUAL;

    INSERT INTO fnd_documents_tl
                (document_id,
                file_name,
                media_id,
                creation_date,
                created_by,
                last_update_date,
                last_updated_by,
                language,
                source_lang)
           VALUES(l_document_id,
                  upper(pv_filename),
                  pn_file_id,
                  sysdate,
                  -1,
                  sysdate,
                  -1,
                  userenv('LANG'),
                  userenv('LANG'));

    -- Modif GV20060322 : déplacement dans main des 2 select
    /*BEGIN

         select category_id
         into l_category_id
         from fnd_document_categories
         where name = g_categorie_doc;

         EXCEPTION
         WHEN NO_DATA_FOUND THEN
               dka_tools_pkg.put_log_message(SQLCODE || '=' ||
                                      substr(SQLERRM, 1, 400));
               dbms_output.put_line('attach_doc_facture - fnd_document_categories - ' || SQLERRM);
               pv_errbuf  := 'attach_doc_facture - fnd_document_categories - ' || SQLERRM;
               pn_retcode := 2;
               ROLLBACK;
               RETURN;
    END;

    BEGIN

         select datatype_id
         into l_datatype_id
         from fnd_document_datatypes
         where user_name = 'Fichier';

         EXCEPTION
         WHEN NO_DATA_FOUND THEN
               dka_tools_pkg.put_log_message(SQLCODE || '=' ||
                                      substr(SQLERRM, 1, 400));
               dbms_output.put_line('attach_doc_facture - fnd_document_datatypes - ' || SQLERRM);
               pv_errbuf  := 'attach_doc_facture - fnd_document_datatypes - ' || SQLERRM;
               pn_retcode := 2;
               ROLLBACK;
               RETURN;
    END;*/

    INSERT INTO fnd_documents
                (document_id,
                file_name,   --RGH migration R12
                media_id,    --RGH Migration R12
                URL,         --RGH Migration R12
                category_id,
                datatype_id,
                creation_date,
                created_by,
                last_update_date,
                last_updated_by,
                SECURITY_TYPE,
                PUBLISH_FLAG,
				USAGE_TYPE) -- OBE artf3024813
           VALUES(l_document_id,
                  upper(pv_filename),   --RGH Migration R12
                  pn_file_id,    --RGH Migration R12
                  pv_urlname,    --RGH Migration R12
                  --l_category_id, -- Modif GV20060322
                  --l_datatype_id, -- passage en
                  g_category_id,   -- variables
                  g_datatype_id,   -- globales
                  sysdate,
                  -1,
                  sysdate,
                  -1,
                  2,
                  'Y',
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
                AUTOMATICALLY_ADDED_FLAG)
           VALUES(l_attached_document_id,
                  l_document_id,
                  10,
                  g_entity_name,
                  pn_invoice_id,
                  sysdate,
                  -1,
                  sysdate,
                  -1,
                  'N');



  EXCEPTION
    WHEN OTHERS THEN

      dka_tools_pkg.put_log_message(SQLCODE || '=' ||
                                      substr(SQLERRM, 1, 400));
      dka_tools_pkg.put_log_message('attach_doc_facture - ' || SQLERRM);
      pv_errbuf  := 'attach_doc_facture - ' || SQLERRM;
      pn_retcode := 2;
      ROLLBACK;
  END attach_doc_facture;


  ---------------------------------------------------------------------------------
END dka_spaploadimg_pkg;

/
show errors
exit;
