create or replace PACKAGE BODY DKA_REPGLSOLDESIMP_PKG IS
  ----------------------------------------------------------------------
  -- PROGRAM : DKA_REPGLSOLDESIMP_PKG.sql                              -
  -- Version : 1.0                                                     -
  -- AUTEUR  : J.PELAT / B.DELATTRE SOCIETE : CAPGEMINI                -
  -- DATE    : 14/04/16                                                -
  ----------------------------------------------------------------------
  -- APPELE PAR : Reprise GL SOLDES Import                               -
  -- FONCTION   : SFD001                                               -
  --                                                                   -
  --                                                                   -
  ----------------------------------------------------------------------
  -- Historique
  -- Date       Qui Description
  -- ---------- --- --------------------------------------------------------------
  -- 14/09/2016 JPE artf2002973 : Reprise des soldes GL  - Prise en compte écritures non lettrées
  -- 26/10/2016 JLY artf2035373 : Description des lignes non lettrées - Import
  -- 27/12/2016 OBE artf2069617 : RDD - GL - EDB035 Reprise en cours d'exercice
  -- 01/02/2017 OBE artf2094104 : RUN3 - Alimenter les segments de la CCF dans la table GL_INTERFACE
  -- 02/02/2017 MEG artf2094331 : RUN3 - Reprise solde GL -Doublon de ligne dans GL_INTERFACE
  -- 07/03/2017 RBE artf2114527 : Reprise détail GL - Import- Corriger l'accounting_date
  -- 20/06/2017 NBO artf2179288 : REP013 - Reprise des soldes GL RUN4 BIS
  -- 17/07/2017 YWA artf2194932 : REP013 - Reprise soldes GL pour les écritures en contrepassation automatique
  -- 13/11/2017 RBE artf2274372 : REPRISES GL - IMPORT R12 - Correction de la transco du projet
  -- 04/12/2017 MEG artf2288957 : RDD GL - IMPORT R12 - Pb dans le lancement de l'EasyLink
  --                artf2288973 : RDD GL - IMPORT R12 - Modification dans la transco de la clé comptable pour le segment ProjetFi
  --                              modfis reprises GL à faire (Voir mail)
   --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PRIVEES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  g_user_id                   fnd_user.user_id%TYPE;
  g_login_id                  fnd_logins.login_id%TYPE;
  g_resp_id                   fnd_responsibility_vl.responsibility_id%TYPE;
  g_resp_appl_id              fnd_responsibility_vl.application_id%TYPE;
  g_request_id                fnd_concurrent_requests.request_id%TYPE;
  g_loader_request_id         fnd_concurrent_requests.request_id%TYPE;
  
  g_tempo                     NUMBER := 5;
  g_limit                     NUMBER := 50000;
  
  g_nb_GL_Soldes_cree_oi      NUMBER :=0; 
  g_nb_GL_Soldes_ctrl_cree_oi NUMBER :=0;
  g_nb_GL_Soldes_charger      NUMBER :=0;
  g_nb_contrepassation_charger NUMBER :=0; --YWA artf2194932
  g_nb_GL_Soldes_cree                NUMBER :=0;
  g_nb_GL_Soldes_rejet        NUMBER :=0;  
  
  g_message_erreur_chargement    VARCHAR2(500) :=null;

  g_je_source_name            VARCHAR2(500) := 'MIGRATION';
  g_je_category_name          VARCHAR2(500) := 'DKA BALANCE 2017'; -- YWA artf2194932  2016 ==>2017  
 -- g_je_cat_name_contrepassation          VARCHAR2(500) := 'DKA CONTREPASSATION 2017'; -- YWA  artf2194932
  g_group_id                  NUMBER;
  
  
  g_reprise  VARCHAR2(500) ;

  /*
    *************************************************************************
    * PROCEDURE NAME : init
    * 
    * DESCRIPTION
    * Procédure d'initialisation des variables globales
    *
    * PARAMETERS
    * ==========
    * NAME              DESCRIPTION
    .* ----------------- ------------------------------------------------------
    * pv_errbuf         Retour de message éventuel
    * pn_retcode        Statut du traitement en sortie
    ************************************************************************
  */
  PROCEDURE init
  IS
  BEGIN

    dka_tools_pkg.put_log_message('Debut init');        
   
    ------------------------
    -- Variables globales --
    ------------------------ 

    g_login_id      := fnd_global.login_id;
    g_request_id    := fnd_global.conc_request_id;
    g_user_id         := fnd_global.user_id;
    g_resp_id       := fnd_global.resp_id;
    g_resp_appl_id  := fnd_global.resp_appl_id;
    
    -- YWA  artf2194932
    IF g_reprise = 'DKA_REPGLCONTREPA'THEN
        g_je_category_name := 'DKA CONTREPASSATION 2017';
    END IF;    

    dka_tools_pkg.put_log_message('Fin init');  
          
  END init;

  /*
    *************************************************************************
    * PROCEDURE NAME : init_environement
    * 
    * DESCRIPTION
    *  Procédure d'initialisation de l'environnement 
    *
    * PARAMETERS
    * ==========
    * NAME              DESCRIPTION
    .* ----------------- ------------------------------------------------------
    * pv_resp        Numéro de la resp
    ************************************************************************
  */
  PROCEDURE init_environement ( pv_resp IN VARCHAR2 DEFAULT NULL)
  IS
    v_resp_id NUMBER;
    v_appl_id NUMBER;
  BEGIN
    IF pv_resp IS NOT NULL THEN
      SELECT  responsibility_id
              ,application_id
      INTO    v_resp_id,
              v_appl_id
      FROM    fnd_responsibility_vl
      WHERE   responsibility_name = pv_resp;
    ELSE
      v_resp_id := g_resp_id;
      v_appl_id := g_resp_appl_id;
    END IF;
      
    fnd_global.apps_initialize(g_user_id, v_resp_id, v_appl_id);       
    
  EXCEPTION
    WHEN NO_DATA_FOUND THEN    
      dka_tools_pkg.put_outdebug_message('Erreur : La responsabilité ' || pv_resp || ' n''existe pas.'); 
      ROLLBACK;
  
  END init_environement;
    
  /*
    *************************************************************************
    * PROCEDURE NAME : Launch_Loader
    * 
    * DESCRIPTION
    *  Procédure de lancement du programme de chargement dans la table spécifique
    *
    * PARAMETERS
    * ==========
    * NAME               DESCRIPTION
    * -----------------  ------------------------------------------------------
    * p_directory           Répertoire du fichier
    * p_file_name        Nom du fichier à charger
    * pv_errbuf          Retour de message éventuel
    * pn_retcode         Statut du traitement en sortie
    * 
    ************************************************************************
  */
  PROCEDURE Launch_Loader(
            pv_errbuf  OUT VARCHAR2,
            pn_retcode OUT NUMBER,
            pv_loader IN VARCHAR2, -- YWA artf2194932 
            pv_NomFich IN VARCHAR2                          
            ) 
  IS
    v_phase                  VARCHAR2 (100);
    v_status                 VARCHAR2 (100);
    v_dev_phase              VARCHAR2 (100);
    v_dev_status             VARCHAR2 (100);
    v_message                VARCHAR2 (100);
    
    l_loader_request_id      NUMBER;

  BEGIN
    v_message := '';
        
        dka_tools_pkg.put_log_message('Debut Launch_Loader');    
        
    dka_tools_pkg.put_log_message('');
    dka_tools_pkg.put_log_message( 'CHARGEMENT DU FICHIER :' || pv_NomFich);
    dka_tools_pkg.put_log_message( '----------------------');
    
    ------------------------------------------------------
    -- Lancement du traitement de chargement du fichier --
    ------------------------------------------------------     

    -- Lancement du traitement 
    l_loader_request_id := Fnd_Request.submit_request (
                                 'DKA'                            -- APPL
                                ,pv_loader         -- PROG -- YWA artf2194932 
                                ,NULL                             -- PROGRAM_NAME
                                ,NULL                             -- START
                                ,FALSE                            -- SUB_REQUEST
                                ,pv_NomFich);

    IF l_loader_request_id = 0
    THEN
      pn_retcode := 2;
      pv_errbuf  := 'Erreur : Le traitement de chargement du fichier '||pv_loader ||' a échoué' ;
      dka_tools_pkg.put_outdebug_message( 'Erreur : Le traitement de chargement du fichier '||pv_loader ||' a échoué.');
    ELSE
      COMMIT;
      dka_tools_pkg.put_log_message( '=> LOAD REQUEST ID= ' || l_loader_request_id);            
      dka_tools_pkg.put_outdebug_message( 'Numéro du traitement de chargement de la table spécifique : ' || l_loader_request_id);  
      
      -- Attente de la fin du traitement
      IF NOT (Fnd_Concurrent.wait_for_request (l_loader_request_id, g_tempo, 0, v_phase, v_status, v_dev_phase, v_dev_status, v_message))
      THEN                        
          pn_retcode := 2;
          pv_errbuf  := 'Erreur : Attente de la fin du programme de chargement du fichier '||pv_loader ||' dépassée : Fin du traitement' ;
          dka_tools_pkg.put_outdebug_message( 'Erreur : Attente de la fin du programme de chargement du fichier '||pv_loader ||' dépassée : Fin du traitement ' || v_message);  
      END IF;
      
      dka_tools_pkg.put_outdebug_message( 'Statut de fin du traitement de chargement de la table spécifique : ' || v_dev_phase || '/' || v_dev_status);  
                   
      IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL') 
      THEN          
          dka_tools_pkg.put_log_message( 'COMPLETION= ' || v_dev_phase || '/' || v_dev_status);
      ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING')
      THEN
          dka_tools_pkg.put_log_message( 'Fin du traitement de chargement en warning '|| l_loader_request_id);
          pn_retcode := 1;
      ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL')  
      THEN
          pn_retcode := 2;
          pv_errbuf  := 'Erreur : Fin anormale du traitement de chargement : '|| l_loader_request_id;
          dka_tools_pkg.put_outdebug_message( 'Erreur : Fin anormale du traitement de chargement '|| l_loader_request_id  || CHR(10) ||
                    'Phase/Statut : ' || v_dev_phase || '/' || v_dev_status || CHR(10) ||
                    'MESSAGE : ' || v_message || CHR(10) );
      END IF;            
    END IF;     
    
    IF g_loader_request_id IS NULL THEN
      g_loader_request_id := l_loader_request_id;
    END IF;
    
    
    -- YWA artf2194932 
    IF pv_loader = 'DKA_REPGLSOLDESIMP_LOADER' THEN 
        UPDATE  DKA_GL_REPSOLDE_TMP
        SET     LOAD_REQUEST_ID = g_loader_request_id
        WHERE   LOAD_REQUEST_ID = l_loader_request_id;
        
        g_nb_GL_Soldes_charger := g_nb_GL_Soldes_charger + SQL%ROWCOUNT;   
    ELSE
        UPDATE  DKA_GL_CONTREPASSATION_TMP
        SET     LOAD_REQUEST_ID = g_loader_request_id
        WHERE   LOAD_REQUEST_ID = l_loader_request_id;
        g_nb_GL_Soldes_charger := g_nb_GL_Soldes_charger + SQL%ROWCOUNT;   
        --g_nb_contrepassation_charger := g_nb_contrepassation_charger + SQL%ROWCOUNT;
    END IF;    
    dka_tools_pkg.put_log_message('Fin Launch_Loader');    

    EXCEPTION
      WHEN OTHERS THEN
        pn_retcode   := 2;
        pv_errbuf    := 'LAUNCH_LOADER : ' ||SQLERRM;
        dka_tools_pkg.put_log_message( pv_errbuf);
        dka_tools_pkg.put_outdebug_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - Erreur : ' || 'Fin de la procédure Launch_Loader : EXCEPTION OTHERS ');
    
    END Launch_Loader;  
    
    /*
    *************************************************************************
    * PROCEDURE NAME : Transco_Segments
    * 
    * DESCRIPTION
    *  Procédure effectuant la transco et le chargement des nouveaux segments dans la table temporaire
    *
    * PARAMETERS
    * ==========
    * NAME               DESCRIPTION
    * -----------------  ------------------------------------------------------
    * pv_errbuf          Retour de message éventuel
    * pn_retcode         Statut du traitement en sortie
    * 
    ************************************************************************
  */
  
  PROCEDURE Transco_Segments IS
        v_SEGMENT1_NEW                 VARCHAR2(25);
        v_SEGMENT2_NEW                 VARCHAR2(25);
        v_SEGMENT3_NEW                 VARCHAR2(25);
        v_SEGMENT4_NEW                 VARCHAR2(25);
        v_SEGMENT5_NEW                 VARCHAR2(25);
        v_SEGMENT6_NEW                 VARCHAR2(25);
        v_SEGMENT7_NEW                 VARCHAR2(25);
        v_SEGMENT8_NEW                 VARCHAR2(25);
        v_SEGMENT9_NEW                 VARCHAR2(25);
        v_SEGMENT10_NEW                 VARCHAR2(25);
        v_SEGMENT11_NEW                 VARCHAR2(25);
        v_SEGMENT12_NEW                 VARCHAR2(25);
    
        CURSOR  cur_gl_soldes IS 
      SELECT  * 
      FROM    DKA_GL_REPSOLDE_TMP 
      WHERE   LOAD_REQUEST_ID = g_loader_request_id 
      FOR UPDATE;
    BEGIN             
    dka_tools_pkg.put_log_message('Début de la transco Transco_Segments');            
    
    FOR c_f IN cur_gl_soldes LOOP
        
      IF c_f.ENTITE ='EL 30/06' THEN
        -- Transco de la clé comptable
        DKA_REP_TRANSCO_PKG.get_cle_transco(
                 c_f.SEGMENT1
                ,c_f.SEGMENT2
                ,c_f.SEGMENT3
                ,'0' -- RBE artf2274372 - ajout des apostrophes
                ,c_f.SEGMENT4
                ,c_f.segment7 --,c_f.SEGMENT6 --RBE artf2274372
                ,c_f.SEGMENT8
                ,c_f.SEGMENT9
                ,c_f.SEGMENT10
                ,v_SEGMENT1_NEW
                ,v_SEGMENT2_NEW
                ,v_SEGMENT3_NEW
                ,v_SEGMENT4_NEW
                ,v_SEGMENT5_NEW
                ,v_SEGMENT6_NEW
                ,v_SEGMENT7_NEW
                ,v_SEGMENT8_NEW
                ,v_SEGMENT9_NEW
                ,v_SEGMENT10_NEW
                ,v_SEGMENT11_NEW
                ,v_SEGMENT12_NEW
                    );
                    
        -- Mise à jour des segments transcodés dans la table temporaire
                UPDATE  DKA_GL_REPSOLDE_TMP 
                SET     SEGMENT1_NEW  = v_SEGMENT1_NEW
                ,SEGMENT2_NEW  = v_SEGMENT2_NEW
                ,SEGMENT3_NEW  = v_SEGMENT3_NEW
                ,SEGMENT4_NEW  = v_SEGMENT4_NEW
                ,SEGMENT5_NEW  = v_SEGMENT5_NEW                        
                WHERE CURRENT OF cur_gl_soldes;                
            ELSE
                    -- Transco de la clé comptable
        DKA_REP_TRANSCO_PKG.get_cle_transco(
                c_f.SEGMENT1
                ,c_f.SEGMENT2
                ,c_f.SEGMENT3
                ,c_f.SEGMENT4
                ,c_f.SEGMENT5
                ,c_f.SEGMENT7  --,c_f.SEGMENT6 --RBE artf2274372
                ,c_f.SEGMENT8
                ,c_f.SEGMENT9
                ,c_f.SEGMENT10
                ,v_SEGMENT1_NEW
                ,v_SEGMENT2_NEW
                ,v_SEGMENT3_NEW
                ,v_SEGMENT4_NEW
                ,v_SEGMENT5_NEW
                ,v_SEGMENT6_NEW
                ,v_SEGMENT7_NEW
                ,v_SEGMENT8_NEW
                ,v_SEGMENT9_NEW
                ,v_SEGMENT10_NEW
                ,v_SEGMENT11_NEW
                ,v_SEGMENT12_NEW);
            
                -- Mise à jour des segments transcodés dans la table temporaire
        UPDATE  DKA_GL_REPSOLDE_TMP 
        SET     SEGMENT1_NEW  = v_SEGMENT1_NEW
                ,SEGMENT2_NEW  = v_SEGMENT2_NEW
                ,SEGMENT3_NEW  = v_SEGMENT3_NEW
                ,SEGMENT4_NEW  = v_SEGMENT4_NEW
                ,SEGMENT5_NEW  = v_SEGMENT5_NEW
                ,SEGMENT6_NEW  = v_SEGMENT6_NEW
                ,SEGMENT7_NEW  = v_SEGMENT7_NEW
                ,SEGMENT8_NEW  = v_SEGMENT8_NEW
                ,SEGMENT9_NEW  = v_SEGMENT9_NEW
                ,SEGMENT10_NEW = v_SEGMENT10_NEW
                ,SEGMENT11_NEW = v_SEGMENT11_NEW
                ,SEGMENT12_NEW = v_SEGMENT12_NEW
        WHERE CURRENT OF cur_gl_soldes;    
      END IF;
    END LOOP;
        
    COMMIT;
        dka_tools_pkg.put_log_message('Fin de la transco Transco_Segments');
    
  END Transco_Segments;
    
    /*
    *************************************************************************
    * PROCEDURE NAME : Transco_Unite_Operationnelle 
    * 
    * DESCRIPTION
    *  Procédure effectuant la transco et le chargement de la nouvelle entité opérationnelle 
      *  dans la table temporaire pour les données issues de la région GFK
    *
    * PARAMETERS
    * ==========
    * NAME               DESCRIPTION
    * -----------------  ------------------------------------------------------
    *
    * 
    ************************************************************************
  */
    PROCEDURE Transco_Unite_Operationnelle(pv_region VARCHAR2) 
  IS
    
        v_region_new VARCHAR2(25);
        
    BEGIN             
        Dka_Tools_Pkg.put_log_message('Début de la transco Transco_Unite_Operationnelle.');      
        
    DKA_REP_TRANSCO_PKG.get_transco(pv_transco_name => '008_REGIONS', 
                                        pv_column_01    => pv_region,
                                        pv_out_01       => v_region_new
                                        );
        
    UPDATE  DKA_GL_REPSOLDE_TMP 
        SET     SEGMENT2_NEW = v_region_new                
        WHERE   SEGMENT2 = pv_region
    AND     LOAD_REQUEST_ID = g_loader_request_id;                
        
        Dka_Tools_Pkg.put_log_message('Fin de la transco Transco_Unite_Operationnelle.');
    END Transco_Unite_Operationnelle;

    
  /*=========================================================================*/
  /* PROCEDURE NAME : purge_data_oi
  /* 
  /* DESCRIPTION
  /*  Purge des donner des opens interfaces
  /*
  /* PARAMETERS
  /* ==========
  /* NAME               DESCRIPTION
  /* -----------------  ------------------------------------------------------
  /* 
  /* 
  /*=========================================================================*/
  PROCEDURE purge_data_oi
  IS
    v_current_program_unit   VARCHAR2(30);

  BEGIN
    v_current_program_unit := 'purge_data';
    dka_tools_pkg.put_log_message('début ' || v_current_program_unit);    
                      
    DELETE  FROM GL_INTERFACE 
    WHERE   USER_JE_SOURCE_NAME = g_je_source_name;  
    
    dka_tools_pkg.put_log_message( 'GL_INTERFACE LIGNE SUPPR. : '||SQL%ROWCOUNT);
        dka_tools_pkg.put_log_message('fin ' || v_current_program_unit);  
  
  END purge_data_oi;
    
    
  /*=========================================================================*/
  /* FUNCTION NAME : insert_gl_interface
  /* 
  /* DESCRIPTION  :   function d'insertion dans l'open interface GL_INTERFACE
  /*  
  /*
  /* PARAMETERS
  /* ==========
  /* NAME               DESCRIPTION
  /* -----------------  ------------------------------------------------------
  /* p_gl_interface_rec              
  /* 
  /*=========================================================================*/
  FUNCTION insert_gl_interface(p_gl_interface_rec GL_INTERFACE%ROWTYPE) 
    RETURN   NUMBER
  IS
  BEGIN
       
    INSERT 
    INTO   GL_INTERFACE
    VALUES p_gl_interface_rec;
    
    return 0;
  
  EXCEPTION
    WHEN OTHERS THEN
      dka_tools_pkg.put_outdebug_message('Erreur lors de l''insertion de la ligne '|| p_gl_interface_rec.LEDGER_ID ||' dans l''open interface');
      dka_tools_pkg.put_log_message('Cause:' || SQLERRM);
      g_message_erreur_chargement := substr(SQLERRM,0,500) ;
      return 1;
            
  END insert_gl_interface;
    
    
    /*=========================================================================*/
  /* PROCEDURE NAME : Control_Data
  /* 
  /* DESCRIPTION
  /* Controle de la validité des données et transcos
  /*
  /* PARAMETERS
  /* ==========
  /* NAME               DESCRIPTION
  /* -----------------  ------------------------------------------------------
  /* 
  /* 
  /*=========================================================================*/
  PROCEDURE Control_Data(
                  pv_errbuf  OUT VARCHAR2,
                                    pn_retcode OUT NUMBER)
  IS 
      ln_count                      NUMBER;
      v_ledger_id                   NUMBER;
    
      v_SEGMENT1_NEW                VARCHAR2(25);
      v_SEGMENT2_NEW                VARCHAR2(25);
      v_SEGMENT3_NEW                VARCHAR2(25);
      v_SEGMENT4_NEW                VARCHAR2(25);
      v_SEGMENT5_NEW                VARCHAR2(25);
      v_SEGMENT6_NEW                VARCHAR2(25);
      v_SEGMENT7_NEW                VARCHAR2(25);
      v_SEGMENT8_NEW                VARCHAR2(25);
      v_SEGMENT9_NEW                VARCHAR2(25);
      v_SEGMENT10_NEW               VARCHAR2(25);
      v_SEGMENT11_NEW               VARCHAR2(25);
      v_SEGMENT12_NEW               VARCHAR2(25);
      v_CCID_NEW                    NUMBER(15);
      V_FLAG_MATRICULE              VARCHAR2(1);
      vv_errbuf                     VARCHAR2(1000) := '';
      vn_retcode                    NUMBER := 0;
      
      CURSOR  cur_gl_soldes IS 
      SELECT  x.rowid row_id, x.* 
      FROM    DKA_GL_REPSOLDE_TMP  x
      WHERE   LOAD_REQUEST_ID = g_loader_request_id 
      AND     STATUT = 'X' 
      --FOR UPDATE
      ;
      
    TYPE typ_gl_soldes IS TABLE OF cur_gl_soldes%ROWTYPE INDEX BY PLS_INTEGER;
    c_f typ_gl_soldes;   

     CURSOR  cur_gl_contrepassation IS 
      SELECT  x.rowid row_id, x.* 
      FROM    DKA_GL_CONTREPASSATION_TMP  x
      WHERE   LOAD_REQUEST_ID = g_loader_request_id 
      AND     STATUT = 'X' ;
      
    TYPE typ_gl_contrepassation IS TABLE OF cur_gl_contrepassation%ROWTYPE INDEX BY PLS_INTEGER;
    c_c typ_gl_contrepassation;   

    
  BEGIN
    pn_retcode := 0; 
    pv_errbuf  := '';
    
    IF g_reprise = 'DKA_REPGLSOLDESIMP' THEN  --YWA 
        UPDATE  DKA_GL_REPSOLDE_TMP  x
        SET     STATUT = 'X'
        WHERE   LOAD_REQUEST_ID = g_loader_request_id 
        AND     (STATUT = 'E' OR STATUT IS NULL);
    ELSE
        UPDATE  DKA_GL_CONTREPASSATION_TMP  x
        SET     STATUT = 'X'
        WHERE   LOAD_REQUEST_ID = g_loader_request_id 
        AND     (STATUT = 'E' OR STATUT IS NULL);
    END IF;
    
    
    COMMIT;
    
    pv_errbuf  := 'Recycacle des rejets OK';
         
    -- Controle existance de la source
    BEGIN
      SELECT  1
      INTO    ln_count
      FROM    GL_JE_SOURCES
      WHERE   USER_JE_SOURCE_NAME = g_je_source_name;

    EXCEPTION
      WHEN OTHERS THEN
        pn_retcode := 1;
        
        dka_tools_pkg.put_outdebug_message('Erreur lors de la recherche de la source : '||g_je_source_name);
        dka_tools_pkg.put_log_message('Cause:' || SQLERRM);
    END;       

    -- Controle existance de la categorie
    BEGIN
      SELECT  1
      INTO    ln_count
      FROM    GL_JE_CATEGORIES
      WHERE   USER_JE_CATEGORY_NAME = g_je_category_name;

    EXCEPTION
      WHEN OTHERS THEN
        pn_retcode := 1;
        
        dka_tools_pkg.put_outdebug_message('Erreur lors de la recherche de la catégorie : '||g_je_category_name);
        dka_tools_pkg.put_log_message('Cause:' || SQLERRM);
    END;
    
    pv_errbuf  := 'controle existance de la categorie OK';
    
    IF g_reprise = 'DKA_REPGLSOLDESIMP' THEN 
        OPEN cur_gl_soldes;
        LOOP
          FETCH cur_gl_soldes
          BULK COLLECT INTO c_f LIMIT g_limit;
          EXIT WHEN c_f.COUNT = 0;

          FOR i IN 1..c_f.COUNT LOOP
            
            c_f(i).STATUT := 'S';
            c_f(i).ERROR_MESSAGE := '';
            vv_errbuf := '';
            vn_retcode := 0;
            
            -- Recherche du LEDGER
            BEGIN
              SELECT  LEDGER_ID 
              INTO    v_ledger_id
              FROM    GL_LEDGERS 
              WHERE   SHORT_NAME = CASE WHEN c_f(i).ENTITE = 'EL 30/06' 
                                        THEN c_f(i).SEGMENT1 ||'_LEGAL'
                                        ELSE c_f(i).SEGMENT1
                                   END;
              --dka_tools_pkg.put_log_message('v_ledger_id : ' || v_ledger_id); -- OBE
              c_f(i).LEDGER_ID := v_ledger_id;
      
            EXCEPTION
              WHEN OTHERS THEN
                pn_retcode := 1;
                
                c_f(i).STATUT := 'E';
                
                IF c_f(i).ERROR_MESSAGE IS NOT NULL THEN
                  c_f(i).ERROR_MESSAGE := c_f(i).ERROR_MESSAGE || '/' || 'Erreur lors de la recherche du LEDGER_ID DU SHORT_NAME '|| CASE WHEN c_f(i).ENTITE = 'EL 30/06' 
                                                                                                           THEN c_f(i).SEGMENT1 ||'_LEGAL'
                                                                                                           ELSE c_f(i).SEGMENT1
                                                                                                      END;
                ELSE
                  c_f(i).ERROR_MESSAGE := 'Erreur lors de la recherche du LEDGER_ID DU SHORT_NAME '|| CASE WHEN c_f(i).ENTITE = 'EL 30/06' 
                                                                                                           THEN c_f(i).SEGMENT1 ||'_LEGAL'
                                                                                                           ELSE c_f(i).SEGMENT1
                                                                                                      END;
                END IF;
            END;
            
            pv_errbuf  := 'Solde : Transco des segments';
            
            -- Transodifiction des segments
            BEGIN             
              IF c_f(i).ENTITE ='EL 30/06' THEN
                DKA_REP_TRANSCO_PKG.get_cle_transco(
                     c_f(i).SEGMENT1
                    ,c_f(i).SEGMENT2
                    ,c_f(i).SEGMENT3
                    ,'0' -- RBE artf2274372 - ajout des apostrophes
                    ,c_f(i).SEGMENT4
                    ,c_f(i).SEGMENT7 --,c_f(i).SEGMENT6 --RBE artf2274372
                    ,c_f(i).SEGMENT8
                    ,c_f(i).SEGMENT9
                    ,c_f(i).SEGMENT10
                    ,v_SEGMENT1_NEW
                    ,v_SEGMENT2_NEW
                    ,v_SEGMENT3_NEW
                    ,v_SEGMENT4_NEW
                    ,v_SEGMENT5_NEW
                    ,v_SEGMENT6_NEW
                    ,v_SEGMENT7_NEW
                    ,v_SEGMENT8_NEW
                    ,v_SEGMENT9_NEW
                    ,v_SEGMENT10_NEW
                    ,v_SEGMENT11_NEW
                    ,v_SEGMENT12_NEW);
              ELSE
                IF c_f(i).SEGMENT7 <> '0' THEN
                  DKA_REP_TRANSCO_PKG.get_cle_transco(
                       c_f(i).SEGMENT1
                      ,c_f(i).SEGMENT2
                      ,c_f(i).SEGMENT3
                      ,c_f(i).SEGMENT4
                      ,c_f(i).SEGMENT5
                      ,c_f(i).SEGMENT7
                      ,c_f(i).SEGMENT8
                      ,c_f(i).SEGMENT9
                      ,c_f(i).SEGMENT10
                      ,v_SEGMENT1_NEW
                      ,v_SEGMENT2_NEW
                      ,v_SEGMENT3_NEW
                      ,v_SEGMENT4_NEW
                      ,v_SEGMENT5_NEW
                      ,v_SEGMENT6_NEW
                      ,v_SEGMENT7_NEW
                      ,v_SEGMENT8_NEW
                      ,v_SEGMENT9_NEW
                      ,v_SEGMENT10_NEW
                      ,v_SEGMENT11_NEW
                      ,v_SEGMENT12_NEW);
                      
                  IF v_SEGMENT8_NEW = '0' THEN
                    vn_retcode := 1;
                    vv_errbuf := c_f(i).SEGMENT7 || ' : La transco du projet n''existe pas';
                  END IF;
                      
                ELSIF (c_f(i).SEGMENT7 = '0' AND c_f(i).SEGMENT6 <> '0') THEN
                  DKA_REP_TRANSCO_PKG.get_cle_transco(
                       c_f(i).SEGMENT1
                      ,c_f(i).SEGMENT2
                      ,c_f(i).SEGMENT3
                      ,c_f(i).SEGMENT4
                      ,c_f(i).SEGMENT5
                      ,c_f(i).SEGMENT6
                      ,c_f(i).SEGMENT8
                      ,c_f(i).SEGMENT9
                      ,c_f(i).SEGMENT10
                      ,v_SEGMENT1_NEW
                      ,v_SEGMENT2_NEW
                      ,v_SEGMENT3_NEW
                      ,v_SEGMENT4_NEW
                      ,v_SEGMENT5_NEW
                      ,v_SEGMENT6_NEW
                      ,v_SEGMENT7_NEW
                      ,v_SEGMENT8_NEW
                      ,v_SEGMENT9_NEW
                      ,v_SEGMENT10_NEW
                      ,v_SEGMENT11_NEW
                      ,v_SEGMENT12_NEW);
                      
                  IF v_SEGMENT8_NEW = '0' THEN
                    vn_retcode := 1;
                    vv_errbuf := c_f(i).SEGMENT6 || ' : La transco du projet n''existe pas';
                  END IF;
                      
                ELSE
                  DKA_REP_TRANSCO_PKG.get_cle_transco(
                       c_f(i).SEGMENT1
                      ,c_f(i).SEGMENT2
                      ,c_f(i).SEGMENT3
                      ,c_f(i).SEGMENT4
                      ,c_f(i).SEGMENT5
                      ,c_f(i).SEGMENT7
                      ,c_f(i).SEGMENT8
                      ,c_f(i).SEGMENT9
                      ,c_f(i).SEGMENT10
                      ,v_SEGMENT1_NEW
                      ,v_SEGMENT2_NEW
                      ,v_SEGMENT3_NEW
                      ,v_SEGMENT4_NEW
                      ,v_SEGMENT5_NEW
                      ,v_SEGMENT6_NEW
                      ,v_SEGMENT7_NEW
                      ,v_SEGMENT8_NEW
                      ,v_SEGMENT9_NEW
                      ,v_SEGMENT10_NEW
                      ,v_SEGMENT11_NEW
                      ,v_SEGMENT12_NEW);         
                END IF;
              END IF;

              --Si OK on sort avec l'ID de la clé comptable
              --sinon on sort avec le message
              IF vn_retcode > 0 THEN
                pn_retcode := 1;
                
                c_f(i).STATUT := 'E';
                
                IF c_f(i).ERROR_MESSAGE IS NOT NULL THEN
                   c_f(i).ERROR_MESSAGE := c_f(i).ERROR_MESSAGE || ' / ' || vv_errbuf;
                ELSE
                   c_f(i).ERROR_MESSAGE := vv_errbuf;
                END IF;
              
              ELSE
                c_f(i).SEGMENT1_NEW := v_SEGMENT1_NEW;
                c_f(i).SEGMENT2_NEW := v_SEGMENT2_NEW;
                c_f(i).SEGMENT3_NEW := v_SEGMENT3_NEW;
                c_f(i).SEGMENT4_NEW := v_SEGMENT4_NEW;
                c_f(i).SEGMENT5_NEW := v_SEGMENT5_NEW;
                c_f(i).SEGMENT6_NEW := v_SEGMENT6_NEW;
                c_f(i).SEGMENT7_NEW := v_SEGMENT7_NEW;
                c_f(i).SEGMENT8_NEW := v_SEGMENT8_NEW;
                c_f(i).SEGMENT9_NEW := v_SEGMENT9_NEW;
                c_f(i).SEGMENT10_NEW := v_SEGMENT10_NEW;
                c_f(i).SEGMENT11_NEW := v_SEGMENT11_NEW;
                c_f(i).SEGMENT12_NEW := v_SEGMENT12_NEW;  
                c_f(i).CCID_NEW := v_CCID_NEW;
              END IF;
            END;
            
            pv_errbuf  := 'Solde : Transco des segments OK';
            
            -- IMPORT
            -- Pour gestion des matricules
            -- Dans le control data, pour les lignes répondant aux caractéristiques suivantes :
            -- Le SEGMENT3 de la clé comptable est dans la liste des comptes requérant la saisie du code MATRICULE (même règle que dans le SPE048 – Saisie GL)
            -- La valeur du complément de compte extrait de la 11i (SEGMENT5) commence par P
            -- Faire les màj suivantes :
            -- Mettre à jour la REFERENCE5 avec la valeur suivante : MAT | SEGMENT5 sans le P 
            -- Alimenter la colonne JGZZ_RECON_REF_NEW comme suit :
            -- Nouvelle référence de lettrage = Matricule employé concaténé avec la référence de lettrage 11i :  JGZZ_RECON_REF_NEW = SEGMENT5 sans le P || - -|| JGZZ_RECON_REF 11i  
            IF c_f(i).ENTITE ='DALKIA_OPE' THEN
              SELECT DECODE(COUNT(1), 0, 'N', 'Y')
                INTO V_FLAG_MATRICULE
                FROM fnd_flex_value_sets ffvs, fnd_flex_values ffv
               WHERE ffvs.flex_value_set_id = ffv.flex_value_set_id
                 AND ffvs.flex_value_set_name = 'DKA_COMPTE_MATRICULE'
                 AND ffv.flex_value = c_f(i).SEGMENT3
                 AND ffv.enabled_flag = 'Y';
              
              IF V_FLAG_MATRICULE = 'Y' AND NVL(substr(c_f(i).SEGMENT5,0,1),'ZZZ') = 'P' THEN
                 c_f(i).REFERENCE5     := 'MAT|'||substr(c_f(i).SEGMENT5, 2, length(c_f(i).SEGMENT5));  
                 IF c_f(i).JGZZ_RECON_REF IS NOT NULL AND c_f(i).JGZZ_RECON_REF <> 'REPRISE' THEN
                    c_f(i).JGZZ_RECON_REF_NEW := substr(c_f(i).SEGMENT5, 2, length(c_f(i).SEGMENT5)) || ' - - ' || c_f(i).JGZZ_RECON_REF;
                 ELSIF c_f(i).JGZZ_RECON_REF IS NOT NULL AND c_f(i).JGZZ_RECON_REF = 'REPRISE' THEN
                    c_f(i).JGZZ_RECON_REF_NEW := NULL;
                 ELSE
                    c_f(i).JGZZ_RECON_REF_NEW := substr(c_f(i).SEGMENT5, 2, length(c_f(i).SEGMENT5));
                 END IF;
              END IF;
              
              pv_errbuf  := 'Solde : Matricule OK';
            END IF;
            
            -- IMPORT
            -- Pour gestion des provisions client
            -- Dans le control data, alimenter la colonne JGZZ_RECON_REF_NEW comme suit pour les lignes dont la REFERENCE5 est non nulle
            -- Nouvelle référence de lettrage = Code client du CUF ATTRIBUTE17 en 11i concaténée avec la référence de lettrage 11i : JGZZ_RECON_REF_NEW = REFERENCE5 || - -|| JGZZ_RECON_REF 11i  
            IF c_f(i).ENTITE ='DALKIA_OPE' THEN
              IF c_f(i).REFERENCE5 IS NOT NULL AND c_f(i).REFERENCE5 NOT LIKE 'MAT%' THEN
                 IF c_f(i).JGZZ_RECON_REF IS NOT NULL AND c_f(i).JGZZ_RECON_REF <> 'REPRISE' THEN
                    c_f(i).JGZZ_RECON_REF_NEW := c_f(i).REFERENCE5 || ' - - ' ||  c_f(i).JGZZ_RECON_REF;
                 ELSE
                    c_f(i).JGZZ_RECON_REF_NEW := c_f(i).REFERENCE5;
                 END IF;
              END IF;
            END IF;
            
            pv_errbuf  := 'Solde : Fin boucle';
             
          END LOOP;

          FORALL i IN INDICES OF c_f
            UPDATE  DKA_GL_REPSOLDE_TMP 
            SET      SEGMENT1_NEW       = c_f(i).SEGMENT1_NEW 
                    ,SEGMENT2_NEW       = c_f(i).SEGMENT2_NEW 
                    ,SEGMENT3_NEW       = c_f(i).SEGMENT3_NEW 
                    ,SEGMENT4_NEW       = c_f(i).SEGMENT4_NEW 
                    ,SEGMENT5_NEW       = c_f(i).SEGMENT5_NEW 
                    ,SEGMENT6_NEW       = c_f(i).SEGMENT6_NEW 
                    ,SEGMENT7_NEW       = c_f(i).SEGMENT7_NEW 
                    ,SEGMENT8_NEW       = c_f(i).SEGMENT8_NEW 
                    ,SEGMENT9_NEW       = c_f(i).SEGMENT9_NEW 
                    ,SEGMENT10_NEW      = c_f(i).SEGMENT10_NEW 
                    ,SEGMENT11_NEW      = c_f(i).SEGMENT11_NEW 
                    ,SEGMENT12_NEW      = c_f(i).SEGMENT12_NEW 
                    ,CCID_NEW           = c_f(i).CCID_NEW 
                    ,STATUT             = c_f(i).STATUT
                    ,LEDGER_ID          = c_f(i).LEDGER_ID      -- OBE 
                    ,ERROR_MESSAGE      = c_f(i).ERROR_MESSAGE
                    ,JGZZ_RECON_REF     = c_f(i).JGZZ_RECON_REF
                    ,REFERENCE5         = c_f(i).REFERENCE5
                    ,JGZZ_RECON_REF_NEW = c_f(i).JGZZ_RECON_REF_NEW
            WHERE ROWID = c_f(i).ROW_ID;    
            
          COMMIT;
        END LOOP;
        CLOSE cur_gl_soldes;        
    --> JLY
    ELSE --YWA 
        OPEN cur_gl_contrepassation;
        LOOP
          FETCH cur_gl_contrepassation
          BULK COLLECT INTO c_c LIMIT g_limit;
          EXIT WHEN c_c.COUNT = 0;

          FOR i IN 1..c_c.COUNT LOOP
            
            c_c(i).STATUT := 'S';
            c_c(i).ERROR_MESSAGE := '';
            vv_errbuf := '';
            vn_retcode := 0;
            
            -- Recherche du LEDGER
            BEGIN
              SELECT  LEDGER_ID 
              INTO    v_ledger_id
              FROM    GL_LEDGERS 
              WHERE   SHORT_NAME = CASE WHEN c_c(i).ENTITE = 'EL 30/06' 
                                        THEN c_c(i).SEGMENT1 ||'_LEGAL'
                                        ELSE c_c(i).SEGMENT1
                                   END;
              --dka_tools_pkg.put_log_message('v_ledger_id : ' || v_ledger_id); -- OBE
              c_c(i).LEDGER_ID := v_ledger_id;
      
            EXCEPTION
              WHEN OTHERS THEN
                pn_retcode := 1;
                
                c_c(i).STATUT := 'E';
                
                IF c_c(i).ERROR_MESSAGE IS NOT NULL THEN
                   c_c(i).ERROR_MESSAGE := c_c(i).ERROR_MESSAGE || '/' || 'Erreur lors de la recherche du LEDGER_ID DU SHORT_NAME '|| CASE WHEN c_c(i).ENTITE = 'EL 30/06' 
                                                                                                            THEN c_c(i).SEGMENT1 ||'_LEGAL'
                                                                                                            ELSE c_c(i).SEGMENT1
                                                                                                       END;
                ELSE
                   c_c(i).ERROR_MESSAGE := 'Erreur lors de la recherche du LEDGER_ID DU SHORT_NAME '|| CASE WHEN c_c(i).ENTITE = 'EL 30/06' 
                                                                                                         THEN c_c(i).SEGMENT1 ||'_LEGAL'
                                                                                                         ELSE c_c(i).SEGMENT1
                                                                                                    END;
                END IF;
            END;
            
            pv_errbuf  := 'Contrepass : Transco des segments';
            
            -- Transodifiction des segments
            BEGIN             
              IF c_c(i).ENTITE ='EL 30/06' THEN
                DKA_REP_TRANSCO_PKG.get_cle_transco(
                     c_c(i).SEGMENT1
                    ,c_c(i).SEGMENT2
                    ,c_c(i).SEGMENT3
                    ,'0'  -- RBE artf2274372 - ajout des apostrophes
                    ,c_c(i).SEGMENT4
                    ,c_c(i).SEGMENT7  --,c_c(i).SEGMENT6 --RBE artf2274372
                    ,c_c(i).SEGMENT8
                    ,c_c(i).SEGMENT9
                    ,c_c(i).SEGMENT10
                    ,v_SEGMENT1_NEW
                    ,v_SEGMENT2_NEW
                    ,v_SEGMENT3_NEW
                    ,v_SEGMENT4_NEW
                    ,v_SEGMENT5_NEW
                    ,v_SEGMENT6_NEW
                    ,v_SEGMENT7_NEW
                    ,v_SEGMENT8_NEW
                    ,v_SEGMENT9_NEW
                    ,v_SEGMENT10_NEW
                    ,v_SEGMENT11_NEW
                    ,v_SEGMENT12_NEW);
              ELSE
              
                IF c_c(i).SEGMENT7 <> '0' THEN
                
                  DKA_REP_TRANSCO_PKG.get_cle_transco(
                       c_c(i).SEGMENT1
                      ,c_c(i).SEGMENT2
                      ,c_c(i).SEGMENT3
                      ,c_c(i).SEGMENT4
                      ,c_c(i).SEGMENT5
                      ,c_c(i).SEGMENT7  --,c_c(i).SEGMENT6 --RBE artf2274372
                      ,c_c(i).SEGMENT8
                      ,c_c(i).SEGMENT9
                      ,c_c(i).SEGMENT10
                      ,v_SEGMENT1_NEW
                      ,v_SEGMENT2_NEW
                      ,v_SEGMENT3_NEW
                      ,v_SEGMENT4_NEW
                      ,v_SEGMENT5_NEW
                      ,v_SEGMENT6_NEW
                      ,v_SEGMENT7_NEW
                      ,v_SEGMENT8_NEW
                      ,v_SEGMENT9_NEW
                      ,v_SEGMENT10_NEW
                      ,v_SEGMENT11_NEW
                      ,v_SEGMENT12_NEW);
                      
                  IF v_SEGMENT8_NEW = '0' THEN
                    vn_retcode := 1;
                    vv_errbuf := c_c(i).SEGMENT7 || ' : La transco du projet n''existe pas';
                  END IF;
                
                ELSIF (c_c(i).SEGMENT7 = '0' AND c_c(i).SEGMENT6 <> '0') THEN
                
                  DKA_REP_TRANSCO_PKG.get_cle_transco(
                       c_c(i).SEGMENT1
                      ,c_c(i).SEGMENT2
                      ,c_c(i).SEGMENT3
                      ,c_c(i).SEGMENT4
                      ,c_c(i).SEGMENT5
                      ,c_c(i).SEGMENT6
                      ,c_c(i).SEGMENT8
                      ,c_c(i).SEGMENT9
                      ,c_c(i).SEGMENT10
                      ,v_SEGMENT1_NEW
                      ,v_SEGMENT2_NEW
                      ,v_SEGMENT3_NEW
                      ,v_SEGMENT4_NEW
                      ,v_SEGMENT5_NEW
                      ,v_SEGMENT6_NEW
                      ,v_SEGMENT7_NEW
                      ,v_SEGMENT8_NEW
                      ,v_SEGMENT9_NEW
                      ,v_SEGMENT10_NEW
                      ,v_SEGMENT11_NEW
                      ,v_SEGMENT12_NEW);
                
                  IF v_SEGMENT8_NEW = '0' THEN
                    vn_retcode := 1;
                    vv_errbuf := c_c(i).SEGMENT6 || ' : La transco du projet n''existe pas';
                  END IF;
                
                ELSE
                
                  DKA_REP_TRANSCO_PKG.get_cle_transco(
                       c_c(i).SEGMENT1
                      ,c_c(i).SEGMENT2
                      ,c_c(i).SEGMENT3
                      ,c_c(i).SEGMENT4
                      ,c_c(i).SEGMENT5
                      ,c_c(i).SEGMENT7
                      ,c_c(i).SEGMENT8
                      ,c_c(i).SEGMENT9
                      ,c_c(i).SEGMENT10
                      ,v_SEGMENT1_NEW
                      ,v_SEGMENT2_NEW
                      ,v_SEGMENT3_NEW
                      ,v_SEGMENT4_NEW
                      ,v_SEGMENT5_NEW
                      ,v_SEGMENT6_NEW
                      ,v_SEGMENT7_NEW
                      ,v_SEGMENT8_NEW
                      ,v_SEGMENT9_NEW
                      ,v_SEGMENT10_NEW
                      ,v_SEGMENT11_NEW
                      ,v_SEGMENT12_NEW);
                 
                END IF;
              END IF;            
              
              --Si OK on sort avec l'ID de la clé comptable
              --sinon on sort avec le message
              IF vn_retcode > 0 THEN
                
                pn_retcode := 1;
                c_c(i).STATUT := 'E';
                
                IF c_c(i).ERROR_MESSAGE IS NOT NULL THEN
                   c_c(i).ERROR_MESSAGE := c_c(i).ERROR_MESSAGE || '/' || vv_errbuf;
                ELSE
                   c_c(i).ERROR_MESSAGE := vv_errbuf;
                END IF;
                
              ELSE
                c_c(i).SEGMENT1_NEW := v_SEGMENT1_NEW;
                c_c(i).SEGMENT2_NEW := v_SEGMENT2_NEW;
                c_c(i).SEGMENT3_NEW := v_SEGMENT3_NEW;
                c_c(i).SEGMENT4_NEW := v_SEGMENT4_NEW;
                c_c(i).SEGMENT5_NEW := v_SEGMENT5_NEW;
                c_c(i).SEGMENT6_NEW := v_SEGMENT6_NEW;
                c_c(i).SEGMENT7_NEW := v_SEGMENT7_NEW;
                c_c(i).SEGMENT8_NEW := v_SEGMENT8_NEW;
                c_c(i).SEGMENT9_NEW := v_SEGMENT9_NEW;
                c_c(i).SEGMENT10_NEW := v_SEGMENT10_NEW;
                c_c(i).SEGMENT11_NEW := v_SEGMENT11_NEW;
                c_c(i).SEGMENT12_NEW := v_SEGMENT12_NEW;  
                c_c(i).CCID_NEW := v_CCID_NEW;
              END IF;
            END;
            
            pv_errbuf  := 'Contrepass : Transco des segments OK';
            
            
            DECLARE
              vv_code_projet_check_new VARCHAR2(500) := '';
              vv_code_projet_check     VARCHAR2(500) := '';
              
            BEGIN
              
              -- IMPORT         
              -- Pour gestion des écritures sur projet (CUFs)
              -- Dans le control data, pour les lignes sur projet (ATTRIBUTE11 non nul et CONTEXT3 in ('Y.E.X','Y.R.X') :
              -- Faire la transco projet à partir de l’ATTRIBUTE11
              -- Sortir en rejet si la transco ramène 0
              -- Si la transco ne ramène pas 0 :
              -- stocker le projet R12 retourné dans la colonne PROJET_NEW
              -- stocker la tache R12 retournée dans la colonne TACHE_NEW
              IF c_c(i).ATTRIBUTE11 IS NOT NULL AND c_c(i).CONTEXT3 IN ('Y.E.X', 'Y.R.X') THEN
            
                vv_code_projet_check_new := DKA_REP_TRANSCO_PKG.get_transco_f(pv_transco_name => '014_PROJETS', 
                                                                        pv_column_01    => c_c(i).ATTRIBUTE11);  
                                                                                                                                                                     
                vv_code_projet_check := nvl(substr(vv_code_projet_check_new,1,instr(vv_code_projet_check_new,';')-1),'0');
                
                pv_errbuf  := '#DEBUG1';
                
                IF vv_code_projet_check = '0' THEN   
                  
                  pv_errbuf  := '#DEBUG2';
                  
                  pn_retcode := 1;
                  c_c(i).STATUT := 'E';
                  vv_errbuf := c_c(i).ATTRIBUTE11 || ' : La transco du projet n''existe pas';
                  
                  IF c_c(i).ERROR_MESSAGE IS NOT NULL THEN
                     c_c(i).ERROR_MESSAGE := c_c(i).ERROR_MESSAGE || '/' || vv_errbuf;
                  ELSE
                     c_c(i).ERROR_MESSAGE := vv_errbuf;
                  END IF;
                
                ELSE
                   
                   pv_errbuf  := '#DEBUG3';
                   c_c(i).PROJET_NEW := substr(vv_code_projet_check_new,1,instr(vv_code_projet_check_new,';')-1);
                   c_c(i).TACHE_NEW  := substr(vv_code_projet_check_new, instr(vv_code_projet_check_new,';')+1, length(vv_code_projet_check_new));
                   
                   -- Controle de l'existance des projets et taches en R12
                   DECLARE
                     vn_project_id NUMBER := NULL;
                   
                   BEGIN
                     
                     pv_errbuf  := '#DEBUG4';
                     SELECT project_id 
                       INTO vn_project_id 
                       FROM pa_projects_all 
                     WHERE segment1 = c_c(i).PROJET_NEW;
                   
                    EXCEPTION
                     WHEN OTHERS THEN
                        pv_errbuf  := '#DEBUG5';
                        pn_retcode := 1;
                        c_c(i).STATUT := 'E';
                        vv_errbuf := c_c(i).PROJET_NEW || ' : Le projet n''existe pas';
                                            
                        IF c_c(i).ERROR_MESSAGE IS NOT NULL THEN
                           c_c(i).ERROR_MESSAGE := c_c(i).ERROR_MESSAGE || '/' || vv_errbuf;
                        ELSE
                           c_c(i).ERROR_MESSAGE := vv_errbuf;
                        END IF;
                   
                    END;
                                   
                    DECLARE
                     vn_task_id NUMBER := NULL;
                        
                    BEGIN
                     
                     pv_errbuf  := '#DEBUG6';
                     SELECT task_id 
                       INTO vn_task_id 
                       FROM pa_tasks 
                      WHERE task_number = c_c(i).TACHE_NEW;
                       
                     EXCEPTION
                     WHEN OTHERS THEN
                        pv_errbuf  := '#DEBUG7';
                        pn_retcode := 1;
                        c_c(i).STATUT := 'E';
                        vv_errbuf := c_c(i).TACHE_NEW || ' : La tache n''existe pas';
                                            
                        IF c_c(i).ERROR_MESSAGE IS NOT NULL THEN
                           c_c(i).ERROR_MESSAGE := c_c(i).ERROR_MESSAGE || '/' || vv_errbuf;
                        ELSE
                           c_c(i).ERROR_MESSAGE := vv_errbuf;
                        END IF;
                       
                   END;
                   
                END IF;
              
              END IF;
              
            END;
            
            pv_errbuf  := 'Contrepass : Matricule';
            
            -- IMPORT
            -- Pour gestion des matricules
            -- Dans le control data, pour les lignes répondant aux caractéristiques suivantes :
            --	Le SEGMENT3 de la clé comptable est dans la liste des comptes requérant la saisie du code MATRICULE (même règle que dans le SPE048 – Saisie GL)
            -- La valeur du complément de compte extrait de la 11i (SEGMENT5) commence par P
            -- Faire les màj suivantes :
            -- Mettre à jour le CONTEXT3 avec la valeur 'MAT'
            -- Mettre à jour l’ATTRIBUTE11 avec la valeur du SEGMENT5 de la table de reprise mais sans le P
            -- Alimenter la colonne JGZZ_RECON_REF_NEW comme suit :
            -- Nouvelle référence de lettrage = Matricule employé concaténé avec la référence de lettrage 11i : JGZZ_RECON_REF_NEW = SEGMENT5 sans le P || - -|| JGZZ_RECON_REF 11i              
            SELECT DECODE(COUNT(1), 0, 'N', 'Y')
              INTO V_FLAG_MATRICULE
              FROM fnd_flex_value_sets ffvs, fnd_flex_values ffv
             WHERE ffvs.flex_value_set_id = ffv.flex_value_set_id
               AND ffvs.flex_value_set_name = 'DKA_COMPTE_MATRICULE'
               AND ffv.flex_value = c_c(i).SEGMENT3
               AND ffv.enabled_flag = 'Y';
            
            IF V_FLAG_MATRICULE = 'Y' AND NVL(substr(c_c(i).SEGMENT5,0,1),'ZZZ') = 'P' THEN
               c_c(i).CONTEXT3       := 'MAT';
               c_c(i).ATTRIBUTE11    := substr(c_c(i).SEGMENT5, 2, length(c_c(i).SEGMENT5));
               IF c_c(i).JGZZ_RECON_REF IS NOT NULL THEN
                  c_c(i).JGZZ_RECON_REF_NEW := substr(c_c(i).SEGMENT5, 2, length(c_c(i).SEGMENT5)) || ' - - ' || c_c(i).JGZZ_RECON_REF;
               ELSE
                  c_c(i).JGZZ_RECON_REF_NEW := substr(c_c(i).SEGMENT5, 2, length(c_c(i).SEGMENT5));
               END IF;
            END IF;
           
           pv_errbuf  := 'Contrepass : Matricule OK';
           
           -- IMPORT
           -- Pour gestion des provisions client
           -- Dans le control data, alimenter la colonne JGZZ_RECON_REF_NEW comme suit pour les lignes dont le CONTEXT3 = 'Y.X.Y' :
           -- Nouvelle référence de lettrage = Code client du CUF ATTRIBUTE17 en 11i concaténée avec la référence de lettrage 11i : JGZZ_RECON_REF_NEW =  ATTRIBUTE12 || - -|| JGZZ_RECON_REF 11i  
           IF c_c(i).CONTEXT3 = 'Y.X.Y' THEN
                 IF c_c(i).JGZZ_RECON_REF IS NOT NULL THEN
                    c_c(i).JGZZ_RECON_REF_NEW := substr(c_c(i).ATTRIBUTE12 || ' - - ' || c_c(i).JGZZ_RECON_REF, 0, 240);
                 ELSE
                    c_c(i).JGZZ_RECON_REF_NEW := substr(c_c(i).ATTRIBUTE12, 0, 240);
                 END IF;
            END IF;
           
           pv_errbuf  := 'Contrepass : Fin boucle';
           
          END LOOP;

          FORALL i IN INDICES OF c_c
            UPDATE  DKA_GL_CONTREPASSATION_TMP   
            SET      SEGMENT1_NEW       = c_c(i).SEGMENT1_NEW 
                    ,SEGMENT2_NEW       = c_c(i).SEGMENT2_NEW 
                    ,SEGMENT3_NEW       = c_c(i).SEGMENT3_NEW 
                    ,SEGMENT4_NEW       = c_c(i).SEGMENT4_NEW 
                    ,SEGMENT5_NEW       = c_c(i).SEGMENT5_NEW 
                    ,SEGMENT6_NEW       = c_c(i).SEGMENT6_NEW 
                    ,SEGMENT7_NEW       = c_c(i).SEGMENT7_NEW 
                    ,SEGMENT8_NEW       = c_c(i).SEGMENT8_NEW 
                    ,SEGMENT9_NEW       = c_c(i).SEGMENT9_NEW 
                    ,SEGMENT10_NEW      = c_c(i).SEGMENT10_NEW 
                    ,SEGMENT11_NEW      = c_c(i).SEGMENT11_NEW 
                    ,SEGMENT12_NEW      = c_c(i).SEGMENT12_NEW 
                    ,CCID_NEW           = c_c(i).CCID_NEW 
                    ,STATUT             = c_c(i).STATUT
                    ,LEDGER_ID          = c_c(i).LEDGER_ID       
                    ,ERROR_MESSAGE      = c_c(i).ERROR_MESSAGE
                    ,JGZZ_RECON_REF     = c_c(i).JGZZ_RECON_REF
                    ,CONTEXT3           = c_c(i).CONTEXT3
                    ,ATTRIBUTE11        = c_c(i).ATTRIBUTE11
                    ,PROJET_NEW         = c_c(i).PROJET_NEW
                    ,TACHE_NEW          = c_c(i).TACHE_NEW
                    ,JGZZ_RECON_REF_NEW = c_c(i).JGZZ_RECON_REF_NEW
            WHERE ROWID = c_c(i).ROW_ID;    
            
          COMMIT;
        END LOOP;
        CLOSE cur_gl_contrepassation;        
        
    END IF;    
    
    IF pn_retcode > 0 THEN
        IF g_reprise = 'DKA_REPGLSOLDESIMP' THEN 
          UPDATE  DKA_GL_REPSOLDE_TMP A
          SET     STATUT = 'E'
          WHERE   LOAD_REQUEST_ID = g_loader_request_id 
          AND     EXISTS (
                    SELECT  1
                    FROM    DKA_GL_REPSOLDE_TMP B
                    WHERE   A.LOAD_REQUEST_ID = B.LOAD_REQUEST_ID
                    AND     A.LEDGER_ID = B.LEDGER_ID
                    AND     B.STATUT = 'E');
     
          dka_tools_pkg.put_outdebug_message('Il existe des erreurs lors de la validation, controler la colonne ERROR_MESSAGE de DKA_GL_REPSOLDE_TMP');
        ELSE
          UPDATE  DKA_GL_CONTREPASSATION_TMP A
          SET     STATUT = 'E'
          WHERE   LOAD_REQUEST_ID = g_loader_request_id 
          AND     EXISTS (
                    SELECT  1
                    FROM    DKA_GL_CONTREPASSATION_TMP B
                    WHERE   A.LOAD_REQUEST_ID = B.LOAD_REQUEST_ID
                    AND     A.LEDGER_ID = B.LEDGER_ID
                    AND     B.STATUT = 'E');
     
          dka_tools_pkg.put_outdebug_message('Il existe des erreurs lors de la validation, controler la colonne ERROR_MESSAGE de DKA_GL_CONTREPASSATION_TMP');
        END IF;
    END IF;
    
    COMMIT;
  
  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode := 2;
      dka_tools_pkg.put_log_message('Erreur dans la procedure CONTROL_DATA : '||SQLERRM);
  END Control_Data;

  
    /*=========================================================================*/
  /* PROCEDURE NAME : insert_open_interface
  /* 
  /* DESCRIPTION
  /* Insertion des données de la table temporaire dans les table open interface
  /*
  /* PARAMETERS
  /* ==========
  /* NAME               DESCRIPTION
  /* -----------------  ------------------------------------------------------
  /* 
  /* 
  /*=========================================================================*/
  PROCEDURE insert_open_interface(
                                    pv_errbuf  OUT VARCHAR2,
                                    pn_retcode OUT NUMBER
                                 )--,
                                    --pd_date    IN  VARCHAR2) --RBE artf2114527
  IS

    v_shortname                      GL_LEDGERS.SHORT_NAME%type;
    v_gl_interface_rec               GL_INTERFACE%ROWTYPE;
    v_cpt_lig                        NUMBER;
    ld_date_fin_periode              DATE; --RBE artf2114527
    ld_date_debut_periode  DATE; -- YWA 
    v_period_name       VARCHAR2(30);
        
    CURSOR cur_gl_soldes IS 
      SELECT  x.rowid, x.* 
      FROM    DKA_GL_REPSOLDE_TMP x
      WHERE   LOAD_REQUEST_ID = g_loader_request_id
      AND     STATUT = 'S'
      --FOR UPDATE
      ; 
      
    TYPE typ_gl_soldes IS TABLE OF cur_gl_soldes%ROWTYPE INDEX BY PLS_INTEGER;
    c_f typ_gl_soldes;
    
    
    --YWA
     CURSOR  cur_gl_contrepassation IS 
      SELECT  x.rowid, x.*
      FROM    DKA_GL_CONTREPASSATION_TMP x  
      WHERE   LOAD_REQUEST_ID = g_loader_request_id 
      AND     STATUT = 'S';

    TYPE typ_gl_contrepassation IS TABLE OF cur_gl_contrepassation%ROWTYPE INDEX BY PLS_INTEGER;
    c_c typ_gl_contrepassation; 
    
    
    TYPE typ_gl_interface IS TABLE OF GL_INTERFACE%ROWTYPE INDEX BY PLS_INTEGER;
    x_gl_interface_rec typ_gl_interface;
    
  BEGIN
    /*============================================================================================*/
    /*Boucle principale d'insertion dans l'open interface GL_INTERFACE et GL_INTERFACE_CONTROL    */
    /*============================================================================================*/
    dka_tools_pkg.put_log_message('Boucle principale d''insertion dans l''open interface GL_INTERFACE et GL_INTERFACE_CONTROL'); 

    --purge_data_oi;

    pn_retcode := 0; 
    
    g_group_id := GL_INTERFACE_CONTROL_S.nextval;
    --g_nb_GL_Soldes_cree_oi := 0;

    IF g_reprise = 'DKA_REPGLSOLDESIMP' THEN 
        OPEN cur_gl_soldes;
        LOOP
          FETCH cur_gl_soldes
          BULK COLLECT INTO c_f LIMIT g_limit;
          EXIT WHEN c_f.COUNT = 0;

          FOR i IN 1..c_f.COUNT LOOP
          
            --RBE artf2114527
            BEGIN
                SELECT  END_DATE
                INTO    ld_date_fin_periode
                FROM    GL_PERIODS
                WHERE   PERIOD_NAME = c_f(i).PERIODE
                AND     PERIOD_SET_NAME = 'GROUPE';
            EXCEPTION
            WHEN OTHERS THEN
                dka_tools_pkg.put_outdebug_message('Erreur lors de la recherche de la date de fin de période : '||c_f(i).PERIODE);
                dka_tools_pkg.put_log_message('Cause:' || SQLERRM);
                RAISE;
            END; 
          
            x_gl_interface_rec(i).LEDGER_ID                 := c_f(i).LEDGER_ID;
            x_gl_interface_rec(i).STATUS                    := 'NEW';                
            x_gl_interface_rec(i).ACCOUNTING_DATE           := ld_date_fin_periode; --pd_date; --RBE artf2114527
            x_gl_interface_rec(i).CURRENCY_CODE             := c_f(i).CURRENCY_CODE;
            x_gl_interface_rec(i).DATE_CREATED              := SYSDATE;
            x_gl_interface_rec(i).CREATED_BY                := c_f(i).CREATED_BY;
            x_gl_interface_rec(i).ACTUAL_FLAG               := 'A';
            x_gl_interface_rec(i).USER_JE_CATEGORY_NAME     := NVL(c_f(i).USER_JE_CATEGORY_NAME,g_je_category_name); -- OBE --g_je_category_name;
            x_gl_interface_rec(i).USER_JE_SOURCE_NAME       := g_je_source_name;
            x_gl_interface_rec(i).GROUP_ID                  := g_group_id;
            x_gl_interface_rec(i).SEGMENT1                  := c_f(i).SEGMENT1_NEW;
            x_gl_interface_rec(i).SEGMENT2                  := c_f(i).SEGMENT2_NEW;
            x_gl_interface_rec(i).SEGMENT3                  := c_f(i).SEGMENT3_NEW;
            x_gl_interface_rec(i).SEGMENT4                  := c_f(i).SEGMENT4_NEW;
            x_gl_interface_rec(i).SEGMENT5                  := c_f(i).SEGMENT5_NEW;
            x_gl_interface_rec(i).SEGMENT6                  := c_f(i).SEGMENT6_NEW;
            x_gl_interface_rec(i).SEGMENT7                  := c_f(i).SEGMENT7_NEW;
            x_gl_interface_rec(i).SEGMENT8                  := c_f(i).SEGMENT8_NEW;
            x_gl_interface_rec(i).SEGMENT9                  := c_f(i).SEGMENT9_NEW;
            x_gl_interface_rec(i).SEGMENT10                 := c_f(i).SEGMENT10_NEW;
            x_gl_interface_rec(i).SEGMENT11                 := c_f(i).SEGMENT11_NEW;
            x_gl_interface_rec(i).SEGMENT12                 := c_f(i).SEGMENT12_NEW;
            x_gl_interface_rec(i).CODE_COMBINATION_ID       := c_f(i).CCID_NEW;
            x_gl_interface_rec(i).ENTERED_DR                := c_f(i).ACCOUNTED_DR;
            x_gl_interface_rec(i).ENTERED_CR                := c_f(i).ACCOUNTED_CR;
            x_gl_interface_rec(i).ACCOUNTED_DR              := c_f(i).ACCOUNTED_DR;
            x_gl_interface_rec(i).ACCOUNTED_CR              := c_f(i).ACCOUNTED_CR;
            x_gl_interface_rec(i).PERIOD_NAME               := c_f(i).PERIODE;
            x_gl_interface_rec(i).REFERENCE1                := 'MIGRATION R12';
            x_gl_interface_rec(i).REFERENCE2                := 'MIGRATION R12';
            x_gl_interface_rec(i).REFERENCE4                := c_f(i).REFERENCE4; -- OBE --'MIGRATION R12';
            
            IF c_f(i).ENTITE = 'EL 30/06' THEN
               x_gl_interface_rec(i).REFERENCE5             := c_f(i).REFERENCE5;
            ELSE
               x_gl_interface_rec(i).REFERENCE5             := NULL;
            END IF;
            
            --< JLY                                  
            --x_gl_interface_rec(i).REFERENCE10             := 'MIGRATION R12';
            x_gl_interface_rec(i).REFERENCE10               := c_f(i).DESCRIPTION;
            x_gl_interface_rec(i).REFERENCE21               := c_f(i).UNIQ_KEY;
            --> JLY                                         
            x_gl_interface_rec(i).JGZZ_RECON_REF            := NVL(c_f(i).JGZZ_RECON_REF_NEW, c_f(i).JGZZ_RECON_REF);
            x_gl_interface_rec(i).ATTRIBUTE9                := c_f(i).ATTRIBUTE9;  -- OBE
            x_gl_interface_rec(i).ATTRIBUTE10               := c_f(i).ATTRIBUTE10; -- OBE

            -- IMPORT
            -- Pour gestion des matricules
            -- Dans le chargement de GL_INTERFACE :
            -- Ajouter l’alimentation de l’ATTRIBUTE11 comme suit :
            -- alimenter avec la valeur de la REFERENCE5 de la table de reprise APRES LE PIPE (SEGMENT5 sans le P) si la REFERENCE5 commence par MAT
            IF c_f(i).ENTITE = 'DALKIA_OPE' THEN
              IF substr(c_f(i).REFERENCE5, 0, instr(c_f(i).REFERENCE5,'|',1)-1) = 'MAT' THEN
                 x_gl_interface_rec(i).ATTRIBUTE11            := substr(c_f(i).REFERENCE5, instr(c_f(i).REFERENCE5,'|',1)+1, length(c_f(i).REFERENCE5));
              ELSE
                 x_gl_interface_rec(i).ATTRIBUTE11            := NULL;
              END IF;
            ELSE
                 x_gl_interface_rec(i).ATTRIBUTE11            := NULL;
            END IF;
            
            -- IMPORT
            -- Pour gestion des provisions client  
            -- Dans le chargement de GL_INTERFACE :
            -- Ajouter l’alimentation de l’ATTRIBUTE17 comme suit :
            -- alimenter avec la REFERENCE5 de la table de reprise si la REFERENCE5 ne commence pas par MAT
            IF c_f(i).ENTITE = 'DALKIA_OPE' THEN
              IF substr(c_f(i).REFERENCE5, 0, 3) <> 'MAT' THEN
                 x_gl_interface_rec(i).ATTRIBUTE17            := c_f(i).REFERENCE5;  
              ELSE
                 x_gl_interface_rec(i).ATTRIBUTE17            := NULL;        
              END IF;
            ELSE
               x_gl_interface_rec(i).ATTRIBUTE17            := NULL;
            END IF;
   
            -- IMPORT         
            -- Pour gestion des provisions client et des matricules
            -- Dans le chargement de GL_INTERFACE :
            -- Ajouter l’alimentation du CONTEXT3 comme suit :
            -- alimenter avec la valeur 'MAT' si la REFERENCE5 de la table de reprise commence par MAT (valeur avant le pipe)
            -- alimenter avec la valeur 'Y.X.Y' si la REFERENCE5 de la table de reprise ne commence par MAT
            IF c_f(i).ENTITE = 'DALKIA_OPE' THEN
              IF c_f(i).REFERENCE5 IS NULL THEN
                 x_gl_interface_rec(i).CONTEXT3                  := NULL;
              ELSIF c_f(i).REFERENCE5 LIKE 'MAT%' THEN
                 x_gl_interface_rec(i).CONTEXT3                  := 'MAT';
              ELSE
                 x_gl_interface_rec(i).CONTEXT3                  := 'Y.X.Y';
              END IF;
            ELSE
               x_gl_interface_rec(i).CONTEXT3                    := NULL;
            END IF;
            
          END LOOP;

        --FORALL i IN INDICES OF x_gl_interface_rec
          FORALL i IN 1 .. c_f.COUNT
            INSERT INTO GL_INTERFACE VALUES x_gl_interface_rec(i); 
            
          FORALL i IN 1 .. c_f.COUNT
            UPDATE DKA_GL_REPSOLDE_TMP SET statut = 'T' WHERE rowid = c_f(i).rowid;   
               
          COMMIT;
        END LOOP;
        CLOSE cur_gl_soldes;
          
    --> JLY
    ELSE --YWA
        OPEN cur_gl_contrepassation;
        LOOP
          FETCH cur_gl_contrepassation
          BULK COLLECT INTO c_c LIMIT g_limit;
          EXIT WHEN c_c.COUNT = 0;

          FOR i IN 1..c_c.COUNT LOOP
          
            BEGIN
                
                SELECT  start_date,period_name
                INTO    ld_date_debut_periode, v_period_name
                FROM    GL_PERIODS where   start_date  =     (SELECT  end_date+1
                FROM    GL_PERIODS
                WHERE   PERIOD_NAME = c_c(i).PERIOD_NAME
                AND     PERIOD_SET_NAME = 'GROUPE')
                AND     PERIOD_SET_NAME = 'GROUPE';
                
            EXCEPTION
            WHEN OTHERS THEN
                dka_tools_pkg.put_outdebug_message('Erreur lors de la recherche de la date du premier jour ouvré de la periode suivante  : '||c_c(i).PERIOD_NAME);
                dka_tools_pkg.put_log_message('Cause:' || SQLERRM);
                RAISE;
            END; 
          
            x_gl_interface_rec(i).LEDGER_ID                 := c_c(i).LEDGER_ID;
            x_gl_interface_rec(i).STATUS                    := 'NEW';          
            
            Dka_Tools_Pkg.put_log_message('premier jour ouvré de la PERIODE SUIVANTE  : START_DATE');
            IF Dka_Tools_Pkg.IS_BANK_HOLIDAY(ld_date_debut_periode) = 1 OR TRIM(TO_CHAR(ld_date_debut_periode, 'DAY')) IN ('SAMEDI', 'DIMANCHE') 
            THEN
             
                Dka_Tools_Pkg.Get_Next_Working_Day(ld_date_debut_periode);
                 
            END IF;
            
            --x_gl_interface_rec(i).ROWID                     := c_c(i).rowid;
            x_gl_interface_rec(i).ACCOUNTING_DATE           := ld_date_debut_periode; 
            x_gl_interface_rec(i).CURRENCY_CODE             := c_c(i).CURRENCY_CODE;
            x_gl_interface_rec(i).DATE_CREATED              := SYSDATE;
            x_gl_interface_rec(i).CREATED_BY                := c_c(i).CREATED_BY;
            x_gl_interface_rec(i).ACTUAL_FLAG               := 'A';
            x_gl_interface_rec(i).USER_JE_CATEGORY_NAME     := g_je_category_name; 
            x_gl_interface_rec(i).USER_JE_SOURCE_NAME       := g_je_source_name;
            x_gl_interface_rec(i).GROUP_ID                  := g_group_id;
            x_gl_interface_rec(i).SEGMENT1                  := c_c(i).SEGMENT1_NEW;
            x_gl_interface_rec(i).SEGMENT2                  := c_c(i).SEGMENT2_NEW;
            x_gl_interface_rec(i).SEGMENT3                  := c_c(i).SEGMENT3_NEW;
            x_gl_interface_rec(i).SEGMENT4                  := c_c(i).SEGMENT4_NEW;
            x_gl_interface_rec(i).SEGMENT5                  := c_c(i).SEGMENT5_NEW;
            x_gl_interface_rec(i).SEGMENT6                  := c_c(i).SEGMENT6_NEW;
            x_gl_interface_rec(i).SEGMENT7                  := c_c(i).SEGMENT7_NEW;
            x_gl_interface_rec(i).SEGMENT8                  := c_c(i).SEGMENT8_NEW;
            x_gl_interface_rec(i).SEGMENT9                  := c_c(i).SEGMENT9_NEW;
            x_gl_interface_rec(i).SEGMENT10                 := c_c(i).SEGMENT10_NEW;
            x_gl_interface_rec(i).SEGMENT11                 := c_c(i).SEGMENT11_NEW;
            x_gl_interface_rec(i).SEGMENT12                 := c_c(i).SEGMENT12_NEW;
            x_gl_interface_rec(i).CODE_COMBINATION_ID       := c_c(i).CCID_NEW;
            x_gl_interface_rec(i).ENTERED_DR                := c_c(i).ACCOUNTED_CR;
            x_gl_interface_rec(i).ENTERED_CR                := c_c(i).ACCOUNTED_DR;
            x_gl_interface_rec(i).ACCOUNTED_DR              := c_c(i).ACCOUNTED_CR;
            x_gl_interface_rec(i).ACCOUNTED_CR              := c_c(i).ACCOUNTED_DR;
            x_gl_interface_rec(i).PERIOD_NAME               := v_period_name ;
            x_gl_interface_rec(i).REFERENCE1                := 'MIGRATION 2018';
            x_gl_interface_rec(i).REFERENCE2                := 'MIGRATION 2018';
            x_gl_interface_rec(i).REFERENCE4                := c_c(i).REFERENCE4; 
            x_gl_interface_rec(i).REFERENCE5                := c_c(i).REFERENCE5;  

            --x_gl_interface_rec(i).REFERENCE10               := 'MIGRATION 2018' ;
                                       
            x_gl_interface_rec(i).JGZZ_RECON_REF            := NVL(c_c(i).JGZZ_RECON_REF_NEW, c_c(i).JGZZ_RECON_REF);
            x_gl_interface_rec(i).ATTRIBUTE9                := c_c(i).CODE_FOLIO;   
            x_gl_interface_rec(i).ATTRIBUTE10               := c_c(i).FIC_IDENT;

            -- IMPORT
            -- Pour gestion des matricules           
            -- Modifier l'alimentation de l’ATTRIBUTE11 comme suit :
            -- alimenter avec l’ATTRIBUTE11 de la table de reprise si CONTEXT3 = 'MAT', sinon alimenter l’ATTRIBUTE11 
            -- avec l'ID du projet R12 contenu dans PROJET_NEW  
            IF c_c(i).CONTEXT3 = 'MAT' THEN
               x_gl_interface_rec(i).ATTRIBUTE11            := c_c(i).ATTRIBUTE11;
            ELSE
