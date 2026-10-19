CREATE OR REPLACE PACKAGE BODY DKA_SPOBDCURL_PKG IS

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PRIVEES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  gv_description VARCHAR2(250);

  ----------------------------------------------------------------------------------------------
  --
  -- $Id$
  --
  -- NOM               : DKA_SPOBDCURL_PKG
  -- DESCRIPTION       : Creation du package specifique pour le specifique 068
  --
  -- AUTEUR           : M. EGOT
  -- DATE DE CREATION : 27/09/2016
  -- DOC. ASSOCIEE    : SPECIFICATIONS FONCTIONNELLES :
  --                    SPECIFICATIONS TECHNIQUES     :
  ---
  ----------------------------------------------------------------------------------------------
  -- NOM DU PROGRAMME :
  --- PARAMETRES       :
  --
  -- HISTORIQUE DES MODIFICATIONS
  -- DATE       VERSION QUI           DESCRIPTION
  ----------------------------------------------------------------------------------------------
  -- 28/02/2017 1.1     Maxime EGOT   artf2109504 : SPE068 - Consultation du BDC dans iProc
  ----------------------------------------------------------------------------------------------
  
  -------------------------------------------------------------
  --Start of Comments
  --Name        : url_bdc
  --
  --Pre-reqs    : IN parameters need to be passed in with valid values
  --
  --Modifies    : None
  --
  --Locks       : None
  --
  --Function    : This procedure deletes all expense lines associated with a
  --              Temp Labor Requisition line that fails validations.
  --
  --Parameter(s):
  --
  --IN          : itemtype IN VARCHAR2,
  --              itemkey  IN VARCHAR2
  --
  --IN OUT:     : None
  --
  --OUT         : None
  --
  --Returns     : None
  --
  --Notes       : None
  --
  --Testing     : None
  --
  --End of Comments
  -------------------------------------------------------------

  FUNCTION url_bdc(p_segment1 IN VARCHAR2) return varchar2 IS
  
    vv_url          varchar2(2000);
    vn_file_id      number;
    vn_header_id    po_headers.po_header_id%type;
    vn_release_id   po_releases.po_release_id%type;
    vn_release_num  number;
    vn_revision_num number;
    vv_segment_tmp  varchar2(2000);
    rec_param       dka_parameters%ROWTYPE;
    pv_errbuf       VARCHAR2(500);
    pn_retcode      NUMBER;
    e_err_param EXCEPTION;
  
  BEGIN
  
    -- Variables liées à la création du document joint
    Dka_Tools_Pkg.get_parameter('SPOBON', 'DESCRIPTION', rec_param, pv_errbuf, pn_retcode);
    gv_description := rec_param.varchar2_value;
  
    IF pn_retcode != 0 OR gv_description IS NULL THEN
      RAISE e_err_param;
    END IF;
  
    BEGIN
    
      SELECT po_header_id, revision_num
        INTO vn_header_id, vn_revision_num
        FROM po_headers
       WHERE segment1 = p_segment1
         AND org_id = fnd_profile.value('ORG_ID');
    
      SELECT max(fl.file_id)
        INTO vn_file_id
        FROM fnd_lobs fl, fnd_attached_docs_form_vl fad
       WHERE fl.file_id = fad.media_id
         AND fad.function_name = 'PO_POXPOEPO'
         AND fad.pk1_value = to_char(vn_header_id)
       --AND fad.pk2_value = to_char(vn_revision_num)
         AND fad.document_description = gv_description;
    
      vv_url := fnd_gfm.construct_download_url2(gfm_agent     => fnd_profile.value('APPS_WEB_AGENT'),
                                                file_id       => vn_file_id,
                                                purge_on_view => FALSE,
                                                modplsql      => false,
                                                authenticate  => TRUE); -- R12 pour autoriser accès fichier
    
      dbms_output.put_line('  url acces PDF =' || vv_url);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vv_url := 'NO_DATA_FOUND';
    END;
  
    RETURN vv_url;
  
  EXCEPTION
    WHEN e_err_param THEN
      RETURN 'NO_DATA_FOUND';
    
  END url_bdc;

END DKA_SPOBDCURL_PKG;
/
show error;
exit;
