CREATE OR REPLACE PACKAGE BODY DKA_SPOREPCOMCONT_PKG AS
-- -----------------------------------------------------------------------------
-- $$
-- Capgemini
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_SPOREPCOMCONT_PKG.pkb
-- DESCRIPTION      : DKA_SPOREPCOMCONT_PKG Package Body
--
-- AUTEUR           : A.DELTOUR (Capgemini)
-- DATE DE CREATION : 28/08/2007
-- COMMENTAIRES     : A exécuter sous SQLPLUS avec le user apps
-- -----------------------------------------------------------------------------
--
-- -----------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------
-- 12/10/2007 ADR Ajout de la quantite facturee.

-- 26/02/2007 SRO Correction quantité commandée et facturée
-- 26/02/2008 ADR Mise en place compteur Vn_count_batch pour gérer la problématique
--                de reprise de commande où le contrat n'existe pas
-- 26/02/2008 ADR Correction de recherche de l'organisation du demandeur
-- 28/02/2008 SRO Correction mise à jour des quantité facturées de la ligne d'imputation de la commande
--                dans les tables standard de commande car cette fonctionnalité n'est pas
--                supportée par le standard d'Open Interface et doit être fait après insertion 
-- 10/03/2008 SRO Correction mise à jour des quantité facturées de la ligne de livraison de la commande
--                en plus des quantité facturées de la ligne d'imputation de la commande
--                + maj de la qté commandée en ligne de commande
-- 19/03/2008 CDE Ajout réception automatique des commandes reprises
-- 03/02/2009 CDE Evolution EID20090030 - gestion multi lieux de livraison
-- 15/04/2009 CDE Evolution EID20090113 - Modification de l'annee de réference de la commande annuelle +
--                positionnement du CUF "ENVOI_AUTO_CDE" (attribute6) à "NON"
-- 02/03/2010 CDE Evolution EID20090323 - Changement de gestion du type de dépense
--                Evolution EID20090220 - Alimentation des champs commande_id et attribute3
-- 18/10/2010 CDE EID20100185 - Adaptation pour déploiement sur VP
-- 15/02/2018 RBE artf2376255 : SPE119 - Correction de la sélection Employés
-- 04/09/2018 RBE artf3025989 : INC0243936 - SPE119 - Problème recherche gestionnaire contrat SSTR
-- -----------------------------------------------------------------------------
--
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--
  gv_user_id          NUMBER := fnd_global.user_id;
  gv_login_id         NUMBER := fnd_global.login_id;
  gv_status_code      VARCHAR2(15) := 'PENDING';
  gv_source_code      VARCHAR2(15) := 'VENDOR';
  gv_transaction_new  VARCHAR2(15) := 'NEW';
  gv_transaction_type VARCHAR2(15) := 'RECEIVE';
  gv_mode_code        VARCHAR2(15) := 'BATCH';
  gv_auto_transact    VARCHAR2(15) := 'DELIVER';

---------------------------------------------------------------------------------------------------------------
--  Nom           : insert_rcv_headers
--  Description   : Procédure d'insertion d'une ligne dans l'interface des entêtes
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

PROCEDURE insert_rcv_headers(pn_vendor_id      IN NUMBER,
                             pn_vendor_site_id IN NUMBER,
                             pv_errbuf         OUT VARCHAR2,
                             pn_retcode        IN OUT NUMBER)
  
IS
  
BEGIN
  
    -- Insertion d'une ligne dans la table RCV_HEADERS_INTERFACE 
    INSERT INTO rcv_headers_interface
      (header_interface_id,
       group_id,
       processing_status_code,
       receipt_source_code,
       transaction_type,
       vendor_id,
       vendor_site_id,
       validation_flag,
       creation_date,
       created_by,
       last_update_date,
       last_updated_by,
       last_update_login,
       expected_receipt_date)
    VALUES
      (rcv_headers_interface_s.NEXTVAL,
       rcv_interface_groups_s.NEXTVAL,
       gv_status_code,
       gv_source_code,
       gv_transaction_new,
       pn_vendor_id, -- vendor_id
       pn_vendor_site_id, -- vendor_site_id
       'Y',
       SYSDATE,
       gv_user_id,
       SYSDATE,
       gv_user_id,
       gv_login_id,
       SYSDATE);
  
EXCEPTION
    WHEN OTHERS THEN
      Dka_Tools_Pkg.put_outdebug_message('Erreur lors de l insertion rcv_headers_interface : ' || SQLERRM(SQLCODE));
      pv_errbuf  := 'DKA_IPOREPCOMCONT.insert_rcv_headers' || SQLERRM;
      pn_retcode := 1;
END insert_rcv_headers;


---------------------------------------------------------------------------------------------------------------
--  Nom           : insert_rcv_transactions
--  Description   : Procédure d'insertion d'une ligne dans l'interface des lignes de réception
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

PROCEDURE insert_rcv_transactions(pn_quantity                IN NUMBER,
                                  pv_uom                     IN VARCHAR2,
                                  pv_description             IN VARCHAR2,
                                  pn_vendor_id               IN NUMBER,
                                  pn_vendor_site_id          IN NUMBER,
                                  pn_header_id               IN NUMBER,
                                  pn_line_id                 IN NUMBER,
                                  pn_line_location_id        IN NUMBER,
                                  pn_ship_to_organization_id IN NUMBER,
                                  pn_ship_to_location_id     IN NUMBER,
                                  pv_errbuf                  OUT VARCHAR2,
                                  pn_retcode                 IN OUT NUMBER)
  
IS
  
BEGIN
  
    -- Insertion d'une ligne dans la table RCV_TRANSACTIONS_INTERFACE 
    INSERT INTO rcv_transactions_interface
      (interface_transaction_id,
       group_id,
       transaction_type,
       transaction_date,
       processing_status_code,
       processing_mode_code,
       transaction_status_code,
       quantity,
       unit_of_measure,
       item_description,
       auto_transact_code,
       receipt_source_code,
       vendor_id,
       vendor_site_id,
       source_document_code,
       po_header_id,
       po_line_id,
       po_line_location_id,
       header_interface_id,
       validation_flag,
       ship_to_location_id,
       to_organization_id,
       deliver_to_location_id,
       creation_date,
       created_by,
       last_update_date,
       last_updated_by,
       last_update_login,
       expected_receipt_date)
    VALUES
      (rcv_transactions_interface_s.NEXTVAL,
       rcv_interface_groups_s.CURRVAL,
       gv_transaction_type,
       SYSDATE,
       gv_status_code,
       gv_mode_code,
       gv_status_code,
       pn_quantity,
       pv_uom,
       pv_description,
       gv_auto_transact,
       gv_source_code,
       pn_vendor_id,
       pn_vendor_site_id,
       'PO',
       pn_header_id,
       pn_line_id,
       pn_line_location_id,
       rcv_headers_interface_s.CURRVAL,
       'Y',
       pn_ship_to_location_id,
       pn_ship_to_organization_id,
       pn_ship_to_location_id,
       SYSDATE,
       gv_user_id,
       SYSDATE,
       gv_user_id,
       gv_login_id,
       SYSDATE);
  
EXCEPTION
    WHEN OTHERS THEN
      Dka_Tools_Pkg.put_outdebug_message('Erreur lors de l insertion rcv_transaction_interface : ' || SQLERRM(SQLCODE));
      pn_retcode := 1;
      pv_errbuf  := 'DKA_SPORECOMCONT.insert_rcv_transactions' ||
                    SQLERRM;
END insert_rcv_transactions;


--------------------------------------------------------------------------------------------------------------
--  Nom           : reception_commandes
--  Description   : Reception automatique des commandes reprises
--
--  PARAMETRES    :
--  pv_errbuf                 Entrée/Sortie      message d'erreur
--  pn_retcode                Entree/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
--  VALEUR RETOURNEE :
--     N/A
--     Description       :
--     Valeurs possibles :
---------------------------------------------------------------------------------------------------------------

