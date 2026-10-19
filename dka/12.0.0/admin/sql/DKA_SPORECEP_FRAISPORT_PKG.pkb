CREATE OR REPLACE PACKAGE BODY DKA_SPORECEP_FRAISPORT_PKG is
---PROD------------------------------------------------------------------------------------------------------------
-- CAPGEMINI
-- PROJET            	: DALKIA Oracle Applications
-- NOM           	    : DKA_SPORECEP_FRAISPORT.pkb
-- DESCRIPTION       	: DKA_SPORECEP_FRAISPORT package body :
---
--- AUTEUR       	: Thierry BOUGAULT
--- DATE DE CREATION 	: 05/02/2007
--- DOC. ASSOCIEE    	:
-- COMMENTAIRE       	: A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- 12/03/2007  TB Init : Ajout de la variable transaction_auto pour l'AUTO_TRANSACT_CODE
---                Insert_rcv_transaction : modification de la valeur de l'AUTO_TRANSACT_CODE
--- 15/05/2007  TB Main : Correction de la sélection des lignes a traiter (éviction des lignes annulées et non des entetes)
---                Update_suivi : modification de la sélection du message a récupérer en cas de rejet
--- 04/11/2015 JJA Main : Correction de la sélection des lignes a traiter : DPE20150064 
--- 02/06/2016 MEG Migration R12
--- 14/03/2017  EFL artf2120909 : Modification du curseur cur_commandes
---------------------------------------------------------------------------------------------------------------

    ----- Déclaration des variables globales du package -----
    gv_status_code                   VARCHAR2 (15);
    gv_source_code                   VARCHAR2 (15);
    gv_transaction_new               VARCHAR2 (15);
    gv_transaction_type              VARCHAR2 (15);
    gv_transaction_auto              VARCHAR2 (15);
    gv_mode_code                     VARCHAR2 (15);   
    gn_user_id                       NUMBER;
    gn_request_id                    NUMBER;
    gn_retcode                       NUMBER;
    gv_errbuf                        VARCHAR2 (2500);
    gn_tot_ent_ok                    NUMBER := 0;
    gn_tot_ent_ko                    NUMBER := 0;
    gn_tot_lig_ok                    NUMBER := 0;
    gn_tot_lig_ko                    NUMBER := 0;

    e_trt                            EXCEPTION;   -- erreur spécifique
    Vn_Request_Id_PORVCTP            Fnd_Concurrent_Requests.Request_Id%TYPE;
    
            
-----------------------------------------------------------------
-- NOM         : put_line_log
-- DESCRIPTION : Ecrit une ligne dans le fichier log du traitement
-----------------------------------------------------------------
    PROCEDURE put_line_log (
        pv_buffer   IN   VARCHAR2
    )
    IS
    BEGIN
        fnd_file.put_line (fnd_file.LOG, pv_buffer);
    EXCEPTION
        WHEN OTHERS
        THEN
            NULL;   -- on ne fait rien
    END put_line_log;

-----------------------------------------------------------------
-- NOM         : put_line_out
-- DESCRIPTION : Ecrit une ligne dans le fichier out du traitement
-----------------------------------------------------------------
    PROCEDURE put_line_out (
        pv_buffer   IN   VARCHAR2
    )
    IS
    BEGIN
        fnd_file.put_line (fnd_file.output, pv_buffer);
    EXCEPTION
        WHEN OTHERS
        THEN
            NULL;   -- on ne fait rien
    END put_line_out;

-----------------------------------------------------------------
-- NOM         : get_param_varchar
-- DESCRIPTION : Recupere la valeur d'un parametre DKA de type VARCHAR
-----------------------------------------------------------------
    FUNCTION get_param_varchar (
        pv_parameter   IN   VARCHAR2,
        pv_prog_code   IN   VARCHAR2 DEFAULT 'DKA_SPORECEP'
    )
        RETURN VARCHAR2
    IS
        rec_param   dka_parameters%ROWTYPE;
    BEGIN
        dka_tools_pkg.get_parameter (pv_prog_code, pv_parameter, rec_param, gn_retcode, gv_errbuf);

        IF gn_retcode != 0
        THEN
            gv_errbuf    := 'DKA_SPORECEP_FRAISPORT_PKG.get_param_varchar' || '-' || pv_prog_code || '-' || pv_parameter || '-'
                            || gv_errbuf;
            RAISE e_trt;
        ELSE
            RETURN rec_param.varchar2_value;
        END IF;
    EXCEPTION
        WHEN e_trt
        THEN
            RAISE;
        WHEN OTHERS
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := 'DKA_SPORECEP_FRAISPORT_PKG.get_param_varchar:' || SQLERRM;
            RAISE e_trt;
    END get_param_varchar;

