CREATE OR REPLACE PACKAGE BODY DKA_SAPINIT_HOLD_PKG
AS
--------------------------------------------------------------------------------
-- $Id: DKA_SAPINIT_HOLD_PKG.pkb 1769 2009-04-09 08:36:21Z CORP\viknab $
-- Capgemini
-- Projet           : Puissance4
-- Nom              : DKA_SAPINIT_HOLD_PKG.pkb
-- Description      : Corps du package DKA_SAPINIT_HOLD_PKG
-- Auteur           : Vincent Knab
-- Date de création : 29/12/2008
-- Commentaires     : a executer sous SQLPLUS avec l'utilisateur APPS
--------------------------------------------------------------------------------
-- Historique
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------
---2016/07/05 JJA Portage Helios R12
--------------------------------------------------------------------------------

  ----------------------------------------------------------------------------
  -- CONSTANTES ET VARIABLES PRIVEES
  ----------------------------------------------------------------------------
  cb_debug constant boolean := false;

PROCEDURE main(pv_errbuf   OUT VARCHAR2,
               pn_retcode  OUT NUMBER
               ) is

vd_starttime timestamp;

begin
  pn_retcode := 0;
  pv_errbuf  := NULL;
  Dka_Tools_Pkg.put_outdebug_message('Démarrage du traitement');
  
  vd_starttime := LOCALTIMESTAMP;
  begin
  
  --Purge de la table de travail
  Dka_Tools_Pkg.put_log_message('Purge de la table de DKA_SAPREINITBLOCAGE_TMP');
    
  EXECUTE IMMEDIATE 'TRUNCATE TABLE DKA.DKA_SAPREINITBLOCAGE_TMP';
  
  --requete Blocages avec notifications férmées
  INSERT INTO DKA_SAPREINITBLOCAGE_TMP
       select DISTINCT dsl.param1_value DIVISION,
            ai.org_id,
            substr(haou.name,4,4) SOCIETE,
            dsl.param2_value REGION,
            dsl.return_value CSP,
            ah.rowid,
            ai.invoice_id,
            ai.invoice_num,
            ah.hold_lookup_code INVOICE_HOLD,
            ah.attribute1 ||' - '||ah.attribute2 WF_INIT_INDICATOR,
            wnClos.notification_id NOTIF_ID,
            substr(ah.attribute3,1,INSTR(ah.attribute3,'_')-1) NOTIF_CLOSED,
            wnClos.subject NOTIF_SUBJECT,
            wnClos.status NOTIF_STATUS,
            wnClos.responder NOTIF_RESPONDER,
            wnClos.to_user NOTIF_USER,
            wnClos.end_date NOTIF_CLOSE_DATE,
            fnd_global.user_id  CREATED_BY,
            sysdate  CREATION_DATE,
            null,
            null,
            null,
            fnd_global.conc_request_id
      from ap_holds_all ah,
           ap_invoices_all ai,
           HR_all_ORGANIZATION_UNITS haou,
           dka_stransco_headers dsh,
           dka_stransco_lines dsl,
           (SELECT  wn.notification_id, wn.to_user,wn.status, wn.subject, wn.responder, wn.end_date,  SUBSTR(wn.context, 1, INSTR(wn.context, ':')-1) item_type,
                          SUBSTR(wn.context, INSTR(wn.context, ':')+1, INSTR(wn.context, ':',1, 2)-INSTR(wn.context, ':')-1) item_key,
                          message_name
            FROM wf_notifications wn
            WHERE wn.status = 'CLOSED'
            AND wn.message_type = 'DKA_CSP'
            ) wnClos,
           dka_stransco_headers dshBloc,
           dka_stransco_lines   dslBloc,
           dka_stransco_headers dshMetier,
           dka_stransco_lines   dslMetier
      where ah.attribute1 = 'DKA_CSP'
      and ah.attribute2 is not null
      and ah.attribute3 is not null
      and ah.invoice_id = ai.invoice_id
      and ah.release_lookup_code  is null
      and haou.organization_id = ai.org_id
      and dsh.set_name = 'CENTRE_SERVICE_PARTAGE'
      and dsl.set_id = dsh.set_id
      and dsl.param1_value = haou.attribute10
      and dsl.enable = 'Y'
      and sysdate between dsl.start_date and nvl(dsl.end_date, sysdate)
      and ah.attribute2 =wnClos.item_key
      and substr(ah.attribute3,1,INSTR(ah.attribute3,'_')-1) = wnClos.notification_id
      -- relier le message au type de blocage
      and wnClos.message_name =  dslMetier.param1_value
      and dslBloc.param1_value  = ah.hold_lookup_code
      and dshBloc.set_id = dslBloc.set_id
      AND dshBloc.set_name = 'DKA_BLOCAGES_NOTIFS'
      and dshMetier.set_id = dslMetier.set_id
      AND dshMetier.set_name = 'DKA_NOTIF_METIER'
      and dslBloc.return_value = dslMetier.param2_value
      and dslBloc.enable = 'Y'
      and sysdate between dslBloc.start_date and nvl(dslBloc.end_date, sysdate)
      and dslMetier.enable = 'Y'
      and sysdate between dslMetier.start_date and nvl(dslMetier.end_date, sysdate)
      and((
          ah.hold_lookup_code = 'QTY REC'
          and not exists (select 1 from wf_notifications wn
                          WHERE wn.status = 'OPEN'
                            AND wn.message_type = 'DKA_CSP'
                            AND MESSAGE_NAME in ('DKA_MSG2_ANO_QTY_REC',
                                                 'DKA_MSG_FWD_ANO_QTY_REC',
                                                 'DKA_MSG_ANO_QTY_REC',
                                                 'DKA_MSG2_ANO_QTY_REC2',
                                                 'DKA_MSG_FWD_ANO_QTY_REC2')
                            and SUBSTR(wn.context, 1, INSTR(wn.context, ':')-1) ='DKA_CSP'
                            and SUBSTR(wn.context, INSTR(wn.context, ':')+1, INSTR(wn.context, ':',1, 2)-INSTR(wn.context, ':')-1) = ah.attribute2
                          )
          )
        OR
          (
          ah.hold_lookup_code = 'QTY ORD'
          and not exists (select 1 from wf_notifications wn
                          WHERE wn.status = 'OPEN'
                            AND wn.message_type = 'DKA_CSP'
                            AND MESSAGE_NAME in ('DKA_MSG_ANO_QTY_ORD',
                                                 'DKA_MSG2_ANO_QTY_ORD',
                                                 'DKA_MSG_HIERAR_ANO_QTY_ORD',
                                                 'DKA_MSG2_ANO_QTY_ORD2',
                                                 'DKA_MSG_HIERAR_ANO_QTY_ORD2')
                            and SUBSTR(wn.context, 1, INSTR(wn.context, ':')-1) ='DKA_CSP'
                            and SUBSTR(wn.context, INSTR(wn.context, ':')+1, INSTR(wn.context, ':',1, 2)-INSTR(wn.context, ':')-1) = ah.attribute2
                          )
          ))
       AND not exists  (select 1 from ap_holds_all ahlitige
                               --suite a simplification axe metier
                        WHERE  (   ahlitige.hold_lookup_code = 'En litige Quantité'
                                OR ahlitige.hold_lookup_code = 'En litige Quantité CDE'
                                OR ahlitige.hold_lookup_code = 'En litige Quantité REC')
                        and  ahlitige.release_lookup_code  is null
                        and ahlitige.invoice_id = ah.invoice_id
                        )    ;

      --requete Blocage sans notification
      INSERT INTO DKA_SAPREINITBLOCAGE_TMP
         select DISTINCT dsl.param1_value DIVISION,
              ai.org_id,
              substr(haou.name,4,4) SOCIETE,
              dsl.param2_value REGION,
              dsl.return_value CSP,
              ah.rowid,
              ai.invoice_id,
              ai.invoice_num,
              ah.hold_lookup_code INVOICE_HOLD,
              ah.attribute1 ||' - '||ah.attribute2 WF_INIT_INDICATOR,
              null as NOTIF_ID,
              substr(ah.attribute3,1,INSTR(ah.attribute3,'_')-1) NOTIF_CLOSED,
              null as NOTIF_SUBJECT,
              null as NOTIF_STATUS,
              null as NOTIF_RESPONDER,
              null as NOTIF_USER,
              null as NOTIF_CLOSE_DATE,
              fnd_global.user_id  CREATED_BY,
              sysdate  CREATION_DATE,
              null,
              null,
              null,
              fnd_global.conc_request_id
        from ap_holds_all ah,
             ap_invoices_all ai,
             HR_all_ORGANIZATION_UNITS haou,
             dka_stransco_headers dsh,
             dka_stransco_lines dsl
        where ah.attribute1 = 'DKA_CSP'
        and ah.attribute2 is not null
        and ah.attribute3 is not null
        and ah.invoice_id = ai.invoice_id
        and ah.release_lookup_code  is null
        and haou.organization_id = ai.org_id
        and dsh.set_name = 'CENTRE_SERVICE_PARTAGE'
        and dsl.set_id = dsh.set_id
        and dsl.param1_value = haou.attribute10
        and dsl.enable = 'Y'
        and sysdate between dsl.start_date and nvl(dsl.end_date, sysdate)
        and (ah.hold_lookup_code = 'QTY REC' OR ah.hold_lookup_code = 'QTY ORD')
        and not exists (SELECT 1
                         FROM   wf_notifications wn
                         WHERE wn.message_type = 'DKA_CSP'
                         AND  SUBSTR(wn.context, INSTR(wn.context, ':')+1, INSTR(wn.context, ':',1, 2)-INSTR(wn.context, ':')-1) = ah.attribute2
                         )
        AND not exists  (SELECT 1
                          FROM   ap_holds_all ahlitige
                                 --suite a simplification axe metier
                          WHERE  (   ahlitige.hold_lookup_code = 'En litige Quantité'
                                  OR ahlitige.hold_lookup_code = 'En litige Quantité CDE'
                                  OR ahlitige.hold_lookup_code = 'En litige Quantité REC')
                          AND  ahlitige.release_lookup_code  is null
                          AND ahlitige.invoice_id = ah.invoice_id
                          )    ;


      Dka_Tools_Pkg.put_outdebug_message('Reinit des blocages ');
       update ap_holds_all set attribute1 = null, attribute2=null, attribute3 = null
               ,LAST_UPDATE_DATE = sysdate
               ,LAST_UPDATED_BY = nvl(to_number(fnd_profile.value('USER_ID')),-1)
               ,LAST_UPDATE_LOGIN = nvl(to_number(fnd_profile.value('LOGIN_ID')),-1)
       where rowid in (
         select HOLD_ID from DKA_SAPREINITBLOCAGE_TMP
         where request_id = fnd_global.conc_request_id
       );

      Dka_Tools_Pkg.put_outdebug_message(' blocages réinitialisés : '|| SQL%ROWCOUNT);

      Dka_Tools_Pkg.put_outdebug_message('  [' ||
                                        TO_CHAR(LOCALTIMESTAMP - vd_starttime) || ']');

      Dka_Tools_Pkg.put_outdebug_message('Reinit des factures ');
      update ap_invoices_all set wfapproval_status =  'REQUIRED'
             ,LAST_UPDATE_DATE = sysdate
             ,LAST_UPDATED_BY = nvl(to_number(fnd_profile.value('USER_ID')),-1)
             ,LAST_UPDATE_LOGIN = nvl(to_number(fnd_profile.value('LOGIN_ID')),-1)
      where INVOICE_ID in (
         select invoice_ID from DKA_SAPREINITBLOCAGE_TMP
         where request_id = fnd_global.conc_request_id
       )
      and wfapproval_status = 'WFAPPROVED';

      Dka_Tools_Pkg.put_outdebug_message(' factures réinitialisées : '|| SQL%ROWCOUNT);

      Dka_Tools_Pkg.put_outdebug_message('  [' ||
                                        TO_CHAR(LOCALTIMESTAMP - vd_starttime) || ']');

      Dka_Tools_Pkg.put_outdebug_message('Reinit des attribute3 global');
      update ap_holds_all set attribute3 = null
                             ,LAST_UPDATE_DATE = sysdate
                             ,LAST_UPDATED_BY = nvl(to_number(fnd_profile.value('USER_ID')),-1)
                             ,LAST_UPDATE_LOGIN = nvl(to_number(fnd_profile.value('LOGIN_ID')),-1)
       where attribute3 is not null;

      Dka_Tools_Pkg.put_outdebug_message(' attribute3 réinitialisés : '|| SQL%ROWCOUNT);

      Dka_Tools_Pkg.put_outdebug_message('  [' ||
                                        TO_CHAR(LOCALTIMESTAMP - vd_starttime) || ']');
      commit;
  EXCEPTION
      when others then
        pv_errbuf := 'traitement : EXCEPTION ' || substr(SQLERRM, 1, 500);
        Dka_Tools_Pkg.put_outdebug_message(pv_errbuf);
        pn_retcode := 2;
  END;
end;

end DKA_SAPINIT_HOLD_PKG;
/
show errors package body DKA_SAPINIT_HOLD_PKG;

EXIT
