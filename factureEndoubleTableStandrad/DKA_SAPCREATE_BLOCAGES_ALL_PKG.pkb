create or replace package body DKA_SPOFRAIS_PORT_PKG is
---PROD------------------------------------------------------------------------------------------------------------
-- CAPGEMINI
-- PROJET                : DALKIA Oracle Applications
-- NOM                   : DKA_SPOFRAIS_PORT_PKG.pkb
-- DESCRIPTION           : DKA_SPOFRAIS_PORT_PKG package body :
---
--- AUTEUR               : Eric BLONDEEL
--- DATE DE CREATION     : 06/03/2006
--- DOC. ASSOCIEE        :
-- COMMENTAIRE           : A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date        Qui     Description
--- ----        ---     -----------
--- 06/03/2006  EB      Création du package
--- 18/04/2006  TB      Inserer_ligne : correction problème de réception
--- 16/11/2007  ADR     ETANCHEITE DALKIA 2007
--- 05/05/2009  CDE     Evolution Fermeture commandes - Suppression outdebug message dans Calculer_montant et Annuler_ligne
--- 23/06/2010  TB      Correction des MAJ des données des lignes insérées
--- 24/04/2013  JJA     DPE20130031 : Modification Supprimer_ligne : ajout de l'annulation de la ligne de DA
--- 03/02/2017  MEG     Correction artf2092860 : DEFECT 500 - GESTION DES FRAIS DE PORT
--- 14/03/2017  EFL     artf2120909 : Modification des insertions 
--- 04/04/2017  MEG     artf2131632 : Dysfonctionnement de la gestion des frais de port
--- 08/11/2018  RBE     INC0228864  : Incident sur les frais de port auto dans Oracle
---------------------------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------------------------
--  Nom           : Calculer_montant
--  Description   : Procédure de Calcul du montant de la commande en tennant pas compte d'eventuelles lignes de frais de port
--
--  PARAMETRES    :pn_header_id              Entrée
--
--                 pn_montant_calculé        Sortie
--                 pv_errbuf                 Entrée/Sortie    message d'erreur
--                 pn_retcode                Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
PROCEDURE Calculer_montant(
        pn_header_id                IN  NUMBER,
        pn_montant_calculé          OUT NUMBER,
        pv_errbuf                   OUT VARCHAR2,
        pn_retcode                  OUT NUMBER)

IS
Vv_Message VARCHAR2(80);
BEGIN

       Dka_Tools_Pkg.put_debug_message ('---> Calcul du montant de la commande');
       dbms_output.put_line ('---> Calcul du montant de la commande');


       SELECT SUM(unit_price * quantity)
       INTO   pn_montant_calculé
       FROM   po_lines_all
       WHERE  po_header_id = pn_header_id
       AND    UPPER(item_description)  NOT LIKE 'FRAIS DE PORT%'
       /* ETANCHEITE DALKIA 2007 */
       --AND    org_id = gn_org_id
       ;


EXCEPTION

         WHEN NO_DATA_FOUND
         THEN
              Vv_Message := SUBSTR(SQLERRM,1,80);
              Dka_Tools_Pkg.put_outdebug_message ('NO DATA FOUND lors du calcul du montant: ' || Vv_Message);
              dbms_output.put_line ('NO DATA FOUND lors du calcul du montant: ' || Vv_Message);
              pv_errbuf := 'NO DATA FOUND lors du calcul du montant: ' || Vv_Message;
              pn_retcode := 2;

         WHEN OTHERS
         THEN
              Vv_Message := SUBSTR(SQLERRM,1,80);
              Dka_Tools_Pkg.put_outdebug_message ('Erreur lors du calcul du montant: ' || Vv_Message);
              dbms_output.put_line ('Erreur lors du calcul du montant: ' || Vv_Message);
              pv_errbuf := 'Erreur lors du calcul du montant: ' || Vv_Message;
              pn_retcode := 2;

END Calculer_montant;


---------------------------------------------------------------------------------------------------------------
--  Nom           : Inserer_ligne
--  Description   : Procédure d'insertion d'une ligne de frais de port
--
--  PARAMETRES    :pn_header_id              Entrée
--
--                 pn_montant_calculé        Sortie
--                 pv_errbuf                 Entrée/Sortie    message d'erreur
--                 pn_retcode                Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------

PROCEDURE Inserer_ligne(
        pn_header_id                IN  NUMBER,
        pn_vendor_id                IN  NUMBER,
        pv_errbuf                   OUT VARCHAR2,
        pn_retcode                  OUT NUMBER)

IS

  vn_line_num                       NUMBER;
  vn_unit_price                     NUMBER;
  vr_dka_parameters  dka_parameters%ROWTYPE;
  vv_description                    VARCHAR2(50);
  vn_line_type_id                   NUMBER;
  vn_category                       NUMBER;
  vv_unit                           VARCHAR2(50);
  vn_line_id                        NUMBER;
  vn_location_id                    NUMBER;
  vn_distribution_id                NUMBER;

  Vr_Rowid                          ROWID;
  Vv_accrue_on_receipt_flag         VARCHAR2(1);
  Vb_autocreated_ship               BOOLEAN;
  Vn_line_location_id               NUMBER;
  Vv_Message                        VARCHAR2(80);

  -- Curseur qui ramene les infos de la ligne de reference
  CURSOR cur_line ( pn_header_id IN NUMBER ) IS
            SELECT   *
            FROM     PO_LINES_ALL
            WHERE    PO_HEADER_ID = pn_header_id
            --AND      LINE_NUM = 1 --RBE INC0228864 
            --RBE INC0228864
            AND      LINE_NUM =(SELECT MIN(line_num)
                                FROM   PO_LINES_ALL
                                WHERE  PO_HEADER_ID = pn_header_id)
            /* ETANCHEITE DALKIA 2007 */
            --AND      org_id = gn_org_id
            ;
  Rec_line cur_line%ROWTYPE;

  CURSOR cur_locations ( pn_header_id IN NUMBER, pn_line_id IN NUMBER ) IS
            SELECT   *
            FROM     PO_LINE_LOCATIONS_ALL
            WHERE    PO_HEADER_ID =   pn_header_id
            AND      LINE_LOCATION_ID = (SELECT MIN(LINE_LOCATION_ID)
                                         FROM     PO_LINE_LOCATIONS_ALL
                                         WHERE    PO_HEADER_ID =  pn_header_id
                                           AND    PO_LINE_ID = pn_line_id
                                         /* ETANCHEITE DALKIA 2007 */
                                         --AND      org_id = gn_org_id
                                         );
   Rec_locations cur_locations%ROWTYPE;

   CURSOR cur_distributions ( pn_line_location_id IN NUMBER ) IS
            SELECT   *
            FROM     PO_DISTRIBUTIONS_ALL
            WHERE    PO_HEADER_ID =   pn_header_id
            AND      PO_DISTRIBUTION_ID = (SELECT MIN(PO_DISTRIBUTION_ID)
                                         FROM     PO_DISTRIBUTIONS_ALL
                                         WHERE    LINE_LOCATION_ID =  pn_line_location_id
                                         /* ETANCHEITE DALKIA 2007 */
                                         --AND      org_id = gn_org_id
                                         );
   Rec_distributions cur_distributions%ROWTYPE;

