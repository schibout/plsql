CREATE OR REPLACE PACKAGE BODY APPS.DKA_IAPBANK_PKG
AS
------------------------------------------------------------------------
-- $Id: DKA_IAPBANK_PKG.pks
-- Capgemini
-- Nom              : DKA_IAPBANK_PKG.pks
-- Description      : Spécification du package DKA_IAPBANK_PKG
-- Auteur           : Coudrier Benjamin
-- Date de création : 27/04/2012
-- Doc. associée    :
-- Commentaires     : A exécuter sous SQLPLUS avec l'utilisateur APPS
------------------------------------------------------------------------
-- Historique
-- Date       Qui Description
-- ---------- --- ------------------------------------------------------
-- 2012/01/22 JJA Optimisation de la lecture du lob
-- 2013/03/04 BCO DPE20130016 - Avenant - Fichier Banque de France - RG Code BIC
-- 2013/07/23 BCO INC000000431319 - MAJ Référentiel bancaire a partir fichier FGD Banque de France
--          Modification RG sur Date fin Agence.
-- 2014/01/16 BCO INC000000431319 - Modification RG10b - Modification de la date de fin de OA.
-- 2016/05/31 JPE Migration R12 Utilisation des apis standards pour maj du reférentiel bancaire
-- 2018/03/29 JJA Optimisation process
-- 2019/01/29 NBO Optimisation du processus
-- 2023/10/25 ARA EDB368 - Chargement du fichier Banque de France (Enlever la règle du 500 caracteres pour chaque ligne)
-- ---------- --- ------------------------------------------------------
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PRIVEES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  cn_user_id          CONSTANT NUMBER    := fnd_profile.value('USER_ID');
  cn_login_id     CONSTANT NUMBER    := fnd_profile.value('LOGIN_ID');
  cn_num_traitement CONSTANT NUMBER    := fnd_profile.value('CONC_REQUEST_ID');
  cv_countrycode    CONSTANT VARCHAR2(2) := 'FR'; 
  cv_currency     CONSTANT VARCHAR2(3) := 'EUR';  
  
  ------------------------------------------------------------------------------------
  --  Nom           : historize_file_tmp_gui
  --          Historise les données de la table DKA_IAPBANK_GUI_TMP 
  --          dans la table DKA_IAPBANK_GUI_TMP_HIST
  --  PARAMETRES    :
  --      vn_error  : numéro du probleme.
  --      vv_ch_pb :  description du probleme.
  --  VALEUR RETOURNEE :
  ------------------------------------------------------------------------------------
  PROCEDURE historize_file_tmp_gui (vn_error IN OUT NUMBER,
                    vv_ch_pb IN OUT VARCHAR2) IS
    nbr_iapbank_gui_tmp   NUMBER;
  BEGIN
    -- Initialisation de la variable nbr_iapbank_gui_tmp.
    nbr_iapbank_gui_tmp   := 0;
    
    -- Recherche de l'existence d'enregistrement dans la table DKA_IAPBANK_GUI_TMP.
    BEGIN
      SELECT 1
      INTO nbr_iapbank_gui_tmp
      FROM dual
      WHERE EXISTS (SELECT NULL FROM DKA_IAPBANK_GUI_TMP);
    EXCEPTION
      WHEN OTHERS THEN
        vn_error := 1;
        vv_ch_pb := 'Impossible de contrôler l''existence d''enregistrement dans la table DKA_IAPBANK_GUI_TMP.';
        nbr_iapbank_gui_tmp := 0;
    END;
    
    IF nbr_iapbank_gui_tmp > 0 THEN
      BEGIN
        INSERT INTO DKA_IAPBANK_GUI_TMP_HIST
          (CODE_MOUVEMENT,
           CODE_ETABLISSEMENT,
           CODE_IMMAT_GUI,
           CODE_SITUATION,
           DENOMINATION_PART,
           NOM_GUICHET,
           CODE_ETABLISSEMENT_CBL,
           CODE_GUI_REPRENEUR,
           CODE_GEO_INSEE,
           ADRESSE_3,
           ADRESSE_4,
           ADRESSE_5,
           ADRESSE_6,
           ADRESSE_SWIFT,
           DATE_OPEN_GUICHET,
           DATE_CLOSE_GUICHET,
           DATE_END_GUICHET,
           CODE_ROUT_GUICHET,
           LIB_DOM_RIB,
           NATURE_GUICHET,
           LAST_UPDATE_DATE,
           LAST_UPDATED_BY,
           NAME_FILE)
        SELECT  CODE_MOUVEMENT,
            CODE_ETABLISSEMENT,
            CODE_IMMAT_GUI,
            CODE_SITUATION,
            DENOMINATION_PART,
            NOM_GUICHET,
            CODE_ETABLISSEMENT_CBL,
            CODE_GUI_REPRENEUR,
            CODE_GEO_INSEE,
            ADRESSE_3,
            ADRESSE_4,
            ADRESSE_5,
            ADRESSE_6,
            ADRESSE_SWIFT,
            DATE_OPEN_GUICHET,
            DATE_CLOSE_GUICHET,
            DATE_END_GUICHET,
            CODE_ROUT_GUICHET,
            LIB_DOM_RIB,
            NATURE_GUICHET,
            LAST_UPDATE_DATE,
            LAST_UPDATED_BY,
            NAME_FILE
        FROM  DKA_IAPBANK_GUI_TMP;
        
        commit;
      EXCEPTION
        WHEN OTHERS THEN
          vn_error := 1;
          vv_ch_pb := 'Impossible d''historiser les données dans la table DKA_IAPBANK_GUI_TMP_HIST.';
      END;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      vn_error := 2;
      vv_ch_pb := 'ERREUR : Exécution de la fonction historize_file_tmp_gui.';
  END historize_file_tmp_gui;
  
  
  ------------------------------------------------------------------------------------
  --  Nom           : historize_file_tmp_etab
  --          Historise les données de la table DKA_IAPBANK_ETAB_TMP 
  --          dans la tables DKA_IAPBANK_ETAB_TMP_HIST
  --  PARAMETRES    :
  --      vn_error  : numéro du probleme.
  --      vv_ch_pb :  description du probleme.
  --  VALEUR RETOURNEE :
  ------------------------------------------------------------------------------------
  PROCEDURE historize_file_tmp_etab ( vn_error IN OUT NUMBER,
                    vv_ch_pb IN OUT VARCHAR2) IS
    nbr_iapbank_etab_tmp  NUMBER;
  BEGIN
    -- Initialisation des variables nbr_iapbank_etab_tmp.
    nbr_iapbank_etab_tmp  := 0;
    
    -- Recherche de l'existence d'enregistrement dans les tables DKA_IAPBANK_ETAB_TMP.
    BEGIN
      
      SELECT 1
      INTO nbr_iapbank_etab_tmp
      FROM dual
      WHERE EXISTS (SELECT NULL FROM DKA_IAPBANK_ETAB_TMP);
      
    EXCEPTION
      WHEN OTHERS THEN
        -- vn_error := 1;
        vv_ch_pb := 'Impossible de contrôler l''existence d''enregistrement dans la table DKA_IAPBANK_ETAB_TMP.';
        nbr_iapbank_etab_tmp := 0;
    END;
    
    IF nbr_iapbank_etab_tmp > 0 THEN
      BEGIN
        INSERT INTO DKA_IAPBANK_ETAB_TMP_HIST
          (CODE_MOUVEMENT,
           CODE_ETABLISSEMENT,
           CODE_SITUATION,
           DENOMINATION1,
           DENOMINATION2,
           CODE_NAT_ACTIVITE,
           CODE_ORG_REPRES,
           DATE_AGREMENT,
           DATE_RETRAIT_AGREMENT,
           DATE_FIN_DIFFUSION,
           ADRESSE_3,
           ADRESSE_4,
           ADRESSE_5,
           ADRESSE_6,
           ARGUMENT_TRI,
           CODE_ETABLISSEMENT_ABS,
           OPT_ID_INVARIANT,
           DATE_EFFET_OPT_ID_INV,
           CODE_BIC,
           LIBELLE_COMMERCIAL,
           LAST_UPDATE_DATE,
           LAST_UPDATED_BY,
           NAME_FILE)
        SELECT  CODE_MOUVEMENT,
            CODE_ETABLISSEMENT,
            CODE_SITUATION,
            DENOMINATION1,
            DENOMINATION2,
            CODE_NAT_ACTIVITE,
            CODE_ORG_REPRES,
            DATE_AGREMENT,
            DATE_RETRAIT_AGREMENT,
            DATE_FIN_DIFFUSION,
            ADRESSE_3,
            ADRESSE_4,
            ADRESSE_5,
            ADRESSE_6,
            ARGUMENT_TRI,
            CODE_ETABLISSEMENT_ABS,
            OPT_ID_INVARIANT,
            DATE_EFFET_OPT_ID_INV,
            CODE_BIC,
            LIBELLE_COMMERCIAL,
            LAST_UPDATE_DATE,
            LAST_UPDATED_BY,
            NAME_FILE
        FROM  DKA_IAPBANK_ETAB_TMP;
        commit;
      EXCEPTION
        WHEN OTHERS THEN
          vn_error := 1;
          vv_ch_pb := 'Impossible d''historiser les données dans la table DKA_IAPBANK_ETAB_TMP.';
      END;
    END IF;
    
  EXCEPTION
    WHEN OTHERS THEN
      vn_error := 2;
      vv_ch_pb := 'ERREUR : Exécution de la fonction historize_file_tmp_etab.';
  END historize_file_tmp_etab;
  
  
  ------------------------------------------------------------------------------------
  --  Nom           : dka_chgt_file_situa_gui
  --          Chargement fichier Guichets (FGD Banque de France)
  --          Fichier Situation
  --
  --  PARAMETRES    :
  --      access_id  : id du fichier
  --      pv_file_id : nom du fichier
  --  VALEUR RETOURNEE :
  ------------------------------------------------------------------------------------
  FUNCTION dka_chgt_file_situa_gui(access_id   IN           NUMBER,
                   pv_file_id OUT           VARCHAR2) RETURN VARCHAR2
  IS
    --DEBUT-------------------------------------------------------------------DEBUT--
    -- définition des variables pour l'insertion dans la table DKA_IAPBANK_GUI_TMP --
    --DEBUT-------------------------------------------------------------------DEBUT--
    vv_element1                DKA_IAPBANK_GUI_TMP.CODE_MOUVEMENT%TYPE;
    vv_element2                DKA_IAPBANK_GUI_TMP.CODE_ETABLISSEMENT%TYPE;
    vv_element3                DKA_IAPBANK_GUI_TMP.CODE_IMMAT_GUI%TYPE;
    vv_element4                DKA_IAPBANK_GUI_TMP.CODE_SITUATION%TYPE;
    vv_element5                DKA_IAPBANK_GUI_TMP.DENOMINATION_PART%TYPE;
    vv_element6                DKA_IAPBANK_GUI_TMP.NOM_GUICHET%TYPE;
    vv_element7                DKA_IAPBANK_GUI_TMP.CODE_ETABLISSEMENT_CBL%TYPE;
    vv_element8                DKA_IAPBANK_GUI_TMP.CODE_GUI_REPRENEUR%TYPE;
    vv_element9                DKA_IAPBANK_GUI_TMP.CODE_GEO_INSEE%TYPE;
    vv_element10               DKA_IAPBANK_GUI_TMP.ADRESSE_3%TYPE;
    vv_element11               DKA_IAPBANK_GUI_TMP.ADRESSE_4%TYPE;
    vv_element12               DKA_IAPBANK_GUI_TMP.ADRESSE_5%TYPE;
    vv_element13               DKA_IAPBANK_GUI_TMP.ADRESSE_6%TYPE;
    vv_element14               DKA_IAPBANK_GUI_TMP.ADRESSE_SWIFT%TYPE;
    vv_element15               VARCHAR2(20);
    vv_element16               VARCHAR2(20);
    vv_element17               VARCHAR2(20);
    vv_element18               DKA_IAPBANK_GUI_TMP.CODE_ROUT_GUICHET%TYPE;
    vv_element19               DKA_IAPBANK_GUI_TMP.LIB_DOM_RIB%TYPE;
    vv_element20               DKA_IAPBANK_GUI_TMP.NATURE_GUICHET%TYPE;
    
    vv_result                  VARCHAR2(200);
    vv_file_name         VARCHAR2(256);
    vv_file_id                 VARCHAR2(256);
    vn_gfm_id                  NUMBER := NULL;
    src_lob                    BLOB;
    buffer_var1                CLOB ;

    vv_separator               VARCHAR2(1) := ';';
    vn_dest_offset             INTEGER :=1;
    vn_src_offset              INTEGER :=1;
    vn_warning                 INTEGER;
    vn_lang_context            NUMBER := DBMS_LOB.DEFAULT_LANG_CTX;

    vn_i                       NUMBER:=0;
    vv_buf                     VARCHAR2(32767);
    --vn_pos1                    NUMBER:=1; -->optimisation
    --vn_pos                     NUMBER:=1; -->optimisation
    --vn_len                     INTEGER; -->optimisation
    
    vv_oracle_charset          fnd_lobs.oracle_charset%type;

    vn_depassement             NUMBER:= 0;

    vv_step                    VARCHAR2(200);
    vc_last_car                VARCHAR2(1);

    vn_error                   NUMBER;
    vv_ch_pb                   VARCHAR2(1000);
    vv_existing_records        NUMBER;
    vv_cmpt_commit       NUMBER;
    
    --Optimisation
    cn_lg_ligne       CONSTANT NUMBER := 500; --longueur de la ligne
    vn_ligne                   NUMBER;
    vn_position                NUMBER;
    vn_longueur                NUMBER;
  --EDB368
  vn_t1                      NUMBER :=0;
    
  BEGIN
    vv_result := 'OK';
    vn_error := 0;
      vv_cmpt_commit := 0;
    -- Historise les données de la table DKA_IAPBANK_GUI_TMP 
    -- dans la table DKA_IAPBANK_GUI_TMP_HIST
    historize_file_tmp_gui(vn_error, vv_ch_pb);
    
    IF vn_error = 0 THEN
      -- Purge de la table temporaire DKA_IAPBANK_GUI_TMP. --
      EXECUTE IMMEDIATE 'TRUNCATE TABLE dka.DKA_IAPBANK_GUI_TMP';
      
      vv_file_id := '';
      vn_gfm_id := fnd_gfm.get_file_id(access_id);

      vv_result := 'OK';

      IF vn_gfm_id IS NOT NULL THEN
        
        SELECT  
         file_name, 
         decode(instr(file_name,'/'),0,file_name,substr(file_name,instr(file_name,'/')+1)), 
         file_data,  
         oracle_charset
        INTO    
         vv_file_name, 
         vv_file_id, 
         src_lob,  
         vv_oracle_charset
        FROM    fnd_lobs
        WHERE   file_id =  vn_gfm_id;
    
    
    
    
        -- get file size
        --vn_len :=  DBMS_LOB.GETLENGTH(src_lob); -->optimisation

        -- convertit le blob en clob
        dbms_lob.createtemporary(buffer_var1, TRUE);

        dbms_lob.convertToClob( dest_lob     => buffer_var1,
                    src_blob     => src_lob,
                    amount       => DBMS_LOB.LOBMAXSIZE,
                    dest_offset  => vn_dest_offset,
                    src_offset   =>  vn_src_offset,
                    blob_csid    =>  nls_charset_id(vv_oracle_charset)     ,
                    lang_context => vn_lang_context,
                    warning      => vn_warning);

        --vn_len := DBMS_LOB.GETLENGTH(buffer_var1); -->optimisation
        vn_longueur := DBMS_LOB.GETLENGTH(buffer_var1);

        --vn_pos := dbms_lob.instr(buffer_var1,chr(10),1,1); -->optimisation

        --optimisation 
        --vn_ligne := dbms_lob.instr(buffer_var1,chr(10),1,1); --EDB368
        vn_position := 1;
        
        --vn_pos1 := 1; -->optimisation

        vn_i := 0;

        WHILE vn_position < vn_longueur --optimisation vn_pos  <= vn_len
        LOOP
          vn_error := 0;
          vv_ch_pb := '';
          vn_i := vn_i + 1;
          vv_cmpt_commit := vv_cmpt_commit + 1;
          -->optimisation vv_buf := dbms_lob.substr(buffer_var1, vn_pos - vn_pos1 -1, vn_pos1);
          
      
      
      -->EDB368
    SELECT dbms_lob.instr(to_clob(FILE_DATA), '
', 1,vn_i)
      INTO vn_t1
      FROM fnd_lobs 
      WHERE  file_id =  vn_gfm_id;
      
          /*SELECT utl_raw.cast_to_varchar2(dbms_lob.substr(FILE_DATA,cn_lg_ligne,vn_position)) 
          INTO vv_buf
          FROM fnd_lobs 
          WHERE  file_id =  vn_gfm_id;*/ --EDB368
      
    SELECT utl_raw.cast_to_varchar2(dbms_lob.substr(FILE_DATA,vn_t1-vn_position,vn_position)) 
          INTO vv_buf
          FROM fnd_lobs 
          WHERE  file_id =  vn_gfm_id;
    
      IF vn_position = 1 THEN
      vn_position := vn_position + vn_t1;
      END IF;
      
          
          vn_position := vn_t1;
    
    --<END EDB368
    
          --vn_position := vn_position + vn_ligne;--EDB368
          --<optimisation
          
          SELECT substr(vv_buf, -1) INTO vc_last_car FROM DUAL;

          IF(vc_last_car <> ';') THEN
            vv_buf := vv_buf || ';';
          END IF;

          vv_step   := 'ELEMENT1';
          vv_element1 := 'S';
      
          vv_step := 'ELEMENT2';
          BEGIN
            --vv_element2 := substr(vv_buf,1, instr(vv_buf, vv_separator, 1, 1)-1); --EDB368
      vv_element2 := replace(substr(vv_buf,1, instr(vv_buf, vv_separator, 1, 1)-1),'
','');
          EXCEPTION WHEN OTHERS
            THEN
              vn_error  := 1;
              vv_ch_pb  := vv_ch_pb || 'ELEMENT2, ';
              vv_element2 := NULL;
          END;
      
          vv_step := 'ELEMENT3';
          BEGIN
            vv_element3 := substr(vv_buf,  instr(vv_buf, vv_separator, 1, 2-1)+1, ((instr(vv_buf, vv_separator, 1, 2))-(instr(vv_buf, vv_separator, 1, 2-1)+1)));
          EXCEPTION WHEN OTHERS
            THEN
              vn_error  := 1;
              vv_ch_pb  := vv_ch_pb || 'ELEMENT3, ';
              vv_element3 := NULL;
          END;

          vv_step := 'ELEMENT4';
          BEGIN
            vv_element4 := substr(vv_buf,  instr(vv_buf, vv_separator, 1, 3-1)+1, ((instr(vv_buf, vv_separator, 1, 3))-(instr(vv_buf, vv_separator, 1, 3-1)+1)));
          EXCEPTION WHEN OTHERS
            THEN
              vn_error  := 1;
              vv_ch_pb  := vv_ch_pb || 'ELEMENT4, ';
              vv_element4 := NULL;
          END;

          vv_step := 'ELEMENT5';
          BEGIN
            vv_element5 := substr(vv_buf,  instr(vv_buf, vv_separator, 1, 4-1)+1, ((instr(vv_buf, vv_separator, 1, 4))-(instr(vv_buf, vv_separator, 1, 4-1)+1)));
          EXCEPTION WHEN OTHERS
            THEN
              vn_error  := 1;
              vv_ch_pb  := vv_ch_pb || 'ELEMENT5, ';
              vv_element5 := NULL;
          END;

          vv_step := 'ELEMENT6';
          BEGIN
            vv_element6 := substr(vv_buf,  instr(vv_buf, vv_separator, 1, 5-1)+1, ((instr(vv_buf, vv_separator, 1, 5))-(instr(vv_buf, vv_separator, 1, 5-1)+1)));
          EXCEPTION WHEN OTHERS
            THEN
              vn_error  := 1;
              vv_ch_pb  := vv_ch_pb || 'ELEMENT6, ';
              vv_element6 := NULL;
          END;

          vv_step := 'ELEMENT7';
          BEGIN
            vv_element7 := substr(vv_buf,  instr(vv_buf, vv_separator, 1, 6-1)+1, ((instr(vv_buf, vv_separator, 1, 6))-(instr(vv_buf, vv_separator, 1, 6-1)+1)));
          EXCEPTION WHEN OTHERS
            THEN
              vn_error  := 1;
              vv_ch_pb  := vv_ch_pb || 'ELEMENT7, ';
              vv_element7 := NULL;
          END;
      
          vv_step := 'ELEMENT8';
          BEGIN
            vv_element8 := substr(vv_buf,  instr(vv_buf, vv_separator, 1, 7-1)+1, ((instr(vv_buf, vv_separator, 1, 7))-(instr(vv_buf, vv_separator, 1, 7-1)+1)));
          EXCEPTION WHEN OTHERS
            THEN
              vn_error  := 1;
              vv_ch_pb  := vv_ch_pb || 'ELEMENT8, ';
              vv_element8 := NULL;
          END;
        
          vv_step := 'ELEMENT9';
          BEGIN
            vv_element9 := substr(vv_buf,  instr(vv_buf, vv_separator, 1, 8-1)+1, ((instr(vv_buf, vv_separator, 1, 8))-(instr(vv_buf, vv_separator, 1, 8-1)+1)));
          EXCEPTION WHEN OTHERS
            THEN
              vn_error  := 1;
              vv_ch_pb  := vv_ch_pb || 'ELEMENT9, ';
              vv_element9 := NULL;
          END;
        
          vv_step := 'ELEMENT10';
          BEGIN
            vv_element10 := substr(vv_buf,  instr(vv_buf, vv_separator, 1, 9-1)+1, ((instr(vv_buf, vv_separator, 1, 9))-(instr(vv_buf, vv_separator, 1, 9-1)+1)));
          EXCEPTION WHEN OTHERS
            THEN
              vn_error  := 1;
              vv_ch_pb  := vv_ch_pb || 'ELEMENT10, ';
              vv_element10 := NULL;
          END;
        
          vv_step := 'ELEMENT11';
          BEGIN
            vv_element11 := substr(vv_buf,  instr(vv_buf, vv_separator, 1, 10-1)+1, ((instr(vv_buf, vv_separator, 1, 10))-(instr(vv_buf, vv_separator, 1, 10-1)+1)));
          EXCEPTION WHEN OTHERS
            THEN
              vn_error   := 1;
              vv_ch_pb   := vv_ch_pb || 'ELEMENT11, ';
              vv_element11 := NULL;
          END;
        
          vv_step := 'ELEMENT12';
          BEGIN
            vv_element12 := substr(vv_buf,  instr(vv_buf, vv_separator, 1, 11-1)+1, ((instr(vv_buf, vv_separator, 1, 11))-(instr(vv_buf, vv_separator, 1, 11-1)+1)));
          EXCEPTION WHEN OTHERS
            THEN
              vn_error   := 1;
              vv_ch_pb   := vv_ch_pb || 'ELEMENT12, ';
              vv_element12 := NULL;
          END;
          
          vv_step := 'ELEMENT13';
          BEGIN
            vv_element13 := substr(vv_buf,  instr(vv_buf, vv_separator, 1, 12-1)+1, ((instr(vv_buf, vv_separator, 1, 12))-(instr(vv_buf, vv_separator, 1, 12-1)+1)));
          EXCEPTION WHEN OTHERS
            THEN
              vn_error   := 1;
              vv_ch_pb   := vv_ch_pb || 'ELEMENT13, ';
              vv_element13 := NULL;
          END;
          
          vv_step := 'ELEMENT14';
          BEGIN
            vv_element14 := substr(vv_buf,  instr(vv_buf, vv_separator, 1, 13-1)+1, ((instr(vv_buf, vv_separator, 1, 13))-(instr(vv_buf, vv_separator, 1, 13-1)+1)));
          EXCEPTION WHEN OTHERS
            THEN
              vn_error   := 1;
              vv_ch_pb   := vv_ch_pb || 'ELEMENT14, ';
              vv_element14 := NULL;
          END;
          
          vv_step := 'ELEMENT15';
          BEGIN
            vv_element15 := substr(vv_buf,  instr(vv_buf, vv_separator, 1, 14-1)+1, ((instr(vv_buf, vv_separator, 1, 14))-(instr(vv_buf, vv_separator, 1, 14-1)+1)));
          EXCEPTION WHEN OTHERS
            THEN
              vn_error   := 1;
              vv_ch_pb   := vv_ch_pb || 'ELEMENT15, ';
              vv_element15 := NULL;
          END;
          
          vv_step := 'ELEMENT16';
          BEGIN
            vv_element16 := substr(vv_buf,  instr(vv_buf, vv_separator, 1, 15-1)+1, ((instr(vv_buf, vv_separator, 1, 15))-(instr(vv_buf, vv_separator, 1, 15-1)+1)));
          EXCEPTION WHEN OTHERS
            THEN
              vn_error   := 1;
              vv_ch_pb   := vv_ch_pb || 'ELEMENT16, ';
              vv_element16 := NULL;
          END;
          
          vv_step := 'ELEMENT17';
          BEGIN
            vv_element17 := substr(vv_buf,  instr(vv_buf, vv_separator, 1, 16-1)+1, ((instr(vv_buf, vv_separator, 1, 16))-(instr(vv_buf, vv_separator, 1, 16-1)+1)));
          EXCEPTION WHEN OTHERS
            THEN
              vn_error   := 1;
              vv_ch_pb   := vv_ch_pb || 'ELEMENT17, ';
              vv_element17 := NULL;
          END;
          
          vv_step := 'ELEMENT18';
          BEGIN
            vv_element18 := substr(vv_buf,  instr(vv_buf, vv_separator, 1, 17-1)+1, ((instr(vv_buf, vv_separator, 1, 17))-(instr(vv_buf, vv_separator, 1, 17-1)+1)));
          EXCEPTION WHEN OTHERS
            THEN
              vn_error   := 1;
              vv_ch_pb   := vv_ch_pb || 'ELEMENT18, ';
              vv_element18 := NULL;
          END;
          
          vv_step := 'ELEMENT19';
          BEGIN
            vv_element19 := substr(vv_buf,  instr(vv_buf, vv_separator, 1, 18-1)+1, ((instr(vv_buf, vv_separator, 1, 18))-(instr(vv_buf, vv_separator, 1, 18-1)+1)));
          EXCEPTION WHEN OTHERS
            THEN
              vn_error   := 1;
              vv_ch_pb   := vv_ch_pb || 'ELEMENT19, ';
              vv_element19 := NULL;
          END;
        
          vv_step := 'ELEMENT20';
          BEGIN
            vv_element20 := substr(vv_buf,  instr(vv_buf, vv_separator, 1, 19-1)+1, ((instr(vv_buf, vv_separator, 1, 19))-(instr(vv_buf, vv_separator, 1, 19-1)+1)));
          EXCEPTION WHEN OTHERS
            THEN
              vn_error   := 1;
              vv_ch_pb   := vv_ch_pb || 'ELEMENT20, ';
              vv_element20 := NULL;
          END;
          
          IF vn_i > 1 THEN --On insere pas la ligne de titre
          
            -- Insertion dans la table DKA_IAPBANK_GUI_TMP
            INSERT INTO DKA_IAPBANK_GUI_TMP
               ( CODE_MOUVEMENT,
               CODE_ETABLISSEMENT,
               CODE_IMMAT_GUI,
               CODE_SITUATION,
               DENOMINATION_PART,
               NOM_GUICHET,
               CODE_ETABLISSEMENT_CBL,
               CODE_GUI_REPRENEUR,
               CODE_GEO_INSEE,
               ADRESSE_3,
               ADRESSE_4,
               ADRESSE_5,
               ADRESSE_6,
               ADRESSE_SWIFT,
               DATE_OPEN_GUICHET,
               DATE_CLOSE_GUICHET,
               DATE_END_GUICHET,
               CODE_ROUT_GUICHET,
               LIB_DOM_RIB,
               NATURE_GUICHET,
               LAST_UPDATE_DATE,
               LAST_UPDATED_BY,
               NAME_FILE
              )
            VALUES(
               rtrim(vv_element1, ' '),
               rtrim(vv_element2, ' '),
               rtrim(vv_element3, ' '),
               rtrim(vv_element4, ' '),
               rtrim(vv_element5, ' '),
               rtrim(vv_element6, ' '),
               rtrim(vv_element7, ' '),
               rtrim(vv_element8, ' '),
               rtrim(vv_element9, ' '),
               rtrim(vv_element10, ' '),
               rtrim(vv_element11, ' '),
               rtrim(vv_element12, ' '),
               rtrim(vv_element13, ' '),
               rtrim(vv_element14, ' '),
               rtrim(vv_element15, ' '),
               rtrim(vv_element16, ' '),
               rtrim(vv_element17, ' '),
               rtrim(vv_element18, ' '),
               rtrim(vv_element19, ' '),
               rtrim(vv_element20, ' '),
               sysdate,
               cn_user_id,
               vv_file_name
               );
               
            /*IF vv_cmpt_commit = 500 THEN
              commit;
              vv_cmpt_commit := 0;
            END IF;*/ --EDB368
            -- Fin insertion dans la table DKA_IAPBANK_GUI_TMP
          END IF;
          
          /*--optimisation
          vn_pos1 := vn_pos + 1;
          IF vn_pos = vn_len THEN
            EXIT;
          END IF;
          
          vn_pos := dbms_lob.instr(buffer_var1, chr(10), 1, vn_i +1);
          */
          
        END LOOP;
        commit;
      ELSE
        vv_result := 'PB_FILE';
      END IF;

      pv_file_id := vv_file_id;
    ELSE
      vv_result := 'PB_HIST';
    END IF;
    RETURN  (vv_result);

  EXCEPTION
    WHEN OTHERS THEN
      RETURN (SQLERRM || '(ligne : ' || vn_i || ' champ : ' || vv_step ||  ')');
  END dka_chgt_file_situa_gui;


  ------------------------------------------------------------------------------------
  --  Nom           : dka_chgt_file_situa_etab
  --          Chargement fichier Etablissement (FGD Banque de France)
  --          Fichier Situation
  --
  --  PARAMETRES    :
  --      access_id  : id du fichier
  --      pv_file_id : nom du fichier
  --  VALEUR RETOURNEE :
  ------------------------------------------------------------------------------------
  FUNCTION dka_chgt_file_situa_etab(access_id   IN           NUMBER,
                   pv_file_id OUT           VARCHAR2) RETURN VARCHAR2
  IS
    --DEBUT---------------------------------------------------------------DEBUT--
    -- définition des variables pour l'insertion dans la table DKA_IAPBANK_ETAB_TMP --
    --DEBUT---------------------------------------------------------------DEBUT--
    vv_element1                DKA_IAPBANK_ETAB_TMP.CODE_MOUVEMENT%TYPE;
    vv_element2                DKA_IAPBANK_ETAB_TMP.CODE_ETABLISSEMENT%TYPE;
    vv_element3                DKA_IAPBANK_ETAB_TMP.CODE_SITUATION%TYPE;
    vv_element4                DKA_IAPBANK_ETAB_TMP.DENOMINATION1%TYPE;
    vv_element5                DKA_IAPBANK_ETAB_TMP.DENOMINATION2%TYPE;
    vv_element6                DKA_IAPBANK_ETAB_TMP.CODE_NAT_ACTIVITE%TYPE;
    vv_element7                DKA_IAPBANK_ETAB_TMP.CODE_ORG_REPRES%TYPE;
    vv_element8                VARCHAR2(20);
    vv_element9                VARCHAR2(20);
    vv_element10               VARCHAR2(20);
    vv_element11               DKA_IAPBANK_ETAB_TMP.ADRESSE_3%TYPE;
    vv_element12               DKA_IAPBANK_ETAB_TMP.ADRESSE_4%TYPE;
    vv_element13               DKA_IAPBANK_ETAB_TMP.ADRESSE_5%TYPE;
    vv_element14               DKA_IAPBANK_ETAB_TMP.ADRESSE_6%TYPE;
    vv_element15               DKA_IAPBANK_ETAB_TMP.ARGUMENT_TRI%TYPE;
    vv_element16               DKA_IAPBANK_ETAB_TMP.CODE_ETABLISSEMENT_ABS%TYPE;
    vv_element17               DKA_IAPBANK_ETAB_TMP.OPT_ID_INVARIANT%TYPE;
    vv_element18               VARCHAR2(20);
    vv_element19               DKA_IAPBANK_ETAB_TMP.CODE_BIC%TYPE;
    vv_element20               DKA_IAPBANK_ETAB_TMP.LIBELLE_COMMERCIAL%TYPE;
    
    vv_result                  VARCHAR2(200);
    vv_file_name         VARCHAR2(256);
    vv_file_id                 VARCHAR2(256);
    vn_gfm_id                  NUMBER := NULL;
    src_lob                    BLOB;
    buffer_var1                CLOB ;

    vv_separator               VARCHAR2(1) := ';';
    vn_dest_offset             INTEGER :=1;
    vn_src_offset              INTEGER :=1;
    vn_warning                 INTEGER;
    vn_lang_context            NUMBER := DBMS_LOB.DEFAULT_LANG_CTX;

    vn_i                       NUMBER:=0;
    vv_buf                     VARCHAR2(32767);
    --vn_pos1                    NUMBER:=1; --Optimisation
    --vn_pos                     NUMBER:=1; --Optimisation
    --vn_len                     INTEGER;   --Optimisation
    
    vv_oracle_charset          fnd_lobs.oracle_charset%type;

    vn_depassement             NUMBER:= 0;

    vv_step                    VARCHAR2(200);
    vc_last_car                VARCHAR2(1);

    vn_error                   NUMBER;
    vv_ch_pb                   VARCHAR2(1000);
    vv_existing_records        NUMBER;
    vv_cmpt_commit       NUMBER;
    
    --Optimisation
    cn_lg_ligne       CONSTANT NUMBER := 500; --longueur de la ligne
    vn_ligne                   NUMBER;
    vn_position                NUMBER;
    vn_longueur                NUMBER;
  --EDB368
  vn_t1                      NUMBER :=0;
  
  
    
  BEGIN
    vv_result := 'OK';
    vn_error := 0;
      vv_cmpt_commit := 0;
    -- Historise les données des tables DKA_IAPBANK_ETAB_TMP
    -- dans les tables DKA_IAPBANK_ETAB_TMP_HIST
    historize_file_tmp_etab(vn_error, vv_ch_pb);
    
    IF vn_error = 0 THEN
      -- Purge de la table temporaire DKA_IAPBANK_ETAB_TMP. --
      EXECUTE IMMEDIATE 'TRUNCATE TABLE dka.DKA_IAPBANK_ETAB_TMP';
      
      vv_file_id := '';
      vn_gfm_id := fnd_gfm.get_file_id(access_id);

      vv_result := 'OK';

      IF vn_gfm_id IS NOT NULL THEN
        SELECT  file_name, decode(instr(file_name,'/'),0,file_name,
            substr(file_name,instr(file_name,'/')+1)), file_data,  oracle_charset
        INTO    vv_file_name, vv_file_id, src_lob,  vv_oracle_charset
        FROM    fnd_lobs
        WHERE   file_id =  vn_gfm_id;

        -- get file size
        --vn_len :=  DBMS_LOB.GETLENGTH(src_lob);-->optimisation

        -- convertit le blob en clob
        dbms_lob.createtemporary(buffer_var1, TRUE);

        dbms_lob.convertToClob( dest_lob     => buffer_var1,
                    src_blob     => src_lob,
                    amount       => DBMS_LOB.LOBMAXSIZE,
                    dest_offset  => vn_dest_offset,
                    src_offset   =>  vn_src_offset,
                    blob_csid    =>  nls_charset_id(vv_oracle_charset)     ,
                    lang_context => vn_lang_context,
                    warning      => vn_warning);

        --vn_len := DBMS_LOB.GETLENGTH(buffer_var1);-->optimisation

        vn_longueur := DBMS_LOB.GETLENGTH(buffer_var1);

        --vn_pos := dbms_lob.instr(buffer_var1,chr(10),1,1); -->optimisation

        --optimisation 
        --vn_ligne := dbms_lob.instr(buffer_var1,chr(10),1,1); --EDB368
        vn_position := 1;
    
        
        --vn_pos1 := 1;-->optimisation

        vn_i := 0;

        WHILE vn_position < vn_longueur --optimisation vn_pos  <= vn_len

        LOOP
          vn_error := 0;
          vv_ch_pb := '';
          vn_i := vn_i + 1;
          vv_cmpt_commit := vv_cmpt_commit + 1;
       
          -->optimisation vv_buf := dbms_lob.substr(buffer_var1, vn_pos - vn_pos1 -1, vn_pos1);
      
      -->EDB368
      SELECT dbms_lob.instr(to_clob(FILE_DATA), '
', 1,vn_i)
      INTO vn_t1
      FROM fnd_lobs 
      WHERE  file_id =  vn_gfm_id;
    
      SELECT utl_raw.cast_to_varchar2(dbms_lob.substr(FILE_DATA,vn_t1-vn_position,vn_position)) 
          INTO vv_buf
          FROM fnd_lobs 
          WHERE  file_id =  vn_gfm_id;
                

      IF vn_position = 1 THEN
      vn_position := vn_position + vn_t1;
      END IF;
      
          
          vn_position := vn_t1;
      --<END EDB368
          --<optimisation

          SELECT substr(vv_buf, -1) INTO vc_last_car FROM DUAL;

          IF(vc_last_car <> ';') THEN
            vv_buf := vv_buf || ';';
          END IF;

        
          vv_step   := 'ELEMENT1';
          vv_element1 := 'S';
      
          vv_step := 'ELEMENT2';
          BEGIN
            vv_element2 := replace(substr(vv_buf,1, instr(vv_buf, vv_separator, 1, 1)-1),'
','');--EDB368
          EXCEPTION WHEN OTHERS
            THEN
              vn_error  := 1;
              vv_ch_pb  := vv_ch_pb || 'ELEMENT2, ';
              vv_element2 := NULL;
          END;
      
          vv_step := 'ELEMENT3';
          BEGIN
            vv_element3 := substr(vv_buf,  instr(vv_buf, vv_separator, 1, 2-1)+1, ((instr(vv_buf, vv_separator, 1, 2))-(instr(vv_buf, vv_separator, 1, 2-1)+1)));
          EXCEPTION WHEN OTHERS
            THEN
              vn_error  := 1;
              vv_ch_pb  := vv_ch_pb || 'ELEMENT3, ';
              vv_element3 := NULL;
          END;

          vv_step := 'ELEMENT4';
          BEGIN
            vv_element4 := substr(vv_buf,  instr(vv_buf, vv_separator, 1, 3-1)+1, ((instr(vv_buf, vv_separator, 1, 3))-(instr(vv_buf, vv_separator, 1, 3-1)+1)));
          EXCEPTION WHEN OTHERS
            THEN
              vn_error  := 1;
              vv_ch_pb  := vv_ch_pb || 'ELEMENT4, ';
              vv_element4 := NULL;
          END;

          vv_step := 'ELEMENT5';
          BEGIN
            vv_element5 := substr(vv_buf,  instr(vv_buf, vv_separator, 1, 4-1)+1, ((instr(vv_buf, vv_separator, 1, 4))-(instr(vv_buf, vv_separator, 1, 4-1)+1)));
          EXCEPTION WHEN OTHERS
            THEN
              vn_error  := 1;
              vv_ch_pb  := vv_ch_pb || 'ELEMENT5, ';
              vv_element5 := NULL;
          END;

          vv_step := 'ELEMENT6';
          BEGIN
            vv_element6 := substr(vv_buf,  instr(vv_buf, vv_separator, 1, 5-1)+1, ((instr(vv_buf, vv_separator, 1, 5))-(instr(vv_buf, vv_separator, 1, 5-1)+1)));
          EXCEPTION WHEN OTHERS
            THEN
              vn_error  := 1;
              vv_ch_pb  := vv_ch_pb || 'ELEMENT6, ';
              vv_element6 := NULL;
          END;

          vv_step := 'ELEMENT7';
          BEGIN
            vv_element7 := substr(vv_buf,  instr(vv_buf, vv_separator, 1, 6-1)+1, ((instr(vv_buf, vv_separator, 1, 6))-(instr(vv_buf, vv_separator, 1, 6-1)+1)));
          EXCEPTION WHEN OTHERS
            THEN
              vn_error  := 1;
              vv_ch_pb  := vv_ch_pb || 'ELEMENT7, ';
              vv_element7 := NULL;
          END;
      
          vv_step := 'ELEMENT8';
          BEGIN
            vv_element8 := substr(vv_buf,  instr(vv_buf, vv_separator, 1, 7-1)+1, ((instr(vv_buf, vv_separator, 1, 7))-(instr(vv_buf, vv_separator, 1, 7-1)+1)));
          EXCEPTION WHEN OTHERS
            THEN
              vn_error  := 1;
              vv_ch_pb  := vv_ch_pb || 'ELEMENT8, ';
              vv_element8 := NULL;
          END;
        
          vv_step := 'ELEMENT9';
          BEGIN
            vv_element9 := substr(vv_buf,  instr(vv_buf, vv_separator, 1, 8-1)+1, ((instr(vv_buf, vv_separator, 1, 8))-(instr(vv_buf, vv_separator, 1, 8-1)+1)));
          EXCEPTION WHEN OTHERS
            THEN
              vn_error  := 1;
              vv_ch_pb  := vv_ch_pb || 'ELEMENT9, ';
              vv_element9 := NULL;
          END;
        
          vv_step := 'ELEMENT10';
          BEGIN
            vv_element10 := substr(vv_buf,  instr(vv_buf, vv_separator, 1, 9-1)+1, ((instr(vv_buf, vv_separator, 1, 9))-(instr(vv_buf, vv_separator, 1, 9-1)+1)));
          EXCEPTION WHEN OTHERS
            THEN
              vn_error  := 1;
              vv_ch_pb  := vv_ch_pb || 'ELEMENT10, ';
              vv_element10 := NULL;
          END;
        
          vv_step := 'ELEMENT11';
          BEGIN
            vv_element11 := substr(vv_buf,  instr(vv_buf, vv_separator, 1, 10-1)+1, ((instr(vv_buf, vv_separator, 1, 10))-(instr(vv_buf, vv_separator, 1, 10-1)+1)));
          EXCEPTION WHEN OTHERS
            THEN
              vn_error   := 1;
              vv_ch_pb   := vv_ch_pb || 'ELEMENT11, ';
              vv_element11 := NULL;
          END;
        
          vv_step := 'ELEMENT12';
          BEGIN
            vv_element12 := substr(vv_buf,  instr(vv_buf, vv_separator, 1, 11-1)+1, ((instr(vv_buf, vv_separator, 1, 11))-(instr(vv_buf, vv_separator, 1, 11-1)+1)));
          EXCEPTION WHEN OTHERS
            THEN
              vn_error   := 1;
              vv_ch_pb   := vv_ch_pb || 'ELEMENT12, ';
              vv_element12 := NULL;
          END;
          
          vv_step := 'ELEMENT13';
          BEGIN
            vv_element13 := substr(vv_buf,  instr(vv_buf, vv_separator, 1, 12-1)+1, ((instr(vv_buf, vv_separator, 1, 12))-(instr(vv_buf, vv_separator, 1, 12-1)+1)));
          EXCEPTION WHEN OTHERS
            THEN
              vn_error   := 1;
              vv_ch_pb   := vv_ch_pb || 'ELEMENT13, ';
              vv_element13 := NULL;
          END;
          
          vv_step := 'ELEMENT14';
          BEGIN
            vv_element14 := substr(vv_buf,  instr(vv_buf, vv_separator, 1, 13-1)+1, ((instr(vv_buf, vv_separator, 1, 13))-(instr(vv_buf, vv_separator, 1, 13-1)+1)));
          EXCEPTION WHEN OTHERS
            THEN
              vn_error   := 1;
              vv_ch_pb   := vv_ch_pb || 'ELEMENT14, ';
              vv_element14 := NULL;
          END;
          
          vv_step := 'ELEMENT15';
          BEGIN
            vv_element15 := substr(vv_buf,  instr(vv_buf, vv_separator, 1, 14-1)+1, ((instr(vv_buf, vv_separator, 1, 14))-(instr(vv_buf, vv_separator, 1, 14-1)+1)));
          EXCEPTION WHEN OTHERS
            THEN
              vn_error   := 1;
              vv_ch_pb   := vv_ch_pb || 'ELEMENT15, ';
              vv_element15 := NULL;
          END;
          
          vv_step := 'ELEMENT16';
          BEGIN
            vv_element16 := substr(vv_buf,  instr(vv_buf, vv_separator, 1, 15-1)+1, ((instr(vv_buf, vv_separator, 1, 15))-(instr(vv_buf, vv_separator, 1, 15-1)+1)));
          EXCEPTION WHEN OTHERS
            THEN
              vn_error   := 1;
              vv_ch_pb   := vv_ch_pb || 'ELEMENT16, ';
              vv_element16 := NULL;
          END;
          
          vv_step := 'ELEMENT17';
          BEGIN
            vv_element17 := substr(vv_buf,  instr(vv_buf, vv_separator, 1, 16-1)+1, ((instr(vv_buf, vv_separator, 1, 16))-(instr(vv_buf, vv_separator, 1, 16-1)+1)));
          EXCEPTION WHEN OTHERS
            THEN
              vn_error   := 1;
              vv_ch_pb   := vv_ch_pb || 'ELEMENT17, ';
              vv_element17 := NULL;
          END;
          
          vv_step := 'ELEMENT18';
          BEGIN
            vv_element18 := substr(vv_buf,  instr(vv_buf, vv_separator, 1, 17-1)+1, ((instr(vv_buf, vv_separator, 1, 17))-(instr(vv_buf, vv_separator, 1, 17-1)+1)));
          EXCEPTION WHEN OTHERS
            THEN
              vn_error   := 1;
              vv_ch_pb   := vv_ch_pb || 'ELEMENT18, ';
              vv_element18 := NULL;
          END;
          
          vv_step := 'ELEMENT19';
          BEGIN
            vv_element19 := substr(vv_buf,  instr(vv_buf, vv_separator, 1, 18-1)+1, ((instr(vv_buf, vv_separator, 1, 18))-(instr(vv_buf, vv_separator, 1, 18-1)+1)));
          EXCEPTION WHEN OTHERS
            THEN
              vn_error   := 1;
              vv_ch_pb   := vv_ch_pb || 'ELEMENT19, ';
              vv_element19 := NULL;
          END;
        
          vv_step := 'ELEMENT20';
          BEGIN
            vv_element20 := substr(vv_buf,  instr(vv_buf, vv_separator, 1, 19-1)+1, ((instr(vv_buf, vv_separator, 1, 19))-(instr(vv_buf, vv_separator, 1, 19-1)+1)));
          EXCEPTION WHEN OTHERS
            THEN
              vn_error   := 1;
              vv_ch_pb   := vv_ch_pb || 'ELEMENT20, ';
              vv_element20 := NULL;
          END;
        
          IF vn_i > 1 THEN
            -- Insertion dans la table DKA_IAPBANK_ETAB_TMP
            INSERT INTO DKA_IAPBANK_ETAB_TMP
               ( CODE_MOUVEMENT,
               CODE_ETABLISSEMENT,
               CODE_SITUATION,
               DENOMINATION1,
               DENOMINATION2,
               CODE_NAT_ACTIVITE,
               CODE_ORG_REPRES,
               DATE_AGREMENT,
               DATE_RETRAIT_AGREMENT,
               DATE_FIN_DIFFUSION,
               ADRESSE_3,
               ADRESSE_4,
               ADRESSE_5,
               ADRESSE_6,
               ARGUMENT_TRI,
               CODE_ETABLISSEMENT_ABS,
               OPT_ID_INVARIANT,
               DATE_EFFET_OPT_ID_INV,
               CODE_BIC,
               LIBELLE_COMMERCIAL,
               LAST_UPDATE_DATE,
               LAST_UPDATED_BY,
               NAME_FILE
              )
            VALUES(
               rtrim(vv_element1, ' '),
               rtrim(vv_element2, ' '),
               rtrim(vv_element3, ' '),
               rtrim(vv_element4, ' '),
               rtrim(vv_element5, ' '),
               rtrim(vv_element6, ' '),
               rtrim(vv_element7, ' '),
               rtrim(vv_element8, ' '),
               rtrim(vv_element9, ' '),
               rtrim(vv_element10, ' '),
               rtrim(vv_element11, ' '),
               rtrim(vv_element12, ' '),
               rtrim(vv_element13, ' '),
               rtrim(vv_element14, ' '),
               rtrim(vv_element15, ' '),
               rtrim(vv_element16, ' '),
               rtrim(vv_element17, ' '),
               rtrim(vv_element18, ' '),
               rtrim(vv_element19, ' '),
               rtrim(vv_element20, ' '),
               sysdate,
               cn_user_id,
               vv_file_name
               );
            /*IF vv_cmpt_commit = 500 THEN
              commit;
              vv_cmpt_commit := 0;
            END IF;*/ --EDB368
            -- Fin insertion dans la table DKA_IAPBANK_ETAB_TMP
          END IF;
          /*
          vn_pos1 := vn_pos + 1;
          IF vn_pos = vn_len THEN
            EXIT;
          END IF;
          
          vn_pos := dbms_lob.instr(buffer_var1, chr(10), 1, vn_i +1);
          */
          
        END LOOP;
        commit;
      ELSE
        vv_result := 'PB_FILE';
      END IF;

      pv_file_id := vv_file_id;
    ELSE
      vv_result := 'PB_HIST';
    END IF;
    RETURN  (vv_result);

  EXCEPTION
    WHEN OTHERS THEN
      RETURN (SQLERRM || '(ligne : ' || vn_i || ' champ : ' || vv_step ||  ')');
  END dka_chgt_file_situa_etab;
  

  -----------------------------------------------------------------
  --  NOM           : controle_nbr_enreg_file
  --  DESCRIPTION   : Procédure de contrôle du nombre d'enregistrement.
  --
  --  PARAMETRES :  p_retcode             code retour out
  --          p_errbuf              description de l'erreur out
  --
  -----------------------------------------------------------------
  PROCEDURE controle_nbr_enreg_file(p_errbuf        OUT NOCOPY VARCHAR2,
                    p_retcode       OUT NOCOPY NUMBER) IS
                        
    -- Variable compteur des enregistrements dans les différentes tables temporaires. --
    vn_cnt_etab   NUMBER;
    vn_cnt_gui    NUMBER;
    
    -- Exception sur les recherches du nombre d'enregistrement sur l'Etablissement et les Guichets.
    error_nbr_enr_gui   EXCEPTION;
    error_nbr_enr_etab    EXCEPTION;
  BEGIN
    -- Compte le nombre d'enregistrements dans la table temporaire DKA_IAPBANK_ETAB_TMP. --
    BEGIN
      SELECT  COUNT(1)
      INTO  vn_cnt_etab
      FROM  DKA_IAPBANK_ETAB_TMP;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE error_nbr_enr_etab;
    END;
    
    -- Compte le nombre d'enregistrements dans la table temporaire DKA_IAPBANK_GUI_TMP. --
    BEGIN
      SELECT  COUNT(1)
      INTO  vn_cnt_gui
      FROM  DKA_IAPBANK_GUI_TMP;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE error_nbr_enr_gui;
    END;
    
    -- Contrôle que le nombre d'enregistrement dans l'ENREGISTREMENT COMPTEURS correspond bien au nombre d'enregistrement dans chaque table temporaire. --
    IF vn_cnt_etab IS NOT NULL OR vn_cnt_gui IS NOT NULL THEN
      -- Contrôle que le nombre d'enregistrement inséré dans la table des compteurs correspond bien au nombre d'enregistrement calculé dans la table temporaire DKA_IAPBANK_ETAB_TMP. --
      dka_tools_pkg.put_outdebug_message(Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_NBR_ETAB','NBR_ENREG_ETAB',vn_cnt_etab));
      
      -- Contrôle que le nombre d'enregistrement inséré dans la table des compteurs correspond bien au nombre d'enregistrement calculé dans la table temporaire DKA_IAPBANK_GUI_TMP. --
      dka_tools_pkg.put_outdebug_message(Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_NBR_GUI','NBR_ENREG_GUI',vn_cnt_gui));
      
    ELSE
      p_retcode := 2;
      p_errbuf  := SQLERRM || 'ERREUR - Le fichier ne contient aucun enregistrement.';
    END IF;
  EXCEPTION
    WHEN error_nbr_enr_gui THEN
      p_retcode := 2;
      p_errbuf  := SQLERRM || 'Erreur lors de la recherche du nombre d''enregistrements GUICHETS dans la table temporaire DKA_IAPBANK_GUI_TMP.';
    WHEN error_nbr_enr_etab THEN
      p_retcode := 2;
      p_errbuf  := SQLERRM || 'Erreur lors de la recherche du nombre d''enregistrements ETABLISSEMENTS dans la table temporaire DKA_IAPBANK_ETAB_TMP.';
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := SQLERRM || 'Erreur lors de la recherche du nombre d''enregistrements SYSTEMES ECHANGE dans la table temporaire DKA_IAPBANK_SYS_ECH_TMP.';
  END controle_nbr_enreg_file;


  -----------------------------------------------------------------
  --  NOM           : controle_coherence_file
  --  DESCRIPTION   : Procédure de contrôle de la cohérence de certains enregistrement.
  --
  --  PARAMETRES :  p_retcode             code retour out.
  --          p_errbuf              description de l'erreur out.
  --
  -----------------------------------------------------------------
  PROCEDURE controle_coherence_file (p_errbuf         OUT NOCOPY VARCHAR2,
                     p_retcode        OUT NOCOPY NUMBER) IS
  -- Curseur parcourant l'ensemble des lignes de la table des Etablissements.
  CURSOR Cur_Etablissements IS
          SELECT  DIET.CODE_MOUVEMENT,
              DIET.CODE_ETABLISSEMENT,
              DIET.CODE_SITUATION,
              DIET.DENOMINATION1,
              DIET.DENOMINATION2,
              DIET.CODE_NAT_ACTIVITE,
              DIET.CODE_ORG_REPRES,
              DIET.DATE_AGREMENT,
              DIET.DATE_RETRAIT_AGREMENT,
              DIET.DATE_FIN_DIFFUSION,
              DIET.ADRESSE_3,
              DIET.ADRESSE_4,
              DIET.ADRESSE_5,
              DIET.ADRESSE_6,
              DIET.ARGUMENT_TRI,
              DIET.CODE_ETABLISSEMENT_ABS,
              DIET.OPT_ID_INVARIANT,
              DIET.DATE_EFFET_OPT_ID_INV,
              DIET.CODE_BIC,
              DIET.LIBELLE_COMMERCIAL,
              DIET.LAST_UPDATE_DATE,
              DIET.LAST_UPDATED_BY,
              DIET.NAME_FILE
          FROM  DKA_IAPBANK_ETAB_TMP DIET;
  Rec_Etablissements    Cur_Etablissements%ROWTYPE;
  
  -- Curseur parcourant l'ensemble des lignes de la table des Guichets.
  CURSOR Cur_Guich_Banq IS
          SELECT  DIGT.CODE_MOUVEMENT,
              DIGT.CODE_ETABLISSEMENT,
              DIGT.CODE_IMMAT_GUI,
              DIGT.CODE_SITUATION,
              DIGT.DENOMINATION_PART,
              DIGT.NOM_GUICHET,
              DIGT.CODE_ETABLISSEMENT_CBL,
              DIGT.CODE_GUI_REPRENEUR,
              DIGT.CODE_GEO_INSEE,
              DIGT.ADRESSE_3,
              DIGT.ADRESSE_4,
              DIGT.ADRESSE_5,
              DIGT.ADRESSE_6,
              DIGT.ADRESSE_SWIFT,
              DIGT.DATE_OPEN_GUICHET,
              DIGT.DATE_CLOSE_GUICHET,
              DIGT.DATE_END_GUICHET,
              DIGT.CODE_ROUT_GUICHET,
              DIGT.LIB_DOM_RIB,
              DIGT.NATURE_GUICHET,
              DIGT.LAST_UPDATE_DATE,
              DIGT.LAST_UPDATED_BY,
              DIGT.NAME_FILE
          FROM  DKA_IAPBANK_GUI_TMP DIGT;
  Rec_Guich_Banq    Cur_Guich_Banq%ROWTYPE;
  
  
  -- Curseur parcourant l'ensemble des erreurs sur les données.
  CURSOR Cur_Guich_Banq_Error (vv_type_error IN VARCHAR2) IS
          SELECT  DIE.CODE_ETABLISSEMENT,
              DIE.CODE_IMMAT_GUI,
              DIE.NOM_ETAB,
              DIE.NOM_GUI,
              DIE.ERROR_MSG
          FROM  DKA_IAPBANK_ERROR DIE
          WHERE DIE.FLAG_MSG = vv_type_error;

  Rec_Guich_Banq_Error1 Cur_Guich_Banq_Error%ROWTYPE;
  
  -- Variable permettant de vérifier que le code Etablissement et le code Guichet sont de type numérique et la date de fin de guichet de type date.
  Code_Etablis  NUMBER;
  Code_Gui    NUMBER;
  Date_End_Gui  DATE;
  
  -- Flag permettant de vérifier qu'une erreur a été trouvé sur le code Etablissement et le champ dénomination1 sur la table DKA_IAPBANK_ETAB_TMP.
  verif_etab_code_etab    BOOLEAN;
  verif_etab_denomination1  BOOLEAN;
  
  -- Flag permettant de vérifier qu'une erreur a été trouvé sur le code Etablissement, le code guichet ainsi que la date de fin que la table DKA_IAPBANK_GUI_TMP.
  verif_code_etab   BOOLEAN;
  verif_code_gui    BOOLEAN;
  verif_code_nom_gui  BOOLEAN;
  verif_date_fin    BOOLEAN;
  verif_iden_bic    BOOLEAN;
  
  vn_ctrl_error   NUMBER;
  
  vv_nom_gui      HZ_PARTIES.PARTY_NAME%TYPE;
  
  BEGIN
    -- Purge de la table temporaire DKA_IAPBANK_ERROR. --
    EXECUTE IMMEDIATE 'TRUNCATE TABLE dka.DKA_IAPBANK_ERROR';
    
    -- Vérification sur les établissements. --
    verif_etab_code_etab    := TRUE;
    verif_etab_denomination1  := TRUE;
    
    -- Vérification sur les guichets. --
    verif_code_etab := TRUE;
    verif_code_gui  := TRUE;
    verif_code_nom_gui := TRUE;
    verif_date_fin  := TRUE;
    verif_iden_bic  := TRUE;
    
    -- --------------------------------------------------------------------------------------------- --
    -- Parcours l'ensemble des établissements insérés dans la table temporaire DKA_IAPBANK_ETAB_TMP. --
    -- --------------------------------------------------------------------------------------------- --
    OPEN Cur_Etablissements;
      LOOP
      FETCH Cur_Etablissements INTO Rec_Etablissements;
      EXIT WHEN Cur_Etablissements%NOTFOUND;
        -- Contrôle de la valeur du Code Etablissement.
        BEGIN
          IF Rec_Etablissements.CODE_ETABLISSEMENT IS NULL OR Rec_Etablissements.CODE_ETABLISSEMENT = '     ' THEN
            p_retcode := 1;
            -- Erreur 1.a : La valeur du code Etablissement est null.
            INSERT INTO DKA_IAPBANK_ERROR  (CODE_ETABLISSEMENT,
                            NOM_ETAB,
                            ERROR_MSG,
                            FLAG_MSG)
                        VALUES (Rec_Etablissements.CODE_ETABLISSEMENT,
                            Rec_Etablissements.DENOMINATION1,
                            ' : La valeur du code Etablissement est null.',
                            1);
            commit;
            verif_etab_code_etab := FALSE;
          END IF;
          IF length(Rec_Etablissements.CODE_ETABLISSEMENT) != 5 THEN
            p_retcode := 1;
            -- Erreur 1.b : La valeur du code Etablissement n''est pas sur 5 caracteres.
            INSERT INTO DKA_IAPBANK_ERROR  (CODE_ETABLISSEMENT,
                            NOM_ETAB,
                            ERROR_MSG,
                            FLAG_MSG)
                        VALUES (Rec_Etablissements.CODE_ETABLISSEMENT,
                            Rec_Etablissements.DENOMINATION1,
                            ' : La valeur du code Etablissement n''est pas sur 5 caracteres.',
                            1);
            commit;
            verif_etab_code_etab := FALSE;
          END IF;
          Code_Etablis := to_number(Rec_Etablissements.CODE_ETABLISSEMENT);
        EXCEPTION
          WHEN OTHERS THEN
            p_retcode := 1;
            -- Erreur 1.b : Le format du code Etablissement n''est pas numérique.
            INSERT INTO DKA_IAPBANK_ERROR  (CODE_ETABLISSEMENT,
                            NOM_ETAB,
                            ERROR_MSG,
                            FLAG_MSG)
                        VALUES (Rec_Etablissements.CODE_ETABLISSEMENT,
                            Rec_Etablissements.DENOMINATION1,
                            ' : Le format du code Etablissement n''est pas numérique.',
                            1);
            commit;
            verif_etab_code_etab := FALSE;
        END;
        
        -- Contrôle de la valeur de la Dénomination Etablissement.
        IF Rec_Etablissements.DENOMINATION1 IS NULL OR Rec_Etablissements.DENOMINATION1 = '          ' THEN
          p_retcode := 1;
          -- Erreur 2 : La dénomination de l'établissement est NULL.
          INSERT INTO DKA_IAPBANK_ERROR  (CODE_ETABLISSEMENT,
                          ERROR_MSG,
                          FLAG_MSG)
                      VALUES (Rec_Etablissements.CODE_ETABLISSEMENT,
                          ' : La dénomination de l''établissement est NULL.',
                          2);
          commit;
          verif_etab_denomination1 := FALSE;
        END IF;
      END LOOP;
    CLOSE Cur_Etablissements;
    
    -- ------------------------------------------------------------------------------------ --
    -- Parcours l'ensemble des agence insérés dans la table temporaire DKA_IAPBANK_GUI_TMP. --
    -- ------------------------------------------------------------------------------------ --
    OPEN Cur_Guich_Banq;
      LOOP
      FETCH Cur_Guich_Banq INTO Rec_Guich_Banq;
      EXIT WHEN Cur_Guich_Banq%NOTFOUND;
        -- Variable contenant le nom de guichet.
        vv_nom_gui := nvl(Rec_Guich_Banq.NOM_GUICHET,nvl(Rec_Guich_Banq.DENOMINATION_PART,nvl(Rec_Guich_Banq.LIB_DOM_RIB,NULL)));
        -- Controle de la valeur du Code Etablissement. --
        BEGIN
          IF Rec_Guich_Banq.CODE_ETABLISSEMENT IS NULL OR Rec_Guich_Banq.CODE_ETABLISSEMENT = '     ' THEN
            p_retcode := 1;
            -- Erreur 3.a : La valeur du code Etablissement est null.
            INSERT INTO DKA_IAPBANK_ERROR  (CODE_ETABLISSEMENT,
                            CODE_IMMAT_GUI,
                            ERROR_MSG,
                            FLAG_MSG)
                        VALUES (Rec_Guich_Banq.CODE_ETABLISSEMENT,
                            Rec_Guich_Banq.CODE_IMMAT_GUI,
                            ' : La valeur du code Etablissement est null (Code situation = ' || Rec_Guich_Banq.CODE_SITUATION || ' et Date fin guichet = ' || Rec_Guich_Banq.DATE_END_GUICHET || ').',
                            3);
            commit;
            verif_code_etab := FALSE;
          END IF;
          
          IF length(Rec_Guich_Banq.CODE_ETABLISSEMENT) != 5 THEN
            p_retcode := 1;
            -- Erreur 3.b : La valeur du code Etablissement n''est pas sur 5 caracteres.
            INSERT INTO DKA_IAPBANK_ERROR  (CODE_ETABLISSEMENT,
                            CODE_IMMAT_GUI,
                            ERROR_MSG,
                            FLAG_MSG)
                        VALUES (Rec_Guich_Banq.CODE_ETABLISSEMENT,
                            Rec_Guich_Banq.CODE_IMMAT_GUI,
                            ' : La valeur du code Etablissement n''est pas sur 5 caracteres (Code situation = ' || Rec_Guich_Banq.CODE_SITUATION || ' et Date fin guichet = ' || Rec_Guich_Banq.DATE_END_GUICHET || ').',
                            3);
            commit;
            verif_code_etab := FALSE;
          END IF;
          Code_Etablis := to_number(Rec_Guich_Banq.CODE_ETABLISSEMENT);
        EXCEPTION
          WHEN OTHERS THEN
            p_retcode := 1;
            -- Erreur 3.c : Le format du code Etablissement n''est pas numérique.
            INSERT INTO DKA_IAPBANK_ERROR  (CODE_ETABLISSEMENT,
                            CODE_IMMAT_GUI,
                            ERROR_MSG,
                            FLAG_MSG)
                        VALUES (Rec_Guich_Banq.CODE_ETABLISSEMENT,
                            Rec_Guich_Banq.CODE_IMMAT_GUI,
                            ' : Le format du code Etablissement n''est pas numérique (Code situation = ' || Rec_Guich_Banq.CODE_SITUATION || ' et Date fin guichet = ' || Rec_Guich_Banq.DATE_END_GUICHET || ').',
                            3);
            commit;
            verif_code_etab := FALSE;
        END;
        
        -- Controle de la valeur du Code Guichet. --
        BEGIN
          IF Rec_Guich_Banq.CODE_IMMAT_GUI IS NULL OR Rec_Guich_Banq.CODE_IMMAT_GUI = '     ' THEN
            p_retcode := 1;
            -- Erreur 4.a : La valeur du code Guichet est null.
            INSERT INTO DKA_IAPBANK_ERROR  (CODE_ETABLISSEMENT,
                            CODE_IMMAT_GUI,
                            NOM_GUI,
                            ERROR_MSG,
                            FLAG_MSG)
                        VALUES (Rec_Guich_Banq.CODE_ETABLISSEMENT,
                            Rec_Guich_Banq.CODE_IMMAT_GUI,
                            vv_nom_gui,
                            ' : La valeur du code Guichet est null (Code situation = ' || Rec_Guich_Banq.CODE_SITUATION || ' et Date fin guichet = ' || Rec_Guich_Banq.DATE_END_GUICHET || ').',
                            4);
            commit;
            verif_code_gui := FALSE;
          END IF;
          
          IF length(Rec_Guich_Banq.CODE_IMMAT_GUI) != 5 THEN
            p_retcode := 1;
            -- Erreur 4.b : La valeur du code Guichet n''est pas sur 5 caracteres.
            INSERT INTO DKA_IAPBANK_ERROR  (CODE_ETABLISSEMENT,
                            CODE_IMMAT_GUI,
                            ERROR_MSG,
                            FLAG_MSG)
                        VALUES (Rec_Guich_Banq.CODE_ETABLISSEMENT,
                            Rec_Guich_Banq.CODE_IMMAT_GUI,
                            ' : La valeur du code Guichet n''est pas sur 5 caracteres (Code situation = ' || Rec_Guich_Banq.CODE_SITUATION || ' et Date fin guichet = ' || Rec_Guich_Banq.DATE_END_GUICHET || ').',
                            4);
            commit;
            verif_code_gui := FALSE;
          END IF;
          Code_Gui := to_number(Rec_Guich_Banq.CODE_IMMAT_GUI);
        EXCEPTION
          WHEN OTHERS THEN
            p_retcode := 1;
            -- Erreur 4.b : Le format du code Guichet n''est pas numérique.
            INSERT INTO DKA_IAPBANK_ERROR  (CODE_ETABLISSEMENT,
                            CODE_IMMAT_GUI,
                            ERROR_MSG,
                            FLAG_MSG)
                        VALUES (Rec_Guich_Banq.CODE_ETABLISSEMENT,
                            Rec_Guich_Banq.CODE_IMMAT_GUI,
                            ' : Le format du code Guichet n''est pas numérique (Code situation = ' || Rec_Guich_Banq.CODE_SITUATION || ' et Date fin guichet = ' || Rec_Guich_Banq.DATE_END_GUICHET || ').',
                            4);
            commit;
            verif_code_gui := FALSE;
        END;
        
        -- Controle de la valeur du nom de guichet. --
        IF vv_nom_gui IS NULL THEN
          p_retcode := 1;
          -- Erreur 5 : Le nom du guichet est NULL.
          INSERT INTO DKA_IAPBANK_ERROR  (CODE_ETABLISSEMENT,
                          CODE_IMMAT_GUI,
                          ERROR_MSG,
                          FLAG_MSG)
                      VALUES (Rec_Guich_Banq.CODE_ETABLISSEMENT,
                          Rec_Guich_Banq.CODE_IMMAT_GUI,
                          ' : Le nom du guichet est NULL (Code situation = ' || Rec_Guich_Banq.CODE_SITUATION || ' et Date fin guichet = ' || Rec_Guich_Banq.DATE_END_GUICHET || ').',
                          5);
          verif_code_nom_gui := FALSE;
        END IF;
        
        -- Controle la cohérence de la date de fin. --
        IF Rec_Guich_Banq.DATE_END_GUICHET IS NOT NULL THEN
          BEGIN
            IF Rec_Guich_Banq.DATE_END_GUICHET IS NOT NULL THEN
              Date_End_Gui := to_date(Rec_Guich_Banq.DATE_END_GUICHET, 'dd/mm/yyyy');
            END IF;
          EXCEPTION
            WHEN OTHERS THEN
              p_retcode := 1;
              -- Erreur 6 : La date de fin n''est pas conforme.
              INSERT INTO DKA_IAPBANK_ERROR  (CODE_ETABLISSEMENT,
                              CODE_IMMAT_GUI,
                              ERROR_MSG,
                              FLAG_MSG)
                          VALUES (Rec_Guich_Banq.CODE_ETABLISSEMENT,
                              Rec_Guich_Banq.CODE_IMMAT_GUI,
                              ' : La date de fin n''est pas conforme (Code situation = ' || Rec_Guich_Banq.CODE_SITUATION || ' et Date fin guichet = ' || Rec_Guich_Banq.DATE_END_GUICHET || ').',
                              6);
              commit;
              verif_date_fin := FALSE;
          END;
        END IF;
        
        -- Controle l'Identifiant BIC (Bank Identifier Code) associé au guichet utilisé dans les opérations transitant par le réseau SWIFT.
        IF Rec_Guich_Banq.ADRESSE_SWIFT = '           ' OR Rec_Guich_Banq.ADRESSE_SWIFT IS NULL THEN
          p_retcode := 1;
          INSERT INTO DKA_IAPBANK_ERROR  (CODE_ETABLISSEMENT,
                          CODE_IMMAT_GUI,
                          ERROR_MSG,
                          FLAG_MSG)
                      VALUES (Rec_Guich_Banq.CODE_ETABLISSEMENT,
                          Rec_Guich_Banq.CODE_IMMAT_GUI,
                          ' : L''identifiant BIC associé au guichet est vide (Code situation = ' || Rec_Guich_Banq.CODE_SITUATION || ' et Date fin guichet = ' || Rec_Guich_Banq.DATE_END_GUICHET || ').',
                          7);
          commit;
          verif_iden_bic := FALSE;
        END IF;
      END LOOP;
    CLOSE Cur_Guich_Banq;
    
    -- Affichage des erreurs pour les données Etablissements.
    dka_tools_pkg.put_outdebug_message(Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_TIT_ETAB'));
    -- Affichage pour les codes Etablissements de la table DKA_IAPBANK_ETAB_TMP
    IF verif_etab_code_etab THEN
      dka_tools_pkg.put_outdebug_message(Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_CTRL_EETAB_OK'));
    ELSE
      -- Recherche du nombre d'erreur pour le contrôle établissement sur le guichet. --
      BEGIN
        SELECT  COUNT(1)
        INTO  vn_ctrl_error
        FROM  DKA_IAPBANK_ERROR DIE
        WHERE DIE.FLAG_MSG = 1;
      END;
      dka_tools_pkg.put_outdebug_message(Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_CTRL_EETAB_KO','NBR_ERREUR',to_char(vn_ctrl_error)));
      OPEN Cur_Guich_Banq_Error(1);
        LOOP
        FETCH Cur_Guich_Banq_Error INTO Rec_Guich_Banq_Error1;
        EXIT WHEN Cur_Guich_Banq_Error%NOTFOUND;
          dka_tools_pkg.put_outdebug_message('Etablissement ' || nvl(Rec_Guich_Banq_Error1.CODE_ETABLISSEMENT,Rec_Guich_Banq_Error1.NOM_ETAB) || Rec_Guich_Banq_Error1.ERROR_MSG);
        END LOOP;
      CLOSE Cur_Guich_Banq_Error;
    END IF;
    
    --Affichage pour les Dénominations Etablissement de la table DKA_IAPBANK_ETAB_TMP
    IF verif_etab_denomination1 THEN
      dka_tools_pkg.put_outdebug_message(Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_CTRL_DENO_OK'));
    ELSE
      -- Recherche du nombre d'erreur pour le contrôle établissement sur le guichet. --
      BEGIN
        SELECT  COUNT(1)
        INTO  vn_ctrl_error
        FROM  DKA_IAPBANK_ERROR DIE
        WHERE DIE.FLAG_MSG = 2;
      END;
      dka_tools_pkg.put_outdebug_message(Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_CTRL_DENO_KO','NBR_ERREUR',to_char(vn_ctrl_error)));
      OPEN Cur_Guich_Banq_Error(2);
        LOOP
        FETCH Cur_Guich_Banq_Error INTO Rec_Guich_Banq_Error1;
        EXIT WHEN Cur_Guich_Banq_Error%NOTFOUND;
          dka_tools_pkg.put_outdebug_message('Etablissement ' || Rec_Guich_Banq_Error1.CODE_ETABLISSEMENT || Rec_Guich_Banq_Error1.ERROR_MSG);
        END LOOP;
      CLOSE Cur_Guich_Banq_Error;
    END IF;
    dka_tools_pkg.put_outdebug_message('');
    
    -- Affichage des erreurs pour les données Guichets.
    dka_tools_pkg.put_outdebug_message(Dka_Tools_Pkg.get_message ('DKA','DKA_IAPBANK_TIT_GUI'));
    -- Affichage pour les codes Etablissements de la table DKA_IAPBANK_GUI_TMP
    IF verif_code_etab THEN
      dka_tools_pkg.put_outdebug_message(Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_CTRL_ETAB_OK'));
    ELSE
      -- Recherche du nombre d'erreur pour le contrôle établissement sur le guichet. --
      BEGIN
        SELECT  COUNT(1)
        INTO  vn_ctrl_error
        FROM  DKA_IAPBANK_ERROR DIE
        WHERE DIE.FLAG_MSG = 3;
      END;
      dka_tools_pkg.put_outdebug_message(Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_CTRL_ETAB_KO','NBR_ERREUR',to_char(vn_ctrl_error)));
      OPEN Cur_Guich_Banq_Error(3);
        LOOP
        FETCH Cur_Guich_Banq_Error INTO Rec_Guich_Banq_Error1;
        EXIT WHEN Cur_Guich_Banq_Error%NOTFOUND;
          dka_tools_pkg.put_outdebug_message('Etablissement ' || Rec_Guich_Banq_Error1.CODE_ETABLISSEMENT || ' / ' || 'Guichet ' || Rec_Guich_Banq_Error1.CODE_IMMAT_GUI || Rec_Guich_Banq_Error1.ERROR_MSG);
        END LOOP;
      CLOSE Cur_Guich_Banq_Error;
    END IF;
    -- Affichage pour les codes Guichets de la table DKA_IAPBANK_GUI_TMP
    IF verif_code_gui THEN
      dka_tools_pkg.put_outdebug_message(Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_CTRL_GUI_OK'));
    ELSE
      -- Recherche du nombre d'erreur pour le contrôle établissement sur le guichet. --
      BEGIN
        SELECT  COUNT(1)
        INTO  vn_ctrl_error
        FROM  DKA_IAPBANK_ERROR DIE
        WHERE DIE.FLAG_MSG = 4;
      END;
      dka_tools_pkg.put_outdebug_message(Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_CTRL_GUI_KO','NBR_ERREUR',to_char(vn_ctrl_error)));
      OPEN Cur_Guich_Banq_Error(4);
        LOOP
        FETCH Cur_Guich_Banq_Error INTO Rec_Guich_Banq_Error1;
        EXIT WHEN Cur_Guich_Banq_Error%NOTFOUND;
          dka_tools_pkg.put_outdebug_message('Etablissement ' || Rec_Guich_Banq_Error1.CODE_ETABLISSEMENT || ' / Guichet ' || nvl(Rec_Guich_Banq_Error1.CODE_IMMAT_GUI, Rec_Guich_Banq_Error1.NOM_GUI) || Rec_Guich_Banq_Error1.ERROR_MSG);
        END LOOP;
      CLOSE Cur_Guich_Banq_Error;
    END IF;
    -- Affichage pour les noms de guichet de la table DKA_IAPBANK_GUI_TMP
    IF verif_code_nom_gui THEN
      dka_tools_pkg.put_outdebug_message(Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_CTRL_NGUI_OK'));
    ELSE
      -- Recherche du nombre d'erreur pour le contrôle établissement sur le guichet. --
      BEGIN
        SELECT  COUNT(1)
        INTO  vn_ctrl_error
        FROM  DKA_IAPBANK_ERROR DIE
        WHERE DIE.FLAG_MSG = 5;
      END;
      dka_tools_pkg.put_outdebug_message(Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_CTRL_NGUI_KO','NBR_ERREUR',to_char(vn_ctrl_error)));
      OPEN Cur_Guich_Banq_Error(5);
        LOOP
        FETCH Cur_Guich_Banq_Error INTO Rec_Guich_Banq_Error1;
        EXIT WHEN Cur_Guich_Banq_Error%NOTFOUND;
          dka_tools_pkg.put_outdebug_message('Etablissement ' || Rec_Guich_Banq_Error1.CODE_ETABLISSEMENT || ' / Guichet ' || Rec_Guich_Banq_Error1.CODE_IMMAT_GUI || Rec_Guich_Banq_Error1.ERROR_MSG);
        END LOOP;
      CLOSE Cur_Guich_Banq_Error;
    END IF;
    -- Affichage pour les date de fin de guichet de la table DKA_IAPBANK_GUI_TMP
    IF verif_date_fin THEN
      dka_tools_pkg.put_outdebug_message(Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_CTRL_DTF_OK'));
    ELSE
      -- Recherche du nombre d'erreur pour le contrôle établissement sur le guichet. --
      BEGIN
        SELECT  COUNT(1)
        INTO  vn_ctrl_error
        FROM  DKA_IAPBANK_ERROR DIE
        WHERE DIE.FLAG_MSG = 6;
      END;
      dka_tools_pkg.put_outdebug_message(Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_CTRL_DTF_KO','NBR_ERREUR',to_char(vn_ctrl_error)));
      OPEN Cur_Guich_Banq_Error(6);
        LOOP
        FETCH Cur_Guich_Banq_Error INTO Rec_Guich_Banq_Error1;
        EXIT WHEN Cur_Guich_Banq_Error%NOTFOUND;
          dka_tools_pkg.put_outdebug_message('Etablissement ' || Rec_Guich_Banq_Error1.CODE_ETABLISSEMENT || ' / Guichet ' || Rec_Guich_Banq_Error1.CODE_IMMAT_GUI || Rec_Guich_Banq_Error1.ERROR_MSG);
        END LOOP;
      CLOSE Cur_Guich_Banq_Error;
    END IF;
    -- Affichage pour les codes BIC de la table DKA_IAPBANK_GUI_TMP
    IF verif_iden_bic THEN
      dka_tools_pkg.put_outdebug_message(Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_CTRL_BIC_OK'));
    ELSE
      -- Recherche du nombre d'erreur pour le contrôle établissement sur le guichet. --
      BEGIN
        SELECT  COUNT(1)
        INTO  vn_ctrl_error
        FROM  DKA_IAPBANK_ERROR DIE
        WHERE DIE.FLAG_MSG = 7;
      END;
      dka_tools_pkg.put_outdebug_message(Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_CTRL_BIC_KO','NBR_ERREUR',to_char(vn_ctrl_error)));
      OPEN Cur_Guich_Banq_Error(7);
        LOOP
        FETCH Cur_Guich_Banq_Error INTO Rec_Guich_Banq_Error1;
        EXIT WHEN Cur_Guich_Banq_Error%NOTFOUND;
          dka_tools_pkg.put_outdebug_message('Etablissement ' || Rec_Guich_Banq_Error1.CODE_ETABLISSEMENT || ' / Guichet ' || Rec_Guich_Banq_Error1.CODE_IMMAT_GUI || Rec_Guich_Banq_Error1.ERROR_MSG);
        END LOOP;
      CLOSE Cur_Guich_Banq_Error;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := SQLERRM || ' Erreur : Procédure controle_coherence_file.';
  END controle_coherence_file;
  
  
  -----------------------------------------------------------------
  --  NOM           : verif_end_guichet.
  --  DESCRIPTION   : Procédure de vérification de l'existence d'une
  --                  date de fin dans Oracle Application.
  --
  --  PARAMETRES :  p_retcode             code retour out.
  --          p_errbuf              description de l'erreur out.
  --          p_maj         flag de mise a jour des données.
  --
  -----------------------------------------------------------------
  PROCEDURE verif_end_guichet (p_errbuf         OUT NOCOPY VARCHAR2,
                 p_retcode        OUT NOCOPY NUMBER,
                 p_maj        IN  VARCHAR2) IS
                 
    n_api_version          NUMBER := 1.0;
    v_response_rec         IBY_FNDCPT_COMMON_PUB.RESULT_REC_TYPE;
    v_return_status        VARCHAR2 (2000);
    v_msg_data             VARCHAR2 (2000);
    n_msg_count            NUMBER;
  
    CURSOR cur_end_guichet IS
       SELECT branch_party_id , cbb.branch_number, cbb.bank_branch_name, cbb.bank_number, cbb.bank_name, cbb.end_date
       FROM 
        CE_BANK_BRANCHES_V cbb,
        hz_parties hp
       WHERE 
         SYSDATE <= NVL(end_date,SYSDATE) 
         AND hp.party_id = cbb.branch_party_id
         AND hp.attribute10 IS NOT NULL 
         AND NOT EXISTS
         (SELECT 'X'
            FROM DKA_IAPBANK_GUI_TMP DIGT
           WHERE DIGT.CODE_ETABLISSEMENT = cbb.bank_number
             AND DIGT.CODE_IMMAT_GUI     = cbb.branch_number);
                   
    rec_end_guichet   cur_end_guichet%ROWTYPE;
    
  BEGIN
    -- Parcours l'ensemble des banques qui n'existe pas dans le fichier FGB et dont une date de fin est absente. --
    OPEN cur_end_guichet;
      LOOP
        FETCH cur_end_guichet INTO rec_end_guichet;
        EXIT WHEN cur_end_guichet%NOTFOUND;
          IF p_maj = 'OUI' THEN
            -- MAJ de la date de fin a la date de lancement du traitement. --
            iby_ext_bankacct_pub.set_ext_bank_branch_end_date(  p_api_version   => n_api_version,
                                      p_init_msg_list => fnd_api.g_true,
                                      p_branch_id     => rec_end_guichet.branch_party_id,
                                      p_end_date      => sysdate,
                                      x_return_status => v_return_status,
                                      x_msg_count     => n_msg_count,
                                      x_msg_data      => v_msg_data,
                                      x_response      => v_response_rec                                             
                                      );
            IF v_return_status = 'S' then
              dka_tools_pkg.put_outdebug_message(Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_CTRL_NDF_OK', 'CODE_ETABLISSEMENT', rec_end_guichet.bank_number, 'CODE_IMMAT_GUI', rec_end_guichet.branch_number, 'DATE_CLOSE_GUICHET', SYSDATE));
            ELSE
              dka_tools_pkg.put_outdebug_message(Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_CTRL_NDF_KO', 'CODE_ETABLISSEMENT', rec_end_guichet.bank_number, 'CODE_IMMAT_GUI', rec_end_guichet.branch_number) || ' ' || SQLERRM);
              p_retcode := 1;
              p_errbuf  := SQLERRM || ' ERREUR : - ' || Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_CTRL_NDF_KO', 'CODE_ETABLISSEMENT', rec_end_guichet.bank_number, 'CODE_IMMAT_GUI', rec_end_guichet.branch_number);
            END IF; 
            
          ELSE
            --MODE SIMU
            dka_tools_pkg.put_outdebug_message(Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_CTRL_NDF_OK', 'CODE_ETABLISSEMENT', rec_end_guichet.bank_number, 'CODE_IMMAT_GUI', rec_end_guichet.branch_number, 'DATE_CLOSE_GUICHET', SYSDATE));
          
          END IF;
      END LOOP;
    CLOSE cur_end_guichet;
    -- Mise a jour en fin de contrôle. --
    commit;
  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := SQLERRM || ' Erreur : Procédure vérif_end_guichet.';
      ROLLBACK;
  END verif_end_guichet;
  
  
  ------------------------------------------------------------------------------------
  --  Nom           : dka_date_fin_guichet
  --  Description   : Procédure vérifiant qu'il existe une date de fin sur le guichet
  --
  --  PARAMETRES    :
  --      code_enregistrement  : code banque
  --      code_guichet : code agence bancaire
  --  VALEUR RETOURNEE :
  --    return s'il existe une date de fin sur le guichet dans le fichier FGD.
  ------------------------------------------------------------------------------------
  FUNCTION dka_date_fin_guichet(pv_code_etablis   IN     VARCHAR2,
                 pv_code_guichet    IN     VARCHAR2,
                 pn_errbuf      OUT    NOCOPY VARCHAR2,
                 pn_retcode     OUT    NOCOPY NUMBER) RETURN BOOLEAN
  IS
  -- Code guichet / Date de fin sur le guichet.
  vn_date_fin         NUMBER;
  
  -- Exception concernant l'inexistence d'un code situation.
  error_code_situation    EXCEPTION;
  BEGIN
    -- Recherche du code situation pour déterminer qu'une date de fin existe.
    BEGIN
      SELECT  count(1)
      INTO  vn_date_fin
      FROM  DKA_IAPBANK_GUI_TMP DIGT
      WHERE DIGT.CODE_ETABLISSEMENT = pv_code_etablis
      AND   DIGT.CODE_IMMAT_GUI   = pv_code_guichet
      AND   DIGT.DATE_END_GUICHET IS NOT NULL;
    EXCEPTION
      WHEN OTHERS THEN
        Raise error_code_situation;
    END;
    
    return (vn_date_fin <> 0);
    
  EXCEPTION
    WHEN error_code_situation THEN
      pn_retcode := 2;
      pn_errbuf  := 'Etablissement ' || pv_code_etablis || ' / Guichet ' || pv_code_guichet || ' : Erreur lors de la vérification de l''existence d''une date de fin sur le guichet dans le fichier FGD';
    WHEN OTHERS THEN
      pn_retcode := 2;
      pn_errbuf  := SQLERRM || ' Erreur : Procédure dka_date_fin_guichet.';
  END dka_date_fin_guichet;


  
  -----------------------------------------------------------------
  --  NOM           : simulation_insert_file
  --  DESCRIPTION   : Procédure de contrôle des regles de gestion.
  --
  --  PARAMETRES :  p_retcode             code retour out.
  --          p_errbuf              description de l'erreur out.
  --          p_maj         flag de mise a jour des données.
  --
  -----------------------------------------------------------------
  PROCEDURE simulation_insert_file (p_errbuf          OUT NOCOPY VARCHAR2,
                     p_retcode        OUT NOCOPY NUMBER,
                     p_maj      IN  VARCHAR2) IS
  CURSOR Cur_Guich_Banq IS
          SELECT  DIGT.CODE_MOUVEMENT,
              DIGT.CODE_ETABLISSEMENT,
              DIGT.CODE_IMMAT_GUI,
              DIGT.CODE_SITUATION,
              DIGT.DENOMINATION_PART,
              DIGT.NOM_GUICHET,
              DIGT.CODE_ETABLISSEMENT_CBL,
              DIGT.CODE_GUI_REPRENEUR,
              DIGT.CODE_GEO_INSEE,
              DIGT.ADRESSE_3,
              DIGT.ADRESSE_4,
              DIGT.ADRESSE_5,
              DIGT.ADRESSE_6,
              DIGT.ADRESSE_SWIFT,
              DIGT.DATE_OPEN_GUICHET,
              DIGT.DATE_CLOSE_GUICHET,
              DIGT.DATE_END_GUICHET,
              DIGT.CODE_ROUT_GUICHET,
              DIGT.LIB_DOM_RIB,
              DIGT.NATURE_GUICHET,
              DIGT.LAST_UPDATE_DATE,
              DIGT.LAST_UPDATED_BY,
              DIGT.NAME_FILE,
              DIET.CODE_BIC,
              DIET.DENOMINATION1,
              DIET.DENOMINATION2,
-- 2019/01/29 NBO Optimisation du processus
              /*(SELECT COUNT(1)
              FROM CE_BANK_BRANCHES_V
              WHERE BRANCH_NUMBER = DIGT.CODE_IMMAT_GUI
              and BANK_NUMBER = DIGT.CODE_ETABLISSEMENT
              AND CE_BANK_BRANCHES_V.country = 'FR') NBR_CPL_BANK_GUI,*/
              decode(DIGT.DATE_END_GUICHET,NULL,0,1) N_VERIF_DATE_FIN_GUICHET
          FROM  DKA_IAPBANK_GUI_TMP  DIGT,
              DKA_IAPBANK_ETAB_TMP DIET
          WHERE DIGT.CODE_ETABLISSEMENT = DIET.CODE_ETABLISSEMENT;
          
  Rec_Guich_Banq  Cur_Guich_Banq%ROWTYPE;
  Code_Etablis  NUMBER;
  Code_Gui    NUMBER;
  Date_End_Gui  DATE;
  
  nbr_date_active  NUMBER;
  nbr_date_account NUMBER;
  b_guichet_actif       BOOLEAN := false;
    
  -- Variables de vérification du nom de guichet.
  vv_nom_gui    HZ_PARTIES.PARTY_NAME%TYPE;
  -- 26/07 JPE artf1978351                  
  --vn_nom_gui_file HZ_PARTIES.PARTY_NAME%TYPE;
  vn_nom_gui_abb  HZ_PARTIES.PARTY_NAME%TYPE;
  
  -- Variables utlisées pour le lancement des traitements standards
  n_api_version          NUMBER := 1.0;
  v_response_rec         IBY_FNDCPT_COMMON_PUB.RESULT_REC_TYPE;
    n_bank_id              NUMBER;
  v_return_status        VARCHAR2 (2000);
  v_msg_data             VARCHAR2 (2000);
  n_msg_count            NUMBER;
  
  v_msg_index_out        NUMBER;  
  n_branch_id            NUMBER;
  n_location_id      NUMBER;
  n_acct_id              NUMBER;
  n_obj_vers_num       NUMBER;
    v_ext_bank_rec         IBY_EXT_BANKACCT_PUB.EXTBANK_REC_TYPE;
  v_ext_branch_rec       IBY_EXT_BANKACCT_PUB.EXTBANKBRANCH_REC_TYPE;
  v_location_rec       HZ_LOCATION_V2PUB.LOCATION_REC_TYPE;
  v_party_site_rec     HZ_PARTY_SITE_V2PUB.PARTY_SITE_REC_TYPE;
  v_eft_swift_code     HZ_CONTACT_POINTS.EFT_SWIFT_CODE%TYPE;
    d_start_date           DATE;
  d_end_date             DATE;
    d_new_date_end       DATE;
    v_supplier_site_id     NUMBER;
  n_party_site_id        NUMBER;
  n_party_site_number    NUMBER;
  l_NBR_CPL_BANK_GUI     NUMBER;
      
  v_warining_interface   BOOLEAN := false;
  v_warining_bank        BOOLEAN := false;
  v_operating_unit_exist BOOLEAN;
  v_exist_bank           BOOLEAN;
  
  vv_date_heure      VARCHAR2(25);
  
  -------------------------------------------------------
  -- Procédure de suppression des tables de sauvegarde --
  -------------------------------------------------------
  PROCEDURE delete_save_tables ( pv_table_name VARCHAR2 ) IS

    CURSOR cur_tables(pv_table_name VARCHAR2) IS
      SELECT  owner,
          table_name
      FROM    all_tables
      WHERE   table_name LIKE pv_table_name || '%';

    rec_tables                     cur_tables%ROWTYPE;
    vn_longueur_prefixe            NUMBER;
    vn_longueur_table              NUMBER;
    vv_date_table                  VARCHAR2(30);
    vd_date_table                  DATE;
    vv_sqlstmt                     VARCHAR2(250);

    --------------------------------------------------------------
    -- Fonction qui vérifie qu'une chaine de caractere est bien --
    -- une date au format YYYYMMDDHHMISS                        --
    --------------------------------------------------------------
    FUNCTION is_date ( pv_date VARCHAR2 ) RETURN BOOLEAN IS
      vd_date                      DATE;
      vb_is_date                   BOOLEAN;
    BEGIN
      BEGIN
        vb_is_date := TRUE;
        SELECT TO_DATE(pv_date, 'YYYYMMDDHH24MISS')
        INTO   vd_date
        FROM   dual;
      EXCEPTION
        WHEN OTHERS THEN
          vb_is_date := FALSE;
      END;
      RETURN vb_is_date;
    END is_date;
  BEGIN

    OPEN cur_tables (pv_table_name);
    LOOP
      FETCH cur_tables INTO rec_tables;
      EXIT WHEN cur_tables%NOTFOUND;

      vn_longueur_prefixe := LENGTH(pv_table_name);
      vn_longueur_table   := LENGTH(rec_tables.table_name);

      -------------------------------------------------------------------------------
      -- Le nom de la table doit respester le format 'pv_table_nameYYYYMMDDHHMISS' --
      -- La longueur du nom de la table doit donc etre égale a la longueur du      --
      -- préfixe + 14                                                              --
      -------------------------------------------------------------------------------
      IF vn_longueur_table = vn_longueur_prefixe + 14 THEN
        vv_date_table := SUBSTR(rec_tables.table_name, vn_longueur_prefixe + 1, 14);
        -------------------------------------------------------------
        -- On vérifie que les 14 derniers caracteres sont une date --
        -------------------------------------------------------------
        IF is_date(vv_date_table) THEN
          vd_date_table := TO_DATE(vv_date_table, 'YYYYMMDDHH24MISS');
          -----------------------------------------------
          -- On supprime les table de plus de 30 jours --
          -----------------------------------------------
          IF TRUNC(SYSDATE) - TRUNC(vd_date_table) > 30 THEN
            vv_sqlstmt := 'DROP TABLE ' || rec_tables.owner || '.' || rec_tables.table_name;
            EXECUTE IMMEDIATE vv_sqlstmt;
            Dka_Tools_Pkg.put_log_message('table ' || rec_tables.owner || '.' || rec_tables.table_name || ' supprimée');
          END IF;
        END IF;
      END IF;
    END LOOP;
    CLOSE cur_tables;
  END delete_save_tables;
  
  BEGIN
    IF p_maj = 'OUI' THEN
      ----------------------------------------------------------------------
      -- Suppression des tables de sauvegarde de la table HZ_PARTIES --
      ----------------------------------------------------------------------
      Dka_Tools_Pkg.put_log_message('Suppression des tables de sauvegarde de la table DKA_BK_BRANCHES');
      delete_save_tables ('DKA_BK_BRANCHES_');
      
      -------------------------------------------------
      -- Sauvegarde du contenu des tables de travail --
      -------------------------------------------------
      vv_date_heure := TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS');
      
      ------------------------------------------------------
      -- Sauvegarde de la table HZ_PARTIES               --
      ------------------------------------------------------
      Dka_Tools_Pkg.put_log_message('Création de la table DKA.DKA_BK_BRANCHES_' || vv_date_heure);
      EXECUTE IMMEDIATE 'CREATE TABLE DKA.DKA_BK_BRANCHES_' || vv_date_heure || ' AS SELECT * FROM HZ_PARTIES';
  
    END IF;
    
    -- Parcours l'ensemble des banques insérés dans le table temporaire DKA_IAPBANK_ETAB_TMP. --
    OPEN Cur_Guich_Banq;
      LOOP
      FETCH Cur_Guich_Banq INTO Rec_Guich_Banq;
      EXIT WHEN Cur_Guich_Banq%NOTFOUND;
      
         -- 2019/01/29 NBO Optimisation du processus
         SELECT COUNT(1) INTO l_NBR_CPL_BANK_GUI
              FROM CE_BANK_BRANCHES_V
              WHERE BRANCH_NUMBER = Rec_Guich_Banq.CODE_IMMAT_GUI
              and BANK_NUMBER = Rec_Guich_Banq.CODE_ETABLISSEMENT
              AND CE_BANK_BRANCHES_V.country = 'FR';
      
        -- RG 03 le couple existe-t-il dans OA? --
        
        -- vérification de l''existence de la banque
        iby_ext_bankacct_pub.check_bank_exist(  p_api_version   => n_api_version,
                                                        p_init_msg_list => fnd_api.g_true,
                                                        p_country_code  => cv_countrycode,
                                                        p_bank_name     => NULL,--Rec_Guich_Banq.DENOMINATION1,
                                                        p_bank_number   => Rec_Guich_Banq.CODE_ETABLISSEMENT,
                                                        x_response      => v_response_rec,
                                                        x_bank_id       => n_bank_id,
                                                        x_end_date      => d_end_date,
                                                        x_return_status => v_return_status,
                                                        x_msg_count     => n_msg_count,
                                                        x_msg_data      => v_msg_data
                                                        );
        -- si la banque existe
        IF (n_bank_id IS NOT NULL) and (v_return_status ='S') THEN
                    -- 2019/01/29 NBO Optimisation du processus
          --dka_tools_pkg.put_log_message('CAS BANQUE EXISTANTE : ID DE LA BANQUE ' || Rec_Guich_Banq.DENOMINATION1 || ' : ' || n_bank_id);
          dka_tools_pkg.put_debug_message('CAS BANQUE EXISTANTE : ID DE LA BANQUE ' || Rec_Guich_Banq.DENOMINATION1 || ' : ' || n_bank_id);
          
            -- vérification de l''existence de l''agence
          iby_ext_bankacct_pub.check_ext_bank_branch_exist(   p_api_version   => n_api_version,
                                    p_init_msg_list => fnd_api.g_true,
                                    p_bank_id       => n_bank_id,
                                    p_branch_name   => NULL,--Rec_Guich_Banq.NOM_GUICHET,
                                    p_branch_number => Rec_Guich_Banq.CODE_IMMAT_GUI,
                                    x_response      => v_response_rec,
                                    x_branch_id     => n_branch_id,
                                    x_end_date      => d_end_date,
                                    x_return_status => v_return_status,
                                    x_msg_count     => n_msg_count,
                                    x_msg_data      => v_msg_data
                                                                    );
          -- RG 03 si le couple etablissement / guichet / pays existe dans oracle application. --
          IF  (n_branch_id IS NOT NULL) and (v_return_status ='S') THEN
            
                    -- 2019/01/29 NBO Optimisation du processus
            --IF Rec_Guich_Banq.nbr_cpl_bank_gui = 1 THEN
            IF l_NBR_CPL_BANK_GUI = 1 THEN
            
              -- RG 09 Le code Guichet est- il désactivé dans OA ?          
              b_guichet_actif := (NVL(d_end_date,SYSDATE) >= SYSDATE);
              -- Si Le code Guichet n'est pas desactive dans oracle application.
              IF  b_guichet_actif THEN
                IF  Rec_Guich_Banq.N_VERIF_DATE_FIN_GUICHET != 0 THEN -- RG 04 Existe-t-il une date de fin sur le guichet dans le fichier FGD? --
                  -- RG 11 Existent-ils des comptes bancaires actifs sur ce Guichet.
                  SELECT  COUNT(1)
                  INTO  nbr_date_account
                  FROM  IBY_EXT_BANK_ACCOUNTS
                  WHERE   BRANCH_ID = n_branch_id
                  AND   BANK_ID   = n_bank_id
                  AND   NVL(END_DATE,SYSDATE) >= SYSDATE;
                  
                  -- si des comptes bancaires actifs existent               
                  IF nbr_date_account > 0 THEN
                    dka_tools_pkg.put_outdebug_message(Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_RG12A', 'CODE_ETABLISSEMENT', Rec_Guich_Banq.CODE_ETABLISSEMENT, 'CODE_IMMAT_GUI', Rec_Guich_Banq.CODE_IMMAT_GUI));
                  ELSE
                    dka_tools_pkg.put_outdebug_message(Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_RG12B', 'CODE_ETABLISSEMENT', Rec_Guich_Banq.CODE_ETABLISSEMENT, 'CODE_IMMAT_GUI', Rec_Guich_Banq.CODE_IMMAT_GUI));               
                  END IF;
                  
                  -- RG 12a maj sur les champs + indication dans fichier de sortie de l'existence des comptes bancaires associes a ce guichet que l'on desactive.
                  IF p_maj = 'OUI' THEN
                    -- Recherche du nom du guichet.
                    -- 26/07 JPE artf1978351                  
                    --vn_nom_gui_file := '';
                    
                    -- Initialisation du nom du guichet.
                    BEGIN
                      
                      vv_nom_gui := nvl(Rec_Guich_Banq.NOM_GUICHET,nvl(Rec_Guich_Banq.DENOMINATION_PART,nvl(Rec_Guich_Banq.LIB_DOM_RIB,NULL)));
                      
                    EXCEPTION
                      WHEN OTHERS THEN
                        dka_tools_pkg.put_outdebug_message('ERREUR : RG12A - Etablissement ' || Rec_Guich_Banq.CODE_ETABLISSEMENT || ' / Agence ' || Rec_Guich_Banq.CODE_IMMAT_GUI || ' : Impossible de vérifier l''existence du guichet dans Oracle Application. ' || SQLERRM);
                        p_retcode := 2;
                        p_errbuf  := SQLERRM || 'ERREUR : RG12A - Etablissement ' || Rec_Guich_Banq.CODE_ETABLISSEMENT || ' / Agence ' || Rec_Guich_Banq.CODE_IMMAT_GUI || ' : Impossible de vérifier l''existence du guichet dans Oracle Application.';
                    END;
                    
                    -- api qui applique la date de fin d'activation du guichet ( ce qui consite a le désactiver si la date est inférieure ou égale a la date du jour)
                    iby_ext_bankacct_pub.set_ext_bank_branch_end_date(  p_api_version   => n_api_version,
                                              p_init_msg_list => fnd_api.g_true,
                                              p_branch_id     => n_branch_id,
                                              p_end_date      => to_date(Rec_Guich_Banq.DATE_END_GUICHET,'dd/mm/yyyy'),
                                              x_return_status => v_return_status,
                                              x_msg_count     => n_msg_count,
                                              x_msg_data      => v_msg_data,
                                              x_response      => v_response_rec                                             
                                            );
                    IF v_return_status != 'S' THEN
                      dka_tools_pkg.put_outdebug_message(Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_RG12A_ERR', 'CODE_ETABLISSEMENT', Rec_Guich_Banq.CODE_ETABLISSEMENT, 'CODE_IMMAT_GUI', Rec_Guich_Banq.CODE_IMMAT_GUI) || ' ' || SQLERRM);
                      p_retcode := 2;
                      p_errbuf := SQLERRM || ' ERREUR : RG12A - ' || Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_RG12A_ERR', 'CODE_ETABLISSEMENT', Rec_Guich_Banq.CODE_ETABLISSEMENT, 'CODE_IMMAT_GUI', Rec_Guich_Banq.CODE_IMMAT_GUI);
                    END IF;                       
                  END IF;               
                END IF;
              ELSE
                IF  Rec_Guich_Banq.n_verif_date_fin_guichet != 0 THEN
                  -- RG10b ON GARDE LA DATE DE FIN DE ORACLE APPLICATION. --                      
                  dka_tools_pkg.put_outdebug_message(Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_RG10B', 'CODE_ETABLISSEMENT', Rec_Guich_Banq.CODE_ETABLISSEMENT, 'CODE_IMMAT_GUI', Rec_Guich_Banq.CODE_IMMAT_GUI, 'DATE_CLOSE_GUICHET', Rec_Guich_Banq.DATE_END_GUICHET));
                ELSE
                  -- RG10a Guichet ouvert dans FGD et fermé dans OA. Le guichet est maintenant actif dans OA. --                      
                  dka_tools_pkg.put_outdebug_message(Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_RG10A', 'CODE_ETABLISSEMENT', Rec_Guich_Banq.CODE_ETABLISSEMENT, 'CODE_IMMAT_GUI', Rec_Guich_Banq.CODE_IMMAT_GUI, 'DATE_CLOSE_GUICHET', Rec_Guich_Banq.DATE_END_GUICHET));
                  -- On force la date de fin a la date du jour + 100 ans car l'api ne permet pas de vider le champ date
                  SELECT SYSDATE  + NUMTOYMINTERVAL(100,'YEAR') AS DATE_FUTURE INTO d_new_date_end FROM dual;                             
                  
                  iby_ext_bankacct_pub.set_ext_bank_branch_end_date(  p_api_version   => n_api_version,
                                            p_init_msg_list => fnd_api.g_true,
                                            p_branch_id     => n_branch_id,
                                            p_end_date      => d_new_date_end,
                                            x_return_status => v_return_status,
                                            x_msg_count     => n_msg_count,
                                            x_msg_data      => v_msg_data,
                                            x_response      => v_response_rec);
                  IF v_return_status != 'S' THEN
                    dka_tools_pkg.put_outdebug_message(Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_RG10A_ERR', 'CODE_ETABLISSEMENT', Rec_Guich_Banq.CODE_ETABLISSEMENT, 'CODE_IMMAT_GUI', Rec_Guich_Banq.CODE_IMMAT_GUI) || ' ' || SQLERRM);
                    p_retcode := 2;
                    p_errbuf := SQLERRM || ' ERREUR : RG10a - ' || Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_RG10A_ERR', 'CODE_ETABLISSEMENT', Rec_Guich_Banq.CODE_ETABLISSEMENT, 'CODE_IMMAT_GUI', Rec_Guich_Banq.CODE_IMMAT_GUI);
                  END IF;
                END IF;
              END IF;
              -- RG13 : Mise a jour du référentiel bancaire
              IF p_maj = 'OUI' THEN 
                v_ext_bank_rec.bank_id     := n_bank_id;              
                v_ext_bank_rec.bank_number := Rec_Guich_Banq.CODE_ETABLISSEMENT;  
                
                BEGIN
                  SELECT object_version_number,
                  nvl(Rec_Guich_Banq.DENOMINATION1, hz_parties.party_name)
                  INTO v_ext_bank_rec.object_version_number, v_ext_bank_rec.bank_name 
                  FROM hz_parties 
                  WHERE party_id = n_bank_id;              
                
                EXCEPTION
                  WHEN OTHERS THEN
                    dka_tools_pkg.put_outdebug_message('ERREUR : RG13- Etablissement ' || Rec_Guich_Banq.CODE_ETABLISSEMENT || ' / Agence ' || Rec_Guich_Banq.CODE_IMMAT_GUI || ' : Impossible de vérifier l''existence de la banque dans Oracle Application. ' || SQLERRM);
                    p_retcode := 2;
                    p_errbuf  := SQLERRM || 'ERREUR : RG13 - Etablissement ' || Rec_Guich_Banq.CODE_ETABLISSEMENT || ' / Agence ' || Rec_Guich_Banq.CODE_IMMAT_GUI || ' : Impossible de vérifier l''existence de la banque dans Oracle Application.';
                END;
                v_ext_bank_rec.ATTRIBUTE10 := Rec_Guich_Banq.NAME_FILE || ' / ' || SYSDATE || ' / ' || cn_num_traitement;
                  
                -- MAJ des informations sur la banque
                iby_ext_bankacct_pub.update_ext_bank(   p_api_version   => n_api_version,
                                    p_init_msg_list => fnd_api.g_true,
                                    p_ext_bank_rec  => v_ext_bank_rec,
                                    x_return_status => v_return_status,
                                    x_msg_count     => n_msg_count,
                                    x_msg_data      => v_msg_data,
                                    x_response      => v_response_rec); 
                
                IF v_return_status != 'S' THEN                  
                  dka_tools_pkg.put_outdebug_message(Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_ERR_MAJ_ETAB', 'CODE_ETABLISSEMENT', Rec_Guich_Banq.CODE_ETABLISSEMENT, 'CODE_IMMAT_GUI', Rec_Guich_Banq.CODE_IMMAT_GUI, 'DATE_CLOSE_GUICHET', Rec_Guich_Banq.DATE_END_GUICHET) || ' ' || v_msg_data);
                  p_retcode := 2;
                  p_errbuf := v_msg_data || ' ERREUR : ' || Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_ERR_MAJ_ETAB', 'CODE_ETABLISSEMENT', Rec_Guich_Banq.CODE_ETABLISSEMENT, 'CODE_IMMAT_GUI', Rec_Guich_Banq.CODE_IMMAT_GUI, 'DATE_CLOSE_GUICHET', Rec_Guich_Banq.DATE_END_GUICHET);
                ELSE
                  BEGIN
                    SELECT eft_swift_code 
                    INTO   v_eft_swift_code 
                    FROM   hz_contact_points 
                    WHERE  owner_table_id = n_branch_id
                      AND  eft_swift_code is not null;     --JJA Correction 11/07/2017            
                  
                  EXCEPTION
                    WHEN OTHERS THEN
                      dka_tools_pkg.put_outdebug_message('ERREUR : RG13- Etablissement ' || Rec_Guich_Banq.CODE_ETABLISSEMENT || ' / Agence ' || Rec_Guich_Banq.CODE_IMMAT_GUI || ' : Impossible de vérifier l''existence du code bic dans Oracle Application. ' || SQLERRM);
                      p_retcode := 2;
                      p_errbuf  := SQLERRM || 'ERREUR : RG13 - Etablissement ' || Rec_Guich_Banq.CODE_ETABLISSEMENT || ' / Agence ' || Rec_Guich_Banq.CODE_IMMAT_GUI || ' : Impossible de vérifier l''existence du code bic dans Oracle Application.';
                  END;
                  
                  BEGIN
                    v_ext_branch_rec.bank_party_id   := n_bank_id;              
                    v_ext_branch_rec.branch_party_id := n_branch_id;
                    
                    v_ext_branch_rec.branch_name   := SUBSTR(nvl(Rec_Guich_Banq.NOM_GUICHET,nvl(Rec_Guich_Banq.DENOMINATION_PART,Rec_Guich_Banq.LIB_DOM_RIB)), 1, 60);
                    v_ext_branch_rec.attribute10   := Rec_Guich_Banq.NAME_FILE || ' / ' || SYSDATE || ' / ' || cn_num_traitement;
                    
                    SELECT 
                     hca.class_code, 
                     hca.object_version_number,
                     hop.BANK_OR_BRANCH_NUMBER,
                     hp.object_version_number,
                     hcp.object_version_number,
                     decode(v_eft_swift_code,
                            'XXXXXXXXXXX',
                            nvl(Rec_Guich_Banq.ADRESSE_SWIFT,
                              nvl(Rec_Guich_Banq.CODE_BIC, 'XXXXXXXXXXX')),
                            NULL,
                            nvl(Rec_Guich_Banq.ADRESSE_SWIFT,
                              nvl(Rec_Guich_Banq.CODE_BIC, 'XXXXXXXXXXX')),
                            v_eft_swift_code)
                    INTO   
                     v_ext_branch_rec.branch_type, 
                     v_ext_branch_rec.typ_object_version_number,
                     v_ext_branch_rec.branch_number,
                     v_ext_branch_rec.bch_object_version_number,
                     v_ext_branch_rec.eft_object_version_number,
                     v_ext_branch_rec.bic
                    FROM   hz_code_assignments hca,
                           hz_organization_profiles hop,
                           hz_parties hp,
                           Hz_Contact_Points hcp
                    WHERE  hca.owner_table_name = 'HZ_PARTIES'
                    AND    hca.class_category = 'BANK_BRANCH_TYPE'
                    AND    hca.owner_table_id = hp.party_id
                    AND    hop.party_id = hp.party_id
                    AND    hp.party_id = n_branch_id
                    AND    NVL(hop.effective_end_DATE,SYSDATE) >= SYSDATE
                    AND    hcp.owner_table_id = hp.party_id
                    AND    hcp.contact_point_type = 'EFT';
                     
                  EXCEPTION
                    WHEN OTHERS THEN
                      dka_tools_pkg.put_outdebug_message('ERREUR : RG13- Etablissement ' || Rec_Guich_Banq.CODE_ETABLISSEMENT || ' / Agence ' || Rec_Guich_Banq.CODE_IMMAT_GUI || ' : Impossible de trouver les données correspondant au guichet dans Oracle Application. ' || SQLERRM);
                      p_retcode := 2;
                      p_errbuf  := SQLERRM || 'ERREUR : RG13 - Etablissement ' || Rec_Guich_Banq.CODE_ETABLISSEMENT || ' / Agence ' || Rec_Guich_Banq.CODE_IMMAT_GUI || ' : Impossible de trouver les données correspondant au guichet dans Oracle Application.';
                  END;
                  -- MAJ des informations sur le guichet
                  iby_ext_bankacct_pub.update_ext_bank_branch(    p_api_version   => n_api_version,
                                          p_init_msg_list => fnd_api.g_true,
                                          p_ext_bank_branch_rec => v_ext_branch_rec,
                                          x_return_status => v_return_status,
                                          x_msg_count     => n_msg_count,
                                          x_msg_data      => v_msg_data,
                                          x_response      => v_response_rec);
                  
                  IF v_return_status != 'S' THEN                  
                    dka_tools_pkg.put_outdebug_message(Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_RG13_ERR', 'n_branch_id', n_branch_id, 'n_bank_id', n_bank_id, 'CODE_IMMAT_GUI', Rec_Guich_Banq.CODE_IMMAT_GUI, 'DATE_CLOSE_GUICHET', Rec_Guich_Banq.DATE_END_GUICHET) || ' ' || v_msg_data);
                    p_retcode := 2;
                    p_errbuf := v_msg_data || ' ERREUR : ' || Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_RG13_ERR', 'n_branch_id', n_branch_id, 'n_bank_id', n_bank_id, 'CODE_IMMAT_GUI', Rec_Guich_Banq.CODE_IMMAT_GUI, 'DATE_CLOSE_GUICHET', Rec_Guich_Banq.DATE_END_GUICHET);
                  ELSE
                    BEGIN
                      SELECT HZ_PARTY_SITES.LOCATION_ID, HZ_LOCATIONS.OBJECT_VERSION_NUMBER
                      INTO   v_location_rec.LOCATION_ID, n_obj_vers_num
                      FROM   HZ_PARTY_SITES, HZ_LOCATIONS
                      WHERE  HZ_PARTY_SITES.PARTY_ID  = n_branch_id
                      AND    HZ_PARTY_SITES.LOCATION_ID = HZ_LOCATIONS.LOCATION_ID;
                    EXCEPTION
                      WHEN OTHERS THEN
                        dka_tools_pkg.put_outdebug_message('ERREUR : RG13- n_branch_id ' || n_branch_id || ' / Agence ' || Rec_Guich_Banq.CODE_IMMAT_GUI || ' : Impossible de trouver l''adresse du guichet dans Oracle Application. ' || SQLERRM);
                        p_retcode := 2;
                        p_errbuf  := SQLERRM || 'ERREUR : RG13 - n_branch_id ' || n_branch_id || ' / Agence ' || Rec_Guich_Banq.CODE_IMMAT_GUI || ' : Impossible de trouver l''adresse du guichet dans Oracle Application.';
                    END;                          
                    v_location_rec.address1   := nvl(Rec_Guich_Banq.ADRESSE_3,'.');
                    v_location_rec.address2   := Rec_Guich_Banq.ADRESSE_4;
                    v_location_rec.address3   := Rec_Guich_Banq.ADRESSE_5;
                    v_location_rec.postal_code  := SUBSTR(Rec_Guich_Banq.ADRESSE_6,1,5);
                    v_location_rec.city     := SUBSTR(Rec_Guich_Banq.ADRESSE_6,7,24);
                    v_location_rec.COUNTRY    := cv_countrycode;
                    v_location_rec.attribute10  := Rec_Guich_Banq.NAME_FILE || ' / ' || SYSDATE || ' / ' || cn_num_traitement;
                  
                    -- MAJ de l'adresse du guichet
                    hz_location_v2pub.update_location(  p_init_msg_list          => fnd_api.g_true,
                                      p_location_rec           => v_location_rec,
                                      p_object_version_number  => n_obj_vers_num,
                                      x_return_status          => v_return_status,
                                      x_msg_count              => n_msg_count,
                                      x_msg_data               => v_msg_data);
                                      
                    IF v_return_status != 'S' THEN                  
                      dka_tools_pkg.put_outdebug_message(Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_ERR_MAJ_ADR', 'n_branch_id', n_branch_id, 'CODE_IMMAT_GUI', Rec_Guich_Banq.CODE_IMMAT_GUI, 'DATE_CLOSE_GUICHET', Rec_Guich_Banq.DATE_END_GUICHET) || ' ' || v_msg_data);
                      p_retcode := 2;
                      p_errbuf := v_msg_data || ' ERREUR : ' || Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_ERR_MAJ_ADR', 'n_branch_id', n_branch_id, 'CODE_IMMAT_GUI', Rec_Guich_Banq.CODE_IMMAT_GUI, 'DATE_CLOSE_GUICHET', Rec_Guich_Banq.DATE_END_GUICHET);
                    END IF;             
                  END IF;     
                END IF;                                         
              END IF; 
            -- 2019/01/29 NBO Optimisation du processus           
            --ELSIF Rec_Guich_Banq.nbr_cpl_bank_gui > 1 THEN --JJA 2016/07/12
            ELSIF l_NBR_CPL_BANK_GUI > 1 THEN 
              dka_tools_pkg.put_outdebug_message(Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_RG3_ERR', 'CODE_ETABLISSEMENT', Rec_Guich_Banq.CODE_ETABLISSEMENT, 'CODE_IMMAT_GUI', Rec_Guich_Banq.CODE_IMMAT_GUI));
              p_retcode := 2;       
              p_errbuf  := 'ERREUR : ' || Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_RG3_ERR', 'CODE_ETABLISSEMENT', Rec_Guich_Banq.CODE_ETABLISSEMENT, 'CODE_IMMAT_GUI', Rec_Guich_Banq.CODE_IMMAT_GUI);   
            END IF;
            
          END IF;
        END IF; 
        -- RG 03 LE COUPLE ETABLISSEMENT / GUICHET /PAYS N'EXISTE PAS DANS ORACLE APPLICATION. --
        IF (n_bank_id is null) or (n_branch_id is null)  THEN
          
          -- RG 07 ---------------------------------- --
          -- DATE DE FIN > DATE DU TRAITEMENT (JOUR). --
          -- ---------------------------------------- --
          IF NVL(to_date(Rec_Guich_Banq.DATE_END_GUICHET,'dd/mm/yyyy'), SYSDATE+1) > SYSDATE THEN
            IF Rec_Guich_Banq.n_verif_date_fin_guichet != 0 THEN -- RG 05 Date de Fin du guichet dans le fichier FGD ? --
              -- RG 08 INSERTION DU COUPLE BANQUE/AGENCE DANS OA ET ON POSITIONNE LA DATE DE FIN DANS OA. --
              dka_tools_pkg.put_outdebug_message(Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_RG8', 'CODE_ETABLISSEMENT', Rec_Guich_Banq.CODE_ETABLISSEMENT, 'CODE_IMMAT_GUI', Rec_Guich_Banq.CODE_IMMAT_GUI, 'DATE_CLOSE_GUICHET', Rec_Guich_Banq.DATE_END_GUICHET));
            ELSE
              dka_tools_pkg.put_outdebug_message(Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_RG7', 'CODE_ETABLISSEMENT', Rec_Guich_Banq.CODE_ETABLISSEMENT, 'CODE_IMMAT_GUI', Rec_Guich_Banq.CODE_IMMAT_GUI, 'DATE_CLOSE_GUICHET', Rec_Guich_Banq.DATE_END_GUICHET));
            END IF;
            IF p_maj = 'OUI' THEN
              -- Recherche du nom du guichet.
              BEGIN
                
                vv_nom_gui :=  SUBSTR(nvl(Rec_Guich_Banq.NOM_GUICHET,nvl(Rec_Guich_Banq.DENOMINATION_PART,nvl(Rec_Guich_Banq.LIB_DOM_RIB,Rec_Guich_Banq.CODE_IMMAT_GUI))), 1, 60);
                
              EXCEPTION
                WHEN OTHERS THEN
                  dka_tools_pkg.put_outdebug_message('ERREUR : RG12A - Etablissement ' || Rec_Guich_Banq.CODE_ETABLISSEMENT || ' / Agence ' || Rec_Guich_Banq.CODE_IMMAT_GUI || ' : Impossible de vérifier l''existence du guichet dans Oracle Application. ' || SQLERRM);
                  p_retcode := 2;
                  p_errbuf  := SQLERRM || 'ERREUR : RG12A - Etablissement ' || Rec_Guich_Banq.CODE_ETABLISSEMENT || ' / Agence ' || Rec_Guich_Banq.CODE_IMMAT_GUI || ' : Impossible de vérifier l''existence du guichet dans Oracle Application.';
              END;
              v_return_status := 'S';
              
              IF n_bank_id is null THEN   
                -- création de la banque                  
                dka_tools_pkg.put_log_message('CAS BANQUE INEXISTANTE : CREATION DE LA BANQUE ' || Rec_Guich_Banq.DENOMINATION1);
                v_ext_bank_rec.country_code := cv_countrycode;        
                        
                SELECT nvl(Rec_Guich_Banq.DENOMINATION1, Rec_Guich_Banq.CODE_ETABLISSEMENT)
                INTO v_ext_bank_rec.bank_name 
                FROM DUAL; 
                
                v_ext_bank_rec.bank_short_name := Rec_Guich_Banq.DENOMINATION2;               
                v_ext_bank_rec.bank_number := Rec_Guich_Banq.CODE_ETABLISSEMENT;                
                v_ext_bank_rec.attribute10 := Rec_Guich_Banq.NAME_FILE || ' / ' || SYSDATE || ' / ' || cn_num_traitement;
                
                iby_ext_bankacct_pub.create_ext_bank (  p_api_version   => n_api_version,
                                    p_init_msg_list => fnd_api.g_true,
                                    p_ext_bank_rec  => v_ext_bank_rec,
                                    x_bank_id   => n_bank_id,
                                    x_return_status => v_return_status,
                                    x_msg_count     => n_msg_count,
                                    x_msg_data      => v_msg_data,
                                    x_response      => v_response_rec);                       
              END IF;
              
              IF v_return_status != 'S' THEN
                dka_tools_pkg.put_outdebug_message(Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_RG8_ERR', 'CODE_ETABLISSEMENT', Rec_Guich_Banq.CODE_ETABLISSEMENT, 'CODE_IMMAT_GUI', Rec_Guich_Banq.CODE_IMMAT_GUI, 'DATE_CLOSE_GUICHET', Rec_Guich_Banq.DATE_END_GUICHET) || ' ' || v_msg_data);
                p_retcode := 2;
                p_errbuf := v_msg_data || ' ERREUR : RG8 - ' || Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_RG8_ERR', 'CODE_ETABLISSEMENT', Rec_Guich_Banq.CODE_ETABLISSEMENT, 'CODE_IMMAT_GUI', Rec_Guich_Banq.CODE_IMMAT_GUI, 'DATE_CLOSE_GUICHET', Rec_Guich_Banq.DATE_END_GUICHET);    
              ELSE
                -- création du guichet                  
                dka_tools_pkg.put_log_message('CAS GUICHET INEXISTANT : CREATION DU GUICHET ' || vv_nom_gui);
                v_ext_branch_rec.bank_party_id   := n_bank_id;              
                v_ext_branch_rec.branch_name   := vv_nom_gui;
                v_ext_branch_rec.branch_number   := Rec_Guich_Banq.CODE_IMMAT_GUI;
                v_ext_branch_rec.bic       := nvl(Rec_Guich_Banq.ADRESSE_SWIFT,nvl(Rec_Guich_Banq.CODE_BIC,'XXXXXXXXXXX'));
                v_ext_branch_rec.attribute10   := Rec_Guich_Banq.NAME_FILE || ' / ' || SYSDATE || ' / ' || cn_num_traitement;
                v_ext_branch_rec.branch_type     := 'OTHER';
                            
                iby_ext_bankacct_pub.create_ext_bank_branch (   p_api_version   => n_api_version,
                                        p_init_msg_list => fnd_api.g_true,
                                        p_ext_bank_branch_rec  => v_ext_branch_rec,
                                        x_branch_id   => n_branch_id,
                                        x_return_status => v_return_status,
                                        x_msg_count     => n_msg_count,
                                        x_msg_data      => v_msg_data,
                                        x_response      => v_response_rec); 
                                        
                IF v_return_status != 'S' THEN  
                  dka_tools_pkg.put_outdebug_message(Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_RG8_ERR', 'CODE_ETABLISSEMENT', Rec_Guich_Banq.CODE_ETABLISSEMENT, 'CODE_IMMAT_GUI', Rec_Guich_Banq.CODE_IMMAT_GUI, 'DATE_CLOSE_GUICHET', Rec_Guich_Banq.DATE_END_GUICHET) || ' ' || v_msg_data);
                  p_retcode := 2;
                  p_errbuf := v_msg_data || ' ERREUR : RG8 - ' || Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_RG8_ERR', 'CODE_ETABLISSEMENT', Rec_Guich_Banq.CODE_ETABLISSEMENT, 'CODE_IMMAT_GUI', Rec_Guich_Banq.CODE_IMMAT_GUI, 'DATE_CLOSE_GUICHET', Rec_Guich_Banq.DATE_END_GUICHET);    
                ELSE        
                  -- création de l'adresse du guichet
                  dka_tools_pkg.put_log_message('CREATION ADRESSE GUICHET ' || vv_nom_gui);
                  n_location_id := '';
                  v_location_rec.location_id  := '';
                  v_location_rec.address1   := nvl(Rec_Guich_Banq.ADRESSE_3,'.');
                  v_location_rec.address2   := Rec_Guich_Banq.ADRESSE_4;
                  v_location_rec.address3   := Rec_Guich_Banq.ADRESSE_5;
                  v_location_rec.postal_code  := SUBSTR(Rec_Guich_Banq.ADRESSE_6,1,5);
                  v_location_rec.city     := SUBSTR(Rec_Guich_Banq.ADRESSE_6,7,24);
                  v_location_rec.COUNTRY    := cv_countrycode;
                  v_location_rec.attribute10  := Rec_Guich_Banq.NAME_FILE || ' / ' || SYSDATE || ' / ' || cn_num_traitement;
                  v_location_rec.state    := 'Province';
                  v_location_rec.created_by_module := 'HZ_CPUI';
                  
                  hz_location_v2pub.create_location(  p_init_msg_list          => fnd_api.g_true,
                                    p_location_rec           => v_location_rec,
                                    x_location_id            => n_location_id,
                                    x_return_status          => v_return_status,
                                    x_msg_count              => n_msg_count,                                    
                                    x_msg_data               => v_msg_data);
                  
                  IF v_return_status != 'S' THEN  
                    dka_tools_pkg.put_outdebug_message(Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_ERR_CREA_ADR', 'CODE_ETABLISSEMENT', Rec_Guich_Banq.CODE_ETABLISSEMENT, 'CODE_IMMAT_GUI', Rec_Guich_Banq.CODE_IMMAT_GUI, 'DATE_CLOSE_GUICHET', Rec_Guich_Banq.DATE_END_GUICHET) || ' ' || v_msg_data);
                    p_retcode := 2;
                    p_errbuf := v_msg_data || ' ERREUR : ' || Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_ERR_CREA_ADR', 'CODE_ETABLISSEMENT', Rec_Guich_Banq.CODE_ETABLISSEMENT, 'CODE_IMMAT_GUI', Rec_Guich_Banq.CODE_IMMAT_GUI, 'DATE_CLOSE_GUICHET', Rec_Guich_Banq.DATE_END_GUICHET);   
                  ELSE
                    dka_tools_pkg.put_log_message('CREATION LIEN ADRESSE GUICHET ' || vv_nom_gui);                  
                    
                    -- création du lien adresse guichet         
                    v_party_site_rec.party_id       := n_branch_id ;
                    v_party_site_rec.location_id      := n_location_id ;
                    v_party_site_rec.created_by_module  := 'HZ_CPUI' ;

                    hz_party_site_v2pub.create_party_site (   p_init_msg_list     => fnd_api.g_true,
                                          p_party_site_rec    => v_party_site_rec,
                                          x_party_site_id     => n_party_site_id,
                                          x_party_site_number => n_party_site_number,
                                          x_return_status     => v_return_status,
                                          x_msg_count       => n_msg_count,
                                          x_msg_data      => v_msg_data
                                          );
                    IF v_return_status != 'S' THEN  
                      dka_tools_pkg.put_outdebug_message(Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_ERR_CREA_ADR', 'CODE_ETABLISSEMENT', Rec_Guich_Banq.CODE_ETABLISSEMENT, 'CODE_IMMAT_GUI', Rec_Guich_Banq.CODE_IMMAT_GUI, 'DATE_CLOSE_GUICHET', Rec_Guich_Banq.DATE_END_GUICHET) || ' ' || v_msg_data);
                      p_retcode := 2;
                      p_errbuf := v_msg_data || ' ERREUR : ' || Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_ERR_CREA_ADR', 'CODE_ETABLISSEMENT', Rec_Guich_Banq.CODE_ETABLISSEMENT, 'CODE_IMMAT_GUI', Rec_Guich_Banq.CODE_IMMAT_GUI, 'DATE_CLOSE_GUICHET', Rec_Guich_Banq.DATE_END_GUICHET);   
                    ELSE
                      Dka_Tools_Pkg.put_log_message('Création du lien adresse guichet réussi') ;
                    END IF;
                  END IF;                 
                END IF;
              END IF;
            END IF;
          
          -- RG 05 ---------------------------------- --
          -- DATE DE FIN <= DATE DU TRAITEMENT (JOUR). --
          -- ---------------------------------------- --
          ELSE
            -- RG 06 ----------------------------------------------------------------------------------------------------------------------------------- --
            -- PAS D'ACTION DANS ORACLE APPLICATION. ON NE VA PAS CREER UN COUPLE BANQUE/AGENCE POUR LEQUEL L'AGENCE EST FERMEE A LA DATE DU TRAITEMENT. --
            -- ----------------------------------------------------------------------------------------------------------------------------------------- --
            dka_tools_pkg.put_outdebug_message(Dka_Tools_Pkg.get_message ('DKA', 'DKA_IAPBANK_RG6', 'CODE_ETABLISSEMENT', Rec_Guich_Banq.CODE_ETABLISSEMENT, 'CODE_IMMAT_GUI', Rec_Guich_Banq.CODE_IMMAT_GUI, 'DATE_CLOSE_GUICHET',  Rec_Guich_Banq.DATE_END_GUICHET));
          END IF;
        END IF;
      END LOOP;
    CLOSE Cur_Guich_Banq;
    
    -- 2019/01/29 NBO Optimisation du processus
    DELETE FROM ar.hz_dqm_sync_interface WHERE staged_flag = 'N';
  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf := SQLERRM || ' Erreur : Procédure simulation_insert_file.' || p_errbuf;
  END simulation_insert_file;
  
  
  -----------------------------------------------------------------
  --  NOM           : main
  --  DESCRIPTION   : Procédure principale de mise a jour du référentiel bancaire.
  --
  --  PARAMETRES  : pv_retcode          code retour out
  --                pn_errbuf           description de l'erreur out
  --          PV_MAJ        flag de mise a jour ou de contrôle
  -----------------------------------------------------------------
  PROCEDURE main( pv_errbuf   OUT VARCHAR2,
          pn_retcode  OUT NUMBER,
          PV_MAJ    IN VARCHAR2
          ) IS
    error_enreg EXCEPTION;
  BEGIN
    Dka_Tools_Pkg.put_log_message( ' flag de mise a jour ou de contrôle : ' || PV_MAJ);
    dka_tools_pkg.put_outdebug_message('');
    dka_tools_pkg.put_outdebug_message('--- Contrôle de flux -------------------------------------------------------------------');
    dka_tools_pkg.put_outdebug_message('');
    controle_nbr_enreg_file(pv_errbuf,pn_retcode);
    IF pn_retcode = 2 THEN
      RAISE error_enreg;
    ELSIF pn_retcode = 1 THEN
      Dka_Tools_Pkg.put_log_message(pv_errbuf);
    END IF;
    
    
    dka_tools_pkg.put_outdebug_message('');
    dka_tools_pkg.put_outdebug_message('');
    dka_tools_pkg.put_outdebug_message('--- Contrôle des données ---------------------------------------------------------------');
    dka_tools_pkg.put_outdebug_message('');
    controle_coherence_file(pv_errbuf,pn_retcode);
    IF pn_retcode = 2 THEN
      RAISE error_enreg;
    ELSIF pn_retcode = 1 THEN
      Dka_Tools_Pkg.put_log_message(pv_errbuf);
    END IF;
    
    dka_tools_pkg.put_outdebug_message('');
    dka_tools_pkg.put_outdebug_message('');
    dka_tools_pkg.put_outdebug_message('--- Contrôle/MAJ Fermeture Guichet non présent dans le fichier FGB ---------------------');
    dka_tools_pkg.put_outdebug_message('');
    verif_end_guichet (pv_errbuf,pn_retcode,PV_MAJ);
    IF pn_retcode = 2 THEN
      RAISE error_enreg;
    END IF;
    
    dka_tools_pkg.put_outdebug_message('');
    dka_tools_pkg.put_outdebug_message('');
    IF PV_MAJ = 'NON' THEN
      dka_tools_pkg.put_outdebug_message('--- Simulation -------------------------------------------------------------------------');
    ELSIF PV_MAJ = 'OUI' THEN
      dka_tools_pkg.put_outdebug_message('--- Insertion / Creation ---------------------------------------------------------------');
    END IF;
    dka_tools_pkg.put_outdebug_message('');
    simulation_insert_file(pv_errbuf,pn_retcode,PV_MAJ);
    IF pn_retcode = 2 THEN
      RAISE error_enreg;
    ELSIF pn_retcode = 1 THEN
      Dka_Tools_Pkg.put_log_message(pv_errbuf);
    END IF;
    
    
  EXCEPTION
    WHEN error_enreg THEN
      pn_retcode := 2;
      Dka_Tools_Pkg.put_log_message(pv_errbuf);
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf := SQLERRM || ' Erreur : Procédure main.';
      Dka_Tools_Pkg.put_log_message(pv_errbuf);
  END main;
END DKA_IAPBANK_PKG;

/
show errors
exit;
