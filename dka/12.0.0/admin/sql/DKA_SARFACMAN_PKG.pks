CREATE OR REPLACE PACKAGE Dka_Sarfacman_Pkg
AS

----------------------------------------------------------------------------------------------
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SARFACMAN_PKG.pks
-- DESCRIPTION       : DKA_SARFACMAN_PKG package spec :
---
--- AUTEUR           : Djamal BOUCHA (CGEY)
--- DATE DE CREATION : 14/01/2002
--- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--- 18/03/2002 XD  Ajout de la fonction get_select_record_group et de la constante cg_select_ctt_type_name
--- 07/07/2004 SFE Migration projet PHENIX 2004.
--- 10/10/2016 JPE MIGRATION R12
--- 18/11/2016 MEG artf2046192 
--------------------------------------------------------------------------------------------


--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    cg_select_ctt_type_name          CONSTANT VARCHAR2 (5000)
        := 'select ctt.cust_trx_type_id cust_trx_type_id, ctt.name name, ctt.description description, ctt.type class, arl_class.meaning class_meaning, ctt.accounting_affect_flag open_receivables_flag, ctt.post_to_gl post_to_gl_flag, ctt.allow_freight_flag allow_freight_flag, ctt.creation_sign creation_sign, ctt.allow_overapplication_flag allow_overapplication_flag, ctt.natural_application_only_flag natural_application_only_flag, ctt.tax_calculation_flag tax_calculation_flag, arl_status.meaning default_status, arl_print.meaning default_printing_option, rat.name default_term '
        || 'from ar_lookups arl_print, ar_lookups arl_status, ar_lookups arl_class, ra_terms rat, ra_cust_trx_types ctt '
        || 'where ''INVOICE_PRINT_OPTIONS'' = arl_print.lookup_type and ctt.default_printing_option = arl_print.lookup_code and ''INVOICE_TRX_STATUS'' = arl_status.lookup_type and ctt.default_status = arl_status.lookup_code and ctt.default_term = rat.term_id(+) and ''INV/CM'' = arl_class.lookup_type and ctt.type = arl_class.lookup_code and nvl(:tgw_header.trx_date, trunc(sysdate) ) between start_date and nvl(end_date, nvl(:tgw_header.trx_date, trunc(sysdate) ) ) and ctt.type in (''DEP'', ''GUAR'', ''INV'', ''CM'', ''DM'') and ( nvl(:tgw_header.ctt_class, ctt.type) = ctt.type or ( :tgw_header.ctt_class in (''DM'', ''INV'') and :tgw_header.row_id is not null and ctt.type in (''DM'', ''INV'') ) ) and ( :tgw_header.invoicing_rule_id is null or ctt.type in (''INV'', ''CM'') ) and ( ctt.type not in (''DEP'', ''GUAR'') or ctt.accounting_affect_flag = ''Y'' ) and ctt.post_to_gl = decode(:tgw_header.rev_recog_run_flag, ''Y'', :tgw_header.ctt_post_to_gl_flag, ctt.post_to_gl ) and ( nvl(:tgw_header.complete_flag, ''N'') = ''N'' or :tgw_header.ctt_class != ''CM'' or ( ctt.accounting_affect_flag = :tgw_header.ctt_open_receivables_flag ) ) and not exists ( select ''violates allow freight'' from ra_customer_trx_lines ctl where ctl.customer_trx_id = :tgw_header.customer_trx_id and ( ( ctt.allow_freight_flag = ''N'' and ctl.line_type = ''FREIGHT'' ) or ( ctl.line_type = ''CHARGES'' and ctt.type not in (''DM'', ''CM'') ) ) ) and not exists ( select ''VIOLATES CREATION SIGN'' from ra_customer_trx_lines ctl where ctl.customer_trx_id = :tgw_header.customer_trx_id group by ctt.creation_sign having decode( sign( sum(ctl.extended_amount) ), 1, decode( ctt.creation_sign, ''P'', ''Y'', ''A'', ''Y'', ''N'' ), -1, decode( ctt.creation_sign, ''N'', ''Y'', ''A'', ''Y'', ''N'' ), ''Y'' ) = ''N'' ) and ctt.set_of_books_id = :ar_world.set_of_books_id '
        || 'order by ctt.name';

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

