SET SCAN OFF
CREATE OR REPLACE PACKAGE BODY APPS.DKA_SAPSUIVI_NOTIF_PKG
AS

----------------------------------------------------------------------------
-- $Id: DKA_SAPSUIVI_NOTIF_PKG.pkb 1312 2008-12-19 15:49:13Z CORP\viknab $
-- CAP GEMINI
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SAPSUIVI_NOTIF_PKG.pkb
-- DESCRIPTION       : DKA_SAPSUIVI_NOTIF_PKG package body
---
--- AUTEUR           : J. JARDEZ
--- DATE DE CREATION : 19/06/2008
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A executer sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- ---------------------------------------------------------
--- 2016/07/28 JJA Migration Helios R12
--- 2017/03/09 JJA artf2116249: ajout d'un parametre pour mail test
--- 2017/06/08 OBE artf2169874 : SPE136 : Suivi des notifications ouvertes - Le lien dans le mail vers OA ne fonctionne pas
--- 2018/02/15 RBE artf2376257 : SPE136 - Correction de la sélection Employés
--- 2018/08/27 OBE artf3024115 : INC0241688 - SPE136 - pas de notifications concernant les DA
--- 2018/09/27 SFA artf3024115 : INC0241688 - SPE136 - pas de notifications concernant les DA
--- 2021/08/30 NBO artf07478744 : INC0577446 - Nous constatons une dérive sur la durée du traitement DKA : Suivi des notifications ouvertes
--- 2021/09/16 NBO artf07478744 : INC0577446 - Nous constatons une dérive sur la durée du traitement DKA : Suivi des notifications ouvertes
--- 2021/11/29 AFE artf07478744 : INC0577446 - Nous constatons une dérive sur la durée du traitement DKA : Suivi des notifications ouvertes
----------------------------------------------------------------------------

----------------------------------------------------------------------------
-- CONSTANTES ET VARIABLES PRIVEES
----------------------------------------------------------------------------
cv_table          CONSTANT    VARCHAR2(30) := '<table border="1">';
cv_line           CONSTANT    VARCHAR2(10) := '<tr><td>';
cv_inter          CONSTANT    VARCHAR2(10) := '</td><td>';
cv_end_line       CONSTANT    VARCHAR2(10) := '</td></tr>';
cv_end_table      CONSTANT    VARCHAR2(10) := '</table>';
cv_saut_ligne     CONSTANT    VARCHAR2(10) := '<br/>';
cv_gd_line        CONSTANT    VARCHAR2(30) := '<tr><td colspan="5">';

-- Adresse de test a qui seront envoyés les mails.
gv_mail_test                  VARCHAR2(240) := NULL;

gv_conn                       VARCHAR2(30);
gv_expediteur                 VARCHAR2(50);
gv_subject                    VARCHAR2(4000);
gv_fin_corps                  VARCHAR2(4000);
gv_entete_tableau             VARCHAR2(4000);
gv_entete_tableau_cde_da      VARCHAR2(4000); -- QVA 11/03/2011

gn_traite                     PLS_INTEGER;
gn_erreur                     PLS_INTEGER;

gb_debug                      BOOLEAN;

--convertion
ga_convert_html                dbms_sql.varchar2_table;

----------------------------------------------------------------------------
--  Nom           : LOG_MSG
--  Description   : procedure d'affichage des messages
--
--  PARAMETRES :
--   pv_message      texte a imprimer dans le log
--
----------------------------------------------------------------------------
  PROCEDURE log_msg(pv_message in varchar2) IS
    vv_message VARCHAR2(1000);
  BEGIN

    vv_message := SUBSTR(pv_message, 1, 1000);

    IF (vv_message IS NULL) THEN
      vv_message := TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS');
    END IF;

    fnd_file.put_line(fnd_file.LOG, vv_message);
    --dbms_output.put_line('LOG : '||substr(vv_message,1,253));
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
    RETURN to_char(sysdate,'DD/MM/YYYY HH24:MI:SS');
  END get_time;

----------------------------------------------------------------------------
--  Nom           : GET_TL_CODE_BLOCAGE
--  Description   : fonction qui retourne la traduction code blocage
--
--  PARAMETRES :
--    pv_code_blocage  code blocage
----------------------------------------------------------------------------
  FUNCTION get_tl_code_blocage(pv_code_blocage IN VARCHAR2) RETURN VARCHAR2 IS

   vv_code_blocage VARCHAR2(100);

  BEGIN
    IF gb_debug THEN
     log_msg('get_tl_code_blocage 000 : pv_code_blocage = '||pv_code_blocage);
    END IF;

    CASE
     WHEN pv_code_blocage = 'AFFACT'     THEN vv_code_blocage := 'Affacturage';
     WHEN pv_code_blocage = 'BAP'        THEN vv_code_blocage := 'Bon a payer';
     WHEN pv_code_blocage = 'CMD_MULT'   THEN vv_code_blocage := 'Commande multiple';
     WHEN pv_code_blocage = 'DIVERS'     THEN vv_code_blocage := 'Divers';
     WHEN pv_code_blocage = 'ECART_PRIX' THEN vv_code_blocage := 'Ecart de prix';
     WHEN pv_code_blocage = 'IMPUT'      THEN vv_code_blocage := 'Imputation';
     WHEN pv_code_blocage = 'OI'         THEN vv_code_blocage := 'Open Interface';
     WHEN pv_code_blocage = 'PRLV'       THEN vv_code_blocage := 'Prélevement';
     WHEN pv_code_blocage = 'QTY_ORD'    THEN vv_code_blocage := 'Quantité commandée';
     WHEN pv_code_blocage = 'QTY_REC'    THEN vv_code_blocage := 'Quantité réceptionnée';
     WHEN pv_code_blocage = 'RIB'        THEN vv_code_blocage := 'RIB';
     ELSE
      vv_code_blocage := 'code inconnu';
    END CASE;

    IF gb_debug THEN
     log_msg('get_tl_code_blocage 999 : vv_code_blocage = '||vv_code_blocage);
    END IF;

    RETURN vv_code_blocage;

  EXCEPTION
   WHEN OTHERS THEN
    IF gb_debug THEN
     log_msg('get_tl_code_blocage EEE : '||SQLERRM);
    END IF;
    RETURN 'CODE BLOCAGE INCONNU';
  END get_tl_code_blocage;

----------------------------------------------------------------------------
--  Nom           : GET_INFOS_CDE
--  Description   : fonction qui retourne le numero de commande
--
--  PARAMETRES :
--    pn_invoice_id  invoice_id
----------------------------------------------------------------------------
FUNCTION get_infos_cde(pn_invoice_id IN ap_invoices_all.invoice_id%TYPE) RETURN po_headers.segment1%TYPE IS
  vv_num_cde po_headers.segment1%TYPE;
BEGIN
  IF gb_debug THEN
    log_msg('get_infos_cde 000 : pn_invoice_id = '||pn_invoice_id);
  END IF;

  SELECT DISTINCT
   ph.segment1
  INTO
   vv_num_cde
  FROM
   ap_invoice_distributions_all   aid,
   po_distributions_all           pd,
   po_headers_all                 ph
  WHERE
   --AID
   aid.invoice_id             = pn_invoice_id
   AND aid.line_type_lookup_code != 'TAX'
   --PD
   AND aid.po_distribution_id = pd.po_distribution_id
   --PH
   AND ph.po_header_id = pd.po_header_id
  ;

  IF gb_debug THEN
    log_msg('get_infos_cde 999 : vv_num_cde = '||vv_num_cde);
  END IF;

  RETURN vv_num_cde;

