CREATE OR REPLACE PACKAGE BODY dka_spobon_stocimg_pkg AS
------------------------------------------------------------------------------------------
-- $$
-- CAPGEMINI
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SPOBON_STOCIMG_PKG.pkb
-- DESCRIPTION       : DKA_SPOBON_STOCIMG_PKG package body :
--
-- AUTEUR           : CAPGEMINI
-- DATE DE CREATION : 02/03/2007
-- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- ------------------------------------------------------------------------
-- 06/03/2008 EMA Optimisation de la recherche d'un document attaché de type 'BON DE COMMANDE'
--                dans la procedure Get_doc_bdc
--                Correction d'une anomalie concernant la récupération du dernier numéro 
--                de séquence 
-- 27/05/2008 ADR Report de maintenace ETANCHEITE 2007
-- 19/05/2016 MEG Migration R12
------------------------------------------------------------------------------------------

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PRIVEES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    gn_user_id                      fnd_user.user_id%TYPE;
    gn_login_id                     fnd_logins.login_id%TYPE;
    gn_org_id                       hr_all_organization_units.organization_id%TYPE;
    gn_request_id                   fnd_concurrent_requests.request_id%TYPE;
    gv_description                  VARCHAR2(250);
    gn_category_id                  NUMBER;
    gv_datatype_name                VARCHAR2(30) := 'FILE';
    gn_datatype_id                  NUMBER;
    gv_entity_name                  VARCHAR2(30) := 'PO_HEADERS';





----------------------------------------------------------------------------
--  Nom           : init
--  Description   : Procédure d'initialisation
--
--  PARAMETRES :
--    pv_errbuf   Entrée/Sortie          message d'erreur
--    VALEUR RETOURNEE :  pn_retcode
--  Valeurs possibles : 0=normal, 1=warning, 2=erreur
----------------------------------------------------------------------------
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
        gn_request_id                   := fnd_global.conc_request_id;
        gn_org_id                       := fnd_global.org_id /*fnd_profile.value ('ORG_ID')*/;

        -- Variables liées à la création du document joint
        Dka_Tools_Pkg.get_parameter ('SPOBON', 'DESCRIPTION', rec_param, pv_errbuf, pn_retcode);
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

        Dka_Tools_Pkg.get_parameter ('SPOBON', 'CATEGORY', rec_param, pv_errbuf, pn_retcode);
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


----------------------------------------------------------------------------
--  Nom           : get_po_header_id
--  Description   : Fonction qui renvoie en retour l'Id de la commande
--
--  PARAMETRES :
--    
--    VALEUR RETOURNEE :  pv_numero_cde
--  
----------------------------------------------------------------------------
    FUNCTION get_po_header_id (
        pv_numero_cde   IN   VARCHAR2
    )
    RETURN NUMBER
    IS
        vn_po_header_id   po_headers_all.po_header_id%TYPE;
    BEGIN
        SELECT DISTINCT po_header_id
        INTO   vn_po_header_id
        FROM   po_headers_all
        WHERE  segment1 = pv_numero_cde
        /*ETANCHEITE DALKIA 2007*/
        AND    org_id = gn_org_id;

        RETURN vn_po_header_id;

    END get_po_header_id;

