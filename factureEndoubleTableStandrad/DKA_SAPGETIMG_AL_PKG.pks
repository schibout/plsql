SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

create or replace PACKAGE BODY DKA_EMPJOBSIMP_PKG IS
--------------------------------------------------------------------------------------------
-- FILENAME
--    DKA_EMPJOBSIMP_PKG.pkb  V1.0
--
-- AUTEUR
--    Capgemini
--
-- DESCRIPTION
--    Création du package de la transcodification des fonctions employé
--
-- USAGE
--    A exécuter sous SqlPlus avec user APPS sans paramètre
--
-- NOTES
--
-- PARAMETERS
--
---------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
---------------------------------------------------------------------------------------------
-- Version   Date         Qui Description
---------- -------------- --- ---------------------------------------------------------------
-- V1.0    04/10/2016     PBR Creation

---------------------------------------------------------------------------------------------

 --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PRIVEES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    TYPE summary_typ IS RECORD
    (
     loaded_emp_rows            NUMBER      -- Nb de ligne traitées
    ,traited_rows               NUMBER      -- Nb de lignes prises en charge
    ,existing_emp               NUMBER      -- Nb d'employés non existant
    ,existing_transco           NUMBER      -- Nb de transco inexistante
    ,created_job                NUMBER      -- Nb de fonctions créés
    ,updated_assignment         NUMBER      -- Nb d'assignment mis à jour
    ,rejected_jobs              NUMBER      -- Nb de fonction rejetée
    ,rejected_assignment        NUMBER      -- Nb d'assignment rejeté
    ,purged_rows                NUMBER      -- Nb de Lignes purgées en table spécifique
    );

    g_summary                      summary_typ;

    g_user_id                      fnd_user.user_id%TYPE;
    g_login_id                     fnd_logins.login_id%TYPE;
    g_org_id                       hr_all_organization_units.organization_id%TYPE;
    g_request_id                   fnd_concurrent_requests.request_id%TYPE;
    G_Loader_Request_Id            Fnd_Concurrent_Requests.Request_Id%Type;
    g_int_request_id               Fnd_Concurrent_Requests.Request_Id%Type;
    gv_printer                     fnd_concurrent_requests.printer%TYPE;
    g_number_of_copies             fnd_concurrent_requests.number_of_copies%TYPE;
    g_tempo                        NUMBER;
    V_DATE_GL                      DATE;


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
.* ----------------- ------------------------------------------------------
 * p_errbuf         Retour de message éventuel
 * p_retcode        Statut du traitement en sortie
 ************************************************************************
 */
  PROCEDURE init (
        p_errbuf    OUT      VARCHAR2,
        p_retcode   OUT      NUMBER)
  IS

    v_current_program_unit    VARCHAR2(30);
    v_step_program_error      VARCHAR2(1000);
    program_error             EXCEPTION;

  BEGIN

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début init');

        ----------------------------------
        -- Initialisation des variables --
        ----------------------------------
        p_errbuf  := NULL;
        p_retcode := 0;
        v_current_program_unit := 'INIT';

        ------------------------
        -- Variables globales --
        ------------------------

        g_user_id                      := fnd_global.user_id;
        g_login_id                     := fnd_global.login_id;
        g_request_id                   := fnd_global.conc_request_id;
        g_org_id                       := fnd_profile.value ('ORG_ID');
        g_tempo                        := 20;

        -- Variables globales de comptage

        g_summary.loaded_emp_rows         := 0;
        g_summary.traited_rows            := 0;
        g_summary.existing_emp            := 0;
        g_summary.existing_transco        := 0;
        g_summary.updated_assignment      := 0;
        g_summary.rejected_jobs           := 0;
        g_summary.rejected_assignment     := 0;
        g_summary.purged_rows             := 0;

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin init');

        BEGIN
           SELECT printer
                 ,number_of_copies
           INTO   gv_printer
                 ,g_number_of_copies
           FROM   fnd_concurrent_requests fcr
           WHERE  fcr.request_id = g_request_id;
        EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
           Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Erreur de récupération de l''imprimante');
           gv_printer := NULL;
           g_number_of_copies := 0;
        END;

  EXCEPTION
        WHEN program_error THEN
             fnd_file.put_line(fnd_file.log, 'ERREUR : ' || v_step_program_error);
             RAISE;
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'INIT : ' ||SQLERRM;
  END init;


 /*
 *************************************************************************
 * PROCEDURE NAME : Output_Header
 *
 * DESCRIPTION
 *  Procédure pour insérer une en-tête dans le fichier de sortie
 *
 * PARAMETERS
 * ==========
 * NAME              DESCRIPTION
 * ----------------- ------------------------------------------------------
 *
 *
 ************************************************************************
 */

  PROCEDURE output_header
  IS
        cv_line                     VARCHAR2 (100);
        v_conc_program_name         fnd_concurrent_programs.concurrent_program_name%TYPE;
        v_user_conc_program_name    fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;
  BEGIN

        cv_line    := '+-------------------------------------------------------------------------+';

        ----- Récupération des noms abrégé et long du traitement en fonction de la langue -----
        BEGIN
            SELECT fcp.concurrent_program_name,
                   fcpt.user_concurrent_program_name
            INTO   v_conc_program_name,
                   v_user_conc_program_name
            FROM   fnd_concurrent_programs fcp,
                   fnd_concurrent_programs_tl fcpt
            WHERE  fcp.application_id = Fnd_Global.prog_appl_id
            AND    fcp.concurrent_program_id = Fnd_Global.conc_program_id
            AND    fcpt.application_id = Fnd_Global.prog_appl_id
            AND    fcpt.concurrent_program_id = Fnd_Global.conc_program_id
            AND    fcpt.LANGUAGE = Fnd_Global.current_language;
        EXCEPTION
            WHEN OTHERS
            THEN
                v_user_conc_program_name    := '???????';
                v_conc_program_name         := '???????';
        END;


        Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10));
        Fnd_File.put_line (Fnd_File.output, 'Nom du traitement  : ' || v_user_conc_program_name);
        Fnd_File.put_line (Fnd_File.output, 'Code du traitement : ' || v_conc_program_name);
        Fnd_File.put_line (Fnd_File.output, 'Programme lancé le : ' || TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || CHR(10));
        Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10) || CHR(10));
  END output_header;


 /*
 *************************************************************************
 * PROCEDURE NAME : Output_End
 *
 * DESCRIPTION
 *  Procédure pour insérer une fin dans le fichier de sortie
 *
 * PARAMETERS
 * ==========
 * NAME              DESCRIPTION
 * ----------------- ------------------------------------------------------
 *
 *
 ************************************************************************
 */

  PROCEDURE output_end
  IS
        cv_line                     VARCHAR2 (100);
  BEGIN

        cv_line    := '+-------------------------------------------------------------------------+';

        Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10));
        Fnd_File.put_line (Fnd_File.output, 'Programme terminé le : ' || TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || CHR(10));
        Fnd_File.put_line (Fnd_File.output, cv_line);
  END output_end;

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
.* -----------------  ------------------------------------------------------
 * p_directory       Répertoire du fichier
 * p_file_name       Nom du fichier à charger
 * p_errbuf          Retour de message éventuel
 * p_retcode         Statut du traitement en sortie
 *
 ************************************************************************
 */
  PROCEDURE Launch_Loader(p_Errbuf            OUT VARCHAR2,
                          p_retcode           OUT NUMBER)
  IS
        v_phase                  VARCHAR2 (100);
        v_status                 VARCHAR2 (100);
        v_dev_phase              VARCHAR2 (100);
        v_dev_status             VARCHAR2 (100);
        v_message                VARCHAR2 (100);
        b_result                  BOOLEAN;

  BEGIN
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début Launch_Loader');
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                                         'Lancement de chargement du fichier dans la table d''interface spécifique : ');

        fnd_file.put_line(fnd_file.OUTPUT, CHR(10));
        fnd_file.put_line(fnd_file.OUTPUT, 'CHARGEMENT DU FICHIER :');
        fnd_file.put_line(fnd_file.OUTPUT, '----------------------');
        ------------------------------------------------------
        -- Lancement du traitement de chargement du fichier --
        ------------------------------------------------------
        -- Positionnement des options d'impression
        b_result := fnd_request.set_print_options(printer => gv_printer,
                                                  copies => g_number_of_copies);
        -- Lancement du traitement
        g_loader_request_id         := Fnd_Request.submit_request (
                                                                   'DKA'                            -- APPL
                                                                  ,'DKA_LOADER_EMPJOBSIMP'          -- PROG
                                                                  ,NULL                             -- PROGRAM_NAME
                                                                  ,NULL                             -- START
                                                                  ,FALSE                            -- SUB_REQUEST
                                                                  );

        IF g_loader_request_id = 0
        THEN
            p_retcode    := 2;
            fnd_file.put_line(fnd_file.LOG, 'ERREUR : Le traitement de chargement du fichier a échoué' || CHR(10) ||
                                            'PROGRAMME  : DKA_LOADER_EMPJOBSIMP'
                                            );
            Fnd_File.put_line (Fnd_File.OUTPUT, '====> ERREUR : Le traitement de chargement du fichier a échoué');
        ELSE
            COMMIT;
            Fnd_File.put_line(Fnd_File.LOG, '=> LOAD REQUEST ID= ' || g_loader_request_id);
            Fnd_File.put_line(Fnd_File.OUTPUT, '. Numéro du traitement de chargement du fichier : ' || g_loader_request_id);

            -- Attente de la fin du traitement
            IF NOT (Fnd_Concurrent.wait_for_request (g_loader_request_id, g_tempo, 0, v_phase, v_status, v_dev_phase, v_dev_status, v_message))
            THEN
                p_Errbuf  := v_Message;
                Fnd_file.put_line(Fnd_file.log, 'ERREUR : Attente de la fin du programme de chargement du fichier dépassée : Fin du traitement' || CHR(10) ||
                                                'MESSAGE : ' || v_Message || CHR(10) );
            END IF;

            IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL')
            THEN
                Fnd_File.put_line(Fnd_File.LOG, 'COMPLETION= ' || v_dev_phase || '/' || v_dev_status);
                Fnd_File.put_line(Fnd_File.OUTPUT, '. Statut de fin : ' || v_phase || '/' || v_status);

                SELECT count(1)
                INTO g_summary.loaded_emp_rows
                FROM DKA_EMPLOYEE_JOBS_TMP
                ;

            ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING')
            THEN
                Fnd_File.put_line (Fnd_File.LOG, 'Fin du traitement de chargement en warning '|| g_loader_request_id);
                p_retcode    := 1;

            ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL')
            THEN
                p_retcode := 2;
                p_Errbuf  := 'ERREUR : Fin anormale du traitement de chargement : '||v_Message;

                fnd_file.put_line(fnd_file.LOG, 'ERREUR : Fin anormale du traitement de chargement '|| g_loader_request_id  || CHR(10) ||
                                                'Phase/Statut : ' || v_dev_phase || '/' || v_dev_status || CHR(10) ||
                                                'MESSAGE : ' || v_message || CHR(10) );
                Fnd_File.put_line (Fnd_File.OUTPUT, '===> ERREUR : Fin anormale du traitement de chargement '||g_loader_request_id);
            END IF;
        END IF;
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin Launch_Loader');

  EXCEPTION
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'LAUNCH_LOADER : ' ||SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure Launch_Loader : EXCEPTION OTHERS ');
  END Launch_Loader;


 /*
 *************************************************************************
 * PROCEDURE NAME : validate_data
 *
 * DESCRIPTION
 *  Procédure d'insertion dans les tables finales
 *
 * PARAMETERS
 * ==========
 * NAME               DESCRIPTION
.* -----------------  ------------------------------------------------------
 * p_errbuf          Retour de message éventuel
 * p_retcode         Statut du traitement en sortie
 *
 ************************************************************************
 */
  PROCEDURE validate_data(  p_Errbuf            OUT VARCHAR2,
                            p_retcode           OUT NUMBER
                          )
  IS
    v_message                 VARCHAR2(500);
    vv_emp_exist              VARCHAR2(50);
    vv_transco_exist          VARCHAR2(50);


    CURSOR cur_emp_jobs IS
      SELECT *
      FROM DKA_EMPLOYEE_JOBS_TMP;

    CURSOR cur_jobs_transco IS
      SELECT *
      FROM DKA_REP_TRANSCO_LINES
      WHERE 1=1
      AND TRANSCO_NAME = '022_FONCTIONS';

  BEGIN
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début validate_data');
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Validation des données dans les tables spécifiques : ');

        FOR emp IN cur_emp_jobs LOOP
        --On vérifie si l'employé existe en 12.
          BEGIN
            SELECT LAST_NAME
            INTO vv_emp_exist
            FROM per_all_people_f
            where employee_number = emp.employee_number;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vv_emp_exist := NULL;
          END;

          IF vv_emp_exist IS NOT NULL THEN
          -- on met à jour le champ emp_exists dans la table spé.
            UPDATE DKA_EMPLOYEE_JOBS_TMP
            SET emp_exist = 'Y'
            WHERE employee_number = emp.employee_number;
          ELSE
          -- on met à jour le champ emp_exists dans la table spé.
            UPDATE DKA_EMPLOYEE_JOBS_TMP
            SET emp_exist = 'N'
            WHERE employee_number = emp.employee_number;
            
            fnd_file.put_line(fnd_file.OUTPUT,'   . L''employé n''existe pas dans Oracle : '|| emp.employee_number);
            g_summary.existing_emp := g_summary.existing_emp + 1;
          END IF;

          --on vérifie si la transcodification existe dans la table de transco
          BEGIN
            select column_01
            INTO vv_transco_exist
            FROM DKA_REP_TRANSCO_LINES
            WHERE column_01 = emp.name
            AND TRANSCO_NAME = '022_FONCTIONS';
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vv_transco_exist := NULL;
          END;
        COMMIT;
        END LOOP;
  EXCEPTION
        WHEN OTHERS THEN
            p_retcode   := 2;
            p_errbuf    := 'validate_data : ' ||SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure validate_data : EXCEPTION OTHERS ');
  END validate_data;


 /*
 *************************************************************************
 * PROCEDURE NAME : import_data
 *
 * DESCRIPTION
 *  Procédure de création des assignments et des jobs.
 *
 * PARAMETERS
 * ==========
 * NAME               DESCRIPTION
.* -----------------  ------------------------------------------------------
 * p_errbuf          Retour de message éventuel
 * p_retcode         Statut du traitement en sortie
 *
 ************************************************************************
 */
  PROCEDURE import_data(  p_Errbuf            OUT VARCHAR2,
                          p_retcode           OUT NUMBER
                          )
  IS

  vv_new_job_name             VARCHAR2(255);

  --Job information
  vn_job_id                   NUMBER;

  --Assignement information
  vn_assignment_id                  NUMBER;
  vd_old_eff_start_date             DATE;
  vv_update_type                    VARCHAR2(25);
  vn_old_obj_vers_number            per_all_assignments_f.object_version_number%type;
  vn_obj_vers_number_asg            per_all_assignments_f.object_version_number%type;
  vn_special_ceiling_step_id        NUMBER := NULL;
  vn_people_group_id                NUMBER := NULL;
  vn_soft_coding_keyflex_id         NUMBER := NULL;
  vv_group_name                     VARCHAR2(255);
  vd_effective_start_date           DATE;
  vd_effective_end_date             DATE;
  vb_org_now_no_manager_warning     BOOLEAN;
  vb_other_manager_warning          BOOLEAN;
  vb_spp_delete_warning             BOOLEAN;
  vv_entries_changed_warning        VARCHAR2(255);
  vb_tax_district_changed_war       BOOLEAN;
  vv_concatenated_segments          VARCHAR2(255);
  vv_gsp_post_process_warning       VARCHAR2(255);


  CURSOR valid_employee IS
    SELECT *
    FROM DKA_EMPLOYEE_JOBS_TMP
    WHERE 1=1
    AND emp_exist = 'Y';
  BEGIN

    FOR cur_emp IN valid_employee LOOP

    --Etape 1: On récupére la transcodification de la fonction
      BEGIN
        SELECT OUT_01--compléter avec les champs de la table de transco
        INTO vv_new_job_name
        FROM DKA_REP_TRANSCO_LINES
        WHERE 1=1
        AND TRANSCO_NAME = '022_FONCTIONS'
        AND column_01 = REPLACE(REPLACE(cur_emp.name,CHR(10),''), CHR(13), '');
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vv_new_job_name   := NULL;
      END;

      IF vv_new_job_name IS NULL THEN
        --On ne modifie pas l'assignment
        UPDATE DKA_EMPLOYEE_JOBS_TMP
        SET FLAG = 'E'
        WHERE employee_number = cur_emp.employee_number;
        
        g_summary.existing_transco := g_summary.existing_transco + 1;
        fnd_file.put_line(fnd_file.OUTPUT,'   . La transcodification n''existe pas pour :  '|| cur_emp.name);
      ELSE
      
      --Etape 2: On vérifie si le JOB existe.
        BEGIN
          SELECT job_id
          INTO vn_job_id
          FROM per_jobs
          WHERE name = vv_new_job_name;
        EXCEPTION
         WHEN NO_DATA_FOUND THEN
          vn_job_id := NULL;
        END;

          IF vn_job_id IS NULL THEN
            UPDATE DKA_EMPLOYEE_JOBS_TMP
            SET FLAG = 'E'
            WHERE employee_number = cur_emp.employee_number;
            
            fnd_file.put_line(fnd_file.OUTPUT,'   . Le job n''existe pas pour :  '|| vv_new_job_name);
            g_summary.rejected_jobs := g_summary.rejected_jobs + 1;

          ELSE
            --Etape 4: On récupére les informations de l'assignement
              BEGIN
      
                SELECT paa.assignment_id,
                       paa.object_version_number,
                       paa.effective_start_date
                INTO vn_assignment_id,
                     vn_old_obj_vers_number,
                     vd_old_eff_start_date
                FROM per_all_people_f pap
                JOIN per_all_assignments_f paa ON (pap.person_id = paa.person_id)
                WHERE 1=1
                AND SYSDATE BETWEEN paa.effective_start_date and paa.effective_end_date
                AND pap.employee_number = cur_emp.employee_number;
      
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  vn_assignment_id := NULL;
              END;
            --Etape 5: On met à jour l'assignment.
              IF vn_assignment_id IS NOT NULL THEN
                vn_obj_vers_number_asg := vn_old_obj_vers_number;
                
                IF vd_old_eff_start_date = trunc(SYSDATE) THEN
                  vv_update_type := 'CORRECTION';
                ELSE
                  vv_update_type := 'UPDATE';
                END IF;
                
                HR_ASSIGNMENT_API.update_emp_asg_criteria(p_effective_date                =>  TRUNC(SYSDATE),
                                                          p_datetrack_update_mode         =>  vv_update_type,
                                                          p_assignment_id                 =>  vn_assignment_id,
                                                          p_validate                      =>  FALSE,
                                                          p_job_id                        =>  vn_job_id,
                                                          p_object_version_number         =>  vn_obj_vers_number_asg,
                                                          p_special_ceiling_step_id       =>  vn_special_ceiling_step_id,
                                                          p_people_group_id               =>  vn_people_group_id,
                                                          p_soft_coding_keyflex_id        =>  vn_soft_coding_keyflex_id,
                                                          p_group_name                    =>  vv_group_name,
                                                          p_effective_start_date          =>  vd_effective_start_date,
                                                          p_effective_end_date            =>  vd_effective_end_date,
                                                          p_org_now_no_manager_warning    =>  vb_org_now_no_manager_warning,
                                                          p_other_manager_warning         =>  vb_other_manager_warning,
                                                          p_spp_delete_warning            =>  vb_spp_delete_warning,
                                                          p_entries_changed_warning       =>  vv_entries_changed_warning,
                                                          p_tax_district_changed_warning  =>  vb_tax_district_changed_war,
                                                          p_concatenated_segments         =>  vv_concatenated_segments,
                                                          p_gsp_post_process_warning      =>  vv_gsp_post_process_warning);
      
                IF vn_old_obj_vers_number != vn_obj_vers_number_asg THEN
                  -- On confirme la mise à jour de l'assignment.
                  UPDATE DKA_EMPLOYEE_JOBS_TMP
                  SET FLAG = 'OK'
                  WHERE employee_number = cur_emp.employee_number;                 
                  g_summary.updated_assignment := g_summary.updated_assignment + 1;
      
                ELSE
                  -- On écrit dans les logs le problème de mise à jour de l'assignment et on passe à l'enregistrement suivant.
                  UPDATE DKA_EMPLOYEE_JOBS_TMP
                  SET FLAG = 'E'
                  WHERE employee_number = cur_emp.employee_number;
                  g_summary.rejected_assignment := g_summary.rejected_assignment + 1;
                  Fnd_File.put_line (Fnd_File.LOG, 'Erreur de mise à jour de l''assignment pour l''employé : ' || cur_emp.employee_number);
      
                END IF;
              ELSE
              --erreur l'assignment n'est pas trouvé pour l'employé en cours !
                UPDATE DKA_EMPLOYEE_JOBS_TMP
                SET FLAG = 'E'
                WHERE employee_number = cur_emp.employee_number;               
                g_summary.rejected_assignment := g_summary.rejected_assignment + 1;     
                Fnd_File.put_line (Fnd_File.LOG, 'Aucun assignment pour l''employé : ' || cur_emp.employee_number);
                
              END IF;
        END IF;
      END IF;

    g_summary.traited_rows := g_summary.traited_rows + 1;
    
    END LOOP;

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin import_data');

  EXCEPTION
        WHEN OTHERS THEN
            p_retcode   := 2;
            p_errbuf    := 'import_data : ' ||SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure import_data : EXCEPTION OTHERS ');
  END import_data;


 /*
 *************************************************************************
 * PROCEDURE NAME : Bilan
 *
 * DESCRIPTION
 *  Procédure de génération du bilan du traitement d'interface
 *
 * PARAMETERS
 * ==========
 * NAME                 DESCRIPTION
.* -------------------- ---------------------------------------------------
 * p_errbuf            Retour de message éventuel
 * p_retcode           Statut du traitement en sortie
 ************************************************************************
 */
  PROCEDURE Report_Bilan(p_Errbuf            OUT VARCHAR2,
                         p_retcode           OUT NUMBER
                         )
  IS

  BEGIN

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début Report_Bilan');

        --------------------
        -- Initialisation --
        --------------------

        p_Errbuf  := NULL;
        p_retcode := 0;

        fnd_file.put_line(fnd_file.OUTPUT,CHR(10));
        fnd_file.put_line(fnd_file.OUTPUT,'BILAN :');
        fnd_file.put_line(fnd_file.OUTPUT,'-------');

        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre de lignes chargées dans la table spécifique          : '||TO_CHAR(g_summary.loaded_emp_rows));
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''employéq inexistant dans Oracle                    : '||TO_CHAR(g_summary.existing_emp) || CHR(10));
        
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''employés traités par le traitement                 : '||TO_CHAR(g_summary.traited_rows) || CHR(10) );
        
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre de transcodification inexistante                     : '||TO_CHAR(g_summary.existing_transco));       
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''erreurs sur les fonctions                          : '|| TO_CHAR(g_summary.rejected_jobs));
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''erreurs sur les assignments                        : '|| TO_CHAR(g_summary.rejected_assignment)|| CHR(10));
        
        fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''assignment mis à jour                              : '|| TO_CHAR(g_summary.updated_assignment));

        fnd_file.put_line(fnd_file.OUTPUT,CHR(10));
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin Report_Bilan');


  EXCEPTION
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'REPORT_BILAN : ' ||SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure Report_Bilan : EXCEPTION OTHERS ');
  END Report_Bilan;



