set define off

set define off

CREATE OR REPLACE PACKAGE BODY dka_sapwfcsp_ivalua_pkg IS
  --------------------------------------------------------------------------------
  -- $Id: DKA_SAPWFCSP_IVALUA_PKG.pkb  $
  -- Capgemini
  -- Projet           :
  -- Nom              : DKA_SAPWFCSP_IVALUA_PKG.pkb
  -- Description      : Corps du package DKA_SAPWFCSP_IVALUA_PKG
  -- Auteur           : Asma AMENKOUR
  -- Date de création : 12/10/2020
  -- Commentaires     :
  --------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- ---------- --- --------------------------------------------------------------------------------------------
  --- 2020/10/30 NBO Ajout des modifications workflow
  --- 2020/12/15 NBO SPE129 - Anomalies sur WF n°2B
  --- 2021/03/23 NBO -SPE129 - Anomalies sur WF 2B - REWORK PRODUCTION
  --- 2021/05/06 NBO - ACHATS_DGE20210003_EDB278-F - PFAD - SPE129 - MODIFICATION NOTIFICATIONS DU WORKFLOW
  --- 2022/02/27 ARA - EDB278-H - DGE20210019 - Factures WF1B - Validation auto des notifications de frais + 
  ---                  INC0585970 - Problème mise à jour des champs lors de la levée des blocages En attente WF 1B
  --- 2022/10/10 ARA - Complément de l'EDB278-H (Auto approbation du blocage en attente avec la présence d'autres blocages)
  --- 2025/04/17 ARA - EDB428 - Oracle AP - Levée des blocages de type écart à réception du BAP Ivalua dans Oracle
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PUBLIQUES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  cv_code_blocage_ivalua ap_holds_all.hold_lookup_code%TYPE := 'En attente';
  cv_ano_imput_attente   ap_holds_all.hold_lookup_code%TYPE := 'Imputation en attente';
  cv_litige_BAP          ap_holds_all.hold_lookup_code%TYPE := 'En litige BAP';
  cv_ano_qty_rec         ap_holds_all.hold_lookup_code%type := 'QTY REC'; -- ARA EDB428

  PROCEDURE update_data(p_user_id    IN NUMBER,
                        p_facture_id IN NUMBER,
                        p_emp        IN VARCHAR2,
                        p_return_status OUT NUMBER,
                        p_error_message OUT VARCHAR2) IS
    v_emp_id           per_people_f.person_id%TYPE;
    v_amount           ap_invoices_all.invoice_amount%TYPE;
    v_hold_id          ap_holds_all.hold_id%TYPE;
    v_attribute5       ap_holds_all.attribute5%TYPE;
    v_description      fnd_flex_values_tl.description%TYPE;
    v_hold_lookup_code ap_holds_all.hold_lookup_code%TYPE;
    v_wf_type          ap_holds_all.attribute1%TYPE;
    v_wf_key           ap_holds_all.attribute2%TYPE;
    v_notif_id         wf_notifications.notification_id%TYPE;
    v_status           wf_notifications.status%TYPE;
    v_recipient_role   wf_notifications.recipient_role%TYPE;
    v_username         VARCHAR2(50); 
    lv_comment         VARCHAR2(1000) := 'Accept From Backend';
    l_step             VARCHAR2(50);
    
  BEGIN
    l_step := 'BEGIN';
    
    p_return_status := 0;
    
    BEGIN
      SELECT person_id
        INTO v_emp_id
        FROM per_people_f ppf
       WHERE full_name = p_emp
         AND ppf.current_employee_flag = 'Y'
         AND SYSDATE BETWEEN nvl(ppf.effective_start_date, SYSDATE) AND
             nvl(ppf.effective_end_date, SYSDATE);
    EXCEPTION
      WHEN OTHERS THEN
        SELECT person_id
          INTO v_emp_id
          FROM per_people_f ppf
         WHERE full_name = p_emp
           AND ppf.current_employee_flag = 'Y'
           AND SYSDATE BETWEEN nvl(ppf.effective_start_date, SYSDATE) AND
               nvl(ppf.effective_end_date, SYSDATE)
           AND rownum = 1;
    END;
    
    l_step := 'INVOICE AMOUNT';

    SELECT invoice_amount
      INTO v_amount
      FROM ap_invoices_all
     WHERE invoice_id = p_facture_id;

    l_step := 'AP_HOLDS';
    
    SELECT hold_id, attribute5, hold_lookup_code, attribute1, attribute2
      INTO v_hold_id, v_attribute5, v_hold_lookup_code, v_wf_type, v_wf_key
      FROM ap_holds_all
     WHERE invoice_id = p_facture_id
       AND hold_lookup_code = 'En attente'
       AND release_lookup_code is null;
       
     l_step := 'DESCRIPTION';

    SELECT ffvt.description
      INTO v_description
      FROM fnd_flex_value_sets ffvs,
           fnd_flex_values     ffv,
           fnd_flex_values_tl  ffvt
     WHERE ffvs.flex_value_set_id = ffv.flex_value_set_id
       AND ffv.flex_value_id = ffvt.flex_value_id
       AND ffvt.language = userenv('LANG')
       AND ffvs.flex_value_set_name = 'DKA_TYPE_BLOCAGE_EN_ATTENTE'
       AND ffv.flex_value = v_attribute5;

    l_step := 'AP_HOLDS UPDATE';

    dka_sapwfcsp_pkg.print_wf_message(v_wf_type, 
                                      v_wf_key,
                                      'v_emp_id='|| v_emp_id,
                                      dka_sapwfcsp_pkg.cn_mode_debug);
    dka_sapwfcsp_pkg.print_wf_message(v_wf_type, 
                                      v_wf_key,
                                      'p_user_id='|| p_user_id,
                                      dka_sapwfcsp_pkg.cn_mode_debug);     
    UPDATE ap_holds_all
       SET attribute6       = v_emp_id,
           attribute4       = 'Y',
           last_update_date = SYSDATE,
           last_updated_by  = nvl(p_user_id,fnd_global.user_id),
           last_update_login = fnd_global.LOGIN_ID
     WHERE invoice_id = p_facture_id
       AND hold_lookup_code = 'En attente'
       AND release_lookup_code is null;
       
    /*l_step := 'ap_inv_aprvl_hist_all';

    UPDATE ap_inv_aprvl_hist_all
       SET response          = 'DKA_TRANSFERT_IVALUA',
           approver_name     = p_emp,
           amount_approved   = v_amount,
           approver_comments = v_hold_lookup_code || '-' || v_description,
           last_update_date  = SYSDATE,
           creation_date     = SYSDATE,
           last_updated_by   = v_emp_id,
           created_by        = v_emp_id,
           hold_id           = v_hold_id

     WHERE invoice_id = p_facture_id;*/

    l_step := 'NOTIFICATIONS';
        SELECT USER_NAME INTO v_recipient_role FROM fnd_user WHERE user_id = p_user_id;

      SELECT wn.notification_id, wn.status
        INTO v_notif_id, v_status
        FROM wf_notifications          wn,
             wf_item_activity_statuses was,
             wf_items                  wi
       WHERE 1 = 1
         AND wn.notification_id = was.notification_id
         AND was.item_type = wi.item_type
         AND was.item_key = wi.item_key
            -- AND wn.status IN ('OPEN', 'CANCELED')
         AND wi.item_key = v_wf_key
         AND wi.item_type = v_wf_type
         AND wn.message_name = 'DKA_MSG_DESTINATAIRE_IVALUA'
         AND wn.status = 'OPEN';

      wf_notification.setattrtext(v_notif_id, 'RESULT', 'SOUMETTRE');

      wf_notification.setattrtext(v_notif_id, 'Z_ACTION', 'DKA_APPROVE');
      
      wf_notification.respond(nid             => v_notif_id,
                              respond_comment => lv_comment,
                              responder       => v_recipient_role);

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      p_return_status := 2;
      p_error_message := l_step || ' : ' || SQLERRM;
      
  END;

  -------------------------------------------------------------------------------------
  --  Nom           : notif_CSP_ANO_IMPUT_ATT_IVALUA
  --  Description   :   Procedure gérant la notification que recoit CSP_ANO
  --                            pour une ano INPUTATION_EN_ATTENTE (etape 5)
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE notif_csp_ano_imput_att_ivalua(pv_itemtype  IN wf_items.item_type%TYPE,
                                           pv_itemkey   IN wf_items.item_key%TYPE,
                                           pn_actid     IN wf_item_activity_statuses_v.activity_id%TYPE, -- Ignore
                                           pv_funcmode  IN VARCHAR2,
                                           pv_resultout OUT NOCOPY VARCHAR2) IS

    vn_nid                         wf_notifications.notification_id%TYPE;
    vv_result                      VARCHAR2(100);
    vv_commentaires                ap_inv_aprvl_hist.approver_comments%TYPE;
    vv_nom_item_wf_stockage_action VARCHAR2(100);
    vv_nom_employe                 VARCHAR2(240);
    vv_url                         VARCHAR2(240);
    l_resp_csp                     VARCHAR2(300);
    vn_invoice_id                  NUMBER;
    ln_function_id                 NUMBER;
    l_session_user_id              NUMBER;
    l_session_resp_id              NUMBER;
    l_session_appl_id              NUMBER;

  BEGIN

    IF (pv_funcmode = 'TIMEOUT') THEN
      RETURN;
    END IF;

    IF (pv_funcmode <> wf_engine.eng_run AND pv_funcmode <> 'RESPOND') THEN
      -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
      l_session_resp_id := fnd_global.resp_id;
      l_session_appl_id := fnd_global.resp_appl_id;

      IF (l_session_resp_id = -1) THEN
        l_session_resp_id := NULL;
      END IF;

      IF (l_session_appl_id = -1) THEN
        l_session_appl_id := NULL;
      END IF;

      wf_engine.setitemattrnumber(itemtype => pv_itemtype,
                                  itemkey  => pv_itemkey,
                                  aname    => 'RESPONSIBILITY_ID',
                                  avalue   => l_session_resp_id);

      wf_engine.setitemattrnumber(itemtype => pv_itemtype,
                                  itemkey  => pv_itemkey,
                                  aname    => 'APPLICATION_ID',
                                  avalue   => l_session_appl_id);

      pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
      RETURN;

    END IF;
    dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'notif_CSP_ANO_IMPUT_ATT_IVALUA en pv_funcmode = ' ||
                                      pv_funcmode,
                                      dka_sapwfcsp_pkg.cn_mode_debug);
    vn_nid := wf_engine.context_nid;
    dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'nid: ' || vn_nid,
                                      dka_sapwfcsp_pkg.cn_mode_debug);
    
    
    l_resp_csp := wf_engine.getitemattrtext(itemtype => pv_itemtype,
                                  itemkey  => pv_itemkey,
                                  aname    => 'DKA_RESP_CSP_ANO');

    -- recupere le motif saisi
    vv_commentaires := wf_notification.getattrtext(vn_nid, 'DKA_COMMENTS');

    -- recupere la reponse
    vv_result := wf_notification.getattrtext(vn_nid, 'Z_ACTION');

    vv_nom_employe := wf_notification.getattrtext(vn_nid,
                                                  'FORWARD_TO_USERNAME_RESPONSE');

    IF (pv_funcmode = 'RESPOND') THEN
      -- Verifications
      IF vv_result = 'DKA_FORWARD_BAP' AND vv_nom_employe IS NULL THEN
        --          pv_resultout :='ERROR: You must enter an employee  if forwarding.';
        pv_resultout := wf_engine.eng_error || ':' ||
                        fnd_message.get_string('DKA', 'DKA_SAPWFCSP_E050');
        dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                          pv_itemkey,
                                          'retransmettre vide => DKA_SAPWFCSP_E050',
                                          dka_sapwfcsp_pkg.cn_mode_debug);
        RETURN;
      END IF;

      IF vv_commentaires IS NULL THEN
        pv_resultout := wf_engine.eng_error || ':' ||
                        fnd_message.get_string('DKA', 'DKA_SAPWFCSP_E051');
        RETURN;

      END IF;

      vn_invoice_id := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                                   itemkey  => pv_itemkey,
                                                   aname    => 'INVOICE_ID');

      IF vv_result IN ('DKA_FORWARD_IV4_ORDER_CLOSE',
                       'DKA_FORWARD_IV3_INV_WO_ORD',
                       'DKA_FORWARD_IV5_BAP_ERROR',
                       'DKA_FORWARD_IV6_LINE_UNPLAN') THEN
        SELECT function_id
          INTO ln_function_id
          FROM fnd_form_functions
         WHERE function_name = 'DKA_FACTURE_IVALUA';

        vv_url := fnd_run_function.get_run_function_url(p_function_id       => ln_function_id,
                                                        p_resp_appl_id      => NULL,
                                                        p_resp_id           => NULL,
                                                        p_security_group_id => 0,
                                                        p_parameters        => 'INVOICEID=' ||
                                                                               vn_invoice_id ||
                                                                               '&'||'ITEMKEY=' ||
                                                                               pv_itemkey,
                                                        p_override_agent    => NULL,
                                                        p_org_id            => NULL,
                                                        p_lang_code         => NULL,
                                                        p_encryptparameters => FALSE);

        wf_engine.setitemattrtext(itemtype => pv_itemtype,
                                  itemkey  => pv_itemkey,
                                  aname    => 'DKA_INVOICE_URL_IVALUA',
                                  avalue   => vv_url);
      END IF;

      -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
      l_session_user_id := fnd_global.user_id;
      l_session_resp_id := fnd_global.resp_id;
      l_session_appl_id := fnd_global.resp_appl_id;

      IF (l_session_user_id = -1) THEN
        l_session_user_id := NULL;
      END IF;

      IF (l_session_resp_id = -1) THEN
        l_session_resp_id := NULL;
      END IF;

      IF (l_session_appl_id = -1) THEN
        l_session_appl_id := NULL;
      END IF;

      wf_engine.setitemattrnumber(itemtype => pv_itemtype,
                                  itemkey  => pv_itemkey,
                                  aname    => 'RESPONDER_USER_ID',
                                  avalue   => l_session_user_id);

      wf_engine.setitemattrnumber(itemtype => pv_itemtype,
                                  itemkey  => pv_itemkey,
                                  aname    => 'RESPONDER_RESP_ID',
                                  avalue   => l_session_resp_id);
      wf_engine.setitemattrnumber(itemtype => pv_itemtype,
                                  itemkey  => pv_itemkey,
                                  aname    => 'RESPONDER_APPL_ID',
                                  avalue   => l_session_appl_id);

      wf_engine.setitemattrnumber(itemtype => pv_itemtype,
                                  itemkey  => pv_itemkey,
                                  aname    => 'RESPONSIBILITY_ID',
                                  avalue   => l_session_resp_id);

      wf_engine.setitemattrnumber(itemtype => pv_itemtype,
                                  itemkey  => pv_itemkey,
                                  aname    => 'APPLICATION_ID',
                                  avalue   => l_session_appl_id);

    END IF;

    IF (pv_funcmode = wf_engine.eng_run) THEN
      -- stocke la reponse dans l'items attribute du workflow passé en param
      vv_nom_item_wf_stockage_action := wf_notification.getattrtext(vn_nid,
                                                                    'DKA_G_W_ITEMATTR_REPONSE');

      wf_engine.setitemattrtext(itemtype => pv_itemtype,
                                itemkey  => pv_itemkey,
                                aname    => vv_nom_item_wf_stockage_action,
                                avalue   => vv_result);

      -- stocke qui fait l'action
      BEGIN
        wf_engine.setitemattrtext(itemtype => pv_itemtype,
                                  itemkey  => pv_itemkey,
                                  aname    => 'VALIDEUR_IMPUT',
                                  avalue   => wf_notification.responder(vn_nid));
      EXCEPTION
        WHEN OTHERS THEN
          -- gestion de l'exception pour que l'ancien WF fonctionne
          NULL;
      END;

      -- stocke l'employe vers qui on transfere
      -- 2021/03/23 NBO -SPE129 - Anomalies sur WF 2B - REWORK PRODUCTION
      wf_engine.setitemattrtext(itemtype => pv_itemtype,
                                itemkey  => pv_itemkey,
                                aname    => 'VALIDEUR_BAP',
                                --avalue   => wf_notification.responder(vn_nid));
                                avalue   => vv_nom_employe);

      --19012011 MT Resetting LIB_TITRE_DEMANDE_IMPUT_BAP itemkey value
      wf_engine.setitemattrtext(itemtype => pv_itemtype,
                                itemkey  => pv_itemkey,
                                aname    => 'LIB_TITRE_DEMANDE_IMPUT_BAP',
                                avalue   => dka_tools_pkg.get_message('DKA',
                                                                      'DKA_SAPWFCSP_E012'));
      IF vv_result IN ('DKA_FORWARD_IV4_ORDER_CLOSE',
                             'DKA_FORWARD_IV3_INV_WO_ORD',
                             'DKA_FORWARD_IV5_BAP_ERROR',
                             'DKA_FORWARD_IV6_LINE_UNPLAN') THEN
        -- historise l'action
        insert_history_ivalua(pv_itemtype,
                              pv_itemkey,
                              'DKA_SOUMIS',
                              cv_code_blocage_ivalua,
                              'Demande de saisie du destinataire IVALUA',
                              WF_DIRECTORY.GetRoleDisplayName(l_resp_csp));
      ELSE
        -- historise l'action
        insert_history_ivalua(pv_itemtype,
                pv_itemkey,
                vv_result,
                              cv_ano_imput_attente,
                              vv_commentaires);
       END IF;
        
        wf_engine.setitemattrtext(itemtype => pv_itemtype,
                                  itemkey  => pv_itemkey,
                                  aname    => 'VALIDEUR_IVALUA',
                                  avalue   => wf_notification.responder(vn_nid));
                           
    END IF;
    dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'notif_CSP_ANO_IMPUT_ATT_IVALUA fin',
                                      dka_sapwfcsp_pkg.cn_mode_debug);
  END notif_csp_ano_imput_att_ivalua;

  -------------------------------------------------------------------------------------
  --  Nom           : pose_blocage
  --  Description   : Procédure creant un blocage
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --                   Lookup YES/NO
  -------------------------------------------------------------------------------------
  PROCEDURE pose_blocage(pv_itemtype  IN wf_items.item_type%TYPE,
                         pv_itemkey   IN wf_items.item_key%TYPE,
                         pn_actid     IN wf_item_activity_statuses_v.activity_id%TYPE,
                         pv_funcmode  IN VARCHAR2,
                         pv_resultout OUT NOCOPY VARCHAR2) IS
    vn_invoice_id    ap_invoices_all.invoice_id%TYPE;
    vv_blocage_motif VARCHAR2(40);
    vv_motif_blocage ap_holds_all.hold_reason%TYPE;
    vn_user_id       fnd_user.user_id%TYPE;
    vn_retcode       NUMBER;
    vv_errbuf        VARCHAR2(100);
    vv_code_blocage  ap_lookup_codes.lookup_code%TYPE;
    vv_user_name     fnd_user.user_name%TYPE;

  BEGIN

    IF (pv_funcmode <> wf_engine.eng_run) THEN

      pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
      RETURN;
    END IF;

    dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'pose_blocage debut',
                                      dka_sapwfcsp_pkg.cn_mode_debug);
    vn_invoice_id := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                                 itemkey  => pv_itemkey,
                                                 aname    => 'INVOICE_ID');

    dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'pose_blocage  vn_invoice_id= ' ||
                                      vn_invoice_id,
                                      dka_sapwfcsp_pkg.cn_mode_debug);

    vv_code_blocage := wf_engine.getactivityattrtext(actid    => pn_actid,
                                                     itemtype => pv_itemtype,
                                                     itemkey  => pv_itemkey,
                                                     aname    => 'DKA_TYPE_BLOCAGE');

    dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'pose_blocage vv_code_blocage= ' ||
                                      vv_code_blocage,
                                      dka_sapwfcsp_pkg.cn_mode_debug);

    vv_user_name := wf_engine.getactivityattrtext(actid    => pn_actid,
                                                  itemtype => pv_itemtype,
                                                  itemkey  => pv_itemkey,
                                                  aname    => 'BLOQUEUR');

    dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'pose_blocage vv_user_name= ' ||
                                      vv_user_name,
                                      dka_sapwfcsp_pkg.cn_mode_debug);

    IF vv_user_name IS NOT NULL THEN
      SELECT u.user_id
        INTO vn_user_id
        FROM fnd_user u
       WHERE u.user_name = vv_user_name;
    ELSE
      vn_user_id := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                                itemkey  => pv_itemkey,
                                                aname    => 'USER_ID');
    END IF;

    dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'pose_blocage vv_blocage_motif= ' ||
                                      vv_blocage_motif,
                                      dka_sapwfcsp_pkg.cn_mode_debug);

    SELECT description
      INTO vv_motif_blocage
      FROM ap_hold_codes
     WHERE hold_lookup_code = vv_code_blocage;

    dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'pose_blocage_litige  vv_motif_blocage= ' ||
                                      vv_motif_blocage,
                                      dka_sapwfcsp_pkg.cn_mode_debug);

    dka_sapwfcsp_pkg.cree_blocage_ap('AP',
                                     vn_invoice_id,
                                     vv_code_blocage,
                                     vv_motif_blocage,
                                     NULL,
                                     vn_user_id,
                                     pv_itemtype,
                                     pv_itemkey,
                                     vv_errbuf,
                                     vn_retcode);

    IF vn_retcode = 0 THEN
      pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
    ELSE
      pv_resultout := wf_engine.eng_completed || ':' || 'FAIL';
    END IF;

  END pose_blocage;

  -------------------------------------------------------------------------------------
  --  Nom           : maj_blocage
  --  Description   : Procédure pour mettre à jour un blocage
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --                   Lookup YES/NO
  -------------------------------------------------------------------------------------
  PROCEDURE maj_blocage(pv_itemtype  IN wf_items.item_type%TYPE,
                        pv_itemkey   IN wf_items.item_key%TYPE,
                        pn_actid     IN wf_item_activity_statuses_v.activity_id%TYPE,
                        pv_funcmode  IN VARCHAR2,
                        pv_resultout OUT NOCOPY VARCHAR2) IS
    vv_reason_waiting VARCHAR2(50);
    vv_code_blocage   VARCHAR2(50);
    vv_atraiter       VARCHAR2(50);
    vn_invoice_id     NUMBER;
    vn_user_id        NUMBER;
    vv_blocageouvert  VARCHAR2(10);

  BEGIN
    IF (pv_funcmode <> wf_engine.eng_run) THEN
      pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
      RETURN;
    END IF;

    vn_invoice_id := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                                 itemkey  => pv_itemkey,
                                                 aname    => 'INVOICE_ID');

    vv_code_blocage := wf_engine.getactivityattrtext(actid    => pn_actid,
                                                     itemtype => pv_itemtype,
                                                     itemkey  => pv_itemkey,
                                                     aname    => 'DKA_TYPE_BLOCAGE');

    vn_user_id := wf_engine.getactivityattrnumber(actid    => pn_actid,
                                                     itemtype => pv_itemtype,
                                                     itemkey  => pv_itemkey,
                                                     aname    => 'BLOQUEUR');
    
    IF vn_user_id IS NULL THEN                                                     
      vn_user_id := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                                itemkey  => pv_itemkey,
                                                aname    => 'USER_ID');
    END IF;                                           
                                              

    vv_reason_waiting := wf_engine.getactivityattrtext(actid    => pn_actid,
                                                       itemtype => pv_itemtype,
                                                       itemkey  => pv_itemkey,
                                                       aname    => 'ATTRIBUTE5');

    vv_atraiter := wf_engine.getactivityattrtext(actid    => pn_actid,
                                                       itemtype => pv_itemtype,
                                                       itemkey  => pv_itemkey,
                                                       aname    => 'ATTRIBUTE4');

    vv_blocageouvert := wf_engine.getactivityattrtext(actid    => pn_actid,
                                                       itemtype => pv_itemtype,
                                                       itemkey  => pv_itemkey,
                                                       aname    => 'BLOCAGE_OUVERT');

    -- si vv_code_blocage est rempli filtre les blocages pour ne chercher que celui-la

    dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'maj_blocage : update du code blocage : ' ||
                                      vv_code_blocage || ' sur la facture  ' ||
                                      vn_invoice_id || ' avec user_id : ' || vn_user_id || 
                                      ' et vv_blocageouvert : ' || vv_blocageouvert,
                                      dka_sapwfcsp_pkg.cn_mode_debug);

    IF NVL(vv_blocageouvert, 'N') = 'N' THEN 
      UPDATE ap_holds_all
         SET last_update_date = SYSDATE,
             last_updated_by  = vn_user_id,
             attribute5       = nvl(vv_reason_waiting, attribute5),
             attribute4       = nvl(vv_atraiter, attribute4)
       WHERE invoice_id = vn_invoice_id
         AND hold_lookup_code = vv_code_blocage;
    ELSE
       UPDATE ap_holds_all
         SET last_update_date = SYSDATE,
             last_updated_by  = vn_user_id,
             attribute5       = nvl(vv_reason_waiting, attribute5),
             attribute4       = nvl(vv_atraiter, attribute4)
       WHERE invoice_id = vn_invoice_id
         AND hold_lookup_code = vv_code_blocage
         AND release_lookup_code IS NULL;
    END IF;

    dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'maj_blocage : retourne oui',
                                      dka_sapwfcsp_pkg.cn_mode_debug);
    pv_resultout := 'COMPLETE:' || 'SUCCESS';
  EXCEPTION
    WHEN OTHERS THEN

      dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                        pv_itemkey,
                                        'Exception in maj_blocage',
                                        dka_sapwfcsp_pkg.cn_mode_debug);

      wf_core.context('DKA_SAPWFCSP_PKG',
                      'maj_blocage',
                      pv_itemtype,
                      pv_itemkey,
                      pn_actid,
                      pv_funcmode);
      RAISE;
  END maj_blocage;

  -------------------------------------------------------------------------------------
  --  Nom           : notif_dest_ivalua
  --  Description   : Procedure gérant la notification dans le transfert Ivalua
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE notif_dest_ivalua(pv_itemtype  IN wf_items.item_type%TYPE,
                              pv_itemkey   IN wf_items.item_key%TYPE,
                              pn_actid     IN wf_item_activity_statuses_v.activity_id%TYPE, -- Ignore
                              pv_funcmode  IN VARCHAR2,
                              pv_resultout OUT NOCOPY VARCHAR2) IS

    vn_nid            wf_notifications.notification_id%TYPE;
    vv_result         VARCHAR2(100);
    lv_type_blocage  ap_holds_all.attribute6%TYPE;
    vv_resp_csp      VARCHAR2(150);
    l_session_user_id NUMBER;
    l_session_resp_id NUMBER;
    l_session_appl_id NUMBER;
    vn_invoice_id     NUMBER;
    vn_user_id        NUMBER;
    lv_user           VARCHAR2(50);
    l_count           NUMBER;
  BEGIN

    IF (pv_funcmode = 'TIMEOUT') THEN
      RETURN;
    END IF;

    IF (pv_funcmode <> wf_engine.eng_run AND pv_funcmode <> 'RESPOND') THEN
      -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
      l_session_resp_id := fnd_global.resp_id;
      l_session_appl_id := fnd_global.resp_appl_id;

      IF (l_session_resp_id = -1) THEN
        l_session_resp_id := NULL;
      END IF;

      IF (l_session_appl_id = -1) THEN
        l_session_appl_id := NULL;
      END IF;

      wf_engine.setitemattrnumber(itemtype => pv_itemtype,
                                  itemkey  => pv_itemkey,
                                  aname    => 'RESPONSIBILITY_ID',
                                  avalue   => l_session_resp_id);

      wf_engine.setitemattrnumber(itemtype => pv_itemtype,
                                  itemkey  => pv_itemkey,
                                  aname    => 'APPLICATION_ID',
                                  avalue   => l_session_appl_id);

      pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
      RETURN;

    END IF;
    dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'notif_dest_ivalua en pv_funcmode = ' ||
                                      pv_funcmode,
                                      dka_sapwfcsp_pkg.cn_mode_debug);
    vn_nid := wf_engine.context_nid;
    dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'nid: ' || vn_nid,
                                      dka_sapwfcsp_pkg.cn_mode_debug);

    -- recupere la reponse
    vv_result := wf_notification.getattrtext(vn_nid, 'Z_ACTION');

    dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'Other parameters',
                                      dka_sapwfcsp_pkg.cn_mode_debug);
                                      
    vn_invoice_id := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                                 itemkey  => pv_itemkey,
                                                 aname    => 'INVOICE_ID');

    vn_user_id := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                              itemkey  => pv_itemkey,
                                              aname    => 'USER_ID');
    
    vv_resp_csp := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                              itemkey  => pv_itemkey,
                                              aname    => 'DKA_RESP_CSP_ANO');    

    IF (pv_funcmode = 'RESPOND') THEN

      dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'Count in ap_invoices_all',
                                      dka_sapwfcsp_pkg.cn_mode_debug);
      SELECT COUNT(1)
        INTO l_count
        FROM ap_holds_all
       WHERE invoice_id = vn_invoice_id
         AND hold_lookup_code = cv_code_blocage_ivalua
         AND attribute6 IS NOT NULL;

      -- Verifications
      IF vv_result = 'DKA_APPROVE' AND l_count = 0 THEN

        pv_resultout := wf_engine.eng_error || ':' ||
                        fnd_message.get_string('DKA', 'DKA_SAPWFCSP_E080');
        dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                          pv_itemkey,
                                          'L''employee est vide => DKA_SAPWFCSP_E080',
                                          dka_sapwfcsp_pkg.cn_mode_debug);
        RETURN;
      END IF;

      l_session_user_id := fnd_global.user_id;
      l_session_resp_id := fnd_global.resp_id;
      l_session_appl_id := fnd_global.resp_appl_id;

      IF (l_session_user_id = -1) THEN
        l_session_user_id := NULL;
      END IF;

      IF (l_session_resp_id = -1) THEN
        l_session_resp_id := NULL;
      END IF;

      IF (l_session_appl_id = -1) THEN
        l_session_appl_id := NULL;
      END IF;

      wf_engine.setitemattrnumber(itemtype => pv_itemtype,
                                  itemkey  => pv_itemkey,
                                  aname    => 'RESPONDER_USER_ID',
                                  avalue   => l_session_user_id);

      wf_engine.setitemattrnumber(itemtype => pv_itemtype,
                                  itemkey  => pv_itemkey,
                                  aname    => 'RESPONDER_RESP_ID',
                                  avalue   => l_session_resp_id);
      wf_engine.setitemattrnumber(itemtype => pv_itemtype,
                                  itemkey  => pv_itemkey,
                                  aname    => 'RESPONDER_APPL_ID',
                                  avalue   => l_session_appl_id);

      wf_engine.setitemattrnumber(itemtype => pv_itemtype,
                                  itemkey  => pv_itemkey,
                                  aname    => 'RESPONSIBILITY_ID',
                                  avalue   => l_session_resp_id);

      wf_engine.setitemattrnumber(itemtype => pv_itemtype,
                                  itemkey  => pv_itemkey,
                                  aname    => 'APPLICATION_ID',
                                  avalue   => l_session_appl_id);
                                  
            dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'notif_dest_ivalua : ap_holds_all update attribute4',
                                      dka_sapwfcsp_pkg.cn_mode_debug);
      UPDATE ap_holds_all
         SET last_update_date = SYSDATE,
             last_updated_by  = nvl(l_session_user_id,last_updated_by),
             attribute4       = 'Y'
       WHERE invoice_id = vn_invoice_id
         AND hold_lookup_code = cv_code_blocage_ivalua
         AND release_lookup_code is null;

      dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'notif_dest_ivalua : ''DKA_TYPE_BLOCAGE_EN_ATTENTE''',
                                      dka_sapwfcsp_pkg.cn_mode_debug);
      SELECT ffv.description
        INTO lv_type_blocage
        FROM ap_holds_all        aha,
             fnd_flex_value_sets ffvs,
             fnd_flex_values_vl  ffv
       WHERE invoice_id = vn_invoice_id
         AND hold_lookup_code = cv_code_blocage_ivalua
         AND release_lookup_code is null
         AND ffvs.flex_value_set_name = 'DKA_TYPE_BLOCAGE_EN_ATTENTE'
         AND ffvs.flex_value_set_id = ffv.flex_value_set_id
         AND ffv.flex_value = aha.attribute5;
         
      SELECT user_name
       INTO lv_user
      FROM fnd_user
      WHERE user_id = l_session_user_id;

      -- historise l'action
      insert_history_ivalua(pv_itemtype,
                            pv_itemkey,
                            'DKA_TRANSFERT_IVALUA',
                            cv_code_blocage_ivalua,
                            lv_type_blocage,
                            WF_DIRECTORY.GetRoleDisplayName(lv_user));
                            --wf_notification.responder(vn_nid));

    END IF;

    IF (pv_funcmode = wf_engine.eng_run) THEN
      NULL;
    END IF;

    dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'notif_dest_ivalua fin',
                                      dka_sapwfcsp_pkg.cn_mode_debug);
  END notif_dest_ivalua;

  -------------------------------------------------------------------------------------
  --  Nom           : insert_history_ivalua
  --  Description   : Procédure insérant un message dans l'historique de la facture.
  --
  --  PARAMETRES :
  --     p_message   Entrée      Message a insérer
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE insert_history_ivalua(pv_itemtype     IN wf_items.item_type%TYPE,
                                  pv_itemkey      IN wf_items.item_key%TYPE,
                                  pv_status       IN ap_inv_aprvl_hist.response%TYPE,
                                  pv_code_blocage IN VARCHAR2,
                                  pv_comments     IN ap_inv_aprvl_hist.approver_comments%TYPE,
                                  pv_destinataire IN VARCHAR2 DEFAULT NULL) IS

    vn_iteration     ap_inv_aprvl_hist.iteration%TYPE;
    vn_invoice_id    ap_invoices_all.invoice_id%TYPE;
    ln_hold_id       ap_inv_aprvl_hist.hold_id%TYPE;
    vn_invoice_oi_id ap_invoices_all.invoice_id%TYPE;
    vn_org_id        ap_invoices_all.org_id%TYPE;
    vn_amount        ap_invoices_all.invoice_amount%TYPE;
    vn_nid           wf_notifications.notification_id%TYPE;
    

    vn_hist_id   ap_inv_aprvl_hist.approval_history_id%TYPE;
    vv_employee  per_all_people_f.full_name%TYPE;
    vv_matricule fnd_user.user_name%TYPE;
    vv_lookup_name FND_LOOKUP_VALUES.lookup_code%TYPE;
  
  BEGIN

    dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'insert_history_ivalua  debut pv_itemtype = ' ||
                                      pv_itemtype || 'pv_itemkey =  ' ||
                                      pv_itemkey,
                                      dka_sapwfcsp_pkg.cn_mode_debug);

    vn_invoice_id := substr(pv_itemkey, 1, instr(pv_itemkey, '_') - 1);
    vn_iteration  := substr(pv_itemkey, instr(pv_itemkey, '_') + 1);
    dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'insert_history_ivalua  vn_invoice_id avec substr ' ||
                                      vn_invoice_id,
                                      dka_sapwfcsp_pkg.cn_mode_debug);
    dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'insert_history_ivalua  iteration avec substr ' ||
                                      vn_iteration,
                                      dka_sapwfcsp_pkg.cn_mode_debug);

    vn_org_id := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                             itemkey  => pv_itemkey,
                                             aname    => 'DKA_ORG_ID');
    dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'insert_history_ivalua:  vn_org_id= ' ||
                                      vn_org_id || 'user ' ||
                                      fnd_global.user_name,
                                      dka_sapwfcsp_pkg.cn_mode_debug);

    vn_amount := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                             itemkey  => pv_itemkey,
                                             aname    => 'DKA_INVOICE_AMOUNT');

    dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'insert_history_ivalua:  vn_amount= ' ||
                                      vn_amount,
                                      dka_sapwfcsp_pkg.cn_mode_debug);

    dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'insert_history_ivalua:  pv_destinataire ' ||
                                      pv_destinataire || '  profile = ' ||
                                      fnd_global.user_name,
                                      dka_sapwfcsp_pkg.cn_mode_debug);

    IF pv_destinataire IS NULL THEN
      BEGIN
        dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                          pv_itemkey,
                                          'insert_history_ivalua: pas de destinataire de renseigné',
                                          dka_sapwfcsp_pkg.cn_mode_debug);

        vn_nid := wf_engine.context_nid;
        IF vn_nid IS NOT NULL THEN
          vv_matricule := wf_notification.responder(vn_nid);

          dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                            pv_itemkey,
                                            'insert_history_ivalua: employe trouve pour le responder de la notif ' ||
                                            vn_nid || ' : ' || vv_employee,
                                            dka_sapwfcsp_pkg.cn_mode_debug);

        END IF;

        --  IF vv_employee is null then
        SELECT full_name
          INTO vv_employee
          FROM per_all_people_f pap, fnd_user fu
         WHERE fu.employee_id = pap.person_id
           AND SYSDATE BETWEEN pap.effective_start_date AND
               pap.effective_end_date
           AND fu.user_name = vv_matricule;

        /*             print_wf_message(pv_itemtype,
                                  pv_itemkey,
                                      'insert_history employe trouve pour l''utilisateur ' || fnd_global.user_name || ' : ' ||vv_employee ,cn_mode_debug);
        */
        --END IF;
      EXCEPTION
        WHEN no_data_found THEN
          dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                            pv_itemkey,
                                            'insert_history_ivalua: l''utilisateur ' ||
                                            vv_matricule ||
                                            ' n''est pas rattaché a un employé actif ',
                                            dka_sapwfcsp_pkg.cn_mode_debug);

      END;
    ELSE
      vv_employee := pv_destinataire;
    END IF;

    --vn_invoice_oi_id not null si WF OI
    vn_invoice_oi_id := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                                    itemkey  => pv_itemkey,
                                                    aname    => 'INVOICE_OI_ID');

    IF vn_invoice_oi_id IS NULL THEN
      --FACTURE AP

      -- INC0298239 - Violation d'option de contrôle
      --MOAC
      --MO_GLOBAL.INIT (p_appl_short_name => 'SQLAP');

      --insert into the history table
      SELECT ap_inv_aprvl_hist_s.nextval INTO vn_hist_id FROM dual;

      dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                        pv_itemkey,
                                        'insert_history_ivalua  vn_hist_id = ' ||
                                        vn_hist_id ||
                                        ' pv_code_blocage = ' || pv_code_blocage,
                                        dka_sapwfcsp_pkg.cn_mode_debug);

      BEGIN
        SELECT MIN(hold_id)
          INTO ln_hold_id
          FROM ap_holds_all
         WHERE invoice_id = vn_invoice_id
           AND hold_lookup_code = pv_code_blocage;
      EXCEPTION
        WHEN no_data_found THEN
          ln_hold_id := NULL;
      END;
      
       BEGIN
         select meaning into vv_lookup_name