----------------------------------------------------------------------------
--  Nom           : get_doc_bdc
--  Description   : Procédure permettant de récupérer les info d'un document
--                  attaché de type Bdc s'il existe
--
--  PARAMETRES :
--    pv_errbuf   Entrée/Sortie          message d'erreur
--    VALEUR RETOURNEE :  pn_retcode
--  Valeurs possibles : 0=normal, 1=warning, 2=erreur
----------------------------------------------------------------------------

    PROCEDURE get_doc_bdc (
        pv_po_header_id   IN   NUMBER,
        pv_media_id       OUT  NUMBER,
        pv_document_id    OUT  NUMBER,
        pv_errbuf      IN OUT  VARCHAR2,
        pn_retcode        OUT  NUMBER        
        )
    IS

        -- Curseur de lecture des documents attachés à la commande
        CURSOR cur_documents_joints IS
            SELECT fad.document_id
            FROM   fnd_attached_documents fad
            WHERE  fad.entity_name = gv_entity_name
            AND    fad.pk1_value   = pv_po_header_id
            ORDER BY fad.seq_num;

        rec_documents_joints         cur_documents_joints%ROWTYPE;
        vb_bdc_found                 BOOLEAN := FALSE;


    BEGIN

        dka_tools_pkg.put_debug_message ('(+) Get_doc_bdc');

        -- Debut modification EMA du 06/03/2008
        --
        -- BEGIN
        -- SELECT fdt.document_id,
        --        fdt.media_id
        -- INTO   pv_document_id,
        --        pv_media_id
        -- FROM   fnd_attached_documents fad,
        --        fnd_documents_tl fdt,
        --        fnd_documents fd
        -- WHERE  fdt.document_id = fad.document_id
        --   AND  fd.document_id = fdt.document_id
        --   AND  fd.category_id = gn_category_id  
        --   AND  fd.datatype_id = gn_datatype_id 
        --   AND  fdt.description = gv_description
        --   AND  fad.entity_name = gv_entity_name
        --   AND  fad.pk1_value = pv_po_header_id;
        --
        -- EXCEPTION
        --    WHEN NO_DATA_FOUND
        --    THEN
        --        pv_document_id := NULL;
        --        pv_media_id    := NULL;
        -- END;

        vb_bdc_found   := FALSE;
        pv_document_id := NULL;
        pv_media_id    := NULL;

        -- Boucle de lecture des documents attachés à la commande
        -- On sort de la boucle si on trouve un document de typre "BON DE COMMANDE"
        OPEN cur_documents_joints;
        LOOP
            FETCH cur_documents_joints INTO rec_documents_joints;
            EXIT WHEN cur_documents_joints%NOTFOUND OR vb_bdc_found;

            -- Pour le document joint trouvé, on regarde si il est de type "BON DE COMMANDE"
            BEGIN
                SELECT fdt.document_id,
                       fdt.media_id
                INTO   pv_document_id,
                       pv_media_id
                FROM   fnd_documents_tl fdt,
                       fnd_documents    fd
                WHERE  fdt.document_id = rec_documents_joints.document_id
                AND    fd.document_id  = fdt.document_id
                AND    fd.category_id  = gn_category_id
                AND    fd.datatype_id  = gn_datatype_id
                AND    fdt.description = gv_description
                AND    fdt.language    = userenv('LANG');

                -- Le document joint est de type "BON DE COMMANDE"
                -- On positionne l'indicateur vb_bdc_found pour sortir de la boucle
                vb_bdc_found := TRUE;
                dka_tools_pkg.put_debug_message ('==> Un document de type "BON DE COMMANDE" est déjà rattaché à cette commande (document_id : ' || 
                                                 pv_document_id || ', media_id : ' || pv_media_id || ').');

            EXCEPTION
                WHEN OTHERS THEN
                     -- Le document joint n'est pas de type "BON DE COMMANDE"
                     -- On passe au document joint suivant
                     NULL;
            END;

        END LOOP;
        CLOSE cur_documents_joints;

        -- Il n'existe aucun document de type "BON DE COMMANDE"
        IF NOT vb_bdc_found THEN
            dka_tools_pkg.put_debug_message ('==> Aucun document de type "BON DE COMMANDE" n''est rattaché à cette commande.');
        END IF;
 
        -- Fin modification EMA du 06/03/2008

        dka_tools_pkg.put_debug_message ('(-) Get_doc_bdc');

    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode   := 2;
            pv_errbuf    := 'GET_DOC_DBC : ' ||SQLERRM;

    END get_doc_bdc;