--------------------------------------------------------------------------------------
--  Nom           : INIT
--  Description   : initialisation des parametres
----------------------------------------------------------------------------------------
    PROCEDURE init (
        pv_prog     IN      VARCHAR2 DEFAULT NULL,
        pv_errbuf   OUT  VARCHAR2,
        pn_retcode  OUT  NUMBER           
    )
    IS
        --rec_param   dka_parameters%ROWTYPE;
    BEGIN      

        pv_errbuf  := NULL;
        pn_retcode := 0;
        
        IF gn_user_id IS NULL
        THEN
            gn_user_id    := fnd_global.user_id;
        END IF;
        put_line_log ('>> user id : '|| gn_user_id);
        
        IF gn_request_id IS NULL
        THEN
            gn_request_id    := fnd_global.conc_request_id;
        END IF;
        put_line_log ('>> request id : '|| gn_request_id);
        
        IF pv_prog = 'TRANSFER'
        THEN
            gv_status_code               := get_param_varchar ('STATUS_CODE');
            put_line_log ('>> STATUS_CODE : '|| gv_status_code);
            gv_source_code               := get_param_varchar ('SOURCE_CODE');
            put_line_log ('>> SOURCE_CODE : '|| gv_source_code);
            gv_transaction_new           := get_param_varchar ('TRANSACTION_NEW');
            put_line_log ('>> TRANSACTION_NEW : '|| gv_transaction_new);
            gv_transaction_type          := get_param_varchar ('TRANSACTION_TYPE');
            put_line_log ('>> TRANSACTION_TYPE : '|| gv_transaction_type);
            gv_mode_code                 := get_param_varchar ('MODE_CODE');
            put_line_log ('>> MODE_CODE : '|| gv_mode_code);
            gv_transaction_auto          := get_param_varchar ('TRANSACTION_AUTO'); -- Ajout TB 12/03/2007
            put_line_log ('>> TRANSACTION_AUTO : '|| gv_transaction_auto);
        END IF;
            
        put_line_log ('>> Suppression des lignes de la table de suivi');
        DELETE DKA_SPORECEP_TMP;
        COMMIT;

    EXCEPTION
        WHEN e_trt
        THEN
            RAISE;
        WHEN OTHERS
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := 'DKA_SPORECEP_FRAISPORT_PKG.Init:' || Substr(SQLERRM, 1, 300);
            RAISE e_trt;
    END init;


---------------------------------------------------------------------------------------------------------------
--  Nom           : insert_rcv_headers
--  Description   : Procédure d'insertion d'une ligne dans l'interface des entetes
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

PROCEDURE insert_rcv_headers(
        pn_user_id                  IN  NUMBER,
        pn_vendor_id                IN  NUMBER,
        pn_vendor_site_id           IN  NUMBER,
        pn_location_id              IN  NUMBER,
        pn_org_id                   IN  NUMBER,
        pv_errbuf                   OUT VARCHAR2,
        pn_retcode                  OUT NUMBER)

IS

