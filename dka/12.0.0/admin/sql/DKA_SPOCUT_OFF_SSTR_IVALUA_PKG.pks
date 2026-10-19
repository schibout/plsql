create or replace 
package 
                    DKA_SPOCUT_OFF_SSTR_IVALUA_PKG AS
 --------------------------------------------------------------------------------
  -- Capgemini
  -- PROJET            : DALKIA Oracle Applications
  -- NOM               : DKA_SPOCUT_OFF_PKG.pkb
  -- DESCRIPTION       : Le calcul des provisions (CUTOFF) sera effectué mensuellement 
  --    dans Oracle à partir des informations envoyées par le biais des interfaces de Ivalua.

  -- AUTEUR            : K. HANNACH
  -- DATE DE CRÉATION  : 04/10/2024
  -- DOC. ASSOCIEE     :
  -- COMMENTAIRE       : À exécuter avec SQLPLUS sous l'utilisateur APPS
  --------------------------------------------------------------------------------
  -- HISTORIQUE DES MODIFICATIONS
  -- Date       Personne  Description
  -- ---------- --------- --------------------------------------------------------
  -- 04/10/2024 K.HANNACH  Creation,
  --------------------------------------------------------------------------------


   --------------------------------------------------------------------------------
  -- Nom           : get_charge_theorique_imput
  -- Description   : Fonction de calcul de la charge théorique
  --
  -- Paramètres    :
  --                     P_Montant_Ctr_SSTR      : Montant de la commande pour la période 
  --                     P_Date_Deb_Periode_CRT   : Date de début du contrat
  --                     P_Date_Fin_PERIODE_CRT  : Date Fin du contrat
  --                     P_Date_Resiliation      : Date de résiliation sur le contrat 
  --                     P_Period_date_Comp      : Date de fin de la période comptable
  --------------------------------------------------------------------------------
  Function get_charge_theorique_imput(P_Montant_Ctr_SSTR       In Number
                                      ,P_Date_Deb_Periode_CRT   In Date
                                      ,P_Date_Fin_Periode_CRT  In Date
                                      ,P_Date_Resiliation      In Date
                                      ,P_Period_date_Comp      In Date
                               )       
                                    
    Return Number;
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

END DKA_SPOCUT_OFF_SSTR_IVALUA_PKG;
/

SHOW ERRORS
EXIT