----------------------------------------------------------------------------------------------------------------------
  --  Nom           : get_select_record_group
  --  Description   : Requete pour les listes de valeurs
  --
  --  PARAMETRES    :
  --    pv_errbuf
  --    pv_retcode

--  VALEUR RETOURNEE :
--     Description       : Ordre Select
--     Valeurs possibles :
----------------------------------------------------------------------------------------------------------------------
    FUNCTION get_select_record_group (
        pv_record_group    IN   VARCHAR2
    )
        RETURN VARCHAR2;


----------------------------------------------------------------------------------------------------------------------
  --  Nom           : init
  --  Description   : Initialisation
  --
  --  PARAMETRES    :
  --    pv_errbuf
  --    pv_retcode

--  VALEUR RETOURNEE :
--     Description       : Initialisation
--     Valeurs possibles :
----------------------------------------------------------------------------------------------------------------------
    PROCEDURE init (
        pv_errbuf    OUT   VARCHAR2,
        pn_retcode   OUT   NUMBER
    );


-----------------------------------------------------------------------------------------------------------------------
  --  Nom           :get_acct_combination
  --  Description   :Procedure qui vérifiée le rejet des évenements
  --
  --  PARAMETRES    :
  --    pn_project_id
  --    pd_date
  --    pv_errbuf
  --    pv_retcode

--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles :
----------------------------------------------------------------------------------------------------------------------
    PROCEDURE get_acct_combination (
        pv_custom_event_name            IN      VARCHAR2,      
        pv_concatened_segments_in       IN      VARCHAR2,
        pn_ccid_in                      IN      NUMBER,
        pn_org_id                       IN      NUMBER, --RBE
        pn_project_id                   IN OUT  NUMBER,
        pn_tache_id	                    IN OUT  NUMBER,
        pv_event_type                   IN      VARCHAR2,
        pd_gl_date                      IN      DATE,
        pv_trx_type                     IN      VARCHAR2,
        pv_account_class                IN      VARCHAR2,
        pn_customer_id                  IN      VARCHAR2,
        pn_cust_site_use_id             IN      VARCHAR2,
        pb_update_user_flexfield        OUT     BOOLEAN,
        pb_refac                        OUT     BOOLEAN,
        pn_refac_project_id             IN OUT  NUMBER,
        pn_refac_tache_id               IN OUT  NUMBER,
        pv_cuf                          IN OUT  VARCHAR2,
        pv_concatened_segments_out      OUT     VARCHAR2,
        pn_ccid_out                     OUT     NUMBER,
        Pv_Message                      OUT     VARCHAR2,
        pv_errbuf                       OUT     VARCHAR2,
        pn_retcode                      OUT     NUMBER
    );


-----------------------------------------------------------------------------------------------------------------------
  --  Nom           : Purge__sarfacman_tmp
  --  Description   : Purger la table temporaire
  --
  --  PARAMETRES    :
  --    pv_errbuf
  --    pv_retcode

--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles :
----------------------------------------------------------------------------------------------------------------------
    PROCEDURE purge_sarfacman_tmp (
        pv_errbuf    OUT   VARCHAR2,
        pn_retcode   OUT   NUMBER
    );


-----------------------------------------------------------------------------------------------------------------

--  Nom           :insert_sarfacman_tmp
--  Description   :insertion dans la table dka__sarfacman_tmp
--
--  PARAMETRES :
--    pv_batch_source_name
--    vv_errbuf
--    vn_retcode
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
----------------------------------------------------------------------------------------------------------------
    PROCEDURE insert_sarfacman_tmp (
        pv_batch_source_name   IN       VARCHAR2 DEFAULT NULL,
        pv_errbuf              OUT      VARCHAR2,
        pn_retcode             OUT      NUMBER
    );


