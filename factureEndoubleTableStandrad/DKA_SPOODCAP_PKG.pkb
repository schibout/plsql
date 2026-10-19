CREATE OR REPLACE PACKAGE DKA_SPOCHARGE_PKG AS
  ---------------------------------------------------------------------------------------------- 
  -- $$
  -- CAP GEMINI ERNST AND YOUNG
  -- PROJET            : DALKIA Oracle Applications
  -- NOM             : DKA_SPOCHARGE_PKG.pks
  -- DESCRIPTION       : DKA_SPOCHARGE_PKG package spec : package pour ******************  
  ---
  --- AUTEUR           : AZIZ NOUJOUD(CGEY)
  --- DATE DE CREATION : 07/05/2002
  --- DOC. ASSOCIEE    : 
  -- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
  ----------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- ---------- --- -------------------------------------------------------------------------
  --  06/11/2007 ADR ETANCHEITE DALKIA 2007
  --  05/09/2016 MEG Migration R12
  --- 20/04/2017 RBE artf2140484 : SPE064 - Problème de performance
  --- 20/06/2017 MEG artf2173355 : SPE064 - Comptabilisation des charges à payer - Fonctionnement
  --- 08/03/2018 MEG artf2415550 : SPE064 - Charges a payer fournisseur - Date de la tache 
  ----------------------------------------------------------------------------------------------

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PUBLIQUES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  /* ETANCHEITE DALKIA 2007 */
  --gn_org_id    NUMBER := TO_NUMBER(FND_PROFILE.VALUE('ORG_ID'));
  --gn_ledger_id NUMBER;
  --gn_set_of_books_id NUMBER := TO_NUMBER(Fnd_Profile.VALUE ('GL_SET_OF_BKS_ID'));

  -----------------------------------------------------------------------------
  -- Defining global variables for the calling api.
  -----------------------------------------------------------------------------
  G_RECEIPT_ACCRUAL_PER_END   CONSTANT NUMBER := 1;
  G_UNINVOICED_RECEIPT_REPORT CONSTANT NUMBER := 2;

  -- Global variables to track the quantities for each distribution. Using global
  -- variables, since the API is being called by PAC Period end process also.
  g_shipment_net_qty_received  NUMBER;
  g_shipment_net_qty_delivered NUMBER;
  g_dist_net_qty_delivered     NUMBER;
  g_distribution_id            NUMBER;
  g_shipment_id                NUMBER;
  g_nqr                        NUMBER;
  g_nqd                        NUMBER;

  -----------------------------------------------------------------------------
  -- PL/SQL table types for accrual info to be inserted in temp table
  -----------------------------------------------------------------------------
  TYPE acr_dist_id_tbl_type IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  TYPE acr_shipment_id_tbl_type IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  TYPE acr_category_id_tbl_type IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  TYPE acr_match_option_tbl_type IS TABLE OF VARCHAR2(1) INDEX BY BINARY_INTEGER;
  TYPE acr_qty_received_tbl_type IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  TYPE acr_qty_billed_tbl_type IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  TYPE acr_accrual_qty_tbl_type IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  TYPE acr_encum_qty_tbl_type IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  TYPE acr_unit_price_tbl_type IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  TYPE acr_accrual_amount_tbl_type IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  TYPE acr_encum_amount_tbl_type IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  TYPE acr_cur_code_tbl_type IS TABLE OF VARCHAR2(15) INDEX BY BINARY_INTEGER;
  TYPE acr_cur_conv_type_tbl_type IS TABLE OF VARCHAR2(30) INDEX BY BINARY_INTEGER;
  TYPE acr_cur_conv_rate_tbl_type IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  TYPE acr_cur_conv_date_tbl_type IS TABLE OF DATE INDEX BY BINARY_INTEGER;
  TYPE acr_project_id IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  TYPE acr_task_id IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  TYPE acr_expenditure_type IS TABLE OF VARCHAR2(30) INDEX BY BINARY_INTEGER;
  TYPE acr_date_fermeture_tache IS TABLE OF DATE INDEX BY BINARY_INTEGER;
  TYPE acr_ccid_imputation IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  TYPE acr_ccid_provision IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  TYPE acr_segment1 IS TABLE OF VARCHAR2(25) INDEX BY BINARY_INTEGER;
  TYPE acr_segment2 IS TABLE OF VARCHAR2(25) INDEX BY BINARY_INTEGER;
  TYPE acr_segment6 IS TABLE OF VARCHAR2(25) INDEX BY BINARY_INTEGER;
  TYPE acr_segment7 IS TABLE OF VARCHAR2(25) INDEX BY BINARY_INTEGER;
  TYPE acr_new_segment6 IS TABLE OF VARCHAR2(25) INDEX BY BINARY_INTEGER;
  TYPE acr_new_segment7 IS TABLE OF VARCHAR2(25) INDEX BY BINARY_INTEGER;
  TYPE acr_concatenated_segments IS TABLE OF VARCHAR2(311) INDEX BY BINARY_INTEGER;
  TYPE acr_pp_segment1 IS TABLE OF VARCHAR2(25) INDEX BY BINARY_INTEGER;
  TYPE acr_ph_segment1 IS TABLE OF VARCHAR2(25) INDEX BY BINARY_INTEGER;
  TYPE acr_ph_creation_date IS TABLE OF DATE INDEX BY BINARY_INTEGER;
  TYPE acr_line_num IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  TYPE acr_project_num IS TABLE OF VARCHAR2(25) INDEX BY BINARY_INTEGER; 
  TYPE acr_task_num IS TABLE OF VARCHAR2(25) INDEX BY BINARY_INTEGER; 
  TYPE acr_ledger_id IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  
  TYPE dist_nqd_tbl_type IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  g_dist_nqd_tbl dist_nqd_tbl_type;

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PUBLIQUES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  ---------------------------------------------------------------------------------------------------
  --  Nom           : Create_PerEndAccruals
  --  Description   : Procédure basée sur le procédure standard CST_PerEndAccruals_PVT.Create_PerEndAccruals

  --  PARAMETRES    :
  --     p_api_version      NUMBER       Required
  --     p_init_msg_list    VARCHAR2     Required
  --     p_commit           VARCHAR2     Required
  --     p_validation_level NUMBER       Required
  --     p_min_accrual_amount NUMBER     Required
  --                                     Minimum Accrual Amount
  --     p_vendor_id        NUMBER       Optional         default NULL
  --     p_vendor_from      VARCHAR2     Optional         default NULL
  --                                     Vendor From
  --     p_vendor_to        VARCHAR2     Optional         default NULL
  --                                     Vendor to
  --     p_category_id      NUMBER       Optional         default NULL
  --                                     Category Id
  --     p_category_from    VARCHAR2     Optional         default NULL
  --                                     Category From
  --     p_category_to      VARCHAR2     Optional         default NULL
  --                                     Category to
  --     p_end_date         DATE         Required
  --                                     Period End date
  --     p_accrued_receipt  VARCHAR2     Optional         default NULL
  --                                     Accrued receipts, 'Y' or 'N'
  --     p_online_accruals  VARCHAR2     Optional         default NULL
  --                                     Include online accruals 'Y' or 'N'
  --     p_online_accruals  VARCHAR2     Optional         default NULL
  --                                     Include Closed POs 'Y' or 'N'
  --
  --                                     p_online_accruals, p_accrued_receipts and
  --                                     p_online_accruals are used for Uninvoiced
  --                                     Receipts Report, in other case this value
  --                                     will be 'N'
  --     p_calling_api      NUMBER       Optional
  --
  --   OUT             :
  --     x_return_status    VARCHAR2
  --     x_msg_count        NUMBER
  --     x_msg_data         VARCHAR2
  --
  --   Version : Current version       1.0
  --  VALEUR RETOURNEE :
  --     N/A
  ----------------------------------------------------------------------------------------------------------
  PROCEDURE Create_PerEndAccruals(p_api_version      IN NUMBER,
                                  p_init_msg_list    IN VARCHAR2,
                                  p_commit           IN VARCHAR2,
                                  p_validation_level IN NUMBER,
                                  x_return_status    OUT NOCOPY VARCHAR2,
                                  x_msg_count        OUT NOCOPY NUMBER,
                                  x_msg_data         OUT NOCOPY VARCHAR2,
                                  
                                  p_min_accrual_amount  IN NUMBER,
                                  p_vendor_id           IN NUMBER DEFAULT NULL,
                                  p_vendor_from         IN VARCHAR2 DEFAULT NULL,
                                  p_vendor_to           IN VARCHAR2 DEFAULT NULL,
                                  p_category_id         IN NUMBER DEFAULT NULL,
                                  p_category_from       IN VARCHAR2 DEFAULT NULL,
                                  p_category_to         IN VARCHAR2 DEFAULT NULL,
                                  p_end_date            IN DATE,
                                  p_accrued_receipt     IN VARCHAR2 DEFAULT NULL,
                                  p_online_accruals     IN VARCHAR2 DEFAULT NULL,
                                  p_closed_pos          IN VARCHAR2 DEFAULT NULL,
                                  p_calling_api         IN NUMBER,
                                  p_accrual_effect_date IN DATE,
                                  p_org_name            IN VARCHAR2,
                                  p_period_name         IN VARCHAR2);

  ---------------------------------------------------------------------------------------------------
  --  Nom           : update_gl
  --  Description   : Procédure permettant de mettre a jour les CUF au niveau des pieces GL

  --  PARAMETRES    :
  -- pv_errbuf                 Entrée/Sortie      message d'erreur
  -- pn_retcode                Sortie             code de retour: 'o=normal', '1=warning', '2=erreur'
  --  VALEUR RETOURNEE :
  --     N/A
  ----------------------------------------------------------------------------------------------------------
  PROCEDURE update_gl(pv_period       IN VARCHAR2, --RBE artf2140484
                      pv_errbuf       IN OUT VARCHAR2,
                      pn_retcode      OUT NUMBER,
                      va_batches_name IN OUT Pa_Utils.Char240TabTyp);

  -------------------------------------------------------------------------------------------------------------------------------------                                                                             
  --  Nom           : run_prog_standard                                                                                                                                                                     
  --  Description   : Procedure de lancement du traitement standard Provisions pour réceptions-fin de période                                                                               
  --  PARAMETRES    :  
  -- pn_group_id              Entrée                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
  -- pn_interface_run_id       Entrée 
  -- pn_request_id            Sortie                                                                                                                                                                               
  -- pv_errbuf                 Entrée/Sortie    message d'erreur                                                                                                                                                    
  -- pn_retcode                Sortie           code de retour: 'o=normal', '1=warning', '2=erreur'                                                                                                                 

  --  VALEUR RETOURNEE :                                                                                                                                                                                            
  --     Description       :                                                                                                                                                                         
  --     Valeurs possibles :                                                                                                                                                      
  ------------------------------------------------------------------------------------------------------------------------------------------                                                                        
  PROCEDURE run_prog_standard(pv_period_name IN VARCHAR2,
                              pv_errbuf      OUT VARCHAR2,
                              pn_retcode     OUT NUMBER);

  -------------------------------------------------------------------------------------------------------------------------------------
  --  Nom           : run_prog_comptabilisation
  --  Description   : Procedure de lancement du traitement standard "Créer une comptabilisation - Receiving"
  --  PARAMETRES    :
  -- pv_period_name            Entrée
  -- pv_errbuf                 Entrée/Sortie    message d'erreur
  -- pn_retcode                Sortie           code de retour: 'o=normal', '1=warning', '2=erreur'

  --  VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  ------------------------------------------------------------------------------------------------------------------------------------------
  PROCEDURE run_prog_comptabilisation(pv_period_name  IN VARCHAR2,
                                      pv_errbuf       OUT VARCHAR2,
                                      pn_retcode      OUT NUMBER,
                                      va_batches_name IN OUT Pa_Utils.Char240TabTyp);

  -------------------------------------------------------------------------------------------------------------------------------------                                                                             
  --  Nom           : run_import                                                                                                                                                                     
  --  Description   : Procédure de lancement du Traitement Standard GLLEZI EASYlink de l'open interface                                                                               
  --  PARAMETRES    :  
  -- pn_group_id              Entrée                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
  -- pn_interface_run_id       Entrée 
  -- pn_request_id            Sortie                                                                                                                                                                               
  -- pv_errbuf                 Entrée/Sortie    message d'erreur                                                                                                                                                    
  -- pn_retcode                Sortie           code de retour: 'o=normal', '1=warning', '2=erreur'                                                                                                                 

  --  VALEUR RETOURNEE :                                                                                                                                                                                            
  --     Description       :                                                                                                                                                                         
  --     Valeurs possibles :                                                                                                                                                      
  ------------------------------------------------------------------------------------------------------------------------------------------                                                                        
  /*  PROCEDURE run_import(pn_group_id   IN NUMBER,
  pn_request_id OUT NUMBER,
  pv_errbuf     OUT VARCHAR2,
  pn_retcode    OUT NUMBER);*/

  ---------------------------------------------------------------------------------------------------
  --  Nom           : UPDATE_GL_INTERFACE
  --  Description   : Procédure qui permet de mettre à jour les lignes de GL INTERFACES qui viennent 
  --                 d'être créer par le traitement standard Provisions pour réceptions-fin de période.
  --
  --  PARAMETRES    :
  -- pv_errbuf                 Entrée/Sortie      message d'erreur
  -- pn_retcode                Sortie             code de retour: 'o=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     N/A
  ----------------------------------------------------------------------------------------------------------
  /*  PROCEDURE UPDATE_GL_INTERFACE(pv_errbuf  IN OUT VARCHAR2,
  pn_retcode OUT NUMBER);*/

  ---------------------------------------------------------------------------------------------------
  --  Nom           : main
  --  Description   : Procédure principale du spécifique SPOCHARGE enchainant les différentes procédure 
  --        
  --  
  --  PARAMETRES    :
  -- pv_errbuf                 Entrée/Sortie      message d'erreur
  -- pn_retcode                Sortie             code de retour: 'o=normal', '1=warning', '2=erreur'
  --  VALEUR RETOURNEE :
  --     N/A
  ----------------------------------------------------------------------------------------------------------
  PROCEDURE main(pv_errbuf  IN OUT VARCHAR2,
                 pn_retcode OUT NUMBER,
                 pv_period  IN VARCHAR);

END DKA_SPOCHARGE_PKG;
/
SHOW ERROR
EXIT;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