---------------------------------------------------------------------------
--  Nom           : chargement_image
--  Description   : procédure qui charge une image de bon de commande en table
--
--  PARAMETRES :
--    pv_errbuf   Entrée/Sortie          message d'erreur
--    VALEUR RETOURNEE :  pn_retcode
--  Valeurs possibles : 0=normal, 1=warning, 2=erreur
----------------------------------------------------------------------------
  PROCEDURE chargement_image
                   (pv_nom_fichier IN  VARCHAR2, 
                    pb_existe      OUT BOOLEAN, 
                    pn_file_id     OUT NUMBER, 
                    pv_errbuf      OUT VARCHAR2, 
                    pn_retcode     IN OUT NUMBER) 
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
    
    l_src_fich := bfilename('DALKIA_LOADBDC', pv_nom_fichier);
    pb_existe := DBMS_LOB.FILEEXISTS(l_src_fich) = 1;

    IF pb_existe
    THEN
      dbms_lob.fileopen(l_src_fich, dbms_lob.file_readonly);
      dbms_lob.loadfromfile(l_dst_fich, l_src_fich, dbms_lob.lobmaxsize, l_src_offset, l_dst_offset);
      SELECT fnd_lobs_s.NEXTVAL
      INTO   pn_file_id
      FROM   dual;

      dka_tools_pkg.put_debug_message ('pn_file_id: '||pn_file_id);

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
      replace(pv_nom_fichier,'.out','.pdf'),
      'application/pdf',
      l_dst_fich,
      'binary',
      sysdate,
      'FNDATTCH');

      DBMS_LOB.FILECLOSE(l_src_fich);
    ELSE
       pv_errbuf := 'chargement_image - ERREUR : Pas de fichier à charger';
       dka_tools_pkg.put_debug_message (pv_errbuf);
       pn_retcode := 2;
    END IF;

    dka_tools_pkg.put_debug_message ('(-) chargement_image');
    
  EXCEPTION
    WHEN OTHERS THEN
      dka_tools_pkg.put_debug_message('chargement_image - ' ||
                                      substr(SQLERRM, 1, 400));
      dka_tools_pkg.put_debug_message('chargement_image - ' || SQLERRM);
      pv_errbuf  := 'chargement_image - ' || SQLERRM;
      pn_retcode := 2;
      ROLLBACK;
  END chargement_image;
  

---------------------------------------------------------------------------
--  Nom           : delete_image
--  Description   : procédure qui charge une image de bon de commande en table
--
--  PARAMETRES :
--    pv_errbuf   Entrée/Sortie          message d'erreur
--    VALEUR RETOURNEE :  pn_retcode
--  Valeurs possibles : 0=normal, 1=warning, 2=erreur
----------------------------------------------------------------------------
  PROCEDURE delete_image
                   (pn_file_id  IN NUMBER, 
                    pv_errbuf   OUT VARCHAR2, 
                    pn_retcode  IN OUT NUMBER) 
  IS

  BEGIN
    dka_tools_pkg.put_debug_message ('(+) delete_image');
    pn_retcode := 0; 

      DELETE fnd_lobs
      WHERE file_id = pn_file_id;
  
    dka_Tools_Pkg.put_outdebug_message ('==>  Suppression de l''ancien BDC - file_id : '|| pn_file_id); 
    dka_tools_pkg.put_debug_message ('(-) delete_image');
  EXCEPTION
    WHEN OTHERS THEN
      dka_tools_pkg.put_debug_message('delete_image - ' ||
                                      substr(SQLERRM, 1, 400));
      dka_tools_pkg.put_debug_message('delete_image - ' || SQLERRM);
      pv_errbuf  := 'delete_image - ' || SQLERRM;
      pn_retcode := 2;
      ROLLBACK;
  END delete_image;

