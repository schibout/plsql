CREATE OR REPLACE PACKAGE dka_spacutoffgl_pkg AS

----------------------------------------------------------------------------------------------
-- NOM           : DKA_SPACUTOFFGL_PKG.pks
-- DESCRIPTION       : DKA_SPACUTOFFGL_PKG package spec : spécifique CUTOFF GL/PA
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
--------------------------------------------------------------------------------------------

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
        --pv_famille                 IN       VARCHAR2 DEFAULT NULL, -- TB:13/09/2006 -- OBE
        --pn_code_d_n                IN       VARCHAR2 DEFAULT NULL, -- TB:06/12/2006 -- OBE
        pn_ledger_id               IN       NUMBER DEFAULT NULL,   -- OBE
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
--  Nom           : TRANSFER_FROM_GL_TO_PA
--  Description   : Transfert des écritures de CUTOFF de GL vers PA
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
PROCEDURE transfer_from_gl_to_pa (
    pv_errbuf                  IN OUT   VARCHAR2,
    pn_retcode                 IN OUT   NUMBER
);

END dka_spacutoffgl_pkg; -- Spécification du package
/
SHOW ERRORS
EXIT
