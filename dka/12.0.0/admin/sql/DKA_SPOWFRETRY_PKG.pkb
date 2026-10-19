SET VERIFY OFF;
DEFINE package_name = "DKA_SPOWFRETRY_PKG";

CREATE OR REPLACE PACKAGE BODY &&package_name
AS
----------------------------------------------------------------------------------------------
-- $Id$
-- CAPGEMINI
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SPOWFRETRY_PKG.pkb
-- DESCRIPTION       : DKA_SPOWFRETRY_PKG package body
--- AUTEUR           : Julien Jardez
--- DATE DE CREATION : 02/02/2012
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--- 14/02/2018 RBE artf2376258 : SPE175 - Correction de la sélection Employés
--------------------------------------------------------------------------------------------


  /* variables privées */

--------------------------------------------------------------------------------
  --  Nom           : main
  --  Description   : procédure
  --
  --  Paramètres    : pv_errbuf     message d'erreur
  --                  pn_retcode    code de retour
  --------------------------------------------------------------------------------
  PROCEDURE main(pv_errbuf       OUT VARCHAR2,
                 pn_retcode      OUT NUMBER
                 ) 
  IS


   vd_starttime      TIMESTAMP;
   lv_item_type      wf_item_activity_statuses.item_key%TYPE;
   lv_process_name   wf_process_activities.process_name%TYPE;
        
  
    CURSOR CUR_ERR_NOTI IS
       SELECT    pha.po_header_id,
                 pha.segment1,
                 pha.creation_date,
                 papf1.employee_number,
                 papf1.last_name,
                 papf1.first_name,
                 pha.wf_item_key,
                 wi.item_key,
                 wias_err.notification_id,
                 wias_err.begin_date,
                 wias_err.item_type,
                 wias_err.process_activity,
                 pa.process_name
         FROM    po_headers_all            pha,
                 fnd_user                  fu,
                 --per_all_people_f          papf1, --RBE artf2376258
                 per_people_v7             papf1,   --RBE artf2376258
                 wf_items                  wi,
                 wf_item_activity_statuses wias_err,
                 wf_process_activities     pa
           WHERE 1=1
             AND fu.user_id = pha.created_by
             AND papf1.person_id = fu.employee_id
             AND pha.authorization_status in ('IN PROCESS', 'PRE-APPROVED')
             AND EXISTS (SELECT 'x'
                           FROM wf_item_activity_statuses
                          WHERE activity_status = 'ERROR'
                            AND item_key = pha.wf_item_key
                            AND item_type = pha.wf_item_type)
             AND wi.parent_item_type = pha.wf_item_type
             AND wi.parent_item_key = pha.wf_item_key
             AND wias_err.item_type = wi.item_type
             AND wias_err.item_key = wi.item_key
             AND wias_err.activity_status = 'NOTIFIED'
             AND pa.instance_id=wias_err.process_activity
             --and wias_err.notification_id = 12457717 --TEST
             ;

     REC_CUR_ERR_NOTI  CUR_ERR_NOTI%ROWTYPE;


  BEGIN


    pn_retcode := 0;
    pv_errbuf  := NULL;

    vd_starttime := LOCALTIMESTAMP;
    --xxve_vp4_tools_pkg.putoutlog_line('  [' || TO_CHAR(LOCALTIMESTAMP - vd_starttime) || ']');
    Dka_Tools_Pkg.put_outdebug_message('  [' || TO_CHAR(LOCALTIMESTAMP - vd_starttime) || ']');
    
    FOR REC_CUR_ERR_NOTI  IN CUR_ERR_NOTI LOOP
      BEGIN
        pv_errbuf := 'Traitement notification : '|| chr(10)||
                     'ID   : '|| REC_CUR_ERR_NOTI.notification_id || chr(10) ||
                     'DEST : '|| REC_CUR_ERR_NOTI.first_name || ' '   || REC_CUR_ERR_NOTI.last_name|| chr(10) ||
                     'WKF  : '|| REC_CUR_ERR_NOTI.item_type  || ' : ' || REC_CUR_ERR_NOTI.item_key;
        --xxve_vp4_tools_pkg.putoutlog_line(pv_errbuf);    
        Dka_Tools_Pkg.put_outdebug_message(pv_errbuf);
        
        --On ferme la notification de l'administrateur                 
        wf_engine.handleerror( REC_CUR_ERR_NOTI.item_type,      
                               REC_CUR_ERR_NOTI.item_key,         
                               REC_CUR_ERR_NOTI.process_name,                          
                               'SKIP',
                               'RETRY' );

        --Commit!
        COMMIT;
        
        
        BEGIN
          --On rejoue l'activité en erreur
          SELECT wias.item_type,wpa.process_name
          INTO
           lv_item_type,
           lv_process_name
          FROM  
           wf_item_activity_statuses wias,
           wf_process_activities wpa
          WHERE
           wias.item_key = REC_CUR_ERR_NOTI.wf_item_key
           AND wpa.instance_id = wias.process_activity
           AND wias.activity_status = 'ERROR' ;
          
          pv_errbuf := 'Traitement activité : '|| lv_process_name || chr(10)||
                       'WKF  : '|| lv_item_type  || ' : ' || REC_CUR_ERR_NOTI.wf_item_key;
          --xxve_vp4_tools_pkg.putoutlog_line(pv_errbuf);
          Dka_Tools_Pkg.put_outdebug_message(pv_errbuf);                        
          
          WF_ENGINE.HandleError(itemtype => lv_item_type,
                                itemkey => REC_CUR_ERR_NOTI.wf_item_key,
                                activity => lv_process_name,
                                command => wf_engine.eng_retry,
                                result => pv_errbuf);
          
          --Commit!
          COMMIT;
        
        EXCEPTION
         WHEN OTHERS THEN
           pn_retcode := 1;
           pv_errbuf  := 'Erreur in retry activity : '||lv_item_type||' / '||REC_CUR_ERR_NOTI.wf_item_key||chr(10)||
                         SQLERRM;
           --xxve_vp4_tools_pkg.putoutlog_line(pv_errbuf);
           Dka_Tools_Pkg.put_outdebug_message(pv_errbuf);
           --xxve_vp4_tools_pkg.add_error_stack(pv_errbuf);  
           Dka_Tools_Pkg.add_error_stack(pv_errbuf);                                                  
        END;
        
        --Reinit
        pv_errbuf := '';
        
      EXCEPTION
       WHEN OTHERS THEN
         pn_retcode := 1;
         pv_errbuf  := 'Erreur in closing notification : '||REC_CUR_ERR_NOTI.item_type||' / '||REC_CUR_ERR_NOTI.item_key||chr(10)||
                       SQLERRM;
         --xxve_vp4_tools_pkg.putoutlog_line(pv_errbuf);
         Dka_Tools_Pkg.put_outdebug_message(pv_errbuf);
         --xxve_vp4_tools_pkg.add_error_stack(pv_errbuf); 
         Dka_Tools_Pkg.add_error_stack(pv_errbuf);                                               
      END;
    END LOOP ;
    
    --xxve_vp4_tools_pkg.putoutlog_line('  [' || TO_CHAR(LOCALTIMESTAMP - vd_starttime) || ']');
    Dka_Tools_Pkg.put_outdebug_message('  [' || TO_CHAR(LOCALTIMESTAMP - vd_starttime) || ']');
    
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      pn_retcode := 2;
      pv_errbuf  := 'Erreur inconnue : ' || SQLERRM;
      --xxve_vp4_tools_pkg.putlog_line('Erreur :');
      --xxve_vp4_tools_pkg.putlog_line('# SQLCODE : ' || SQLCODE);
      --xxve_vp4_tools_pkg.putlog_line('# SQLERRM : ' || SQLERRM);
      Dka_Tools_Pkg.put_log_message('Erreur :');
      Dka_Tools_Pkg.put_log_message('# SQLCODE : ' || SQLCODE);
      Dka_Tools_Pkg.put_log_message('# SQLERRM : ' || SQLERRM);
      --xxve_vp4_tools_pkg.print_error_stack();
      Dka_Tools_Pkg.print_error_stack();
  END main;


END &&package_name;
/
SHOW ERRORS;

EXIT;
