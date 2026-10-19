CREATE OR REPLACE PACKAGE BODY dka_ipogencom_pkg AS
  ---------------------------------------------------------------------------------------------------------------
  -- $Id: DKA_IPOGENCOM_PKG.pkb 416 2007-10-23 15:08:59Z NORDEST\jjardez $
  --
  -- CAPGEMINI
  -- PROJET      : DALKIA Oracle Applications
  -- NOM         : DKA_IPOGENCOM_PKG.pkb
  -- DESCRIPTION       : DKA_IPOGENCOM_PKG package body :
  ---
  --- AUTEUR       : Nicolas Boussekeyt (CAPGEMINI)
  --- DATE DE CREATION : 27/08/2007
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
  ---------------------------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- ---------- --- --------------------------------------------------------------------------------------------
  --- 19/10/2007 JJA FT N° 22 : selection sur l'affectation active pour la date du jour
  --  23/10/2007 NBO FT N° 22 : Gère la gestion des erreurs de l'open-interface PO.
  --  10/12/2008 CDE Evol EID20080144
  --  03/04/2009 SRO Evol EID20090113
  --  06/05/2009 CDE EARS00008641539 - Correction lieu de livraison et facturation sur en-tête commande
  --  11/01/2010 CDE Evol EID20090323 - modification type de dépense
  --  26/02/2010 MSL EID20090220 : Ajout procédures modification_commande, create_line_location
  --                  et create_po_distribution
  --  14/06/2010 CDE EID20100127 : Changement du numéro de commande
  --  01/06/2010 CDE EID20100093 - Modif détermination ship_to_organization pour lancement par VP +
  --                  modif récupération organisation du gestionnaire suite spécificité VP
  --  05/05/2011 CDE EARS00009482198 - Correction pour empêcher génération frais de port sur SSTR
  --                 + DGE20100001 - Evol Interface utilisateurs - Approb auto cde en création et renouv
  --  13/10/2011 EMA DGE20110021 - Ajout de la gestion des paiements directs.
  --  25/02/2013 BCO DPE20130002 - Avenant au devis DPE20120104_OA Achats Divers SSTR
  --                   DPE20120104 - Ajout de la gestion des prestations unitaires.
  --  11/10/2013 BCO INC000000462675 - Mode Modification - Mise à jour du numéro de révision lorsque les cases à cochées prestations unitaire et paiement direct sont cochées.
  --  02/03/2017 RBE artf2106737
  --  17/04/2017 RBE artf2139561 - DEFECT 595 - Contrat approuvé mais pas de commande standard créée
  --  02/06/2017 RBE artf2169042 : SPE119 - DEFECT 628 - Génération commande pour contrats multi-imputations
  --  04/07/2017 RBE artf2182182 : SPE119 - Ajout d'une ligne d'imputation sur un contrat
  --  08/02/2018 JWT artf2363899 : SPE119 - Problème lors de l'approbation de certains contrats SSTR
  --                      Alimentation du champ DESTINATION_TYPE_CODE au lieu de DESTINATION_TYPE
  --  13/03/2018 MEG artf2429640 : Contrats SSTR - Commandes en erreur à l'année 0018
  --  14/03/2018 MEG artf2435496 : SPE119 - Org_id erronée lors de la creation de la commande
  --  03/05/2018 MEG artf2589718 : SPE119 - Commandes générées avec la mauvaise clé comptable
  --  14/05/2019 SFA artf07231300: SPE119 : modification de la devise.
  --  05/12/2019 CDE EDB241 : Adaptation pour Dalkia Suisse. Modification unité de mesure utilisée
  ---------------------------------------------------------------------------------------------------------------

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PUBLIQUES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  cst_st CONSTANT      VARCHAR2(50) := 'ST';
  cst_type_ligne       CONSTANT VARCHAR2(50) := 'PRESTATION';
  cst_uom_code         VARCHAR2(10);
  g_debug              BOOLEAN := FALSE;
  g_po_header_id_intf  NUMBER;
  g_po_line_id_intf    NUMBER;
  g_po_distrib_id_intf NUMBER;
  g_org_id             NUMBER; --:= fnd_profile.VALUE('ORG_ID');

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PRIVEES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -------------------------------------------------------------------------------------
  --  Nom           : PRINT_LOG_MESSAGE
  --  Description   : Procédure insérant un message dans le log du traitement.
  --
  --  PARAMETRES :
  --     p_message   Entrée      Message à insérer
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE print_log_message(p_message IN VARCHAR2) IS
    l_message VARCHAR2(1000);
  BEGIN

    l_message := substr(p_message, 1, 1000);

    IF (l_message IS NOT NULL AND g_debug = TRUE)
    THEN
      l_message := to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                   l_message;
      dbms_output.put_line(l_message);
    END IF;

    fnd_file.put_line(fnd_file.log, l_message);

  END print_log_message;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : recupere_numero_de_commande
  --  Description   : Récupère le numéro de la commande standard
  --
  --  PARAMETRES    :
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION recupere_numero_de_commande(p_id_contrat NUMBER) RETURN VARCHAR2 IS
    l_num_commande VARCHAR2(50);
  BEGIN

  --  03/04/2009 SRO Evol EID20090113 Modification de la numerotation de la commande annuelle avec la date de debut du contrat
  --  14/06/2010 CDE EID20100127 Année+Mois sur 4 caractères après le ST au lieu de l'année seulement
    SELECT segment1 || to_char(start_date, 'YYMM') --RBE artf2139561
      INTO l_num_commande
      FROM po_headers_all
     WHERE po_header_id = p_id_contrat;
    RETURN l_num_commande;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END recupere_numero_de_commande;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : verifie_existence_commande
  --  Description   : Vérifie que la commande standard existe
  --
  --  PARAMETRES    : p_num_commande numéro de la commande à vérifier
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : Existence de la commande
  --     Valeurs possibles : Oui ou Non, Oui si la commande existe
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION verifie_existence_commande(p_num_commmande VARCHAR2)
    RETURN BOOLEAN IS
    l_count NUMBER;
  BEGIN

    SELECT COUNT(*)
      INTO l_count
      FROM po_headers_all
     WHERE segment1 = p_num_commmande;

    IF l_count = 1
    THEN
      RETURN TRUE;
    ELSE
      RETURN FALSE;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN TRUE;
  END verifie_existence_commande;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : verifie_approbation_contrat
  --  Description   : Vérifie que le contrat est approuvé
  --
  --  PARAMETRES    : p_num_commande numéro de la commande à vérifier
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : Existence de la commande
  --     Valeurs possibles : Oui ou Non, Oui si la commande existe
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION verifie_approbation_contrat(p_id_contrat NUMBER) RETURN BOOLEAN IS
    l_count NUMBER;
  BEGIN

    SELECT COUNT(*)
      INTO l_count
      FROM po_headers_all
     WHERE po_header_id = p_id_contrat AND
           nvl(authorization_status, 'VIDE') = 'APPROVED';

    IF l_count = 1
    THEN
      RETURN TRUE;
    ELSE
      RETURN FALSE;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN TRUE;
  END verifie_approbation_contrat;

  -------------------------------------------------------------------------------------
  --  Nom           : GENERE_COMPTE_COMMANDE
  --  Description   :
  --
  --  PARAMETRES :
  --     p_message   Entrée      Message à insérer
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE genere_compte_commande(p_errbuf                      OUT VARCHAR2,
                                   p_retcode                     IN OUT NUMBER,
                                   p_category                    IN VARCHAR2,
                                   p_expenditure_type            IN VARCHAR2,
                                   p_org_id_expend               IN NUMBER,
                                   p_agent_id                    IN NUMBER,
                                   p_project_id                  IN NUMBER,
                                   p_task_id                     IN NUMBER, --RBE MigR12
                                   p_vendor_id                   IN NUMBER,
                                   p_ccid                        OUT NUMBER,
                                   p_accrual_ccid                OUT NUMBER,
                                   p_budget_ccid                 OUT NUMBER,
                                   p_variance_ccid               OUT NUMBER,
                                   p_deliver_to_location_id      IN NUMBER,
                                   p_destination_organization_id IN NUMBER) IS
    result BOOLEAN;

    l_charge_success              BOOLEAN;
    l_budget_success              BOOLEAN;
    l_accrual_success             BOOLEAN;
    l_variance_success            BOOLEAN;
    l_code_combination_id         gl_code_combinations_kfv.code_combination_id%TYPE;
    l_budget_account_id           gl_code_combinations_kfv.code_combination_id%TYPE;
    l_accrual_account_id          gl_code_combinations_kfv.code_combination_id%TYPE;
    l_variance_account_id         gl_code_combinations_kfv.code_combination_id%TYPE;
    l_charge_account_flex         gl_code_combinations_kfv.concatenated_segments%TYPE;
    l_budget_account_flex         gl_code_combinations_kfv.concatenated_segments%TYPE;
    l_accrual_account_flex        gl_code_combinations_kfv.concatenated_segments%TYPE;
    l_variance_account_flex       gl_code_combinations_kfv.concatenated_segments%TYPE;
    l_charge_account_desc         gl_code_combinations_kfv.description%TYPE;
    l_budget_account_desc         gl_code_combinations_kfv.description%TYPE;
    l_accrual_account_desc        gl_code_combinations_kfv.description%TYPE;
    l_variance_account_desc       gl_code_combinations_kfv.description%TYPE;
    l_coa_id                      NUMBER;
    l_bom_resource_id             NUMBER;
    l_bom_cost_element_id         NUMBER;
    l_category_id                 NUMBER;
    l_destination_type_code       VARCHAR2(100);
    l_deliver_to_location_id      NUMBER;
    l_destination_organization_id NUMBER;
    l_destination_subinventory    VARCHAR2(100);
    l_expenditure_type            VARCHAR2(100);
    l_expenditure_organization_id NUMBER;
    l_expenditure_item_date       DATE;
    l_item_id                     NUMBER;
    l_line_type_id                NUMBER;
    l_result_billable_flag        VARCHAR2(100);
    l_agent_id                    NUMBER;
    l_project_id                  NUMBER;
    l_from_type_lookup_code       VARCHAR2(100);
    l_from_header_id              NUMBER;
    l_from_line_id                NUMBER;
    --l_task_id                     NUMBER; --RBE MigR12
    l_deliver_to_person_id        NUMBER;
    l_type_lookup_code            VARCHAR2(100);
    l_vendor_id                   NUMBER;
    l_wip_entity_id               NUMBER;
    l_wip_entity_type             VARCHAR2(100);
    l_wip_line_id                 NUMBER;
    l_wip_repetitive_schedule_id  NUMBER;
    l_wip_operation_seq_num       NUMBER;
    l_wip_resource_seq_num        NUMBER;
    l_po_encumberance_flag        VARCHAR2(100);
    l_gl_encumbered_date          DATE;
    l_wf_itemkey                  VARCHAR2(100);
    l_new_combination             BOOLEAN;
    l_header_att1                 VARCHAR2(240);
    l_header_att2                 VARCHAR2(240);
    l_header_att3                 VARCHAR2(240);
    l_header_att4                 VARCHAR2(240);
    l_header_att5                 VARCHAR2(240);
    l_header_att6                 VARCHAR2(240);
    l_header_att7                 VARCHAR2(240);
    l_header_att8                 VARCHAR2(240);
    l_header_att9                 VARCHAR2(240);
    l_header_att10                VARCHAR2(240);
    l_header_att11                VARCHAR2(240);
    l_header_att12                VARCHAR2(240);
    l_header_att13                VARCHAR2(240);
    l_header_att14                VARCHAR2(240);
    l_header_att15                VARCHAR2(240);
    l_line_att1                   VARCHAR2(240);
    l_line_att2                   VARCHAR2(240);
    l_line_att3                   VARCHAR2(240);
    l_line_att4                   VARCHAR2(240);
    l_line_att5                   VARCHAR2(240);
    l_line_att6                   VARCHAR2(240);
    l_line_att7                   VARCHAR2(240);
    l_line_att8                   VARCHAR2(240);
    l_line_att9                   VARCHAR2(240);
    l_line_att10                  VARCHAR2(240);
    l_line_att11                  VARCHAR2(240);
    l_line_att12                  VARCHAR2(240);
    l_line_att13                  VARCHAR2(240);
    l_line_att14                  VARCHAR2(240);
    l_line_att15                  VARCHAR2(240);
    l_shipment_att1               VARCHAR2(240);
    l_shipment_att2               VARCHAR2(240);
    l_shipment_att3               VARCHAR2(240);
    l_shipment_att4               VARCHAR2(240);
    l_shipment_att5               VARCHAR2(240);
    l_shipment_att6               VARCHAR2(240);
    l_shipment_att7               VARCHAR2(240);
    l_shipment_att8               VARCHAR2(240);
    l_shipment_att9               VARCHAR2(240);
    l_shipment_att10              VARCHAR2(240);
    l_shipment_att11              VARCHAR2(240);
    l_shipment_att12              VARCHAR2(240);
    l_shipment_att13              VARCHAR2(240);
    l_shipment_att14              VARCHAR2(240);
    l_shipment_att15              VARCHAR2(240);
    l_distribution_att1           VARCHAR2(240);
    l_distribution_att2           VARCHAR2(240);
    l_distribution_att3           VARCHAR2(240);
    l_distribution_att4           VARCHAR2(240);
    l_distribution_att5           VARCHAR2(240);
    l_distribution_att6           VARCHAR2(240);
    l_distribution_att7           VARCHAR2(240);
    l_distribution_att8           VARCHAR2(240);
    l_distribution_att9           VARCHAR2(240);
    l_distribution_att10          VARCHAR2(240);
    l_distribution_att11          VARCHAR2(240);
    l_distribution_att12          VARCHAR2(240);
    l_distribution_att13          VARCHAR2(240);
    l_distribution_att14          VARCHAR2(240);
    l_distribution_att15          VARCHAR2(240);
    l_fb_error_msg                VARCHAR2(1000);
  BEGIN
    l_bom_cost_element_id   := NULL;
    l_from_type_lookup_code := NULL;
    l_from_header_id        := NULL;
    l_from_line_id          := NULL;
    l_wip_entity_type       := NULL;

    SELECT chart_of_accounts_id
      INTO l_coa_id
      FROM gl_sets_of_books
     WHERE set_of_books_id = fnd_profile.VALUE('GL_SET_OF_BKS_ID');

    SELECT category_id
      INTO l_category_id
      FROM mtl_categories_kfv
     WHERE concatenated_segments = p_category AND structure_id = 201;

    SELECT line_type_id
      INTO l_line_type_id
      FROM po_line_types_all_v
     WHERE line_type = cst_type_ligne;

    --RBE MigR12
    /*
    SELECT task_id
      INTO l_task_id
      FROM pa_tasks
     WHERE project_id = p_project_id AND task_number = 1;
     */

    -- Call the function
    result := po_wf_build_account_init.start_workflow(x_charge_success              => l_charge_success,
                                                      x_budget_success              => l_budget_success,
                                                      x_accrual_success             => l_accrual_success,
                                                      x_variance_success            => l_variance_success,
                                                      x_code_combination_id         => l_code_combination_id,
                                                      x_budget_account_id           => l_budget_account_id,
                                                      x_accrual_account_id          => l_accrual_account_id,
                                                      x_variance_account_id         => l_variance_account_id,
                                                      x_charge_account_flex         => l_charge_account_flex,
                                                      x_budget_account_flex         => l_budget_account_flex,
                                                      x_accrual_account_flex        => l_accrual_account_flex,
                                                      x_variance_account_flex       => l_variance_account_flex,
                                                      x_charge_account_desc         => l_charge_account_desc,
                                                      x_budget_account_desc         => l_budget_account_desc,
                                                      x_accrual_account_desc        => l_accrual_account_desc,
                                                      x_variance_account_desc       => l_variance_account_desc,
                                                      x_coa_id                      => l_coa_id,
                                                      x_bom_resource_id             => l_bom_resource_id,
                                                      x_bom_cost_element_id         => l_bom_cost_element_id,
                                                      x_category_id                 => l_category_id,
                                                      x_destination_type_code       => 'EXPENSE',
                                                      x_deliver_to_location_id      => l_deliver_to_location_id,
                                                      x_destination_organization_id => p_destination_organization_id,
                                                      x_destination_subinventory    => l_destination_subinventory,
                                                      x_expenditure_type            => p_expenditure_type,
                                                      x_expenditure_organization_id => p_org_id_expend,
                                                      x_expenditure_item_date       => SYSDATE,
                                                      x_item_id                     => l_item_id,
                                                      x_line_type_id                => l_line_type_id,
                                                      x_result_billable_flag        => 'N',
                                                      x_agent_id                    => p_agent_id,
                                                      x_project_id                  => p_project_id,
                                                      x_from_type_lookup_code       => l_from_type_lookup_code,
                                                      x_from_header_id              => l_from_header_id,
                                                      x_from_line_id                => l_from_line_id,
                                                      x_task_id                     => p_task_id, --l_task_id, --RBE
                                                      x_deliver_to_person_id        => l_deliver_to_person_id,
                                                      x_type_lookup_code            => 'STANDARD',
                                                      x_vendor_id                   => p_vendor_id,
                                                      x_wip_entity_id               => l_wip_entity_id,
                                                      x_wip_entity_type             => l_wip_entity_type,
                                                      x_wip_line_id                 => l_wip_line_id,
                                                      x_wip_repetitive_schedule_id  => l_wip_repetitive_schedule_id,
                                                      x_wip_operation_seq_num       => l_wip_operation_seq_num,
                                                      x_wip_resource_seq_num        => l_wip_resource_seq_num,
                                                      x_po_encumberance_flag        => 'N',
                                                      x_gl_encumbered_date          => l_gl_encumbered_date,
                                                      wf_itemkey                    => l_wf_itemkey,
                                                      x_new_combination             => l_new_combination,
                                                      header_att1                   => l_header_att1,
                                                      header_att2                   => l_header_att2,
                                                      header_att3                   => l_header_att3,
                                                      header_att4                   => l_header_att4,
                                                      header_att5                   => l_header_att5,
                                                      header_att6                   => l_header_att6,
                                                      header_att7                   => l_header_att7,
                                                      header_att8                   => l_header_att8,
                                                      header_att9                   => l_header_att9,
                                                      header_att10                  => l_header_att10,
                                                      header_att11                  => l_header_att11,
                                                      header_att12                  => l_header_att12,
                                                      header_att13                  => l_header_att13,
                                                      header_att14                  => l_header_att14,
                                                      header_att15                  => l_header_att15,
                                                      line_att1                     => l_line_att1,
                                                      line_att2                     => l_line_att2,
                                                      line_att3                     => l_line_att3,
                                                      line_att4                     => l_line_att4,
                                                      line_att5                     => l_line_att5,
                                                      line_att6                     => l_line_att6,
                                                      line_att7                     => l_line_att7,
                                                      line_att8                     => l_line_att8,
                                                      line_att9                     => l_line_att9,
                                                      line_att10                    => l_line_att10,
                                                      line_att11                    => l_line_att11,
                                                      line_att12                    => l_line_att12,
                                                      line_att13                    => l_line_att13,
                                                      line_att14                    => l_line_att14,
                                                      line_att15                    => l_line_att15,
                                                      shipment_att1                 => l_shipment_att1,
                                                      shipment_att2                 => l_shipment_att2,
                                                      shipment_att3                 => l_shipment_att3,
                                                      shipment_att4                 => l_shipment_att4,
                                                      shipment_att5                 => l_shipment_att5,
                                                      shipment_att6                 => l_shipment_att6,
                                                      shipment_att7                 => l_shipment_att7,
                                                      shipment_att8                 => l_shipment_att8,
                                                      shipment_att9                 => l_shipment_att9,
                                                      shipment_att10                => l_shipment_att10,
                                                      shipment_att11                => l_shipment_att11,
                                                      shipment_att12                => l_shipment_att12,
                                                      shipment_att13                => l_shipment_att13,
                                                      shipment_att14                => l_shipment_att14,
                                                      shipment_att15                => l_shipment_att15,
                                                      distribution_att1             => l_distribution_att1,
                                                      distribution_att2             => l_distribution_att2,
                                                      distribution_att3             => l_distribution_att3,
                                                      distribution_att4             => l_distribution_att4,
                                                      distribution_att5             => l_distribution_att5,
                                                      distribution_att6             => l_distribution_att6,
                                                      distribution_att7             => l_distribution_att7,
                                                      distribution_att8             => l_distribution_att8,
                                                      distribution_att9             => l_distribution_att9,
                                                      distribution_att10            => l_distribution_att10,
                                                      distribution_att11            => l_distribution_att11,
                                                      distribution_att12            => l_distribution_att12,
                                                      distribution_att13            => l_distribution_att13,
                                                      distribution_att14            => l_distribution_att14,
                                                      distribution_att15            => l_distribution_att15,
                                                      fb_error_msg                  => l_fb_error_msg);

    IF NOT l_charge_success
    THEN
      print_log_message(l_fb_error_msg);
      p_errbuf  := l_fb_error_msg;
      p_retcode := 2;
    ELSE
      print_log_message('l_code_combination_id = ' ||
                        l_code_combination_id);
      print_log_message('l_charge_account_flex = ' ||
                        l_charge_account_flex);
      print_log_message('l_accrual_ccid = ' || p_accrual_ccid);
      print_log_message('l_budget_ccid = ' || p_budget_ccid);
      print_log_message('fb_error_msg = ' || l_fb_error_msg);
      p_ccid          := l_code_combination_id;
      p_accrual_ccid  := l_accrual_account_id;
      p_budget_ccid   := l_budget_account_id;
      p_variance_ccid := l_variance_account_id;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'GENERE_COMPTE_COMMANDE =>' || SQLERRM;
  END genere_compte_commande;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : insere_entete_commande
  --  Description   :
  --
  --  PARAMETRES    : p_num_commande numéro de la commande à vérifier
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE insere_entete_commande(p_errbuf          OUT VARCHAR2,
                                   p_retcode         IN OUT NUMBER,
                                   p_num_commmande   po_headers_all.segment1%TYPE,
                                   p_vendor_id       po_headers_all.vendor_id%TYPE,
                                   p_vendor_site_id  po_headers_all.vendor_site_id%TYPE,
                                   p_agent_id        po_headers_all.agent_id%TYPE,
                                   p_ship_to         po_headers_all.ship_to_location_id%TYPE,
                                   p_bill_to         po_headers_all.bill_to_location_id%TYPE,
                                   p_paiement_direct po_headers_all.attribute13%TYPE,
                                   p_prestation_unit po_headers_all.attribute14%TYPE,
                                   p_id_contrat      po_headers_all.po_header_id%TYPE
                                   ) IS
    l_step VARCHAR2(50);
    vn_org_id po_headers_all.org_id%TYPE;
	vn_ledger_id gl_ledgers.ledger_id%TYPE;  --Ajout : SFA  : artf07231300   
    v_currency_code gl_ledgers.currency_code%TYPE;  --Ajout : SFA  : artf07231300 
  BEGIN
    
    l_step := 'SEQUENCE';
    SELECT po_headers_interface_s.NEXTVAL
      INTO g_po_header_id_intf
      FROM dual;
    
    l_step := 'ORG_ID';
    SELECT org_id
      INTO vn_org_id
      FROM po_headers_all
     WHERE po_header_id = p_id_contrat;
	 
	 
	 --<!--Ajout SFA  : artf07231300
	 l_step := 'LEDGER_ID';
	  BEGIN
	   SELECT SET_OF_BOOKS_ID
	   INTO vn_ledger_id
       FROM hr_operating_units 
	   WHERE ORGANIZATION_ID =vn_org_id;
	  EXCEPTION  WHEN NO_DATA_FOUND THEN
			vn_ledger_id := NULL;
	 END;     
	  
	   
	 l_step := 'CURRENCY_CODE';  
	BEGIN
		SELECT currency_code 
			INTO   v_currency_code
			FROM   gl_ledgers 
			WHERE  ledger_id = vn_ledger_id;
	 EXCEPTION  WHEN NO_DATA_FOUND THEN
			    v_currency_code := NULL;
	 END;             	   
     -->--FIN AJOUT SFA  : artf07231300	   
    
    l_step := 'INSERT';
    INSERT INTO po_headers_interface
      (interface_header_id,
       batch_id,
       action,
       org_id,
       document_type_code,
       document_num,
       agent_id,
       vendor_id,
       vendor_site_id,
       approval_status,
       ship_to_location_id,
       bill_to_location_id,
       attribute8,
       attribute13,    -- Modif EMA du 13/10/2011
       attribute14, -- Modif BCO du 13/03/2013
       rate_type, --RBE MigR12
       rate_date, --RBE MigR12
       rate,--RBE MigR12
       currency_code)      --RBE MigR12
    VALUES
      (g_po_header_id_intf,
       g_po_header_id_intf,
       'ORIGINAL',
       vn_org_id,
       'STANDARD',
       p_num_commmande,
       p_agent_id,
       p_vendor_id,
       p_vendor_site_id,
       'APPROVED',
       p_ship_to,
       p_bill_to,
       'OUI',            -- Pour eviter calcul des frais de port
       p_paiement_direct,  -- Modif EMA du 13/10/2011
       p_prestation_unit,   -- Modif BCO du 13/03/2013
       NULL, --RBE MigR12
       NULL, --RBE MigR12
       NULL,  --RBE MigR12
       v_currency_code    --SFA  : artf07231300	 --'EUR' --RBE MigR12
       );

  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'insere_entete_commande =>' || l_step || '=>' || SQLERRM;
  END insere_entete_commande;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : insere_ligne_commande
  --  Description   :
  --
  --  PARAMETRES    : p_num_commande numéro de la commande à vérifier
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE insere_ligne_commande(p_errbuf       OUT VARCHAR2,
                                  p_retcode      IN OUT NUMBER,
                                  p_ship_to      po_lines_interface.ship_to_location_id%TYPE,
                                --p_category     po_lines_interface.category%TYPE,
                                  p_category_id  po_lines_interface.category_id%TYPE,
                                  p_item_desc    po_lines_interface.item_description%TYPE,
                                  p_qty          po_lines_interface.quantity%TYPE,
                                  p_line_num     po_lines_interface.line_num%TYPE,
                                  p_id_contrat   po_headers_all.po_header_id%TYPE) IS
    l_step VARCHAR2(50);
    vn_org_id po_headers_all.org_id%TYPE;
	vn_ledger_id gl_ledgers.ledger_id%TYPE;  --Ajout : SFA  : artf07231300   
    v_currency_code gl_ledgers.currency_code%TYPE;  --Ajout : SFA  : artf07231300 
    
  BEGIN
  
    l_step := 'SEQUENCE';
    SELECT po_lines_interface_s.NEXTVAL
      INTO g_po_line_id_intf
      FROM dual;

    l_step := 'ORG_ID';
    SELECT org_id
      INTO vn_org_id
      FROM po_headers_all
     WHERE po_header_id = p_id_contrat;

	 --<!--Ajout SFA  : artf07231300
	 l_step := 'LEDGER_ID';  
	  BEGIN
	  SELECT SET_OF_BOOKS_ID
	   INTO vn_ledger_id
       FROM hr_operating_units 
	  WHERE ORGANIZATION_ID =vn_org_id;
	  EXCEPTION  WHEN NO_DATA_FOUND THEN
			vn_ledger_id := NULL;
	 END;     
	   
	 l_step := 'CURRENCY_CODE';  
	BEGIN
		SELECT currency_code 
			INTO   v_currency_code
			FROM   gl_ledgers 
			WHERE  ledger_id = vn_ledger_id;
	 EXCEPTION  WHEN NO_DATA_FOUND THEN
			    v_currency_code := NULL;
	 END;             	   
     -->--FIN AJOUT SFA  : artf07231300	 
     
   -- CDE 051219 recherche de l'UOM paramétré par défaut sur le type de ligne PRESTATION  
   l_step := 'UNITE_MESURE';
   BEGIN
     SELECT uom_code
     INTO   cst_uom_code
     FROM   mtl_units_of_measure muom
          , po_line_types plt
     WHERE muom.unit_of_measure = plt.unit_of_measure   
     AND   plt.line_type = cst_type_ligne;
	 EXCEPTION  WHEN NO_DATA_FOUND THEN
			    cst_uom_code := NULL;
	 END;        
	 
    l_step := 'INSERT';
    INSERT INTO po_lines_interface
      (interface_line_id,
       interface_header_id,
       line_num,
       shipment_num,
       line_type,
       ship_to_location_id,
       ship_to_organization_id, -- CDE 010610 ship_to_organization_code,
       --category, --RBE artf2139561
       category_id, --RBE artf2139561
       item_description,
       uom_code,
       quantity,
       unit_price)
    VALUES
      (g_po_line_id_intf,
       g_po_header_id_intf,
       1, -- CDE 060209 p_line_num, -- Pour gestion multi lieux livraison
       p_line_num, -- CDE 060209 1,
       cst_type_ligne,  
       p_ship_to,
       vn_org_id, -- CDE 010610 'DKA',
       --p_category, --RBE artf2139561
       p_category_id, --RBE artf2139561
       p_item_desc,
       cst_uom_code,    -- CDE 051219 v_currency_code,   
       p_qty,
       1);
       
  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'insere_ligne_commande =>' || l_step || '=>' || SQLERRM;
  END insere_ligne_commande;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : insere_imputation_commande
  --  Description   :
  --
  --  PARAMETRES    : p_num_commande numéro de la commande à vérifier
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE insere_imputation_commande(p_errbuf  OUT VARCHAR2,
                                       p_retcode IN OUT NUMBER,
                                       --                                  p_ship_id  PO_DISTRIBUTIONS_INTERFACE.SHIP_TO_LOCATION_ID%TYPE,
                                       p_contrat_imput_id   NUMBER,
                                       p_distribution_num   NUMBER,
                                       p_project_id         po_distributions_interface.project_id%TYPE,
                                       p_task_id            po_distributions_interface.task_id%TYPE, --RBE MigR12
                                       p_expenditure_type   dka_contrat_sstr_imputation.expenditure_type%TYPE,
                                       p_expenditure_org    hr_organization_units.NAME%TYPE,
                                       p_expenditure_org_id hr_organization_units.organization_id%TYPE,
                                       p_qty                NUMBER,
                                       p_ccid               NUMBER,
                                       p_accrual_ccid       OUT NUMBER,
                                       p_budget_ccid        OUT NUMBER,
                                       p_variance_ccid      OUT NUMBER,
                                       p_id_contrat         po_headers_all.po_header_id%TYPE) IS

    l_step    VARCHAR2(50);
    --l_task_id NUMBER; --RBE MigR12
    l_project VARCHAR2(50);
    l_task       VARCHAR2(150); --RBE MigR12
    vn_org_id po_headers_all.org_id%TYPE;
    
  BEGIN
  
    l_step := 'SEQUENCE';
    SELECT po_distributions_interface_s.NEXTVAL
      INTO g_po_distrib_id_intf
      FROM dual;

    SELECT task_number --RBE MigR12
      INTO l_task
      FROM pa_tasks
     WHERE task_id = p_task_id --task_number = 1  --RBE MigR12
     AND project_id = p_project_id;

    SELECT segment1
      INTO l_project
      FROM pa_projects_all
     WHERE project_id = p_project_id;

    l_step := 'ORG_ID';
    SELECT org_id
      INTO vn_org_id
      FROM po_headers_all
     WHERE po_header_id = p_id_contrat;

    l_step := 'INSERT';
    INSERT INTO po_distributions_interface
      (interface_header_id,
       interface_line_id,
       interface_distribution_id,
       distribution_num,
       project_id,
       task_id,
       project,
       task,
       expenditure_type,
       expenditure_organization,
       expenditure_organization_id,
       expenditure_item_date,
       quantity_ordered,
       org_id,
       --charge_account_id,
       --accrual_account_id,
       --budget_account_id,
       --variance_account_id,
       project_accounting_context,
       destination_context,
       --destination_type,
       destination_type_code, -- JWT 08/02/2018
       attribute3)
    VALUES
      (g_po_header_id_intf,
       g_po_line_id_intf,
       g_po_distrib_id_intf,
       p_distribution_num,
       p_project_id,
       p_task_id, --l_task_id, --RBE MigR12
       l_project,
       l_task, --'1', --RBE MigR12
       p_expenditure_type,
       p_expenditure_org,
       p_expenditure_org_id,
       trunc(SYSDATE),
       p_qty,
       vn_org_id,
       --p_ccid,
       --p_accrual_ccid,
       --p_budget_ccid,
       --301473,
       'Y',
       'EXPENSE',
       -- 'Charges',
       'EXPENSE', -- JWT 08/02/2018
       p_contrat_imput_id);

  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'insere_imputation_commande =>' || l_step || '=>' ||
                   SQLERRM;
  END insere_imputation_commande;

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
                                  resultout OUT NOCOPY VARCHAR2) IS

  vv_step                                   VARCHAR2(250);
  vn_num_commande                           dka_contrat_sstr.commande_id%TYPE;
  vn_num_contrat                            po_headers_all.po_header_id%TYPE;
  vn_vendor_site_id                         po_headers_all.vendor_site_id%TYPE;
  vn_ship_to_location_id                    po_headers_all.ship_to_location_id%TYPE;
  vn_bill_to_location_id                    po_headers_all.bill_to_location_id%TYPE;
  vn_agent_id                               po_headers_all.agent_id%TYPE;
  vv_attribute5                             po_headers_all.attribute5%TYPE;
  vv_attribute13                            po_headers_all.attribute13%TYPE;
  vv_attribute14                            po_headers_all.attribute14%TYPE;
  vv_attribute13_archi                        po_headers_archive_all.attribute13%TYPE;
  vv_attribute14_archi                        po_headers_archive_all.attribute14%TYPE;
  vv_desc_spe_contrat                       dka_contrat_sstr.description_specifique_contrat%TYPE;
  vn_ccid                                   NUMBER;
  vn_quantity                               NUMBER;
  vn_quantity_line                          NUMBER;
  vn_retcode                                NUMBER;
  vv_err_msg                                VARCHAR2(2000);
  vv_category_id                            mtl_categories_v.CATEGORY_ID%TYPE;
  vn_revision_num                           NUMBER;
  vn_revision_num_max                       NUMBER;
  vn_compteur                               NUMBER;
  vn_line_location_id_cree   NUMBER;

  vv_errbuf                                 VARCHAR2(250);
  e_ccid_not_found   EXCEPTION;
  vv_presta_unit po_headers_all.attribute14%TYPE;

  CURSOR cur_ligne_modif(pn_contrat_id   dka_contrat_sstr_imputation.po_header_id%TYPE) IS
    SELECT dcsi.po_header_id contrat_id,                      -- Contrat_id
           pda.po_header_id command_id,                       -- Commande_id
           dcsi.contrat_imputation_id,             -- Numero de ligne
           dcsi.project_id,                        -- Projet
           dcsi.location_id,                       -- Lieu de livraison
           dcsi.expenditure_type,                  -- Type de dépense
           pda.quantity_ordered,                   -- Quantity
           pda.po_line_id,                         -- Id de la ligne
           paa.organization_id,                    -- Expediture_organisation_id
           pha.vendor_id,                          -- Vendor_id
           pha.agent_id,                           -- Signataire_id
           pla.category_id,                        -- Nature_prestation
           pda.line_location_id,
           pha.attribute5,                          -- Category_concat_segs
           dcsi.task_id,
           pha.org_id
      FROM dka_contrat_sstr_imputation dcsi
           ,dka_contrat_sstr dcs
           ,po_distributions_all pda
           ,per_all_assignments_f paa
           ,po_headers_all pha
           ,po_lines_all pla
     WHERE 1 = 1
       AND dcs.commande_id = pda.po_header_id
       AND dcs.po_header_id = dcsi.po_header_id
       AND pda.attribute3 = dcsi.contrat_imputation_id
       AND pha.po_header_id = dcsi.po_header_id
       AND paa.person_id = pha.agent_id
       AND TRUNC(SYSDATE) BETWEEN TRUNC(paa.effective_start_date) AND NVL(paa.effective_end_date,SYSDATE) --RBE
       AND pla.po_header_id = pda.po_header_id
       AND dcsi.po_header_id = pn_contrat_id;

  CURSOR cur_ligne_cree(pn_contrat_id   dka_contrat_sstr_imputation.po_header_id%TYPE) IS
      SELECT dcsi.po_header_id contrat_id,         -- Contrat_id
             dcs.commande_id,                         -- Id de la commande
             dcsi.contrat_imputation_id,             -- Numero de ligne
             dcsi.project_id,                        -- Projet
             dcsi.location_id,                       -- Lieu de livraison
             dcsi.expenditure_type,                  -- Type de dépense
             paa.organization_id,                    -- Expediture_organisation_id
             pha.vendor_id,                          -- Vendor_id
             pha.agent_id,                           -- Signataire_id
             pla.category_id,                        -- Nature_prestation
             pha.attribute5,                         -- Category_concat_segs
             pla.po_line_id,                         -- Ligne de la commande
             pha.vendor_site_id,                      -- Vendor_site_id
             pha.org_id,                              -- ship_to_organization_id
             dcsi.task_id  --RBE MigR12
        FROM dka_contrat_sstr_imputation dcsi
             ,dka_contrat_sstr dcs
             ,per_all_assignments_f paa
             ,po_headers_all pha
             ,po_lines_all pla
       WHERE 1 = 1
         AND dcs.po_header_id = dcsi.po_header_id
         AND pha.po_header_id = dcsi.po_header_id
         AND paa.person_id = pha.agent_id
         AND TRUNC(SYSDATE) BETWEEN TRUNC(paa.effective_start_date) AND paa.effective_end_date --RBE
         AND pla.po_header_id = dcs.commande_id
         AND dcsi.po_header_id = pn_contrat_id
         AND NOT EXISTS (SELECT 1
                           FROM DKA_CONTRAT_SSTR_IMPUTATION dcsi2,
                                DKA_CONTRAT_SSTR dcs2,
                                PO_DISTRIBUTIONS_ALL pda2
                          WHERE 1 = 1
                            AND dcs2.commande_id = pda2.po_header_id
                            AND dcs2.po_header_id = dcsi2.po_header_id
                            AND dcsi2.contrat_imputation_id = pda2.attribute3
                            AND dcsi2.po_header_id = dcsi.po_header_id
                            AND dcsi2.contrat_imputation_id = dcsi.contrat_imputation_id
                         );
    vn_annulation      NUMBER;

    v_org_id           NUMBER;
  BEGIN
    vn_quantity_line := 0;

    vv_step := 'Recupération de numéro de contrat';
      vn_num_contrat := wf_engine.getitemattrnumber(itemtype => itemtype,
                                                     itemkey  => itemkey,
                                                     aname    => 'P_CONTRACT_ID');
    -- DGE20130037 - Modification du montant d'un contrat.
    BEGIN
        SELECT COUNT(1)
          INTO vn_annulation
          FROM DKA_CONTRAT_SSTR_ARCHI DCSA
         WHERE DCSA.PO_HEADER_ID = vn_num_contrat
           AND DCSA.REVISION_NUM = (SELECT decode(DCS.REVISION_NUM, 0, 0,  DCS.REVISION_NUM-1)
                                      FROM DKA_CONTRAT_SSTR DCS
                                     WHERE DCS.PO_HEADER_ID = DCSA.PO_HEADER_ID)
           AND DCSA.ANNULATION     = 'OUI';
    EXCEPTION
        WHEN OTHERS THEN
            vn_annulation := 0;
    END;

    vv_step := 'Recupération de numéro de commande';
    SELECT dcs.commande_id,org_id
      INTO vn_num_commande,v_org_id -- RBE artf2182182
      FROM DKA_CONTRAT_SSTR dcs
     WHERE dcs.po_header_id = vn_num_contrat;
    --RBE artf2182182
    MO_GLOBAL.SET_POLICY_CONTEXT('S',v_org_id);

    wf_engine.setitemattrnumber(itemtype => itemtype,
                                itemkey  => itemkey,
                                aname    => 'COMMANDE_ID',
                                avalue   => vn_num_commande);

    wf_engine.setitemattrnumber(itemtype => itemtype,
                                itemkey  => itemkey,
                                aname    => 'COMMANDE_ANN_ID',
                                avalue   => vn_num_commande);



    vv_step := 'Récupération des données modifier sur le contrat';
    SELECT ph.vendor_site_id,
           ph.ship_to_location_id,
           ph.bill_to_location_id,
           ph.agent_id,
           ph.attribute5,
           ph.attribute13,                         -- Modif EMA du 13/10/2011
           ph.attribute14,                           -- Modif BCO du 13/03/2013
           dcs.description_specifique_contrat,
           mcv.category_id
      INTO vn_vendor_site_id,
           vn_ship_to_location_id,
           vn_bill_to_location_id,
           vn_agent_id,
           vv_attribute5,
           vv_attribute13,                         -- Modif EMA du 13/10/2011
           vv_attribute14,                           -- Modif BCO du 13/03/2013
           vv_desc_spe_contrat,
           vv_category_id
      FROM po_headers_all ph,
           dka_contrat_sstr dcs,
           per_all_assignments_f pa,
           hr_organization_units hu,
           mtl_categories_v mcv
     WHERE ph.po_header_id = vn_num_contrat AND
           ph.po_header_id = dcs.po_header_id AND
           hu.organization_id = pa.organization_id AND
           -- FT N°22 selection sur l'affectation active pour la date du jour
           TRUNC(SYSDATE) BETWEEN TRUNC(pa.effective_start_date) AND NVL(pa.effective_end_date,SYSDATE) --RBE
           AND pa.person_id = dcs.signataire_contrat
           AND mcv.CATEGORY_CONCAT_SEGS = ph.attribute5;

    -- BCO INC000000462675 - Recherche Paiement direct unitaire dans la table d'archive et table de po_headers_all.
    BEGIN
        SELECT pha.attribute13,
               pha.attribute14
          INTO vv_attribute13_archi,
               vv_attribute14_archi
          FROM po_headers_archive_all pha,
               po_headers_all ph
         WHERE ph.po_header_id = pha.po_header_id
           AND pha.revision_num = ph.revision_num - 1
           AND ph.po_header_id = vn_num_contrat;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            vv_attribute13_archi := NULL;
            vv_attribute14_archi := NULL;
        WHEN OTHERS THEN
            vv_attribute13_archi := NULL;
            vv_attribute14_archi := NULL;
    END;

    -- Entête de la commande
    vv_step := 'Mise à jour entête de commande';
    -- Revision num pour la commande
    -- BCO INC000000462675 - Si le champ Prestation Unitaire ou Paiement Direct est modifié, aucun modif du numéro de version sur commande.
    IF vv_attribute13_archi != vv_attribute13 OR vv_attribute14_archi != vv_attribute14 THEN
        -- Revision num pour la commande
        BEGIN
             SELECT nvl(ph.revision_num,0)
               INTO vn_revision_num
               FROM PO_HEADERS_ALL ph
              WHERE ph.po_header_id = vn_num_commande
                AND ph.authorization_status = 'APPROVED';
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
             -- Récupération du dernier numéro de version archivé
             SELECT max(ph.revision_num)
               INTO vn_revision_num
               FROM PO_HEADERS_ARCHIVE_ALL ph
              WHERE ph.po_header_id = vn_num_commande;
        END;
    ELSE
        BEGIN
             SELECT nvl(ph.revision_num,0) + 1
               INTO vn_revision_num
               FROM PO_HEADERS_ALL ph
              WHERE ph.po_header_id = vn_num_commande
                AND ph.authorization_status = 'APPROVED';
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
             -- Récupération du dernier numéro de version archivé
             SELECT max(ph.revision_num) + 1
               INTO vn_revision_num
               FROM PO_HEADERS_ARCHIVE_ALL ph
              WHERE ph.po_header_id = vn_num_commande;
        END;
    END IF;

    -- Dernier révision num dans la table de contrat pour la commande
    SELECT max(dcsa.commande_version)
      INTO vn_revision_num_max
      FROM DKA_CONTRAT_SSTR_ARCHI dcsa
     WHERE dcsa.commande_id = vn_num_commande;

    UPDATE PO_HEADERS_ALL ph
     SET
      ph.vendor_site_id       = vn_vendor_site_id,
      ph.ship_to_location_id  = vn_ship_to_location_id,
      ph.bill_to_location_id  = vn_bill_to_location_id,
      ph.agent_id             = vn_agent_id,
      ph.last_update_date     = SYSDATE,
      ph.last_updated_by      = FND_GLOBAL.USER_ID,
      ph.last_update_login    = FND_GLOBAL.LOGIN_ID,
      ph.revision_num         = vn_revision_num,
      ph.authorization_status = 'REQUIRES REAPPROVAL',
      ph.approved_flag        = 'R',
      ph.approved_date        = NULL,
      ph.attribute13          = vv_attribute13,                  -- Modif EMA du 13/10/2011
      ph.attribute14          = vv_attribute14                   -- Modif BCO du 13/03/2013
     WHERE
      po_header_id = vn_num_commande;

    vv_step := 'Mise à jour du numéro de révision pour le contrat correspondant';
    UPDATE DKA_CONTRAT_SSTR dcs
       SET dcs.commande_version =  vn_revision_num
     WHERE dcs.commande_id = vn_num_commande
       AND dcs.po_header_id = vn_num_contrat;

    UPDATE DKA_CONTRAT_SSTR_ARCHI dcsa
       SET dcsa.commande_version =  vn_revision_num
     WHERE dcsa.commande_id = vn_num_commande
       AND dcsa.po_header_id = vn_num_contrat
       AND dcsa.revision_num = (SELECT revision_num
                                FROM DKA_CONTRAT_SSTR dcs
                                WHERE dcs.po_header_id = dcsa.po_header_id);


    /*********************
    * Modification ligne *
    **********************/
    FOR rec_ligne_modif IN cur_ligne_modif(vn_num_contrat)
    LOOP
      -- Calcul du ccid
      DKA_SPOCONTRAT_SSTR_PKG.get_ccid(pv_nature_prestation => rec_ligne_modif.attribute5,
                                       pv_expenditure_type => rec_ligne_modif.expenditure_type,
                                       pn_signataire_id => rec_ligne_modif.agent_id,
                                       pn_project_id => rec_ligne_modif.project_id,
                                       pn_task_id => rec_ligne_modif.task_id, --RBE MigR12
                                       pn_vendor_id => rec_ligne_modif.vendor_id,
                                       pn_org_id => rec_ligne_modif.org_id, --RBE MigR12
                                       pn_ccid => vn_ccid,
                                       pn_retcode => vn_retcode,
                                       pv_err_msg => vv_err_msg );

      IF vn_retcode = 2 THEN
        RAISE e_ccid_not_found;
      END IF;

      -- DPE20120104 - Recherche  s'il s'agit d'une prestation unitaire.
      BEGIN
        SELECT pha.attribute14
          INTO vv_presta_unit
          FROM po_headers_all pha
         WHERE pha.po_header_id = vn_num_contrat;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
            vv_presta_unit := NULL;
        WHEN OTHERS THEN
            vv_presta_unit := NULL;
      END;

      -- On compare les montants
      IF vn_annulation != 0 THEN
        vn_quantity := dka_spowfmaster_pkg.get_montant_presta_unit(rec_ligne_modif.contrat_imputation_id);
      ELSIF vv_presta_unit = 'OUI' THEN
        vn_quantity := dka_spowfmaster_pkg.get_montant_presta_unit(rec_ligne_modif.contrat_imputation_id);
      ELSE
        -- Nouvelle quantité
        vn_quantity := dka_spowfmaster_pkg.get_montant_imput(rec_ligne_modif.contrat_imputation_id);
      END IF;
      vn_quantity_line := vn_quantity_line + vn_quantity;

      -- PO_DISTRIBUTIONS_ALL
      vv_step := 'Mise à jour dans PO_DISTRIBUTIONS_ALL';
      UPDATE PO_DISTRIBUTIONS_ALL pda
       SET pda.quantity_ordered = vn_quantity,
           pda.expenditure_type = rec_ligne_modif.expenditure_type,
           pda.expenditure_organization_id = rec_ligne_modif.organization_id,
           pda.code_combination_id = vn_ccid,
           pda.variance_account_id = vn_ccid,
           pda.last_update_date = SYSDATE,
           pda.last_updated_by = FND_GLOBAL.USER_ID,
           pda.last_update_login = FND_GLOBAL.LOGIN_ID
       WHERE
           pda.po_header_id = vn_num_commande
       AND pda.attribute3 = rec_ligne_modif.contrat_imputation_id;

      -- PO_LINE_LOCATIONS_ALL
      vv_step := 'Mise à jour dans PO_LINE_LOCATIONS_ALL';
      UPDATE PO_LINE_LOCATIONS_ALL pll
       SET  pll.quantity = vn_quantity,
            pll.last_update_date = SYSDATE,
            pll.last_updated_by = FND_GLOBAL.USER_ID,
            pll.last_update_login = FND_GLOBAL.LOGIN_ID
       WHERE pll.po_header_id = vn_num_commande
         AND pll.ship_to_location_id = rec_ligne_modif.location_id
         AND pll.line_location_id = rec_ligne_modif.line_location_id;


    END LOOP;

    /*****************
    * Création ligne *
    ******************/
    FOR rec_ligne_cree IN cur_ligne_cree (vn_num_contrat)
    LOOP
        -- Quantité a ajouter
        -- DPE20120104 - Recherche  s'il s'agit d'une prestation unitaire.
          BEGIN
            SELECT pha.attribute14
              INTO vv_presta_unit
              FROM po_headers_all pha
             WHERE pha.po_header_id = vn_num_contrat;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
                vv_presta_unit := NULL;
            WHEN OTHERS THEN
                vv_presta_unit := NULL;
          END;

        -- On compare les montants
        IF vn_annulation != 0 THEN
            vn_quantity := dka_spowfmaster_pkg.get_montant_presta_unit(rec_ligne_cree.contrat_imputation_id);
        ELSIF vv_presta_unit = 'OUI' THEN
            vn_quantity := dka_spowfmaster_pkg.get_montant_presta_unit(rec_ligne_cree.contrat_imputation_id);
        ELSE
            vn_quantity := dka_spowfmaster_pkg.get_montant_imput(rec_ligne_cree.contrat_imputation_id);
        END IF;
        vn_quantity_line := vn_quantity_line + vn_quantity;
           -- Création de la ligne
           create_line_location(p_errbuf => vv_errbuf,
                                p_retcode => vn_retcode,
                                pn_line_id => rec_ligne_cree.po_line_id,
                                pn_header_id => rec_ligne_cree.commande_id,
                                pn_quantity => vn_quantity,
                                pn_ship_to_location_id => rec_ligne_cree.location_id,
                                pn_ship_to_organization_id => rec_ligne_cree.org_id,
                                pv_vendor_site_id => rec_ligne_cree.vendor_site_id,
                                pn_line_location_id => vn_line_location_id_cree);

           IF vn_retcode <> 2 THEN
             -- Création de la ligne dans po_distribution_all
             create_po_distribution(p_errbuf => vv_errbuf,
                                    p_retcode => vn_retcode,
                                    pn_line_id => rec_ligne_cree.po_line_id,
                                    pn_header_id => rec_ligne_cree.commande_id,
                                    pn_line_location_id => vn_line_location_id_cree,
                                    pv_nature_prestation => rec_ligne_cree.attribute5,
                                    pv_expenditure_type => rec_ligne_cree.expenditure_type,
                                    pn_agent_id => rec_ligne_cree.agent_id,
                                    pn_project_id => rec_ligne_cree.project_id,
                                    pn_vendor_id => rec_ligne_cree.vendor_id,
                                    pn_quantity => vn_quantity,
                                    pn_expenditure_org_id => rec_ligne_cree.organization_id,
                                    pn_contrat_imputation_id => rec_ligne_cree.contrat_imputation_id,
                                    pn_task_id   => rec_ligne_cree.task_id,
                                    pn_org_id   => rec_ligne_cree.org_id
                                    );
            END IF;

    END LOOP;

    -- PO_LINES_ALL
    vv_step := 'Mise à jour dans PO_LINES_ALL';
    UPDATE PO_LINES_ALL pla
     SET  pla.category_id = vv_category_id,
          pla.item_description = vv_desc_spe_contrat,
          pla.quantity = vn_quantity_line,
          pla.last_update_date = SYSDATE,
          pla.last_updated_by = FND_GLOBAL.USER_ID,
          pla.last_update_login = FND_GLOBAL.LOGIN_ID
     WHERE
      po_header_id = vn_num_commande;
  EXCEPTION
    WHEN e_ccid_not_found THEN
    print_log_message('CCID non retourné');

    WHEN OTHERS THEN
    print_log_message('modification_commande =>' || vv_step || '=>' ||
                   SQLERRM);

  END modification_commande;


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
                                 pn_line_location_id        OUT NUMBER)
  IS
    l_step              VARCHAR2(250);
    vn_shipment_num     NUMBER;
    vv_unit_of_measure  VARCHAR2(30);
    vv_match_option     VARCHAR2(10);

  BEGIN
    l_step := 'CREATE LINE LOCATION - BEGIN';
    p_retcode := 0;

    -- Récupération du nouveau shipment_num
    l_step := 'Determination shipment_num';
    SELECT max(shipment_num) + 1
      INTO vn_shipment_num
      FROM po_line_locations_all
     WHERE po_line_id = pn_line_id;

    -- Récupération de l'unité de mesure
    l_step := 'Determination unit_of_measure';
    SELECT unit_of_measure
      INTO vv_unit_of_measure
      FROM po_line_types  -- CDE 051219 mtl_units_of_measure_vl
     WHERE line_type = cst_type_ligne; -- CDE 051219 récupération valeur par défaut du type de ligne -- uom_code = 'EUR';

    -- Récupération de match_option
    l_step := 'Determination match_option';
    SELECT match_option
      INTO vv_match_option
      FROM po_vendor_sites
     WHERE vendor_site_id = pv_vendor_site_id;

    -- Calcul du line_location_id
    SELECT po_line_locations_s.nextval
      INTO pn_line_location_id
      FROM dual;

    -- Insertion dans po_line_locations
    l_step := 'INSERT po_line_locations';
    INSERT INTO po_line_locations_all
      (line_location_id,
       last_update_date,
       last_updated_by,
       po_header_id,
       creation_date,
       created_by,
       last_update_login,
       po_line_id,
       quantity,
       quantity_received,
       quantity_accepted,
       quantity_rejected,
       quantity_billed,
       quantity_cancelled,
       ship_to_location_id,
       approved_flag,
       closed_code,
       price_override,
       price_discount,
       taxable_flag,
       shipment_type,
       shipment_num,
       inspection_required_flag,
       receipt_required_flag,
       days_early_receipt_allowed,
       days_late_receipt_allowed,
       enforce_ship_to_location_code,
       ship_to_organization_id,
       invoice_close_tolerance,
       receive_close_tolerance,
       accrue_on_receipt_flag,
       allow_substitute_receipts_flag,
       receiving_routing_id,
       qty_rcv_tolerance,
       qty_rcv_exception_code,
       receipt_days_exception_code,
       unit_meas_lookup_code,
       match_option,
       secondary_quantity_received,
       quantity_shipped,
       OUTSOURCED_ASSEMBLY, --RBE artf2182182
       org_id, -- RBE artf2182182
       MATCHING_BASIS) --RBE artf2182182
      (SELECT pn_line_location_id, --line_location_id
              SYSDATE, --last_update_date
              fnd_global.user_id, --last_updated_by
              pn_header_id, --po_header_id
              SYSDATE, --creation_date
              fnd_global.user_id, --created_by
              fnd_global.login_id, --last_update_login
              pn_line_id, --po_line_id
              pn_quantity, --quantity
              0, --quantity_received
              0, --quantity_accepted
              0, --quantity_rejected
              0, --quantity_billed
              0, --quantity_cancelled
              pn_ship_to_location_id, --ship_to_location_id
              'N', --approved_flag
              'OPEN', --closed_code
              1, --price_override
              0, --price_discount
              'N', --taxable_flag
              'STANDARD', --shipment_type
              vn_shipment_num, --shipment_num
              params.inspection_required_flag, --inspection_required_flag
              params.receiving_flag, --receipt_required_flag,
              rcv_params.days_early_receipt_allowed, --days_early_receipt_allowed
              rcv_params.days_late_receipt_allowed, --days_late_receipt_allowed
              rcv_params.enforce_ship_to_location_code, --enforce_ship_to_location_code
              pn_ship_to_organization_id, --ship_to_organization_id
              params.invoice_close_tolerance, --invoice_close_tolerance
              params.receive_close_tolerance, --receive_close_tolerance
              decode(nvl(params.receiving_flag, 'N'),'N','N',
                     decode(params.expense_accrual_code,'PERIOD END','N','Y'),
                        'Y','N'), --accrue_on_receipt_flag
              rcv_params.allow_substitute_receipts_flag, --allow_substitute_receipts_flag
              rcv_params.receiving_routing_id, --receiving_routing_id
              rcv_params.qty_rcv_tolerance, --qty_rcv_tolerance
              rcv_params.qty_rcv_exception_code, --qty_rcv_exception_code
              rcv_params.receipt_days_exception_code, --receipt_days_exception_code
              vv_unit_of_measure, --unit_meas_lookup_code
              vv_match_option, --match_option
              0, --secondary_quantity_received
              0, -- quantity_shipped
              2, --OUTSOURCED_ASSEMBLY --RBE artf2182182
              params.org_id, --org_id --RBE artf2182182
              'QUANTITY' --MATCHING_BASIS --RBE artf2182182
         FROM po_system_parameters params, rcv_parameters rcv_params
        WHERE rcv_params.organization_id = params.org_id);

  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'create_line_location =>' || l_step || '=>' || SQLERRM;
  END create_line_location;


  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : create_po_distribution
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
                                   pn_org_id             IN NUMBER)
  IS
    l_step                         VARCHAR2(250);
    vn_distribution_num            NUMBER;
    vn_destination_org_id          NUMBER;
    vn_ccid                        NUMBER;
    vn_retcode                     NUMBER;
    vv_err_msg                     VARCHAR2(2000);
    --vn_task_id                     NUMBER;  --RBE MigR12
    vv_segment1                    VARCHAR2(30);
    vv_segment2                    VARCHAR2(30);
    vv_acc_segment3                VARCHAR2(30);
    vv_acc_segment4                VARCHAR2(30);
    vv_acc_segment5                VARCHAR2(30);
    vv_acc_segment6                VARCHAR2(30);
    vv_acc_segment7                VARCHAR2(30);
    vv_acc_segment8                VARCHAR2(30);
    vn_accrual_code_combination_id NUMBER;
    vv_accrue_on_receipt_flag      VARCHAR2(1);
    e_rejet_cle                    EXCEPTION;
    e_rejet_ccid                   EXCEPTION;

  BEGIN
    l_step := 'CREATE PO DISTRIBUTION - BEGIN';
    p_retcode := 0;

    -- Calcul de la CCID
    dka_spocontrat_sstr_pkg.get_ccid(pv_nature_prestation => pv_nature_prestation,
                                     pv_expenditure_type  => pv_expenditure_type,
                                     pn_signataire_id     => pn_agent_id,
                                     pn_project_id        => pn_project_id,
                                     pn_task_id           => pn_task_id, --RBE MigR12
                                     pn_vendor_id         => pn_vendor_id,
                                     pn_org_id            => pn_org_id, --RBE MigR12
                                     pn_ccid              => vn_ccid,
                                     pn_retcode           => vn_retcode,
                                     pv_err_msg           => vv_err_msg);

    IF vn_retcode = 2 THEN
      RAISE e_rejet_ccid;
    END IF;


    -- Détermination de accrual_account_id
    l_step := 'Determination accrual_account_id';
    SELECT segment1, segment2
      INTO vv_segment1, vv_segment2
      FROM gl_code_combinations
     WHERE code_combination_id = vn_ccid;

    SELECT gcc.segment3,
           gcc.segment4,
           gcc.segment5,
           gcc.segment6,
           gcc.segment7,
           gcc.segment8
      INTO vv_acc_segment3,
           vv_acc_segment4,
           vv_acc_segment5,
           vv_acc_segment6,
           vv_acc_segment7,
           vv_acc_segment8
      FROM gl_code_combinations gcc, po_system_parameters psp
     WHERE gcc.code_combination_id = psp.accrued_code_combination_id;

    Dka_Tools_Pkg.get_code_combination_id(vv_segment1,
                                          vv_segment2,
                                          vv_acc_segment3,
                                          vv_acc_segment4,
                                          vv_acc_segment5,
                                          vv_acc_segment6,
                                          vv_acc_segment7,
                                          vv_acc_segment8,
                                          '0',
                                          '0',
                                          NULL, --RBE MigR12
                                          NULL, --RBE MigR12
                                          vn_accrual_code_combination_id,
                                          vv_err_msg,
                                          vn_retcode,
                                          'Y');

    IF vn_accrual_code_combination_id IS NULL THEN
      RAISE e_rejet_cle;
    END IF;

    -- Détermination du distribution_num
    l_step := 'Determintation du distribution_num';
    SELECT nvl(max(distribution_num), 1)
      INTO vn_distribution_num
      FROM po_distributions_all
     WHERE line_location_id = pn_line_location_id;

    -- Récupération du destination_organization_id
    l_step := 'Determintation du destination_organization_id';
    SELECT ship_to_organization_id, accrue_on_receipt_flag
      INTO vn_destination_org_id, vv_accrue_on_receipt_flag
      FROM po_line_locations_all
     WHERE line_location_id = pn_line_location_id;

     --RBE MigR12
