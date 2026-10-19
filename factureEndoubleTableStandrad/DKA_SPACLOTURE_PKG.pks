CREATE OR REPLACE PACKAGE BODY dka_iporecvtotal_pkg IS
  --
  -- $Id: DKA_IPORECVTOTAL_PKG.pkb 264 2007-09-18 08:29:21Z NORDEST\nboussek $
  --
  ---PROD------------------------------------------------------------------------------------------------------------
  -- CAPGEMINI
  -- PROJET             : DALKIA Oracle Applications
  -- NOM                : DKA_SPORECEP_FRAISPORT.pkb
  -- DESCRIPTION        : DKA_SPORECEP_FRAISPORT package body :
  ---
  --- AUTEUR        : Nicolas BOUSSEKEYT
  --- DATE DE CREATION  : 30/08/2007
  --- DOC. ASSOCIEE     :
  -- COMMENTAIRE        : A exécuter sous SQLPLUS avec le user APPS
  ---------------------------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- 15/01/2009 CDE Suite Evol EID20080144 - Réception pour commandes multi lignes
  --- 26/02/2010 MSL EID20090220 - Evol 3-1 : Ajout procédures correction_reception, complement_recept_correction
  ---                              complement_recept_correction_2
  --- 05/02/2014 BCO Correction des réceptions pour la prise en compte de la prestation unitaire.
  --- 31/01/2014 BCO Modification du montant d'un contrat
  --- 04/08/2015 BCO INC000000709324 : Workflow de Modification des Contrats SSTR incorrecte lors des prestations unitaires
  --- 04/07/2017 RBE Migration R12
  ---------------------------------------------------------------------------------------------------------------

  ----- Déclaration des variables globales du package -----
  gv_status_code      VARCHAR2(15) := 'PENDING';
  gv_source_code      VARCHAR2(15) := 'VENDOR';
  gv_transaction_new  VARCHAR2(15) := 'NEW';
  gv_transaction_type VARCHAR2(15) := 'RECEIVE';
  gv_mode_code        VARCHAR2(15) := 'BATCH';
  gv_auto_transact    VARCHAR2(15) := 'DELIVER';
  gv_user_id          NUMBER := fnd_global.user_id;
  gv_login_id         NUMBER := fnd_global.login_id;

  -----------------------------------------------------------------
  -- NOM         : put_line_log
  -- DESCRIPTION : Ecrit une ligne dans le fichier log du traitement
  -----------------------------------------------------------------
  PROCEDURE put_line_log(pv_buffer IN VARCHAR2) IS
  BEGIN
    fnd_file.put_line(fnd_file.log, pv_buffer);
  EXCEPTION
    WHEN OTHERS THEN
      NULL; -- on ne fait rien
  END put_line_log;

  -----------------------------------------------------------------
  -- NOM         : put_line_out
  -- DESCRIPTION : Ecrit une ligne dans le fichier out du traitement
  -----------------------------------------------------------------
  PROCEDURE put_line_out(pv_buffer IN VARCHAR2) IS
  BEGIN
    fnd_file.put_line(fnd_file.output, pv_buffer);
  EXCEPTION
    WHEN OTHERS THEN
      NULL; -- on ne fait rien
  END put_line_out;

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
                               pn_org_id         IN NUMBER, --RBE MigR12
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
       org_id, --RBE MigR12
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
       pn_org_id, --RBE MigR12
       'Y',
       SYSDATE,
       gv_user_id,
       SYSDATE,
       gv_user_id,
       gv_login_id,
       SYSDATE);

  EXCEPTION
    WHEN OTHERS THEN
      put_line_log('Erreur lors de l insertion RHI : ' || SQLERRM(SQLCODE));
      pv_errbuf  := 'DKA_IPORECVTOTAL_PKG.insert_rcv_headers' || SQLERRM;
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
      put_line_log('Erreur lors de l insertion RTI : ' || SQLERRM(SQLCODE));
      pn_retcode := 1;
      pv_errbuf  := 'DKA_SPORECEP_FRAISPORT_PKG.insert_rcv_transactions' ||
                    SQLERRM;
  END insert_rcv_transactions;

  -------------------------------------------------------------------------------------
  --  Nom           : correction_reception
  --  Description   : Procédure qui permet de corriger les receptions 
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
PROCEDURE correction_reception(itemtype  IN VARCHAR2,
                               itemkey   IN VARCHAR2,
                               actid     IN NUMBER,
                               funcmode  IN VARCHAR2,                            
                               resultout OUT NOCOPY VARCHAR2) IS
  
    vn_contrat_id                    NUMBER;
    vn_quantity_delivered            po_distributions_all.quantity_delivered%TYPE;
    vb_quantity_diminue              BOOLEAN := FALSE;
    vn_vendor_id                     po_headers_all.vendor_id%TYPE;
    vn_vendor_site_id                po_headers_all.vendor_site_id%TYPE;
    vn_quantity                      po_line_locations_all.quantity%TYPE;
    vv_unit_of_measure               po_lines_all.unit_meas_lookup_code%TYPE;
    vv_description                   po_lines_all.item_description%TYPE;
    vn_po_line_id                    po_lines_all.po_line_id%TYPE;
    vn_ship_to_location_id           po_line_locations_all.ship_to_location_id%TYPE;
    vn_ship_to_organization_id       po_line_locations_all.ship_to_organization_id%TYPE;
    vn_po_line_location_id           po_line_locations_all.line_location_id%TYPE;
    vn_po_distribution_id            po_distributions_all.po_distribution_id%TYPE;
    
    vn_group_id    rcv_transactions_interface.interface_transaction_id%TYPE :=NULL;
    vn_group_id_2  rcv_transactions_interface.interface_transaction_id%TYPE :=NULL;            
    vn_request_id                    NUMBER;
   
    vv_user_phase                 VARCHAR2(200);
    vv_user_status                VARCHAR2(200);
    vv_dev_phase                  VARCHAR2(200);
    vv_dev_status                 VARCHAR2(200);
    vv_message                    VARCHAR2(200);    
        
    vv_errbuf      VARCHAR2(2000);
    vn_retcode     NUMBER;
    
    vn_batch_id    NUMBER;    
    
    vn_shipment_header_id           rcv_transactions.shipment_header_id%TYPE;
    vn_shipment_line_id             rcv_transactions.shipment_line_id%TYPE;
    vn_transaction_id               rcv_transactions.transaction_id%TYPE;
    vn_line_location_id  po_distributions_all.line_location_id%TYPE;    
    
    -- 05/02/2014 - Ajout de la variable de contrôle de prestation unitaire.
    vv_presta_unit     po_headers_all.attribute14%TYPE;
    vn_quantity_cal NUMBER;
    vn_annulation            NUMBER;
    CURSOR cur_contrat_imput(pn_contrat_id NUMBER) IS
    SELECT dcsi.po_header_id, 
           dcsi.contrat_imputation_id,             -- Numero de ligne
           dcsi.project_id,                        -- Projet
           dcsi.location_id,                       -- Lieu de livraison
           dcsi.expenditure_type,                  -- Type de dépense
           dcs.commande_id                         -- Numéro de la commande
      FROM dka_contrat_sstr_imputation dcsi,
           dka_contrat_sstr dcs      
     WHERE dcs.po_header_id = dcsi.po_header_id
       AND dcsi.po_header_id = pn_contrat_id;
    
  BEGIN
  
    -- Récupération de l'id contrat
    vn_contrat_id := wf_engine.getitemattrnumber(itemtype => itemtype,
                                                 itemkey  => itemkey,
                                                 aname    => 'P_CONTRACT_ID');
    -- ------------------------------------------------------------------ --
    -- 01/31/2014 BCO DGE20130037 - Modification du montant d'un contrat. --
    -- ------------------------------------------------------------------ --
    BEGIN
        SELECT COUNT(1)
          INTO vn_annulation
          FROM DKA_CONTRAT_SSTR_ARCHI DCSA
         WHERE DCSA.PO_HEADER_ID = vn_contrat_id
           AND DCSA.REVISION_NUM = (SELECT decode(DCS.REVISION_NUM, 0, 0,  DCS.REVISION_NUM-1)
                                      FROM DKA_CONTRAT_SSTR DCS 
                                     WHERE DCS.PO_HEADER_ID = DCSA.PO_HEADER_ID)
           AND DCSA.ANNULATION     = 'OUI';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            vn_annulation := 0;
        WHEN OTHERS THEN
            vn_annulation := 0;
    END;
    -- ------------------------------------------------------------------------------------------- --
    -- 05/02/2014 BCO Correction des réceptions pour la prise en compte de la prestation unitaire. --
    -- Modification de la valeur du champ quantity de la table rcv_transactions_interface.         --
    -- ------------------------------------------------------------------------------------------- --
    BEGIN
        SELECT pha.attribute14
          INTO vv_presta_unit
          FROM po_headers_all pha
         WHERE pha.po_header_id = vn_contrat_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            vv_presta_unit := NULL;
        WHEN OTHERS THEN
            vv_presta_unit := NULL;
    END;
    
    -- Pour toutes les lignes
    FOR rec_contrat_imput IN cur_contrat_imput(vn_contrat_id)
        LOOP 
        -- -------------------------------------------------------------------------------------------- --
        -- 05/02/2014 BCO Si le contrat est en prestation unitaire, le montant facturée est spécifique. --
        -- -------------------------------------------------------------------------------------------- --
        IF vv_presta_unit = 'OUI' OR vn_annulation != 0 THEN
            vn_quantity_cal := dka_spowfmaster_pkg.get_montant_presta_unit(rec_contrat_imput.contrat_imputation_id);
        ELSE
            vn_quantity_cal := dka_spowfmaster_pkg.get_montant_imput(rec_contrat_imput.contrat_imputation_id);
        END IF;
        
        BEGIN
          -- On récupére le montant de la ligne
          SELECT pda.quantity_delivered,
                 pda.po_distribution_id,
                 pda.line_location_id
            INTO vn_quantity_delivered,
                 vn_po_distribution_id,
                 vn_line_location_id
          FROM dka_contrat_sstr_imputation dcsi,
               po_line_locations_all pll,
               po_distributions_all pda,
               dka_contrat_sstr dcs
         WHERE pll.ship_to_location_id = dcsi.location_id                -- Lieu de livraison
           AND pda.line_location_id = pll.line_location_id                
           AND dcsi.project_id = pda.project_id                          -- Projet
           AND dcsi.expenditure_type = pda.expenditure_type              -- Type de dépense
           and dcs.po_header_id = dcsi.po_header_id
           and dcs.commande_id = pda.po_header_id
           and dcs.commande_id = pll.po_header_id
           AND dcsi.po_header_id = rec_contrat_imput.po_header_id
           AND dcsi.contrat_imputation_id = rec_contrat_imput.contrat_imputation_id;
        EXCEPTION
           WHEN NO_DATA_FOUND THEN
             vn_quantity_delivered := 0;  
        END;
             
        -- On compare les montants pour la ligne
        IF vn_quantity_delivered > vn_quantity_cal THEN
          
          -- Récupération des données à modifier pour une correction en RECEIVE
          BEGIN
            SELECT ph.vendor_id,
                   ph.vendor_site_id,
                   pll.quantity,
                   pl.unit_meas_lookup_code,
                   pl.item_description,
                   pl.po_line_id,
                   pll.ship_to_organization_id,
                   pll.ship_to_location_id,
                   pll.line_location_id
              INTO vn_vendor_id,
                   vn_vendor_site_id,
                   vn_quantity,
                   vv_unit_of_measure,
                   vv_description,
                   vn_po_line_id,                                       
                   vn_ship_to_organization_id,
                   vn_ship_to_location_id,                   
                   vn_po_line_location_id                                             
              FROM po_headers_all ph,
                   po_lines_all pl, 
                   po_line_locations_all pll
             WHERE ph.po_header_id = pl.po_header_id 
               AND pl.po_line_id = pll.po_line_id 
               AND ph.po_header_id = pll.po_header_id
               AND ph.po_header_id = rec_contrat_imput.commande_id
               AND pll.line_location_id = vn_line_location_id;        
            
          EXCEPTION
            WHEN OTHERS THEN
              put_line_log('Erreur lors de la récupération des données à modifier pour la réception : ');
              put_line_log(SQLERRM);
          END;                
                    
         BEGIN
           IF vn_group_id IS NULL THEN
             -- Récupération du group_id
             SELECT rcv_interface_groups_s.nextval
               INTO vn_group_id
               FROM dual;
           END IF;   
         EXCEPTION
           WHEN OTHERS THEN
             put_line_log('Erreur lors de la récupération des données à modifier pour la réception : ');
             put_line_log(SQLERRM);
            
         END;
         BEGIN
         
           SELECT rt.shipment_header_id,
                  rt.shipment_line_id,
                  rt.transaction_id
             INTO vn_shipment_header_id,
                  vn_shipment_line_id,
                  vn_transaction_id                         
             FROM rcv_transactions rt,
                  po_distributions_all pda
            WHERE rt.transaction_type = 'DELIVER'
              AND rt.po_header_id = pda.po_header_id
              AND rt.po_distribution_id = pda.po_distribution_id
              AND pda.po_header_id = rec_contrat_imput.commande_id
              AND pda.po_distribution_id = vn_po_distribution_id;
              
         EXCEPTION
           WHEN no_data_found THEN
           put_line_log('Pas de donnée trouvée pour transaction_type = DELIVER');
 
         END;                             
           -- Insertion des données dans la table de transaction pour modification
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
                       po_distribution_id,                                                                                         
                       validation_flag,                                                 
                       ship_to_location_id,                                             
                       to_organization_id,                                              
                       deliver_to_location_id,                                          
                       creation_date,                                                   
                       created_by,                                                      
                       last_update_date,                                                
                       last_updated_by,                                                 
                       last_update_login,                                               
                       expected_receipt_date,
                       destination_type_code,
                       destination_context,
                       shipment_header_id,   
                       shipment_line_id,     
                       parent_transaction_id)                                             
                    VALUES                                                              
                      (rcv_transactions_interface_s.NEXTVAL,   -- interface_transaction_
                       vn_group_id,                            -- group_id              
                       'CORRECT',                              -- transaction_type      
                       SYSDATE,                                -- transaction_date      
                       'PENDING',                              -- processing_status_code
                       'BATCH',                                -- processing_mode_code  
                       'PENDING',                              -- transaction_status_cod
                       vn_quantity_cal -- quantity    A vérifier !!!!!!!!!
                        - vn_quantity_delivered,                                      
                       vv_unit_of_measure,                     -- unit_of_measure       
                       vv_description,                         -- item_description      
                       'DELIVER',                              -- auto_transact_code    
                       'VENDOR',                               -- receipt_source_code   
                       vn_vendor_id,                           -- vendor_id             
                       vn_vendor_site_id,                      -- vendor_site_id        
                       'PO',                                   -- source_document_code  
                       rec_contrat_imput.commande_id,          -- po_header_id          
                       vn_po_line_id,                          -- po_line_id            
                       vn_po_line_location_id,                 -- po_line_location_id
                       vn_po_distribution_id,                  -- po_distribution_id   
                       'Y',                                    -- validation_flag       
                       vn_ship_to_location_id,                 -- ship_to_location_id   
                       vn_ship_to_organization_id,             -- to_organization_id    
                       NULL,                                   -- deliver_to_location_id
                       SYSDATE,                                -- creation_date         
                       fnd_global.user_id,                     -- created_by            
                       SYSDATE,                                -- last_update_date      
                       fnd_global.user_id,                     -- last_updated_by       
                       fnd_global.login_id,                    -- last_update_login     
                       NULL,                                   -- expected_receipt_date
                       'EXPENSE',                              -- destination_type_code 
                       'EXPENSE',                              -- destination_context                                                      
                       vn_shipment_header_id,   
                       vn_shipment_line_id,     
                       vn_transaction_id);                        
           
           BEGIN
             IF vn_group_id_2 IS NULL THEN
               -- Récupération du group_id
               SELECT rcv_interface_groups_s.nextval
                 INTO vn_group_id_2
                 FROM dual;
             END IF;     
           EXCEPTION
             WHEN OTHERS THEN
               put_line_log('Erreur lors de la récupération des données à modifier pour la réception : ');
               put_line_log(SQLERRM);
               
           END;
           
           BEGIN
           
             SELECT rt.shipment_header_id,
                    rt.shipment_line_id,
                    rt.transaction_id
               INTO vn_shipment_header_id,
                    vn_shipment_line_id,
                    vn_transaction_id                         
               FROM rcv_transactions rt,
                    po_distributions_all pda
              WHERE rt.transaction_type = 'RECEIVE'
                AND rt.po_header_id = pda.po_header_id
                AND rt.po_distribution_id = pda.po_distribution_id
                AND pda.po_header_id = rec_contrat_imput.commande_id
                AND pda.po_distribution_id = vn_po_distribution_id;
                
           EXCEPTION
             WHEN no_data_found THEN
             put_line_log('Pas de donnée trouvée pour transaction_type = RECEIVE');
   
           END;           
                                               
           -- Insertion des données dans la table de transaction pour modification
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
                       po_distribution_id,                                                                     
                       validation_flag,                                                 
                       ship_to_location_id,                                             
                       to_organization_id,                                              
                       deliver_to_location_id,                                          
                       creation_date,                                                   
                       created_by,                                                      
                       last_update_date,                                                
                       last_updated_by,                                                 
                       last_update_login,                                               
                       expected_receipt_date,
                       destination_type_code,
                       destination_context,
                       shipment_header_id,   
                       shipment_line_id,     
                       parent_transaction_id)                                           
                    VALUES                                                              
                      (rcv_transactions_interface_s.NEXTVAL,   -- interface_transaction_
                       vn_group_id_2,                          -- group_id              
                       'CORRECT',                              -- transaction_type      
                       SYSDATE,                                -- transaction_date      
                       'PENDING',                              -- processing_status_code
                       'BATCH',                                -- processing_mode_code  
                       'PENDING',                              -- transaction_status_cod
                       vn_quantity_cal -- quantity    A vérifier !!!!!!!!!
                        - vn_quantity_delivered,                                       
                       vv_unit_of_measure,                     -- unit_of_measure       
                       vv_description,                         -- item_description      
                       'RECEIVE',                              -- auto_transact_code    
                       'VENDOR',                               -- receipt_source_code   
                       vn_vendor_id,                           -- vendor_id             
                       vn_vendor_site_id,                      -- vendor_site_id        
                       'PO',                                   -- source_document_code  
                       rec_contrat_imput.commande_id,          -- po_header_id          
                       vn_po_line_id,                          -- po_line_id            
                       vn_po_line_location_id,                 -- po_line_location_id   
                       vn_po_distribution_id,                  -- po_distribution_id                           
                       'Y',                                    -- validation_flag       
                       vn_ship_to_location_id,                 -- ship_to_location_id   
                       vn_ship_to_organization_id,             -- to_organization_id    
                       NULL,                                   -- deliver_to_location_id
                       SYSDATE,                                -- creation_date         
                       fnd_global.user_id,                     -- created_by            
                       SYSDATE,                                -- last_update_date      
                       fnd_global.user_id,                     -- last_updated_by       
                       fnd_global.login_id,                    -- last_update_login     
                       NULL,                                   -- expected_receipt_date
                       'RECEIVING',                            -- destination_type_code 
                       'RECEIVING',                            -- destination_context                                                                                                
                       vn_shipment_header_id,   
                       vn_shipment_line_id,     
                       vn_transaction_id); 
        COMMIT;
        
        END IF;    
    
    END LOOP;
  
  -- Affecte le nouveau groupe de reception
  wf_engine.setitemattrnumber(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'BATCH_ID',
                              avalue   => vn_group_id);

  wf_engine.setitemattrnumber(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'BATCH_ID_2',
                              avalue   => vn_group_id_2);



  END;
  -------------------------------------------------------------------------------------
  --  Nom           : complement_reception
  --  Description   : Procédure qui permet de completer les receptions 
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------    
  PROCEDURE complement_recept_correction(itemtype  IN VARCHAR2,
                                            itemkey   IN VARCHAR2,
                                            actid     IN NUMBER,
                                            funcmode  IN VARCHAR2,                            
                                            resultout OUT NOCOPY VARCHAR2) IS
                                 
  vn_commande_id               NUMBER;
  vn_contrat_id                    NUMBER;
  vb_complement                BOOLEAN := FALSE;
  vn_vendor_id                 NUMBER;
  vn_vendor_site_id            NUMBER;
  vn_group_id    rcv_transactions_interface.interface_transaction_id%TYPE :=NULL;
  vn_group_id_2  rcv_transactions_interface.interface_transaction_id%TYPE :=NULL;            
  vn_shipment_header_id           rcv_transactions.shipment_header_id%TYPE;
  vn_shipment_line_id             rcv_transactions.shipment_line_id%TYPE;
  vn_transaction_id               rcv_transactions.transaction_id%TYPE;
  vn_quantity                      po_line_locations_all.quantity%TYPE;
  vv_unit_of_measure               po_lines_all.unit_meas_lookup_code%TYPE;
  vv_description                   po_lines_all.item_description%TYPE;
  vn_po_line_id                    po_lines_all.po_line_id%TYPE;
  vn_ship_to_location_id           po_line_locations_all.ship_to_location_id%TYPE;
  vn_ship_to_organization_id       po_line_locations_all.ship_to_organization_id%TYPE;
  vn_po_line_location_id           po_line_locations_all.line_location_id%TYPE;
  vn_po_distribution_id            po_distributions_all.po_distribution_id%TYPE;
  vb_correction                    BOOLEAN := FALSE;
  vb_header                        BOOLEAN := FALSE;
     
  vv_errbuf                    VARCHAR2(2000);
  vn_retcode                   NUMBER;  
  
  CURSOR cur_po_distribution IS
    SELECT pda.quantity_ordered,
           pda.quantity_delivered,
           pda.po_distribution_id,
           pda.line_location_id
      FROM po_distributions_all pda
     WHERE pda.po_header_id = vn_commande_id
       AND pda.quantity_ordered > pda.quantity_delivered
       AND pda.quantity_delivered = 0; 
  
  CURSOR cur_ligne_commande (pn_line_location_id NUMBER) IS
    SELECT ph.vendor_id,
           ph.vendor_site_id,
           pll.quantity,
           pl.unit_meas_lookup_code,
           pl.item_description,
           pl.po_line_id,
           pll.ship_to_organization_id,
           pll.ship_to_location_id,
           pll.line_location_id
    FROM po_headers_all ph, 
         po_lines_all pl, 
         po_line_locations_all pll
    WHERE pll.line_location_id = pn_line_location_id AND
          ph.po_header_id = pl.po_header_id AND
          pl.po_line_id = pll.po_line_id AND
          ph.po_header_id = pll.po_header_id;  

    vn_org_id NUMBER; --RBE MigR12
  BEGIN
    -- Récupération de l'id commande
    vn_commande_id := wf_engine.getitemattrnumber(itemtype => itemtype,
                                                 itemkey  => itemkey,
                                                 aname    => 'COMMANDE_ID');
    -- On vérifie chaque ligne de la commande
    FOR rec_po_distribution IN cur_po_distribution
    LOOP
        /*IF rec_po_distribution.quantity_ordered > rec_po_distribution.quantity_delivered
        THEN
           -- Création d'une nouvelle reception
           IF rec_po_distribution.quantity_delivered = 0
           THEN*/
      vb_correction := TRUE;  

      IF vb_header = FALSE
      THEN

      SELECT ph.vendor_id, 
             ph.vendor_site_id,
             ph.org_id  --RBE MigR12
       INTO vn_vendor_id, 
            vn_vendor_site_id,
            vn_org_id   --RBE MigR12
       FROM po_headers_all ph
      WHERE ph.po_header_id = vn_commande_id;
                    
      -- Insertion entête
      insert_rcv_headers(vn_vendor_id,
                         vn_vendor_site_id,
                         vn_org_id, --RBE MigR12
                         vv_errbuf,
                         vn_retcode);
      vb_header := TRUE;
                                       
      -- Insertion ligne
      IF vn_retcode != 0
      THEN
        RETURN;
      END IF;
      
      END IF;

      FOR rec_ligne_commande IN cur_ligne_commande (rec_po_distribution.line_location_id) LOOP
        BEGIN
          -- Insertion des infos de la table des lignes
          insert_rcv_transactions(rec_ligne_commande.quantity,
                                  rec_ligne_commande.unit_meas_lookup_code,
                                  rec_ligne_commande.item_description,
                                  rec_ligne_commande.vendor_id,
                                  rec_ligne_commande.vendor_site_id,
                                  vn_commande_id,
                                  rec_ligne_commande.po_line_id,
                                  rec_ligne_commande.line_location_id,
                                  rec_ligne_commande.ship_to_organization_id,
                                  rec_ligne_commande.ship_to_location_id,
                                  vv_errbuf,
                                  vn_retcode);

          IF vn_retcode != 0
          THEN
             RETURN;
          END IF;
        END;
      END LOOP;

      COMMIT;              

      BEGIN
       IF vn_group_id IS NULL THEN
         -- Récupération du group_id
         SELECT rcv_interface_groups_s.currval
           INTO vn_group_id
           FROM dual;
       END IF;     
      EXCEPTION
       WHEN OTHERS THEN
         put_line_log('Erreur lors de la récupération des données à modifier pour la réception : ');
         put_line_log(SQLERRM);
                             
      END;
                             
        --   END IF;
        --END IF;    
    END LOOP;

  -- Affecte le nouveau groupe de reception
  wf_engine.setitemattrnumber(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'BATCH_ID',
                              avalue   => vn_group_id);
  
  -- Si un correction est nécessaire, on retourne 'oui'    
  IF vb_correction = TRUE THEN
    resultout := wf_engine.eng_completed || ':' || 'Y';      
  ELSE
    resultout := wf_engine.eng_completed || ':' || 'N';
  END IF;

                                
  END;
  
