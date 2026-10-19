CREATE OR REPLACE PACKAGE DKA_STRANSCO_PKG AS
---------------------------------------------------------------------------------------------- 
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM		         : DKA_STRANSCO_PKG.pks
-- DESCRIPTION	     : DKA_STRANSCO_PKG package spec : 
---
--- AUTEUR	         : S BERTHEAS (CGEY)
--- DATE DE CREATION : 20/12/2001
--- DOC. ASSOCIEE    : 
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--- 18/01/2002 SYB ajout fonction etl_get_value_f pour transco via ETL (pas de variable OUT)
--------------------------------------------------------------------------------------------


--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-----------------------------------------------------------------
-- NOM         : get_value_f
-- DESCRIPTION : renvoie la valeur qui correspond aux paramètres d'entrée
-- PARAMETRES  :
--              pv_set_name       : nom du jeu de valeurs de correspondance
--              pd_date           : date d'effet
--              pv_message        : message d'erreur
--              pv_param1         : paramètre 1
--              pv_param2         : paramètre 2
--              pv_param3         : paramètre 3
--              
-- VALEUR RETOURNEE : pv_return_value  : valeur de correspondance (NULL si non trouvée)
-----------------------------------------------------------------

FUNCTION get_value_f (
                     pv_set_name            IN dka_stransco_headers.set_name%TYPE,
                     pd_date                IN DATE,
                     pv_errbuf              IN OUT VARCHAR2,
                     pv_param1              IN dka_stransco_lines.param1_value%TYPE    DEFAULT NULL,
                     pv_param2              IN dka_stransco_lines.param2_value%TYPE    DEFAULT NULL,
                     pv_param3              IN dka_stransco_lines.param3_value%TYPE    DEFAULT NULL
                     )
RETURN VARCHAR2 ;
-----------------------------------------------------------------
-- NOM         : etl_get_value_f
-- DESCRIPTION : renvoie la valeur qui correspond aux paramètres d'entrée
-- PARAMETRES  :
--              pv_set_name       : nom du jeu de valeurs de correspondance
--              pd_date           : date d'effet
--              pv_param1         : paramètre 1
--              pv_param2         : paramètre 2
--              pv_param3         : paramètre 3
--              
-- VALEUR RETOURNEE : pv_return_value  : valeur de correspondance (NULL si non trouvée)
-----------------------------------------------------------------

FUNCTION etl_get_value_f (
                     pv_set_name            IN dka_stransco_headers.set_name%TYPE,
                     pd_date                IN DATE,
                     pv_param1              IN dka_stransco_lines.param1_value%TYPE    DEFAULT NULL,
                     pv_param2              IN dka_stransco_lines.param2_value%TYPE    DEFAULT NULL,
                     pv_param3              IN dka_stransco_lines.param3_value%TYPE    DEFAULT NULL
                     )
RETURN VARCHAR2 ;

---------------------------------------------------------------

END DKA_STRANSCO_PKG;
/
SHOW ERROR
EXIT;