/*    -- Détermination du task_id
    l_step := 'Determintation du task_id';
    SELECT task_id
      INTO vn_task_id
      FROM pa_tasks
     WHERE project_id = pn_project_id; --RBE MigR12
     */

    -- Insertion dans po_distributions
    l_step := 'INSERT po_distributions';
    INSERT INTO po_distributions_all
      (po_distribution_id,
       last_update_date,
       last_updated_by,
       po_header_id,
       creation_date,
       created_by,
       last_update_login,
       po_line_id,
       line_location_id,
       set_of_books_id,
       code_combination_id,
       quantity_ordered,
       quantity_delivered,
       quantity_billed,
       quantity_cancelled,
       encumbered_flag,
       prevent_encumbrance_flag,
       distribution_num,
       destination_type_code,
       destination_organization_id,
       budget_account_id,
       accrual_account_id,
       variance_account_id,
       project_id,
       task_id,
       expenditure_type,
       project_accounting_context,
       destination_context,
       expenditure_organization_id,
       expenditure_item_date,
       accrue_on_receipt_flag,
       tax_recovery_override_flag,
       attribute3,
       org_id --RBE artf2182182
       )
    VALUES
      (po_distributions_s.NEXTVAL, --po_distribution_id
       SYSDATE, --last_update_date
       fnd_global.user_id, --last_updated_by
       pn_header_id, --po_header_id
       SYSDATE, --creation_date
       fnd_global.user_id, --created_by
       fnd_global.login_id, --last_update_login
       pn_line_id, --po_line_id
       pn_line_location_id, --line_location_id
       fnd_profile.VALUE('GL_SET_OF_BKS_ID'), --set_of_books_id
       vn_ccid, --code_combination_id
       pn_quantity, --quantity_ordered
       0, --quantity_delivered
       0, --quantity_billed
       0, --quantity_cancelled
       'N', --encumbered_flag
       'N', --prevent_encumbered_flag
       vn_distribution_num, --distribution_num
       'EXPENSE', --destination_type_code
       vn_destination_org_id, --destination_organization_id
       NULL, --budget_account_id
       vn_accrual_code_combination_id, --accrual_account_id
       vn_ccid, --variance_account_id
       pn_project_id, --project_id
       pn_task_id, --task_id --RBE MigR12
       pv_expenditure_type, --expenditure_type
       'Y', --project_accounting_context
       'EXPENSE', --destination_context
       pn_expenditure_org_id, --expenditure_organization_id
       TRUNC(SYSDATE), --expenditure_item_date
       vv_accrue_on_receipt_flag, --accrue_on_receipt_flag
       'N', --tax_recovery_override_flag
       pn_contrat_imputation_id, --attribute3
       pn_org_id --RBE artf2182182
       );

  EXCEPTION
    WHEN e_rejet_ccid THEN
      p_retcode := 2;
      p_errbuf  := 'create_po_distribution - calcul ccid =>' || vv_err_msg;
    WHEN e_rejet_cle THEN
      p_retcode := 2;
      p_errbuf  := 'create_po_distribution - calcul accrual_ccid =>' || vv_err_msg;
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'create_po_distribution =>' || l_step || '=>' || SQLERRM;
  END create_po_distribution;


  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : insere_historisation_commande
  --  Description   : Insertion des informations de la commande de sous-traitance en fonction des informations
  --                  d'historisation du contrat de sous-traitance.
  --
  --  PARAMETRES    : p_id_contrat : Identifiant du contrat de sous-traitance
  --
  --
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE insere_historisation_commande(p_errbuf  OUT VARCHAR2,
                                          p_retcode IN OUT NUMBER,
                                          p_id_contrat IN NUMBER,
                                          p_num_commande IN VARCHAR2)
                                          IS
    l_step              VARCHAR2(250);
    vv_action_code        PO_ACTION_HISTORY.ACTION_CODE%TYPE;
    vd_action_date        PO_ACTION_HISTORY.ACTION_DATE%TYPE;
    vn_employee_id        PO_ACTION_HISTORY.EMPLOYEE_ID%TYPE;
    vn_sequence_num        NUMBER;
    vn_revision_num PO_HEADERS_ALL.REVISION_NUM%TYPE;
    vn_id_commande PO_HEADERS_ALL.Po_Header_Id%TYPE;
  BEGIN
      -- -------------------------------------------------------------------------------------------- --
      --  BCO DPE20130002 - Avenant au devis DPE20120104_OA Achats Divers SSTR                        --
      --  Ajout de l'historique d'approbation de la version en cours du contrat sur la commande SSTR  --
      -- -------------------------------------------------------------------------------------------- --
        l_step := 'Recherche des informations date/action/acteur au niveau du contrat de sous-traitance.';
        SELECT    PAH.ACTION_CODE, PAH.ACTION_DATE, PAH.EMPLOYEE_ID
        INTO    vv_action_code, vd_action_date, vn_employee_id
        FROM    PO_ACTION_HISTORY PAH
        WHERE    PAH.OBJECT_ID    =    p_id_contrat
        AND     PAH.SEQUENCE_NUM = (SELECT MAX(PAH2.SEQUENCE_NUM) FROM PO_ACTION_HISTORY PAH2 WHERE PAH2.OBJECT_ID  =  p_id_contrat AND PAH2.OBJECT_SUB_TYPE_CODE = 'CONTRACT')
        AND     PAH.OBJECT_SUB_TYPE_CODE = 'CONTRACT';

        l_step := 'Recherche de l''identifiant de la commande de sous-traitance.';
        SELECT PHA_COMMANDE.Po_Header_Id
        INTO vn_id_commande
        FROM PO_HEADERS_ALL PHA_COMMANDE
        WHERE PHA_COMMANDE.SEGMENT1 = p_num_commande;

        l_step := 'Recherche de la version au niveau de la commande de sous-traitance.';
        SELECT     PHA.REVISION_NUM
        INTO    vn_revision_num
        FROM     PO_HEADERS_ALL PHA
        WHERE     PHA.PO_HEADER_ID = vn_id_commande;

        l_step := 'Recherche du numéro d''ordre au niveau de la commande de sous-traitance.';
        SELECT     decode(MAX(SEQUENCE_NUM), NULL, 0,MAX(SEQUENCE_NUM) + 1)
        INTO    vn_sequence_num
        FROM     PO_ACTION_HISTORY PAH
        WHERE     PAH.OBJECT_ID = vn_id_commande;

        l_step := 'Insertion des données d''historisation.';
        INSERT INTO PO_ACTION_HISTORY(OBJECT_ID,
                                      OBJECT_TYPE_CODE,
                                      OBJECT_SUB_TYPE_CODE,
                                      SEQUENCE_NUM,
                                      LAST_UPDATE_DATE,
                                      LAST_UPDATED_BY,
                                      CREATION_DATE,
                                      CREATED_BY,
                                      ACTION_CODE,
                                      ACTION_DATE,
                                      EMPLOYEE_ID,
                                      APPROVAL_PATH_ID,
                                      NOTE,
                                      OBJECT_REVISION_NUM,
                                      OFFLINE_CODE,
                                      LAST_UPDATE_LOGIN,
                                      REQUEST_ID,
                                      PROGRAM_APPLICATION_ID,
                                      PROGRAM_ID,
                                      PROGRAM_UPDATE_DATE,
                                      PROGRAM_DATE)
                                      VALUES
                                      (vn_id_commande, -- OBJECT_ID
                                      'PO',                    -- OBJECT_TYPE_CODE
                                      'STANDARD',            -- OBJECT_SUB_TYPE_CODE
                                      vn_sequence_num,        -- SEQUENCE_NUM
                                      SYSDATE,                -- LAST_UPDATE_DATE
                                      -1,                    -- LAST_UPDATED_BY
                                      SYSDATE,                -- CREATION_DATE
                                      -1,                    -- CREATED_BY
                                      vv_action_code,        -- ACTION_CODE
                                      vd_action_date,        -- ACTION_DATE
                                      vn_employee_id,        -- EMPLOYEE_ID
                                      0,                    -- APPROVAL_PATH_ID
                                      NULL,                    -- NOTE
                                      vn_revision_num,        -- OBJECT_REVISION_NUM
                                      NULL,                    -- OFFLINE_CODE
                                      -1,                    -- LAST_UPDATE_LOGIN
                                      0,                    -- REQUEST_ID
                                      0,                    -- PROGRAM_APPLICATION_ID
                                      0,                    -- PROGRAM_ID
                                      NULL,                    -- PROGRAM_UPDATE_DATE
                                      NULL);                -- PROGRAM_DATE
  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'insere_historisation_commande =>' || l_step || '=>' || SQLERRM;
  END;


  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PUBLIQUES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
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
                 p_group_id   OUT NUMBER) IS

    CURSOR cur_ligne_imputation IS
      SELECT dc.*,hu.name organization_name,ppa.carrying_out_organization_id organization_id--RBE MigR12
        FROM DKA_CONTRAT_SSTR_IMPUTATION DC, PA_PROJECTS_ALL PPA,hr_organization_units hu
       WHERE dc.po_header_id = p_id_contrat
       AND   DC.PROJECT_ID   = PPA.PROJECT_ID
       AND   hu.organization_id = ppa.carrying_out_organization_id
       ;

    l_step                    VARCHAR2(50);
    l_num_commande            VARCHAR2(50);
    l_vendor_id               NUMBER;
    l_vendor_site_id          NUMBER;
    l_signataire              NUMBER;
    l_category                VARCHAR2(150);
    l_paiement_direct         po_headers_all.attribute13%TYPE;
    l_prestation_unit          po_headers_all.attribute14%TYPE;
    l_comments                po_headers_all.comments%TYPE;
    l_blanket_total_amount    po_headers_all.blanket_total_amount%TYPE;
    l_expenditure_type        dka_contrat_sstr_imputation.expenditure_type%TYPE;
    l_ship_to_location_id     po_headers_all.ship_to_location_id%TYPE;
    l_bill_to_location_id     po_headers_all.bill_to_location_id%TYPE;
    --l_organization_signataire hr_organization_units.NAME%TYPE;  --RBE MigR12
    l_total                   NUMBER;
    l_count                   NUMBER;
    l_reste_montant           NUMBER;
    l_total_ligne             NUMBER;
    l_distribution_num        NUMBER;
    --l_org_id_signataire       NUMBER;  --RBE MigR12
    l_ccid                    NUMBER;
    l_accrual_ccid            NUMBER;
    l_budget_ccid             NUMBER;
    l_variance_ccid           NUMBER;
    l_org_id_contrat          NUMBER;
    l_request_id              NUMBER;
    l_return                  BOOLEAN;
    l_phase                   VARCHAR2(30);
    l_status                  VARCHAR2(30);
    l_dev_phase               VARCHAR2(30);
    l_dev_status              VARCHAR2(30);
    l_message                 VARCHAR2(1000);
    l_ship_num                NUMBER;
    l_category_id             NUMBER; --RBE artf2139561
    l_return_status VARCHAR2(1) := FND_API.G_RET_STS_SUCCESS; -- RBE
  BEGIN
    p_retcode := 0;

    l_step := 'BEGIN';

    g_debug := p_debug;

    l_step := 'VERIF CONTRAT';
    IF NOT verifie_approbation_contrat(p_id_contrat)
    THEN
      p_retcode := 2;
      p_errbuf  := dka_tools_pkg.get_message('DKA', 'DKA_IPOGENC_E001');
      RETURN;
    END IF;

    l_step         := 'RECUP COMMANDE';
    l_num_commande := recupere_numero_de_commande(p_id_contrat);

    l_step := 'VERIF EXIST';
    IF verifie_existence_commande(l_num_commande)
    THEN
      p_retcode := 2;
      p_errbuf  := dka_tools_pkg.get_message('DKA',
                                             'DKA_IPOGENC_E002',
                                             'NUM_ORDER',
                                             l_num_commande);
      RETURN;
    END IF;

    l_step := 'SELECT CONTRAT';
    SELECT ph.vendor_id,
           ph.vendor_site_id,
           dc.signataire_contrat,
           ph.attribute5,
           ph.attribute13,               -- Modif EMA du 13/10/2011
           ph.attribute14,
           dc.description_specifique_contrat,
           ph.blanket_total_amount,
           -- CDE 11/01/2010 dc.expenditure_type,
           ph.ship_to_location_id,
          -- hu.NAME,
         --  hu.organization_id,
           ph.bill_to_location_id
      INTO l_vendor_id, l_vendor_site_id, l_signataire, l_category, l_paiement_direct, l_prestation_unit, l_comments, l_blanket_total_amount,
           -- CDE 11/01/2010 l_expenditure_type,
           l_ship_to_location_id, /*l_organization_signataire, l_org_id_signataire,*/ l_bill_to_location_id
      -- CDE 01/06/2010 FROM po_headers_all ph, dka_contrat_sstr dc, per_all_assignments_f pa, hr_organization_units hu
      FROM po_headers_all ph, dka_contrat_sstr dc --, per_all_people_f pa, hr_organization_units hu, PER_ASSIGNMENTS_F PAV
     WHERE ph.po_header_id = p_id_contrat AND
           ph.po_header_id = dc.po_header_id --AND
           -- CDE 01/06/2010 hu.organization_id = pa.organization_id AND
           --hu.name = pa.attribute1 AND --RBE MigR12
           --pa.PERSON_ID = PAV.PERSON_ID  --RBE MigR12
           --AND pav.organization_id = hu.organization_id --RBE MigR12
           --AND SYSDATE BETWEEN PAV.EFFECTIVE_START_DATE AND PAV.EFFECTIVE_END_DATE --RBE MigR12
           -- FT N°22 selection sur l'affectation active pour la date du jour
           --AND SYSDATE BETWEEN pa.effective_start_date AND pa.effective_end_date AND
           --pa.person_id = dc.signataire_contrat
           ;

    -- Si le commentaire est vide, mettre la nature de prestation.
    IF (l_comments IS NULL)
    THEN
      l_comments := l_category;
    END IF;

    --RBE artf2139561 : recherche ID
    l_step := 'SELECT CATEGORY_ID';
    SELECT category_id
    INTO l_category_id
    FROM mtl_categories_kfv
    WHERE concatenated_segments = l_category AND structure_id = 201;

    l_step := 'INSERE ENTETE';
    print_log_message('INSERE ENTETE');
    insere_entete_commande(p_errbuf,
                           p_retcode,
                           l_num_commande,
                           l_vendor_id,
                           l_vendor_site_id,
                           l_signataire,
                           l_ship_to_location_id,
                           l_bill_to_location_id,
                           l_paiement_direct,        -- Modif EMA du 13/10/2011
                           l_prestation_unit,        -- Modif BCO du 13/03/2013
                           p_id_contrat);     

    IF (p_retcode != 0)
    THEN
      RETURN;
    END IF;