EXCEPTION
 WHEN OTHERS THEN
  IF gb_debug THEN
    log_msg('get_infos_cde EEE : '||SQLERRM);
  END IF;
  RETURN '&nbsp;';
END get_infos_cde;

----------------------------------------------------------------------------
--  Nom           : GET_INFOS_DA
--  Description   : fonction qui retourne le numero de DA
--
--  PARAMETRES :
--    pv_num_cde  numero de commande
----------------------------------------------------------------------------
FUNCTION get_infos_da(pv_num_cde IN po_headers.segment1%TYPE) RETURN po_requisition_headers.segment1%TYPE IS
  vv_num_da po_requisition_headers.segment1%TYPE;
BEGIN

  IF gb_debug THEN
    log_msg('get_infos_da 000 : pv_num_cde = '||pv_num_cde);
  END IF;

  SELECT DISTINCT
   prh.SEGMENT1
  INTO
   vv_num_da
  FROM
   po_distributions_all           pd,
   po_headers_all                 ph,
   po_requisition_headers_all     prh,
   po_req_distributions_all       prd,
   po_requisition_lines_all       prl
  WHERE
   --PH
   ph.segment1 = pv_num_cde
   --PD
   AND ph.po_header_id = pd.po_header_id
   --PRD
   AND pd.REQ_DISTRIBUTION_ID = prd.DISTRIBUTION_ID
   --PRL
   AND prd.REQUISITION_LINE_ID = prl.REQUISITION_LINE_ID
   --PRH
   AND prl.REQUISITION_HEADER_ID = prh.REQUISITION_HEADER_ID
  ;

  IF gb_debug THEN
    log_msg('get_infos_da 999 : vv_num_da = '||vv_num_da);
  END IF;

  RETURN vv_num_da;

EXCEPTION
 WHEN OTHERS THEN
  IF gb_debug THEN
    log_msg('get_infos_da EEE : '||SQLERRM);
  END IF;
  RETURN '&nbsp;';
END get_infos_da;

----------------------------------------------------------------------------
--  Nom           : GET_CONVERT_HTML
--  Description   : fonction qui retourne une chaine de caractere html
--
--  PARAMETRES :
--    pv_chaine  chaine de caractere en entrée
----------------------------------------------------------------------------
FUNCTION get_convert_html(pv_chaine IN VARCHAR2) RETURN VARCHAR2 IS
    vv_out  VARCHAR2(4000);
BEGIN

   vv_out := pv_chaine;

   FOR i IN ga_convert_html.FIRST..ga_convert_html.LAST LOOP
    vv_out := REPLACE(vv_out,chr(i),ga_convert_html(i));
   END LOOP;

   RETURN vv_out;

EXCEPTION
 WHEN OTHERS THEN
  IF gb_debug THEN
    log_msg('get_convert_html EEE : Erreur conversion : '||SQLERRM);
  END IF;
  RETURN pv_chaine;
END get_convert_html;


---------------------------------------------------------------------------
--  Nom           : denormalize_notification
--  Description   : Procedure denormalize_notification
--
--PARAMETRES :
--  pv_errbuf   Entree/Sortie          message d'erreur
--  VALEUR RETOURNEE :  pn_retcode
--Valeurs possibles : 0=normal, 1=warning, 2=erreur
----------------------------------------------------------------------------
    PROCEDURE denormalize_notification (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    ) IS
      cursor c_nid is
      select notification_id
        from wf_notifications
       where subject is null
         and message_type='DKA_CSP'
         and status='OPEN'
         and message_name   != 'DKA_MSG_SYSADMIN'
     union
      select notification_id
        from wf_notifications wn
       where wn.subject is null
        and wn.status = 'OPEN'
        AND wn.message_type IN ('DKA_POAP','REQAPPRV')
        AND wn.message_name != 'DKA_MSG_SYSADMIN'
        AND wn.message_name in ('PO_REQ_APPROVE','PO_PO_APPROVE')
        ;


       TYPE    T_NID  IS TABLE OF wf_notifications.notification_id%TYPE;
      vv_nid   T_NID;

    BEGIN

      IF gb_debug THEN
        log_msg('init 000');
      END IF;

     OPEN c_nid;
     FETCH c_nid BULK COLLECT INTO vv_nid;
     CLOSE c_nid;

     IF gb_debug THEN
      log_msg('denormalize_notification 001 : open/close cursor');
     END IF;

    IF vv_nid.FIRST IS NOT NULL THEN
      FOR i IN vv_nid.FIRST..vv_nid.LAST LOOP
       BEGIN

       IF gb_debug THEN
       log_msg('denormalize_notification 002 : denormalize notification id: '|| vv_nid(i));
       END IF;

       wf_notification.Denormalize_Notification(vv_nid(i));

       end;
       END loop;

     END IF;

     IF gb_debug THEN
       log_msg('init 999');
     END IF;

    EXCEPTION
      WHEN OTHERS THEN
         pv_errbuf  := 'Erreur procedure denormalize_notification '|| SQLERRM;
         pn_retcode := 2;
         log_msg(pv_errbuf);
    END denormalize_notification;

