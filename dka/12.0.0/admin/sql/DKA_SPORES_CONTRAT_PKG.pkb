CREATE OR REPLACE PACKAGE BODY DKA_SPORES_CONTRAT_PKG AS

  ----------------------------------------------------------------------------
  -- $Id: DKA_SPORES_CONTRAT_PKG.pkb 408 2007-10-23 09:13:51Z NORDEST\jjardez $
  -- CAP GEMINI
  -- PROJET            : DALKIA Oracle Applications
  -- NOM               : DKA_SPORES_CONTRAT_PKG.pks
  -- DESCRIPTION       : DKA_SPORES_CONTRAT_PKG package specifications
  ---
  --- AUTEUR           : J. JARDEZ
  --- DATE DE CREATION : 10/09/2006
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE       : A executer sous SQLPLUS avec le user APPS
  ----------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- ---------- --- ---------------------------------------------------------
  --- 12/10/2007 JJA Controle si la version en archive existe deja
  --- 23/10/2007 JJA Récupération de l'adresse au niveau de
  ---                l'employé plutot que l'utilisateur
  --- 28/05/2009 CDE EID20090143 : Evolution 2 - lot 1
  --- 08/12/2009 CDE EARS00008924370 : Restriction des sélections aux contrats
  ---                ouverts
  --- 11/02/2010 CDE EID20090220 : Evolution 3 -lot 1
  --- 01/06/2010 CDE EID20100093 : Suppression <> sur connexion pour lancement VP
  --- 05/05/2011 CDE EARS00009526504 : Pb nbre de renouvellement à vide
  --- 30/09/2011 CDE EARS00009681449 : Pb date d'envoi des messages
  --- 10/01/2013 BCO INC000000363006 : Ajout de la fermeture d'un contrat dont le
  ---                  nombre de reconduction a atteint ca limite.
  --- 17/03/2017 YWA artf2120401
  --- 04/07/2017 RBE artf2154499
  --- 25/08/2017 NBO artf2212485 - SPE119 - Traitement de résiliation et renouvellement - cloisonnement par UO
  --- 15/02/2018 RBE artf2376255 : SPE119 - Correction de la sélection Employés
  --- 04/09/2018 RBE artf3025989 : INC0243936 - SPE119 - Problème recherche gestionnaire contrat SSTR
  ----------------------------------------------------------------------------

  ----------------------------------------------------------------------------
  -- CONSTANTES ET VARIABLES PRIVEES
  ----------------------------------------------------------------------------
  gn_nbre_reconduction NUMBER(15);
  gv_conn              VARCHAR2(30);
  gv_expediteur        VARCHAR2(50);
  gv_subject           VARCHAR2(4000);
  gv_body              VARCHAR2(4000);
  gn_traite            PLS_INTEGER;
  gn_erreur            PLS_INTEGER;
  gv_subject_avert     VARCHAR2(4000);
  gv_body_avert        VARCHAR2(4000);

  -- 10/01/2013 BCO INC000000363006 - ajout variable d'envoi par mail de fermeture définitive.
  gv_subject_fin        VARCHAR2(4000);
  gv_body_fin           VARCHAR2(4000);
  gv_subject_avert_fin  VARCHAR2(4000);
  gv_subject_avert_nfin VARCHAR2(4000);
  gv_body_avert_fin     VARCHAR2(4000);
  gv_body_avert_nfin    VARCHAR2(4000);

  gn_traite_avert PLS_INTEGER;
  gn_erreur_avert PLS_INTEGER;
  gv_mail_test          VARCHAR2(240) := NULL;--YWA artf2120401 

  ----------------------------------------------------------------------------
  --  Nom           : LOG_MSG
  --  Description   : procedure d'affichage des messages
  --
  --  PARAMETRES :
  --   pv_message      texte a imprimer dans le log
  --
  ----------------------------------------------------------------------------
  PROCEDURE log_msg(pv_message in varchar2) IS
    l_message VARCHAR2(1000);
  BEGIN
  
    l_message := SUBSTR(pv_message, 1, 1000);
  
    IF (l_message IS NULL) THEN
      l_message := TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS');
    END IF;
  
    fnd_file.put_line(fnd_file.LOG, l_message);
    --dbms_output.put_line('LOG : '||substr(l_message,1,253));
  END log_msg;

  ----------------------------------------------------------------------------
  --  Nom           : OUT_MSG
  --  Description   : procedure d'affichage des messages
  --
  --  PARAMETRES :
  --   pv_message          texte a imprimer dans la sortie
  --
  ----------------------------------------------------------------------------
  PROCEDURE out_msg(pv_message in varchar2) IS
  BEGIN
    -- Ecriture dans le fichier de sortie
    fnd_file.put_line(fnd_file.output, pv_message);
  END out_msg;

  ----------------------------------------------------------------------------
  --  Nom           : GET_TIME
  --  Description   : fonction qui retourne la date et l'heure
  --                  actuelle
  --
  --  PARAMETRES :
  --
  ----------------------------------------------------------------------------
  FUNCTION get_time RETURN VARCHAR2 IS
  BEGIN
    RETURN to_char(sysdate, 'DD/MM/YYYY HH24:MI:SS');
  END get_time;

  ----------------------------------------------------------------------------
  --  Nom           : INIT
  --  Description   : Procedure d'initialisation
  --
  --PARAMETRES :
  --  pv_errbuf   Entree/Sortie          message d'erreur
  --  VALEUR RETOURNEE :  pn_retcode
  --Valeurs possibles : 0=normal, 1=warning, 2=erreur
  ----------------------------------------------------------------------------
  PROCEDURE init(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER) IS
    l_param   VARCHAR2(100);
    rec_param dka_parameters%ROWTYPE;
    e_err_param EXCEPTION;
  BEGIN
    gn_traite       := 0;
    gn_erreur       := 0;
    gn_traite_avert := 0;
    gn_erreur_avert := 0;
  
    --Recuperation du nombre de reconduction max
    l_param := 'NB_RECONDUCTION_MAX';
    Dka_Tools_Pkg.get_parameter('SPORES_CONTRAT',
                                'NB_RECONDUCTION_MAX',
                                rec_param,
                                pv_errbuf,
                                pn_retcode);
    gn_nbre_reconduction := rec_param.number_value;
  
    log_msg('Nombre de reconduction maximum : ' || gn_nbre_reconduction);
  
    IF pn_retcode != 0 THEN
      RAISE e_err_param;
    END IF;
  
    --Recuperation des parametres de connexion
    l_param := 'SMTP_CONNECTION';
    Dka_Tools_Pkg.get_parameter ('SPORES_CONTRAT', 'SMTP_CONNECTION', rec_param, pv_errbuf, pn_retcode);
    gv_conn := rec_param.varchar2_value;
    --gv_conn := 'kriek.nord-est.capgemini.fr';
    log_msg('Connexion SMTP : ' || gv_conn);
  
    IF pn_retcode != 0 THEN
      RAISE e_err_param;
    END IF;
  
    --Recuperation du nombre de reconduction max
    l_param := 'EXPEDITEUR_MAIL';
    Dka_Tools_Pkg.get_parameter('SPORES_CONTRAT',
                                'EXPEDITEUR_MAIL',
                                rec_param,
                                pv_errbuf,
                                pn_retcode);
    gv_expediteur := rec_param.varchar2_value;
  
    log_msg('Expediteur mail : ' || gv_expediteur);
  
    IF pn_retcode != 0 THEN
      RAISE e_err_param;
    END IF;
  
  EXCEPTION
    WHEN e_err_param THEN
      pv_errbuf  := 'Erreur parametre ' || l_param || ' : ' || SQLERRM;
      pn_retcode := 2;
      log_msg(pv_errbuf);
    WHEN OTHERS THEN
      pv_errbuf  := 'Erreur procedure INIT ' || SQLERRM;
      pn_retcode := 2;
      log_msg(pv_errbuf);
  END init;

  ----------------------------------------------------------------------------
  --  Nom           : MAJ_PO
  --  Description   : procedure de mise à jour des donnees de po_headers_all
  --
  --PARAMETRES :
  --  pn_header_id IN       identifiant du contrat
  --  pv_errbuf    IN OUT   message de sortie
  --  pn_retcode   OUT      code retour
  --  VALEUR RETOURNEE :  pn_retcode
  --Valeurs possibles : 0=normal, 1=warning, 2=erreur
  ----------------------------------------------------------------------------
  PROCEDURE maj_po(pn_header_id IN PO_HEADERS_ALL.po_header_id%TYPE,
                   pv_errbuf    IN OUT VARCHAR2,
                   pn_retcode   OUT NUMBER) IS
  BEGIN
  
    UPDATE PO_HEADERS_ALL ph
       SET ph.last_update_date     = SYSDATE,
           ph.last_updated_by      = FND_GLOBAL.USER_ID,
           ph.last_update_login    = FND_GLOBAL.LOGIN_ID,
           ph.revision_num         = nvl(ph.revision_num, 0) + 1,
           ph.authorization_status = 'REQUIRES REAPPROVAL',
           ph.approved_flag        = 'R',
           ph.approved_date        = NULL,
           ph.start_date           = ph.end_date + 1,
           ph.end_date             = add_months(ph.end_date, 12)
     WHERE po_header_id = pn_header_id;
  
    -- Repositionnement du flag "mail avertissement envoyé" à NULL
    -- et des champs liés à la fonction de modification
    UPDATE DKA_CONTRAT_SSTR dcs
       SET dcs.last_update_date        = SYSDATE,
           dcs.last_updated_by         = FND_GLOBAL.USER_ID,
           dcs.flag_mail_avertissement = NULL,
           dcs.revision_num            = nvl(dcs.revision_num, 0) + 1,
           dcs.reconduction_num        = nvl(dcs.reconduction_num, 0) + 1,
           dcs.date_effet              = NULL,
           dcs.commande_id             = NULL,
           dcs.commande_version        = NULL
     WHERE po_header_id = pn_header_id;
  
    -- Incrémentation du numéro de révision
    UPDATE DKA_CONTRAT_SSTR_IMPUTATION dcsi
       SET dcsi.last_update_date = SYSDATE,
           dcsi.last_updated_by  = FND_GLOBAL.USER_ID,
           dcsi.revision_num     = nvl(dcsi.revision_num, 0) + 1
     WHERE po_header_id = pn_header_id;
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'Erreur procedure MAJ_PO ' || SQLERRM;
      pn_retcode := 2;
      log_msg(pv_errbuf);
  END maj_po;

  ----------------------------------------------------------------------------
  --  Nom           : MAJ_PO_FIN
  --  Description   : 10/01/2013 BCO INC000000363006 - procedure de mise à jour des donnees de po_headers_all
  --
  --PARAMETRES :
  --  pn_header_id IN       identifiant du contrat
  --  pv_errbuf    IN OUT   message de sortie
  --  pn_retcode   OUT      code retour
  --  VALEUR RETOURNEE :  pn_retcode
  --Valeurs possibles : 0=normal, 1=warning, 2=erreur
  ----------------------------------------------------------------------------
  PROCEDURE maj_po_fin(pn_header_id IN PO_HEADERS_ALL.po_header_id%TYPE,
                       pv_errbuf    IN OUT VARCHAR2,
                       pn_retcode   OUT NUMBER) IS
  BEGIN
  
    UPDATE PO_HEADERS_ALL ph
       SET ph.last_update_date  = SYSDATE,
           ph.last_updated_by   = FND_GLOBAL.USER_ID,
           ph.last_update_login = FND_GLOBAL.LOGIN_ID,
           ph.closed_code       = 'FINALLY CLOSED',
           ph.closed_date       = SYSDATE,
           ph.comments          = 'Fermeture définitive du contrat suite au lancement du traitement automatique de résiliation des contrats récurrents de sous-traitance'
     WHERE po_header_id = pn_header_id;
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'Erreur procedure MAJ_PO_FIN ' || SQLERRM;
      pn_retcode := 2;
      log_msg(pv_errbuf);
  END maj_po_fin;

  ----------------------------------------------------------------------------
  --  Nom           : MAJ_FLAG_AVERT
  --  Description   : procedure de mise à jour du flag d'avertissement
  --
  --PARAMETRES :
  --  pn_header_id IN       identifiant du contrat
  --  pv_errbuf    IN OUT   message de sortie
  --  pn_retcode   OUT      code retour
  --  VALEUR RETOURNEE :  pn_retcode
  --Valeurs possibles : 0=normal, 1=warning, 2=erreur
  ----------------------------------------------------------------------------
  PROCEDURE maj_flag_avert(pn_header_id IN PO_HEADERS_ALL.po_header_id%TYPE,
                           pv_errbuf    IN OUT VARCHAR2,
                           pn_retcode   OUT NUMBER) IS
  BEGIN
  
    UPDATE DKA_CONTRAT_SSTR dcs
       SET dcs.flag_mail_avertissement = 'Y'
     WHERE po_header_id = pn_header_id;
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'Erreur procedure MAJ_FLAG_AVERT ' || SQLERRM;
      pn_retcode := 2;
      log_msg(pv_errbuf);
  END maj_flag_avert;

  -------------------------------------------------------------------------------------
  --  Nom           : GET_MESSAGE
  --  Description   : procedure de recuperation des messages
  --
  --  PARAMETRES    :
  --  pn_header_id IN       identifiant du contrat
  --  pv_errbuf    IN OUT   message de sortie
  --  pn_retcode   OUT      code retour
  --  VALEUR RETOURNEE :  pn_retcode
  --Valeurs possibles : 0=normal, 1=warning, 2=erreur
  ------------------------------------------------------------------------------------
  PROCEDURE get_message(pn_header_id IN PO_HEADERS_ALL.po_header_id%TYPE,
                        pv_errbuf    OUT VARCHAR2,
                        pn_retcode   OUT NUMBER) IS
  
    l_fournisseur      po_vendors.Vendor_Name%TYPE;
    l_date_fin         VARCHAR2(10);
    l_no_contrat       po_headers_all.segment1%TYPE;
    l_date_periode_res VARCHAR2(10);
  
  BEGIN
  
    SELECT ph.segment1,
           to_char(ph.End_Date, 'dd/mm/yyyy'),
           pv.vendor_name,
           to_char(add_months(ph.End_Date, - (dcs.preavis_resiliation)),
                   'DD/MM/YYYY')
      INTO l_no_contrat, l_date_fin, l_fournisseur, l_date_periode_res
      FROM po_headers_all ph, po_vendors pv, dka_contrat_sstr dcs
     WHERE ph.po_header_id = pn_header_id
       AND ph.vendor_id = pv.vendor_id
       AND dcs.po_header_id = ph.po_header_id;
  
    --GET MESSAGE
    gv_subject := Dka_Tools_Pkg.get_message('DKA',
                                            'DKA_SPORES_CONTRAT_MAIL_SUJET');
  
    gv_body := Dka_Tools_Pkg.get_message('DKA',
                                         'DKA_SPORES_CONTRAT_MAIL_CORPS',
                                         'NO_CONTRAT',
                                         l_no_contrat,
                                         'NOM_FOURNISSEUR',
                                         l_fournisseur,
                                         'DATE_FIN',
                                         l_date_fin);
  
    gv_subject_avert := Dka_Tools_Pkg.get_message('DKA',
                                                  'DKA_SPORES_MAIL_AVERT_SUJET');
  
    gv_body_avert := Dka_Tools_Pkg.get_message('DKA',
                                               'DKA_SPORES_MAIL_AVERT_CORPS',
                                               'NO_CONTRAT',
                                               l_no_contrat,
                                               'NOM_FOURNISSEUR',
                                               l_fournisseur,
                                               'DATE_PERIODE_RES',
                                               l_date_periode_res);
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'Erreur procedure GET_MESSAGE ' || SQLERRM;
      pn_retcode := 2;
      log_msg(pv_errbuf);
  END get_message;

  -------------------------------------------------------------------------------------
  --  Nom           : GET_MESSAGE_FIN
  --  Description   : 10/01/2013 BCO INC000000363006 - procedure de recuperation des messages
  --          lorsqu'un contrat a atteint son nombre de reconduction
  --
  --  PARAMETRES    :
  --  pn_header_id IN       identifiant du contrat
  --  pv_errbuf    IN OUT   message de sortie
  --  pn_retcode   OUT      code retour
  --  VALEUR RETOURNEE :  pn_retcode
  --Valeurs possibles : 0=normal, 1=warning, 2=erreur
  ------------------------------------------------------------------------------------
  PROCEDURE get_message_fin(pn_header_id IN PO_HEADERS_ALL.po_header_id%TYPE,
                            pv_errbuf    OUT VARCHAR2,
                            pn_retcode   OUT NUMBER) IS
  
    l_fournisseur      po_vendors.Vendor_Name%TYPE;
    l_date_fin         VARCHAR2(10);
    l_no_contrat       po_headers_all.segment1%TYPE;
    l_date_periode_res VARCHAR2(10);
  
  BEGIN
  
    SELECT ph.segment1,
           to_char(ph.End_Date, 'dd/mm/yyyy'),
           pv.vendor_name,
           to_char(add_months(ph.End_Date, - (dcs.preavis_resiliation)),
                   'DD/MM/YYYY')
      INTO l_no_contrat, l_date_fin, l_fournisseur, l_date_periode_res
      FROM po_headers_all ph, po_vendors pv, dka_contrat_sstr dcs
     WHERE ph.po_header_id = pn_header_id
       AND ph.vendor_id = pv.vendor_id
       AND dcs.po_header_id = ph.po_header_id;
  
    -- Message de fermeture définitive des contrats ayant atteint le maximum des renouvellements possibles. --
    gv_subject_fin := Dka_Tools_Pkg.get_message('DKA',
                                                'DKA_SPORES_CONTRAT_MAIL_SNRENO');
  
    gv_body_fin := Dka_Tools_Pkg.get_message('DKA',
                                             'DKA_SPORES_CONTRAT_MAIL_CNRENO',
                                             'NO_CONTRAT',
                                             l_no_contrat,
                                             'NOM_FOURNISSEUR',
                                             l_fournisseur,
                                             'DATE_FIN',
                                             l_date_fin);
  
    -- Message d'avertissement concernant les contrats ayant atteint le maximum des renouvellements possibles. --
    gv_subject_avert_fin := Dka_Tools_Pkg.get_message('DKA',
                                                      'DKA_SPORES_CONTRAT_MAX_SRENO');
  
    gv_body_avert_fin := Dka_Tools_Pkg.get_message('DKA',
                                                   'DKA_SPORES_CONTRAT_MAX_CRENO',
                                                   'NO_CONTRAT',
                                                   l_no_contrat,
                                                   'NOM_FOURNISSEUR',
                                                   l_fournisseur);
  
    -- Message d'avertissement consernant les contrats n'ayant pas atteint le maximum des renouvellements possibles. --
    gv_subject_avert_nfin := Dka_Tools_Pkg.get_message('DKA',
                                                       'DKA_SPORES_CONTRAT_MAX_SNRENO');
  
    gv_body_avert_nfin := Dka_Tools_Pkg.get_message('DKA',
                                                    'DKA_SPORES_CONTRAT_MAX_CNRENO',
                                                    'NO_CONTRAT',
                                                    l_no_contrat,
                                                    'NOM_FOURNISSEUR',
                                                    l_fournisseur,
                                                    'DATE_FIN',
                                                    l_date_fin);
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'Erreur procedure GET_MESSAGE ' || SQLERRM;
      pn_retcode := 2;
      log_msg(pv_errbuf);
  END get_message_fin;

  -------------------------------------------------------------------------------------
  --  Nom           : ENVOI_MAIL
  --  Description   : procedure d'envoi de mail
  --
  --  PARAMETRES    :
  --  pv_signataire IN       signataire du contrat (destinataire du mail)
  --  pv_subject    IN       Sujet du courriel
  --  pv_body       IN       Corps du courriel
  --  pv_errbuf     IN OUT   message de sortie
  --  pn_retcode    OUT      code retour
  --  VALEUR RETOURNEE :  pn_retcode
  --Valeurs possibles : 0=normal, 1=warning, 2=erreur
  ------------------------------------------------------------------------------------

  PROCEDURE envoi_mail(pv_signataire IN DKA_CONTRAT_SSTR.Signataire_Contrat%TYPE,
                       pv_subject    IN VARCHAR2,
                       pv_body       IN VARCHAR2,
                       pv_errbuf     OUT VARCHAR2,
                       pn_retcode    OUT NUMBER) IS
  
    l_user_name fnd_user.user_name%TYPE;
    l_email     fnd_user.email_address%TYPE;
  
    l_mesg VARCHAR2(4000);
    l_conn UTL_SMTP.CONNECTION;
  
  BEGIN
  
    --Recuperation du mail et du login
    SELECT ppf.FULL_NAME, trim(' ' FROM nvl(ppf.EMAIL_ADDRESS,fu.email_address))
    INTO l_user_name, l_email
    FROM
     fnd_user fu,
     --per_people_f ppf -- RBE artf2376255
     per_people_f ppf  -- RBE artf2376255 --artf3025989
    WHERE
     fu.employee_id = pv_signataire
     AND fu.employee_id = ppf.person_id
     AND TRUNC(SYSDATE) BETWEEN TRUNC(ppf.effective_start_date) AND NVL(ppf.effective_end_date,SYSDATE) --RBE artf3025989
     AND rownum = 1;
     
    -- Création et envoi du mail au créateur
    l_conn := utl_smtp.open_connection(gv_conn, 25);
  
    utl_smtp.helo(l_conn, gv_conn);
    utl_smtp.mail(l_conn, gv_expediteur);
    utl_smtp.rcpt(l_conn, '<' || nvl(gv_mail_test,l_email) || '>');-- YWA artf2120401
    utl_smtp.open_data(l_conn);
    -- l_mesg:= 'Date: ' || TO_CHAR( SYSDATE, 'dd Mon yy hh24:mi:ss' ) || utl_tcp.CRLF ||
    l_mesg := 'Date: ' ||
              to_char(systimestamp, 'dd Mon yy hh24:mi:ss tzhtzm') ||
              utl_tcp.CRLF || 'From: ' || gv_expediteur || utl_tcp.CRLF ||
              'To: ' || l_user_name || ' <' || l_email || '>' ||
              utl_tcp.CRLF || 'Subject:' || pv_subject || utl_tcp.CRLF ||
              'Content-Type: text/plain;    ' || utl_tcp.CRLF ||
              ' charset="iso-8859-1"' || utl_tcp.CRLF || utl_tcp.CRLF ||
              pv_body || utl_tcp.CRLF;
    utl_smtp.write_data(l_conn, l_mesg);
    utl_smtp.close_data(l_conn);
    utl_smtp.quit(l_conn);
  
    log_msg('Mail envoye a : ' || l_user_name || ' <' || l_email || '>');
  
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      pv_errbuf  := 'Aucune adresse mail trouvee pour le singnataire : ' ||
                    pv_signataire;
      pn_retcode := 2;
      log_msg(pv_errbuf);
    WHEN OTHERS THEN
      pv_errbuf  := 'Erreur procedure ENVOI_MAIL ' || SQLERRM;
      pn_retcode := 2;
      log_msg(pv_errbuf);
  END envoi_mail;

  -------------------------------------------------------------------------------------
  --  Nom           : ENVOI_NOTIF
  --  Description   : procedure d'envoi de notification via workflow
  --
  --  PARAMETRES    :
  --  pn_header_id  IN       identifiant du contrat
  --  pv_signataire IN       signataire du contrat (destinataire du mail)
  --  pv_errbuf     IN OUT   message de sortie
  --  pn_retcode    OUT      code retour
  --  VALEUR RETOURNEE :  pn_retcode
  --Valeurs possibles : 0=normal, 1=warning, 2=erreur
  ------------------------------------------------------------------------------------

  PROCEDURE envoi_notif(pn_header_id  IN PO_HEADERS_ALL.po_header_id%TYPE,
                        pv_signataire IN DKA_CONTRAT_SSTR.Signataire_Contrat%TYPE,
                        pv_errbuf     OUT VARCHAR2,
                        pn_retcode    OUT NUMBER) IS
  
    l_wf_itemtype wf_items.item_type%TYPE;
    l_wf_process  wf_items.root_activity%TYPE;
    l_wf_itemkey  wf_items.item_key%TYPE;
  
    l_user_name fnd_user.user_name%TYPE;
  
  BEGIN
  
    -- Initialisation
    l_wf_itemtype := 'DKASDNOT';
    l_wf_process  := 'DKA_SEND_NOTIF_PROCESS';
    SELECT TO_CHAR(DKA_SEND_NOTIF_s.NEXTVAL) INTO l_wf_itemkey FROM dual;
  
    -- Creation du process WF
    wf_engine.CreateProcess(itemtype => l_wf_itemtype,
                            itemkey  => l_wf_itemkey,
                            process  => l_wf_process);
  
    -- Initialisation des attributs
  
    --DKA_DESTINATAIRE
    ------------------
    SELECT user_name
      INTO l_user_name
      FROM fnd_user fu
     WHERE fu.employee_id = pv_signataire
       AND rownum = 1;
  
    wf_engine.SetItemAttrText(itemtype => l_wf_itemtype,
                              itemkey  => l_wf_itemkey,
                              aname    => 'DKA_DESTINATAIRE',
                              avalue   => l_user_name);
  
    --DKA_DOCUMENT_ID
    -----------------
    wf_engine.SetItemAttrNumber(itemtype => l_wf_itemtype,
                                itemkey  => l_wf_itemkey,
                                aname    => 'DKA_DOCUMENT_ID',
                                avalue   => pn_header_id);
  
    --DKA_TEXT_HEAD
    ---------------
    wf_engine.SetItemAttrText(itemtype => l_wf_itemtype,
                              itemkey  => l_wf_itemkey,
                              aname    => 'DKA_TEXT_HEAD',
                              avalue   => gv_subject);
  
    --DKA_TEXT_BODY
    ---------------
    wf_engine.SetItemAttrText(itemtype => l_wf_itemtype,
                              itemkey  => l_wf_itemkey,
                              aname    => 'DKA_TEXT_BODY',
                              avalue   => gv_body);
  
    -- Kick off the process
    wf_engine.StartProcess(itemtype => l_wf_itemtype,
                           itemkey  => l_wf_itemkey);
  
    log_msg('Notification envoye a : ' || l_user_name || '(Workflow : ' ||
            l_wf_itemtype || '-' || l_wf_itemkey || ')');
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'Erreur procedure ENVOI_NOTIF ' || SQLERRM;
      pn_retcode := 2;
      log_msg(pv_errbuf);
  END envoi_notif;

  -------------------------------------------------------------------------------------
  --  Nom           : CHECK_CONTRAT_AVERT
  --  Description   :
  --
  --  PARAMETRES    :
  --    pv_errbuf       Sortie
  --    pv_retcode      Sortie

  --  VALEUR RETOURNEE :
  --     Description       : code retour de validite
  --     Valeurs possibles : 0: OK, 2: erreur ou code erreur ORA
  ------------------------------------------------------------------------------------

  PROCEDURE check_contrat_avert(pv_errbuf  OUT VARCHAR2,
                                pn_retcode OUT NUMBER) IS
  
    TYPE T_HEADER_ID IS TABLE OF PO_HEADERS_ALL.po_header_id%TYPE;
    TYPE T_SIGNATAIRE IS TABLE OF DKA_CONTRAT_SSTR.signataire_contrat%TYPE;
  
    l_header_id  T_HEADER_ID;
    l_signataire T_SIGNATAIRE;
  
    l_result        BOOLEAN;
    l_check_version po_headers_all.revision_num%TYPE;
    l_ok_version    VARCHAR2(2);
    l_chk_archive   NUMBER;
  
    CURSOR c_select IS
      SELECT ph.po_header_id, dcs.signataire_contrat
        --- 25/08/2017 NBO artf2212485 - SPE119 - Traitement de résiliation et renouvellement - cloisonnement par UO
        FROM po_headers/*_all*/ ph, dka_contrat_sstr dcs
       WHERE ph.po_header_id = dcs.po_header_id
         AND ph.type_lookup_code = 'CONTRACT'
         AND ph.attribute4 IN
             ('CONTRAT DEPENDANT', 'CONTRAT SOUS-TRAITANCE')
         AND trunc(sysdate) BETWEEN
             trunc(add_months(ph.End_Date, - (dcs.preavis_resiliation + 1))) AND
             trunc(add_months(ph.End_Date, - (dcs.preavis_resiliation)))
         AND ph.authorization_status = 'APPROVED'
         AND (ph.closed_date IS NULL OR
             TRUNC(ph.closed_date) > TRUNC(ph.end_date))
            -- CDE 110210 AND ph.revision_num < nvl(dcs.NB_RECONDUCTION,gn_nbre_reconduction)
         AND dcs.reconduction_num < nvl(dcs.NB_RECONDUCTION, 0)
         AND dcs.reconduction_num < gn_nbre_reconduction
         AND (dcs.flag_mail_avertissement IS NULL OR
             dcs.flag_mail_avertissement != 'Y');
  
    ln_retcode NUMBER;
    lv_errbuf  VARCHAR2(2000);
  
    e_maj_flag_avert EXCEPTION;
    e_send_mail EXCEPTION;
    e_get_message EXCEPTION;
  
  BEGIN
  
    OPEN c_select;
    FETCH c_select BULK COLLECT
      INTO l_header_id, l_signataire;
    CLOSE c_select;
  
    IF l_header_id.FIRST IS NOT NULL THEN
      FOR i IN l_header_id.FIRST .. l_header_id.LAST LOOP
        log_msg(chr(10) || 'Avertissement pour le contrat ' || chr(10) ||
                'id = ' || l_header_id(i) || ' signataire = ' ||
                l_signataire(i) || chr(10));
        BEGIN
        
          --RECUPERATION DES MESSAGES
          log_msg('Recuperation des messages...');
          get_message(l_header_id(i), lv_errbuf, ln_retcode);
          IF ln_retcode != 0 THEN
            RAISE e_get_message;
          END IF;
          log_msg('Recuperation des messages OK...');
        
          --MISE A JOUR DKA_CONTRAT_SSTR
          log_msg('Mise a jour DKA_CONTRAT_SSTR...');
          maj_flag_avert(l_header_id(i), lv_errbuf, ln_retcode);
          IF ln_retcode != 0 THEN
            RAISE e_maj_flag_avert;
          END IF;
          log_msg('Mise a jour DKA_CONTRAT_SSTR OK...');
        
          --ENVOI MAIL AVERTISSEMENT
          log_msg('Envoi mail...');
          envoi_mail(l_signataire(i),
                     gv_subject_avert,
                     gv_body_avert,
                     lv_errbuf,
                     ln_retcode);
          IF ln_retcode != 0 THEN
            RAISE e_send_mail;
          END IF;
          log_msg('Envoi mail avertissement OK...');
        
          gn_traite_avert := gn_traite_avert + 1;
        
          COMMIT;
        
        EXCEPTION
          WHEN e_get_message THEN
            lv_errbuf  := 'Erreur dans la procedure de recuperation des messages : ' ||
                          SQLERRM;
            pn_retcode := 1;
            log_msg(lv_errbuf);
            --CONTINUE
            gn_erreur_avert := gn_erreur_avert + 1;
            ROLLBACK;
          WHEN e_send_mail THEN
            lv_errbuf  := 'Erreur dans la procedure d''envoi des notifications : ' ||
                          SQLERRM;
            pn_retcode := 1;
            log_msg(lv_errbuf);
            --CONTINUE
            gn_erreur_avert := gn_erreur_avert + 1;
            ROLLBACK;
          WHEN e_maj_flag_avert THEN
            lv_errbuf  := 'Erreur dans la mise a jour de la table DKA_CONTRAT_SSTR : ' ||
                          SQLERRM;
            pn_retcode := 1;
            log_msg(lv_errbuf);
            --CONTINUE
            gn_erreur_avert := gn_erreur_avert + 1;
            ROLLBACK;
          WHEN OTHERS THEN
            lv_errbuf  := 'Erreur dans la boucle : ' || SQLERRM;
            pn_retcode := 1;
            log_msg(lv_errbuf);
            --CONTINUE
            gn_erreur_avert := gn_erreur_avert + 1;
            ROLLBACK;
        END;
      END LOOP;
    
    END IF;
  
    IF pn_retcode = 1 THEN
      pv_errbuf := 'Erreur dans la verification des contrats';
      log_msg(pv_errbuf);
    END IF;
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'Erreur procedure CHECK_CONTRAT_AVERT ' || SQLERRM;
      pn_retcode := 2;
      log_msg(pv_errbuf);
  END check_contrat_avert;

  -------------------------------------------------------------------------------------
  --  Nom           : CHECK_CONTRAT_AVERT_MAX_RENOUV
  --  Description   : Envoi d'un mail d'avertissement lorsque le contrat non renouvelable
  --          a atteint le maximum des renouvellements possible.
  --
  --  PARAMETRES    :
  --    pv_errbuf       Sortie
  --    pv_retcode      Sortie

  --  VALEUR RETOURNEE :
  --     Description       : code retour de validite
  --     Valeurs possibles : 0: OK, 2: erreur ou code erreur ORA
  ------------------------------------------------------------------------------------

  PROCEDURE check_contrat_max_renouv(pv_errbuf  OUT VARCHAR2,
                                           pn_retcode OUT NUMBER) IS
  
    TYPE T_HEADER_ID IS TABLE OF PO_HEADERS_ALL.po_header_id%TYPE;
    TYPE T_SIGNATAIRE IS TABLE OF DKA_CONTRAT_SSTR.signataire_contrat%TYPE;
  
    l_header_id  T_HEADER_ID;
    l_signataire T_SIGNATAIRE;
  
    l_result        BOOLEAN;
    l_check_version po_headers_all.revision_num%TYPE;
    l_ok_version    VARCHAR2(2);
    l_chk_archive   NUMBER;
  
    CURSOR c_select IS
      SELECT ph.po_header_id, dcs.signataire_contrat
        --- 25/08/2017 NBO artf2212485 - SPE119 - Traitement de résiliation et renouvellement - cloisonnement par UO
        FROM po_headers/*_all*/ ph, dka_contrat_sstr dcs
       WHERE ph.po_header_id = dcs.po_header_id
         AND ph.type_lookup_code = 'CONTRACT'
         AND ph.attribute4 IN
             ('CONTRAT DEPENDANT', 'CONTRAT SOUS-TRAITANCE')
         AND trunc(sysdate) BETWEEN
             trunc(add_months(ph.End_Date, - (dcs.preavis_resiliation + 1))) AND
             trunc(add_months(ph.End_Date, - (dcs.preavis_resiliation)))
         AND ph.authorization_status = 'APPROVED'
         AND (ph.closed_date IS NULL OR
             TRUNC(ph.closed_date) > TRUNC(ph.end_date))
            -- CDE 110210 AND ph.revision_num < nvl(dcs.NB_RECONDUCTION,gn_nbre_reconduction)
         AND dcs.reconduction_num >= nvl(dcs.NB_RECONDUCTION, 0)
         AND dcs.reconduction_num >= gn_nbre_reconduction
         AND (dcs.flag_mail_avertissement IS NULL OR
             dcs.flag_mail_avertissement != 'Y');
  
    ln_retcode NUMBER;
    lv_errbuf  VARCHAR2(2000);
  
    e_maj_flag_avert EXCEPTION;
    e_send_mail EXCEPTION;
    e_get_message EXCEPTION;
  
  BEGIN
  
    OPEN c_select;
    FETCH c_select BULK COLLECT
      INTO l_header_id, l_signataire;
    CLOSE c_select;
  
    IF l_header_id.FIRST IS NOT NULL THEN
      FOR i IN l_header_id.FIRST .. l_header_id.LAST LOOP
        log_msg(chr(10) || 'Avertissement pour le contrat ' || chr(10) ||
                'id = ' || l_header_id(i) || ' signataire = ' ||
                l_signataire(i) || chr(10));
        BEGIN
        
          --RECUPERATION DES MESSAGES
          log_msg('Recuperation des messages...');
          get_message_fin(l_header_id(i), lv_errbuf, ln_retcode);
          IF ln_retcode != 0 THEN
            RAISE e_get_message;
          END IF;
          log_msg('Recuperation des messages OK...');
        
          --MISE A JOUR DKA_CONTRAT_SSTR
          log_msg('Mise a jour DKA_CONTRAT_SSTR...');
          maj_flag_avert(l_header_id(i), lv_errbuf, ln_retcode);
          IF ln_retcode != 0 THEN
            RAISE e_maj_flag_avert;
          END IF;
          log_msg('Mise a jour DKA_CONTRAT_SSTR OK...');
        
          --ENVOI MAIL AVERTISSEMENT
          log_msg('Envoi mail...');
          envoi_mail(l_signataire(i),
                     gv_subject_avert_fin,
                     gv_body_avert_fin,
                     lv_errbuf,
                     ln_retcode);
          IF ln_retcode != 0 THEN
            RAISE e_send_mail;
          END IF;
          log_msg('Envoi mail avertissement OK...');
        
          gn_traite_avert := gn_traite_avert + 1;
        
          COMMIT;
        
        EXCEPTION
          WHEN e_get_message THEN
            lv_errbuf  := 'Erreur dans la procedure de recuperation des messages : ' ||
                          SQLERRM;
            pn_retcode := 1;
            log_msg(lv_errbuf);
            --CONTINUE
            gn_erreur_avert := gn_erreur_avert + 1;
            ROLLBACK;
          WHEN e_send_mail THEN
            lv_errbuf  := 'Erreur dans la procedure d''envoi des notifications : ' ||
                          SQLERRM;
            pn_retcode := 1;
            log_msg(lv_errbuf);
            --CONTINUE
            gn_erreur_avert := gn_erreur_avert + 1;
            ROLLBACK;
          WHEN e_maj_flag_avert THEN
            lv_errbuf  := 'Erreur dans la mise a jour de la table DKA_CONTRAT_SSTR : ' ||
                          SQLERRM;
            pn_retcode := 1;
            log_msg(lv_errbuf);
            --CONTINUE
            gn_erreur_avert := gn_erreur_avert + 1;
            ROLLBACK;
          WHEN OTHERS THEN
            lv_errbuf  := 'Erreur dans la boucle : ' || SQLERRM;
            pn_retcode := 1;
            log_msg(lv_errbuf);
            --CONTINUE
            gn_erreur_avert := gn_erreur_avert + 1;
            ROLLBACK;
        END;
      END LOOP;
    
    END IF;
  
    IF pn_retcode = 1 THEN
      pv_errbuf := 'Erreur dans la verification des contrats';
      log_msg(pv_errbuf);
    END IF;
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'Erreur procedure CHECK_CONTRAT_AVERT ' || SQLERRM;
      pn_retcode := 2;
      log_msg(pv_errbuf);
  END check_contrat_max_renouv;

  -------------------------------------------------------------------------------------
  --  Nom           : CHECK_CONTRAT_AVERT_NMAX_RENOUV
  --  Description   : Envoi d'un mail d'avertissement lorsque le contrat non renouvelable
  --          a atteint le maximum des renouvellements possible sur son contrat mais
  --          n'a pas atteint le maximum des renouvellements possible.
  --
  --  PARAMETRES    :
  --    pv_errbuf       Sortie
  --    pv_retcode      Sortie

  --  VALEUR RETOURNEE :
  --     Description       : code retour de validite
  --     Valeurs possibles : 0: OK, 2: erreur ou code erreur ORA
  ------------------------------------------------------------------------------------

  PROCEDURE check_contrat_nmax_renouv(pv_errbuf  OUT VARCHAR2,
                                            pn_retcode OUT NUMBER) IS
  
    TYPE T_HEADER_ID IS TABLE OF PO_HEADERS_ALL.po_header_id%TYPE;
    TYPE T_SIGNATAIRE IS TABLE OF DKA_CONTRAT_SSTR.signataire_contrat%TYPE;
  
    l_header_id  T_HEADER_ID;
    l_signataire T_SIGNATAIRE;
  
    l_result        BOOLEAN;
    l_check_version po_headers_all.revision_num%TYPE;
    l_ok_version    VARCHAR2(2);
    l_chk_archive   NUMBER;
  
    CURSOR c_select IS
      SELECT ph.po_header_id, dcs.signataire_contrat
        --- 25/08/2017 NBO artf2212485 - SPE119 - Traitement de résiliation et renouvellement - cloisonnement par UO
        FROM po_headers/*_all*/ ph, dka_contrat_sstr dcs
       WHERE ph.po_header_id = dcs.po_header_id
         AND ph.type_lookup_code = 'CONTRACT'
         AND ph.attribute4 IN
             ('CONTRAT DEPENDANT', 'CONTRAT SOUS-TRAITANCE')
         AND trunc(sysdate) BETWEEN
             trunc(add_months(ph.End_Date, - (dcs.preavis_resiliation + 1))) AND
             trunc(add_months(ph.End_Date, - (dcs.preavis_resiliation)))
         AND ph.authorization_status = 'APPROVED'
         AND (ph.closed_date IS NULL OR
             TRUNC(ph.closed_date) > TRUNC(ph.end_date))
         AND dcs.reconduction_num >= nvl(dcs.NB_RECONDUCTION, 0)
         AND dcs.reconduction_num < gn_nbre_reconduction
         AND (dcs.flag_mail_avertissement IS NULL OR
             dcs.flag_mail_avertissement != 'Y');
  
    ln_retcode NUMBER;
    lv_errbuf  VARCHAR2(2000);
  
    e_maj_flag_avert EXCEPTION;
    e_send_mail EXCEPTION;
    e_get_message EXCEPTION;
  
  BEGIN
  
    OPEN c_select;
    FETCH c_select BULK COLLECT
      INTO l_header_id, l_signataire;
    CLOSE c_select;
  
    IF l_header_id.FIRST IS NOT NULL THEN
      FOR i IN l_header_id.FIRST .. l_header_id.LAST LOOP
        log_msg(chr(10) || 'Avertissement pour le contrat ' || chr(10) ||
                'id = ' || l_header_id(i) || ' signataire = ' ||
                l_signataire(i) || chr(10));
        BEGIN
        
          --RECUPERATION DES MESSAGES
          log_msg('Recuperation des messages...');
          get_message_fin(l_header_id(i), lv_errbuf, ln_retcode);
          IF ln_retcode != 0 THEN
            RAISE e_get_message;
          END IF;
          log_msg('Recuperation des messages OK...');
        
          --MISE A JOUR DKA_CONTRAT_SSTR
          log_msg('Mise a jour DKA_CONTRAT_SSTR...');
          maj_flag_avert(l_header_id(i), lv_errbuf, ln_retcode);
          IF ln_retcode != 0 THEN
            RAISE e_maj_flag_avert;
          END IF;
          log_msg('Mise a jour DKA_CONTRAT_SSTR OK...');
        
          --ENVOI MAIL AVERTISSEMENT
          log_msg('Envoi mail...');
          envoi_mail(l_signataire(i),
                     gv_subject_avert_nfin,
                     gv_body_avert_nfin,
                     lv_errbuf,
                     ln_retcode);
          IF ln_retcode != 0 THEN
            RAISE e_send_mail;
          END IF;
          log_msg('Envoi mail avertissement OK...');
        
          gn_traite_avert := gn_traite_avert + 1;
        
          COMMIT;
        
        EXCEPTION
          WHEN e_get_message THEN
            lv_errbuf  := 'Erreur dans la procedure de recuperation des messages : ' ||
                          SQLERRM;
            pn_retcode := 1;
            log_msg(lv_errbuf);
            --CONTINUE
            gn_erreur_avert := gn_erreur_avert + 1;
            ROLLBACK;
          WHEN e_send_mail THEN
            lv_errbuf  := 'Erreur dans la procedure d''envoi des notifications : ' ||
                          SQLERRM;
            pn_retcode := 1;
            log_msg(lv_errbuf);
            --CONTINUE
            gn_erreur_avert := gn_erreur_avert + 1;
            ROLLBACK;
          WHEN e_maj_flag_avert THEN
            lv_errbuf  := 'Erreur dans la mise a jour de la table DKA_CONTRAT_SSTR : ' ||
                          SQLERRM;
            pn_retcode := 1;
            log_msg(lv_errbuf);
            --CONTINUE
            gn_erreur_avert := gn_erreur_avert + 1;
            ROLLBACK;
          WHEN OTHERS THEN
            lv_errbuf  := 'Erreur dans la boucle : ' || SQLERRM;
            pn_retcode := 1;
            log_msg(lv_errbuf);
            --CONTINUE
            gn_erreur_avert := gn_erreur_avert + 1;
            ROLLBACK;
        END;
      END LOOP;
    
    END IF;
  
    IF pn_retcode = 1 THEN
      pv_errbuf := 'Erreur dans la verification des contrats';
      log_msg(pv_errbuf);
    END IF;
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'Erreur procedure CHECK_CONTRAT_AVERT ' || SQLERRM;
      pn_retcode := 2;
      log_msg(pv_errbuf);
  END check_contrat_nmax_renouv;

  -------------------------------------------------------------------------------------
  --  Nom           : CHECK_CONTRAT
  --  Description   :
  --
  --  PARAMETRES    :
  --    pv_errbuf       Sortie
  --    pv_retcode      Sortie

  --  VALEUR RETOURNEE :
  --     Description       : code retour de validite
  --     Valeurs possibles : 0: OK, 2: erreur ou code erreur ORA
  ------------------------------------------------------------------------------------

  PROCEDURE check_contrat(pv_errbuf OUT VARCHAR2, pn_retcode OUT NUMBER) IS
  
    TYPE T_HEADER_ID IS TABLE OF PO_HEADERS_ALL.po_header_id%TYPE;
    TYPE T_SIGNATAIRE IS TABLE OF DKA_CONTRAT_SSTR.signataire_contrat%TYPE;
  
    l_header_id  T_HEADER_ID;
    l_signataire T_SIGNATAIRE;
  
    l_result        BOOLEAN;
    l_check_version po_headers_all.revision_num%TYPE;
    l_ok_version    VARCHAR2(2);
    l_chk_archive   NUMBER;
  
    CURSOR c_select IS
      SELECT ph.po_header_id, dcs.signataire_contrat
        --- 25/08/2017 NBO artf2212485 - SPE119 - Traitement de résiliation et renouvellement - cloisonnement par UO
        FROM po_headers/*_all*/ ph, dka_contrat_sstr dcs
       WHERE ph.po_header_id = dcs.po_header_id
         AND ph.type_lookup_code = 'CONTRACT'
         AND ph.attribute4 IN
             ('CONTRAT DEPENDANT', 'CONTRAT SOUS-TRAITANCE')
         AND trunc(sysdate) BETWEEN
             trunc(add_months(ph.End_Date, - (dcs.preavis_resiliation))) AND
             trunc(ph.End_Date)
         AND ph.authorization_status = 'APPROVED'
         AND (ph.closed_date IS NULL OR
             TRUNC(ph.closed_date) > TRUNC(ph.end_date))
            -- CDE 110210 AND ph.revision_num < nvl(dcs.NB_RECONDUCTION,gn_nbre_reconduction)
         AND dcs.reconduction_num < nvl(dcs.NB_RECONDUCTION, 0)
         AND dcs.reconduction_num < gn_nbre_reconduction;
  
    ln_retcode NUMBER;
    lv_errbuf  VARCHAR2(2000);
  
    e_archiver EXCEPTION;
    e_maj_po EXCEPTION;
    e_send_mail EXCEPTION;
    e_get_message EXCEPTION;
    
    --RBE artf2154499
    v_return_status         VARCHAR2(50);
    v_msg_count             NUMBER;
    v_msg_data              VARCHAR2(1000);
  
  BEGIN
  
    OPEN c_select;
    FETCH c_select BULK COLLECT
      INTO l_header_id, l_signataire;
    CLOSE c_select;
  
    IF l_header_id.FIRST IS NOT NULL THEN
      FOR i IN l_header_id.FIRST .. l_header_id.LAST LOOP
        log_msg(chr(10) || 'Opération pour le contrat ' || chr(10) ||
                'id = ' || l_header_id(i) || ' signataire = ' ||
                l_signataire(i) || chr(10));
        BEGIN
          --ARCHIVER
          log_msg('Archivage...');
        
          SELECT COUNT(1)
            INTO l_chk_archive
            FROM po_headers_archive_all pha, po_headers_all ph
           WHERE pha.po_header_id = ph.po_header_id
             AND ph.revision_num = pha.revision_num
             AND pha.latest_external_flag = 'Y'
             AND ph.po_header_id = l_header_id(i);
        
          IF l_chk_archive = 0 THEN
            BEGIN
              --Vérifier que la version précédente est bien archivee
              SELECT nvl(ph.revision_num, 0)
                INTO l_check_version
                FROM po_headers_all ph
               WHERE ph.po_header_id = l_header_id(i);
            
              IF l_check_version != 0 THEN
                SELECT 'ok'
                  INTO l_ok_version
                  FROM po_headers_archive_all pha
                 WHERE pha.revision_num = l_check_version - 1 -- version précédente
                   AND pha.latest_external_flag = 'Y'
                   AND pha.po_header_id = l_header_id(i);
              END IF;
            
            EXCEPTION
              WHEN OTHERS THEN
                lv_errbuf := 'Erreur dans la procedure d''archivage : ' ||
                             SQLERRM || chr(10) ||
                             'Verifier la table PO_HEADERS_ARCHIVE_ALL pour po_header_id = ' ||
                             l_header_id(i);
                log_msg(lv_errbuf);
                RAISE e_archiver;
            END;
          
            --RBE artf2154499 
            --PO_ARCHIVE_DOCUMENT_SV.Archive_PO(l_header_id(i), l_result);
            PO_DOCUMENT_ARCHIVE_PVT.archive_po( p_api_version => 1.0,
                                                p_document_id           => l_header_id(i),
                                                p_document_type         => 'PA',
                                                p_document_subtype      => 'CONTRACT',
                                                x_return_status         => v_return_status,
                                                x_msg_count             => v_msg_count,
                                                x_msg_data              => v_msg_data);
            IF v_return_status != 'S' THEN
            --IF NOT l_result THEN --RBE artf2154499 
              RAISE e_archiver;
            END IF;
            log_msg('Archivage OK...');
          
          ELSE
            log_msg('Archivage inutile...');
          END IF;
        
          --RECUPERATION DES MESSAGES
          log_msg('Recuperation des messages...');
          get_message(l_header_id(i), lv_errbuf, ln_retcode);
          IF ln_retcode != 0 THEN
            RAISE e_get_message;
          END IF;
          log_msg('Recuperation des messages OK...');
        
          --MISE A JOUR PO_HEADER_ALL
          log_msg('Mise a jour PO_HEADER_ALL...');
          maj_po(l_header_id(i), lv_errbuf, ln_retcode);
          IF ln_retcode != 0 THEN
            RAISE e_maj_po;
          END IF;
          log_msg('Mise a jour PO_HEADER_ALL OK...');
        
          --ENVOI NOTIF + MAIL
          log_msg('Envoi mail...');
          envoi_mail(l_signataire(i),
                     gv_subject,
                     gv_body,
                     lv_errbuf,
                     ln_retcode);
          IF ln_retcode != 0 THEN
            RAISE e_send_mail;
          END IF;
          log_msg('Envoi mail OK...');
        
          log_msg('Envoi notification...');
          envoi_notif(l_header_id(i),
                      l_signataire(i),
                      lv_errbuf,
                      ln_retcode);
          IF ln_retcode != 0 THEN
            RAISE e_send_mail;
          END IF;
          log_msg('Envoi notification OK...');
        
          gn_traite := gn_traite + 1;
        
          COMMIT;
        
        EXCEPTION
          WHEN e_archiver THEN
            lv_errbuf  := 'Erreur dans la procedure d''archivage : ' ||
                          SQLERRM;
            pn_retcode := 1;
            log_msg(lv_errbuf);
            --CONTINUE
            gn_erreur := gn_erreur + 1;
            ROLLBACK;
          WHEN e_maj_po THEN
            lv_errbuf  := 'Erreur dans la mise a jour de la table PO_HEADERS_ALL : ' ||
                          SQLERRM;
            pn_retcode := 1;
            log_msg(lv_errbuf);
            --CONTINUE
            gn_erreur := gn_erreur + 1;
            ROLLBACK;
          WHEN e_get_message THEN
            lv_errbuf  := 'Erreur dans la procedure de recuperation des messages : ' ||
                          SQLERRM;
            pn_retcode := 1;
            log_msg(lv_errbuf);
            --CONTINUE
            gn_erreur := gn_erreur + 1;
            ROLLBACK;
          WHEN e_send_mail THEN
            lv_errbuf  := 'Erreur dans la procedure d''envoi des notifications : ' ||
                          SQLERRM;
            pn_retcode := 1;
            log_msg(lv_errbuf);
            --CONTINUE
            gn_erreur := gn_erreur + 1;
            ROLLBACK;
          WHEN OTHERS THEN
            lv_errbuf  := 'Erreur dans la boucle : ' || SQLERRM;
            pn_retcode := 1;
            log_msg(lv_errbuf);
            --CONTINUE
            gn_erreur := gn_erreur + 1;
            ROLLBACK;
        END;
      END LOOP;
    
    END IF;
  
    IF pn_retcode = 1 THEN
      pv_errbuf := 'Erreur dans la verification des contrats';
      log_msg(pv_errbuf);
    END IF;
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'Erreur procedure CHECK_CONTRAT ' || SQLERRM;
      pn_retcode := 2;
      log_msg(pv_errbuf);
  END check_contrat;

  -------------------------------------------------------------------------------------
  --  Nom           : CHECK_CONTRAT_FIN
  --  Description   : 10/01/2013 BCO INC000000363006
  --
  --  PARAMETRES    :
  --    pv_errbuf       Sortie
  --    pv_retcode      Sortie

  --  VALEUR RETOURNEE :
  --     Description       : code retour de validite
  --     Valeurs possibles : 0: OK, 2: erreur ou code erreur ORA
  ------------------------------------------------------------------------------------

  PROCEDURE check_contrat_fin(pv_errbuf  OUT VARCHAR2,
                              pn_retcode OUT NUMBER) IS
  
    TYPE T_HEADER_ID IS TABLE OF PO_HEADERS_ALL.po_header_id%TYPE;
    TYPE T_SIGNATAIRE IS TABLE OF DKA_CONTRAT_SSTR.signataire_contrat%TYPE;
  
    l_header_id  T_HEADER_ID;
    l_signataire T_SIGNATAIRE;
  
    l_result        BOOLEAN;
    l_check_version po_headers_all.revision_num%TYPE;
    l_ok_version    VARCHAR2(2);
    l_chk_archive   NUMBER;
  
    CURSOR c_select_fin IS
      SELECT ph.po_header_id, dcs.signataire_contrat
        --- 25/08/2017 NBO artf2212485 - SPE119 - Traitement de résiliation et renouvellement - cloisonnement par UO
        FROM po_headers/*_all*/ ph, dka_contrat_sstr dcs
       WHERE ph.po_header_id = dcs.po_header_id
         AND ph.type_lookup_code = 'CONTRACT'
         AND ph.attribute4 IN
             ('CONTRAT DEPENDANT', 'CONTRAT SOUS-TRAITANCE')
         AND trunc(sysdate) > trunc(ph.End_Date)
            --AND ph.authorization_status = 'APPROVED'
         AND (ph.closed_code != 'FINALLY CLOSED' OR
             ph.closed_code IS NULL)
         AND ph.closed_date IS NULL
         AND (dcs.reconduction_num >= nvl(dcs.NB_RECONDUCTION, 0) OR
             dcs.reconduction_num >= gn_nbre_reconduction);
  
    ln_retcode NUMBER;
    lv_errbuf  VARCHAR2(2000);
  
    e_maj_po EXCEPTION;
    e_send_mail EXCEPTION;
    e_get_message EXCEPTION;
  
  BEGIN
  
    OPEN c_select_fin;
    FETCH c_select_fin BULK COLLECT
      INTO l_header_id, l_signataire;
    CLOSE c_select_fin;
  
    IF l_header_id.FIRST IS NOT NULL THEN
      FOR i IN l_header_id.FIRST .. l_header_id.LAST LOOP
        log_msg(chr(10) || 'Opération pour le contrat ' || chr(10) ||
                'id = ' || l_header_id(i) || ' signataire = ' ||
                l_signataire(i) || chr(10));
        BEGIN
        
          --RECUPERATION DES MESSAGES
          log_msg('Recuperation des messages...');
          get_message_fin(l_header_id(i), lv_errbuf, ln_retcode);
          IF ln_retcode != 0 THEN
            RAISE e_get_message;
          END IF;
          log_msg('Recuperation des messages OK...');
        
          --MISE A JOUR PO_HEADER_ALL
          log_msg('Mise a jour PO_HEADER_ALL...');
          maj_po_fin(l_header_id(i), lv_errbuf, ln_retcode);
          IF ln_retcode != 0 THEN
            RAISE e_maj_po;
          END IF;
          log_msg('Mise a jour PO_HEADER_ALL OK...');
        
          --ENVOI NOTIF + MAIL
          log_msg('Envoi mail...');
          envoi_mail(l_signataire(i),
                     gv_subject_fin,
                     gv_body_fin,
                     lv_errbuf,
                     ln_retcode);
          IF ln_retcode != 0 THEN
            RAISE e_send_mail;
          END IF;
          log_msg('Envoi mail OK...');
        
          gn_traite := gn_traite + 1;
        
          COMMIT;
        
        EXCEPTION
          WHEN e_maj_po THEN
            lv_errbuf  := 'Erreur dans la mise a jour de la table PO_HEADERS_ALL : ' ||
                          SQLERRM;
            pn_retcode := 1;
            log_msg(lv_errbuf);
            --CONTINUE
            gn_erreur := gn_erreur + 1;
            ROLLBACK;
          WHEN e_get_message THEN
            lv_errbuf  := 'Erreur dans la procedure de recuperation des messages : ' ||
                          SQLERRM;
            pn_retcode := 1;
            log_msg(lv_errbuf);
            --CONTINUE
            gn_erreur := gn_erreur + 1;
            ROLLBACK;
          WHEN e_send_mail THEN
            lv_errbuf  := 'Erreur dans la procedure d''envoi des notifications : ' ||
                          SQLERRM;
            pn_retcode := 1;
            log_msg(lv_errbuf);
            --CONTINUE
            gn_erreur := gn_erreur + 1;
            ROLLBACK;
          WHEN OTHERS THEN
            lv_errbuf  := 'Erreur dans la boucle : ' || SQLERRM;
            pn_retcode := 1;
            log_msg(lv_errbuf);
            --CONTINUE
            gn_erreur := gn_erreur + 1;
            ROLLBACK;
        END;
      END LOOP;
    
    END IF;
  
    IF pn_retcode = 1 THEN
      pv_errbuf := 'Erreur dans la verification des contrats';
      log_msg(pv_errbuf);
    END IF;
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'Erreur procedure CHECK_CONTRAT ' || SQLERRM;
      pn_retcode := 2;
      log_msg(pv_errbuf);
  END check_contrat_fin;

  -----------------------------------------------------------------
  --  NOM           : EDITION_OUTPUT
  --  DESCRIPTION   : procedure d'edition du fichier de sortie
  --
  --  PARAMETRES :
  --
  --  PN_RETCODE             code retour out
  --  PV_ERRBUF              description de l'erreur out
  --
  -----------------------------------------------------------------
  PROCEDURE edition_output(pv_errbuf  OUT NOCOPY VARCHAR2,
                           pn_retcode OUT NOCOPY NUMBER) IS
  BEGIN
    out_msg(gn_traite || ' contrats ont ete traités avec succes');
    out_msg(gn_erreur || ' contrats sont tombés en erreur' || chr(10));
    out_msg(gn_traite_avert ||
            ' mails d''avertissement envoyés avec succes');
    out_msg(gn_erreur_avert || ' mails d''avertissement tombés en erreur' ||
            chr(10));
  
    out_msg('Veuillez consulter le fichier de journalisation du traitement ID = ' ||
            FND_GLOBAL.CONC_REQUEST_ID);
  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf  := 'Erreur procedure EDITION_OUTPUT' || chr(10) || SQLERRM;
      log_msg(pv_errbuf);
  END edition_output;

  --------------------------------------------------------------------------------------
  --  Nom           : MAIN
  --  Description   : Procedure principale enchainant l'ensemble des autres procedures
  --
  --  PARAMETRES :
  --    pv_errbuf                   Entree/Sortie       retour de message eventuel
  --    pn_retcode                  Sortie          status du traitement en sortie
  --
  --  VALEUR RETOURNEE :
  --     Description       : code retour de validite
  --     Valeurs possibles : 0: normal, 1: warning, 2: erreur
  --   pv_mail_test                Entree          Adresse mail destinataire pour test
  ----------------------------------------------------------------------------------------
  PROCEDURE main(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER,pv_mail_test IN VARCHAR2) IS
    --Exception
    e_init EXCEPTION;
    e_check_contrat EXCEPTION;
    e_edition_output EXCEPTION;
    e_check_contrat_avert EXCEPTION;
    e_check_contrat_max_renouv EXCEPTION;
    e_check_contrat_nmax_renouv EXCEPTION;
    
    --10/01/2013 BCO INC000000363006 - Exception pour fermeture définive des contrats dont le nombre de reconduction est atteint.
    e_check_contrat_fin EXCEPTION;
  
    --variable temporaire pour le code retour
    l_retcode PLS_INTEGER := 0;
  
  BEGIN
    ----------------------------------------------------------------
    --Initialisation du traitement
    ----------------------------------------------------------------
    log_msg('____________________________________________________________' ||
            chr(10) || 'Initialisation' || chr(10) ||
            '____________________________________________________________' ||
            chr(10));
  
    log_msg('Debut : ' || get_time || chr(10));
    
    --YWA artf2120401
    ------------------------------------
    --INITIALISATION ADRESSE MAIL TEST--
    ------------------------------------
    DKA_SEND_MAIL_PKG.mail_test(pv_mail_test,gv_mail_test);
    log_msg('Mail de test :'||gv_mail_test);
  
    --procedure de initialisation
    init(pv_errbuf, pn_retcode);
    IF pn_retcode != 0 THEN
      RAISE e_init;
    END IF;
  
    log_msg('Initialisation OK...' || chr(10));
    log_msg('Fin   : ' || get_time || chr(10));
  
    ----------------------------------------------------------------
    --Envoi des messages d'avertissement
    ----------------------------------------------------------------
    log_msg('____________________________________________________________' ||
            chr(10) || 'Envoi des messages d''avertissement' || chr(10) ||
            '____________________________________________________________' ||
            chr(10));
    log_msg('Debut : ' || get_time || chr(10));
  
    --procedure de reprise de la table des rejets
    check_contrat_avert(pv_errbuf, pn_retcode);
    IF pn_retcode = 2 THEN
      RAISE e_check_contrat_avert;
    END IF;
  
    log_msg('Envoi mail avertissement OK...' || chr(10));
    log_msg('Fin   : ' || get_time || chr(10));
  
    l_retcode := pn_retcode;
  
    ----------------------------------------------------------------
    --Envoi des messages d'avertissement lorsque le contrat non renouvelable
    --a atteint le maximum des renouvellements possible.
    ----------------------------------------------------------------
    log_msg('_______________________________________________________________________________________________________________________________________________' ||
            chr(10) || 'Envoi des messages d''avertissement lorsque le contrat non renouvelable a atteint le maximum des renouvellements possible' || chr(10) ||
            '_______________________________________________________________________________________________________________________________________________' ||
            chr(10));
    log_msg('Debut : ' || get_time || chr(10));
  
    --procedure de reprise de la table des rejets
    check_contrat_max_renouv(pv_errbuf, pn_retcode);
    IF pn_retcode = 2 THEN
      RAISE e_check_contrat_max_renouv;
    END IF;
  
    log_msg('Envoi mail avertissement contrat non renouvelable atteint maximum renouvellements OK...' || chr(10));
    log_msg('Fin   : ' || get_time || chr(10));
  
    l_retcode := pn_retcode;
    
    ----------------------------------------------------------------
    --Envoi des messages d'avertissement lorsque le contrat non renouvelable
    --a atteint le maximum des renouvellements possible sur son contrat mais
    --n'a pas atteint le maximum des renouvellements possible.
    ----------------------------------------------------------------
    log_msg('______________________________________________________________________________________________________________________________________________________________________________________________________________' ||
            chr(10) || 'Envoi des messages d''avertissement lorsque le contrat non renouvelable a atteint le maximum des renouvellements possible mais n''a pas atteint le maximum des renouvellements possibles.' || chr(10) ||
            '______________________________________________________________________________________________________________________________________________________________________________________________________________' ||
            chr(10));
    log_msg('Debut : ' || get_time || chr(10));
  
    --procedure de reprise de la table des rejets
    check_contrat_nmax_renouv(pv_errbuf, pn_retcode);
    IF pn_retcode = 2 THEN
      RAISE e_check_contrat_nmax_renouv;
    END IF;
  
    log_msg('Envoi mail avertissement contrat non renouvelable atteint maximum renouvellements mais pas atteint maximum renouvellement possible OK...' || chr(10));
    log_msg('Fin   : ' || get_time || chr(10));
  
    l_retcode := pn_retcode;
    
    ----------------------------------------------------------------
    --Verification des contrats
    ----------------------------------------------------------------
    log_msg('____________________________________________________________' ||
            chr(10) || 'Verification des contrats' || chr(10) ||
            '____________________________________________________________' ||
            chr(10));
    log_msg('Debut : ' || get_time || chr(10));
  
    --procedure de reprise de la table des rejets
    check_contrat(pv_errbuf, pn_retcode);
    IF pn_retcode = 2 THEN
      RAISE e_check_contrat;
    END IF;
  
    log_msg('Verification des contrats OK...' || chr(10));
    log_msg('Fin   : ' || get_time || chr(10));
  
    l_retcode := pn_retcode;
  
    -----------------------------------------------------------------------------------------------------
    -- Verification des contrats pour la fermeture définitive suite au nombre de renouvellement atteint.
    -----------------------------------------------------------------------------------------------------
    log_msg('____________________________________________________________' ||
            chr(10) ||
            'Verification des contrats pour la fermeture définitive suite au nombre de renouvellement atteint' ||
            chr(10) ||
            '____________________________________________________________' ||
            chr(10));
    log_msg('Debut : ' || get_time || chr(10));
  
    --procedure de reprise de la table des rejets
    check_contrat_fin(pv_errbuf, pn_retcode);
    IF pn_retcode = 2 THEN
      RAISE e_check_contrat_fin;
    END IF;
  
    log_msg('Verification des contrats pour la fermeture définitive suite au nombre de renouvellement atteint OK...' ||
            chr(10));
    log_msg('Fin   : ' || get_time || chr(10));
  
    l_retcode := pn_retcode;
  
    ----------------------------------------------------------------
    --Edition fichier de sortie
    ----------------------------------------------------------------
    log_msg('____________________________________________________________' ||
            chr(10) || 'Edition fichier de sortie' || chr(10) ||
            '____________________________________________________________' ||
            chr(10));
    log_msg('Debut : ' || get_time || chr(10));
  
    --procedure d'edition de la sortie
    edition_output(pv_errbuf, pn_retcode);
    IF pn_retcode != 0 THEN
      RAISE e_edition_output;
    END IF;
  
    log_msg('Edition fichier de sortie OK...' || chr(10));
    log_msg('Fin   : ' || get_time || chr(10));
  
    --Erreur
    pn_retcode := l_retcode;
  
  EXCEPTION
    WHEN e_init THEN
      pv_errbuf  := 'Erreur procedure INIT';
      pn_retcode := 2;
      log_msg(pv_errbuf);
    WHEN e_check_contrat_avert THEN
      pv_errbuf  := 'Erreur procedure CHECK_CONTRAT_AVERT';
      pn_retcode := 2;
      log_msg(pv_errbuf);
    WHEN e_check_contrat_max_renouv THEN
      pv_errbuf  := 'Erreur procedure CHECK_CONTRAT_MAX_RENOUV';
      pn_retcode := 2;
      log_msg(pv_errbuf);
    WHEN e_check_contrat_nmax_renouv THEN
      pv_errbuf  := 'Erreur procedure CHECK_CONTRAT_NMAX_RENOUV';
      pn_retcode := 2;
      log_msg(pv_errbuf);
    WHEN e_check_contrat THEN
      pv_errbuf  := 'Erreur procedure CHECK_CONTRAT';
      pn_retcode := 2;
      log_msg(pv_errbuf);
    WHEN e_edition_output THEN
      pv_errbuf  := 'Erreur procedure EDITION_OUTPUT';
      pn_retcode := 2;
      log_msg(pv_errbuf);
      -- 10/01/2013 BCO INC000000363006 - Exception lorsque le procédure CHECK_CONTRAT_FIN est tombé en erreur.
    WHEN e_check_contrat_fin THEN
      pv_errbuf  := 'Erreur procedure CHECK_CONTRAT_FIN';
      pn_retcode := 2;
      log_msg(pv_errbuf);
    WHEN OTHERS THEN
      pv_errbuf  := 'Erreur procedure MAIN ' || SQLERRM;
      pn_retcode := 2;
      log_msg(pv_errbuf);
  END MAIN;

END DKA_SPORES_CONTRAT_PKG;
/
SHOW ERRORS
EXIT
