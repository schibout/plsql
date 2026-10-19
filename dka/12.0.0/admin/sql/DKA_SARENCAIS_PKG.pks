/*<TOAD_FILE_CHUNK>*/
/* Formatted on 02/20/2002 11:07 (Formatter Plus v4.5.2) */
CREATE OR REPLACE PACKAGE Dka_Sarencais_Pkg AS

  ----------------------------------------------------------------------------------------------
  -- $$
  -- CAP GEMINI ERNST AND YOUNG
  -- PROJET            : DALKIA Oracle Applications
  -- NOM           : DKA_SARENCAIS_PKG.pks
  -- DESCRIPTION       : DKA_SARENCAIS_PKG package spec :
  ---
  --- AUTEUR           : Drifa ARBOUZ (CGEY)
  --- DATE DE CREATION : 05/11/2001
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
  ----------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- ---------- --- -------------------------------------------------------------------------
  --- 18/07/2003 AD  La procédure insert_ar_interface a été renommée en insert_ar_transmission.
  ---                Creation de la procédure insert_ar_interface.
  --- 08/03/2018 RBE artf2418217 : INC0191600 : SPE019 - Campagne de paiement intra Groupe AP/AR

  --------------------------------------------------------------------------------------------
  --- PHENIX 2004
  --- Ajout paramètre dans procédure run_import 
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --                               PROCEDURES PUBLIQUES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -------------------------------------------------------------------------------------
  --  Nom           : init
  --  Description   : Procédure d'initialisation des variables globales du package
  --
  --  PARAMETRES    :
  --  pv_errbuf       Entrée  Sortie
  --  pv_retcode                  Sortie
  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: OK  ou 2: erreur
  ------------------------------------------------------------------------------------
  PROCEDURE init(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER);

  ----------------------------------------------------------------------------------------
  --  Nom           : get_ap_payments
  --  Description   : Procédure d'insertion dans la table dka_sarencais_tmp des réglments ayant
  --          les caractéristiques suivantes :
  --          - Type de fournisseurs partenaire/société sur système
  --          - Tous les règlements sont des virements
  --          - Le règlement doit être en status 'Négociable'
  --
  --  PARAMETRES    :
  --  pv_errbuf       Entrée  Sortie
  --  pv_retcode                  Sortie
  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: OK, 2: erreur ou le code  erreur ORA
  ------------------------------------------------------------------------------------
  PROCEDURE get_ap_payments(pv_errbuf  IN OUT VARCHAR2,
                            pn_retcode OUT NUMBER);

  ------------------------------------------------------------------------------------
  --  Nom           : get_ar_period_date_f
  --  Description   : Renvoie la date de fin de la premiere periode ouverte AR
  --                  par rapport a une date de reference D
  --                  (ie la 1ère période AR ouverte, par ordre chrono, dont la date de fin est >= D)
  --
  --  PARAMETRES    :
  --      pd_ref_date                 Entree
  --      pn_set_of_books_id          Entree

  --  VALEUR RETOURNEE :
  --     Description       : Date de fin de la premiere periode ouverte
  --     Valeurs possibles : 
  -------------------------------------------------------------------------------------
  FUNCTION get_ar_period_date_f(pd_ref_date         IN   DATE,
                                pn_set_of_books_id  IN   NUMBER DEFAULT NULL
  ) RETURN DATE;

  ---------------------------------------------------------------------------------------
  --  Nom           : get_customer_partner
  --  Description   : Procédure permettant d'obtenir les identifiants du client, addresse client,
  --                  et lieu de facturation 
  --
  --  PARAMETRES :
  --          pv_code_societe         Entrée
  --          pv_centre_gestion       Entrée
  --          pn_org_id               Entrée
  --          pn_customer_id          Sortie
  --          pv_customer_number      Sortie
  --          pn_customer_site_id     Sortie
  --          pn_bill_to_site_use_id  Sortie
  --          pv_errbuf               Entrée  Sortie
  --          pn_retcode              Sortie
  --
  --  VALEUR RETOURNEE :
  --     Description       : Identifiant du client + code retour de validité
  --     Valeurs possibles : 0: deroulement correct
  --                         2: deroulement avec erreur
  -------------------------------------------------------------------------------------------------------------------
  PROCEDURE get_customer_partner(pv_code_societe        IN VARCHAR2,
                                 pv_interco             IN VARCHAR2,
                                 pn_customer_id         OUT NUMBER,
                                 pv_customer_number     OUT VARCHAR2,
                                 pn_customer_site_id    OUT NUMBER,
                                 pn_bill_to_site_use_id OUT NUMBER,
                                 pv_bill_to_location    OUT VARCHAR2, --RBE artf2418217
                                 pv_errbuf              IN OUT VARCHAR2,
                                 pn_retcode             OUT NUMBER);

  ------------------------------------------------------------------------------------
  --  Nom           : check_periods
  --  Description   : Procédure permettant de savoir si la periode correspondante à la
  ---                 date de règlement AP est ouverte dans les modules AP et AR.
  --
  --  PARAMETRES    :
  --      pd_date                 Entrée
  --      pv_open_flag                    Sortie
  --  pv_errbuf       Entrée  Sortie
  --  pv_retcode                  Sortie
  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: OK, 2: erreur ou le code  erreur ORA
  -------------------------------------------------------------------------------------
  PROCEDURE check_periods(pd_date      IN DATE,
                          pd_sob       IN NUMBER,
                          pv_open_flag OUT VARCHAR2,
                          pv_errbuf    IN OUT VARCHAR2,
                          pn_retcode   OUT NUMBER);

  --------------------------------------------------------------------------------------
  --  Nom           : insert_ar_transmission
  --  Description   : Procédure permet d'inserer dans la tables ar_transmissions_all.
  --          
  --
  --  PARAMETRES    :
  --      pv_errbuf       Entrée  Sortie
  --      pv_retcode                  Sortie
  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: OK, 2: erreur ou le code  erreur ORA
  --
  ------------------------------------------------------------------------------------
  PROCEDURE insert_ar_transmission(pv_errbuf  IN OUT VARCHAR2,
                                   pn_retcode OUT NUMBER);

  --------------------------------------------------------------------------------------
  --  Nom           : insert_ar_interface
  --  Description   : Procédure permet d'inserer dans ar_payments_interface_all 
  --                  les informations importées par
  --                  l'open interface Aotolockbox
  --
  --  PARAMETRES    :
  --      pn_transmission   Entrée     
  --      pn_org_id         Entrée     
  --      pv_bank_acct_area Entrée    
  --      pn_bank_segment3  Entrée    
  --      pv_errbuf         Entrée    Sortie
  --      pv_retcode                  Sortie
  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: OK, 2: erreur ou le code  erreur ORA
  --
  ------------------------------------------------------------------------------------
  PROCEDURE insert_ar_interface(pn_transmission   IN NUMBER,
                                pn_org_id         IN NUMBER,
                                pv_bank_acct_area IN VARCHAR2,
                                pn_bank_segment3  IN NUMBER,
                                pv_errbuf         IN OUT VARCHAR2,
                                pn_retcode        OUT NUMBER);

  ---------------------------------------------------------------------------------------
  --  Nom           : populate_data
  --  Description   : Procédure qui renseigne et complète  la table dka_sarencais_tmp
  --  PARAMETRES    :
  --  PARAMETRES    :
  --      pv_errbuf       Entrée  Sortie
  --      pv_retcode                  Sortie
  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: OK, 2: erreur ou le code  erreur ORA
  --------------------------------------------------------------------------------------
  PROCEDURE populate_data(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER);

  -----------------------------------------------------------------------------------
  --  Nom           : run_import
  --  Description   : Procedure qui permet de lancer le traitement Standard  ARLPLB
  --                  de l'open interface
  --  PARAMETRES    :
  --  PARAMETRES    :
  --      pn_transmission_id              Entrée
  --      pn_org_id                       Entrée
  --      pn_request_id                           Sortie
  --      pv_errbuf               Entrée  Sortie
  --      pv_retcode                          Sortie
  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: OK, 2: erreur ou le code  erreur ORA
  ------------------------------------------------------------------------------------------
  PROCEDURE run_import(pv_errbuf          IN OUT VARCHAR2,
                       pn_retcode         OUT NUMBER,
                       pn_transmission_id IN NUMBER,
                       pn_org_id          IN NUMBER,
                       pv_acct_area       IN VARCHAR2,
                       pv_region_ap       IN VARCHAR2, --RBE artf2418217
                       pv_segment3        IN VARCHAR2,
                       pn_ar_org_id       IN NUMBER, -- PHENIX 2004
                       pn_request_id      OUT NUMBER);

  ------------------------------------------------------------------------------------
  --  Nom           : run_all_imports
  --  Description   : Procedure qui permet d'enchainer tous les traitements de l'open interface
  --  PARAMETRES    :
  --  PARAMETRES    :
  --      pv_errbuf       Entrée  Sortie
  --      pv_retcode                  Sortie
  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: OK, 2: erreur ou le code  erreur ORA
  -------------------------------------------------------------------------------------------
  PROCEDURE run_all_imports(pv_errbuf  IN OUT VARCHAR2,
                            pn_retcode OUT NUMBER);

  --------------------------------------------------------------------------------------------------------------------
  --  Nom           :tieback
  --  Description   :Cette procédure permet de:
  --                 Mettre à jour de la table dka_sarencais_tmp avec le status='A'  pour les lignes accéptées.
  --                 Mettre à jour de la table dka_sarencais_tmp avec le status='W'  pour les lignes non lettrées.
  --                 Mettre à jour de la table dka_sarencais_tmp avec le status='R'  pour les lignes rejetées.
  --                 Mettre à jour du check_id dans ap_checks_all  correspondant à l'id du règlement dans AR.
  --  PARAMETRES :
  --      pv_errbuf           Entrée  Sortie
  --      pn_retcode                  Sortie
  --  VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles : 0: deroulement correct
  --               2: deroulement avec erreur
  ---------------------------------------------------------------------------------------------------------------------
  PROCEDURE tieback(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER);

  ------------------------------------------------------------------------------------------------------------
  --  Nom           :output_status
  --  Description   :Cette procédure permet d'afficher un etat de sortie suivant un status donné.
  --  PARAMETRES :
  --      pv_status               Entrée
  --      pv_errbuf           Entrée  Sortie
  --      pn_retcode                  Sortie
  --  VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles : 0: deroulement correct
  --               2: deroulement avec erreur
  -----------------------------------------------------------------------------------------------------------
  PROCEDURE output_status(pv_status  IN VARCHAR2,
                          pv_errbuf  IN OUT VARCHAR2,
                          pn_retcode OUT NUMBER);

  ------------------------------------------------------------------------------------------------------------
  --  Nom           :create_output
  --  Description   :Cette procédure permet d'afficher les enregistrements en erreur sous forme
  --                 de tableau dans le fichier de sortie du traitement.
  --  PARAMETRES :
  --      pv_errbuf           Entrée  Sortie
  --      pn_retcode                  Sortie
  --  VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles : 0: deroulement correct
  --               2: deroulement avec erreur
  -----------------------------------------------------------------------------------------------------------
  PROCEDURE create_output(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER);

  ------------------------------------------------------------------------------------------
  --  Nom           : main
  --  Description   : Procédure principale enchaînant l'ensemble des autres procédures.
  --
  --  PARAMETRES :
  --      pv_errbuf               Entrée  Sortie
  --      pn_retcode                  Sortie
  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: normal, 1: warning, 2: erreur
  --
  ----------------------------------------------------------------------------------------
  PROCEDURE main(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER);
  ----------------------------------------------------------------------------------------

END Dka_Sarencais_Pkg;
/
/*<TOAD_FILE_CHUNK>*/
SHOW ERROR
EXIT;