----------------------------------------------------------------------------
--  Nom           : INIT
--  Description   : Procedure d'initialisation
--
--PARAMETRES :
--  pv_errbuf   Entree/Sortie          message d'erreur
--  VALEUR RETOURNEE :  pn_retcode
--Valeurs possibles : 0=normal, 1=warning, 2=erreur
----------------------------------------------------------------------------
    PROCEDURE init (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    ) IS
      vv_param     VARCHAR2(100);
      rec_param   dka_parameters%ROWTYPE;
      e_err_param EXCEPTION;
    BEGIN
      gn_erreur := 0;
      gn_traite := 0;

      IF gb_debug THEN
        log_msg('init 000');
      END IF;

      --Recuperation des parametres de connexion
      vv_param := 'SMTP_CONNECTION';
      Dka_Tools_Pkg.get_parameter ('DKA_SAPSUIVI_NOTIF', 'SMTP_CONNECTION', rec_param, pv_errbuf, pn_retcode);
      gv_conn := rec_param.varchar2_value;

      log_msg('Connexion SMTP : '||gv_conn);

      IF pn_retcode != 0 THEN
        RAISE e_err_param;
      END IF;

      --Recuperation du nombre de reconduction max
      vv_param := 'EXPEDITEUR_MAIL';
      Dka_Tools_Pkg.get_parameter ('DKA_SAPSUIVI_NOTIF', 'EXPEDITEUR_MAIL', rec_param, pv_errbuf, pn_retcode);
      gv_expediteur := rec_param.varchar2_value;

      log_msg('Expediteur mail : '||gv_expediteur);

      IF pn_retcode != 0 THEN
        RAISE e_err_param;
      END IF;

     --Remplissage tableau de conversion
     ga_convert_html(161) := '&iexcl;';
     ga_convert_html(162) := '&cent;';
     ga_convert_html(163) := '&pound;';
     ga_convert_html(164) := '&curren;';
     ga_convert_html(165) := '&yen;';
     ga_convert_html(166) := '&brvbar;';
     ga_convert_html(167) := '&sect;';
     ga_convert_html(168) := '&uml;';
     ga_convert_html(169) := '&copy;';
     ga_convert_html(170) := '&ordf;';
     ga_convert_html(171) := '&laquo;';
     ga_convert_html(172) := '&not;';
     ga_convert_html(173) := '&shy;';
     ga_convert_html(174) := '&reg;';
     ga_convert_html(175) := '&macr;';
     ga_convert_html(176) := '&deg;';
     ga_convert_html(177) := '&plusmn;';
     ga_convert_html(178) := '&sup2;';
     ga_convert_html(179) := '&sup3;';
     ga_convert_html(180) := '&acute;';
     ga_convert_html(181) := '&micro;';
     ga_convert_html(182) := '&para;';
     ga_convert_html(183) := '&middot;';
     ga_convert_html(184) := '&cedil;';
     ga_convert_html(185) := '&sup1;';
     ga_convert_html(186) := '&ordm;';
     ga_convert_html(187) := '&raquo;';
     ga_convert_html(188) := '&frac14;';
     ga_convert_html(189) := '&frac12;';
     ga_convert_html(190) := '&frac34;';
     ga_convert_html(191) := '&iquest;';
     ga_convert_html(192) := '&Agrave;';
     ga_convert_html(193) := '&Aacute;';
     ga_convert_html(194) := '&Acirc;';
     ga_convert_html(195) := '&Atilde;';
     ga_convert_html(196) := '&Auml;';
     ga_convert_html(197) := '&Aring;';
     ga_convert_html(198) := '&AElig;';
     ga_convert_html(199) := '&Ccedil;';
     ga_convert_html(200) := '&Egrave;';
     ga_convert_html(201) := '&Eacute;';
     ga_convert_html(202) := '&Ecirc;';
     ga_convert_html(203) := '&Euml;';
     ga_convert_html(204) := '&Igrave;';
     ga_convert_html(205) := '&Iacute;';
     ga_convert_html(206) := '&Icirc;';
     ga_convert_html(207) := '&Iuml;';
     ga_convert_html(208) := '&ETH;';
     ga_convert_html(209) := '&Ntilde;';
     ga_convert_html(210) := '&Ograve;';
     ga_convert_html(211) := '&Oacute;';
     ga_convert_html(212) := '&Ocirc;';
     ga_convert_html(213) := '&Otilde;';
     ga_convert_html(214) := '&Ouml;';
     ga_convert_html(215) := '&times;';
     ga_convert_html(216) := '&Oslash;';
     ga_convert_html(217) := '&Ugrave;';
     ga_convert_html(218) := '&Uacute;';
     ga_convert_html(219) := '&Ucirc;';
     ga_convert_html(220) := '&Uuml;';
     ga_convert_html(221) := '&Yacute;';
     ga_convert_html(222) := '&THORN;';
     ga_convert_html(223) := '&szlig;';
     ga_convert_html(224) := '&agrave;';
     ga_convert_html(225) := '&aacute;';
     ga_convert_html(226) := '&acirc;';
     ga_convert_html(227) := '&atilde;';
     ga_convert_html(228) := '&auml;';
     ga_convert_html(229) := '&aring;';
     ga_convert_html(230) := '&aelig;';
     ga_convert_html(231) := '&ccedil;';
     ga_convert_html(232) := '&egrave;';
     ga_convert_html(233) := '&eacute;';
     ga_convert_html(234) := '&ecirc;';
     ga_convert_html(235) := '&euml;';
     ga_convert_html(236) := '&igrave;';
     ga_convert_html(237) := '&iacute;';
     ga_convert_html(238) := '&icirc;';
     ga_convert_html(239) := '&iuml;';
     ga_convert_html(240) := '&eth;';
     ga_convert_html(241) := '&ntilde;';
     ga_convert_html(242) := '&ograve;';
     ga_convert_html(243) := '&oacute;';
     ga_convert_html(244) := '&ocirc;';
     ga_convert_html(245) := '&otilde;';
     ga_convert_html(246) := '&ouml;';
     ga_convert_html(247) := '&divide;';
     ga_convert_html(248) := '&oslash;';
     ga_convert_html(249) := '&ugrave;';
     ga_convert_html(250) := '&uacute;';
     ga_convert_html(251) := '&ucirc;';
     ga_convert_html(252) := '&uuml;';
     ga_convert_html(253) := '&yacute;';
     ga_convert_html(254) := '&thorn;';
     ga_convert_html(255) := '&yuml';

     --GET MESSAGE
     gv_subject     := Dka_Tools_Pkg.get_message('DKA','DKA_SAPSUIVI_NOTIF_SUJET');
     gv_fin_corps   := get_convert_html(Dka_Tools_Pkg.get_message('DKA','DKA_SAPSUIVI_NOTIF_FIN_CORPS'));

     --CONSTRUCTION ENTETE DE TABLEAU
     gv_entete_tableau := get_convert_html(
      cv_table || cv_line ||
      Dka_Tools_Pkg.get_message('DKA','DKA_SAPSUIVI_NOTIF_TIT_TAB_01') || cv_inter ||
      Dka_Tools_Pkg.get_message('DKA','DKA_SAPSUIVI_NOTIF_TIT_TAB_02') || cv_inter ||
      Dka_Tools_Pkg.get_message('DKA','DKA_SAPSUIVI_NOTIF_TIT_TAB_03') || cv_inter ||
      Dka_Tools_Pkg.get_message('DKA','DKA_SAPSUIVI_NOTIF_TIT_TAB_04') || cv_inter ||
      Dka_Tools_Pkg.get_message('DKA','DKA_SAPSUIVI_NOTIF_TIT_TAB_05') || cv_end_line);

     gv_entete_tableau_cde_da := get_convert_html(
      cv_table || cv_line ||
      Dka_Tools_Pkg.get_message('DKA','DKA_SAPSUIVI_NOTIF_TIT_TAB_01') || cv_inter ||
      Dka_Tools_Pkg.get_message('DKA','DKA_SAPSUIVI_NOTIF_TIT_TAB_05') || cv_end_line);

     IF gb_debug THEN
       log_msg('init 999');
     END IF;

    EXCEPTION
      WHEN e_err_param THEN
         pv_errbuf  := 'Erreur parametre '||vv_param||' : '|| SQLERRM;
         pn_retcode := 2;
         log_msg(pv_errbuf);
      WHEN OTHERS THEN
         pv_errbuf  := 'Erreur procedure INIT '|| SQLERRM;
         pn_retcode := 2;
         log_msg(pv_errbuf);
    END init;


