CREATE OR REPLACE PACKAGE BODY DKA_SAPGETIMG_AL_PKG
AS

----------------------------------------------------------------------------------------------
-- $Id: DKA_SAPGETIMG_AL_PKG.pkb 2772 2009-10-16 09:30:25Z CORP\mslama $
-- CAPGEMINI
-- PROJET            : VEOLIA Oracle Applications
-- NOM               : DKA_SAPGETIMG_AL_PKG.pkb
-- DESCRIPTION       : DKA_SAPGETIMG_AL_PKG package body : Création des liens url pour la
--                          visualisation des images provenant d'Aladin
-- AUTEUR            : MSLA (CAPGEMINI)
-- DATE DE CREATION  : 26/06/2009
-- DOC. ASSOCIEE     :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
-- HISTORIQUE  DES MODIFICATIONS
-- Date        Qui Description
-- 23/09/2016  PBR Portage en version 12.2.4 (Migration R12)
-- 17/06/2021  NBO INC0514828 - Impossible de lancer le spécifique SPE154 _ Restitution factures numérisées. 
-- ----------- --- -------------------------------------------------------------------------

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PRIVEES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    gv_description_ap               VARCHAR2(250);
    gv_description_po               VARCHAR2(250);
    gn_category_id_ap               NUMBER;
    gn_category_id_po               NUMBER;
    gv_datatype_name                VARCHAR2(30) := 'FILE';
    gn_datatype_id                  NUMBER;
    gv_entity_name_ap               VARCHAR2(30) := 'AP_INVOICES';
    gv_entity_name_oi               VARCHAR2(30) := 'AP_INVOICES_INTERFACE';
    gn_nbre_jour                    NUMBER;

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PRIVEES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  cb_debug constant boolean := false;


----------------------------------------------------------------------------
--  Nom           : LOG_MSG
--  Description   : procedure de log des messages
--
--  PARAMETRES :
--   pv_message      texte a imprimer dans le log
--
----------------------------------------------------------------------------
PROCEDURE log_msg(pv_message in varchar2) IS
  vv_message VARCHAR2(1000);
BEGIN

  vv_message := SUBSTR(pv_message, 1, 1000);

  IF (vv_message IS NULL) THEN
    vv_message := TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS');
  END IF;

  IF (cb_debug = False) THEN
    fnd_file.put_line(fnd_file.LOG, vv_message);
  ELSE
    dbms_output.put_line('LOG : ' || substr(vv_message, 1, 253));
  END IF;

END log_msg;

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
        pv_errbuf    := 'Paramètre DESCRIPTION AP : ' || pv_errbuf;
        RETURN;
    ELSIF gv_description_ap IS NULL
    THEN
        pv_errbuf    := 'Paramètre DESCRIPTION AP : Aucune donnée trouvée';
        pn_retcode   := 1;
        RETURN;
    END IF;


    Dka_Tools_Pkg.get_parameter ('IAPLOADIMG_XEROX', 'CATEGORY', rec_param, pv_errbuf, pn_retcode);
    vv_category_ap                  := rec_param.varchar2_value;

    IF pn_retcode != 0
    THEN
        pv_errbuf    := 'Paramètre CATEGORY AP : ' || pv_errbuf;
        RETURN;
    ELSIF vv_category_ap IS NULL
    THEN
        pv_errbuf    := 'Paramètre CATEGORY AP : Aucune donnée trouvée';
        pn_retcode   := 2;
        RETURN;
    END IF;

    Dka_Tools_Pkg.get_parameter ('SAPGETIMG_WF', 'NBRE_JOUR_ACCESS', rec_param, pv_errbuf, pn_retcode);
    gn_nbre_jour                  := rec_param.number_value;

    IF pn_retcode != 0
    THEN
        pv_errbuf    := 'Paramètre NBRE_JOUR_ACCESS : ' || pv_errbuf;
        RETURN;
    ELSIF gn_nbre_jour IS NULL
    THEN
        pv_errbuf    := 'Paramètre NBRE_JOUR_ACCESS : Aucune donnée trouvée';
        pn_retcode   := 3;
        RETURN;
    END IF;

    -- Récupération de l'id correspondant à la categorie de document
    SELECT category_id
    INTO gn_category_id_ap
    FROM fnd_document_categories
    WHERE name = vv_category_ap;

    -- Récupération de l'id correspondant au type de document
    SELECT distinct datatype_id
    INTO gn_datatype_id
    FROM fnd_document_datatypes
    WHERE name = gv_datatype_name;

