create or replace PACKAGE BODY DKA_SAPGETIMG_WF_PKG
AS

----------------------------------------------------------------------------------------------
-- $Id: DKA_SAPGETIMG_WF_PKG.pkb 767 2008-06-05 14:41:01Z CORP\viknab $
-- CAPGEMINI
-- PROJET            : Dalkia Oracle Applications
-- NOM               : DKA_SAPGETIMG_WF_PKG.pkb
-- DESCRIPTION       : DKA_SAPGETIMG_WF_PKG package body : Création des liens url pour la
--                          visualisation des images dans le WF AP
-- AUTEUR            : CDE (CAPGEMINI)
-- DATE DE CREATION  : 06/03/2008
-- DOC. ASSOCIEE     :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
-- HISTORIQUE  DES MODIFICATIONS
-- Date        Qui Description
-- ----------- --- -------------------------------------------------------------------------
-- 2016/07/05 JJA Portage Helios R12
-- 2018/02/22 NBO artf2392081 - SPEXXX - Durée de validité des images sur les notifications AP
--------------------------------------------------------------------------------------------



--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PRIVEES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    gv_description_ap               VARCHAR2(250);
    gv_description_po               VARCHAR2(250);
    gn_category_id_ap               NUMBER;
    gn_category_id_po               NUMBER;
    gv_file_datatype_name           VARCHAR2(30) := 'FILE';
    gn_file_datatype_id             NUMBER;
    gv_web_datatype_name            VARCHAR2(30) := 'WEB_PAGE';
    gn_web_datatype_id              NUMBER;

    gv_entity_name_ap               VARCHAR2(30) := 'AP_INVOICES';
    gv_entity_name_oi               VARCHAR2(30) := 'AP_INVOICES_INTERFACE';
    gv_entity_name_po               VARCHAR2(30) := 'PO_HEADERS';
    gn_nbre_jour                    NUMBER;

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PRIVEES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PUBLIQUES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : init_ap
  --  Description   : procédure d'initialisation pour les factures ap
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------

    PROCEDURE init_ap (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    )
    IS
        rec_param      dka_parameters%ROWTYPE;
        vv_category_ap fnd_document_categories.name%TYPE;

    BEGIN
        pv_errbuf     := NULL;
        pn_retcode    := 0;

        -- Variables liées aux caratéristiques des documents joints
        Dka_Tools_Pkg.get_parameter ('IAPLOADIMG_XEROX', 'DESCRIPTION', rec_param, pv_errbuf, pn_retcode);
        gv_description_ap                   := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'Parametre DESCRIPTION AP : ' || pv_errbuf;
            RETURN;
        ELSIF gv_description_ap IS NULL
        THEN
            pv_errbuf    := 'Parametre DESCRIPTION AP : Aucune donnée trouvée';
            pn_retcode   := 2;
            RETURN;
        END IF;


        Dka_Tools_Pkg.get_parameter ('IAPLOADIMG_XEROX', 'CATEGORY', rec_param, pv_errbuf, pn_retcode);
        vv_category_ap                  := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'Parametre CATEGORY AP : ' || pv_errbuf;
            RETURN;
        ELSIF vv_category_ap IS NULL
        THEN
            pv_errbuf    := 'Parametre CATEGORY AP : Aucune donnée trouvée';
            pn_retcode   := 2;
            RETURN;
        END IF;

        Dka_Tools_Pkg.get_parameter ('SAPGETIMG_WF', 'NBRE_JOUR_ACCESS', rec_param, pv_errbuf, pn_retcode);
        gn_nbre_jour                  := rec_param.number_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'Parametre NBRE_JOUR_ACCESS : ' || pv_errbuf;
            RETURN;
        ELSIF gn_nbre_jour IS NULL
        THEN
            pv_errbuf    := 'Parametre NBRE_JOUR_ACCESS : Aucune donnée trouvée';
            pn_retcode   := 2;
            RETURN;
        END IF;

        -- Récupération de l'id correspondant a la categorie de document
        SELECT category_id
        INTO gn_category_id_ap
        FROM fnd_document_categories
        WHERE name = vv_category_ap;

        -- Récupération de l'id correspondant au type de document 'Fichier'
        SELECT distinct datatype_id
        INTO gn_file_datatype_id
        FROM fnd_document_datatypes
        WHERE name = gv_file_datatype_name;

        -- Récupération de l'id correspondant au type de document 'Page Web'
        SELECT distinct datatype_id
        INTO gn_web_datatype_id
        FROM fnd_document_datatypes
        WHERE name = gv_web_datatype_name;

    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode   := 2;
            pv_errbuf    := SUBSTR('INIT AP: ' ||SQLERRM,1,250);
    END init_ap;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : init_po
  --  Description   : procédure d'initialisation pour les commandes po
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------

    PROCEDURE init_po (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    )
    IS
        rec_param      dka_parameters%ROWTYPE;
        vv_category_po fnd_document_categories.name%TYPE;

    BEGIN
        pv_errbuf     := NULL;
        pn_retcode    := 0;

        -- Variables liées aux caratéristiques des documents joints
        Dka_Tools_Pkg.get_parameter ('SPOBON', 'DESCRIPTION', rec_param, pv_errbuf, pn_retcode);
        gv_description_po                   := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'Parametre DESCRIPTION PO : ' || pv_errbuf;
            RETURN;
        ELSIF gv_description_po IS NULL
        THEN
            pv_errbuf    := 'Parametre DESCRIPTION PO : Aucune donnée trouvée';
            pn_retcode   := 2;
            RETURN;
        END IF;


        Dka_Tools_Pkg.get_parameter ('SPOBON', 'CATEGORY', rec_param, pv_errbuf, pn_retcode);
        vv_category_po                  := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'Parametre CATEGORY PO : ' || pv_errbuf;
            RETURN;
        ELSIF vv_category_po IS NULL
        THEN
            pv_errbuf    := 'Parametre CATEGORY PO : Aucune donnée trouvée';
            pn_retcode   := 2;
            RETURN;
        END IF;

        Dka_Tools_Pkg.get_parameter ('SAPGETIMG_WF', 'NBRE_JOUR_ACCESS', rec_param, pv_errbuf, pn_retcode);
        gn_nbre_jour                  := rec_param.number_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'Parametre NBRE_JOUR_ACCESS : ' || pv_errbuf;
            RETURN;
        ELSIF gn_nbre_jour IS NULL
        THEN
            pv_errbuf    := 'Parametre NBRE_JOUR_ACCESS : Aucune donnée trouvée';
            pn_retcode   := 2;
            RETURN;
        END IF;

        -- Récupération de l'id correspondant a la categorie de document
        SELECT category_id
        INTO gn_category_id_po
        FROM fnd_document_categories
        WHERE name = vv_category_po;

        -- Récupération de l'id correspondant au type de document 'Fichier'
        SELECT distinct datatype_id
        INTO gn_file_datatype_id
        FROM fnd_document_datatypes
        WHERE name = gv_file_datatype_name;

        -- Récupération de l'id correspondant au type de document 'Page Web'
        SELECT distinct datatype_id
        INTO gn_web_datatype_id
        FROM fnd_document_datatypes
        WHERE name = gv_web_datatype_name;

    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode   := 2;
            pv_errbuf    := SUBSTR('INIT PO: ' ||SQLERRM,1,250);
    END init_po;


  -------------------------------------------------------------------------------------------------------------------
  --  Nom           : authorize
  --  Description   : Fonction donnant l'autorisation d'acces au lob
  --
  --  PARAMETRES    :
  --    file_id      number
  --  VALEUR RETOURNEE :
  --     result       : number
  -------------------------------------------------------------------------------------------------------------------

  FUNCTION authorize(file_id number)
       RETURN number
  IS
  pragma autonomous_transaction;
    result number;
  BEGIN
       INSERT INTO fnd_lob_access
             (access_id
            , file_id
            , timestamp)
       VALUES (to_number(to_char(fnd_lobs_s.nextval)||to_char(sysdate,'SSSSS'))
            , file_id
            , sysdate+gn_nbre_jour)
       RETURNING access_id INTO result;
     commit;

     RETURN result;
  EXCEPTION
  WHEN OTHERS THEN
      fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
      fnd_message.set_token('ROUTINE', 'DKA_SAPGETIMG_WF_PKG.authorize');
      fnd_message.set_token('ERRNO', SQLCODE);
      fnd_message.set_token('REASON', SQLERRM);
    raise;
  END;


  -------------------------------------------------------------------------------------------------------------------
  --  Nom           : construct_download_url
  --  Description   : construction de l'url en se basant sur la fonction standard fnd_gfm.construct_download_URL
  --
  --  PARAMETRES    :
  --    gfm_agent      varchar2
  --    file_id        number
  --  VALEUR RETOURNEE :
  --     url       : varchar2
  -------------------------------------------------------------------------------------------------------------------

  FUNCTION construct_download_url(gfm_agent     varchar2,
	                          			file_id       number
				                          )
	RETURN varchar2
  IS
      pragma autonomous_transaction;
      access_id  number;
      url        varchar2(2000);
      file_ext   varchar2(10);
      export_mime varchar2(30);
      ext_length number;
   BEGIN
      access_id := authorize(file_id);


      SELECT instr(file_name,'.',-1)
      INTO ext_length
      FROM fnd_lobs
      WHERE file_id = construct_download_url.file_id;

    IF ext_length > 0 THEN
       SELECT substr(file_name,instr(file_name,'.',-1))
       INTO file_ext
       FROM fnd_lobs
       WHERE file_id = construct_download_url.file_id;
    ELSE
       file_ext := NULL;
    END IF;

    /*url := fnd_web_config.trail_slash(gfm_agent)||'fndgfm/fnd_gfm.get/'||
             access_id||'/'||file_id||'/fnd_gfm'||file_ext;*/

    -- 2018/02/22 NBO artf2392081 - SPEXXX - Durée de validité des images sur les notifications AP
    -- 28/08/2025 CGI ; on remet l'API . et le durée de validité sera corrigée par un trigger
    --url := fnd_gfm.construct_download_url (gfm_agent, file_id, FALSE);
    -- url := fnd_web_config.trail_slash(fnd_profile.value('APPS_FRAMEWORK_AGENT'))||'OA_HTML/fndgfm.jsp?mode=download_blob'||'&'||'fid='||file_id||'&'||'accessid='||access_id;
    url  := fnd_gfm.construct_download_url(gfm_agent     => fnd_web_config.gfm_agent,
                                file_id       => file_id,
                                --purge_on_view boolean default FALSE,
                                --modplsql      boolean default FALSE,
                                authenticate  =>false --,
                                --user_name     => 'DKAEXPLOIT'
                                --lifespan      number  default NULL
                                );

    commit;
    RETURN url;
  EXCEPTION
       WHEN others THEN
            fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
            fnd_message.set_token('ROUTINE', 'DKA_SAPGETIMG_WF_PKG.construct_download_url');
            fnd_message.set_token('ERRNO', SQLCODE);
            fnd_message.set_token('REASON', SQLERRM);
       raise;
  END;



  -------------------------------------------------------------------------------------------------------------------
  --  Nom           : GET_URL_IMAGE_FACTURE
  --  Description   : renvoie l'URL permettant d'ouvrir l'image des factures AP ou en rejet dans l'OI
  --
  --  PARAMETRES    :
  --    pn_invoice_id      number
  --    pv_entity_type     varchar2 (AP ou OI)
  --  VALEUR RETOURNEE :
  --     url       : varchar2
  --        cas particulier : -1 : Aucune image n'est rattachée a cette facture
  --                          -2 : Erreur
  -------------------------------------------------------------------------------------------------------------------
   FUNCTION get_url_image_facture (pn_invoice_id  IN NUMBER
                                 , pv_entity_type IN VARCHAR2)
        RETURN VARCHAR2
   IS
      gfm_agent      VARCHAR2(255);
      v_media_id     NUMBER;
      pv_errbuf      VARCHAR2(250);
      pn_retcode     NUMBER := 0;
      url            VARCHAR2(500);
      v_entity_name  fnd_attached_documents.entity_name%TYPE;
      v_pk1_value    fnd_attached_documents.pk1_value%TYPE;
      v_datatype_id  fnd_documents.datatype_id%TYPE;
      v_file_name    fnd_documents_tl.file_name%TYPE;

   BEGIN


         ----- Appel de la procédure INIT_AP-----
         init_ap (pv_errbuf, pn_retcode);

         IF pn_retcode != 0
         THEN
             -- Erreur lors de la récupération des variables globales
             url := '-2';
         ELSE

             v_pk1_value := to_char(pn_invoice_id);

             SELECT decode(pv_entity_type, 'OI', gv_entity_name_oi, gv_entity_name_ap)
             INTO   v_entity_name
             FROM   dual;

             -- Récupération de l'Id du fichier
             BEGIN
                  SELECT nvl(fdt.media_id,fd.media_id),
                         nvl(fdt.file_name,fd.file_name),
                         fd.datatype_id
                  INTO v_media_id,
                       v_file_name,
                       v_datatype_id
                  FROM fnd_attached_documents fad,
                       fnd_documents_tl fdt,
                       fnd_documents fd
                  WHERE fdt.document_id = fad.document_id
                    AND fd.document_id  = fdt.document_id
                    AND fd.category_id  = gn_category_id_ap
                    AND fd.datatype_id IN (gn_file_datatype_id, gn_web_datatype_id)
                    AND fdt.description = gv_description_ap
                    AND fdt.language    = USERENV('LANG')
                    AND fad.entity_name = v_entity_name
                    AND fad.pk1_value   = v_pk1_value;
             EXCEPTION
             WHEN NO_DATA_FOUND THEN
                  v_media_id := 0;
             END;


             IF v_media_id <> 0
             THEN
                  -- Construction de l'url pour récupérer le document joint
                  gfm_agent := fnd_web_config.gfm_agent;
                  url := construct_download_URL( gfm_agent, v_media_id);
                  -- Si le document est de type 'Page Web', l'URL est contenue dans le champ file_name
             ELSIF v_datatype_id = gn_web_datatype_id
             THEN
                  url := v_file_name;
             ELSE
                  -- Aucun document joint de type IMAGE FACTURE n'existe pour cette facture
                  url := '-1';
             END IF;

         END IF;

      ----- return value -----
      RETURN (url);

   END get_url_image_facture;


  -------------------------------------------------------------------------------------------------------------------
  --  Nom           : GET_URL_IMAGE_BDC
  --  Description   : renvoie l'URL permettant d'ouvrir le bon de commande
  --
  --  PARAMETRES    :
  --    pn_po_header_id      number
  --  VALEUR RETOURNEE :
  --     url       : varchar2
  --        cas particulier : -1 : Aucune image n'est rattachée a cette commande
  --                          -2 : Erreur
  -------------------------------------------------------------------------------------------------------------------
   FUNCTION get_url_image_bdc (pn_po_header_id  IN NUMBER)
        RETURN VARCHAR2
   IS
      gfm_agent      VARCHAR2(255);
      v_media_id     NUMBER;
      pv_errbuf      VARCHAR2(250);
      pn_retcode     NUMBER := 0;
      url            VARCHAR2(500);
      v_tmp_document_id number;
      v_pk1_value    fnd_attached_documents.pk1_value%TYPE;
   BEGIN


         ----- Appel de la procédure INIT_PO -----
         init_po (pv_errbuf, pn_retcode);

         IF pn_retcode != 0
         THEN
             -- Erreur lors de la récupération des variables globales
             url := '-2';
         ELSE

             -- Récupération de l'Id du fichier
             BEGIN

                  v_pk1_value := to_char(pn_po_header_id);

                  SELECT fad.document_id
                  INTO v_tmp_document_id
                  FROM fnd_attached_documents fad
                  WHERE fad.entity_name = gv_entity_name_po
                    AND fad.pk1_value   = v_pk1_value;


                  SELECT nvl(fdt.media_id,fd.media_id)
                  INTO v_media_id
                  FROM
                       fnd_documents_tl fdt,
                       fnd_documents fd
                  WHERE fdt.document_id = v_tmp_document_id
                    AND fd.document_id  = fdt.document_id
                    AND fd.category_id  = gn_category_id_po
                    AND fd.datatype_id  = gn_file_datatype_id
                    AND fdt.description = gv_description_po
                    AND fdt.language    = USERENV('LANG');
             EXCEPTION
             WHEN NO_DATA_FOUND THEN
                  v_media_id := 0;
             END;


             IF v_media_id <> 0
             THEN
                  -- Construction de l'url pour récupérer le document joint
                  gfm_agent := fnd_web_config.gfm_agent;
                  url := construct_download_URL( gfm_agent, v_media_id);
             ELSE
                  -- Aucun document joint de type IMAGE BDC n'existe pour cette commande
                  url := '-1';
             END IF;

         END IF;

      ----- return value -----
      RETURN (url);

   END get_url_image_bdc;

  -------------------------------------------------------------------------------------------------------------------
  --  Nom           : GET_URL_IMAGE_FACTURE_IVALUA
  --  Description   : renvoie l'URL permettant d'ouvrir l'image des factures AP ou en rejet dans l'OI IVALUA
  --
  --  PARAMETRES    :
  --    pn_invoice_id      number
  --    pv_entity_type     varchar2 (AP ou OI)
  --  VALEUR RETOURNEE :
  --     url       : varchar2
  --        cas particulier : -1 : Aucune image n'est rattachée a cette facture
  --                          -2 : Erreur
  -------------------------------------------------------------------------------------------------------------------
   FUNCTION get_url_image_facture_ivalua (pn_invoice_id  IN NUMBER
                                        , pv_entity_type IN VARCHAR2)
        RETURN VARCHAR2
   IS
      gfm_agent      VARCHAR2(255);
      v_media_id     NUMBER;
      pv_errbuf      VARCHAR2(250);
      pn_retcode     NUMBER := 0;
      url            VARCHAR2(500);
      v_entity_name  fnd_attached_documents.entity_name%TYPE;
      v_pk1_value    fnd_attached_documents.pk1_value%TYPE;
      v_datatype_id  fnd_documents.datatype_id%TYPE;
      v_file_name    fnd_documents_tl.file_name%TYPE;

   BEGIN


         ----- Appel de la procédure INIT_AP-----
         init_ap (pv_errbuf, pn_retcode);

         IF pn_retcode != 0
         THEN
             -- Erreur lors de la récupération des variables globales
             url := '-2';
         ELSE

             v_pk1_value := to_char(pn_invoice_id);

             SELECT decode(pv_entity_type, 'OI', gv_entity_name_oi, gv_entity_name_ap)
             INTO   v_entity_name
             FROM   dual;

             -- Récupération de l'Id du fichier
             BEGIN
                  SELECT nvl(fdt.media_id,fd.media_id),
                         nvl(fdt.file_name,fd.file_name),
                         fd.datatype_id
                  INTO v_media_id,
                       v_file_name,
                       v_datatype_id
                  FROM fnd_attached_documents fad,
                       fnd_documents_tl fdt,
                       fnd_documents fd
                  WHERE fdt.document_id = fad.document_id
                    AND fd.document_id  = fdt.document_id
                    AND fd.category_id  = gn_category_id_ap
                    AND fd.datatype_id IN (gn_file_datatype_id, gn_web_datatype_id)
                    AND fdt.description = gv_description_ap
                    AND fdt.language    = USERENV('LANG')
                    AND fad.entity_name = v_entity_name
                    AND fad.pk1_value   = v_pk1_value;
             EXCEPTION
             WHEN NO_DATA_FOUND THEN
                  v_media_id := 0;
             END;


             IF v_media_id <> 0
             THEN
                  -- Construction de l'url pour récupérer le document joint
                  gfm_agent := fnd_web_config.gfm_agent;
                  url := construct_download_URL( gfm_agent, v_media_id);
                  -- Si le document est de type 'Page Web', l'URL est contenue dans le champ file_name
             ELSIF v_datatype_id = gn_web_datatype_id
             THEN
                  url := v_file_name;
             ELSE
                  -- Aucun document joint de type IMAGE FACTURE n'existe pour cette facture
                  url := '-1';
             END IF;

         END IF;

      ----- return value -----
      RETURN (url);

   END get_url_image_facture_ivalua;

  -------------------------------------------------------------------------------------------------------------------
  --  Nom           : GET_URL_IMAGE_BDC_IVALUA
  --  Description   : renvoie l'URL permettant d'ouvrir le bon de commande
  --
  --  PARAMETRES    :
  --    pn_po_header_id      number
  --  VALEUR RETOURNEE :
  --     url       : varchar2
  --        cas particulier : -1 : Aucune image n'est rattachée a cette commande
  --                          -2 : Erreur
  -------------------------------------------------------------------------------------------------------------------
   FUNCTION get_url_image_bdc_ivalua(pn_po_header_id IN NUMBER)
     RETURN VARCHAR2 IS
     gfm_agent           VARCHAR2(255);
     v_media_id          NUMBER;
     ln_file_datatype_id NUMBER;
     l_count             NUMBER;
     pv_errbuf           VARCHAR2(250);
     pn_retcode          NUMBER := 0;
     url                 VARCHAR2(500);
     v_tmp_document_id   NUMBER;
     v_pk1_value         fnd_attached_documents.pk1_value%TYPE;
   BEGIN

     ----- Appel de la procédure INIT_PO -----
     init_po(pv_errbuf, pn_retcode);

     IF pn_retcode != 0 THEN
       -- Erreur lors de la récupération des variables globales
       url := '-2';
     ELSE

       -- Récupération de l'Id du fichier
       BEGIN
         v_pk1_value := to_char(pn_po_header_id);

         SELECT fad.document_id
           INTO v_tmp_document_id
           FROM fnd_attached_documents fad
          WHERE fad.entity_name = gv_entity_name_po
            AND fad.pk1_value = v_pk1_value;

         SELECT COUNT(1)
           INTO l_count
           FROM po_headers_all
          WHERE po_header_id = v_pk1_value
            AND attribute7 = 'IVALUA';

         IF l_count = 1 THEN

           BEGIN
             SELECT datatype_id
               INTO ln_file_datatype_id
               FROM fnd_document_datatypes
              WHERE NAME = 'WEB_PAGE'
                AND LANGUAGE = userenv('LANG');

             SELECT url
               INTO url
               FROM fnd_documents fd
              WHERE fd.document_id = v_tmp_document_id
                AND category_id = gn_category_id_po
                AND datatype_id = ln_file_datatype_id;
           EXCEPTION

             WHEN no_data_found THEN
               url := '-1';
           END;

         ELSE
           BEGIN

             SELECT nvl(fdt.media_id, fd.media_id)
               INTO v_media_id
               FROM fnd_documents_tl fdt, fnd_documents fd
              WHERE fdt.document_id = v_tmp_document_id
                AND fd.document_id = fdt.document_id
                AND fd.category_id = gn_category_id_po
                AND fd.datatype_id = gn_file_datatype_id
                AND fdt.description = gv_description_po
                AND fdt.language = userenv('LANG');
           EXCEPTION
             WHEN no_data_found THEN
               v_media_id := 0;
           END;

           IF v_media_id <> 0 THEN
             -- Construction de l'url pour récupérer le document joint
             gfm_agent := fnd_web_config.gfm_agent;
             url       := construct_download_url(gfm_agent, v_media_id);
           ELSE
             -- Aucun document joint de type IMAGE BDC n'existe pour cette commande
             url := '-1';
           END IF;

         END IF;

       EXCEPTION
         WHEN no_data_found THEN

           url := '-1';
       END;
     END IF;

     ----- return value -----
     RETURN(url);

   END get_url_image_bdc_ivalua;

END DKA_SAPGETIMG_WF_PKG;
/

SHOW ERRORS;
EXIT