PROCEDURE reception_commandes
       (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   IN OUT   NUMBER
        )
IS

     Vb_Trash                      BOOLEAN;
     Vv_Phase                      VARCHAR2(50);
     Vv_Status                     VARCHAR2(50);
     Vv_Dev_Phase                  VARCHAR2(50);
     Vv_Dev_Status                 VARCHAR2(50);
     Vv_Message                    VARCHAR2(50);
     vn_request_id                 NUMBER;
     vn_nbre_a_receptionner        NUMBER;
     vn_nbre_reception_ok          NUMBER;
     vn_nbre_reception_ko          NUMBER;

     CURSOR cur_commandes
     IS
       SELECT distinct ph.po_header_id
            , phi.document_num
            , ph.vendor_id 
            , ph.vendor_site_id 
            , pll.quantity 
            , pl.unit_meas_lookup_code uom
            , pl.item_description description
            , pl.po_line_id 
            , pll.ship_to_organization_id 
            , pll.ship_to_location_id 
            , pll.line_location_id
       FROM   dka_po_com_cont_tmp dpc
            , po_headers_interface phi
            , po_headers ph
            , po_lines pl
            , po_line_locations pll
       WHERE dpc.po_header_id = phi.interface_header_id
       AND   ph.segment1 = phi.document_num
       AND   ph.po_header_id = pl.po_header_id
       AND   pl.po_line_id = pll.po_line_id
       AND   ph.authorization_status = 'APPROVED'
       AND   NOT EXISTS (SELECT 'x'
                        FROM rcv_shipment_lines
                        WHERE po_header_id = ph.po_header_id);

     rec_commandes          cur_commandes%ROWTYPE;
     
     CURSOR cur_rejet_OI (pn_request_id NUMBER)
     IS
       SELECT pha.segment1
            , pie.error_message
       FROM   po_interface_errors pie
            , rcv_transactions_interface rti
            , po_headers_all pha
       WHERE pie.table_name = 'RCV_HEADERS_INTERFACE'
       AND   rti.interface_transaction_id = pie.interface_transaction_id
       AND   pha.po_header_id = rti.po_header_id
       AND   pie.request_id = pn_request_id;

     rec_rejet_OI          cur_rejet_OI%ROWTYPE;

 
BEGIN

        Dka_Tools_Pkg.put_debug_message(' **** BEBUT RECEPTION DES COMMANDES ***');
        -- Initialisation variables
        vn_nbre_a_receptionner := 0;
        vn_nbre_reception_ok := 0;
        vn_nbre_reception_ko := 0;

        -- Insertion des commandes dans l'open interface
        OPEN cur_commandes;
        LOOP
            FETCH cur_commandes INTO rec_commandes;
            EXIT WHEN cur_commandes%NOTFOUND;

        
            -- Interface reception : Insertion entêtes
            insert_rcv_headers(rec_commandes.vendor_id,
                               rec_commandes.vendor_site_id,
                               pv_errbuf,
                               pn_retcode);
  
            IF pn_retcode != 0
            THEN
               RETURN;
            END IF;
  
            -- Interface reception : Insertion lignes
            insert_rcv_transactions(rec_commandes.quantity,
                                    rec_commandes.uom,
                                    rec_commandes.description,
                                    rec_commandes.vendor_id,
                                    rec_commandes.vendor_site_id,
                                    rec_commandes.po_header_id,
                                    rec_commandes.po_line_id,
                                    rec_commandes.line_location_id,
                                    rec_commandes.ship_to_organization_id,
                                    rec_commandes.ship_to_location_id,
                                    pv_errbuf,
                                    pn_retcode);
  
            IF pn_retcode != 0
            THEN
               RETURN;
            END IF;
            
            vn_nbre_a_receptionner := vn_nbre_a_receptionner + 1;

        END LOOP;   
        COMMIT;
        CLOSE cur_commandes;


        dka_tools_pkg.put_debug_message ('<<<< LANCEMENT DE L''INTERFACE STANDARD RVCTP >>>>');
        Vn_Request_Id   := Fnd_Request.Submit_Request (
                                   'PO'	          -- APPLICATION SHORT NAME
                                 , 'RVCTP'        -- CONCURRENT PROGRAM NAME
                                 , NULL            -- DESCRIPTION
                                 , NULL            -- START
                                 , FALSE           -- SUB_REQUEST
    			 				                                 -- ARGUMENTS
                                 ,'BATCH'          -- mode
                                 , NULL            -- batch_id
                              );


                              -- Validation pour soumettre le traitement
                              COMMIT;

        IF Vn_Request_Id = 0
        THEN
               pv_errbuf := '!!!! Erreur lors de la soumission du programme d''import des réceptions. ';
               dka_tools_pkg.put_outdebug_message (Pv_errbuf);
               dka_tools_pkg.put_outdebug_message (Fnd_Message.Get);
               -- Sortie en erreur
               pn_Retcode := 2;
        END IF;

        -- Attente de la fin d'execution du programme standard
        vb_trash := fnd_concurrent.wait_for_request(vn_request_id, -- REQUEST_ID
                                                10, -- INTERVAL
                                                0, -- MAX_WAIT (pas de delai)
                                                vv_phase, -- PHASE
                                                vv_status, -- STATUS
                                                vv_dev_phase, -- DEV_PHASE
                                                vv_dev_status, -- DEV_STATUS
                                                vv_message -- MESSAGE
                                                );
  
        IF NOT vb_trash
        THEN
            pv_errbuf := pv_errbuf || 'Pb dans l'' attente du traitement RCVTP';
        END IF;
  
        IF vv_status = 'Erreur'
        THEN
            pv_errbuf := pv_errbuf || vv_message;
        END IF;

        SELECT count(distinct rti.po_header_id)
        INTO   vn_nbre_reception_ko
        FROM   po_interface_errors pie
             , rcv_transactions_interface rti
        WHERE  rti.interface_transaction_id = pie.interface_transaction_id
        AND    pie.request_id = vn_request_id;
        
        vn_nbre_reception_ok := vn_nbre_a_receptionner - vn_nbre_reception_ko;

        Dka_Tools_Pkg.put_outdebug_message(' ');
        Dka_Tools_Pkg.put_outdebug_message('Nombre de commandes à receptionner........................: ' ||  vn_nbre_a_receptionner);
        Dka_Tools_Pkg.put_outdebug_message('Nombre de commandes receptionnées.........................: ' ||  vn_nbre_reception_ok);
        Dka_Tools_Pkg.put_outdebug_message('Nombre de receptions en erreur............................: ' ||  vn_nbre_reception_ko);
        Dka_Tools_Pkg.put_outdebug_message(' ');

        -- Liste des rejets
        OPEN cur_rejet_OI(vn_request_id);
        LOOP
              FETCH cur_rejet_OI INTO rec_rejet_OI;
              EXIT WHEN cur_rejet_OI%NOTFOUND;
              
              Dka_Tools_Pkg.put_outdebug_message('  => Commande '||rec_rejet_OI.segment1||' non receptionnée pour motif : '||rec_rejet_OI.error_message);

        END LOOP;
        CLOSE cur_rejet_OI;

        Dka_Tools_Pkg.put_debug_message(' **** FIN RECEPTION DES COMMANDES ***');


EXCEPTION
    WHEN OTHERS
    THEN
          pv_errbuf     := 'sortie de reception_commandes avec erreur EXCEPTION OTHERS:' || SQLERRM;
          pn_retcode    := 2;
END reception_commandes;