/*              DKA_REP_TRANSCO_PKG.get_transco(pv_transco_name => '014_PROJETS', 
                                              pv_column_01    => c_c(i).ATTRIBUTE11,
                                              pv_out_01       => x_gl_interface_rec(i).ATTRIBUTE11, 
                                              pv_out_02       => x_gl_interface_rec(i).ATTRIBUTE17 
                                          );*/
               DECLARE
                 vn_project_id NUMBER := NULL;
               
               BEGIN
                 
                 IF c_c(i).PROJET_NEW IS NOT NULL THEN 
                 
                   SELECT project_id 
                     INTO vn_project_id 
                     FROM pa_projects_all 
                   WHERE segment1 = c_c(i).PROJET_NEW;
                   
                   x_gl_interface_rec(i).ATTRIBUTE11            := vn_project_id;
                 
                 END IF;
               
                END;
               
            END IF;
            
            -- IMPORT
            -- Pour gestion des provisions client    
            -- Dans le chargement de GL_INTERFACE :
            -- Modifier l’alimentation de l’ATTRIBUTE12 comme suit :
            -- alimenter avec l’ATTRIBUTE12 de la table de reprise si CONTEXT3 ! = 'Y.X.Y', sinon ne pas alimenter
            -- Ajouter l’alimentation de l’ATTRIBUTE17 comme suit :
            -- alimenter avec l’ATTRIBUTE12 de la table de reprise si CONTEXT3 = 'Y.X.Y', sinon alimenter l’ATTRIBUTE17 avec l'ID de la 
            -- tache R12 contenue dans TACHE_NEW
            IF c_c(i).CONTEXT3 <> 'Y.X.Y' THEN
               x_gl_interface_rec(i).ATTRIBUTE12            := c_c(i).ATTRIBUTE12;
               
               DECLARE
                 vn_task_id NUMBER := NULL;
               
               BEGIN
                 
                 IF c_c(i).TACHE_NEW IS NOT NULL THEN
               
                   SELECT task_id 
                     INTO vn_task_id 
                     FROM pa_tasks 
                    WHERE task_number = c_c(i).TACHE_NEW;
                 
                     x_gl_interface_rec(i).ATTRIBUTE17            := vn_task_id;
                   
                 END IF;
                 
               END;
               
            ELSE
               x_gl_interface_rec(i).ATTRIBUTE12            := NULL;
               IF c_c(i).CONTEXT3 = 'Y.X.Y' THEN 
                  x_gl_interface_rec(i).ATTRIBUTE17            := c_c(i).ATTRIBUTE12;   
               END IF;
            END IF;
            
            x_gl_interface_rec(i).ATTRIBUTE13               := c_c(i).ATTRIBUTE13;
            x_gl_interface_rec(i).ATTRIBUTE14               := c_c(i).ATTRIBUTE14;
            
            x_gl_interface_rec(i).CONTEXT3                  := c_c(i).CONTEXT3;
            
