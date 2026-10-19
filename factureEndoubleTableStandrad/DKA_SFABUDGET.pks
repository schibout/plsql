CREATE OR REPLACE PACKAGE BODY APPS.DKA_SAPIAWIE_pkg AS
  ---------------------------------------------------------------------------------------------------------------
  -- $Id: DKA_SAPIAWIE_pkg.pkb 485 2008-04-16 08:04:21Z CORP\jjardez $
  --
  -- CAPGEMINI
  -- PROJET      : VEOLIA Puissance 4
  -- NOM         : DKA_SAPIAWIE_PKG.pkb
  -- DESCRIPTION : DKA_SAPIAWIE_PKG package body :
  ---              package spécifique utilisé dans le workflow remplacant le workflow approbation AP
  --- AUTEUR       : Vincent Knab (CAPGEMINI)
  --- DATE DE CREATION : 16/01/2008
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
  ---------------------------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- ---------- --- --------------------------------------------------------------------------------------------
  --- 2016/07/05 JJA Portage Helios R12
 ---------------------------------------------------------------------------------------------------------------
  --- 2017/08/08 NBO artf2068302 - SPE129 - Exclusion des sociétés du controle de l'image
  --- 2018/05/30 RBE artf2677019 : INC0197034 : Problème d'approbation des factures
  --- 2019/02/25 SFA INC0290921 - Problème d'alignement statut sur une facture
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PUBLIQUES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PRIVEES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


  PROCEDURE print_log_message(pv_message IN VARCHAR2, pn_mode_debug IN NUMBER) IS
    vv_message VARCHAR2(1000);
  BEGIN

    vv_message := substr(pv_message, 1, 1000);

    IF (vv_message IS NOT NULL) THEN

      vv_message := to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                    vv_message;
      dbms_output.put_line(vv_message);
      wf_core.CONTEXT('DKA_SAPWFCSP_PKG', vv_message, vv_message);
      IF pn_mode_debug >= 1 THEN
            fnd_file.put_line(fnd_file.log, vv_message);
      END IF;
    END IF;
  END print_log_message;

  -------------------------------------------------------------------------------------
  --  Nom           : print_wf_message
  --  Description   : Procédure insérant un message dans le log du traitement.
  --
  --  PARAMETRES :
  --     pv_message   Entrée      Message a insérer
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE print_wf_message(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                             pv_itemkey   IN VARCHAR2,
                             pv_message IN VARCHAR2) IS
  pragma AUTONOMOUS_TRANSACTION;
    vv_message VARCHAR2(1000);
  BEGIN
     vv_message := substr(pv_message, 1, 1000);
     print_log_message( pv_message, cn_mode_debug);
     IF cn_mode_debug = 2 THEN
          -- Table de DEBUG
          insert into DKA_WF_DEBUG values (pv_itemkey,vv_message,  sysdate, DKA_wf_debug_seq.nextval);
          commit;
     END IF;
  END print_wf_message;


  -------------------------------------------------------------------------------------
  --  Nom           : is_facture_perimetre_CSP
  --  Description   : Procédure vérifiant si la facture est dans le périmetre
  --                     d'un CSP
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --                   Lookup YES/NO
  -------------------------------------------------------------------------------------
    PROCEDURE is_facture_perimetre_CSP(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                                       pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                                       pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                                       pv_funcmode  IN VARCHAR2,
                                       pv_resultout OUT NOCOPY VARCHAR2) IS
      vn_invoice_id     ap_invoices_all.invoice_id%type;
      vv_source         ap_invoices_all.source%type;
      vv_division       hr_all_organization_units.attribute10%type;
      vv_region         varchar2(50);
      vn_geree_par_CSP  number;
      vv_type_facture   AP_INVOICES_all.invoice_type_lookup_code%type;
      vn_org_id         AP_INVOICES_all.org_id%type;
      vv_doc_category_code  AP_INVOICES_all.doc_category_code%type;
    BEGIN
      vn_invoice_id := substr(pv_itemkey, 1, instr(pv_itemkey,'_')-1);

      select
       ai.source,
       hou.attribute10 ,
       substr(hou.name, 1, 3) ,
       ai.invoice_type_lookup_code,
       ai.org_id,
       ai.doc_category_code
      into
       vv_source,
       vv_division,
       vv_region,
       vv_type_facture,
       vn_org_id,
       vv_doc_category_code
      from
       hr_all_organization_units hou,
       AP_INVOICES_all ai
      where
      hou.organization_id = ai.org_id
      and invoice_id = vn_invoice_id;

      WF_ENGINE.SETITEMATTRNumber(pv_itemtype,
          pv_itemkey,
          'ORG_ID',
          vn_org_id);


      -- determine si la facture est rattachee a un couple (division, region) gere par un CSP
      SELECT count(1)
      into  vn_geree_par_CSP
      FROM
       dka_stransco_headers dsh,
       dka_stransco_lines dsl
      WHERE dsh.Set_Id = dsl.set_id
       AND dsh.set_name = 'CENTRE_SERVICE_PARTAGE'
       and dsl.param1_value = vv_division
       and dsl.param2_value =  vv_region
       and dsl.start_date <= trunc(sysdate)
       and nvl(dsl.end_date,trunc(sysdate)) >= trunc(sysdate)
       and rownum <2;


      IF (
            /*  uniquement pour les factures venant de l'Open Interface */ vv_source ='SCAN_XGS'  or vv_source ='SCAN'
            or /* facture AP directement saisies */ vv_source ='Manual Invoice Entry'
          )
        and  vn_geree_par_CSP=1
        and ( vv_type_facture ='STANDARD' or vv_type_facture ='CREDIT')
        and vv_doc_category_code not like '%REPRISE%'
      THEN
         pv_resultout:='COMPLETE:'||'Y';
      ELSE
         pv_resultout:='COMPLETE:'||'N';
      END IF;
  END is_facture_perimetre_CSP;


 -------------------------------------------------------------------------------------
  --  Nom           : insert_history
  --  Description   : Procédure insérant l'approbation dans la table d'hitorique standard
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --
  -------------------------------------------------------------------------------------
  PROCEDURE insert_history(pn_invoice_id  IN AP_INV_APRVL_HIST.INVOICE_ID%type,
                          pn_iteration IN AP_INV_APRVL_HIST.ITERATION%type,
                          pn_org_id IN  AP_INV_APRVL_HIST.ORG_ID%type,
                          pv_status IN AP_INV_APRVL_HIST.RESPONSE%type) IS
    ln_hist_id  AP_INV_APRVL_HIST.APPROVAL_HISTORY_ID%type;
    ln_amount        ap_invoices_all.invoice_amount%TYPE;
  BEGIN
      --MOAC
      MO_GLOBAL.INIT (p_appl_short_name => 'SQLAP');

      --insert into the history table
      SELECT AP_INV_APRVL_HIST_S.nextval
            INTO ln_hist_id
            FROM dual;

      SELECT invoice_amount
      INTO ln_amount
      FROM AP_INVOICES_ALL
      WHERE invoice_id = pn_invoice_id;

      INSERT INTO  AP_INV_APRVL_HIST
        (APPROVAL_HISTORY_ID
        ,INVOICE_ID
        ,ITERATION
        ,RESPONSE
        ,APPROVER_ID
        ,APPROVER_NAME
        ,AMOUNT_APPROVED
        ,CREATED_BY
        ,CREATION_DATE
        ,LAST_UPDATE_DATE
        ,LAST_UPDATED_BY
        ,LAST_UPDATE_LOGIN
        ,ORG_ID)
      VALUES (
        ln_hist_id,
        pn_invoice_id,
        pn_iteration,
        pv_status,
        NULL,
        FND_PROFILE.VALUE('USERNAME'),
        ln_amount,
        nvl(to_number(fnd_profile.value('USER_ID')),-1),
        sysdate,
        sysdate,
        nvl(to_number(fnd_profile.value('USER_ID')),-1),
        nvl(to_number(fnd_profile.value('LOGIN_ID')),-1),
        pn_org_id);

      commit;

  END insert_history;


  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : approuve_facture_auto_pl
  --  Description   : Lance l'approbation de la facture en automatique depuis le pl
  --
  --  PARAMETRES    :
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE approuve_facture_auto_pl(pn_invoice_id IN ap_invoices_all.invoice_id%type,
            vn_iteration IN AP_INV_APRVL_HIST.ITERATION%type DEFAULT 1) IS
     vn_org_id   ap_invoices_all.org_id%type;
  BEGIN
    --MOAC
    MO_GLOBAL.INIT (p_appl_short_name => 'SQLAP');

    -- MAJ du champ statut d'approbation. Celui ci passe de REQUIRED a WFAPPROVED
    UPDATE AP_INVOICES_all
    SET wfapproval_status = 'WFAPPROVED'
    WHERE invoice_id = pn_invoice_id
    returning org_id into vn_org_id;

    -- RBE artf2677019 : MAJ du champ statut d'approbation pour les lignes. Celui ci passe de INITIATED a REQUIRED
    /*UPDATE AP_INVOICE_LINES_ALL
    SET wfapproval_status = 'REQUIRED'
    WHERE invoice_id = pn_invoice_id
    AND wfapproval_status = 'INITIATED';*/

  --ajouté par SFA : INC0290921

    UPDATE AP_INVOICE_LINES_ALL
    SET wfapproval_status ='NOT REQUIRED'
    WHERE  wfapproval_status IN ('INITIATED' , 'NEEDS WFREAPPROVAL', 'WFAPPROVED')
      AND invoice_id IN
   (SELECT invoice_id FROM  ap_invoices_all WHERE wfapproval_status = 'WFAPPROVED'
   -- NBO 03/04/2019 :
    AND invoice_id = pn_invoice_id);

  ---fin ajout par SFA-- INC0290921

    -- insere dans l'historique le fait que la facture a été approuvée
    -- pour visu dan l'écran standard d'historique d'approbation
    insert_history(pn_invoice_id,
                        vn_iteration ,
                        vn_org_id ,
                        'WFAPPROVED' );
  END approuve_facture_auto_pl;


  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : approuve_facture_auto
  --  Description   : Lance l'approbation de la facture en automatique depuis le workflow
  --
  --  PARAMETRES    :
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE approuve_facture_auto(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                           pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                           pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                           pv_funcmode  IN VARCHAR2,
                           pv_resultout OUT NOCOPY VARCHAR2) IS
  vn_invoice_id  ap_invoices_all.invoice_id%type;
  vn_org_id   ap_invoices_all.org_id%type;
  vn_iteration  AP_INV_APRVL_HIST.ITERATION%type;
  BEGIN
    vn_invoice_id := substr(pv_itemkey, 1, instr(pv_itemkey,'_')-1);

    vn_iteration := substr(pv_itemkey, instr(pv_itemkey,'_')+1, length(pv_itemkey));
    approuve_facture_auto_pl(   vn_invoice_id,   vn_iteration);
    print_wf_message(pv_itemtype , pv_itemkey   ,' approuve_facture_auto user_id = ' ||FND_PROFILE.VALUE('USER_ID'));

    pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
  END approuve_facture_auto;






  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : lance_workflow_CSP
  --  Description   : Lance le workflow CSP de puis le workflow standard
  --
  --  PARAMETRES    :
  --
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
   PROCEDURE lance_workflow_CSP(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                           pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                           pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                           pv_funcmode  IN VARCHAR2,
                           pv_resultout OUT NOCOPY VARCHAR2) IS
    vn_invoice_id  ap_invoices_all.invoice_id%type;
    vn_retcode    number :=0;
    vv_errbuf   VARCHAR2(1000);
    vv_step        VARCHAR2(50);
    vn_dummy       NUMBER;
    vv_item_key    WF_ITEMS.ITEM_KEY%type;
    vv_wf_itemtype WF_ITEMS.ITEM_TYPE%type;
    vv_wf_process  VARCHAR2(20);

  BEGIN
      vn_invoice_id := substr(pv_itemkey, 1, instr(pv_itemkey,'_')-1);
      print_wf_message(pv_itemtype , pv_itemkey   ,' lance_workflow_CSP pour la facture ' || vn_invoice_id);
      vv_wf_itemtype := 'DKA_CSP';

      vv_wf_process  := 'DKA_PROCESS_AP';
        SELECT to_char(DKA_SAPWFCSP_s.NEXTVAL)
          INTO vn_dummy
          FROM dual;


      vv_item_key := vn_invoice_id || '_' || vn_dummy;


      -- Creation du process WF
      wf_engine.createprocess(itemtype => vv_wf_itemtype,
                            itemkey  => vv_item_key,
                            process  => vv_wf_process);


      IF pv_itemtype is not null and pv_itemkey is not null then
          -- Lie le workflow au workflow Maître
          wf_engine.setitemparent(itemtype        => vv_wf_itemtype,
                                  itemkey         => vv_item_key,
                                  parent_itemtype => pv_itemtype,
                                  parent_itemkey  => pv_itemkey,
                                  parent_context  => NULL);
      end if;



      wf_engine.setitemattrnumber(itemtype => vv_wf_itemtype,
                                    itemkey  => vv_item_key,
                                    aname    => 'INVOICE_ID',
                                    avalue   => vn_invoice_id);


    -- Kick off the process
    wf_engine.startprocess(itemtype => vv_wf_itemtype,
                           itemkey  => vv_item_key);


    pv_resultout := wf_engine.eng_completed || ':' || 'SUCCESS';
    COMMIT;

    EXCEPTION
       WHEN OTHERS THEN
             pv_resultout := wf_engine.eng_completed || ':' || 'FAIL';

  END lance_workflow_CSP;

