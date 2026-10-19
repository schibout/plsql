/* Formatted on 02/25/2002 14:24 (Formatter Plus v4.5.2) */
CREATE OR REPLACE PACKAGE BODY dka_sapcptdas2_pkg
AS

----------------------------------------------------------------------------------------------
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SAPCPTDAS2_PKG.pkb
-- DESCRIPTION       : DKA_SAPCPTDAS2_PKG package body :
---
--- AUTEUR           : Djamal BOUCHA (CGEY)
--- DATE DE CREATION : 14/12/2001
--- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--- 21/02/2002 DJB Correction de l'érreur d'extraction
--- 25/02/2002 XD  check_das_required : traitement du cas où pv_compte est NULL
--------------------------------------------------------------------------------------------


--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

------------------------------------------------------------------------------------------------------------------
 --  Nom           :get_code_das
  --  Description   :Recherche du compte compta honoraire
  --
  --  PARAMETRES    :
  --    pv_errbuf   varchar2
  --    pn_retcode  number
  --    pv_codedas  varchar2
  --    pv_compte   number
  --  VALEUR RETOURNEE :
  --     Description       : Recherche du type de la taxe
  --     Valeurs possibles : 0: deroulement correct
  --                 2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE get_code_das (
        pv_codedas   IN       VARCHAR2,
        pv_compte    IN OUT   VARCHAR2,
        pv_errbuf    OUT      VARCHAR2,
        pn_retcode   OUT      NUMBER
    )
    IS
        --vv_codedas_ok            fnd_flex_values.attribute1%TYPE;
        vv_compte_ok             fnd_flex_values.flex_value%TYPE;
        vv_flex_value_set_name   fnd_flex_value_sets.flex_value_set_name%TYPE;
        vn_flex_value_set_id     fnd_flex_value_sets.flex_value_set_id%TYPE;
        vb_valeur_ok             BOOLEAN;

        CURSOR flex_value_cur (
            pn_flex_value_set_id   NUMBER
        )
        IS
            SELECT ffv.flex_value
            FROM   fnd_flex_values ffv
            WHERE      ffv.attribute1 = pv_codedas
                   AND ffv.flex_value_set_id = vn_flex_value_set_id;

        flex_value_rec           flex_value_cur%ROWTYPE;
    BEGIN
        --Initialisation de la variable
        vb_valeur_ok    := FALSE;
        --Récuperation de flex_value_set_id
        dka_tools_pkg.get_flex_key_seg_value_set (pv_errbuf, pn_retcode, 'N', 3, vn_flex_value_set_id, vv_flex_value_set_name);

        IF NOT flex_value_cur%ISOPEN
        THEN
            OPEN flex_value_cur (vn_flex_value_set_id);
        END IF;

        LOOP
            FETCH flex_value_cur INTO flex_value_rec;
            EXIT WHEN flex_value_cur%NOTFOUND;

            IF flex_value_rec.flex_value = pv_compte
            THEN
                vb_valeur_ok    := TRUE;
            END IF;

            IF vv_compte_ok IS NULL
            THEN
                vv_compte_ok    := flex_value_rec.flex_value;
            ELSE
                vv_compte_ok    := vv_compte_ok || ' ou ' || flex_value_rec.flex_value;
            END IF;
        END LOOP;

        CLOSE flex_value_cur;

        --Controle sur les comptes comptables
        IF NOT vb_valeur_ok
        THEN
            -- Le code DAS2 CODE_DAS2 doit correspondre au compte comptable COMPTE_COMPTABLE
            pv_errbuf     := dka_tools_pkg.get_message ('DKA', 'DKA_SAPCPTDAS2_E001', 'CODE_DAS2', pv_codedas, 'COMPTE_COMPTABLE', vv_compte_ok);
            pn_retcode    := 1;
            pv_compte     := vv_compte_ok;
        END IF;
    /*
    --Contrôle sur le code_das2
    IF    (vv_codedas_ok != pv_codedas)
       OR (    vv_codedas_ok IS NULL
           AND pv_codedas IS NOT NULL
          )
    THEN
        pn_retcode    := 1;
        pv_errbuf     := dka_tools_pkg.get_message ('DKA', 'DKA_SAPCPTDAS2_E001', 'CODE_DAS2', pv_codedas, 'COMPTE_COMPTABLE', pv_compte);
    ELSIF (    vv_codedas_ok IS NOT NULL
           AND pv_codedas IS NULL
          )
    THEN
        pn_retcode    := 1;
        pv_errbuf     := dka_tools_pkg.get_message ('DKA', 'DKA_SAPCPTDAS2_E002', 'Vous devez selectionner le CODE_DAS2', vv_codedas_ok);
    ELSE
        NULL;
    END IF;
    */

    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            -- Il n'existe pas de compte comptable pour le code DAS2 CODE_DAS2
            pv_errbuf     := dka_tools_pkg.get_message ('DKA', 'DKA_SAPCPTDAS2_E002', 'CODE_DAS2', pv_codedas);
            pn_retcode    := 2;
        WHEN OTHERS
        THEN
            pv_errbuf     := 'DKA_SAPCPTDAS2_PKG.get_code_das:' || SQLERRM;
            pn_retcode    := 2;
    END get_code_das;


----------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
  --  Nom           :check_das_required
  --  Description   :Recherche pour un compte donné l'éxistance d'un code DAS correspondant
  --
  --  PARAMETRES    :
  --    pv_errbuf   varchar2
  --    pn_retcode  number
  --    pv_compte   varchar2
  --  VALEUR RETOURNEE :
  --     Description       : Recherche du type de la taxe
  --     Valeurs possibles : 0: deroulement correct
  --                 2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE check_das_required (
        pv_compte    IN OUT   VARCHAR2,
        pv_errbuf    OUT      VARCHAR2,
        pn_retcode   OUT      NUMBER
    )
    IS
        vn_flex_value_set_id     fnd_flex_values.flex_value_set_id%TYPE;
        vv_flex_value_set_name   fnd_flex_value_sets.flex_value_set_name%TYPE;
        vv_attribute1            fnd_flex_values.attribute1%TYPE;
    BEGIN
        IF pv_compte IS NOT NULL
        THEN
            --Récuperation de flex_value_set_id
            dka_tools_pkg.get_flex_key_seg_value_set (pv_errbuf, pn_retcode, 'N', 3, vn_flex_value_set_id, vv_flex_value_set_name);

            SELECT ffv.attribute1
            INTO   vv_attribute1
            FROM   fnd_flex_values ffv
            WHERE      ffv.flex_value_set_id = vn_flex_value_set_id
                   AND ffv.flex_value = pv_compte;

            IF vv_attribute1 IS NOT NULL
            THEN
                pn_retcode    := 1;
                pv_errbuf     := dka_tools_pkg.get_message ('DKA', 'DKA_SAPCPTDAS2_E003', 'COMPTE_COMPTABLE', pv_compte);
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            pv_errbuf     := 'DKA_SAPCPTDAS2_PKG.check_das_required:' || SQLERRM;
            pn_retcode    := 2;
    END check_das_required;
--------------------------------------------------------------------------------------------------------------------
END dka_sapcptdas2_pkg;
/
SHOW ERROR
EXIT;
