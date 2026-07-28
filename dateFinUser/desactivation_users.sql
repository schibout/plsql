-- =====================================================================
-- Desactivation d'utilisateurs Oracle EBS a une date donnee
-- =====================================================================
-- Pose FND_USER.END_DATE par UPDATE direct sur la table de base.
-- Les responsabilites et les roles ne sont PAS touches.
--
-- AVERTISSEMENT : l'ecriture directe dans FND_USER n'est pas une methode
-- supportee par Oracle. Elle ne declenche ni la synchronisation annuaire
-- (LDAP / OID / OAM) ni la propagation vers Workflow. Le compte est bien
-- ferme cote EBS, mais un referentiel externe synchronise peut rester
-- desaligne. Choix assume par la maitrise d'ouvrage.
--
-- SEMANTIQUE DE LA DATE : EBS considere un compte actif tant que
-- END_DATE IS NULL OR END_DATE > SYSDATE. La date est donc posee a
-- 00:00 : le compte est inactif DES le jour demande, le dernier jour
-- d'acces effectif etant la veille. Pour laisser l'acces pendant toute
-- la journee demandee, indiquer le lendemain.
--
-- Ce fichier n'est pas destine a etre lance seul : le lanceur
-- Desactiver_Users.ps1 y injecte la liste des matricules a la place du
-- marqueur prevu et definit les variables ci-dessous.
--
-- Variables attendues (DEFINE, posees par le lanceur) :
--   P_DATE_FIN  date de fin a appliquer, au format AAAA-MM-JJ
--   P_MODE      SIMULATION (rollback systematique) ou EXECUTION (commit)
--   P_USER_EBS  compte EBS realisant l'operation (colonnes WHO)
--
-- Privileges requis :
--   APPLSYS.FND_USER           SELECT et UPDATE          (obligatoire)
--   PER_ALL_PEOPLE_F           SELECT                    (facultatif :
--       sans lui, seule la resolution par USER_NAME reste disponible)
--
-- Note sur la simulation : le mode SIMULATION execute reellement les
-- ordres UPDATE puis effectue un ROLLBACK. Il valide donc aussi les
-- droits d'ecriture et le ciblage des lignes, sans rien conserver.
--
-- Sortie : lignes balisees consommees par le lanceur
--   ##RES##matricule|user_name|mode_resolution|ancienne_fin|nouvelle_fin|statut|message
--   ##INFO##texte     ##ERR##texte     ##SUM##cle=valeur;...
-- =====================================================================