-- 2020/12/15 NBO SPE129 - Anomalies sur WF n°2B
         from FND_LOOKUP_VALUES where lookup_code = pv_code_blocage and lookup_type = 'HOLD CODE' and language = 'F';
       EXCEPTION
         WHEN NO_DATA_FOUND THEN
           vv_lookup_name := pv_code_blocage;
       END;

      dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                        pv_itemkey,
                                        'insert_history  vv_lookup_name = ' ||
                                        vv_lookup_name,
                                        dka_sapwfcsp_pkg.cn_mode_debug);   

      -- INC0298239 - Violation d'option de contrôle
      INSERT INTO ap_inv_aprvl_hist_all
        (approval_history_id,
         invoice_id,
         iteration,
         response,
         approver_id,
         approver_name,
         amount_approved,
         approver_comments,
         created_by,
         creation_date,
         last_update_date,
         last_updated_by,
         last_update_login,
         org_id,
         hold_id)
      VALUES
        (vn_hist_id,
         vn_invoice_id,
         vn_iteration,
         pv_status,
         NULL,
         vv_employee,
         vn_amount,
         vv_lookup_name || ' - ' || pv_comments,
         nvl(fnd_global.user_id, -1),
         SYSDATE,
         SYSDATE,
         nvl(fnd_global.user_id, -1),
         nvl(fnd_global.login_id, -1),
         vn_org_id,
         ln_hold_id);
    ELSE
      --FACTURE OI
      --insert into the history table
      SELECT dka_ap_inv_aprvl_hist_s.nextval INTO vn_hist_id FROM dual;

      dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                        pv_itemkey,
                                        'insert_history  vn_hist_id = ' ||
                                        vn_hist_id,
                                        dka_sapwfcsp_pkg.cn_mode_debug);
      
       BEGIN
         select meaning into vv_lookup_name