/*    l_step := 'INSERE LIGNE';
    insere_ligne_commande(p_errbuf,
                          p_retcode,
                          l_ship_to_location_id,
                          l_category,
                          l_comments,
                          l_blanket_total_amount);
    IF (p_retcode != 0)
    THEN
      RETURN;
    END IF;*/

    SELECT SUM(unite_oeuvre)
      INTO l_total
      FROM dka_contrat_sstr_imputation
     WHERE po_header_id = p_id_contrat;

    SELECT COUNT(*)
      INTO l_count
      FROM dka_contrat_sstr_imputation
     WHERE po_header_id = p_id_contrat;

    l_step             := 'BOUCLE IMPUTATION';
    l_distribution_num := 0;
    l_ship_num         := 0;
    l_reste_montant    := l_blanket_total_amount;
    FOR rec_imputation IN cur_ligne_imputation LOOP
      BEGIN
        l_total_ligne      := round((rec_imputation.unite_oeuvre *
                                    l_blanket_total_amount) / l_total,
                                    2);
        l_distribution_num := 1;
        l_ship_num         := l_ship_num + 1;

        IF l_ship_num = l_count
        THEN
          l_total_ligne := l_reste_montant;
        ELSE
          l_reste_montant := l_reste_montant - l_total_ligne;
        END IF;
        print_log_message('TOTAL LIGNE=' || l_total_ligne);


        l_step := 'INSERE LIGNE';
        insere_ligne_commande(p_errbuf,
                              p_retcode,
                              rec_imputation.location_id,
                              --l_category,  --RBE artf2139561
                              l_category_id, --RBE artf2139561
                              l_comments,
                              l_total_ligne,
                              l_ship_num,
                              p_id_contrat);
        IF (p_retcode != 0)
        THEN
           RETURN;
        END IF;


        -- FT 22 NBO : Suppression de l'appel du workflow de création de compte
        /*l_step := 'GENERE COMMANDE';
        genere_compte_commande(p_errbuf,
                               p_retcode,
                               l_category,
                               l_expenditure_type,
                               l_org_id_signataire,
                               l_signataire,
                               rec_imputation.project_id,
                               l_vendor_id,
                               l_ccid,
                               l_accrual_ccid,
                               l_budget_ccid,
                               l_variance_ccid,
                               rec_imputation.location_id,
                               g_org_id);
        IF p_retcode != 0
        THEN
          RETURN;
        END IF;*/

        l_step := 'INSERE IMPUTATION';
        insere_imputation_commande(p_errbuf,
                                   p_retcode,
                                   rec_imputation.contrat_imputation_id,
                                   l_distribution_num,
                                   rec_imputation.project_id,
                                   rec_imputation.task_id, -- RBE MigR12
                                   rec_imputation.expenditure_type, -- CDE 11/01/2010 l_expenditure_type
                                   --l_organization_signataire,
                                   rec_imputation.organization_name, --RBE MigR12
                                   --l_org_id_signataire,
                                   rec_imputation.organization_id, --RBE MigR12
                                   l_total_ligne,
                                   l_ccid,
                                   l_accrual_ccid,
                                   l_budget_ccid,
                                   l_variance_ccid,
                                   p_id_contrat);
        IF p_retcode != 0
        THEN
          RETURN;
        END IF;

      END;
    END LOOP;

    IF p_retcode = 0
    THEN
      print_log_message('COMMIT');

      COMMIT;

      p_group_id := g_po_header_id_intf;
      --RBE artf2169042
      /*
      po_docs_interface_sv5.process_po_headers_interface(p_group_id,
                                                         NULL,
                                                         'STANDARD',
                                                         NULL,
                                                         'N',
                                                         'N',
                                                         NULL,
                                                         'INCOMPLETE',
                                                         1,
                                                         'PENDING',
                                                         NULL,
                                                         NULL,
                                                         NULL);
      */
    
    BEGIN
    
      SELECT org_id 
        INTO l_org_id_contrat 
        FROM po_headers_all 
       WHERE po_header_id = p_id_contrat;
    
    EXCEPTION
      WHEN OTHERS THEN
        l_org_id_contrat := NULL;
    END;
    
      PO_PDOI_GRP.start_process
      ( p_api_version           => 1.0,
        p_init_msg_list         => FND_API.G_TRUE,
        p_validation_level      => FND_API.G_VALID_LEVEL_FULL,
        p_commit                => FND_API.G_TRUE,
        x_return_status         => l_return_status,
        p_gather_intf_tbl_stat  => FND_API.G_FALSE,
        p_calling_module        => PO_PDOI_CONSTANTS.g_CALL_MOD_UNKNOWN,
        p_selected_batch_id     => p_group_id,
        p_batch_size            => PO_PDOI_CONSTANTS.g_DEF_BATCH_SIZE,
        p_buyer_id              => NULL,
        p_document_type         => 'STANDARD',
        p_document_subtype      => NULL,
        p_create_items          => NULL,
        p_create_sourcing_rules_flag => NULL,
        p_rel_gen_method             => NULL,
        p_sourcing_level        => NULL,
        p_sourcing_inv_org_id   => NULL,
        p_approved_status       => 'INCOMPLETE',
        p_process_code          => 'PENDING',
        p_interface_header_id   => NULL,
        p_org_id                => l_org_id_contrat,
        p_ga_flag               => NULL,
        p_group_lines           => 'Y'
      );
      COMMIT;

      -- FT 22 NBO Contrôle que la commande existe bien dans l'open-interface.
      SELECT COUNT(*)
        INTO l_count
        FROM po_headers_ALL --RBE
       WHERE segment1 = l_num_commande;

      IF l_count <> 1
      THEN
        p_retcode := 2;
        p_errbuf  := dka_tools_pkg.get_message('DKA', 'DKA_IPOGENC_E003');
      END IF;

      insere_historisation_commande(p_errbuf,
                                    p_retcode,
                                    p_id_contrat,
                                    l_num_commande);

      IF (p_retcode != 0)
        THEN
           RETURN;
        END IF;
        commit;
      /*l_request_id := fnd_request.submit_request('PO',
                                                   'POXPOPDOI',
                                                   NULL,
                                                   NULL,
                                                   FALSE,
                                                   NULL,
                                                   'STANDARD',
                                                   NULL,
                                                   'N',
                                                   NULL,
                                                   'INCOMPLETE',
                                                   NULL,
                                                   g_po_header_id_intf,
                                                   NULL,
                                                   NULL);
        --
        -- Validation for GTS
        --
        COMMIT;

        IF l_request_id = 0
        THEN
          print_log_message('MAIN : EXCEPTION : Exécution SQL*Loader en erreur');
          p_retcode := 2;
          p_errbuf  := 'MAIN : EXCEPTION : Exécution SQL*Loader en erreur';
        ELSIF (l_request_id IS NOT NULL)
        THEN
          LOOP
            l_return := fnd_concurrent.wait_for_request(l_request_id,
                                                        10,
                                                        300,
                                                        l_phase,
                                                        l_status,
                                                        l_dev_phase,
                                                        l_dev_status,
                                                        l_message);

            l_return := fnd_concurrent.get_request_status(l_request_id,
                                                          NULL,
                                                          NULL,
                                                          l_phase,
                                                          l_status,
                                                          l_dev_phase,
                                                          l_dev_status,
                                                          l_message);

            IF (nvl(l_dev_phase, 'ERROR') = 'COMPLETE')
            THEN
              EXIT;
            END IF;
          END LOOP;

          IF (nvl(l_dev_status, 'ERROR') NOT IN ('NORMAL', 'WARNING'))
          THEN
            print_log_message('MAIN : EXCEPTION : Fin du SQL*Loader en erreur');
            p_retcode := 2;
            p_errbuf  := 'MAIN : EXCEPTION : Fin du SQL*Loader en erreur';
          ELSE
            l_step := 'RECUP NUM COMMANDE';
            BEGIN
              SELECT po_header_id
                INTO p_id_commande
                FROM po_headers_all
               WHERE request_id = l_request_id;
            EXCEPTION
              WHEN no_data_found THEN
                p_id_commande := -1;
            END;
          END IF;
      END IF;*/
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      print_log_message(p_errbuf);
      p_retcode := 2;
      p_errbuf  := 'MAIN =>' || l_step || '=>' || SQLERRM;
  END main;

END dka_ipogencom_pkg; -- Spécification du package
/
SHOW ERROR;
EXIT
