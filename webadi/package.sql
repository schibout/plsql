--------------------------------------------------------
--  Fichier créé - mercredi-octobre-14-2026   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package DKA_SPACUTOFFGL_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "WEBADI"."DKA_SPACUTOFFGL_PKG" AS
PRAGMA RESTRICT_REFERENCES (DKA_SPACUTOFFGL_PKG, WNDS);
----------------------------------------------------------------------------------------------
--  NOM           : WEBADI.DKA_SPACUTOFFGL_PKG.pks
-- DESCRIPTION       : WEBADI.DKA_SPACUTOFFGL_PKG package spec : spécifique CUTOFF GL/PA
---
--- AUTEUR           : K.Helali
--- DATE DE CREATION : 30/10/2001
--- DOC. ASSOCIEE    :
---
----------------------------------------------------------------------------------------------
--- NOM DU PROGRAMME :
--- PARAMETRES       :
---
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--- 22/07/2004 STI controler_line_gl : ajout de 4 arguments segments pv_segment9_in, pv_segment8_in
--- 13/11/2007 GV  version allégée pour WebAdi
--- 27/03/2009 TB  Optimisation des contrôles pour DKA WebAdi
--  29/11/2016 TBO Version du package pour WebADI R12
--------------------------------------------------------------------------------------------
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    TYPE dka_cuf IS TABLE OF VARCHAR2(200) INDEX BY BINARY_INTEGER;
    TYPE dka_ncuf IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;

----------------------------------------------------------------------------------------
--  Nom           : CONTROLER_LINE_GL
--  Description   : controle de la ligne dans GL
--
--  PARAMETRES :
--    pv_errbuf               Sortie
--    pn_retcode      Sortie
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal
--                         1: normal mais rien à faire en retour
--                         2: erreur
--                 ou le code erreur ORA
----------------------------------------------------------------------------------------
PROCEDURE controler_line_gl (
        pv_errbuf                  IN OUT   VARCHAR2,
        pn_retcode                 IN OUT   NUMBER,
        pv_user_je_category_name   IN       VARCHAR2,
        pd_gl_date                 IN       DATE,
        pv_amount_type             IN       VARCHAR2,   -- D = Débit, C = Crédit
        pv_segment1_in             IN       VARCHAR2,
        pv_segment2_in             IN       VARCHAR2,
        pv_segment3_in             IN       VARCHAR2,
        pv_segment4_in             IN       VARCHAR2,
        pv_segment5_in             IN       VARCHAR2,
        pv_segment6_in             IN       VARCHAR2,
        pv_segment7_in             IN       VARCHAR2,
        pv_segment8_in             IN       VARCHAR2,
        pv_segment9_in             IN       VARCHAR2, -- PHENIX 2004
        pv_segment10_in            IN       VARCHAR2, -- PHENIX 2004
        pv_segment11_in            IN       VARCHAR2, -- OBE
        pv_segment12_in            IN       VARCHAR2, -- OBE
        pn_project_id              IN OUT   NUMBER,
        pn_task_id                 IN OUT   NUMBER, -- OBE
        pv_event_type              IN       VARCHAR2,
        pv_expenditure_type        IN       VARCHAR2,
        pn_quantity                IN       NUMBER DEFAULT NULL,
        pn_project_id_refac        IN OUT   NUMBER,   --code projet à refacturer
        pn_task_id_refac           IN OUT   NUMBER,   -- OBE
        pv_segment1_out            OUT      VARCHAR2,
        pv_segment2_out            OUT      VARCHAR2,
        pv_segment3_out            OUT      VARCHAR2,
        pv_segment4_out            OUT      VARCHAR2,
        pv_segment5_out            OUT      VARCHAR2,
        pv_segment6_out            OUT      VARCHAR2,
        pv_segment7_out            OUT      VARCHAR2,
        pv_segment8_out            OUT      VARCHAR2,
        pv_segment9_out            OUT      VARCHAR2, -- PHENIX 2004
		    pv_segment10_out           OUT      VARCHAR2, -- PHENIX 2004
        pv_segment11_out           OUT      VARCHAR2, -- OBE
		    pv_segment12_out           OUT      VARCHAR2, -- OBE
        pv_concatenated_segs       OUT      VARCHAR2,
        pn_ccid                    OUT      NUMBER,
        pv_message_info            OUT      VARCHAR2
    );


