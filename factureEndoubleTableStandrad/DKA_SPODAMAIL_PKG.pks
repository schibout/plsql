CREATE OR REPLACE PACKAGE BODY DKA_IAPCTRFLUX_IVALUA_PKG IS
  ------------------------------------------------------------------------
  -- $Id: DKA.DKA_IAPCTRFLUX_IVALUA_PKG.pkb 
  -- Nom              : DKA.DKA_IAPCTRFLUX_IVALUA_PKG.pkb
  -- Description      : Corps du package DKA.DKA_IAPCTRFLUX_IVALUA_PKG
  -- Auteur           : Mathieu TIABLIKOFF (Capgemini)
  -- Date de creation : 24/09/2020
  -- Commentaire      : A executer sous sqlplus avec le user APPS
  ------------------------------------------------------------------------
  -- Historique des modifications
  -- Date       Qui Description
  -- ---------- --- ------------------------------------------------------

  -- separateur de lignes
  cv_nl CONSTANT VARCHAR2(1) := chr(10);
  -- separateur de champs
  cv_fsep CONSTANT VARCHAR2(1) := ';';
  -- separateur pour le message des incohérence
  cv_isep CONSTANT VARCHAR2(3) := ' - ';
  -- format de date pour conversion en chaine dans l'entete
  cv_date_format CONSTANT VARCHAR2(10) := 'DD/MM/YYYY';
  -- table de transcodification utilisee pour filtrer sur le csp,
  -- la division et/ou la region
  cv_transco_table CONSTANT VARCHAR2(22) := 'CENTRE_SERVICE_PARTAGE';
  -- application_short_name utilise pour stocker les messages
  cv_msg_app CONSTANT VARCHAR2(4) := 'DKA';
  -- prefixe des noms des messages
  cv_msg_pfx CONSTANT VARCHAR2(28) := 'DKA_IAPCTRFLUX_IVALUA_COL';
  -- morceaux de chaines utilisees dans les messages d'erreur
  cv_err_pfx CONSTANT VARCHAR2(16) := 'Erreur durant : ';
  cv_err_log CONSTANT VARCHAR2(25) := ' (detail dans le journal)';
  -- Status des nouvelles factures
  cv_new CONSTANT VARCHAR2(3) := 'NEW';

  -- quand on catche cette exception, il faut juste remplir la stack
  -- et faire un re-raise de celle-ci ; cela permet d'afficher une trace
  -- du deroulement du traitement
  e_raised  EXCEPTION;
  e_warning EXCEPTION;

  ----------------------------------------------------------------------
  -- Convertit une date en chaine en utilisant le format defini dans la
  -- constante cv_date_format.
  --
  -- Parametres
  --  pd_date   date a convertir
  ----------------------------------------------------------------------
  FUNCTION format_date(pd_date DATE) RETURN VARCHAR2 IS
  BEGIN
    RETURN to_char(pd_date, cv_date_format);
  EXCEPTION
    WHEN OTHERS THEN
      dka_Tools_Pkg.add_error_stack('[format_date] ' || SQLERRM);
      RAISE e_raised;
  END format_date;

  -----------------------------------------------------------------------
  -- Procédure principale
  -----------------------------------------------------------------------
  PROCEDURE main(pv_errbuf OUT VARCHAR2, pn_retcode OUT NUMBER) IS
  
    -- Déclaration des variables
    vv_step                 VARCHAR2(100); -- Etape du traitement
    vn_nb_facture_rec       NUMBER; -- Nombre de facture reçues
    vn_nb_facture_rec_ENERG NUMBER; -- Nombre de facture reçues pour energie
    vn_nb_facture_int       NUMBER; -- Nombre de facture intégré
    vn_nb_rejets            NUMBER; -- Nombre de facture rejetées au total
    vn_nb_integres          NUMBER; -- Nombre de facture intégrées AP
    vn_nb_fac_div           NUMBER; -- Nombre de facture reçues par division
    vn_nb_fac_tab           NUMBER; -- Nombre de facture dans la table de travail
    vn_cumul_fac_rejets     NUMBER; -- Cumul des factures rejetées pour le sous tableau
    vn_cumul_fac_int        NUMBER; -- Cumul des factures intégrés pour le sous tableau
    vn_cumul_total          NUMBER; -- Cumul des factures pour le sous tableau
    vv_incoherence          VARCHAR2(50); -- Ajout des divisions ou il y a des incohérences
    vv_fac_nr               VARCHAR2(50); -- Ajout des divisions ou il n'y a pas de facture reçue
    vv_controle             VARCHAR2(50); -- Ajout des divisions ou il n'y a pas de controle reçu
    vb_incoherence          BOOLEAN; -- Incoherence detectée
    vb_fac_nr               BOOLEAN; -- Facture non reçue
    vb_fich_cont            BOOLEAN; -- Fichier de contrôle non reçu
    vb_warning              BOOLEAN; -- Une des 3 erreurs est détectée
  
    -- Récupération des divisions existantes
    CURSOR cur_division IS
      SELECT distinct xov.division, tab1.nom_fichier nom
        FROM dka_organisation_v xov,
             dka_stransco_lines dsl, -- Ajout MSL -- 11/03/2010
             dka_stransco_headers dsh, -- Ajout MSL -- 11/03/2010
             (SELECT xix.nom_fichier, xii.code_division
                FROM dka_iapfacxgs_interface   xii,
                     dka.dka_iapctrflux_ivalua xix
               WHERE RTRIM(xii.nom_fichier) = xix.nom_fichier
                 AND xix.status = cv_new) tab1
       WHERE xov.DIVISION = tab1.code_division(+)
         AND dsh.set_id = dsl.set_id -- Ajout MSL -- 11/03/2010
         AND dsh.set_name = cv_transco_table -- Ajout MSL -- 11/03/2010
         AND dsl.PARAM1_VALUE = xov.division; -- Ajout MSL -- 11/03/2010
    --AND xov.VALUE = fnd_profile.value('ORG_ID');                             -- Ajout MSL -- 11/03/2010
  
    -- Récupération des valeurs
    CURSOR cur_valeur(pv_div DKA_STRANSCO_LINES.param1_value%TYPE) IS
      SELECT -- liste.division,
       liste.csp,
       nvl(nb_rejets.nb, 0) nb_rejets,
       nvl(nb_integres.nb, 0) nb_integres
        FROM -- Selection des divisions, CSP et du code région
             (SELECT dsl.param1_value AS division,
                     dsl.return_value AS CSP,
                     dsl.PARAM2_VALUE AS code_region
                FROM DKA_STRANSCO_LINES dsl, DKA_STRANSCO_HEADERS dsh
               WHERE dsh.set_name = cv_transco_table -- CENTRE_SERVICE_PARTAGE
                 AND dsh.set_id = dsl.set_id
                 AND dsl.param1_value = pv_div) liste, -- Division en cours de traitement
             -- Selection du nombre de factures rejetées par code région
             (SELECT xii.CODE_REGION AS code_region, COUNT(*) AS nb
                FROM AP_INVOICES_INTERFACE     aii,
                     DKA_IAPFACXGS_INTERFACE   xii,
                     DKA.DKA_IAPCTRFLUX_IVALUA xix
               WHERE aii.attribute3 = xii.reference_lad
                 AND aii.status = 'REJECTED'
                 AND xix.nom_fichier = RTRIM(xii.nom_fichier) -- Présent dans le fichier
                 AND xix.status = cv_new -- Status des nouvelles factures
               GROUP BY xii.CODE_REGION) nb_rejets,
             -- Selection du nombre de factures intégrées par code région
             (SELECT xii.CODE_REGION AS code_region, COUNT(*) AS nb
                FROM AP_INVOICES_ALL           aia,
                     DKA_IAPFACXGS_INTERFACE   xii,
                     DKA.DKA_IAPCTRFLUX_IVALUA xix
               WHERE aia.attribute3 = xii.reference_lad
                 AND aia.attribute9 = 'DSP'
                 AND xix.nom_fichier = RTRIM(xii.nom_fichier) -- Facture présente dans le fichier
                 AND xix.status = cv_new -- Status des nouvelles factures
               GROUP BY xii.CODE_REGION) nb_integres
       WHERE liste.code_region = nb_rejets.code_region(+) -- Jointure des factures rejetées avec les divisions et CSP grace au code région
         AND liste.code_region = nb_integres.code_region(+) -- Jointure des factures intégrés avec les divisions et CSP grace au code région
         AND (nb_rejets.code_region IS NOT NULL OR
             nb_integres.code_region IS NOT NULL);
  
  BEGIN
  
    pn_retcode     := 0;
    pv_errbuf      := NULL;
    vb_incoherence := FALSE;
    vb_fac_nr      := FALSE;
    vb_fich_cont   := FALSE;
  
    vv_step := 'Ecriture de l''entete du fichier';
    -- Nom du traitement
    dka_Tools_Pkg.put_outdebug_message(fnd_message.get_string(cv_msg_app,
                                                              cv_msg_pfx || '1'));
    -- Date et heure
    dka_Tools_Pkg.put_outdebug_message(format_date(SYSDATE));
  
    -- Saut de ligne
    dka_Tools_Pkg.put_outdebug_message(cv_nl);
  
    vv_step := 'Ecriture du premier bloc de données';
    -- Nombre de factures reçues
  
    BEGIN
      select nb_invoices_processed
        INTO vn_nb_facture_rec_ENERG
        from dka.dka_iapctrflux_ivalua xix
       where exists (select 1
                from dka_stransco_lines dsl, dka_stransco_headers dsh
               where decode(xix.company_value, 'DAL', 'ENERGIE') =
                     dsl.PARAM1_VALUE
                 and dsh.set_id = dsl.set_id
                 AND dsh.set_name = 'CENTRE_SERVICE_PARTAGE')
         AND xix.status = cv_new;
    
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vn_nb_facture_rec_ENERG := 0;
    END;
  
    vn_nb_facture_rec := vn_nb_facture_rec_ENERG;
    vn_nb_facture_rec := nvl(vn_nb_facture_rec, -1);
  
    -- Affichage de la ligne : Nombre de factures reçues par le fichier de contrôle
    IF vn_nb_facture_rec < 0 THEN
      dka_Tools_Pkg.put_outdebug_message(fnd_message.get_string(cv_msg_app,
                                                                cv_msg_pfx || '2') ||
                                         cv_fsep || 'NR');
    ELSE
      dka_Tools_Pkg.put_outdebug_message(fnd_message.get_string(cv_msg_app,
                                                                cv_msg_pfx || '2') ||
                                         cv_fsep || vn_nb_facture_rec);
    END IF;
  
    -- Nombre de factures intégrées
    SELECT COUNT(1)
      INTO vn_nb_facture_int
      FROM DKA_IAPFACXGS_INTERFACE xii, DKA.DKA_IAPCTRFLUX_IVALUA xix
     WHERE exists (select 1
              from dka_stransco_lines dsl, dka_stransco_headers dsh
             WHERE dsh.set_id = dsl.set_id
               AND dsh.set_name = cv_transco_table
               AND dsl.PARAM1_VALUE = xii.code_division)
       AND xix.status = cv_new
       AND xix.nom_fichier = RTRIM(xii.nom_fichier)
       AND xii.REFERENCE_LAD like 'DSP%';
  
    -- Affichage de la ligne :  Nom du fichier intégré  +  Nombre de factures intégrées
    dka_Tools_Pkg.put_outdebug_message(fnd_message.get_string(cv_msg_app,
                                                              cv_msg_pfx || '3') ||
                                       cv_fsep || vn_nb_facture_int);
  
    -- Calcul du nombre de factures rejetées et du nombre de factures intégrées AP
    SELECT sum(nb_rejets.nb), sum(nb_integres.nb)
      INTO vn_nb_rejets, vn_nb_integres
      FROM -- Selection des divisions, CSP et du code région
           (SELECT dsl.param1_value AS division,
                   dsl.return_value AS CSP,
                   dsl.PARAM2_VALUE AS code_region
              FROM DKA_STRANSCO_LINES dsl, DKA_STRANSCO_HEADERS dsh
             WHERE dsh.set_name = cv_transco_table -- CENTRE_SERVICE_PARTAGE
               AND dsh.set_id = dsl.set_id) liste,
           -- Selection du nombre de factures rejetées par code région
           (SELECT xii.CODE_REGION AS code_region, COUNT(*) AS nb
              FROM AP_INVOICES_INTERFACE     aii,
                   DKA_IAPFACXGS_INTERFACE   xii,
                   DKA.DKA_IAPCTRFLUX_IVALUA xix
             WHERE exists
             (select 1
                      from dka_stransco_lines dsl, dka_stransco_headers dsh
                     where dsh.set_id = dsl.set_id
                       AND dsh.set_name = cv_transco_table
                       AND dsl.PARAM1_VALUE = xii.code_division)
               AND aii.attribute3 = xii.reference_lad
               AND aii.status = 'REJECTED'
               AND xix.nom_fichier = RTRIM(xii.nom_fichier) -- Présent dans le fichier
               AND xix.status = cv_new -- Status des nouvelles factures
             GROUP BY xii.CODE_REGION) nb_rejets,
           -- Selection du nombre de facture intégré par code région
           (SELECT xii.CODE_REGION AS code_region, COUNT(*) AS nb
              FROM AP_INVOICES_ALL           aia,
                   DKA_IAPFACXGS_INTERFACE   xii,
                   DKA.DKA_IAPCTRFLUX_IVALUA xix
             WHERE exists
             (select 1
                      from dka_stransco_lines dsl, dka_stransco_headers dsh
                     where dsh.set_id = dsl.set_id
                       AND dsh.set_name = cv_transco_table
                       AND dsl.PARAM1_VALUE = xii.code_division)
               AND aia.attribute3 = xii.reference_lad
               and aia.attribute9 = 'DSP'
               AND xix.nom_fichier = RTRIM(xii.nom_fichier) -- Présent dans le fichier
               AND xix.status = cv_new -- Status des nouvelles factures
             GROUP BY xii.CODE_REGION) nb_integres
     WHERE liste.code_region = nb_rejets.code_region(+) -- Jointure des factures rejetées avec les divisions et CSP grace au code région
       AND liste.code_region = nb_integres.code_region(+) -- Jointure des factures intégrés avec les divisions et CSP grace au code région
       AND (nb_rejets.code_region IS NOT NULL OR
           nb_integres.code_region IS NOT NULL);
  
    vn_nb_rejets   := nvl(vn_nb_rejets, 0);
    vn_nb_integres := nvl(vn_nb_integres, 0);
  
    -- Affichage de la ligne : Nombre de factures rejetées totales
    dka_Tools_Pkg.put_outdebug_message(fnd_message.get_string(cv_msg_app,
                                                              cv_msg_pfx || '4') ||
                                       cv_fsep || vn_nb_rejets);
  
    -- Affichage de la ligne : Nombre de factures intégrées AP
    dka_Tools_Pkg.put_outdebug_message(fnd_message.get_string(cv_msg_app,
                                                              cv_msg_pfx || '5') ||
                                       cv_fsep || vn_nb_integres);
  
    -- Saut de ligne
    dka_Tools_Pkg.put_outdebug_message(cv_nl);
  
    vv_step := 'Ecriture du second bloc de données';
    -- Pour chaque ligne du curseur on a Division, CSP, factures rejetées, factures intégrées
    FOR rec_division IN cur_division LOOP
    
      -- Affichage de la ligne : Division XXX
      dka_Tools_Pkg.put_outdebug_message(fnd_message.get_string(cv_msg_app,
                                                                cv_msg_pfx || '6') ||
                                         rec_division.division);
    
      -- Nombre de factures reçues par le fichier de contrôle pour la division en cours de traitement
      BEGIN
        SELECT nb_invoices_processed
          INTO vn_nb_fac_div
          FROM DKA.DKA_IAPCTRFLUX_IVALUA
         where exists
         (select 1
                  from (SELECT dsl.param1_value AS tag
                          FROM DKA_STRANSCO_LINES   dsl,
                               DKA_STRANSCO_HEADERS dsh
                         WHERE dsh.set_name = cv_transco_table
                           AND dsh.set_id = dsl.set_id) transco
                 WHERE status = cv_new
                   AND company_value = decode(transco.tag, 'ENERGIE', 'DAL')
                   AND rec_division.division = transco.tag);
      
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vn_nb_fac_div := -1;
      END;
    
      IF vn_nb_fac_div = -1 THEN
        -- Affichage de la ligne : Pas de factures dans le fichier de contrôle
        dka_Tools_Pkg.put_outdebug_message(fnd_message.get_string(cv_msg_app,
                                                                  cv_msg_pfx || '7') ||
                                           cv_fsep || 'NR');
      ELSE
        -- Affichage de la ligne : Nombre de factures reçues
        dka_Tools_Pkg.put_outdebug_message(fnd_message.get_string(cv_msg_app,
                                                                  cv_msg_pfx || '7') ||
                                           cv_fsep || vn_nb_fac_div);
      END IF;
    
      -- Nombre de factures dans la table de travail
      IF rec_division.nom IS NOT NULL THEN
        SELECT COUNT(xii.REFERENCE_LAD)
          INTO vn_nb_fac_tab
          FROM DKA_IAPFACXGS_INTERFACE xii, DKA.DKA_IAPCTRFLUX_IVALUA xix
         WHERE RTRIM(xii.NOM_FICHIER) = xix.NOM_FICHIER
              --AND xii.NOM_FICHIER LIKE '%'|| rec_division.nom ||'%'    -- Suppression -- MSL -- 11/03/2010
           AND xii.code_division = rec_division.division -- Ajout -- MSL -- 11/03/2010
           AND xix.status = cv_new;
      ELSE
        vn_nb_fac_tab := 0;
      END IF;
    
      -- Affichage de la ligne : Nombre de factures dans la table de travail
      dka_Tools_Pkg.put_outdebug_message(fnd_message.get_string(cv_msg_app,
                                                                cv_msg_pfx || '8') ||
                                         cv_fsep || vn_nb_fac_tab);
    
      -- Entete du sous tableau
      dka_Tools_Pkg.put_outdebug_message(cv_fsep ||
                                         fnd_message.get_string(cv_msg_app,
                                                                cv_msg_pfx || '9') ||
                                         cv_fsep ||
                                         fnd_message.get_string(cv_msg_app,
                                                                cv_msg_pfx || '10') ||
                                         cv_fsep ||
                                         fnd_message.get_string(cv_msg_app,
                                                                cv_msg_pfx || '11'));
    
      -- Initialisation des variables de cumul par division
      vn_cumul_fac_rejets := 0;
      vn_cumul_fac_int    := 0;
      vn_cumul_total      := 0;
    
      vv_step := 'Ecriture du sous tableau dynamique';
      -- Remplissage du sous tableau dynamique
      FOR rec_valeur IN cur_valeur(rec_division.division) LOOP
        dka_Tools_Pkg.put_outdebug_message(rec_valeur.CSP || cv_fsep ||
                                           rec_valeur.nb_rejets || cv_fsep ||
                                           rec_valeur.nb_integres ||
                                           cv_fsep ||
                                           (rec_valeur.nb_rejets +
                                           rec_valeur.nb_integres));
      
        vn_cumul_fac_rejets := vn_cumul_fac_rejets + rec_valeur.nb_rejets;
        vn_cumul_fac_int    := vn_cumul_fac_int + rec_valeur.nb_integres;
        vn_cumul_total      := vn_cumul_total + rec_valeur.nb_rejets +
                               rec_valeur.nb_integres;
      
      END LOOP;
    
      -- Affichage de la ligne de total pour la division en cours de traitement
      dka_Tools_Pkg.put_outdebug_message(fnd_message.get_string(cv_msg_app,
                                                                cv_msg_pfx || '11') ||
                                         cv_fsep || vn_cumul_fac_rejets ||
                                         cv_fsep || vn_cumul_fac_int ||
                                         cv_fsep || vn_cumul_total);
    
      -- Facture non reçue
      IF vn_nb_fac_tab = 0 THEN
        vv_fac_nr := vv_fac_nr || cv_isep || rec_division.division;
        vb_fac_nr := TRUE;
      END IF;
    
      -- Fichier de contrôle non reçu
      IF vn_nb_fac_div = -1 THEN
        vv_controle  := vv_controle || cv_isep || rec_division.division;
        vb_fich_cont := TRUE;
      END IF;
    
      -- Gestion du message d'incohérence
      -- si nombre de factures reçues différent de nombre de factures rejetées + nbre de factures intégrées
      -- sauf si on n'a pas reçu de fichier de contrôle et qu'on a 0 factures
      IF (vn_cumul_fac_rejets + vn_cumul_fac_int) != vn_nb_fac_div THEN
        IF NOT ((vn_nb_fac_div = -1) AND (vn_nb_fac_tab = 0)) THEN
          vv_incoherence := vv_incoherence || cv_isep ||
                            rec_division.division;
          vb_incoherence := true;
        END IF;
      END IF;
    
    END LOOP;
  
    -- Saut de ligne
    dka_Tools_Pkg.put_outdebug_message(cv_nl);
  
    -- Affichage du message d'erreur si aucune facture reçue pour au moins une division
    vv_step := 'Ecriture du message en cas de facture non reçue pour une division';
    IF vb_fac_nr = TRUE THEN
      dka_Tools_Pkg.put_outdebug_message(fnd_message.get_string(cv_msg_app,
                                                                cv_msg_pfx || '13') ||
                                         LTRIM(vv_fac_nr, cv_isep));
      vb_fac_nr  := FALSE;
      vb_warning := TRUE;
    END IF;
  
    -- Affichage du message d'erreur si fichier de contrôle non reçu
    vv_step := 'Ecriture du message en cas de fichier de contrôle non reçu';
    IF vb_fich_cont = TRUE THEN
      dka_Tools_Pkg.put_outdebug_message(fnd_message.get_string(cv_msg_app,
                                                                cv_msg_pfx || '14') ||
                                         LTRIM(vv_controle, cv_isep));
      vb_fich_cont := FALSE;
      vb_warning   := TRUE;
    END IF;
  
    -- Affichage du message d'erreur si au moins une incohérence a été trouvées
    vv_step := 'Ecriture du message d''erreur en cas d''incohérence';
    IF vb_incoherence = TRUE THEN
      dka_Tools_Pkg.put_outdebug_message(fnd_message.get_string(cv_msg_app,
                                                                cv_msg_pfx || '12') ||
                                         LTRIM(vv_incoherence, cv_isep));
      vb_incoherence := FALSE;
      vb_warning     := TRUE;
    END IF;
  
    -- Si l'une des 3 erreurs est détectée, la sortie doit etre en Warning
    IF vb_warning = TRUE THEN
      RAISE e_warning;
      vb_warning := FALSE;
    END IF;
  
  EXCEPTION
    WHEN e_warning THEN
      pn_retcode := 1;
      dka_Tools_Pkg.put_log_message(cv_err_pfx || vv_step);
    WHEN e_raised THEN
      pn_retcode := 2;
      pv_errbuf  := cv_err_pfx || vv_step || cv_err_log;
      dka_Tools_Pkg.put_log_message(cv_err_pfx || vv_step);
      dka_Tools_Pkg.print_error_stack();
    WHEN OTHERS THEN
      pn_retcode := 2;
      dka_Tools_Pkg.add_error_stack('[main] ' || SQLERRM);
      pv_errbuf := cv_err_pfx || vv_step || cv_err_log;
      dka_Tools_Pkg.put_log_message(cv_err_pfx || vv_step);
      dka_Tools_Pkg.print_error_stack();
    
  END main;

  -----------------------------------------------------------------------
  -- Insertion des de la table temporaire dans la table interface Xerox
  -----------------------------------------------------------------------
  PROCEDURE insert_dka_iapctrflux_ivalua(pv_errbuf  OUT VARCHAR2,
                                         pn_retcode OUT NUMBER)
  
   IS
    -- definir variables
  
    -----------------------------------------------
    -- Curseur de lecture de la table temporaire --
    -----------------------------------------------
    CURSOR Cur_tmp IS
      SELECT date_envoi_yyyymmdd,
             company_value,
             nb_invoices_processed,
             nb_invoices_rejected,
             nb_tra_file,
             nb_pnc_file
        FROM dka.dka_iapctrflux_ivalua_tmp
       WHERE nvl(company_value, 'x') <> 'EAU';
  
    Rec_tmp Cur_tmp%ROWTYPE;
  
  BEGIN
  
    -- Les enregistrements existants de DKA.DKA_IAPCTRFLUX_IVALUA sont passés a OLD
    UPDATE dka.dka_iapctrflux_ivalua
       SET status = 'OLD'
     WHERE status = 'NEW';
  
    -- Rechercher date pour constitution du nom du fichier.
    -- NON la date qui figure dans le nom du fichier est la sysdate
  
    -- Mise a jour DKA_PARAMETERS
    UPDATE dka_parameters
       SET varchar2_value = to_char(sysdate, 'YYYYMMDD')
     WHERE program_code = 'IAPCTRFLUX_IVALUA'
       AND parameter_name = 'DATE_TRAITEMENT';
  
    -- Traitement du curseur Cur_tmp
    OPEN Cur_tmp;
    LOOP
      FETCH Cur_tmp
        INTO Rec_tmp;
      EXIT WHEN Cur_tmp%NOTFOUND;
    
      -- Chargement des nouveaux enregistrements dans DKA.DKA_IAPCTRFLUX_IVALUA
      INSERT INTO dka.dka_iapctrflux_ivalua
        (nom_fichier,
         date_envoi,
         company_value,
         nb_invoices_processed,
         nb_invoices_rejected,
         nb_tra_file,
         nb_pnc_file,
         status,
         created_by,
         creation_date,
         last_update_date,
         last_updated_by,
         last_update_login)
      VALUES
        ('DSP_' || Rec_tmp.company_value || '_' ||
         TO_CHAR(SYSDATE, 'YYYYMMDD') || '.csv',
         decode(Rec_tmp.Date_Envoi_Yyyymmdd,
                'TEMPLATE',
                trunc(sysdate),
                to_date(Rec_tmp.date_envoi_yyyymmdd, 'YYYYMMDD')),
         Rec_tmp.company_value,
         Rec_tmp.nb_invoices_processed,
         Rec_tmp.nb_invoices_rejected,
         Rec_tmp.nb_tra_file,
         Rec_tmp.nb_pnc_file,
         'NEW',
         fnd_global.user_id,
         SYSDATE,
         '',
         '',
         '');
    
    END LOOP;
    -- validation
    --pas de commit;
  
  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode := 2;
      dka_Tools_Pkg.put_log_message('[error - insert_dka_iapctrflux_ivalua] ' ||
                                    SQLCODE || ' - ' || SQLERRM);
      pv_errbuf := '[error - insert_dka_iapctrflux_ivalua] : Consultez le fichier de log';
      ROLLBACK;
    
  END insert_dka_iapctrflux_ivalua;

END DKA_IAPCTRFLUX_IVALUA_PKG;
/
SHOW ERROR PACKAGE BODY DKA_IAPCTRFLUX_XEROX_PKG;
EXIT
