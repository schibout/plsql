CREATE OR REPLACE PACKAGE BODY DKA_GL_TOOLS_PKG AS
----------------------------------------------------------------------------------------------
-- $Id$
--
-- NOM               : DKA_GL_TOOLS_PKG.pkb
-- DESCRIPTION       : DKA_GL_TOOLS_PKG package body : fonctions communes
---
--- AUTEUR           : J.JARDEZ
--- DATE DE CREATION : 16/03/2016
--- DOC. ASSOCIEE    :
---
----------------------------------------------------------------------------------------------
--- NOM DU PROGRAMME :
--- PARAMETRES       :
---
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--  16/03/2016 JJA Portage Helios 2016
--------------------------------------------------------------------------------------------
--  29/09/2016 OBE Modification : Ajout de la procédure gl_get_category_autorev_flag
--  14/03/2017 YWA artf2095471 : SPE048 : Affichage "No data found" dans le log période exceptionnelle 
--  12/07/2017 MEG artf2194372 : SPE048 - defect ORACLE_R12 #706 GL/PA Problème de sélection des périodes à traiter
--------------------------------------------------------------------------------------------
-----------------------------------------------------------------
--  Variables globales
-----------------------------------------------------------------
    gv_debug_mode        VARCHAR2 (1);

-----------------------------------------------------------------
--  Nom           : GL_GET_LOOKUP_MEANING
--  Description   : Fonction qui récupere la signification d'une
--                  valeur d'un jeu de codes express GL
--
--  PARAMETRES :
--     pv_lookup_type     Entrée
--     pv_lookup_code     Entrée
--
--  VALEUR RETOURNEE :
--     Description       :  Signification du jeu de codes express
--     Valeurs possibles :
-----------------------------------------------------------------
    FUNCTION gl_get_lookup_meaning (
        pv_lookup_type   IN   VARCHAR2,
        pv_lookup_code   IN   VARCHAR2
    )
        RETURN VARCHAR2
    IS
        vv_lookup_meaning   gl_lookups.meaning%TYPE;
    BEGIN
        SELECT gl.meaning
        INTO   vv_lookup_meaning
        FROM   gl_lookups gl
        WHERE      gl.lookup_type = pv_lookup_type
               AND gl.lookup_code = pv_lookup_code;

        RETURN vv_lookup_meaning;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END gl_get_lookup_meaning;

