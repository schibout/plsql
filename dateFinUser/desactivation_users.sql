-- =====================================================================
-- Desactivation d'utilisateurs Oracle EBS a une date donnee
-- =====================================================================
-- Pose FND_USER.END_DATE via l'API supportee APPS.FND_USER_PKG.UpdateUser.
-- Les responsabilites et les roles ne sont PAS touches.
--
-- Ce fichier n'est pas destine a etre lance seul : le lanceur
-- Desactiver_Users.ps1 y injecte la liste des matricules a la place du
-- marqueur -- @@LISTE_MATRICULES@@ et definit les variables ci-dessous.
--
-- Variables attendues (DEFINE, posees par le lanceur) :
--   P_DATE_FIN  date de fin a appliquer, au format AAAA-MM-JJ
--   P_MODE      SIMULATION (rollback systematique) ou EXECUTION (commit)
--   P_USER_EBS  nom du compte EBS realisant l'operation (tracabilite WHO)
--
-- Objets requis et privileges :
--   APPS.FND_USER              SELECT
--   APPS.PER_ALL_PEOPLE_F      SELECT
--   APPS.FND_RESPONSIBILITY    SELECT
--   APPS.FND_USER_PKG          EXECUTE
--   APPS.FND_GLOBAL            EXECUTE
--
-- Sortie : lignes balisees consommees par le lanceur
--   ##RES##matricule|user_name|mode_resolution|ancienne_fin|nouvelle_fin|statut|message
--   ##INFO##texte     ##ERR##texte     ##SUM##cle=valeur;...
-- =====================================================================

DECLARE
    -- ---------- Parametres ----------
    c_date_fin   CONSTANT DATE          := TO_DATE('&&P_DATE_FIN', 'YYYY-MM-DD');
    c_mode       CONSTANT VARCHAR2(20)  := UPPER('&&P_MODE');
    c_user_ebs   CONSTANT VARCHAR2(100) := UPPER('&&P_USER_EBS');

    -- Comptes techniques EBS : jamais desactives, meme s'ils figurent dans le CSV.
    TYPE t_liste IS TABLE OF VARCHAR2(100) INDEX BY PLS_INTEGER;
    l_proteges   t_liste;
    l_mat        t_liste;

    -- ---------- Contexte applicatif ----------
    l_ctx_user_id   NUMBER;
    l_resp_id       NUMBER;
    l_resp_appl_id  NUMBER;

    -- ---------- Variables de boucle ----------
    l_matricule   VARCHAR2(100);
    l_user_id     NUMBER;
    l_user_name   VARCHAR2(100);
    l_old_end     DATE;
    l_mode_reso   VARCHAR2(30);
    l_statut      VARCHAR2(30);
    l_message     VARCHAR2(500);
    l_nb          PLS_INTEGER;
    l_new_end     VARCHAR2(20);

    -- ---------- Compteurs ----------
    n_total       PLS_INTEGER := 0;
    n_traites     PLS_INTEGER := 0;
    n_deja        PLS_INTEGER := 0;
    n_introuv     PLS_INTEGER := 0;
    n_ambigu      PLS_INTEGER := 0;
    n_protege     PLS_INTEGER := 0;
    n_erreur      PLS_INTEGER := 0;

    -- Format unique de date pour toutes les sorties.
    FUNCTION fdate(p_date IN DATE) RETURN VARCHAR2 IS
    BEGIN
        IF p_date IS NULL THEN RETURN ''; END IF;
        RETURN TO_CHAR(p_date, 'DD/MM/YYYY');
    END fdate;

    PROCEDURE log_info(p_texte IN VARCHAR2) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE('##INFO##' || p_texte);
    END log_info;

    PROCEDURE log_res IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE('##RES##' || l_matricule
            || '|' || l_user_name
            || '|' || l_mode_reso
            || '|' || fdate(l_old_end)
            || '|' || l_new_end
            || '|' || l_statut
            || '|' || REPLACE(REPLACE(NVL(l_message, ' '), '|', '/'), CHR(10), ' '));
    END log_res;