DECLARE
    -- ---------- Parametres ----------
    c_date_fin   CONSTANT DATE          := TRUNC(TO_DATE('&&P_DATE_FIN', 'YYYY-MM-DD'));
    c_mode       CONSTANT VARCHAR2(20)  := UPPER('&&P_MODE');
    c_user_ebs   CONSTANT VARCHAR2(100) := UPPER('&&P_USER_EBS');

    TYPE t_liste IS TABLE OF VARCHAR2(100) INDEX BY PLS_INTEGER;
    l_proteges   t_liste;   -- comptes techniques : jamais desactives
    l_mat        t_liste;   -- matricules injectes par le lanceur
    l_cand_hr    t_liste;   -- schemas candidats pour PER_ALL_PEOPLE_F

    -- ---------- Contexte ----------
    l_ctx_user_id NUMBER;
    l_table_hr    VARCHAR2(100);   -- NULL si la resolution RH est indisponible
    l_dummy       NUMBER;

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
    n_total    PLS_INTEGER := 0;
    n_traites  PLS_INTEGER := 0;
    n_deja     PLS_INTEGER := 0;
    n_introuv  PLS_INTEGER := 0;
    n_ambigu   PLS_INTEGER := 0;
    n_protege  PLS_INTEGER := 0;
    n_erreur   PLS_INTEGER := 0;

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
    -- 0. Comptes techniques proteges
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
    log_info('Date de fin    : ' || fdate(c_date_fin) || ' (compte inactif des cette date a 00:00)');
    log_info('Matricules lus : ' || n_total);

    IF n_total = 0 THEN
        DBMS_OUTPUT.PUT_LINE('##ERR##Aucun matricule a traiter.');
        RETURN;
    END IF;

    -- =================================================================
    -- 2. Contexte : compte EBS trace dans les colonnes WHO
    -- =================================================================
    BEGIN
        SELECT user_id INTO l_ctx_user_id
          FROM applsys.fnd_user
         WHERE UPPER(user_name) = c_user_ebs;
        log_info('Colonnes WHO tracees au nom de ' || c_user_ebs || ' (user_id=' || l_ctx_user_id || ').');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            l_ctx_user_id := -1;
            log_info('Compte ' || c_user_ebs || ' absent de FND_USER : LAST_UPDATED_BY force a -1.');
    END;

    -- =================================================================
    -- 3. Disponibilite de la resolution par EMPLOYEE_NUMBER
    -- =================================================================
    -- Acces dynamique : selon les habilitations, la table RH est vue via
    -- le synonyme APPS ou directement dans le schema HR, voire pas du tout.
    -- Une reference statique ferait echouer la compilation du bloc entier.
    l_cand_hr(1) := 'apps.per_all_people_f';
    l_cand_hr(2) := 'hr.per_all_people_f';
    l_cand_hr(3) := 'per_all_people_f';

    FOR i IN 1 .. l_cand_hr.COUNT LOOP
        BEGIN
            EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM ' || l_cand_hr(i) || ' WHERE ROWNUM = 1'
                INTO l_dummy;
            l_table_hr := l_cand_hr(i);
            EXIT;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;

    IF l_table_hr IS NOT NULL THEN
        log_info('Resolution RH disponible via ' || l_table_hr || '.');
    ELSE
        log_info('PER_ALL_PEOPLE_F inaccessible : seule la resolution par USER_NAME sera tentee.');
    END IF;

    -- =================================================================
    -- 4. Traitement matricule par matricule
    -- =================================================================
    FOR i IN 1 .. l_mat.COUNT LOOP

        l_matricule := TRIM(l_mat(i));
        l_user_id   := NULL;  l_user_name := NULL;  l_old_end := NULL;
        l_mode_reso := NULL;  l_statut    := NULL;  l_message := NULL;
        l_new_end   := NULL;

        -- ---------------------------------------------------------
        -- 4.1 Resolution : USER_NAME d'abord, EMPLOYEE_NUMBER ensuite
        -- ---------------------------------------------------------
        BEGIN
            SELECT user_id, user_name, end_date
              INTO l_user_id, l_user_name, l_old_end
              FROM applsys.fnd_user
             WHERE UPPER(user_name) = UPPER(l_matricule);
            l_mode_reso := 'USER_NAME';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN NULL;
        END;

        IF l_user_id IS NULL AND l_table_hr IS NOT NULL THEN
            -- Table datee : on ne retient que la ligne en vigueur, et on
            -- dedoublonne sur le compte applicatif.
            EXECUTE IMMEDIATE
                'SELECT COUNT(DISTINCT fu.user_id)
                   FROM applsys.fnd_user fu
                   JOIN ' || l_table_hr || ' p ON p.person_id = fu.employee_id
                  WHERE UPPER(p.employee_number) = :1
                    AND TRUNC(SYSDATE) BETWEEN p.effective_start_date AND p.effective_end_date'
                INTO l_nb USING UPPER(l_matricule);

            IF l_nb = 1 THEN
                EXECUTE IMMEDIATE
                    'SELECT DISTINCT fu.user_id, fu.user_name, fu.end_date
                       FROM applsys.fnd_user fu
                       JOIN ' || l_table_hr || ' p ON p.person_id = fu.employee_id
                      WHERE UPPER(p.employee_number) = :1
                        AND TRUNC(SYSDATE) BETWEEN p.effective_start_date AND p.effective_end_date'
                    INTO l_user_id, l_user_name, l_old_end USING UPPER(l_matricule);
                l_mode_reso := 'EMPLOYEE_NUMBER';
            ELSIF l_nb > 1 THEN
                l_statut  := 'AMBIGU';
                l_message := l_nb || ' comptes EBS portent ce matricule : resolution manuelle requise.';
            END IF;
        END IF;

        IF l_user_id IS NULL AND l_statut IS NULL THEN
            l_statut  := 'INTROUVABLE';
            l_message := CASE WHEN l_table_hr IS NULL
                              THEN 'Aucun compte trouve par USER_NAME (resolution RH indisponible).'
                              ELSE 'Aucun compte trouve, ni par USER_NAME ni par EMPLOYEE_NUMBER.' END;
        END IF;

        -- ---------------------------------------------------------
        -- 4.2 Garde-fous
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
            IF l_old_end IS NOT NULL AND TRUNC(l_old_end) = c_date_fin THEN
                l_statut  := 'DEJA_A_JOUR';
                l_message := 'La date de fin demandee est deja posee.';
            ELSIF l_old_end IS NOT NULL AND TRUNC(l_old_end) < c_date_fin THEN
                -- Repousser la date rouvrirait l'acces : on ne touche pas.
                l_statut  := 'DEJA_DESACTIVE';
                l_message := 'Compte deja clos le ' || fdate(l_old_end)
                             || ' : appliquer la nouvelle date prolongerait l''acces.';
            ELSE
                l_statut := 'A_DESACTIVER';
            END IF;
        END IF;

        -- ---------------------------------------------------------
        -- 4.3 Mise a jour directe de FND_USER
        -- ---------------------------------------------------------
        IF l_statut = 'A_DESACTIVER' THEN
            BEGIN
                UPDATE applsys.fnd_user
                   SET end_date          = c_date_fin,
                       last_update_date  = SYSDATE,
                       last_updated_by   = l_ctx_user_id,
                       last_update_login = l_ctx_user_id
                 WHERE user_id = l_user_id;

                IF SQL%ROWCOUNT = 1 THEN
                    l_new_end := fdate(c_date_fin);
                    n_traites := n_traites + 1;
                    IF c_mode = 'EXECUTION' THEN l_statut := 'DESACTIVE'; END IF;
                ELSE
                    l_statut  := 'ERREUR';
                    l_message := SQL%ROWCOUNT || ' ligne(s) affectee(s) au lieu de 1 : mise a jour abandonnee.';
                    n_erreur  := n_erreur + 1;
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    l_statut  := 'ERREUR';
                    l_message := SUBSTR(SQLERRM, 1, 400);
                    n_erreur  := n_erreur + 1;
            END;
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
    -- 5. Cloture
    -- =================================================================
    IF c_mode = 'EXECUTION' THEN
        IF n_erreur = 0 THEN
            COMMIT;
            log_info('COMMIT effectue : ' || n_traites || ' compte(s) desactive(s).');
        ELSE
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('##ERR##' || n_erreur
                || ' erreur(s) : ROLLBACK complet, aucune modification conservee.');
        END IF;
    ELSE
        ROLLBACK;
        log_info('SIMULATION : ' || n_traites || ' UPDATE testes puis annules (rollback). Droits d''ecriture valides.');
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
