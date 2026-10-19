set define off
CREATE OR REPLACE PACKAGE BODY dka_sapwfcspntf_pkg AS
  ---------------------------------------------------------------------------------------------------------------
  -- $Id: $
  --
  -- CAPGEMINI
  -- PROJET      : Helios
  -- NOM         : DKA_SAPWFCSP_PKG.pkb
  -- DESCRIPTION : DKA_SAPWFCSP_PKG package body :
  ---
  --- AUTEUR       : Nicolas BOUSSEKEYT (CAPGEMINI)
  --- DATE DE CREATION : 29/04/2019
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
  ---------------------------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- 17/04/2020 - MTIA - TASK0111380 - Besoin complémentaire à l'évolution EDB236 - Ajouter une ligne dans l'historique d'approbation
  --- 23/12/2021 - AFE - TASK0162876 : Ajout HINT + ajout to_char pour éviter le plantage du traitement
  --- 19/01/2021 - AFE - TASK0165199 : Regression suite MEP TASK0162876
  --- ---------- --- --------------------------------------------------------------------------------------------
  ---------------------------------------------------------------------------------------------------------------

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PUBLIQUES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PRIVEES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  -------------------------------------------------------------------------------------
  --  Nom           : main
  --  Description   : lance le traitement d'annulation des workflows pour chaque facture ayant des notifications avec des factures OI ou AP
  --                geree par CSP
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --
  -------------------------------------------------------------------------------------
  PROCEDURE main(pv_errbuf OUT VARCHAR2, pn_retcode IN OUT NUMBER) IS
    CURSOR cur_wi IS
      SELECT 
             substr(wn.context, 9, instr(CONTEXT, '_', -1) - 9) invoice_id,
             wn.context,
             substr(wn.context, 9, instr(CONTEXT, ':', -2) - 9) item_id,
             wn.NOTIFICATION_ID,
             wn.subject,
             wn.message_name,
             wn.ITEM_KEY,
             'OI' as Type_notif
        FROM wf_notifications wn
       WHERE status NOT IN ('CLOSED', 'CANCELED')
         AND message_type = 'DKA_CSP'
         and wn.message_name in
             (select /*+ INDEX(dsl DKA_STRANSCO_LINES_U1)*/ 
                dsl.PARAM1_VALUE
                from DKA_STRANSCO_HEADERS dsh, DKA_STRANSCO_LINES dsl
               where dsl.SET_ID = dsh.SET_ID
                 and dsh.SET_NAME = 'DKA_NOTIF_METIER'
                 and dsl.PARAM2_VALUE = to_char(0))
         AND NOT EXISTS
       (select 'X'
                from ap_invoices_interface aii
               where aii.global_attribute2 = wn.message_type
                 and aii.global_attribute3 = wn.item_key)
      UNION
      SELECT substr(wn.context, 9, instr(CONTEXT, '_', -1) - 9) invoice_id,
             wn.context,
             substr(wn.context, 9, instr(CONTEXT, ':', -2) - 9) item_id,
             wn.NOTIFICATION_ID,
             wn.subject,
             wn.message_name,
             wn.ITEM_KEY,
             'AP' as Type_notif
        FROM wf_notifications wn
       WHERE status NOT IN ('CLOSED', 'CANCELED')
         AND message_type = 'DKA_CSP'
         and wn.message_name in
             (select /*+ INDEX(dsl DKA_STRANSCO_LINES_U1)*/ 
                dsl.PARAM1_VALUE
                from DKA_STRANSCO_HEADERS dsh, DKA_STRANSCO_LINES dsl
               where dsl.SET_ID = dsh.SET_ID
                 and dsh.SET_NAME = 'DKA_NOTIF_METIER'
                 and dsl.PARAM2_VALUE <> to_char(0))
         and 0 = (select COUNT(1)
                    from ap_holds_all aha
                   where SUBSTR(wn.context,
                                INSTR(wn.context, ':') + 1,
                                INSTR(wn.context, '_', 1, 2) -
                                INSTR(wn.context, ':') - 1) =
                         to_char(aha.invoice_id)
                     and aha.release_reason is null);
  
    l_result     VARCHAR2(20);
    l_count      NUMBER;
    l_historique NUMBER := 0;
    vn_iteration AP_INV_APRVL_HIST.ITERATION%type;
    ln_hist_id   AP_INV_APRVL_HIST.APPROVAL_HISTORY_ID%type;
    ln_amount    ap_invoices_all.invoice_amount%TYPE;
    ln_org_id    ap_invoices_all.org_id%type;
  BEGIN
    pn_retcode := 0;
  
    FOR rec_wi IN cur_wi LOOP
      l_historique := 0;
      dka_tools_pkg.put_log_message('Annulation de l''item_id : ' ||
                                    rec_wi.item_id);
      dka_tools_pkg.put_log_message('notification_id : ' ||
                                    rec_wi.notification_id);
    
      select count(1)
        into l_count
        from wf_items
       where item_key = rec_wi.item_id
         and item_type = 'DKA_CSP'
         and end_date is null;
    
      IF l_count = 1 THEN
        wf_engine.abortprocess('DKA_CSP', rec_wi.item_id, NULL, l_result);
        if l_result is null then
          l_historique := 1;
        else
          l_historique := 0;
        end if;
      ELSE
        SELECT count(1)
          into l_count
          FROM wf_notifications wn
         WHERE wn.status NOT IN ('CLOSED', 'CANCELED')
           AND wn.NOTIFICATION_ID = rec_wi.notification_id;
      
        IF l_count = 1 THEN
          wf_notification.cancel(nid            => rec_wi.notification_id,
                                 cancel_comment => 'Annulation par traitement');
          l_historique := 1;
        END IF;
      END IF;
    
      --MTIA : 17/04/2020 - TASK0111380 - Besoin complémentaire à l'évolution EDB236 - Ajouter une ligne dans l'historique d'approbation
      IF rec_wi.type_notif = 'AP' and l_historique = 1 then
        --MOAC
        MO_GLOBAL.INIT(p_appl_short_name => 'SQLAP');
      
        vn_iteration := substr(rec_wi.ITEM_ID,
                               instr(rec_wi.ITEM_ID, '_') + 1,
                               length(rec_wi.ITEM_ID));
        --insert into the history table
        SELECT AP_INV_APRVL_HIST_S.nextval INTO ln_hist_id FROM dual;
      
        SELECT invoice_amount, org_id
          INTO ln_amount, ln_org_id
          FROM AP_INVOICES_ALL
         WHERE invoice_id = rec_wi.invoice_id;
      
        INSERT INTO AP_INV_APRVL_HIST
          (APPROVAL_HISTORY_ID,
           INVOICE_ID,
           ITERATION,
           APPROVER_COMMENTS,
           APPROVER_ID,
           APPROVER_NAME,
           AMOUNT_APPROVED,
           CREATED_BY,
           CREATION_DATE,
           LAST_UPDATE_DATE,
           LAST_UPDATED_BY,
           LAST_UPDATE_LOGIN,
           ORG_ID)
        VALUES
          (ln_hist_id,
           rec_wi.invoice_id,
           vn_iteration,
           'Annulé par le traitement notification WF obsolète',
           null,
           'EXPLOITATION',
           ln_amount,
           1205,
           sysdate,
           sysdate,
           1205,
           1205,
           ln_org_id);
      
      END IF;
    
      COMMIT;
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'DKA_SAPWFCSPNTF_pkg.MAIN : ' || SQLERRM;
      pn_retcode := 2;
      dka_tools_pkg.put_log_message('DKA_SAPWFCSPNTF_pkg.MAIN : ' ||
                                    SQLERRM);
  END;

END dka_sapwfcspntf_pkg; -- Corps du package
/
SHOW ERROR PACKAGE BODY DKA_SAPWFCSP_PKG;
EXIT