----------------------------------------------------------------------------------------
--  Nom           : get_context_cuf
--  Description   : Recherche du contexte applicable pour le CUF sur lignes GL
--
--  PARAMETRES :
--    pv_errbuf               Sortie
--    pn_retcode      Sortie
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal
--                         2: erreur
--                 ou le code erreur ORA
----------------------------------------------------------------------------------------
PROCEDURE get_context_cuf (
     pv_errbuf                  IN OUT   VARCHAR2
    ,pn_retcode                 IN OUT   NUMBER
    ,pv_user_je_category_name   IN       VARCHAR2
    ,pv_account                 IN       VARCHAR2
    ,pv_context                 OUT      VARCHAR2
);


----------------------------------------------------------------------------------------
--  Nom           : tab_get_context_cuf
--  Description   : Recherche du contexte applicable pour le CUF pour un tableau de lignes
--
--  PARAMETRES :
--    pt_retcode      Sortie
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal
--                         2: erreur
--                 ou le code erreur ORA
----------------------------------------------------------------------------------------
PROCEDURE tab_get_context_cuf (
     pv_user_je_category_name   IN       VARCHAR2
    ,pt_retcode                 OUT      dka_cuf
    ,pt_account                 IN       dka_cuf
    ,pt_context                 OUT      dka_cuf
    ,pv_version                 OUT      VARCHAR2
);

----------------------------------------------------------------------------------------
--  Nom           : tab_controler_line_gl
--  Description   : Controle d'un tableau de ligne
--
--  PARAMETRES :
--    pt_retour       Sortie
--    pt_retcode      Sortie
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal
--                         2: erreur
--                 ou le code erreur ORA
----------------------------------------------------------------------------------------
PROCEDURE tab_controler_line_gl (
        pv_user_je_category_name   IN       VARCHAR2,
        pd_gl_date                 IN       DATE,
        pt_segment1                IN OUT   dka_cuf,
        pt_segment2                IN OUT   dka_cuf,
        pt_segment3                IN OUT   dka_cuf,
        pt_segment4                IN OUT   dka_cuf,
        pt_segment5                IN OUT   dka_cuf,
        pt_segment6                IN OUT   dka_cuf,
        pt_segment7                IN OUT   dka_cuf,
        pt_segment8                IN OUT   dka_cuf,
        pt_segment9                IN OUT   dka_cuf,
        pt_segment10               IN OUT   dka_cuf,
        pt_segment11               IN OUT   dka_cuf,
        pt_segment12               IN OUT   dka_cuf,
        pt_project_id              IN OUT   dka_ncuf,
        pt_task_id                 IN OUT   dka_ncuf,
        pt_event_type              IN OUT   dka_cuf,
        pt_expenditure_type        IN OUT   dka_cuf,
        pt_quantity                IN OUT   dka_ncuf,
        pt_project_id_refac        IN OUT   dka_ncuf,
        pt_task_id_refac           IN OUT   dka_ncuf,
        pt_retcode                 OUT      dka_cuf,
        pt_retour                  OUT      dka_cuf
);

----------------------------------------------------------------------------------------
--  Nom           : tab_select
--  Description   : Lancement de requêtes pour un tableau de valeurs
--
--  PARAMETRES :
--    pt_retcode      Sortie
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal
--                         2: erreur
--                 ou le code erreur ORA
----------------------------------------------------------------------------------------
PROCEDURE tab_select (
        pv_req                     IN       VARCHAR2,
        pd_date                    IN       DATE,
        pt_project                 IN       dka_cuf,
        pt_value                   IN OUT   dka_cuf,
        pt_retcode                 OUT      dka_cuf
);

END DKA_SPACUTOFFGL_PKG; -- Spécification du package

/
