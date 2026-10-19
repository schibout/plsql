create or replace PACKAGE BODY DKA_REPAPDESAC_PKG IS
  --------------------------------------------------------------------------------
  -- Nom du fichier : DKA_REPAPDESAC_PKG.pkb                                           
  -- Version        : 1.0                                                               
  -- Auteur         : Maxime EGOT / SOCIETE : CAPGEMINI                                 
  -- Date           : 03/05/2017                                                        
  --------------------------------------------------------------------------------
  -- Traitement     : DKA : desactivation des sites fournisseur / POST-REPRISE                    
  --                                                                             
  --------------------------------------------------------------------------------
  -- Historique
  -- Date       Qui Description
  -- ---------- --- --------------------------------------------------------------
  -- 
  --------------------------------------------------------------------------------

  --*************************************************************************
  -- CONSTANTES ET VARIABLES PRIVEES
  --*************************************************************************
  g_user_id    fnd_user.user_id%TYPE;
  g_login_id   fnd_logins.login_id%TYPE;
  g_request_id fnd_concurrent_requests.request_id%TYPE;

  /*
  *************************************************************************
  * PROCEDURE NAME : init
  *
  * DESCRIPTION
  *  Procédure d'initialisation des variables globales
  *
  * PARAMETERS
  * ==========
  * NAME              DESCRIPTION
  * ----------------- ------------------------------------------------------
  * p_errbuf         Retour de message éventuel
  * p_retcode        Statut du traitement en sortie
  ************************************************************************
  */

  PROCEDURE init(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS
  
  BEGIN
  
    ------------------------
    -- Variables globales --
    ------------------------
    g_login_id   := fnd_global.login_id;
    g_request_id := fnd_global.conc_request_id;
    g_user_id    := fnd_global.user_id;
  
  EXCEPTION
    WHEN program_error THEN
      p_errbuf := 'init: ' || SQLERRM;
      Dka_Tools_Pkg.put_log_message('ERREUR : ' || p_errbuf);
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'init: ' || SQLERRM;
      Dka_Tools_Pkg.put_log_message('ERREUR : ' || p_errbuf);
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
  * ----------------- ------------------------------------------------------
  * p_errbuf         Retour de message éventuel
  * p_retcode        Statut du traitement en sortie
  ************************************************************************
  */

  PROCEDURE init_environnement(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS
  
    v_resp_id      NUMBER;
    v_resp_appl_id NUMBER;
  
  BEGIN
  
    SELECT responsibility_id, application_id
      INTO v_resp_id, v_resp_appl_id
      FROM fnd_responsibility fr
     WHERE fr.responsibility_key = 'TOUT_AP_ADMINISTRATEUR';
  
    fnd_global.apps_initialize(g_user_id, v_resp_id, v_resp_appl_id);
    MO_GLOBAL.INIT('SQLAP');
  
  EXCEPTION
    WHEN program_error THEN
      p_errbuf := 'init_environnement: ' || SQLERRM;
      Dka_Tools_Pkg.put_log_message('ERREUR : ' || p_errbuf);
    WHEN NO_DATA_FOUND THEN
      p_retcode := 1;
      p_errbuf  := 'init_environnement: ' || SQLERRM;
      Dka_Tools_Pkg.put_log_message('ERREUR : ' || p_errbuf);
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'init_environnement: ' || SQLERRM;
      Dka_Tools_Pkg.put_log_message('ERREUR : ' || p_errbuf);
  END init_environnement;

  /*
  *************************************************************************
  * PROCEDURE NAME : list_sites
  *
  * DESCRIPTION
  *  Procédure permettant la maj et le listing des sites
  *
  * PARAMETERS
  * ==========
  * NAME              DESCRIPTION
  * ----------------- ------------------------------------------------------
  * p_errbuf         Retour de message éventuel
  * p_retcode        Statut du traitement en sortie
  ************************************************************************
  */

  PROCEDURE list_sites(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER, p_simulation VARCHAR2) IS
  
    CURSOR cur_sites IS
      SELECT asu.segment1, asu.vendor_name, assa.vendor_site_code, haou.name, assa.attribute13
        FROM ap_suppliers asu, ap_supplier_sites_all assa, hr_all_organization_units haou
       WHERE assa.vendor_id = asu.vendor_id
         AND haou.organization_id = assa.org_id
         AND assa.attribute4 = 'UPDATE_FLAG_RDD'
         FOR UPDATE of assa.purchasing_site_flag, assa.pay_site_flag, assa.inactive_date, assa.attribute4;
  
    vn_cpt_update NUMBER := 0;
    vn_cpt_sites  NUMBER := 0;
  
  BEGIN
  
    -- Affichage du nombre de sites fournisseur mis a jour
    SELECT COUNT(1)
      INTO vn_cpt_update
      FROM ap_suppliers asu, ap_supplier_sites_all assa, hr_all_organization_units haou
     WHERE assa.vendor_id = asu.vendor_id
       AND haou.organization_id = assa.org_id
       AND assa.attribute4 = 'UPDATE_FLAG_RDD';
    
    IF p_simulation = 'NON' THEN
       Dka_Tools_Pkg.put_outdebug_message('Nombre de sites fournisseur mis à jour: ' || vn_cpt_update);
       Dka_Tools_Pkg.put_outdebug_message('Liste des sites mis à jour :');
    ELSE
       Dka_Tools_Pkg.put_outdebug_message('Nombre de sites fournisseur sélectionnés: ' || vn_cpt_update);
       Dka_Tools_Pkg.put_outdebug_message('Liste des sites sélectionnés :');
    END IF;
    
    -- Liste l'ensemble des sites a mettre a jour
    Dka_Tools_Pkg.put_outdebug_message('-------------------------------------------------------------------------------------------------------------------------------------------------------');
    Dka_Tools_Pkg.put_outdebug_message('Numéro               Nom fournisseur                                 Site fournisseur                  Organisation               Référence            ');
    Dka_Tools_Pkg.put_outdebug_message('Fournisseur                                                                                                                       (11i)                ');
    Dka_Tools_Pkg.put_outdebug_message('-------------------------------------------------------------------------------------------------------------------------------------------------------');
  
    FOR rec_sites IN cur_sites LOOP
    
      IF p_simulation = 'NON' THEN
      
        -- Mets a jour les champs "site d'achat" et "site de reglement" pour mettre la valeur "Non"
        UPDATE ap_supplier_sites_all assa
           SET assa.purchasing_site_flag = 'N',
               assa.pay_site_flag        = 'N',
               assa.inactive_date        = sysdate, 
               assa.attribute4 = NULL
         WHERE CURRENT OF cur_sites;
      
      END IF;
    
      -- Compteur pour le nombre total de lignes selectionnees
      vn_cpt_sites := vn_cpt_sites + 1;
    
      Dka_Tools_Pkg.put_outdebug_message(RPAD(substr(rec_sites.segment1, 1, 21), 21, ' ') ||
                                         RPAD(substr(rec_sites.vendor_name, 1, 48), 48, ' ') ||
                                         RPAD(substr(rec_sites.vendor_site_code, 1, 34), 34, ' ') ||
                                         RPAD(substr(rec_sites.name, 1, 27), 27, ' ') ||
                                         RPAD(substr(rec_sites.attribute13, 1, 28), 28, ' '));
    
    END LOOP;
  
    Dka_Tools_Pkg.put_outdebug_message('-------------------------------------------------------------------------------------------------------------------------------------------------------');
  
    COMMIT;
  
    IF vn_cpt_sites = 0 THEN
      p_retcode := 1;
    END IF;
  
  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'list_sites: ' || SQLERRM;
      Dka_Tools_Pkg.put_log_message('ERREUR : ' || p_errbuf);
      ROLLBACK;
  END list_sites;

  /*=====================================================================================*/
  /* PROCEDURE NAME : main
  /*
  /* DESCRIPTION
  /*  Procédure principale de l'interface de création des fournisseurs
  /*
  /* PARAMETERS
  /* ==========
  /* NAME              DESCRIPTION
  /* ----------------- ------------------------------------------------------
  /* p_errbuf         Retour de message éventuel
  /* p_retcode        Statut du traitement en sortie
  /* p_simulation     Permet de lister l'ensemble des sites a metre a jour
  /*=====================================================================================*/

  PROCEDURE MAIN(p_errbuf IN OUT VARCHAR2, p_retcode IN OUT NUMBER, p_simulation VARCHAR2) IS
  
  BEGIN
  
    Dka_Tools_Pkg.put_log_message('Initialisation des variables');
    Init(p_errbuf, p_retcode);
  
    Dka_Tools_Pkg.put_log_message('Initialisation de l''environnement');
    init_environnement(p_errbuf, p_retcode);
  
    Dka_Tools_Pkg.put_log_message('Listing et Maj des sites');
    list_sites(p_errbuf, p_retcode, p_simulation);
  
  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'Erreur technique sur le composant: ' || SUBSTR(SQLERRM, 1, 200);
      Dka_Tools_Pkg.put_log_message('ERREUR : ' || p_errbuf);
      ROLLBACK;
    
  END main;

END DKA_REPAPDESAC_PKG;
/
SHOW ERRORS;
EXIT