-------------------------------------------------------------------------------------
--  Nom           : ENVOI_MAIL
--  Description   : procedure d'envoi de mail
--
--  PARAMETRES    :
--
--  pv_errbuf     IN OUT   message de sortie
--  pn_retcode    OUT      code retour
--  VALEUR RETOURNEE :  pn_retcode
--Valeurs possibles : 0=normal, 1=warning, 2=erreur
------------------------------------------------------------------------------------

    PROCEDURE envoi_mail (
        pv_destinataire IN   VARCHAR2,
        pv_email        IN   VARCHAR2,
        pn_nb_fact      IN   PLS_INTEGER,
        pn_nb_notif     IN   PLS_INTEGER,
        pn_nb_da        IN   PLS_INTEGER,
        pt_tab_bocage   IN   T_LISTE_BLOCAGE,
        pv_errbuf       OUT  VARCHAR2,
        pn_retcode      OUT  NUMBER
    ) IS

      vv_mesg       VARCHAR2( 4000 );
      vc_conn       UTL_SMTP.CONNECTION;

      e_erreur_mail EXCEPTION;

    BEGIN

     IF gb_debug THEN
      log_msg('envoi_mail 000 : pv_destinataire = '||pv_destinataire||chr(10)||
                               'pv_email = '||pv_email||chr(10)||
                               'pn_nb_fact = '||pn_nb_fact||chr(10)||
                               'pn_nb_notif = '||pn_nb_notif||chr(10)||
                               'nb pt_tab_bocage = '||pt_tab_bocage.COUNT);
     END IF;

     --Controle email
     IF pv_email IS NULL THEN
      RAISE e_erreur_mail;
     END IF;

     -- Création et envoi du mail au créateur
     vc_conn:= utl_smtp.open_connection( gv_conn, 25 );

     IF gb_debug THEN
      log_msg('envoi_mail 001 : connection open');
     END IF;

     utl_smtp.helo( vc_conn , gv_conn );
     utl_smtp.mail( vc_conn , gv_expediteur );
     utl_smtp.rcpt( vc_conn , '<'||nvl(gv_mail_test,pv_email)||'>' );
     utl_smtp.open_data(vc_conn);

     IF gb_debug THEN
      log_msg('envoi_mail 002 : open data');
     END IF;

     --vv_mesg:= 'Date: ' || to_char(systimestamp, 'dd Mon yy hh24:mi:ss tzhtzm') || utl_tcp.CRLF ||
	 vv_mesg:= 'Date: ' || to_char(systimestamp, 'dd Mon yyyy hh24:mi:ss tzhtzm','NLS_DATE_LANGUAGE=American') || utl_tcp.CRLF ||
         'From: ' || gv_expediteur || utl_tcp.CRLF ||
         'To: ' || pv_destinataire  || utl_tcp.CRLF ||
         'Subject:' || gv_subject || utl_tcp.CRLF ||
         'Content-Type: text/html;	'|| utl_tcp.CRLF ||
         ' charset="iso-8859-1"' || utl_tcp.CRLF || utl_tcp.CRLF;

     --Entete du message
     utl_smtp.write_data(vc_conn, vv_mesg);


     IF gb_debug THEN
      log_msg('envoi_mail 003 : Entete du message');
     END IF;

     --Corps du message
     --DEBUT

     IF pn_nb_notif != 0 and pn_nb_da != 0 THEN -- QVA 11/03/2011
     vv_mesg := get_convert_html(
                 Dka_Tools_Pkg.get_message('DKA','DKA_SAPSUIVI_NOTIF_DEB_CORPS',
                                           'NBFACTURE',pn_nb_fact,
                                           'NBNOTIF',pn_nb_notif,
                                           'NBDA',pn_nb_da,
                                           'URL_LOGIN',fnd_web_config.WEB_SERVER || 'OA_HTML/AppsLogin' )); -- OBE artf2169874
     ELSIF pn_nb_notif = 0 and pn_nb_da != 0 THEN
        vv_mesg := get_convert_html(
                 Dka_Tools_Pkg.get_message('DKA','DKA_SAPSUIVI_NOTIF_ABSENT_DEB',
                                           'NBDA',pn_nb_da,
                                           'URL_LOGIN',fnd_web_config.WEB_SERVER || 'OA_HTML/AppsLogin' )); -- OBE artf2169874
     ELSIF pn_nb_da = 0 and pn_nb_notif != 0 THEN
        vv_mesg := get_convert_html(
                 Dka_Tools_Pkg.get_message('DKA','DKA_SAPSUIVI_DA_ABSENT_DEB',
                                           'NBFACTURE',pn_nb_fact,
                                           'NBNOTIF',pn_nb_notif,
                                           'URL_LOGIN',fnd_web_config.WEB_SERVER || 'OA_HTML/AppsLogin' )); -- OBE artf2169874
     END IF;

     utl_smtp.write_data(vc_conn, vv_mesg);

     IF gb_debug THEN
      log_msg('envoi_mail 004 : debut du message');
     END IF;

     --BOUCLE BLOCAGE
     IF pt_tab_bocage.COUNT > 0 THEN
      FOR i IN pt_tab_bocage.FIRST..pt_tab_bocage.LAST LOOP
      IF pt_tab_bocage(i).nom_blocage != 'Liste des DA et commandes a approuver' THEN -- QVA 11/03/2011
        vv_mesg := cv_saut_ligne|| i || '. ' ||
                   Dka_Tools_Pkg.get_message('DKA','DKA_SAPSUIVI_NOTIF_CODE_BLOC') ||
                   get_convert_html(get_tl_code_blocage(pt_tab_bocage(i).nom_blocage)) || cv_saut_ligne;
        utl_smtp.write_data(vc_conn, vv_mesg);

        utl_smtp.write_data(vc_conn, gv_entete_tableau);
        ELSE
        vv_mesg := cv_saut_ligne|| i || '. ' ||
                   get_convert_html('Liste des DA et commandes a approuver') || cv_saut_ligne;
        utl_smtp.write_data(vc_conn, vv_mesg);

        utl_smtp.write_data(vc_conn, gv_entete_tableau_cde_da);
      END IF; -- QVA 11/03/2011

        IF gb_debug THEN
         log_msg('envoi_mail 005 : ECRITURE BLOCAGE');
        END IF;

        --BOUCLE SUR LES LIGNES DE BLOCAGE
        IF pt_tab_bocage(i).tab_blocage.COUNT > 0 THEN
          FOR j IN pt_tab_bocage(i).tab_blocage.FIRST..pt_tab_bocage(i).tab_blocage.LAST LOOP
            IF gb_debug THEN
             log_msg('envoi_mail 006 : ECRITURE LIGNE BLOCAGE');
            END IF;
            utl_smtp.write_data(vc_conn,pt_tab_bocage(i).tab_blocage(j));
          END LOOP;
        ELSE
         IF gb_debug THEN
          log_msg('envoi_mail 007 : PAS DE LIGNE DE BLOCAGE');
         END IF;
         utl_smtp.write_data(vc_conn, cv_gd_line||
                                      cv_saut_ligne||'<h2>PAS DE LIGNE DE BLOCAGE</h2>'||cv_saut_ligne||
                                      cv_end_line||cv_end_table);
        END IF;

        utl_smtp.write_data(vc_conn, cv_end_table);

      END LOOP;

     ELSE
      IF gb_debug THEN
       log_msg('envoi_mail 008 : PAS DE BLOCAGE');
      END IF;
      utl_smtp.write_data(vc_conn, cv_saut_ligne||'<h1>PAS DE BLOCAGE</h1>'||cv_saut_ligne);
     END IF;

     --FIN
     utl_smtp.write_data(vc_conn, gv_fin_corps);

     IF gb_debug THEN
      log_msg('envoi_mail 009 : Fin du message');
     END IF;

     utl_smtp.close_data(vc_conn);
     utl_smtp.quit( vc_conn );

     IF gb_debug THEN
      log_msg('envoi_mail 010 : close / quit');
     END IF;

     log_msg('Mail envoye a : '|| pv_destinataire);

     IF gb_debug THEN
      log_msg('envoi_mail 999');
     END IF;

    EXCEPTION
      WHEN e_erreur_mail THEN
         pv_errbuf  := 'L''adresse mail n''est pas renseignée : '||pv_destinataire;
         pn_retcode := 2;
         log_msg(pv_errbuf);
      WHEN OTHERS THEN
         --STOP MAIL
         utl_smtp.close_data(vc_conn);
         utl_smtp.quit( vc_conn );

         pv_errbuf  := 'Erreur procedure ENVOI_MAIL '|| SQLERRM;
         pn_retcode := 2;
         log_msg(pv_errbuf);
    END envoi_mail;


-------------------------------------------------------------------------------------
--  Nom           : ENVOI_ALL_MAIL
--  Description   :
--
--  PARAMETRES    :
--    pv_errbuf       Sortie
--    pv_retcode      Sortie