-------------------------------------------------------------------------------------
  --  Nom           : Invoice_image_exists
  --  Description   :
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --                   Lookup YES/NO
  -------------------------------------------------------------------------------------
    PROCEDURE Invoice_image_exists(pv_itemtype  IN WF_ITEMS.ITEM_TYPE%type,
                           pv_itemkey   IN WF_ITEMS.ITEM_KEY%type,
                           pn_actid     IN WF_ITEM_ACTIVITY_STATUSES_V.ACTIVITY_ID%type,
                           pv_funcmode  IN VARCHAR2,
                           pv_resultout OUT NOCOPY VARCHAR2) IS
      vn_invoice_id  ap_invoices_all.invoice_id%type;
      vv_source        ap_invoices_all.source%type;
      vn_org_id       AP_INVOICES_all.org_id%type;
      vv_doc_category_code  AP_INVOICES_all.doc_category_code%type;
      vv_attribute9         AP_INVOICES_all.Attribute9%type;
      vv_exclude_count     number:=0;
      vv_image_count       number:=0;
      vv_org_name VARCHAR2(15);

    vn_verif_notif     number:=0;
    BEGIN
      vn_invoice_id := substr(pv_itemkey, 1, instr(pv_itemkey,'_')-1);

      select ai.source, ai.org_id, ai.doc_category_code,ai.attribute9, hou.name
      into vv_source, vn_org_id, vv_doc_category_code,vv_attribute9, vv_org_name
      from  AP_INVOICES_all ai, hr_operating_units hou
      where invoice_id = vn_invoice_id
      and hou.organization_id = ai.org_id;


      -- check if the legal entity is in the list of excluded legal entities

      select count(1)
       into vv_exclude_count
       from DKA_STRANSCO_HEADERS DSH,
            DKA_STRANSCO_LINES DSL
      where dsh.set_name='DKA_STES_EXCLUES'
        and dsh.set_id=dsl.set_id
        --- 2017/08/08 NBO artf2068302 - SPE129 - Exclusion des sociétés du controle de l'image
        and ((dsl.param1_value = substr(vv_org_name,4,4) AND dsl.param2_value IS NULL)
        or (dsl.param1_value = substr(vv_org_name,4,4) AND dsl.param2_value = substr(vv_org_name,1,3)));
        --and dsl.param1_value=substr(vv_doc_category_code,1,4)
        --and dsl.return_value=vn_org_id;

        DKA_SAPWFCSP_PKG.print_wf_message(pv_itemtype, pv_itemkey, 'org_name : ' || substr(vv_org_name,4,4), 2);
        DKA_SAPWFCSP_PKG.print_wf_message(pv_itemtype, pv_itemkey,'vv_exclude_count : ' || vv_exclude_count, 2);
        DKA_SAPWFCSP_PKG.print_wf_message(pv_itemtype, pv_itemkey,'vv_source : ' || vv_source, 2);

        pv_resultout:='COMPLETE:'||'Y';

        IF vv_exclude_count = 0 Then --not in excluded leagal entitiy list
           IF vv_source='SCAN_XGS'
             OR vv_source='SCAN'
             OR ( vv_source='Manual Invoice Entry'  and (vv_attribute9 not in ('HAC','HAF') or vv_attribute9 is null))
             OR ( vv_source ='AMONTS' and  vv_attribute9 not in ('HAC','HAF')) THEN

             select count(1)
               into vv_image_count
               from fnd_attached_documents fad,
                    fnd_documents fd,
                    fnd_document_datatypes fdd,
                    fnd_documents_tl fdt
              where fad.entity_name='AP_INVOICES'
                and fad.document_id=fd.document_id
                and fd.category_id=1
                and fd.datatype_id=fdd.datatype_id
                and fdd.language='F'
                and fdd.user_name='Fichier'
                and fad.document_id=fdt.document_id
                and fd.document_id=fdt.document_id
                and fdt.language='F'
                and fdt.description='IMAGE FACTURE'
                and fad.pk1_value=to_char(vn_invoice_id);

             IF vv_image_count=0 THEN
         -- INC000000506832 - Vérifie que la facture n'est pas une notification.
         SELECT COUNT(1)
           INTO vn_verif_notif
           FROM AP_INVOICES_ALL AIA
        WHERE AIA.INVOICE_ID = vn_invoice_id
          AND AIA.PAY_GROUP_LOOKUP_CODE LIKE '%EMPLOYE%';

        IF vn_verif_notif = 0 THEN
                   pv_resultout:='COMPLETE:'||'N';
        END IF;
             END IF;
           END IF;
         END IF;
   COMMIT;

  EXCEPTION
     WHEN OTHERS THEN
           pv_resultout := wf_engine.eng_completed || ':' || 'FAIL';
  END Invoice_image_exists;

END DKA_SAPIAWIE_pkg; -- Spécification du package
/
SHOW ERROR PACKAGE BODY DKA_SAPIAWIE_pkg;
EXIT
