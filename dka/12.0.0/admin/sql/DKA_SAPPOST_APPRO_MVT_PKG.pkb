CREATE OR REPLACE PACKAGE BODY DKA_SAPPOST_APPRO_MVT_PKG
AS
--------------------------------------------------------------------------------
-- $Id: DKA_SAPPOST_APPRO_MVT_PKG.pkb 20 2008-01-28 16:12:56Z NORDEST\tbonduae $
-- Capgemini
-- Projet           : Puissance4
-- Nom              : DKA_SAPPOST_APPRO_MVT_PKG.pks
-- Description      : Spécification du package DKA_SAPPOST_APPRO_MVT_PKG
-- Auteur           : Thomas Bonduaeux
-- Date de création : 28/01/2008
-- Commentaires     : A exécuter sous SQLPLUS avec l'utilisateur APPS
--------------------------------------------------------------------------------
-- Historique
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------
-- 2016/07/05 JJA Portage Helios R12
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
--  Nom           : respond_sysadmin_notif
--  Description   : Répond automatiquement aux notifications
--                  DKA_MSG_SYSADMIN
--
--  Parametres    : pn_retcode    code de retour
--                  pv_errbuf     message d'erreur
--------------------------------------------------------------------------------
PROCEDURE respond_sysadmin_notif(pv_errbuf  OUT NOCOPY VARCHAR2,
                                 pn_retcode OUT NOCOPY NUMBER)
IS
  TYPE t_notification_ids IS TABLE OF wf_notifications.notification_id%TYPE;
  l_notification_ids t_notification_ids;

  TYPE t_awaited_results IS TABLE OF wf_lookups.lookup_code%TYPE;
  l_awaited_results t_awaited_results;

  e_no_notification EXCEPTION;
  e_error_in_action EXCEPTION;
BEGIN
  pn_retcode := 0;
  pv_errbuf  := '';

  SAVEPOINT startaction;

  -- recuperation des notifications
  SELECT wn.notification_id,
         (SELECT wl.lookup_code
          FROM wf_lookups wl
          WHERE wl.lookup_type = 'WFSTD_YES_NO'
          AND ROWNUM = 1)
  BULK COLLECT INTO l_notification_ids, l_awaited_results
  FROM wf_notifications wn,
       wf_message_attributes wma
  WHERE wn.message_type = 'DKA_CSP'
    AND wn.message_name = 'DKA_MSG_SYSADMIN'
    AND wn.status = 'OPEN'
    AND wn.recipient_role = 'SYSADMIN'
    AND wma.message_type = wn.message_type
    AND wma.message_name = wn.message_name
    AND wma.name = 'RESULT'
  ORDER BY notification_id;

  IF l_notification_ids.count = 0 THEN
    RAISE e_no_notification;
  ELSE
    -- pour chaque notification, repondre
    FOR i IN l_notification_ids.FIRST..l_notification_ids.LAST LOOP
      BEGIN
        wf_engine.preserved_context := TRUE;
        wf_notification.setattrtext(l_notification_ids(i),
                                    'RESULT',
                                    l_awaited_results(i));
        wf_notification.respond(nid       => l_notification_ids(i),
                                responder => fnd_global.user_name);
      EXCEPTION
        WHEN OTHERS THEN
          fnd_message.set_name('DKA', 'DKA_SAPPOST_APPRO_MVT_ERR');
          fnd_message.set_token('N_ID', l_notification_ids(i));
          fnd_message.set_token('ERROR', SQLERRM);
          pv_errbuf  := fnd_message.get;
          pn_retcode := 2;
          RAISE e_error_in_action;
      END;
    END LOOP;
  END IF;

EXCEPTION
  WHEN e_no_notification THEN
    ROLLBACK TO startaction;
    pn_retcode := 0;
    fnd_message.set_name('DKA', 'DKA_SAPPOST_APPRO_MVT_NDF');
    pv_errbuf := fnd_message.get;
  WHEN e_error_in_action THEN
    ROLLBACK TO startaction;
  WHEN OTHERS THEN
    ROLLBACK TO startaction;
    pn_retcode := 2;
    pv_errbuf  := SQLERRM;
END respond_sysadmin_notif;

END DKA_SAPPOST_APPRO_MVT_PKG;
/
SHOW ERROR PACKAGE BODY DKA_SAPPOST_APPRO_MVT_PKG
EXIT