-- -----------------------------------------------------------------------------
-- Nom              : main
-- Description      : Procédure principale du traitement qui enchaîne l'ensemble
--                    des autres procédures.
--
-- PARAMETRES       : Pv_Errbuf         Sortie Message d'erreur
--                    Pn_Retcode        Sortie Code Retour de la procédure
--                                           '0' : Normal
--                                           '1' : Avertissement
--                                           '2' : Erreur
--
-- VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles :
-- -----------------------------------------------------------------------------
PROCEDURE Main(Pv_Errbuf  OUT NOCOPY VARCHAR2,
               Pn_Retcode OUT NOCOPY NUMBER
              )
IS

Vn_count                            NUMBER         := 0;
-- ADR le 26/02/2008
Vn_count_batch                      NUMBER         := 0;
Vn_batch_id                         NUMBER         := NULL;
Vn_total_rec                        NUMBER         := 0;
Vn_erreur_bis                       NUMBER         := 0;
Vn_inserted                         NUMBER         := 0;
Vn_new                              NUMBER         := 0;
Vn_total_commande                   NUMBER         := 0;
Vn_interface_headers                NUMBER         := 0;
Vn_interface_lines                  NUMBER         := 0;
Vn_interface_distributions          NUMBER         := 0;
Vn_rejected                         NUMBER         := 0;
Vn_accepted                         NUMBER         := 0;
Vn_request_id                       NUMBER;
Vb_return                           BOOLEAN;
Vb_result                           BOOLEAN;
Vv_phase                            VARCHAR2(30);
Vv_status                           VARCHAR2(30);
Vv_dev_phase                        VARCHAR2(30);
Vv_dev_status                       VARCHAR2(30);
Vv_message                          VARCHAR2(1000);
i                                   INTEGER        := 0;
Vn_preparer_id                      NUMBER         := 0;
--------------------------------------------
-- Curseur de lecture de la table temporaire
--------------------------------------------
CURSOR C_TMP
IS  SELECT tmp.ref_commande,
           tmp.description,
           tmp.ref_contrat_parent,
           tmp.description_contrat,
           tmp.num_fournisseur,
           tmp.site_code,
           -- CDE 030209 tmp.ship_to,
           tmp.bill_to,
           tmp.nature_prestation,
           tmp.acheteur,
           tmp.matricule,
           tmp.montant_commande,
           tmp.type_depense,
           COUNT(*) nb_lignes
    FROM   DKA_PO_COM_CONT_TMP tmp
    WHERE  ROW_STATUS = 'N'
    GROUP BY
           tmp.ref_commande,
           tmp.description,
           tmp.ref_contrat_parent,
           tmp.description_contrat,
           tmp.num_fournisseur,
           tmp.site_code,
           -- CDE 030209 tmp.ship_to,
           tmp.bill_to,
           tmp.nature_prestation,
           tmp.acheteur,
           tmp.matricule,
           tmp.montant_commande,
           tmp.type_depense
    ORDER BY tmp.ref_commande ASC;

--------------------------------------------
-- Curseur de lecture des lignes d'imputations
--------------------------------------------
CURSOR C_TMP_2 ( p_ref_commande VARCHAR2 )
IS  SELECT ROWID,tmp.*
    FROM   DKA_PO_COM_CONT_TMP tmp
    WHERE  ROW_STATUS = 'N'
    AND    tmp.ref_commande = p_ref_commande
    ORDER BY ref_commande, projet ASC;

rec_tmp_2 c_tmp_2%ROWTYPE;