BEGIN

       -- Insertion d'une ligne dans la table RCV_HEADERS_INTERFACE 
       INSERT INTO RCV_HEADERS_INTERFACE
                   (HEADER_INTERFACE_ID,
                    GROUP_ID,
                    PROCESSING_STATUS_CODE,
                    RECEIPT_SOURCE_CODE,
                    TRANSACTION_TYPE,
                    LAST_UPDATE_DATE,
                    LAST_UPDATED_BY,
                    LAST_UPDATE_LOGIN,
                    CREATION_DATE,
                    CREATED_BY,
                    --SHIPMENT_NUM,
                    VENDOR_ID,
                    VENDOR_SITE_ID,
                    SHIP_TO_ORGANIZATION_ID,
                    LOCATION_ID,
                    SHIPPED_DATE,
                    EXPECTED_RECEIPT_DATE,
                    EMPLOYEE_ID,
                    VALIDATION_FLAG)
       VALUES
                   (RCV_HEADERS_INTERFACE_S.NEXTVAL,
                    RCV_INTERFACE_GROUPS_S.NEXTVAL,
                    gv_status_code,
                    gv_source_code,
                    gv_transaction_new,
                    SYSDATE, -- last_update_date
                    pn_user_id, -- LAST_UPDATED_BY
                    pn_user_id,
                    SYSDATE, -- created_date 
                    pn_user_id, -- created by
                    --1, -- shipment_num
                    pn_vendor_id, -- vendor_id
                    pn_vendor_site_id, -- vendor_site_id
                    pn_org_id, -- org id
                    pn_location_id, -- location id
                    SYSDATE,
                    SYSDATE,
                    pn_user_id, -- id employe
                    'Y');

   gn_tot_ent_ok := gn_tot_ent_ok + 1;
         
            
EXCEPTION
         WHEN OTHERS
         THEN
              put_line_log ('Erreur lors de l insertion RHI : ' || SQLERRM(SQLCODE));
              gn_tot_ent_ko := gn_tot_ent_ko + 1; 
              pv_errbuf  := 'DKA_SPORECEP_FRAISPORT_PKG.insert_rcv_headers' || SQLERRM;
              pn_retcode := 1;

              RETURN;

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

PROCEDURE insert_rcv_transactions(
        pn_user_id                  IN  NUMBER,
        pn_quantity                 IN  NUMBER,
        pv_uom                      IN  VARCHAR2,
        pv_description              IN  VARCHAR2,
        pn_org_id                   IN  NUMBER,
        pn_vendor_id                IN  NUMBER,
        pn_vendor_site_id           IN  NUMBER,        
        pn_header_id                IN  NUMBER,
        pn_line_id                  IN  NUMBER,
        pn_line_location_id         IN  NUMBER,        
        pv_errbuf                   OUT VARCHAR2,
        pn_retcode                  OUT NUMBER)

IS

BEGIN

       -- Insertion d'une ligne dans la table RCV_TRANSACTIONS_INTERFACE 
       INSERT INTO RCV_TRANSACTIONS_INTERFACE 
                   (INTERFACE_TRANSACTION_ID,
                    GROUP_ID,
                    LAST_UPDATE_DATE,
                    LAST_UPDATED_BY,
                    CREATION_DATE,
                    CREATED_BY, 
                    LAST_UPDATE_LOGIN,
                    TRANSACTION_TYPE,
                    TRANSACTION_DATE,
                    PROCESSING_STATUS_CODE,
                    PROCESSING_MODE_CODE,
                    TRANSACTION_STATUS_CODE,
                    QUANTITY,
                    UNIT_OF_MEASURE,
                    ITEM_DESCRIPTION,  
                    AUTO_TRANSACT_CODE,
                    RECEIPT_SOURCE_CODE,
                    VENDOR_ID,
                    VENDOR_SITE_ID,
                    TO_ORGANIZATION_ID,
                    SOURCE_DOCUMENT_CODE,
                    PO_HEADER_ID,
                    PO_LINE_ID,
                    PO_LINE_LOCATION_ID,
                    HEADER_INTERFACE_ID,                    
                    VALIDATION_FLAG)
       VALUES 
                   (RCV_TRANSACTIONS_INTERFACE_S.NEXTVAL,
                    RCV_INTERFACE_GROUPS_S.CURRVAL,
                    SYSDATE,
                    pn_user_id, 
                    SYSDATE, 
                    pn_user_id, 
                    pn_user_id,
                    gv_transaction_type,
                    SYSDATE,
                    gv_status_code, 
                    gv_mode_code,
                    gv_status_code,
                    pn_quantity, 
                    pv_uom,
                    pv_description,
                    gv_transaction_auto, -- Modif TB 12/03/2007 : gv_transaction_type,
                    gv_source_code,
                    pn_vendor_id,
                    pn_vendor_site_id,                    
                    pn_org_id,
                    'PO',
                    pn_header_id, 
                    pn_line_id, 
                    pn_line_location_id,
                    RCV_HEADERS_INTERFACE_S.CURRVAL,
                    'Y');