-- 2020/12/15 NBO SPE129 - Anomalies sur WF n°2B
         from FND_LOOKUP_VALUES where lookup_code = pv_code_blocage and lookup_type = 'HOLD CODE' and language = 'F';
       EXCEPTION
         WHEN NO_DATA_FOUND THEN
           vv_lookup_name := pv_code_blocage;
       END;

      dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                        pv_itemkey,
                                        'insert_history  vv_lookup_name = ' ||
                                        vv_lookup_name,
                                        dka_sapwfcsp_pkg.cn_mode_debug);       
 
      INSERT INTO dka_ap_inv_aprvl_hist_all
        (approval_history_id,
         invoice_id,
         iteration,
         response,
         approver_id,
         approver_name,
         amount_approved,
         approver_comments,
         created_by,
         creation_date,
         last_update_date,
         last_updated_by,
         last_update_login,
         org_id)
      VALUES
        (vn_hist_id,
         vn_invoice_id,
         vn_iteration,
         pv_status,
         NULL,
         vv_employee,
         vn_amount,
         vv_lookup_name || ' - ' || pv_comments,
         nvl(fnd_global.user_id, -1),
         SYSDATE,
         SYSDATE,
         nvl(fnd_global.user_id, -1),
         nvl(fnd_global.login_id, -1),
         vn_org_id);
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                        pv_itemkey,
                                        'insert_history: INSERT ERREUR : ' ||
                                        'APPROVAL_HISTORY_ID = ' ||
                                        vn_hist_id || chr(10) ||
                                        'INVOICE_ID = ' || vn_invoice_id ||
                                        chr(10) || 'ITERATION = ' ||
                                        vn_iteration || chr(10) ||
                                        'STATUS = ' || pv_status || chr(10) ||
                                        'EMPLOYEE = ' || vv_employee ||
                                        chr(10) || 'AMOUNT = ' || vn_amount ||
                                        chr(10) || 'COMMENT = ' ||
                                        pv_code_blocage || ' - ' ||
                                        pv_comments,
                                        dka_sapwfcsp_pkg.cn_mode_debug);
      dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                        pv_itemkey,
                                        'Erreur : ' || SQLERRM,
                                        dka_sapwfcsp_pkg.cn_mode_debug);
      RAISE;
  END insert_history_ivalua;

  -------------------------------------------------------------------------------------
  --  Nom           : pre_notification_ivalua
  --  Description   : Procédure pour mettre a jour certains champs des notifs
  --                        - URL de l'image qui a une durée de validité limitée
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --                   Lookup Sucess/fail
  -------------------------------------------------------------------------------------
  PROCEDURE pre_notification_ivalua(pv_itemtype  IN wf_items.item_type%TYPE,
                                    pv_itemkey   IN wf_items.item_key%TYPE,
                                    pn_actid     IN wf_item_activity_statuses_v.activity_id%TYPE, -- Ignore
                                    pv_funcmode  IN VARCHAR2,
                                    pv_resultout OUT NOCOPY VARCHAR2) IS
    vv_num_facture  ap_invoices_all.invoice_num%TYPE;
    vn_po_header_id po_headers_all.po_header_id%TYPE;
    vn_invoice_id   ap_invoices_all.invoice_id%TYPE;
    vv_url_facture  VARCHAR2(1000);
    vv_url_commande VARCHAR2(1000);
  BEGIN

    IF (pv_funcmode <> wf_engine.eng_run) THEN

      pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
      RETURN;

    END IF;

    vv_num_facture := wf_engine.getitemattrtext(itemtype => pv_itemtype,
                                                itemkey  => pv_itemkey,
                                                aname    => 'INVOICE_OI_NUM');
    vn_invoice_id  := substr(pv_itemkey, 1, instr(pv_itemkey, '_') - 1);

    dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'pre_notif   vn_invoice_id = ' ||
                                      vn_invoice_id || 'vv_num_facture =  ' ||
                                      vv_num_facture,
                                      dka_sapwfcsp_pkg.cn_mode_debug);

    BEGIN
      IF vv_num_facture IS NULL THEN
        vv_url_facture := dka_sapgetimg_wf_pkg.get_url_image_facture_ivalua(vn_invoice_id,
                                                                            'AP');
        dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                          pv_itemkey,
                                          'pre_notif    AP ' ||
                                          vv_url_facture,
                                          dka_sapwfcsp_pkg.cn_mode_debug);

      ELSE
        vv_url_facture := dka_sapgetimg_wf_pkg.get_url_image_facture_ivalua(vn_invoice_id,
                                                                            'OI');
        dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                          pv_itemkey,
                                          'pre_notif    OI ' ||
                                          vv_url_facture,
                                          dka_sapwfcsp_pkg.cn_mode_debug);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        vv_url_facture := NULL;
    END;

    wf_engine.setitemattrtext(itemtype => pv_itemtype,
                              itemkey  => pv_itemkey,
                              aname    => 'DKA_INVOICE_URL',
                              avalue   => vv_url_facture);

    vn_po_header_id := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                                   itemkey  => pv_itemkey,
                                                   aname    => 'COMMANDE_ID');

    BEGIN
      vv_url_commande := dka_sapgetimg_wf_pkg.get_url_image_bdc_ivalua(vn_po_header_id);
    EXCEPTION
      WHEN OTHERS THEN
        vv_url_commande := NULL;
    END;
    dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'vv_url_commande ' || vv_url_commande,
                                      dka_sapwfcsp_pkg.cn_mode_debug);
    wf_engine.setitemattrtext(itemtype => pv_itemtype,
                              itemkey  => pv_itemkey,
                              aname    => 'DKA_PURCHASE_ORDER_URL',
                              avalue   => vv_url_commande);

    wf_engine.setitemattrtext(itemtype => pv_itemtype,
                              itemkey  => pv_itemkey,
                              aname    => 'DOC_LIGNE_FACTURE_IVALUA',
                              avalue   => 'PLSQLCLOB:dka_sapwfcsp_ivalua_pkg.get_infos_ap_ivalua/' ||
                                          pv_itemtype || ':' || pv_itemkey || ':' ||
                                          '&#NID');


    wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                              itemkey  => pv_itemkey,
                              aname    => 'DOC_HISTO_IVALUA',
                              avalue   => 'PLSQLCLOB:DKA_SAPWFCSP_ivalua_pkg.GET_ACTION_HISTORY_IVALUA/' ||
                                          pv_itemtype || ':' ||
                                          pv_itemkey);

    wf_engine.setitemattrtext(itemtype => pv_itemtype,
                              itemkey  => pv_itemkey,
                              aname    => 'DOC_ECART_PRIX_IVALUA',
                              avalue   => 'PLSQLCLOB:DKA_SAPWFCSP_ivalua_pkg.get_ecart_prix_ivalua/' ||
                                          pv_itemtype || ':' || pv_itemkey);

    -- Libellé notif ivalua
    wf_engine.setitemattrtext(itemtype => pv_itemtype,
                              itemkey  => pv_itemkey,
                              aname    => 'LIB_TITRE_NOTIF_DEST_IVALUA',
                              avalue   => dka_tools_pkg.get_message('DKA',
                                                                    'DKA_SAPWFCSP_E081'));
    wf_engine.setitemattrtext(itemtype => pv_itemtype,
                              itemkey  => pv_itemkey,
                              aname    => 'LIB_TITRE_NOTIF_REPONSE_IVALUA',
                              avalue   => dka_tools_pkg.get_message('DKA',
                                                                    'DKA_SAPWFCSP_E082'));
    wf_engine.setitemattrtext(itemtype => pv_itemtype,
                              itemkey  => pv_itemkey,
                              aname    => 'LIB_TITRE_NOTIF_ECART_PRIX_IV',
                              avalue   => dka_tools_pkg.get_message('DKA',
                                                                    'DKA_SAPWFCSP_E083'));

    wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                              itemkey  => pv_itemkey,
                              aname    => 'LIB_TITRE_NOTIF_CSP_QTY_REC_IV',
                              avalue => dka_tools_pkg.get_message('DKA',
                                                                 'DKA_SAPWFCSP_E084'));

    wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                              itemkey  => pv_itemkey,
                              aname    => 'LIB_TITRE_NOTIF_CSP_QTY_ORD_IV',
                              avalue => dka_tools_pkg.get_message('DKA',
                                                                 'DKA_SAPWFCSP_E085'));  
    wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => 'TEXTE_CSP_QTY_ORD_IV',
                                      avalue => dka_tools_pkg.get_message('DKA',
                                                                          'DKA_SAPWFCSP_E087'));                                                                                                                                
                                                                 

  END pre_notification_ivalua;

  -------------------------------------------------------------------------------------
  --  Nom           : get_action_history_ivalua
  --  Description   : Procédure utilisée pour afficher le tableau d'historique
  --                    des actions sur la facture dans les notifications
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --
  -------------------------------------------------------------------------------------
  PROCEDURE get_action_history_ivalua(pv_document_id   IN VARCHAR2,
                                      pv_display_type  IN VARCHAR2,
                                      pv_document      IN OUT NOCOPY CLOB,
                                      pv_document_type IN OUT NOCOPY VARCHAR2) IS -- Ignore

    vv_item_type      wf_items.item_type%TYPE;
    vv_item_key       wf_items.item_key%TYPE;
    vv_document       VARCHAR2(32000) := '';
    nl                VARCHAR2(1) := fnd_global.newline;
    l_notification_id NUMBER;
    vn_invoice_id     NUMBER;
    vn_invoice_oi_id  ap_invoices_all.invoice_id%TYPE;

    nb_hist_fact NUMBER;
    CURSOR c_histo_ap_1(pn_invoice_id ap_invoices_all.invoice_id%TYPE) IS
      SELECT aiah.approver_name,
             flv.meaning AS response,
             to_char(aiah.creation_date, 'dd/mm/yyyy hh24:mi:ss') creation_date,
             aiah.approver_comments
        FROM ap_inv_aprvl_hist_all aiah, fnd_lookup_values_vl flv
       WHERE aiah.invoice_id = pn_invoice_id
         AND flv.lookup_type = 'AP_WFAPPROVAL_STATUS'
         AND flv.lookup_code = aiah.response
         AND flv.enabled_flag = 'Y'
         AND SYSDATE BETWEEN nvl(flv.start_date_active, SYSDATE) AND
             nvl(flv.end_date_active, SYSDATE)
       ORDER BY aiah.approval_history_id DESC;

    CURSOR c_histo_ap_2(pn_invoice_id ap_invoices_all.invoice_id%TYPE) IS
      SELECT aiah.approver_name,
             flv.meaning AS response,
             to_char(aiah.creation_date, 'dd/mm/yyyy hh24:mi:ss') creation_date,
             aiah.approver_comments
        FROM ap_inv_aprvl_hist_all aiah, fnd_lookup_values_vl flv
       WHERE aiah.invoice_id = pn_invoice_id
         AND flv.lookup_type = 'AP_WFAPPROVAL_STATUS'
         AND flv.lookup_code = aiah.response
         AND flv.enabled_flag = 'Y'
         AND SYSDATE BETWEEN nvl(flv.start_date_active, SYSDATE) AND
             nvl(flv.end_date_active, SYSDATE)
         AND aiah.response IS NOT NULL
         AND aiah.approver_name IS NOT NULL
       ORDER BY aiah.approval_history_id DESC;

    CURSOR c_histo_ap_3(pn_invoice_id ap_invoices_all.invoice_id%TYPE) IS
      SELECT aiah.approver_name,
             flv.meaning AS response,
             to_char(aiah.creation_date, 'dd/mm/yyyy hh24:mi:ss') creation_date,
             aiah.approver_comments
        FROM ap_inv_aprvl_hist_all aiah, fnd_lookup_values_vl flv
       WHERE aiah.invoice_id = pn_invoice_id
         AND flv.lookup_type = 'AP_WFAPPROVAL_STATUS'
         AND flv.lookup_code = aiah.response
         AND flv.enabled_flag = 'Y'
         AND SYSDATE BETWEEN nvl(flv.start_date_active, SYSDATE) AND
             nvl(flv.end_date_active, SYSDATE)
         AND aiah.response IS NOT NULL
         AND aiah.approver_name IS NOT NULL
         AND aiah.response != 'DKA_SOUMIS'
         AND rownum <= 60
       ORDER BY aiah.approval_history_id DESC;

    CURSOR c_histo_oi_1(pn_invoice_id ap_invoices_all.invoice_id%TYPE) IS
      SELECT aiah.approver_name,
             flv.meaning AS response,
             to_char(aiah.creation_date, 'dd/mm/yyyy hh24:mi:ss') creation_date,
             aiah.approver_comments
        FROM dka_ap_inv_aprvl_hist_all aiah, fnd_lookup_values_vl flv
       WHERE aiah.invoice_id = pn_invoice_id
         AND flv.lookup_type = 'AP_WFAPPROVAL_STATUS'
         AND flv.lookup_code = aiah.response
         AND flv.enabled_flag = 'Y'
         AND SYSDATE BETWEEN nvl(flv.start_date_active, SYSDATE) AND
             nvl(flv.end_date_active, SYSDATE)
       ORDER BY aiah.approval_history_id DESC;

    CURSOR c_histo_oi_2(pn_invoice_id ap_invoices_all.invoice_id%TYPE) IS
      SELECT aiah.approver_name,
             flv.meaning AS response,
             to_char(aiah.creation_date, 'dd/mm/yyyy hh24:mi:ss') creation_date,
             aiah.approver_comments
        FROM dka_ap_inv_aprvl_hist_all aiah, fnd_lookup_values_vl flv
       WHERE aiah.invoice_id = pn_invoice_id
         AND flv.lookup_type = 'AP_WFAPPROVAL_STATUS'
         AND flv.lookup_code = aiah.response
         AND flv.enabled_flag = 'Y'
         AND SYSDATE BETWEEN nvl(flv.start_date_active, SYSDATE) AND
             nvl(flv.end_date_active, SYSDATE)
         AND aiah.response IS NOT NULL
         AND aiah.approver_name IS NOT NULL
       ORDER BY aiah.approval_history_id DESC;

    CURSOR c_histo_oi_3(pn_invoice_id ap_invoices_all.invoice_id%TYPE) IS
      SELECT aiah.approver_name,
             flv.meaning AS response,
             to_char(aiah.creation_date, 'dd/mm/yyyy hh24:mi:ss') creation_date,
             aiah.approver_comments
        FROM dka_ap_inv_aprvl_hist_all aiah, fnd_lookup_values_vl flv
       WHERE aiah.invoice_id = pn_invoice_id
         AND flv.lookup_type = 'AP_WFAPPROVAL_STATUS'
         AND flv.lookup_code = aiah.response
         AND flv.enabled_flag = 'Y'
         AND SYSDATE BETWEEN nvl(flv.start_date_active, SYSDATE) AND
             nvl(flv.end_date_active, SYSDATE)
         AND aiah.response IS NOT NULL
         AND aiah.response != 'DKA_SOUMIS'
         AND aiah.approver_name IS NOT NULL
         AND rownum <= 60
       ORDER BY aiah.approval_history_id DESC;

  BEGIN
    dka_sapwfcsp_pkg.get_item_info(pv_document_id,
                                   vv_item_type,
                                   vv_item_key,
                                   l_notification_id);
    dka_sapwfcsp_pkg.print_wf_message(vv_item_type,
                                      vv_item_key,
                                      'get_action_history  document_id= ' ||
                                      pv_document_id || 'pv_display_type ' ||
                                      pv_display_type,
                                      dka_sapwfcsp_pkg.cn_mode_debug);

    dka_sapwfcsp_pkg.print_wf_message(vv_item_type,
                                      vv_item_key,
                                      'get_action_history  vv_item_type= ' ||
                                      vv_item_type || 'vv_item_key ' ||
                                      vv_item_key,
                                      dka_sapwfcsp_pkg.cn_mode_debug);

    vn_invoice_id := substr(vv_item_key, 1, instr(vv_item_key, '_') - 1);

    dka_sapwfcsp_pkg.print_wf_message(vv_item_type,
                                      vv_item_key,
                                      'get_action_history  vn_invoice_id= ' ||
                                      vn_invoice_id,
                                      dka_sapwfcsp_pkg.cn_mode_debug);

    IF (pv_display_type = 'text/html') THEN

      vv_document := nl || nl || '<!-- ACTION_HISTORY -->' || nl || nl;
      vv_document := vv_document || '<TABLE ' ||
                     dka_sapwfcsp_pkg.l_table_style || ' summary="' ||
                     fnd_message.get_string('ICX',
                                            'ICX_POR_TBL_OF_APPROVERS') || '">' || nl;
      vv_document := vv_document || '<TR>' || nl;
      vv_document := vv_document || '<TH ' ||
                     dka_sapwfcsp_pkg.l_table_header_style ||
                     ' width=20% id="employee_3"><font ' ||
                     dka_sapwfcsp_pkg.l_font_header_style || '>' ||
                     fnd_message.get_string('PO', 'PO_WF_NOTIF_EMPLOYEE') ||
                     '</font></TH>' || nl;
      vv_document := vv_document || '<TH ' ||
                     dka_sapwfcsp_pkg.l_table_header_style ||
                     ' width=12% id="action_3"><font ' ||
                     dka_sapwfcsp_pkg.l_font_header_style || '>' ||
                     fnd_message.get_string('PO', 'PO_WF_NOTIF_ACTION') ||
                     '</font></TH>' || nl;
      vv_document := vv_document || '<TH ' ||
                     dka_sapwfcsp_pkg.l_table_header_style ||
                     ' width=12% id="date_3"><font ' ||
                     dka_sapwfcsp_pkg.l_font_header_style || '>' ||
                     fnd_message.get_string('PO', 'PO_WF_NOTIF_DATE') ||
                     '</font></TH>' || nl;
      vv_document := vv_document || '<TH ' ||
                     dka_sapwfcsp_pkg.l_table_header_style ||
                     ' width=35% id="actionNote_3"><font ' ||
                     dka_sapwfcsp_pkg.l_font_header_style || '>' ||
                     fnd_message.get_string('PO', 'PO_WF_NOTIF_ACTION_NOTE') ||
                     '</font></TH>' || nl;
      vv_document := vv_document || '</TR>' || nl;

      --vn_invoice_oi_id not null si WF OI
      vn_invoice_oi_id := wf_engine.getitemattrnumber(itemtype => vv_item_type,
                                                      itemkey  => vv_item_key,
                                                      aname    => 'INVOICE_OI_ID');

      IF vn_invoice_oi_id IS NULL THEN
        nb_hist_fact := 0;
        BEGIN
          SELECT COUNT(1)
            INTO nb_hist_fact
            FROM ap_inv_aprvl_hist_all aiah, fnd_lookup_values_vl flv
           WHERE aiah.invoice_id = vn_invoice_id
             AND flv.lookup_type = 'AP_WFAPPROVAL_STATUS'
             AND flv.lookup_code = aiah.response
             AND flv.enabled_flag = 'Y'
             AND SYSDATE BETWEEN nvl(flv.start_date_active, SYSDATE) AND
                 nvl(flv.end_date_active, SYSDATE)
           ORDER BY aiah.approval_history_id DESC;
        EXCEPTION
          WHEN OTHERS THEN
            nb_hist_fact := 0;
        END;
        IF nb_hist_fact <= 60 THEN
          --FACTURE AP
          FOR histo1 IN c_histo_ap_1(vn_invoice_id) LOOP
            vv_document := vv_document || nl || '<TR>' || nl;
            vv_document := vv_document || nl || '<td ' ||
                           dka_sapwfcsp_pkg.l_table_cell_style ||
                           ' headers="employee_3"><font ' ||
                           dka_sapwfcsp_pkg.l_font_cell_style || '>' ||
                           nvl(histo1.approver_name, ' &nbsp') ||
                           '</font></td>' || nl;
            vv_document := vv_document || nl || '<td ' ||
                           dka_sapwfcsp_pkg.l_table_cell_style ||
                           ' headers="action_3"><font ' ||
                           dka_sapwfcsp_pkg.l_font_cell_style || '>' ||
                           nvl(histo1.response, '&nbsp ') || '</font></td>' || nl;
            vv_document := vv_document || nl || '<td ' ||
                           dka_sapwfcsp_pkg.l_table_cell_style ||
                           ' headers="date_3"><font ' ||
                           dka_sapwfcsp_pkg.l_font_cell_style || '>' ||
                           histo1.creation_date || '</font></td>' || nl;
            vv_document := vv_document || nl || '<td ' ||
                           dka_sapwfcsp_pkg.l_table_cell_style ||
                           ' headers="actioNote_3"><font ' ||
                           dka_sapwfcsp_pkg.l_font_cell_style || '>' ||
                           nvl(histo1.approver_comments, '&nbsp ') ||
                           '</font></td>' || nl;
            vv_document := vv_document || '</TR>' || nl;
          END LOOP;
        ELSE
          nb_hist_fact := 0;
          BEGIN
            SELECT COUNT(1)
              INTO nb_hist_fact
              FROM ap_inv_aprvl_hist_all aiah, fnd_lookup_values_vl flv
             WHERE aiah.invoice_id = vn_invoice_id
               AND flv.lookup_type = 'AP_WFAPPROVAL_STATUS'
               AND flv.lookup_code = aiah.response
               AND flv.enabled_flag = 'Y'
               AND SYSDATE BETWEEN nvl(flv.start_date_active, SYSDATE) AND
                   nvl(flv.end_date_active, SYSDATE)
               AND aiah.response IS NOT NULL
               AND aiah.approver_name IS NOT NULL
             ORDER BY aiah.approval_history_id DESC;
          EXCEPTION
            WHEN OTHERS THEN
              nb_hist_fact := 0;
          END;

          IF nb_hist_fact <= 60 THEN
            --FACTURE AP
            FOR histo2 IN c_histo_ap_2(vn_invoice_id) LOOP
              vv_document := vv_document || nl || '<TR>' || nl;
              vv_document := vv_document || nl || '<td ' ||
                             dka_sapwfcsp_pkg.l_table_cell_style ||
                             ' headers="employee_3"><font ' ||
                             dka_sapwfcsp_pkg.l_font_cell_style || '>' ||
                             nvl(histo2.approver_name, ' &nbsp') ||
                             '</font></td>' || nl;
              vv_document := vv_document || nl || '<td ' ||
                             dka_sapwfcsp_pkg.l_table_cell_style ||
                             ' headers="action_3"><font ' ||
                             dka_sapwfcsp_pkg.l_font_cell_style || '>' ||
                             nvl(histo2.response, '&nbsp ') ||
                             '</font></td>' || nl;
              vv_document := vv_document || nl || '<td ' ||
                             dka_sapwfcsp_pkg.l_table_cell_style ||
                             ' headers="date_3"><font ' ||
                             dka_sapwfcsp_pkg.l_font_cell_style || '>' ||
                             histo2.creation_date || '</font></td>' || nl;
              vv_document := vv_document || nl || '<td ' ||
                             dka_sapwfcsp_pkg.l_table_cell_style ||
                             ' headers="actioNote_3"><font ' ||
                             dka_sapwfcsp_pkg.l_font_cell_style || '>' ||
                             nvl(histo2.approver_comments, '&nbsp ') ||
                             '</font></td>' || nl;
              vv_document := vv_document || '</TR>' || nl;
            END LOOP;
          ELSE
            --FACTURE AP
            FOR histo3 IN c_histo_ap_3(vn_invoice_id) LOOP
              vv_document := vv_document || nl || '<TR>' || nl;
              vv_document := vv_document || nl || '<td ' ||
                             dka_sapwfcsp_pkg.l_table_cell_style ||
                             ' headers="employee_3"><font ' ||
                             dka_sapwfcsp_pkg.l_font_cell_style || '>' ||
                             nvl(histo3.approver_name, ' &nbsp') ||
                             '</font></td>' || nl;
              vv_document := vv_document || nl || '<td ' ||
                             dka_sapwfcsp_pkg.l_table_cell_style ||
                             ' headers="action_3"><font ' ||
                             dka_sapwfcsp_pkg.l_font_cell_style || '>' ||
                             nvl(histo3.response, '&nbsp ') ||
                             '</font></td>' || nl;
              vv_document := vv_document || nl || '<td ' ||
                             dka_sapwfcsp_pkg.l_table_cell_style ||
                             ' headers="date_3"><font ' ||
                             dka_sapwfcsp_pkg.l_font_cell_style || '>' ||
                             histo3.creation_date || '</font></td>' || nl;
              vv_document := vv_document || nl || '<td ' ||
                             dka_sapwfcsp_pkg.l_table_cell_style ||
                             ' headers="actioNote_3"><font ' ||
                             dka_sapwfcsp_pkg.l_font_cell_style || '>' ||
                             nvl(histo3.approver_comments, '&nbsp ') ||
                             '</font></td>' || nl;
              vv_document := vv_document || '</TR>' || nl;
            END LOOP;
          END IF;
        END IF;

      ELSE
        ----------------
        -- ---------- --
        -- FACTURE OI --
        -- ---------- --
        ----------------
        nb_hist_fact := 0;
        BEGIN
          SELECT COUNT(1)
            INTO nb_hist_fact
            FROM dka_ap_inv_aprvl_hist_all aiah, fnd_lookup_values_vl flv
           WHERE aiah.invoice_id = vn_invoice_oi_id
             AND flv.lookup_type = 'AP_WFAPPROVAL_STATUS'
             AND flv.lookup_code = aiah.response
             AND flv.enabled_flag = 'Y'
             AND SYSDATE BETWEEN nvl(flv.start_date_active, SYSDATE) AND
                 nvl(flv.end_date_active, SYSDATE)
           ORDER BY aiah.approval_history_id DESC;
        EXCEPTION
          WHEN OTHERS THEN
            nb_hist_fact := 0;
        END;
        IF nb_hist_fact <= 60 THEN

          FOR histo1 IN c_histo_oi_1(vn_invoice_oi_id) LOOP
            vv_document := vv_document || nl || '<TR>' || nl;
            vv_document := vv_document || nl || '<td ' ||
                           dka_sapwfcsp_pkg.l_table_cell_style ||
                           ' headers="employee_3"><font ' ||
                           dka_sapwfcsp_pkg.l_font_cell_style || '>' ||
                           nvl(histo1.approver_name, ' &nbsp') ||
                           '</font></td>' || nl;
            vv_document := vv_document || nl || '<td ' ||
                           dka_sapwfcsp_pkg.l_table_cell_style ||
                           ' headers="action_3"><font ' ||
                           dka_sapwfcsp_pkg.l_font_cell_style || '>' ||
                           nvl(histo1.response, '&nbsp ') || '</font></td>' || nl;
            vv_document := vv_document || nl || '<td ' ||
                           dka_sapwfcsp_pkg.l_table_cell_style ||
                           ' headers="date_3"><font ' ||
                           dka_sapwfcsp_pkg.l_font_cell_style || '>' ||
                           histo1.creation_date || '</font></td>' || nl;
            vv_document := vv_document || nl || '<td ' ||
                           dka_sapwfcsp_pkg.l_table_cell_style ||
                           ' headers="actioNote_3"><font ' ||
                           dka_sapwfcsp_pkg.l_font_cell_style || '>' ||
                           nvl(histo1.approver_comments, '&nbsp ') ||
                           '</font></td>' || nl;
            vv_document := vv_document || '</TR>' || nl;
          END LOOP;
        ELSE
          nb_hist_fact := 0;
          BEGIN
            SELECT COUNT(1)
              INTO nb_hist_fact
              FROM dka_ap_inv_aprvl_hist_all aiah, fnd_lookup_values_vl flv
             WHERE aiah.invoice_id = vn_invoice_oi_id
               AND flv.lookup_type = 'AP_WFAPPROVAL_STATUS'
               AND flv.lookup_code = aiah.response
               AND flv.enabled_flag = 'Y'
               AND SYSDATE BETWEEN nvl(flv.start_date_active, SYSDATE) AND
                   nvl(flv.end_date_active, SYSDATE)
               AND aiah.response IS NOT NULL
               AND aiah.approver_name IS NOT NULL
             ORDER BY aiah.approval_history_id DESC;
          EXCEPTION
            WHEN OTHERS THEN
              nb_hist_fact := 0;
          END;
          IF nb_hist_fact <= 60 THEN
            FOR histo2 IN c_histo_oi_2(vn_invoice_oi_id) LOOP
              vv_document := vv_document || nl || '<TR>' || nl;
              vv_document := vv_document || nl || '<td ' ||
                             dka_sapwfcsp_pkg.l_table_cell_style ||
                             ' headers="employee_3"><font ' ||
                             dka_sapwfcsp_pkg.l_font_cell_style || '>' ||
                             nvl(histo2.approver_name, ' &nbsp') ||
                             '</font></td>' || nl;
              vv_document := vv_document || nl || '<td ' ||
                             dka_sapwfcsp_pkg.l_table_cell_style ||
                             ' headers="action_3"><font ' ||
                             dka_sapwfcsp_pkg.l_font_cell_style || '>' ||
                             nvl(histo2.response, '&nbsp ') ||
                             '</font></td>' || nl;
              vv_document := vv_document || nl || '<td ' ||
                             dka_sapwfcsp_pkg.l_table_cell_style ||
                             ' headers="date_3"><font ' ||
                             dka_sapwfcsp_pkg.l_font_cell_style || '>' ||
                             histo2.creation_date || '</font></td>' || nl;
              vv_document := vv_document || nl || '<td ' ||
                             dka_sapwfcsp_pkg.l_table_cell_style ||
                             ' headers="actioNote_3"><font ' ||
                             dka_sapwfcsp_pkg.l_font_cell_style || '>' ||
                             nvl(histo2.approver_comments, '&nbsp ') ||
                             '</font></td>' || nl;
              vv_document := vv_document || '</TR>' || nl;
            END LOOP;
          ELSE
            FOR histo3 IN c_histo_oi_3(vn_invoice_oi_id) LOOP
              vv_document := vv_document || nl || '<TR>' || nl;
              vv_document := vv_document || nl || '<td ' ||
                             dka_sapwfcsp_pkg.l_table_cell_style ||
                             ' headers="employee_3"><font ' ||
                             dka_sapwfcsp_pkg.l_font_cell_style || '>' ||
                             nvl(histo3.approver_name, ' &nbsp') ||
                             '</font></td>' || nl;
              vv_document := vv_document || nl || '<td ' ||
                             dka_sapwfcsp_pkg.l_table_cell_style ||
                             ' headers="action_3"><font ' ||
                             dka_sapwfcsp_pkg.l_font_cell_style || '>' ||
                             nvl(histo3.response, '&nbsp ') ||
                             '</font></td>' || nl;
              vv_document := vv_document || nl || '<td ' ||
                             dka_sapwfcsp_pkg.l_table_cell_style ||
                             ' headers="date_3"><font ' ||
                             dka_sapwfcsp_pkg.l_font_cell_style || '>' ||
                             histo3.creation_date || '</font></td>' || nl;
              vv_document := vv_document || nl || '<td ' ||
                             dka_sapwfcsp_pkg.l_table_cell_style ||
                             ' headers="actioNote_3"><font ' ||
                             dka_sapwfcsp_pkg.l_font_cell_style || '>' ||
                             nvl(histo3.approver_comments, '&nbsp ') ||
                             '</font></td>' || nl;
              vv_document := vv_document || '</TR>' || nl;
            END LOOP;
          END IF;
        END IF;
      END IF;
      vv_document := vv_document || '</TABLE>' || nl;

      wf_notification.writetoclob(pv_document, vv_document);

    ELSIF (pv_display_type = 'text/plain') THEN

      wf_notification.writetoclob(pv_document, '');
    END IF;

    dka_sapwfcsp_pkg.print_wf_message(vv_item_type,
                                      vv_item_key,
                                      'get_action_history  end',
                                      dka_sapwfcsp_pkg.cn_mode_debug);
  END get_action_history_ivalua;

  -------------------------------------------------------------------------------------
  --  Nom           : get_infos_AP_ivalua
  --  Description   : Procédure utilisée pour afficher le tableau d'informations
  --                    sur la facture AP dans les notifications
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --
  -------------------------------------------------------------------------------------
  PROCEDURE get_infos_ap_ivalua(pv_document_id   IN VARCHAR2,
                                pv_display_type  IN VARCHAR2,
                                pv_document      IN OUT NOCOPY CLOB,
                                pv_document_type IN OUT NOCOPY VARCHAR2) IS -- Ignore

    vv_item_type wf_items.item_type%TYPE;
    vv_item_key  wf_items.item_key%TYPE;

    vv_document       VARCHAR2(32000) := '';
    nl                VARCHAR2(1) := fnd_global.newline;
    l_notification_id wf_notifications.notification_id%TYPE;
    vn_invoice_id     ap_invoices_all.invoice_id%TYPE;
    vn_invoice_amount ap_invoices_all.invoice_amount%TYPE;
    vv_invoice_num    ap_invoices_all.invoice_num%TYPE;
    vv_num_vendeur    ap_suppliers.segment1%TYPE;
    vd_invoice_date   ap_invoices_all.invoice_date%TYPE;
    vv_invoice_type   ap_invoices_all.invoice_type_lookup_code%TYPE;
    vv_pay_group      ap_invoices_interface.pay_group_lookup_code%TYPE;
    vv_desc           ap_invoices_interface.description%TYPE;
    vv_nom_fourn      ap_suppliers.vendor_name%TYPE;
    vv_num_command    po_headers.segment1%TYPE;
    vv_code_sitefourn ap_supplier_sites.vendor_site_code%TYPE;
    vv_type_notif     VARCHAR2(2000);
  BEGIN
    dka_sapwfcsp_pkg.get_item_info(pv_document_id,
                                   vv_item_type,
                                   vv_item_key,
                                   l_notification_id);
    dka_sapwfcsp_pkg.print_wf_message(vv_item_type,
                                      vv_item_key,
                                      'get_infos_AP_ivalua  document_id= ' ||
                                      pv_document_id || 'pv_display_type ' ||
                                      pv_display_type,
                                      dka_sapwfcsp_pkg.cn_mode_debug);

    vn_invoice_id := substr(vv_item_key, 1, instr(vv_item_key, '_') - 1);
    dka_sapwfcsp_pkg.print_wf_message(vv_item_type,
                                      vv_item_key,
                                      'get_infos_AP_ivalua  vv_item_type= ' ||
                                      vv_item_type || 'vv_item_key ' ||
                                      vv_item_key || 'vn_invoice_id ' ||
                                      vn_invoice_id || 'l_notification_id' ||
                                      l_notification_id,
                                      dka_sapwfcsp_pkg.cn_mode_debug);

    BEGIN
      vv_type_notif := wf_notification.getattrtext(l_notification_id,
                                                   'TYPE_NOTIF');
    EXCEPTION
      WHEN OTHERS THEN
        vv_type_notif := NULL;
    END;

    dka_sapwfcsp_pkg.print_wf_message(vv_item_type,
                                      vv_item_key,
                                      'get_infos_AP_ivalua  vv_type_notif = ' ||
                                      vv_type_notif,
                                      dka_sapwfcsp_pkg.cn_mode_debug);

    vv_invoice_num := wf_engine.getitemattrtext(itemtype => vv_item_type,
                                                itemkey  => vv_item_key,
                                                aname    => 'INVOICE_NUM');

    vv_num_vendeur := wf_engine.getitemattrtext(itemtype => vv_item_type,
                                                itemkey  => vv_item_key,
                                                aname    => 'VENDOR_SEGMENT1');

    vn_invoice_amount := wf_engine.getitemattrnumber(itemtype => vv_item_type,
                                                     itemkey  => vv_item_key,
                                                     aname    => 'DKA_INVOICE_AMOUNT');

    vd_invoice_date := wf_engine.getitemattrdate(itemtype => vv_item_type,
                                                 itemkey  => vv_item_key,
                                                 aname    => 'DKA_INVOICE_DATE');

    vv_invoice_type := wf_engine.getitemattrtext(itemtype => vv_item_type,
                                                 itemkey  => vv_item_key,
                                                 aname    => 'INVOICE_TYPE');

    vv_pay_group := wf_engine.getitemattrtext(itemtype => vv_item_type,
                                              itemkey  => vv_item_key,
                                              aname    => 'PAY_GROUP');

    vv_desc := wf_engine.getitemattrtext(itemtype => vv_item_type,
                                         itemkey  => vv_item_key,
                                         aname    => 'DESCRIPT');

    vv_nom_fourn := wf_engine.getitemattrtext(itemtype => vv_item_type,
                                              itemkey  => vv_item_key,
                                              aname    => 'VENDOR_NAME');

    vv_num_command := wf_engine.getitemattrtext(itemtype => vv_item_type,
                                                itemkey  => vv_item_key,
                                                aname    => 'COMMANDE_NUM');

    vv_code_sitefourn := wf_engine.getitemattrtext(itemtype => vv_item_type,
                                                   itemkey  => vv_item_key,
                                                   aname    => 'VENDOR_SITE_CODE');

    IF (pv_display_type = 'text/html') THEN

      vv_document := nl || nl || '<!-- BLOCAGES -->' || nl || nl;
      vv_document := vv_document || '<TABLE ' ||
                     dka_sapwfcsp_pkg.l_table_style || '>' || nl;
      vv_document := vv_document || '<TR>' || nl;

      vv_document := vv_document || '<TH ' ||
                     dka_sapwfcsp_pkg.l_table_header_style ||
                     '  id="employee_3"><font ' ||
                     dka_sapwfcsp_pkg.l_font_header_style || '>' ||
                     fnd_message.get_string('DKA', 'DKA_SAPWFCSP_E015') ||
                     '</font></TH>' || nl;
      vv_document := vv_document || '<TH ' ||
                     dka_sapwfcsp_pkg.l_table_header_style ||
                     '  id="action_3"><font ' ||
                     dka_sapwfcsp_pkg.l_font_header_style || '>' || --desc
                     fnd_message.get_string('DKA', 'DKA_SAPWFCSP_E019') ||
                     '</font></TH>' || nl;
      vv_document := vv_document || '<TH ' ||
                     dka_sapwfcsp_pkg.l_table_header_style ||
                     '  id="action_3"><font ' ||
                     dka_sapwfcsp_pkg.l_font_header_style || '>' ||
                     fnd_message.get_string('DKA', 'DKA_SAPWFCSP_E030') ||
                     '</font></TH>' || nl; --N° fourn

      vv_document := vv_document || '<TH ' ||
                     dka_sapwfcsp_pkg.l_table_header_style ||
                     '  id="action_3"><font ' ||
                     dka_sapwfcsp_pkg.l_font_header_style || '>' ||
                     fnd_message.get_string('DKA', 'DKA_SAPWFCSP_E031') ||
                     '</font></TH>' || nl; -- code fourn
      vv_document := vv_document || '<TH ' ||
                     dka_sapwfcsp_pkg.l_table_header_style ||
                     '  id="actionNote_3"><font ' ||
                     dka_sapwfcsp_pkg.l_font_header_style || '>' ||
                     fnd_message.get_string('DKA', 'DKA_SAPWFCSP_E034') ||
                     '</font></TH>' || nl; -- nom fourn

      vv_document := vv_document || '<TH ' ||
                     dka_sapwfcsp_pkg.l_table_header_style ||
                     '  id="action_3"><font ' ||
                     dka_sapwfcsp_pkg.l_font_header_style || '>' ||
                     fnd_message.get_string('DKA', 'DKA_SAPWFCSP_E032') ||
                     '</font></TH>' || nl; -- classe regl

      vv_document := vv_document || '<TH ' ||
                     dka_sapwfcsp_pkg.l_table_header_style ||
                     '  id="action_3"><font ' ||
                     dka_sapwfcsp_pkg.l_font_header_style || '>' ||
                     fnd_message.get_string('DKA', 'DKA_SAPWFCSP_E033') ||
                     '</font></TH>' || nl; --type fact

      vv_document := vv_document || '<TH ' ||
                     dka_sapwfcsp_pkg.l_table_header_style ||
                     '  id="actionNote_3"><font ' ||
                     dka_sapwfcsp_pkg.l_font_header_style || '>' ||
                     fnd_message.get_string('DKA', 'DKA_SAPWFCSP_E017') ||
                     '</font></TH>' || nl; --date

      vv_document := vv_document || '<TH ' ||
                     dka_sapwfcsp_pkg.l_table_header_style ||
                     '  id="actionNote_3"><font ' ||
                     dka_sapwfcsp_pkg.l_font_header_style || '>' ||
                     fnd_message.get_string('DKA', 'DKA_SAPWFCSP_E035') ||
                     '</font></TH>' || nl; -- N° comm

      vv_document := vv_document || '<TH ' ||
                     dka_sapwfcsp_pkg.l_table_header_style ||
                     '  id="actionNote_3"><font ' ||
                     dka_sapwfcsp_pkg.l_font_header_style || '>' ||
                     fnd_message.get_string('DKA', 'DKA_SAPWFCSP_E018') ||
                     '</font></TH>' || nl; -- ID

      vv_document := vv_document || '<TH ' ||
                     dka_sapwfcsp_pkg.l_table_header_style ||
                     '  id="action_3"><font ' ||
                     dka_sapwfcsp_pkg.l_font_header_style || '>' ||
                     fnd_message.get_string('DKA', 'DKA_SAPWFCSP_E016') ||
                     '</font></TH>' || nl; -- montant

      vv_document := vv_document || '<TH ' ||
                     dka_sapwfcsp_pkg.l_table_header_style ||
                     '  id="employee_3"><font ' ||
                     dka_sapwfcsp_pkg.l_font_header_style || '>' ||
                     fnd_message.get_string('DKA', 'DKA_SAPWFCSP_E026') ||
                     '</font></TH>' || nl;
      vv_document := vv_document || '<TH ' ||
                     dka_sapwfcsp_pkg.l_table_header_style ||
                     '  id="action_3"><font ' ||
                     dka_sapwfcsp_pkg.l_font_header_style || '>' ||
                     fnd_message.get_string('DKA', 'DKA_SAPWFCSP_E027') ||
                     '</font></TH>' || nl;
      vv_document := vv_document || '<TH ' ||
                     dka_sapwfcsp_pkg.l_table_header_style ||
                     '  id="actionNote_3"><font ' ||
                     dka_sapwfcsp_pkg.l_font_header_style || '>' ||
                     fnd_message.get_string('DKA', 'DKA_SAPWFCSP_E028') ||
                     '</font></TH>' || nl;
      vv_document := vv_document || '</TR>' || nl;

      vv_document := vv_document || nl || '<TR>' || nl;
      vv_document := vv_document || nl || '<td ' ||
                     dka_sapwfcsp_pkg.l_table_cell_unique_style ||
                     ' headers="employee_3"><font ' ||
                     dka_sapwfcsp_pkg.l_font_cell_style || '>' ||
                     nvl(vv_invoice_num, ' &nbsp') || '</font></td>' || nl;
      vv_document := vv_document || nl || '<td ' ||
                     dka_sapwfcsp_pkg.l_table_cell_unique_style ||
                     ' headers="employee_3"><font ' ||
                     dka_sapwfcsp_pkg.l_font_cell_style || '>' ||
                     nvl(vv_desc, ' &nbsp') || '</font></td>' || nl;
      vv_document := vv_document || nl || '<td ' ||
                     dka_sapwfcsp_pkg.l_table_cell_unique_style ||
                     ' headers="employee_3"><font ' ||
                     dka_sapwfcsp_pkg.l_font_cell_style || '>' ||
                     nvl(vv_num_vendeur, ' &nbsp') || '</font></td>' || nl;

      vv_document := vv_document || nl || '<td ' ||
                     dka_sapwfcsp_pkg.l_table_cell_unique_style ||
                     ' headers="employee_3"><font ' ||
                     dka_sapwfcsp_pkg.l_font_cell_style || '>' ||
                     nvl(vv_code_sitefourn, ' &nbsp') || '</font></td>' || nl;
      vv_document := vv_document || nl || '<td ' ||
                     dka_sapwfcsp_pkg.l_table_cell_unique_style ||
                     ' headers="action_3"><font ' ||
                     dka_sapwfcsp_pkg.l_font_cell_style || '>' ||
                     nvl(vv_nom_fourn, '&nbsp ') || '</font></td>' || nl;
      vv_document := vv_document || nl || '<td ' ||
                     dka_sapwfcsp_pkg.l_table_cell_unique_style ||
                     ' headers="employee_3"><font ' ||
                     dka_sapwfcsp_pkg.l_font_cell_style || '>' ||
                     nvl(vv_pay_group, ' &nbsp') || '</font></td>' || nl;

      vv_document := vv_document || nl || '<td ' ||
                     dka_sapwfcsp_pkg.l_table_cell_unique_style ||
                     ' headers="action_3"><font ' ||
                     dka_sapwfcsp_pkg.l_font_cell_style || '>' ||
                     nvl(vv_invoice_type, '&nbsp ') || '</font></td>' || nl;

      vv_document := vv_document || nl || '<td ' ||
                     dka_sapwfcsp_pkg.l_table_cell_unique_style ||
                     ' headers="action_3"><font ' ||
                     dka_sapwfcsp_pkg.l_font_cell_style || '>' ||
                     nvl(to_char(vd_invoice_date), '&nbsp ') ||
                     '</font></td>' || nl;
      vv_document := vv_document || nl || '<td ' ||
                     dka_sapwfcsp_pkg.l_table_cell_unique_style ||
                     ' headers="action_3"><font ' ||
                     dka_sapwfcsp_pkg.l_font_cell_style || '>' ||
                     nvl(vv_num_command, '&nbsp ') || '</font></td>' || nl;
      vv_document := vv_document || nl || '<td ' ||
                     dka_sapwfcsp_pkg.l_table_cell_unique_style ||
                     ' headers="action_3"><font ' ||
                     dka_sapwfcsp_pkg.l_font_cell_style || '>' ||
                     nvl(to_char(vn_invoice_id), '&nbsp ') ||
                     '</font></td>' || nl;
      vv_document := vv_document || nl || '<td ' ||
                     dka_sapwfcsp_pkg.l_table_cell_unique_style ||
                     ' headers="action_3"><font ' ||
                     dka_sapwfcsp_pkg.l_font_cell_style || '>' ||
                     nvl(to_char(vn_invoice_amount), '&nbsp ') ||
                     '</font></td>' || nl;
      --      vv_document :=  vv_document || NL ||  '<td ' || L_TABLE_CELL_STYLE || ' colspan="3" headers="action_3">'|| NL;
      --      vv_document :=  vv_document || get_blocages_AP( vn_invoice_id);
      --      vv_document :=  vv_document || NL ||'</td>'|| NL;
      --      vv_document := vv_document || '</TR>' || NL;

      vv_document := vv_document ||
                     dka_sapwfcsp_pkg.get_blocages_ap(vn_invoice_id,
                                                      vv_type_notif,
                                                      vv_item_key);
      vv_document := vv_document || '</TABLE> ' || nl;

      wf_notification.writetoclob(pv_document, vv_document);

    ELSIF (pv_display_type = 'text/plain') THEN
      wf_notification.writetoclob(pv_document, '');
    END IF;
    dka_sapwfcsp_pkg.print_wf_message(vv_item_type,
                                      vv_item_key,
                                      'get_infos_AP_ivalua  fin ',
                                      dka_sapwfcsp_pkg.cn_mode_debug);

  END get_infos_ap_ivalua;

  -------------------------------------------------------------------------------------
  --  Nom           : notif_reponse_ivalua
  --  Description   : Procedure gérant la notification dans le retour Ivalua
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE notif_reponse_ivalua(pv_itemtype  IN wf_items.item_type%TYPE,
                                 pv_itemkey   IN wf_items.item_key%TYPE,
                                 pn_actid     IN wf_item_activity_statuses_v.activity_id%TYPE, -- Ignore
                                 pv_funcmode  IN VARCHAR2,
                                 pv_resultout OUT NOCOPY VARCHAR2) IS

    vn_nid            wf_notifications.notification_id%TYPE;
    vv_commentaires   ap_inv_aprvl_hist.approver_comments%TYPE;
    lv_user           VARCHAR2(100);
    l_session_user_id NUMBER;
    l_session_resp_id NUMBER;
    l_session_appl_id NUMBER;
  BEGIN

    IF (pv_funcmode = 'TIMEOUT') THEN
      RETURN;
    END IF;

    IF (pv_funcmode <> wf_engine.eng_run AND pv_funcmode <> 'RESPOND') THEN
      -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
      l_session_resp_id := fnd_global.resp_id;
      l_session_appl_id := fnd_global.resp_appl_id;

      IF (l_session_resp_id = -1) THEN
        l_session_resp_id := NULL;
      END IF;

      IF (l_session_appl_id = -1) THEN
        l_session_appl_id := NULL;
      END IF;

      wf_engine.setitemattrnumber(itemtype => pv_itemtype,
                                  itemkey  => pv_itemkey,
                                  aname    => 'RESPONSIBILITY_ID',
                                  avalue   => l_session_resp_id);

      wf_engine.setitemattrnumber(itemtype => pv_itemtype,
                                  itemkey  => pv_itemkey,
                                  aname    => 'APPLICATION_ID',
                                  avalue   => l_session_appl_id);

      pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
      RETURN;

    END IF;
    dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'notif_REPONSE_IVALUA en pv_funcmode = ' ||
                                      pv_funcmode,
                                      dka_sapwfcsp_pkg.cn_mode_debug);
    vn_nid := wf_engine.context_nid;
    dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'nid: ' || vn_nid,
                                      dka_sapwfcsp_pkg.cn_mode_debug);

    -- recupere le motif saisi
    vv_commentaires := wf_notification.getattrtext(vn_nid, 'DKA_COMMENTS');

    IF (pv_funcmode = 'RESPOND') THEN

      -- Verifications
      IF vv_commentaires IS NULL THEN
        pv_resultout := wf_engine.eng_error || ':' ||
                        fnd_message.get_string('DKA', 'DKA_SAPWFCSP_E051');
        RETURN;
      ELSE
        wf_engine.setitemattrtext(itemtype => pv_itemtype,
                                  itemkey  => pv_itemkey,
                                  aname    => 'DKA_COMMENTS',
                                  avalue   => vv_commentaires);
      END IF;

      l_session_user_id := fnd_global.user_id;
      l_session_resp_id := fnd_global.resp_id;
      l_session_appl_id := fnd_global.resp_appl_id;

      IF (l_session_user_id = -1) THEN
        l_session_user_id := NULL;
      ELSE
         dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'notif_dest_ivalua VALIDEUR_IVALUA',
                                      dka_sapwfcsp_pkg.cn_mode_debug);
        /*SELECT user_name
          INTO lv_user
          FROM fnd_user
         WHERE user_id = l_session_user_id;*/
        wf_engine.setitemattrtext(itemtype => pv_itemtype,
                                  itemkey  => pv_itemkey,
                                  aname    => 'VALIDEUR_IVALUA',
                                  avalue   => wf_notification.responder(vn_nid));
      END IF;

      IF (l_session_resp_id = -1) THEN
        l_session_resp_id := NULL;
      END IF;

      IF (l_session_appl_id = -1) THEN
        l_session_appl_id := NULL;
      END IF;

      wf_engine.setitemattrnumber(itemtype => pv_itemtype,
                                  itemkey  => pv_itemkey,
                                  aname    => 'RESPONDER_USER_ID',
                                  avalue   => l_session_user_id);

      wf_engine.setitemattrnumber(itemtype => pv_itemtype,
                                  itemkey  => pv_itemkey,
                                  aname    => 'RESPONDER_RESP_ID',
                                  avalue   => l_session_resp_id);
      wf_engine.setitemattrnumber(itemtype => pv_itemtype,
                                  itemkey  => pv_itemkey,
                                  aname    => 'RESPONDER_APPL_ID',
                                  avalue   => l_session_appl_id);

      wf_engine.setitemattrnumber(itemtype => pv_itemtype,
                                  itemkey  => pv_itemkey,
                                  aname    => 'RESPONSIBILITY_ID',
                                  avalue   => l_session_resp_id);

      wf_engine.setitemattrnumber(itemtype => pv_itemtype,
                                  itemkey  => pv_itemkey,
                                  aname    => 'APPLICATION_ID',
                                  avalue   => l_session_appl_id);

    END IF;

    dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'notif_dest_ivalua fin',
                                      dka_sapwfcsp_pkg.cn_mode_debug);
  END notif_reponse_ivalua;

  -------------------------------------------------------------------------------------
  --  Nom           : traitement_blocage_ivalua
  --  Description   : Procedure de traitement du blocage « En attente » conformément à la réponse au BAP reçue d¿IVALUA
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE traitement_blocage_ivalua(pv_itemtype  IN wf_items.item_type%TYPE,
                                      pv_itemkey   IN wf_items.item_key%TYPE,
                                      pn_actid     IN wf_item_activity_statuses_v.activity_id%TYPE, -- Ignore
                                      pv_funcmode  IN VARCHAR2, -- Ignore
                                      pv_resultout OUT NOCOPY VARCHAR2) IS
    vn_invoice_id     NUMBER;
  vn_user_id_responder     NUMBER;
  vn_id_user   NUMBER;
    vn_user_id        NUMBER;
  vn_user_ivalua    NUMBER;
    vn_hold_id        NUMBER;
    vn_count          NUMBER;
    vn_count_qty_rec  NUMBER; --EDB428
    vv_response       VARCHAR2(50);
  vn_attribute5     VARCHAR2(25);
    vv_errbuf         VARCHAR2(250);
    vv_release_reason VARCHAR2(250);
    vv_motif_blocage  ap_hold_codes.description%TYPE;
    vv_comments       ap_inv_aprvl_hist.approver_comments%TYPE;
    vv_litige         VARCHAR2(100);
    vn_retcode        NUMBER;
    vv_user_name      VARCHAR2(20);
  BEGIN
    vn_retcode := 0;

    dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'traitement_blocage_ivalua debut ',
                                      dka_sapwfcsp_pkg.cn_mode_debug);
  
  --> EDB278-H + INC0585970
    vn_user_id_responder := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                              itemkey  => pv_itemkey,
                                              aname    => 'RESPONDER_USER_ID'); 
                        
  vn_id_user := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                              itemkey  => pv_itemkey,
                                              aname    => 'USER_ID');
        
  vn_user_id := NVL(vn_user_id_responder, vn_id_user); 

  --< EDB278-H + INC0585970
  
    select user_name into vv_user_name
    from fnd_user where user_id = vn_user_id;
  

  --EDB278-H
  select user_id into vn_user_ivalua
    from fnd_user where user_name like 'IVALUA';
    

    vn_invoice_id := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                                 itemkey  => pv_itemkey,
                                                 aname    => 'INVOICE_ID');

    vn_hold_id := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                              itemkey  => pv_itemkey,
                                              aname    => 'DKA_HOLD_ID');

    dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'vn_hold_id: ' || vn_hold_id,
                                      dka_sapwfcsp_pkg.cn_mode_debug);

    vv_comments := wf_engine.getitemattrtext(itemtype => pv_itemtype,
                                             itemkey  => pv_itemkey,
                                             aname    => 'DKA_COMMENTS');

    dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'vv_comments: ' || vv_comments,
                                      dka_sapwfcsp_pkg.cn_mode_debug);

    BEGIN
      SELECT response
        INTO vv_response
        FROM ap_inv_aprvl_hist_all
       WHERE approval_history_id IN
             (SELECT MAX(approval_history_id)
                FROM ap_inv_aprvl_hist_all
               WHERE invoice_id = vn_invoice_id
                 AND hold_id = vn_hold_id
                 AND approver_name = 'IVALUA');
    EXCEPTION
      WHEN OTHERS THEN
        dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                          pv_itemkey,
                                          'pas de reponse trouvé',
                                          dka_sapwfcsp_pkg.cn_mode_debug);
        pv_resultout := wf_engine.eng_completed || ':' || 'FAIL';
        RETURN;
    END;
  
    dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'vv_response: ' || vv_response,
                                      dka_sapwfcsp_pkg.cn_mode_debug);

    SELECT description
      INTO vv_release_reason
      FROM ap_hold_codes
     WHERE hold_lookup_code = 'APPROVED'
       AND hold_type = 'INVOICE RELEASE REASON';
     
    dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'vv_release_reason: ' ||
                                      vv_release_reason,
                                      dka_sapwfcsp_pkg.cn_mode_debug);
  -- > EDB278-H + INC0585970      
  BEGIN
  SELECT ATTRIBUTE5
        INTO vn_attribute5
        FROM ap_holds_all
       WHERE invoice_id = vn_invoice_id
     AND hold_lookup_code = cv_code_blocage_ivalua;
  EXCEPTION
      WHEN OTHERS THEN
        dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                          pv_itemkey,
                                          'pas d''attribute trouvé',
                                          dka_sapwfcsp_pkg.cn_mode_debug);
        pv_resultout := wf_engine.eng_completed || ':' || 'FAIL';
        RETURN;
  END;
  
  
  
  dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'vn_attribute5: ' ||
                                      vn_attribute5,
                                      dka_sapwfcsp_pkg.cn_mode_debug);
                    
    --ARA EDB428
  BEGIN
     select count(1)
     into vn_count_qty_rec
        FROM (
       select distinct 1
          from ap_invoices_all aia, ap_holds_all aha , ap_invoice_lines_all ail
         where aia.invoice_id = aha.invoice_id
           and aia.invoice_id = ail.invoice_id
          and hold_LOOKUP_CODE = cv_ano_qty_rec
           and RELEASE_LOOKUP_CODE is null
           and exists 
           (
             select 1 
             from po_headers_all poh
             WHERE poh.po_header_id = ail.po_header_id
             and poh.segment1 like 'ST%'
             and attribute7 = 'IVALUA'
           )
           AND NOT EXISTS (
          SELECT  1
          FROM ap_holds_all aha2
          WHERE aha2.invoice_id = aia.invoice_id
            AND aha2.hold_lookup_code like 'En litige%'
            AND aha2.release_lookup_code IS NULL
             )
       and aia.INVOICE_ID = vn_invoice_id
         );
         
    EXCEPTION
     WHEN OTHERS THEN
       fnd_file.put_line(fnd_file.LOG, 'Erreur recuperation existance QTY REC : ' || SQLERRM);
     END;
  
  --END ARA EDB428
                    
  --<EDB278-H + INC0585970    
  
    IF vv_response = 'DKA_ACCEPTE_IVALUA' THEN
  
       
    --< EDB278-H
    IF vn_attribute5 in ( 'LIGNE_FACT_SANS_CDE', 'BAP') --SHA-EB408 --AJOUT BAP
    THEN
    
    --ARA complement EDB278-H
    dka_sapwfcsp_pkg.leve_blocage(vn_invoice_id,
                                      cv_code_blocage_ivalua,
                                      'APPROVED',
                                      vn_user_id,
                                      vv_errbuf,
                                      vn_retcode,
                                      0,
                                      pv_itemtype,
                                      pv_itemkey,
                                      vv_release_reason);
    
    --commit;
      
      -- historise l'action
      insert_history_ivalua(pv_itemtype,
                            pv_itemkey,
                            'DKA_APPROVE',
                            cv_code_blocage_ivalua,
                            'DKA_ACCEPTE_IVALUA',
                            WF_DIRECTORY.GetRoleDisplayName('IVALUA'));--EDB278-H
    
    UPDATE ap_holds_all
         SET last_updated_by  = vn_user_ivalua
       WHERE invoice_id = vn_invoice_id
         AND hold_lookup_code = cv_ano_imput_attente;
     
      --ARA EDB428
    IF vn_count_qty_rec = 1 THEN
    
    dka_sapwfcsp_pkg.leve_blocage(vn_invoice_id,
                                      cv_ano_qty_rec,
                                      'APPROVED',
                                      vn_user_ivalua,
                                      vv_errbuf,
                                      vn_retcode,
                                      0,
                                      pv_itemtype,
                                      pv_itemkey,
                                      vv_release_reason);
    
    UPDATE ap_holds_all
         SET last_updated_by  = vn_user_ivalua
       WHERE invoice_id = vn_invoice_id
         AND hold_lookup_code = cv_ano_qty_rec;
    
    END IF;
    
    
     
    ELSE
    
    --< ARA complement EDB278-H
    SELECT COUNT(1)
        INTO vn_count
        FROM ap_holds_all
       WHERE invoice_id = vn_invoice_id
         AND hold_lookup_code != cv_code_blocage_ivalua
         AND release_lookup_code IS NULL;

      IF vn_count = 0 THEN 
      --> ARA complement EDB278-H
    dka_sapwfcsp_pkg.leve_blocage(vn_invoice_id,
                                      cv_code_blocage_ivalua,
                                      'APPROVED',
                                      vn_user_id,
                                      vv_errbuf,
                                      vn_retcode,
                                      0,
                                      pv_itemtype,
                                      pv_itemkey,
                                      vv_release_reason);
                    
      END IF;
    
    -- historise l'action
      insert_history_ivalua(pv_itemtype,
                            pv_itemkey,
                            'DKA_APPROVE',
                            cv_code_blocage_ivalua,
                            vv_comments,
                --- 2021/05/06 NBO - ACHATS_DGE20210003_EDB278-F - PFAD - SPE129 - MODIFICATION NOTIFICATIONS DU WORKFLOW
                            WF_DIRECTORY.GetRoleDisplayName(vv_user_name));
              
     UPDATE ap_holds_all
         SET last_updated_by  = vn_user_id
       WHERE invoice_id = vn_invoice_id
         AND hold_lookup_code = cv_ano_imput_attente;
     
    END IF;
    
    
    COMMIT;
   --> EDB278-H
    
    ELSIF vv_response = 'DKA_REFUSE_IVALUA' THEN

      vv_litige := dka_stransco_pkg.get_value_f(pv_set_name => 'DKA_BLOCAGES_IVALUA',
                                                pd_date     => SYSDATE,
                                                pv_errbuf   => vv_errbuf,
                                                pv_param1   => cv_code_blocage_ivalua);
      dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                        pv_itemkey,
                                        'vv_litige: ' || vv_litige,
                                        dka_sapwfcsp_pkg.cn_mode_debug);

      SELECT COUNT(1)
        INTO vn_count
        FROM ap_holds_all
       WHERE invoice_id = vn_invoice_id
         AND release_lookup_code IS NULL
         AND hold_lookup_code = vv_litige;

      dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                        pv_itemkey,
                                        'vn_count :' || vn_count,
                                        dka_sapwfcsp_pkg.cn_mode_debug);

      IF vn_count = 0 THEN
        SELECT description
          INTO vv_motif_blocage
          FROM ap_hold_codes
         WHERE hold_lookup_code = vv_litige;

        dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                          pv_itemkey,
                                          'cree_blocage_ap',
                                          dka_sapwfcsp_pkg.cn_mode_debug);
        dka_sapwfcsp_pkg.cree_blocage_ap('AP',
                                         vn_invoice_id,
                                         vv_litige,
                                         vv_motif_blocage,
                                         NULL,
                                         vn_user_id,
                                         pv_itemtype,
                                         pv_itemkey,
                                         vv_errbuf,
                                         vn_retcode);

      END IF;

      SELECT count(1)
       INTO vn_count
      FROM ap_holds_all aha
     WHERE invoice_id = vn_invoice_id
       AND hold_lookup_code != cv_code_blocage_ivalua
       AND release_lookup_code IS NULL
       AND (select count(1) from ap_holds_all
     WHERE invoice_id = aha.invoice_id
       AND hold_lookup_code NOT IN (cv_litige_BAP, cv_code_blocage_ivalua)
        AND release_lookup_code IS NULL) = 0;

     dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                          pv_itemkey,
                                          'nb_blocages : ' || vn_count,
                                          dka_sapwfcsp_pkg.cn_mode_debug);

      IF vn_count > 0 THEN
        dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                          pv_itemkey,
                                          'leve_blocage : ' || cv_code_blocage_ivalua,
                                          dka_sapwfcsp_pkg.cn_mode_debug);
        dka_sapwfcsp_pkg.leve_blocage(vn_invoice_id,
                                      cv_code_blocage_ivalua,
                                      'APPROVED',
                                      vn_user_id,
                                      vv_errbuf,
                                      vn_retcode,
                                      0,
                                      pv_itemtype,
                                      pv_itemkey,
                                      'Facture Mise en Litige');
      END IF;

      IF vn_retcode = 0 THEN
        -- historise l'action
        insert_history_ivalua(pv_itemtype,
                              pv_itemkey,
                              'DKA_REFUSE',
                              vv_litige,
                              vv_comments,
                  --- 2021/05/06 NBO - ACHATS_DGE20210003_EDB278-F - PFAD - SPE129 - MODIFICATION NOTIFICATIONS DU WORKFLOW
                              WF_DIRECTORY.GetRoleDisplayName(vv_user_name));
    
    --INC0585970 ARA
    UPDATE ap_holds_all
         SET last_updated_by  = vn_user_id
       WHERE invoice_id = vn_invoice_id
         AND hold_lookup_code = cv_ano_imput_attente;
    
    COMMIT;
    
    --END INC0585970 ARA
    
      END IF;

    END IF;

    dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'traitement_blocage_ivalua fin',
                                      dka_sapwfcsp_pkg.cn_mode_debug);
    IF vn_retcode = 0 THEN
      pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
    ELSE
      pv_resultout := wf_engine.eng_completed || ':' || 'FAIL';
    END IF;

  END traitement_blocage_ivalua;

  -------------------------------------------------------------------------------------
  --  Nom           : debloque_null
  --  Description   : Procédure enlevant un type de blocage
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --                   Lookup Sucess/fail
  -------------------------------------------------------------------------------------
  PROCEDURE debloque_null(pv_itemtype  IN wf_items.item_type%TYPE,
                          pv_itemkey   IN wf_items.item_key%TYPE,
                          pn_actid     IN wf_item_activity_statuses_v.activity_id%TYPE,
                          pv_funcmode  IN VARCHAR2, -- Ignore
                          pv_resultout OUT NOCOPY VARCHAR2) IS
    vn_invoice_id                 ap_invoices_all.invoice_id%TYPE;
    vv_blocage                    ap_lookup_codes.lookup_code%TYPE;
    vn_user_id                    fnd_user.user_id%TYPE;
    vv_user_name                  fnd_user.user_name%TYPE;
    vn_retcode                    NUMBER;
    vv_errbuf                     VARCHAR2(100);
    vv_code_deblocage             VARCHAR2(100);
    vv_release_reason             VARCHAR2(100);

  BEGIN
    dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'debloque  debut ',
                                      dka_sapwfcsp_pkg.cn_mode_debug);
    vn_invoice_id := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                                 itemkey  => pv_itemkey,
                                                 aname    => 'INVOICE_ID');

    vv_blocage := wf_engine.getactivityattrtext(actid    => pn_actid,
                                                itemtype => pv_itemtype,
                                                itemkey  => pv_itemkey,
                                                aname    => 'DKA_CODE_BLOCAGE');

    vv_code_deblocage := wf_engine.getactivityattrtext(actid    => pn_actid,
                                                       itemtype => pv_itemtype,
                                                       itemkey  => pv_itemkey,
                                                       aname    => 'DKA_CODE_DEBLOCAGE');

    vv_user_name := wf_engine.getactivityattrtext(actid    => pn_actid,
                                                  itemtype => pv_itemtype,
                                                  itemkey  => pv_itemkey,
                                                  aname    => 'PERSONNE_DEBLOQUEUR');

    --Nouvel NodeAttribute pour Simplification de l'axe métier
    BEGIN
      vv_release_reason := wf_engine.getactivityattrtext(actid    => pn_actid,
                                                         itemtype => pv_itemtype,
                                                         itemkey  => pv_itemkey,
                                                         aname    => 'DKA_RELEASE_REASON');
    EXCEPTION
      WHEN OTHERS THEN
        --l'exception permet de gérer les anciennes versions du WF.
        vv_release_reason := NULL;
    END;

    IF vv_user_name IS NOT NULL THEN
      SELECT u.user_id
        INTO vn_user_id
        FROM fnd_user u
       WHERE u.user_name = vv_user_name;
    ELSE
      vn_user_id := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                                itemkey  => pv_itemkey,
                                                aname    => 'USER_ID');
    END IF;

    dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'debloque  vn_user_id= ' ||
                                      vn_user_id,
                                      dka_sapwfcsp_pkg.cn_mode_debug);

    dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'debloque  vv_blocage =  ' ||
                                      vv_blocage ||
                                      '  vv_code_deblocage =  ' ||
                                      vv_code_deblocage ||
                                      '  vn_user_id =  ' || vn_user_id,
                                      dka_sapwfcsp_pkg.cn_mode_debug);

    dka_sapwfcsp_pkg.leve_blocage(vn_invoice_id,
                                  vv_blocage,
                                  vv_code_deblocage,
                                  vn_user_id,
                                  vv_errbuf,
                                  vn_retcode,
                                  0,
                                  pv_itemtype,
                                  pv_itemkey,
                                  vv_release_reason);

    IF vn_retcode = 0 THEN
      pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
    ELSE
      pv_resultout := wf_engine.eng_completed || ':' || 'FAIL';
    END IF;
    dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'debloque  fin ',
                                      dka_sapwfcsp_pkg.cn_mode_debug);
  END debloque_null;

  -------------------------------------------------------------------------------------
  --  Nom           : is_ivalua_order
  --  Description   : Procedure de traitement du blocage « En attente » conformément à la réponse au BAP reçue d¿IVALUA
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE is_ivalua_order(pv_itemtype  IN wf_items.item_type%TYPE,
                            pv_itemkey   IN wf_items.item_key%TYPE,
                            pn_actid     IN wf_item_activity_statuses_v.activity_id%TYPE, -- Ignore
                            pv_funcmode  IN VARCHAR2, -- Ignore
                            pv_resultout OUT NOCOPY VARCHAR2) IS
    vn_invoice_id NUMBER;
    ln_count      NUMBER;
  BEGIN

    dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'is_ivalua_order debut ',
                                      dka_sapwfcsp_pkg.cn_mode_debug);

    vn_invoice_id := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                                 itemkey  => pv_itemkey,
                                                 aname    => 'INVOICE_ID');
    SELECT COUNT(1)
      INTO ln_count
      FROM ap_invoice_distributions_all aida,
           po_distributions_all         pda,
           po_headers_all               pha
     WHERE aida.po_distribution_id = pda.po_distribution_id
       AND aida.invoice_id = vn_invoice_id
       AND pda.po_header_id = pha.po_header_id
       AND pha.attribute7 = 'IVALUA'
       AND (SELECT COUNT(1)
              FROM ap_invoice_distributions_all aida,
                   po_distributions_all         pda,
                   po_headers_all               pha
             WHERE aida.po_distribution_id = pda.po_distribution_id
               AND aida.invoice_id = vn_invoice_id
               AND pda.po_header_id = pha.po_header_id
               AND nvl(pha.attribute7, 'NOTIVALUA') != 'IVALUA') = 0;

    IF ln_count > 0 THEN
      pv_resultout := wf_engine.eng_completed || ':' || 'Y';
    ELSE
      pv_resultout := wf_engine.eng_completed || ':' || 'N';
    END IF;

    dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'is_ivalua_order fin ',
                                      dka_sapwfcsp_pkg.cn_mode_debug);
  END is_ivalua_order;

  -------------------------------------------------------------------------------------
  --  Nom           : notif_ecartprix_ivalua
  --  Description   : Procedure gérant la notification dans le transfert Ivalua
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE notif_ecartprix_ivalua(pv_itemtype  IN wf_items.item_type%TYPE,
                                   pv_itemkey   IN wf_items.item_key%TYPE,
                                   pn_actid     IN wf_item_activity_statuses_v.activity_id%TYPE, -- Ignore
                                   pv_funcmode  IN VARCHAR2,
                                   pv_resultout OUT NOCOPY VARCHAR2) IS

    vn_nid            wf_notifications.notification_id%TYPE;
    vv_nom_item_wf_stockage_action VARCHAR2(100);
    vv_result         VARCHAR2(100);
    vv_commentaires                AP_INV_APRVL_HIST.APPROVER_COMMENTS%type;
    l_session_user_id NUMBER;
    l_session_resp_id NUMBER;
    l_session_appl_id NUMBER;
  BEGIN

    IF (pv_funcmode = 'TIMEOUT') THEN
      RETURN;
    END IF;
    
    IF (pv_funcmode <> wf_engine.eng_run AND pv_funcmode <> 'RESPOND') THEN
      -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
      l_session_resp_id := fnd_global.resp_id;
      l_session_appl_id := fnd_global.resp_appl_id;

      IF (l_session_resp_id = -1) THEN
        l_session_resp_id := NULL;
      END IF;

      IF (l_session_appl_id = -1) THEN
        l_session_appl_id := NULL;
      END IF;

      wf_engine.setitemattrnumber(itemtype => pv_itemtype,
                                  itemkey  => pv_itemkey,
                                  aname    => 'RESPONSIBILITY_ID',
                                  avalue   => l_session_resp_id);

      wf_engine.setitemattrnumber(itemtype => pv_itemtype,
                                  itemkey  => pv_itemkey,
                                  aname    => 'APPLICATION_ID',
                                  avalue   => l_session_appl_id);

      pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
      RETURN;

    END IF;
    dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'notif_ecartprix_ivalua en pv_funcmode = ' ||
                                      pv_funcmode,
                                      dka_sapwfcsp_pkg.cn_mode_debug);
    vn_nid := wf_engine.context_nid;
    dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'nid: ' || vn_nid,
                                      dka_sapwfcsp_pkg.cn_mode_debug);

    -- recupere la reponse
    vv_result := wf_notification.getattrtext(vn_nid, 'Z_ACTION');

    -- recupere le motif saisi
    vv_commentaires := wf_notification.GetAttrText(vn_nid,
                                                   'DKA_COMMENTS');

    IF (pv_funcmode = 'RESPOND') THEN

      l_session_user_id := fnd_global.user_id;
      l_session_resp_id := fnd_global.resp_id;
      l_session_appl_id := fnd_global.resp_appl_id;

      IF (l_session_user_id = -1) THEN
        l_session_user_id := NULL;
      END IF;

      IF (l_session_resp_id = -1) THEN
        l_session_resp_id := NULL;
      END IF;

      IF (l_session_appl_id = -1) THEN
        l_session_appl_id := NULL;
      END IF;

      wf_engine.setitemattrnumber(itemtype => pv_itemtype,
                                  itemkey  => pv_itemkey,
                                  aname    => 'RESPONDER_USER_ID',
                                  avalue   => l_session_user_id);

      wf_engine.setitemattrnumber(itemtype => pv_itemtype,
                                  itemkey  => pv_itemkey,
                                  aname    => 'RESPONDER_RESP_ID',
                                  avalue   => l_session_resp_id);
      wf_engine.setitemattrnumber(itemtype => pv_itemtype,
                                  itemkey  => pv_itemkey,
                                  aname    => 'RESPONDER_APPL_ID',
                                  avalue   => l_session_appl_id);

      wf_engine.setitemattrnumber(itemtype => pv_itemtype,
                                  itemkey  => pv_itemkey,
                                  aname    => 'RESPONSIBILITY_ID',
                                  avalue   => l_session_resp_id);

      wf_engine.setitemattrnumber(itemtype => pv_itemtype,
                                  itemkey  => pv_itemkey,
                                  aname    => 'APPLICATION_ID',
                                  avalue   => l_session_appl_id);
                                  
      -- Verifications
      IF vv_commentaires is null then
          pv_resultout := wf_engine.eng_error || ':' ||
                          fnd_message.get_string('DKA',
                                                 'DKA_SAPWFCSP_E051');
          return;
      end if;

    END IF;

    IF (pv_funcmode = wf_engine.eng_run) THEN
          -- stocke la reponse dans l'items attribute du workflow passé en param
      vv_nom_item_wf_stockage_action := wf_notification.getattrtext(vn_nid,
                                                                    'DKA_G_W_ITEMATTR_REPONSE');

      wf_engine.setitemattrtext(itemtype => pv_itemtype,
                                itemkey  => pv_itemkey,
                                aname    => vv_nom_item_wf_stockage_action,
                                avalue   => vv_result);

      -- stocke qui fait l'action
      BEGIN
        wf_engine.setitemattrtext(itemtype => pv_itemtype,
                                  itemkey  => pv_itemkey,
                                  aname    => 'VALIDEUR_ECARTPRIX',
                                  avalue   => wf_notification.responder(vn_nid));
      EXCEPTION
        WHEN OTHERS THEN
          -- gestion de l'exception pour que l'ancien WF fonctionne
          NULL;
      END;
    END IF;

    dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'notif_ecartprix_ivalua fin',
                                      dka_sapwfcsp_pkg.cn_mode_debug);
  END notif_ecartprix_ivalua;

  -------------------------------------------------------------------------------------
  --  Nom           : get_ecart_prix_valua
  --  Description   : Procédure utilisée pour afficher le tableau des écart de prix sur
  --                  la facture
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --
  -------------------------------------------------------------------------------------
  PROCEDURE get_ecart_prix_ivalua(pv_document_id   IN VARCHAR2,
                                  pv_display_type  IN VARCHAR2,
                                  pv_document      IN OUT NOCOPY CLOB,
                                  pv_document_type IN OUT NOCOPY VARCHAR2) IS -- Ignore

    CURSOR c_ecart(p_invoice_id NUMBER) IS
      SELECT DISTINCT to_char(pl.line_num) line_num,
                      pha.segment1 num_de_commande,
                      TRIM(to_char(pl.unit_price, '999999990.90')) prix_commande,
                      TRIM(to_char(aid.unit_price, '999999990.90')) prix_facture,
                      TRIM(to_char((aid.unit_price - pl.unit_price),
                                   '999999990.90')) ecart
        FROM ap_holds_all                 ah,
             po_line_locations_all        pll,
             po_lines_all                 pl,
             ap_invoice_distributions_all aid,
             po_distributions_all         pd,
             po_headers_all               pha
       WHERE ah.hold_lookup_code = 'PRICE'
         AND pha.po_header_id = pl.po_header_id
         AND pll.line_location_id = ah.line_location_id
         AND pll.po_line_id = pl.po_line_id
         AND aid.invoice_id = ah.invoice_id
         AND aid.po_distribution_id = pd.po_distribution_id
         AND pl.po_line_id = pd.po_line_id
         AND ah.invoice_id = p_invoice_id
         AND nvl(reversal_flag, '@@@') != 'Y' --and reversal_flag is null   SFA -- artf07151619
         AND aid.unit_price <> pl.unit_price
       ORDER BY pl.line_num;

    vv_item_type      wf_items.item_type%TYPE;
    vv_item_key       wf_items.item_key%TYPE;
    vv_document       VARCHAR2(32000) := '';
    nl                VARCHAR2(1) := fnd_global.newline;
    l_notification_id NUMBER;
    vn_invoice_id     NUMBER;

  BEGIN
    dka_sapwfcsp_pkg.print_wf_message(vv_item_type,
                                      vv_item_key,
                                      'get_ecart_prix_ivalua  document_id= ' ||
                                      pv_document_id || 'pv_display_type ' ||
                                      pv_display_type,
                                      dka_sapwfcsp_pkg.cn_mode_debug);

    dka_sapwfcsp_pkg.get_item_info(pv_document_id,
                                   vv_item_type,
                                   vv_item_key,
                                   l_notification_id);

    dka_sapwfcsp_pkg.print_wf_message(vv_item_type,
                                      vv_item_key,
                                      'get_ecart_prix_ivalua  vv_item_type= ' ||
                                      vv_item_type || 'vv_item_key ' ||
                                      vv_item_key,
                                      dka_sapwfcsp_pkg.cn_mode_debug);

    vn_invoice_id := substr(vv_item_key, 1, instr(vv_item_key, '_') - 1);

    dka_sapwfcsp_pkg.print_wf_message(vv_item_type,
                                      vv_item_key,
                                      'get_ecart_prix_ivalua  vn_invoice_id= ' ||
                                      vn_invoice_id,
                                      dka_sapwfcsp_pkg.cn_mode_debug);

    IF (pv_display_type = 'text/html') THEN

      vv_document := nl || nl || '<!-- LIGNE ECART PRIX -->' || nl || nl;
      vv_document := vv_document || '<TABLE ' ||
                     dka_sapwfcsp_pkg.l_table_style || '>' || nl;
      vv_document := vv_document || '<TR>' || nl;
      --      vv_document := vv_document || '<TH ' || L_TABLE_HEADER_STYLE || ' width=25%>&nbsp </TH>' || NL;
      vv_document := vv_document || '<TH ' ||
                     dka_sapwfcsp_pkg.l_table_header_style || ' width=20%>' ||
                     fnd_message.get_string('DKA', 'DKA_SAPWFCSP_E068') ||
                     '</TH>' || nl;
      vv_document := vv_document || '<TH ' ||
                     dka_sapwfcsp_pkg.l_table_header_style || ' width=20%>' ||
                     fnd_message.get_string('DKA', 'DKA_SAPWFCSP_E069') ||
                     '</TH>' || nl;
      vv_document := vv_document || '<TH ' ||
                     dka_sapwfcsp_pkg.l_table_header_style || ' width=20%>' ||
                     fnd_message.get_string('DKA', 'DKA_SAPWFCSP_E036') ||
                     '</TH>' || nl;
      vv_document := vv_document || '<TH ' ||
                     dka_sapwfcsp_pkg.l_table_header_style || ' width=20%>' ||
                     fnd_message.get_string('DKA', 'DKA_SAPWFCSP_E037') ||
                     '</TH>' || nl;
      vv_document := vv_document || '<TH ' ||
                     dka_sapwfcsp_pkg.l_table_header_style || ' width=20%>' ||
                     fnd_message.get_string('DKA', 'DKA_SAPWFCSP_E038') ||
                     '</TH>' || nl;
      vv_document := vv_document || '</TR>' || nl;

      FOR l IN c_ecart(vn_invoice_id) LOOP
        vv_document := vv_document || nl || '<TR>' || nl;
        vv_document := vv_document || nl || '<td ' ||
                       dka_sapwfcsp_pkg.l_table_cell_center_style || ' >' ||
                       nvl(l.line_num, ' &nbsp') || '</td>' || nl;
        vv_document := vv_document || nl || '<td ' ||
                       dka_sapwfcsp_pkg.l_table_cell_center_style || '>' ||
                       nvl(l.num_de_commande, ' &nbsp') || '</td>' || nl;
        vv_document := vv_document || nl || '<td ' ||
                       dka_sapwfcsp_pkg.l_table_cell_right_style || ' >' ||
                       nvl(l.prix_commande, ' &nbsp') || '</td>' || nl;
        vv_document := vv_document || nl || '<td ' ||
                       dka_sapwfcsp_pkg.l_table_cell_right_style || ' >' ||
                       nvl(l.prix_facture, '&nbsp ') || '</td>' || nl;
        vv_document := vv_document || nl || '<td ' ||
                       dka_sapwfcsp_pkg.l_table_cell_right_style || ' >' ||
                       nvl(l.ecart, '&nbsp ') || '</td>' || nl;
        vv_document := vv_document || '</TR>' || nl;
      END LOOP;

      vv_document := vv_document || '</TABLE>' || nl;

      wf_notification.writetoclob(pv_document, vv_document);

    ELSIF (pv_display_type = 'text/plain') THEN
      wf_notification.writetoclob(pv_document, '');
    END IF;
    dka_sapwfcsp_pkg.print_wf_message(vv_item_type,
                                      vv_item_key,
                                      'get_ecart_prix_ivalua  end',
                                      dka_sapwfcsp_pkg.cn_mode_debug);
  END get_ecart_prix_ivalua;

  PROCEDURE insert_history_wf_ivalua(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                pv_funcmode  IN VARCHAR2,
                                pv_resultout OUT NOCOPY VARCHAR2) IS
        vv_code_blocage VARCHAR2(30);
        vv_destinataire VARCHAR2(100);
        vv_code_action  VARCHAR2(100);
        vv_commentaire  VARCHAR2(1000);
    BEGIN

        if (pv_funcmode <> wf_engine.eng_run) then

            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            return;

        end if;

        dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'insert_history_wf_ivalua  debut pv_itemtype = ' ||
                         pv_itemtype || 'pv_itemkey =  ' || pv_itemkey,
                         dka_sapwfcsp_pkg.cn_mode_debug);

        vv_code_blocage := wf_engine.GetActivityAttrText(actid    => pn_actid,
                                                         itemtype => pv_itemtype,
                                                         itemkey  => pv_itemkey,
                                                         aname    => 'CODE_BLOCAGE');

        vv_destinataire := wf_engine.GetActivityAttrText(actid    => pn_actid,
                                                         itemtype => pv_itemtype,
                                                         itemkey  => pv_itemkey,
                                                         aname    => 'DESTINATAIRE_NOTIF');

        vv_code_action := wf_engine.GetActivityAttrText(actid    => pn_actid,
                                                        itemtype => pv_itemtype,
                                                        itemkey  => pv_itemkey,
                                                        aname    => 'CODE_ACTION');

        vv_commentaire := wf_engine.GetActivityAttrText(actid    => pn_actid,
                                                        itemtype => pv_itemtype,
                                                        itemkey  => pv_itemkey,
                                                        aname    => 'COMMENTAIRE');
        dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'insert_history_wf_ivalua  COMMENTAIRE = ' ||
                         vv_commentaire,
                         dka_sapwfcsp_pkg.cn_mode_debug);
                         
        insert_history_ivalua(pv_itemtype,
                              pv_itemkey,
                              vv_code_action,
                              vv_code_blocage,
                              vv_commentaire,
                              WF_DIRECTORY.GetRoleDisplayName(vv_destinataire));

    END insert_history_wf_ivalua;

    -------------------------------------------------------------------------------------
    --  Nom           : notif_CSP_ANO_QTY_REC
    --  Description   :   Procedure gérant la notification que reçoit le CSP pour une
    --                     anomalie quantité facturée dépasse la quantité réceptionnée
    --  PARAMETRES :
    --
    --  VALEUR RETOURNEE :
    --     N/A
    -------------------------------------------------------------------------------------
    PROCEDURE notif_CSP_ANO_QTY_REC_IV(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                    pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                    pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type, -- ignore
                                    pv_funcmode  IN VARCHAR2,
                                    pv_resultout OUT NOCOPY VARCHAR2) IS

        vn_nid                         wf_notifications.notification_id%type;
        vv_result                      VARCHAR2(100);
        vv_commentaires                AP_INV_APRVL_HIST.APPROVER_COMMENTS%type;
        vv_nom_item_wf_stockage_action VARCHAR2(100);
        lv_user                        VARCHAR2(50);
        l_session_user_id               NUMBER;
        l_session_resp_id               NUMBER;
        l_session_appl_id               NUMBER;
    BEGIN

        if (pv_funcmode = 'TIMEOUT') THEN
            return;
        end if;

        IF (pv_funcmode <> wf_engine.eng_run AND pv_funcmode <> 'RESPOND') THEN
          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
        l_session_resp_id := fnd_global.resp_id;
        l_session_appl_id := fnd_global.resp_appl_id;

        IF (l_session_resp_id = -1) THEN
            l_session_resp_id := NULL;
        END IF;

        IF (l_session_appl_id = -1) THEN
            l_session_appl_id := NULL;
        END IF;

        wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                            itemkey => pv_itemkey,
                            aname   => 'RESPONSIBILITY_ID',
                            avalue  => l_session_resp_id);

                            wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                            itemkey => pv_itemkey,
                            aname   => 'APPLICATION_ID',
                            avalue  => l_session_appl_id);

            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            RETURN;

        END IF;

        dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_CSP_ANO_QTY_REC_IV en pv_funcmode = ' ||
                         pv_funcmode,
                         dka_sapwfcsp_pkg.cn_mode_debug);
        vn_nid := WF_ENGINE.context_nid;

        dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'nid: ' || vn_nid,
                         dka_sapwfcsp_pkg.cn_mode_debug);

        -- recupere le motif saisi
        vv_commentaires := wf_notification.GetAttrText(vn_nid,
                                                       'DKA_COMMENTS');

        -- recupere la reponse
        vv_result := wf_notification.GetAttrText(vn_nid, 'Z_ACTION');

        IF (pv_funcmode = 'RESPOND') THEN
          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
                    l_session_user_id := fnd_global.user_id;
            l_session_resp_id := fnd_global.resp_id;
            l_session_appl_id := fnd_global.resp_appl_id;

            IF (l_session_user_id = -1) THEN
              l_session_user_id := NULL;
            END IF;

            IF (l_session_resp_id = -1) THEN
                l_session_resp_id := NULL;
            END IF;

            IF (l_session_appl_id = -1) THEN
                l_session_appl_id := NULL;
            END IF;
            
            IF (l_session_user_id = -1) THEN
              l_session_user_id := NULL;
            ELSE
              SELECT user_name
                INTO lv_user
                FROM fnd_user
               WHERE user_id = l_session_user_id;
              wf_engine.setitemattrtext(itemtype => pv_itemtype,
                                        itemkey  => pv_itemkey,
                                        aname    => 'VALIDEUR_IVALUA',
                                        avalue   => lv_user);
            END IF;

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_USER_ID',
                                        avalue  => l_session_user_id);

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_RESP_ID',
                                        avalue  => l_session_resp_id);
            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_APPL_ID',
                                        avalue  => l_session_appl_id);

            -- Verifications
            IF vv_commentaires is null then
                pv_resultout := wf_engine.eng_error || ':' ||
                                fnd_message.get_string('DKA',
                                                       'DKA_SAPWFCSP_E051');
                return;
            end if;
        END IF;

        IF (pv_funcmode = wf_engine.eng_run) THEN

            -- stocke la reponse dans l'items attribute du workflow passé en param
            vv_nom_item_wf_stockage_action := wf_notification.GetAttrText(vn_nid,
                                                                          'DKA_G_W_ITEMATTR_REPONSE');

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => vv_nom_item_wf_stockage_action,
                                      avalue   => vv_result);

            -- stocke qui fait l'action
            BEGIN
              wf_engine.setitemattrtext(itemtype => pv_itemtype,
                                        itemkey  => pv_itemkey,
                                        aname    => 'VALIDEUR_QTYREC',
                                        avalue   => wf_notification.responder(vn_nid));
            EXCEPTION
              WHEN OTHERS THEN
                -- gestion de l'exception pour que l'ancien WF fonctionne
                NULL;
            END;

        END IF;
        dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_CSP_ANO_QTY_REC_IV fin',
                         dka_sapwfcsp_pkg.cn_mode_debug);
    END notif_CSP_ANO_QTY_REC_IV;

    -------------------------------------------------------------------------------------
    --  Nom           : notif_CSP_ANO_ORD_REC_IV
    --  Description   :   Procedure gérant la notification que reçoit le CSP pour une
    --                     anomalie quantité commandée dépasse la quantité réceptionnée
    --  PARAMETRES :
    --
    --  VALEUR RETOURNEE :
    --     N/A
    -------------------------------------------------------------------------------------
    PROCEDURE notif_CSP_ANO_QTY_ORD_IV(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                    pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                    pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type, -- ignore
                                    pv_funcmode  IN VARCHAR2,
                                    pv_resultout OUT NOCOPY VARCHAR2) IS

        vn_nid                         wf_notifications.notification_id%type;
        vv_result                      VARCHAR2(100);
        vv_commentaires                AP_INV_APRVL_HIST.APPROVER_COMMENTS%type;
        vv_nom_item_wf_stockage_action VARCHAR2(100);
        lv_user                        VARCHAR2(50);
        l_session_user_id               NUMBER;
        l_session_resp_id               NUMBER;
        l_session_appl_id               NUMBER;
    BEGIN

        if (pv_funcmode = 'TIMEOUT') THEN
            return;
        end if;

        IF (pv_funcmode <> wf_engine.eng_run AND pv_funcmode <> 'RESPOND') THEN
          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
        l_session_resp_id := fnd_global.resp_id;
        l_session_appl_id := fnd_global.resp_appl_id;

        IF (l_session_resp_id = -1) THEN
            l_session_resp_id := NULL;
        END IF;

        IF (l_session_appl_id = -1) THEN
            l_session_appl_id := NULL;
        END IF;

        wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                            itemkey => pv_itemkey,
                            aname   => 'RESPONSIBILITY_ID',
                            avalue  => l_session_resp_id);

                            wf_engine.SetItemAttrNumber(itemtype=>pv_itemtype,
                            itemkey => pv_itemkey,
                            aname   => 'APPLICATION_ID',
                            avalue  => l_session_appl_id);

            pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
            RETURN;

        END IF;

        dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_CSP_ANO_QTY_REC_IV en pv_funcmode = ' ||
                         pv_funcmode,
                         dka_sapwfcsp_pkg.cn_mode_debug);
        vn_nid := WF_ENGINE.context_nid;

        dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'nid: ' || vn_nid,
                         dka_sapwfcsp_pkg.cn_mode_debug);

        -- recupere le motif saisi
        vv_commentaires := wf_notification.GetAttrText(vn_nid,
                                                       'DKA_COMMENTS');

        -- recupere la reponse
        vv_result := wf_notification.GetAttrText(vn_nid, 'Z_ACTION');

        IF (pv_funcmode = 'RESPOND') THEN
          -- 2019/03/08 NBO artf07150229 - INCXXXXX - Notifications workflow en erreur
                    l_session_user_id := fnd_global.user_id;
            l_session_resp_id := fnd_global.resp_id;
            l_session_appl_id := fnd_global.resp_appl_id;

            IF (l_session_user_id = -1) THEN
              l_session_user_id := NULL;
            END IF;

            IF (l_session_resp_id = -1) THEN
                l_session_resp_id := NULL;
            END IF;

            IF (l_session_appl_id = -1) THEN
                l_session_appl_id := NULL;
            END IF;
            