/*
*************************************************************************
 * PROCEDURE NAME : purge_data
 *
 * DESCRIPTION
 *  Procédure de purge des données
 *
 * PARAMETERS
 * ==========
 * NAME               DESCRIPTION
 * -----------------  ------------------------------------------------------
 *
 *************************************************************************/
  PROCEDURE purge_data(p_Errbuf            OUT VARCHAR2,
                       p_retcode           OUT NUMBER
                              )
  IS

  BEGIN

     DELETE FROM DKA_EMPLOYEE_JOBS_TMP;
     g_summary.purged_rows := SQL%ROWCOUNT;
     Fnd_File.Put_Line(Fnd_File.LOG, '=> Deleted rows '||TO_CHAR(g_summary.purged_rows));

  EXCEPTION
        WHEN OTHERS THEN
            p_retcode   := 2;
            p_errbuf    := 'PURGE_DATA : ' ||SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure PURGE_DATA : EXCEPTION OTHERS ');
  END purge_data;
 /*
 *************************************************************************
 * PROCEDURE NAME : main
 *
 * DESCRIPTION
 *  Procédure principale
 *
 * PARAMETERS
 * ==========
 * NAME              DESCRIPTION
 * ----------------- ------------------------------------------------------
 * p_errbuf          Retour de message éventuel
 * p_retcode         Statut du traitement en sortie
 ************************************************************************
 */

  PROCEDURE main(p_errbuf       IN    OUT VARCHAR2,
                 p_retcode            OUT NUMBER
                 )
  IS

    v_current_program_unit     VARCHAR2(30);
    v_errbuf                   VARCHAR2(2500);
    v_retcode                  NUMBER;
    Erreur_Programme           EXCEPTION;
  BEGIN

      ----------------------------
      -- PHASE D'INITIALISATION --
      ----------------------------
      v_current_program_unit := 'main';
      Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'DEBUT DE L''INTERFACE');

      Output_Header;

      Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'PHASE D''INITIALISATION');

      v_errbuf  := NULL;
      v_retcode := 0;

      Init(v_errbuf, v_retcode);

      IF v_retcode = 2
      THEN
          p_Errbuf  := v_errbuf;
          p_retcode := v_retcode;
          RAISE Erreur_Programme;
      END IF;

      -------------------------------------------
      -- PHASE DE PURGE DES ANCIENNES DONNEES  --
      -------------------------------------------
      Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'PURGE DES DONNEES');
      purge_data(v_errbuf,
                    v_retcode
                   );
      IF v_retcode = 2
      THEN
          p_Errbuf  := v_errbuf;
          p_retcode := v_retcode;
          RAISE Erreur_Programme;
      END IF;

      ------------------------------------
      -- PHASE DE CHARGEMENT DU FICHIER --
      ------------------------------------
      Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'PHASE DE CHARGEMENT DU FICHIER');


      -- Lancement du programme de chargement
      Launch_Loader(v_errbuf,
                    v_retcode
                   );
      IF v_retcode = 2
        THEN
        RAISE Erreur_Programme;
      END IF;

      -- Lancement de validation des données
      validate_data(v_errbuf,
                   v_retcode);
      IF v_retcode = 2
      THEN
          RAISE Erreur_Programme;
      END IF;

      -- Lancement de l'insertion des données
      import_data(v_errbuf,
                   v_retcode);
      IF v_retcode = 2
      THEN
          RAISE Erreur_Programme;
      END IF;

      -- bilan
      Report_Bilan(p_Errbuf,
                   p_retcode);

      ---------------------------------------
      -- PHASE DE FIN DU TRAITEMENT MAITRE --
      ---------------------------------------
      IF p_retcode = 2
      THEN
         p_errbuf := 'ATTENTION : Erreur bloquante : '||p_errbuf;
      ELSIF (g_summary.rejected_assignment > 0 OR g_summary.rejected_jobs > 0 OR g_summary.existing_emp > 0 OR g_summary.existing_transco > 0)
      THEN
         p_errbuf := 'ATTENTION : Il y a des cas de rejet ou avertissement.';
         p_retcode := 1;
      ELSIF (g_summary.loaded_emp_rows = 0)
      THEN
         p_errbuf := 'ATTENTION : Aucun enregistrement chargé.';
         p_retcode := 1;
      ELSE
         p_errbuf := 'Fin normale du traitement - Aucun rejet.';
         p_retcode := 0;
      END IF;

      COMMIT;

      Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
      Fnd_File.put_line (Fnd_File.OUTPUT, CHR(10)||p_errbuf||CHR(10));
      output_end;
      Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'FIN DE L''INTERFACE');

  EXCEPTION
        WHEN Erreur_Programme
        THEN
            p_retcode   := 2;
            p_errbuf    := v_errbuf;
            --Fnd_File.put_line (Fnd_Filxe.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.OUTPUT, CHR(10)||p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure '||v_current_program_unit||' : EXCEPTION Erreur_Traitement ');
            Fnd_File.put_line (Fnd_File.OUTPUT, '==> Fin de la procédure '||v_current_program_unit||' : EXCEPTION Erreur_Traitement ');
       WHEN OTHERS
       THEN
           fnd_concurrent.af_rollback;
           p_retcode := 2;
           Fnd_File.put_line (Fnd_File.Log,'Erreur technique sur le composant   : '||'DKA_REPARFACTIMP_PKG.' || v_current_program_unit||CHR(10)||'A retourné     : '||SQLERRM);
           Fnd_File.put_line (Fnd_File.Output ,CHR(10) || '==> Erreur technique (voir journal du traitement)' || CHR(10));
           p_errbuf := SQLERRM;
  END main;
  
END DKA_EMPJOBSIMP_PKG;

/
SHOW ERRORS
EXIT