-----------------------------------------------------------------------------------------------------------------
  --  Nom           :insert_pa_events
  --  Description   :insertion des évenements
  --
  --  PARAMETRES :
  --    vv_errbuf
  --    vn_retcode
  --  VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles : 0: deroulement correct
  --                         2: deroulement avec erreur
  ----------------------------------------------------------------------------------------------------------------
    PROCEDURE insert_pa_events (
        pv_errbuf    OUT   VARCHAR2,
        pn_retcode   OUT   NUMBER
    );



---------------------------------------------------------------------------------------------------------------------
  --  Nom           :get_societe
  --  Description   :
  --
  --  PARAMETRES :
  --    pv_project
  --    vv_societe
  --    vv_errbuf
  --    vn_retcode
  --  VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles : 0: deroulement correct
  --                         2: deroulement avec erreur
  ----------------------------------------------------------------------------------------------------------------
    PROCEDURE get_societe (
        pv_project   IN       VARCHAR2,
        vv_societe   OUT      VARCHAR2,
        pv_errbuf    OUT      VARCHAR2,
        pn_retcode   OUT      NUMBER
    );

---------------------------------------------------------------------------------------------------------------------
--  Nom           : get_dr_code_combination_id
--  Description   : calcul de la ccid de contrepartie
--
--  PARAMETRES :
--    pv_segment1
--    vv_errbuf
--    vn_retcode
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
----------------------------------------------------------------------------------------------------------------
    PROCEDURE get_dr_code_combination_id (
        pv_segment1   IN       VARCHAR2,
        pv_segment2   IN       VARCHAR2,  -- PHENIX 2004: Ajout.
        pn_ccid       OUT      NUMBER,
        pv_errbuf     OUT      VARCHAR2,
        pn_retcode    OUT      NUMBER
    );
--------------------------------------------------------------------------------------------------------------------
--  Nom           :get_code_saisie
--  Description   :Recherche du segment4 saisie dans cuf
--
--  PARAMETRES :
--    pv_compte_gl
--    vv_errbuf
--    vn_retcode
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
    FUNCTION get_code_saisie (
        pv_compte_gl   IN   VARCHAR2
    )
        RETURN VARCHAR2;


--------------------------------------------------------------------------------------------------------------------
--  Nom           :get_attribute_category
--  Description   :Détermine le contexte pour affichage du cuf
--
--  PARAMETRES :
--    pv_compte_gl
--    vv_errbuf
--    vn_retcode
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
    FUNCTION get_attribute_category (
        pv_account_class     IN   VARCHAR2,
        pv_accounting_flex   IN   VARCHAR2
    )
        RETURN VARCHAR2;


-----------------------------------------------------------------------------------------------------------------------
 --  Nom           :events_status_rejection
 --  Description   :Procedure qui vérifiée la validite du statut
 --
 --  PARAMETRES    :
 --    pv_errbuf
 --    pv_retcode

--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles :
----------------------------------------------------------------------------------------------------------------------
    PROCEDURE events_status_rejection (
        pn_project_id   IN       NUMBER,
        pv_segment1     IN       VARCHAR2,
        pd_date         IN       DATE,
        pv_errbuf       OUT      VARCHAR2,
        pn_retcode      OUT      NUMBER
    );


-----------------------------------------------------------------------------------------------------------------------
--  Nom           :events_type_rejection
--  Description   :Procedure qui vérifiée la validite du type d''évenement
--
--  PARAMETRES    :
--    pv_errbuf
--    pv_retcode
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles :
----------------------------------------------------------------------------------------------------------------------
    PROCEDURE events_type_rejection (
        pv_event_type   IN       VARCHAR2,
        pd_date         IN       DATE,
        pv_errbuf       OUT      VARCHAR2,
        pn_retcode      OUT      NUMBER
    );


