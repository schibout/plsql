CREATE OR REPLACE PACKAGE DKA_SPOCLOSCOM_PKG AS

  ----------------------------------------------------------------------------
  -- $$
  -- CAPGEMINI
  -- PROJET            : DALKIA Oracle Applications
  -- NOM               : DKA_SPOCLOSCOM_PKG.pks
  -- DESCRIPTION       : DKA_SPOCLOSCOM_PKG package spécifications
  ---
  --- AUTEUR           : C. Delcasso
  --- DATE DE CREATION : 04/05/2009
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
  ----------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- ---------- --- ---------------------------------------------------------
  ----------------------------------------------------------------------------

  ----------------------------------------------------------------------------
  --  Nom           : init
  --  Description   : Procédure d'initialisation
  --
  --PARAMETRES :
  --  pv_errbuf   Entrée/Sortie          message d'erreur
  --  VALEUR RETOURNEE :  pn_retcode
  --Valeurs possibles : 0=normal, 1=warning, 2=erreur
  ----------------------------------------------------------------------------
  PROCEDURE init(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER);

  -------------------------------------------------------------------------------------
  --  Nom           : Cloture_ligne_commande
  --  Description   :
  --
  --  PARAMETRES    :
  --    pv_errbuf       Sortie
  --    pv_retcode          Sortie

  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: OK, 2: erreur ou code erreur ORA
  ------------------------------------------------------------------------------------
  PROCEDURE Cloture_ligne_commande(pn_po_line_id    IN NUMBER,
                                   pv_closed_reason IN VARCHAR2,
                                   pv_errbuf        OUT VARCHAR2,
                                   pn_retcode       OUT NUMBER);

  -------------------------------------------------------------------------------------
  --  Nom           : Cloture_ligne_livraison
  --  Description   :
  --
  --  PARAMETRES    :
  --    pv_errbuf       Sortie
  --    pv_retcode          Sortie

  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: OK, 2: erreur ou code erreur ORA
  ------------------------------------------------------------------------------------
  PROCEDURE Cloture_ligne_livraison(pn_po_line_id    IN NUMBER,
                                    pv_closed_reason IN VARCHAR2,
                                    pv_uo            IN VARCHAR2,
                                    pv_errbuf        OUT VARCHAR2,
                                    pn_retcode       OUT NUMBER);

  -------------------------------------------------------------------------------------
  --  Nom           : Cloture_entete_commande
  --  Description   :
  --
  --  PARAMETRES    :
  --    pv_errbuf       Sortie
  --    pv_retcode          Sortie

  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: OK, 2: erreur ou code erreur ORA
  ------------------------------------------------------------------------------------
  PROCEDURE Cloture_entete_commande(pn_po_header_id IN NUMBER,
                                    pv_errbuf       OUT VARCHAR2,
                                    pn_retcode      OUT NUMBER);

  -------------------------------------------------------------------------------------
  --  Nom           : Select_ligne_cde_proj_ferme
  --  Description   :
  --
  --  PARAMETRES    :
  --    pv_errbuf       Sortie
  --    pv_retcode          Sortie

  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: OK, 2: erreur ou code erreur ORA
  ------------------------------------------------------------------------------------

  PROCEDURE Select_ligne_cde_proj_ferme(pv_errbuf  OUT VARCHAR2,
                                        pn_retcode OUT NUMBER,
                                        pv_uo      IN VARCHAR2);

  -------------------------------------------------------------------------------------
  --  Nom           : Select_ligne_cde_ancienne
  --  Description   :
  --
  --  PARAMETRES    :
  --    pv_errbuf       Sortie
  --    pv_retcode          Sortie

  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: OK, 2: erreur ou code erreur ORA
  ------------------------------------------------------------------------------------

  PROCEDURE Select_ligne_cde_ancienne(pv_errbuf  OUT VARCHAR2,
                                      pn_retcode OUT NUMBER,
                                      pv_uo      IN VARCHAR2);

  --------------------------------------------------------------------------------------
  --  Nom           : lancement_par_region
  --  Description   : Procédure permettant le lacement région par région de la fermeture
  --                  des commandes.
  --
  --  PARAMETRES :
  --    pv_errbuf                   Entrée/Sortie       retour de message eventuel
  --    pn_retcode                  Sortie          status du traitement en sortie
  --
  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: normal, 1: warning, 2: erreur
  --
  ----------------------------------------------------------------------------------------

  PROCEDURE lancement_par_region(pv_errbuf  IN OUT VARCHAR2,
                                 pn_retcode OUT NUMBER);

  --------------------------------------------------------------------------------------
  --  Nom           : MAIN
  --  Description   : Procédure principale enchaînant l'ensemble des autres procédures
  --
  --  PARAMETRES :
  --    pv_errbuf                   Entrée/Sortie       retour de message eventuel
  --    pn_retcode                  Sortie          status du traitement en sortie
  --
  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: normal, 1: warning, 2: erreur
  --
  ----------------------------------------------------------------------------------------
  PROCEDURE main(pv_errbuf    IN OUT VARCHAR2,
                 pn_retcode   OUT NUMBER,
                 pn_nbre_mois IN NUMBER,
                 pv_uo        IN VARCHAR2);

END DKA_SPOCLOSCOM_PKG;
/
SHOW ERROR
EXIT;