-- 2020/12/15 NBO SPE129 - Anomalies sur WF n°2B
            IF (l_session_user_id = -1) THEN
              l_session_user_id := NULL;
            ELSE
              SELECT user_name
                INTO lv_user
                FROM fnd_user
               WHERE user_id = l_session_user_id;
              wf_engine.setitemattrtext(itemtype => pv_itemtype,
                                        itemkey  => pv_itemkey,
                                        aname    => 'VALIDEUR_IVALUA',
                                        avalue   => lv_user);
            END IF;

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_USER_ID',
                                        avalue  => l_session_user_id);

            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_RESP_ID',
                                        avalue  => l_session_resp_id);
            wf_engine.SetItemAttrNumber(itemtype=> pv_itemtype,
                                        itemkey => pv_itemkey,
                                        aname   => 'RESPONDER_APPL_ID',
                                        avalue  => l_session_appl_id);

            -- Verifications
            IF vv_commentaires is null then
                pv_resultout := wf_engine.eng_error || ':' ||
                                fnd_message.get_string('DKA',
                                                       'DKA_SAPWFCSP_E051');
                return;
            end if;
        END IF;

        IF (pv_funcmode = wf_engine.eng_run) THEN

            -- stocke la reponse dans l'items attribute du workflow passé en param
            vv_nom_item_wf_stockage_action := wf_notification.GetAttrText(vn_nid,
                                                                          'DKA_G_W_ITEMATTR_REPONSE');

            wf_engine.SetItemAttrText(itemtype => pv_itemtype,
                                      itemkey  => pv_itemkey,
                                      aname    => vv_nom_item_wf_stockage_action,
                                      avalue   => vv_result);

            -- stocke qui fait l'action
            BEGIN
              wf_engine.setitemattrtext(itemtype => pv_itemtype,
                                        itemkey  => pv_itemkey,
                                        aname    => 'VALIDEUR_QTYORD',
                                        avalue   => wf_notification.responder(vn_nid));
            EXCEPTION
              WHEN OTHERS THEN
                -- gestion de l'exception pour que l'ancien WF fonctionne
                NULL;
            END;

        END IF;
        dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                         pv_itemkey,
                         'notif_CSP_ANO_QTY_REC_IV fin',
                         dka_sapwfcsp_pkg.cn_mode_debug);
    END notif_CSP_ANO_QTY_ORD_IV;
  