EXCEPTION
         WHEN OTHERS
         THEN
              put_line_log ('Erreur lors de l insertion RTI : ' || SQLERRM(SQLCODE));
              pn_retcode := 1;
              pv_errbuf  := 'DKA_SPORECEP_FRAISPORT_PKG.insert_rcv_transactions' || SQLERRM;
              RETURN;

END insert_rcv_transactions;


---------------------------------------------------------------------------------------------------------------
--  Nom           : insert_suivi
--  Description   : Procédure d'insertion d'une ligne dans l'interface des entetes
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

PROCEDURE insert_suivi(
        pv_num_commande             IN  VARCHAR2,
        pn_commande_id              IN  NUMBER,
        pv_num_ligne                IN  VARCHAR2,
        pn_ligne_id                 IN  VARCHAR2,
        pn_vendor_id                IN  NUMBER,
        pn_vendor_site_id           IN  NUMBER,
        pv_errbuf                   OUT VARCHAR2,
        pn_retcode                  OUT NUMBER)

IS
        pn_group_id       NUMBER;
                 
BEGIN

       -- Récupération du group_id
       SELECT  RCV_INTERFACE_GROUPS_S.CURRVAL
       INTO    pn_group_id
       FROM    dual;
     
       -- Insertion d'une ligne dans la table RCV_HEADERS_INTERFACE 
       INSERT INTO DKA_SPORECEP_TMP
                   (BATCH_ID,
                    NUM_COMMANDE,
                    COMMANDE_ID,
                    NUM_LIGNE,
                    LINE_ID,
                    VENDOR_ID,
                    VENDOR_SITE_ID,
                    PROCESSING_DATE)
       VALUES
                   (pn_group_id,
                    pv_num_commande,
                    pn_commande_id,
                    pv_num_ligne,
                    pn_ligne_id,
                    pn_vendor_id,
                    pn_vendor_site_id,
                    SYSDATE);


         
            
EXCEPTION
         WHEN OTHERS
         THEN
              put_line_log ('Erreur lors de l insertion dans la table de suivi : ' || SQLERRM(SQLCODE));
              pv_errbuf  := 'DKA_SPORECEP_FRAISPORT_PKG.insert_suivi' || SQLERRM;
              pn_retcode := 1;

              RETURN;

END insert_suivi;

---------------------------------------------------------------------------------------------------------------
--  Nom           : update_suivi
--  Description   : Procédure d'insertion d'une ligne dans l'interface des entetes
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

PROCEDURE update_suivi(
        pv_errbuf                   OUT VARCHAR2,
        pn_retcode                  OUT NUMBER)

IS
                 
BEGIN

     -- Mise a jour du statut des commandes traitées
     put_line_log ('>>>>> Mise a jour de la table de suivi');
     UPDATE DKA_SPORECEP_TMP dst
     SET    dst.STATUT        = (SELECT rhi.processing_status_code FROM rcv_headers_interface rhi
                                 WHERE rhi.group_id = dst.BATCH_ID);
     COMMIT;

     -- Mise a jour du message d'erreur pour les lignes rejetées
     put_line_log ('>>>>> Mise a jour du message d''erreur pour les lignes rejetées');
     UPDATE DKA_SPORECEP_TMP dst
     SET   dst.ERROR_MESSAGE    = (SELECT pie.error_message FROM po_interface_errors pie
                                   WHERE pie.batch_id = dst.BATCH_ID
                                   AND table_name != 'RCV_HEADERS_INTERFACE' -- Modif TB 15/05/2007
                                   AND ROWNUM = 1)
     WHERE dst.STATUT = 'ERROR';

     COMMIT;
     
     -- Mise a jour du numéro de réception pour les lignes acceptées
     put_line_log ('>>>>> Mise a jour du numéro de réception pour les lignes acceptées');
     UPDATE DKA_SPORECEP_TMP dst
     SET    dst.receipt_num    = (SELECT rsh.receipt_num FROM rcv_headers_interface rhi, RCV_SHIPMENT_HEADERS rsh
                                  WHERE rhi.receipt_header_id = rsh.shipment_header_id
                                    AND rhi.group_id = dst.BATCH_ID)
     WHERE dst.STATUT = 'SUCCESS';

     COMMIT;
            