-----------------------------------------------------------------
--  Nom           : GET_LEGDER_ID
--  Description   : Fonction qui renvoi ID du ledger d'un societe
--
--  PARAMETRES :
--     pv_societe     Entrée
--
--  VALEUR RETOURNEE :
--     Description       :  LEDGER_ID (null si ça n'existe pas)
--     Valeurs possibles :
-----------------------------------------------------------------
    FUNCTION get_legder_id (
        pv_societe   IN   VARCHAR2
    )
        RETURN gl_ledgers.ledger_id%TYPE
    IS
        vn_ledger_id   gl_ledgers.ledger_id%TYPE;
    BEGIN
        
        SELECT ledger_id
        INTO vn_ledger_id
        FROM gl_ledgers
        WHERE short_name = pv_societe
        AND ledger_category_code = 'PRIMARY';

        RETURN vn_ledger_id;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END get_legder_id;

-----------------------------------------------------------------
--  Nom           : GL_GET_CATEGORY_AUTOREV_FLAG
--  Description   : Récupération du flag de contrepassation automatique de la catégorie de journal GL
--
--  PARAMETRES    :
--      pv_errbuf                       VARCHAR2
--      pn_retcode                      NUMBER
--      pn_set_of_books_id              NUMBER
--      pv_je_category_name             VARCHAR2
--      pv_user_je_category_name        VARCHAR2
--
--  VALEUR RETOURNEE :
--     Description       : Flag de contrepassation automatique
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-----------------------------------------------------------------    
    PROCEDURE gl_get_category_autorev_flag (
        pv_errbuf                  OUT      VARCHAR2,
        pn_retcode                 OUT      NUMBER,
        pn_ledger_id               IN       NUMBER DEFAULT NULL,
        pv_je_category_name        IN       VARCHAR2 DEFAULT NULL,
        pv_user_je_category_name   IN       VARCHAR2 DEFAULT NULL,
        pv_autoreverse_flag        OUT      VARCHAR2
    )
    IS
        vn_ledger_id   gl_ledgers.ledger_id%TYPE;
    BEGIN
        IF pn_ledger_id IS NOT NULL
        THEN
            vn_ledger_id    := pn_ledger_id;
        ELSE
            vn_ledger_id    := TO_NUMBER(gl_access_set_security_pkg.get_default_ledger_id(FND_PROFILE.value('GL_ACCESS_SET_ID'), 'R'));
        END IF;

        IF pv_je_category_name IS NOT NULL
        THEN
            SELECT gao.autoreverse_flag
            INTO   pv_autoreverse_flag
            FROM   gl_autoreverse_options gao
            WHERE  gao.je_category_name = pv_je_category_name;
        ELSIF pv_user_je_category_name IS NOT NULL
        THEN
            SELECT gao.autoreverse_flag
            INTO   pv_autoreverse_flag
            FROM   gl_autoreverse_options gao,
                   gl_je_categories gjc,
                   gl_ledgers       gl
            WHERE  gl.ledger_id = vn_ledger_id
                   AND gl.criteria_set_id = gao.criteria_set_id
                   AND gao.je_category_name = gjc.je_category_name
                   AND gjc.user_je_category_name = pv_user_je_category_name;
        ELSE
            pv_errbuf     := 'Paramètres non valides';
            pn_retcode    := 2;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            pv_errbuf     := SQLERRM;
            pn_retcode    := 2;
    END gl_get_category_autorev_flag;    
    
---------------------------------------------------------------------------------------------------------------
--  Nom           : PERIOD_GL_TO_CLOSE
--  Description   : Recherche la période spécIFiée pour le jeu d'autoimputation DKA_MOIS_GL_A_REFERMER
--
--  PARAMETRES    :
--     pn_sob_id  number
--     pn_autopost_set_id number
--
--  VALEUR RETOURNEE :
--     pv_errbuf  varchar2
--     pv_period_GL_name verchar2
--     pd_period_name   varchar2
---------------------------------------------------------------------------------------------------------------
PROCEDURE period_gl_to_close (
	pn_ledger_id        IN    NUMBER,
	pn_autopost_set_id        IN OUT   NUMBER,
	pv_period_GL_name   OUT      VARCHAR2,
	pv_errbuf        OUT      VARCHAR2,
	pn_retcode       OUT      NUMBER
)
IS
BEGIN
	pv_errbuf := NULL;
	------------------------------------------------------------------------------------------
	--récupération de la période spécIFiée sur le jeu d'auto-imputation DKA_MOIS_GL_A_REFERMER
	--ainsi que son id correspondant

  SELECT DISTINCT period_name, po.AUTOPOST_SET_ID
    INTO pv_period_GL_name, pn_autopost_set_id
    FROM gl_automatic_posting_sets ps, GL_AUTOMATIC_POSTING_OPTIONS po
   WHERE ps.autopost_set_name = 'DKA_MOIS_GL_A_REFERMER'
     AND po.AUTOPOST_SET_ID = ps.AUTOPOST_SET_ID
   --AND ps.set_of_books_id = pn_sob_id
     AND po.ledger_id = pn_ledger_id
     and ps.enabled_flag = 'Y';

	EXCEPTION
  WHEN NO_DATA_FOUND THEN
    pn_autopost_set_id := NULL;
    pv_period_GL_name  := NULL;
  
	WHEN OTHERS THEN
	--dka_tools_pkg.put_log_message(SUBSTR (SQLERRM, 1, 250)); --YWA artf2095471
		pv_errbuf  := SUBSTR (SQLERRM, 1, 250);
		pn_retcode := 2;
END;    

-----------------------------------------------------------------
--  Nom           : GL_IS_SPECIAL_PERIOD_OPEN
--  Description   : Fonction de contrôle du spécifique SGLPERUTIL
--                  Détection des droits d' ouverture spéciale de
--          période GL (users GL privilégiés)
--
--  PARAMETRES :
--     pv_périod     Entrée      Champ à contrôler
--
--  VALEUR RETOURNEE :
--     Description       :  code retour de validité (boolean)
--     Valeurs possibles :  True (ouverture permise) / False
-----------------------------------------------------------------
    FUNCTION gl_is_special_period_open (
        pv_period   IN   VARCHAR2
    )
        RETURN BOOLEAN
    IS
        vb_return          BOOLEAN;
        vv_period_status   VARCHAR2 (1);
        vv_special_open    VARCHAR2 (1);
    BEGIN
        SELECT closing_status,
               NVL (attribute1, 'N')
        INTO   vv_period_status,
               vv_special_open
        FROM   gl_period_statuses_v
        WHERE      period_name = pv_period
               AND ledger_id = TO_NUMBER(gl_access_set_security_pkg.get_default_ledger_id(FND_PROFILE.value('GL_ACCESS_SET_ID'), 'R')) --Fnd_Profile.VALUE ('GL_SET_OF_BKS_ID')
               AND application_id = 101;

        IF (   vv_period_status = 'O'
            OR vv_period_status = 'F'
           )
        THEN
            BEGIN
                IF vv_special_open <> 'Y'
                THEN
                    vb_return    := TRUE;
                ELSIF Fnd_Profile.VALUE ('DKA_GL_SPECIAL_PERIOD') = 'Y'
                THEN
                    vb_return    := TRUE;
                ELSE
                    vb_return    := FALSE;
                END IF;
            END;
        ELSE
            vb_return    := FALSE;
        END IF;

        RETURN (vb_return);
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            RETURN TRUE;
        WHEN OTHERS
        THEN
            RETURN TRUE;
    END gl_is_special_period_open;

END dka_gl_tools_pkg; -- Spécification du package
/
SHOW ERRORS
EXIT;