--< EDB278-H
  -------------------------------------------------------------------------------------
  --  Nom           : get_reponse_blocage_ivalua
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     Oui/Non
  -------------------------------------------------------------------------------------
  PROCEDURE get_reponse_blocage_ivalua(pv_itemtype  IN wf_items.item_type%TYPE,
                                      pv_itemkey   IN wf_items.item_key%TYPE,
                                      pn_actid     IN wf_item_activity_statuses_v.activity_id%TYPE, -- Ignore
                                      pv_funcmode  IN VARCHAR2, -- Ignore
                                      pv_resultout OUT NOCOPY VARCHAR2) IS
    vn_invoice_id     NUMBER;
    vn_hold_id        NUMBER;
    vv_response       VARCHAR2(50);

  BEGIN

    dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'get_reponse_blocage_ivalua debut ',
                                      dka_sapwfcsp_pkg.cn_mode_debug);
    

    vn_invoice_id := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                                 itemkey  => pv_itemkey,
                                                 aname    => 'INVOICE_ID');

    vn_hold_id := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                              itemkey  => pv_itemkey,
                                              aname    => 'DKA_HOLD_ID');

    dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'vn_hold_id: ' || vn_hold_id,
                                      dka_sapwfcsp_pkg.cn_mode_debug);

    BEGIN
    SELECT response
        INTO vv_response
        FROM ap_inv_aprvl_hist_all
       WHERE approval_history_id IN
             (SELECT MAX(approval_history_id)
                FROM ap_inv_aprvl_hist_all api,ap_holds_all aph
               WHERE api.hold_id = aph.hold_id
                 AND api.invoice_id = aph.invoice_id
                 AND api.invoice_id = vn_invoice_id
                 AND api.hold_id = vn_hold_id
         AND aph.hold_lookup_code = 'En attente'
                 AND aph.attribute5 in ( 'LIGNE_FACT_SANS_CDE','BAP')--SHA-EB408 ---ajout BAP
                 AND api.approver_name = 'IVALUA');
    EXCEPTION
      WHEN OTHERS THEN
        dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                          pv_itemkey,
                                          'pas de reponse trouvée',
                                          dka_sapwfcsp_pkg.cn_mode_debug);
        pv_resultout := 'COMPLETE:' || 'N';
        RETURN;
    END;

    dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'vv_response: ' || vv_response,
                                      dka_sapwfcsp_pkg.cn_mode_debug);

    IF vv_response = 'DKA_ACCEPTE_IVALUA' THEN
      
    
    dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                          pv_itemkey,
                                          'get_reponse_blocage_ivalua : retourne oui',
                                          dka_sapwfcsp_pkg.cn_mode_debug);
    
      pv_resultout := 'COMPLETE:' || 'Y';
    
    ELSE
  
  dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                          pv_itemkey,
                                          'get_reponse_blocage_ivalua : retourne non',
                                          dka_sapwfcsp_pkg.cn_mode_debug);
  pv_resultout := 'COMPLETE:' || 'N';

    END IF;
  
  dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                      pv_itemkey,
                                      'get_reponse_blocage_ivalua fin ',
                                      dka_sapwfcsp_pkg.cn_mode_debug);

  END get_reponse_blocage_ivalua;