EXCEPTION
         WHEN OTHERS
         THEN
              put_line_log ('>>>>> Erreur lors de la mise a jour de la table de suivi : ' || SQLERRM(SQLCODE));
              pv_errbuf  := 'DKA_SPORECEP_FRAISPORT_PKG.update_suivi' || SQLERRM;
              pn_retcode := 1;

              RETURN;

END update_suivi;
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

      PROCEDURE wait_RVCTP
       (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   IN OUT   NUMBER
        )
    IS

      Vb_Trash                      BOOLEAN;
      Vv_Phase                      VARCHAR2(50);
      Vv_Status                     VARCHAR2(50);
      Vv_Dev_Phase                  VARCHAR2(50);
      Vv_Dev_Status                 VARCHAR2 (50);
      Vv_Message                    VARCHAR2 (50);

    BEGIN

          -- Attente de la fin d'execution des programmes
          Vb_Trash := FND_CONCURRENT.WAIT_FOR_REQUEST ( Vn_Request_Id_PORVCTP, -- REQUEST_ID
                                            10                     , -- INTERVAL
                                            0                      , -- MAX_WAIT (pas de delai)
                                            Vv_Phase               , -- PHASE
                                            Vv_Status              , -- STATUS
                                            Vv_Dev_Phase           , -- DEV_PHASE
                                            Vv_Dev_Status          , -- DEV_STATUS
                                            Vv_Message               -- MESSAGE
                                          );

         IF not Vb_Trash Then
            pv_errbuf     := pv_errbuf || 'Pb dans l attente wait_RVCTP';
         END IF;

         IF Vv_Status = 'Erreur' Then
            pv_errbuf := pv_errbuf || Vv_Message ;
         END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            pv_errbuf     := 'sortie de wait_RVCTP avec erreur EXCEPTION OTHERS:' || SQLERRM;
            pn_retcode    := 2;
    END wait_RVCTP;
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
PROCEDURE main (
    pv_errbuf                  OUT      VARCHAR2,
    pn_retcode                 OUT      NUMBER,
    vd_date_deb                IN       VARCHAR2,
    vd_date_fin                IN       VARCHAR2
)
IS       
         -- Récupération des dates passées comme parametre
         pd_date_deb    VARCHAR2(11);
         pd_date_fin    VARCHAR2(11);
                          
        --Liste des commandes a traiter
        CURSOR cur_commandes
        IS
          SELECT DISTINCT rt.po_header_id header_id
          FROM   rcv_transactions rt
          WHERE ( trunc(rt.creation_date) BETWEEN pd_date_deb AND pd_date_fin
           AND rt.Last_Update_Date >= pd_date_deb -- RCV_TRANSACTIONS_N23
               AND EXISTS (SELECT 'X'
                           FROM   po_lines_all pl,
                                  po_line_locations_all pll
                           WHERE  pl.po_line_id = pll.po_line_id
                             AND  rt.po_header_id = pl.po_header_id
                             AND  nvl(pl.attribute1,' ') != 'A'
                             AND  EXISTS ( SELECT 'X'
                                           FROM  po_lines_all pl2,
                                                 po_line_locations_all pll2
                                           WHERE pl2.po_line_id = pll2.po_line_id
                                             AND rt.po_header_id = pl2.po_header_id
                                             AND nvl(pl2.attribute1,' ') = 'A'
                                             AND nvl(pl2.cancel_flag,'N') = 'N' -- Ligne non annulée
                                             AND nvl(pl2.closed_code,'OPEN') IN ('OPEN','CLOSED FOR INVOICE') -- Ligne non fermée                                                                                     
                                           HAVING  ( SUM (pll2.quantity) - SUM (pll2.quantity_received) ) > 0 )
                           HAVING (SUM (pll.quantity) - SUM (pll.quantity_received)) <=0))
             OR
                 EXISTS (SELECT 'X'
                         FROM   po_lines_all pl,
                                po_line_locations_all pll
                         WHERE  pl.po_line_id = pll.po_line_id
                           AND  rt.po_header_id = pl.po_header_id
                           AND  nvl(pl.attribute1,' ') != 'A'
                           AND  EXISTS ( SELECT 'X'
                                         FROM  po_lines_all pl2,
                                               po_line_locations_all pll2
                                         WHERE pl2.po_line_id = pll2.po_line_id
                                           AND rt.po_header_id = pl2.po_header_id
                                           AND nvl(pl2.attribute1,' ') = 'A'
                                           AND nvl(pl2.cancel_flag,'N') = 'N' -- Ligne non annulée
                                           AND nvl(pl2.closed_code,'OPEN') IN ('OPEN','CLOSED FOR INVOICE') -- Ligne non fermée 
                                           AND trunc(pl2.creation_date) BETWEEN pd_date_deb AND pd_date_fin                                                                                      
                                         HAVING  ( SUM (pll2.quantity) - SUM (pll2.quantity_received) ) > 0 )
                         HAVING (SUM (pll.quantity) - SUM (pll.quantity_received)) <=0);
              
        rec_commandes          cur_commandes%ROWTYPE;

        --Liste des informations sur les lignes a réceptionner
        CURSOR cur_lignes (pn_header_id NUMBER)
        IS
          SELECT ph.po_header_id               po_header_id,
                 ph.segment1                   segment1,
                 pl.line_num                   line_num,
                 pl.po_line_id                 po_line_id,       
                 pl.item_description           item_description,
                 pl.quantity                   quantity,
                 pll.line_location_id          line_location_id,
                 ph.vendor_id                  vendor_id,
                 ph.vendor_site_id             vendor_site_id,
                 pll.ship_to_location_id       ship_to_location_id,
                 pll.ship_to_organization_id   ship_to_organization_id,
                 pl.category_id                category_id,
                 uom.UOM_CODE                  UOM_CODE,
                 pl.unit_meas_lookup_code      unit_meas_lookup_code,
                 pl.created_by                 created_by,
                 pda.po_distribution_id        po_distribution_id
          FROM   po_distributions_all pda,
                 po_lines_all pl,
                 po_headers_all ph,
                 po_vendors pv,
                 po_line_locations_all pll,
                 MTL_UNITS_OF_MEASURE uom
          WHERE  pda.po_line_id = pl.po_line_id
            AND  pda.po_header_id = ph.po_header_id
            AND  ph.vendor_id = pv.vendor_id
            AND  nvl(pl.cancel_flag,'N') != 'Y' -- Modif TB 15/05/2007
            AND  pl.po_line_id = pll.po_line_id
            and  nvl(pl.attribute1,' ') = 'A'
            AND  pl.unit_meas_lookup_code = uom.UNIT_OF_MEASURE
            AND  ph.po_header_id = pn_header_id ;
            
          rec_lignes          cur_lignes%ROWTYPE;
        
        CURSOR cur_suivi(status VARCHAR2) IS
            SELECT BATCH_ID,
                   NUM_COMMANDE,
                   COMMANDE_ID,
                   NUM_LIGNE,
                   LINE_ID,
                   VENDOR_ID,
                   VENDOR_SITE_ID,
                   RECEIPT_NUM,
                   ERROR_MESSAGE,
                   STATUT,
                   PROCESSING_DATE
            FROM   DKA_SPORECEP_TMP
            WHERE  STATUT = status;

          rec_suivi                     cur_suivi%ROWTYPE;
          
    BEGIN
        --- Appel de la procédure INIT pour l'initialisation de parametres globaux
        put_line_out ('<< INITIALISATION DES PARAMETRES GLOBAUX >>');
        put_line_log ('<< INITIALISATION DES PARAMETRES GLOBAUX >>');
        init ('TRANSFER',pv_errbuf,pn_retcode);
        put_line_log ('');
        put_line_out ('');

        pd_date_deb       := to_date (vd_date_deb,'YYYY/MM/DD HH24:MI:SS');
        pd_date_fin       := to_date (vd_date_fin,'YYYY/MM/DD HH24:MI:SS');

        put_line_out ('<<< LISTE DES LIGNES DE COMMANDES DU '|| pd_date_deb ||' AU '||pd_date_fin||' A TRAITER  >>>');

        -- Boucle sur les commandes
        put_line_log ('<<< OUVERTURE DE LA BOUCLE SUR LES COMMANDES DU '||pd_date_deb||' AU '||pd_date_fin||' >>>');
        OPEN cur_commandes;
        LOOP
            FETCH cur_commandes INTO rec_commandes;
            EXIT WHEN cur_commandes%NOTFOUND;                

                -- Boucle sur les lignes
                OPEN cur_lignes(rec_commandes.header_id);
                LOOP
                    FETCH cur_lignes INTO rec_lignes;
                     EXIT WHEN cur_lignes%NOTFOUND;

                        -- Insertion des infos de la table des entetes
                        insert_rcv_headers(rec_lignes.created_by,
                                           rec_lignes.vendor_id,
                                           rec_lignes.vendor_site_id,
                                           rec_lignes.ship_to_location_id,
                                           rec_lignes.ship_to_organization_id,
                                           gv_errbuf,
                                           gn_retcode);

                       put_line_out ('Commande n°'||rec_lignes.segment1||' (id = '
                                     ||rec_lignes.po_header_id||') pour la ligne n°'||rec_lignes.line_num
                                     ||' (id = '||rec_lignes.po_line_id||')'); 

                        -- Insertion des infos de la table des lignes
                        insert_rcv_transactions(rec_lignes.created_by,
                                                rec_lignes.quantity,
                                                rec_lignes.unit_meas_lookup_code,
                                                rec_lignes.item_description,
                                                rec_lignes.ship_to_organization_id,
                                                rec_lignes.vendor_id,
                                                rec_lignes.vendor_site_id,                                                
                                                rec_lignes.po_header_id,
                                                rec_lignes.po_line_id,
                                                rec_lignes.line_location_id,
                                                gv_errbuf,
                                                gn_retcode);

                        -- Insertion des infos de la table de suivi
                        insert_suivi (rec_lignes.segment1,
                                      rec_lignes.po_header_id,
                                      rec_lignes.line_num,
                                      rec_lignes.po_line_id,
                                      rec_lignes.vendor_id,
                                      rec_lignes.vendor_site_id,
                                      gv_errbuf,
                                      gn_retcode);                                                
                                                
                END LOOP;   -- Pour chaque ligne trouvée
                -- Fin normale
                COMMIT;
                CLOSE cur_lignes;        


        END LOOP;   -- Pour chaque commandes trouvée
        -- Fin normale
        COMMIT;                        
        CLOSE cur_commandes;

        put_line_log ('>>> Nombre De Commandes Traitées : '||gn_tot_ent_ok);                
        put_line_log ('<<< FERMETURE DE LA BOUCLE SUR LES COMMANDES >>>');        
        put_line_out (' => Nombre De Commandes Traitées : '||gn_tot_ent_ok);

        -- Si des commandes ont été trouvées, lancement de l'interface des réceptions 
        IF gn_tot_ent_ok !=0 THEN
        
           -- Lancement de l'interface standard
           put_line_log ('');
           put_line_log ('<<<< LANCEMENT DE L''INTERFACE STANDARD RVCTP >>>>');
           Vn_Request_Id_PORVCTP   := Fnd_Request.Submit_Request (
                                   'PO'	          -- APPLICATION SHORT NAME
                                 , 'RVCTP'        -- CONCURRENT PROGRAM NAME
                                 , NULL           -- DESCRIPTION
                                 , NULL           -- START
                                 , FALSE          -- SUB_REQUEST
    			 				                                -- ARGUMENTS
                                 , 'BATCH'        -- mode
                                 , NULL           -- batch_id
                                 , NULL           -- org_id 
                              );


                              -- Validation pour soumettre le traitement
                              COMMIT;
       
           IF Vn_Request_Id_PORVCTP = 0
           THEN
               pv_errbuf := '!!!! Erreur lors de la soumission du programme d''import des réceptions. ';
               dka_tools_pkg.put_outdebug_message (Pv_errbuf);
               dka_tools_pkg.put_outdebug_message (Fnd_Message.Get);
               -- Sortie en erreur
               pn_Retcode := 2;
           END IF;       
       
           -- Attente fin du traitement
           put_line_log ('>>>> Attente fin de l''interface standard RVCTP');
           wait_rvctp(gv_errbuf,gn_retcode);
           put_line_log ('<<<< SORTIE DE L''INTERFACE STANDARD RVCTP >>>>');
        
           -- Impression du compte-rendu du traitement
           put_line_log ('');
           put_line_log ('<<<<< MISE A JOUR DU SUIVI DES COMMANDES TRAITEES ET REJETEES >>>>>');
           
           update_suivi(  gv_errbuf,gn_retcode);
           
           put_line_log ('<<<<< FIN DE LA MISE A JOUR DU SUIVI DES COMMANDES TRAITEES ET REJETEES >>>>>');       

           put_line_out ('');
           put_line_out('<<<< LISTE DES COMMANDES RECEPTIONNEES >>>>');
           put_line_log ('');
           put_line_log ('<<<<<< AFFICHAGE DES COMMANDES TRAITEES ET REJETEES >>>>>>');

           OPEN cur_suivi('SUCCESS');
           LOOP
               FETCH cur_suivi INTO rec_suivi;
               EXIT WHEN cur_suivi%NOTFOUND;

               put_line_out('OK pour Réception n°'|| rec_suivi.RECEIPT_NUM
                            ||' pour la Commande n°'||rec_suivi.NUM_COMMANDE 
                            ||' (id = '||rec_suivi.COMMANDE_ID||') et Ligne n°'
                            ||rec_suivi.NUM_LIGNE ||' (id = '||rec_suivi.LINE_ID||')');
               gn_tot_lig_ok := gn_tot_lig_ok + 1;
           END LOOP;
           CLOSE cur_suivi; 
       
           put_line_out ('');
           put_line_out('<<<< LISTE DES RECEPTIONS REJETES >>>>');
       
           OPEN cur_suivi('ERROR');
           LOOP
               FETCH cur_suivi INTO rec_suivi;
               EXIT WHEN cur_suivi%NOTFOUND;

               put_line_out('ERREUR pour Commande n°'||rec_suivi.NUM_COMMANDE||' (id = '
                            ||rec_suivi.COMMANDE_ID||')  Motif du Rejet : '
                            ||rec_suivi.ERROR_MESSAGE ); 
               gn_tot_lig_ko := gn_tot_lig_ko + 1;
           END LOOP;
           CLOSE cur_suivi;                             
               
           put_line_out ('');
           put_line_out (' => Nombre de commandes réceptionnées : ' || gn_tot_lig_ok);
           put_line_out (' => Nombre de réceptions rejetées : ' || gn_tot_lig_ko);
           put_line_log ('>>>>>> Nombre de commandes réceptionnées : ' || gn_tot_lig_ok);
           put_line_log ('>>>>>> Nombre de réceptions rejetées : ' || gn_tot_lig_ko);
           
           -- Si lignes rejetées => Traitement en Avertissement
           IF gn_tot_lig_ko != 0
           THEN
               pn_retcode       :=1;
               pv_errbuf        := gn_tot_lig_ko || 'ligne(s) de réceptions rejetée(s)'; 
           END IF;

           put_line_log ('<<<<<< FIN DE L''AFFICHAGE DES COMMANDES TRAITEES ET REJETEES >>>>>>');
           
       ELSE -- Aucune commande a traiter
       put_line_out ('');
       put_line_out ('<<<< Aucune commande a traiter : Sortie du traitement >>>>');
       put_line_log ('');
       put_line_log ('<<<< Aucune commande a traiter : Sortie du traitement >>>>');

       
       END IF;

       -- Mise a jour de la date de derniere éxécution
      UPDATE   dka_parameters dp
        SET dp.date_value = pd_date_fin
      WHERE dp.program_code = 'DKA_SPORECEP'
        AND dp.parameter_name = 'DATE_FIN';

       put_line_out ('');
       put_line_out ('<< Mise a jour de la derniere date de fin de sélection ('||pd_date_fin||') >>');
       put_line_log ('');
       put_line_log ('<< Mise a jour de la derniere date de fin de sélection ('||pd_date_fin||') >>');
       
    EXCEPTION
        WHEN e_trt
        THEN
            ROLLBACK;
            pn_retcode    := gn_retcode;
            pv_errbuf     := Substr(gv_errbuf, 1, 80);
        WHEN OTHERS
        THEN
            ROLLBACK;
            pn_retcode    := SQLCODE;
            pv_errbuf     := 'DKA_SPORECEP_FRAISPORT_PKG.main' || Substr(SQLERRM, 1, 80);
    END main;
    
END DKA_SPORECEP_FRAISPORT_PKG;
/
SHOW ERRORS;
EXIT  