EXCEPTION
    WHEN OTHERS
    THEN
        pn_retcode   := 4;
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
        pv_errbuf    := 'Paramètre DESCRIPTION PO : ' || pv_errbuf;
        RETURN;
    ELSIF gv_description_po IS NULL
    THEN
        pv_errbuf    := 'Paramètre DESCRIPTION PO : Aucune donnée trouvée';
        pn_retcode   := 1;
        RETURN;
    END IF;

    Dka_Tools_Pkg.get_parameter ('SPOBON', 'CATEGORY', rec_param, pv_errbuf, pn_retcode);
    vv_category_po                  := rec_param.varchar2_value;

    IF pn_retcode != 0
    THEN
        pv_errbuf    := 'Paramètre CATEGORY PO : ' || pv_errbuf;
        RETURN;
    ELSIF vv_category_po IS NULL
    THEN
        pv_errbuf    := 'Paramètre CATEGORY PO : Aucune donnée trouvée';
        pn_retcode   := 2;
        RETURN;
    END IF;

    Dka_Tools_Pkg.get_parameter ('SAPGETIMG_WF', 'NBRE_JOUR_ACCESS', rec_param, pv_errbuf, pn_retcode);
    gn_nbre_jour                  := rec_param.number_value;

    IF pn_retcode != 0
    THEN
        pv_errbuf    := 'Paramètre NBRE_JOUR_ACCESS : ' || pv_errbuf;
        RETURN;
    ELSIF gn_nbre_jour IS NULL
    THEN
        pv_errbuf    := 'Paramètre NBRE_JOUR_ACCESS : Aucune donnée trouvée';
        pn_retcode   := 3;
        RETURN;
    END IF;

    -- Récupération de l'id correspondant à la categorie de document
    SELECT category_id
    INTO gn_category_id_po
    FROM fnd_document_categories
    WHERE name = vv_category_po;

    -- Récupération de l'id correspondant au type de document
    SELECT distinct datatype_id
    INTO gn_datatype_id
    FROM fnd_document_datatypes
    WHERE name = gv_datatype_name;

EXCEPTION
    WHEN OTHERS
    THEN
        pn_retcode   := 4;
        pv_errbuf    := SUBSTR('INIT PO: ' ||SQLERRM,1,250);
END init_po;


-------------------------------------------------------------------------------------------------------------------
--  Nom           : authorize
--  Description   : Fonction donnant l'autorisation d'accès au lob
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
    fnd_message.set_token('ROUTINE', 'XXDKA_SAPGETIMG_WF_PKG.authorize');
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

  url := fnd_web_config.trail_slash(gfm_agent)||'fndgfm/fnd_gfm.get/'||
           access_id||'/'||file_id||'/fnd_gfm'||file_ext;

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
--    pv_file_name       varchar2  
--  VALEUR RETOURNEE :
--     url       : varchar2
--        cas particulier : -1 : Aucune image n'est rattachée à cette facture
--                          -2 : Erreur
-------------------------------------------------------------------------------------------------------------------
FUNCTION get_url_image_facture (pn_invoice_id  IN NUMBER,
                               pv_entity_type IN VARCHAR2,
                               pv_file_name IN VARCHAR2)
    RETURN VARCHAR2
IS
  gfm_agent      VARCHAR2(255);
  v_media_id     NUMBER;
  pv_errbuf      VARCHAR2(250);
  pn_retcode     NUMBER := 0;
  url            VARCHAR2(500);
  v_entity_name  fnd_attached_documents.entity_name%TYPE;   
  v_pk1_value    fnd_attached_documents.pk1_value%TYPE;     

BEGIN
     ----- Appel de la procédure INIT_AP-----
     init_ap (pv_errbuf, pn_retcode);

     IF pn_retcode != 0
     THEN
         -- Erreur lors de la récupération des variables globales
         url := '-2';
         log_msg('Erreur lors de init_ap ' || pv_errbuf || 'pn_retcode = ' ||pn_retcode);
     ELSE
         v_pk1_value := to_char(pn_invoice_id);

         SELECT decode(pv_entity_type, 'OI', gv_entity_name_oi, gv_entity_name_ap)
         INTO   v_entity_name
         FROM   dual;

         -- Récupération de l'Id du fichier
         BEGIN
              SELECT fdt.media_id
              INTO v_media_id
              FROM fnd_attached_documents fad,
                   fnd_documents_tl fdt,
                   fnd_documents fd
              WHERE fdt.document_id = fad.document_id
                AND fd.document_id  = fdt.document_id
                AND fd.category_id  = gn_category_id_ap
                AND fd.datatype_id  = gn_datatype_id
                AND fdt.language    = USERENV('LANG')
                AND fad.entity_name = v_entity_name    
                AND fad.pk1_value   = v_pk1_value
                AND fdt.file_name   = pv_file_name;     
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
              -- Aucun document joint de type IMAGE FACTURE n'existe pour cette facture
              url := '-1';
         END IF;

     END IF;

  ----- return value -----
  RETURN (url);

END get_url_image_facture;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : return_nom_image
--  Description   : Renvoie le nom de l'image de la facture
--
--  PARAMETRES    :
--    pn_id_facture      : number
--  VALEUR RETOURNEE :
--    vn_nom_image       : varchar2
-------------------------------------------------------------------------------------------------------------------
FUNCTION return_nom_image(pn_id_facture NUMBER) RETURN VARCHAR2 IS

vn_nom_image	VARCHAR2(2048);

BEGIN
  
SELECT fdt.file_name 
  INTO vn_nom_image
  FROM --fnd_documents_vl fdt,
       fnd_documents_tl fdt,
       fnd_attached_documents fad
 WHERE fdt.document_id = fad.document_id
	 AND fad.pk1_value = pn_id_facture
-- 17/06/2021  NBO INC0514828 - Impossible de lancer le spécifique SPE154 _ Restitution factures numérisées.    
   AND fad.entity_name = 'AP_INVOICES'
	 AND fdt.file_name IS NOT NULL
   AND rownum = 1; 
  
  RETURN(vn_nom_image);
  
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN(NULL);
             
END return_nom_image;

END DKA_SAPGETIMG_AL_PKG;
/
SHOW ERROR PACKAGE BODY DKA_SAPGETIMG_AL_PKG;
EXIT