-------------------------------------------------------------------------------------
  --  Nom           : complement_recept_correction_2
  --  Description   : Procédure qui permet de completer les receptions 
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------    
  PROCEDURE complement_recept_correction_2(itemtype  IN VARCHAR2,
                                       itemkey   IN VARCHAR2,
                                       actid     IN NUMBER,
                                       funcmode  IN VARCHAR2,                            
                                       resultout OUT NOCOPY VARCHAR2) IS
                                 
  vn_commande_id               NUMBER;
  vn_contrat_id                NUMBER;
  vb_complement                BOOLEAN := FALSE;
  vn_vendor_id                 NUMBER;
  vn_vendor_site_id            NUMBER;
  vn_group_id    rcv_transactions_interface.interface_transaction_id%TYPE :=NULL;
  vn_group_id_2  rcv_transactions_interface.interface_transaction_id%TYPE :=NULL;            
  vn_shipment_header_id           rcv_transactions.shipment_header_id%TYPE;
  vn_shipment_line_id             rcv_transactions.shipment_line_id%TYPE;
  vn_transaction_id               rcv_transactions.transaction_id%TYPE;
  vn_quantity                      po_line_locations_all.quantity%TYPE;
  vv_unit_of_measure               po_lines_all.unit_meas_lookup_code%TYPE;
  vv_description                   po_lines_all.item_description%TYPE;
  vn_po_line_id                    po_lines_all.po_line_id%TYPE;
  vn_ship_to_location_id           po_line_locations_all.ship_to_location_id%TYPE;
  vn_ship_to_organization_id       po_line_locations_all.ship_to_organization_id%TYPE;
  vn_po_line_location_id           po_line_locations_all.line_location_id%TYPE;
  vn_po_distribution_id            po_distributions_all.po_distribution_id%TYPE;
  vb_correction                    BOOLEAN := FALSE;
     
  vv_errbuf                    VARCHAR2(2000);
  vn_retcode                   NUMBER;  
  
  CURSOR cur_po_distribution IS
    SELECT pda.quantity_ordered,
           pda.quantity_delivered,
           pda.po_distribution_id,
           pda.line_location_id
      FROM po_distributions_all pda
     WHERE pda.po_header_id = vn_commande_id
       AND pda.quantity_ordered > quantity_delivered
       AND quantity_delivered > 0; 
  
  CURSOR cur_ligne_commande (pn_line_location_id NUMBER) IS
    SELECT ph.vendor_id,
           ph.vendor_site_id,
           pll.quantity,
           pl.unit_meas_lookup_code,
           pl.item_description,
           pl.po_line_id,
           pll.ship_to_organization_id,
           pll.ship_to_location_id,
           pll.line_location_id
    FROM po_headers_all ph, 
         po_lines_all pl, 
         po_line_locations_all pll
    WHERE pll.line_location_id = pn_line_location_id AND
          ph.po_header_id = pl.po_header_id AND
          pl.po_line_id = pll.po_line_id AND
          ph.po_header_id = pll.po_header_id;  

 
  BEGIN
    -- Récupération de l'id commande
    vn_commande_id := wf_engine.getitemattrnumber(itemtype => itemtype,
                                                 itemkey  => itemkey,
                                                 aname    => 'COMMANDE_ID');
    -- On vérifie chaque ligne de la commande
    FOR rec_po_distribution IN cur_po_distribution
    LOOP
      -- Correction de reception   
       
          FOR rec_ligne_commande IN cur_ligne_commande (rec_po_distribution.line_location_id) LOOP
          vb_correction := TRUE;
                
              BEGIN
                SELECT ph.vendor_id,
                       ph.vendor_site_id,
                       pll.quantity,
                       pl.unit_meas_lookup_code,
                       pl.item_description,
                       pl.po_line_id,
                       pll.ship_to_organization_id,
                       pll.ship_to_location_id,
                       pll.line_location_id
                  INTO vn_vendor_id,
                       vn_vendor_site_id,
                       vn_quantity,
                       vv_unit_of_measure,
                       vv_description,
                       vn_po_line_id,                                       
                       vn_ship_to_organization_id,
                       vn_ship_to_location_id,                   
                       vn_po_line_location_id                                             
                  FROM po_headers_all ph,
                       po_lines_all pl, 
                       po_line_locations_all pll
                 WHERE ph.po_header_id = pl.po_header_id 
                   AND pl.po_line_id = pll.po_line_id 
                   AND ph.po_header_id = pll.po_header_id
                   AND ph.po_header_id = vn_commande_id
                   AND pll.line_location_id = rec_ligne_commande.line_location_id;        
                      
              EXCEPTION
                WHEN OTHERS THEN
                  put_line_log('Erreur lors de la récupération des données à modifier pour la réception : ');
                  put_line_log(SQLERRM);
              END;               
                
                               
             BEGIN
               IF vn_group_id IS NULL THEN
                 -- Récupération du group_id
                 SELECT rcv_interface_groups_s.nextval
                   INTO vn_group_id
                   FROM dual;
               END IF;     
             EXCEPTION
               WHEN OTHERS THEN
                 put_line_log('Erreur lors de la récupération des données à modifier pour la réception : ');
                 put_line_log(SQLERRM);
                       
             END;
             
             BEGIN
                   
               SELECT rt.shipment_header_id,
                      rt.shipment_line_id,
                      rt.transaction_id
                 INTO vn_shipment_header_id,
                      vn_shipment_line_id,
                      vn_transaction_id                         
                 FROM rcv_transactions rt,
                      po_distributions_all pda
                WHERE rt.transaction_type = 'RECEIVE'
                  AND rt.po_header_id = pda.po_header_id
                  AND rt.po_distribution_id = pda.po_distribution_id
                  AND pda.po_header_id = vn_commande_id
                  AND pda.po_distribution_id = rec_po_distribution.po_distribution_id;
                        
             EXCEPTION
               WHEN no_data_found THEN
               put_line_log('Pas de donnée trouvée pour transaction_type = RECEIVE');
           
             END;  
                  
             -- Insertion des données dans la table de transaction pour modification
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
                   po_distribution_id,                                                                     
                   validation_flag,                                                 
                   ship_to_location_id,                                             
                   to_organization_id,                                              
                   deliver_to_location_id,                                          
                   creation_date,                                                   
                   created_by,                                                      
                   last_update_date,                                                
                   last_updated_by,                                                 
                   last_update_login,                                               
                   expected_receipt_date,
                   destination_type_code,
                   destination_context,
                   shipment_header_id,   
                   shipment_line_id,     
                   parent_transaction_id)                                           
                VALUES                                                              
                  (rcv_transactions_interface_s.NEXTVAL,   -- interface_transaction_
                   vn_group_id,                            -- group_id              
                   'CORRECT',                              -- transaction_type      
                   SYSDATE,                                -- transaction_date      
                   'PENDING',                              -- processing_status_code
                   'BATCH',                                -- processing_mode_code  
                   'PENDING',                              -- transaction_status_cod
                   rec_po_distribution.quantity_ordered -
                   rec_po_distribution.quantity_delivered, -- quantity                                           
                   vv_unit_of_measure,                     -- unit_of_measure       
                   vv_description,                         -- item_description      
                   'RECEIVE',                              -- auto_transact_code    
                   'VENDOR',                               -- receipt_source_code   
                   vn_vendor_id,                           -- vendor_id             
                   vn_vendor_site_id,                      -- vendor_site_id        
                   'PO',                                   -- source_document_code  
                   vn_commande_id,                         -- po_header_id          
                   vn_po_line_id,                          -- po_line_id            
                   vn_po_line_location_id,                 -- po_line_location_id   
                   rec_po_distribution.po_distribution_id, -- po_distribution_id                           
                   'Y',                                    -- validation_flag       
                   vn_ship_to_location_id,                 -- ship_to_location_id   
                   vn_ship_to_organization_id,             -- to_organization_id    
                   NULL,                                   -- deliver_to_location_id
                   SYSDATE,                                -- creation_date         
                   fnd_global.user_id,                     -- created_by            
                   SYSDATE,                                -- last_update_date      
                   fnd_global.user_id,                     -- last_updated_by       
                   fnd_global.login_id,                    -- last_update_login     
                   NULL,                                   -- expected_receipt_date
                   'RECEIVING',                            -- destination_type_code 
                   'RECEIVING',                            -- destination_context                                                                                                
                   vn_shipment_header_id,   
                   vn_shipment_line_id,     
                   vn_transaction_id);

             BEGIN
               IF vn_group_id_2 IS NULL THEN
                 -- Récupération du group_id
                 SELECT rcv_interface_groups_s.nextval
                   INTO vn_group_id_2
                   FROM dual;
               END IF;   
             EXCEPTION
               WHEN OTHERS THEN
                 put_line_log('Erreur lors de la récupération des données à modifier pour la réception : ');
                 put_line_log(SQLERRM);
                      
             END;
                   
             BEGIN
                   
               SELECT rt.shipment_header_id,
                      rt.shipment_line_id,
                      rt.transaction_id
                 INTO vn_shipment_header_id,
                      vn_shipment_line_id,
                      vn_transaction_id                         
                 FROM rcv_transactions rt,
                      po_distributions_all pda
                WHERE rt.transaction_type = 'DELIVER'
                  AND rt.po_header_id = pda.po_header_id
                  AND rt.po_distribution_id = pda.po_distribution_id
                  AND pda.po_header_id = vn_commande_id
                  AND pda.po_distribution_id = rec_po_distribution.po_distribution_id;
                        
             EXCEPTION
               WHEN no_data_found THEN
               put_line_log('Pas de donnée trouvée pour transaction_type = DELIVER');
           
             END;                             
             
             -- Insertion des données dans la table de transaction pour modification
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
                         po_distribution_id,                                                                                         
                         validation_flag,                                                 
                         ship_to_location_id,                                             
                         to_organization_id,                                              
                         deliver_to_location_id,                                          
                         creation_date,                                                   
                         created_by,                                                      
                         last_update_date,                                                
                         last_updated_by,                                                 
                         last_update_login,                                               
                         expected_receipt_date,
                         destination_type_code,
                         destination_context,
                         shipment_header_id,   
                         shipment_line_id,     
                         parent_transaction_id)                                             
                      VALUES                                                              
                        (rcv_transactions_interface_s.NEXTVAL,   -- interface_transaction_
                         vn_group_id_2,                          -- group_id              
                         'CORRECT',                              -- transaction_type      
                         SYSDATE,                                -- transaction_date      
                         'PENDING',                              -- processing_status_code
                         'BATCH',                                -- processing_mode_code  
                         'PENDING',                              -- transaction_status_cod
                         rec_po_distribution.quantity_ordered -
                         rec_po_distribution.quantity_delivered, -- quantity                                           
                         vv_unit_of_measure,                     -- unit_of_measure       
                         vv_description,                         -- item_description      
                         'DELIVER',                              -- auto_transact_code    
                         'VENDOR',                               -- receipt_source_code   
                         vn_vendor_id,                           -- vendor_id             
                         vn_vendor_site_id,                      -- vendor_site_id        
                         'PO',                                   -- source_document_code  
                         vn_commande_id,                         -- po_header_id          
                         vn_po_line_id,                          -- po_line_id            
                         vn_po_line_location_id,                 -- po_line_location_id
                         rec_po_distribution.po_distribution_id, -- po_distribution_id   
                         'Y',                                    -- validation_flag       
                         vn_ship_to_location_id,                 -- ship_to_location_id   
                         vn_ship_to_organization_id,             -- to_organization_id    
                         NULL,                                   -- deliver_to_location_id
                         SYSDATE,                                -- creation_date         
                         fnd_global.user_id,                     -- created_by            
                         SYSDATE,                                -- last_update_date      
                         fnd_global.user_id,                     -- last_updated_by       
                         fnd_global.login_id,                    -- last_update_login     
                         NULL,                                   -- expected_receipt_date
                         'EXPENSE',                              -- destination_type_code 
                         'EXPENSE',                              -- destination_context                                                      
                         vn_shipment_header_id,   
                         vn_shipment_line_id,     
                         vn_transaction_id);                             
                                 
          COMMIT;                

          END LOOP;                  
    END LOOP;

  -- Affecte le nouveau groupe de reception
  wf_engine.setitemattrnumber(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'BATCH_ID',
                              avalue   => vn_group_id);

  wf_engine.setitemattrnumber(itemtype => itemtype,
                              itemkey  => itemkey,
                              aname    => 'BATCH_ID_2',
                              avalue   => vn_group_id_2);

  -- Si un correction est nécessaire, on retourne 'oui'    
  IF vb_correction = TRUE THEN
    resultout := wf_engine.eng_completed || ':' || 'Y';      
  ELSE
    resultout := wf_engine.eng_completed || ':' || 'N';
  END IF;
                                
  END;  
  
  --------------------------------------------------------------------------------------------------------------
  --  Nom           : wait_GLPOS
  --  Description   : Attente de la fin d'execution du traitement GLPOS soumis
  --
  --  PARAMETRES    :
  --  pv_errbuf                 Entrée/Sortie      message d'erreur
  --  pn_retcode                Entree/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
  --  VALEUR RETOURNEE :
  --     N/A
  --     Description       :
  --     Valeurs possibles :
  ---------------------------------------------------------------------------------------------------------------

  PROCEDURE wait_rvctp(pv_errbuf             IN OUT VARCHAR2,
                       pn_retcode            IN OUT NUMBER,
                       pn_request_id_porvctp IN NUMBER) IS

    vb_trash      BOOLEAN;
    vv_phase      VARCHAR2(50);
    vv_status     VARCHAR2(50);
    vv_dev_phase  VARCHAR2(50);
    vv_dev_status VARCHAR2(50);
    vv_message    VARCHAR2(50);

  BEGIN

    -- Attente de la fin d'execution des programmes
    vb_trash := fnd_concurrent.wait_for_request(pn_request_id_porvctp, -- REQUEST_ID
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
      pv_errbuf := pv_errbuf || 'Pb dans l attente wait_RVCTP';
    END IF;

    IF vv_status = 'Erreur'
    THEN
      pv_errbuf := pv_errbuf || vv_message;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'sortie de wait_RVCTP avec erreur EXCEPTION OTHERS:' ||
                    SQLERRM;
      pn_retcode := 2;
  END wait_rvctp;

  ------------------------------------------------------------------------------------------------------------------------
  --  Nom           : main
  --  Description   : Procédure principale enchaînant l'ensemble des autres procédures
  --
  --  PARAMETRES :
  --    pv_periode_name         Sortie
  --    pv_errbuf                   Entrée/Sortie       retour de message eventuel
  --    pn_retcode                  Sortie          status du traitement en sortie
  --
  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: normal, 1: warning, 2: erreur
  -----------------------------------------------------------------------------------------------------------------------
  PROCEDURE main(pv_errbuf      OUT VARCHAR2,
                 pn_retcode     IN OUT NUMBER,
                 pn_commande_id IN NUMBER,
                 pn_batch_id    OUT NUMBER) IS

    l_vendor_id               NUMBER;
    l_vendor_site_id          NUMBER;
    l_org_id                  NUMBER; --RBE MigR12
    l_quantity                NUMBER;
    l_uom                     po_lines_all.unit_meas_lookup_code%TYPE;
    l_description             po_lines_all.item_description%TYPE;
    l_po_line_id              NUMBER;
    l_po_line_location_id     NUMBER;
    vn_request_id             NUMBER;
    l_batch_id                NUMBER;
    l_ship_to_organization_id NUMBER;
    l_ship_to_location_id     NUMBER;
    l_count                   NUMBER;
    l_step                    VARCHAR2(50);

  CURSOR cur_ligne_commande (pn_commande_id NUMBER) IS
         SELECT ph.vendor_id,
                ph.vendor_site_id,
                pll.quantity,
                pl.unit_meas_lookup_code,
                pl.item_description,
                pl.po_line_id,
                pll.ship_to_organization_id,
                pll.ship_to_location_id,
                pll.line_location_id
         FROM po_headers_all ph, po_lines_all pl, po_line_locations_all pll
         WHERE ph.po_header_id = pn_commande_id AND
               ph.po_header_id = pl.po_header_id AND
               pl.po_line_id = pll.po_line_id AND
               ph.po_header_id = pll.po_header_id;

  BEGIN
    pn_retcode := 0;

    l_step := 'APPROUVE';
    -- Vérifie si la commande a été approuvé
    SELECT COUNT(*)
      INTO l_count
      FROM po_headers_all
     WHERE po_header_id = pn_commande_id AND
           nvl(authorization_status, 'VIDE') = 'APPROVED';

    IF (l_count = 0)
    THEN
      pn_retcode := 2;
      pv_errbuf  := dka_tools_pkg.get_message('DKA', 'DKA_IPORECC_E002');
      RETURN;
    END IF;

    l_step := 'RECEPTION';
    -- Vérifie si la commande a déjà été réceptionné
    SELECT COUNT(*)
      INTO l_count
      FROM rcv_shipment_lines
     WHERE po_header_id = pn_commande_id;

    IF (l_count > 0)
    THEN
      pn_retcode := 2;
      pv_errbuf  := dka_tools_pkg.get_message('DKA', 'DKA_IPORECC_E001');
      RETURN;
    END IF;

    l_step := 'INIT';
    --- Appel de la procédure INIT pour l'initialisation de parametres globaux
/*    SELECT ph.vendor_id, ph.vendor_site_id, pl.quantity, pl.unit_meas_lookup_code, pl.item_description, pl.po_line_id, pll.ship_to_organization_id, pll.ship_to_location_id, pll.line_location_id
      INTO l_vendor_id, l_vendor_site_id, l_quantity, l_uom, l_description, l_po_line_id, l_ship_to_organization_id, l_ship_to_location_id, l_po_line_location_id
      FROM po_headers_all ph, po_lines_all pl, po_line_locations_all pll
     WHERE ph.po_header_id = pn_commande_id AND
           ph.po_header_id = pl.po_header_id AND
           pl.po_line_id = pll.po_line_id AND
           ph.po_header_id = pll.po_header_id;*/
    SELECT ph.vendor_id, ph.vendor_site_id, ph.org_id --RBE
      INTO l_vendor_id, l_vendor_site_id, l_org_id -- RBE
      FROM po_headers_all ph
     WHERE ph.po_header_id = pn_commande_id;

    -- Insertion des infos de la table des entêtes
    l_step := 'HEADER';
    insert_rcv_headers(l_vendor_id,
                       l_vendor_site_id,
                       l_org_id, --RBE MigR12
                       pv_errbuf,
                       pn_retcode);

    IF pn_retcode != 0
    THEN
      RETURN;
    END IF;


    FOR rec_ligne_commande IN cur_ligne_commande (pn_commande_id) LOOP
      BEGIN
       -- Insertion des infos de la table des lignes
       insert_rcv_transactions(rec_ligne_commande.quantity,
                               rec_ligne_commande.unit_meas_lookup_code,
                               rec_ligne_commande.item_description,
                               rec_ligne_commande.vendor_id,
                               rec_ligne_commande.vendor_site_id,
                               pn_commande_id,
                               rec_ligne_commande.po_line_id,
                               rec_ligne_commande.line_location_id,
                               rec_ligne_commande.ship_to_organization_id,
                               rec_ligne_commande.ship_to_location_id,
                               pv_errbuf,
                               pn_retcode);

        IF pn_retcode != 0
        THEN
           RETURN;
        END IF;
        END;
      END LOOP;

    COMMIT;

    -- Lancement de l'interface standard
    put_line_log('');
    put_line_log('<<<< LANCEMENT DE L''INTERFACE STANDARD RVCTP >>>>');

    SELECT rcv_interface_groups_s.CURRVAL
      INTO l_batch_id
      FROM dual;

    pn_batch_id := l_batch_id;

    /*Vn_Request_Id := Fnd_Request.Submit_Request('PO' -- APPLICATION SHORT NAME
                                                       ,
                                                        'RVCTP' -- CONCURRENT PROGRAM NAME
                                                       ,
                                                        NULL -- DESCRIPTION
                                                       ,
                                                        NULL -- START
                                                       ,
                                                        FALSE -- SUB_REQUEST
                                                        -- ARGUMENTS
                                                       ,
                                                        'BATCH' -- mode
                                                       ,
                                                        l_batch_id -- batch_id
                                                        );

    -- Validation pour soumettre le traitement
    COMMIT;

    IF Vn_Request_Id = 0 THEN
      pv_errbuf := '!!!! Erreur lors de la soumission du programme d''import des réceptions. ';
      dka_tools_pkg.put_outdebug_message(Pv_errbuf);
      dka_tools_pkg.put_outdebug_message(Fnd_Message.Get);
      -- Sortie en erreur
      pn_Retcode := 2;
    END IF;

    -- Attente fin du traitement
    put_line_log('>>>> Attente fin de l''interface standard RVCTP');
    wait_rvctp(pv_errbuf, pn_retcode, Vn_Request_Id);
    put_line_log('<<<< SORTIE DE L''INTERFACE STANDARD RVCTP >>>>');

    select count(*) into l_count
    from PO_INTERFACE_ERRORS   where interface_type = 'RCV-856'   and batch_id = l_batch_id;

    IF (l_count > 0) THEN
       pn_retcode := 2;
       pv_errbuf := 'Pas de réception';
    END IF;*/
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      pn_retcode := 2;
      pv_errbuf  := 'main' || l_step || ':' || substr(SQLERRM, 1, 80);
  END main;

END dka_iporecvtotal_pkg;
/
SHOW ERROR
EXIT