BEGIN
  Dka_Tools_Pkg.Put_Debug_Message('Start - Main (+)');

  ----------------------------------
  -- initialisation des variables --
  ----------------------------------

  -- SRO le 10/03/08
  -- Réinitialisation de la table dka_po_com_cont_qty_billed_tmp
  DELETE FROM dka_po_com_cont_qty_billed_tmp;
  
  Dka_Tools_Pkg.Put_Outdebug_Message(' ');
  Dka_Tools_Pkg.Put_Outdebug_Message('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
  Dka_Tools_Pkg.Put_Outdebug_Message('=> Execution du traitement d''alimentation de l''OI des commandes de contrat');
  Dka_Tools_Pkg.Put_Outdebug_Message('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
  BEGIN
    SELECT fu.employee_id
    INTO   Vn_preparer_id
    FROM   FND_USER fu
    WHERE  fu.user_id = gv_user_id;--fu.user_name = 'SOFTAPACK'; --RBE MigR12
  EXCEPTION WHEN NO_DATA_FOUND THEN
    Dka_Tools_Pkg.Put_Debug_Message('=> Init: L''approbateur n''est pas défini. Aucune donnée ne peut être traitée');
    Pn_Retcode := 2;
    RETURN;
  END;
  ---------------------------------------------------------------------------------
  -- Phase 1 : Identification des commandes de contrat en doublons               --
  -- Principe:                                                                   --
  ---------------------------------------------------------------------------------
  Dka_Tools_Pkg.Put_Debug_Message(' ');
  Dka_Tools_Pkg.Put_Debug_Message('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
  Dka_Tools_Pkg.Put_Debug_Message('=> Phase 1 : Identification des doublons');

  UPDATE dka_po_com_cont_tmp t
  SET    t.ROW_STATUS = 'R'
  WHERE (t.REF_COMMANDE) IN (SELECT tmp.ref_commande
                                   FROM ( SELECT REF_COMMANDE,SHIP_TO,PROJET, COUNT(1)
                                          FROM dka_po_com_cont_tmp
                                          GROUP BY REF_COMMANDE,SHIP_TO,PROJET
                                          HAVING COUNT(1) > 1
                                         )tmp
                                  );
  IF SQL%ROWCOUNT != 0 THEN
    Dka_Tools_Pkg.Put_Debug_Message(' !!! Présence de commande de contrat en doublon.');
  END IF;
  COMMIT;
  Dka_Tools_Pkg.Put_Debug_Message('=> Statut OK');

  FOR REC_TMP IN C_TMP
  LOOP
    Dka_Tools_Pkg.Put_Debug_Message(' ');
    Dka_Tools_Pkg.Put_Debug_Message('Commande - référence = ' || rec_tmp.ref_commande);

    gt_distribution_tab.DELETE;
    i := 0;

    DECLARE
      Vb_is_null                          BOOLEAN                           := FALSE;
      Vv_column_name                      VARCHAR2(4000)                    := NULL;
      Vb_no_data_found                    BOOLEAN                           := FALSE;
      Vb_error                            BOOLEAN                           := FALSE;
      Vb_reject                           BOOLEAN                           := FALSE;
      Vv_segment1                         PO_HEADERS_ALL.SEGMENT1%TYPE      := NULL;
      Vn_header_id                        PO_HEADERS_ALL.PO_HEADER_ID%TYPE  := NULL;
      Vn_line_id                          PO_LINES_ALL.PO_LINE_ID%TYPE      := NULL;
      Vn_distribution_id                  PO_DISTRIBUTIONS_ALL.PO_DISTRIBUTION_ID%TYPE := NULL;
      Vv_expenditure_type                 Pa_Expenditure_Types.Expenditure_Type%TYPE := NULL;
      Vv_status                           PA_PROJECTS_ALL.PROJECT_STATUS_CODE%TYPE := NULL;
      Vn_project_id                       PA_PROJECTS_ALL.PROJECT_ID%TYPE   := NULL;
      Vn_nbr_entete                       NUMBER                            := 0;
      Vn_exist                            NUMBER                            := NULL;
      Vr_header                           PO_HEADERS_ALL%ROWTYPE;
      Vn_task_id                          PA_TASKS.TASK_ID%TYPE             := NULL;
      Vv_organization_signataire          HR_ALL_ORGANIZATION_UNITS.NAME%TYPE := NULL;
      Vn_org_id_signataire                HR_ALL_ORGANIZATION_UNITS.ORGANIZATION_ID%TYPE := NULL;
      Vn_uo                               DKA_CONTRAT_SSTR_IMPUTATION.UNITE_OEUVRE%TYPE := NULL;
      Vn_total_uo                         DKA_CONTRAT_SSTR_IMPUTATION.UNITE_OEUVRE%TYPE := NULL;
      Vn_contrat_imputation_id            DKA_CONTRAT_SSTR_IMPUTATION.CONTRAT_IMPUTATION_ID%TYPE := NULL;  
      Vn_qty_ordered                      NUMBER := 0;
      Vn_qty_billed                       NUMBER := 0; -- ADR le 11/12/2207
      E_check_failed                      EXCEPTION;
      E_not_inserted                      EXCEPTION;
      Vn_ship_num                         NUMBER := 0;
      Vn_ship_to_location_id              HR_LOCATIONS_ALL.LOCATION_ID%TYPE := NULL;

    BEGIN

      SAVEPOINT SV1;
      ------------------------------------------------------------------------
      -- Verification que toutes les informations destinées à l'entête du   --
      -- contrat sont identiques sur chaque lignes d'imputation             --
      ------------------------------------------------------------------------
      IF rec_tmp.ref_commande IS NOT NULL THEN
        SELECT COUNT(t.ref_commande)
        INTO   Vn_nbr_entete
        FROM   DKA_PO_COM_CONT_TMP t
        WHERE  t.ref_commande = rec_tmp.ref_commande
        GROUP BY t.ref_commande;
      ELSE
        Dka_Tools_Pkg.Put_Debug_Message('=> ERREUR : La référence de la commande n''est pas renseignée');
        RAISE E_not_inserted;
      END IF;

      IF rec_tmp.nb_lignes != Vn_nbr_entete THEN
        Dka_Tools_Pkg.Put_Debug_Message('=> Vérifier les informations d''entête/lignes (' || Vn_nbr_entete || '/' || rec_tmp.nb_lignes || ')' );
        RAISE E_not_inserted;
      ELSE
        Dka_Tools_Pkg.Put_Debug_Message('=> Entêtes de ligne correctes (' || Vn_nbr_entete || '/' || rec_tmp.nb_lignes || ')' );
        ----------------------------------------------------------------------
        -- Recherche du contrat parent                                      --
        ----------------------------------------------------------------------
        BEGIN
          IF rec_tmp.ref_contrat_parent IS NOT NULL THEN
            SELECT pha.*
            INTO   Vr_header
            FROM   PO_HEADERS_ALL pha,
                   DKA_CONTRAT_SSTR dcs
            WHERE  dcs.description_specifique_contrat = rec_tmp.ref_contrat_parent || '-' || rec_tmp.description_contrat
            AND    pha.po_header_id = dcs.po_header_id
            AND    pha.attribute4 IN ('CONTRAT SOUS-TRAITANCE','CONTRAT DEPENDANT')
            AND    pha.type_lookup_code = 'CONTRACT'
            AND    pha.approved_flag = 'Y'
            AND    pha.org_id = gn_org_id
            AND    dcs.org_id = gn_org_id;
          ELSE
            Dka_Tools_Pkg.Put_Debug_Message('=> ERREUR : La référence du contrat parent n''est pas renseignée');
            RAISE E_not_inserted;
          END IF;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            Dka_Tools_Pkg.Put_Debug_Message('=> ERREUR : Contrat parent ' || rec_tmp.ref_contrat_parent || '-' || rec_tmp.description_contrat  || ' introuvable');
            RAISE E_not_inserted;
          WHEN TOO_MANY_ROWS THEN
            Dka_Tools_Pkg.Put_Debug_Message('=> ERREUR : Plus d''un contrat parent trouvé ' || rec_tmp.ref_contrat_parent || '-' || rec_tmp.description_contrat);
            RAISE E_not_inserted;
          WHEN OTHERS THEN
            Dka_Tools_Pkg.Put_Debug_Message('=> ERREUR : Contrat parent ' || rec_tmp.ref_contrat_parent || '-' || rec_tmp.description_contrat );
            RAISE E_not_inserted;
        END;
        ----------------------------------------------------------------------
        -- On vérifie que la commande n' a pas déja été importée.           --
        ----------------------------------------------------------------------
        -- CDE 150409 Vv_segment1 := Vr_header.segment1 || 'ST' || TO_CHAR(SYSDATE,'RRRR');
        -- CDE 181010 Vv_segment1 := Vr_header.segment1 || 'ST' || TO_CHAR(Vr_header.start_date,'RRRR');
        Vv_segment1 := Vr_header.segment1 || 'ST' || TO_CHAR(Vr_header.start_date,'YYMM');

        SELECT COUNT(1)
        INTO   Vn_exist
        FROM   PO_HEADERS_ALL pha
        WHERE  pha.type_lookup_code = 'STANDARD'
        AND    pha.segment1 = Vv_segment1
        AND    pha.org_id = gn_org_id;

        IF Vn_exist > 0
        THEN
          Dka_Tools_Pkg.Put_Debug_Message('ERREUR : La commande' || Vv_segment1 || ' a déjà été importée.');
          RAISE E_not_inserted;
        END IF;

        /* CDE 030209 SELECT po_lines_interface_s.NEXTVAL
        INTO   Vn_line_id
        FROM   dual;*/

        SELECT po_headers_interface_s.NEXTVAL
        INTO   Vn_header_id
        FROM   dual;

        -- L'identifiant de la première commande est le batch_id.
        IF Vn_count_batch = 0 THEN
          Vn_batch_id := Vn_header_id;
        END IF;

        -- Traitement des lignes
        OPEN C_TMP_2(rec_tmp.ref_commande);
        LOOP
          FETCH C_TMP_2 INTO rec_tmp_2;
          EXIT WHEN C_TMP_2%NOTFOUND;

          -- Réinitialisation des variables
          Vb_is_null                 := FALSE;
          Vb_no_data_found           := FALSE;
          Vb_error                   := FALSE;
          Vn_distribution_id         := NULL;



          ---------------------------------------------------------------------------------
          -- Phase 2 : Contrôle des colonnes obligatoires                                --
          -- Colonnes : Montant total de la commande                                     --
          --            Projet                                                           --
          ---------------------------------------------------------------------------------
          Dka_Tools_Pkg.Put_Debug_Message('=> Phase 2 : Vérification des champs obligatoires');

          IF rec_tmp_2.montant_commande IS NULL THEN
            vv_column_name := 'Montant de la commande';
            vb_is_null := TRUE;
          END IF;

          IF rec_tmp_2.PROJET IS NULL THEN
            vv_column_name := vv_column_name || CHR(10) ||'Projet d''imputation';
            vb_is_null := TRUE;
          END IF;
          
          IF rec_tmp_2.TACHE IS NULL THEN
            vv_column_name := vv_column_name || CHR(10) ||'Tache d''imputation';
            vb_is_null := TRUE;
          END IF;
          
          IF vb_is_null THEN
            Dka_Tools_Pkg.Put_Debug_Message('Statut : Valeur NULL sur zone obligatoire détectée.' );
            Dka_Tools_Pkg.Put_Debug_Message('Les champs concernés sont:' || CHR(10) || vv_column_name);
          ELSE
            Dka_Tools_Pkg.Put_Debug_Message('=> Statut OK');
          END IF;

          ---------------------------------------------------------------------------------
          -- Phase 3 : Contrôle référentiel                                              --
          -- Colonnes : Identifiant de tache                                             --
          --            Identifiant du projet                                            --
          --            Organisation de dépense et son identifiant                       --                                          
          --            Type de dépense                                                  --
          --            Quantité commandée                                               --
          --            Lieu de livraison                                                --
          ---------------------------------------------------------------------------------
          Dka_Tools_Pkg.Put_Debug_Message('=> Phase 3 : Contrôle référentiel');
          -- Projet
          BEGIN
            IF rec_tmp_2.PROJET IS NOT NULL THEN
                SELECT ppa.project_status_code,
                       ppa.project_id
                INTO   Vv_status,
                       Vn_project_id
                FROM   pa_projects_all ppa
                WHERE  ppa.segment1 = rec_tmp_2.projet
                AND    ppa.org_id = gn_org_id;

                IF Vv_status = 'CLOSED' THEN
                  Vb_error := TRUE;
                  Dka_Tools_Pkg.Put_Debug_Message('=> Statut (3.1): Le projet ' || rec_tmp_2.PROJET || 'est fermé.');
                END IF;
            END IF;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              Vb_no_data_found := TRUE;
              Dka_Tools_Pkg.Put_Debug_Message('=> Statut (3.1): Projet invalide.' || rec_tmp_2.PROJET);
            WHEN OTHERS THEN
              Vb_error := TRUE;
              Dka_Tools_Pkg.Put_Debug_Message('=> Statut (3.1) : ' || SQLERRM);
          END;
          -- Tache
          BEGIN
            IF rec_tmp_2.tache IS NOT NULL THEN
              SELECT task_id
              INTO   Vn_task_id
              FROM   pa_tasks
              WHERE  task_number = rec_tmp_2.tache --RBE
              AND    project_id = Vn_project_id;
            END IF;
            
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              Vb_no_data_found := TRUE;
              Dka_Tools_Pkg.Put_Debug_Message('=> Statut (3.2): Tache ' || rec_tmp_2.tache ||' n''est pas associé au projet ' || rec_tmp_2.projet);
            WHEN OTHERS THEN
              Vb_error := TRUE;
              Dka_Tools_Pkg.Put_Debug_Message('=> Statut (3.2) : ' || SQLERRM);
          END;
            -- Type de dépense
            BEGIN
              IF rec_tmp_2.TYPE_DEPENSE IS NOT NULL THEN
                SELECT pet.expenditure_type
                INTO   Vv_expenditure_type
                FROM   pa_expenditure_types pet,
                       pa_transaction_controls ptc
                WHERE  ptc.expenditure_type = pet.expenditure_type
                AND    NVL(pet.attribute5,'N') = 'Y'
                AND    NVL(pet.attribute3,'N') = 'Y'
                AND    pet.expenditure_type = rec_tmp_2.type_depense
                AND    ptc.project_id = Vn_project_id
                AND    ptc.task_id = Vn_task_id; --RBE
              END IF;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                Vb_no_data_found := TRUE;
                Dka_Tools_Pkg.Put_Debug_Message('=> Statut (3.3): Type de dépense invalide ' || rec_tmp_2.TYPE_DEPENSE ||' pour le projet '||rec_tmp_2.projet );
              WHEN OTHERS THEN
                Vb_error := TRUE;
                Dka_Tools_Pkg.Put_Debug_Message('=> Statut (3.3) : ' || SQLERRM);
            END;
          
          -- Organisation de dépense
          BEGIN
          -- CDE 181010  SELECT hou.NAME,
          -- CDE 181010         hou.organization_id
          -- CDE 181010  INTO   Vv_organization_signataire,
          -- CDE 181010         Vn_org_id_signataire
          -- CDE 181010  FROM   per_all_assignments_f paa,
          -- CDE 181010         hr_organization_units hou
          -- CDE 181010  WHERE hou.organization_id = paa.organization_id
          -- CDE 181010  AND   paa.person_id = Vr_header.agent_id
            -- ADR le 26/02/2008
          -- CDE 181010  AND   trunc(sysdate) between paa.effective_start_date and NVL(paa.effective_end_date,sysdate+1);
         
            --RBE
            /* SELECT hou.NAME,
                    hou.organization_id
             INTO   Vv_organization_signataire,
                    Vn_org_id_signataire
             FROM   --per_all_people_f papf,  -- RBE artf2376255
                    per_people_v7 papf, -- RBE artf2376255
                    hr_organization_units hou
             WHERE  hou.name = papf.attribute1
             AND    papf.person_id = Vr_header.agent_id
             AND    trunc(SYSDATE) BETWEEN papf.effective_start_date AND papf.effective_end_date; */
             
            SELECT hou.NAME,
                   hou.organization_id
            INTO  Vv_organization_signataire, 
                  Vn_org_id_signataire
            FROM  --per_all_people_f papf,  -- RBE artf2376255
                  per_people_f papf, -- RBE artf2376255 --artf3025989
                  per_all_assignments_f paaf, 
                  hr_organization_units hou
            WHERE paaf.person_id = papf.person_id
            AND   papf.person_id = Vr_header.agent_id   
            AND   hou.organization_id = paaf.organization_id       
            AND TRUNC(SYSDATE) BETWEEN TRUNC(papf.effective_start_date) AND NVL(papf.effective_end_date,SYSDATE) --RBE artf3025989
            AND TRUNC(SYSDATE) BETWEEN TRUNC(paaf.effective_start_date) AND paaf.effective_end_date;
       
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              Vb_no_data_found := TRUE;
              Dka_Tools_Pkg.Put_Debug_Message('=> Statut (3.4): Organisation de dépense introuvable pour l''acheteur (identifiant = ' || Vr_header.agent_id || ' )');
            WHEN OTHERS THEN
              Vb_error := TRUE;
              Dka_Tools_Pkg.Put_Debug_Message('=> Statut (3.4) : ' || SQLERRM);
          END;
          -- CDE 030209 Lieu de livraison
          BEGIN
            IF rec_tmp_2.ship_to IS NOT NULL THEN
              SELECT hl.location_id
              INTO   Vn_ship_to_location_id
              FROM   hr_locations hl
              WHERE  hl.ship_to_site_flag = 'Y'
              AND    hl.location_code = rec_tmp_2.ship_to
              ;          
            END IF;        
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              Vb_no_data_found := TRUE;
              Dka_Tools_Pkg.Put_Debug_Message('=> Statut (3.5): Aucun lieu de livraison trouvé pour le lieu ' || rec_tmp_2.ship_to);
            WHEN OTHERS THEN
              Vb_error := TRUE;
              Dka_Tools_Pkg.Put_Debug_Message('=> Statut (3.5) : ' || SQLERRM);
          END;
          -- Quantité commandée
          BEGIN
            IF Vn_project_id IS NOT NULL THEN
              SELECT dcsi.unite_oeuvre,
                     dcsi2.total,
                     dcsi.contrat_imputation_id
              INTO   Vn_uo,
                     Vn_total_uo,
                     Vn_contrat_imputation_id
              FROM   dka_contrat_sstr_imputation dcsi,
                     (SELECT SUM(dcsi.unite_oeuvre) total
                      FROM   dka_contrat_sstr_imputation dcsi
                      WHERE  dcsi.po_header_id = Vr_header.po_header_id) dcsi2
              WHERE  dcsi.po_header_id = Vr_header.po_header_id
              AND    dcsi.project_id = Vn_project_id
              AND    dcsi.location_id = Vn_ship_to_location_id
              AND    dcsi.expenditure_type = Vv_expenditure_type;

              Vn_qty_ordered := ((NVL(Vr_header.blanket_total_amount,0)* Vn_uo) / Vn_total_uo);  -- ADR le 11/12/2007 -- SRO le 26/02/2007
              Vn_qty_billed  := (((NVL(Vr_header.blanket_total_amount,0) - NVL(rec_tmp.montant_commande,0)) * Vn_uo) / Vn_total_uo); -- ADR le 11/12/2007 -- SRO le 26/02/2007

            END IF;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              Vb_no_data_found := TRUE;
              Dka_Tools_Pkg.Put_Debug_Message('=> Statut (3.6): Unité d''oeuvre introuvable (identifiant commande = ' || Vr_header.po_header_id || ' )');
            WHEN OTHERS THEN
              Vb_error := TRUE;
              Dka_Tools_Pkg.Put_Debug_Message('=> Statut (3.6) : UO ' || SQLERRM);
          END;



          IF NOT vb_is_null AND
             NOT Vb_no_data_found AND
             NOT Vb_error THEN
            i := i + 1;

            -- CDE 030209
            SELECT po_lines_interface_s.NEXTVAL 
            INTO   Vn_line_id
            FROM   dual;

            SELECT po_distributions_interface_s.NEXTVAL
            INTO   Vn_distribution_id
            FROM   dual;

            gt_distribution_tab(i).interface_header_id        := Vn_header_id;
            gt_distribution_tab(i).interface_line_id          := Vn_line_id;
            gt_distribution_tab(i).interface_distribution_id  := Vn_distribution_id;
            gt_distribution_tab(i).distribution_num           := 1; -- CDE 030209 i;
            gt_distribution_tab(i).org_id                     := gn_org_id;
            gt_distribution_tab(i).quantity_ordered           := Vn_qty_ordered;
            gt_distribution_tab(i).quantity_billed            := Vn_qty_billed; -- ADR le 12/10/2007;
            gt_distribution_tab(i).destination_type           := 'Charges';
            gt_distribution_tab(i).destination_context        := 'EXPENSE';
            gt_distribution_tab(i).project                    := rec_tmp_2.projet;
            gt_distribution_tab(i).project_id                 := Vn_project_id;
            gt_distribution_tab(i).task                       := rec_tmp_2.tache; --RBE MigR12
            gt_distribution_tab(i).task_id                    := Vn_task_id;
            gt_distribution_tab(i).expenditure_type           := Vv_expenditure_type;
            gt_distribution_tab(i).project_accounting_context := 'Y';
            gt_distribution_tab(i).expenditure_organization   := Vv_organization_signataire;
            gt_distribution_tab(i).expenditure_organization_id:= Vn_org_id_signataire;
            gt_distribution_tab(i).expenditure_item_date      := TRUNC(SYSDATE);
            gt_distribution_tab(i).attribute3                 := Vn_contrat_imputation_id;
            gt_line_tab(i).interface_line_id                  := Vn_line_id;
            gt_line_tab(i).ship_to_location_id                := Vn_ship_to_location_id;
            gt_line_tab(i).quantity                           := Vn_qty_ordered;
            
            
            UPDATE DKA_PO_COM_CONT_TMP
            SET    po_distribution_id =  Vn_distribution_id
            WHERE  ROWID = rec_tmp_2.ROWID;

            Dka_Tools_Pkg.Put_Debug_Message('=> Statut OK');

          ELSE
            -- Mise à jour du statut du contrat
            UPDATE DKA_PO_COM_CONT_TMP
            SET    ROW_STATUS = 'R'
            WHERE  ROWID = rec_tmp_2.ROWID;
            Vb_reject := TRUE;
          END IF;

        END LOOP;
        CLOSE C_TMP_2;

        IF NOT Vb_reject THEN

          ---------------------------------------------------------------------------------
          -- Phase 4 : Alimentation de l'Open interface                                  --
          ---------------------------------------------------------------------------------
          Dka_Tools_Pkg.Put_Debug_Message('=> Phase 4 : Insertion de la commande dans l''OI');
          Dka_Tools_Pkg.Put_Debug_Message('=> Numéro de commande = ' || Vv_segment1);

          INSERT INTO po_headers_interface
          ( interface_header_id,
            batch_id,
            action,
            org_id,
            document_type_code,
            document_num,
            currency_code,
            agent_id,
            vendor_id,
            vendor_site_id,
            ship_to_location_id,
            bill_to_location_id,
            approval_status,
            revision_num,
            comments,
            creation_date,
            created_by,
            last_update_date,
            last_updated_by,
            last_update_login,
            attribute6
          )
          VALUES
          ( Vn_header_id,
            Vn_batch_id,
            'ORIGINAL',
            gn_org_id,
            'STANDARD',
            Vv_segment1,
            'EUR',
            Vr_header.agent_id,
            Vr_header.vendor_id,
            Vr_header.vendor_site_id,
            Vr_header.ship_to_location_id,
            Vr_header.bill_to_location_id,
            'APPROVED',
            0,
            rec_tmp.ref_commande ||'-'|| rec_tmp.description,
            SYSDATE,
            gn_userid,
            SYSDATE,
            gn_userid,
            gn_login_id,
            'NON'
          );

          Dka_Tools_Pkg.Put_Debug_Message('=> Entête OK');

          FOR k IN gt_distribution_tab.FIRST..gt_distribution_tab.LAST
          LOOP
          
          Vn_ship_num := Vn_ship_num + 1;

          INSERT INTO po_lines_interface
          ( interface_line_id,
            interface_header_id,
            line_num,
            shipment_num,
            line_type,
            ship_to_location_id,
            need_by_date,
            ship_to_organization_id,
            category,
            item_description,
            uom_code,
            quantity,
            unit_price,
            last_update_date,
            last_updated_by,
            last_update_login,
            creation_date,
            created_by,
            organization_id
          )
          VALUES
          ( gt_line_tab(k).interface_line_id,
            Vn_header_id,
            1,
            Vn_ship_num,  -- CDE 020309
            'PRESTATION',
            gt_line_tab(k).ship_to_location_id,
            SYSDATE,
            gn_org_id,
            Vr_header.attribute5,
            Vr_header.attribute5,
            'EUR',
            -- SRO 10/03/08 Correction de la quantité commandée 
            -- rec_tmp.montant_commande,
            gt_line_tab(k).quantity,  -- CDE 020309 Vr_header.blanket_total_amount,
            1,
            SYSDATE,
            gn_userid,
            gn_login_id,
            SYSDATE,
            gn_userid,
            gn_org_id);

          Dka_Tools_Pkg.Put_Debug_Message('=> Lignes OK');

          /* CDE 030209 FOR k IN gt_distribution_tab.FIRST..gt_distribution_tab.LAST
          LOOP*/
            INSERT INTO PO_DISTRIBUTIONS_INTERFACE
            ( interface_header_id,
              interface_line_id,
              interface_distribution_id,
              distribution_num,
              org_id,
              quantity_ordered,
              quantity_billed,  -- ADR le 12/10/2007
              destination_type,
              destination_context,
              project,
              project_id,
              task,
              task_id,
              expenditure_type,
              project_accounting_context,
              expenditure_organization,
              expenditure_organization_id,
              expenditure_item_date,
              created_by,
              creation_date,
              last_updated_by,
              last_update_date,
              last_update_login,
              attribute3) -- CDE 020310
            VALUES
            ( gt_distribution_tab(k).interface_header_id,
              gt_distribution_tab(k).interface_line_id,
              gt_distribution_tab(k).interface_distribution_id,
              gt_distribution_tab(k).distribution_num,
              gt_distribution_tab(k).org_id,
              gt_distribution_tab(k).quantity_ordered,
              -- ADR le 12/10/2007
              -- SRO le 28/02/2008 mise à jour de la quantité facturée impossible par Open Interface
              0,--gt_distribution_tab(k).quantity_billed,  
              gt_distribution_tab(k).destination_type,
              gt_distribution_tab(k).destination_context,
              gt_distribution_tab(k).project,
              gt_distribution_tab(k).project_id,
              gt_distribution_tab(k).task,
              gt_distribution_tab(k).task_id,
              gt_distribution_tab(k).expenditure_type,
              gt_distribution_tab(k).project_accounting_context,
              gt_distribution_tab(k).expenditure_organization,
              gt_distribution_tab(k).expenditure_organization_id,
              gt_distribution_tab(k).expenditure_item_date,
              gn_userid,
              SYSDATE,
              gn_userid,
              SYSDATE,
              gn_login_id,
              gt_distribution_tab(k).attribute3
            );
            
            -- SRO le 28/02/2008
            -- Mémorisation des quantités facturées pour mise à jour directement dans les tables d'imputation de commande
            INSERT INTO dka_po_com_cont_qty_billed_tmp
            ( interface_header_id,
              interface_line_id,
              interface_distribution_id,
              distribution_num,
              quantity_billed,
              shipment_num)  -- CDE 030209
            VALUES
            ( gt_distribution_tab(k).interface_header_id,
              gt_distribution_tab(k).interface_line_id,
              gt_distribution_tab(k).interface_distribution_id,
              gt_distribution_tab(k).distribution_num,
              gt_distribution_tab(k).quantity_billed,
              Vn_ship_num);  -- CDE 030209

          END LOOP;
          Dka_Tools_Pkg.Put_Debug_Message('=> Distributions OK');
          -- Mise à jour du statut du contrat
          UPDATE DKA_PO_COM_CONT_TMP
          SET    ROW_STATUS   = 'I',
                 PO_HEADER_ID = Vn_header_id,
                 PO_LINE_ID   = Vn_line_id
          WHERE  ref_commande = rec_tmp.ref_commande;
          -- ADR le 26/02/2008
          Vn_count_batch := Vn_count_batch + 1;
        ELSE
          -- Passage au contrat suivant
          RAISE E_check_failed;
        END IF;
      END IF;
    EXCEPTION
    WHEN E_check_failed THEN
      Dka_Tools_Pkg.Put_Debug_Message('~ ERREUR : Passage au contrat suivant' );
      Dka_Tools_Pkg.Put_Debug_Message('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
      --vn_erreur := vn_erreur + 1;
    WHEN E_not_inserted THEN
      Dka_Tools_Pkg.Put_Debug_Message('~ ERREUR : Passage au contrat suivant' );
      Dka_Tools_Pkg.Put_Debug_Message('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
      --vn_erreur := vn_erreur + 1;
      ROLLBACK TO SV1;
      UPDATE DKA_PO_COM_CONT_TMP
      SET    ROW_STATUS = 'R'
      WHERE  ref_commande = rec_tmp.ref_commande;
    WHEN OTHERS THEN
      Dka_Tools_Pkg.Put_Debug_Message('~ ERREUR NON DEFINIE - ' || SQLERRM );
      Dka_Tools_Pkg.Put_Debug_Message('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
      --vn_erreur := vn_erreur + 1;
      ROLLBACK TO SV1;
      UPDATE DKA_PO_COM_CONT_TMP
      SET    ROW_STATUS = 'R'
      WHERE  ref_commande = rec_tmp.ref_commande;
    END;
    -- ADR le 26/02/2008 
     vn_count := vn_count + 1;

  END LOOP;

  COMMIT;

  ------------------------------------------
  -- Reporting
  ------------------------------------------
  -- Nombre total d'enregistrements
  SELECT (SELECT COUNT(*) FROM DKA_PO_COM_CONT_TMP ),
         (SELECT COUNT(DISTINCT ref_commande) FROM DKA_PO_COM_CONT_TMP),
         (SELECT COUNT(*) FROM DKA_PO_COM_CONT_TMP WHERE ROW_STATUS = 'R'),
         (SELECT COUNT(*) FROM DKA_PO_COM_CONT_TMP WHERE ROW_STATUS = 'I'),
         (SELECT COUNT(*) FROM DKA_PO_COM_CONT_TMP WHERE ROW_STATUS = 'N')
  INTO   Vn_total_rec,
         Vn_total_commande,
         Vn_erreur_bis,
         Vn_inserted,
         Vn_new
  FROM DUAL;

  SELECT COUNT(DISTINCT phi.document_num),
         COUNT(DISTINCT pli.interface_line_id),
         COUNT(pdi.interface_distribution_id)
  INTO   Vn_interface_headers,
         Vn_interface_lines,
         Vn_interface_distributions
  FROM   DKA_PO_COM_CONT_TMP dpct,
         PO_HEADERS_INTERFACE phi,
         PO_LINES_INTERFACE pli,
         PO_DISTRIBUTIONS_INTERFACE pdi
  WHERE phi.interface_header_id  = dpct.po_header_id
  AND   phi.batch_id = Vn_batch_id
  AND   pli.interface_line_id = dpct.po_line_id
  AND   pli.interface_header_id = dpct.po_header_id
  AND   pdi.interface_distribution_id = dpct.po_distribution_id
  AND   pdi.interface_line_id = dpct.po_line_id
  AND   pdi.interface_header_id = dpct.po_header_id;

  ------------------------------------------
  -- Resultat d'import
  ------------------------------------------
  Dka_Tools_Pkg.Put_Debug_Message('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
  Dka_Tools_Pkg.put_outdebug_message('Nombre Total d''enregistrements............................: ' ||  Vn_total_rec);
  Dka_Tools_Pkg.put_outdebug_message('Nombre Total de commande..................................: ' ||  Vn_total_commande);
  Dka_Tools_Pkg.put_outdebug_message('Nombre Total de commande lu...............................: ' ||  Vn_count);
  Dka_Tools_Pkg.put_outdebug_message('Nombre Total de lignes de distribution en erreur..........: ' ||  Vn_erreur_bis);
  Dka_Tools_Pkg.put_outdebug_message('Nombre Total de lignes de distribution insérées ..........: ' ||  Vn_inserted);

  IF Vn_new != 0 THEN
    Dka_Tools_Pkg.put_outdebug_message('Nombre Total d''enregistrements non traités.................: ' || Vn_new);
  END IF;
  Dka_Tools_Pkg.put_outdebug_message(' ');
  Dka_Tools_Pkg.put_outdebug_message('Nombre de commandes dans l''OI.............................: ' ||  Vn_interface_headers);
  Dka_Tools_Pkg.put_outdebug_message('Nombre de lignes dans l''OI................................: ' ||  Vn_interface_lines);
  Dka_Tools_Pkg.put_outdebug_message('Nombre de lignes de distribution dans l''OI................: ' ||  Vn_interface_distributions);


  ---------------------------------------------
  -- Exécuter l'import standard Purchase Orders
  ---------------------------------------------
  IF Vn_interface_headers != 0 THEN
    Vn_request_id := fnd_request.submit_request(
                                               'PO',          -- APPL
                                               'POXPOPDOI',    -- PROG
                                               NULL,           -- PROGRAM_NAME
                                               NULL,           -- START
                                               FALSE,          -- SUB_REQUEST
                                               NULL,           --
                                               'STANDARD',     --
                                               NULL,           --
                                               'N',            --
                                               NULL,           --
                                               'APPROVED',     --
                                               NULL,           --
                                               Vn_batch_id,    --
                                               gn_org_id,      --
                                               NULL,
                                               NULL,
                                               NULL,
                                               NULL,
                                               NULL,
                                               'N',
                                               'N',
                                               5000,
                                               'N'
                                                );
                                                
    --
    -- Validation for GTS
    --
    COMMIT;

    IF Vn_request_id = 0
    THEN
      dka_tools_pkg.put_debug_message('');
      pn_retcode := 2;
      pv_errbuf  := 'POXPOPDOI : impossible de sousmettre le traitement d''import';
    ELSIF (Vn_request_id IS NOT NULL)
    THEN
      Dka_tools_pkg.put_debug_message('POXPOPDOI : Traitement ' || Vn_request_id || ' en cours.');
      LOOP
        Vb_result := fnd_concurrent.wait_for_request(Vn_request_id,
                                                     10,
                                                     300,
                                                     Vv_phase,
                                                     Vv_status,
                                                     Vv_dev_phase,
                                                     Vv_dev_status,
                                                     Vv_message);

        Vb_return := fnd_concurrent.get_request_status(Vn_request_id,
                                                       NULL,
                                                       NULL,
                                                       Vv_phase,
                                                       Vv_status,
                                                       Vv_dev_phase,
                                                       Vv_dev_status,
                                                       Vv_message);

        IF (nvl(Vv_dev_phase, 'ERROR') = 'COMPLETE')
        THEN
          Dka_tools_pkg.put_debug_message('POXPOPDOI : Traitement ' || Vn_request_id || ' terminé.');
          EXIT;
        END IF;
      END LOOP;

      IF (nvl(Vv_dev_status, 'ERROR') NOT IN ('NORMAL', 'WARNING'))
      THEN
        Dka_tools_pkg.put_debug_message('POXPOPDOI : Statut = ' || Vv_dev_status );
        pn_retcode := 2;
      ELSE
        Dka_tools_pkg.put_debug_message('POXPOPDOI : Statut = ' || Vv_dev_status );
      END IF;
    END IF;
  END IF;
  
  -- SRO le 28/02/2008
  -- Script de Mise à jour des quantité facturées de la ligne d'imputation de la commande car cette fonctionnalité n'est pas
  -- supporté par le standard d'Open Interface et doit être fait après insertion dans les tables standard de commande
  DECLARE
  CURSOR C_TMP_3
  IS  SELECT    distinct pd.po_distribution_id
                ,pd.line_location_id
                ,d.quantity_billed
      FROM      dka_po_com_cont_qty_billed_tmp d,
                po_headers_interface phi,
                po_headers_all ph,
                po_lines_interface pli,
                po_lines_all pl,
                po_line_locations_all plla,  -- CDE 030209
                po_distributions_interface pdi,
                po_distributions_all pd
       -- Selection l'entête de commande        
       WHERE    d.interface_header_id           = phi.interface_header_id
       AND      phi.document_num                = ph.segment1
       AND      ph.po_header_id                 = pl.po_header_id
       -- Selection de la ligne de commande
       -- CDE 030209 AND      d.interface_header_id           = pli.interface_header_id
       AND      d.interface_line_id             = pli.interface_line_id
       AND      pli.line_num                    = pl.line_num
       -- CDE 030209 Selection de la ligne de livraison
       AND      plla.po_line_id                 = pl.po_line_id
       AND      plla.shipment_num               = pli.shipment_num
       -- Selection de la ligne d'imputation de commande
       AND      plla.line_location_id           = pd.line_location_id   -- CDE 030209
       -- CDE 030209 AND      pl.po_header_id                 = pd.po_header_id
       -- CDE 030209 AND      pl.po_line_id                   = pd.po_line_id
       -- CDE 030209 AND      d.interface_header_id           = pdi.interface_header_id
       -- CDE 030209 AND      d.interface_line_id             = pdi.interface_line_id
       AND      d.interface_distribution_id     = pdi.interface_distribution_id
       AND      pdi.distribution_num            = pd.distribution_num
       AND      ph.org_id                       = gn_org_id
       ;
  
  BEGIN       
  FOR REC_TMP_3 IN C_TMP_3
    LOOP  
        -- Mise à jour des qty facturées sur la ligne d'imputation
        UPDATE   po_distributions_all
        SET      quantity_billed     = REC_TMP_3.quantity_billed
        WHERE    po_distribution_id  = REC_TMP_3.po_distribution_id;

        -- Mise à jour des qty facturées sur la ligne de livraison        
        UPDATE   po_line_locations_all
        SET      quantity_billed     = quantity_billed + REC_TMP_3.quantity_billed
        WHERE    line_location_id    = REC_TMP_3.line_location_id;        
        
    END LOOP;             
  END;

  -- Mise à jour des contrats avec les numéros des commandes qui viennent d'être insérées 
  UPDATE dka_contrat_sstr dcs
  SET commande_id = (SELECT pha_cde.po_header_id 
                     FROM po_headers_all pha_cde,
                          po_headers_all pha_ctr
                     WHERE pha_cde.segment1 = pha_ctr.segment1 || 'ST' || TO_CHAR(pha_ctr.start_date,'YYMM')
                     AND pha_ctr.po_header_id = dcs.po_header_id
                     AND pha_cde.org_id = gn_org_id)
     ,commande_version = (SELECT pha_cde.revision_num 
                     FROM po_headers_all pha_cde,
                          po_headers_all pha_ctr
                     WHERE pha_cde.segment1 = pha_ctr.segment1 || 'ST' || TO_CHAR(pha_ctr.start_date,'YYMM')
                     AND pha_ctr.po_header_id = dcs.po_header_id
                     AND pha_cde.org_id = gn_org_id)
  WHERE dcs.description_specifique_contrat IN (SELECT ref_contrat_parent || '-' || description_contrat
                                               FROM dka_po_com_cont_tmp dpcct)
  AND dcs.commande_id IS NULL
  AND dcs.org_id = gn_org_id;

  UPDATE dka_contrat_sstr_archi dcsa
  SET commande_id = (SELECT pha_cde.po_header_id 
                     FROM po_headers_all pha_cde,
                          po_headers_all pha_ctr
                     WHERE pha_cde.segment1 = pha_ctr.segment1 || 'ST' || TO_CHAR(pha_ctr.start_date,'YYMM')
                     AND pha_ctr.po_header_id = dcsa.po_header_id
                     AND pha_cde.org_id = gn_org_id
                     )
     ,commande_version = (SELECT pha_cde.revision_num 
                     FROM po_headers_all pha_cde,
                          po_headers_all pha_ctr
                     WHERE pha_cde.segment1 = pha_ctr.segment1 || 'ST' || TO_CHAR(pha_ctr.start_date,'YYMM')
                     AND pha_ctr.po_header_id = dcsa.po_header_id
                     AND pha_cde.org_id = gn_org_id
                     )
  WHERE dcsa.description_specifique_contrat IN (SELECT ref_contrat_parent || '-' || description_contrat
                                               FROM dka_po_com_cont_tmp dpcct)
  AND dcsa.commande_id IS NULL
  AND dcsa.org_id = gn_org_id;
 
  
  SELECT COUNT(1)
  INTO   Vn_accepted
  FROM   po_headers_interface  phi
  WHERE  phi.batch_id = Vn_batch_id
  AND    phi.process_code = 'ACCEPTED';

  SELECT COUNT(1)
  INTO   Vn_rejected
  FROM   po_headers_interface  phi
  WHERE  phi.batch_id = Vn_batch_id
  AND    phi.process_code = 'REJECTED';

  Dka_tools_pkg.put_debug_message('POXPOPDOI : Accepted = ' || Vn_accepted || ' Rejected = ' || Vn_rejected );

  Dka_Tools_Pkg.put_outdebug_message(' ');
  Dka_Tools_Pkg.put_outdebug_message('Nombre de commandes créées par le traitement d''import.....: ' ||  Vn_accepted);
  Dka_Tools_Pkg.put_outdebug_message('Nombre de commandes rejetées par le traitement d''import...: ' ||  Vn_rejected);


    ---------------------------------------------
    -- Reception des commandes
    ---------------------------------------------
    
    reception_commandes(pv_errbuf,
                        pn_retcode);
  
    IF pn_retcode != 0
    THEN
      RETURN;
    END IF;



  Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
  Dka_Tools_Pkg.Put_Outdebug_Message('=> FIN DE PROGRAMME');
  Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');


  Dka_Tools_Pkg.Put_Debug_Message('End - Main (-)');

EXCEPTION
  WHEN OTHERS THEN
    Dka_Tools_Pkg.Put_Outdebug_Message(' ');
    Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
    Dka_Tools_Pkg.Put_Outdebug_Message('=> TRAITEMENT TERMINE EN ERREUR');
    Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
    Pv_Errbuf  := 'Erreur dans la procécure Main : ' || SQLERRM;
    Pn_Retcode := 2;
    Dka_Tools_Pkg.Put_Outdebug_Message(Pv_Errbuf);
    Dka_Tools_Pkg.Put_Debug_Message('End - Main (-)');
END Main;

END DKA_SPOREPCOMCONT_PKG;
/
SHOW ERROR PACKAGE BODY DKA_SPOREPCOMCONT_PKG
EXIT