--  VALEUR RETOURNEE :
--     Description       : code retour de validite
--     Valeurs possibles : 0: OK, 2: erreur ou code erreur ORA
------------------------------------------------------------------------------------

    PROCEDURE envoi_all_mail (
        pv_errbuf       OUT      VARCHAR2,
        pn_retcode      OUT      NUMBER
    ) IS

     CURSOR cur_select IS
      SELECT
       pap.full_name ||' <' ||
       trim(nvl(pap.email_address,fu.email_address))||'>'  FULL_ADDRESS,
       trim(nvl(pap.email_address,fu.email_address)) EMAIL_ADDRESS,
       wna.text_value                                CODE_BLOCAGE,
       substr(wn.subject,1,instr(wn.subject,':')-2)  SUBJECT,
       pv.vendor_name                                VENDOR_NAME,
       to_char(wn.begin_date,'dd/mm/yyyy')           DATE_BLOCAGE,
       ai.invoice_id                                 INVOICE_ID,
       wn.notification_id                            NOTIFICATION_ID,
       wn.context                                    CONTEXT,
       wn.recipient_role                             RECIPIENT_ROLE,
       wn.message_name                               MESSAGE_NAME,
       pap.person_id
      FROM
       wf_notifications           wn,
       wf_notification_attributes wna,
       fnd_user                   fu,
       --per_all_people_f           pap, --RBE artf2376257
       per_people_v7              pap, --RBE artf2376257
       per_all_assignments_f      paa,
       per_jobs                   pj,
       ap_invoices_all            ai,
       ap_suppliers               pv
      WHERE
       --WN
       wn.status      = 'OPEN'
       AND wn.message_type    = 'DKA_CSP'
       AND wn.message_name   != 'DKA_MSG_SYSADMIN' -- on ne selectionne pas les messages pour l'admin
       --WNA
       AND wn.notification_id = wna.notification_id
       AND wna.name           = 'TYPE_NOTIF'
       --FU
       AND wn.recipient_role = fu.user_name
       --PAP
       AND pap.person_id = fu.employee_id
       --PAA
       AND paa.person_id = pap.person_id
       AND SYSDATE         BETWEEN nvl(paa.effective_start_date,SYSDATE)
                           AND nvl(paa.effective_end_date,SYSDATE)
       --PJ
       AND pj.JOB_ID = paa.job_id
       AND nvl(pj.ATTRIBUTE2,'NON') = 'NON'
       --AI
       AND ai.invoice_id = substr(wn.context,instr(wn.context,':')+1,instr(wn.context,'_',1,2)-(instr(wn.context,':')+1))
       --PV
       AND ai.VENDOR_ID              = pv.vendor_id
       UNION
       SELECT DISTINCT               -- SFA 27/09/2018
       pap.full_name ||' <' ||
       trim(nvl(pap.email_address,fu.email_address))||'>'  FULL_ADDRESS,
       trim(nvl(pap.email_address,fu.email_address)) EMAIL_ADDRESS,
       '',
       'DA_CDE',
       '',
       '',
       null,
       null,
       '',
       '',
       '',
       pap.person_id
      FROM
       wf_notifications           wn,
       wf_notification_attributes wna,
       fnd_user                   fu,
       --per_all_people_f           pap, --RBE artf2376257
       per_people_v7              pap, --RBE artf2376257
       per_all_assignments_f      paa,
       per_jobs                   pj
      WHERE
       --WN
       wn.status      = 'OPEN'
        AND wn.message_type    IN ('DKA_POAP','REQAPPRV')
        --AND wn.message_name   != 'DKA_MSG_SYSADMIN' -- on ne selectionne pas les messages pour l'admin  -- SFA 27/09/2018
		AND wn.message_name IN ('PO_REQ_APPROVE_SIMPLE_JRAD','PO_PO_APPROVE')    --('PO_REQ_APPROVE','PO_PO_APPROVE')     -- SFA 27/09/2018
       --WNA
       AND wn.notification_id = wna.notification_id
       AND wna.name = 'DOCUMENT_TYPE_DISP'
       --AND wna.text_value IN ('Demande d''achat','Commande standard')                                                     -- SFA 27/09/2018
	   AND wna.text_value IN (  'Commande standard','Standard Purchase Order', 'Demande d''achat','Purchase Requisition')  -- SFA 27/09/2018
       --FU
       AND wn.recipient_role = fu.user_name
       --PAP
       AND pap.person_id = fu.employee_id
       --PAA
       AND paa.person_id = pap.person_id
       AND SYSDATE         BETWEEN nvl(paa.effective_start_date,SYSDATE)
                               AND nvl(paa.effective_end_date,SYSDATE)
       --PJ
       AND pj.JOB_ID = paa.job_id
       AND nvl(pj.ATTRIBUTE2,'NON') = 'NON'
      ORDER BY 1,2,3,4;

     CURSOR cur_select_da(pn_person_id NUMBER) IS   -- QVA 11/03/2011
      SELECT
       --pap.full_name ||' <' ||                                                  -- SFA 27/09/2018
       --trim(nvl(pap.email_address,fu.email_address))||'>'  FULL_ADDRESS,        -- SFA 27/09/2018
       --trim(nvl(pap.email_address,fu.email_address)) EMAIL_ADDRESS,             -- SFA 27/09/2018
       --wna.text_value                                CODE_BLOCAGE,                     -- OBE artf3024115
       DECODE(wna.text_value,'Standard Purchase Order','Commande standard','Purchase Requisition','Demande d''achat', wna.text_value)  CODE_BLOCAGE,  --replace(wna.text_value,'Purchase Requisition','Demande d''achat')   CODE_BLOCAGE, -- OBE artf3024115  -- SFA 27/09/2018
      -- substr(wn.subject,1,instr(wn.subject,':')-2)  SUBJECT,               -- SFA 27/09/2018
       to_char(wn.begin_date,'dd/mm/yyyy')             DATE_BLOCAGE,
       --wn.notification_id                            NOTIFICATION_ID,       -- SFA 27/09/2018
       --wn.context                                    CONTEXT,               -- SFA 27/09/2018
       --wn.recipient_role                             RECIPIENT_ROLE,        -- SFA 27/09/2018
       --wn.message_name                               MESSAGE_NAME,          -- SFA 27/09/2018
	   --< OBE artf3024115
       /*
	   case when wna.text_value = 'Demande d''achat' THEN substr(wn.subject,29,instr(wn.subject,'de',1,2)-29)
            when wna.text_value = 'Commande standard' THEN substr(wn.subject,20,instr(wn.subject,',')-20) END num_cde_da,*/    -- SFA 27/08/2018

        (SELECT wna1.text_value FROM wf_notification_attributes wna1 WHERE wn.notification_id = wna1.notification_id and wna1.name = 'DOCUMENT_NUMBER') num_cde_da,     -- SFA 27/08/2018

	   /*
	   case when wna.text_value = 'Demande d''achat' THEN substr(wn.subject,instr(wn.subject,'(')+1,instr(wn.subject,')')-instr(wn.subject,'(')-5)
            when wna.text_value = 'Commande standard' THEN substr(wn.subject,instr(wn.subject,'EUR')+5,instr(wn.subject,'.')-instr(wn.subject,'EUR')-2) END montant*/

	 --case when wna.text_value in ('Demande d''achat', 'Purchase Requisition') THEN prha.segment1         -- SFA 27/08/2018
             --when wna.text_value = 'Commande standard' THEN pha.segment1 END num_cde_da,                 -- SFA 27/08/2018
     --case when wna.text_value in ('Demande d''achat', 'Purchase Requisition')  THEN substr(wn.subject,instr(wn.subject,'(')+1,instr(wn.subject,')')-instr(wn.subject,'(')-5)      -- SFA 27/08/2018
             --when wna.text_value = 'Commande standard' THEN substr(wn.subject,instr(wn.subject,'EUR')+5,instr(wn.subject,'.')-instr(wn.subject,'EUR')-2) END montant		        -- SFA 27/08/2018

	   (SELECT wna2.text_value FROM wf_notification_attributes wna2 WHERE wn.notification_id = wna2.notification_id and wna2.name = 'TOTAL_AMOUNT_DSP') montant,
       --> OBE artf3024115
       wna.text_value 
      FROM
       wf_notifications           wn,
       wf_notification_attributes wna,
       fnd_user                   fu
       --per_all_people_f           pap, --RBE artf2376257
	   --- 2021/09/16 NBO artf07478744 : INC0577446 - Nous constatons une dérive sur la durée du traitement DKA : Suivi des notifications ouvertes
       --per_people_v7              pap, --RBE artf2376257
       --per_all_assignments_f      paa,
       --per_jobs                   pj
       --,                                                    -- SFA 27/09/2018
       --po_headers_all pha,               -- OBE artf3024115 -- SFA 27/09/2018
       --po_requisition_headers_all prha   -- OBE artf3024115 -- SFA 27/09/2018
      WHERE
       --WN
       wn.status      = 'OPEN'
       AND wn.message_type    IN ('DKA_POAP','REQAPPRV')
       --AND wn.message_name   != 'DKA_MSG_SYSADMIN'  -- on ne selectionne pas les messages pour l'admin           -- SFA 27/09/2018
       --AND wn.message_name IN ('PO_REQ_APPROVE','PO_PO_APPROVE')     -- OBE artf3024115            -- SFA 27/09/2018
	   AND wn.message_name IN ('PO_REQ_APPROVE_SIMPLE_JRAD','PO_PO_APPROVE') -- OBE artf3024115  -- SFA 27/09/2018
       --WNA
       AND wn.notification_id = wna.notification_id
       AND wna.name = 'DOCUMENT_TYPE_DISP'
       --AND wna.text_value IN ('Demande d''achat','Commande standard')                       -- OBE artf3024115
       --AND wna.text_value IN ('Demande d''achat','Commande standard', 'Purchase Requisition') -- OBE artf3024115        -- SFA 27/09/2018
		--AND wna.text_value IN  ( 'Commande standard','Standard Purchase Order','Demande d''achat','Purchase Requisition') -- SFA 27/09/2018

       --FU
       AND wn.recipient_role = fu.user_name
       --PAP
	   --- 2021/09/16 NBO artf07478744 : INC0577446 - Nous constatons une dérive sur la durée du traitement DKA : Suivi des notifications ouvertes
       --AND pap.person_id = fu.employee_id
       AND fu.employee_id = pn_person_id
       --AND pap.person_id = pn_person_id
       --PAA
       --AND paa.person_id = pap.person_id
       --AND SYSDATE         BETWEEN nvl(paa.effective_start_date,SYSDATE)
       --                        AND nvl(paa.effective_end_date,SYSDATE)
       --PJ
       --AND pj.JOB_ID = paa.job_id
       --AND nvl(pj.ATTRIBUTE2,'NON') = 'NON'

      --and substr(replace(wn.item_key,'-','_'), 1, instr(replace(wn.item_key,'-','_'), '_', 1, 1) -1) = pha.po_header_id(+)           -- OBE artf3024115 -- SFA 27/09/2018
      --and substr(replace(wn.item_key,'-','_'), 1, instr(replace(wn.item_key,'-','_'), '_', 1, 1) -1) = prha.requisition_header_id(+) -- OBE artf3024115  -- SFA 27/09/2018
      ORDER BY 2;   --ORDER BY 6;        -- SFA 27/09/2018



     --CURSEUR
     TYPE    T_CURSOR_TAB  IS TABLE OF cur_select%ROWTYPE;
     vt_select_tab   T_CURSOR_TAB;

     rec_select_da     cur_select_da%ROWTYPE;

     --TYPE LOCAL
     TYPE T_INVOICE IS TABLE OF VARCHAR2(1) INDEX BY BINARY_INTEGER;

     vn_retcode    NUMBER;
     vv_errbuf     VARCHAR2(2000);

     vv_email        per_people_f.EMAIL_ADDRESS%TYPE;
     vv_full_address VARCHAR2(4000);
     vn_person_id    NUMBER(10);

     --Cpt
     vt_tab_invoice T_INVOICE;
     vn_cpt_fact    PLS_INTEGER;
     vn_cpt_notif   PLS_INTEGER;
     vn_cpt_da      PLS_INTEGER;

     --Blocages
     vv_ligne      VARCHAR2(4000);
     vv_blocage    VARCHAR2(100);
     vt_lg_blocage T_BLOCAGE_TAB;
     vr_blocage    R_BLOCAGE;
     vt_tab_blocage T_LISTE_BLOCAGE;

     e_send_mail   EXCEPTION;


    BEGIN
     vn_cpt_fact  := 0;
     vn_cpt_notif := 0;
     vn_cpt_da    := 0;

     IF gb_debug THEN
      log_msg('envoi_mail 000');
     END IF;

     OPEN cur_select;
	 --- 2021/08/30 NBO artf07478744 : INC0577446 - Nous constatons une dérive sur la durée du traitement DKA : Suivi des notifications ouvertes
     LOOP
       FETCH cur_select BULK COLLECT INTO vt_select_tab LIMIT 10000;
       EXIT WHEN vt_select_tab.COUNT = 0;

       IF gb_debug THEN
        log_msg('envoi_mail 001 : open/close cursor');
       END IF;

       IF vt_select_tab.FIRST IS NOT NULL THEN
        FOR i IN vt_select_tab.FIRST..vt_select_tab.LAST LOOP
         BEGIN

           -- ne pas tester avec vv_email/email_address car peut etre null
           IF nvl(vv_full_address,vt_select_tab(i).FULL_ADDRESS) != vt_select_tab(i).FULL_ADDRESS  THEN

              --AJOUT DERNIER RECORD
             IF gb_debug THEN
              log_msg('envoi_mail 002 : ajout dernier record');
             END IF;

             IF vv_blocage != 'Liste des DA et commandes a approuver' THEN -- QVA 11/03/2011
              vr_blocage.nom_blocage := vv_blocage;
              vr_blocage.tab_blocage := vt_lg_blocage;

              vt_tab_blocage(vt_tab_blocage.COUNT+1) := vr_blocage;

              vt_lg_blocage.DELETE;
                vv_blocage      := NULL;
             END IF;

             IF gb_debug THEN
              log_msg('Passage aux DA');
              log_msg('vn_person_id : '||vn_person_id);
             END IF;

             OPEN cur_select_da(vn_person_id); -- QVA 11/03/2011
             LOOP
                 FETCH cur_select_da INTO rec_select_da;
                 EXIT WHEN cur_select_da%NOTFOUND;
                 IF rec_select_da.TEXT_VALUE IN ( 'Commande standard','Standard Purchase Order','Demande d''achat','Purchase Requisition') THEN
                   vn_cpt_da := vn_cpt_da + 1;

                   vv_ligne := cv_line || 'La '||rec_select_da.code_blocage || ' '
                                       || rec_select_da.num_cde_da || ' d''un montant de '
                                       || rec_select_da.montant || ' nécessite votre approbation.'
                                       || cv_inter||rec_select_da.date_blocage ||cv_end_line;
                   vt_lg_blocage(vt_lg_blocage.COUNT+1) := vv_ligne;
                 END IF;
             END LOOP;
             CLOSE cur_select_da;

             IF gb_debug THEN
              log_msg('Nombre de DA : '||vn_cpt_da);
             END IF;

             IF vn_cpt_da != 0 THEN -- QVA 11/03/2011
                vr_blocage.nom_blocage := 'Liste des DA et commandes a approuver';
                vr_blocage.tab_blocage := vt_lg_blocage;

                vt_tab_blocage(vt_tab_blocage.COUNT+1) := vr_blocage;
             END IF;

             IF gb_debug THEN
              log_msg('envoi_mail 003 : envoi mail');
             END IF;

             -- 130209 CDE Ajout condition pour envoi mail seulement quand blocage
             IF vn_cpt_notif != 0 or vn_cpt_da != 0 -- QVA 11/03/2011
             THEN
                 --ENVOI MAIL
                 log_msg('Envoi mail...');
                 envoi_mail(vv_full_address,
                            vv_email,
                            vn_cpt_fact,
                            vn_cpt_notif,
                            vn_cpt_da,
                            vt_tab_blocage,
                            vv_errbuf,
                            vn_retcode);
                 IF vn_retcode != 0 THEN
                    RAISE e_send_mail;
                 END IF;
                 log_msg('Envoi mail OK...');
             ELSE
                 log_msg('Aucun mail envoyé ... Pas de notification');
             END IF;

             IF gb_debug THEN
              log_msg('envoi_mail 004 : reinit variable locale');
             END IF;

             --REINIT
             vn_cpt_fact   := 0;
             vn_cpt_notif  := 0;
             vn_cpt_da     := 0; -- QVA 11/03/2011
             vt_tab_blocage.DELETE;
             vt_lg_blocage.DELETE;
             vt_tab_invoice.DELETE;
             vv_email        := vt_select_tab(i).EMAIL_ADDRESS;
             vv_full_address := vt_select_tab(i).FULL_ADDRESS;
             vn_person_id := vt_select_tab(i).person_id;
             vv_blocage      := NULL;

             gn_traite := gn_traite + 1 ;
           END IF;


           IF gb_debug THEN
            log_msg('envoi_mail 005 : contruction du mail');
           END IF;

           --CONSTRUCTION DU MAIL
           vv_email        := vt_select_tab(i).EMAIL_ADDRESS;
           vv_full_address := vt_select_tab(i).FULL_ADDRESS;
           vn_person_id    := vt_select_tab(i).person_id;

           IF gb_debug THEN
            log_msg('envoi_mail 006 : incr nb notif');
           END IF;

           IF vt_select_tab(i).SUBJECT IS NOT NULL THEN
            IF vt_select_tab(i).SUBJECT != 'DA_CDE' THEN
             --INCR NB NOTIF
             vn_cpt_notif  := vn_cpt_notif + 1;

             IF gb_debug THEN
              log_msg('envoi_mail 007 : incr nb facture');
             END IF;
             --INCR NB FACT
             IF NOT vt_tab_invoice.EXISTS(vt_select_tab(i).invoice_id) THEN
              vt_tab_invoice(vt_select_tab(i).invoice_id) := '#';
              vn_cpt_fact := vn_cpt_fact + 1;
             END IF;

             --REMPLISSAGE TABLEAU DES BLOCAGES
             IF nvl(vv_blocage,vt_select_tab(i).CODE_BLOCAGE) != vt_select_tab(i).CODE_BLOCAGE THEN
               IF gb_debug THEN
                log_msg('envoi_mail 008 : contruction du record');
               END IF;

               --CONTRUCTION DU RECORD
               vr_blocage.nom_blocage := vv_blocage;
               vr_blocage.tab_blocage := vt_lg_blocage;

               vt_tab_blocage(vt_tab_blocage.COUNT+1) := vr_blocage;

               vv_blocage    := vt_select_tab(i).CODE_BLOCAGE;
               vt_lg_blocage.DELETE;

             END IF;

             IF gb_debug THEN
              log_msg('envoi_mail 009 : contruction des lignes blocages');
             END IF;

             vv_blocage := vt_select_tab(i).CODE_BLOCAGE;

             --CONTRUCTION DES LIGNES
             vv_ligne := cv_line ||vt_select_tab(i).SUBJECT||
                         cv_inter||get_infos_cde(vt_select_tab(i).invoice_id)||
                         cv_inter||vt_select_tab(i).VENDOR_NAME||
                         cv_inter||get_infos_da(get_infos_cde(vt_select_tab(i).invoice_id))||
                         cv_inter||vt_select_tab(i).DATE_BLOCAGE||cv_end_line;

             vv_ligne := get_convert_html(vv_ligne);

             vt_lg_blocage(vt_lg_blocage.COUNT+1) := vv_ligne;
            END IF;
           ELSE --erreur dans la notif

             log_msg('Erreur pour la notification : id             = '||vt_select_tab(i).NOTIFICATION_ID||chr(10)||
                     '                              message_name   = '||vt_select_tab(i).MESSAGE_NAME||chr(10)||
                     '                              context        = '||vt_select_tab(i).CONTEXT||chr(10)||
                     '                              recipient_role = '||vt_select_tab(i).RECIPIENT_ROLE||chr(10)||
                     '                              full_address   = '||vt_select_tab(i).FULL_ADDRESS||chr(10)||
                     '                              date_notif     = '||vt_select_tab(i).DATE_BLOCAGE||chr(10)
                    );
             --avertissement
             pn_retcode := 1;
             gn_erreur := gn_erreur + 1 ;
           END IF;

           IF gb_debug THEN
            log_msg('envoi_mail 010 : ligne suivante');
           END IF;

         EXCEPTION
          WHEN e_send_mail THEN
           pv_errbuf  := 'Erreur dans la procedure d''envoi des mails : '|| SQLERRM;
           pn_retcode := 1;
           log_msg(pv_errbuf);
           --REINIT
           vn_cpt_fact   := 0;
           vn_cpt_notif  := 0;
           vn_cpt_da     := 0;
           vt_tab_blocage.DELETE;
           vt_lg_blocage.DELETE;
           vt_tab_invoice.DELETE;
           vv_email        := vt_select_tab(i).EMAIL_ADDRESS;
           vv_full_address := vt_select_tab(i).FULL_ADDRESS;
           vn_person_id    := vt_select_tab(i).person_id;
           vv_blocage      := NULL;
           --CONTINUE
           gn_erreur := gn_erreur + 1 ;
          WHEN OTHERS THEN
           pv_errbuf  := 'Erreur dans la boucle : '|| SQLERRM;
           pn_retcode := 1;
           log_msg(pv_errbuf);
           --CONTINUE
           gn_erreur := gn_erreur + 1 ;
         END;
        END LOOP;

        --AJOUT DERNIER RECORD
        IF gb_debug THEN
         log_msg('envoi_mail 011 : ajout dernier record');
        END IF;

        IF vv_blocage != 'Liste des DA et commandes a approuver' THEN     -- QVA 11/03/2011
          vr_blocage.nom_blocage := vv_blocage;
          vr_blocage.tab_blocage := vt_lg_blocage;

          vt_tab_blocage(vt_tab_blocage.COUNT+1) := vr_blocage;
        END IF;

        IF gb_debug THEN
         log_msg('envoi_mail 012 : envoi dernier mail');
        END IF;

        vt_lg_blocage.DELETE;
        vv_blocage      := NULL;


        OPEN cur_select_da(vn_person_id); -- QVA 11/03/2011
             LOOP
                 FETCH cur_select_da INTO rec_select_da;
                 EXIT WHEN cur_select_da%NOTFOUND;
                 IF  rec_select_da.TEXT_VALUE IN ( 'Commande standard','Standard Purchase Order','Demande d''achat','Purchase Requisition') THEN
                   vn_cpt_da := vn_cpt_da + 1;

                   vv_ligne := cv_line || 'La '||rec_select_da.code_blocage || ' '
                                       || rec_select_da.num_cde_da || ' d''un montant de '
                                       || rec_select_da.montant || ' nécessite votre approbation.'
                                       || cv_inter||rec_select_da.date_blocage ||cv_end_line;
                   vt_lg_blocage(vt_lg_blocage.COUNT+1) := vv_ligne;
                 END IF;
             END LOOP;
        CLOSE cur_select_da;    -- QVA 11/03/2011

        IF vn_cpt_da != 0 THEN       -- QVA 11/03/2011
             vr_blocage.nom_blocage := 'Liste des DA et commandes a approuver';
             vr_blocage.tab_blocage := vt_lg_blocage;

             vt_tab_blocage(vt_tab_blocage.COUNT+1) := vr_blocage;
        END IF;

        IF vn_cpt_notif != 0 or vn_cpt_da != 0
        THEN
            --ENVOI DERNIER MAIL
            log_msg('Envoi mail...');
            envoi_mail(vv_full_address,
                       vv_email,
                       vn_cpt_fact,
                       vn_cpt_notif,
                       vn_cpt_da,
                       vt_tab_blocage,
                       vv_errbuf,
                       vn_retcode);
            IF vn_retcode != 0 THEN
               RAISE e_send_mail;
            END IF;
            log_msg('Envoi mail OK...');
        ELSE
            log_msg('Aucun mail envoyé ... Pas de notification');
        END IF;

        gn_traite := gn_traite + 1 ;

       ELSE
        pv_errbuf := 'Aucune données a traiter';
        log_msg(pv_errbuf);
       END IF;

       IF  pn_retcode = 1 THEN
        pv_errbuf := 'Erreur dans l''envoi des mails';
        log_msg(pv_errbuf);
       END IF;

       IF gb_debug THEN
        log_msg('envoi_mail 999');
       END IF;

	 --- 2021/08/30 NBO artf07478744 : INC0577446 - Nous constatons une dérive sur la durée du traitement DKA : Suivi des notifications ouvertes
     END LOOP;
     CLOSE cur_select;

    EXCEPTION
      WHEN e_send_mail THEN
         pv_errbuf  := 'Erreur dans la procedure d''envoi des mails : '|| SQLERRM;
         pn_retcode := 1;
         log_msg(pv_errbuf);
         --CONTINUE
         gn_erreur := gn_erreur + 1 ;
      WHEN OTHERS THEN
         pv_errbuf  := 'Erreur procedure ENVOI_ALL_MAIL '|| SQLERRM;
         pn_retcode := 2;
         log_msg(pv_errbuf);
    END envoi_all_mail;

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
  PROCEDURE edition_output(pv_errbuf        OUT NOCOPY VARCHAR2,
                           pn_retcode       OUT NOCOPY NUMBER) IS
  BEGIN
   out_msg(gn_traite || ' mails envoyés avec succes');
   out_msg(gn_erreur || ' mails en erreur'||chr(10));
   out_msg('Veuillez consulter le fichier de journalisation du traitement ID = '||FND_GLOBAL.CONC_REQUEST_ID);
  EXCEPTION
   WHEN OTHERS THEN
    pn_retcode := 2;
    pv_errbuf  := 'Erreur procedure EDITION_OUTPUT'||chr(10)||SQLERRM;
    log_msg(pv_errbuf);
  END edition_output;

