CREATE OR REPLACE PACKAGE BODY DKA_SAPVIR_ATTACH_PKG AS
    ------------------------------------------------------------------------------------------
    -- $$
    -- CAPGEMINI
    -- PROJET            : DALKIA Oracle Applications
    -- NOM               : DKA_SAPVIR_ATTACH_PKG.pkb
    -- DESCRIPTION       : DKA_SAPVIR_ATTACH_PKG package body :
    --
    -- AUTEUR           : CAPGEMINI
    -- DATE DE CREATION : 19/08/2013
    -- DOC. ASSOCIEE    :
    -- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
    ------------------------------------------------------------------------------------------
    -- HISTORIQUE DES MODIFICATIONS
    -- Date       Qui Description
    -- ---------- --- ------------------------------------------------------------------------
    -- 20/12/2013 BCO Optimisation du traitement (exécution d'un traitement unique pour l'ensemble des virements).
    -- 10/10/2016 RBE Migration R12
    --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    -- CONSTANTES ET VARIABLES PRIVEES
    --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    gn_user_id       fnd_user.user_id%TYPE;
    gn_login_id      fnd_logins.login_id%TYPE;
    gn_org_id        hr_all_organization_units.organization_id%TYPE;
    gv_description   VARCHAR2(250);
    gn_category_id   NUMBER;
    gv_datatype_name VARCHAR2(30) := 'FILE';
    gn_datatype_id   NUMBER;
    gv_entity_name   VARCHAR2(30) := 'AP_CHECKS';

    g_step VARCHAR2(500);

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
    END out_msg;

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
    END log_msg;

    ----------------------------------------------------------------------------
    --  Nom           : init
    --  Description   : Procédure d'initialisation
    --
    --  PARAMETRES :
    --    pv_errbuf   Entrée/Sortie          message d'erreur
    --    VALEUR RETOURNEE :  pn_retcode
    --  Valeurs possibles : 0=normal, 1=warning, 2=erreur
    ----------------------------------------------------------------------------
    PROCEDURE init(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER) IS
        rec_param   dka_parameters%ROWTYPE;
        vv_category fnd_document_categories.name%TYPE;
    
    BEGIN
        g_step := 'INIT 000 - DEBUT';
        log_msg(g_step);
        pv_errbuf  := NULL;
        pn_retcode := 0;
    
        -- En-tête du fichier de sortie
        dka_tools_pkg.put_out_header;
    
        -- Variables globale "WHO"
        gn_user_id  := fnd_global.user_id;
        gn_login_id := fnd_global.login_id;
        gn_org_id   := fnd_profile.value('ORG_ID');
    
        -- Variables liées à la création du document joint
        Dka_Tools_Pkg.get_parameter('DKA_SAPVIR_ATTACH',
                                    'DESCRIPTION',
                                    rec_param,
                                    pv_errbuf,
                                    pn_retcode);
        gv_description := rec_param.varchar2_value;
    
        IF pn_retcode != 0 THEN
            pv_errbuf := 'Paramètre DESCRIPTION : ' || pv_errbuf;
            RETURN;
        ELSIF gv_description IS NULL THEN
            pv_errbuf  := 'Paramètre DESCRIPTION : Aucune donnée trouvée';
            pn_retcode := 2;
            RETURN;
        END IF;
    
        g_step := 'INIT 001 - DESCRIPTION : ' || gv_description;
        log_msg(g_step);
    
        Dka_Tools_Pkg.get_parameter('DKA_SAPVIR_ATTACH',
                                    'CATEGORY',
                                    rec_param,
                                    pv_errbuf,
                                    pn_retcode);
        vv_category := rec_param.varchar2_value;
    
        IF pn_retcode != 0 THEN
            pv_errbuf := 'Paramètre CATEGORY : ' || pv_errbuf;
            RETURN;
        ELSIF vv_category IS NULL THEN
            pv_errbuf  := 'Paramètre CATEGORY : Aucune donnée trouvée';
            pn_retcode := 2;
            RETURN;
        END IF;
    
        -- Récupération de l'id correspondant à la categorie de document
        SELECT category_id
          INTO gn_category_id
          FROM fnd_document_categories
         WHERE name = vv_category;
    
        g_step := 'INIT 001 - IDENTIFIANT DE LA CATEGORY : ' ||
                  gn_category_id;
        log_msg(g_step);
    
        -- Récupération de l'id correspondant au type de document
        SELECT distinct datatype_id
          INTO gn_datatype_id
          FROM fnd_document_datatypes
         WHERE name = gv_datatype_name;
    
        g_step := 'INIT 002 - IDENTIFIANT DU TYPE DE DONNEES : ' ||
                  gn_datatype_id;
        log_msg(g_step);
        g_step := 'INIT 999 - FIN';
        log_msg(g_step);
    EXCEPTION
        WHEN OTHERS THEN
            pn_retcode := 2;
            pv_errbuf  := 'INIT 999 : ' || SQLERRM;
    END init;

    ----------------------------------------------------------------------------
    --  Nom           : get_doc_avr
    --  Description   : Procédure permettant de récupérer les info d'un document
    --                  attaché de type Avis de virement s'il existe
    --
    --  PARAMETRES :
    --    pv_errbuf   Entrée/Sortie          message d'erreur
    --    VALEUR RETOURNEE :  pn_retcode
    --  Valeurs possibles : 0=normal, 1=warning, 2=erreur
    ----------------------------------------------------------------------------

    PROCEDURE get_doc_avr(pv_check_id    IN NUMBER,
                          pv_media_id    OUT NUMBER,
                          pv_document_id OUT NUMBER,
                          pv_errbuf      IN OUT VARCHAR2,
                          pn_retcode     OUT NUMBER) IS
    
        -- Curseur de lecture des documents attachés à l'avis de virement
        CURSOR cur_documents_joints IS
            SELECT fad.document_id
              FROM fnd_attached_documents fad
             WHERE fad.entity_name = gv_entity_name
               AND fad.pk1_value = pv_check_id
             ORDER BY fad.seq_num;
    
        rec_documents_joints cur_documents_joints%ROWTYPE;
        vb_avr_found         BOOLEAN := FALSE;
    
    BEGIN
        g_step := 'GET_DOC_AVR 000 - DEBUT';
        log_msg(g_step);
    
        vb_avr_found   := FALSE;
        pv_document_id := NULL;
        pv_media_id    := NULL;
    
        -- Boucle de lecture des documents attachés à la commande
        -- On sort de la boucle si on trouve un document de typre "AVIS DE VIREMENT"
        OPEN cur_documents_joints;
        LOOP
            FETCH cur_documents_joints
                INTO rec_documents_joints;
            EXIT WHEN cur_documents_joints%NOTFOUND OR vb_avr_found;
        
            -- Pour le document joint trouvé, on regarde si il est de type "AVIS DE VIREMENT"
            BEGIN
                SELECT fdt.document_id, fdt.media_id
                  INTO pv_document_id, pv_media_id
                  FROM fnd_documents_tl fdt, fnd_documents fd
                 WHERE fdt.document_id = rec_documents_joints.document_id
                   AND fd.document_id = fdt.document_id
                   AND fd.category_id = gn_category_id
                   AND fd.datatype_id = gn_datatype_id
                   AND fdt.description = gv_description
                   AND fdt.language = userenv('LANG');
            
                -- Le document joint est de type "AVIS DE VIREMENT"
                -- On positionne l'indicateur vb_avr_found pour sortir de la boucle
                vb_avr_found := TRUE;
                g_step       := 'GET_DOC_AVR 001 - Un document de type "AVIS DE VIREMENT" est déjà rattaché à cette commande (document_id : ' ||
                                pv_document_id || ', media_id : ' ||
                                pv_media_id || ').';
                log_msg(g_step);
            
            EXCEPTION
                WHEN OTHERS THEN
                    -- Le document joint n'est pas de type "BON DE COMMANDE"
                    -- On passe au document joint suivant
                    NULL;
            END;
        
        END LOOP;
        CLOSE cur_documents_joints;
    
        -- Il n'existe aucun document de type "BON DE COMMANDE"
        IF NOT vb_avr_found THEN
            g_step := 'GET_DOC_AVR 001 - ERROR - Aucun document de type "AVIS DE VIREMENT" n''est rattaché à cette commande.';
            log_msg(g_step);
        END IF;
    
        -- Fin modification EMA du 06/03/2008
    
        g_step := 'GET_DOC_AVR 999 - FIN';
        log_msg(g_step);
    
    EXCEPTION
        WHEN OTHERS THEN
            pn_retcode := 2;
            pv_errbuf  := 'GET_DOC_AVR : ' || SQLERRM;
    END get_doc_avr;

    ---------------------------------------------------------------------------
    --  Nom           : chargement_image
    --  Description   : procédure qui charge une image d'avis de virement en table
    --
    --  PARAMETRES :
    --    pv_errbuf   Entrée/Sortie          message d'erreur
    --    VALEUR RETOURNEE :  pn_retcode
    --  Valeurs possibles : 0=normal, 1=warning, 2=erreur
    ----------------------------------------------------------------------------
    PROCEDURE chargement_image(pv_nom_fichier IN VARCHAR2,
                               pb_existe      OUT BOOLEAN,
                               pn_file_id     OUT NUMBER,
                               pv_errbuf      OUT VARCHAR2,
                               pn_retcode     IN OUT NUMBER) IS
        l_src_fich   BFILE;
        l_dst_fich   BLOB;
        l_src_offset NUMBER := 1;
        l_dst_offset NUMBER := 1;
    
    BEGIN
        g_step := 'CHARGEMENT_IMAGE 000 - DEBUT';
        log_msg(g_step);
        pn_retcode := 0;
        dbms_lob.createtemporary(l_dst_fich, true, dbms_lob.session);
    
        l_src_fich := bfilename('DKA_LOADAVR', pv_nom_fichier);
        pb_existe  := DBMS_LOB.FILEEXISTS(l_src_fich) = 1;
    
        IF pb_existe THEN
            dbms_lob.fileopen(l_src_fich, dbms_lob.file_readonly);
            dbms_lob.loadfromfile(l_dst_fich,
                                  l_src_fich,
                                  dbms_lob.lobmaxsize,
                                  l_src_offset,
                                  l_dst_offset);
            SELECT fnd_lobs_s.NEXTVAL INTO pn_file_id FROM dual;
        
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
                 replace(pv_nom_fichier,'.out','.pdf'), --RBE
                 'application/pdf',
                 l_dst_fich,
                 'binary',
                 sysdate,
                 'FNDATTCH');
        
            DBMS_LOB.FILECLOSE(l_src_fich);
        ELSE
            pv_errbuf := 'CHARGEMENT_IMAGE - ERREUR : Pas de fichier à charger';
            log_msg(pv_errbuf);
            pn_retcode := 2;
        END IF;
    
        g_step := 'CHARGEMENT_IMAGE 999 - FIN';
        log_msg(g_step);
    EXCEPTION
        WHEN OTHERS THEN
            g_step := 'CHARGEMENT_IMAGE 999 - ' || substr(SQLERRM, 1, 400);
            log_msg(g_step);
            g_step := 'CHARGEMENT_IMAGE 999 - ' || SQLERRM;
            log_msg(g_step);
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
    PROCEDURE delete_image(pn_file_id IN NUMBER,
                           pv_errbuf  OUT VARCHAR2,
                           pn_retcode IN OUT NUMBER) IS
    
    BEGIN
        g_step := 'DELETE_IMAGE 000 : DEBUT.';
        log_msg(g_step);
        pn_retcode := 0;
    
        DELETE fnd_lobs WHERE file_id = pn_file_id;
        g_step := 'DELETE_IMAGE 001 : SUPPRESSION DE L''ANCIEN AVIS DE VIREMENT : ' ||
                  pn_file_id;
        log_msg(g_step);
        g_step := 'DELETE_IMAGE 099 : FIN.';
        log_msg(g_step);
    EXCEPTION
        WHEN OTHERS THEN
            g_step := 'DELETE_IMAGE 099 : ' || substr(SQLERRM, 1, 400);
            log_msg(g_step);
            g_step := 'DELETE_IMAGE 099 : ' || SQLERRM;
            log_msg(g_step);
            pv_errbuf  := 'delete_image - ' || SQLERRM;
            pn_retcode := 2;
            ROLLBACK;
    END delete_image;

    ----------------------------------------------------------------------------
    --  Nom           : create_attached_document_avr
    --  Description   : procédure qui crée le document attaché
    --
    --
    --  PARAMETRES :
    --    pv_errbuf   Entrée/Sortie          message d'erreur
    --    VALEUR RETOURNEE :  pn_retcode
    --  Valeurs possibles : 0=normal, 1=warning, 2=erreur
    ----------------------------------------------------------------------------
    PROCEDURE create_attached_document_avr(pv_filename IN VARCHAR2,
                                           pv_check_id IN NUMBER,
                                           pn_file_id  IN NUMBER,
                                           pv_errbuf   OUT VARCHAR2,
                                           pn_retcode  IN OUT NUMBER) IS
    
        l_document_id          NUMBER;
        l_attached_document_id NUMBER;
        l_num_seq              NUMBER;
    BEGIN
        g_step := 'CREATE_ATTACHED_DOCUMENT_AVR 000 : DEBUT.';
        log_msg(g_step);
        pn_retcode := 0;
    
        -- Recupération du dernier numéro de séquence 
        BEGIN
            SELECT NVL(MAX(seq_num), 0) + 10
              INTO l_num_seq
              FROM fnd_attached_documents
             WHERE entity_name = gv_entity_name
               AND pk1_value = pv_check_id;
        
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                l_num_seq := 10;
        END;
    
        SELECT fnd_documents_s.nextval INTO l_document_id FROM DUAL;
    
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
        VALUES
            (l_document_id,
             replace(pv_filename,'.out','.pdf'), --RBE
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
             category_id,
             datatype_id,
             creation_date,
             created_by,
             last_update_date,
             last_updated_by,
             security_type,
             security_id,
             publish_flag,
             file_name, --RBE MigR12
             media_id)  -- RBE MigR12
        VALUES
            (l_document_id,
             gn_category_id,
             gn_datatype_id,
             sysdate,
             -1,
             sysdate,
             -1,
             1,
             gn_org_id,
             'Y',
             replace(pv_filename,'.out','.pdf'), --RBE MigR12
             pn_file_id); --RBE MigR12
    
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
        VALUES
            (l_attached_document_id,
             l_document_id,
             l_num_seq,
             gv_entity_name,
             pv_check_id,
             sysdate,
             -1,
             sysdate,
             -1,
             'N');
    
        dka_Tools_Pkg.put_outdebug_message('==>  Création du document_id : ' ||
                                           l_document_id);
        g_step := 'CREATE_ATTACHED_DOCUMENT_AVR 001 : CREATION DU DOCUMENT_ID : ' ||
                  l_document_id;
        log_msg(g_step);
        g_step := 'CREATE_ATTACHED_DOCUMENT_AVR 099 : FIN.';
        log_msg(g_step);
    EXCEPTION
        WHEN OTHERS THEN
            g_step := 'CREATE_ATTACHED_DOCUMENT_AVR 099 - ERREUR : ' ||
                      SQLCODE || '=' || substr(SQLERRM, 1, 400);
            log_msg(g_step);
            g_step := 'CREATE_ATTACHED_DOCUMENT_AVR 099 - ERREUR : ' ||
                      SQLERRM;
            log_msg(g_step);
            pv_errbuf  := 'create_attached_document_bdc - ' || SQLERRM;
            pn_retcode := 2;
            ROLLBACK;
    END create_attached_document_avr;

    ----------------------------------------------------------------------------
    --  Nom           : update_attached_document_avr
    --  Description   : procédure qui crée le document attaché
    --
    --
    --  PARAMETRES :
    --    pv_errbuf   Entrée/Sortie          message d'erreur
    --    VALEUR RETOURNEE :  pn_retcode
    --  Valeurs possibles : 0=normal, 1=warning, 2=erreur
    ----------------------------------------------------------------------------
    PROCEDURE update_attached_document_avr(pv_filename    IN VARCHAR2,
                                           pn_file_id     IN NUMBER,
                                           pn_document_id IN NUMBER,
                                           pv_errbuf      OUT VARCHAR2,
                                           pn_retcode     IN OUT NUMBER) IS
    
    BEGIN
        g_step := 'UPDATE_ATTACHED_DOCUMENT_AVR 000 : DEBUT.';
        log_msg(g_step);
    
        pn_retcode := 0;
    
        UPDATE fnd_documents_tl
           SET file_name        = replace(pv_filename,'.out','.pdf'),
               media_id         = pn_file_id,
               last_update_date = sysdate,
               last_updated_by  = -1
         WHERE document_id = pn_document_id;
        g_step := 'UPDATE_ATTACHED_DOCUMENT_AVR 001 : MISE A JOUT DU DOCUMENT_ID : ' ||
                  pn_document_id;
        log_msg(g_step);
    
        g_step := 'UPDATE_ATTACHED_DOCUMENT_AVR 999 : FIN';
        log_msg(g_step);
    EXCEPTION
        WHEN OTHERS THEN
            g_step := 'UPDATE_ATTACHED_DOCUMENT_AVR 999 - ERREUR : ' ||
                      SQLCODE || '=' || substr(SQLERRM, 1, 400);
            log_msg(g_step);
            g_step := 'UPDATE_ATTACHED_DOCUMENT_AVR 999 - ERREUR : ' ||
                      SQLERRM;
            log_msg(g_step);
            pv_errbuf  := 'UPDATE_ATTACHED_DOCUMENT_AVR - ' || SQLERRM;
            pn_retcode := 2;
            ROLLBACK;
    END update_attached_document_avr;

    ----------------------------------------------------------------------------
    --  Nom           : main
    --  Description   : procédure principale du stockage des avis de virement
    --
    --
    --  PARAMETRES :
    --    pv_errbuf       Entrée/Sortie           message d'erreur
    --    VALEUR RETOURNEE :  pn_retcode
    --  Valeurs possibles : 0=normal, 1=warning, 2=erreur
    ----------------------------------------------------------------------------

    PROCEDURE main(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER)
    
     IS
        v_retcode	    NUMBER;
		vb_rattachement NUMBER;
		v_check_id    NUMBER;
        v_output_file VARCHAR2(100);
        v_existe      BOOLEAN;
        v_file_id     NUMBER;
        v_media_id    fnd_documents_tl.media_id%TYPE;
        v_document_id fnd_documents_tl.document_id%TYPE;
        e_main EXCEPTION;
    
        CURSOR cur_avis_reglement IS
            SELECT distinct DST.REQUEST_ID,
                            DST.CHECK_ID,
                            DST.CREATED_BY,
                            DST.CREATION_DATE,
                            DST.LAST_UPDATED_BY,
                            DST.LAST_UPDATE_DATE
              FROM DKA_SAPVIR_ATTACH_TMP DST
             ORDER BY DST.REQUEST_ID;
    
        rec_avis_reglement cur_avis_reglement%ROWTYPE;
    BEGIN
        g_step := 'MAIN 000 : DEBUT.';
        log_msg(g_step);
		v_retcode := 0;
		vb_rattachement := 0;
        ----- Initialisation des variables de sortie de la procédure -----
        pv_errbuf  := NULL;
        pn_retcode := 0;
    
        g_step := 'MAIN 001 : INITIALISATION DES VARIABLES.';
        log_msg(g_step);
        ----- Appel de la procédure INIT -----
        init(pv_errbuf, pn_retcode);
    
        OPEN cur_avis_reglement;
        LOOP
            FETCH cur_avis_reglement
                INTO rec_avis_reglement;
            EXIT WHEN cur_avis_reglement%NOTFOUND;
            BEGIN
                g_step := 'MAIN 002 : ***** RECUPERATION DES PARAMETRES *****';
                log_msg(g_step);
                select to_number(fcr1.ARGUMENT4),
                       SUBSTR(fcr1.outfile_name,
                              INSTR(fcr1.outfile_name, '/', -1, 1) + 1)
                  into v_check_id, v_output_file
                  from fnd_concurrent_requests fcr1
                 where fcr1.request_id = rec_avis_reglement.REQUEST_ID
                   AND fcr1.output_file_type = 'PDF';
            
                log_msg('check_id : ' || TO_CHAR(v_check_id));
                log_msg('fichier avis de virement : ' || v_output_file);
            
                log_msg('');
                g_step := 'MAIN 004 : ***** STOCKAGE DE L''AVIS DE VIREMENT *****';
                log_msg(g_step);
                log_msg('');
            
                -- Chargement de l'image en table
                chargement_image(pv_nom_fichier => v_output_file,
                                 pb_existe      => v_existe,
                                 pn_file_id     => v_file_id,
                                 pv_errbuf      => pv_errbuf,
                                 pn_retcode     => pn_retcode);
            
                IF pn_retcode != 0 THEN
                    pv_errbuf := 'CHARGEMENT IMAGE - ' || pv_errbuf;
                    log_msg(CHR(10) || pv_errbuf);
                    RAISE e_main;
                END IF;
            
                -- Recherche si un document attaché AVR existe déjà sur le règlement.
                get_doc_avr(pv_check_id    => v_check_id,
                            pv_media_id    => v_media_id,
                            pv_document_id => v_document_id,
                            pv_errbuf      => pv_errbuf,
                            pn_retcode     => pn_retcode);
            
                IF v_document_id IS NOT NULL THEN
                
                    -- Mise à jour du document existant avec le nouveau fichier
                    g_step := 'MAIN 005 : Un document de type "AVIS DE VIREMENT" est déjà rattaché à cette commande.';
                    log_msg(g_step);
                    update_attached_document_avr(pv_filename    => v_output_file,
                                                 pn_file_id     => v_file_id,
                                                 pn_document_id => v_document_id,
                                                 pv_errbuf      => pv_errbuf,
                                                 pn_retcode     => pn_retcode);
                
                    IF pn_retcode != 0 THEN
                        pv_errbuf := 'UPDATE ATTACHED DOCUMENT AVR - ' ||
                                     pv_errbuf;
                        log_msg(CHR(10) || pv_errbuf);
                        RAISE e_main;
                    END IF;
                
                    -- Suppression de l'ancien fichier
                    delete_image(pn_file_id => v_media_id,
                                 pv_errbuf  => pv_errbuf,
                                 pn_retcode => pn_retcode);
                
                    IF pn_retcode != 0 THEN
                        pv_errbuf := 'DELETE IMAGE - ' || pv_errbuf;
                        log_msg(CHR(10) || pv_errbuf);
                        RAISE e_main;
					ELSE
						vb_rattachement := 1;
                    END IF;
                
                ELSE
                
                    -- Création d'un nouveau document joint
                    create_attached_document_avr(v_output_file,
                                                 v_check_id,
                                                 v_file_id,
                                                 pv_errbuf,
                                                 pn_retcode);
                
                    IF pn_retcode != 0 THEN
                        pv_errbuf := 'CREATE ATTACHED DOCUMENT AVR - ' ||
                                     pv_errbuf;
                        log_msg(CHR(10) || pv_errbuf);
                        RAISE e_main;
          ELSE
            vb_rattachement := 1;
                    END IF;
                END IF;
                -- Rattachement OK :
                g_step := '==> Rattachement de l''image du règlement d''identifiant : ' ||
                          v_check_id;
                out_msg(pv_errbuf);
            EXCEPTION
                WHEN e_main THEN
                    -- Avertissement :
                    pn_retcode := 1;
          v_retcode := 1;
                    pv_errbuf  := '==> Erreur lors du rattachement de l''image du règlement d''identifiant : ' ||
                                  v_check_id;
                    out_msg(pv_errbuf);
                    log_msg(pv_errbuf);
            END;
        END LOOP;
        CLOSE cur_avis_reglement;
    
        g_step := 'MAIN 999 - FIN.';
        log_msg(g_step);
    IF vb_rattachement = 0 THEN
      pn_retcode := 2;
    ELSIF v_retcode = 1 THEN
      pn_retcode := 1;
    END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pn_retcode := 2;
            pv_errbuf  := 'Procédure main en erreur ' || SQLERRM;
            g_step     := 'MAIN 999 - ERREUR : ' || pv_errbuf;
            log_msg(g_step);
    END main;

END DKA_SAPVIR_ATTACH_PKG;
/

SHOW ERROR

EXIT
