CREATE OR REPLACE PACKAGE Dka_Sglabonnement_Pkg AS

    -- -----------------------------------------------------------------------------
    -- $$
    -- Capgemini
    -- PROJET           : DALKIA Oracle Applications
    -- NOM              : DKA_SGLABONNEMENT_PKG
    -- DESCRIPTION      : DKA_SGLABONNEMENT_PKG Package Specifications
    --
    -- AUTEUR           : E.MATUSZEWSKI (Capgemini)
    -- DATE DE CREATION : 18/07/2006
    -- COMMENTAIRES     : A exécuter sous SQLPLUS avec le user apps
    -- -----------------------------------------------------------------------------
    --
    -- -----------------------------------------------------------------------------
    -- HISTORIQUE DES MODIFICATIONS
    -- Date       Qui Description
    -- 28/05/2008 GV  is_rule_num_in_table : création d'une fonction qui vérifie la
    --                                       présence d'une ligne de formule pour
    --                                       une ligne de pièce d'abonnement
    -- ---------- --- --------------------------------------------------------------
    --
    -- -----------------------------------------------------------------------------

    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    -- CONSTANTES ET VARIABLES PUBLIQUES
    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    -- FONCTIONS ET PROCEDURES PRIVEES
    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    /*cg_rec_batches                  CONSTANT VARCHAR2 (5000)
                := 'select recurring_batch_id, ' ||
                   ' name,                     ' ||
                   ' description               ' ||
                   ' from gl_recurring_batches ' ||
                   ' where 1=1                 ' ||
                   ' order by name ';
    */

 
 
    -- Fonctions servant à l'interactif (CUSTOM.pll) --
    /*
    FUNCTION get_select_record_group (               --
        pv_record_group     IN   VARCHAR2,           --
        pv_societe          IN   VARCHAR2,           --
        pv_region           IN   VARCHAR2            --
    )                                                --
        RETURN VARCHAR2;                             --
    */                                                 --
    FUNCTION check_company_and_cost_center (         --
        pv_societe     IN   VARCHAR2,                --
        pv_region      IN   VARCHAR2                 --
    )                                                --
        RETURN BOOLEAN;                              --
                                                     --
    FUNCTION check_account(                          --
        pv_local_account  IN  VARCHAR2               --
    )                                                --
        RETURN BOOLEAN;                              --
                                                     --
    PROCEDURE get_rec_header_tot_amount (            --
        pn_rec_header_id   IN NUMBER,                --
        pn_rec_line_num    IN NUMBER,                --
        pn_debit_amount    OUT NUMBER,               --
        pn_credit_amount   OUT NUMBER                --
    );                                               --
                                                     --
    FUNCTION get_rec_line_description (              --
        pn_rec_header_id   IN NUMBER                 --
    )                                                --
        RETURN VARCHAR2;                             --
                                                     --
    FUNCTION is_rule_num_in_table (                  --
        pn_rec_header_id   IN NUMBER,                --
        pn_rec_line_num    IN NUMBER                 --
    )                                                --
        RETURN BOOLEAN;                              --
    ---------------------------------------------------


    -- -----------------------------------------------------------------------------
    -- Nom              : Compte_Rendu
    -- Description      : Edition du compte-rendu des anomalies pour un centre de
    --                    gestion.
    --
    -- PARAMETRES       : Pv_Centre_Gestion Entrée        Centre de Gestion
    --                    Pv_Errbuf                Sortie Message d'erreur
    --                    Pn_Retcode               Sortie Code Retour de la procédure
    --                                                    '0' : Normal
    --                                                    '1' : Avertissement
    --                                                    '2' : Erreur
    --
    --
    -- VALEUR RETOURNEE :
    --     Description       :
    --     Valeurs possibles :
    -- -----------------------------------------------------------------------------
    PROCEDURE Compte_Rendu(Pv_Errbuf            OUT VARCHAR2,
                           Pn_Retcode           OUT NUMBER,
                           Pv_Centre_Gestion IN     VARCHAR2);


    -- -----------------------------------------------------------------------------
    -- Nom              : main
    -- Description      : Procédure principale du traitement qui enchaîne l'ensemble
    --                    des autres procédures.
    --
    -- PARAMETRES       : Pv_Errbuf    Sortie Message d'erreur
    --                    Pn_Retcode   Sortie Code Retour de la procédure
    --                                        '0' : Normal
    --                                        '1' : Avertissement
    --                                        '2' : Erreur
    --
    --
    -- VALEUR RETOURNEE :
    --     Description       :
    --     Valeurs possibles :
    -- -----------------------------------------------------------------------------
    PROCEDURE Main(Pv_Errbuf  OUT VARCHAR2,
                   Pn_Retcode OUT NUMBER);

END Dka_Sglabonnement_Pkg;
/
SHOW ERRORS
EXIT
