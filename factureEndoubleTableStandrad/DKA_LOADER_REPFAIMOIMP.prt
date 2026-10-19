/* Formatted on 02/07/2002 13:52 (Formatter Plus v4.5.2) */
CREATE OR REPLACE PACKAGE dka_sapcptdas2_pkg
AS
    
---------------------------------------------------------------------------------------------- 
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SAPCPTDAS2_PKG.pks
-- DESCRIPTION       : DKA_SAPCPTDAS2_PKG package spec : 
---
--- AUTEUR           : Djamal BOUCHA (CGEY)
--- DATE DE CREATION : 14/12/2001
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
-------------------------------------------------------------------------------------------------------------------
  --  Nom           :get_code_das 
  --  Description   :Recherche du compte compta honoraire
  --
  --  PARAMETRES    :
  --    pv_errbuf   varchar2
  --    pn_retcode  number
  --    pv_codedas  varchar2
  --    pv_compte   varchar2    
  --  VALEUR RETOURNEE :
  --     Description       : Recherche du type de la taxe
  --     Valeurs possibles : 0: deroulement correct
  --                 2: deroulement avec erreur 
------------------------------------------------------------------------------------------------------------------- 
    PROCEDURE get_code_das (
        pv_codedas   IN       VARCHAR2,
        pv_compte    IN  OUT  VARCHAR2,
        pv_errbuf    OUT      VARCHAR2,
        pn_retcode   OUT      NUMBER
    );
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
        pv_compte    IN  OUT  VARCHAR2,
        pv_errbuf    OUT      VARCHAR2,
        pn_retcode   OUT      NUMBER
    );
--------------------------------------------------------------------------------------------------------------------
END dka_sapcptdas2_pkg;
/
SHOW ERROR
EXIT;