--------------------------------------------------------------------------------------
 --  Nom           : MAIN
 --  Description   : Procedure principale enchainant l'ensemble des autres procedures
 --
 --  PARAMETRES :
 --    pv_errbuf                   Entree/Sortie       retour de message eventuel
 --    pn_retcode                  Sortie          status du traitement en sortie
 --    pv_debug                    Entree          Mode debug ?
 --    pv_mail_test                Entree          Adresse mail destinataire pour test
 --
 --  VALEUR RETOURNEE :
 --     Description       : code retour de validite
 --     Valeurs possibles : 0: normal, 1: warning, 2: erreur
 --
 ----------------------------------------------------------------------------------------
    PROCEDURE main (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER,
        pv_debug     IN       VARCHAR2,
        pv_mail_test IN       VARCHAR2
    ) IS
      --Exception
      e_init                   EXCEPTION;
      e_envoi_all_mail         EXCEPTION;
      e_edition_output         EXCEPTION;

      --variable temporaire pour le code retour
      vn_retcode                PLS_INTEGER := 0;

    BEGIN
      gb_debug := (nvl(pv_debug,'N') = 'Y');

      ------------------------------------
      --INITIALISATION ADRESSE MAIL TEST--
      ------------------------------------
      DKA_SEND_MAIL_PKG.mail_test(pv_mail_test,gv_mail_test);
      log_msg('Mail de test :'||gv_mail_test);

      ----------------------------------------------------------------
      --Initialisation du traitement
      ----------------------------------------------------------------
      log_msg('____________________________________________________________'||chr(10)||
              'Initialisation'||chr(10)||
              '____________________________________________________________'||chr(10));

      log_msg('Debut : '||get_time||chr(10));

      --procedure de initialisation
      init(pv_errbuf,pn_retcode);
      IF pn_retcode != 0 THEN
        RAISE e_init;
      END IF;

      log_msg('Initialisation OK...'||chr(10));
      log_msg('Fin   : '||get_time||chr(10));

       log_msg('____________________________________________________________'||chr(10)||
              'Denormalize Notification '||chr(10)||
              '____________________________________________________________'||chr(10));

      log_msg('Debut : '||get_time||chr(10));

      --procedure de denormalize_notification
      denormalize_notification (pv_errbuf,pn_retcode);
      IF pn_retcode != 0 THEN
        RAISE e_init;
      END IF;

      log_msg('Denormalize Notification OK...'||chr(10));
      log_msg('Fin   : '||get_time||chr(10));
      --- 27052011   MT end

      ----------------------------------------------------------------
      --Verification des contrats
      ----------------------------------------------------------------
      log_msg('____________________________________________________________'||chr(10)||
              'Procedure d''envoi des mails'||chr(10)||
              '____________________________________________________________'||chr(10));
      log_msg('Debut : '||get_time||chr(10));

      --procedure d'envoi des mails
      envoi_all_mail(pv_errbuf,pn_retcode);
      IF pn_retcode = 2 THEN
        RAISE e_envoi_all_mail;
      END IF;

      log_msg('Procedure d''envoi des mails OK...'||chr(10));
      log_msg('Fin   : '||get_time||chr(10));

      vn_retcode := pn_retcode;

      ----------------------------------------------------------------
      --Edition fichier de sortie
      ----------------------------------------------------------------
      log_msg('____________________________________________________________'||chr(10)||
              'Edition fichier de sortie'||chr(10)||
              '____________________________________________________________'||chr(10));
      log_msg('Debut : '||get_time||chr(10));

      --procedure d'edition de la sortie
      edition_output(pv_errbuf,pn_retcode);
      IF pn_retcode != 0 THEN
        RAISE e_edition_output;
      END IF;

      log_msg('Edition fichier de sortie OK...'||chr(10));
      log_msg('Fin   : '||get_time||chr(10));

      --Erreur
      pn_retcode := vn_retcode;

    EXCEPTION
     WHEN e_init THEN
       pv_errbuf  := 'Erreur procedure INIT';
       pn_retcode := 2;
       log_msg(pv_errbuf);
     WHEN e_envoi_all_mail THEN
       pv_errbuf  := 'Erreur procedure ENVOI_ALL_MAIL';
       pn_retcode := 2;
       log_msg(pv_errbuf);
     WHEN e_edition_output THEN
       pv_errbuf  := 'Erreur procedure EDITION_OUTPUT';
       pn_retcode := 2;
       log_msg(pv_errbuf);
     WHEN OTHERS THEN
       pv_errbuf  := 'Erreur procedure MAIN '|| SQLERRM;
       pn_retcode := 2;
       log_msg(pv_errbuf);
    END MAIN;

END DKA_SAPSUIVI_NOTIF_PKG;

/
SHOW ERRORS
EXIT