----------------------------------------------------------------------------
--  Nom           : create_attached_document_bdc
--  Description   : procédure qui crée le document attaché
--
--
--  PARAMETRES :
--    pv_errbuf   Entrée/Sortie          message d'erreur
--    VALEUR RETOURNEE :  pn_retcode
--  Valeurs possibles : 0=normal, 1=warning, 2=erreur
----------------------------------------------------------------------------
  PROCEDURE create_attached_document_bdc
                (pv_filename     IN VARCHAR2, 
                 pn_po_header_id IN NUMBER, 
                 pn_file_id      IN NUMBER, 
                 pv_errbuf       OUT VARCHAR2, 
                 pn_retcode      IN OUT NUMBER) 
  IS

    l_document_id NUMBER;
    l_attached_document_id NUMBER;
    l_num_seq NUMBER;
  BEGIN

    dka_tools_pkg.put_debug_message ('(+) create_attached_document_bdc');
    pn_retcode := 0;

    -- Recupération du dernier numéro de séquence 
    BEGIN
    -- SELECT seq_num + 10
    SELECT NVL(MAX(seq_num), 0) + 10
    INTO   l_num_seq
    FROM   fnd_attached_documents
    WHERE  entity_name   = gv_entity_name
           AND pk1_value = pn_po_header_id;

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
                  gv_description,
                  sysdate,
                  -1,
                  sysdate,
                  -1,
                  userenv('LANG'),
                  userenv('LANG'));



    INSERT INTO fnd_documents
                (document_id,
                file_name,
                category_id,
                datatype_id,
                creation_date,
                created_by,
                last_update_date,
                last_updated_by,
                security_type,
                security_id,
                publish_flag,
                media_id,
                usage_type)
           VALUES(l_document_id,
                  pv_filename,
                  gn_category_id,  
                  gn_datatype_id,  
                  sysdate,
                  -1,
                  sysdate,
                  -1,
                  1,
                  gn_org_id,
                  'Y',
                  pn_file_id,
                  'O');

    SELECT fnd_attached_documents_s.nextval 
    INTO l_attached_document_id 
    FROM DUAL;

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
                  l_num_seq,
                  gv_entity_name,
                  pn_po_header_id,
                  sysdate,
                  -1,
                  sysdate,
                  -1,
                  'N');

    dka_Tools_Pkg.put_outdebug_message ('==>  Création du document_id : '|| l_document_id);
    dka_tools_pkg.put_debug_message ('(-) create_attached_document_bdc');
    
  EXCEPTION
    WHEN OTHERS THEN
      dka_tools_pkg.put_debug_message(SQLCODE || '=' ||
                                      substr(SQLERRM, 1, 400));
      dka_tools_pkg.put_debug_message('create_attached_document_bdc - ' || SQLERRM);
      pv_errbuf  := 'create_attached_document_bdc - ' || SQLERRM;
      pn_retcode := 2;
      ROLLBACK;
  END create_attached_document_bdc;


----------------------------------------------------------------------------
--  Nom           : update_attached_document_bdc
--  Description   : procédure qui crée le document attaché
--
--
--  PARAMETRES :
--    pv_errbuf   Entrée/Sortie          message d'erreur
--    VALEUR RETOURNEE :  pn_retcode
--  Valeurs possibles : 0=normal, 1=warning, 2=erreur
----------------------------------------------------------------------------
  PROCEDURE update_attached_document_bdc
                (pv_filename     IN VARCHAR2, 
                 pn_file_id      IN NUMBER,
                 pn_document_id  IN NUMBER, 
                 pv_errbuf       OUT VARCHAR2, 
                 pn_retcode      IN OUT NUMBER) 
  IS

  BEGIN

    dka_tools_pkg.put_debug_message ('(+) update_attached_document_bdc');
    pn_retcode := 0;

    UPDATE fnd_documents_tl
    SET    file_name        = pv_filename
          ,media_id         = pn_file_id
          ,last_update_date = sysdate
          ,last_updated_by  = -1
    WHERE  document_id = pn_document_id;

    UPDATE fnd_documents
    SET    file_name        = pv_filename
          ,media_id         = pn_file_id
          ,last_update_date = sysdate
          ,last_updated_by  = -1
    WHERE  document_id = pn_document_id;

    Dka_Tools_Pkg.put_outdebug_message ('==>  Mise à jour du document_id : '|| pn_document_id);
    
    dka_tools_pkg.put_debug_message ('(-) update_attached_document_bdc');
  EXCEPTION
    WHEN OTHERS THEN
      dka_tools_pkg.put_debug_message(SQLCODE || '=' ||
                                      substr(SQLERRM, 1, 400));
      dka_tools_pkg.put_debug_message('update_attached_document_bdc - ' || SQLERRM);
      pv_errbuf  := 'update_attached_document_bdc - ' || SQLERRM;
      pn_retcode := 2;
      ROLLBACK;
  END update_attached_document_bdc;



