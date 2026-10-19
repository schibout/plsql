CREATE OR REPLACE PACKAGE dka_ideclic_pkg AS
-- $$
-- Capgemini
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_IDECLIC_PKG.pks
-- DESCRIPTION      : Creation des spécifications du package DKA_IDECLIC_PKG
-- AUTEUR           : Eric MATUSZEWSKI
-- DATE DE CREATION : 07/12/2004
-- PARAMETRES       : A exécuter sous SQLPLUS avec le user APPS
--
--------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
--------------------------------------------------------------------------------
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------
-- 28/10/2016 YWA Migration R12  
--
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--------------------------------------------------------------------------------
--  Nom           : extract_i00rc
--  Description   : procédure de remplissage de la table DKA_I00RC
--
--  PARAMETRES    : pv_errbuf   Entrée/Sortie    message d'erreur   
--                  pn_retcode         Sortie    code de retour: 'O=normal', 
---                                                              '1=warning',
--                                                               '2=erreur' 
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
--------------------------------------------------------------------------------
PROCEDURE extract_i00rc (pv_errbuf  IN OUT VARCHAR2,
                         pn_retcode    OUT NUMBER,
                         p_period_name gl_period_statuses.period_name%TYPE,
                             p_end_date gl_period_statuses.end_date%TYPE);

--------------------------------------------------------------------------------
--  Nom           : extract_i00eh
--  Description   : procédure de remplissage de la table DKA_I00EH
--
--  PARAMETRES    : pv_errbuf   Entrée/Sortie    message d'erreur   
--                  pn_retcode         Sortie    code de retour: 'O=normal', 
---                                                              '1=warning',
--                                                               '2=erreur' 
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
--------------------------------------------------------------------------------
/*PROCEDURE extract_i00eh(pv_errbuf  IN OUT VARCHAR2,
                        pn_retcode    OUT NUMBER);*/--YWA

--------------------------------------------------------------------------------
--  Nom           : main
--  Description   : procédure principale
--
--  PARAMETRES    : pv_errbuf   Entrée/Sortie    message d'erreur   
--                  pn_retcode         Sortie    code de retour: 'O=normal', 
---                                                              '1=warning',
--                                                               '2=erreur' 
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
--------------------------------------------------------------------------------
PROCEDURE main(pv_errbuf  IN OUT VARCHAR2,
               pn_retcode    OUT NUMBER,
               p_period_name VARCHAR2);
               

FUNCTION calcul_solde (p_bill_to_customer_id NUMBER DEFAULT NULL,
                               p_bill_to_site_use_id NUMBER DEFAULT NULL,
                               p_org_id             NUMBER,
                               p_period_name         VARCHAR2,
                               p_ledger_id  NUMBER)
        RETURN NUMBER; --RBE
        
END dka_ideclic_pkg;
/
SHOW ERROR
EXIT