CREATE OR REPLACE PACKAGE Dka_Controle_Refac_Pkg IS

    -- -----------------------------------------------------------------------------
    -- $$
    -- Capgemini
    -- PROJET           : DALKIA Oracle Applications
    -- NOM              : DKA_CONTROLE_REFAC_PKG.pkb
    -- DESCRIPTION      : DKA_CONTROLE_REFAC_PKG Package Specifications
    --
    -- AUTEUR           : E.MATUSZEWSKI (Capgemini)
    -- DATE DE CREATION : 26/02/2007
    -- COMMENTAIRES     : A exécuter sous SQLPLUS avec le user apps
    -- -----------------------------------------------------------------------------
    --
    -- -----------------------------------------------------------------------------
    -- HISTORIQUE DES MODIFICATIONS
    -- Date       Qui Description
    -- ---------- --- --------------------------------------------------------------
    --
    -- -----------------------------------------------------------------------------

    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    -- FONCTIONS ET PROCEDURES PRIVEES
    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    PROCEDURE Step_1(Pv_Errbuf     OUT VARCHAR2,
                     Pn_Retcode    OUT NUMBER);

    PROCEDURE Step_2(Pv_Errbuf         OUT VARCHAR2,
                     Pn_Retcode        OUT NUMBER,
                     Pv_Period_Name IN     VARCHAR2);

    PROCEDURE Step_3(Pv_Errbuf         OUT VARCHAR2,
                     Pn_Retcode        OUT NUMBER,
                     Pv_Period_Name IN     VARCHAR2);

    PROCEDURE Step_4(Pv_Errbuf         OUT VARCHAR2,
                     Pn_Retcode        OUT NUMBER,
                     Pv_Period_Name IN     VARCHAR2);

    PROCEDURE Step_5(Pv_Errbuf     OUT VARCHAR2,
                     Pn_Retcode    OUT NUMBER);

    PROCEDURE Step_6(Pv_Errbuf     OUT VARCHAR2,
                     Pn_Retcode    OUT NUMBER);

    PROCEDURE Step_7(Pv_Errbuf     OUT VARCHAR2,
                     Pn_Retcode    OUT NUMBER);

    PROCEDURE Step_8(Pv_Errbuf     OUT VARCHAR2,
                     Pn_Retcode    OUT NUMBER);

    PROCEDURE Main(Pv_Errbuf      IN OUT VARCHAR2,
                   Pn_Retcode     IN OUT NUMBER,
                   Pv_Period_Name IN     VARCHAR2,
                   Pv_Ctrl_Sites  IN     VARCHAR2);

END Dka_Controle_Refac_Pkg;
/
SHOW ERRORS 
EXIT