----------------------------------------------------------------------------
--  Nom           : main
--  Description   : procédure principale du stockage des bons de commande
--
--
--  PARAMETRES :
--    pv_errbuf   Entrée/Sortie          message d'erreur
--    VALEUR RETOURNEE :  pn_retcode
--  Valeurs possibles : 0=normal, 1=warning, 2=erreur
----------------------------------------------------------------------------

  PROCEDURE main
           (pv_errbuf IN OUT VARCHAR2,
            pn_retcode OUT NUMBER) 

  IS

    v_request_set_id       NUMBER;
    v_bdc_request_id       NUMBER;
    v_po_num               fnd_concurrent_requests.argument3%TYPE;
    v_output_file          VARCHAR2(100);
    v_existe               BOOLEAN;
    v_file_id              NUMBER;
    v_po_header_id         po_headers_all.po_header_id%TYPE;
    v_media_id             fnd_documents_tl.media_id%TYPE;
    v_document_id          fnd_documents_tl.document_id%TYPE;
    e_ivalua            EXCEPTION;
    
    l_retcode           NUMBER := 0;
    l_count             NUMBER;
  BEGIN
  	        
        dka_tools_pkg.put_debug_message ('(+) main');

        ----- Initialisation des variables de sortie de la procédure -----
        pv_errbuf     := NULL;
        pn_retcode    := 0;
        Dka_Tools_Pkg.put_debug_message (CHR (10) || 'début de la procédure principale' || CHR (10));

        ----- Appel de la procédure INIT -----
        init (pv_errbuf, pn_retcode);

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'INIT - ' || pv_errbuf;
            Dka_Tools_Pkg.put_outdebug_message( CHR(10)||pv_errbuf);
            RETURN;
        END IF;
        
        Dka_Tools_Pkg.put_outdebug_message('***** RECUPERATION DES PARAMETRES *****');
        Dka_Tools_Pkg.put_outdebug_message( CHR(10));

        SELECT fcr1.request_id,
               fcr3.parent_request_id,
               fcr1.argument3,
               SUBSTR (fcr1.outfile_name, INSTR (fcr1.outfile_name, '/', -1, 1) + 1)
        INTO   v_bdc_request_id,
               v_request_set_id,
               v_po_num,
               v_output_file
        FROM   fnd_concurrent_requests fcr1, -- prog edition bdc
               fnd_concurrent_requests fcr2, -- etape edition bdc
               fnd_concurrent_requests fcr3, -- etape stockage bdc
               fnd_concurrent_requests fcr4  -- prog stockage bdc
        WHERE      fcr4.request_id = gn_request_id
               AND fcr3.request_id = fcr4.parent_request_id + 0
               AND fcr2.parent_request_id = fcr3.parent_request_id + 0
               AND fcr1.parent_request_id = fcr2.request_id + 0
               AND fcr1.output_file_type = 'PDF';

        Dka_Tools_Pkg.put_outdebug_message ('request_id : '|| TO_CHAR (gn_request_id));
        Dka_Tools_Pkg.put_outdebug_message ('request_id edition bdc  : '|| TO_CHAR (v_bdc_request_id));
        Dka_Tools_Pkg.put_outdebug_message ('request_id du jeu : '|| TO_CHAR (v_request_set_id));
        Dka_Tools_Pkg.put_outdebug_message ('num commande : '|| v_po_num);
        Dka_Tools_Pkg.put_outdebug_message ('fichier bdc : '|| v_output_file);
        Dka_Tools_Pkg.put_outdebug_message ('identifiant de l''organisation : '|| gn_org_id);
        
        SELECT 
          COUNT(1)
        INTO 
          l_count
        FROM
         po_headers ph
        WHERE
         ph.segment1 = v_po_num
         AND ph.org_id = gn_org_id
         AND NVL(ATTRIBUTE7, 'ORACLE') IN ('IVALUA', 'REPRISE')
        ;
        
        IF l_count > 0 THEN
          RAISE e_ivalua;
        END IF;

        -- Récupération de l'Id de la commande
        v_po_header_id := get_po_header_id(v_po_num);
        Dka_Tools_Pkg.put_outdebug_message ('Id commande : '|| v_po_header_id);

        Dka_Tools_Pkg.put_outdebug_message( CHR(10));
        Dka_Tools_Pkg.put_outdebug_message('***** STOCKAGE DU BON DE COMMANDE *****');
        Dka_Tools_Pkg.put_outdebug_message( CHR(10));

        -- Chargement de l'image en table
        chargement_image(pv_nom_fichier => v_output_file, 
                         pb_existe      => v_existe, 
                         pn_file_id     => v_file_id, 
                         pv_errbuf      => pv_errbuf, 
                         pn_retcode     => pn_retcode);
        
        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'CHARGEMENT IMAGE - ' || pv_errbuf;
            Dka_Tools_Pkg.put_outdebug_message( CHR(10)||pv_errbuf);
            RETURN;
        END IF;        
        

        -- Recherche si un document attaché BDC existe déjà sur la commande
        get_doc_bdc (pv_po_header_id   => v_po_header_id,
                     pv_media_id       => v_media_id,
                     pv_document_id    => v_document_id,
                     pv_errbuf         => pv_errbuf,
                     pn_retcode        => pn_retcode);


        IF v_document_id IS NOT NULL
        THEN
                      
            -- Mise à jour du document existant avec le nouveau fichier
            Dka_Tools_Pkg.put_outdebug_message ('Un document de type "BON DE COMMANDE" est déjà rattaché à cette commande.');
            update_attached_document_bdc
                (pv_filename     => v_output_file, 
                 pn_file_id      => v_file_id,
                 pn_document_id  => v_document_id, 
                 pv_errbuf       => pv_errbuf, 
                 pn_retcode      => pn_retcode);             
 

            IF pn_retcode != 0
            THEN
                 pv_errbuf    := 'UPDATE ATTACHED DOCUMENT BDC - ' || pv_errbuf;
                 Dka_Tools_Pkg.put_outdebug_message( CHR(10)||pv_errbuf);
                 RETURN;
            END IF;

            -- Suppression de l'ancien fichier
            delete_image
                   (pn_file_id   => v_media_id, 
                    pv_errbuf    => pv_errbuf, 
                    pn_retcode   => pn_retcode);


            IF pn_retcode != 0
            THEN
                 pv_errbuf    := 'DELETE IMAGE - ' || pv_errbuf;
                 Dka_Tools_Pkg.put_outdebug_message( CHR(10)||pv_errbuf);
                 RETURN;
            END IF;   
        
        ELSE
        
             -- Création d'un nouveau document joint
            create_attached_document_bdc
                (pv_filename     => v_output_file, 
                 pn_po_header_id => v_po_header_id, 
                 pn_file_id      => v_file_id, 
                 pv_errbuf       => pv_errbuf, 
                 pn_retcode      => pn_retcode);
 
             IF pn_retcode != 0
             THEN
                 pv_errbuf    := 'CREATE ATTACHED DOCUMENT BDC - ' || pv_errbuf;
                 Dka_Tools_Pkg.put_outdebug_message( CHR(10)||pv_errbuf);
                 RETURN;
             END IF;                  
        END IF;         
                              
        Dka_Tools_Pkg.put_outdebug_message(CHR(10));
        Dka_Tools_Pkg.put_outdebug_message('***** FIN DU TRAITEMENT *****');

        dka_tools_pkg.put_debug_message ('(-) main');                                 

  EXCEPTION
   WHEN e_ivalua THEN
     pv_errbuf  := 'Commande IVALUA ou REPRISE, pas d''envoi de mail';
     pn_retcode := 1;
     Dka_Tools_Pkg.put_outdebug_message(pv_errbuf);  
  END main;

END dka_spobon_stocimg_pkg;
/
SHOW ERROR

EXIT