BEGIN

       dbms_output.put_line ('---> Insertion ligne de frais de port');

       --------------------------------------
       -- determination des valeurs à inserer
       --------------------------------------

       pn_retcode :=0;


       IF (pn_header_id is NULL) AND (pn_vendor_id is NULL)
       THEN
           pn_retcode := 10;
           RETURN;
       END IF;

       -- Determination du line_num
       SELECT MAX(line_num) + 1
       INTO   vn_line_num
       FROM   PO_LINES_ALL
       WHERE  PO_HEADER_ID = pn_header_id
       /* ETANCHEITE DALKIA 2007 */
       --AND    org_id = gn_org_id
       ;


       dbms_output.put_line ('vn_line_num: '|| vn_line_num);

       -- Calcul du montant
       SELECT Montant
       INTO   vn_unit_price
       FROM   DKA_SPOPARAM_FRAIS_PORT
       WHERE  vendor_id = pn_vendor_id
       /* ETANCHEITE DALKIA 2007 */
       /*AND    org_id = gn_org_id*/
       ;

       dbms_output.put_line ('vn_unit_price: '|| vn_unit_price);

/*       -- Determination des sequences
       SELECT po_lines_s.NEXTVAL,
              po_line_locations_s.NEXTVAL,
              po_distributions_s.Nextval
       INTO   vn_line_id,
              vn_location_id,
              vn_distribution_id
       FROM   dual;*/


       -- recherche du type de ligne
       Dka_Tools_Pkg.get_parameter ('SPOFRAIS', 'LINE_TYPE_ID', vr_dka_parameters, pn_retcode, pv_errbuf);

       IF pn_retcode != 0
       THEN
          pv_errbuf := 'Erreur lors de la determination du type de ligne';
       END IF;

       vn_line_type_id := vr_dka_parameters.number_value;
       dbms_output.put_line ('vn_line_type_id: '|| vn_line_type_id);

       -- recherche de la categorie
       Dka_Tools_Pkg.get_parameter ('SPOFRAIS', 'CATEGORY_ID', vr_dka_parameters, pn_retcode, pv_errbuf);

       IF pn_retcode != 0
       THEN
          pv_errbuf := 'Erreur lors de la determination de la categorie';
       END IF;

       vn_category := vr_dka_parameters.number_value;
       dbms_output.put_line ('vn_category: '|| vn_category);

       -- recherche de la description
       Dka_Tools_Pkg.get_parameter ('SPOFRAIS', 'ITEM_DESCRIPTION', vr_dka_parameters, pn_retcode, pv_errbuf);

       IF pn_retcode != 0
       THEN
          pv_errbuf := 'Erreur lors de la determination de la categorie';
       END IF;

       vv_description := vr_dka_parameters.varchar2_value;
       dbms_output.put_line ('vv_description: '|| vv_description);

        -- recherche de l'unité de mesure
       Dka_Tools_Pkg.get_parameter ('SPOFRAIS', 'UNIT_MEAS_LOOKUP_CODE', vr_dka_parameters, pn_retcode, pv_errbuf);

       IF pn_retcode != 0
       THEN
          pv_errbuf := 'Erreur lors de la determination de l unité de mesure';
       END IF;

       vv_unit := vr_dka_parameters.varchar2_value;
       dbms_output.put_line ('vv_unit: '|| vv_unit);


       -- Insertion de la ligne de frais de port dans PO_LINES_ALL
       OPEN cur_line ( pn_header_id => pn_header_id );
       FETCH cur_line INTO Rec_Line;
       CLOSE cur_line;

       dbms_output.put_line ('Insertion de la ligne de frais de port dans PO_LINES_ALL');
       PO_LINES_SV3.insert_line ( x_rowid    => Vr_Rowid,
                                                x_po_line_id => vn_line_id,
                                                x_last_update_date => SYSDATE,
                                                x_last_updated_by  => Fnd_Global.user_Id,
                                                x_po_header_id     => pn_header_id,
                                                x_line_type_id     => vn_line_type_id,
                                    x_line_num         => PO_LINES_SV2.get_max_line_num (X_po_header_id => pn_header_id) +1 ,
                                x_last_update_login => Fnd_Global.Login_Id,
                                x_creation_date     => SYSDATE,
                                x_created_by        => Fnd_Global.user_Id,
                                x_item_id           => NULL, -- Rec_Line.Item_Id,  SELO : artf07295578
                                x_item_revision     => Rec_Line.Item_revision,
                                x_category_id       => vn_category ,
                                x_item_description  => vv_description,
                                x_unit_meas_lookup_code  => vv_unit,
                                x_quantity_committed     =>  Rec_Line.quantity_committed,
                                x_committed_amount       => Rec_Line.committed_amount,
                                x_allow_price_override_flag => Rec_Line.allow_price_override_flag,
                                x_not_to_exceed_price       =>  Rec_Line.not_to_exceed_price,
                                x_list_price_per_unit       => vn_unit_price,
                                x_unit_price                => vn_unit_price,
                                x_quantity                  => 1,
                                x_un_number_id              => Rec_Line.un_number_id,
                                x_hazard_class_id           => Rec_Line.hazard_class_id,
                                x_note_to_vendor            => Rec_Line.note_to_vendor,
                                x_from_header_id            => Rec_Line.from_header_id,
                                x_from_line_id              => Rec_Line.from_line_id  ,
                                x_from_line_location_id     => Rec_Line.from_line_location_id,
                                x_min_order_quantity        => Rec_Line.min_order_quantity,
                                x_max_order_quantity        => Rec_Line.max_order_quantity ,
                                x_qty_rcv_tolerance         => Rec_Line.qty_rcv_tolerance,
                                x_over_tolerance_error_flag => Rec_Line.over_tolerance_error_flag,
                                x_market_price              => Rec_Line.market_price,
                                x_unordered_flag            => Rec_Line.unordered_flag,
                                x_closed_flag               => NULL, -- Modif TB 23/06/2010 CLOSED_FLAG = rec_line.CLOSED_FLAG,
                                x_user_hold_flag            => NULL, -- Modif TB 23/06/2010 USER_HOLD_FLAG = rec_line.USER_HOLD_FLAG,
                                x_cancel_flag               => NULL, -- Modif TB 23/06/2010 CANCEL_FLAG = rec_line.CANCEL_FLAG,
                                x_cancelled_by              => NULL, -- Modif TB 23/06/2010 CANCELLED_BY = rec_line.CANCELLED_BY,
                                x_cancel_date               => NULL, -- Modif TB 23/06/2010 CANCEL_DATE = rec_line.CANCEL_DATE,
                                x_cancel_reason             => NULL, -- Modif TB 23/06/2010 CANCEL_REASON = rec_line.CANCEL_REASON,
                                x_firm_status_lookup_code   => Rec_Line.firm_status_lookup_code,
                                x_firm_date                 => Rec_Line.firm_date,
                                x_vendor_product_num        => NULL, -- Colonne non alimentee dans le version 11i
                                x_contract_num              => Rec_Line.contract_num,
                                x_taxable_flag              => Rec_Line.taxable_flag,
                                x_tax_code_id               => rec_Line.tax_code_id,
                                x_type_1099                 => rec_Line.type_1099,
                                x_capital_expense_flag      => rec_Line.capital_expense_flag,
                                x_negotiated_by_preparer_flag => rec_Line.negotiated_by_preparer_flag,
                                x_attribute_category          => rec_Line.attribute_category,
                                x_attribute1                  => 'A',
                                x_attribute2                  => rec_Line.attribute2,
                                x_attribute3                  => rec_Line.attribute3,
                                x_attribute4                  => rec_Line.attribute4,
                                x_attribute5                  => rec_Line.attribute5,
                                x_attribute6                  => rec_Line.attribute6,
                                x_attribute7                  => rec_Line.attribute7,
                                x_attribute8                  => rec_Line.attribute8,
                                x_attribute9                  => rec_Line.attribute9,
                                x_attribute10                 => rec_Line.attribute10,
                                x_reference_num               => rec_Line.reference_num,
                                x_attribute11                 => rec_Line.attribute11,
                                x_attribute12                 => rec_Line.attribute12,
                                x_attribute13                 => rec_Line.attribute13,
                                x_attribute14                 => rec_Line.attribute14,
                                x_attribute15                 => rec_Line.attribute15,
                                x_min_release_amount          => rec_Line.min_release_amount,
                                x_price_type_lookup_code      => rec_Line.price_type_lookup_code,
                                x_closed_code                 => NULL,-- Modif TB 23/06/2010 CLOSED_CODE = rec_line.CLOSED_CODE,
                                x_price_break_lookup_code     => rec_Line.price_break_lookup_code,
                                x_ussgl_transaction_code      => rec_Line.ussgl_transaction_code,
                                x_government_context          => rec_Line.government_context,
                                x_closed_date                 => NULL, -- Modif TB 23/06/2010 CLOSED_DATE = rec_line.CLOSED_DATE,
                                x_closed_reason               => NULL, -- Modif TB 23/06/2010 CLOSED_REASON = rec_line.CLOSED_REASON,
                                x_closed_by                   => NULL, -- Modif TB 23/06/2010 CLOSED_BY = rec_line.CLOSED_BY,
                                x_transaction_reason_code     => rec_Line.transaction_reason_code,
                                x_revise_header               => NULL, -- Parametre non utilise dans le package
                                x_revision_num                => NULL, -- Parametre non utilise dans le package
                                x_revised_date                => NULL, -- Parametre non utilise dans le package
                                x_approved_flag               => NULL, -- Parametre non utilise dans le package
                                x_header_row_id               => NULL, -- Parametre non utilise dans le package
                                x_type_lookup_code            => 'STANDARD',
                                x_ship_to_location_id         => NULL,
                                x_ship_org_id                 => NULL,
                                x_need_by_date                => NULL,
                                x_promised_date               => NULL,
                                x_receipt_required_flag       => NULL,
                                x_invoice_close_tolerance     => NULL,
                                x_receive_close_tolerance     => NULL,
                                x_planned_item_flag           => NULL,
                                x_outside_operation_flag      => NULL,
                                x_destination_type_code       => NULL,
                                x_expense_accrual_code        => NULL,
                                x_dist_blk_status             => NULL,
                                x_accrue_on_receipt_flag      => Vv_accrue_on_receipt_flag,
                                x_ok_to_autocreate_ship       => NULL,
                                x_autocreated_ship            => Vb_autocreated_ship,
                                x_line_location_id            => Vn_line_location_id,
                                x_vendor_id                   => NULL,
                                x_global_attribute_category   => rec_Line.global_attribute_category,
                                x_global_attribute1           => rec_Line.global_attribute1,
                                x_global_attribute2           => rec_Line.global_attribute2,
                                x_global_attribute3           => rec_Line.global_attribute3,
                                x_global_attribute4           => rec_Line.global_attribute4,
                                x_global_attribute5           => rec_Line.global_attribute5,
                                x_global_attribute6           => rec_Line.global_attribute6,
                                x_global_attribute7           => rec_Line.global_attribute7,
                                x_global_attribute8           => rec_Line.global_attribute8,
                                x_global_attribute9           => rec_Line.global_attribute9,
                                x_global_attribute10          => rec_Line.global_attribute10,
                                x_global_attribute11          => rec_Line.global_attribute11,
                                x_global_attribute12          => rec_Line.global_attribute12,
                                x_global_attribute13          => rec_Line.global_attribute13,
                                x_global_attribute14          => rec_Line.global_attribute14,
                                x_global_attribute15          => rec_Line.global_attribute15,
                                x_global_attribute16          => rec_Line.global_attribute16,
                                x_global_attribute17          => rec_Line.global_attribute17,
                                x_global_attribute18          => rec_Line.global_attribute18,
                                x_global_attribute19          => rec_Line.global_attribute19,
                                x_global_attribute20          => rec_Line.global_attribute20,
                                x_expiration_date             => rec_Line.expiration_date,
                                x_base_uom                    => rec_Line.base_uom,
                                x_base_qty                    => rec_Line.base_qty,
                                x_secondary_uom               => rec_Line.secondary_uom,
                                x_secondary_qty               => rec_Line.secondary_qty,
                                x_qc_grade                    => rec_Line.qc_grade,
                                x_oke_contract_header_id      => rec_Line.oke_contract_header_id,
                                x_oke_contract_version_id     => rec_Line.oke_contract_version_id,
                                x_secondary_unit_of_measure   => rec_Line.secondary_unit_of_measure,
                                x_secondary_quantity          => rec_Line.secondary_quantity,
                                x_preferred_grade             => rec_Line.preferred_grade,
                                p_contract_id                 => rec_Line.contract_id,
                                x_job_id                      => rec_Line.job_id,
                                x_contractor_first_name       => rec_Line.contractor_first_name,
                                x_contractor_last_name        => rec_Line.contractor_last_name,
                                x_assignment_start_date       => rec_Line.start_date,
                                x_amount_db                   => rec_Line.amount,
                                x_order_type_lookup_code      => rec_Line.order_type_lookup_code,
                                x_purchase_basis              => rec_Line.purchase_basis,
                                x_matching_basis              => rec_Line.matching_basis ,
                                x_base_unit_price             => rec_Line.base_unit_price,
                                p_manual_price_change_flag    => rec_Line.manual_price_change_flag,
                                p_consigned_from_supplier_flag => NULL,
                                p_org_id                       => rec_Line.org_id);

         -- Insertion de la ligne de frais de port dans PO_LINE_LOCATIONS_ALL

         Vr_Rowid := NULL;
         OPEN cur_locations (pn_header_id => pn_header_id, pn_line_id => Rec_Line.po_line_id);
         FETCH cur_locations INTO rec_locations;
         CLOSE cur_locations;

         dbms_output.put_line ('Insertion de la ligne de frais de port dans PO_LINE_LOCATIONS_ALL');
         PO_LINE_LOCATIONS_PKG_S0.Insert_Row ( x_rowid => Vr_Rowid ,
                                               x_line_location_id => vn_location_id,
                                               x_last_update_date => SYSDATE,
                                               x_last_updated_by  => Fnd_Global.User_Id,
                                               x_po_header_id     => pn_header_id,
                                               x_po_line_id       => vn_line_id,
                                               x_last_update_login => Fnd_Global.Login_Id,
                                               x_creation_date     => SYSDATE,
                                               x_created_by        => Fnd_Global.User_Id,
                                               x_quantity          => 1,
                                               x_quantity_received => 0, -- QUANTITY_RECEIVED,  -- Modif TB 23/06/2010
                                               x_quantity_accepted => 0, -- QUANTITY_ACCEPTED,  -- Modif TB 23/06/2010
                                               x_quantity_rejected => 0, -- QUANTITY_REJECTED,  -- Modif TB 23/06/2010
                                               x_quantity_billed   => 0, -- QUANTITY_BILLED,    -- Modif TB 23/06/2010
                                               x_quantity_cancelled => 0, -- QUANTITY_CANCELLED, -- Modif TB 23/06/2010
                                               x_unit_meas_lookup_code => vv_unit,
                                               x_po_release_id         => rec_locations.po_release_id,
                                               x_ship_to_location_id   => rec_locations.ship_to_location_id,
                                               x_ship_via_lookup_code  => rec_locations.ship_via_lookup_code,
                                               x_need_by_date          => rec_locations.need_by_date,
                                               x_promised_date         => rec_locations.promised_date,
                                               x_last_accept_date      => SYSDATE,
                                               x_price_override        => vn_unit_price,
                                               x_encumbered_flag       => rec_locations.encumbered_flag,
                                               x_encumbered_date       => rec_locations.encumbered_date,
                                               x_fob_lookup_code       => rec_locations.fob_lookup_code,
                                               x_freight_terms_lookup_code => rec_locations.freight_terms_lookup_code,
                                               x_taxable_flag              => rec_locations.taxable_flag,
                                               x_tax_code_id               => rec_locations.tax_code_id,
                                               x_tax_user_override_flag    => rec_locations.tax_user_override_flag,
                                               x_calculate_tax_flag        => rec_locations.calculate_tax_flag,
                                               x_from_header_id            => rec_locations.from_header_id,
                                               x_from_line_id              => rec_locations.from_line_id,
                                               x_from_line_location_id     => rec_locations.from_line_location_id,
                                               x_start_date                => rec_locations.start_date,
                                               x_end_date                  => rec_locations.end_date,
                                               x_lead_time                 => rec_locations.lead_time,
                                               x_lead_time_unit            => rec_locations.lead_time_unit,
                                               x_price_discount            => rec_locations.price_discount,
                                               x_terms_id                  => rec_locations.terms_id,
                                               x_approved_flag             => rec_locations.approved_flag,
                                               x_approved_date             => rec_locations.approved_date,
                                               x_closed_flag               => NULL,-- Modif TB 23/06/2010 CLOSED_FLAG = rec_locations.CLOSED_FLAG,
                                               x_cancel_flag               => NULL,-- Modif TB 23/06/2010 CANCEL_FLAG = rec_locations.CANCEL_FLAG,
                                               x_cancelled_by              => NULL,-- Modif TB 23/06/2010 CANCELLED_BY = rec_locations.CANCELLED_BY,
                                               x_cancel_date               => NULL,-- Modif TB 23/06/2010 CANCEL_DATE = rec_locations.CANCEL_DATE,
                                               x_cancel_reason             => NULL,-- Modif TB 23/06/2010 CANCEL_REASON = rec_locations.CANCEL_REASON,
                                               x_firm_status_lookup_code   => rec_locations.firm_status_lookup_code,
                                               x_attribute_category        => rec_locations.attribute_category,
                                               x_attribute1                => rec_locations.attribute1,
                                               x_attribute2                => rec_locations.attribute2,
                                               x_attribute3                => rec_locations.attribute3,
                                               x_attribute4                => rec_locations.attribute4,
                                               x_attribute5                => rec_locations.attribute5,
                                               x_attribute6                => rec_locations.attribute6,
                                               x_attribute7                => rec_locations.attribute7,
                                               x_attribute8                => rec_locations.attribute8,
                                               x_attribute9                => rec_locations.attribute9,
                                               x_attribute10               => rec_locations.attribute10,
                                               x_attribute11               => rec_locations.attribute11,
                                               x_attribute12               => rec_locations.attribute12,
                                               x_attribute13               => rec_locations.attribute13,
                                               x_attribute14               => rec_locations.attribute14,
                                               x_attribute15               => rec_locations.attribute15,
                                               x_inspection_required_flag  => rec_locations.inspection_required_flag,
                                               x_receipt_required_flag     => rec_locations.receipt_required_flag,
                                               x_qty_rcv_tolerance         => rec_locations.qty_rcv_tolerance,
                                               x_qty_rcv_exception_code    => rec_locations.qty_rcv_exception_code,
                                               x_enforce_ship_to_location  => rec_locations.enforce_ship_to_location_code,
                                               x_allow_substitute_receipts => rec_locations.allow_substitute_receipts_flag,
                                               x_days_early_receipt_allowed => rec_locations.days_early_receipt_allowed,
                                               x_days_late_receipt_allowed  => rec_locations.days_late_receipt_allowed,
                                               x_receipt_days_exception_code => rec_locations.receipt_days_exception_code ,
                                               x_invoice_close_tolerance     => rec_locations.invoice_close_tolerance,
                                               x_receive_close_tolerance     => rec_locations.receive_close_tolerance,
                                               x_ship_to_organization_id     => rec_locations.ship_to_organization_id,
                                               x_shipment_num                => rec_locations.shipment_num,
                                               x_source_shipment_id          => rec_locations.source_shipment_id,
                                               x_shipment_type               => rec_locations.shipment_type,
                                               x_closed_code                 => NULL, -- Modif TB 23/06/2010 CLOSED_CODE = rec_locations.CLOSED_CODE,
                                               x_ussgl_transaction_code      => rec_locations.ussgl_transaction_code,
                                               x_government_context          => rec_locations.government_context,
                                               x_receiving_routing_id        => rec_locations.receiving_routing_id,
                                               x_accrue_on_receipt_flag      => rec_locations.accrue_on_receipt_flag ,
                                               x_closed_reason               => NULL, -- Modif TB 23/06/2010 CLOSED_REASON = rec_locations.CLOSED_REASON,
                                               x_closed_date                 => NULL, -- Modif TB 23/06/2010 CLOSED_DATE = rec_locations.CLOSED_DATE,
                                               x_closed_by                   => NULL, -- Modif TB 23/06/2010 CLOSED_BY = rec_locations.CLOSED_BY,
                                               x_global_attribute_category   => rec_locations.global_attribute_category,
                                               x_global_attribute1           => rec_locations.global_attribute1,
                                               x_global_attribute2           => rec_locations.global_attribute2,
                                               x_global_attribute3           => rec_locations.global_attribute3,
                                               x_global_attribute4           => rec_locations.global_attribute4,
                                               x_global_attribute5           => rec_locations.global_attribute5,
                                               x_global_attribute6           => rec_locations.global_attribute6,
                                               x_global_attribute7           => rec_locations.global_attribute7,
                                               x_global_attribute8           => rec_locations.global_attribute8,
                                               x_global_attribute9           => rec_locations.global_attribute9,
                                               x_global_attribute10          => rec_locations.global_attribute10,
                                               x_global_attribute11          => rec_locations.global_attribute11,
                                               x_global_attribute12          => rec_locations.global_attribute12,
                                               x_global_attribute13          => rec_locations.global_attribute13,
                                               x_global_attribute14          => rec_locations.global_attribute14,
                                               x_global_attribute15          => rec_locations.global_attribute15,
                                               x_global_attribute16          => rec_locations.global_attribute16,
                                               x_global_attribute17          => rec_locations.global_attribute17,
                                               x_global_attribute18          => rec_locations.global_attribute18,
                                               x_global_attribute19          => rec_locations.global_attribute19,
                                               x_global_attribute20          => rec_locations.global_attribute20,
                                               x_country_of_origin_code      => rec_locations.country_of_origin_code,
                                               x_invoice_match_option        => rec_locations.match_option,
                                               p_value_basis                 => rec_locations.value_basis,
                                               p_matching_basis              => rec_locations.matching_basis,
                                               x_note_to_receiver            => rec_locations.note_to_receiver,
                                               x_secondary_unit_of_measure   => rec_locations.secondary_unit_of_measure,
                                               x_secondary_quantity          => rec_locations.secondary_quantity,
                                               x_preferred_grade             => rec_locations.preferred_grade,
                                               x_secondary_quantity_received => rec_locations.secondary_quantity_received,
                                               x_secondary_quantity_accepted => rec_locations.secondary_quantity_accepted,
                                               x_secondary_quantity_rejected => rec_locations.secondary_quantity_rejected,
                                               x_secondary_quantity_cancelled => rec_locations.secondary_quantity_cancelled,
                                               x_consigned_flag               => rec_locations.consigned_flag,
                                               x_amount                       => rec_locations.amount,
                                               p_transaction_flow_header_id   => rec_locations.transaction_flow_header_id,
                                               p_manual_price_change_flag     => rec_locations.manual_price_change_flag,
                                               p_org_id                       => rec_locations.org_id,
                                               p_outsourced_assembly          => rec_locations.outsourced_assembly);

        -- Insertion dans PO_DISTRIBUTIONS_ALL

        Vr_Rowid := NULL;
        OPEN cur_distributions (pn_line_location_id => rec_locations.line_location_id);
        FETCH cur_distributions INTO rec_distributions;
        CLOSE cur_distributions;
                
        dbms_output.put_line ('Insertion de la ligne de frais de port dans PO_DISTRIBUTIONS_ALL');
        PO_DISTRIBUTIONS_PKG1.INSERT_ROW ( x_rowid => Vr_Rowid,
                                           x_po_distribution_id => vn_distribution_id,
                                           x_last_update_date   => SYSDATE,
                                           x_last_updated_by    => Fnd_Global.User_Id,
                                           x_po_header_id       => pn_header_id,
                                           x_po_line_id         => vn_line_id,
                                           x_line_location_id   => vn_location_id, --vn_line_location_id,
                                           x_set_of_books_id    => rec_distributions.set_of_books_id,
                                           x_code_combination_id   => rec_distributions.code_combination_id,
                                           x_quantity_ordered      => 1,
                                           x_last_update_login     => Fnd_Global.Login_Id,
                                           x_creation_date         => SYSDATE,
                                           x_created_by            => Fnd_Global.User_Id,
                                           x_po_release_id         => rec_distributions.po_release_id,
                                           x_quantity_delivered    => 0, -- Modif TB 23/06/2010 QUANTITY_DELIVERED = rec_distributions.QUANTITY_DELIVERED,
                                           x_quantity_billed       => 0, -- Modif TB 23/06/2010 QUANTITY_BILLED = rec_distributions.QUANTITY_BILLED,,
                                           x_quantity_cancelled    => 0, -- Modif TB 23/06/2010 QUANTITY_CANCELLED = rec_distributions.QUANTITY_CANCELLED,,
                                           x_req_header_reference_num => NULL,
                                           x_req_line_reference_num   => NULL,
                                           x_req_distribution_id      => NULL,
                                           x_deliver_to_location_id   => rec_distributions.DELIVER_TO_LOCATION_ID,    -- Modif TB 18/04/2006,
                                           x_deliver_to_person_id     => rec_distributions.DELIVER_TO_PERSON_ID,    -- Modif TB 18/04/2006,
                                           x_rate_date                => rec_distributions.RATE_DATE,
                                           x_rate                     => rec_distributions.RATE,
                                           x_amount_billed            => NULL, -- Modif TB 23/06/2010 AMOUNT_BILLED = rec_distributions.AMOUNT_BILLED,
                                           x_accrued_flag             => rec_distributions.ACCRUED_FLAG,
                                           x_encumbered_flag          => rec_distributions.ENCUMBERED_FLAG,
                                           x_encumbered_amount        => rec_distributions.ENCUMBERED_AMOUNT,
                                           x_unencumbered_quantity    => rec_distributions.UNENCUMBERED_QUANTITY,
                                           x_unencumbered_amount      => rec_distributions.UNENCUMBERED_AMOUNT,
                                           x_failed_funds_lookup_code => rec_distributions.FAILED_FUNDS_LOOKUP_CODE,
                                           x_gl_encumbered_date       => rec_distributions.GL_ENCUMBERED_DATE,
                                           x_gl_encumbered_period_name => rec_distributions.GL_ENCUMBERED_PERIOD_NAME,
                                           x_gl_cancelled_date         => rec_distributions.GL_CANCELLED_DATE,
                                           x_destination_type_code     => rec_distributions.DESTINATION_TYPE_CODE,
                                           x_destination_organization_id => rec_distributions.DESTINATION_ORGANIZATION_ID,
                                           x_destination_subinventory    => rec_distributions.DESTINATION_SUBINVENTORY,
                                           x_attribute_category          => rec_distributions.attribute_category,
                                           x_attribute1                  => rec_distributions.attribute1,
                                           x_attribute2                  => rec_distributions.attribute2,
                                           x_attribute3                  => rec_distributions.attribute3,
                                           x_attribute4                  => rec_distributions.attribute4,
                                           x_attribute5                  => rec_distributions.attribute5,
                                           x_attribute6                  => rec_distributions.attribute6,
                                           x_attribute7                  => rec_distributions.attribute7,
                                           x_attribute8                  => rec_distributions.attribute8,
                                           x_attribute9                  => rec_distributions.attribute9,
                                           x_attribute10                 => rec_distributions.attribute10,
                                           x_attribute11                 => rec_distributions.attribute11,
                                           x_attribute12                 => rec_distributions.attribute12,
                                           x_attribute13                 => rec_distributions.attribute13,
                                           x_attribute14                 => rec_distributions.attribute14,
                                           x_attribute15                 => rec_distributions.attribute15,
                                           x_wip_entity_id               => rec_distributions.WIP_ENTITY_ID,
                                           x_wip_operation_seq_num       => rec_distributions.WIP_OPERATION_SEQ_NUM,
                                           x_wip_resource_seq_num        => rec_distributions.WIP_RESOURCE_SEQ_NUM,
                                           x_wip_repetitive_schedule_id  => rec_distributions.WIP_REPETITIVE_SCHEDULE_ID,
                                           x_wip_line_id                 => rec_distributions.WIP_LINE_ID,
                                           x_bom_resource_id             => rec_distributions.BOM_RESOURCE_ID,
                                           x_budget_account_id           => rec_distributions.BUDGET_ACCOUNT_ID,
                                           x_accrual_account_id          => rec_distributions.ACCRUAL_ACCOUNT_ID,
                                           x_variance_account_id         => rec_distributions.VARIANCE_ACCOUNT_ID,
                                           p_dest_charge_account_id      => NULL,
                                           p_dest_variance_account_id    => NULL,
                                           x_prevent_encumbrance_flag    => rec_distributions.PREVENT_ENCUMBRANCE_FLAG,
                                           x_ussgl_transaction_code      => rec_distributions.USSGL_TRANSACTION_CODE,
                                           x_government_context          => rec_distributions.GOVERNMENT_CONTEXT,
                                           x_destination_context         => rec_distributions.DESTINATION_CONTEXT,
                                           x_distribution_num            => rec_distributions.DISTRIBUTION_NUM,
                                           x_source_distribution_id      => rec_distributions.SOURCE_DISTRIBUTION_ID,
                                           x_project_id                  => rec_distributions.PROJECT_ID,
                                           x_task_id                     => rec_distributions.TASK_ID,
                                           x_expenditure_type            => rec_distributions.EXPENDITURE_TYPE,
                                           x_project_accounting_context  => rec_distributions.PROJECT_ACCOUNTING_CONTEXT,
                                           x_expenditure_organization_id => rec_distributions.EXPENDITURE_ORGANIZATION_ID,
                                           x_gl_closed_date              => rec_distributions.GL_CLOSED_DATE,
                                           x_accrue_on_receipt_flag      => rec_distributions.ACCRUE_ON_RECEIPT_FLAG,
                                           x_expenditure_item_date       => rec_distributions.EXPENDITURE_ITEM_DATE,
                                           x_end_item_unit_number        => rec_distributions.END_ITEM_UNIT_NUMBER,
                                           x_recovery_rate               => rec_distributions.RECOVERY_RATE,
                                           x_recoverable_tax             => rec_distributions.RECOVERABLE_TAX,
                                           x_nonrecoverable_tax          => rec_distributions.NONRECOVERABLE_TAX,
                                           x_tax_recovery_override_flag  => rec_distributions.TAX_RECOVERY_OVERRIDE_FLAG,
                                           x_award_id                    => rec_distributions.AWARD_ID,
                                           x_oke_contract_line_id        => rec_distributions.OKE_CONTRACT_LINE_ID,
                                           x_oke_contract_deliverable_id => rec_distributions.OKE_CONTRACT_DELIVERABLE_ID,
                                           x_amount_ordered              => rec_distributions.AMOUNT_ORDERED,
                                           x_distribution_type           => rec_distributions.DISTRIBUTION_TYPE,
                                           x_amount_to_encumber          => rec_distributions.AMOUNT_TO_ENCUMBER,
                                           p_org_id                      => rec_distributions.ORG_ID,
                                           x_global_attribute_category   => rec_distributions.global_attribute_category,
                                           x_global_attribute1           => rec_distributions.global_attribute1,
                                           x_global_attribute2           => rec_distributions.global_attribute2,
                                           x_global_attribute3           => rec_distributions.global_attribute3,
                                           x_global_attribute4           => rec_distributions.global_attribute4,
                                           x_global_attribute5           => rec_distributions.global_attribute5,
                                           x_global_attribute6           => rec_distributions.global_attribute6,
                                           x_global_attribute7           => rec_distributions.global_attribute7,
                                           x_global_attribute8           => rec_distributions.global_attribute8,
                                           x_global_attribute9           => rec_distributions.global_attribute9,
                                           x_global_attribute10          => rec_distributions.global_attribute10,
                                           x_global_attribute11          => rec_distributions.global_attribute11,
                                           x_global_attribute12          => rec_distributions.global_attribute12,
                                           x_global_attribute13          => rec_distributions.global_attribute13,
                                           x_global_attribute14          => rec_distributions.global_attribute14,
                                           x_global_attribute15          => rec_distributions.global_attribute15,
                                           x_global_attribute16          => rec_distributions.global_attribute16,
                                           x_global_attribute17          => rec_distributions.global_attribute17,
                                           x_global_attribute18          => rec_distributions.global_attribute18,
                                           x_global_attribute19          => rec_distributions.global_attribute19,
                                           x_global_attribute20          => rec_distributions.global_attribute20);
                                           
