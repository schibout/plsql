CREATE OR REPLACE PACKAGE DKA_SFND_DESACTIV_USERS_PKG
AS
--------------------------------------------------------------------------------
-- Capgemini
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SFND_DESACTIV_USERS.pkb
-- DESCRIPTION       : DKA_SFND_DESACTIV_USERS_PKG package
--
-- AUTEUR            : B COPIN, Q VANHOUTE
-- DATE DE CREATION  : 18/03/2009
-- DOC. ASSOCIEE     :
-- COMMENTAIRE       : À exécuter sous SQLPLUS avec le user APPS
--------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Personne  Description
-- ---------- --------- --------------------------------------------------------
-- 06/03/2013 BCOUDRIER INC000000375077 - Désactivation des utilisateurs inactif
--						lorsque le TP est ouvert et lorsque le TP est fermé.
-- 06/03/2013 BCOUDRIER DPE20130017 - Procédure get_employee_users: Désactivation 
--						des comptes des employés sortis.
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PUBLIQUES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--------------------------------------------------------------------------------
--  Nom           : main
--  Description   : Procédure principale
--  PARAMETRES    :
--                     pn_retcode           : Le code d'erreur
--                     pv_err_msg           : Le message d'erreur
--------------------------------------------------------------------------------
PROCEDURE main (pn_retcode           OUT NUMBER,
                                  pv_err_msg           OUT VARCHAR2,
                                  pn_nb_jours IN NUMBER);

--------------------------------------------------------------------------------
--  Nom           : get_purchasing_users
--  Description   : Procédure désactivant les utilisateurs Achats
--  PARAMETRES    :
--                     pn_retcode           : Le code d'erreur
--                     pv_err_msg           : Le message d'erreur
--                     pn_count_pusers      : compteur des utilisateurs Achats désactivés
--                     pn_count_pusers_err  : compteur des utilisateurs Achats en erreur
--------------------------------------------------------------------------------
PROCEDURE get_purchasing_users (pn_retcode            OUT NUMBER,
                                                                   pv_err_msg            OUT VARCHAR2,
                                                                    pn_count_pusers OUT NUMBER,
                                                                    pn_count_pusers_err OUT NUMBER,
                                                                     pn_nb_jours IN NUMBER);

--------------------------------------------------------------------------------
--  Nom           : get_financial_users
--  Description   : Procédure désactivant les utilisateurs Finance
--  PARAMETRES    :
--                     pn_retcode           : Le code d'erreur
--                     pv_err_msg           : Le message d'erreur
--                     pn_count_fusers      : compteur des utilisateurs Finance désactivés
--                     pn_count_fusers_err  : compteur des utilisateurs Finance en erreur
--------------------------------------------------------------------------------
PROCEDURE get_financial_users (pn_retcode           OUT NUMBER,
                                     pv_err_msg          OUT VARCHAR2,
                                      pn_count_fusers OUT NUMBER,
                                                                    pn_count_fusers_err OUT NUMBER,
                                                                     pn_nb_jours IN NUMBER);
                                                                
--------------------------------------------------------------------------------
--  Nom           : get_employee_users
--  Description   : Procédure désactivant les comptes des employés sortis.
--  PARAMETRES    :
--                     pn_retcode           : Le code d'erreur
--                     pv_err_msg           : Le message d'erreur
--                     pn_count_fusers      : compteur des utilisateurs Finance désactivés
--                     pn_count_fusers_err  : compteur des utilisateurs Finance en erreur
--------------------------------------------------------------------------------
PROCEDURE get_employee_users (pn_retcode          OUT NUMBER,
                              pv_err_msg          OUT VARCHAR2,
                              pn_count_eusers     OUT NUMBER,
                              pn_count_eusers_err OUT NUMBER);
							 
END DKA_SFND_DESACTIV_USERS_PKG;
/

SHOW ERROR

EXIT
