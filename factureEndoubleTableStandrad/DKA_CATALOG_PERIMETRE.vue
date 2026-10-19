CREATE OR REPLACE PACKAGE BODY DKA_SPOCLOSCOM_PKG AS

  ----------------------------------------------------------------------------
  -- $$
  -- CAPGEMINI
  -- PROJET            : DALKIA Oracle Applications
  -- NOM               : DKA_SPOCLOSCOM_PKG.pkb
  -- DESCRIPTION       : DKA_SPOCLOSCOM_PKG package body
  ---
  --- AUTEUR           : C. Delcasso
  --- DATE DE CREATION : 04/05/2009
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
  ----------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- ---------- --- ---------------------------------------------------------
  --- 12/09/2016 MEG Migration R12
  ----------------------------------------------------------------------------

  gn_user_id              fnd_user.user_id%TYPE;
  gn_login_id             fnd_logins.login_id%TYPE;
  gn_request_id           fnd_concurrent_requests.request_id%TYPE;
  gd_date_seuil           DATE;
  gn_nbre_mois            NUMBER;
  gv_status_closed        po_headers_all.closed_code%TYPE;
  gv_type_lookup_code     po_headers_all.type_lookup_code%TYPE;
  gv_message_proj_ferme   po_lines_all.closed_reason%TYPE;
  gv_message_cde_ancienne po_lines_all.closed_reason%TYPE;

  ----------------------------------------------------------------------------
  --  Nom           : init
  --  Description   : Procédure d'initialisation
  --
  --PARAMETRES :
  --  pv_errbuf   Entrée/Sortie          message d'erreur
  --  VALEUR RETOURNEE :  pn_retcode
  --Valeurs possibles : 0=normal, 1=warning, 2=erreur
  ----------------------------------------------------------------------------
  PROCEDURE init(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER) IS
    v_data dka_parameters%ROWTYPE;
  
  BEGIN
    dka_tools_pkg.put_debug_message('(+) Init');
    pv_errbuf  := NULL;
    pn_retcode := 0;
  
    -- En-tête du fichier de sortie
    dka_tools_pkg.put_out_header;
  
    -- Variables globale "WHO"
    gn_user_id    := fnd_global.user_id;
    gn_login_id   := fnd_global.login_id;
    gn_request_id := fnd_global.conc_request_id;
  
    -- Variables MAJ des Commandes
    gv_status_closed    := 'FINALLY CLOSED';
    gv_type_lookup_code := 'STANDARD';
  
    -- Récupération dans DKA_PARAMETERS du message de fermeture des lignes sur projet fermé --
    Dka_Tools_Pkg.get_parameter('SPOCLOSCOM',
                                'MESSAGE_PROJET_FERME',
                                v_data,
                                pn_retcode,
                                pv_errbuf);
  
    IF pn_retcode != 0 THEN
      pn_retcode := 1;
      pv_errbuf  := 'Le message à utiliser sur les fermetures de lignes sur projet fermé n''a pas été déterminé';
      Dka_Tools_Pkg.put_debug_message(pv_errbuf);
      RETURN;
    ELSE
      gv_message_proj_ferme := v_data.varchar2_value;
      Dka_Tools_Pkg.put_debug_message('Message fermeture projet fermé ==>' ||
                                      gv_message_proj_ferme);
    END IF;
  
    SELECT add_months(SYSDATE, -gn_nbre_mois) INTO gd_date_seuil FROM dual;
  
    -- Récupération dans DKA_PARAMETERS du message de fermeture des lignes sur projet fermé --
    Dka_Tools_Pkg.get_parameter('SPOCLOSCOM',
                                'MESSAGE_COMMANDE_ANCIENNE',
                                v_data,
                                pn_retcode,
                                pv_errbuf);
  
    IF pn_retcode != 0 THEN
      pn_retcode := 1;
      pv_errbuf  := 'Le message à utiliser sur les fermetures de lignes anciennes n''a pas été déterminé';
      Dka_Tools_Pkg.put_debug_message(pv_errbuf);
      RETURN;
    ELSE
      gv_message_cde_ancienne := v_data.varchar2_value;
      Dka_Tools_Pkg.put_debug_message('Message fermeture ligne commande ancienne ==>' ||
                                      gv_message_cde_ancienne);
    END IF;
  
    gv_message_cde_ancienne := gv_message_cde_ancienne || ' ' ||
                               to_char(gd_date_seuil, 'DD/MM/RRRR');
  
    dka_tools_pkg.put_debug_message('(-) Init');
  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf  := 'INIT : ' || SQLERRM;
  END init;

  -------------------------------------------------------------------------------------
  --  Nom           : Cloture_ligne_livraison
  --  Description   :
  --
  --  PARAMETRES    :
  --    pv_errbuf       Sortie
  --    pv_retcode          Sortie

  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: OK, 2: erreur ou code erreur ORA
  ------------------------------------------------------------------------------------
  PROCEDURE Cloture_ligne_livraison(pn_po_line_id    IN NUMBER,
                                    pv_closed_reason IN VARCHAR2,
                                    pv_uo            IN VARCHAR2,
                                    pv_errbuf        OUT VARCHAR2,
                                    pn_retcode       OUT NUMBER) IS
  BEGIN
  
    dka_tools_pkg.put_debug_message('(+) Cloture_ligne_livraison');
  
    ----- Initialisation des variables de sortie de la procédure -----
    pv_errbuf  := NULL;
    pn_retcode := 0;
  
    UPDATE po_line_locations pll
       SET closed_code          = gv_status_closed,
           closed_date          = trunc(sysdate),
		   SHIPMENT_CLOSED_DATE = trunc(sysdate), --SNK artf07230322 26/03/2019
           closed_by            = gn_user_id,
           closed_reason        = pv_closed_reason,
           last_update_date     = sysdate,
           last_updated_by      = gn_user_id
     WHERE po_line_id = pn_po_line_id
       AND closed_date is null
	   AND SHIPMENT_CLOSED_DATE IS NULL --SNK artf07230322 26/03/2019
       AND EXISTS
     (SELECT 'X'
              FROM gl_code_combinations gcc, po_distributions_all pda
             WHERE pll.line_location_id = pda.line_location_id
               AND pda.code_combination_id = gcc.code_combination_id
               AND gcc.segment2 = pv_uo);
    dka_tools_pkg.put_debug_message('(-) Cloture_ligne_livraison');
  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf  := 'Cloture_ligne_commande : ' || SQLERRM;
  END Cloture_ligne_livraison;

  -------------------------------------------------------------------------------------
  --  Nom           : Cloture_ligne_commande
  --  Description   :
  --
  --  PARAMETRES    :
  --    pv_errbuf       Sortie
  --    pv_retcode          Sortie

  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: OK, 2: erreur ou code erreur ORA
  ------------------------------------------------------------------------------------
  PROCEDURE Cloture_ligne_commande(pn_po_line_id    IN NUMBER,
                                   pv_closed_reason IN VARCHAR2,
                                   pv_errbuf        OUT VARCHAR2,
                                   pn_retcode       OUT NUMBER) IS
  BEGIN
  
    dka_tools_pkg.put_debug_message('(+) Cloture_ligne_commande');
  
    ----- Initialisation des variables de sortie de la procédure -----
    pv_errbuf  := NULL;
    pn_retcode := 0;
  
    Dka_Tools_Pkg.put_debug_message('Fermeture ligne livraison');
  
    UPDATE po_line_locations pll
       SET closed_code          = gv_status_closed,
           closed_date          = trunc(sysdate),
		   SHIPMENT_CLOSED_DATE = trunc(sysdate), --SNK artf07230322 26/03/2019
           closed_by            = gn_user_id,
           closed_reason        = pv_closed_reason,
           last_update_date     = sysdate,
           last_updated_by      = gn_user_id
     WHERE po_line_id = pn_po_line_id
       AND closed_date is null
	   AND SHIPMENT_CLOSED_DATE IS NULL --SNK artf07230322 26/03/2019
    /*AND EXISTS (SELECT 'X'
                                       FROM gl_code_combinations gcc,
                                            po_distributions_all pda
                                       WHERE pll.line_location_id = pda.line_location_id
                                       AND   pda.code_combination_id = gcc.code_combination_id
                                       AND   gcc.segment2 = pv_uo)*/
    ;
  
    Dka_Tools_Pkg.put_debug_message('Fermeture ligne commande');
  
    UPDATE po_lines
       SET closed_code      = gv_status_closed,
           closed_date      = trunc(sysdate),
           closed_by        = gn_user_id,
           closed_reason    = pv_closed_reason,
           last_update_date = sysdate,
           last_updated_by  = gn_user_id
     WHERE po_line_id = pn_po_line_id
       AND closed_date is null;
  
    dka_tools_pkg.put_debug_message('Fermeture de la ligne de commande : ' ||
                                    pn_po_line_id);
  
    dka_tools_pkg.put_debug_message('(-) Cloture_ligne_commande');
  
  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf  := 'Cloture_ligne_commande : ' || SQLERRM;
  END Cloture_ligne_commande;

  -------------------------------------------------------------------------------------
  --  Nom           : Cloture_entete_commande
  --  Description   :
  --
  --  PARAMETRES    :
  --    pv_errbuf       Sortie
  --    pv_retcode          Sortie

  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: OK, 2: erreur ou code erreur ORA
  ------------------------------------------------------------------------------------
  PROCEDURE Cloture_entete_commande(pn_po_header_id IN NUMBER,
                                    pv_errbuf       OUT VARCHAR2,
                                    pn_retcode      OUT NUMBER) IS
  BEGIN
  
    dka_tools_pkg.put_debug_message('(+) Cloture_entete_commande');
  
    ----- Initialisation des variables de sortie de la procédure -----
    pv_errbuf  := NULL;
    pn_retcode := 0;
    Dka_Tools_Pkg.put_debug_message('Fermeture de commande');
  
    UPDATE po_headers
       SET closed_code      = gv_status_closed,
           closed_date      = trunc(sysdate),
           last_update_date = sysdate,
           last_updated_by  = gn_user_id,
           attribute9       = NULL
     WHERE po_header_id = pn_po_header_id
       AND closed_date is null;
  
    dka_tools_pkg.put_debug_message('Fermeture de la commande : ' ||
                                    pn_po_header_id);
  
    dka_tools_pkg.put_debug_message('(-) Cloture_entete_commande');
  
  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf  := 'Cloture_entete_commande : ' || SQLERRM;
  END Cloture_entete_commande;

  --------------------------------------------------------------------------------------
  --  Nom           : lancement_par_region
  --  Description   : Procédure permettant le lacement région par région de la fermeture
  --                  des commandes.
  --
  --  PARAMETRES :
  --    pv_errbuf                   Entrée/Sortie       retour de message eventuel
  --    pn_retcode                  Sortie          status du traitement en sortie
  --
  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: normal, 1: warning, 2: erreur
  --
  ----------------------------------------------------------------------------------------

  PROCEDURE lancement_par_region(pv_errbuf  IN OUT VARCHAR2,
                                 pn_retcode OUT NUMBER
                                 
                                 ) IS
  
    cv_prog_name CONSTANT VARCHAR2(30) := 'DKA_SPOCLOSCOM_PR';
    cn_tempo     CONSTANT NUMBER := 20;
    vv_errbuf                      VARCHAR2(500) := NULL;
    vn_retcode                     NUMBER := 0;
    vn_prog_application_id         NUMBER(15);
    vv_prog_application_short_name VARCHAR2(50);
    vn_program_id                  NUMBER(15);
    vn_responsibility_id           NUMBER(15);
    vn_application_id              NUMBER(15);
    vn_user_id                     NUMBER(15);
    vn_request_id                  NUMBER(15);
    vv_rphase                      VARCHAR2(80);
    vv_rstatus                     VARCHAR2(80);
    vv_dphase                      VARCHAR2(30);
    vv_dstatus                     VARCHAR2(30);
    vv_message                     VARCHAR2(240);
    vn_trt_a_lancer                NUMBER := 0;
    vn_trt_lances                  NUMBER := 0;
    vn_trt_normal                  NUMBER := 0;
    vn_trt_erreur                  NUMBER := 0;
    vn_trt_warning                 NUMBER := 0;
    vn_traitement                  NUMBER := 0;
  
    TYPE myrecord IS RECORD(
      request_id NUMBER);
  
    TYPE mytable IS TABLE OF myrecord INDEX BY BINARY_INTEGER;
  
    vt_traitement mytable;
    -----------------------------------------------------------
    -- RG 6.15 RG 6.16 - Curseur de sélection des régions. --
    -----------------------------------------------------------
    CURSOR cur_csp IS
      SELECT ffv.flex_value REGION
        FROM fnd_flex_value_sets ffvs, fnd_flex_values ffv
       WHERE ffvs.flex_value_set_id = ffv.flex_value_set_id
         AND ffvs.flex_value_set_name = 'DAOPCCF_UO'
         /*and (ffvs.flex_value_set_name = 'DAOPCCF_REGION' OR
             ffvs.flex_value_set_name = 'VTOPCCF_REGION')*/
         AND flex_value NOT IN ('T', 'YYY')
         AND SYSDATE BETWEEN NVL(ffv.start_date_active, SYSDATE) AND
             NVL(ffv.end_date_active, SYSDATE)
         AND ffv.attribute1 = 'OUI';
  BEGIN
    --------------------------------------------------
    -- Parcours de l'ensemble des régions valident. --
    --------------------------------------------------
    FOR rec_csp IN cur_csp LOOP
    
      --------------------------------------------------------------------------
      -- Recherche des identifiants de la responsabilité et de l'application. --
      --------------------------------------------------------------------------
      Dka_Tools_Pkg.put_outdebug_message('Recuperation des identifiants user');
      
      SELECT fr.responsibility_id, fr.application_id
        INTO vn_responsibility_id, vn_application_id
        FROM fnd_responsibility fr
       WHERE responsibility_key =
             'DKA PO ' || rec_csp.REGION || ' FERMETURE DEF COM'
          /*OR responsibility_key =
             'VT PO ' || rec_csp.REGION || ' APPROVISIONNEUR'*/;
    
      ----------------------------------------------------------------
      -- Recherche de l'identifiant de l'utilisateur de la région. --
      ----------------------------------------------------------------
      SELECT user_id
        INTO vn_user_id
        FROM fnd_user
       WHERE user_name = rec_csp.REGION;
    
      ----------------------------------------------
      -- Recherche de l'identifiant du programme. --
      ----------------------------------------------
      Dka_Tools_Pkg.put_outdebug_message('Recuperation des identifiants programme');
      SELECT fcp.application_id,
             fa.application_short_name,
             fcp.concurrent_program_id
        INTO vn_prog_application_id,
             vv_prog_application_short_name,
             vn_program_id
        FROM fnd_concurrent_programs fcp, fnd_application fa
       WHERE fcp.concurrent_program_name = cv_prog_name
         AND fa.application_id = fcp.application_id;
    
      --------------------------------------------------------------------------------------------------------------------
      -- Initialisation du contexte en fonction des identifiant de la responsabilité, de l'application et du programme. --
      --------------------------------------------------------------------------------------------------------------------
      Dka_Tools_Pkg.put_outdebug_message('Initialisation dans le contexte OA');
      
      fnd_global.apps_initialize(vn_user_id,
                                 vn_responsibility_id,
                                 vn_application_id);
      MO_GLOBAL.INIT('PO'); 
      
      -------------------------------------------------------------------------------------
      -- Modification de la langue DB par la valeur de l'option de profile ICX_LANGUAGE. --
      -------------------------------------------------------------------------------------
      EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE=''' ||
                        fnd_profile.value('ICX_LANGUAGE') || '''';
    
      ---------------------------------
      -- Récupération des paramètres. --
      ---------------------------------
      Dka_Tools_Pkg.put_outdebug_message('Recuperation des parametres');
      dka_tools_pkg.get_request_set_params(pv_errbuf                 => vv_errbuf,
                                           pn_retcode                => vn_retcode,
                                           pn_application_id         => NULL,
                                           pn_request_set_id         => NULL,
                                           pn_request_set_program_id => NULL,
                                           pn_prog_application_id    => vn_prog_application_id,
                                           pn_program_id             => vn_program_id);
    
      IF vn_retcode != 0 THEN
        Dka_Tools_Pkg.put_outdebug_message('Impossible de récupérer les paramètres :');
        Dka_Tools_Pkg.put_outdebug_message(vv_errbuf);
        pn_retcode := 2;
        RETURN;
      END IF;
    
      -------------------------------
      -- Soumission du traitement (procédure stockée PL/SQL [DKA_SPOCLOSCOM_PKG.main]). --
      -------------------------------
      Dka_Tools_Pkg.put_outdebug_message('Soumission du traitement');
      vn_request_id := fnd_request.submit_request(vv_prog_application_short_name, --APPLICATION PROPRIETAIRE DU TRAITEMENT
                                                  cv_prog_name, --SHORT_NAME du TRAITEMENT
                                                  NULL, --PROGRAM_NAME
                                                  NULL, --START
                                                  FALSE, --SUB_REQUEST
                                                  dka_tools_pkg.tab_request_params(1), --ARGUMENT1
                                                  rec_csp.REGION, --ARGUMENT2
                                                  dka_tools_pkg.tab_request_params(3), --ARGUMENT3
                                                  dka_tools_pkg.tab_request_params(4), --ARGUMENT4
                                                  dka_tools_pkg.tab_request_params(5), --ARGUMENT5
                                                  dka_tools_pkg.tab_request_params(6), --ARGUMENT6
                                                  dka_tools_pkg.tab_request_params(7), --ARGUMENT7
                                                  dka_tools_pkg.tab_request_params(8), --ARGUMENT8
                                                  dka_tools_pkg.tab_request_params(9), --ARGUMENT9
                                                  dka_tools_pkg.tab_request_params(10), --ARGUMENT10
                                                  dka_tools_pkg.tab_request_params(11), --ARGUMENT11
                                                  dka_tools_pkg.tab_request_params(12), --ARGUMENT12
                                                  dka_tools_pkg.tab_request_params(13), --ARGUMENT13
                                                  dka_tools_pkg.tab_request_params(14), --ARGUMENT14
                                                  dka_tools_pkg.tab_request_params(15), --ARGUMENT15
                                                  dka_tools_pkg.tab_request_params(16), --ARGUMENT16
                                                  dka_tools_pkg.tab_request_params(17), --ARGUMENT17
                                                  dka_tools_pkg.tab_request_params(18), --ARGUMENT18
                                                  dka_tools_pkg.tab_request_params(19), --ARGUMENT19
                                                  dka_tools_pkg.tab_request_params(20), --ARGUMENT20
                                                  dka_tools_pkg.tab_request_params(21), --ARGUMENT21
                                                  dka_tools_pkg.tab_request_params(22), --ARGUMENT22
                                                  dka_tools_pkg.tab_request_params(23), --ARGUMENT23
                                                  dka_tools_pkg.tab_request_params(24), --ARGUMENT24
                                                  dka_tools_pkg.tab_request_params(25), --ARGUMENT25
                                                  dka_tools_pkg.tab_request_params(26), --ARGUMENT26
                                                  dka_tools_pkg.tab_request_params(27), --ARGUMENT27
                                                  dka_tools_pkg.tab_request_params(28), --ARGUMENT28
                                                  dka_tools_pkg.tab_request_params(29), --ARGUMENT29
                                                  dka_tools_pkg.tab_request_params(30), --ARGUMENT30
                                                  dka_tools_pkg.tab_request_params(31), --ARGUMENT31
                                                  dka_tools_pkg.tab_request_params(32), --ARGUMENT32
                                                  dka_tools_pkg.tab_request_params(33), --ARGUMENT33
                                                  dka_tools_pkg.tab_request_params(34), --ARGUMENT34
                                                  dka_tools_pkg.tab_request_params(35), --ARGUMENT35
                                                  dka_tools_pkg.tab_request_params(36), --ARGUMENT36
                                                  dka_tools_pkg.tab_request_params(37), --ARGUMENT37
                                                  dka_tools_pkg.tab_request_params(38), --ARGUMENT38
                                                  dka_tools_pkg.tab_request_params(39), --ARGUMENT39
                                                  dka_tools_pkg.tab_request_params(40), --ARGUMENT40
                                                  dka_tools_pkg.tab_request_params(41), --ARGUMENT41
                                                  dka_tools_pkg.tab_request_params(42), --ARGUMENT42
                                                  dka_tools_pkg.tab_request_params(43), --ARGUMENT43
                                                  dka_tools_pkg.tab_request_params(44), --ARGUMENT44
                                                  dka_tools_pkg.tab_request_params(45), --ARGUMENT45
                                                  dka_tools_pkg.tab_request_params(46), --ARGUMENT46
                                                  dka_tools_pkg.tab_request_params(47), --ARGUMENT47
                                                  dka_tools_pkg.tab_request_params(48), --ARGUMENT48
                                                  dka_tools_pkg.tab_request_params(49), --ARGUMENT49
                                                  dka_tools_pkg.tab_request_params(50), --ARGUMENT50
                                                  dka_tools_pkg.tab_request_params(51), --ARGUMENT51
                                                  dka_tools_pkg.tab_request_params(52), --ARGUMENT52
                                                  dka_tools_pkg.tab_request_params(53), --ARGUMENT53
                                                  dka_tools_pkg.tab_request_params(54), --ARGUMENT54
                                                  dka_tools_pkg.tab_request_params(55), --ARGUMENT55
                                                  dka_tools_pkg.tab_request_params(56), --ARGUMENT56
                                                  dka_tools_pkg.tab_request_params(57), --ARGUMENT57
                                                  dka_tools_pkg.tab_request_params(58), --ARGUMENT58
                                                  dka_tools_pkg.tab_request_params(59), --ARGUMENT59
                                                  dka_tools_pkg.tab_request_params(60), --ARGUMENT60
                                                  dka_tools_pkg.tab_request_params(61), --ARGUMENT61
                                                  dka_tools_pkg.tab_request_params(62), --ARGUMENT62
                                                  dka_tools_pkg.tab_request_params(63), --ARGUMENT63
                                                  dka_tools_pkg.tab_request_params(64), --ARGUMENT64
                                                  dka_tools_pkg.tab_request_params(65), --ARGUMENT65
                                                  dka_tools_pkg.tab_request_params(66), --ARGUMENT66
                                                  dka_tools_pkg.tab_request_params(67), --ARGUMENT67
                                                  dka_tools_pkg.tab_request_params(68), --ARGUMENT68
                                                  dka_tools_pkg.tab_request_params(69), --ARGUMENT69
                                                  dka_tools_pkg.tab_request_params(70), --ARGUMENT70
                                                  dka_tools_pkg.tab_request_params(71), --ARGUMENT71
                                                  dka_tools_pkg.tab_request_params(72), --ARGUMENT72
                                                  dka_tools_pkg.tab_request_params(73), --ARGUMENT73
                                                  dka_tools_pkg.tab_request_params(74), --ARGUMENT74
                                                  dka_tools_pkg.tab_request_params(75), --ARGUMENT75
                                                  dka_tools_pkg.tab_request_params(76), --ARGUMENT76
                                                  dka_tools_pkg.tab_request_params(77), --ARGUMENT77
                                                  dka_tools_pkg.tab_request_params(78), --ARGUMENT78
                                                  dka_tools_pkg.tab_request_params(79), --ARGUMENT79
                                                  dka_tools_pkg.tab_request_params(80), --ARGUMENT80
                                                  dka_tools_pkg.tab_request_params(81), --ARGUMENT81
                                                  dka_tools_pkg.tab_request_params(82), --ARGUMENT82
                                                  dka_tools_pkg.tab_request_params(83), --ARGUMENT83
                                                  dka_tools_pkg.tab_request_params(84), --ARGUMENT84
                                                  dka_tools_pkg.tab_request_params(85), --ARGUMENT85
                                                  dka_tools_pkg.tab_request_params(86), --ARGUMENT86
                                                  dka_tools_pkg.tab_request_params(87), --ARGUMENT87
                                                  dka_tools_pkg.tab_request_params(88), --ARGUMENT88
                                                  dka_tools_pkg.tab_request_params(89), --ARGUMENT89
                                                  dka_tools_pkg.tab_request_params(90), --ARGUMENT90
                                                  dka_tools_pkg.tab_request_params(91), --ARGUMENT91
                                                  dka_tools_pkg.tab_request_params(92), --ARGUMENT92
                                                  dka_tools_pkg.tab_request_params(93), --ARGUMENT93
                                                  dka_tools_pkg.tab_request_params(94), --ARGUMENT94
                                                  dka_tools_pkg.tab_request_params(95), --ARGUMENT95
                                                  dka_tools_pkg.tab_request_params(96), --ARGUMENT96
                                                  dka_tools_pkg.tab_request_params(97), --ARGUMENT97
                                                  dka_tools_pkg.tab_request_params(98), --ARGUMENT98
                                                  dka_tools_pkg.tab_request_params(99), --ARGUMENT99
                                                  dka_tools_pkg.tab_request_params(100) --ARGUMENT100
                                                  );
      Dka_Tools_Pkg.put_outdebug_message('Validation pour que les GTS puissent prendre la demande');
      vn_traitement := vn_traitement + 1;
      vt_traitement(vn_traitement).request_id := vn_request_id;
      COMMIT;
    
      IF vn_request_id = 0 THEN
        Dka_Tools_Pkg.put_outdebug_message('Impossible de lancer le Traitement ');
        pn_retcode := 2;
        RETURN;
      END IF;
    
      Dka_Tools_Pkg.put_outdebug_message('Traitement numero : ' ||
                                         TO_CHAR(vn_request_id));
      vv_dstatus := 'INITIAL';
      --WHILE vv_dstatus !='NORMAL' or vv_dstatus !='WARNING' LOOP
      IF NOT fnd_concurrent.wait_for_request(vt_traitement(vn_traitement)
                                             .request_id,
                                             cn_tempo,
                                             0,
                                             vv_rphase,
                                             vv_rstatus,
                                             vv_dphase,
                                             vv_dstatus,
                                             vv_message) THEN
        Dka_Tools_Pkg.put_outdebug_message('Passage au traitement suivant');
      ELSE
        Dka_Tools_Pkg.put_outdebug_message('Passage au traitement suivant');
      END IF;
      --END LOOP;
    
    END LOOP;
  
    -----------------------------------------------
    -- Attente de la fin de tous les traitements --
    -----------------------------------------------
    FOR vn_indice IN 1 .. vn_traitement LOOP
      IF NOT fnd_concurrent.wait_for_request(vt_traitement(vn_indice)
                                             .request_id,
                                             cn_tempo,
                                             0,
                                             vv_rphase,
                                             vv_rstatus,
                                             vv_dphase,
                                             vv_dstatus,
                                             vv_message) THEN
                                             
        Dka_Tools_Pkg.put_outdebug_message(CHR(10) || '>>> Traitement ' ||
                                           vt_traitement(vn_indice)
                                           .request_id ||
                                           ' termine en Warning');
      ELSE
      
        IF vv_dstatus = 'NORMAL' THEN
          Dka_Tools_Pkg.put_outdebug_message(CHR(10) || '>>> Traitement ' ||
                                             vt_traitement(vn_indice)
                                             .request_id ||
                                             ' termine normalement');
          vn_trt_normal := vn_trt_normal + 1;
        ELSIF vv_dstatus = 'WARNING' THEN
          Dka_Tools_Pkg.put_outdebug_message(CHR(10) || '>>> Traitement ' ||
                                             vt_traitement(vn_indice)
                                             .request_id ||
                                             ' termine en Warning ');
          vn_trt_warning := vn_trt_warning + 1;
        ELSIF vv_dstatus != 'NORMAL' THEN
          Dka_Tools_Pkg.put_outdebug_message(CHR(10) || '>>> Traitement ' ||
                                             vt_traitement(vn_indice)
                                             .request_id ||
                                             ' termine en Erreur ');
          vn_trt_erreur := vn_trt_erreur + 1;
        END IF;
        
      END IF;
    
    END LOOP;
  
    -- Fermeture du fichier de commandes
    ------------------------------------
    Dka_Tools_Pkg.put_outdebug_message(CHR(10) ||
                                       '==> Nombre de traitements à lancer             : ' ||
                                       TO_CHAR(vn_trt_a_lancer, '99990'));
    Dka_Tools_Pkg.put_outdebug_message('==> Nombre de traitements lances               : ' ||
                                       TO_CHAR(vn_trt_lances, '99990'));
    Dka_Tools_Pkg.put_outdebug_message('==> Nombre de traitements termines normalement : ' ||
                                       TO_CHAR(vn_trt_normal, '99990'));
    Dka_Tools_Pkg.put_outdebug_message('==> Nombre de traitements termines en warning  : ' ||
                                       TO_CHAR(vn_trt_warning, '99990'));
    Dka_Tools_Pkg.put_outdebug_message('==> Nombre de traitements termines en erreur   : ' ||
                                       TO_CHAR(vn_trt_erreur, '99990'));
  
    IF vn_trt_warning + vn_trt_erreur > 0 then
      pn_retcode := 1;
    ELSE
      pn_retcode := 0;
    END IF;
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := SQLERRM;
      pn_retcode := 2;
  END;

  -------------------------------------------------------------------------------------
  --  Nom           : Select_ligne_cde_proj_ferme
  --  Description   :
  --
  --  PARAMETRES    :
  --    pv_errbuf       Sortie
  --    pv_retcode          Sortie

  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: OK, 2: erreur ou code erreur ORA
  ------------------------------------------------------------------------------------

  PROCEDURE Select_ligne_cde_proj_ferme(pv_errbuf  OUT VARCHAR2,
                                        pn_retcode OUT NUMBER,
                                        pv_uo      IN VARCHAR2) IS
    CURSOR cur_ligne_cde_proj_ferme IS
      SELECT gcc.segment2 uo,
             pha.po_header_id,
             pha.segment1,
             pha.creation_date,
             pla.po_line_id,
             pla.line_num || '.' || pll.shipment_num || '.' ||
             pda.distribution_num line_num,
             pla.quantity * pla.unit_price montant,
             --ppa.segment1 code_projet,
             pt.task_number,
             gcc.segment8 code_projet_finance,
             --gcc.segment6 secteur
             gcc.segment6 centre_finance,
             gcc.segment7 affaire
      --dka_ibdsoc_tools_pkg.find_parent_acct_area_by_level(gcc.segment6,
      --                                                    4,
      --                                                    pda.creation_date) centre
        FROM po_headers pha,
             po_lines   pla,
             --po_vendor_sites       pvs,
             ap_supplier_sites     pvs,
             po_distributions_all  pda,
             gl_code_combinations  gcc,
             po_line_locations_all pll,
             pa_projects_all       ppa,
             pa_tasks              pt
       WHERE pla.po_header_id = pha.po_header_id
         AND pla.po_line_id = pll.po_line_id
         AND pll.po_header_id = pha.po_header_id
         AND pvs.vendor_site_id(+) = pha.vendor_site_id
         AND pha.type_lookup_code = gv_type_lookup_code
         AND pla.closed_date IS NULL
         AND pha.closed_date IS NULL
         AND (pla.attribute2 IS NULL OR pla.attribute2 != 'OUI')
         AND pha.segment1 NOT LIKE '%ST%'
         AND pda.code_combination_id = gcc.code_combination_id
         AND pda.po_header_id = pha.po_header_id
         AND pll.line_location_id = pda.line_location_id
         AND ppa.project_id = pda.project_id
         AND pt.task_id = pda.task_id
         AND gcc.segment2 = pv_uo
         AND EXISTS
       (SELECT 'x'
                FROM po_distributions  pda,
                     po_line_locations plla,
                     pa_projects       ppa
               WHERE pda.line_location_id = plla.line_location_id
                 AND plla.po_line_id = pla.po_line_id
                 AND ppa.project_id = pda.project_id
                 AND ppa.attribute7 IS NOT NULL
                 AND Fnd_Date.canonical_to_date(ppa.attribute7) <=
                     TRUNC(SYSDATE)
                 AND plla.quantity_received != 0)
         AND NOT EXISTS
       (SELECT 'x'
                FROM po_distributions  pda,
                     po_line_locations plla,
                     pa_projects       ppa
               WHERE pda.line_location_id = plla.line_location_id
                 AND plla.po_line_id = pla.po_line_id
                 AND ppa.project_id = pda.project_id
                 AND (ppa.attribute7 IS NULL OR Fnd_Date.canonical_to_date(ppa.attribute7) >
                     TRUNC(SYSDATE)))
         AND NOT EXISTS
       (SELECT 'x'
                FROM po_distributions         pda1,
                     ap_invoice_distributions aid,
                     ap_holds                 ah
               WHERE pda1.po_distribution_id = aid.po_distribution_id
                 AND aid.invoice_id = ah.invoice_id
                 AND pda1.po_line_id = pla.po_line_id
                 AND ah.release_lookup_code IS NULL);
  
    rec_ligne_cde_proj_ferme cur_ligne_cde_proj_ferme%ROWTYPE;
  
    CURSOR Cur_cde_proj_ferme IS
      SELECT po_header_id, segment1
        FROM po_headers_all pha
       WHERE pha.closed_date IS NULL
         AND pha.type_lookup_code = gv_type_lookup_code
         AND EXISTS (SELECT 'x'
                FROM po_lines_all pla
               WHERE pla.closed_date = TRUNC(SYSDATE)
                 AND pla.closed_reason = gv_message_proj_ferme
                 AND pla.po_header_id = pha.po_header_id)
         AND NOT EXISTS
       (SELECT 'x'
                FROM po_lines_all pla
               WHERE pla.closed_date IS NULL
                 AND pla.po_header_id = pha.po_header_id);
  
    rec_cde_proj_ferme cur_cde_proj_ferme%ROWTYPE;
  
    CURSOR Cur_ligne_art_proj_ferme IS
      SELECT po_line_id
        FROM po_lines_all pla
       WHERE pla.closed_date IS NULL
         AND EXISTS (SELECT 'X'
                FROM po_line_locations_all pll
               WHERE pll.closed_date = TRUNC(SYSDATE)
                 AND pll.closed_reason = gv_message_proj_ferme
                 AND pll.po_line_id = pla.po_line_id)
         AND NOT EXISTS
       (SELECT 'X'
                FROM po_line_locations_all pll
               WHERE pll.closed_date IS NULL
                 AND pll.po_line_id = pla.po_line_id);
  
    rec_ligne_art_proj_ferme Cur_ligne_art_proj_ferme%ROWTYPE;
  
    vn_nbre_ligne_ferme     NUMBER;
    vn_nbre_cde_ferme       NUMBER;
    vn_nbre_ligne_cde_ferme NUMBER;
  
    e_error EXCEPTION;
  
  BEGIN
    dka_tools_pkg.put_debug_message('(+) Select_ligne_cde_proj_ferme');
  
    ----- Initialisation des variables de sortie de la procédure -----
    pv_errbuf               := NULL;
    pn_retcode              := 0;
    vn_nbre_ligne_ferme     := 0;
    vn_nbre_cde_ferme       := 0;
    vn_nbre_ligne_cde_ferme := 0;
    Dka_Tools_Pkg.put_debug_message('Sélection lignes de commande sur projet fermé');
  
    Dka_Tools_Pkg.put_outdebug_message(CHR(10));
  
    OPEN cur_ligne_cde_proj_ferme;
    FETCH cur_ligne_cde_proj_ferme
      INTO rec_ligne_cde_proj_ferme;
  
    IF (cur_ligne_cde_proj_ferme%FOUND) THEN
    
      --Dka_Tools_Pkg.put_outdebug_message('REGION | N° COMMANDE | DATE CREATION | N° LIGNE | MONTANT | CODE PROJET | SECTEUR | CENTRE');
      Dka_Tools_Pkg.put_outdebug_message('UO | N° COMMANDE | DATE CREATION | N° LIGNE | MONTANT | CODE PROJET FINANCE | TACHE | CENTRE DE FINANCE | AFFAIRE');
    
      /*      Dka_Tools_Pkg.put_outdebug_message(rpad(rec_ligne_cde_proj_ferme.region,
           7) || '| ' ||
      rpad(rec_ligne_cde_proj_ferme.segment1,
           12) || '| ' ||
      rpad(to_char(rec_ligne_cde_proj_ferme.creation_date,
                   'DD/MM/RRRR'),
           14) || '| ' ||
      rpad(rec_ligne_cde_proj_ferme.line_num,
           9) || '| ' ||
      rec_ligne_cde_proj_ferme.montant || '| ' ||
      rec_ligne_cde_proj_ferme.code_projet || '| ' ||
      rec_ligne_cde_proj_ferme.secteur || '| ' ||
      rec_ligne_cde_proj_ferme.centre);*/
    
      Dka_Tools_Pkg.put_outdebug_message(rpad(rec_ligne_cde_proj_ferme.uo,
                                              7) || '| ' ||
                                         rpad(rec_ligne_cde_proj_ferme.segment1,
                                              12) || '| ' ||
                                         rpad(to_char(rec_ligne_cde_proj_ferme.creation_date,
                                                      'DD/MM/RRRR'),
                                              14) || '| ' ||
                                         rpad(rec_ligne_cde_proj_ferme.line_num,
                                              9) || '| ' ||
                                         rec_ligne_cde_proj_ferme.montant || '| ' ||
                                         rec_ligne_cde_proj_ferme.code_projet_finance || '| ' ||
                                         rec_ligne_cde_proj_ferme.task_number || '| ' ||
                                         rec_ligne_cde_proj_ferme.centre_finance || '| ' ||
                                         rec_ligne_cde_proj_ferme.affaire);
    
      -- Fermeture de la ligne de commande
      Cloture_ligne_commande(rec_ligne_cde_proj_ferme.po_line_id,
                             gv_message_proj_ferme /*,pv_uo*/,
                             pv_errbuf,
                             pn_retcode);
    
      IF pn_retcode != 0 THEN
      
        pv_errbuf := '=> ERREUR FERMETURE LIGNE LIVRAISON SUR PROJET FERME - ' ||
                     pv_errbuf;
        RAISE e_error;
      ELSE
        vn_nbre_ligne_ferme := vn_nbre_ligne_ferme + 1;
      END IF;
    
      LOOP
        FETCH cur_ligne_cde_proj_ferme
          INTO rec_ligne_cde_proj_ferme;
        EXIT WHEN cur_ligne_cde_proj_ferme%NOTFOUND;
      
        /*        Dka_Tools_Pkg.put_outdebug_message(rpad(rec_ligne_cde_proj_ferme.region,
             7) || '| ' ||
        rpad(rec_ligne_cde_proj_ferme.segment1,
             12) || '| ' ||
        rpad(to_char(rec_ligne_cde_proj_ferme.creation_date,
                     'DD/MM/RRRR'),
             14) || '| ' ||
        rpad(rec_ligne_cde_proj_ferme.line_num,
             9) || '| ' ||
        rec_ligne_cde_proj_ferme.montant || '| ' ||
        rec_ligne_cde_proj_ferme.code_projet || '| ' ||
        rec_ligne_cde_proj_ferme.secteur || '| ' ||
        rec_ligne_cde_proj_ferme.centre);*/
      
        Dka_Tools_Pkg.put_outdebug_message(rpad(rec_ligne_cde_proj_ferme.uo,
                                                7) || '| ' ||
                                           rpad(rec_ligne_cde_proj_ferme.segment1,
                                                12) || '| ' ||
                                           rpad(to_char(rec_ligne_cde_proj_ferme.creation_date,
                                                        'DD/MM/RRRR'),
                                                14) || '| ' ||
                                           rpad(rec_ligne_cde_proj_ferme.line_num,
                                                9) || '| ' ||
                                           rec_ligne_cde_proj_ferme.montant || '| ' ||
                                           rec_ligne_cde_proj_ferme.code_projet_finance || '| ' ||
                                           rec_ligne_cde_proj_ferme.task_number || '| ' ||
                                           rec_ligne_cde_proj_ferme.centre_finance || '| ' ||
                                           rec_ligne_cde_proj_ferme.affaire);
      
        -- Fermeture de la ligne de commande
        Cloture_ligne_commande(rec_ligne_cde_proj_ferme.po_line_id,
                               gv_message_proj_ferme,
                               pv_errbuf,
                               pn_retcode);
      
        IF pn_retcode != 0 THEN
        
          pv_errbuf := '=> ERREUR FERMETURE LIGNE LIVRAISON ANCIENNE - ' ||
                       pv_errbuf;
          RAISE e_error;
        ELSE
          vn_nbre_ligne_ferme := vn_nbre_ligne_ferme + 1;
        END IF;
      
      END LOOP;
    
    ELSE
      Dka_Tools_Pkg.put_outdebug_message('Aucune ligne traitée');
    END IF;
  
    CLOSE cur_ligne_cde_proj_ferme;
  
    Dka_Tools_Pkg.put_outdebug_message('***** 1. FERMETURE DES LIGNES DE COMMANDES SUR PROJET FERME *****');
  
    /*OPEN Cur_ligne_art_proj_ferme;
    LOOP
         FETCH Cur_ligne_art_proj_ferme INTO rec_ligne_art_proj_ferme;
         EXIT WHEN Cur_ligne_art_proj_ferme%NOTFOUND;
         
            -- Fermeture de la ligne de commande
            Cloture_ligne_commande(rec_ligne_art_proj_ferme.po_line_id, gv_message_proj_ferme, pv_errbuf, pn_retcode);
            
            IF pn_retcode != 0
            THEN
    
                pv_errbuf    := '=> ERREUR FERMETURE LIGNE COMMANDE SUR PROJET FERME - '|| pv_errbuf;
                RAISE e_error;
            ELSE
                vn_nbre_ligne_cde_ferme := vn_nbre_ligne_cde_ferme + 1;
            END IF;
            
    END LOOP;
    CLOSE Cur_ligne_art_proj_ferme;*/
  
    OPEN cur_cde_proj_ferme;
    LOOP
      FETCH cur_cde_proj_ferme
        INTO rec_cde_proj_ferme;
      EXIT WHEN cur_cde_proj_ferme%NOTFOUND;
    
      -- Fermeture de la commande
      Cloture_entete_commande(rec_cde_proj_ferme.po_header_id,
                              pv_errbuf,
                              pn_retcode);
    
      IF pn_retcode != 0 THEN
      
        pv_errbuf := '=> ERREUR FERMETURE COMMANDE ANCIENNE' ||
                     rec_cde_proj_ferme.segment1 || ' - ' || pv_errbuf;
        RAISE e_error;
      ELSE
        vn_nbre_cde_ferme := vn_nbre_cde_ferme + 1;
      END IF;
    
    END LOOP;
    CLOSE cur_cde_proj_ferme;
  
    Dka_Tools_Pkg.put_outdebug_message(CHR(10));
    -- Dka_Tools_Pkg.put_outdebug_message('Nombre de lignes de livraison fermées : '||vn_nbre_ligne_ferme);
    Dka_Tools_Pkg.put_outdebug_message('Nombre de lignes de commande fermées : ' ||
                                       vn_nbre_ligne_ferme);
    Dka_Tools_Pkg.put_outdebug_message('Nombre de commandes fermées          : ' ||
                                       vn_nbre_cde_ferme);
    Dka_Tools_Pkg.put_outdebug_message(CHR(10));
    dka_tools_pkg.put_debug_message('(-) Select_ligne_cde_proj_ferme');
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'Select_ligne_cde_proj_ferme - ' || SQLERRM;
      pn_retcode := 2;
  END Select_ligne_cde_proj_ferme;

  -------------------------------------------------------------------------------------
  --  Nom           : Select_ligne_cde_ancienne
  --  Description   :
  --
  --  PARAMETRES    :
  --    pv_errbuf       Sortie
  --    pv_retcode          Sortie

  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: OK, 2: erreur ou code erreur ORA
  ------------------------------------------------------------------------------------

  PROCEDURE Select_ligne_cde_ancienne(pv_errbuf  OUT VARCHAR2,
                                      pn_retcode OUT NUMBER,
                                      pv_uo      IN VARCHAR2) IS
    CURSOR Cur_ligne_cde_ancienne IS
      SELECT --gcc.segment2 region,
       gcc.segment2 uo,
       pha.po_header_id,
       pha.segment1,
       pha.creation_date,
       pla.po_line_id,
       pla.line_num || '.' || pll.shipment_num || '.' ||
       pda.distribution_num line_num,
       pla.quantity * pla.unit_price montant,
       --ppa.segment1 code_projet,
       pt.task_number,
       gcc.segment8 code_projet_finance,
       --gcc.segment6 secteur
       gcc.segment6 centre_finance,
       gcc.segment7 affaire
      --dka_ibdsoc_tools_pkg.find_parent_acct_area_by_level(gcc.segment6,
      --                                                    4,
      --                                                    pda.creation_date) centre
      
        FROM po_headers            pha,
             po_lines              pla,
             po_vendor_sites       pvs,
             po_distributions_all  pda,
             po_line_locations_all pll,
             gl_code_combinations  gcc,
             pa_projects_all       ppa,
             pa_tasks              pt
       WHERE pla.po_header_id = pha.po_header_id
         AND pla.po_line_id = pll.po_line_id
         AND pll.po_header_id = pha.po_header_id
         AND pt.task_id = pda.task_id
         AND pvs.vendor_site_id(+) = pha.vendor_site_id
         AND pha.type_lookup_code = gv_type_lookup_code
         AND pla.closed_date IS NULL
         AND pha.closed_date IS NULL
         AND (pla.attribute2 IS NULL OR pla.attribute2 != 'OUI')
         AND pla.creation_date < add_months(sysdate, -gn_nbre_mois)
         AND pha.segment1 NOT LIKE '%ST%'
         AND pda.code_combination_id = gcc.code_combination_id
         AND pda.po_header_id = pha.po_header_id
         AND pll.line_location_id = pda.line_location_id
         AND pda.project_id = ppa.project_id
         AND gcc.segment2 = pv_uo
         AND EXISTS (SELECT 'x'
                FROM po_line_locations plla
               WHERE plla.po_line_id = pla.po_line_id
                 AND plla.quantity_received != 0)
         AND NOT EXISTS
       (SELECT 'x'
                FROM po_distributions         pda1,
                     ap_invoice_distributions aid,
                     ap_holds                 ah
               WHERE pda1.po_distribution_id = aid.po_distribution_id
                 AND aid.invoice_id = ah.invoice_id
                 AND pda1.po_line_id = pla.po_line_id
                 AND ah.release_lookup_code IS NULL);
  
    rec_ligne_cde_ancienne cur_ligne_cde_ancienne%ROWTYPE;
  
    CURSOR Cur_cde_ancienne IS
      SELECT po_header_id, segment1
        FROM po_headers_all pha
       WHERE pha.closed_date IS NULL
         AND pha.type_lookup_code = gv_type_lookup_code
         AND EXISTS
       (SELECT 'x'
                FROM po_lines_all pla
               WHERE pla.closed_date = TRUNC(SYSDATE)
                 AND pla.closed_reason = gv_message_cde_ancienne
                 AND pla.po_header_id = pha.po_header_id)
         AND NOT EXISTS
       (SELECT 'x'
                FROM po_lines_all pla
               WHERE pla.closed_date IS NULL
                 AND pla.po_header_id = pha.po_header_id)
      -- AND ROWNUM < 5 
      ;
  
    rec_cde_ancienne cur_cde_ancienne%ROWTYPE;
  
    CURSOR Cur_ligne_art_ancienne IS
      SELECT po_line_id
        FROM po_lines_all pla
       WHERE pla.closed_date IS NULL
         AND EXISTS (SELECT 'X'
                FROM po_line_locations_all pll
               WHERE pll.closed_date = TRUNC(SYSDATE)
                 AND pll.closed_reason = gv_message_proj_ferme
                 AND pll.po_line_id = pla.po_line_id)
         AND NOT EXISTS
       (SELECT 'X'
                FROM po_line_locations_all pll
               WHERE pll.closed_date IS NULL
                 AND pll.po_line_id = pla.po_line_id);
  
    rec_ligne_art_ancienne Cur_ligne_art_ancienne%ROWTYPE;
  
    vn_nbre_ligne_ferme     NUMBER;
    vn_nbre_cde_ferme       NUMBER;
    vn_nbre_ligne_cde_ferme NUMBER;
    e_error EXCEPTION;
  
  BEGIN
    dka_tools_pkg.put_debug_message('(+) Select_ligne_cde_ancienne');
  
    ----- Initialisation des variables de sortie de la procédure -----
    pv_errbuf               := NULL;
    pn_retcode              := 0;
    vn_nbre_ligne_ferme     := 0;
    vn_nbre_cde_ferme       := 0;
    vn_nbre_ligne_cde_ferme := 0;
    Dka_Tools_Pkg.put_debug_message('Sélection lignes de commande ancienne');
  
    Dka_Tools_Pkg.put_outdebug_message('***** 2. FERMETURE DES LIGNES DE COMMANDES ANTERIEURES AU ' ||
                                       to_char(gd_date_seuil, 'DD/MM/RRRR') ||
                                       ' *****');
    Dka_Tools_Pkg.put_outdebug_message(CHR(10));
  
    OPEN cur_ligne_cde_ancienne;
    FETCH cur_ligne_cde_ancienne
      INTO rec_ligne_cde_ancienne;
  
    IF (cur_ligne_cde_ancienne%FOUND) THEN
    
      --Dka_Tools_Pkg.put_outdebug_message('REGION | N° COMMANDE | DATE CREATION | N° LIGNE | MONTANT | CODE PROJET | SECTEUR | CENTRE');
      Dka_Tools_Pkg.put_outdebug_message('UO | N° COMMANDE | DATE CREATION | N° LIGNE | MONTANT | CODE PROJET FINANCE | TACHE | CENTRE DE FINANCE | AFFAIRE');
    
      /*      Dka_Tools_Pkg.put_outdebug_message(rpad(rec_ligne_cde_ancienne.region,
           7) || '| ' ||
      rpad(rec_ligne_cde_ancienne.segment1,
           12) || '| ' ||
      rpad(to_char(rec_ligne_cde_ancienne.creation_date,
                   'DD/MM/RRRR'),
           14) || '| ' ||
      rpad(rec_ligne_cde_ancienne.line_num,
           9) || '| ' ||
      rec_ligne_cde_ancienne.montant || '| ' ||
      rec_ligne_cde_ancienne.code_projet || '| ' ||
      rec_ligne_cde_ancienne.secteur || '| ' ||
      rec_ligne_cde_ancienne.centre);*/
    
      Dka_Tools_Pkg.put_outdebug_message(rpad(rec_ligne_cde_ancienne.uo, 7) || '| ' ||
                                         rpad(rec_ligne_cde_ancienne.segment1,
                                              12) || '| ' ||
                                         rpad(to_char(rec_ligne_cde_ancienne.creation_date,
                                                      'DD/MM/RRRR'),
                                              14) || '| ' ||
                                         rpad(rec_ligne_cde_ancienne.line_num,
                                              9) || '| ' ||
                                         rec_ligne_cde_ancienne.montant || '| ' ||
                                         rec_ligne_cde_ancienne.code_projet_finance || '| ' ||
                                         rec_ligne_cde_ancienne.task_number || '| ' ||
                                         rec_ligne_cde_ancienne.centre_finance || '| ' ||
                                         rec_ligne_cde_ancienne.affaire);
    
      -- Fermeture de la ligne de commande
      Cloture_ligne_commande(rec_ligne_cde_ancienne.po_line_id,
                             gv_message_cde_ancienne, /*pv_uo,*/
                             pv_errbuf,
                             pn_retcode);
    
      IF pn_retcode != 0 THEN
      
        pv_errbuf := '=> ERREUR FERMETURE LIGNE LIVRAISON ANCIENNE - ' ||
                     pv_errbuf;
        RAISE e_error;
      ELSE
        vn_nbre_ligne_ferme := vn_nbre_ligne_ferme + 1;
      END IF;
    
      LOOP
        FETCH cur_ligne_cde_ancienne
          INTO rec_ligne_cde_ancienne;
        EXIT WHEN cur_ligne_cde_ancienne%NOTFOUND;
      
        /*        Dka_Tools_Pkg.put_outdebug_message(rpad(rec_ligne_cde_ancienne.region,
             7) || '| ' ||
        rpad(rec_ligne_cde_ancienne.segment1,
             12) || '| ' ||
        rpad(to_char(rec_ligne_cde_ancienne.creation_date,
                     'DD/MM/RRRR'),
             14) || '| ' ||
        rpad(rec_ligne_cde_ancienne.line_num,
             9) || '| ' ||
        rec_ligne_cde_ancienne.montant || '| ' ||
        rec_ligne_cde_ancienne.code_projet || '| ' ||
        rec_ligne_cde_ancienne.secteur || '| ' ||
        rec_ligne_cde_ancienne.centre);*/
      
        Dka_Tools_Pkg.put_outdebug_message(rpad(rec_ligne_cde_ancienne.uo,
                                                7) || '| ' ||
                                           rpad(rec_ligne_cde_ancienne.segment1,
                                                12) || '| ' ||
                                           rpad(to_char(rec_ligne_cde_ancienne.creation_date,
                                                        'DD/MM/RRRR'),
                                                14) || '| ' ||
                                           rpad(rec_ligne_cde_ancienne.line_num,
                                                9) || '| ' ||
                                           rec_ligne_cde_ancienne.montant || '| ' ||
                                           rec_ligne_cde_ancienne.code_projet_finance || '| ' ||
                                           rec_ligne_cde_ancienne.task_number || '| ' ||
                                           rec_ligne_cde_ancienne.centre_finance || '| ' ||
                                           rec_ligne_cde_ancienne.affaire);
      
        -- Fermeture de la ligne de commande
        Cloture_ligne_commande(rec_ligne_cde_ancienne.po_line_id,
                               gv_message_cde_ancienne, /*pv_uo,*/
                               pv_errbuf,
                               pn_retcode);
      
        IF pn_retcode != 0 THEN
        
          pv_errbuf := '=> ERREUR FERMETURE LIGNE LIVRAISON ANCIENNE - ' ||
                       pv_errbuf;
          RAISE e_error;
        ELSE
          vn_nbre_ligne_ferme := vn_nbre_ligne_ferme + 1;
        END IF;
      
      END LOOP;
    
    ELSE
      Dka_Tools_Pkg.put_outdebug_message('Aucune ligne traitée');
    END IF;
  
    CLOSE cur_ligne_cde_ancienne;
  
    /*OPEN Cur_ligne_art_ancienne;
    LOOP
         FETCH Cur_ligne_art_ancienne INTO rec_ligne_art_ancienne;
         EXIT WHEN Cur_ligne_art_ancienne%NOTFOUND;
         
            -- Fermeture de la ligne de commande
            Cloture_ligne_commande(rec_ligne_art_ancienne.po_line_id, gv_message_proj_ferme, pv_errbuf, pn_retcode);
            
            IF pn_retcode != 0
            THEN
    
                pv_errbuf    := '=> ERREUR FERMETURE LIGNE COMMANDE ANCIENNE - '|| pv_errbuf;
                RAISE e_error;
            ELSE
                vn_nbre_ligne_cde_ferme := vn_nbre_ligne_cde_ferme + 1;
            END IF;
            
    END LOOP;
    CLOSE Cur_ligne_art_ancienne;*/
  
    OPEN cur_cde_ancienne;
    LOOP
      FETCH cur_cde_ancienne
        INTO rec_cde_ancienne;
      EXIT WHEN cur_cde_ancienne%NOTFOUND;
    
      -- Fermeture de la commande
      Cloture_entete_commande(rec_cde_ancienne.po_header_id,
                              pv_errbuf,
                              pn_retcode);
    
      IF pn_retcode != 0 THEN
      
        pv_errbuf := '=> ERREUR FERMETURE COMMANDE ANCIENNE' ||
                     rec_cde_ancienne.segment1 || ' - ' || pv_errbuf;
        RAISE e_error;
      ELSE
        vn_nbre_cde_ferme := vn_nbre_cde_ferme + 1;
      END IF;
    
    END LOOP;
    CLOSE cur_cde_ancienne;
  
    Dka_Tools_Pkg.put_outdebug_message(CHR(10));
    -- Dka_Tools_Pkg.put_outdebug_message('Nombre de lignes de livraison fermées : '||vn_nbre_ligne_ferme);
    Dka_Tools_Pkg.put_outdebug_message('Nombre de lignes de commande fermées : ' ||
                                       vn_nbre_ligne_ferme);
    Dka_Tools_Pkg.put_outdebug_message('Nombre de commandes fermées          : ' ||
                                       vn_nbre_cde_ferme);
    Dka_Tools_Pkg.put_outdebug_message(CHR(10));
    dka_tools_pkg.put_debug_message('(-) Select_ligne_cde_ancienne');
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'Select_ligne_cde_ancienne - ' || SQLERRM;
      pn_retcode := 2;
  END Select_ligne_cde_ancienne;

  --------------------------------------------------------------------------------------
  --  Nom           : MAIN
  --  Description   : Procédure principale enchaînant l'ensemble des autres procédures
  --
  --  PARAMETRES :
  --    pv_errbuf                   Entrée/Sortie       retour de message eventuel
  --    pn_retcode                  Sortie          status du traitement en sortie
  --
  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: normal, 1: warning, 2: erreur
  --
  ----------------------------------------------------------------------------------------
  PROCEDURE main(pv_errbuf    IN OUT VARCHAR2,
                 pn_retcode   OUT NUMBER,
                 pn_nbre_mois IN NUMBER,
                 pv_uo        IN VARCHAR2) IS
  BEGIN
    dka_tools_pkg.put_debug_message('(+) main');
  
    ----- Initialisation des variables de sortie de la procédure -----
    pv_errbuf  := NULL;
    pn_retcode := 0;
    Dka_Tools_Pkg.put_debug_message(CHR(10) ||
                                    'début de la procédure principale' ||
                                    CHR(10));
  
    gn_nbre_mois := pn_nbre_mois;
  
    ----- Appel de la procédure INIT -----
    init(pv_errbuf, pn_retcode);
  
    IF pn_retcode != 0 THEN
      pv_errbuf := 'INIT - ' || pv_errbuf;
      Dka_Tools_Pkg.put_outdebug_message(CHR(10) || pv_errbuf);
      RETURN;
    END IF;
  
    Dka_Tools_Pkg.put_outdebug_message('**************** FERMETURE DES LIGNES DE COMMANDES ****************');
    Dka_Tools_Pkg.put_outdebug_message(CHR(10));
  
    -- Fermeture des commandes anciennes
    Select_ligne_cde_proj_ferme(pv_errbuf, pn_retcode, pv_uo);
  
    -- Fermeture des commandes anciennes
    Select_ligne_cde_ancienne(pv_errbuf, pn_retcode, pv_uo);
  
    Dka_Tools_Pkg.put_outdebug_message(CHR(10));
    Dka_Tools_Pkg.put_outdebug_message('***** FIN DU TRAITEMENT *****');
  
    dka_tools_pkg.put_debug_message('(-) main');
  
  END main;

END DKA_SPOCLOSCOM_PKG;
/
SHOW ERROR
EXIT;