EXCEPTION
         WHEN OTHERS
         THEN
              Vv_Message := SUBSTR(SQLERRM,1,80);
              dbms_output.put_line ('Erreur lors de l insertion: ' || Vv_Message);
              dbms_output.put_line (fnd_message.get);
              pv_errbuf := 'Erreur lors de l insertion: ' || Vv_Message;
              
              pn_retcode := 1;
END Inserer_ligne;


PROCEDURE Annuler_ligne(
        pn_header_id                IN  NUMBER,
        pn_line_id                  IN  NUMBER,
        pv_errbuf                   OUT VARCHAR2,
        pn_retcode                  OUT NUMBER)

IS
Vv_Message VARCHAR2(80);
BEGIN

       Dka_Tools_Pkg.put_debug_message ('---> Annuler ligne(s) de frais de port');
       dbms_output.put_line ('---> Annuler ligne(s) de frais de port');

       pn_retcode := 0;

       -- Mise à jour de PO_DISTRIBUTIONS_ALL
       UPDATE PO_DISTRIBUTIONS_ALL POD
       SET    POD.Quantity_Cancelled =  pod.quantity_ordered -
                                        DECODE(sign(nvl(quantity_delivered,0) -
                                        nvl(quantity_billed,0)),
                                        1, nvl(quantity_delivered,0),
                                        nvl(quantity_billed,0)),
              POD.Last_Update_Date = SYSDATE,
              POD.Last_Updated_By = fnd_global.user_id,
              POD.Last_Update_Login = fnd_global.login_id
       WHERE  POD.PO_HEADER_ID = pn_header_id
       AND    POD.Line_Location_Id IN (SELECT line_location_id
                                   FROM PO_LINE_LOCATIONS_ALL
                                   WHERE po_header_id = pn_header_id
                                   AND   po_line_id = pn_line_id
                                   /* ETANCHEITE DALKIA 2007 */
                                   --AND   org_id = gn_org_id
                                   );



        UPDATE PO_LINE_LOCATIONS_ALL POLL
        SET    POLL.cancel_flag = 'I',
               POLL.cancel_date = TRUNC(SYSDATE),
               POLL.cancel_reason = 'Annulation ligne de frais de port',
               POLL.cancelled_by = fnd_global.user_id,
               POLL.last_update_date = sysdate,
               POLL.last_updated_by = fnd_global.user_id,
               POLL.last_update_login = fnd_global.login_id,
               POLL.quantity_cancelled = (SELECT SUM(nvl(POD.quantity_cancelled,0))
                                          FROM   PO_DISTRIBUTIONS_ALL POD
                                          WHERE  POD.line_location_id = POLL.line_location_id)
        WHERE  POLL.po_header_id = pn_header_id
        AND    POLL.po_line_id = pn_line_id
        /* ETANCHEITE DALKIA 2007 */
        --AND    POLL.org_id = gn_org_id
        ;



        UPDATE PO_LINES_ALL pol
        SET    pol.cancel_flag = 'I',
               pol.cancel_date = TRUNC(SYSDATE),
               pol.cancel_reason = 'Annulation ligne de frais de port',
               pol.cancelled_by = fnd_global.user_id,
               pol.last_update_date = sysdate,
               pol.last_updated_by = fnd_global.user_id,
               pol.last_update_login = fnd_global.login_id,
               pol.quantity = (SELECT sum(nvl(poll.quantity,0) - nvl(poll.quantity_cancelled,0))
                               FROM   PO_LINE_LOCATIONS_ALL poll
                               WHERE  poll.po_line_id = pol.po_line_id
                               AND    poll.shipment_type IN ('STANDARD','BLANKET', 'PLANNED') )
        WHERE  POL.po_header_id = pn_header_id
        AND    POL.po_line_id = pn_line_id
        /* ETANCHEITE DALKIA 2007 */
        --AND    POL.org_id = gn_org_id
        ;




        UPDATE PO_DISTRIBUTIONS_ALL POD
        SET    pod.last_update_date = sysdate,
               pod.last_updated_by = fnd_global.user_id,
               pod.last_update_login = fnd_global.login_id,
               pod.req_distribution_id = NULL ,
               pod.gl_cancelled_date = TRUNC(SYSDATE)
        WHERE  pod.line_location_id IN
               ( SELECT poll.line_location_id
                 FROM   PO_LINE_LOCATIONS_ALL poll
                 WHERE  poll.po_line_id = pn_line_id
                 /* ETANCHEITE DALKIA 2007 */
                 --AND    poll.org_id = gn_org_id
                 );



        UPDATE PO_LINE_LOCATIONS_ALL POLL
        SET    POLL.cancel_flag = 'Y',
               POLL.cancel_date = TRUNC(SYSDATE),
               POLL.cancel_reason = 'Annulation ligne de frais de port',
               POLL.cancelled_by = fnd_global.user_id,
               POLL.last_update_date = sysdate,
               POLL.last_updated_by = fnd_global.user_id,
               POLL.last_update_login = fnd_global.login_id
        WHERE  POLL.po_line_id = pn_line_id
        /* ETANCHEITE DALKIA 2007 */
        --AND    poll.org_id = gn_org_id
        ;


        UPDATE PO_LINES_ALL pol
        SET    pol.cancel_flag = 'Y',
               pol.cancel_date = TRUNC(SYSDATE),
               pol.cancel_reason = 'Annulation ligne de frais de port',
               pol.cancelled_by = fnd_global.user_id,
               pol.last_update_date = sysdate,
               pol.last_updated_by = fnd_global.user_id,
               pol.last_update_login = fnd_global.login_id
        WHERE  pol.po_line_id = pn_line_id
        /* ETANCHEITE DALKIA 2007 */
        --AND    pol.org_id = gn_org_id
        ;



        UPDATE PO_LINE_LOCATIONS_ALL POLL
        SET    CLOSED_CODE = (SELECT ( DECODE
                                     ( DECODE(
                                          sign((( POLL.quantity - nvl(poll.quantity_cancelled,0) )* ( 1 -  nvl(POLL.invoice_close_tolerance,nvl(POSP.invoice_close_tolerance,0))/100 ))
                                                  - nvl(poll.quantity_billed,0)), 1,
                                      'OPEN',
                                      'CLOSED FOR INVOICE'),
                                      'CLOSED FOR INVOICE',
                                         DECODE (
                                            DECODE(sign ((( POLL.quantity - nvl(POLL.quantity_cancelled,0) )
                                                         * ( 1 - nvl(POLL.receive_close_tolerance,
                                                         nvl(POSP.receive_close_tolerance,0))/100 ))
                                                   - decode( POSP.receive_close_code,
                                                             'ACCEPTED',
                                                             nvl(POLL.quantity_accepted,0),
                                                             'DELIVERED',
                                                             sum(nvl(POD.quantity_delivered,0)),
                                                             nvl(POLL.quantity_received,0)                                          )
                                                             )  , 1, 'OPEN', 'CLOSED FOR RECEIVING'),
                                         'CLOSED FOR RECEIVING',
                                         'CLOSED',
                                         'CLOSED FOR INVOICE'),
                                      'OPEN',
                                          DECODE (
                                             DECODE(sign ((( POLL.quantity - nvl(POLL.quantity_cancelled,0) )
                                                     * ( 1 - nvl(POLL.receive_close_tolerance,
                                                     nvl(POSP.receive_close_tolerance,0))/100 ))
                                                     - decode(POSP.receive_close_code,
                                                     'ACCEPTED',
                                                     nvl(POLL.quantity_accepted,0),
                                                     'DELIVERED',
                                                     sum(nvl(POD.quantity_delivered,0)),
                                                     nvl(POLL.quantity_received,0))),
                                                     1,
                                                     'OPEN',
                                                     'CLOSED FOR RECEIVING'),
                                          'CLOSED FOR RECEIVING',
                                          'CLOSED FOR RECEIVING',
                                          'OPEN') ) )
                              FROM   PO_DISTRIBUTIONS_ALL POD,
                                     PO_SYSTEM_PARAMETERS/*_ALL*/ POSP /* ETANCHEITE DALKIA 2007 */
                              WHERE  POLL.po_line_id = pn_line_id
                              AND    nvl(POLL.closed_code, 'OPEN')not in ('FINALLY CLOSED')
                              AND    POD.line_location_id = POLL.line_location_id
                              /* ETANCHEITE DALKIA 2007 */
                              --AND    pod.org_id = gn_org_id
                              GROUP BY   POLL.quantity,
                                         POLL.quantity_cancelled,
                                         POLL.quantity_billed,
                                         POLL.quantity_accepted,
                                         POLL.quantity_received,
                                         POLL.invoice_close_tolerance,
                                         POLL.receive_close_tolerance,
                                         POSP.receive_close_code,
                                         POSP.receive_close_tolerance,
                                         POSP.invoice_close_tolerance )
        WHERE  POLL.po_line_id = pn_line_id
        AND    POLL.po_release_id IS NULL
        AND    nvl(POLL.closed_code, 'OPEN') not in ('FINALLY CLOSED')
        AND    poll.last_update_date > nvl(POLL.closed_date,poll.last_update_date-1)
        /* ETANCHEITE DALKIA 2007 */
        --AND    poll.org_id = gn_org_id
        ;


        UPDATE PO_LINE_LOCATIONS_ALL POLL
        SET    CLOSED_DATE = decode(POLL.closed_code,'CLOSED',sysdate,null),
               CLOSED_REASON = decode(POLL.closed_code,'CLOSED','Annulation ligne de frais de port',null),
               CLOSED_BY = decode(POLL.closed_code,'OPEN', null,fnd_global.user_id)
        WHERE  POLL.po_line_id = pn_line_id
        AND POLL.po_release_id IS NULL
        AND POLL.closed_date is null
        AND    nvl(POLL.closed_code, 'OPEN') in ('CLOSED','OPEN','CLOSED FOR INVOICING', 'CLOSED FOR RECEIVING' )
        /* ETANCHEITE DALKIA 2007 */
        --AND    poll.org_id = gn_org_id
        ;


        UPDATE PO_LINES_ALL POL
        SET    POL.closed_code='CLOSED',
               POL.last_update_date=sysdate ,
               POL.last_updated_by=fnd_global.user_id,
               POL.last_update_login=fnd_global.login_id,
               POL.closed_by= fnd_global.user_id,
               POL.closed_date=SYSDATE,
               POL.closed_reason= 'Annulation ligne de frais de port'
        where ((POL.po_line_id=pn_line_id and nvl(POL.closed_code,'OPEN')<> 'CLOSED')
        and    nvl(POL.closed_code,'OPEN')<>'FINALLY CLOSED')
        /* ETANCHEITE DALKIA 2007 */
        --AND    pol.org_id = gn_org_id
        ;