---------------------------------------------------------------------------------------------------------------------
--  Nom           :Amount_sign
--  Description   :Recherche du segment4 saisie dans cuf
--
--  PARAMETRES :
--    pv_compte_gl
--    vv_errbuf
--    vn_retcode
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
----------------------------------------------------------------------------------------------------------------
    FUNCTION amount_sign (
        pv_type     IN   VARCHAR2,
        pv_name     IN   VARCHAR2,
        pn_amount   IN   NUMBER
    )
        RETURN NUMBER;

    PRAGMA RESTRICT_REFERENCES (amount_sign, WNDS);


----------------------------------------------------------------------------------------------------------------
--  Nom           :get_code_partenaire
--  Description   :Recherche du code partenaire du client
--
--  PARAMETRES :
--    pn_customer_id
--    vv_errbuf
--    vn_retcode
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
----------------------------------------------------------------------------------------------------------------
    FUNCTION get_code_partenaire (
        pn_customer_id      IN   NUMBER,
        pn_cust_site_use_id IN NUMBER
    )
        RETURN VARCHAR2;


----------------------------------------------------------------------------------------------------------------
--  Nom           :get_code_partenaire_desc
--  Description   :Recherche de la description du segment4
--
--  PARAMETRES :
--    pv_code_partenaire
--    vv_errbuf
--    vn_retcode
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
----------------------------------------------------------------------------------------------------------------
    FUNCTION get_code_partenaire_desc (
        pv_code_partenaire   IN   VARCHAR2
    )
        RETURN VARCHAR2;


----------------------------------------------------------------------------------------------------------------

   --  Nom           :create_output
  --  Description   :Création du fichier de sortie
  --  PARAMETRES :
  --    pv_errbuf
  --    pn_result
  --  VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles : 0: deroulement correct
  --                 2: deroulement avec erreur
-----------------------------------------------------------------------------------------------------------
    PROCEDURE create_output (
        pv_errbuf    OUT   VARCHAR2,
        pn_retcode   OUT   NUMBER
    );

   -----------------------------------------------------------------------------------------------------------------------
--  Nom           : get_data_for_refaccuf
--  Description   : données pour remplir le cuf dans le cas d'une refac
--
--  PARAMETRES    :
--    pn_project_id
--    pd_date
--    pv_errbuf
--    pv_retcode

--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles :
----------------------------------------------------------------------------------------------------------------------
    PROCEDURE get_data_for_refaccuf (
        pn_project_id                   IN OUT  NUMBER,
        pn_tache_id	                    IN OUT  NUMBER,
        pv_event_type                   IN      VARCHAR2,     
        pn_trx_org_id                   IN      NUMBER, --RBE     
        pb_refac                        OUT     BOOLEAN,
        pn_refac_project_id             IN OUT  NUMBER,
        pn_refac_tache_id               IN OUT  NUMBER,
        pv_concatened_segments_in       IN      VARCHAR2,
        pv_trx_type                     IN      VARCHAR2,
        pv_account_class                IN      VARCHAR2,
        pv_cuf                          IN OUT  VARCHAR2,
        pn_org_id                       OUT     NUMBER,
        Pv_Message                      OUT     VARCHAR2,
        pv_errbuf                       OUT     VARCHAR2,
        pn_retcode                      OUT     NUMBER
        );
----------------------------------------------------------------------------------------------------------------
--  Nom           : main
--  Description   : Procédure principale enchaînant l'ensemble des autres procédures
--
--  PARAMETRES :
--    pv_errbuf                   Entrée/Sortie       retour de message eventuel
--    pn_retcode                  Sortie          status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       :        code retour de validité
--     Valeurs possibles :        0: normal, 1: warning, 2: erreur
--
---------------------------------------------------------------------------------------------------------------------
    PROCEDURE main (
        pv_errbuf              IN OUT   VARCHAR2,
        pn_retcode             OUT      NUMBER,
        pv_batch_source_name   IN       VARCHAR2 DEFAULT NULL
    );
----------------------------------------------------------------------------------------------------------------------
END Dka_Sarfacman_Pkg;
/
SHOW ERRORS
EXIT