--> EDB278-H

  -------------------------------------------------------------------------------------
  --  Nom           : verif_blocage_ivalua
  --  Description   : Procedure de verification du blocage « En attente »avec le flag 'Y'
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE verif_blocage_ivalua(pv_itemtype  IN wf_items.item_type%TYPE,
                                 pv_itemkey   IN wf_items.item_key%TYPE,
                                 pn_actid     IN wf_item_activity_statuses_v.activity_id%TYPE, -- Ignore
                                 pv_funcmode  IN VARCHAR2, -- Ignore
                                 pv_resultout OUT NOCOPY VARCHAR2) IS
    vn_invoice_id NUMBER;
    ln_count      NUMBER;
  BEGIN
     dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                       pv_itemkey,
                                       'verif_blocage_ivalua début',
                                       dka_sapwfcsp_pkg.cn_mode_debug);
                                       
    vn_invoice_id := wf_engine.getitemattrnumber(itemtype => pv_itemtype,
                                                 itemkey  => pv_itemkey,
                                                 aname    => 'INVOICE_ID');             

     SELECT count(1) 
     INTO ln_count
     FROM ap_holds_all
     WHERE attribute4 = 'Y'
     AND invoice_id = vn_invoice_id
     AND hold_lookup_code = cv_code_blocage_ivalua;
       
     IF ln_count >= 1 THEN
       pv_resultout := wf_engine.eng_completed || ':' || 'Y';
     ELSE
       pv_resultout := wf_engine.eng_completed || ':' || 'N';
     END IF;

     dka_sapwfcsp_pkg.print_wf_message(pv_itemtype,
                                       pv_itemkey,
                                       'verif_blocage_ivalua fin ',
                                       dka_sapwfcsp_pkg.cn_mode_debug);
  END verif_blocage_ivalua; 

END dka_sapwfcsp_ivalua_pkg;
/
show error;
exit;
