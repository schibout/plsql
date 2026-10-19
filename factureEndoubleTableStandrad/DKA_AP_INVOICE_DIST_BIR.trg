CREATE OR REPLACE PACKAGE BODY DKA_STRANSCO_PKG AS
---------------------------------------------------------------------------------------------- 
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM		         : DKA_STRANSCO_PKG.pks
-- DESCRIPTION	     : DKA_STRANSCO_PKG package body : 
---
--- AUTEUR	         : S BERTHEAS (CGEY)
--- DATE DE CREATION : 20/12/2001
--- DOC. ASSOCIEE    : 
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
---
--------------------------------------------------------------------------------------------


--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PRIVEES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
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
RETURN VARCHAR2 IS
   vv_return_value  dka_stransco_lines.return_value%TYPE;   
   vv_params_value  VARCHAR2(100);
BEGIN
   --generation de vv_params_value
   vv_params_value := pv_param1||pv_param2||pv_param3;
   
   SELECT dsl.return_value
   INTO vv_return_value
   FROM dka_stransco_lines dsl,
        dka_stransco_headers dsh 
   WHERE dsh.set_id = dsl.set_id
     AND trunc(pd_date) <= trunc(nvl(dsh.inactive_date,pd_date))
     AND (trunc(pd_date) between trunc(dsl.start_date) 
                             AND trunc(nvl(dsl.end_date,pd_date))
         )
     AND dsh.set_name = pv_set_name
     AND dsl.params_value = vv_params_value
     AND dsl.enable = 'Y';     
   
   RETURN vv_return_value;
   
EXCEPTION	
   WHEN NO_DATA_FOUND
   THEN
      pv_errbuf := dka_tools_pkg.get_message('DKA','DKA_STRANSCO_E002','PARAMETERS_VALUE',vv_params_value,'DATE',pd_date,'SET_NAME',pv_set_name);	
      RETURN NULL;
   WHEN TOO_MANY_ROWS
   THEN
      pv_errbuf := dka_tools_pkg.get_message('DKA','DKA_STRANSCO_E003','PARAMETERS_VALUE',vv_params_value,'DATE',pd_date,'SET_NAME',pv_set_name);	
      RETURN NULL;
   WHEN OTHERS
   THEN
      pv_errbuf := dka_tools_pkg.get_message('DKA','DKA_STRANSCO_E001','ERROR',SQLERRM,'PARAMETERS_VALUE',vv_params_value,'SET_NAME',pv_set_name);
      RETURN NULL;
END get_value_f;

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
RETURN VARCHAR2 
IS
vv_errbuf VARCHAR2(200);
BEGIN
	RETURN get_value_f (pv_set_name,pd_date,vv_errbuf, pv_param1, pv_param2,pv_param3);
END;



---------------------------------------------------------------

END DKA_STRANSCO_PKG;
/
SHOW ERROR
EXIT;
