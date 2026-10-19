CREATE OR REPLACE PACKAGE dka_ipogencom_pkg AS
  ---------------------------------------------------------------------------------------------------------------
  -- $Id: DKA_IPOGENCOM_PKG.pks 416 2007-10-23 15:08:59Z NORDEST\jjardez $
  --
  -- CAPGEMINI
  -- PROJET      : DALKIA Oracle Applications
  -- NOM         : DKA_IPOGENCOM_PKG.pks
  -- DESCRIPTION       : DKA_IPOGENCOM_PKG package spec :
  ---
  --- AUTEUR       : Nicolas Boussekeyt (CAPGEMINI)
  --- DATE DE CREATION : 24/08/2007
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
  ---------------------------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- 26022010   MSL EID20090220 : Ajout procédures modification_commande,
  ---                              create_line_location et create_po_distribution
  --  02/03/2017 RBE artf2106737
  ---------------------------------------------------------------------------------------------------------------

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PUBLIQUES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PRIVEES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PUBLIQUES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


  PROCEDURE genere_compte_commande(p_errbuf                      OUT VARCHAR2,
                                   p_retcode                     IN OUT NUMBER,
                                   p_category                    IN VARCHAR2,
                                   p_expenditure_type            IN VARCHAR2,
                                   p_org_id_expend               IN NUMBER,
                                   p_agent_id                    IN NUMBER,
                                   p_project_id                  IN NUMBER,
								   p_task_id                  IN NUMBER, --RBE
                                   p_vendor_id                   IN NUMBER,
                                   p_ccid                        OUT NUMBER,
                                   p_accrual_ccid                OUT NUMBER,
                                   p_budget_ccid                 OUT NUMBER,
                                   p_variance_ccid               OUT NUMBER,
                                   p_deliver_to_location_id      IN NUMBER,
                                   p_destination_organization_id IN NUMBER);

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : modification_commande
  --  Description   :
  --
  --  PARAMETRES    : p_num_commande numéro de la commande à modifier
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE modification_commande(itemtype  IN VARCHAR2,
                                  itemkey   IN VARCHAR2,
                                  actid     IN NUMBER,
                                  funcmode  IN VARCHAR2,                            
                                  resultout OUT NOCOPY VARCHAR2);

 
  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : create_line_location
  --  Description   :
  --
  --  PARAMETRES    : pn_line_id                  : Id de la ligne
  --                  pn_header_id                : Id de l'entrete de la commande
  --                  pn_quantity                 : Montant de la ligne du contrat
  --                  pn_ship_to_location_id      : Location id de la ligne du contrat
  --                  pn_ship_to_organization_id  : Org_id
  --                  pv_vendor_site_id           : Vendor_id de l'entete de la commande
  --                  pn_line_location_id         : Id de la ligne créée
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  ---------------------------------------------------------------------------------------------------------------  
  PROCEDURE create_line_location(p_errbuf                   OUT VARCHAR2,
                                 p_retcode                  IN OUT NUMBER,
                                 pn_line_id                 IN NUMBER,
                                 pn_header_id               IN NUMBER,
                                 pn_quantity                IN NUMBER,
                                 pn_ship_to_location_id     IN NUMBER,
                                 pn_ship_to_organization_id IN NUMBER,
                                 pv_vendor_site_id          IN NUMBER,
                                 pn_line_location_id        OUT NUMBER); 

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : create_line_location
  --  Description   :
  --
  --  PARAMETRES    : 
  --
  --  VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  ---------------------------------------------------------------------------------------------------------------    
  PROCEDURE create_po_distribution(p_errbuf              OUT VARCHAR2,
                                   p_retcode             IN OUT NUMBER,
                                   pn_line_id            IN NUMBER,
                                   pn_header_id          IN NUMBER,
                                   pn_line_location_id   IN NUMBER,
                                   pv_nature_prestation  IN VARCHAR2,
                                   pv_expenditure_type   IN VARCHAR2,
                                   pn_agent_id           IN NUMBER,
                                   pn_project_id         IN NUMBER,
                                   pn_vendor_id          IN NUMBER,
                                   pn_quantity           IN NUMBER,
                                   pn_expenditure_org_id IN NUMBER,
                                   pn_contrat_imputation_id IN NUMBER,
                                   pn_task_id            IN NUMBER,
                                   pn_org_id             IN NUMBER
                                   );

 ---------------------------------------------------------------------------------------------------------------
  --  Nom           : main
  --  Description   : procédure principale
  --
  --  PARAMETRES    :
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE main(p_errbuf     OUT VARCHAR2,
                 p_retcode    IN OUT NUMBER,
                 p_debug      IN BOOLEAN,
                 p_id_contrat IN NUMBER,
                 p_group_id   OUT NUMBER);

END dka_ipogencom_pkg; -- Spécification du package
/
SHOW ERROR PACKAGE DKA_IPOGENCOM_PKG;
EXIT