EXCEPTION
         WHEN OTHERS
         THEN
              Vv_Message := SUBSTR(SQLERRM,1,80);
              dbms_output.put_line ('Erreur lors de l annulation: ' || Vv_Message);
              
              RETURN;

END Annuler_ligne;

---------------------------------------------------------------------------------------------------------------
--  Nom           : Supprimer_ligne
--  Description   : Procédure qui supprime une ligne de frais de port
--
--  PARAMETRES    :pn_header_id              Entrée
--                 pn_line_id                Entrée
--
--                 pv_errbuf                 Entrée/Sortie    message d'erreur
--                 pn_retcode                Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------

PROCEDURE Supprimer_ligne(
        pn_header_id                IN  NUMBER,
        pn_line_id                  IN  NUMBER,
        pv_errbuf                   OUT VARCHAR2,
        pn_retcode                  OUT NUMBER)

IS
  /*JJA - 24/04/2013*/
  vn_req_header_id PO_REQUISITION_LINES_ALL.requisition_header_id%TYPE;
  vn_req_line_id   PO_REQUISITION_LINES_ALL.requisition_line_id%TYPE;
  vv_return_code   VARCHAR2(500);
  /*JJA - 24/04/2013*/
BEGIN

       dbms_output.put_line ('---> Supprimer ligne(s) de frais de port');

       pn_retcode := 0;
       pv_errbuf := NULL;

       -- Suppression dans PO_DISTRIBUTIONS_ALL
       DELETE PO_DISTRIBUTIONS_ALL
       WHERE  po_header_id = pn_header_id
       AND    line_location_id IN (SELECT line_location_id
                                   FROM PO_LINE_LOCATIONS_ALL
                                   WHERE po_header_id = pn_header_id
                                   AND   po_line_id = pn_line_id
                                   /* ETANCHEITE DALKIA 2007 */
                                   --AND   org_id = gn_org_id
                                   );

       /*JJA - 24/04/2013*/
       BEGIN
         SELECT
          requisition_header_id,
          requisition_line_id
         INTO
          vn_req_header_id,
          vn_req_line_id
         FROM PO_REQUISITION_LINES_ALL
         WHERE line_location_id IN (SELECT line_location_id
                                     FROM PO_LINE_LOCATIONS_ALL
                                     WHERE po_header_id = pn_header_id
                                     AND   po_line_id = pn_line_id
                                     --AND   org_id = gn_org_id
                                     );



         po_reqs_control_sv.update_reqs_status(
                   X_req_header_id => vn_req_header_id,
                   X_req_line_id => vn_req_line_id,
                   X_agent_id => NULL,
                   X_req_doc_type => 'PURCHASE',
                   X_req_doc_subtype => NULL,
                   X_req_control_action => 'CANCEL',
                   X_req_control_reason => 'Annulation : Frais de port',
                   X_req_action_date => SYSDATE,
                   X_encumbrance_flag => NULL,
                   X_oe_installed_flag => NULL,
                   X_req_control_error_rc => vv_return_code);

       EXCEPTION
        WHEN NO_DATA_FOUND THEN
         dbms_output.put_line ('Pas de ligne de DA');
        WHEN OTHERS THEN
         dbms_output.put_line ('Erreur lors de l''annulation de la ligne de DA: ' || vv_return_code);
         RAISE;
       END;
       /*JJA - 24/04/2013*/

       -- MISE A JOUR pour liberer la ligne de demande d'achat
       UPDATE PO_REQUISITION_LINES_ALL
       SET    LINE_LOCATION_ID = NULL,
              REQS_IN_POOL_FLAG = 'Y'
       WHERE  requisition_line_id = vn_req_line_id --JJA 24/05/2013
            /*line_location_id IN (SELECT line_location_id
                                   FROM PO_LINE_LOCATIONS_ALL
                                   WHERE po_header_id = pn_header_id
                                   AND   po_line_id = pn_line_id
                                   \* ETANCHEITE DALKIA 2007 *\
                                   AND   org_id = gn_org_id)*/;

      -- Suppression dans PO_LINE_LOCATIONS_ALL
      DELETE  PO_LINE_LOCATIONS_ALL
      WHERE   po_header_id = pn_header_id
      AND     po_line_id = pn_line_id
      /* ETANCHEITE DALKIA 2007 */
      --AND   org_id = gn_org_id
      ;


      -- Suppression dans PO_LINES_ALL
      DELETE  PO_LINES_ALL
      WHERE   po_header_id = pn_header_id
      AND     po_line_id = pn_line_id
      /* ETANCHEITE DALKIA 2007 */
      --AND   org_id = gn_org_id
      ;



EXCEPTION
         WHEN OTHERS
         THEN
              dbms_output.put_line ('Erreur lors la suppresion: ' || SQLERRM(SQLCODE));
              pv_errbuf := 'Erreur lors la suppresion: ';
              pn_retcode := 2;
              RETURN;

END Supprimer_ligne;

END DKA_SPOFRAIS_PORT_PKG;
/
show err;
exit
