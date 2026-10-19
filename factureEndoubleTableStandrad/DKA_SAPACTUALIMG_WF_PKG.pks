CREATE OR REPLACE PACKAGE DKA_GL_TOOLS_PKG AS
----------------------------------------------------------------------------------------------
-- $Id$
--
-- NOM               : DKA_GL_TOOLS_PKG.pks
-- DESCRIPTION       : DKA_GL_TOOLS_PKG package spec : fonctions communes
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
        RETURN VARCHAR2;

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
        RETURN gl_ledgers.ledger_id%TYPE;

    PRAGMA RESTRICT_REFERENCES (gl_get_lookup_meaning, WNDS);

-------------------------------------------------------------------------------------------------------------------
--  Nom           : GL_GET_CATEGORY_AUTOREV_FLAG
--  Description   : Récupération du flag de contrepassation automatique de la catégorie de journal GL
--
--  PARAMETRES    :
--      pv_errbuf                       VARCHAR2
--      pn_retcode                      NUMBER
--      pv_je_category_name             VARCHAR2
--      pv_user_je_category_name        VARCHAR2
--
--  VALEUR RETOURNEE :
--     Description       : Flag de contrepassation automatique
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE gl_get_category_autorev_flag (
        pv_errbuf                  OUT      VARCHAR2,
        pn_retcode                 OUT      NUMBER,
        pn_ledger_id               IN       NUMBER DEFAULT NULL,
        pv_je_category_name        IN       VARCHAR2 DEFAULT NULL,
        pv_user_je_category_name   IN       VARCHAR2 DEFAULT NULL,
        pv_autoreverse_flag        OUT      VARCHAR2
    );    

-------------------------------------------------------------------------------------------------------------------
--  Nom           : PERIOD_GL_TO_CLOSE
--  Description   : Recherche la période spécifiée pour le jeu d'autoimputation DKA_MOIS_GL_A_REFERMER
--
--  PARAMETRES    :
--     pn_sob_id  number
--     pn_autopost_set_id number
--
--  VALEUR RETOURNEE :
--     pv_errbuf  varchar2
--     pv_period_GL_name verchar2
--     pd_period_name   varchar2
-------------------------------------------------------------------------------------------------------------------
 PROCEDURE period_gl_to_close (
      pn_ledger_id        IN    NUMBER,
      pn_autopost_set_id        IN OUT   NUMBER,
      pv_period_GL_name   OUT      VARCHAR2,
      pv_errbuf        OUT      VARCHAR2,
      pn_retcode       OUT      NUMBER
   );    

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
--     Description       :  code retour de validité
--     Valeurs possibles :  True (Période ouverte) / False
-----------------------------------------------------------------
    FUNCTION gl_is_special_period_open (
        pv_period   IN   VARCHAR2
    )
        RETURN BOOLEAN;
        
        
END dka_gl_tools_pkg; -- Spécification du package
/

SHOW ERRORS
EXIT;

