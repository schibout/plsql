CREATE OR REPLACE PACKAGE DKA_SPOCUT_OFF_PKG AS
--------------------------------------------------------------------------------
-- $Id: DKA_SPOCUT_OFF_PKG.pks 364 2007-10-04 16:12:58Z NORDEST\viknab $
-- Capgemini
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SPOCUT_OFF_PKG.pks
-- DESCRIPTION       : Spécification du package DKA_SPOCUT_OFF_PKG
--
-- AUTEUR           : T. BONDUAEUX
-- DATE DE CRÉATION : 25/09/2007
-- DOC. ASSOCIÉE    :
-- COMMENTAIRE       : À exécuter avec SQLPLUS sous l'utilisateur APPS
--------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Personne  Description
-- 18/02/2010 CDE       EID20090220 : Ajout de la fonction get_charge_theorique_imput
-- 08/06/2017 RBE       Correction artf2170606 : SPE119 - SPOCUTOFF - Automatisation en erreur - Defect Bout_En_Bout_Helios_Ref #751
-- ---------- --------- --------------------------------------------------------


--------------------------------------------------------------------------------
-- Nom           : get_charge_theorique_imput
-- Description   : Fonction de calcul de la charge théorique
--
-- Paramètres    :
--                     pn_contrat_imputation_id  : ID imputation contrat
--                     pd_start_date             : Date de début du contrat
--                     pd_period_date            : Date de fin de la période
--------------------------------------------------------------------------------
    FUNCTION get_charge_theorique_imput(
                      pn_contrat_imputation_id   IN     NUMBER
                     ,pd_start_date              IN     DATE
                     ,pd_period_date             IN     DATE)
    RETURN NUMBER; 

-------------------------------------------------------------------------------
-- Nom           : main
-- Description   : Insère, pour chaque imputation d'une commande en cours d'un
--                  contrat de sous-traitance, une Charge À Payer (CAP) ou une
--                  Charge Constatée d'Avance (CCA).
--                  
--                  Pour une CAP, génère une écriture de charge (débit), une
--                  écriture sur le compte CAP (crédit), et une écriture de TVA
--                  (crédit).
--                  Pour une CCA, génère une écriture de charge (crédit) et une
--                  écriture sur le compte CCA (débit).
--                  Les écritures sur les comptes CAP, TVA, CCA sont regroupées
--                  suivant le segment1 (société), segment2 (région), et compte
--                  local (CAP, TVA ou CCA).
--
-- Paramètres    :
--   pv_errbuf     Entrée/Sortie         Retour de message eventuel
--   pn_retcode           Sortie         Statut du traitement en sortie
--   period        Entrée                Chaîne contenant la période sur
--                                       laquelle calculer (ex. 'JAN-08')
--------------------------------------------------------------------------------
  PROCEDURE main(pv_errbuf  IN OUT VARCHAR2,
                 pn_retcode    OUT NUMBER,
                 period     IN     gl_period_statuses.period_name%TYPE,
                 p_set_of_books_id IN NUMBER); -- RBE artf2170606

END DKA_SPOCUT_OFF_PKG;
/

SHOW ERRORS
EXIT