/*            DKA_REP_TRANSCO_PKG.get_transco(pv_transco_name => '014_PROJETS', 
                                        pv_column_01    => c_c(i).ATTRIBUTE15,
                                        pv_out_01       => x_gl_interface_rec(i).ATTRIBUTE15,
                                        pv_out_02       => x_gl_interface_rec(i).ATTRIBUTE18  
                                        );*/
            
            x_gl_interface_rec(i).REFERENCE10 := c_c(i).ATTRIBUTE15;

          END LOOP;

          FORALL i IN 1 .. c_c.COUNT
            INSERT INTO GL_INTERFACE VALUES x_gl_interface_rec(i); 
            
          FORALL i IN 1 .. c_c.COUNT
            UPDATE DKA_GL_CONTREPASSATION_TMP SET statut = 'T' WHERE rowid = c_c(i).rowid;   
                 
          COMMIT;
        END LOOP;
        CLOSE cur_gl_contrepassation;
    END IF;
    
    SELECT COUNT(*)
    INTO g_nb_GL_Soldes_cree_oi
    FROM GL_INTERFACE 
    WHERE   USER_JE_SOURCE_NAME = g_je_source_name; 
    
    IF pn_retcode = 2 THEN
      pv_errbuf := 'Chargement de la table gl_interface contient des erreurs';
      dka_tools_pkg.put_outdebug_message('Chargement de la table gl_interface contient des erreurs');
    END IF;            

    dka_tools_pkg.put_log_message('Fin d''insertion dans les tables d''open interface GL_INTERFACE'); 
  END insert_open_interface;
    
    
    /*=========================================================================*/
  /* PROCEDURE NAME :   program_import_gl_soldes
  /* 
  /* DESCRIPTION  Traitement standard d'import des solde GL
  /*  
  /*
  /* PARAMETERS
  /* ==========
  /* NAME               DESCRIPTION
  /* -----------------  ------------------------------------------------------
  /*                
  /* 
  /*=========================================================================*/
  PROCEDURE program_import_gl_soldes( 
                  pv_errbuf  OUT VARCHAR2,
                  pn_retcode OUT NUMBER) 
  IS
    
    v_phase                  VARCHAR2 (100);
    v_status                 VARCHAR2 (100);
    v_dev_phase              VARCHAR2 (100);
    v_dev_status             VARCHAR2 (100);
    v_message                VARCHAR2 (100);
    
    v_societe                VARCHAR2 (100);
    v_cle_comptable          VARCHAR2 (100);

    ln_run_id                NUMBER;
    v_nb_GL_Soldes_rejet     NUMBER:= 0;
    
    CURSOR cur_gl_int_ctrl IS 
      SELECT  LEDGER_ID, GROUP_ID, MOD(row_number() over (partition by 1 order by 1), 20) rk
      FROM    GL_INTERFACE
      WHERE   USER_JE_SOURCE_NAME = g_je_source_name
      GROUP BY LEDGER_ID, GROUP_ID;

  BEGIN
  
    DELETE  FROM GL_INTERFACE_CONTROL 
    WHERE   JE_SOURCE_NAME = (SELECT JE_SOURCE_NAME FROM GL_JE_SOURCES WHERE USER_JE_SOURCE_NAME = g_je_source_name);  
                
    dka_tools_pkg.put_log_message('GL_INTERFACE_CONTROL LIGNE SUPPR. : '||SQL%ROWCOUNT);
  
    -- JPE artf1983374 : RUN1-Reprise GL -Table gl_interface_control
    FOR r_row in cur_gl_int_ctrl LOOP
      -- Un meme INTERFACE_RUN_ID ne peut pas contenir plus de 20 livres differents
      IF r_row.rk = 0 THEN
        ln_run_id := NULL;
      END IF;
      
      GL_JOURNAL_IMPORT_PKG.populate_interface_control( user_je_source_name   => g_je_source_name,
                                                        group_id              => r_row.GROUP_ID,
                                                        set_of_books_id       => r_row.LEDGER_ID,
                                                        interface_run_id      => ln_run_id,
                                                        processed_data_action => gl_journal_import_pkg.SAVE_DATA
                                                        );      
    END LOOP;

    FOR gllezl in ( select  distinct interface_run_id, 
                                     case when gl.short_name like '%LEGAL'
                                          then 'TOUT_GL_LEG_ADMINISTRATEUR'
                                          else 'TOUT_GL_OPE_ADMINISTRATEUR'
                                     end name
                    from    gl_interface_control gic
                            join gl_ledgers gl
                              on gic.set_of_books_id = gl.ledger_id
                    where  je_source_name = (select je_source_name from gl_je_sources where user_je_source_name = g_je_source_name)
                 ) LOOP
   
      init_environement(gllezl.name);
          
      g_request_id:= fnd_request.submit_request(    
                              application   =>'SQLGL',
                              program       =>'GLLEZL',
                              description   => NULL,
                              sub_request   => FALSE,
                              argument1     => gllezl.interface_run_id,               --interface run id
                              argument2     => FND_PROFILE.VALUE('GL_ACCESS_SET_ID'), --data access set_id
                              argument3     => 'N',                                   --post to suspense
                              argument4     => NULL,                                  --from date
                              argument5     => NULL,                                  --to date
                              argument6     => 'N',                                   --summary mode
                              argument7     => 'O',                                   --import DFF                   
                              argument8     => 'Y'                                    --backward mode
                              );

      IF g_request_id = 0 THEN        
        pn_retcode := 2;
        pv_errbuf  := 'Erreur : Le traitement standard d''import des soldes gl s''est terminé en erreur.';
        dka_tools_pkg.put_outdebug_message( 'Erreur : Le traitement standard d''import des soldes gl s''est terminé en erreur.' || CHR(10) || 'PROGRAMME  : Importation des soldes gl');
      
      ELSE
        COMMIT;
        dka_tools_pkg.put_outdebug_message( 'Numéro du traitement standard d''import des soldes gl: ' || g_request_id);             
          
        --********************************************
        -- Wait for the concurrent program to complete
        --********************************************
        IF NOT (Fnd_Concurrent.wait_for_request (g_request_id, g_tempo, 0, v_phase, v_status, v_dev_phase, v_dev_status, v_message)) THEN      
          pv_errbuf  := v_message;
        END IF;
        
        dka_tools_pkg.put_outdebug_message(    'Statut de fin du traitement standard d''import des soldes gl: ' || v_phase || '/' || v_status);
        
        SELECT   count(*)
        INTO     v_nb_GL_Soldes_rejet
        FROM     gl_interface             
        WHERE    status NOT IN ('NEW', 'P', 'PROCESSED', 'CORRECTED')
        AND      request_id = g_request_id;
        
        DELETE FROM gl_interface
        WHERE   status = 'PROCESSED'
        AND     request_id = g_request_id;
        
        g_nb_GL_Soldes_cree := g_nb_GL_Soldes_cree + SQL%ROWCOUNT;
                                                        
        IF v_nb_GL_Soldes_rejet !=0 THEN 
      
          dka_tools_pkg.put_outdebug_message('-------------------------------------------------------------------------------------------------------------------------------------------------------');
          dka_tools_pkg.put_outdebug_message('---------------------------------------------REJETS LORS DU LANCEMENT DU TRAITEMENT EASYLINK LA TABLE TMP----------------------------------------------');
          dka_tools_pkg.put_outdebug_message('-------------------------------------------------------------------------------------------------------------------------------------------------------');
          dka_tools_pkg.put_outdebug_message(RPAD('CLE COMPTABLE',50,' ')||RPAD('ID DU LIVRE',20,' ')||RPAD('STATUT',40,' '));
          dka_tools_pkg.put_outdebug_message('-------------------------------------------------------------------------------------------------------------------------------------------------------');
          dka_tools_pkg.put_outdebug_message(chr(10));
          
          FOR rejections IN ( SELECT  ledger_id, segment1, segment2, segment3, segment4, segment5, segment6, segment7, segment8, segment9, segment10, segment11, segment12, date_created, created_by, status
                              FROM    gl_interface          
                              WHERE   gl_interface.status NOT IN ('NEW', 'P', 'PROCESSED', 'CORRECTED')
                              AND     request_id = g_request_id
                            )         
          LOOP   
            v_cle_comptable := rejections.segment1 || '.' || rejections.segment2 || '.' || rejections.segment3 || '.' || rejections.segment4 || '.' || 
                               rejections.segment5 || '.' || rejections.segment6 || '.' || rejections.segment7 || '.' || rejections.segment8 || '.' || 
                               rejections.segment9 || '.' || rejections.segment10 || '.' || rejections.segment11 || '.' || rejections.segment12;
                     
            dka_tools_pkg.put_outdebug_message(RPAD(v_cle_comptable,50,' ') || RPAD(rejections.ledger_id,20,' ') || RPAD(rejections.status,40,' '));
            dka_tools_pkg.put_outdebug_message('-------------------------------------------------------------------------------------------------------------------------------------------------------');             
          END LOOP;
          g_nb_GL_Soldes_rejet := g_nb_GL_Soldes_rejet+v_nb_GL_Soldes_rejet;
          pn_retcode    := 1;    
        END IF;
      END IF;
      
      COMMIT;      
    END LOOP;
    
    init_environement(NULL);
  END program_import_gl_soldes;
    
    /*
    *************************************************************************
    * PROCEDURE NAME : Bilan
    * 
    * DESCRIPTION
    *  Procédure de génération du bilan du traitement 
    *
    * PARAMETERS
    * ==========
    * NAME                 DESCRIPTION
    .* -------------------- -------------------------------------------------
    * pv_errbuf            Retour de message éventuel
    * pn_retcode           Statut du traitement en sortie
    ************************************************************************
  */
  PROCEDURE Report_Bilan( pv_errbuf            OUT VARCHAR2,
            pn_retcode           OUT NUMBER
            ) 
  IS
  BEGIN

    dka_tools_pkg.put_outdebug_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Debut Report_Bilan');

    --------------------    
    -- Initialisation --
    --------------------          

    pv_errbuf  := NULL;
    pn_retcode := 0;


    dka_tools_pkg.put_outdebug_message(CHR(10));
    dka_tools_pkg.put_outdebug_message('-----------------------------------------------------BILAN-------------------------------------------------------------------------');
    dka_tools_pkg.put_outdebug_message('-----------------------------------------------------------------------------------------------------------------------------------');
    dka_tools_pkg.put_outdebug_message('   . Nombre d''enregistrements chargés dans la table spécifique des soldes gl  : ' || TO_CHAR(g_nb_GL_Soldes_charger)||CHR(10));
    dka_tools_pkg.put_outdebug_message('   . Nombre d''enregistrements chargés dans l''OI                              : ' || TO_CHAR(g_nb_GL_Soldes_cree_oi)||CHR(10));
    dka_tools_pkg.put_outdebug_message(CHR(10));
    dka_tools_pkg.put_outdebug_message(' *Voir les sorties des traitements d''Open interface pour avoir plus de détails sur les enregistrements rejetés.');
    dka_tools_pkg.put_outdebug_message(CHR(10));
    dka_tools_pkg.put_outdebug_message('-----------------------------------------------------------------------------------------------------------------------------------');
    dka_tools_pkg.put_outdebug_message('   . Nombre d''enregistrements chargés dans la table des soldes GL             : ' || TO_CHAR(g_nb_GL_Soldes_cree)||CHR(10));
    dka_tools_pkg.put_outdebug_message('   . Nombre d''enregistrements non chargés dans la table des soldes GL (rejets): ' || TO_CHAR(g_nb_GL_Soldes_rejet)||CHR(10));
            
    dka_tools_pkg.put_outdebug_message(CHR(10));
    dka_tools_pkg.put_outdebug_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin Report_Bilan');  


  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode   := 2;
      pv_errbuf    := 'REPORT_BILAN : ' ||SQLERRM;
      dka_tools_pkg.put_log_message( pv_errbuf);
      dka_tools_pkg.put_outdebug_message(TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - Erreur : ' || 'Fin de la procédure Report_Bilan : EXCEPTION OTHERS ');
  END Report_Bilan;     
  
  /*=====================================================================================*/
  /* PROCEDURE NAME : main
  /* 
  /* DESCRIPTION
  /*  Procédure principale de l'interface de création des solde gl
  /*
  /* PARAMETERS
  /* ==========
  /* NAME              DESCRIPTION
  /* ----------------- ------------------------------------------------------
  /* pv_errbuf         Retour de message éventuel
  /* pn_retcode        Statut du traitement en sortie
  /*=====================================================================================*/

  PROCEDURE MAIN( pv_errbuf        IN OUT VARCHAR2,
                  pn_retcode       IN OUT NUMBER,
                  pv_chargement_f  IN VARCHAR2,
                  pv_chargement_oi IN VARCHAR2,
                  pv_lancement_oi  IN VARCHAR2,
                  pv_fichier       IN VARCHAR2 -- OBE
                 )
  IS

    -- ========== VARIABLES ==========
    v_package                    VARCHAR2(30)  := 'DKA_REPGLSOLDESIMP_PKG';
    v_nom_traitement             VARCHAR2(200) := 'Import des soldes GL';
    v_sqlerrm                    VARCHAR2(250) := NULL;
    v_procedure                  VARCHAR2(30)  := 'MAIN';
    v_message                    VARCHAR2(500);        
    v_errbuf                     VARCHAR2(2500);
    v_retcode                    NUMBER;
    v_exeption                   EXCEPTION;
    cv_loader                   VARCHAR2(30)  := 'DKA_REPGLSOLDESIMP_LOADER';
    
    --ld_date_fin_periode          DATE; --RBE artf2114527
  
  BEGIN
    ----------------------------------
    -- Début du Programme principal --
    ----------------------------------
        
    -- Initialisation des variables d'anomalies
    pn_retcode   := 0;
    pv_errbuf   := NULL;
    v_message   := 'Début procédure MAIN';
    g_reprise := 'DKA_REPGLSOLDESIMP'; --YWA artf2194932
    -- Entete fichier sortie        
    dka_tools_pkg.put_out_header;
    
    dka_tools_pkg.put_outdebug_message('Libelle du login OA '  || FND_GLOBAL.USER_NAME);
    dka_tools_pkg.put_outdebug_message('==========================================================================');

    ----------------------------------
    -- Initialisation des variables --
    ---------------------------------- 
    v_message   := 'Init';
    dka_tools_pkg.put_log_message( 'Initialisation des variables'); 
    
    Init;
        
    IF v_retcode = 2 THEN
        pv_errbuf  := v_errbuf;
        pn_retcode := v_retcode;
        RAISE v_exeption;
    END IF;       
            
    -----------------------------
    -- Chargement des fichiers --
    -----------------------------
    IF pv_chargement_f ='Y' THEN
      dka_tools_pkg.put_log_message('/*============================================================================================*/');
      dka_tools_pkg.put_log_message('/* Chargement des fichiers plats */');
      dka_tools_pkg.put_log_message('/*============================================================================================*/');
      v_message   := 'PHASE DE CHARGEMENT DU FICHIER';     

      -- JPE ARTIFACT artf1983364 : RUN1 -Reprise GL - Suppression table temporaire 
      --DELETE FROM DKA_GL_REPSOLDE_TMP;

      -- Lancement du programme de chargement des fichiers
      --Launch_Loader(v_errbuf, v_retcode, 'DKA_REP_GL_SOLDES_DKA_LEGAL.txt');
      --Launch_Loader(v_errbuf, v_retcode, 'DKA_REP_GL_SOLDES_DAOPCCF.txt');
      --Launch_Loader(v_errbuf, v_retcode, 'DKA_GL_DETAIL_DKA_LEGAL.txt'); -- OBE 
      --Launch_Loader(v_errbuf, v_retcode, 'DKA_GL_DETAIL_DAOPCCF.txt');   -- OBE 
      Launch_Loader(v_errbuf, v_retcode,cv_loader, pv_fichier); -- OBE -- YWA artf2194932 
          
      IF v_retcode = 2 THEN
        pv_errbuf  := v_errbuf;
        pn_retcode := v_retcode;
        dka_tools_pkg.put_outdebug_message('Erreur de chargement des fichiers');
        RAISE v_exeption;
      END IF;
     
      dka_tools_pkg.put_log_message('Fin chargement des fichiers plats avec succès');
    ELSE
      SELECT  MAX(LOAD_REQUEST_ID)
      INTO    g_loader_request_id
      FROM    DKA_GL_REPSOLDE_TMP;
    END IF;        
          
    -------------------------------------------------------------------------------------------
    -- Insertion dans les tables open interface et lancement du traitement standard easylink --
    -------------------------------------------------------------------------------------------
    IF pv_chargement_oi ='Y' THEN
                       
      -- Chargement des tables open interface
      dka_tools_pkg.put_log_message('/*============================================================================================*/');
      dka_tools_pkg.put_log_message('/*Insertion dans les opens interfaces*/');
      dka_tools_pkg.put_log_message('/*============================================================================================*/');

      -----------------------------
      -- Contrôle des données
      -----------------------------        
      Control_Data(v_errbuf, v_retcode);
      
      IF v_retcode = 2 THEN
        pv_errbuf  := v_errbuf;
        pn_retcode := v_retcode;
        RAISE v_exeption;
      END IF;

      /* --RBE artf2114527
      DECLARE
        lv_period varchar2(10);
      BEGIN
        SELECT  PERIODE 
        INTO    lv_period
        FROM    DKA_GL_REPSOLDE_TMP 
        WHERE   LOAD_REQUEST_ID = g_loader_request_id  
        AND ROWNUM = 1; 
      
        SELECT  END_DATE
        INTO    ld_date_fin_periode
        FROM    GL_PERIODS
        WHERE   PERIOD_NAME = lv_period
        AND     PERIOD_SET_NAME = 'GROUPE';
      EXCEPTION
        WHEN OTHERS THEN
        dka_tools_pkg.put_outdebug_message('Erreur lors de la recherche de la date de fin de période : '||lv_period);
        dka_tools_pkg.put_log_message('Cause:' || SQLERRM);
        g_message_erreur_chargement := substr(SQLERRM,0,500);
        RAISE v_exeption;
      END;  
     */      

      insert_open_interface(v_errbuf, v_retcode); --, ld_date_fin_periode); --RBE artf2114527
      
      IF v_retcode = 2 THEN
        pv_errbuf  := v_errbuf;
        pn_retcode := v_retcode;
        RAISE v_exeption;
      ELSE
        COMMIT;
        dka_tools_pkg.put_log_message('Chargement des tables open interface terminé avec succès');
                
      END IF;    
    END IF;

    -------------------------------------------------------------------------------------------
    -- Insertion dans les tables open interface et lancement du traitement standard easylink --
    -------------------------------------------------------------------------------------------
    IF pv_lancement_oi ='Y' THEN
      -- 20/06/2017 NBO artf2179288 : REP013 - Reprise des soldes GL RUN4 BIS
      dbms_stats.gather_schema_stats(ownname => 'GL', estimate_percent => dbms_stats.auto_sample_size, cascade => true, degree => 8) ;
    
      -- Lancement du traitement standard Easylink
      dka_tools_pkg.put_log_message('/*============================================================================================*/');
      dka_tools_pkg.put_log_message('/*Lancement du traitement standard Easylink*/');
      dka_tools_pkg.put_log_message('/*============================================================================================*/');            
                
      program_import_gl_soldes(v_errbuf, v_retcode);

      IF v_retcode = 2 THEN
        pv_errbuf  := v_errbuf;
        pn_retcode := v_retcode;
        RAISE v_exeption;
      END IF;   
      
      dka_tools_pkg.put_log_message('Traitement stantard Easylink des tables open interface gl terminé avec succès');            
    END IF;
 
    ----------------------------------
    -- Phase de bilan du traitement --
    ----------------------------------
    Report_Bilan(v_errbuf,v_retcode); 

    IF v_retcode = 2 THEN
      pv_errbuf  := v_errbuf;
      pn_retcode := v_retcode;
      RAISE v_exeption;
    END IF;
  
    COMMIT; 

    dka_tools_pkg.put_log_message( pv_errbuf);
    dka_tools_pkg.put_log_message( CHR(10)||pv_errbuf||CHR(10));
    dka_tools_pkg.put_log_message('==========================================================================');
    dka_tools_pkg.put_log_message('Programme principale terminé.');

  ----------------------------
  -- Gestion des exceptions --
  ----------------------------
  EXCEPTION
    WHEN v_exeption THEN
      dka_tools_pkg.put_log_message('-------------------- ERREUR --------------------');
      dka_tools_pkg.put_log_message('Package   : '||v_package);
      dka_tools_pkg.put_log_message('Procédure : '||v_procedure);
      dka_tools_pkg.put_log_message('Exception : OTHERS');
      dka_tools_pkg.put_log_message('Erreur     : '||pv_errbuf);
      dka_tools_pkg.put_log_message('------------------------------------------------');
      dka_tools_pkg.put_log_message('Fin de la procédure '||v_procedure||' : EXCEPTION v_exeption');        
      dka_tools_pkg.put_log_message('=========================================================================');
      dka_tools_pkg.put_outdebug_message('Traitement '||v_nom_traitement||' terminé en erreur.');
      ROLLBACK;

    WHEN OTHERS THEN
      v_sqlerrm := SUBSTR(SQLERRM,1,200);
      pn_retcode := 2;
      pv_errbuf  := 'Erreur technique sur le composant dans pkg.proc/fonc '||v_package||'.'||v_procedure;
      dka_tools_pkg.put_log_message('-------------------- ERREUR --------------------');
      dka_tools_pkg.put_log_message('Package   : '||v_package);
      dka_tools_pkg.put_log_message('Procédure : '||v_procedure);
      dka_tools_pkg.put_log_message('Exception : OTHERS');
      dka_tools_pkg.put_log_message('Message   : '||v_message);
      dka_tools_pkg.put_log_message(pv_errbuf);  
      dka_tools_pkg.put_log_message('Cause     : '||v_sqlerrm);
      dka_tools_pkg.put_log_message('------------------------------------------------');
      dka_tools_pkg.put_outdebug_message('Traitement '||v_nom_traitement||' terminé en erreur         ');
      dka_tools_pkg.put_log_message('=========================================================================');
      ROLLBACK;
 
  END main; 
    
    
    
    /*=====================================================================================*/
    /* PROCEDURE NAME : main
    /* 
    /* DESCRIPTION
    /*  Procédure principale de l'interface de création des
    /*
    /* PARAMETERS
    /* ==========
    /* NAME              DESCRIPTION
    /* ----------------- ------------------------------------------------------
    /* pv_errbuf         Retour de message éventuel
    /* pn_retcode        Statut du traitement en sortie
    /*=====================================================================================*/
    
    PROCEDURE MAIN2( pv_errbuf        IN OUT VARCHAR2,
                  pn_retcode       IN OUT NUMBER,
                  pv_chargement_f  IN VARCHAR2,
                  pv_chargement_oi IN VARCHAR2,
                  pv_lancement_oi  IN VARCHAR2,
                  pv_fichier       IN VARCHAR2 
                 )
    IS

        -- ========== VARIABLES ==========
        v_package                    VARCHAR2(30)  := 'DKA_REPGLSOLDESIMP_PKG';
        v_nom_traitement             VARCHAR2(200) := 'DKA : Reprise des pièces en contrepassation automatique';
        v_sqlerrm                    VARCHAR2(250) := NULL;
        v_procedure                  VARCHAR2(30)  := 'MAIN2';
        v_message                    VARCHAR2(500);        
        v_errbuf                     VARCHAR2(2500);
        v_retcode                    NUMBER;
        v_exeption                   EXCEPTION;
        cv_loader                   VARCHAR2(30)  := 'DKA_REPGLCONTREPA_LOADER';
                
    BEGIN
        ----------------------------------
        -- Début du Programme principal --
        ----------------------------------
         
        -- Initialisation des variables d'anomalies
        g_reprise := 'DKA_REPGLCONTREPA';
        pn_retcode   := 0;
        pv_errbuf   := NULL;
        v_message   := 'Début procédure MAIN2';

        -- Entete fichier sortie        
        dka_tools_pkg.put_out_header;

        dka_tools_pkg.put_outdebug_message('Libelle du login OA '  || FND_GLOBAL.USER_NAME);
        dka_tools_pkg.put_outdebug_message('==========================================================================');

        ----------------------------------
        -- Initialisation des variables --
        ---------------------------------- 
        v_message   := 'Init';
        dka_tools_pkg.put_log_message( 'Initialisation des variables'); 

        Init;
            
        IF v_retcode = 2 THEN
            pv_errbuf  := v_errbuf;
            pn_retcode := v_retcode;
            RAISE v_exeption;
        END IF;       
                
        -----------------------------
        -- Chargement des fichiers --
        -----------------------------
        IF pv_chargement_f ='Y' THEN
          dka_tools_pkg.put_log_message('/*============================================================================================*/');
          dka_tools_pkg.put_log_message('/* Chargement des fichiers plats */');
          dka_tools_pkg.put_log_message('/*============================================================================================*/');
          v_message   := 'PHASE DE CHARGEMENT DU FICHIER';     

          Launch_Loader(v_errbuf, v_retcode,cv_loader, pv_fichier); 
              
          IF v_retcode = 2 THEN
            pv_errbuf  := v_errbuf;
            pn_retcode := v_retcode;
            dka_tools_pkg.put_outdebug_message('Erreur de chargement des fichiers');
            RAISE v_exeption;
          END IF;
         
          dka_tools_pkg.put_log_message('Fin chargement des fichiers plats avec succès');
        ELSE
          SELECT  MAX(LOAD_REQUEST_ID)
          INTO    g_loader_request_id
          FROM    DKA_GL_CONTREPASSATION_TMP;
        END IF;        
              
        -------------------------------------------------------------------------------------------
        -- Insertion dans les tables open interface et lancement du traitement standard easylink --
        -------------------------------------------------------------------------------------------
        IF pv_chargement_oi ='Y' THEN
          
          v_message   := 'Chargement dans l''open interface';  
                        
          -- Chargement des tables open interface
          dka_tools_pkg.put_log_message('/*============================================================================================*/');
          dka_tools_pkg.put_log_message('/*Insertion dans les opens interfaces*/');
          dka_tools_pkg.put_log_message('/*============================================================================================*/');

          -----------------------------
          -- Contrôle des données
          -----------------------------  
          
          v_message   := 'Control_Data';     
          Control_Data(v_errbuf, v_retcode);
          v_message   := 'Control_Data OK';
          
          IF v_retcode = 2 THEN
            pv_errbuf  := v_errbuf;
            pn_retcode := v_retcode;
            RAISE v_exeption;
          END IF;    

          v_message   := 'Insert_open_interface';
          insert_open_interface(v_errbuf, v_retcode); 
          v_message   := 'Insert_open_interface OK';
          
          IF v_retcode = 2 THEN
            pv_errbuf  := v_errbuf;
            pn_retcode := v_retcode;
            RAISE v_exeption;
          ELSE
            COMMIT;
            dka_tools_pkg.put_log_message('Chargement des tables open interface terminé avec succès');
                    
          END IF;    
        END IF;

        -------------------------------------------------------------------------------------------
        -- Insertion dans les tables open interface et lancement du traitement standard easylink --
        -------------------------------------------------------------------------------------------
        IF pv_lancement_oi ='Y' THEN
          
          v_message   := 'Stats GL';
          dbms_stats.gather_schema_stats(ownname => 'GL', estimate_percent => dbms_stats.auto_sample_size, cascade => true, degree => 8) ;
          v_message   := 'Stats GL OK';

          -- Lancement du traitement standard Easylink
          dka_tools_pkg.put_log_message('/*============================================================================================*/');
          dka_tools_pkg.put_log_message('/*Lancement du traitement standard Easylink*/');
          dka_tools_pkg.put_log_message('/*============================================================================================*/');            
          
          v_message   := 'Program_import_gl_soldes';         
          program_import_gl_soldes(v_errbuf, v_retcode);
          v_message   := 'Program_import_gl_soldes OK';
          
          IF v_retcode = 2 THEN
            pv_errbuf  := v_errbuf;
            pn_retcode := v_retcode;
            RAISE v_exeption;
          END IF;   
          
          dka_tools_pkg.put_log_message('Traitement stantard Easylink des tables open interface gl terminé avec succès');            
        END IF;

        ----------------------------------
        -- Phase de bilan du traitement --
        ----------------------------------
        Report_Bilan(v_errbuf,v_retcode); 

        IF v_retcode = 2 THEN
          pv_errbuf  := v_errbuf;
          pn_retcode := v_retcode;
          RAISE v_exeption;
        END IF;

        COMMIT; 

        dka_tools_pkg.put_log_message( pv_errbuf);
        dka_tools_pkg.put_log_message( CHR(10)||pv_errbuf||CHR(10));
        dka_tools_pkg.put_log_message('==========================================================================');
        dka_tools_pkg.put_log_message('Programme principale terminé.');

        ----------------------------
        -- Gestion des exceptions --
        ----------------------------
    EXCEPTION
    WHEN v_exeption THEN
      dka_tools_pkg.put_log_message('-------------------- ERREUR --------------------');
      dka_tools_pkg.put_log_message('Package   : '||v_package);
      dka_tools_pkg.put_log_message('Procédure : '||v_procedure);
      dka_tools_pkg.put_log_message('Exception : v_exeption');
      dka_tools_pkg.put_log_message('Erreur     : '||pv_errbuf);
      dka_tools_pkg.put_log_message('------------------------------------------------');
      dka_tools_pkg.put_log_message('Fin de la procédure '||v_procedure||' : EXCEPTION v_exeption');        
      dka_tools_pkg.put_log_message('=========================================================================');
      dka_tools_pkg.put_outdebug_message('Traitement '||v_nom_traitement||' terminé en erreur.');
      ROLLBACK;

    WHEN OTHERS THEN
      v_sqlerrm := SUBSTR(SQLERRM,1,200);
      pn_retcode := 2;
      pv_errbuf  := 'Erreur technique sur le composant dans pkg.proc/fonc '||v_package||'.'||v_procedure;
      dka_tools_pkg.put_log_message('-------------------- ERREUR --------------------');
      dka_tools_pkg.put_log_message('Package   : '||v_package);
      dka_tools_pkg.put_log_message('Procédure : '||v_procedure);
      dka_tools_pkg.put_log_message('Exception : OTHERS');
      dka_tools_pkg.put_log_message('Message   : '||v_message);
      dka_tools_pkg.put_log_message(pv_errbuf);  
      dka_tools_pkg.put_log_message('Cause     : '||v_sqlerrm);
      dka_tools_pkg.put_log_message('------------------------------------------------');
      dka_tools_pkg.put_outdebug_message('Traitement '||v_nom_traitement||' terminé en erreur         ');
      dka_tools_pkg.put_log_message('=========================================================================');
      ROLLBACK;

    END main2;

END DKA_REPGLSOLDESIMP_PKG;
/
SHOW ERRORS;
EXIT