BEGIN
    -- =================================================================
    -- 0. Comptes proteges
    -- =================================================================
    l_proteges(1)  := 'SYSADMIN';
    l_proteges(2)  := 'GUEST';
    l_proteges(3)  := 'AUTOINSTALL';
    l_proteges(4)  := 'APPSMGR';
    l_proteges(5)  := 'ANONYMOUS';
    l_proteges(6)  := 'WIZARD';
    l_proteges(7)  := 'CONCURRENT MANAGER';
    l_proteges(8)  := 'XML_USER';
    l_proteges(9)  := 'IBE_GUEST';
    l_proteges(10) := 'ASGADM';
    l_proteges(11) := 'INITIAL SETUP';
    l_proteges(12) := 'FEEDER SYSTEM';
    l_proteges(13) := 'MOBILEADM';
    l_proteges(14) := 'OP_SYSADMIN';
    l_proteges(15) := 'OP_CUST_CARE_ADMIN';

    -- =================================================================
    -- 1. Liste des matricules (injectee par le lanceur)
    -- =================================================================
    -- @@LISTE_MATRICULES@@

    n_total := l_mat.COUNT;
    log_info('Mode           : ' || c_mode);
    log_info('Date de fin    : ' || fdate(c_date_fin));
    log_info('Matricules lus : ' || n_total);

    IF n_total = 0 THEN
        DBMS_OUTPUT.PUT_LINE('##ERR##Aucun matricule a traiter.');
        RETURN;
    END IF;

    -- =================================================================
    -- 2. Contexte applicatif (tracabilite des colonnes WHO)
    -- =================================================================
    BEGIN
        SELECT user_id INTO l_ctx_user_id
          FROM apps.fnd_user
         WHERE UPPER(user_name) = c_user_ebs;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            BEGIN
                SELECT user_id INTO l_ctx_user_id
                  FROM apps.fnd_user
                 WHERE user_name = 'SYSADMIN';
                log_info('Compte ' || c_user_ebs || ' introuvable dans FND_USER : contexte SYSADMIN utilise.');
            EXCEPTION
                WHEN OTHERS THEN
                    l_ctx_user_id := NULL;
                    log_info('Aucun contexte applicatif resolu : les colonnes WHO seront approximatives.');
            END;
    END;

    IF l_ctx_user_id IS NOT NULL THEN
        BEGIN
            SELECT responsibility_id, application_id
              INTO l_resp_id, l_resp_appl_id
              FROM apps.fnd_responsibility
             WHERE responsibility_key = 'SYSTEM_ADMINISTRATOR'
               AND ROWNUM = 1;
        EXCEPTION
            WHEN OTHERS THEN
                l_resp_id := 0; l_resp_appl_id := 0;
        END;
        apps.fnd_global.apps_initialize(l_ctx_user_id, l_resp_id, l_resp_appl_id);
        log_info('Contexte applicatif : user_id=' || l_ctx_user_id
                 || ' resp_id=' || l_resp_id || ' appl_id=' || l_resp_appl_id);
    END IF;

    -- =================================================================
    -- 3. Traitement matricule par matricule
    -- =================================================================
    FOR i IN 1 .. l_mat.COUNT LOOP

        l_matricule := TRIM(l_mat(i));
        l_user_id   := NULL;
        l_user_name := NULL;
        l_old_end   := NULL;
        l_mode_reso := NULL;
        l_statut    := NULL;
        l_message   := NULL;
        l_new_end   := NULL;

        -- ---------------------------------------------------------
        -- 3.1 Resolution : d'abord USER_NAME, sinon EMPLOYEE_NUMBER
        -- ---------------------------------------------------------
        BEGIN
            SELECT user_id, user_name, end_date
              INTO l_user_id, l_user_name, l_old_end
              FROM apps.fnd_user
             WHERE UPPER(user_name) = UPPER(l_matricule);
            l_mode_reso := 'USER_NAME';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN NULL;
        END;

        IF l_user_id IS NULL THEN
            -- PER_ALL_PEOPLE_F est une table datee : on ne garde que la ligne
            -- en vigueur, et on dedoublonne sur le compte applicatif.
            SELECT COUNT(DISTINCT fu.user_id)
              INTO l_nb
              FROM apps.fnd_user fu
              JOIN apps.per_all_people_f p ON p.person_id = fu.employee_id
             WHERE UPPER(p.employee_number) = UPPER(l_matricule)
               AND TRUNC(SYSDATE) BETWEEN p.effective_start_date AND p.effective_end_date;

            IF l_nb = 1 THEN
                SELECT DISTINCT fu.user_id, fu.user_name, fu.end_date
                  INTO l_user_id, l_user_name, l_old_end
                  FROM apps.fnd_user fu
                  JOIN apps.per_all_people_f p ON p.person_id = fu.employee_id
                 WHERE UPPER(p.employee_number) = UPPER(l_matricule)
                   AND TRUNC(SYSDATE) BETWEEN p.effective_start_date AND p.effective_end_date;
                l_mode_reso := 'EMPLOYEE_NUMBER';
            ELSIF l_nb > 1 THEN
                l_statut  := 'AMBIGU';
                l_message := l_nb || ' comptes EBS portent ce matricule : resolution manuelle requise.';
            ELSE
                l_statut  := 'INTROUVABLE';
                l_message := 'Aucun compte trouve, ni par USER_NAME ni par EMPLOYEE_NUMBER.';
            END IF;
        END IF;

        -- ---------------------------------------------------------
        -- 3.2 Garde-fous
        -- ---------------------------------------------------------
        IF l_statut IS NULL THEN
            FOR p IN 1 .. l_proteges.COUNT LOOP
                IF UPPER(l_user_name) = l_proteges(p) THEN
                    l_statut  := 'PROTEGE';
                    l_message := 'Compte technique EBS : desactivation refusee par securite.';
                    EXIT;
                END IF;
            END LOOP;
        END IF;

        IF l_statut IS NULL THEN
            IF l_old_end IS NOT NULL AND TRUNC(l_old_end) = TRUNC(c_date_fin) THEN
                l_statut  := 'DEJA_A_JOUR';
                l_message := 'La date de fin demandee est deja posee.';
            ELSIF l_old_end IS NOT NULL AND TRUNC(l_old_end) < TRUNC(c_date_fin) THEN
                -- Repousser la date rouvrirait l'acces : on ne touche pas.
                l_statut  := 'DEJA_DESACTIVE';
                l_message := 'Compte deja clos le ' || fdate(l_old_end)
                             || ' : appliquer la nouvelle date prolongerait l''acces.';
            ELSE
                l_statut := 'A_DESACTIVER';
            END IF;
        END IF;

        -- ---------------------------------------------------------
        -- 3.3 Application
        -- ---------------------------------------------------------
        IF l_statut = 'A_DESACTIVER' THEN
            IF c_mode = 'EXECUTION' THEN
                BEGIN
                    apps.fnd_user_pkg.updateuser(
                        x_user_name => l_user_name,
                        x_owner     => 'CUST',
                        x_end_date  => c_date_fin);
                    l_statut  := 'DESACTIVE';
                    l_new_end := fdate(c_date_fin);
                    n_traites := n_traites + 1;
                EXCEPTION
                    WHEN OTHERS THEN
                        l_statut  := 'ERREUR';
                        l_message := SUBSTR(SQLERRM, 1, 400);
                        n_erreur  := n_erreur + 1;
                END;
            ELSE
                l_new_end := fdate(c_date_fin);
                n_traites := n_traites + 1;
            END IF;
        END IF;

        CASE l_statut
            WHEN 'DEJA_A_JOUR'    THEN n_deja    := n_deja    + 1;
            WHEN 'DEJA_DESACTIVE' THEN n_deja    := n_deja    + 1;
            WHEN 'INTROUVABLE'    THEN n_introuv := n_introuv + 1;
            WHEN 'AMBIGU'         THEN n_ambigu  := n_ambigu  + 1;
            WHEN 'PROTEGE'        THEN n_protege := n_protege + 1;
            ELSE NULL;
        END CASE;

        log_res;

    END LOOP;

    -- =================================================================
    -- 4. Cloture
    -- =================================================================
    IF c_mode = 'EXECUTION' THEN
        IF n_erreur = 0 THEN
            COMMIT;
            log_info('COMMIT effectue : ' || n_traites || ' compte(s) desactive(s).');
        ELSE
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('##ERR##' || n_erreur || ' erreur(s) : ROLLBACK complet, aucune modification conservee.');
        END IF;
    ELSE
        ROLLBACK;
        log_info('SIMULATION : rollback effectue, aucune modification en base.');
    END IF;

    DBMS_OUTPUT.PUT_LINE('##SUM##total=' || n_total
        || ';traites='     || n_traites
        || ';deja='        || n_deja
        || ';introuvable=' || n_introuv
        || ';ambigu='      || n_ambigu
        || ';protege='     || n_protege
        || ';erreur='      || n_erreur);

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('##ERR##Echec global : ' || SUBSTR(SQLERRM, 1, 400));
        DBMS_OUTPUT.PUT_LINE('##ERR##' || SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 1, 400));
        RAISE;
END;
/
